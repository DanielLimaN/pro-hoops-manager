extends Control

func _ready():
	_refresh()

func _refresh():
	var team = GameManager.get_user_team()
	if team.is_empty():
		return

	%TeamNameLabel.text = team.city + " " + team.name
	%RecordLabel.text = str(team.wins) + " W - " + str(team.losses) + " L"
	%OverallLabel.text = "OVR: " + str(floor(_avg_ovr(team.players)))
	%ChemistryLabel.text = "Química: " + str(floor(team.chemistry))

	_populate_standings()
	_populate_next_game()
	_populate_stats(team)

func _avg_ovr(players: Array) -> float:
	var total = 0.0
	if players.is_empty(): return 0.0
	for p in players:
		total += p.overall
	return total / players.size()

func _populate_standings():
	var table = %StandingsTable
	for child in table.get_children():
		child.queue_free()
		
	var header = _create_row(["Pos", "Equipe", "V", "D", "%", "OVR"], true, 0)
	table.add_child(header)

	var teams = GameManager.league.teams.duplicate()
	teams.sort_custom(func(a, b): return (a.wins - a.losses) > (b.wins - b.losses))

	for i in range(teams.size()):
		var t = teams[i]
		var pct = "0.000"
		var total_games = t.wins + t.losses
		if total_games > 0:
			pct = "%.3f" % (float(t.wins) / total_games)
			
		var row = _create_row([
			str(i+1), 
			t.city + " " + t.name,
			str(t.wins), 
			str(t.losses), 
			pct, 
			str(floor(_avg_ovr(t.players)))
		], false, i+1, t.id == GameManager.user_team_id)
		table.add_child(row)

func _create_row(columns: Array, is_header: bool = false, index: int = 0, is_user: bool = false) -> Control:
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
		
		# Name (index 1) expands
		if i == 1:
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.custom_minimum_size = Vector2(100, 20)
		elif i == 0:
			label.custom_minimum_size = Vector2(30, 20)
		else:
			label.custom_minimum_size = Vector2(40, 20)
			
		label.add_theme_font_size_override("font_size", 13)
		if is_header:
			label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		elif is_user:
			label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0)) # Highlight user team
		
		row.add_child(label)
		
	panel.add_child(row)
	return panel

func _populate_next_game():
	var schedule = GameManager.get_schedule()
	for game in schedule:
		if not game.played and (game.home_team == GameManager.user_team_id or game.away_team == GameManager.user_team_id):
			var league = GameManager.league
			var home_team = _find_team(league.teams, game.home_team)
			var away_team = _find_team(league.teams, game.away_team)
			
			%HomeTeamLabel.text = home_team.city + "\n" + home_team.name
			%AwayTeamLabel.text = away_team.city + "\n" + away_team.name
			
			%PlayButton.pressed.connect(func(): _on_play(game.home_team, game.away_team))
			break

func _populate_stats(team: Dictionary):
	# Just some placeholder stats to fill the bottom-left panel
	%PPGLabel.text = "104.5 PPG"
	%OPPLabel.text = "98.2 OPP"

func _find_team(teams: Array, team_id: int) -> Dictionary:
	for t in teams:
		if t.id == team_id:
			return t
	return {}

func _on_play(home_id: int, away_id: int):
	GameManager.pending_home_id = home_id
	GameManager.pending_away_id = away_id
	get_tree().change_scene_to_file("res://scenes/match.tscn")
