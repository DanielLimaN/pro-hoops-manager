extends PanelContainer

signal cancel_pressed
signal save_pressed

const COL_BRAND := Color("#A78BFA")
const COL_BRAND_DEEP := Color("#7C3AED")
const COL_SUCCESS := Color("#10B981")
const COL_TEXT := Color("#FFFFFF")

func _ready():
	_build_banner()

func _build_banner():
	var s = StyleBoxFlat.new()
	var g = Gradient.new()
	g.set_color(0, COL_BRAND)
	g.set_color(1, COL_BRAND_DEEP)
	s.bg_color = COL_BRAND
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	s.shadow_color = Color("#A78BFA77")
	s.shadow_size = 24
	s.shadow_offset = Vector2(0, 4)
	add_theme_stylebox_override("panel", s)

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 12)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var l_hbox = HBoxContainer.new()
	l_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_hbox.add_theme_constant_override("separation", 10)

	var icon_container = PanelContainer.new()
	icon_container.custom_minimum_size = Vector2(24, 24)
	var icon_bg_style = StyleBoxFlat.new()
	icon_bg_style.bg_color = Color("#FFFFFF22")
	icon_bg_style.corner_radius_top_left = 6
	icon_bg_style.corner_radius_top_right = 6
	icon_bg_style.corner_radius_bottom_left = 6
	icon_bg_style.corner_radius_bottom_right = 6
	icon_container.add_theme_stylebox_override("panel", icon_bg_style)

	var icon = Label.new()
	icon.text = "⚡"
	icon.add_theme_font_size_override("font_size", 12)
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_container.add_child(icon)

	var info_vbox = VBoxContainer.new()
	info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	info_vbox.add_theme_constant_override("separation", 0)

	var title_lbl = Label.new()
	title_lbl.text = "EDITANDO ESCALAÇÃO"
	title_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", COL_TEXT)

	var sub_lbl = Label.new()
	sub_lbl.text = "Clique em uma posição do quinteto para substituir"
	sub_lbl.add_theme_font_size_override("font_size", 10)
	sub_lbl.add_theme_color_override("font_color", Color("#FFFFFFAA"))

	info_vbox.add_child(title_lbl)
	info_vbox.add_child(sub_lbl)

	l_hbox.add_child(icon_container)
	l_hbox.add_child(info_vbox)

	var r_hbox = HBoxContainer.new()
	r_hbox.add_theme_constant_override("separation", 8)

	var cancel_btn = PanelContainer.new()
	var cs = StyleBoxFlat.new()
	cs.bg_color = Color("#FFFFFF15")
	cs.corner_radius_top_left = 6
	cs.corner_radius_top_right = 6
	cs.corner_radius_bottom_left = 6
	cs.corner_radius_bottom_right = 6
	cs.border_color = Color("#FFFFFF55")
	cs.border_width_left = 1
	cs.border_width_top = 1
	cs.border_width_right = 1
	cs.border_width_bottom = 1
	cancel_btn.add_theme_stylebox_override("panel", cs)

	var cancel_margin = MarginContainer.new()
	cancel_margin.add_theme_constant_override("margin_left", 14)
	cancel_margin.add_theme_constant_override("margin_right", 14)
	cancel_margin.add_theme_constant_override("margin_top", 7)
	cancel_margin.add_theme_constant_override("margin_bottom", 7)

	var cancel_lbl = Label.new()
	cancel_lbl.text = "Cancelar"
	cancel_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	cancel_lbl.add_theme_font_size_override("font_size", 11)
	cancel_lbl.add_theme_color_override("font_color", COL_TEXT)

	cancel_margin.add_child(cancel_lbl)
	cancel_btn.add_child(cancel_margin)

	var cancel_click = Button.new()
	cancel_click.flat = true
	cancel_click.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cancel_click.mouse_filter = Control.MOUSE_FILTER_STOP
	cancel_click.pressed.connect(func(): cancel_pressed.emit())
	cancel_btn.add_child(cancel_click)

	var save_btn = PanelContainer.new()
	var ss = StyleBoxFlat.new()
	ss.bg_color = COL_SUCCESS
	ss.corner_radius_top_left = 6
	ss.corner_radius_top_right = 6
	ss.corner_radius_bottom_left = 6
	ss.corner_radius_bottom_right = 6
	save_btn.add_theme_stylebox_override("panel", ss)

	var save_margin = MarginContainer.new()
	save_margin.add_theme_constant_override("margin_left", 16)
	save_margin.add_theme_constant_override("margin_right", 16)
	save_margin.add_theme_constant_override("margin_top", 7)
	save_margin.add_theme_constant_override("margin_bottom", 7)

	var save_lbl = Label.new()
	save_lbl.text = "Salvar"
	save_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	save_lbl.add_theme_font_size_override("font_size", 11)
	save_lbl.add_theme_color_override("font_color", COL_TEXT)

	save_margin.add_child(save_lbl)
	save_btn.add_child(save_margin)

	var save_click = Button.new()
	save_click.flat = true
	save_click.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	save_click.mouse_filter = Control.MOUSE_FILTER_STOP
	save_click.pressed.connect(func(): save_pressed.emit())
	save_btn.add_child(save_click)

	r_hbox.add_child(cancel_btn)
	r_hbox.add_child(save_btn)

	hbox.add_child(l_hbox)
	hbox.add_child(r_hbox)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_child(hbox)
	add_child(margin)
