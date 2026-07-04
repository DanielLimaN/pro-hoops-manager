extends PanelContainer

signal action_selected(action_id: String)
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
const COL_BORDER := Color("#1F1432")
const COL_BRAND := Color("#A78BFA")
const COL_BRAND_DEEP := Color("#7C3AED")
const COL_SUCCESS := Color("#10B981")
const COL_WARNING := Color("#FBBF24")
const COL_WARNING_DARK := Color("#F59E0B")
const COL_TEXT := Color("#FFFFFF")
const COL_TEXT_MUTED := Color("#94A3B8")
const COL_TEXT_DISABLED := Color("#6B5B95")
const COL_SURFACE_ALT := Color("#150826")

var player_data: Dictionary = {} : set = _set_player_data

func _set_player_data(d: Dictionary):
	player_data = d
	if is_node_ready():
		_refresh()

func _ready():
	_build_popover()
	_refresh()

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
	_build_actions(vbox)

func _build_header(parent: VBoxContainer):
	var header = PanelContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hs = StyleBoxFlat.new()
	var g = Gradient.new()
	g.set_color(0, COL_WARNING)
	g.set_color(1, COL_WARNING_DARK)
	var g2d = GradientTexture2D.new()
	g2d.gradient = g
	g2d.fill_from = Vector2(0, 0)
	g2d.fill_to = Vector2(1, 0)
	hs.bg_color = COL_WARNING
	header.add_theme_stylebox_override("panel", hs)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var avatar = PanelContainer.new()
	avatar.custom_minimum_size = Vector2(28, 28)
	var avs = StyleBoxFlat.new()
	avs.bg_color = COL_BRAND
	avs.corner_radius_top_left = 14
	avs.corner_radius_top_right = 14
	avs.corner_radius_bottom_left = 14
	avs.corner_radius_bottom_right = 14
	avs.border_color = Color("#0B0514")
	avs.border_width_left = 2
	avs.border_width_top = 2
	avs.border_width_right = 2
	avs.border_width_bottom = 2
	avatar.add_theme_stylebox_override("panel", avs)

	var init_lbl = Label.new()
	init_lbl.name = "AvatarInitials"
	init_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	init_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	init_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	init_lbl.add_theme_font_size_override("font_size", 10)
	init_lbl.add_theme_color_override("font_color", COL_TEXT)
	init_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	init_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(init_lbl)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	info_vbox.add_theme_constant_override("separation", 0)

	var name_lbl = Label.new()
	name_lbl.name = "PlayerName"
	name_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(0, 0, 0, 1))

	var pos_lbl = Label.new()
	pos_lbl.name = "PlayerPos"
	pos_lbl.add_theme_font_size_override("font_size", 10)
	pos_lbl.add_theme_color_override("font_color", Color(0, 0, 0, 0.6))

	info_vbox.add_child(name_lbl)
	info_vbox.add_child(pos_lbl)

	var close_container = Control.new()
	close_container.custom_minimum_size = Vector2(20, 20)

	var close_bg = PanelContainer.new()
	close_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cs = StyleBoxFlat.new()
	cs.bg_color = Color("#0B051488")
	cs.corner_radius_top_left = 10
	cs.corner_radius_top_right = 10
	cs.corner_radius_bottom_left = 10
	cs.corner_radius_bottom_right = 10
	close_bg.add_theme_stylebox_override("panel", cs)

	var close_lbl = Label.new()
	close_lbl.text = "×"
	close_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	close_lbl.add_theme_font_size_override("font_size", 14)
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

	hbox.add_child(avatar)
	hbox.add_child(info_vbox)
	hbox.add_child(close_container)
	margin.add_child(hbox)
	header.add_child(margin)
	parent.add_child(header)

func _build_actions(parent: VBoxContainer):
	var actions = [
		{id = "view_profile", label = "Ver Perfil Completo", highlight = false},
		{id = "renew_contract", label = "Renovar Contrato", highlight = true},
		{id = "individual_program", label = "Programa Individual", highlight = false},
		{id = "talk", label = "Conversar", highlight = false},
		{id = "", label = "", highlight = false, divider = true},
		{id = "list_for_sale", label = "Listar para Venda", highlight = false},
		{id = "release", label = "Dispensar Jogador", highlight = false},
	]

	var list_margin = MarginContainer.new()
	list_margin.add_theme_constant_override("margin_left", 8)
	list_margin.add_theme_constant_override("margin_right", 8)
	list_margin.add_theme_constant_override("margin_top", 8)
	list_margin.add_theme_constant_override("margin_bottom", 8)

	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 2)

	for a in actions:
		if a.get("divider", false):
			var div = ColorRect.new()
			div.custom_minimum_size = Vector2(0, 1)
			div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			div.color = COL_BORDER
			div.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var div_margin = MarginContainer.new()
			div_margin.add_theme_constant_override("margin_top", 4)
			div_margin.add_theme_constant_override("margin_bottom", 4)
			div_margin.add_child(div)
			list_vbox.add_child(div_margin)
		else:
			list_vbox.add_child(_make_action_row(a.id, a.label, a.highlight))

	list_margin.add_child(list_vbox)
	parent.add_child(list_margin)

func _make_action_row(action_id: String, label: String, highlight: bool) -> PanelContainer:
	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var s = StyleBoxFlat.new()
	if highlight:
		s.bg_color = Color("#10B98122")
		s.border_color = COL_SUCCESS
		s.border_width_left = 1
		s.border_width_top = 1
		s.border_width_right = 1
		s.border_width_bottom = 1
	else:
		s.bg_color = Color.TRANSPARENT
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	row.add_theme_stylebox_override("panel", s)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl = Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", COL_TEXT_MUTED if not highlight else COL_SUCCESS)

	hbox.add_child(lbl)
	row.add_child(hbox)

	var click = Button.new()
	click.flat = true
	click.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	click.mouse_filter = Control.MOUSE_FILTER_STOP
	click.pressed.connect(func(): action_selected.emit(action_id))
	row.add_child(click)

	return row

func _refresh():
	var init_lbl = find_child("AvatarInitials", true, false)
	if init_lbl:
		var name = _player_name(player_data)
		var parts = name.split(" ", false)
		init_lbl.text = (parts[0][0] + parts[1][0]) if parts.size() >= 2 else name[0]

	var name_lbl = find_child("PlayerName", true, false)
	if name_lbl:
		name_lbl.text = _player_name(player_data, "Jogador")

	var pos_lbl = find_child("PlayerPos", true, false)
	if pos_lbl:
		pos_lbl.text = player_data.get("pos", "PG") + " · " + str(player_data.get("ovr", 50)) + " OVR"
