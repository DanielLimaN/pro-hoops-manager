extends GridContainer
class_name CalendarGrid

signal match_clicked(match_data: Dictionary)
signal interview_clicked(interview_data: Dictionary)
signal day_clicked(day_data: Dictionary)

@export var current_month: int = 11
@export var current_year: int = 2025
@export var today_day: int = -1
@export var events_for_month: Array = []

var _today_month: int = 11
var _today_year: int = 2025

const DayCellScene = preload("res://scenes/screens/calendar/components/day_cell.tscn")

func _ready():
	columns = 7
	add_theme_constant_override("h_separation", 0)
	add_theme_constant_override("v_separation", 0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

func build_calendar(month_events: Array = [], month: int = -1, year: int = -1, t_day: int = 1, t_month: int = 11, t_year: int = 2025):
	if month > 0: current_month = month
	if year > 0: current_year = year

	_today_month = t_month
	_today_year = t_year
	today_day = t_day if (t_month == current_month and t_year == current_year) else -1

	events_for_month = month_events

	for child in get_children():
		child.queue_free()

	_draw_headers()

	var first_dow = _get_day_of_week(current_year, current_month, 1)
	var days_in_month = _get_days_in_month(current_year, current_month)
	var days_in_prev = _get_days_in_month(current_year, current_month - 1) if current_month > 1 else 31

	var prev_month_days = first_dow

	for i in range(42):
		var cell = DayCellScene.instantiate()

		var day_num = i + 1 - prev_month_days
		var cell_state = DayCell.DayState.NORMAL
		var is_current = true

		if day_num <= 0:
			day_num = days_in_prev + day_num
			cell_state = DayCell.DayState.DIM
			is_current = false
		elif day_num > days_in_month:
			day_num -= days_in_month
			cell_state = DayCell.DayState.DIM
			is_current = false

		if is_current and day_num == today_day:
			cell_state = DayCell.DayState.TODAY
		elif is_current and today_day > 0 and day_num < today_day:
			cell_state = DayCell.DayState.PAST

		var cell_events = []
		if is_current:
			cell_events = _find_events_for_day(day_num)

		cell.setup(day_num, cell_state, cell_events)
		cell.clicked.connect(_on_cell_clicked)
		add_child(cell)

func _draw_headers():
	var days = ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SAB"]
	for d in days:
		var p = PanelContainer.new()
		var s = StyleBoxFlat.new()
		s.bg_color = ThemeConfig.BG_SURFACE_ALT
		s.border_color = ThemeConfig.BORDER_SUBTLE
		s.border_width_bottom = 1
		p.add_theme_stylebox_override("panel", s)

		var lbl = Label.new()
		lbl.text = d
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		lbl.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_constant_override("letter_spacing", 2)
		var m = MarginContainer.new()
		m.add_theme_constant_override("margin_top", 16)
		m.add_theme_constant_override("margin_bottom", 16)
		m.add_child(lbl)
		p.add_child(m)
		add_child(p)

func _find_events_for_day(day: int) -> Array:
	var result = []
	for evt in events_for_month:
		if evt.get("day", 0) != day:
			continue
		result.append(evt)
	return result

func _get_day_of_week(year: int, month: int, day: int) -> int:
	var date = {"year": year, "month": month, "day": day, "hour": 12, "minute": 0, "second": 0}
	var unix = Time.get_unix_time_from_datetime_dict(date)
	var dt = Time.get_datetime_dict_from_unix_time(unix)
	return dt.get("weekday", 0)

func _get_days_in_month(year: int, month: int) -> int:
	if month < 1 or month > 12:
		return 30
	var dm = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	if month == 2 and _is_leap_year(year):
		return 29
	return dm[month - 1]

static func _is_leap_year(year: int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)

func _on_cell_clicked(day_number: int, events: Array):
	var interview_evt = null
	for evt in events:
		if evt.get("event_type") == "match":
			match_clicked.emit(evt)
			return
		if evt.get("event_type") == "interview" and not evt.get("is_completed", false):
			interview_evt = evt
	if interview_evt:
		interview_clicked.emit(interview_evt)
		return
	day_clicked.emit({"day": day_number})

func clear_highlights():
	pass
