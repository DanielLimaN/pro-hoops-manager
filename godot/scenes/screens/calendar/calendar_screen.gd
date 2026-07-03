extends Control

enum CalendarState { DEFAULT, MATCH_SELECTED, SIMULATING }

@onready var calendar_grid = %CalendarGrid
@onready var month_navigator = %MonthNavigator
@onready var next_match_card = %NextMatchCard
@onready var mini_standings = %MiniStandings
var popover_scene = preload("res://scenes/screens/calendar/components/match_action_popover.tscn")
var popover_instance = null
var interview_popup_scene = preload("res://scenes/screens/calendar/components/interview_popup.tscn")
var interview_popup_instance = null

var current_state: CalendarState = CalendarState.DEFAULT
var selected_match: Dictionary = {}

var _month: int = 11
var _year: int = 2025

func _ready():
	EventBus.match_updated.connect(_on_match_updated)
	EventBus.date_updated.connect(_on_date_updated)
	EventBus.day_completed.connect(_on_day_completed)

	var bg = ColorRect.new()
	bg.color = ThemeConfig.BG_APP
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)

	var cp = get_node("MarginContainer/MainVBox/ContentHBox/LeftCol/CalendarPanel")
	cp.set_script(preload("res://scenes/ui/components/container_base.gd"))
	cp._ready()

	_build_ui()
	calendar_grid.match_clicked.connect(_on_match_clicked)
	calendar_grid.interview_clicked.connect(_on_interview_clicked)
	calendar_grid.day_clicked.connect(_on_day_clicked)
	month_navigator.month_changed.connect(_on_month_changed)
	month_navigator.today_clicked.connect(_on_today_clicked)

	var current_event = EventManager.get_current_event()
	if not current_event.is_empty():
		_month = current_event.get("month", 11)
		_year = current_event.get("year", 2025)
		month_navigator.set_month(_month, _year)
		_refresh_grid()
		_refresh_next_match()
		_refresh_standings()

	_wrap_calendar_in_scroll()

func _wrap_calendar_in_scroll():
	var calendar_panel = calendar_grid.get_parent()
	var left_col = calendar_panel.get_parent()
	left_col.remove_child(calendar_panel)

	var scroll = ScrollContainer.new()
	scroll.name = "CalendarScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	calendar_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(calendar_panel)
	left_col.add_child(scroll)

func _refresh_standings():
	mini_standings.refresh()

func _find_next_match() -> Dictionary:
	return EventManager.get_next_match()

func _get_team_data(team_id: int) -> Dictionary:
	var teams = GameManager.league.get("teams", [])
	for t in teams:
		if t.get("id") == 0:
			continue
		if t.get("id") == team_id:
			return t
	return GameManager.get_team(team_id)

func _get_standings() -> Array:
	var teams = GameManager.league.get("teams", [])
	var sorted = teams.duplicate()
	sorted.sort_custom(func(a, b):
		var a_wins = a.get("wins", 0)
		var b_wins = b.get("wins", 0)
		if a_wins != b_wins:
			return a_wins > b_wins
		var a_losses = a.get("losses", 0)
		var b_losses = b.get("losses", 0)
		return a_losses < b_losses
	)
	return sorted

func _refresh_next_match():
	var next = _find_next_match()
	if next.is_empty():
		next_match_card.hide()
		return

	next_match_card.show()

	var user_id = GameManager.user_team_id
	var home_id = next.get("home_team_id", 0)
	var away_id = next.get("away_team_id", 0)
	var is_home = home_id == user_id

	var home_team_raw = _get_team_data(home_id)
	var away_team_raw = _get_team_data(away_id)

	var standings = _get_standings()
	var home_pos = 0
	var away_pos = 0
	for i in range(standings.size()):
		if standings[i].get("id") == home_id:
			home_pos = i + 1
		if standings[i].get("id") == away_id:
			away_pos = i + 1

	var d = {"day": next.get("day", 1), "month": next.get("month", 1), "year": next.get("year", 2025)}

	var user_wins = 0
	var user_losses = 0
	var opp_wins = 0
	var opp_losses = 0
	var user_abbr = "???"
	var user_name = "???"
	var opp_abbr = "???"
	var opp_name = "???"

	if is_home:
		user_wins = home_team_raw.get("wins", 0)
		user_losses = home_team_raw.get("losses", 0)
		user_abbr = home_team_raw.get("abbreviation", "???")
		user_name = home_team_raw.get("name", "???")
		opp_wins = away_team_raw.get("wins", 0)
		opp_losses = away_team_raw.get("losses", 0)
		opp_abbr = away_team_raw.get("abbreviation", "???")
		opp_name = away_team_raw.get("name", "???")
	else:
		user_wins = away_team_raw.get("wins", 0)
		user_losses = away_team_raw.get("losses", 0)
		user_abbr = away_team_raw.get("abbreviation", "???")
		user_name = away_team_raw.get("name", "???")
		opp_wins = home_team_raw.get("wins", 0)
		opp_losses = home_team_raw.get("losses", 0)
		opp_abbr = home_team_raw.get("abbreviation", "???")
		opp_name = home_team_raw.get("name", "???")

	var user_total = user_wins + user_losses
	var opp_total = opp_wins + opp_losses
	var pred = 0.5
	if user_total > 0 or opp_total > 0:
		var user_ratio = float(user_wins) / float(max(user_total, 1))
		var opp_ratio = float(opp_wins) / float(max(opp_total, 1))
		var total_ratio = user_ratio + opp_ratio
		if total_ratio > 0:
			pred = user_ratio / total_ratio
	pred = clamp(pred, 0.0, 1.0)

	var phase_label = next.get("phase_label", "")

	var enriched = {
		"home_team": {
			"abbr": user_abbr,
			"name": user_name,
			"wins": user_wins,
			"losses": user_losses,
			"position": home_pos if is_home else away_pos
		},
		"away_team": {
			"abbr": opp_abbr,
			"name": opp_name,
			"wins": opp_wins,
			"losses": opp_losses,
			"position": away_pos if is_home else home_pos
		},
		"is_home": is_home,
		"is_playoff": next.get("is_playoff", false),
		"phase_label": phase_label,
		"day": d.day,
		"month": d.month,
		"year": d.year,
		"time": str(next.get("hour", 20)) + "h" + ("0" + str(next.get("minute", 0)) if next.get("minute", 0) < 10 else str(next.get("minute", 0))),
		"home_team_id": home_id,
		"away_team_id": away_id,
		"prediction": pred
	}

	next_match_card.setup(enriched)

func _on_advance_requested():
	_set_state(CalendarState.SIMULATING)
	EventBus.advance_simulation_requested.emit({})

@onready var nav_row = %NavRow

func _build_ui():
	for c in nav_row.get_children():
		if c.name == "TabBarPlaceholder":
			c.queue_free()

	var tab_box = HBoxContainer.new()
	tab_box.add_theme_constant_override("separation", 8)

	var tabs = [
		{"l": "CALENDÁRIO", "i": "calendar"},
	]
	for i in range(tabs.size()):
		var t = tabs[i]
		var b = preload("res://scenes/ui/components/tab_button.tscn").instantiate()
		b.text = t.l
		var icon_path = "res://addons/at-icons/control/" + ("text" if t.i == "list" else t.i) + ".svg"
		b.icon = load(icon_path)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 14)
		b.add_theme_constant_override("h_separation", 8)
		b.is_active = (i == 0)

		tab_box.add_child(b)

	nav_row.add_child(tab_box)
	nav_row.move_child(tab_box, 0)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_row.add_child(spacer)
	nav_row.move_child(spacer, 1)

	var right_nav = HBoxContainer.new()
	right_nav.add_theme_constant_override("separation", 12)

	nav_row.add_child(right_nav)

func _refresh_grid():
	if GameManager.league.is_empty():
		calendar_grid.build_calendar([], _month, _year)
		return

	var current_event = EventManager.get_current_event()
	var today_year = current_event.get("year", 2025)
	var today_month = current_event.get("month", 11)
	var today_day = current_event.get("day", 1) if not current_event.is_empty() else 1

	var month_events = EventManager.get_events_for_month(_month, _year)
	calendar_grid.build_calendar(month_events, _month, _year, today_day, today_month, today_year)

func _on_month_changed(year: int, month: int):
	_month = month
	_year = year
	_refresh_grid()

func _on_today_clicked():
	var current_event = EventManager.get_current_event()
	if current_event.is_empty(): return
	_month = current_event.get("month", 11)
	_year = current_event.get("year", 2025)
	month_navigator.set_month(_month, _year)
	_refresh_grid()
	_refresh_next_match()
	_refresh_standings()

func _on_date_updated(date_data: Dictionary):
	var current_event = EventManager.get_current_event()
	if current_event.is_empty(): return
	_month = current_event.get("month", 11)
	_year = current_event.get("year", 2025)
	month_navigator.set_month(_month, _year)
	_refresh_grid()
	_refresh_next_match()
	_refresh_standings()

func _on_interview_clicked(interview_data: Dictionary):
	if current_state != CalendarState.DEFAULT: return
	if interview_popup_instance: return

	interview_popup_instance = interview_popup_scene.instantiate()
	add_child(interview_popup_instance)
	interview_popup_instance.set_event(interview_data)
	interview_popup_instance.close_requested.connect(_on_interview_popup_closed)

func _on_interview_popup_closed():
	if interview_popup_instance:
		interview_popup_instance.queue_free()
		interview_popup_instance = null

func _on_match_clicked(match_data: Dictionary):
	if current_state != CalendarState.DEFAULT: return

	selected_match = match_data
	_set_state(CalendarState.MATCH_SELECTED)

	if not popover_instance:
		popover_instance = popover_scene.instantiate()
		add_child(popover_instance)
		popover_instance.close_requested.connect(_back_to_default)
		popover_instance.play_requested.connect(_on_play_now)
		popover_instance.sim_requested.connect(_on_simulate_until)

	var home_id = match_data.get("home_team_id", 0)
	var away_id = match_data.get("away_team_id", 0)
	var user_id = GameManager.user_team_id
	var is_home = home_id == user_id

	var opp_id = away_id if is_home else home_id
	var opp_abbr = "???"
	var user_abbr = "???"
	for t in GameManager.league.get("teams", []):
		if t.get("id") == opp_id:
			opp_abbr = t.get("abbreviation", "???")
		if t.get("id") == user_id:
			user_abbr = t.get("abbreviation", "???")

	var d = match_data.get("day", 1)
	var m = match_data.get("month", 1)
	var month_names = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"]
	var day_name = ""
	match (_get_dow(match_data.get("year", 2025), m, d)):
		0: day_name = "Dom"
		1: day_name = "Seg"
		2: day_name = "Ter"
		3: day_name = "Qua"
		4: day_name = "Qui"
		5: day_name = "Sex"
		6: day_name = "Sab"

	var date_str = day_name + ", " + str(d) + " " + month_names[m - 1]
	var h = match_data.get("hour", 20)
	var mi = match_data.get("minute", 0)
	var time_str = "%02dh%02d" % [h, mi]

	var schedule = GameManager.get_schedule()
	var games_until = 0
	for g in schedule:
		if not g.get("played", false) and g.get("week", 1) <= match_data.get("week", 1 if match_data.has("week") else 0):
			games_until += 1

	var popover_data = {
		"home_abbr": user_abbr if is_home else opp_abbr,
		"away_abbr": opp_abbr if is_home else user_abbr,
		"date": date_str,
		"time": time_str,
		"games_until": max(games_until, 1),
		"prediction": "50%",
		"raw": match_data
	}

	popover_instance.set_match(popover_data)
	popover_instance.show()

func _get_dow(year, month, day) -> int:
	var date = {"year": year, "month": month, "day": day, "hour": 12, "minute": 0, "second": 0}
	var unix = Time.get_unix_time_from_datetime_dict(date)
	var dt = Time.get_datetime_dict_from_unix_time(unix)
	return dt.get("weekday", 0)

func _on_day_clicked(day_data: Dictionary):
	if current_state == CalendarState.MATCH_SELECTED:
		_back_to_default()

func _on_play_now(match_data: Dictionary):
	var raw = match_data.get("raw", match_data)
	GameManager.pending_home_id = raw.get("home_team_id", 1)
	GameManager.pending_away_id = raw.get("away_team_id", 2)
	get_tree().change_scene_to_file("res://scenes/match.tscn")

func _on_simulate_until(match_data: Dictionary):
	_set_state(CalendarState.SIMULATING)
	var raw = match_data.get("raw", match_data)
	EventBus.advance_simulation_requested.emit(raw)

func _on_skip_to_match():
	_back_to_default()
	get_tree().change_scene_to_file("res://scenes/match.tscn")

func _back_to_default():
	_set_state(CalendarState.DEFAULT)
	selected_match = {}
	if popover_instance:
		popover_instance.hide()

func _set_state(new_state: CalendarState):
	current_state = new_state

func _on_day_completed(summary: Dictionary):
	_refresh_grid()
	_refresh_next_match()
	_refresh_standings()

func _on_match_updated(match_data: Dictionary):
	if match_data == null or match_data.is_empty():
		return
	if calendar_grid:
		for child in calendar_grid.get_children():
			if child.has_method("setup_from_event"):
				var day = match_data.get("day", 1)
				if child.day_number == day:
					child.setup_from_event({"match": match_data})
