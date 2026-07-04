extends PanelContainer

signal candidate_selected(player_idx: int)
signal closed

static func _player_name(d: Dictionary, fallback: String = "?") -> String:
	if d.has("name") and not d.get("name", "").is_empty():
		return d.get("name")
	var first = d.get("first_name", "")
	var last = d.get("last_name", "")
	if first.is_empty() and last.is_empty():
		return fallback
	return (first + " " + last).strip_edges()

const COL_SURFACE := Color("#0F0720")
const COL_SURFACE_ALT := Color("#150826")
const COL_BORDER := Color("#1F1432")
const COL_BORDER_DEFAULT := Color("#2D1B4E")
const COL_BRAND := Color("#A78BFA")
const COL_BRAND_DEEP := Color("#7C3AED")
const COL_SUCCESS := Color("#10B981")
const COL_WARNING := Color("#FBBF24")
const COL_WARNING_DARK := Color("#F59E0B")
const COL_TEXT := Color("#FFFFFF")
const COL_TEXT_MUTED := Color("#94A3B8")
const COL_TEXT_DISABLED := Color("#6B5B95")

var position_name: String = ""
var current_starter: Dictionary = {}
var candidates: Array = []
var selected_idx: int = -1

func _ready():
	_build_popover()

func _build_popover():
	var s = StyleBoxFlat.new()
	s.bg_color = COL_SURFACE
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	s.border_color = COL_WARNING
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.shadow_color = Color(0, 0, 0, 0.8)
	s.shadow_size = 32
	add_theme_stylebox_override("panel", s)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 0)
	vbox.clip_contents = true
	add_child(vbox)

	_build_header(vbox)
	_build_info(vbox)
	_build_candidates(vbox)

func _build_header(parent: VBoxContainer):
	var header = PanelContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hs = StyleBoxFlat.new()
	hs.bg_color = COL_WARNING
	header.add_theme_stylebox_override("panel", hs)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var l_box = HBoxContainer.new()
	l_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_box.add_theme_constant_override("separation", 6)
	l_box.alignment = BoxContainer.ALIGNMENT_CENTER

	var pos_lbl = Label.new()
	pos_lbl.text = position_name
	pos_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	pos_lbl.add_theme_font_size_override("font_size", 13)
	pos_lbl.add_theme_color_override("font_color", Color(0, 0, 0, 1))

	var starter_lbl = Label.new()
	starter_lbl.text = _player_name(current_starter, "Vago")
	starter_lbl.add_theme_font_size_override("font_size", 10)
	starter_lbl.add_theme_color_override("font_color", Color(0, 0, 0, 0.6))

	l_box.add_child(pos_lbl)
	l_box.add_child(starter_lbl)

	var close_container = Control.new()
	close_container.custom_minimum_size = Vector2(18, 18)

	var close_bg = PanelContainer.new()
	close_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cs = StyleBoxFlat.new()
	cs.bg_color = Color("#0B051488")
	cs.corner_radius_top_left = 9
	cs.corner_radius_top_right = 9
	cs.corner_radius_bottom_left = 9
	cs.corner_radius_bottom_right = 9
	close_bg.add_theme_stylebox_override("panel", cs)

	var close_lbl = Label.new()
	close_lbl.text = "×"
	close_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	close_lbl.add_theme_font_size_override("font_size", 12)
	close_lbl.add_theme_color_override("font_color", COL_TEXT)
	close_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	close_bg.add_child(close_lbl)
	close_container.add_child(close_bg)

	var close_click = Button.new()
	close_click.flat = true
	close_click.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	close_click.mouse_filter = Control.MOUSE_FILTER_STOP
	close_click.pressed.connect(func(): closed.emit())
	close_container.add_child(close_click)

	hbox.add_child(l_box)
	hbox.add_child(close_container)
	margin.add_child(hbox)
	header.add_child(margin)
	parent.add_child(header)

func _build_info(parent: VBoxContainer):
	var info = PanelContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var info_style = StyleBoxFlat.new()
	info_style.bg_color = COL_SURFACE_ALT
	info_style.border_color = COL_BORDER
	info_style.border_width_bottom = 1
	info.add_theme_stylebox_override("panel", info_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)

	var label = Label.new()
	label.text = "TITULAR ATUAL"
	label.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", COL_TEXT_DISABLED)
	label.add_theme_constant_override("letter_spacing", 1)

	var starter_hbox = HBoxContainer.new()
	starter_hbox.add_theme_constant_override("separation", 8)
	starter_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var init_circle = PanelContainer.new()
	init_circle.custom_minimum_size = Vector2(20, 20)
	var init_s = StyleBoxFlat.new()
	init_s.bg_color = COL_BRAND_DEEP
	init_s.corner_radius_top_left = 10
	init_s.corner_radius_top_right = 10
	init_s.corner_radius_bottom_left = 10
	init_s.corner_radius_bottom_right = 10
	init_circle.add_theme_stylebox_override("panel", init_s)

	var init_lbl = Label.new()
	var name = _player_name(current_starter)
	var parts = name.split(" ", false)
	init_lbl.text = (parts[0][0] + parts[1][0]) if parts.size() >= 2 else name[0]
	init_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	init_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	init_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	init_lbl.add_theme_font_size_override("font_size", 8)
	init_lbl.add_theme_color_override("font_color", COL_TEXT)
	init_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	init_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	init_circle.add_child(init_lbl)

	var name_lbl = Label.new()
	name_lbl.text = _player_name(current_starter, "Vago")
	name_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", COL_TEXT)

	var ovr_lbl = Label.new()
	ovr_lbl.text = str(current_starter.get("ovr", 0)) + " OVR"
	ovr_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	ovr_lbl.add_theme_font_size_override("font_size", 10)
	ovr_lbl.add_theme_color_override("font_color", COL_TEXT_MUTED)

	starter_hbox.add_child(init_circle)
	starter_hbox.add_child(name_lbl)
	starter_hbox.add_child(ovr_lbl)

	vbox.add_child(label)
	vbox.add_child(starter_hbox)
	margin.add_child(vbox)
	info.add_child(margin)
	parent.add_child(info)

func _build_candidates(parent: VBoxContainer):
	var candidates_container = VBoxContainer.new()
	candidates_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	candidates_container.add_theme_constant_override("separation", 4)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)

	var inner = VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 4)

	var section_label = Label.new()
	section_label.text = "CANDIDATOS DISPONÍVEIS"
	section_label.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
	section_label.add_theme_font_size_override("font_size", 8)
	section_label.add_theme_color_override("font_color", COL_BRAND)
	section_label.add_theme_constant_override("letter_spacing", 1.5)
	inner.add_child(section_label)

	for i in range(candidates.size()):
		var c = candidates[i]
		inner.add_child(_make_candidate_row(c, i))

	margin.add_child(inner)
	candidates_container.add_child(margin)
	parent.add_child(candidates_container)

func _make_candidate_row(data: Dictionary, idx: int) -> PanelContainer:
	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var is_selected = idx == selected_idx
	var s = StyleBoxFlat.new()
	if is_selected:
		s.bg_color = Color("#10B98122")
		s.border_color = COL_SUCCESS
	else:
		s.bg_color = COL_SURFACE_ALT
		s.border_color = COL_BORDER_DEFAULT
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", s)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var init_circle = PanelContainer.new()
	init_circle.custom_minimum_size = Vector2(20, 20)
	var init_s = StyleBoxFlat.new()
	init_s.bg_color = COL_BRAND_DEEP
	init_s.corner_radius_top_left = 10
	init_s.corner_radius_top_right = 10
	init_s.corner_radius_bottom_left = 10
	init_s.corner_radius_bottom_right = 10
	init_circle.add_theme_stylebox_override("panel", init_s)

	var init_lbl = Label.new()
	var name = _player_name(data)
	var parts = name.split(" ", false)
	init_lbl.text = (parts[0][0] + parts[1][0]) if parts.size() >= 2 else name[0]
	init_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	init_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	init_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	init_lbl.add_theme_font_size_override("font_size", 8)
	init_lbl.add_theme_color_override("font_color", COL_TEXT)
	init_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	init_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	init_circle.add_child(init_lbl)

	var name_vbox = VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	name_vbox.add_theme_constant_override("separation", 0)

	var name_lbl = Label.new()
	name_lbl.text = _player_name(data, "Jogador")
	name_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", COL_TEXT)

	var detail_lbl = Label.new()
	detail_lbl.text = data.get("pos", "") + " · " + str(data.get("ovr", 0)) + " OVR"
	detail_lbl.add_theme_font_size_override("font_size", 9)
	detail_lbl.add_theme_color_override("font_color", COL_TEXT_MUTED)

	name_vbox.add_child(name_lbl)
	name_vbox.add_child(detail_lbl)

	var check = Label.new()
	check.text = "✓" if is_selected else ""
	check.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	check.add_theme_font_size_override("font_size", 14)
	check.add_theme_color_override("font_color", COL_SUCCESS if is_selected else Color.TRANSPARENT)
	check.custom_minimum_size = Vector2(20, 0)
	check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	hbox.add_child(init_circle)
	hbox.add_child(name_vbox)
	hbox.add_child(check)
	row.add_child(hbox)

	var click = Button.new()
	click.flat = true
	click.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	click.mouse_filter = Control.MOUSE_FILTER_STOP
	click.pressed.connect(func():
		candidate_selected.emit(idx)
	)
	row.add_child(click)

	return row
