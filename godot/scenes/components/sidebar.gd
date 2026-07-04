extends Panel

@export var active_tab: String = ""
signal menu_item_selected(path: String)

const NAV_ITEMS := [
	{name = "Dashboard",    icon = "grid_coarse",          path = "res://scenes/ui/dashboard/dashboard.tscn",               screen = "Dashboard"},
	{name = "Elenco",       icon = "human",                path = "res://scenes/team.tscn",                                 screen = "Team"},
	{name = "Calendário",   icon = "calendar",             path = "res://scenes/screens/calendar/calendar_screen.tscn",      screen = "CalendarScreen"},
	{name = "Tática",       icon = "clipboard",            path = "res://scenes/tactics.tscn",                               screen = "Tactics"},
	{name = "Treinos",      icon = "weight",               path = "res://scenes/training.tscn",                              screen = "Training"},
	{name = "Caixa de Entrada", icon = "envelope",         path = "res://scenes/inbox.tscn",                                 screen = "Inbox"},
	{name = "Transferências", icon = "arrow_right_arrow_left", path = "res://scenes/ui/dashboard/dashboard.tscn",           screen = ""},
	{name = "Finanças",     icon = "coins",                path = "res://scenes/finance.tscn",                               screen = "Finance"},
	{name = "Estatísticas", icon = "bar_graph",            path = "res://scenes/ui/dashboard/dashboard.tscn",               screen = ""},
	{name = "Conquistas",   icon = "trophy",               path = "res://scenes/ui/dashboard/dashboard.tscn",               screen = ""},
]

var _nav_buttons: Array[Button] = []
var _nav_data: Array[Dictionary] = []

const COLOR_ACTIVE_BG := Color("#A78BFA22")
const COLOR_ACTIVE_ACCENT := Color("#A78BFA66")
const COLOR_ACTIVE_TEXT := Color("#FFFFFF")
const COLOR_INACTIVE_ICON := Color("#A78BFA")
const COLOR_INACTIVE_TEXT := Color("#CBD5E1")
const COLOR_BRAND := Color("#A78BFA")
const COLOR_BRAND_DEEP := Color("#7C3AED")
const COLOR_FOOTER_ICON := Color("#6B5B95")
const COLOR_FOOTER_TEXT := Color("#94A3B8")
const COLOR_BADGE_PURPLE := Color("#A78BFA")
const COLOR_BADGE_RED := Color("#EF4444")

@onready var nav_container: VBoxContainer = %NavContainer
@onready var initials_lbl: Label = %Initials
@onready var name_lbl: Label = %NameLbl
@onready var team_lbl: Label = %TeamLbl
@onready var settings_area: Control = %SettingsArea
@onready var restart_area: Control = %RestartArea
@onready var logout_area: Control = %LogoutArea

func _ready():
	_init_labels()
	_init_footer()
	_build_nav_items()
	if active_tab != "":
		set_active_tab(active_tab)

func _init_labels():
	var t1 = $VBox/Header/HeaderHBox/TitleVBox/T1
	t1.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
	t1.add_theme_font_size_override("font_size", 20)
	t1.add_theme_color_override("font_color", COLOR_ACTIVE_TEXT)
	t1.add_theme_constant_override("letter_spacing", 1)

	var t2 = $VBox/Header/HeaderHBox/TitleVBox/T2
	t2.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	t2.add_theme_font_size_override("font_size", 20)
	t2.add_theme_color_override("font_color", COLOR_BRAND)
	t2.add_theme_constant_override("letter_spacing", 2)

	initials_lbl.text = _get_initials()
	initials_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	initials_lbl.add_theme_font_size_override("font_size", 13)
	initials_lbl.add_theme_color_override("font_color", COLOR_ACTIVE_TEXT)

	name_lbl.text = _get_coach_name()
	name_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", COLOR_ACTIVE_TEXT)

	team_lbl.text = _get_team_name()
	team_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	team_lbl.add_theme_font_size_override("font_size", 13)
	team_lbl.add_theme_color_override("font_color", COLOR_BRAND)
	if team_lbl.text.length() > 22:
		team_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _init_footer():
	var settings_icon = $VBox/Footer/FooterMargin/FooterHBox/SettingsIcon
	settings_icon.modulate = COLOR_FOOTER_ICON

	var settings_lbl = $VBox/Footer/FooterMargin/FooterHBox/SettingsLbl
	settings_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	settings_lbl.add_theme_font_size_override("font_size", 14)
	settings_lbl.add_theme_color_override("font_color", COLOR_FOOTER_TEXT)

	var settings_click = settings_area.get_node("SettingsClick")
	settings_click.pressed.connect(func(): menu_item_selected.emit("settings"))

	var restart_click = restart_area.get_node("RestartClick")
	restart_click.pressed.connect(_on_restart)

	var logout_click = logout_area.get_node("LogoutClick")
	logout_click.pressed.connect(func(): menu_item_selected.emit("logout"))

func _build_nav_items():
	for i in range(NAV_ITEMS.size()):
		var item = NAV_ITEMS[i]
		var btn = Button.new()
		btn.text = "  " + item.name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_constant_override("h_separation", 12)
		btn.add_theme_constant_override("icon_max_width", 18)
		btn.expand_icon = true
		btn.icon = load("res://addons/at-icons/control/" + item.icon + ".svg")
		btn.add_theme_font_override("font", ThemeConfig.FONT_INTER)
		btn.add_theme_font_size_override("font_size", 15)

		set_nav_style(btn, false)

		var path = item.path
		btn.pressed.connect(func():
			emit_signal("menu_item_selected", path)
		)

		_nav_buttons.append(btn)
		_nav_data.append(item)
		nav_container.add_child(btn)

		if item.name == "Elenco":
			_add_badge(btn, "", COLOR_BADGE_PURPLE)
		elif item.name == "Caixa de Entrada":
			_add_badge(btn, "", COLOR_BADGE_RED)

func set_nav_style(btn: Button, active: bool):
	var s = StyleBoxFlat.new()
	if active:
		s.bg_color = COLOR_ACTIVE_BG
		s.border_color = COLOR_ACTIVE_ACCENT
		s.border_width_left = 2
		btn.add_theme_color_override("font_color", COLOR_ACTIVE_TEXT)
		btn.add_theme_color_override("font_hover_color", COLOR_ACTIVE_TEXT)
		btn.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		btn.modulate = Color.WHITE
	else:
		s.bg_color = Color.TRANSPARENT
		btn.add_theme_color_override("font_color", COLOR_INACTIVE_TEXT)
		btn.add_theme_color_override("font_hover_color", COLOR_ACTIVE_TEXT)
		btn.add_theme_font_override("font", ThemeConfig.FONT_INTER)
		btn.modulate = COLOR_INACTIVE_ICON
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover", s)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_stylebox_override("focus", s)

func _add_badge(btn: Button, text: String, color: Color):
	var container = PanelContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bs = StyleBoxFlat.new()
	bs.bg_color = color
	bs.corner_radius_top_left = 5
	bs.corner_radius_top_right = 5
	bs.corner_radius_bottom_left = 5
	bs.corner_radius_bottom_right = 5
	container.add_theme_stylebox_override("panel", bs)

	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", COLOR_ACTIVE_TEXT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	margin.add_child(lbl)
	container.add_child(margin)

	container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 10)
	btn.add_child(container)

func _get_initials() -> String:
	if GameManager.league.is_empty() or not GameManager.league.has("coach_name"):
		return "GM"
	var name = GameManager.league.coach_name
	var parts = name.split(" ", false)
	if parts.size() >= 2:
		return parts[0][0] + parts[1][0]
	return name.left(2).to_upper()

func _get_coach_name() -> String:
	if GameManager.league.is_empty() or not GameManager.league.has("coach_name"):
		return "General Manager"
	return GameManager.league.coach_name

func _get_team_name() -> String:
	if GameManager.league.is_empty() or not GameManager.league.has("user_team_name"):
		return "Meu Time"
	return GameManager.league.user_team_name

func _on_restart():
	menu_item_selected.emit("restart")

func set_active_tab(screen_name: String):
	for i in range(_nav_buttons.size()):
		var btn = _nav_buttons[i]
		var data = _nav_data[i]
		var is_active = data.screen == screen_name
		set_nav_style(btn, is_active)
		if is_active:
			btn.modulate = Color.WHITE
