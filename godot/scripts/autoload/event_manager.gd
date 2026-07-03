extends Node

var events: Array = []
var current_index: int = 0

const MONTH_ABBR = ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]

func _ready():
	_load_from_engine()

func _load_from_engine():
	if GameManager.engine and GameManager.engine.has_method("get_events"):
		events = GameManager.engine.get_events()
		if events.is_empty():
			_generate_season_events()
		current_index = _find_first_incomplete()

func _save_to_engine():
	if GameManager.engine:
		var has_set = GameManager.engine.has_method("set_events")
		print("[EventManager] _save_to_engine: engine OK, has_method(set_events)=", has_set, " events.size=", events.size())
		if has_set:
			GameManager.engine.set_events(events)
			print("[EventManager] set_events called with ", events.size(), " events")
		else:
			print("[EventManager] ENGINE DOES NOT HAVE set_events method!")
	else:
		print("[EventManager] _save_to_engine: NO ENGINE")

func generate_season_events():
	_generate_season_events()
	_save_to_engine()

func _generate_season_events():
	events.clear()
	var schedule = GameManager.get_schedule()
	print("[EventManager] _generate_season_events: schedule.size=", schedule.size())
	if schedule.is_empty():
		print("[EventManager] NO SCHEDULE, aborting")
		return

	var season = GameManager.league.get("season", 2025)
	var teams = GameManager.league.get("teams", [])
	var user_id = GameManager.user_team_id
	var event_id = 1

	var day_names = ["SEGUNDA", "TERCA", "QUARTA", "QUINTA", "SEXTA"]

	var match_dates = {}
	var match_hours = {}
	var match_opps = {}
	for m in schedule:
		var home_id = m.get("home_team", 0)
		var away_id = m.get("away_team", 0)
		if home_id != user_id and away_id != user_id:
			continue

		var w = m.get("week", 1)
		var d = _week_to_match_date(season, w)
		var key = str(d.year) + "-" + str(d.month) + "-" + str(d.day)
		match_dates[str(w)] = d
		match_dates[key] = true

		var is_home = home_id == user_id
		var opp_id = away_id if is_home else home_id
		var opp_abbr = "???"
		for t in teams:
			if t.get("id") == opp_id:
				opp_abbr = t.get("abbreviation", "???")
				break
		match_opps[str(w)] = opp_abbr

		var hour = randi_range(13, 22)
		match_hours[str(w)] = hour

		var phase_label = ""
		var is_playoff = m.get("is_playoff", false)
		if is_playoff:
			if w == 23:
				phase_label = "QUARTAS"
			elif w == 24:
				phase_label = "SEMIFINAL"
			elif w == 25:
				phase_label = "FINAL"
			else:
				phase_label = "PLAYOFF"

		var desc = "vs " + opp_abbr + (" (CASA)" if is_home else " (FORA)")

		events.append({
			"id": event_id,
			"event_type": "match",
			"season": season,
			"year": d.year,
			"month": d.month,
			"day": d.day,
			"hour": hour,
			"minute": 0,
			"competition": "league",
			"description": desc,
			"is_completed": m.get("played", false),
			"home_team_id": home_id,
			"away_team_id": away_id,
			"game_id": m.get("id", 0),
			"is_playoff": is_playoff,
			"phase_label": phase_label,
			"cup_stage": ""
		})
		event_id += 1

	for w in range(1, 23):
		var d = match_dates.get(str(w))
		if d == null:
			continue
		var h = match_hours.get(str(w), 20)
		var opp = match_opps.get(str(w), "OPP")
		var interview_h = h + 2
		var interview_m = 30
		if interview_h >= 24:
			interview_h -= 24
			var next = _add_days(d.year, d.month, d.day, 1)
			d = next

		events.append({
			"id": event_id,
			"event_type": "interview",
			"season": season,
			"year": d.year,
			"month": d.month,
			"day": d.day,
			"hour": interview_h,
			"minute": interview_m,
			"competition": "",
			"description": "Pós @" + opp,
			"is_completed": false,
			"home_team_id": 0,
			"away_team_id": 0,
			"game_id": 0,
			"is_playoff": false,
			"phase_label": "",
			"cup_stage": ""
		})
		event_id += 1

	var last_week = 0
	for m in schedule:
		if m.get("week", 1) > last_week:
			last_week = m.get("week", 1)

	var used_dates = {}
	for w in range(1, last_week + 1):
		var match_d = match_dates.get(str(w))
		if match_d == null:
			continue

		var opp = match_opps.get(str(w), "OPP")
		var monday = _week_to_date(season, w)
		var weekdays = []
		for offset in range(0, 5):
			weekdays.append(_add_days(monday.year, monday.month, monday.day, offset))

		var match_offset = -1
		for i in range(5):
			var wd = weekdays[i]
			if wd.day == match_d.day and wd.month == match_d.month and wd.year == match_d.year:
				match_offset = i
				break

		if match_offset < 0:
			continue

		var pre2 = _add_event_at_offset(weekdays, match_offset - 2, event_id, "training_tactical", 9, 0, "Tático", season, used_dates)
		if pre2 > 0: event_id = pre2

		var pre1_press = _add_event_at_offset(weekdays, match_offset - 2, event_id, "press_conference", 14, 0, "Coletiva", season, used_dates, true)
		if pre1_press > 0: event_id = pre1_press

		var pre1_tac = _add_event_at_offset(weekdays, match_offset - 1, event_id, "training_tactical", 9, 0, "Tático", season, used_dates)
		if pre1_tac > 0: event_id = pre1_tac

		var post1 = _add_event_at_offset(weekdays, match_offset + 1, event_id, "recovery", 15, 0, "Recuperação", season, used_dates)
		if post1 > 0: event_id = post1

		var post2 = _add_event_at_offset(weekdays, match_offset + 2, event_id, "training_physical", 9, 0, "Físico", season, used_dates)
		if post2 > 0: event_id = post2

		for i in range(5):
			if i == match_offset:
				continue
			var wd = weekdays[i]
			var key = str(wd.year) + "-" + str(wd.month) + "-" + str(wd.day)
			if used_dates.has(key):
				continue
			if match_dates.has(key):
				continue

			if w % 7 == 0:
				var rest_id = _add_event_at_offset(weekdays, i, event_id, "rest", 8, 0, "Descanso", season, used_dates)
				if rest_id > 0: event_id = rest_id
			elif w % 3 == 0 and i % 2 == 0:
				var meet_id = _add_event_at_offset(weekdays, i, event_id, "meeting", 11, 0, "Diretoria", season, used_dates)
				if meet_id > 0: event_id = meet_id
			else:
				var tac_id = _add_event_at_offset(weekdays, i, event_id, "training_tactical", 10, 0, "Tático", season, used_dates)
				if tac_id > 0: event_id = tac_id

	events.sort_custom(func(a, b):
		if a.year != b.year: return a.year < b.year
		if a.month != b.month: return a.month < b.month
		if a.day != b.day: return a.day < b.day
		return a.hour < b.hour
	)

	current_index = _find_first_incomplete()
	print("[EventManager] Generated ", events.size(), " events, current_index=", current_index)
	_save_to_engine()

func _add_event_at_offset(weekdays: Array, offset: int, start_id: int, etype: String, ehour: int, emin: int, elabel: String, season: int, used: Dictionary, force: bool = false) -> int:
	if offset < 0 or offset >= weekdays.size():
		return 0
	var wd = weekdays[offset]
	var key = str(wd.year) + "-" + str(wd.month) + "-" + str(wd.day)
	if not force and used.has(key):
		return 0
	used[key] = true

	var desc = elabel
	if etype == "training_physical":
		desc = "Físico"
	elif etype == "training_tactical":
		desc = "Tático"
	elif etype == "recovery":
		desc = "Recuperação"
	elif etype == "press_conference":
		desc = "Coletiva"
	elif etype == "meeting":
		desc = "Diretoria"
	elif etype == "rest":
		desc = "Descanso"

	events.append({
		"id": start_id,
		"event_type": etype,
		"season": season,
		"year": wd.year,
		"month": wd.month,
		"day": wd.day,
		"hour": ehour,
		"minute": emin,
		"competition": "",
		"description": desc,
		"is_completed": false,
		"home_team_id": 0,
		"away_team_id": 0,
		"game_id": 0,
		"is_playoff": false,
		"phase_label": "",
		"cup_stage": ""
	})
	return start_id + 1

func _find_first_incomplete() -> int:
	for i in range(events.size()):
		if not events[i].get("is_completed", false):
			return i
	return events.size()

func get_events_for_month(month: int, year: int) -> Array:
	var result = []
	for evt in events:
		if evt.year == year and evt.month == month:
			result.append(evt)
	return result

func get_current_event() -> Dictionary:
	if current_index < events.size():
		return events[current_index]
	return {}

func get_next_events(count: int = 5) -> Array:
	var result = []
	for i in range(current_index, min(current_index + count, events.size())):
		result.append(events[i])
	return result

func get_next_match() -> Dictionary:
	var user_id = GameManager.user_team_id
	for i in range(current_index, events.size()):
		var evt = events[i]
		if evt.get("event_type") == "match":
			if evt.get("home_team_id", 0) == user_id or evt.get("away_team_id", 0) == user_id:
				if not evt.get("is_completed", false):
					return evt
	return {}

func advance_to_next_event() -> Dictionary:
	var evt = get_current_event()
	if not evt.is_empty():
		complete_event(evt.id, true)
		current_index += 1
		return get_current_event()
	return {}

func complete_event(event_id: int, save: bool = true):
	var completed_type := ""
	for i in range(events.size()):
		if events[i].id == event_id:
			events[i].is_completed = true
			completed_type = events[i].get("event_type", "")
			break
	if save:
		_save_to_engine()
		if GameManager.engine and GameManager.engine.has_method("complete_event"):
			GameManager.engine.complete_event(event_id)

	if completed_type == "training" or completed_type == "training_physical" or completed_type == "training_tactical" or completed_type == "recovery":
		var label = "Treino Concluído"
		if completed_type == "recovery":
			label = "Recuperação Concluída"
		EventBus.inbox_received.emit({
			"event_type": "training_completed",
			"title": label,
			"body": "Sessão finalizada. Jogadores evoluíram atributos.",
			"severity": "info",
			"sender_role": "Preparador Físico",
			"sender_name": "Comissão Técnica"
		})

func has_next_event() -> bool:
	return current_index < events.size()

func is_season_over() -> bool:
	return current_index >= events.size()

func get_progress() -> float:
	if events.is_empty():
		return 0.0
	return float(current_index) / float(events.size())

func get_progress_text() -> String:
	return "DIA %d DE %d" % [current_index, events.size()]

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

static func _week_to_match_date(season: int, week: int) -> Dictionary:
	var mon = _week_to_date(season, week)
	var offset = (week - 1) % 5
	return _add_days(mon.year, mon.month, mon.day, offset)

static func _add_days(year: int, month: int, day: int, count: int) -> Dictionary:
	var d = day + count
	var m = month
	var y = year
	var days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	while d > days_in_month[m - 1]:
		d -= days_in_month[m - 1]
		m += 1
		if m > 12:
			m = 1
			y += 1
	return {"day": d, "month": m, "year": y}
