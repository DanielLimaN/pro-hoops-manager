extends Control

func _ready():
	_refresh()

func _refresh():
	var league = GameManager.league
	if league.is_empty():
		return

	var all_players = []
	for team in league.teams:
		for player in team.players:
			player["team_abbr"] = team.abbreviation
			all_players.append(player)

	all_players.sort_custom(func(a, b): return a.overall > b.overall)

	var table = %ScoutTable
	for child in table.get_children():
		child.queue_free()

	var header = _row(["Pos", "Nome", "Time", "Idade", "OVR", "POT", "3PT", "MID", "PAS", "DEF", "Salario"], true, 0)
	table.add_child(header)

	for i in range(min(50, all_players.size())):
		var p = all_players[i]
		var avg_def = (p.attributes.perimeter_def + p.attributes.interior_def) / 2.0
		var row_ui = _row([
			p.position, p.last_name + " " + p.first_name, p.team_abbr,
			str(p.age), str(floor(p.overall)), str(floor(p.attributes.potential)),
			str(floor(p.attributes.three_pt)), str(floor(p.attributes.mid_range)),
			str(floor(p.attributes.passing)), str(floor(avg_def)),
			"$" + _fmt(p.salary)
		], false, i+1)
		
		var btn = Button.new()
		btn.text = "Perfil"
		btn.custom_minimum_size = Vector2(50, 20)
		btn.add_theme_font_size_override("font_size", 11)
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.35, 0.2, 0.8, 1)
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_right = 4
		sb.corner_radius_bottom_left = 4
		btn.add_theme_stylebox_override("normal", sb)
		
		btn.pressed.connect(func():
			var profile = load("res://scenes/player_profile.tscn").instantiate()
			profile.load_player(p)
			
			var root = get_tree().root
			# Encontra a cena Main e a oculta para não ter sobreposição
			if root.has_node("Main"):
				root.get_node("Main").hide()
				
			root.add_child(profile)
		)
		
		row_ui.get_child(0).add_child(btn)
		
		table.add_child(row_ui)

func _row(columns: Array, is_header: bool = false, index: int = 0) -> Control:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	
	if is_header:
		style.bg_color = Color(0.12, 0.12, 0.17, 1.0)
	elif index % 2 == 0:
		style.bg_color = Color(0.16, 0.16, 0.22, 1.0)
	else:
		style.bg_color = Color(0.14, 0.14, 0.2, 1.0)
		
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	
	for i in range(columns.size()):
		var label = Label.new()
		label.text = columns[i]
		
		# Name (index 1)
		if i == 1:
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.custom_minimum_size = Vector2(100, 20)
		elif i == 0:
			label.custom_minimum_size = Vector2(30, 20)
		elif i == 2:
			label.custom_minimum_size = Vector2(40, 20)
		else:
			label.custom_minimum_size = Vector2(45, 20)
			
		label.add_theme_font_size_override("font_size", 13)
		
		if is_header:
			label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		elif i == 4: # OVR highlight
			label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
		elif i == 5: # POT highlight
			label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
			
		row.add_child(label)
		
	panel.add_child(row)
	return panel

func _fmt(amount: int) -> String:
	if amount >= 1000000:
		return str(amount / 1000000.0).pad_decimals(1) + "M"
	return str(amount / 1000) + "K"
