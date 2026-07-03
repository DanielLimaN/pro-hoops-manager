extends Control

var _tick_timer: float = 0.0
var _match_home_id: int = 0
var _match_away_id: int = 0

func _ready():
	GameManager.match_events.clear()
	%Court2D.clear_court()

	# Populate speed options
	%SpeedSelect.clear()
	%SpeedSelect.add_item("1x")
	%SpeedSelect.add_item("2x")
	%SpeedSelect.add_item("4x")
	%SpeedSelect.add_item("8x")

	%TickButton.pressed.connect(_on_tick)
	%SimButton.pressed.connect(_on_sim_toggle)
	%ExitButton.pressed.connect(_on_exit)
	%SpeedSelect.item_selected.connect(_on_speed_changed)

	_match_home_id = GameManager.pending_home_id
	_match_away_id = GameManager.pending_away_id
	if _match_home_id > 0:
		GameManager.start_match(_match_home_id, _match_away_id)
		GameManager.pending_home_id = 0

func _process(delta):
	if GameManager.is_simulating:
		_tick_timer += delta
		# 1 tick = 0.4 game seconds. To achieve 1:1 real-time speed at 1x,
		# the tick interval must be 0.4 seconds.
		var interval = 0.4 / GameManager.sim_speed
		while _tick_timer >= interval:
			_tick_timer -= interval
			_tick()
			if GameManager.is_match_over():
				GameManager.is_simulating = false
				break

	if not GameManager.match_events.is_empty():
		var latest = GameManager.match_events[GameManager.match_events.size() - 1]
		if latest.has("score"):
			%HomeScoreLabel.text = "%02d" % int(latest.score.home)
			%AwayScoreLabel.text = "%02d" % int(latest.score.away)
			%HomeFoulsLabel.text = str(latest.score.get("home_fouls", 0))
			%AwayFoulsLabel.text = str(latest.score.get("away_fouls", 0))
			%ClockLabel.text = _fmt_clock(int(latest.score.clock_seconds))
			%ShotClockLabel.text = str(int(latest.score.shot_clock))
			%QuarterLabel.text = str(latest.score.quarter)

		_update_event_log()

func _tick():
	var event = GameManager.sim_tick()
	if event.is_empty():
		return

	if GameManager.is_match_over():
		_on_match_end()

func _on_tick():
	if GameManager.is_simulating:
		return
	_tick()

func _on_sim_toggle():
	GameManager.is_simulating = not GameManager.is_simulating
	%SimButton.text = "Pausar" if GameManager.is_simulating else "Simular"

func _on_speed_changed(idx: int):
	var speeds = [1.0, 2.0, 4.0, 8.0]
	GameManager.sim_speed = speeds[idx]

func _on_exit():
	GameManager.is_simulating = false
	var score = GameManager.get_match_score()
	GameManager.record_match_result(
		_match_home_id,
		_match_away_id,
		int(score.home),
		int(score.away)
	)
	GameManager.stop_match()
	GameManager.pending_home_id = 0
	GameManager.pending_away_id = 0
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_match_end():
	GameManager.is_simulating = false
	%SimButton.text = "Simular"

func _update_event_log():
	var events = GameManager.match_events
	var valid_events = []
	var last_text = ""
	for evt in events:
		if evt.has("text") and evt.text.strip_edges() != "":
			var txt = evt.text.strip_edges()
			if txt != last_text:
				valid_events.append(evt)
				last_text = txt
			
	var count = valid_events.size()
	var log_text = ""
	var start = max(0, count - 30)
	for i in range(start, count):
		var evt = valid_events[i]
		var clock = _fmt_clock(evt.score.clock_seconds)
		var line = "[" + clock + "] " + evt.text
		log_text += line + "\n"
	%EventLog.text = log_text

func _fmt_clock(seconds) -> String:
	var secs_int = int(seconds)
	var mins = secs_int / 60
	var secs = secs_int % 60
	return str(mins) + ":" + ("0" if secs < 10 else "") + str(secs)
