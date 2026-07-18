extends Control

# ENGINE CONNECTED - Member variables for dynamic data
var _display_month: int = 11
var _display_year: int = 2026
var _month_label: Label
var _year_label: Label
var _calendar_vb: VBoxContainer
var _grid_scroll: ScrollContainer

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
	
	# ENGINE CONNECTED - Inicializa mês do calendário a partir da liga real
	var season = GameManager.league.get("season", 2026)
	var current_week = GameManager.league.get("current_week", 1)
	var current_date = SimulationBridge._week_to_date(season, current_week)
	_display_month = current_date.month
	_display_year = current_date.year
	
	_build_top_bar(vbox)
	_build_tabs_bar(vbox)
	
	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 24)
	vbox.add_child(main_hbox)
	
	_build_calendar(main_hbox)
	_build_right_sidebar(main_hbox)

func _build_top_bar(parent: Node):
	var topbar_scene = preload("res://scenes/components/topbar.tscn")
	var tb = topbar_scene.instantiate()
	tb.set_title("LIGA & CALENDÁRIO")
	parent.add_child(tb)

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
	
	# ENGINE CONNECTED - Month selector with real navigation
	var msel = PanelContainer.new()
	var ms_st = StyleBoxFlat.new()
	ms_st.bg_color = ThemeConfig.BG_ELEVATED
	ms_st.corner_radius_top_left = 6; ms_st.corner_radius_top_right = 6; ms_st.corner_radius_bottom_left = 6; ms_st.corner_radius_bottom_right = 6
	msel.add_theme_stylebox_override("panel", ms_st)
	var mh = HBoxContainer.new()
	var larr = Button.new(); larr.text = " < "; larr.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	var larr_st = StyleBoxFlat.new(); larr_st.bg_color = Color(0,0,0,0); larr.add_theme_stylebox_override("normal", larr_st)
	larr.pressed.connect(_on_prev_month)
	var rarr = Button.new(); rarr.text = " > "; rarr.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	var rarr_st = StyleBoxFlat.new(); rarr_st.bg_color = Color(0,0,0,0); rarr.add_theme_stylebox_override("normal", rarr_st)
	rarr.pressed.connect(_on_next_month)
	var mtxt = VBoxContainer.new()
	mtxt.custom_minimum_size = Vector2(100, 0)
	mtxt.alignment = BoxContainer.ALIGNMENT_CENTER
	var m1 = Label.new(); _month_label = m1; m1.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); m1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var m2 = Label.new(); _year_label = m2; m2.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); m2.add_theme_font_size_override("font_size", 10); m2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_update_month_label()
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
	_calendar_vb = vb
	
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
	
	# ENGINE CONNECTED - Grid com dados reais
	_rebuild_calendar_grid()
	
	pnl.add_child(vb)
	parent.add_child(pnl)

# ENGINE CONNECTED - Reconstrói o grid do calendário com dados reais
func _rebuild_calendar_grid():
	# Remove grid_scroll antigo se existir
	if _grid_scroll and _grid_scroll.get_parent() == _calendar_vb:
		_calendar_vb.remove_child(_grid_scroll)
		_grid_scroll.queue_free()
	
	# Busca partidas reais do mês
	var matches = SimulationBridge.get_matches_for_month(_display_month, _display_year)
	
	# Lookup por dia
	var match_by_day := {}
	for m in matches:
		match_by_day[m.get("day", 0)] = m
	
	# Primeiro dia da semana do mês (0=DOM, 6=SAB)
	var first_weekday = _get_weekday(_display_year, _display_month, 1)
	
	# Dias no mês
	var dim = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var days_in_month = dim[_display_month - 1]
	if _display_month == 2 and (_display_year % 4 == 0 and (_display_year % 100 != 0 or _display_year % 400 == 0)):
		days_in_month = 29
	
	var total_needed = first_weekday + days_in_month
	var rows = ceili(float(total_needed) / 7.0)
	var total_cells = rows * 7
	
	var grid_scroll = ScrollContainer.new()
	grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var grid = GridContainer.new()
	grid.columns = 7
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)
	
	var day = 1
	var prev_month_days = _get_days_in_month(_display_month - 1, _display_year)
	var prev_day = prev_month_days - first_weekday + 1
	
	# Data atual da liga para destacar "hoje"
	var season = GameManager.league.get("season", 2026)
	var current_week = GameManager.league.get("current_week", 1)
	var current_date = SimulationBridge._week_to_date(season, current_week)
	
	for i in range(total_cells):
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
		
		var num_lbl = Label.new()
		num_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		
		if i < first_weekday:
			# Dias do mês anterior (acinzentados)
			num_lbl.text = str(prev_day)
			num_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
			prev_day += 1
		elif day <= days_in_month:
			num_lbl.text = str(day)
			
			# Destaca o dia atual
			if day == current_date.day and _display_month == current_date.month and _display_year == current_date.year:
				num_lbl.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
			
			# ENGINE CONNECTED - Badge de partida real
			var match_data = match_by_day.get(day)
			if match_data:
				_add_match_badge_from_data(cvb, match_data)
			
			day += 1
		else:
			# Dias do próximo mês (acinzentados)
			var next_day_num = day - days_in_month
			num_lbl.text = str(next_day_num)
			num_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
			day += 1
		
		cvb.add_child(num_lbl)
		cm.add_child(cvb)
		cell.add_child(cm)
		grid.add_child(cell)
	
	grid_scroll.add_child(grid)
	_grid_scroll = grid_scroll
	_calendar_vb.add_child(grid_scroll)

# ENGINE CONNECTED - Cria badge de partida a partir dos dados da engine
func _add_match_badge_from_data(parent: Node, match_data: Dictionary):
	var time = match_data.get("time", "20h00")
	var is_home = match_data.get("is_home", true)
	var opp_abbr = match_data.get("away_abbr", "???")
	var opp = ("vs " if is_home else "@ ") + opp_abbr
	var played = match_data.get("played", false)
	
	var score_str := ""
	var won = null
	
	if played:
		var home_score = match_data.get("home_score", 0)
		var away_score = match_data.get("away_score", 0)
		score_str = str(home_score) + "-" + str(away_score)
		if is_home:
			won = home_score > away_score
		else:
			won = away_score > home_score
	
	_add_match_badge(parent, time, opp, score_str, won)

func _get_weekday(year: int, month: int, day: int) -> int:
	var unix = Time.get_unix_time_from_datetime_dict({
		"year": year, "month": month, "day": day, "hour": 12, "minute": 0, "second": 0
	})
	var dict = Time.get_datetime_dict_from_unix_time(unix)
	return dict["weekday"] % 7  # 0=DOM, 6=SAB

func _get_days_in_month(month: int, year: int) -> int:
	var m = month
	var y = year
	if m < 1:
		m = 12
		y -= 1
	elif m > 12:
		m = 1
		y += 1
	var dim = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var days = dim[m - 1]
	if m == 2 and (y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)):
		days = 29
	return days

func _update_month_label():
	var months = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
	_month_label.text = months[_display_month - 1]
	_year_label.text = str(_display_year)

func _on_prev_month():
	_display_month -= 1
	if _display_month < 1:
		_display_month = 12
		_display_year -= 1
	_update_month_label()
	_rebuild_calendar_grid()

func _on_next_month():
	_display_month += 1
	if _display_month > 12:
		_display_month = 1
		_display_year += 1
	_update_month_label()
	_rebuild_calendar_grid()

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
	var t1 = Label.new(); t1.text = "CLASSIFICAÇÃO"; t1.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t1.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); t1.add_theme_font_size_override("font_size", 12); t1.add_theme_constant_override("letter_spacing", 1)
	var vt = Label.new(); vt.text = "VER TUDO >"; vt.add_theme_font_size_override("font_size", 10); vt.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h1.add_child(t1); h1.add_child(vt)
	v1.add_child(h1)
	
	var div1 = ColorRect.new(); div1.custom_minimum_size = Vector2(0,1); div1.color = ThemeConfig.BORDER_SUBTLE; v1.add_child(div1)
	
	# ENGINE CONNECTED - Classificação real da liga
	var all_teams = GameManager.league.get("teams", [])
	var sorted = all_teams.duplicate()
	sorted.sort_custom(func(a, b):
		if a.get("wins", 0) != b.get("wins", 0):
			return a.get("wins", 0) > b.get("wins", 0)
		return a.get("losses", 0) < b.get("losses", 0)
	)
	var top6 = sorted.slice(0, 6)
	var position = 1
	for t in top6:
		var r = HBoxContainer.new(); r.add_theme_constant_override("separation", 12)
		var badge = PanelContainer.new(); badge.custom_minimum_size = Vector2(20,20); badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bs = StyleBoxFlat.new()
		if position == 1:
			bs.bg_color = ThemeConfig.BRAND_PRIMARY
		elif position <= 4:
			bs.bg_color = ThemeConfig.SUCCESS
		else:
			bs.bg_color = ThemeConfig.TEXT_MUTED
		bs.corner_radius_top_left=10; bs.corner_radius_bottom_right=10; bs.corner_radius_top_right=10; bs.corner_radius_bottom_left=10
		badge.add_theme_stylebox_override("panel", bs)
		var bl = Label.new(); bl.text = str(position); bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; bl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); bl.add_theme_font_size_override("font_size", 10)
		badge.add_child(bl)
		r.add_child(badge)
		var is_user_team = t.get("id", 0) == GameManager.user_team_id
		var dot = PanelContainer.new(); dot.custom_minimum_size = Vector2(6,6); dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var ds = StyleBoxFlat.new(); ds.bg_color = ThemeConfig.BRAND_PRIMARY if is_user_team else ThemeConfig.SUCCESS; ds.corner_radius_top_left=3; ds.corner_radius_bottom_right=3; ds.corner_radius_top_right=3; ds.corner_radius_bottom_left=3
		dot.add_theme_stylebox_override("panel", ds)
		r.add_child(dot)
		var city_name = t.get("city", "")
		var team_name = t.get("name", "")
		var display_name = (city_name + " " + team_name).strip_edges()
		var nl = Label.new(); nl.text = display_name; nl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL; nl.add_theme_font_size_override("font_size", 12)
		if is_user_team:
			nl.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
		r.add_child(nl)
		var w = t.get("wins", 0)
		var l = t.get("losses", 0)
		var wl = Label.new(); wl.text = str(w) + "-" + str(l); wl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); wl.add_theme_font_size_override("font_size", 12)
		if is_user_team:
			wl.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
		r.add_child(wl)
		var total_g = w + l
		var pct = "%.3f" % (float(w) / float(max(total_g, 1)))
		var pl = Label.new(); pl.text = pct; pl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); pl.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY); pl.add_theme_font_size_override("font_size", 12)
		r.add_child(pl)
		v1.add_child(r)
		position += 1
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
	
	# ENGINE CONNECTED - Líderes reais da liga
	var points_leader = {"name": "", "team_pos": "", "value": 0.0}
	var assists_leader = {"name": "", "team_pos": "", "value": 0.0}
	var rebounds_leader = {"name": "", "team_pos": "", "value": 0.0}
	var steals_leader = {"name": "", "team_pos": "", "value": 0.0}
	
	for t in all_teams:
		var t_abbr = t.get("abbreviation", "")
		for p in t.get("players", []):
			var stats_season = p.get("stats_season", {})
			var gp = stats_season.get("games_played", 1)
			if gp <= 0: gp = 1
			
			var full_name = (p.get("first_name", "") + " " + p.get("last_name", "")).strip_edges()
			var pos = p.get("position", "")
			var team_pos = t_abbr + " • " + pos
			
			var pts = stats_season.get("points", 0)
			var ppg = float(pts) / float(gp)
			if ppg > points_leader.value:
				points_leader = {"name": full_name, "team_pos": team_pos, "value": ppg}
			
			var ast = stats_season.get("assists", 0)
			var apg = float(ast) / float(gp)
			if apg > assists_leader.value:
				assists_leader = {"name": full_name, "team_pos": team_pos, "value": apg}
			
			var reb = stats_season.get("rebounds", 0)
			var rpg = float(reb) / float(gp)
			if rpg > rebounds_leader.value:
				rebounds_leader = {"name": full_name, "team_pos": team_pos, "value": rpg}
			
			var stl = stats_season.get("steals", 0)
			var spg = float(stl) / float(gp)
			if spg > steals_leader.value:
				steals_leader = {"name": full_name, "team_pos": team_pos, "value": spg}
	
	_add_lider(v2, "PONTOS/JOGO", points_leader.name, points_leader.team_pos, "%.1f" % points_leader.value, Color("#2E1065"))
	_add_lider(v2, "ASSISTÊNCIAS/JOGO", assists_leader.name, assists_leader.team_pos, "%.1f" % assists_leader.value, Color("#1E3A8A"))
	_add_lider(v2, "REBOTES/JOGO", rebounds_leader.name, rebounds_leader.team_pos, "%.1f" % rebounds_leader.value, Color("#064E3B"))
	_add_lider(v2, "ROUBOS/JOGO", steals_leader.name, steals_leader.team_pos, "%.1f" % steals_leader.value, Color("#451A03"))
	
	m2.add_child(v2); p2.add_child(m2); vb.add_child(p2)
	
	# ENGINE CONNECTED - Próximo Jogo real
	var next_match = EventManager.get_next_match()
	var has_next = not next_match.is_empty()
	
	var next_opp_abbr = "---"
	var next_is_home = true
	var next_opp_id = 0
	var next_date_str = "---"
	var next_day = 0
	var next_month = 0
	var next_year = 0
	var next_hour = 20
	var next_minute = 0
	
	if has_next:
		next_is_home = next_match.get("home_team_id", 0) == GameManager.user_team_id
		next_opp_id = next_match.get("away_team_id", 0) if next_is_home else next_match.get("home_team_id", 0)
		for t in all_teams:
			if t.get("id") == next_opp_id:
				next_opp_abbr = t.get("abbreviation", "---")
				break
		
		next_day = next_match.get("day", 0)
		next_month = next_match.get("month", 0)
		next_year = next_match.get("year", 0)
		next_hour = next_match.get("hour", 20)
		next_minute = next_match.get("minute", 0)
		
		var day_names = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
		var month_names = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"]
		var unix = Time.get_unix_time_from_datetime_dict({"year": next_year, "month": next_month, "day": next_day, "hour": 12, "minute": 0, "second": 0})
		var date_dict = Time.get_datetime_dict_from_unix_time(unix)
		var weekday_name = day_names[date_dict["weekday"] % 7]
		next_date_str = "%s, %d %s • %02dh%02d" % [weekday_name, next_day, month_names[next_month - 1], next_hour, next_minute]
	
	# Abreviação do time do usuário
	var user_abbr = "???"
	for t in all_teams:
		if t.get("id") == GameManager.user_team_id:
			user_abbr = t.get("abbreviation", "???")
			break
	
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
	var am = Label.new(); am.text = "PRÓXIMO"; am.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); am.add_theme_color_override("font_color", ThemeConfig.WARNING); am.add_theme_font_size_override("font_size", 10); am.size_flags_horizontal = Control.SIZE_EXPAND_FILL; am.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h3.add_child(am)
	v3.add_child(h3)
	var div3 = ColorRect.new(); div3.custom_minimum_size = Vector2(0,1); div3.color = ThemeConfig.BORDER_SUBTLE; v3.add_child(div3)
	
	var teams_h = HBoxContainer.new()
	teams_h.alignment = BoxContainer.ALIGNMENT_CENTER
	teams_h.add_theme_constant_override("separation", 16)
	
	var home_abbr = user_abbr if next_is_home else next_opp_abbr
	var away_abbr = next_opp_abbr if next_is_home else user_abbr
	
	var home_circle = PanelContainer.new(); home_circle.custom_minimum_size = Vector2(48,48)
	var home_cs = StyleBoxFlat.new(); home_cs.bg_color = ThemeConfig.BRAND_PRIMARY; home_cs.corner_radius_top_left=24; home_cs.corner_radius_bottom_right=24; home_cs.corner_radius_top_right=24; home_cs.corner_radius_bottom_left=24; home_circle.add_theme_stylebox_override("panel", home_cs)
	var home_lbl = Label.new(); home_lbl.text = home_abbr; home_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); home_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; home_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	home_circle.add_child(home_lbl); teams_h.add_child(home_circle)
	
	var vs_v = VBoxContainer.new(); vs_v.alignment = BoxContainer.ALIGNMENT_CENTER
	var fora = Label.new(); fora.text = "CASA" if next_is_home else "FORA"; fora.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); fora.add_theme_font_size_override("font_size", 9); fora.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; fora.add_theme_color_override("font_color", Color.BLACK)
	var fora_p = PanelContainer.new(); var fs = StyleBoxFlat.new(); fs.bg_color = ThemeConfig.TEXT_MUTED; fs.corner_radius_top_left=4; fs.corner_radius_bottom_right=4; fs.corner_radius_top_right=4; fs.corner_radius_bottom_left=4; fora_p.add_theme_stylebox_override("panel", fs)
	var fora_m = MarginContainer.new(); fora_m.add_theme_constant_override("margin_left",4); fora_m.add_theme_constant_override("margin_right",4); fora_m.add_child(fora); fora_p.add_child(fora_m); vs_v.add_child(fora_p)
	var vs = Label.new(); vs.text = "VS"; vs.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); vs.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); vs.add_theme_font_size_override("font_size", 20); vs_v.add_child(vs)
	teams_h.add_child(vs_v)
	
	var away_circle = PanelContainer.new(); away_circle.custom_minimum_size = Vector2(48,48)
	var away_cs = StyleBoxFlat.new(); away_cs.bg_color = Color("#EF4444"); away_cs.corner_radius_top_left=24; away_cs.corner_radius_bottom_right=24; away_cs.corner_radius_top_right=24; away_cs.corner_radius_bottom_left=24; away_circle.add_theme_stylebox_override("panel", away_cs)
	var away_lbl = Label.new(); away_lbl.text = away_abbr; away_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); away_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; away_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	away_circle.add_child(away_lbl); teams_h.add_child(away_circle)
	v3.add_child(teams_h)
	
	var date = Label.new(); date.text = next_date_str; date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; date.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); date.add_theme_font_size_override("font_size", 12)
	v3.add_child(date)
	
	var btn = Button.new(); btn.text = "JOGAR AGORA"
	var b_st = StyleBoxFlat.new(); b_st.bg_color = ThemeConfig.BRAND_PRIMARY; b_st.corner_radius_top_left=8; b_st.corner_radius_bottom_right=8; b_st.corner_radius_top_right=8; b_st.corner_radius_bottom_left=8; b_st.content_margin_top=12; b_st.content_margin_bottom=12
	btn.add_theme_stylebox_override("normal", b_st); btn.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	if has_next:
		var n_home_id = next_match.get("home_team_id", 0)
		var n_away_id = next_match.get("away_team_id", 0)
		btn.pressed.connect(func():
			GameManager.pending_home_id = n_home_id
			GameManager.pending_away_id = n_away_id
			get_tree().change_scene_to_file("res://scenes/match.tscn")
		)
	else:
		btn.disabled = true
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
