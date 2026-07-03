extends PanelContainer

var rows_container: VBoxContainer

func _ready() -> void:
	for c in get_children():
		c.queue_free()
		
	var style = StyleBoxFlat.new()
	style.bg_color = ThemeConfig.BG_SURFACE
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12; style.corner_radius_bottom_right = 12
	style.border_color = ThemeConfig.BORDER_DEFAULT
	style.border_width_left = 1; style.border_width_top = 1; style.border_width_right = 1; style.border_width_bottom = 1
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 16
	add_theme_stylebox_override("panel", style)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)
	
	# TOP HEADER
	var header_pad = MarginContainer.new()
	header_pad.add_theme_constant_override("margin_left", 24)
	header_pad.add_theme_constant_override("margin_right", 24)
	header_pad.add_theme_constant_override("margin_top", 24)
	header_pad.add_theme_constant_override("margin_bottom", 16)
	
	var header_hbox = HBoxContainer.new()
	var title_vbox = VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var subt = Label.new()
	subt.text = "CLASSIFICAÇÃO GERAL"
	subt.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	subt.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
	subt.add_theme_font_size_override("font_size", 11)
	subt.add_theme_constant_override("letter_spacing", 2)
	var tit = Label.new()
	tit.text = "Conferência Sul"
	tit.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	tit.add_theme_color_override("font_color", Color.WHITE)
	tit.add_theme_font_size_override("font_size", 16)
	title_vbox.add_child(subt)
	title_vbox.add_child(tit)
	header_hbox.add_child(title_vbox)
	
	var legend_hbox = HBoxContainer.new()
	legend_hbox.add_theme_constant_override("separation", 16)
	legend_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	legend_hbox.add_child(_create_legend_item("PLAYOFFS", ThemeConfig.SUCCESS))
	legend_hbox.add_child(_create_legend_item("PLAY-IN", ThemeConfig.WARNING))
	legend_hbox.add_child(_create_legend_item("REBAIX.", ThemeConfig.DANGER))
	header_hbox.add_child(legend_hbox)
	
	header_pad.add_child(header_hbox)
	main_vbox.add_child(header_pad)
	
	# COLUMNS HEADER
	var col_header_bg = PanelContainer.new()
	var ch_style = StyleBoxFlat.new()
	ch_style.bg_color = Color(0,0,0,0)
	ch_style.content_margin_left = 24
	ch_style.content_margin_right = 24
	ch_style.content_margin_top = 8
	ch_style.content_margin_bottom = 8
	ch_style.border_color = ThemeConfig.BORDER_SUBTLE
	ch_style.border_width_bottom = 1
	col_header_bg.add_theme_stylebox_override("panel", ch_style)
	
	var col_hbox = HBoxContainer.new()
	col_hbox.add_theme_constant_override("separation", 16)
	col_hbox.add_child(_create_col_lbl("#", 24, false))
	col_hbox.add_child(_create_col_lbl("TIME", 0, true))
	col_hbox.add_child(_create_col_lbl("V", 30, false))
	col_hbox.add_child(_create_col_lbl("D", 30, false))
	col_hbox.add_child(_create_col_lbl("%", 50, false))
	col_hbox.add_child(_create_col_lbl("FORMA", 70, false))
	col_hbox.add_child(_create_col_lbl("SEQ", 30, false))
	col_header_bg.add_child(col_hbox)
	main_vbox.add_child(col_header_bg)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	rows_container = VBoxContainer.new()
	rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_container.add_theme_constant_override("separation", 0)
	scroll.add_child(rows_container)
	main_vbox.add_child(scroll)

func _create_legend_item(txt: String, color: Color) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var dot = PanelContainer.new()
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 4; s.corner_radius_top_right = 4; s.corner_radius_bottom_left = 4; s.corner_radius_bottom_right = 4
	dot.add_theme_stylebox_override("panel", s)
	var l = Label.new()
	l.text = txt
	l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	h.add_child(dot)
	h.add_child(l)
	return h

func _create_col_lbl(txt: String, w: int, expand: bool) -> Label:
	var l = Label.new()
	l.text = txt
	l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	l.add_theme_constant_override("letter_spacing", 1)
	if expand:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		l.custom_minimum_size = Vector2(w, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func refresh(teams: Array) -> void:
	if not rows_container: return
	for child in rows_container.get_children():
		child.queue_free()
		
	var sorted_teams = teams.duplicate()
	sorted_teams.sort_custom(func(a, b): return a.get("wins", 0) > b.get("wins", 0) if a.get("wins", 0) != b.get("wins", 0) else a.get("losses", 0) < b.get("losses", 0))
	
	var idx = 1
	for t in sorted_teams:
		var is_user = t.get("id", -1) == GameManager.user_team_id
		var row_bg = PanelContainer.new()
		var rs = StyleBoxFlat.new()
		
		if is_user:
			rs.bg_color = Color("#1A0B2E")
			rs.border_color = ThemeConfig.BRAND_PRIMARY
			rs.border_width_left = 4
		else:
			rs.bg_color = Color(0,0,0,0)
			rs.border_color = ThemeConfig.BORDER_SUBTLE
			rs.border_width_bottom = 1
			
		rs.content_margin_left = 24
		rs.content_margin_right = 24
		rs.content_margin_top = 12
		rs.content_margin_bottom = 12
		row_bg.add_theme_stylebox_override("panel", rs)
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		
		# Position Circle
		var c_style = StyleBoxFlat.new()
		c_style.corner_radius_top_left = 12; c_style.corner_radius_top_right = 12
		c_style.corner_radius_bottom_left = 12; c_style.corner_radius_bottom_right = 12
		if idx <= 6:
			c_style.bg_color = ThemeConfig.SUCCESS
		elif idx <= 8:
			c_style.bg_color = ThemeConfig.WARNING
		else:
			c_style.bg_color = ThemeConfig.DANGER
			
		var pnl = PanelContainer.new()
		pnl.add_theme_stylebox_override("panel", c_style)
		pnl.custom_minimum_size = Vector2(24, 24)
		var l_pos = Label.new()
		l_pos.text = str(idx)
		l_pos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l_pos.add_theme_color_override("font_color", Color.WHITE)
		l_pos.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		l_pos.add_theme_font_size_override("font_size", 12)
		pnl.add_child(l_pos)
		row.add_child(pnl)
		
		# Name (with small dot)
		var n_hbox = HBoxContainer.new()
		n_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n_hbox.add_theme_constant_override("separation", 8)
		
		var t_dot = PanelContainer.new()
		t_dot.custom_minimum_size = Vector2(6, 6)
		t_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var tds = StyleBoxFlat.new()
		tds.corner_radius_top_left = 3; tds.corner_radius_top_right = 3; tds.corner_radius_bottom_left = 3; tds.corner_radius_bottom_right = 3
		var team_colors = [ThemeConfig.BRAND_PRIMARY, ThemeConfig.SUCCESS, ThemeConfig.WARNING, ThemeConfig.INFO, Color("#38BDF8"), Color("#F43F5E"), ThemeConfig.TEXT_MUTED]
		tds.bg_color = team_colors[idx % team_colors.size()]
		t_dot.add_theme_stylebox_override("panel", tds)
		n_hbox.add_child(t_dot)
		
		var l_name = Label.new()
		l_name.text = t.get("name", "Desconhecido")
		if is_user:
			l_name.add_theme_color_override("font_color", Color.WHITE)
			l_name.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		else:
			l_name.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
			l_name.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		l_name.add_theme_font_size_override("font_size", 13)
		n_hbox.add_child(l_name)
		row.add_child(n_hbox)
		
		# Wins
		var l_w = Label.new()
		l_w.custom_minimum_size = Vector2(30, 0)
		l_w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l_w.text = str(t.get("wins", 0))
		l_w.add_theme_color_override("font_color", ThemeConfig.SUCCESS)
		l_w.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		l_w.add_theme_font_size_override("font_size", 13)
		row.add_child(l_w)
		
		# Losses
		var l_l = Label.new()
		l_l.custom_minimum_size = Vector2(30, 0)
		l_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l_l.text = str(t.get("losses", 0))
		l_l.add_theme_color_override("font_color", ThemeConfig.DANGER)
		l_l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		l_l.add_theme_font_size_override("font_size", 13)
		row.add_child(l_l)
		
		# Pct
		var l_pct = Label.new()
		l_pct.custom_minimum_size = Vector2(50, 0)
		l_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var t_w = t.get("wins", 0)
		var t_l = t.get("losses", 0)
		var total = float(t_w + t_l)
		var pct = float(t_w) / total if total > 0.0 else 0.0
		var pct_str = "%.3f" % pct
		pct_str = pct_str.replace("0.", ".") # e.g. .800
		l_pct.text = pct_str
		l_pct.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		l_pct.add_theme_color_override("font_color", Color.WHITE)
		l_pct.add_theme_font_size_override("font_size", 13)
		row.add_child(l_pct)
		
		# Form (5 boxes)
		var f_box = HBoxContainer.new()
		f_box.custom_minimum_size = Vector2(70, 0)
		f_box.alignment = BoxContainer.ALIGNMENT_CENTER
		f_box.add_theme_constant_override("separation", 4)
		for i in range(5):
			var form_res = (idx + i) % 3 != 0 # pseudo-random form
			var sq = PanelContainer.new()
			sq.custom_minimum_size = Vector2(8, 8)
			sq.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var sqs = StyleBoxFlat.new()
			sqs.corner_radius_top_left = 2; sqs.corner_radius_top_right = 2; sqs.corner_radius_bottom_left = 2; sqs.corner_radius_bottom_right = 2
			sqs.bg_color = ThemeConfig.SUCCESS if form_res else ThemeConfig.DANGER
			sq.add_theme_stylebox_override("panel", sqs)
			f_box.add_child(sq)
		row.add_child(f_box)
		
		# Streak
		var streak_lbl = Label.new()
		streak_lbl.custom_minimum_size = Vector2(30, 0)
		streak_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var s_win = t.get("wins", 0) > t.get("losses", 0)
		var s_num = (t.get("wins", 0) % 4) + 1
		streak_lbl.text = ("V" if s_win else "D") + str(s_num)
		streak_lbl.add_theme_color_override("font_color", ThemeConfig.SUCCESS if s_win else ThemeConfig.DANGER)
		streak_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		streak_lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(streak_lbl)
		
		row_bg.add_child(row)
		rows_container.add_child(row_bg)
		idx += 1
