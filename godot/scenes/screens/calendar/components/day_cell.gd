extends PanelContainer
class_name DayCell

enum DayState { NORMAL, TODAY, PAST, DIM, GAME_DAY, SELECTED, SIMULATED }

signal clicked(day_number, events)

@export var day_number: int = 1
@export var state: DayState = DayState.NORMAL
var cell_events: Array = []

@onready var num_lbl = $Margin/VBox/NumLbl
@onready var match_container = $Margin/VBox/MatchContainer

const EVENT_COLORS = {
	"match": Color("#A78BFA"),
	"training_physical": Color("#EF4444"),
	"training_tactical": Color("#3B82F6"),
	"recovery": Color("#10B981"),
	"interview": Color("#F472B6"),
	"press_conference": Color("#A78BFA"),
	"meeting": Color("#06B6D4"),
	"rest": Color("#64748B"),
}

const EVENT_ICONS = {
	"match": "basketball",
	"training_physical": "weight",
	"training_tactical": "clipboard",
	"recovery": "leaf",
	"interview": "microphone",
	"press_conference": "script",
	"meeting": "human",
	"rest": "moon",
}

const EVENT_LABELS = {
	"training_physical": "Físico",
	"training_tactical": "Tático",
	"recovery": "Recuperação",
	"interview": "Entrevista",
	"press_conference": "Coletiva",
	"meeting": "Diretoria",
	"rest": "Descanso",
}

var header_hbox: HBoxContainer
var today_badge: PanelContainer
var today_badge_lbl: Label

func _ready():
	gui_input.connect(_on_gui_input)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox = $Margin/VBox
	var num_idx = num_lbl.get_index()

	header_hbox = HBoxContainer.new()
	header_hbox.name = "HeaderRow"
	header_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_theme_constant_override("separation", 6)

	vbox.remove_child(num_lbl)
	header_hbox.add_child(num_lbl)

	var spacer = Control.new()
	spacer.name = "HeaderSpacer"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)

	today_badge = PanelContainer.new()
	today_badge.name = "TodayBadge"
	var tb_style = StyleBoxFlat.new()
	tb_style.bg_color = Color("#A78BFA")
	tb_style.corner_radius_top_left = 3
	tb_style.corner_radius_top_right = 3
	tb_style.corner_radius_bottom_left = 3
	tb_style.corner_radius_bottom_right = 3
	tb_style.content_margin_left = 6
	tb_style.content_margin_right = 6
	tb_style.content_margin_top = 2
	tb_style.content_margin_bottom = 2
	today_badge.add_theme_stylebox_override("panel", tb_style)

	today_badge_lbl = Label.new()
	today_badge_lbl.text = "HOJE"
	today_badge_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	today_badge_lbl.add_theme_font_size_override("font_size", 9)
	today_badge_lbl.add_theme_color_override("font_color", Color("#0B0514"))
	today_badge_lbl.add_theme_constant_override("letter_spacing", 0.5)
	today_badge.add_child(today_badge_lbl)
	today_badge.hide()
	header_hbox.add_child(today_badge)

	vbox.add_child(header_hbox)
	vbox.move_child(header_hbox, num_idx)

	update_visuals()

func setup(day: int, s: DayState, events: Array = []):
	day_number = day
	state = s
	cell_events = events
	if is_inside_tree():
		update_visuals()

func setup_from_event(event_data: Dictionary):
	if event_data == null or event_data.is_empty(): return
	var has_match = event_data.has("match") and event_data.match != null
	var is_simulating = event_data.has("is_simulating") and event_data.is_simulating
	if has_match:
		state = DayState.GAME_DAY
	elif is_simulating:
		state = DayState.SIMULATED
	if is_inside_tree():
		update_visuals()

func update_visuals():
	if not is_inside_tree(): return
	num_lbl.text = str(day_number)
	num_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
	num_lbl.add_theme_font_size_override("font_size", 12)

	var style = StyleBoxFlat.new()
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_color = Color("#1F1432")

	if state == DayState.DIM:
		style.bg_color = Color("#06030E")
		num_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
	elif state == DayState.TODAY:
		style.bg_color = Color("#A78BFA15")
		num_lbl.add_theme_color_override("font_color", Color("#A78BFA"))
		today_badge.show()
	elif state == DayState.PAST:
		style.bg_color = Color("#0F0720")
		num_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
	else:
		style.bg_color = Color("#0F0720")
		num_lbl.add_theme_color_override("font_color", Color("#94A3B8"))

	add_theme_stylebox_override("panel", style)

	if state != DayState.TODAY:
		if is_instance_valid(today_badge):
			today_badge.hide()

	for c in match_container.get_children():
		c.queue_free()

	for evt in cell_events:
		var etype = evt.get("event_type", "")
		if etype == "match":
			_render_match_badge(evt)
		elif EVENT_COLORS.has(etype):
			_render_event_badge(evt, etype)

func _render_event_badge(evt: Dictionary, etype: String):
	var color = EVENT_COLORS[etype]
	var icon_name = EVENT_ICONS.get(etype, "circle")
	var label = evt.get("description", EVENT_LABELS.get(etype, etype))
	var hour = evt.get("hour", 9)
	var minute = evt.get("minute", 0)
	var time_str = "%02dh" % hour if minute == 0 else "%02dh%02d" % [hour, minute]
	if etype == "rest":
		time_str = "—"

	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(color.r, color.g, color.b, 0.094)
	card_style.corner_radius_top_left = 4
	card_style.corner_radius_top_right = 4
	card_style.corner_radius_bottom_left = 4
	card_style.corner_radius_bottom_right = 4
	card_style.border_width_left = 2
	card_style.border_color = color
	card.add_theme_stylebox_override("panel", card_style)

	var pad = MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_top", 10)
	pad.add_theme_constant_override("margin_bottom", 10)
	card.add_child(pad)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	pad.add_child(vb)

	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var icon_path = "res://addons/at-icons/control/" + icon_name + ".svg"
	if ResourceLoader.exists(icon_path):
		var icon_tex = TextureRect.new()
		icon_tex.texture = load(icon_path)
		icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_tex.custom_minimum_size = Vector2(16, 16)
		icon_tex.modulate = color
		top.add_child(icon_tex)

	var time_lbl = Label.new()
	time_lbl.text = time_str
	time_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
	time_lbl.add_theme_font_size_override("font_size", 12)
	time_lbl.add_theme_color_override("font_color", Color("#6B5B95"))
	top.add_child(time_lbl)
	vb.add_child(top)

	var name_lbl = Label.new()
	name_lbl.text = label
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_constant_override("line_spacing", -2)
	vb.add_child(name_lbl)

	match_container.add_child(card)

func _render_match_badge(evt: Dictionary):
	var is_playoff = evt.get("is_playoff", false)
	var home_id = evt.get("home_team_id", 0)
	var away_id = evt.get("away_team_id", 0)
	var is_home = home_id == GameManager.user_team_id
	var opp_id = away_id if is_home else home_id
	var opp = "???"
	var teams = GameManager.league.get("teams", [])
	for t in teams:
		if t.get("id") == opp_id:
			opp = t.get("abbreviation", "???")
			break

	var hour = evt.get("hour", 20)
	var minute = evt.get("minute", 0)
	var time_str = "%02dh%02d" % [hour, minute]
	var comp_label = "LIGA"
	var comp_color = ThemeConfig.INFO
	if is_playoff:
		comp_label = "PLAYOFF"
		comp_color = ThemeConfig.DANGER
	elif evt.get("competition", "") == "cup":
		comp_label = "COPA"
		comp_color = Color("#FBBF24")

	var played = evt.get("is_completed", false)
	var won = false
	var h_score = 0
	var a_score = 0
	if played:
		var game_id = evt.get("game_id", 0)
		if game_id > 0:
			var sched = GameManager.get_schedule()
			for g in sched:
				if g.get("id", 0) == game_id:
					h_score = g.get("home_score", 0)
					a_score = g.get("away_score", 0)
					break
		var us = h_score if is_home else a_score
		var them = a_score if is_home else h_score
		won = us > them

	var mc = PanelContainer.new()
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var ms = StyleBoxFlat.new()
	if played and won:
		ms.bg_color = Color("#10B98122")
		ms.border_color = Color("#10B981")
	elif played:
		ms.bg_color = Color("#EF444422")
		ms.border_color = Color("#EF4444")
	else:
		ms.bg_color = Color("#A78BFA28")
		ms.border_color = Color("#A78BFA")
	ms.border_width_left = 1; ms.border_width_right = 1; ms.border_width_top = 1; ms.border_width_bottom = 1
	ms.corner_radius_top_left = 5; ms.corner_radius_top_right = 5; ms.corner_radius_bottom_left = 5; ms.corner_radius_bottom_right = 5
	mc.add_theme_stylebox_override("panel", ms)

	var mm = MarginContainer.new()
	mm.add_theme_constant_override("margin_left", 12)
	mm.add_theme_constant_override("margin_right", 12)
	mm.add_theme_constant_override("margin_top", 12)
	mm.add_theme_constant_override("margin_bottom", 12)
	mc.add_child(mm)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	mm.add_child(vb)

	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var tm = Label.new()
	tm.text = time_str
	tm.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
	tm.add_theme_font_size_override("font_size", 13)
	tm.add_theme_color_override("font_color", Color("#6B5B95"))
	top.add_child(tm)

	var st = Control.new()
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(st)

	var tp = PanelContainer.new()
	var tps = StyleBoxFlat.new()
	tps.bg_color = Color(comp_color.r, comp_color.g, comp_color.b, 0.133)
	tps.corner_radius_top_left = 2; tps.corner_radius_top_right = 2; tps.corner_radius_bottom_left = 2; tps.corner_radius_bottom_right = 2
	tp.add_theme_stylebox_override("panel", tps)
	var tl = Label.new()
	tl.text = comp_label
	tl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	tl.add_theme_font_size_override("font_size", 10)
	tl.add_theme_color_override("font_color", comp_color)
	tl.add_theme_constant_override("letter_spacing", 0.3)
	var tlm = MarginContainer.new()
	tlm.add_theme_constant_override("margin_left", 4)
	tlm.add_theme_constant_override("margin_right", 4)
	tlm.add_child(tl)
	tp.add_child(tlm)
	top.add_child(tp)
	vb.add_child(top)

	var teams_row = HBoxContainer.new()
	teams_row.add_theme_constant_override("separation", 4)
	teams_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var ha = Label.new()
	ha.text = "vs" if is_home else "@"
	ha.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
	ha.add_theme_font_size_override("font_size", 12)
	ha.add_theme_color_override("font_color", Color("#6B5B95"))
	teams_row.add_child(ha)

	var team = Label.new()
	team.text = opp
	team.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	team.add_theme_font_size_override("font_size", 15)
	team.add_theme_color_override("font_color", Color.WHITE)
	teams_row.add_child(team)
	vb.add_child(teams_row)

	if played:
		var sc = Label.new()
		sc.text = str(h_score) + "-" + str(a_score)
		sc.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
		sc.add_theme_font_size_override("font_size", 15)
		sc.add_theme_color_override("font_color", Color("#10B981") if won else Color("#EF4444"))
		vb.add_child(sc)

	match_container.add_child(mc)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked", day_number, cell_events)
