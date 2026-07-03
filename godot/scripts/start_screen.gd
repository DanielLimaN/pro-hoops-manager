extends Control

var custom_font = SystemFont.new()

func _init():
	custom_font.font_names = PackedStringArray(["Inter", "Helvetica Neue", "Arial", "sans-serif"])
	custom_font.font_weight = 900
	custom_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	custom_font.generate_mipmaps = true

func _ready():
	# 1. Background Image
	var bg_tex = TextureRect.new()
	bg_tex.texture = load("res://assets/images/start_bg.jpg")
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_tex)
	
	# 2. Dark Overlay for Contrast
	var overlay = ColorRect.new()
	overlay.color = Color(0.01, 0.01, 0.03, 0.5)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	# 3. Main Container (Glassmorphism Panel)
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 250)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.08, 0.8)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.5, 0.2, 1.0, 0.4)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	panel_style.shadow_size = 20
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	# 4. Logo Component
	var logo_scene = preload("res://scenes/components/logo.tscn")
	var logo = logo_scene.instantiate()
	logo.variant = "vertical"
	logo.theme_name = "dark-purple"
	logo.logo_size = 120
	logo.show_text = true
	vbox.add_child(logo)
	
	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_vbox)
	
	# 5. Buttons
	if GameManager.has_save():
		var continue_btn = _create_btn("CONTINUE CAREER", true)
		btn_vbox.add_child(continue_btn)
		continue_btn.pressed.connect(func():
			_show_loading(continue_btn)
			await get_tree().process_frame
			await get_tree().process_frame
			
			if GameManager.load_career():
				get_tree().change_scene_to_file("res://scenes/main.tscn")
		)
		
	var new_btn = _create_btn("NEW CAREER", not GameManager.has_save())
	btn_vbox.add_child(new_btn)
	new_btn.pressed.connect(func():
		GameManager.league.clear()
		get_tree().change_scene_to_file("res://scenes/new_game.tscn")
	)

func _show_loading(btn: Button):
	var load_bg = ColorRect.new()
	load_bg.color = Color(0.05, 0.05, 0.08, 0.9)
	load_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_parent().add_child(load_bg)
	
	var load_lbl = Label.new()
	load_lbl.text = "LOADING DATABASE..."
	load_lbl.add_theme_font_override("font", custom_font)
	load_lbl.add_theme_font_size_override("font_size", 24)
	load_lbl.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	load_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	load_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	load_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	load_bg.add_child(load_lbl)

func _create_btn(txt: String, primary: bool) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.add_theme_font_override("font", custom_font)
	btn.add_theme_font_size_override("font_size", 16)
	btn.custom_minimum_size = Vector2(250, 45)
	
	var style = StyleBoxFlat.new()
	if primary:
		style.bg_color = Color(0.4, 0.15, 0.9, 0.9)
		style.border_color = Color(0.7, 0.4, 1.0)
	else:
		style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
		style.border_color = Color(0.3, 0.3, 0.4)
		
	style.border_width_left = 1; style.border_width_top = 1
	style.border_width_right = 1; style.border_width_bottom = 1
	style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4; style.corner_radius_bottom_left = 4
	
	var hover_style = style.duplicate()
	if primary:
		hover_style.bg_color = Color(0.5, 0.2, 1.0, 1.0)
		hover_style.shadow_color = Color(0.7, 0.3, 1.0, 0.6)
		hover_style.shadow_size = 10
	else:
		hover_style.bg_color = Color(0.2, 0.2, 0.25, 0.9)
		hover_style.border_color = Color(0.5, 0.5, 0.6)
		
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", style)
	
	return btn
