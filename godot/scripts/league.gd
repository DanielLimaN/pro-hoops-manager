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
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)
	
	_build_top_bar(vbox)
	_build_tabs_bar(vbox)
	
	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 24)
	vbox.add_child(main_hbox)
	
	_build_calendar(main_hbox)
	_build_right_sidebar(main_hbox)

func _build_top_bar(parent: Node):
	var topbar = HBoxContainer.new()
	
	var title_box = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 4)
	var sub = Label.new()
	sub.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	sub.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_constant_override("letter_spacing", 2)
	var tit = Label.new()
	tit.text = "Liga & Calendário"
	tit.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	tit.add_theme_color_override("font_color", Color.WHITE)
	tit.add_theme_font_size_override("font_size", 24)
	title_box.add_child(sub)
	title_box.add_child(tit)
	topbar.add_child(title_box)
	
	var right_actions = HBoxContainer.new()
	right_actions.add_theme_constant_override("separation", 12)
	right_actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	_create_pill(right_actions, "$", "ORÇAMENTO", "R$ 12.4M", ThemeConfig.SUCCESS)
	_create_pill(right_actions, "+", "MORAL", "87%", ThemeConfig.WARNING)
	_create_pill(right_actions, "E", "ENERGIA", "92%", ThemeConfig.INFO)
	
	# Bell Icon
	var bell = PanelContainer.new()
	bell.custom_minimum_size = Vector2(40, 40)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0,0,0,0)
	bs.border_color = ThemeConfig.BORDER_DEFAULT
	bs.border_width_left = 1; bs.border_width_top = 1; bs.border_width_right = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left = 8; bs.corner_radius_top_right = 8; bs.corner_radius_bottom_left = 8; bs.corner_radius_bottom_right = 8
	bell.add_theme_stylebox_override("panel", bs)
	var bell_lbl = Label.new()
	bell_lbl.text = "!"
	bell_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bell_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bell.add_child(bell_lbl)
	right_actions.add_child(bell)
	
	var adv = Button.new()
	adv.text = "AVANÇAR"
	var as_st = StyleBoxFlat.new()
	as_st.bg_color = ThemeConfig.BRAND_PRIMARY
	as_st.corner_radius_top_left = 8; as_st.corner_radius_top_right = 8; as_st.corner_radius_bottom_left = 8; as_st.corner_radius_bottom_right = 8
	as_st.content_margin_left = 24; as_st.content_margin_right = 24
	adv.add_theme_stylebox_override("normal", as_st)
	adv.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	right_actions.add_child(adv)
	
	topbar.add_child(right_actions)
	parent.add_child(topbar)

func _create_pill(parent: Node, icon_txt: String, lbl: String, val: String, color: Color):
	var p = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0,0,0,0)
	style.border_color = ThemeConfig.BORDER_DEFAULT
	style.border_width_left = 1; style.border_width_top = 1; style.border_width_right = 1; style.border_width_bottom = 1
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8; style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	p.add_theme_stylebox_override("panel", style)
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 6)
	m.add_theme_constant_override("margin_bottom", 6)
	p.add_child(m)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	m.add_child(h)
	var ic = Label.new()
	ic.text = icon_txt
	ic.add_theme_color_override("font_color", color)
	h.add_child(ic)
	var v = VBoxContainer.new()
	h.add_child(v)
	var l = Label.new()
	l.text = lbl
	l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	v.add_child(l)
	var va = Label.new()
	va.text = val
	va.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	va.add_theme_font_size_override("font_size", 14)
	v.add_child(va)
	parent.add_child(p)

func _build_tabs_bar(parent: Node):
	var h = HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 16)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_add_tab(tabs, "CALENDÁRIO", true)
	_add_tab(tabs, "CLASSIFICAÇÃO", false)
	_add_tab(tabs, "LÍDERES", false)
	_add_tab(tabs, "PLAYOFFS", false)
	
	h.add_child(tabs)
	
	var right = HBoxContainer.new()
	right.add_theme_constant_override("separation", 12)
	
	# Month selector
	var msel = PanelContainer.new()
	var ms_st = StyleBoxFlat.new()
	ms_st.bg_color = ThemeConfig.BG_ELEVATED
	ms_st.corner_radius_top_left = 6; ms_st.corner_radius_top_right = 6; ms_st.corner_radius_bottom_left = 6; ms_st.corner_radius_bottom_right = 6
	msel.add_theme_stylebox_override("panel", ms_st)
	var mh = HBoxContainer.new()
	var larr = Label.new(); larr.text = " < "; larr.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	var rarr = Label.new(); rarr.text = " > "; rarr.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	var mtxt = VBoxContainer.new()
	mtxt.custom_minimum_size = Vector2(100, 0)
	mtxt.alignment = BoxContainer.ALIGNMENT_CENTER
	var m1 = Label.new(); m1.text = "Novembro"; m1.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); m1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var m2 = Label.new(); m2.text = "2026"; m2.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); m2.add_theme_font_size_override("font_size", 10); m2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mtxt.add_child(m1); mtxt.add_child(m2)
	mh.add_child(larr); mh.add_child(mtxt); mh.add_child(rarr)
	msel.add_child(mh)
	right.add_child(msel)
	
	# Hoje btn
	var hoje = Button.new(); hoje.text = "HOJE"
	var h_st = StyleBoxFlat.new(); h_st.bg_color = Color(0,0,0,0); h_st.border_width_left=1;h_st.border_width_right=1;h_st.border_width_top=1;h_st.border_width_bottom=1;h_st.border_color = ThemeConfig.BORDER_DEFAULT; h_st.corner_radius_top_left=6;h_st.corner_radius_bottom_right=6;h_st.corner_radius_bottom_left=6;h_st.corner_radius_top_right=6
	h_st.content_margin_left = 16; h_st.content_margin_right = 16
	hoje.add_theme_stylebox_override("normal", h_st); hoje.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	right.add_child(hoje)
	
	# Filtros btn
	var filt = Button.new(); filt.text = "FILTROS"
	filt.add_theme_stylebox_override("normal", h_st); filt.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	right.add_child(filt)
	
	h.add_child(right)
	parent.add_child(h)

func _add_tab(parent: Node, txt: String, active: bool):
	var p = PanelContainer.new()
	var s = StyleBoxFlat.new()
	if active:
		s.bg_color = ThemeConfig.BRAND_PRIMARY
	else:
		s.bg_color = Color(0,0,0,0)
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6; s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	p.add_theme_stylebox_override("panel", s)
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 8)
	var l = Label.new()
	l.text = txt
	l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	if not active: l.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	m.add_child(l)
	p.add_child(m)
	parent.add_child(p)

func _build_calendar(parent: Node):
	var pnl = PanelContainer.new()
	pnl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pnl.size_flags_stretch_ratio = 2.0
	var style = StyleBoxFlat.new()
	style.bg_color = ThemeConfig.BG_SURFACE
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12; style.corner_radius_bottom_left = 12; style.corner_radius_bottom_right = 12
	style.border_color = ThemeConfig.BORDER_SUBTLE
	style.border_width_left = 1; style.border_width_top = 1; style.border_width_right = 1; style.border_width_bottom = 1
	pnl.add_theme_stylebox_override("panel", style)
	
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	
	# Days Header
	var dh = HBoxContainer.new()
	var days = ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SAB"]
	for d in days:
		var l = Label.new()
		l.text = d
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		l.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
		l.add_theme_font_size_override("font_size", 11)
		l.add_theme_constant_override("letter_spacing", 2)
		var m = MarginContainer.new()
		m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		m.add_theme_constant_override("margin_top", 16)
		m.add_theme_constant_override("margin_bottom", 16)
		m.add_child(l)
		dh.add_child(m)
	vb.add_child(dh)
	
	var div = ColorRect.new(); div.custom_minimum_size = Vector2(0,1); div.color = ThemeConfig.BORDER_SUBTLE
	vb.add_child(div)
	
	# Grid
	var grid_scroll = ScrollContainer.new()
	grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var grid = GridContainer.new()
	grid.columns = 7
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)
	
	var start_day = 26
	for i in range(35):
		var cell = PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var cs = StyleBoxFlat.new()
		cs.bg_color = Color(0,0,0,0)
		cs.border_width_right = 1; cs.border_width_bottom = 1
		cs.border_color = ThemeConfig.BORDER_SUBTLE
		if i % 7 == 6: cs.border_width_right = 0
		cell.add_theme_stylebox_override("panel", cs)
		
		var cm = MarginContainer.new()
		cm.add_theme_constant_override("margin_left", 12)
		cm.add_theme_constant_override("margin_top", 12)
		cm.add_theme_constant_override("margin_right", 12)
		cm.add_theme_constant_override("margin_bottom", 12)
		
		var cvb = VBoxContainer.new()
		
		var day_num = start_day + i
		if day_num > 31 and start_day == 26: day_num = day_num - 31
		elif day_num > 30 and start_day == 26 and i > 6: day_num = day_num - 30
		
		var num_lbl = Label.new()
		num_lbl.text = str(day_num)
		num_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		if i < 5: num_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		cvb.add_child(num_lbl)
		
		# Add fake match badges
		if i == 5: _add_match_badge(cvb, "20h00", "@ BHE", "98-91", true)
		if i == 8: _add_match_badge(cvb, "20h30", "vs RJF", "108-94", true)
		if i == 11: _add_match_badge(cvb, "21h00", "@ BSB", "112-105", true)
		if i == 14: _add_match_badge(cvb, "20h00", "vs REC", "98-103", false)
		if i == 17: _add_match_badge(cvb, "19h30", "@ POA", "118-99", true)
		if i == 20: _add_match_badge(cvb, "20h30", "vs CWB", "121-115", true)
		if i == 24: _add_match_badge(cvb, "20h00", "vs REC", "HOJE", null)
		if i == 26: _add_match_badge(cvb, "20h30", "@ POA", "", null)
		if i == 30: _add_match_badge(cvb, "19h30", "vs FOR", "", null)
		if i == 33: _add_match_badge(cvb, "20h00", "vs GNC", "", null)
		
		cm.add_child(cvb)
		cell.add_child(cm)
		grid.add_child(cell)
		
	grid_scroll.add_child(grid)
	vb.add_child(grid_scroll)
	pnl.add_child(vb)
	parent.add_child(pnl)

func _add_match_badge(parent: Node, time: String, opp: String, score: String, won):
	var p = PanelContainer.new()
	var s = StyleBoxFlat.new()
	if won == true:
		s.bg_color = Color("#064E3B")
		s.border_color = ThemeConfig.SUCCESS
	elif won == false:
		s.bg_color = Color("#450A0A")
		s.border_color = ThemeConfig.DANGER
	else:
		s.bg_color = Color("#172554")
		s.border_color = Color("#3B82F6")
	if score == "HOJE" or score == "":
		s.bg_color = ThemeConfig.BG_ELEVATED
		s.border_color = ThemeConfig.BORDER_SUBTLE
	
	s.border_width_left = 1; s.border_width_top = 1; s.border_width_right = 1; s.border_width_bottom = 1
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6; s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	p.add_theme_stylebox_override("panel", s)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 6)
	m.add_theme_constant_override("margin_right", 6)
	m.add_theme_constant_override("margin_top", 4)
	m.add_theme_constant_override("margin_bottom", 4)
	
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	
	var h = HBoxContainer.new()
	var tl = Label.new(); tl.text = time; tl.add_theme_font_size_override("font_size", 9); tl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	var type = Label.new(); type.text = "LIGA"; type.add_theme_font_size_override("font_size", 8); type.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); type.size_flags_horizontal = Control.SIZE_EXPAND_FILL; type.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if score == "HOJE": type.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
	elif won == false: type.add_theme_color_override("font_color", ThemeConfig.WARNING); type.text = "COPA"
	else: type.add_theme_color_override("font_color", Color("#38BDF8"))
	h.add_child(tl); h.add_child(type)
	v.add_child(h)
	
	var ol = Label.new(); ol.text = opp; ol.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); ol.add_theme_font_size_override("font_size", 11)
	v.add_child(ol)
	
	if score != "":
		var sl = Label.new(); sl.text = score; sl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); sl.add_theme_font_size_override("font_size", 11)
		if won == true: sl.add_theme_color_override("font_color", ThemeConfig.SUCCESS)
		elif won == false: sl.add_theme_color_override("font_color", ThemeConfig.DANGER)
		else: sl.add_theme_color_override("font_color", Color.WHITE)
		v.add_child(sl)
		
	m.add_child(v)
	p.add_child(m)
	
	p.gui_input.connect(_on_badge_gui_input.bind(opp, time, score))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	
	parent.add_child(p)

func _on_badge_gui_input(event: InputEvent, opp: String, time: String, score: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_match_modal(opp, time, score)

func _show_match_modal(opp: String, time: String, score: String):
	var modal_scene = load("res://scenes/ui/league/match_modal.tscn")
	if not modal_scene: return
	
	var modal = modal_scene.instantiate()
	add_child(modal)
	
	var team_abbr = "PHX"
	if GameManager.user_team_id > 0:
		var schedule = GameManager.get_schedule()
		for t in GameManager.league.get("teams", []):
			if t.get("id") == GameManager.user_team_id:
				team_abbr = t.get("abbreviation", "PHX")
				break
	
	var clean_opp = opp.replace("vs ", "").replace("@ ", "")
	
	var data = {
		"home_abbr": team_abbr if opp.begins_with("vs") else clean_opp,
		"away_abbr": clean_opp if opp.begins_with("vs") else team_abbr,
		"date": "Ter, 18 Nov", # Dummy
		"time": time,
		"games_until": 0,
		"prediction": 78
	}
	modal.set_match(data)
	modal.play_requested.connect(_on_modal_play_requested)
	modal.sim_requested.connect(_on_modal_sim_requested)

func _on_modal_play_requested(match_data: Dictionary):
	# Could transition to match.tscn here if we find the match id
	get_tree().change_scene_to_file("res://scenes/match.tscn")

func _on_modal_sim_requested(match_data: Dictionary):
	# Dummy simulate action
	GameManager.sim_week()

func _build_right_sidebar(parent: Node):
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 1.0
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 24)
	scroll.add_child(vb)
	
	# Top 6
	var p1 = PanelContainer.new()
	var s1 = StyleBoxFlat.new()
	s1.bg_color = ThemeConfig.BG_SURFACE
	s1.corner_radius_top_left=12; s1.corner_radius_top_right=12; s1.corner_radius_bottom_left=12; s1.corner_radius_bottom_right=12
	s1.border_color = ThemeConfig.BORDER_SUBTLE; s1.border_width_left=1; s1.border_width_right=1; s1.border_width_top=1; s1.border_width_bottom=1
	p1.add_theme_stylebox_override("panel", s1)
	var m1 = MarginContainer.new()
	m1.add_theme_constant_override("margin_left", 20); m1.add_theme_constant_override("margin_right", 20)
	m1.add_theme_constant_override("margin_top", 20); m1.add_theme_constant_override("margin_bottom", 20)
	var v1 = VBoxContainer.new()
	v1.add_theme_constant_override("separation", 16)
	var h1 = HBoxContainer.new()
	var t1 = Label.new(); t1.text = "TOP 6 • CONF. SUL"; t1.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t1.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); t1.add_theme_font_size_override("font_size", 12); t1.add_theme_constant_override("letter_spacing", 1)
	var vt = Label.new(); vt.text = "VER TUDO >"; vt.add_theme_font_size_override("font_size", 10); vt.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h1.add_child(t1); h1.add_child(vt)
	v1.add_child(h1)
	
	var div1 = ColorRect.new(); div1.custom_minimum_size = Vector2(0,1); div1.color = ThemeConfig.BORDER_SUBTLE; v1.add_child(div1)
	
	var teams = [
		{"n": "SP Phoenix", "w": "8-2", "p": ".800", "c": ThemeConfig.BRAND_PRIMARY},
		{"n": "Cangurus RJ", "w": "7-3", "p": ".700", "c": ThemeConfig.SUCCESS},
		{"n": "Jaguars BSB", "w": "7-3", "p": ".700", "c": ThemeConfig.WARNING},
		{"n": "Trovões CWB", "w": "6-4", "p": ".600", "c": ThemeConfig.SUCCESS},
		{"n": "Tubarões REC", "w": "5-5", "p": ".500", "c": ThemeConfig.SUCCESS},
		{"n": "Fênix MAN", "w": "5-5", "p": ".500", "c": ThemeConfig.SUCCESS}
	]
	var idx = 1
	for t in teams:
		var r = HBoxContainer.new(); r.add_theme_constant_override("separation", 12)
		var badge = PanelContainer.new(); badge.custom_minimum_size = Vector2(20,20); badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bs = StyleBoxFlat.new(); bs.bg_color = ThemeConfig.SUCCESS; bs.corner_radius_top_left=10; bs.corner_radius_bottom_right=10; bs.corner_radius_top_right=10; bs.corner_radius_bottom_left=10
		badge.add_theme_stylebox_override("panel", bs)
		var bl = Label.new(); bl.text = str(idx); bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; bl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); bl.add_theme_font_size_override("font_size", 10)
		badge.add_child(bl)
		r.add_child(badge)
		var dot = PanelContainer.new(); dot.custom_minimum_size = Vector2(6,6); dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var ds = StyleBoxFlat.new(); ds.bg_color = t.c; ds.corner_radius_top_left=3; ds.corner_radius_bottom_right=3; ds.corner_radius_top_right=3; ds.corner_radius_bottom_left=3
		dot.add_theme_stylebox_override("panel", ds)
		r.add_child(dot)
		var nl = Label.new(); nl.text = t.n; nl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL; nl.add_theme_font_size_override("font_size", 12)
		r.add_child(nl)
		var wl = Label.new(); wl.text = t.w; wl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); wl.add_theme_font_size_override("font_size", 12)
		r.add_child(wl)
		var pl = Label.new(); pl.text = t.p; pl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); pl.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY); pl.add_theme_font_size_override("font_size", 12)
		r.add_child(pl)
		v1.add_child(r)
		idx += 1
	m1.add_child(v1); p1.add_child(m1); vb.add_child(p1)
	
	# Lideres
	var p2 = PanelContainer.new()
	p2.add_theme_stylebox_override("panel", s1)
	var m2 = MarginContainer.new()
	m2.add_theme_constant_override("margin_left", 20); m2.add_theme_constant_override("margin_right", 20)
	m2.add_theme_constant_override("margin_top", 20); m2.add_theme_constant_override("margin_bottom", 20)
	var v2 = VBoxContainer.new(); v2.add_theme_constant_override("separation", 16)
	var h2 = HBoxContainer.new()
	var t2 = Label.new(); t2.text = "LÍDERES DA LIGA"; t2.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t2.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); t2.add_theme_font_size_override("font_size", 12); t2.add_theme_constant_override("letter_spacing", 1)
	var cr = TextureRect.new(); cr.texture = load("res://addons/at-icons/control/crown.svg"); cr.custom_minimum_size = Vector2(14, 14); cr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; cr.modulate = ThemeConfig.WARNING; cr.size_flags_horizontal = Control.SIZE_EXPAND_FILL; cr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h2.add_child(t2); h2.add_child(cr)
	v2.add_child(h2)
	var div2 = ColorRect.new(); div2.custom_minimum_size = Vector2(0,1); div2.color = ThemeConfig.BORDER_SUBTLE; v2.add_child(div2)
	
	_add_lider(v2, "PONTOS/JOGO", "Marcus Silva", "SP Phoenix • PG", "28.4", Color("#2E1065"))
	_add_lider(v2, "ASSISTÊNCIAS/JOGO", "L. Henrique", "Cangurus RJ • PG", "11.2", Color("#1E3A8A"))
	_add_lider(v2, "REBOTES/JOGO", "K. Patterson", "Jaguars BSB • C", "14.6", Color("#064E3B"))
	_add_lider(v2, "ROUBOS/JOGO", "D. Santos", "Trovões CWB • SG", "3.2", Color("#451A03"))
	
	m2.add_child(v2); p2.add_child(m2); vb.add_child(p2)
	
	# Proximo Jogo
	var p3 = PanelContainer.new()
	p3.add_theme_stylebox_override("panel", s1)
	var m3 = MarginContainer.new()
	m3.add_theme_constant_override("margin_left", 20); m3.add_theme_constant_override("margin_right", 20)
	m3.add_theme_constant_override("margin_top", 20); m3.add_theme_constant_override("margin_bottom", 20)
	var v3 = VBoxContainer.new(); v3.add_theme_constant_override("separation", 16)
	var h3 = HBoxContainer.new()
	var d3 = PanelContainer.new(); d3.custom_minimum_size = Vector2(6,6); d3.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ds3 = StyleBoxFlat.new(); ds3.bg_color = ThemeConfig.BRAND_PRIMARY; ds3.corner_radius_top_left=3; ds3.corner_radius_bottom_right=3; ds3.corner_radius_top_right=3; ds3.corner_radius_bottom_left=3; d3.add_theme_stylebox_override("panel", ds3)
	h3.add_child(d3)
	var t3 = Label.new(); t3.text = "PRÓXIMO JOGO"; t3.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t3.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); t3.add_theme_font_size_override("font_size", 12); t3.add_theme_constant_override("letter_spacing", 1)
	h3.add_child(t3)
	var am = Label.new(); am.text = "AMANHÃ"; am.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); am.add_theme_color_override("font_color", ThemeConfig.WARNING); am.add_theme_font_size_override("font_size", 10); am.size_flags_horizontal = Control.SIZE_EXPAND_FILL; am.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h3.add_child(am)
	v3.add_child(h3)
	var div3 = ColorRect.new(); div3.custom_minimum_size = Vector2(0,1); div3.color = ThemeConfig.BORDER_SUBTLE; v3.add_child(div3)
	
	var teams_h = HBoxContainer.new()
	teams_h.alignment = BoxContainer.ALIGNMENT_CENTER
	teams_h.add_theme_constant_override("separation", 16)
	var phx = PanelContainer.new(); phx.custom_minimum_size = Vector2(48,48)
	var phxs = StyleBoxFlat.new(); phxs.bg_color = ThemeConfig.BRAND_PRIMARY; phxs.corner_radius_top_left=24; phxs.corner_radius_bottom_right=24; phxs.corner_radius_top_right=24; phxs.corner_radius_bottom_left=24; phx.add_theme_stylebox_override("panel", phxs)
	var phxl = Label.new(); phxl.text = "PHX"; phxl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); phxl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; phxl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	phx.add_child(phxl); teams_h.add_child(phx)
	
	var vs_v = VBoxContainer.new(); vs_v.alignment = BoxContainer.ALIGNMENT_CENTER
	var fora = Label.new(); fora.text = "FORA"; fora.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); fora.add_theme_font_size_override("font_size", 9); fora.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; fora.add_theme_color_override("font_color", Color.BLACK)
	var fora_p = PanelContainer.new(); var fs = StyleBoxFlat.new(); fs.bg_color = ThemeConfig.TEXT_MUTED; fs.corner_radius_top_left=4; fs.corner_radius_bottom_right=4; fs.corner_radius_top_right=4; fs.corner_radius_bottom_left=4; fora_p.add_theme_stylebox_override("panel", fs)
	var fora_m = MarginContainer.new(); fora_m.add_theme_constant_override("margin_left",4); fora_m.add_theme_constant_override("margin_right",4); fora_m.add_child(fora); fora_p.add_child(fora_m); vs_v.add_child(fora_p)
	var vs = Label.new(); vs.text = "VS"; vs.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); vs.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); vs.add_theme_font_size_override("font_size", 20); vs_v.add_child(vs)
	teams_h.add_child(vs_v)
	
	var poa = PanelContainer.new(); poa.custom_minimum_size = Vector2(48,48)
	var poas = StyleBoxFlat.new(); poas.bg_color = ThemeConfig.DANGER; poas.corner_radius_top_left=24; poas.corner_radius_bottom_right=24; poas.corner_radius_top_right=24; poas.corner_radius_bottom_left=24; poa.add_theme_stylebox_override("panel", poas)
	var poal = Label.new(); poal.text = "POA"; poal.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); poal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; poal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	poa.add_child(poal); teams_h.add_child(poa)
	v3.add_child(teams_h)
	
	var date = Label.new(); date.text = "Sex, 25 Nov • 20h30"; date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; date.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); date.add_theme_font_size_override("font_size", 12)
	v3.add_child(date)
	
	var btn = Button.new(); btn.text = "JOGAR AGORA"
	var b_st = StyleBoxFlat.new(); b_st.bg_color = ThemeConfig.BRAND_PRIMARY; b_st.corner_radius_top_left=8; b_st.corner_radius_bottom_right=8; b_st.corner_radius_top_right=8; b_st.corner_radius_bottom_left=8; b_st.content_margin_top=12; b_st.content_margin_bottom=12
	btn.add_theme_stylebox_override("normal", b_st); btn.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	v3.add_child(btn)
	
	m3.add_child(v3); p3.add_child(m3); vb.add_child(p3)
	
	parent.add_child(scroll)

func _add_lider(parent: Node, stat: String, n: String, sub: String, val: String, c: Color):
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 12)
	var ic = PanelContainer.new(); ic.custom_minimum_size = Vector2(36,36); ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ics = StyleBoxFlat.new(); ics.bg_color = c; ics.corner_radius_top_left=18; ics.corner_radius_bottom_right=18; ics.corner_radius_top_right=18; ics.corner_radius_bottom_left=18; ic.add_theme_stylebox_override("panel", ics)
	var lbl = Label.new(); lbl.text = "O"; lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; ic.add_child(lbl); h.add_child(ic)
	var v = VBoxContainer.new(); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL; v.alignment = BoxContainer.ALIGNMENT_CENTER
	var s = Label.new(); s.text = stat; s.add_theme_font_size_override("font_size", 8); s.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); s.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); v.add_child(s)
	var name_lbl = Label.new(); name_lbl.text = n; name_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); name_lbl.add_theme_font_size_override("font_size", 13); v.add_child(name_lbl)
	var sub_lbl = Label.new(); sub_lbl.text = sub; sub_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); sub_lbl.add_theme_font_size_override("font_size", 10); v.add_child(sub_lbl)
	h.add_child(v)
	var val_lbl = Label.new(); val_lbl.text = val; val_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); val_lbl.add_theme_font_size_override("font_size", 16)
	if "PONTOS" in stat: val_lbl.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
	elif "ASSIST" in stat: val_lbl.add_theme_color_override("font_color", Color("#3B82F6"))
	elif "REBOTE" in stat: val_lbl.add_theme_color_override("font_color", ThemeConfig.SUCCESS)
	elif "ROUBO" in stat: val_lbl.add_theme_color_override("font_color", ThemeConfig.WARNING)
	h.add_child(val_lbl)
	parent.add_child(h)
