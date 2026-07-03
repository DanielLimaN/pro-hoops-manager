extends Control

func _ready():
	for c in get_children():
		c.queue_free()
		
	var bg = ColorRect.new()
	bg.color = ThemeConfig.BG_APP
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.theme_type_variation = "ScreenMargin"
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.theme_type_variation = "ScreenVBox"
	margin.add_child(vbox)
	
	_build_top_bar(vbox)
	_build_tabs(vbox)
	_build_kpis(vbox)
	
	var content = HBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 24)
	vbox.add_child(content)
	
	_build_left_col(content)
	_build_center_col(content)
	_build_right_col(content)

func _build_top_bar(parent: Node):
	var topbar_scene = preload("res://scenes/components/topbar.tscn")
	var tb = topbar_scene.instantiate()
	tb.screen_title = "TREINOS"
	parent.add_child(tb)

func _create_kpi_badge(title: String, val: String, color: Color, icon: String) -> PanelContainer:
	var p = PanelContainer.new()
	var s = StyleBoxFlat.new(); s.bg_color = Color(0,0,0,0); s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = ThemeConfig.BORDER_SUBTLE; s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8
	p.add_theme_stylebox_override("panel", s)
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 12)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 16); m.add_theme_constant_override("margin_right", 16); m.add_theme_constant_override("margin_top", 8); m.add_theme_constant_override("margin_bottom", 8); m.add_child(h); p.add_child(m)
	var l_icon = Label.new(); l_icon.text = icon; l_icon.add_theme_color_override("font_color", color); l_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; h.add_child(l_icon)
	var vb = VBoxContainer.new(); vb.alignment = BoxContainer.ALIGNMENT_CENTER
	var l_title = Label.new(); l_title.text = title; l_title.add_theme_font_size_override("font_size", 8); l_title.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); l_title.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); vb.add_child(l_title)
	var l_val = Label.new(); l_val.text = val; l_val.add_theme_font_size_override("font_size", 14); l_val.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); vb.add_child(l_val)
	h.add_child(vb)
	return p

func _build_tabs(parent: Node):
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 32)
	
	var tabs = ["CRONOGRAMA", "DESENVOLVIMENTO", "INDIVIDUAL", "RECUPERAÇÃO"]
	var tab_box = HBoxContainer.new()
	tab_box.add_theme_constant_override("separation", 8)
	for i in range(tabs.size()):
		var b = Button.new()
		b.text = tabs[i]
		b.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		b.add_theme_font_size_override("font_size", 12)
		var s = StyleBoxFlat.new(); s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8; s.content_margin_left=16; s.content_margin_right=16; s.content_margin_top=8; s.content_margin_bottom=8
		if i == 0:
			b.icon = load("res://addons/at-icons/control/calendar.svg")
			b.add_theme_constant_override("h_separation", 8)
			s.bg_color = ThemeConfig.BRAND_PRIMARY; s.border_width_bottom=0
			b.add_theme_color_override("font_color", Color.WHITE)
			b.add_theme_color_override("icon_normal_color", Color.WHITE)
		else:
			if i == 1: b.icon = load("res://addons/at-icons/control/arrow_up_right.svg")
			elif i == 2: b.text = "@ " + b.text
			elif i == 3: b.icon = load("res://addons/at-icons/control/heart.svg")
			b.add_theme_constant_override("h_separation", 8)
			s.bg_color = Color(0,0,0,0); s.border_width_bottom=0
			b.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
			b.add_theme_color_override("icon_normal_color", ThemeConfig.TEXT_MUTED)
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", s)
		tab_box.add_child(b)
	
	h.add_child(tab_box)
	
	var space = Control.new(); space.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(space)
	
	var focus_box = HBoxContainer.new(); focus_box.add_theme_constant_override("separation", 6); focus_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var focus_l = Label.new(); focus_l.text = "FOCO:"; focus_l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); focus_l.add_theme_font_size_override("font_size", 10); focus_l.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); focus_l.add_theme_constant_override("letter_spacing", 1); focus_box.add_child(focus_l)
	
	var current_focus = GameManager.get_training_focus()
	var focus_opts = ["Shooting", "Defense", "Playmaking", "Physical", "Balanced"]
	var focus_colors = [ThemeConfig.BRAND_PRIMARY, ThemeConfig.DANGER, Color("#3B82F6"), ThemeConfig.WARNING, Color.WHITE]
	for fi in range(focus_opts.size()):
		var fb = _create_focus_btn(focus_opts[fi], focus_colors[fi % focus_colors.size()], focus_opts[fi] == current_focus)
		focus_box.add_child(fb)
	h.add_child(focus_box)
	
	var sep_v1 = VSeparator.new(); h.add_child(sep_v1)
	
	var int_box = HBoxContainer.new(); int_box.add_theme_constant_override("separation", 8); int_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var int_l = Label.new(); int_l.text = "INTENSIDADE:"; int_l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); int_l.add_theme_font_size_override("font_size", 10); int_l.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); int_l.add_theme_constant_override("letter_spacing", 1); int_box.add_child(int_l)
	
	int_box.add_child(_create_int_btn("BAIXA", ThemeConfig.SUCCESS, false))
	int_box.add_child(_create_int_btn("MÉDIA", ThemeConfig.WARNING, true))
	int_box.add_child(_create_int_btn("ALTA", ThemeConfig.DANGER, false))
	h.add_child(int_box)
	
	var sep_v = VSeparator.new(); h.add_child(sep_v)
	
	var btn_gen = Button.new(); btn_gen.text = "GERAR COM IA"; btn_gen.icon = load("res://addons/at-icons/control/magic_wand.svg"); btn_gen.add_theme_constant_override("h_separation", 8); btn_gen.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); btn_gen.add_theme_font_size_override("font_size", 12)
	var sg = StyleBoxFlat.new(); sg.bg_color = Color(0,0,0,0); sg.border_width_left=1; sg.border_width_right=1; sg.border_width_top=1; sg.border_width_bottom=1; sg.border_color = ThemeConfig.BRAND_PRIMARY; sg.corner_radius_top_left=8; sg.corner_radius_bottom_right=8; sg.corner_radius_bottom_left=8; sg.corner_radius_top_right=8; sg.content_margin_left=16; sg.content_margin_right=16
	btn_gen.add_theme_stylebox_override("normal", sg)
	btn_gen.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
	h.add_child(btn_gen)
	
	parent.add_child(h)

func _create_focus_btn(text: String, color: Color, active: bool) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	b.add_theme_font_size_override("font_size", 10)
	var s = StyleBoxFlat.new()
	if active:
		s.bg_color = color
		s.border_width_bottom = 0
		b.add_theme_color_override("font_color", Color.WHITE)
	else:
		s.bg_color = Color(0,0,0,0)
		s.border_width_left = 1; s.border_width_right = 1; s.border_width_top = 1; s.border_width_bottom = 1
		s.border_color = color
		b.add_theme_color_override("font_color", color)
	s.corner_radius_top_left = 6; s.corner_radius_bottom_right = 6; s.corner_radius_bottom_left = 6; s.corner_radius_top_right = 6
	s.content_margin_left = 12; s.content_margin_right = 12; s.content_margin_top = 6; s.content_margin_bottom = 6
	b.add_theme_stylebox_override("normal", s)
	b.add_theme_stylebox_override("hover", s)
	b.pressed.connect(func():
		GameManager.set_training_focus(text)
		# Refresh UI to show new active state
		for child in b.get_parent().get_children():
			if child is Button and child != b.get_parent().get_child(0):
				var cs = StyleBoxFlat.new()
				cs.bg_color = Color(0,0,0,0)
				cs.corner_radius_top_left = 6; cs.corner_radius_bottom_right = 6
				cs.corner_radius_bottom_left = 6; cs.corner_radius_top_right = 6
				cs.content_margin_left = 12; cs.content_margin_right = 12
				cs.content_margin_top = 6; cs.content_margin_bottom = 6
				cs.border_width_left = 1; cs.border_width_right = 1
				cs.border_width_top = 1; cs.border_width_bottom = 1
				cs.border_color = color
				child.add_theme_stylebox_override("normal", cs)
				child.add_theme_color_override("font_color", color)
		var act_s = StyleBoxFlat.new()
		act_s.bg_color = color
		act_s.corner_radius_top_left = 6; act_s.corner_radius_bottom_right = 6
		act_s.corner_radius_bottom_left = 6; act_s.corner_radius_top_right = 6
		act_s.content_margin_left = 12; act_s.content_margin_right = 12
		act_s.content_margin_top = 6; act_s.content_margin_bottom = 6
		b.add_theme_stylebox_override("normal", act_s)
		b.add_theme_color_override("font_color", Color.WHITE)
	)
	return b

func _create_int_btn(text: String, color: Color, active: bool) -> PanelContainer:
	var p = PanelContainer.new()
	var s = StyleBoxFlat.new(); s.bg_color = color if active else Color(0,0,0,0); s.corner_radius_top_left=4; s.corner_radius_bottom_right=4; s.corner_radius_bottom_left=4; s.corner_radius_top_right=4; s.border_width_left=1 if not active else 0; s.border_width_right=1 if not active else 0; s.border_width_top=1 if not active else 0; s.border_width_bottom=1 if not active else 0; s.border_color = ThemeConfig.BORDER_SUBTLE
	p.add_theme_stylebox_override("panel", s)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 8); m.add_theme_constant_override("margin_right", 8); m.add_theme_constant_override("margin_top", 4); m.add_theme_constant_override("margin_bottom", 4); p.add_child(m)
	var l = Label.new(); l.text = text; l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); l.add_theme_font_size_override("font_size", 10); l.add_theme_color_override("font_color", Color("#06030E") if active else color); m.add_child(l)
	return p

func _build_kpis(parent: Node):
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	
	h.add_child(_create_stat_card("CARGA SEMANAL", "68", ThemeConfig.WARNING, "clock", "/100"))
	h.add_child(_create_stat_card("RISCO LESÃO", "12", ThemeConfig.SUCCESS, "#", "%"))
	h.add_child(_create_stat_card("FORMA MÉDIA", "82", ThemeConfig.BRAND_PRIMARY, "arrow_up_right", "/100"))
	h.add_child(_create_stat_card("SESSÕES", "11", Color("#3B82F6"), "calendar", "/14 sem."))
	
	parent.add_child(h)

func _create_stat_card(title: String, val: String, color: Color, icon: String, suf_text: String) -> PanelContainer:
	var p = PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s = StyleBoxFlat.new(); s.bg_color = ThemeConfig.BG_SURFACE; s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8; s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = ThemeConfig.BORDER_SUBTLE
	p.add_theme_stylebox_override("panel", s)
	
	var bg_grad = TextureRect.new(); var g2d = GradientTexture2D.new(); var g = Gradient.new(); g.set_color(0, Color(color.r, color.g, color.b, 0.1)); g.set_color(1, Color(0,0,0,0)); g2d.gradient = g; g2d.fill_from = Vector2(0.5, 0); g2d.fill_to = Vector2(0.5, 0.6); bg_grad.texture = g2d; bg_grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg_grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); p.add_child(bg_grad)
	
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 16); m.add_theme_constant_override("margin_right", 16); m.add_theme_constant_override("margin_top", 12); m.add_theme_constant_override("margin_bottom", 12); p.add_child(m)
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", 8); m.add_child(v)
	
	var htop = HBoxContainer.new(); htop.add_theme_constant_override("separation", 12)
	var ic = PanelContainer.new(); ic.custom_minimum_size = Vector2(32, 32)
	var sic = StyleBoxFlat.new(); sic.bg_color = Color(color.r, color.g, color.b, 0.1); sic.corner_radius_top_left=8; sic.corner_radius_bottom_right=8; sic.corner_radius_bottom_left=8; sic.corner_radius_top_right=8; sic.border_width_left=1; sic.border_width_right=1; sic.border_width_top=1; sic.border_width_bottom=1; sic.border_color = color; ic.add_theme_stylebox_override("panel", sic)
	var lic = Label.new(); lic.text = icon; lic.add_theme_color_override("font_color", color); lic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lic.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; ic.add_child(lic); htop.add_child(ic)
	
	var vtext = VBoxContainer.new(); vtext.alignment = BoxContainer.ALIGNMENT_CENTER
	var t = Label.new(); t.text = title; t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_font_size_override("font_size", 10); t.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); vtext.add_child(t)
	
	var th2 = HBoxContainer.new()
	var vl = Label.new(); vl.text = val; vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); vl.add_theme_font_size_override("font_size", 20); th2.add_child(vl)
	var suf = Label.new(); suf.text = " " + suf_text; suf.add_theme_font_size_override("font_size", 10); suf.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); suf.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM; th2.add_child(suf)
	vtext.add_child(th2)
	htop.add_child(vtext)
	v.add_child(htop)
	
	var bar = ColorRect.new(); bar.custom_minimum_size = Vector2(0, 4); bar.color = ThemeConfig.BG_ELEVATED
	var bfill = TextureRect.new(); bfill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bfill.custom_minimum_size = Vector2(0, 4); bfill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var g2 = GradientTexture2D.new(); var gg = Gradient.new()
	gg.set_color(0, Color(color.r, color.g, color.b, 0.3)); gg.set_color(1, color)
	g2.gradient = gg; g2.fill_from = Vector2(0,0); g2.fill_to = Vector2(1,0)
	bfill.texture = g2
	var bar_fill = Control.new()
	bar_fill.custom_minimum_size = Vector2(val.to_int() * 2, 4)
	bar_fill.add_child(bfill)
	bar.add_child(bar_fill)
	v.add_child(bar)
	
	return p

func _create_main_panel(ratio: float) -> PanelContainer:
	var p = PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL; p.size_flags_vertical = Control.SIZE_EXPAND_FILL; p.size_flags_stretch_ratio = ratio
	var s = StyleBoxFlat.new(); s.bg_color = ThemeConfig.BG_SURFACE; s.corner_radius_top_left=12; s.corner_radius_bottom_right=12; s.corner_radius_bottom_left=12; s.corner_radius_top_right=12; s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = ThemeConfig.BORDER_SUBTLE
	p.add_theme_stylebox_override("panel", s)
	var bg_grad = TextureRect.new(); var g2d = GradientTexture2D.new(); var g = Gradient.new(); g.set_color(0, Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.15)); g.set_color(1, Color(0,0,0,0)); g2d.gradient = g; g2d.fill_from = Vector2(0.5, 0); g2d.fill_to = Vector2(0.5, 0.6); bg_grad.texture = g2d; bg_grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg_grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); p.add_child(bg_grad)
	return p

func _build_left_col(parent: Node):
	var p = _create_main_panel(1.0)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20); m.add_theme_constant_override("margin_top", 20); m.add_theme_constant_override("margin_bottom", 20); p.add_child(m)
	var scroll = ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; m.add_child(scroll)
	var vb = VBoxContainer.new(); vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(vb)
	
	vb.add_child(_create_section_head("L", "BIBLIOTECA", ""))
	vb.add_child(_create_lib_head("FÍSICO", "3", ThemeConfig.DANGER))
	vb.add_child(_create_lib_item("Resistência", "90min · INT Alta", ThemeConfig.DANGER, "arrow_double_vertical"))
	vb.add_child(_create_lib_item("Força", "60min · INT Alta", ThemeConfig.DANGER, "F"))
	vb.add_child(_create_lib_item("Velocidade", "45min · INT Méd", ThemeConfig.DANGER, "E"))
	
	vb.add_child(_create_lib_head("TÉCNICO", "2", ThemeConfig.BRAND_PRIMARY))
	vb.add_child(_create_lib_item("Arremesso 3PT", "60min · INT Méd", ThemeConfig.BRAND_PRIMARY, "O"))
	vb.add_child(_create_lib_item("Defesa Individual", "75min · INT Méd", ThemeConfig.BRAND_PRIMARY, "#"))
	
	vb.add_child(_create_lib_head("TÁTICO", "2", Color("#3B82F6")))
	vb.add_child(_create_lib_item("5v5 Halfcourt", "90min · INT Alta", Color("#3B82F6"), "P"))
	vb.add_child(_create_lib_item("Jogadas", "60min · INT Baixa", Color("#3B82F6"), ">"))
	
	vb.add_child(_create_lib_head("RECUPERAÇÃO", "2", ThemeConfig.SUCCESS))
	vb.add_child(_create_lib_item("Mobilidade", "45min · INT Baixa", ThemeConfig.SUCCESS, "arrow_uturn_left_down"))
	vb.add_child(_create_lib_item("Folga", "— · INT Nula", ThemeConfig.SUCCESS, "Z"))
	
	parent.add_child(p)

func _create_section_head(icon: String, text: String, right_text: String) -> HBoxContainer:
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 8); h.custom_minimum_size = Vector2(0, 32)
	var i = Label.new(); i.text = icon; i.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); h.add_child(i)
	var t = Label.new(); t.text = text; t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_font_size_override("font_size", 10); t.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); t.add_theme_constant_override("letter_spacing", 1); h.add_child(t)
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(sp)
	if right_text != "":
		var rt = Label.new(); rt.text = right_text; rt.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); rt.add_theme_font_size_override("font_size", 10); rt.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); h.add_child(rt)
	return h

func _create_lib_head(text: String, count: String, color: Color) -> HBoxContainer:
	var h = HBoxContainer.new(); h.custom_minimum_size = Vector2(0, 32); h.alignment = BoxContainer.ALIGNMENT_CENTER
	var t = Label.new(); t.text = text; t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_font_size_override("font_size", 9); t.add_theme_color_override("font_color", color); t.add_theme_constant_override("letter_spacing", 1); h.add_child(t)
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(sp)
	var c = Label.new(); c.text = count; c.add_theme_font_size_override("font_size", 9); c.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); h.add_child(c)
	return h

func _create_lib_item(title: String, desc: String, color: Color, icon: String) -> PanelContainer:
	var p = PanelContainer.new(); p.custom_minimum_size = Vector2(0, 56)
	var s = StyleBoxFlat.new(); s.bg_color = Color(0,0,0,0); s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = ThemeConfig.BORDER_SUBTLE; s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8
	p.add_theme_stylebox_override("panel", s)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 12); m.add_theme_constant_override("margin_right", 12); p.add_child(m)
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 12); m.add_child(h)
	
	var ic = PanelContainer.new(); ic.custom_minimum_size = Vector2(32, 32); ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sic = StyleBoxFlat.new(); sic.bg_color = Color(color.r, color.g, color.b, 0.1); sic.border_width_left=1; sic.border_width_right=1; sic.border_width_top=1; sic.border_width_bottom=1; sic.border_color = color; sic.corner_radius_top_left=6; sic.corner_radius_bottom_right=6; sic.corner_radius_bottom_left=6; sic.corner_radius_top_right=6
	ic.add_theme_stylebox_override("panel", sic)
	var lic = Label.new(); lic.text = icon; lic.add_theme_color_override("font_color", color); lic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lic.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; ic.add_child(lic); h.add_child(ic)
	
	var v = VBoxContainer.new(); v.alignment = BoxContainer.ALIGNMENT_CENTER
	var t = Label.new(); t.text = title; t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_font_size_override("font_size", 12); v.add_child(t)
	var d = Label.new(); d.text = desc; d.add_theme_font_size_override("font_size", 9); d.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); v.add_child(d)
	h.add_child(v)
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(sp)
	var drag = TextureRect.new(); drag.texture = load("res://addons/at-icons/control/arrow_double_vertical.svg"); drag.custom_minimum_size = Vector2(12, 12); drag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; drag.modulate = ThemeConfig.TEXT_MUTED; drag.size_flags_vertical = Control.SIZE_SHRINK_CENTER; h.add_child(drag)
	
	return p

func _build_center_col(parent: Node):
	var p = _create_main_panel(2.2)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24); m.add_theme_constant_override("margin_top", 24); m.add_theme_constant_override("margin_bottom", 24); p.add_child(m)
	var vb = VBoxContainer.new(); vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; m.add_child(vb)
	
	var top = HBoxContainer.new()
	var i1 = TextureRect.new(); i1.texture = load("res://addons/at-icons/control/calendar.svg"); i1.custom_minimum_size = Vector2(12, 12); i1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; i1.modulate = ThemeConfig.TEXT_MUTED; top.add_child(i1)
	var hl = Label.new(); hl.text = " CRONOGRAMA · 24-30 NOV"; hl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); hl.add_theme_font_size_override("font_size", 10); hl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hl.add_theme_constant_override("letter_spacing", 1); top.add_child(hl)
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(sp)
	var btn = Button.new(); btn.text = "X JOGO SEX 25/11"; btn.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); btn.add_theme_font_size_override("font_size", 10)
	var sbtn = StyleBoxFlat.new(); sbtn.bg_color = Color(0,0,0,0); sbtn.border_width_left=1; sbtn.border_width_right=1; sbtn.border_width_top=1; sbtn.border_width_bottom=1; sbtn.border_color = Color("#3B82F6"); sbtn.corner_radius_top_left=4; sbtn.corner_radius_bottom_right=4; sbtn.corner_radius_bottom_left=4; sbtn.corner_radius_top_right=4; sbtn.content_margin_left=12; sbtn.content_margin_right=12; sbtn.content_margin_top=4; sbtn.content_margin_bottom=4
	btn.add_theme_stylebox_override("normal", sbtn); btn.add_theme_color_override("font_color", Color("#3B82F6")); top.add_child(btn)
	vb.add_child(top)
	
	vb.add_theme_constant_override("separation", 16)
	
	# Calendar Grid
	var cal = HBoxContainer.new(); cal.size_flags_vertical = Control.SIZE_EXPAND_FILL; cal.add_theme_constant_override("separation", 1)
	cal.add_child(_create_cal_day("SEG", "24", [_create_cal_card("09h00", "Resistência", "90min", ThemeConfig.DANGER, 3), _create_cal_card("14h00", "Arremesso 3PT", "60min", ThemeConfig.BRAND_PRIMARY, 2)]))
	cal.add_child(_create_cal_day("TER", "25", [_create_cal_card("09h00", "Defesa Individual", "75min", ThemeConfig.BRAND_PRIMARY, 2), _create_cal_card("14h00", "5v5 Halfcourt", "90min", Color("#3B82F6"), 3)]))
	cal.add_child(_create_cal_day("QUA", "26", [_create_cal_card("10h00", "Mobilidade", "45min", ThemeConfig.SUCCESS, 1), _create_cal_card("15h00", "Jogadas Ensaiadas", "60min", Color("#3B82F6"), 1)]))
	cal.add_child(_create_cal_day("QUI", "27", [_create_cal_card("09h00", "Força", "60min", ThemeConfig.DANGER, 3), _create_cal_card("14h00", "Velocidade", "45min", ThemeConfig.DANGER, 2)]))
	cal.add_child(_create_cal_day("SEX", "28", [_create_game_card("DIA DE JOGO", "vs POA", "20h30")], true))
	cal.add_child(_create_cal_day("SÁB", "29", [_create_cal_card("10h00", "Folga Total", "—", ThemeConfig.SUCCESS, 0)]))
	cal.add_child(_create_cal_day("DOM", "30", [_create_cal_card("11h00", "Mobilidade", "45min", ThemeConfig.SUCCESS, 1)]))
	vb.add_child(cal)
	
	var sep = HSeparator.new(); vb.add_child(sep)
	
	var hbot = HBoxContainer.new()
	var ctit = Label.new(); ctit.text = "CARGA SEMANAL POR DIA"; ctit.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); ctit.add_theme_font_size_override("font_size", 10); ctit.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); ctit.add_theme_constant_override("letter_spacing", 1); hbot.add_child(ctit)
	var sp2 = Control.new(); sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hbot.add_child(sp2)
	var med = Label.new(); med.text = "MÉDIA: 68/100"; med.add_theme_font_size_override("font_size", 10); med.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hbot.add_child(med)
	vb.add_child(hbot)
	
	var chart = HBoxContainer.new(); chart.custom_minimum_size = Vector2(0, 64); chart.add_theme_constant_override("separation", 8); chart.alignment = BoxContainer.ALIGNMENT_CENTER
	chart.add_child(_create_chart_bar(78, ThemeConfig.WARNING, "SEG"))
	chart.add_child(_create_chart_bar(85, ThemeConfig.WARNING, "TER"))
	chart.add_child(_create_chart_bar(40, ThemeConfig.SUCCESS, "QUA"))
	chart.add_child(_create_chart_bar(75, ThemeConfig.WARNING, "QUI"))
	chart.add_child(_create_chart_bar(95, ThemeConfig.DANGER, "SEX"))
	chart.add_child(_create_chart_bar(15, ThemeConfig.SUCCESS, "SÁB"))
	chart.add_child(_create_chart_bar(35, ThemeConfig.SUCCESS, "DOM"))
	vb.add_child(chart)
	
	parent.add_child(p)

func _create_cal_day(day_name: String, day_num: String, cards: Array, has_game: bool = false) -> PanelContainer:
	var p = PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s = StyleBoxFlat.new(); s.bg_color = Color(1,1,1, 0.02) if not has_game else Color(1,1,1, 0.05); s.border_width_right=1; s.border_color = ThemeConfig.BORDER_SUBTLE
	p.add_theme_stylebox_override("panel", s)
	var vb = VBoxContainer.new(); vb.add_theme_constant_override("separation", 8); p.add_child(vb)
	
	var header = VBoxContainer.new(); header.custom_minimum_size = Vector2(0, 48); header.alignment = BoxContainer.ALIGNMENT_CENTER
	var dname = Label.new(); dname.text = day_name; dname.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); dname.add_theme_font_size_override("font_size", 10); dname.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); dname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; header.add_child(dname)
	var dnum = Label.new(); dnum.text = day_num; dnum.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); dnum.add_theme_font_size_override("font_size", 16); dnum.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; header.add_child(dnum)
	if has_game:
		dname.add_theme_color_override("font_color", Color("#3B82F6")); dnum.add_theme_color_override("font_color", Color("#3B82F6"))
		dname.text = day_name
		var st = TextureRect.new(); st.texture = load("res://addons/at-icons/control/star.svg"); st.custom_minimum_size = Vector2(10, 10); st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; st.modulate = ThemeConfig.WARNING; header.add_child(st)
	
	vb.add_child(header)
	
	var mc = MarginContainer.new(); mc.add_theme_constant_override("margin_left", 4); mc.add_theme_constant_override("margin_right", 4); mc.size_flags_vertical = Control.SIZE_EXPAND_FILL; vb.add_child(mc)
	var card_v = VBoxContainer.new(); card_v.add_theme_constant_override("separation", 8); mc.add_child(card_v)
	for c in cards:
		card_v.add_child(c)
	
	return p

func _create_cal_card(time: String, title: String, dur: String, color: Color, dots: int) -> PanelContainer:
	var p = PanelContainer.new()
	var s = StyleBoxFlat.new(); s.bg_color = Color(color.r, color.g, color.b, 0.1); s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = color; s.corner_radius_top_left=4; s.corner_radius_bottom_right=4; s.corner_radius_bottom_left=4; s.corner_radius_top_right=4
	p.add_theme_stylebox_override("panel", s)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 6); m.add_theme_constant_override("margin_right", 6); m.add_theme_constant_override("margin_top", 6); m.add_theme_constant_override("margin_bottom", 6); p.add_child(m)
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", 2); m.add_child(v)
	
	var lt = Label.new(); lt.text = time; lt.add_theme_font_size_override("font_size", 9); lt.add_theme_color_override("font_color", color); v.add_child(lt)
	var ltit = Label.new(); ltit.text = title; ltit.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); ltit.add_theme_font_size_override("font_size", 10); ltit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(ltit)
	
	var hb = HBoxContainer.new()
	var durl = Label.new(); durl.text = dur; durl.add_theme_font_size_override("font_size", 9); durl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	var durc = TextureRect.new(); durc.texture = load("res://addons/at-icons/control/clock.svg"); durc.custom_minimum_size = Vector2(10, 10); durc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; durc.modulate = ThemeConfig.TEXT_MUTED
	var dhb = HBoxContainer.new(); dhb.add_theme_constant_override("separation", 4); dhb.add_child(durc); dhb.add_child(durl); hb.add_child(dhb)
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hb.add_child(sp)
	var dots_h = HBoxContainer.new(); dots_h.add_theme_constant_override("separation", 2); dots_h.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(3):
		var dot = ColorRect.new(); dot.custom_minimum_size = Vector2(3,3); dot.color = color if i < dots else Color(1,1,1,0.2)
		dots_h.add_child(dot)
	hb.add_child(dots_h)
	v.add_child(hb)
	return p

func _create_game_card(top: String, mid: String, bot: String) -> PanelContainer:
	var p = PanelContainer.new()
	var color = Color("#3B82F6")
	var s = StyleBoxFlat.new(); s.bg_color = Color(color.r, color.g, color.b, 0.2); s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = color; s.corner_radius_top_left=4; s.corner_radius_bottom_right=4; s.corner_radius_bottom_left=4; s.corner_radius_top_right=4
	p.add_theme_stylebox_override("panel", s)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 6); m.add_theme_constant_override("margin_right", 6); m.add_theme_constant_override("margin_top", 12); m.add_theme_constant_override("margin_bottom", 12); p.add_child(m)
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", 4); v.alignment = BoxContainer.ALIGNMENT_CENTER; m.add_child(v)
	
	var ic = TextureRect.new(); ic.texture = load("res://addons/at-icons/control/star.svg"); ic.custom_minimum_size = Vector2(14, 14); ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ic.modulate = ThemeConfig.WARNING; ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; v.add_child(ic)
	var l1 = Label.new(); l1.text = top; l1.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); l1.add_theme_font_size_override("font_size", 9); l1.add_theme_color_override("font_color", color); l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(l1)
	var l2 = Label.new(); l2.text = mid; l2.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); l2.add_theme_font_size_override("font_size", 14); l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(l2)
	var l3 = Label.new(); l3.text = bot; l3.add_theme_font_size_override("font_size", 10); l3.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(l3)
	return p

func _create_chart_bar(val: int, color: Color, day: String) -> VBoxContainer:
	var vb = VBoxContainer.new(); vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vb.alignment = BoxContainer.ALIGNMENT_END
	var vl = Label.new(); vl.text = str(val); vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); vl.add_theme_font_size_override("font_size", 9); vl.add_theme_color_override("font_color", color); vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(vl)
	var bar = ColorRect.new(); bar.custom_minimum_size = Vector2(0, max(4, val * 0.4)); bar.color = color; vb.add_child(bar)
	var dl = Label.new(); dl.text = day; dl.add_theme_font_size_override("font_size", 9); dl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(dl)
	return vb

func _build_right_col(parent: Node):
	var p = _create_main_panel(1.2)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20); m.add_theme_constant_override("margin_top", 20); m.add_theme_constant_override("margin_bottom", 20); p.add_child(m)
	var scroll = ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; m.add_child(scroll)
	var vb = VBoxContainer.new(); vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vb.add_theme_constant_override("separation", 16); scroll.add_child(vb)
	
	var top = HBoxContainer.new(); top.custom_minimum_size = Vector2(0, 32)
	var i1 = TextureRect.new(); i1.texture = load("res://addons/at-icons/control/arrow_up_right.svg"); i1.custom_minimum_size = Vector2(12, 12); i1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; i1.modulate = ThemeConfig.TEXT_MUTED; top.add_child(i1)
	var hl = Label.new(); hl.text = " PROGRAMAS INDIVIDUAIS"; hl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); hl.add_theme_font_size_override("font_size", 10); hl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hl.add_theme_constant_override("letter_spacing", 1); top.add_child(hl)
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(sp)
	var bp = PanelContainer.new()
	var sbp = StyleBoxFlat.new(); sbp.bg_color = Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.2); sbp.corner_radius_top_left=4; sbp.corner_radius_bottom_right=4; sbp.corner_radius_bottom_left=4; sbp.corner_radius_top_right=4; bp.add_theme_stylebox_override("panel", sbp)
	var mbp = MarginContainer.new(); mbp.add_theme_constant_override("margin_left", 6); mbp.add_theme_constant_override("margin_right", 6); bp.add_child(mbp)
	var lbp = Label.new(); lbp.text = "5 ATIVOS"; lbp.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lbp.add_theme_font_size_override("font_size", 9); lbp.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY); mbp.add_child(lbp); top.add_child(bp)
	vb.add_child(top)
	
	vb.add_child(_create_indiv_card("MS", "Marcus Silva", "PG · Liderança", "ESTRELA", ThemeConfig.WARNING, "QI Quadra", "88", "92", "+0.3/sem", 4, ThemeConfig.SUCCESS, 0.4))
	vb.add_child(_create_indiv_card("LA", "Lucas Almeida", "PG · Arremesso 3PT", "JOVEM", ThemeConfig.SUCCESS, "3PT %", "72", "80", "+0.8/sem", 8, ThemeConfig.BRAND_PRIMARY, 0.6))
	vb.add_child(_create_indiv_card("PH", "Pedro Henrique", "C · Defesa Pivô", "", Color.WHITE, "Defesa", "64", "75", "+0.6/sem", 10, Color("#3B82F6"), 0.3))
	vb.add_child(_create_indiv_card("AC", "Anderson Costa", "PF · Recuperação", "CANSADO", ThemeConfig.WARNING, "Energia", "45", "80", "+5/sem", 1, ThemeConfig.SUCCESS, 0.8))
	vb.add_child(_create_indiv_card("TW", "Tyrone Walker", "C · Fisioterapia", "LESÃO", ThemeConfig.DANGER, "Lesão", "0", "100", "+7/sem", 2, ThemeConfig.DANGER, 0.2))
	
	parent.add_child(p)

func _create_indiv_card(ini: String, name: String, desc: String, badge: String, bcolor: Color, stat: String, vfrom: String, vto: String, rate: String, weeks: int, pcolor: Color, prog: float) -> PanelContainer:
	var p = PanelContainer.new()
	var s = StyleBoxFlat.new(); s.bg_color = Color(0,0,0,0); s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = ThemeConfig.BORDER_SUBTLE; s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8
	p.add_theme_stylebox_override("panel", s)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 16); m.add_theme_constant_override("margin_right", 16); m.add_theme_constant_override("margin_top", 12); m.add_theme_constant_override("margin_bottom", 12); p.add_child(m)
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", 12); m.add_child(v)
	
	var htop = HBoxContainer.new(); htop.add_theme_constant_override("separation", 12)
	var av = PanelContainer.new(); av.custom_minimum_size = Vector2(32, 32)
	var sav = StyleBoxFlat.new(); sav.bg_color = Color.WHITE; sav.corner_radius_top_left=16; sav.corner_radius_bottom_right=16; sav.corner_radius_bottom_left=16; sav.corner_radius_top_right=16; av.add_theme_stylebox_override("panel", sav)
	var lav = Label.new(); lav.text = ini; lav.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lav.add_theme_font_size_override("font_size", 12); lav.add_theme_color_override("font_color", ThemeConfig.BG_APP); lav.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lav.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; av.add_child(lav); htop.add_child(av)
	
	var vname = VBoxContainer.new(); vname.alignment = BoxContainer.ALIGNMENT_CENTER
	var ln = Label.new(); ln.text = name; ln.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); ln.add_theme_font_size_override("font_size", 12); vname.add_child(ln)
	var ld = Label.new(); ld.text = desc; ld.add_theme_font_size_override("font_size", 10); ld.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); vname.add_child(ld)
	htop.add_child(vname)
	
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; htop.add_child(sp)
	
	if badge != "":
		var bp = PanelContainer.new(); bp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var sbp = StyleBoxFlat.new(); sbp.bg_color = Color(0,0,0,0); sbp.border_width_left=1; sbp.border_width_right=1; sbp.border_width_top=1; sbp.border_width_bottom=1; sbp.border_color = bcolor; sbp.corner_radius_top_left=4; sbp.corner_radius_bottom_right=4; sbp.corner_radius_bottom_left=4; sbp.corner_radius_top_right=4; bp.add_theme_stylebox_override("panel", sbp)
		var mbp = MarginContainer.new(); mbp.add_theme_constant_override("margin_left", 6); mbp.add_theme_constant_override("margin_right", 6); bp.add_child(mbp)
		var lbp = Label.new(); lbp.text = badge; lbp.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lbp.add_theme_font_size_override("font_size", 9); lbp.add_theme_color_override("font_color", bcolor); mbp.add_child(lbp); htop.add_child(bp)
	v.add_child(htop)
	
	var hmid = HBoxContainer.new()
	var ls = Label.new(); ls.text = stat; ls.add_theme_font_size_override("font_size", 11); hmid.add_child(ls)
	var sp2 = Control.new(); sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hmid.add_child(sp2)
	var lv1 = Label.new(); lv1.text = vfrom; lv1.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lv1.add_theme_font_size_override("font_size", 11); hmid.add_child(lv1)
	var larr = TextureRect.new(); larr.texture = load("res://addons/at-icons/control/arrow_right.svg"); larr.custom_minimum_size = Vector2(10, 10); larr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; larr.modulate = ThemeConfig.TEXT_MUTED; hmid.add_child(larr)
	var lv2 = Label.new(); lv2.text = vto; lv2.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lv2.add_theme_font_size_override("font_size", 11); lv2.add_theme_color_override("font_color", pcolor); hmid.add_child(lv2)
	v.add_child(hmid)
	
	var bar = ColorRect.new(); bar.custom_minimum_size = Vector2(0, 4); bar.color = ThemeConfig.BG_ELEVATED
	var bfill = TextureRect.new(); bfill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bfill.custom_minimum_size = Vector2(0, 4); bfill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var g2 = GradientTexture2D.new(); var gg = Gradient.new()
	gg.set_color(0, Color(pcolor.r, pcolor.g, pcolor.b, 0.3)); gg.set_color(1, pcolor)
	g2.gradient = gg; g2.fill_from = Vector2(0,0); g2.fill_to = Vector2(1,0)
	bfill.texture = g2
	var bctrl = Control.new(); bctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bctrl.anchor_right = prog; bctrl.add_child(bfill); bar.add_child(bctrl); v.add_child(bar)
	
	var hbot = HBoxContainer.new()
	var lr = Label.new(); lr.text = rate; lr.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lr.add_theme_font_size_override("font_size", 10); lr.add_theme_color_override("font_color", pcolor)
	var lri = TextureRect.new(); lri.texture = load("res://addons/at-icons/control/arrow_up_right.svg"); lri.custom_minimum_size = Vector2(10, 10); lri.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; lri.modulate = pcolor
	var lrbox = HBoxContainer.new(); lrbox.add_theme_constant_override("separation", 2); lrbox.add_child(lri); lrbox.add_child(lr); hbot.add_child(lrbox)
	var sp3 = Control.new(); sp3.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hbot.add_child(sp3)
	var lw = Label.new(); lw.text = str(weeks) + " sem restantes"; lw.add_theme_font_size_override("font_size", 10); lw.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hbot.add_child(lw)
	v.add_child(hbot)
	
	return p
