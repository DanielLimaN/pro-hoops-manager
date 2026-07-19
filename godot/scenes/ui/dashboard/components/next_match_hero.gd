extends PanelContainer

signal simulate_requested

func _ready() -> void:
	%SimBtn.pressed.connect(func(): emit_signal("simulate_requested"))

func setup(data: Dictionary) -> void:
	var day = data.get("day", 1)
	var month = data.get("month", 1)
	var hour = data.get("hour", 20)
	var min = data.get("minute", 0)
	var months = ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]
	%DateLabel.text = "%d %s • %dh%02d" % [day, months[month - 1], hour, min]

	var user_team = GameManager.user_team_id
	var home_id = data.get("home_team_id", 0)
	var away_id = data.get("away_team_id", 0)
	var is_home = home_id == user_team
	%HaPill.text = " CASA " if is_home else " FORA "

	var league_teams = GameManager.league.teams
	var ht = _find_team(league_teams, home_id)
	var at = _find_team(league_teams, away_id)

	%HomeAbbr.text = ht.get("abbreviation", "H") if ht else "H"
	%AwayAbbr.text = at.get("abbreviation", "A") if at else "A"
	%HomeName.text = ht.get("name", "HOME").to_upper() if ht else "HOME"
	%AwayName.text = at.get("name", "AWAY").to_upper() if at else "AWAY"
	
	%HomeRecord.text = str(ht.get("wins", 0)) + "V - " + str(ht.get("losses", 0)) + "D" if ht else ""
	%AwayRecord.text = str(at.get("wins", 0)) + "V - " + str(at.get("losses", 0)) + "D" if at else ""
	
	# Injetar Escudos
	_apply_team_shield(%HomeAbbr, ht.get("abbreviation", "H"))
	_apply_team_shield(%AwayAbbr, at.get("abbreviation", "A"))

func _apply_team_shield(abbr_node: Label, abbr_str: String) -> void:
	if not abbr_node: return
	
	var shield_path = "res://assets/teams/%s.png" % abbr_str.to_lower()
	var center_container = abbr_node.get_parent()
	var circle_panel = center_container.get_parent() # O verdadeiro painel com o fundo colorido
	
	if ResourceLoader.exists(shield_path):
		abbr_node.hide() 
		
		var tex_rect = circle_panel.get_node_or_null("TeamShield")
		if not tex_rect:
			tex_rect = TextureRect.new()
			tex_rect.name = "TeamShield"
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			# Usamos âncoras personalizadas para o escudo sangrar o painel em 20px pra cada lado
			tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			tex_rect.anchor_left = 0
			tex_rect.anchor_top = 0
			tex_rect.anchor_right = 1
			tex_rect.anchor_bottom = 1
			tex_rect.offset_left = -20
			tex_rect.offset_top = -20
			tex_rect.offset_right = 20
			tex_rect.offset_bottom = 20
			
			# Injeta no panel por cima de tudo
			circle_panel.add_child(tex_rect)
			
		tex_rect.texture = load(shield_path)
		tex_rect.show()
		
		# Limpa o fundo do painel e as bordas
		var style = circle_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if style:
			style.bg_color = Color(0, 0, 0, 0)
			style.border_width_left = 0
			style.border_width_right = 0
			style.border_width_top = 0
			style.border_width_bottom = 0
			style.shadow_size = 0
			circle_panel.add_theme_stylebox_override("panel", style)
	else:
		abbr_node.show()

	%Prediction.text = "Previsão: 58% V"

func _find_team(teams: Array, id: int) -> Dictionary:
	for t in teams:
		if t.get("id", -1) == id: return t
	return {}
