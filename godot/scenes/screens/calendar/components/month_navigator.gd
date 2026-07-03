extends HBoxContainer
class_name MonthNavigator

signal month_changed(year: int, month: int)
signal today_clicked

@onready var month_lbl = $MonthLbl
@onready var prev_btn = $PrevBtn
@onready var next_btn = $NextBtn
@onready var today_btn = $TodayBtn

var _current_month: int = 11
var _current_year: int = 2025

var _month_names = [
	"Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
	"Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
]

func _ready():
	prev_btn.text = ""
	prev_btn.icon = load("res://addons/at-icons/control/previous.svg")
	prev_btn.expand_icon = true
	prev_btn.add_theme_constant_override("icon_max_width", 14)
	prev_btn.add_theme_color_override("icon_normal_color", Color.WHITE)
	prev_btn.add_theme_color_override("icon_pressed_color", Color.WHITE)
	prev_btn.add_theme_color_override("icon_hover_color", Color.WHITE)
	prev_btn.add_theme_color_override("icon_focus_color", Color.WHITE)

	next_btn.text = ""
	next_btn.icon = load("res://addons/at-icons/control/next.svg")
	next_btn.expand_icon = true
	next_btn.add_theme_constant_override("icon_max_width", 14)
	next_btn.add_theme_color_override("icon_normal_color", Color.WHITE)
	next_btn.add_theme_color_override("icon_pressed_color", Color.WHITE)
	next_btn.add_theme_color_override("icon_hover_color", Color.WHITE)
	next_btn.add_theme_color_override("icon_focus_color", Color.WHITE)

	prev_btn.pressed.connect(_on_prev)
	next_btn.pressed.connect(_on_next)
	today_btn.pressed.connect(_on_today)

	month_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0, 0, 0, 0)
	style_normal.border_color = ThemeConfig.BORDER_SUBTLE
	style_normal.border_width_left = 1
	style_normal.border_width_top = 1
	style_normal.border_width_right = 1
	style_normal.border_width_bottom = 1
	style_normal.corner_radius_top_left = 20
	style_normal.corner_radius_top_right = 20
	style_normal.corner_radius_bottom_left = 20
	style_normal.corner_radius_bottom_right = 20
	style_normal.content_margin_left = 6
	style_normal.content_margin_right = 6

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = ThemeConfig.BG_ELEVATED
	style_hover.border_color = ThemeConfig.BORDER_SUBTLE
	style_hover.border_width_left = 1
	style_hover.border_width_top = 1
	style_hover.border_width_right = 1
	style_hover.border_width_bottom = 1
	style_hover.corner_radius_top_left = 20
	style_hover.corner_radius_top_right = 20
	style_hover.corner_radius_bottom_left = 20
	style_hover.corner_radius_bottom_right = 20
	style_hover.content_margin_left = 6
	style_hover.content_margin_right = 6

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	style_pressed.border_color = ThemeConfig.BORDER_SUBTLE
	style_pressed.border_width_left = 1
	style_pressed.border_width_top = 1
	style_pressed.border_width_right = 1
	style_pressed.border_width_bottom = 1
	style_pressed.corner_radius_top_left = 20
	style_pressed.corner_radius_top_right = 20
	style_pressed.corner_radius_bottom_left = 20
	style_pressed.corner_radius_bottom_right = 20
	style_pressed.content_margin_left = 6
	style_pressed.content_margin_right = 6

	prev_btn.add_theme_stylebox_override("normal", style_normal)
	prev_btn.add_theme_stylebox_override("hover", style_hover)
	prev_btn.add_theme_stylebox_override("pressed", style_pressed)
	next_btn.add_theme_stylebox_override("normal", style_normal)
	next_btn.add_theme_stylebox_override("hover", style_hover)
	next_btn.add_theme_stylebox_override("pressed", style_pressed)

	today_btn.text = "HOJE"
	today_btn.icon = load("res://addons/at-icons/control/target.svg")
	today_btn.expand_icon = true
	today_btn.add_theme_constant_override("icon_max_width", 14)
	today_btn.add_theme_constant_override("h_separation", 6)
	today_btn.add_theme_color_override("icon_normal_color", Color.WHITE)
	today_btn.add_theme_color_override("icon_pressed_color", Color.WHITE)
	today_btn.add_theme_color_override("icon_hover_color", Color.WHITE)
	today_btn.add_theme_color_override("icon_focus_color", Color.WHITE)

func set_month(month: int, year: int):
	_current_month = month
	_current_year = year
	var name = _month_names[month - 1] if month >= 1 and month <= 12 else "?"
	month_lbl.text = "%s\n%d" % [name.to_upper(), year]

func set_to_current_week():
	var current_event = EventManager.get_current_event()
	if current_event.is_empty(): return
	set_month(current_event.get("month", 11), current_event.get("year", 2025))
	month_changed.emit(current_event.get("year", 2025), current_event.get("month", 11))

func _on_prev():
	var m = _current_month - 1
	var y = _current_year
	if m < 1:
		m = 12
		y -= 1
	set_month(m, y)
	month_changed.emit(y, m)

func _on_next():
	var m = _current_month + 1
	var y = _current_year
	if m > 12:
		m = 1
		y += 1
	set_month(m, y)
	month_changed.emit(y, m)

func _on_today():
	today_clicked.emit()
