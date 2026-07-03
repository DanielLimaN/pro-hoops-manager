extends Node

var modal_scene = preload("res://scenes/screens/calendar/components/simulation_modal.tscn")
var modal_instance = null
var _is_simulating := false
var _pending_match_data: Dictionary = {}
var _current_target_match: Dictionary = {}

func _ready():
	EventBus.simulation_complete.connect(_on_simulation_complete)
	EventBus.advance_simulation_requested.connect(_on_advance_requested)
	EventBus.match_found.connect(_on_match_found)

func _ensure_modal():
	if modal_instance:
		return
	modal_instance = modal_scene.instantiate()
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.add_child(modal_instance)
	add_child(canvas_layer)

	modal_instance.cancel_requested.connect(func():
		_is_simulating = false
		SimulationBridge.cancel_simulation()
		modal_instance.hide()
		GameManager.pending_home_id = 0
		GameManager.pending_away_id = 0
		_pending_match_data = {}
	)
	modal_instance.skip_to_match_requested.connect(func():
		_is_simulating = false
		SimulationBridge.cancel_simulation()
		modal_instance.hide()
		get_tree().change_scene_to_file("res://scenes/match.tscn")
	)
	modal_instance.inbox_requested.connect(func():
		_is_simulating = false
		SimulationBridge.cancel_simulation()
		modal_instance.hide()
		GameManager.pending_screen = "res://scenes/inbox.tscn"
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	modal_instance.play_requested.connect(_on_modal_play)
	modal_instance.simulate_requested.connect(_on_modal_simulate)

func _on_advance_requested(target: Dictionary):
	if _is_simulating:
		return
	_is_simulating = true

	_ensure_modal()

	var next_match = EventManager.get_next_match()
	var effective_target = target.duplicate()
	if target.is_empty() and not next_match.is_empty():
		effective_target = next_match

	_current_target_match = next_match

	var target_week = effective_target.get("week", 0)
	if target_week <= 0:
		target_week = next_match.get("week", GameManager.league.get("current_week", 1)) if not next_match.is_empty() else GameManager.league.get("current_week", 1)

	print("[SimCtrl] _on_advance_requested: target_week=", target_week, " league.current_week=", GameManager.league.get("current_week", 1), " next_match=", next_match.get("description", "none"))
	print("[SimCtrl] _on_advance_requested: current_index=", EventManager.current_index, " events.size=", EventManager.events.size(), " is_over=", EventManager.is_season_over())

	var expected_events = _count_events_until(next_match)
	modal_instance.start_simulation(effective_target, max(expected_events, 1))

	await get_tree().process_frame

	SimulationBridge.start_simulation(target_week)

func _on_simulation_complete():
	if not _is_simulating:
		return
	_is_simulating = false

	print("[SimCtrl] _on_simulation_complete: current_index=", EventManager.current_index, " is_over=", EventManager.is_season_over())
	_complete_events_up_to(_current_target_match)

	GameManager.save_career()

	if is_instance_valid(modal_instance) and modal_instance.visible:
		modal_instance.fast_forward_complete()

	if EventManager.is_season_over():
		_show_new_season_prompt()

func _show_new_season_prompt():
	var popup = AcceptDialog.new()
	popup.title = "Temporada Concluída!"
	popup.dialog_text = "Parabéns! Você completou mais uma temporada.\n\nDeseja avançar para a próxima temporada?"
	popup.ok_button_text = "AVANÇAR"
	popup.add_cancel_button("")
	popup.get_ok_button().pressed.connect(func():
		popup.queue_free()
		_start_new_season()
	)
	popup.exclusive = true
	popup.unresizable = true
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 110
	canvas_layer.add_child(popup)
	if modal_instance and is_instance_valid(modal_instance):
		modal_instance.add_child(canvas_layer)
	else:
		get_tree().root.add_child(canvas_layer)
	popup.popup_centered()

func _start_new_season():
	GameManager.advance_season()
	EventBus.date_updated.emit({"year": GameManager.league.get("season", 2026), "date_string": "NOVA TEMPORADA"})
	EventBus.day_completed.emit({})

func _on_match_found(match_data: Dictionary):
	_pending_match_data = match_data
	if is_instance_valid(modal_instance):
		modal_instance.show_match_prompt(match_data)

func _on_modal_play():
	_is_simulating = false
	SimulationBridge.cancel_simulation()
	modal_instance.hide()
	_mark_match_completed(_pending_match_data)
	var home_id = _pending_match_data.get("home_id", 0)
	var away_id = _pending_match_data.get("away_id", 0)
	_pending_match_data = {}
	GameManager.pending_home_id = home_id
	GameManager.pending_away_id = away_id
	get_tree().change_scene_to_file("res://scenes/match.tscn")

func _on_modal_simulate():
	SimulationBridge.resume_simulation(true)
	_mark_match_completed(_pending_match_data)
	_pending_match_data = {}

func _count_events_until(target_match: Dictionary) -> int:
	var evts = EventManager.events
	var count = 0
	var target_game_id = target_match.get("game_id", 0)
	for i in range(EventManager.current_index, evts.size()):
		count += 1
		if evts[i].get("game_id", 0) == target_game_id:
			break
	return max(count, 1)

func _complete_events_up_to(target_match: Dictionary):
	var target_game_id = target_match.get("game_id", -1)
	if target_game_id <= 0:
		print("[SimCtrl] _complete_events_up_to: invalid target_game_id=", target_game_id)
		return

	var target_idx = -1
	var events = EventManager.events
	for i in range(events.size()):
		if events[i].get("game_id", 0) == target_game_id:
			target_idx = i
			break
	if target_idx < 0:
		print("[SimCtrl] _complete_events_up_to: target_game_id not found in events")
		return

	print("[SimCtrl] _complete_events_up_to: current_index=", EventManager.current_index, " target_idx=", target_idx)
	for i in range(EventManager.current_index, target_idx + 1):
		var evt = events[i]
		if not evt.get("is_completed", false):
			EventManager.complete_event(evt.id, false)

	EventManager.current_index = EventManager._find_first_incomplete()
	EventManager._save_to_engine()

func _mark_match_completed(match_data: Dictionary):
	if match_data.is_empty():
		return
	var events = EventManager.events
	var home_id = match_data.get("home_id", 0)
	var away_id = match_data.get("away_id", 0)
	for evt in events:
		if evt.get("event_type") == "match" and not evt.get("is_completed", false):
			if evt.get("home_team_id", 0) == home_id and evt.get("away_team_id", 0) == away_id:
				EventManager.complete_event(evt.id)
				break
	EventManager._save_to_engine()
