extends Node

var engine: RefCounted
var league: Dictionary = {}
var user_team_id: int = 0
var match_events: Array = []
var is_simulating: bool = false
var sim_speed: float = 1.0
var pending_home_id: int = 0
var pending_away_id: int = 0
var pending_screen: String = ""

func _ready():
	engine = BasketballEngine.new()

func new_game(coach_name: String, team_id: int, focus: String) -> Dictionary:
	league = engine.new_game(coach_name, team_id, focus)
	user_team_id = engine.get_user_team_id()
	print("[GameManager] new_game done, calling EventManager.generate_season_events")
	EventManager.generate_season_events()
	league = get_league()
	print("[GameManager] league.events after generation: ", league.get("events", []).size() if league else 0)
	var saved = save_career()
	print("[GameManager] save_career result: ", saved)
	return league

func advance_season() -> Dictionary:
	league = engine.advance_season()
	user_team_id = engine.get_user_team_id()
	EventManager.generate_season_events()
	league = get_league()
	var saved = save_career()
	print("[GameManager] advance_season: season=", league.get("season", 0), " saved=", saved)
	return league

func start_match(home_id: int, away_id: int):
	match_events.clear()
	engine.start_match(home_id, away_id)

func sim_tick() -> Dictionary:
	var event = engine.sim_tick()
	if not event.is_empty():
		match_events.append(event)
	return event

func stop_match():
	pass

func get_team(team_id: int) -> Dictionary:
	return engine.get_team(team_id)

func get_league() -> Dictionary:
	return engine.get_league()

func get_schedule() -> Array:
	return engine.get_schedule()

func get_inbox() -> Array:
	if engine and engine.has_method("get_inbox"):
		return engine.get_inbox()
	return []

func get_finances(team_id: int = -1) -> Dictionary:
	if engine and engine.has_method("get_finances"):
		if team_id == -1:
			team_id = user_team_id
		return engine.get_finances(team_id)
	return {}

func get_player_salary_details(team_id: int = -1) -> Array:
	var finances = get_finances(team_id)
	return finances.get("player_salaries", [])

func get_game_params() -> Dictionary:
	if engine and engine.has_method("get_game_params"):
		return engine.get_game_params()
	return {}

func set_game_param(key: String, value) -> bool:
	if engine and engine.has_method("set_game_param"):
		var ok = engine.set_game_param(key, value)
		if ok:
			save_career()
		return ok
	return false

func set_tactic(team_id: int, tactic: Dictionary):
	engine.set_tactic(team_id, tactic)

func set_rotation_order(team_id: int, player_ids: Array):
	if engine and engine.has_method("set_rotation_order"):
		engine.set_rotation_order(team_id, player_ids)
		save_career()

func get_rotation_order(team_id: int = -1) -> Array:
	if engine and engine.has_method("get_rotation_order"):
		if team_id == -1:
			team_id = user_team_id
		return engine.get_rotation_order(team_id)
	return []

func set_training_focus(focus: String):
	if engine and engine.has_method("set_training_focus"):
		engine.set_training_focus(focus)
		save_career()

func get_training_focus() -> String:
	if engine and engine.has_method("get_training_focus"):
		return engine.get_training_focus()
	return "Balanced"

func set_training_intensity(intensity: String):
	if engine and engine.has_method("set_training_intensity"):
		engine.set_training_intensity(intensity)
		save_career()

func get_training_intensity() -> String:
	if engine and engine.has_method("get_training_intensity"):
		return engine.get_training_intensity()
	return "MÉDIA"

func get_training_status(team_id: int = -1) -> Dictionary:
	if engine and engine.has_method("get_training_status"):
		if team_id == -1:
			team_id = user_team_id
		return engine.get_training_status(team_id)
	return {}

func get_coach() -> Dictionary:
	if engine and engine.has_method("get_coach"):
		return engine.get_coach()
	return {}

func get_staff() -> Array:
	if engine and engine.has_method("get_staff"):
		return engine.get_staff()
	return []

func submit_interview_answer(answer_id: String, target_id: int = 0) -> Dictionary:
	if engine and engine.has_method("submit_interview_answer"):
		return engine.submit_interview_answer(answer_id, target_id)
	return {"message": "Engine indisponível"}

func get_user_team() -> Dictionary:
	return engine.get_team(user_team_id)

func get_match_score() -> Dictionary:
	return engine.get_match_score()

func is_match_over() -> bool:
	return engine.is_match_over()

func record_match_result(home_id: int, away_id: int, home_score: int, away_score: int) -> bool:
	if engine and engine.has_method("record_match_result"):
		var ok = engine.record_match_result(home_id, away_id, home_score, away_score)
		if ok:
			league = get_league()
		return ok
	return false

func save_game(path: String) -> bool:
	return engine.save_game(path)

func load_game(path: String) -> Dictionary:
	league = engine.load_game(path)
	user_team_id = engine.get_user_team_id()
	EventManager._load_from_engine()
	return league

func sim_week() -> bool:
	if engine.has_method("sim_week"):
		var did_sim = engine.sim_week()
		if did_sim:
			league = get_league()
			save_career()
		return did_sim
	return false

func sim_next_game() -> bool:
	if engine.has_method("sim_next_game"):
		var prev_week = league.get("current_week", 1)
		var did_sim = engine.sim_next_game()
		if did_sim:
			league = get_league()
			var new_week = league.get("current_week", 1)
			if new_week > prev_week:
				save_career()
		return did_sim
	return false

func sim_day() -> Dictionary:
	if engine.has_method("sim_day"):
		var result = engine.sim_day()
		if result.get("status", "") != "ERROR":
			league = get_league()
			if result.get("events", []).size() > 0:
				save_career()
		return result
	return {"status": "ERROR"}

func get_save_path() -> String:
	return ProjectSettings.globalize_path("user://savegame.db")

func has_save() -> bool:
	return FileAccess.file_exists("user://savegame.db")

func reset_career():
	league = {}
	user_team_id = 0
	match_events = []
	is_simulating = false
	sim_speed = 1.0
	pending_home_id = 0
	pending_away_id = 0
	pending_screen = ""

func save_career() -> bool:
	return save_game(get_save_path())

func load_career() -> bool:
	var loaded_league = load_game(get_save_path())
	if not loaded_league.is_empty():
		return true
	return false
