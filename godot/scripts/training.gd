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

# ENGINE CONNECTED helpers
func _get_season() -> int:
	return GameManager.league.get("season", 2026)

func _get_current_week() -> int:
	return GameManager.league.get("current_week", 1)

static func _week_to_date(season: int, week: int) -> Dictionary:
	var base_day = 3
	var base_month = 11
	var day = base_day + (week - 1) * 7
	var month = base_month
	var year = season
	var days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	while day > days_in_month[month - 1]:
		day -= days_in_month[month - 1]
		month += 1
		if month > 12:
			month = 1
			year += 1
	return {"day": day, "month": month, "year": year}

static func _add_days(year: int, month: int, day: int, count: int) -> Dictionary:
	var d = day + count
	var m = month
	var y = year
	var days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	while d > days_in_month[m - 1]:
		d -= days_in_month[m - 1]
		m += 1
		if m > 12:
			m = 1
			y += 1
	return {"day": d, "month": m, "year": y}

func _get_events_for_date(day: int, month: int, year: int) -> Array:
	var result: Array = []
	for evt in EventManager.events:
		if evt.get("day", 0) == day and evt.get("month", 0) == month and evt.get("year", 0) == year:
			result.append(evt)
	return result

func _get_dow(year: int, month: int, day: int) -> int:
	var date = {"year": year, "month": month, "day": day, "hour": 12, "minute": 0, "second": 0}
	var unix = Time.get_unix_time_from_datetime_dict(date)
	var dt = Time.get_datetime_dict_from_unix_time(unix)
	return dt.get("weekday", 0)

func _training_event_color(etype: String) -> Color:
	match etype:
		"training_physical":
			return ThemeConfig.DANGER
		"training_tactical":
			return ThemeConfig.BRAND_PRIMARY
		"recovery":
			return ThemeConfig.SUCCESS
		"rest":
			return ThemeConfig.SUCCESS
		"meeting":
			return Color("#3B82F6")
		"press_conference":
			return Color("#3B82F6")
		_:
			return ThemeConfig.BRAND_PRIMARY

func _training_event_dots(etype: String) -> int:
	match etype:
		"training_physical":
			return 3
		"training_tactical":
			return 2
		"recovery":
			return 1
		"rest":
			return 0
		"meeting":
			return 1
		"press_conference":
			return 1
		_:
			return 2

func _training_event_duration(etype: String) -> String:
	match etype:
		"training_physical":
			return "90min"
		"training_tactical":
			return "60min"
		"recovery":
			return "45min"
		"rest":
			return "—"
		"meeting":
			return "60min"
		"press_conference":
			return "30min"
		_:
			return "60min"
# END ENGINE CONNECTED helpers

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
	
	var current_intensity = GameManager.get_training_intensity()
	int_box.add_child(_create_int_btn("BAIXA", ThemeConfig.SUCCESS, current_intensity == "BAIXA"))
	int_box.add_child(_create_int_btn("MÉDIA", ThemeConfig.WARNING, current_intensity == "MÉDIA"))
	int_box.add_child(_create_int_btn("ALTA", ThemeConfig.DANGER, current_intensity == "ALTA"))
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

func _create_int_btn(text: String, color: Color, active: bool) -> Button:
	var b = Button.new()
	b.text = text
	b.flat = true
	b.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	b.add_theme_font_size_override("font_size", 10)
	var s = StyleBoxFlat.new()
	s.bg_color = color if active else Color(0,0,0,0)
	s.corner_radius_top_left = 4; s.corner_radius_bottom_right = 4
	s.corner_radius_bottom_left = 4; s.corner_radius_top_right = 4
	if not active:
		s.border_width_left = 1; s.border_width_right = 1
		s.border_width_top = 1; s.border_width_bottom = 1
		s.border_color = ThemeConfig.BORDER_SUBTLE
	b.add_theme_stylebox_override("normal", s)
	b.add_theme_stylebox_override("hover", s)
	b.add_theme_stylebox_override("pressed", s)
	b.add_theme_color_override("font_color", Color("#06030E") if active else color)
	b.pressed.connect(func():
		GameManager.set_training_intensity(text)
		for child in b.get_parent().get_children():
			if child is Button and child != b.get_parent().get_child(0):
				var cs = StyleBoxFlat.new()
				cs.bg_color = Color(0,0,0,0)
				cs.corner_radius_top_left = 4; cs.corner_radius_bottom_right = 4
				cs.corner_radius_bottom_left = 4; cs.corner_radius_top_right = 4
				cs.border_width_left = 1; cs.border_width_right = 1
				cs.border_width_top = 1; cs.border_width_bottom = 1
				cs.border_color = ThemeConfig.BORDER_SUBTLE
				child.add_theme_stylebox_override("normal", cs)
				child.add_theme_color_override("font_color", color)
		var act_s = StyleBoxFlat.new()
		act_s.bg_color = color
		act_s.corner_radius_top_left = 4; act_s.corner_radius_bottom_right = 4
		act_s.corner_radius_bottom_left = 4; act_s.corner_radius_top_right = 4
		b.add_theme_stylebox_override("normal", act_s)
		b.add_theme_color_override("font_color", Color("#06030E"))
	)
	return b

func _build_kpis(parent: Node): # ENGINE CONNECTED
	var team = GameManager.get_user_team()
	var players: Array = team.get("players", [])
	var season = _get_season()
	var week = _get_current_week()
	
	# FORMA MÉDIA: average morale
	var avg_morale := 50
	if players.size() > 0:
		var morale_sum := 0
		for p in players:
			morale_sum += p.get("morale", 50)
		avg_morale = morale_sum / players.size()
	
	# SESSÕES: count training-type events in current week
	var week_start = _week_to_date(season, week)
	var session_count := 0
	for evt in EventManager.events:
		for offset in range(5):
			var d = _add_days(week_start.year, week_start.month, week_start.day, offset)
			if evt.get("day", 0) == d.day and evt.get("month", 0) == d.month and evt.get("year", 0) == d.year:
				var etype: String = evt.get("event_type", "")
				if etype.begins_with("training") or etype == "recovery" or etype == "meeting" or etype == "press_conference":
					session_count += 1
				break
	
	# RISCO LESÃO: based on avg stamina
	var avg_stamina := 50
	if players.size() > 0:
		var stamina_sum := 0
		for p in players:
			stamina_sum += p.get("attributes", {}).get("stamina", 50)
		avg_stamina = stamina_sum / players.size()
	
	var injury_risk: int
	var injury_color: Color
	if avg_stamina < 40:
		injury_risk = 65
		injury_color = ThemeConfig.DANGER
	elif avg_stamina < 60:
		injury_risk = 35
		injury_color = ThemeConfig.WARNING
	else:
		injury_risk = 12
		injury_color = ThemeConfig.SUCCESS
	
	# CARGA SEMANAL: based on current focus
	var focus = GameManager.get_training_focus()
	var weekly_load = {"Shooting": 70, "Defense": 65, "Playmaking": 68, "Physical": 75, "Balanced": 60}.get(focus, 60)
	
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	
	h.add_child(_create_stat_card("CARGA SEMANAL", str(weekly_load), ThemeConfig.WARNING, "clock", "/100"))
	h.add_child(_create_stat_card("RISCO LESÃO", str(injury_risk), injury_color, "#", "%"))
	h.add_child(_create_stat_card("FORMA MÉDIA", str(avg_morale), ThemeConfig.BRAND_PRIMARY, "arrow_up_right", "/100"))
	h.add_child(_create_stat_card("SESSÕES", str(session_count), Color("#3B82F6"), "calendar", "/14 sem."))
	
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

func _build_left_col(parent: Node): # ENGINE CONNECTED
	var p = _create_main_panel(1.0)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20); m.add_theme_constant_override("margin_top", 20); m.add_theme_constant_override("margin_bottom", 20); p.add_child(m)
	var scroll = ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; m.add_child(scroll)
	var vb = VBoxContainer.new(); vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(vb)
	
	var focus = GameManager.get_training_focus()
	
	vb.add_child(_create_section_head("L", "BIBLIOTECA", ""))
	
	# Physical — highlight when focus == Physical
	var phys_alpha = 1.0 if focus == "Physical" else 0.35
	vb.add_child(_create_lib_head("FÍSICO", "3", Color(ThemeConfig.DANGER.r, ThemeConfig.DANGER.g, ThemeConfig.DANGER.b, phys_alpha)))
	vb.add_child(_create_lib_item("Resistência", "90min · INT Alta", Color(ThemeConfig.DANGER.r, ThemeConfig.DANGER.g, ThemeConfig.DANGER.b, phys_alpha), "arrow_double_vertical"))
	vb.add_child(_create_lib_item("Força", "60min · INT Alta", Color(ThemeConfig.DANGER.r, ThemeConfig.DANGER.g, ThemeConfig.DANGER.b, phys_alpha), "F"))
	vb.add_child(_create_lib_item("Velocidade", "45min · INT Méd", Color(ThemeConfig.DANGER.r, ThemeConfig.DANGER.g, ThemeConfig.DANGER.b, phys_alpha), "E"))
	
	# Técnico — Shooting or Defense highlights this section
	var tech_alpha = 1.0 if focus == "Shooting" or focus == "Defense" else 0.35
	vb.add_child(_create_lib_head("TÉCNICO", "2", Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, tech_alpha)))
	var shoot_alpha = 1.0 if focus == "Shooting" else tech_alpha
	var def_alpha = 1.0 if focus == "Defense" else tech_alpha
	vb.add_child(_create_lib_item("Arremesso 3PT", "60min · INT Méd", Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, shoot_alpha), "O"))
	vb.add_child(_create_lib_item("Defesa Individual", "75min · INT Méd", Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, def_alpha), "#"))
	
	# Tático — Playmaking focus
	var tac_alpha = 1.0 if focus == "Playmaking" else 0.35
	vb.add_child(_create_lib_head("TÁTICO", "2", Color(0.23, 0.51, 0.96, tac_alpha)))
	vb.add_child(_create_lib_item("5v5 Halfcourt", "90min · INT Alta", Color(0.23, 0.51, 0.96, tac_alpha), "P"))
	vb.add_child(_create_lib_item("Jogadas", "60min · INT Baixa", Color(0.23, 0.51, 0.96, tac_alpha), ">"))
	
	# Recuperação — always full color
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

func _build_center_col(parent: Node): # ENGINE CONNECTED
	var p = _create_main_panel(2.2)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24); m.add_theme_constant_override("margin_top", 24); m.add_theme_constant_override("margin_bottom", 24); p.add_child(m)
	var vb = VBoxContainer.new(); vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; m.add_child(vb)
	
	var season = _get_season()
	var week = _get_current_week()
	var week_start = _week_to_date(season, week)
	var month_names = ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]
	var day_labels = ["SEG", "TER", "QUA", "QUI", "SEX", "SÁB", "DOM"]
	
	# Compute week end (Monday + 6 days)
	var week_end = _add_days(week_start.year, week_start.month, week_start.day, 6)
	
	# Collect events for each day of the week + compute load
	var day_events: Array = []
	var day_loads: Array = []
	var total_load := 0
	var next_match_data: Dictionary = {}
	var next_match_idx := -1
	
	for offset in range(7):
		var d = _add_days(week_start.year, week_start.month, week_start.day, offset)
		var date_events = _get_events_for_date(d.day, d.month, d.year)
		day_events.append(date_events)
		
		# Compute load for this day
		var load := 10
		var has_match := false
		for evt in date_events:
			var etype: String = evt.get("event_type", "")
			if etype == "match":
				load = 95
				has_match = true
				if next_match_data.is_empty():
					next_match_data = evt
					next_match_idx = offset
			elif etype == "training_physical":
				load = max(load, 82)
			elif etype == "training_tactical":
				load = max(load, 65)
			elif etype == "recovery":
				load = max(load, 28)
			elif etype == "press_conference" or etype == "meeting":
				load = max(load, 35)
			elif etype == "rest":
				load = max(load, 12)
		day_loads.append(load)
		total_load += load
	
	var avg_load = total_load / 7
	
	# --- Week header ---
	var top = HBoxContainer.new()
	var i1 = TextureRect.new(); i1.texture = load("res://addons/at-icons/control/calendar.svg"); i1.custom_minimum_size = Vector2(12, 12); i1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; i1.modulate = ThemeConfig.TEXT_MUTED; top.add_child(i1)
	var hl = Label.new()
	hl.text = " CRONOGRAMA · " + str(week_start.day) + "-" + str(week_end.day) + " " + month_names[week_start.month - 1]
	hl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); hl.add_theme_font_size_override("font_size", 10); hl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hl.add_theme_constant_override("letter_spacing", 1); top.add_child(hl)
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(sp)
	
	# Next match button in this week
	if not next_match_data.is_empty():
		var nd = next_match_data
		var ndow = _get_dow(nd.get("year", season), nd.get("month", 1), nd.get("day", 1))
		var ndow_labels = ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SÁB"]
		var btn = Button.new()
		var desc: String = nd.get("description", "Jogo")
		var hour: int = nd.get("hour", 20)
		btn.text = str(nd.get("day", "?")) + " " + desc + " " + str(hour) + "h"
		btn.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); btn.add_theme_font_size_override("font_size", 10)
		var sbtn = StyleBoxFlat.new(); sbtn.bg_color = Color(0,0,0,0); sbtn.border_width_left=1; sbtn.border_width_right=1; sbtn.border_width_top=1; sbtn.border_width_bottom=1; sbtn.border_color = Color("#3B82F6"); sbtn.corner_radius_top_left=4; sbtn.corner_radius_bottom_right=4; sbtn.corner_radius_bottom_left=4; sbtn.corner_radius_top_right=4; sbtn.content_margin_left=12; sbtn.content_margin_right=12; sbtn.content_margin_top=4; sbtn.content_margin_bottom=4
		btn.add_theme_stylebox_override("normal", sbtn); btn.add_theme_color_override("font_color", Color("#3B82F6"))
		btn.pressed.connect(func():
			EventBus.navigation_requested.emit("match")
		)
		top.add_child(btn)
	vb.add_child(top)
	
	vb.add_theme_constant_override("separation", 16)
	
	# --- Calendar Grid ---
	var cal = HBoxContainer.new(); cal.size_flags_vertical = Control.SIZE_EXPAND_FILL; cal.add_theme_constant_override("separation", 1)
	
	for offset in range(7):
		var d = _add_days(week_start.year, week_start.month, week_start.day, offset)
		var events_today: Array = day_events[offset]
		var cards: Array = []
		var has_match := false
		
		for evt in events_today:
			var etype: String = evt.get("event_type", "")
			var hour: int = evt.get("hour", 9)
			var min: int = evt.get("minute", 0)
			var time_str = "%02dh%02d" % [hour, min]
			var desc: String = evt.get("description", "Sessão")
			
			if etype == "match":
				has_match = true
				var opp_label: String = desc
				var hour_str = str(hour) + "h" + str(min) if min > 0 else str(hour) + "h00"
				cards.append(_create_game_card("DIA DE JOGO", opp_label, hour_str))
			else:
				var color = _training_event_color(etype)
				var dots = _training_event_dots(etype)
				var dur = _training_event_duration(etype)
				cards.append(_create_cal_card(time_str, desc, dur, color, dots))
		
		cal.add_child(_create_cal_day(day_labels[offset], str(d.day), cards, has_match))
	
	vb.add_child(cal)
	
	var sep = HSeparator.new(); vb.add_child(sep)
	
	# --- Load chart ---
	var hbot = HBoxContainer.new()
	var ctit = Label.new(); ctit.text = "CARGA SEMANAL POR DIA"; ctit.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); ctit.add_theme_font_size_override("font_size", 10); ctit.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); ctit.add_theme_constant_override("letter_spacing", 1); hbot.add_child(ctit)
	var sp2 = Control.new(); sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hbot.add_child(sp2)
	var med = Label.new(); med.text = "MÉDIA: " + str(avg_load) + "/100"; med.add_theme_font_size_override("font_size", 10); med.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hbot.add_child(med)
	vb.add_child(hbot)
	
	var chart = HBoxContainer.new(); chart.custom_minimum_size = Vector2(0, 64); chart.add_theme_constant_override("separation", 8); chart.alignment = BoxContainer.ALIGNMENT_CENTER
	for offset in range(7):
		var load = day_loads[offset]
		var color: Color
		if load >= 80:
			color = ThemeConfig.DANGER
		elif load >= 50:
			color = ThemeConfig.WARNING
		else:
			color = ThemeConfig.SUCCESS
		chart.add_child(_create_chart_bar(load, color, day_labels[offset]))
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

func _build_right_col(parent: Node): # ENGINE CONNECTED
	var p = _create_main_panel(1.2)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20); m.add_theme_constant_override("margin_top", 20); m.add_theme_constant_override("margin_bottom", 20); p.add_child(m)
	var scroll = ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; m.add_child(scroll)
	var vb = VBoxContainer.new(); vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vb.add_theme_constant_override("separation", 16); scroll.add_child(vb)
	
	var team = GameManager.get_user_team()
	var all_players: Array = team.get("players", [])
	all_players.sort_custom(func(a, b): return a.get("overall", 0) > b.get("overall", 0))
	var top5 = all_players.slice(0, 5)
	
	var focus = GameManager.get_training_focus()
	
	# Map training focus → attribute key, display name, and visual color
	var attr_map = {
		"Shooting": {"key": "three_point", "label": "3PT %"},
		"Defense": {"key": "defense", "label": "Defesa"},
		"Physical": {"key": "stamina", "label": "Energia"},
		"Playmaking": {"key": "passing", "label": "Passe"},
		"Balanced": {"key": "overall", "label": "Geral"}
	}
	var focus_attr = attr_map.get(focus, attr_map["Balanced"])
	
	var season = _get_season()
	var week = _get_current_week()
	var weeks_left = max(0, 22 - week)
	
	var top = HBoxContainer.new(); top.custom_minimum_size = Vector2(0, 32)
	var i1 = TextureRect.new(); i1.texture = load("res://addons/at-icons/control/arrow_up_right.svg"); i1.custom_minimum_size = Vector2(12, 12); i1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; i1.modulate = ThemeConfig.TEXT_MUTED; top.add_child(i1)
	var hl = Label.new(); hl.text = " PROGRAMAS INDIVIDUAIS"; hl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); hl.add_theme_font_size_override("font_size", 10); hl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hl.add_theme_constant_override("letter_spacing", 1); top.add_child(hl)
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(sp)
	var bp = PanelContainer.new()
	var sbp = StyleBoxFlat.new(); sbp.bg_color = Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.2); sbp.corner_radius_top_left=4; sbp.corner_radius_bottom_right=4; sbp.corner_radius_bottom_left=4; sbp.corner_radius_top_right=4; bp.add_theme_stylebox_override("panel", sbp)
	var mbp = MarginContainer.new(); mbp.add_theme_constant_override("margin_left", 6); mbp.add_theme_constant_override("margin_right", 6); bp.add_child(mbp)
	var lbp = Label.new(); lbp.text = str(top5.size()) + " ATIVOS"; lbp.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lbp.add_theme_font_size_override("font_size", 9); lbp.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY); mbp.add_child(lbp); top.add_child(bp)
	vb.add_child(top)
	
	for player in top5:
		var first: String = player.get("first_name", "Jogador")
		var last: String = player.get("last_name", "")
		var full_name = first + " " + last
		var ini = first.substr(0, 1).to_upper() + last.substr(0, 1).to_upper()
		var pos: String = player.get("position", "RES")
		var overall: int = player.get("overall", 50)
		var morale: int = player.get("morale", 50)
		var attributes: Dictionary = player.get("attributes", {})
		var stamina: int = attributes.get("stamina", 50)
		var attr_val: int = attributes.get(focus_attr["key"], overall)
		
		# Position → Portuguese label
		var pos_labels = {"PG": "Armador", "SG": "Ala", "SF": "Ala", "PF": "Ala-Pivô", "C": "Pivô", "RES": "Reserva"}
		var pos_label = pos_labels.get(pos, pos)
		
		# Desc: position + focus attribute
		var desc = pos_label + " · " + focus_attr["label"]
		
		# Badge
		var badge := ""
		var bcolor := Color.WHITE
		if stamina < 40:
			badge = "LESÃO"
			bcolor = ThemeConfig.DANGER
		elif stamina < 60:
			badge = "CANSADO"
			bcolor = ThemeConfig.WARNING
		elif morale > 80:
			badge = "ESTRELA"
			bcolor = ThemeConfig.WARNING
		
		# Progress
		var attr_capped = mini(attr_val, 99)
		var prog = float(attr_capped) / 99.0
		
		# Progress color
		var pcolor: Color
		if attr_val < 50:
			pcolor = ThemeConfig.DANGER
		elif attr_val < 70:
			pcolor = ThemeConfig.WARNING
		else:
			pcolor = ThemeConfig.BRAND_PRIMARY
		
		# Rate (approximate weekly gain based on focus)
		var rate_str = "+0." + str((attr_val % 10 + 2) % 10) + "/sem"
		
		vb.add_child(_create_indiv_card(ini, full_name, desc, badge, bcolor, focus_attr["label"], str(attr_val), "99", rate_str, weeks_left, pcolor, prog))
	
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
