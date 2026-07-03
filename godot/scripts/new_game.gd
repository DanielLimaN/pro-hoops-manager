extends Control

func _ready():
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.13)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 24)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "CREATE MANAGER PROFILE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.8, 0.5, 1.0))
	vbox.add_child(title)
	
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	vbox.add_child(grid)
	
	# Name
	var name_lbl = Label.new()
	name_lbl.text = "Coach Name:"
	grid.add_child(name_lbl)
	
	var name_input = LineEdit.new()
	name_input.placeholder_text = "John Doe"
	name_input.custom_minimum_size = Vector2(200, 30)
	grid.add_child(name_input)
	
	# Focus
	var focus_lbl = Label.new()
	focus_lbl.text = "Coaching Style:"
	grid.add_child(focus_lbl)
	
	var focus_input = OptionButton.new()
	focus_input.add_item("Tactical Mastermind")
	focus_input.add_item("Youth Development")
	focus_input.add_item("Motivator")
	grid.add_child(focus_input)
	
	# Team
	var team_lbl = Label.new()
	team_lbl.text = "Select Franchise:"
	grid.add_child(team_lbl)
	
	var team_input = OptionButton.new()
	var team_names = [
		"São Paulo Dragões", "Rio de Janeiro Fênix", "Belo Horizonte Trovões",
		"Curitiba Lobos", "Porto Alegre Águias", "Brasília Jaguars",
		"Salvador Tubarões", "Recife Corsários", "Fortaleza Leões",
		"Manaus Guerreiros", "Goiânia Cangurus", "Florianópolis Tsunamis"
	]
	for i in range(team_names.size()):
		team_input.add_item(team_names[i], i + 1)
	grid.add_child(team_input)
	
	var start_btn = Button.new()
	start_btn.text = "START CAREER"
	start_btn.add_theme_font_size_override("font_size", 20)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.45, 0.2, 0.95)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6; style.corner_radius_bottom_left = 6
	style.content_margin_top = 12; style.content_margin_bottom = 12
	start_btn.add_theme_stylebox_override("normal", style)
	start_btn.add_theme_stylebox_override("hover", style)
	vbox.add_child(start_btn)
	
	start_btn.pressed.connect(func():
		var coach_name = name_input.text
		if coach_name.is_empty():
			coach_name = "Coach"
		var focus = focus_input.get_item_text(focus_input.selected)
		var team_id = team_input.get_item_id(team_input.selected)
		
		# Loading Overlay
		var load_bg = ColorRect.new()
		load_bg.color = Color(0.05, 0.05, 0.08, 0.9)
		load_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(load_bg)
		
		var load_lbl = Label.new()
		load_lbl.text = "GERANDO LIGA E PREPARANDO BANCO DE DADOS..."
		load_lbl.add_theme_font_size_override("font_size", 24)
		load_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		load_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		load_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		load_bg.add_child(load_lbl)
		
		await get_tree().process_frame
		await get_tree().process_frame
		
		GameManager.new_game(coach_name, team_id, focus)
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
