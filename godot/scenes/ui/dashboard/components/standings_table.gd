extends PanelContainer

var row_scene = preload("res://scenes/ui/dashboard/components/standings_row.tscn")

func refresh(teams: Array) -> void:
	if %Rows:
		for c in %Rows.get_children():
			c.queue_free()
	
	if teams.is_empty():
		return
		
	var sorted = teams.duplicate()
	sorted.sort_custom(func(a, b): return a.get("wins", 0) > b.get("wins", 0) if a.get("wins", 0) != b.get("wins", 0) else a.get("losses", 0) < b.get("losses", 0))
	
	var user_team = GameManager.user_team_id
	var pos = 1
	for t in sorted:
		var r = row_scene.instantiate()
		%Rows.add_child(r)
		
		var is_user = t.get("id", -1) == user_team
		
		# Colors based on position
		var b_col = ThemeConfig.BRAND_PRIMARY
		var t_col = Color.WHITE
		if pos <= 6:
			b_col = ThemeConfig.SUCCESS
		elif pos <= 10:
			b_col = ThemeConfig.WARNING
		elif pos > 10:
			b_col = ThemeConfig.DANGER
			
		if is_user:
			# Highlight user row
			var bg_style = r.get_theme_stylebox("panel").duplicate()
			bg_style.bg_color = Color(ThemeConfig.BRAND_PRIMARY, 0.1)
			r.add_theme_stylebox_override("panel", bg_style)
		
		r.get_node("%PosBadge").self_modulate = b_col
		r.get_node("%PosLabel").text = str(pos)
		
		r.get_node("%TeamIcon").self_modulate = b_col
		r.get_node("%TeamName").text = t.get("name", "Team")
		if is_user:
			r.get_node("%TeamName").add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		
		var w = t.get("wins", 0)
		var l = t.get("losses", 0)
		var total = w + l
		var pct = float(w) / float(total) if total > 0 else 0.0
		
		r.get_node("%W").text = str(w)
		r.get_node("%L").text = str(l)
		r.get_node("%PCT").text = "%.3f" % pct
		
		var form_box = r.get_node("%FormBox")
		var form = t.get("form", [true, true, false, true, false])
		var form_idx = 0
		for child in form_box.get_children():
			if form_idx < form.size():
				child.self_modulate = ThemeConfig.SUCCESS if form[form_idx] else ThemeConfig.DANGER
			else:
				child.self_modulate = Color(0.2, 0.2, 0.2, 1) # Muted if not played
			form_idx += 1
			
		var seq_lbl = r.get_node("%Seq")
		var streak = t.get("streak", 0)
		if streak > 0:
			seq_lbl.text = "V" + str(streak)
			seq_lbl.add_theme_color_override("font_color", ThemeConfig.SUCCESS)
		elif streak < 0:
			seq_lbl.text = "D" + str(abs(streak))
			seq_lbl.add_theme_color_override("font_color", ThemeConfig.DANGER)
		else:
			seq_lbl.text = "-"
			seq_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
			
		pos += 1
