extends Node

var _engine
var _event_buffer: Array = []
var _is_simulating := false
var _target_week := 0
var _total_games := 0
var _completed_games := 0

signal on_stats_updated(safe_data: Dictionary)
signal on_day_advanced(date: String)

func _ready():
	await get_tree().process_frame
	_engine = GameManager.engine
	if not _engine:
		printerr("[SimulationBridge] ERRO: GameManager.engine não existe!")
		return
	if _engine.has_signal("stats_updated"):
		_engine.stats_updated.connect(_on_rust_stats_updated)
	if _engine.has_signal("day_advanced"):
		_engine.day_advanced.connect(_on_rust_day_advanced)

# ── Nova API assíncrona (Worker Thread) ──

func start_simulation(target_week: int) -> bool:
	if _is_simulating:
		return false
	if not _engine or not _engine.has_method("start_worker"):
		push_error("[SimulationBridge] Worker API não disponível no engine")
		_fallback_simulation(target_week)
		return true

	_is_simulating = true
	_target_week = target_week
	_completed_games = 0
	_total_games = _count_remaining_games(target_week)
	_engine.start_worker()
	_engine.simulate_to_week(target_week)
	return true

func cancel_simulation():
	if not _is_simulating:
		return
	if _engine and _engine.has_method("send_worker_command"):
		_engine.send_worker_command("cancel")
	_force_stop_worker()
	_is_simulating = false

func _process(delta):
	if not _is_simulating:
		return
	if not _engine or not _engine.has_method("poll_worker_events"):
		return

	var events = _engine.poll_worker_events()
	if events.is_empty():
		return

	for event in events:
		_process_worker_event(event)

func _force_stop_worker():
	if _engine and _engine.has_method("stop_worker"):
		_engine.stop_worker()

func _process_worker_event(event: Dictionary):
	var kind = event.get("kind", "")

	match kind:
		"match_simulated":
			_completed_games += 1
			_event_buffer.append(event)
			if _event_buffer.size() > 5:
				_event_buffer.pop_front()
			call_deferred("_emit_match_event", event)

		"day_advanced":
			var week = event.get("week", 0)
			var season = event.get("season", 2025)
			var stats = event.get("stats", {})
			if not stats.is_empty():
				call_deferred("_emit_stats_updated", stats)

			var phase = "regular"
			var phase_label = ""
			if week >= 23 and week <= 25:
				phase = "playoffs"
				var rounds = {23: "QUARTAS DE FINAL", 24: "SEMIFINAL", 25: "GRANDE FINAL"}
				phase_label = rounds.get(week, "PLAYOFFS")

			var date_string = _compute_date_string(season, week)
			call_deferred("_emit_date_updated", {
				"year": season,
				"week": week,
				"date_string": date_string,
				"phase": phase,
				"phase_label": phase_label
			})

		"progress_update":
			var progress = event.get("progress", 0.0)
			EventBus.time_advanced.emit(progress)

		"match_day":
			_engine.sync_worker_state()
			GameManager.league = GameManager.get_league()
			var home_id = event.get("home_id", 0)
			var away_id = event.get("away_id", 0)
			var week = event.get("week", 0)
			GameManager.pending_home_id = home_id
			GameManager.pending_away_id = away_id
			EventBus.match_found.emit({
				"home_id": home_id,
				"away_id": away_id,
				"week": week,
				"home_abbr": event.get("home_abbr", "HOME"),
				"away_abbr": event.get("away_abbr", "AWAY"),
			})

		"simulation_complete":
			_is_simulating = false
			if _engine and _engine.has_method("sync_worker_state"):
				_engine.sync_worker_state()
			GameManager.league = GameManager.get_league()
			_force_stop_worker()
			EventBus.time_advanced.emit(1.0)
			EventBus.simulation_complete.emit()

		"cancelled":
			_is_simulating = false
			_force_stop_worker()

		"error":
			var msg = event.get("message", "Erro desconhecido")
			push_error("[SimulationBridge] Worker error: ", msg)
			_is_simulating = false
			_force_stop_worker()

func _emit_match_event(event: Dictionary):
	var home_id = event.get("home_id", 0)
	var away_id = event.get("away_id", 0)
	var home_score = event.get("home_score", 0)
	var away_score = event.get("away_score", 0)
	if home_id > 0 and away_id > 0:
		GameManager.record_match_result(home_id, away_id, home_score, away_score)

	EventBus.day_completed.emit(event)

	var won = event.get("won", false)
	var opponent = event.get("opponent", "OPP")
	var is_home = event.get("is_home", true)

	var title = "Vitória sobre %s" % opponent if won else "Derrota para %s" % opponent
	var location = "em casa" if is_home else "fora de casa"
	var body = "%s %s %d a %d contra %s" % [
		"Seu time venceu" if won else "Seu time perdeu",
		location, home_score, away_score, opponent
	]

	# Emit inbox message
	EventBus.inbox_received.emit({
		"event_type": "match_result",
		"title": title,
		"body": body,
		"severity": "info",
		"sender_role": "Departamento de Imprensa",
		"sender_name": "Imprensa do Clube"
	})

	GameManager.save_career()

func _emit_date_updated(data: Dictionary):
	EventBus.date_updated.emit(data)

func _emit_stats_updated(stats: Dictionary):
	EventBus.stats_updated.emit(stats)
	var wins = stats.get("wins", 0)
	var losses = stats.get("losses", 0)
	var budget = stats.get("budget", 0)
	var safe_data = {"wins": wins, "losses": losses, "budget": budget}
	on_stats_updated.emit(safe_data)

func resume_simulation(simulate_match: bool):
	if _engine and _engine.has_method("resume_worker"):
		_engine.resume_worker(simulate_match)

# ── Fallback síncrono (caso worker não exista) ──

func _fallback_simulation(target_week: int):
	_is_simulating = true
	_total_games = _count_remaining_games(target_week)
	_completed_games = 0

	while GameManager.league.get("current_week", 1) <= target_week:
		if not _is_simulating:
			break
		var result = trigger_daily_simulation()
		if result.is_empty() or result.get("status", "") != "COMPLETED":
			break
		if not _is_simulating:
			break

	EventBus.time_advanced.emit(1.0)
	_is_simulating = false

# ── API antiga (mantida para compatibilidade) ──

func trigger_advance_week() -> bool:
	return GameManager.sim_week()

func trigger_next_game() -> bool:
	return GameManager.sim_next_game()

func trigger_daily_simulation() -> Dictionary:
	var raw = GameManager.sim_day()
	if _validate_day_schema(raw):
		_event_buffer.append(raw)
		if _event_buffer.size() > 5:
			_event_buffer.pop_front()
		call_deferred("_emit_day_completed", raw)
		var stats = raw.get("stats", {})
		if not stats.is_empty():
			call_deferred("_emit_stats_updated", stats)
		return raw
	push_error("[SimulationBridge] Dia inválido: ", raw)
	return {}

func get_recent_days() -> Array:
	return _event_buffer.duplicate()

func _emit_day_completed(summary: Dictionary):
	EventBus.day_completed.emit(summary)

func _validate_day_schema(d: Dictionary) -> bool:
	if d.is_empty() or d.get("status", "") != "COMPLETED":
		return false
	if typeof(d.get("events")) != TYPE_ARRAY:
		return false
	var stats = d.get("stats", {})
	if not stats.has("wins") or not stats.has("losses"):
		return false
	return true

func _on_rust_stats_updated(raw_data: Dictionary):
	var safe_data = _validate_stats_schema(raw_data)
	if safe_data.is_empty():
		printerr("[SimulationBridge] Erro Fatal: O Rust enviou um schema inválido!")
		return
	on_stats_updated.emit(safe_data)

func _on_rust_day_advanced(date: String):
	on_day_advanced.emit(date)
	var week_str = date.trim_prefix("Week ").strip_edges()
	var week = int(week_str) if week_str.is_valid_int() else 1
	var season = GameManager.league.get("season", 2025) if not GameManager.league.is_empty() else 2025
	var date_string = _compute_date_string(season, week)

	var phase = "regular"
	var phase_label = ""
	if week >= 23 and week <= 25:
		phase = "playoffs"
		var rounds = {23: "QUARTAS DE FINAL", 24: "SEMIFINAL", 25: "GRANDE FINAL"}
		phase_label = rounds.get(week, "PLAYOFFS")

	EventBus.date_updated.emit({
		"year": season,
		"week": week,
		"date_string": date_string,
		"phase": phase,
		"phase_label": phase_label
	})

func _compute_date_string(season: int, week: int) -> String:
	var d = _week_to_date(season, week)
	var months = [
		"JANEIRO", "FEVEREIRO", "MARÇO", "ABRIL",
		"MAIO", "JUNHO", "JULHO", "AGOSTO",
		"SETEMBRO", "OUTUBRO", "NOVEMBRO", "DEZEMBRO"
	]
	if d.month < 1 or d.month > 12:
		return str(d.day) + " DE NOVEMBRO"
	return str(d.day) + " DE " + months[d.month - 1]

static func _week_to_date(season: int, week: int) -> Dictionary:
	var base_day = 3
	var base_month = 11
	var day = base_day + (week - 1) * 7
	var month = base_month
	var year = season
	var days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	while day > days_in_month[month - 1]:
		day -= days_in_month[month - 1]
		month += 1
		if month > 12:
			month = 1
			year += 1
	return {"day": day, "month": month, "year": year}

func submit_interview_answer(answer_id: String, target_id: int = 0) -> Dictionary:
	var result = GameManager.submit_interview_answer(answer_id, target_id)
	var msg = result.get("message", "Você respondeu à entrevista.")
	EventBus.inbox_received.emit({
		"event_type": "interview_feedback",
		"title": "Entrevista Pós-Jogo",
		"body": msg,
		"severity": "info",
		"sender_role": "Departamento de Imprensa",
		"sender_name": "Assessoria de Comunicação"
	})
	GameManager.save_career()
	return result

static func get_season_data() -> Dictionary:
	if GameManager.league.is_empty():
		return {"season": 0, "current_week": 0, "schedule": [], "total_weeks": 25}
	var season = GameManager.league.get("season", 2025)
	var current_week = GameManager.league.get("current_week", 1)
	var schedule = GameManager.get_schedule()
	return {
		"season": season,
		"current_week": current_week,
		"schedule": schedule,
		"total_weeks": 25
	}

static func get_matches_for_month(month: int, year: int) -> Array:
	var data = get_season_data()
	if data.season == 0:
		return []
	var user_id = GameManager.user_team_id
	var result = []
	var teams = GameManager.league.get("teams", [])
	for m in data.schedule:
		var home_id = m.get("home_team", 0)
		var away_id = m.get("away_team", 0)
		if home_id != user_id and away_id != user_id:
			continue
		var d = _week_to_date(data.season, m.get("week", 1))
		if d.month == month and d.year == year:
			var is_home = home_id == user_id
			var opp_id = away_id if is_home else home_id
			var opp_abbr = "OPP"
			for t in teams:
				if t.get("id") == opp_id:
					opp_abbr = t.get("abbreviation", "OPP")
					break
			var is_playoff = m.get("is_playoff", false)
			result.append({
				"day": d.day,
				"month": d.month,
				"year": d.year,
				"week": m.get("week", 1),
				"is_home": is_home,
				"away_abbr": opp_abbr,
				"played": m.get("played", false),
				"is_playoff": is_playoff,
				"home_score": m.get("home_score", 0),
				"away_score": m.get("away_score", 0),
				"home_team": home_id,
				"away_team": away_id,
				"time": "20h00"
			})
	return result

func _validate_stats_schema(data: Dictionary) -> Dictionary:
	var required_keys = ["wins", "losses", "budget"]
	for key in required_keys:
		if not data.has(key):
			push_error("Schema mismatch: Faltando chave '%s' no dicionário vindo do Rust." % key)
			return {}
	return {
		"wins": int(data["wins"]),
		"losses": int(data["losses"]),
		"budget": float(data["budget"])
	}

func _count_remaining_games(target_week: int) -> int:
	var count = 0
	var sched = GameManager.get_schedule()
	for g in sched:
		var w = g.get("week", 0)
		if not g.get("played", false) and w <= target_week:
			count += 1
	return max(count, 1)
