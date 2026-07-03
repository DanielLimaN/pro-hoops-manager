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
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)
	
	_build_top_bar(vbox)
	_build_tabs_and_search(vbox)
	_build_kpis(vbox)
	
	var content = HBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 24)
	vbox.add_child(content)
	
	_build_player_table(content)
	_build_player_detail(content)

func _build_top_bar(parent: Node):
	var topbar_scene = preload("res://scenes/components/topbar.tscn")
	var tb = topbar_scene.instantiate()
	tb.screen_title = "ELENCO"
	parent.add_child(tb)

func _build_tabs_and_search(parent: Node):
	var h = HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 16)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_add_tab_pill(tabs, "TODOS", "15", true)
	_add_tab_pill(tabs, "TITULARES", "5", false)
	_add_tab_pill(tabs, "ROTAÇÃO", "8", false)
	_add_tab_pill(tabs, "LESIONADOS", "2", false)
	_add_tab_pill(tabs, "JOVENS", "3", false)
	
	h.add_child(tabs)
	
	var right = preload("res://scenes/ui/components/header_filter.tscn").instantiate()
	right.search_placeholder = "Buscar jogador..."
	right.action_btn_text = "CONTRATAR"
	if right.has_node("%ActionBtn"):
		right.get_node("%ActionBtn").icon = load("res://addons/at-icons/control/plus.svg")
		if not Engine.is_editor_hint():
			var cs = StyleBoxFlat.new(); cs.bg_color = ThemeConfig.SUCCESS
			cs.corner_radius_top_left=8; cs.corner_radius_bottom_right=8; cs.corner_radius_bottom_left=8; cs.corner_radius_top_right=8
			right.get_node("%ActionBtn").add_theme_stylebox_override("normal", cs)
	
	h.add_child(right)
	parent.add_child(h)

func _add_tab_pill(parent: Node, txt: String, num: String, active: bool):
	var p = PanelContainer.new()
	var s = StyleBoxFlat.new()
	s.bg_color = ThemeConfig.BRAND_PRIMARY if active else Color(0,0,0,0)
	s.corner_radius_top_left=16; s.corner_radius_top_right=16; s.corner_radius_bottom_left=16; s.corner_radius_bottom_right=16
	p.add_theme_stylebox_override("panel", s)
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16); m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 8); m.add_theme_constant_override("margin_bottom", 8)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var l = Label.new()
	l.text = txt
	l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	l.add_theme_color_override("font_color", Color.WHITE if active else ThemeConfig.TEXT_MUTED)
	h.add_child(l)
	var n = PanelContainer.new()
	var ns = StyleBoxFlat.new(); ns.bg_color = Color(0,0,0,0.2) if active else ThemeConfig.BG_ELEVATED
	ns.corner_radius_top_left=10; ns.corner_radius_bottom_right=10; ns.corner_radius_bottom_left=10; ns.corner_radius_top_right=10
	n.add_theme_stylebox_override("panel", ns)
	var nm = MarginContainer.new()
	nm.add_theme_constant_override("margin_left",8); nm.add_theme_constant_override("margin_right",8)
	var nl = Label.new(); nl.text = num; nl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); nl.add_theme_font_size_override("font_size", 10)
	nl.add_theme_color_override("font_color", Color.WHITE if active else ThemeConfig.TEXT_MUTED)
	nm.add_child(nl); n.add_child(nm); h.add_child(n)
	m.add_child(h); p.add_child(m); parent.add_child(p)

func _build_kpis(parent: Node):
	var h = HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 24)
	
	_add_kpi(h, "star", "OVERALL MÉDIO", "82.4", "/100", ThemeConfig.BRAND_PRIMARY)
	_add_kpi(h, "calendar", "IDADE MÉDIA", "26.3", "anos", Color("#38BDF8"))
	_add_kpi(h, "coins", "SALÁRIO TOTAL", "R$ 8.2", "M/mês", ThemeConfig.SUCCESS)
	_add_kpi(h, "beaker", "QUÍMICA", "94", "/100", Color("#F43F5E"))
	
	parent.add_child(h)

func _add_kpi(parent: Node, icon: String, title: String, val: String, sub: String, c: Color):
	var p = preload("res://scenes/ui/components/container_base.tscn").instantiate()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 16); m.add_theme_constant_override("margin_bottom", 16)
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 16)
	
	var ic = PanelContainer.new(); ic.custom_minimum_size = Vector2(40,40); ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ics = StyleBoxFlat.new(); ics.bg_color = Color(c.r, c.g, c.b, 0.1)
	ics.corner_radius_top_left=8; ics.corner_radius_bottom_right=8; ics.corner_radius_top_right=8; ics.corner_radius_bottom_left=8
	ic.add_theme_stylebox_override("panel", ics)
	var il = TextureRect.new()
	il.texture = load("res://addons/at-icons/control/" + icon + ".svg")
	il.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	il.custom_minimum_size = Vector2(24, 24)
	il.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	il.modulate = c
	il.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	il.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.add_child(il); h.add_child(ic)
	
	var v = VBoxContainer.new()
	var t = Label.new(); t.text = title; t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_font_size_override("font_size", 10); t.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	v.add_child(t)
	var h2 = HBoxContainer.new(); h2.add_theme_constant_override("separation", 4)
	var vl = Label.new(); vl.text = val; vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); vl.add_theme_font_size_override("font_size", 24)
	h2.add_child(vl)
	var sl = Label.new(); sl.text = sub; sl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); sl.size_flags_vertical = Control.SIZE_SHRINK_END; sl.add_theme_font_size_override("font_size", 12)
	h2.add_child(sl)
	v.add_child(h2)
	h.add_child(v)
	
	m.add_child(h); p.add_child(m); parent.add_child(p)

func _build_player_table(parent: Node):
	var p = preload("res://scenes/ui/components/container_base.tscn").instantiate()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.size_flags_stretch_ratio = 2.0
	
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	
	# Header
	var cols = [
		{"n": "POS", "w": 48}, {"n": "JOGADOR", "w": 200}, {"n": "IDADE", "w": 60}, 
		{"n": "OVR", "w": 40}, {"n": "FORMA", "w": 100}, {"n": "ENERGIA", "w": 120},
		{"n": "CONTRATO", "w": 80}, {"n": "SALÁRIO", "w": 80}, {"n": "STATUS", "w": 80}
	]
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 16); m.add_theme_constant_override("margin_bottom", 16)
	var hh = HBoxContainer.new(); hh.add_theme_constant_override("separation", 16)
	for c in cols:
		var l = Label.new(); l.text = c.n; l.custom_minimum_size = Vector2(c.w, 0)
		if c.n == "JOGADOR": l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		l.add_theme_font_size_override("font_size", 10)
		l.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		l.add_theme_constant_override("letter_spacing", 1)
		hh.add_child(l)
	m.add_child(hh); vb.add_child(m)
	
	var div = ColorRect.new(); div.custom_minimum_size = Vector2(0,1); div.color = ThemeConfig.BORDER_SUBTLE
	vb.add_child(div)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 0)
	
	var p_data = [
		{"pos": "PG", "in": "MS", "n": "Marcus Silva", "sub": "The Maestro", "i": 28, "ovr": 92, "en": 88, "ct": "2 anos", "sal": "R$ 2.4M", "st": "ATIVO"},
		{"pos": "SG", "in": "JP", "n": "João Pedro", "sub": "Sniper", "i": 26, "ovr": 88, "en": 76, "ct": "3 anos", "sal": "R$ 1.8M", "st": "ATIVO"},
		{"pos": "SF", "in": "CM", "n": "Carlos Mendez", "sub": "El Capitán", "i": 31, "ovr": 86, "en": 65, "ct": "1 ano", "sal": "R$ 1.5M", "st": "ATIVO"},
		{"pos": "PF", "in": "AC", "n": "Anderson Costa", "sub": "The Beast", "i": 29, "ovr": 85, "en": 45, "ct": "2 anos", "sal": "R$ 1.3M", "st": "CANSADO"},
		{"pos": "C", "in": "TW", "n": "Tyrone Walker", "sub": "The Wall", "i": 32, "ovr": 83, "en": 30, "ct": "0.5 ano", "sal": "R$ 1.1M", "st": "LESIONADO"},
		{"pos": "PG", "in": "LA", "n": "Lucas Almeida", "sub": "Rookie", "i": 21, "ovr": 78, "en": 95, "ct": "4 anos", "sal": "R$ 480K", "st": "ATIVO"},
		{"pos": "SG", "in": "DR", "n": "Diego Ramos", "sub": "Flash", "i": 24, "ovr": 81, "en": 82, "ct": "2 anos", "sal": "R$ 720K", "st": "ATIVO"},
		{"pos": "SF", "in": "RS", "n": "Rafael Souza", "sub": "Iron Man", "i": 27, "ovr": 79, "en": 70, "ct": "3 anos", "sal": "R$ 650K", "st": "ATIVO"},
		{"pos": "PF", "in": "BO", "n": "Bruno Oliveira", "sub": "Hammer", "i": 25, "ovr": 76, "en": 88, "ct": "1 ano", "sal": "R$ 540K", "st": "ATIVO"},
		{"pos": "C", "in": "PH", "n": "Pedro Henrique", "sub": "Big Pete", "i": 23, "ovr": 74, "en": 92, "ct": "4 anos", "sal": "R$ 420K", "st": "ATIVO"}
	]
	
	for d in p_data:
		_add_player_row(list, d)
		
	scroll.add_child(list)
	vb.add_child(scroll)
	p.add_child(vb)
	parent.add_child(p)

func _add_player_row(parent: Node, d: Dictionary):
	var row = preload("res://scenes/ui/components/player_row.tscn").instantiate()
	row.player_data = d
	if d.n == "Marcus Silva":
		row.is_selected = true
	parent.add_child(row)

func _build_player_detail(parent: Node):
	var p = preload("res://scenes/ui/components/container_base.tscn").instantiate()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.size_flags_stretch_ratio = 1.0
	
	var card_grad = TextureRect.new()
	var cg2d = GradientTexture2D.new()
	var cg = Gradient.new()
	cg.set_color(0, Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.15))
	cg.set_color(1, Color(0,0,0,0))
	cg2d.gradient = cg
	cg2d.fill_from = Vector2(0.5, 0)
	cg2d.fill_to = Vector2(0.5, 0.6)
	card_grad.texture = cg2d
	card_grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_child(card_grad)
	
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var m = MarginContainer.new()
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_theme_constant_override("margin_left", 32); m.add_theme_constant_override("margin_right", 32)
	m.add_theme_constant_override("margin_top", 32); m.add_theme_constant_override("margin_bottom", 32)
	
	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 24)
	
	var th = HBoxContainer.new()
	var tl = Label.new(); tl.text = "JOGADOR SELECIONADO"; tl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); tl.add_theme_font_size_override("font_size", 10); tl.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY); tl.add_theme_constant_override("letter_spacing", 1); tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tr = Label.new(); tr.text = "ESTRELA"; tr.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); tr.add_theme_font_size_override("font_size", 10); tr.add_theme_color_override("font_color", ThemeConfig.WARNING)
	var tr_box = HBoxContainer.new(); tr_box.add_theme_constant_override("separation", 4)
	var tr_icon = TextureRect.new(); tr_icon.texture = load("res://addons/at-icons/control/star.svg"); tr_icon.custom_minimum_size = Vector2(12, 12); tr_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr_icon.modulate = ThemeConfig.WARNING
	tr_box.add_child(tr_icon); tr_box.add_child(tr)
	th.add_child(tl); th.add_child(tr_box); vb.add_child(th)
	
	# Profile header
	var ph = HBoxContainer.new(); ph.add_theme_constant_override("separation", 16)
	
	var av_container = Control.new()
	av_container.custom_minimum_size = Vector2(80, 80)
	
	var glow = TextureRect.new()
	var gg = GradientTexture2D.new()
	var gg_color = Gradient.new()
	gg_color.set_color(0, Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.6))
	gg_color.set_color(1, Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.0))
	gg.gradient = gg_color
	gg.fill = GradientTexture2D.FILL_RADIAL
	gg.fill_from = Vector2(0.5, 0.5)
	gg.fill_to = Vector2(1.0, 0.5)
	gg.width = 160
	gg.height = 160
	glow.texture = gg
	glow.position = Vector2(-40, -40)
	av_container.add_child(glow)
	
	var av = PanelContainer.new(); av.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var avs = StyleBoxFlat.new(); avs.bg_color = ThemeConfig.BRAND_PRIMARY; avs.corner_radius_top_left=40; avs.corner_radius_bottom_right=40; avs.corner_radius_top_right=40; avs.corner_radius_bottom_left=40
	avs.shadow_color = Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.4)
	avs.shadow_size = 20
	av.add_theme_stylebox_override("panel", avs)
	var al = Label.new(); al.text = "MS"; al.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); al.add_theme_font_size_override("font_size", 28); al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; al.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av.add_child(al); av_container.add_child(av); ph.add_child(av_container)
	
	var pv = VBoxContainer.new(); pv.alignment = BoxContainer.ALIGNMENT_CENTER; pv.add_theme_constant_override("separation", 4)
	var pnum = Label.new(); pnum.text = "#7"; pnum.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); pnum.add_theme_font_size_override("font_size", 12); pnum.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); pv.add_child(pnum)
	var pnam = Label.new(); pnam.text = "Marcus Silva"; pnam.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); pnam.add_theme_font_size_override("font_size", 24); pv.add_child(pnam)
	var psub = Label.new(); psub.text = "\"The Maestro\""; psub.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); pv.add_child(psub)
	ph.add_child(pv); vb.add_child(ph)
	
	# 4 stats boxes
	var sh = HBoxContainer.new(); sh.add_theme_constant_override("separation", 12); sh.alignment = BoxContainer.ALIGNMENT_CENTER
	_add_stat_box(sh, "POS", "PG")
	_add_stat_box(sh, "IDADE", "28")
	_add_stat_box(sh, "ALTURA", "1.91m")
	_add_stat_box(sh, "OVR", "92")
	vb.add_child(sh)
	
	var div1 = ColorRect.new(); div1.custom_minimum_size = Vector2(0,1); div1.color = ThemeConfig.BORDER_SUBTLE; vb.add_child(div1)
	
	# ATRIBUTOS
	var at = Label.new(); at.text = "ATRIBUTOS"; at.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); at.add_theme_font_size_override("font_size", 10); at.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY); at.add_theme_constant_override("letter_spacing", 1); vb.add_child(at)
	
	var ab = VBoxContainer.new(); ab.add_theme_constant_override("separation", 16)
	_add_attr_bar(ab, "Arremesso", 95, ThemeConfig.BRAND_PRIMARY)
	_add_attr_bar(ab, "Drible / Manejo", 96, ThemeConfig.BRAND_PRIMARY)
	_add_attr_bar(ab, "Passe / Visão", 94, ThemeConfig.BRAND_PRIMARY)
	_add_attr_bar(ab, "Defesa", 78, Color("#3B82F6"))
	_add_attr_bar(ab, "Atletismo", 85, ThemeConfig.SUCCESS)
	_add_attr_bar(ab, "QI de Quadra", 92, ThemeConfig.BRAND_PRIMARY)
	vb.add_child(ab)
	
	var div2 = ColorRect.new(); div2.custom_minimum_size = Vector2(0,1); div2.color = ThemeConfig.BORDER_SUBTLE; vb.add_child(div2)
	
	# QUINTETO TITULAR
	var qh = HBoxContainer.new()
	var qt = Label.new(); qt.text = "QUINTETO TITULAR"; qt.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); qt.add_theme_font_size_override("font_size", 10); qt.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY); qt.add_theme_constant_override("letter_spacing", 1); qt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var qe = PanelContainer.new(); var qes = StyleBoxFlat.new(); qes.bg_color = ThemeConfig.BG_ELEVATED; qes.corner_radius_top_left=4; qes.corner_radius_bottom_right=4; qes.corner_radius_bottom_left=4; qes.corner_radius_top_right=4; qe.add_theme_stylebox_override("panel", qes)
	var qem = MarginContainer.new(); qem.add_theme_constant_override("margin_left",8); qem.add_theme_constant_override("margin_right",8); qem.add_theme_constant_override("margin_top",4); qem.add_theme_constant_override("margin_bottom",4)
	var qel_box = HBoxContainer.new(); qel_box.add_theme_constant_override("separation", 4)
	var qei = TextureRect.new(); qei.texture = load("res://addons/at-icons/control/pencil.svg"); qei.custom_minimum_size = Vector2(10, 10); qei.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; qei.modulate = ThemeConfig.TEXT_MUTED; qel_box.add_child(qei)
	var qel = Label.new(); qel.text = "EDITAR"; qel.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); qel.add_theme_font_size_override("font_size", 9); qel.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); qel_box.add_child(qel)
	qem.add_child(qel_box); qe.add_child(qem)
	qh.add_child(qt); qh.add_child(qe); vb.add_child(qh)
	
	# Court mockup
	var court = PanelContainer.new()
	court.custom_minimum_size = Vector2(0, 180)
	court.clip_contents = true
	var cs = StyleBoxFlat.new(); cs.bg_color = ThemeConfig.BG_APP; cs.border_width_left=1; cs.border_width_right=1; cs.border_width_top=1; cs.border_width_bottom=1; cs.border_color=ThemeConfig.BORDER_SUBTLE; cs.corner_radius_top_left=12; cs.corner_radius_bottom_right=12; cs.corner_radius_bottom_left=12; cs.corner_radius_top_right=12
	court.add_theme_stylebox_override("panel", cs)
	
	var cctrl = Control.new()
	cctrl.set_script(preload("res://scripts/menu_court.gd"))
	court.add_child(cctrl)
	
	# Nodes
	_add_court_node(cctrl, "MS", ThemeConfig.BRAND_PRIMARY, Vector2(160, 80))
	_add_court_node(cctrl, "JP", Color("#3B82F6"), Vector2(80, 130))
	_add_court_node(cctrl, "CM", ThemeConfig.SUCCESS, Vector2(240, 130))
	
	vb.add_child(court)
	
	m.add_child(vb)
	scroll.add_child(m)
	p.add_child(scroll)
	parent.add_child(p)

func _add_stat_box(parent: Node, title: String, val: String):
	var p = PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s = StyleBoxFlat.new(); s.bg_color = ThemeConfig.BG_ELEVATED; s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8
	p.add_theme_stylebox_override("panel", s)
	var v = VBoxContainer.new(); v.alignment = BoxContainer.ALIGNMENT_CENTER
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_top", 12); m.add_theme_constant_override("margin_bottom", 12)
	var t = Label.new(); t.text = title; t.add_theme_font_size_override("font_size", 9); t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var val_lbl = Label.new(); val_lbl.text = val; val_lbl.add_theme_font_size_override("font_size", 16); val_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t); v.add_child(val_lbl); m.add_child(v); p.add_child(m); parent.add_child(p)

func _add_attr_bar(parent: Node, title: String, val: int, color: Color):
	var h = HBoxContainer.new()
	var tl = Label.new(); tl.text = title; tl.custom_minimum_size = Vector2(120, 0); tl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); tl.add_theme_font_size_override("font_size", 12)
	var ebox = VBoxContainer.new(); ebox.size_flags_horizontal = Control.SIZE_EXPAND_FILL; ebox.alignment = BoxContainer.ALIGNMENT_CENTER
	var ebar = ColorRect.new(); ebar.custom_minimum_size = Vector2(0, 6); ebar.color = ThemeConfig.BG_ELEVATED
	var w = (val / 100.0) * 160 # approximate for visual width
	
	var efill = TextureRect.new()
	efill.custom_minimum_size = Vector2(w, 6)
	var g2d = GradientTexture2D.new()
	var g = Gradient.new()
	g.set_color(0, Color(color.r, color.g, color.b, 0.2))
	g.set_color(1, color)
	g2d.gradient = g
	g2d.fill_from = Vector2(0, 0)
	g2d.fill_to = Vector2(1, 0)
	efill.texture = g2d
	efill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	ebar.add_child(efill); ebox.add_child(ebar)
	var vl = Label.new(); vl.text = str(val); vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); vl.add_theme_font_size_override("font_size", 14); vl.add_theme_color_override("font_color", color); vl.custom_minimum_size = Vector2(32, 0); vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(tl); h.add_child(ebox); h.add_child(vl)
	parent.add_child(h)

func _add_court_node(parent: Node, init: String, color: Color, pos: Vector2):
	var av = PanelContainer.new(); av.custom_minimum_size = Vector2(32, 32); av.position = pos - Vector2(16, 16)
	var as_st = StyleBoxFlat.new(); as_st.bg_color = color; as_st.corner_radius_top_left=16; as_st.corner_radius_bottom_right=16; as_st.corner_radius_top_right=16; as_st.corner_radius_bottom_left=16; av.add_theme_stylebox_override("panel", as_st)
	var al = Label.new(); al.text = init; al.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); al.add_theme_font_size_override("font_size", 10); al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; al.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av.add_child(al); parent.add_child(av)
