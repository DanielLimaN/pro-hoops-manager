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
	tb.screen_title = "TÁTICA"
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
	
	var tabs = ["ESCALAÇÃO", "ESQUEMA OFENSIVO", "ESQUEMA DEFENSIVO", "JOGADAS ENSAIADAS"]
	var tab_box = HBoxContainer.new()
	tab_box.add_theme_constant_override("separation", 8)
	for i in range(tabs.size()):
		var b = Button.new()
		b.text = tabs[i]
		b.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		b.add_theme_font_size_override("font_size", 12)
		var s = StyleBoxFlat.new(); s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8; s.content_margin_left=16; s.content_margin_right=16; s.content_margin_top=8; s.content_margin_bottom=8
		b.add_theme_constant_override("h_separation", 8)
		if i == 0:
			b.icon = load("res://addons/at-icons/control/clipboard.svg")
			s.bg_color = ThemeConfig.BRAND_PRIMARY; s.border_width_bottom=0
			b.add_theme_color_override("font_color", Color.WHITE)
			b.add_theme_color_override("icon_normal_color", Color.WHITE)
			b.add_theme_color_override("icon_hover_color", Color.WHITE)
			b.add_theme_color_override("icon_focus_color", Color.WHITE)
		else:
			if i == 1: b.icon = load("res://addons/at-icons/control/cross.svg")
			elif i == 2: b.icon = load("res://addons/at-icons/control/shield.svg")
			elif i == 3: b.icon = load("res://addons/at-icons/control/arrows_clockwise.svg")
			s.bg_color = Color(0,0,0,0); s.border_width_bottom=0
			b.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
			b.add_theme_color_override("icon_normal_color", ThemeConfig.TEXT_MUTED)
			b.add_theme_color_override("icon_hover_color", ThemeConfig.TEXT_MUTED)
			b.add_theme_color_override("icon_focus_color", ThemeConfig.TEXT_MUTED)
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", s)
		tab_box.add_child(b)
	
	h.add_child(tab_box)
	
	var space = Control.new(); space.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(space)
	
	var presets = HBoxContainer.new(); presets.add_theme_constant_override("separation", 16)
	
	var btn_preset = Button.new(); btn_preset.text = "PRESET: 'CORRE-CORRE'"; btn_preset.icon = load("res://addons/at-icons/control/bookmark.svg"); btn_preset.add_theme_constant_override("h_separation", 8); btn_preset.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); btn_preset.add_theme_font_size_override("font_size", 12)
	var s_pre = StyleBoxFlat.new(); s_pre.bg_color = Color(0,0,0,0); s_pre.border_width_left=1; s_pre.border_width_right=1; s_pre.border_width_top=1; s_pre.border_width_bottom=1; s_pre.border_color = ThemeConfig.BORDER_SUBTLE; s_pre.corner_radius_top_left=8; s_pre.corner_radius_bottom_right=8; s_pre.corner_radius_bottom_left=8; s_pre.corner_radius_top_right=8; s_pre.content_margin_left=16; s_pre.content_margin_right=16
	btn_preset.add_theme_stylebox_override("normal", s_pre)
	presets.add_child(btn_preset)
	
	var btn_reset = Button.new(); btn_reset.text = "RESETAR"; btn_reset.icon = load("res://addons/at-icons/control/arrow_counterclockwise.svg"); btn_reset.add_theme_constant_override("h_separation", 8); btn_reset.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); btn_reset.add_theme_font_size_override("font_size", 12)
	var s_res = StyleBoxFlat.new(); s_res.bg_color = Color(0,0,0,0); s_res.border_width_left=1; s_res.border_width_right=1; s_res.border_width_top=1; s_res.border_width_bottom=1; s_res.border_color = ThemeConfig.BORDER_SUBTLE; s_res.corner_radius_top_left=8; s_res.corner_radius_bottom_right=8; s_res.corner_radius_bottom_left=8; s_res.corner_radius_top_right=8; s_res.content_margin_left=16; s_res.content_margin_right=16
	btn_reset.add_theme_stylebox_override("normal", s_res)
	presets.add_child(btn_reset)
	
	h.add_child(presets)
	parent.add_child(h)

func _build_kpis(parent: Node):
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	
	h.add_child(_create_stat_card("ATAQUE", 94, ThemeConfig.BRAND_PRIMARY, "cross"))
	h.add_child(_create_stat_card("DEFESA", 87, Color("#3B82F6"), "shield"))
	h.add_child(_create_stat_card("QUÍMICA", 91, ThemeConfig.DANGER, "beaker"))
	h.add_child(_create_stat_card("VANTAGEM vs POA", 12, ThemeConfig.SUCCESS, "arrow_up_right", true))
	
	parent.add_child(h)

func _create_stat_card(title: String, val: int, color: Color, icon: String, is_diff: bool = false) -> PanelContainer:
	var p = PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s = StyleBoxFlat.new(); s.bg_color = ThemeConfig.BG_SURFACE; s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8
	s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = ThemeConfig.BORDER_SUBTLE
	p.add_theme_stylebox_override("panel", s)
	
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 16); m.add_theme_constant_override("margin_right", 16); m.add_theme_constant_override("margin_top", 12); m.add_theme_constant_override("margin_bottom", 12); p.add_child(m)
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", 8); m.add_child(v)
	
	var htop = HBoxContainer.new(); htop.add_theme_constant_override("separation", 12)
	var ic = PanelContainer.new(); ic.custom_minimum_size = Vector2(32, 32)
	var sic = StyleBoxFlat.new(); sic.bg_color = Color(color.r, color.g, color.b, 0.1); sic.corner_radius_top_left=8; sic.corner_radius_bottom_right=8; sic.corner_radius_bottom_left=8; sic.corner_radius_top_right=8; ic.add_theme_stylebox_override("panel", sic)
	var lic = TextureRect.new()
	lic.texture = load("res://addons/at-icons/control/" + icon + ".svg")
	lic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lic.custom_minimum_size = Vector2(16, 16)
	lic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lic.modulate = color
	lic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.add_child(lic); htop.add_child(ic)
	
	var vtext = VBoxContainer.new(); vtext.alignment = BoxContainer.ALIGNMENT_CENTER
	var t = Label.new(); t.text = title; t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_font_size_override("font_size", 10); t.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); vtext.add_child(t)
	
	var th2 = HBoxContainer.new()
	var vl = Label.new(); vl.text = "+" + str(val) if is_diff else str(val); vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); vl.add_theme_font_size_override("font_size", 20); th2.add_child(vl)
	var suf = Label.new(); suf.text = " pts" if is_diff else " /100"; suf.add_theme_font_size_override("font_size", 10); suf.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); suf.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM; th2.add_child(suf)
	vtext.add_child(th2)
	htop.add_child(vtext)
	v.add_child(htop)
	
	var bar = ColorRect.new(); bar.custom_minimum_size = Vector2(0, 4); bar.color = ThemeConfig.BG_ELEVATED
	var bfill = TextureRect.new(); bfill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bfill.custom_minimum_size = Vector2(0, 4); bfill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var g2 = GradientTexture2D.new(); var g = Gradient.new()
	g.set_color(0, Color(color.r, color.g, color.b, 0.3)); g.set_color(1, color)
	g2.gradient = g; g2.fill_from = Vector2(0,0); g2.fill_to = Vector2(1,0)
	bfill.texture = g2
	# Mock width
	var bar_fill = Control.new()
	bar_fill.custom_minimum_size = Vector2(200 if not is_diff else 120, 4)
	bar_fill.add_child(bfill)
	bar.add_child(bar_fill)
	
	v.add_child(bar)
	return p

func _build_left_col(parent: Node):
	var p = preload("res://scenes/ui/components/container_base.tscn").instantiate()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL; p.size_flags_vertical = Control.SIZE_EXPAND_FILL; p.size_flags_stretch_ratio = 1.0
	var bg_grad = TextureRect.new(); var g2d = GradientTexture2D.new(); var g = Gradient.new(); g.set_color(0, Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.15)); g.set_color(1, Color(0,0,0,0)); g2d.gradient = g; g2d.fill_from = Vector2(0.5, 0); g2d.fill_to = Vector2(0.5, 0.6); bg_grad.texture = g2d; bg_grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg_grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); p.add_child(bg_grad)
	
	var scroll = ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var m = MarginContainer.new(); m.size_flags_horizontal = Control.SIZE_EXPAND_FILL; m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24); m.add_theme_constant_override("margin_top", 24); m.add_theme_constant_override("margin_bottom", 24)
	var vb = VBoxContainer.new(); vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vb.add_theme_constant_override("separation", 24)
	
	var hl = Label.new(); hl.text = "ESTRATÉGIA GERAL"; hl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); hl.add_theme_font_size_override("font_size", 10); hl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hl.add_theme_constant_override("letter_spacing", 1)
	var hbox = HBoxContainer.new(); hbox.add_theme_constant_override("separation", 8)
	var icon = TextureRect.new(); icon.texture = load("res://addons/at-icons/control/sliders.svg"); icon.custom_minimum_size = Vector2(14, 14); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.modulate = ThemeConfig.TEXT_MUTED; hbox.add_child(icon); hbox.add_child(hl); vb.add_child(hbox)
	
	vb.add_child(_create_btn_group("RITMO DE JOGO", ["LENTO", "MÉDIO", "RÁPIDO"], 2, ["play", "fast_forward", "lightning_bolt"]))
	vb.add_child(_create_btn_group("FOCO OFENSIVO", ["PERÍMETRO", "GARRAFÃO", "BALANCEADO"], 0, ["target", "cube", "balance"]))
	vb.add_child(_create_btn_group("FOCO DEFENSIVO", ["INDIVIDUAL", "ZONA 2-3", "PRESSÃO"], 0, ["human", "grid_fine", "shield"]))
	vb.add_child(_create_btn_group("AGRESSIVIDADE", ["PASSIVO", "EQUILIBRADO", "AGRESSIVO"], 1, ["shield", "scales", "fire"]))
	
	var sep = HSeparator.new(); vb.add_child(sep)
	
	vb.add_child(_create_slider_row("INTENSIDADE 3PT", 70, ThemeConfig.BRAND_PRIMARY))
	vb.add_child(_create_slider_row("GARRAFÃO", 30, Color("#3B82F6")))
	vb.add_child(_create_slider_row("ROTAÇÃO RESERVAS", 55, ThemeConfig.SUCCESS))
	
	m.add_child(vb); scroll.add_child(m); p.add_child(scroll); parent.add_child(p)

func _create_btn_group(title: String, opts: Array, active_idx: int, icons: Array) -> VBoxContainer:
	var vb = VBoxContainer.new(); vb.add_theme_constant_override("separation", 8)
	var tl = Label.new(); tl.text = title; tl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); tl.add_theme_font_size_override("font_size", 10); tl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	vb.add_child(tl)
	
	var hb = HBoxContainer.new(); hb.add_theme_constant_override("separation", 8)
	for i in range(opts.size()):
		var b = Button.new(); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var t = opts[i]
		b.text = t
		if icons.size() > i:
			b.icon = load("res://addons/at-icons/control/" + icons[i] + ".svg")
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); b.add_theme_font_size_override("font_size", 10)
		
		var s = StyleBoxFlat.new(); s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8; s.content_margin_top=8; s.content_margin_bottom=8
		s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1
		if i == active_idx:
			s.bg_color = Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.1)
			s.border_color = ThemeConfig.BRAND_PRIMARY
			b.add_theme_color_override("font_color", Color.WHITE)
			b.add_theme_color_override("icon_normal_color", Color.WHITE)
			b.add_theme_color_override("icon_hover_color", Color.WHITE)
			b.add_theme_color_override("icon_focus_color", Color.WHITE)
		else:
			s.bg_color = ThemeConfig.BG_APP
			s.border_color = ThemeConfig.BORDER_SUBTLE
			b.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
			b.add_theme_color_override("icon_normal_color", ThemeConfig.TEXT_MUTED)
			b.add_theme_color_override("icon_hover_color", ThemeConfig.TEXT_MUTED)
			b.add_theme_color_override("icon_focus_color", ThemeConfig.TEXT_MUTED)
		
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", s)
		hb.add_child(b)
	vb.add_child(hb)
	return vb

func _create_slider_row(title: String, val: int, color: Color) -> VBoxContainer:
	var vb = VBoxContainer.new(); vb.add_theme_constant_override("separation", 8)
	var hb = HBoxContainer.new()
	var tl = Label.new(); tl.text = title; tl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); tl.add_theme_font_size_override("font_size", 10); tl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hb.add_child(tl)
	var space = Control.new(); space.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hb.add_child(space)
	var vl = Label.new(); vl.text = str(val) + "%"; vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); vl.add_theme_font_size_override("font_size", 12); vl.add_theme_color_override("font_color", color); hb.add_child(vl)
	vb.add_child(hb)
	
	var bar = ColorRect.new(); bar.custom_minimum_size = Vector2(0, 6); bar.color = ThemeConfig.BG_ELEVATED
	var fill = TextureRect.new(); fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var g2d = GradientTexture2D.new(); var g = Gradient.new(); g.set_color(0, Color(color.r, color.g, color.b, 0.2)); g.set_color(1, color)
	g2d.gradient = g; g2d.fill_from = Vector2(0, 0); g2d.fill_to = Vector2(1, 0); fill.texture = g2d
	var fctrl = Control.new(); fctrl.custom_minimum_size = Vector2(val * 2.5, 6); fctrl.add_child(fill); bar.add_child(fctrl)
	
	var thumb = Panel.new(); thumb.custom_minimum_size = Vector2(12, 12); thumb.position = Vector2(val * 2.5 - 6, -3)
	var st = StyleBoxFlat.new(); st.bg_color = Color.WHITE; st.corner_radius_top_left=6; st.corner_radius_bottom_right=6; st.corner_radius_bottom_left=6; st.corner_radius_top_right=6; thumb.add_theme_stylebox_override("panel", st)
	bar.add_child(thumb)
	vb.add_child(bar)
	return vb

func _build_center_col(parent: Node):
	var p = preload("res://scenes/ui/components/container_base.tscn").instantiate()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL; p.size_flags_vertical = Control.SIZE_EXPAND_FILL; p.size_flags_stretch_ratio = 1.8
	var bg_grad = TextureRect.new(); var g2d = GradientTexture2D.new(); var g = Gradient.new(); g.set_color(0, Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.15)); g.set_color(1, Color(0,0,0,0)); g2d.gradient = g; g2d.fill_from = Vector2(0.5, 0); g2d.fill_to = Vector2(0.5, 0.6); bg_grad.texture = g2d; bg_grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg_grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); p.add_child(bg_grad)
	
	var scroll = ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var m = MarginContainer.new(); m.size_flags_horizontal = Control.SIZE_EXPAND_FILL; m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24); m.add_theme_constant_override("margin_top", 24); m.add_theme_constant_override("margin_bottom", 24)
	var vb = VBoxContainer.new(); vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vb.add_theme_constant_override("separation", 16)
	
	var htop = HBoxContainer.new(); htop.add_theme_constant_override("separation", 16)
	var hl = Label.new(); hl.text = "QUINTETO TITULAR"; hl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); hl.add_theme_font_size_override("font_size", 10); hl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hl.add_theme_constant_override("letter_spacing", 1)
	var hb_icon = HBoxContainer.new(); hb_icon.add_theme_constant_override("separation", 8)
	var icon = TextureRect.new(); icon.texture = load("res://addons/at-icons/control/human.svg"); icon.custom_minimum_size = Vector2(14, 14); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.modulate = ThemeConfig.TEXT_MUTED; hb_icon.add_child(icon); hb_icon.add_child(hl); htop.add_child(hb_icon)
	
	var space = Control.new(); space.size_flags_horizontal = Control.SIZE_EXPAND_FILL; htop.add_child(space)
	
	htop.add_child(_create_stat("OVR", "87"))
	htop.add_child(_create_stat("IDADE MÉDIA", "27.2"))
	htop.add_child(_create_stat("SALÁRIO", "R$ 6.8M", ThemeConfig.SUCCESS))
	
	var btn_edit = Button.new(); btn_edit.text = "EDITAR"; btn_edit.icon = load("res://addons/at-icons/control/pencil.svg"); btn_edit.add_theme_constant_override("h_separation", 4); btn_edit.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); btn_edit.add_theme_font_size_override("font_size", 10)
	var se = StyleBoxFlat.new(); se.bg_color = Color(0,0,0,0); se.border_width_left=1; se.border_width_right=1; se.border_width_top=1; se.border_width_bottom=1; se.border_color = ThemeConfig.BORDER_SUBTLE; se.corner_radius_top_left=6; se.corner_radius_bottom_right=6; se.corner_radius_bottom_left=6; se.corner_radius_top_right=6; se.content_margin_left=12; se.content_margin_right=12
	btn_edit.add_theme_stylebox_override("normal", se)
	htop.add_child(btn_edit)
	vb.add_child(htop)
	
	# Court
	var court_panel = PanelContainer.new(); court_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sc = StyleBoxFlat.new(); sc.bg_color = ThemeConfig.BG_APP; sc.corner_radius_top_left=12; sc.corner_radius_bottom_right=12; sc.corner_radius_bottom_left=12; sc.corner_radius_top_right=12; sc.border_width_left=1; sc.border_width_right=1; sc.border_width_top=1; sc.border_width_bottom=1; sc.border_color = ThemeConfig.BORDER_SUBTLE
	court_panel.add_theme_stylebox_override("panel", sc)
	court_panel.clip_contents = true
	
	var court = Control.new()
	court.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	court.set_script(preload("res://scripts/menu_court.gd"))
	court_panel.add_child(court)
	
	var cnodes = Control.new()
	cnodes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	court_panel.add_child(cnodes)
	_add_court_node(cnodes, "PG", "7", "Marcus", "92", ThemeConfig.BRAND_PRIMARY, Vector2(250, 150))
	_add_court_node(cnodes, "SG", "23", "Pedro", "88", Color("#3B82F6"), Vector2(100, 300))
	_add_court_node(cnodes, "SF", "12", "Carlos", "86", ThemeConfig.SUCCESS, Vector2(400, 300))
	_add_court_node(cnodes, "PF", "44", "Anderson", "85", ThemeConfig.WARNING, Vector2(200, 420))
	_add_court_node(cnodes, "C", "33", "Tyrone", "83", ThemeConfig.DANGER, Vector2(300, 480))
	
	vb.add_child(court_panel)
	
	# Minutagem
	var hmin = HBoxContainer.new(); hmin.add_theme_constant_override("separation", 16)
	var lmin = Label.new(); lmin.text = "MINUTAGEM:"; lmin.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lmin.add_theme_font_size_override("font_size", 10); lmin.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hmin.add_child(lmin)
	hmin.add_child(_create_min_box("MS", "38min", ThemeConfig.BRAND_PRIMARY))
	hmin.add_child(_create_min_box("PP", "34min", Color("#3B82F6")))
	hmin.add_child(_create_min_box("CM", "32min", ThemeConfig.SUCCESS))
	hmin.add_child(_create_min_box("AC", "28min", ThemeConfig.WARNING))
	hmin.add_child(_create_min_box("TW", "30min", ThemeConfig.DANGER))
	vb.add_child(hmin)
	
	m.add_child(vb); scroll.add_child(m); p.add_child(scroll); parent.add_child(p)

func _create_stat(title: String, val: String, color: Color = Color.WHITE) -> HBoxContainer:
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 6)
	var t = Label.new(); t.text = title; t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_font_size_override("font_size", 10); t.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	var v = Label.new(); v.text = val; v.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); v.add_theme_font_size_override("font_size", 12); v.add_theme_color_override("font_color", color)
	h.add_child(t); h.add_child(v); return h

func _create_min_box(pos: String, min: String, color: Color) -> PanelContainer:
	var p = PanelContainer.new()
	var s = StyleBoxFlat.new(); s.bg_color = Color(0,0,0,0); s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = color; s.corner_radius_top_left=4; s.corner_radius_bottom_right=4; s.corner_radius_bottom_left=4; s.corner_radius_top_right=4
	p.add_theme_stylebox_override("panel", s)
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 0)
	var p1 = PanelContainer.new()
	var s1 = StyleBoxFlat.new(); s1.bg_color = Color(color.r, color.g, color.b, 0.2); s1.corner_radius_top_left=3; s1.corner_radius_bottom_left=3; p1.add_theme_stylebox_override("panel", s1)
	var m1 = MarginContainer.new(); m1.add_theme_constant_override("margin_left", 6); m1.add_theme_constant_override("margin_right", 6); p1.add_child(m1)
	var l1 = Label.new(); l1.text = pos; l1.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); l1.add_theme_font_size_override("font_size", 10); l1.add_theme_color_override("font_color", color); m1.add_child(l1)
	
	var p2 = PanelContainer.new()
	var s2 = StyleBoxFlat.new(); s2.bg_color = Color(0,0,0,0); p2.add_theme_stylebox_override("panel", s2)
	var m2 = MarginContainer.new(); m2.add_theme_constant_override("margin_left", 6); m2.add_theme_constant_override("margin_right", 6); p2.add_child(m2)
	var l2 = Label.new(); l2.text = min; l2.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); l2.add_theme_font_size_override("font_size", 10); m2.add_child(l2)
	
	h.add_child(p1); h.add_child(p2); p.add_child(h)
	return p

func _add_court_node(parent: Control, pos: String, num: String, pname: String, ovr: String, color: Color, p_pos: Vector2):
	var c = Control.new()
	c.position = p_pos
	
	var circ = PanelContainer.new(); circ.position = Vector2(-24, -24); circ.custom_minimum_size = Vector2(48, 48)
	var sc = StyleBoxFlat.new(); sc.bg_color = color; sc.corner_radius_top_left=24; sc.corner_radius_bottom_right=24; sc.corner_radius_bottom_left=24; sc.corner_radius_top_right=24
	sc.border_width_left=2; sc.border_width_right=2; sc.border_width_top=2; sc.border_width_bottom=2; sc.border_color = Color.WHITE
	circ.add_theme_stylebox_override("panel", sc)
	var num_lbl = Label.new(); num_lbl.text = num; num_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); num_lbl.add_theme_font_size_override("font_size", 20); num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	circ.add_child(num_lbl)
	c.add_child(circ)
	
	var info = PanelContainer.new(); info.position = Vector2(-30, 24); info.custom_minimum_size = Vector2(60, 24)
	var si = StyleBoxFlat.new(); si.bg_color = ThemeConfig.BG_APP; si.border_width_left=1; si.border_width_right=1; si.border_width_top=1; si.border_width_bottom=1; si.border_color=ThemeConfig.BORDER_SUBTLE; si.corner_radius_top_left=4; si.corner_radius_bottom_right=4; si.corner_radius_bottom_left=4; si.corner_radius_top_right=4
	info.add_theme_stylebox_override("panel", si)
	var vb = VBoxContainer.new(); vb.add_theme_constant_override("separation", 0); vb.alignment = BoxContainer.ALIGNMENT_CENTER
	var h = HBoxContainer.new(); h.alignment = BoxContainer.ALIGNMENT_CENTER; h.add_theme_constant_override("separation", 2)
	var pl = Label.new(); pl.text = pos; pl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); pl.add_theme_font_size_override("font_size", 9); pl.add_theme_color_override("font_color", color); h.add_child(pl)
	var ol = Label.new(); ol.text = "· " + ovr; ol.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); ol.add_theme_font_size_override("font_size", 9); h.add_child(ol)
	vb.add_child(h)
	var nl = Label.new(); nl.text = pname; nl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); nl.add_theme_font_size_override("font_size", 9); nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(nl)
	info.add_child(vb)
	c.add_child(info)
	
	parent.add_child(c)

func _build_right_col(parent: Node):
	var p = preload("res://scenes/ui/components/container_base.tscn").instantiate()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL; p.size_flags_vertical = Control.SIZE_EXPAND_FILL; p.size_flags_stretch_ratio = 1.0
	var bg_grad = TextureRect.new(); var g2d = GradientTexture2D.new(); var g = Gradient.new(); g.set_color(0, Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.15)); g.set_color(1, Color(0,0,0,0)); g2d.gradient = g; g2d.fill_from = Vector2(0.5, 0); g2d.fill_to = Vector2(0.5, 0.6); bg_grad.texture = g2d; bg_grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg_grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); p.add_child(bg_grad)
	
	var scroll = ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var m = MarginContainer.new(); m.size_flags_horizontal = Control.SIZE_EXPAND_FILL; m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24); m.add_theme_constant_override("margin_top", 24); m.add_theme_constant_override("margin_bottom", 24)
	var vb = VBoxContainer.new(); vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vb.add_theme_constant_override("separation", 24)
	
	var htop = HBoxContainer.new()
	var hl = Label.new(); hl.text = "ANÁLISE DO ADVERSÁRIO"; hl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); hl.add_theme_font_size_override("font_size", 10); hl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hl.add_theme_constant_override("letter_spacing", 1)
	var hbox = HBoxContainer.new(); hbox.add_theme_constant_override("separation", 8)
	var icon = TextureRect.new(); icon.texture = load("res://addons/at-icons/control/magnifying_glass.svg"); icon.custom_minimum_size = Vector2(14, 14); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.modulate = ThemeConfig.TEXT_MUTED; hbox.add_child(icon); hbox.add_child(hl); htop.add_child(hbox)
	var space = Control.new(); space.size_flags_horizontal = Control.SIZE_EXPAND_FILL; htop.add_child(space)
	var days = Label.new(); days.text = "3 DIAS"; days.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); days.add_theme_font_size_override("font_size", 10); days.add_theme_color_override("font_color", ThemeConfig.WARNING); htop.add_child(days)
	vb.add_child(htop)
	
	var team_box = HBoxContainer.new(); team_box.add_theme_constant_override("separation", 16)
	var tlogo = PanelContainer.new(); tlogo.custom_minimum_size = Vector2(48, 48)
	var st = StyleBoxFlat.new(); st.bg_color = ThemeConfig.DANGER; st.corner_radius_top_left=24; st.corner_radius_bottom_right=24; st.corner_radius_bottom_left=24; st.corner_radius_top_right=24; tlogo.add_theme_stylebox_override("panel", st)
	var tl_lbl = Label.new(); tl_lbl.text = "POA"; tl_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); tl_lbl.add_theme_font_size_override("font_size", 14); tl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tl_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; tlogo.add_child(tl_lbl)
	team_box.add_child(tlogo)
	var tvb = VBoxContainer.new(); tvb.alignment = BoxContainer.ALIGNMENT_CENTER
	var tname = Label.new(); tname.text = "Porto Alegre"; tname.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); tname.add_theme_font_size_override("font_size", 16); tvb.add_child(tname)
	var tstat = Label.new(); tstat.text = "3V - 7D · 12º lugar · @ Casa"; tstat.add_theme_font_size_override("font_size", 12); tstat.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); tvb.add_child(tstat)
	team_box.add_child(tvb)
	vb.add_child(team_box)
	
	vb.add_child(_create_adv_stat("Forte no garrafão", "94 OVR", ThemeConfig.DANGER, "arrow_up_right"))
	vb.add_child(_create_adv_stat("Defesa do perímetro fraca", "67 OVR", Color("#3B82F6"), "arrow_down_right", true))
	vb.add_child(_create_adv_stat("Pouca rotação no banco", "5 jog", ThemeConfig.SUCCESS, "arrow_down_right"))
	
	var rec = PanelContainer.new()
	var sr = StyleBoxFlat.new(); sr.bg_color = Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.1); sr.border_width_left=1; sr.border_width_right=1; sr.border_width_top=1; sr.border_width_bottom=1; sr.border_color = ThemeConfig.BRAND_PRIMARY; sr.corner_radius_top_left=8; sr.corner_radius_bottom_right=8; sr.corner_radius_bottom_left=8; sr.corner_radius_top_right=8
	rec.add_theme_stylebox_override("panel", sr)
	var rm = MarginContainer.new(); rm.add_theme_constant_override("margin_left", 16); rm.add_theme_constant_override("margin_right", 16); rm.add_theme_constant_override("margin_top", 16); rm.add_theme_constant_override("margin_bottom", 16); rec.add_child(rm)
	var rv = VBoxContainer.new(); rv.add_theme_constant_override("separation", 12); rm.add_child(rv)
	var rhl = Label.new(); rhl.text = "RECOMENDAÇÃO DO ASSISTENTE"; rhl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); rhl.add_theme_font_size_override("font_size", 10); rhl.add_theme_color_override("font_color", ThemeConfig.WARNING)
	var rhbox = HBoxContainer.new(); rhbox.add_theme_constant_override("separation", 8)
	var ricon = TextureRect.new(); ricon.texture = load("res://addons/at-icons/control/star.svg"); ricon.custom_minimum_size = Vector2(14, 14); ricon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ricon.modulate = ThemeConfig.WARNING; rhbox.add_child(ricon); rhbox.add_child(rhl); rv.add_child(rhbox)
	var rdesc = Label.new(); rdesc.text = "Explore o perímetro com Marcus e Pedro. Aumente intensidade 3PT para 80%+ e use rotação rápida para cansar o oponente."; rdesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; rdesc.add_theme_font_size_override("font_size", 12); rdesc.custom_minimum_size = Vector2(100, 0); rv.add_child(rdesc)
	var rbtn = Button.new(); rbtn.text = "APLICAR ESTRATÉGIA"; rbtn.icon = load("res://addons/at-icons/control/magic_wand.svg"); rbtn.add_theme_constant_override("h_separation", 8); rbtn.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); rbtn.add_theme_font_size_override("font_size", 12)
	var srb = StyleBoxFlat.new(); srb.bg_color = ThemeConfig.BRAND_PRIMARY; srb.corner_radius_top_left=6; srb.corner_radius_bottom_right=6; srb.corner_radius_bottom_left=6; srb.corner_radius_top_right=6; srb.content_margin_top=8; srb.content_margin_bottom=8
	rbtn.add_theme_stylebox_override("normal", srb)
	rv.add_child(rbtn)
	vb.add_child(rec)
	
	var p2 = PanelContainer.new(); p2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sp2 = StyleBoxFlat.new(); sp2.bg_color = ThemeConfig.BG_APP; sp2.corner_radius_top_left=12; sp2.corner_radius_bottom_right=12; sp2.corner_radius_bottom_left=12; sp2.corner_radius_top_right=12; sp2.border_width_left=1; sp2.border_width_right=1; sp2.border_width_top=1; sp2.border_width_bottom=1; sp2.border_color = ThemeConfig.BORDER_SUBTLE
	p2.add_theme_stylebox_override("panel", sp2)
	var m2 = MarginContainer.new(); m2.add_theme_constant_override("margin_left", 16); m2.add_theme_constant_override("margin_right", 16); m2.add_theme_constant_override("margin_top", 16); m2.add_theme_constant_override("margin_bottom", 16); p2.add_child(m2)
	var v2 = VBoxContainer.new(); v2.add_theme_constant_override("separation", 16); m2.add_child(v2)
	
	var jtop = HBoxContainer.new()
	var jl = Label.new(); jl.text = "JOGADAS ENSAIADAS"; jl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); jl.add_theme_font_size_override("font_size", 10); jl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); jl.add_theme_constant_override("letter_spacing", 1); jtop.add_child(jl)
	var jsp = Control.new(); jsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; jtop.add_child(jsp)
	var jc = Label.new(); jc.text = "4/8"; jc.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); jc.add_theme_font_size_override("font_size", 10); jc.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); jtop.add_child(jc)
	v2.add_child(jtop)
	
	v2.add_child(_create_play("Pick & Roll Alto", "Marcus - Tyrone", 5, "link"))
	v2.add_child(_create_play("Drive & Kick", "Pedro - Carlos 3pt", 4, "arrow_right"))
	v2.add_child(_create_play("Iso Wing", "Carlos · 1v1", 4, "target"))
	v2.add_child(_create_play("Post-Up Pivô", "Tyrone · garrafão", 3, "clock"))
	v2.add_child(_create_play("Transition Break", "Defesa - Ataque rápido", 4, "lightning_bolt"))
	
	vb.add_child(p2)
	
	m.add_child(vb); scroll.add_child(m); p.add_child(scroll); parent.add_child(p)

func _create_adv_stat(title: String, val: String, color: Color, icon: String, active: bool = false) -> HBoxContainer:
	var h = HBoxContainer.new()
	var p = PanelContainer.new()
	if active:
		var sp = StyleBoxFlat.new(); sp.bg_color = Color(0,0,0,0); sp.border_width_left=1; sp.border_width_right=1; sp.border_width_top=1; sp.border_width_bottom=1; sp.border_color = color; sp.corner_radius_top_left=4; sp.corner_radius_bottom_right=4; sp.corner_radius_bottom_left=4; sp.corner_radius_top_right=4
		p.add_theme_stylebox_override("panel", sp)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 8); m.add_theme_constant_override("margin_right", 8); m.add_theme_constant_override("margin_top", 4); m.add_theme_constant_override("margin_bottom", 4); p.add_child(m)
	var hb = HBoxContainer.new(); hb.add_theme_constant_override("separation", 8); m.add_child(hb)
	
	var i = TextureRect.new(); i.texture = load("res://addons/at-icons/control/" + icon + ".svg"); i.custom_minimum_size = Vector2(16, 16); i.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; i.modulate = color; i.size_flags_vertical = Control.SIZE_SHRINK_CENTER; hb.add_child(i)
	var t = Label.new(); t.text = title; t.add_theme_font_size_override("font_size", 12); hb.add_child(t)
	h.add_child(p)
	
	var space = Control.new(); space.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(space)
	var v = Label.new(); v.text = val; v.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); v.add_theme_font_size_override("font_size", 12); v.add_theme_color_override("font_color", color); h.add_child(v)
	return h

func _create_play(title: String, sub: String, stars: int, icon: String) -> PanelContainer:
	var p = PanelContainer.new()
	var s = StyleBoxFlat.new(); s.bg_color = Color(0,0,0,0); s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = ThemeConfig.BORDER_SUBTLE; s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8
	p.add_theme_stylebox_override("panel", s)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 12); m.add_theme_constant_override("margin_right", 12); m.add_theme_constant_override("margin_top", 8); m.add_theme_constant_override("margin_bottom", 8); p.add_child(m)
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 16); m.add_child(h)
	
	var ic = TextureRect.new(); ic.texture = load("res://addons/at-icons/control/" + icon + ".svg"); ic.custom_minimum_size = Vector2(16, 16); ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ic.modulate = ThemeConfig.TEXT_MUTED; ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER; h.add_child(ic)
	
	var v = VBoxContainer.new(); v.alignment = BoxContainer.ALIGNMENT_CENTER
	var t = Label.new(); t.text = title; t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_font_size_override("font_size", 12); v.add_child(t)
	var su = Label.new(); su.text = sub; su.add_theme_font_size_override("font_size", 10); su.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); v.add_child(su)
	h.add_child(v)
	
	var space = Control.new(); space.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(space)
	
	var sbox = HBoxContainer.new(); sbox.add_theme_constant_override("separation", 2); sbox.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(5):
		var st = TextureRect.new(); st.texture = load("res://addons/at-icons/control/star.svg"); st.custom_minimum_size = Vector2(10, 10); st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		st.modulate = ThemeConfig.WARNING if i < stars else ThemeConfig.BORDER_SUBTLE
		sbox.add_child(st)
	h.add_child(sbox)
	
	return p
