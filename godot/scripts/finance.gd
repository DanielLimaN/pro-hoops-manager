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
	_build_right_col(content)

func _build_top_bar(parent: Node):
	var topbar_scene = preload("res://scenes/components/topbar.tscn")
	var tb = topbar_scene.instantiate()
	tb.screen_title = "FINANÇAS"
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
	
	var tabs = ["VISÃO GERAL", "RECEITAS", "DESPESAS", "CONTRATOS", "PATROCÍNIOS"]
	var tab_box = HBoxContainer.new()
	tab_box.add_theme_constant_override("separation", 8)
	for i in range(tabs.size()):
		var b = Button.new()
		b.text = tabs[i]
		b.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		b.add_theme_font_size_override("font_size", 12)
		var s = StyleBoxFlat.new(); s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8; s.content_margin_left=16; s.content_margin_right=16; s.content_margin_top=8; s.content_margin_bottom=8
		if i == 0:
			b.icon = load("res://addons/at-icons/control/coins.svg")
			b.add_theme_constant_override("h_separation", 8)
			s.bg_color = ThemeConfig.BRAND_PRIMARY; s.border_width_bottom=0
			b.add_theme_color_override("font_color", Color.WHITE)
			b.add_theme_color_override("icon_normal_color", Color.WHITE)
		else:
			if i == 1: b.icon = load("res://addons/at-icons/control/arrow_up_right.svg")
			elif i == 2: b.icon = load("res://addons/at-icons/control/arrow_down_right.svg")
			elif i == 3: b.icon = load("res://addons/at-icons/control/file.svg")
			elif i == 4: b.text = "$ " + b.text
			b.add_theme_constant_override("h_separation", 8)
			s.bg_color = Color(0,0,0,0); s.border_width_bottom=0
			b.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
			b.add_theme_color_override("icon_normal_color", ThemeConfig.TEXT_MUTED)
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", s)
		tab_box.add_child(b)
	
	h.add_child(tab_box)
	
	var space = Control.new(); space.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(space)
	
	var filter_box = HBoxContainer.new(); filter_box.add_theme_constant_override("separation", 8); filter_box.alignment = BoxContainer.ALIGNMENT_CENTER
	filter_box.add_child(_create_filter_btn("7D", false))
	filter_box.add_child(_create_filter_btn("30D", false))
	filter_box.add_child(_create_filter_btn("TRIMESTRE", true))
	filter_box.add_child(_create_filter_btn("ANO", false))
	filter_box.add_child(_create_filter_btn("TUDO", false))
	h.add_child(filter_box)
	
	parent.add_child(h)

func _create_filter_btn(text: String, active: bool) -> PanelContainer:
	var p = PanelContainer.new()
	var s = StyleBoxFlat.new(); s.bg_color = ThemeConfig.BRAND_PRIMARY if active else Color(0,0,0,0); s.corner_radius_top_left=12; s.corner_radius_bottom_right=12; s.corner_radius_bottom_left=12; s.corner_radius_top_right=12; s.border_width_left=1 if not active else 0; s.border_width_right=1 if not active else 0; s.border_width_top=1 if not active else 0; s.border_width_bottom=1 if not active else 0; s.border_color = ThemeConfig.BORDER_SUBTLE
	p.add_theme_stylebox_override("panel", s)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 12); m.add_theme_constant_override("margin_right", 12); m.add_theme_constant_override("margin_top", 4); m.add_theme_constant_override("margin_bottom", 4); p.add_child(m)
	var l = Label.new(); l.text = text; l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); l.add_theme_font_size_override("font_size", 10); l.add_theme_color_override("font_color", Color.WHITE if active else ThemeConfig.TEXT_MUTED); m.add_child(l)
	return p

func _build_kpis(parent: Node):
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	
	h.add_child(_create_stat_card("SALDO ATUAL", "R$ 12.4M", ThemeConfig.BRAND_PRIMARY, "coins", "+R$ 2.1M vs trimestre", true))
	h.add_child(_create_stat_card("RECEITAS (TRIM.)", "R$ 38.6M", ThemeConfig.SUCCESS, "arrow_up_right", "+18.2% vs Q3", true))
	h.add_child(_create_stat_card("DESPESAS (TRIM.)", "R$ 26.2M", ThemeConfig.DANGER, "arrow_down_right", "+5.4% vs Q3", false, ThemeConfig.DANGER))
	h.add_child(_create_stat_card("MARGEM LÍQUIDA", "32.1%", ThemeConfig.WARNING, "%", "+8.4pp lucratividade", true))
	h.add_child(_create_stat_card("SALARY CAP", "78%", Color("#3B82F6"), "#", "+R$ 1.8M espaço livre", true))
	
	parent.add_child(h)

func _create_stat_card(title: String, val: String, color: Color, icon: String, sub: String, positive: bool, val_color: Color = Color.WHITE) -> PanelContainer:
	var p = PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s = StyleBoxFlat.new(); s.bg_color = ThemeConfig.BG_SURFACE; s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8; s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = ThemeConfig.BORDER_SUBTLE
	p.add_theme_stylebox_override("panel", s)
	
	var bg_grad = TextureRect.new(); var g2d = GradientTexture2D.new(); var g = Gradient.new(); g.set_color(0, Color(color.r, color.g, color.b, 0.05)); g.set_color(1, Color(0,0,0,0)); g2d.gradient = g; g2d.fill_from = Vector2(0.5, 0); g2d.fill_to = Vector2(0.5, 0.6); bg_grad.texture = g2d; bg_grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg_grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); p.add_child(bg_grad)
	
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 16); m.add_theme_constant_override("margin_right", 16); m.add_theme_constant_override("margin_top", 12); m.add_theme_constant_override("margin_bottom", 12); p.add_child(m)
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", 16); m.add_child(v)
	
	var htop = HBoxContainer.new(); htop.add_theme_constant_override("separation", 12)
	var t = Label.new(); t.text = title; t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_font_size_override("font_size", 10); t.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; htop.add_child(t)
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; htop.add_child(sp)
	
	var ic = PanelContainer.new(); ic.custom_minimum_size = Vector2(24, 24)
	var sic = StyleBoxFlat.new(); sic.bg_color = Color(color.r, color.g, color.b, 0.1); sic.corner_radius_top_left=6; sic.corner_radius_bottom_right=6; sic.corner_radius_bottom_left=6; sic.corner_radius_top_right=6; sic.border_width_left=1; sic.border_width_right=1; sic.border_width_top=1; sic.border_width_bottom=1; sic.border_color = color; ic.add_theme_stylebox_override("panel", sic)
	var lic = Label.new(); lic.text = icon; lic.add_theme_color_override("font_color", color); lic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lic.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; ic.add_child(lic); htop.add_child(ic)
	v.add_child(htop)
	
	var vtext = VBoxContainer.new(); vtext.add_theme_constant_override("separation", 4)
	var vl = Label.new(); vl.text = val; vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); vl.add_theme_font_size_override("font_size", 24); vl.add_theme_color_override("font_color", val_color); vtext.add_child(vl)
	
	var hb_sub = HBoxContainer.new(); hb_sub.add_theme_constant_override("separation", 4)
	var arr = TextureRect.new(); arr.texture = load("res://addons/at-icons/control/arrow_up_right.svg" if positive else "res://addons/at-icons/control/arrow_down_right.svg"); arr.custom_minimum_size = Vector2(10, 10); arr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; arr.modulate = ThemeConfig.SUCCESS if positive else ThemeConfig.DANGER; arr.size_flags_vertical = Control.SIZE_SHRINK_CENTER; hb_sub.add_child(arr)
	var subl = Label.new(); subl.text = sub; subl.add_theme_font_size_override("font_size", 10); subl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hb_sub.add_child(subl)
	vtext.add_child(hb_sub)
	v.add_child(vtext)
	
	return p

func _create_main_panel(ratio: float) -> PanelContainer:
	var p = preload("res://scenes/ui/components/container_base.tscn").instantiate()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL; p.size_flags_vertical = Control.SIZE_EXPAND_FILL; p.size_flags_stretch_ratio = ratio
	return p

func _build_left_col(parent: Node):
	var v_left = VBoxContainer.new(); v_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL; v_left.size_flags_vertical = Control.SIZE_EXPAND_FILL; v_left.size_flags_stretch_ratio = 2.0; v_left.add_theme_constant_override("separation", 16)
	
	var top_p = _create_main_panel(1.0)
	var top_m = MarginContainer.new(); top_m.add_theme_constant_override("margin_left", 20); top_m.add_theme_constant_override("margin_right", 20); top_m.add_theme_constant_override("margin_top", 20); top_m.add_theme_constant_override("margin_bottom", 20); top_p.add_child(top_m)
	var top_v = VBoxContainer.new(); top_v.add_theme_constant_override("separation", 16); top_m.add_child(top_v)
	
	var h_legend = HBoxContainer.new()
	var ti = TextureRect.new(); ti.texture = load("res://addons/at-icons/control/arrow_up_right.svg"); ti.custom_minimum_size = Vector2(14, 14); ti.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ti.modulate = ThemeConfig.TEXT_MUTED; h_legend.add_child(ti)
	var tl = Label.new(); tl.text = "FLUXO DE CAIXA · ÚLTIMOS 12 MESES"; tl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); tl.add_theme_font_size_override("font_size", 10); tl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); tl.add_theme_constant_override("letter_spacing", 1); h_legend.add_child(tl)
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h_legend.add_child(sp)
	h_legend.add_child(_create_legend_item("RECEITA", ThemeConfig.SUCCESS))
	h_legend.add_child(_create_legend_item("DESPESA", ThemeConfig.DANGER))
	h_legend.add_child(_create_legend_item("SALDO", ThemeConfig.BRAND_PRIMARY))
	top_v.add_child(h_legend)
	
	var chart = HBoxContainer.new(); chart.size_flags_vertical = Control.SIZE_EXPAND_FILL; chart.alignment = BoxContainer.ALIGNMENT_CENTER; chart.add_theme_constant_override("separation", 32)
	var months = ["DEZ","JAN","FEV","MAR","ABR","MAI","JUN","JUL","AGO","SET","OUT","NOV"]
	var vals = [
		[40, 60], [45, 65], [42, 45], [48, 55], [50, 52], [55, 45],
		[60, 48], [48, 48], [45, 55], [60, 45], [75, 48], [80, 50]
	]
	for i in range(months.size()):
		chart.add_child(_create_chart_col(months[i], vals[i][0], vals[i][1], i == 11))
	top_v.add_child(chart)
	v_left.add_child(top_p)
	
	var h_bot = HBoxContainer.new(); h_bot.size_flags_vertical = Control.SIZE_EXPAND_FILL; h_bot.add_theme_constant_override("separation", 16)
	
	# Receitas Categoria
	var p_rec = _create_main_panel(1.0)
	var m_rec = MarginContainer.new(); m_rec.add_theme_constant_override("margin_left", 20); m_rec.add_theme_constant_override("margin_right", 20); m_rec.add_theme_constant_override("margin_top", 20); m_rec.add_theme_constant_override("margin_bottom", 20); p_rec.add_child(m_rec)
	var v_rec = VBoxContainer.new(); v_rec.add_theme_constant_override("separation", 16); m_rec.add_child(v_rec)
	var h_rec_t = HBoxContainer.new()
	var lrti = TextureRect.new(); lrti.texture = load("res://addons/at-icons/control/arrow_up.svg"); lrti.custom_minimum_size = Vector2(14, 14); lrti.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; lrti.modulate = ThemeConfig.SUCCESS; h_rec_t.add_child(lrti)
	var lrt = Label.new(); lrt.text = "RECEITAS POR CATEGORIA"; lrt.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lrt.add_theme_font_size_override("font_size", 10); lrt.add_theme_color_override("font_color", ThemeConfig.SUCCESS); lrt.add_theme_constant_override("letter_spacing", 1); h_rec_t.add_child(lrt)
	var spr = Control.new(); spr.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h_rec_t.add_child(spr)
	var lrv = Label.new(); lrv.text = "R$ 38.6M"; lrv.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lrv.add_theme_font_size_override("font_size", 12); lrv.add_theme_color_override("font_color", ThemeConfig.SUCCESS); h_rec_t.add_child(lrv)
	v_rec.add_child(h_rec_t)
	var scroll_rec = ScrollContainer.new(); scroll_rec.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll_rec.size_flags_vertical = Control.SIZE_EXPAND_FILL; v_rec.add_child(scroll_rec)
	var list_rec = VBoxContainer.new(); list_rec.size_flags_horizontal = Control.SIZE_EXPAND_FILL; list_rec.add_theme_constant_override("separation", 12); scroll_rec.add_child(list_rec)
	list_rec.add_child(_create_cat_bar("Bilheteria", "R$ 14.2M", "37%", ThemeConfig.SUCCESS, 0.37))
	list_rec.add_child(_create_cat_bar("Patrocínios", "R$ 11.8M", "31%", Color("#3B82F6"), 0.31))
	list_rec.add_child(_create_cat_bar("Merchandising", "R$ 6.4M", "17%", ThemeConfig.BRAND_PRIMARY, 0.17))
	list_rec.add_child(_create_cat_bar("Premiação Liga", "R$ 3.8M", "10%", ThemeConfig.WARNING, 0.10))
	list_rec.add_child(_create_cat_bar("Direitos TV", "R$ 2.4M", "5%", ThemeConfig.HIGHLIGHT, 0.05))
	h_bot.add_child(p_rec)
	
	# Despesas Categoria
	var p_des = _create_main_panel(1.0)
	var m_des = MarginContainer.new(); m_des.add_theme_constant_override("margin_left", 20); m_des.add_theme_constant_override("margin_right", 20); m_des.add_theme_constant_override("margin_top", 20); m_des.add_theme_constant_override("margin_bottom", 20); p_des.add_child(m_des)
	var v_des = VBoxContainer.new(); v_des.add_theme_constant_override("separation", 16); m_des.add_child(v_des)
	var h_des_t = HBoxContainer.new()
	var ldti = TextureRect.new(); ldti.texture = load("res://addons/at-icons/control/arrow_down.svg"); ldti.custom_minimum_size = Vector2(14, 14); ldti.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ldti.modulate = ThemeConfig.DANGER; h_des_t.add_child(ldti)
	var ldt = Label.new(); ldt.text = "DESPESAS POR CATEGORIA"; ldt.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); ldt.add_theme_font_size_override("font_size", 10); ldt.add_theme_color_override("font_color", ThemeConfig.DANGER); ldt.add_theme_constant_override("letter_spacing", 1); h_des_t.add_child(ldt)
	var spd = Control.new(); spd.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h_des_t.add_child(spd)
	var ldv = Label.new(); ldv.text = "R$ 26.2M"; ldv.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); ldv.add_theme_font_size_override("font_size", 12); ldv.add_theme_color_override("font_color", ThemeConfig.DANGER); h_des_t.add_child(ldv)
	v_des.add_child(h_des_t)
	var scroll_des = ScrollContainer.new(); scroll_des.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll_des.size_flags_vertical = Control.SIZE_EXPAND_FILL; v_des.add_child(scroll_des)
	var list_des = VBoxContainer.new(); list_des.size_flags_horizontal = Control.SIZE_EXPAND_FILL; list_des.add_theme_constant_override("separation", 12); scroll_des.add_child(list_des)
	list_des.add_child(_create_cat_bar("Salários Jogadores", "R$ 16.8M", "64%", ThemeConfig.DANGER, 0.64))
	list_des.add_child(_create_cat_bar("Equipe Técnica", "R$ 3.2M", "12%", ThemeConfig.WARNING, 0.12))
	list_des.add_child(_create_cat_bar("Infraestrutura", "R$ 2.4M", "9%", ThemeConfig.WARNING, 0.09))
	list_des.add_child(_create_cat_bar("Viagens & Logística", "R$ 1.8M", "7%", ThemeConfig.BRAND_PRIMARY, 0.07))
	list_des.add_child(_create_cat_bar("Marketing", "R$ 1.6M", "6%", Color("#3B82F6"), 0.06))
	list_des.add_child(_create_cat_bar("Médico & Outros", "R$ 0.4M", "2%", ThemeConfig.TEXT_MUTED, 0.02))
	h_bot.add_child(p_des)
	
	v_left.add_child(h_bot)
	parent.add_child(v_left)

func _create_legend_item(text: String, color: Color) -> HBoxContainer:
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 6)
	var c = ColorRect.new(); c.custom_minimum_size = Vector2(8, 8); c.color = color; c.size_flags_vertical = Control.SIZE_SHRINK_CENTER; h.add_child(c)
	var l = Label.new(); l.text = text; l.add_theme_font_size_override("font_size", 9); l.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); h.add_child(l)
	return h

func _create_chart_col(month: String, rec_val: float, des_val: float, active: bool) -> VBoxContainer:
	var v = VBoxContainer.new(); v.alignment = BoxContainer.ALIGNMENT_END; v.add_theme_constant_override("separation", 8)
	var h_bars = HBoxContainer.new(); h_bars.alignment = BoxContainer.ALIGNMENT_CENTER; h_bars.add_theme_constant_override("separation", 2); h_bars.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var rec = ColorRect.new(); rec.custom_minimum_size = Vector2(6, max(4, rec_val * 1.5)); rec.color = ThemeConfig.SUCCESS; rec.size_flags_vertical = Control.SIZE_SHRINK_END
	var rec_glow = TextureRect.new(); var g2 = GradientTexture2D.new(); var gg = Gradient.new(); gg.set_color(0, Color(ThemeConfig.SUCCESS.r, ThemeConfig.SUCCESS.g, ThemeConfig.SUCCESS.b, 1.0)); gg.set_color(1, Color(ThemeConfig.SUCCESS.r, ThemeConfig.SUCCESS.g, ThemeConfig.SUCCESS.b, 0.0)); g2.gradient = gg; g2.fill_from = Vector2(0,0); g2.fill_to = Vector2(0,1); rec_glow.texture = g2; rec_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; rec_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); rec.add_child(rec_glow)
	h_bars.add_child(rec)
	
	var des = ColorRect.new(); des.custom_minimum_size = Vector2(6, max(4, des_val * 1.5)); des.color = ThemeConfig.DANGER; des.size_flags_vertical = Control.SIZE_SHRINK_END
	var des_glow = TextureRect.new(); var g3 = GradientTexture2D.new(); var ggg = Gradient.new(); ggg.set_color(0, Color(ThemeConfig.DANGER.r, ThemeConfig.DANGER.g, ThemeConfig.DANGER.b, 1.0)); ggg.set_color(1, Color(ThemeConfig.DANGER.r, ThemeConfig.DANGER.g, ThemeConfig.DANGER.b, 0.0)); g3.gradient = ggg; g3.fill_from = Vector2(0,0); g3.fill_to = Vector2(0,1); des_glow.texture = g3; des_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; des_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); des.add_child(des_glow)
	h_bars.add_child(des)
	
	v.add_child(h_bars)
	
	var l = Label.new(); l.text = month; l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); l.add_theme_font_size_override("font_size", 9); l.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY if active else ThemeConfig.TEXT_MUTED); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(l)
	return v

func _create_cat_bar(title: String, val: String, pct: String, color: Color, prog: float) -> VBoxContainer:
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", 6); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h = HBoxContainer.new()
	var c = ColorRect.new(); c.custom_minimum_size = Vector2(4, 12); c.color = color; c.size_flags_vertical = Control.SIZE_SHRINK_CENTER; h.add_child(c)
	var t = Label.new(); t.text = title; t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_font_size_override("font_size", 11); h.add_child(t)
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(sp)
	var vl = Label.new(); vl.text = val; vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); vl.add_theme_font_size_override("font_size", 11); h.add_child(vl)
	var pl = Label.new(); pl.text = pct; pl.add_theme_font_size_override("font_size", 10); pl.add_theme_color_override("font_color", color); h.add_child(pl)
	v.add_child(h)
	
	var bar = ColorRect.new(); bar.custom_minimum_size = Vector2(0, 2); bar.color = ThemeConfig.BG_ELEVATED
	var bctrl = Control.new(); bctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bctrl.anchor_right = prog
	var bfill = ColorRect.new(); bfill.color = color; bfill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bctrl.add_child(bfill); bar.add_child(bctrl)
	v.add_child(bar)
	return v

func _build_right_col(parent: Node):
	var v_right = VBoxContainer.new(); v_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL; v_right.size_flags_vertical = Control.SIZE_EXPAND_FILL; v_right.size_flags_stretch_ratio = 1.0; v_right.add_theme_constant_override("separation", 16)
	
	# Teto Salarial
	var p_cap = _create_main_panel(1.0)
	var m_cap = MarginContainer.new(); m_cap.add_theme_constant_override("margin_left", 20); m_cap.add_theme_constant_override("margin_right", 20); m_cap.add_theme_constant_override("margin_top", 20); m_cap.add_theme_constant_override("margin_bottom", 20); p_cap.add_child(m_cap)
	var v_cap = VBoxContainer.new(); v_cap.add_theme_constant_override("separation", 16); m_cap.add_child(v_cap)
	
	var hc_t = HBoxContainer.new()
	var lcti = TextureRect.new(); lcti.texture = load("res://addons/at-icons/control/clock.svg"); lcti.custom_minimum_size = Vector2(14, 14); lcti.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; lcti.modulate = ThemeConfig.TEXT_MUTED; hc_t.add_child(lcti)
	var lct = Label.new(); lct.text = "TETO SALARIAL"; lct.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lct.add_theme_font_size_override("font_size", 10); lct.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); lct.add_theme_constant_override("letter_spacing", 1); hc_t.add_child(lct)
	var spc = Control.new(); spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hc_t.add_child(spc)
	
	var bbadge = PanelContainer.new()
	var sbb = StyleBoxFlat.new(); sbb.bg_color = Color(0,0,0,0); sbb.border_width_left=1; sbb.border_width_right=1; sbb.border_width_top=1; sbb.border_width_bottom=1; sbb.border_color = ThemeConfig.SUCCESS; sbb.corner_radius_top_left=12; sbb.corner_radius_bottom_right=12; sbb.corner_radius_bottom_left=12; sbb.corner_radius_top_right=12; bbadge.add_theme_stylebox_override("panel", sbb)
	var mbb = MarginContainer.new(); mbb.add_theme_constant_override("margin_left", 8); mbb.add_theme_constant_override("margin_right", 8); mbb.add_theme_constant_override("margin_top", 2); mbb.add_theme_constant_override("margin_bottom", 2); bbadge.add_child(mbb)
	var lbb = Label.new(); lbb.text = "DENTRO DO LIMITE"; lbb.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lbb.add_theme_font_size_override("font_size", 8); lbb.add_theme_color_override("font_color", ThemeConfig.SUCCESS); mbb.add_child(lbb); hc_t.add_child(bbadge)
	v_cap.add_child(hc_t)
	
	var hc_v = HBoxContainer.new()
	var vc_l = VBoxContainer.new()
	var vcl1 = Label.new(); vcl1.text = "R$ 6.4M"; vcl1.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); vcl1.add_theme_font_size_override("font_size", 24); vc_l.add_child(vcl1)
	var vcl2 = Label.new(); vcl2.text = "usado / R$ 8.2M total"; vcl2.add_theme_font_size_override("font_size", 10); vcl2.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); vc_l.add_child(vcl2)
	hc_v.add_child(vc_l)
	var spc2 = Control.new(); spc2.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hc_v.add_child(spc2)
	var vc_r = VBoxContainer.new(); vc_r.alignment = BoxContainer.ALIGNMENT_END
	var vcr1 = Label.new(); vcr1.text = "R$ 1.8M"; vcr1.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); vcr1.add_theme_font_size_override("font_size", 16); vcr1.add_theme_color_override("font_color", ThemeConfig.SUCCESS); vcr1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; vc_r.add_child(vcr1)
	var vcr2 = Label.new(); vcr2.text = "disponível"; vcr2.add_theme_font_size_override("font_size", 10); vcr2.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); vcr2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; vc_r.add_child(vcr2)
	hc_v.add_child(vc_r)
	v_cap.add_child(hc_v)
	
	var hc_b = VBoxContainer.new(); hc_b.add_theme_constant_override("separation", 8)
	var bar = ColorRect.new(); bar.custom_minimum_size = Vector2(0, 8); bar.color = ThemeConfig.BG_ELEVATED
	var bctrl = Control.new(); bctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bctrl.anchor_right = 0.78
	var bfill = TextureRect.new(); bfill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bfill.custom_minimum_size = Vector2(0, 8); bfill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var g2 = GradientTexture2D.new(); var gg = Gradient.new(); gg.set_color(0, Color("#3B82F6")); gg.set_color(1, ThemeConfig.SUCCESS); g2.gradient = gg; g2.fill_from = Vector2(0,0); g2.fill_to = Vector2(1,0); bfill.texture = g2; bctrl.add_child(bfill); bar.add_child(bctrl)
	var limit_marker = ColorRect.new(); limit_marker.color = ThemeConfig.DANGER; limit_marker.custom_minimum_size = Vector2(2, 12); limit_marker.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE); limit_marker.anchor_left = 0.85; limit_marker.anchor_right = 0.85; limit_marker.position = Vector2(0, -2); bar.add_child(limit_marker)
	hc_b.add_child(bar)
	
	var hl_b = HBoxContainer.new()
	var hll1 = Label.new(); hll1.text = "R$ 0"; hll1.add_theme_font_size_override("font_size", 9); hll1.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hl_b.add_child(hll1)
	var sph1 = Control.new(); sph1.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hl_b.add_child(sph1)
	var hll2 = Label.new(); hll2.text = "85% LIMITE"; hll2.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); hll2.add_theme_font_size_override("font_size", 9); hll2.add_theme_color_override("font_color", ThemeConfig.DANGER); hl_b.add_child(hll2)
	var sph2 = Control.new(); sph2.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hl_b.add_child(sph2)
	var hll3 = Label.new(); hll3.text = "R$ 8.2M"; hll3.add_theme_font_size_override("font_size", 9); hll3.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hl_b.add_child(hll3)
	hc_b.add_child(hl_b)
	v_cap.add_child(hc_b)
	v_right.add_child(p_cap)
	
	# Transações
	var p_tr = _create_main_panel(1.0)
	var m_tr = MarginContainer.new(); m_tr.add_theme_constant_override("margin_left", 20); m_tr.add_theme_constant_override("margin_right", 20); m_tr.add_theme_constant_override("margin_top", 16); m_tr.add_theme_constant_override("margin_bottom", 16); p_tr.add_child(m_tr)
	var v_tr = VBoxContainer.new(); v_tr.add_theme_constant_override("separation", 16); m_tr.add_child(v_tr)
	var ht_t = HBoxContainer.new()
	var ltti = TextureRect.new(); ltti.texture = load("res://addons/at-icons/control/arrows_counterclockwise.svg"); ltti.custom_minimum_size = Vector2(14, 14); ltti.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ltti.modulate = ThemeConfig.BRAND_PRIMARY; ht_t.add_child(ltti)
	var ltt = Label.new(); ltt.text = "TRANSAÇÕES RECENTES"; ltt.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); ltt.add_theme_font_size_override("font_size", 10); ltt.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY); ltt.add_theme_constant_override("letter_spacing", 1); ht_t.add_child(ltt)
	var spt = Control.new(); spt.size_flags_horizontal = Control.SIZE_EXPAND_FILL; ht_t.add_child(spt)
	var ltv = Label.new(); ltv.text = "VER TODAS >"; ltv.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); ltv.add_theme_font_size_override("font_size", 9); ltv.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); ht_t.add_child(ltv)
	v_tr.add_child(ht_t)
	var sept = HSeparator.new(); v_tr.add_child(sept)
	var str_v = VBoxContainer.new(); str_v.add_theme_constant_override("separation", 16); v_tr.add_child(str_v)
	str_v.add_child(_create_transaction("coins", "Patrocínio Nike", "Pagamento mensal · 25 Nov", "+R$ 1.2M", true))
	str_v.add_child(_create_transaction("@", "Salário · Marcus Silva", "Folha de pagamento · 20 Nov", "-R$ 2.4M", false))
	str_v.add_child(_create_transaction("*", "Bilheteria vs Cangurus", "Receita de jogo · 18 Nov", "+R$ 850K", true))
	v_right.add_child(p_tr)
	
	# Patrocinadores
	var p_sp = _create_main_panel(1.0)
	var m_sp = MarginContainer.new(); m_sp.add_theme_constant_override("margin_left", 20); m_sp.add_theme_constant_override("margin_right", 20); m_sp.add_theme_constant_override("margin_top", 16); m_sp.add_theme_constant_override("margin_bottom", 16); p_sp.add_child(m_sp)
	var v_sp = VBoxContainer.new(); v_sp.add_theme_constant_override("separation", 16); m_sp.add_child(v_sp)
	var hs_t = HBoxContainer.new()
	var lsti = TextureRect.new(); lsti.texture = load("res://addons/at-icons/control/star.svg"); lsti.custom_minimum_size = Vector2(14, 14); lsti.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; lsti.modulate = ThemeConfig.WARNING; hs_t.add_child(lsti)
	var lst = Label.new(); lst.text = "PATROCINADORES TOP"; lst.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lst.add_theme_font_size_override("font_size", 10); lst.add_theme_color_override("font_color", ThemeConfig.WARNING); lst.add_theme_constant_override("letter_spacing", 1); hs_t.add_child(lst)
	var sps = Control.new(); sps.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hs_t.add_child(sps)
	var lsv = Label.new(); lsv.text = "4 ATIVOS"; lsv.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lsv.add_theme_font_size_override("font_size", 9); lsv.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hs_t.add_child(lsv)
	v_sp.add_child(hs_t)
	var ssp_v = VBoxContainer.new(); ssp_v.add_theme_constant_override("separation", 12); v_sp.add_child(ssp_v)
	ssp_v.add_child(_create_sponsor("NK", "Nike", "3 anos · PRINCIPAL", "R$ 1.2M", "/mês", ThemeConfig.BG_APP, Color.WHITE))
	ssp_v.add_child(_create_sponsor("IT", "Itaú", "2 anos · BANCO OFICIAL", "R$ 680K", "/mês", Color("#E46B25"), Color.WHITE))
	ssp_v.add_child(_create_sponsor("GT", "Gatorade", "5 anos · BEBIDAS", "R$ 420K", "/mês", Color("#E57A27"), Color.WHITE))
	ssp_v.add_child(_create_sponsor("SP", "Spotify BR", "1 anos · MÍDIA", "R$ 280K", "/mês", Color("#1DB954"), Color.WHITE))
	v_right.add_child(p_sp)
	
	parent.add_child(v_right)

func _create_transaction(icon: String, title: String, desc: String, val: String, positive: bool) -> HBoxContainer:
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 16)
	var ic = PanelContainer.new(); ic.custom_minimum_size = Vector2(36, 36); ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sic = StyleBoxFlat.new(); sic.bg_color = Color(ThemeConfig.SUCCESS.r, ThemeConfig.SUCCESS.g, ThemeConfig.SUCCESS.b, 0.1) if positive else Color(ThemeConfig.DANGER.r, ThemeConfig.DANGER.g, ThemeConfig.DANGER.b, 0.1); sic.corner_radius_top_left=18; sic.corner_radius_bottom_right=18; sic.corner_radius_bottom_left=18; sic.corner_radius_top_right=18; ic.add_theme_stylebox_override("panel", sic)
	var lic = Label.new(); lic.text = icon; lic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lic.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; ic.add_child(lic); h.add_child(ic)
	var v = VBoxContainer.new(); v.alignment = BoxContainer.ALIGNMENT_CENTER
	var t = Label.new(); t.text = title; t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_font_size_override("font_size", 11); v.add_child(t)
	var d = Label.new(); d.text = desc; d.add_theme_font_size_override("font_size", 9); d.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); v.add_child(d)
	h.add_child(v)
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(sp)
	var vl = Label.new(); vl.text = val; vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); vl.add_theme_font_size_override("font_size", 12); vl.add_theme_color_override("font_color", ThemeConfig.SUCCESS if positive else ThemeConfig.DANGER); h.add_child(vl)
	return h

func _create_sponsor(ini: String, title: String, desc: String, val: String, suf: String, bg_color: Color, txt_color: Color) -> PanelContainer:
	var p = PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s = StyleBoxFlat.new(); s.bg_color = Color(0,0,0,0); s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = ThemeConfig.BORDER_SUBTLE; s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8
	p.add_theme_stylebox_override("panel", s)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 12); m.add_theme_constant_override("margin_right", 12); m.add_theme_constant_override("margin_top", 8); m.add_theme_constant_override("margin_bottom", 8); p.add_child(m)
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 16); m.add_child(h)
	
	var ic = PanelContainer.new(); ic.custom_minimum_size = Vector2(36, 36); ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sic = StyleBoxFlat.new(); sic.bg_color = bg_color; sic.corner_radius_top_left=8; sic.corner_radius_bottom_right=8; sic.corner_radius_bottom_left=8; sic.corner_radius_top_right=8; ic.add_theme_stylebox_override("panel", sic)
	var lic = Label.new(); lic.text = ini; lic.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lic.add_theme_font_size_override("font_size", 12); lic.add_theme_color_override("font_color", txt_color); lic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lic.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; ic.add_child(lic); h.add_child(ic)
	
	var v = VBoxContainer.new(); v.alignment = BoxContainer.ALIGNMENT_CENTER
	var t = Label.new(); t.text = title; t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_font_size_override("font_size", 11); v.add_child(t)
	var d = Label.new(); d.text = desc; d.add_theme_font_size_override("font_size", 9); d.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); v.add_child(d)
	h.add_child(v)
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(sp)
	var v2 = VBoxContainer.new(); v2.alignment = BoxContainer.ALIGNMENT_CENTER
	var vl = Label.new(); vl.text = val; vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); vl.add_theme_font_size_override("font_size", 12); vl.add_theme_color_override("font_color", ThemeConfig.SUCCESS); vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; v2.add_child(vl)
	var dl = Label.new(); dl.text = suf; dl.add_theme_font_size_override("font_size", 9); dl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; v2.add_child(dl)
	h.add_child(v2)
	return p
