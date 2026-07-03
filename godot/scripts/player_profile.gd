extends Control

var player_data: Dictionary

func _ready():
	%BackButton.pressed.connect(func():
		var root = get_tree().root
		if root.has_node("Main"):
			root.get_node("Main").show()
		queue_free()
	)
	
	if not player_data.is_empty():
		_populate_data(player_data)

func load_player(p: Dictionary):
	player_data = p

func _populate_data(p: Dictionary):
	%NameLabel.text = p.get("first_name", "") + " " + p.get("last_name", "")
	%SubLabel.text = p.get("position", "") + " | OVR: " + str(floor(p.get("overall", 50)))
	
	_load_avatar(p.get("first_name", "") + p.get("last_name", ""))
	
	_build_pbm_layout(p)

func _build_pbm_layout(p: Dictionary):
	var body = %BodyVBox
	for c in body.get_children(): c.queue_free()
	
	var title = Label.new()
	title.text = "CHARACTERISTICS OF " + p.get("last_name", "").to_upper()
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	body.add_child(title)
	
	var top_grid = HBoxContainer.new()
	top_grid.add_theme_constant_override("separation", 24)
	body.add_child(top_grid)
	
	# === LEFT PANEL: PREFERRED POSITIONS & PROFILES ===
	var left_col = VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_stretch_ratio = 1.0
	top_grid.add_child(left_col)
	
	_add_section_title(left_col, "PREFERRED POSITIONS")
	
	var court = Control.new()
	court.custom_minimum_size = Vector2(0, 150)
	court.set_script(preload("res://scripts/pref_pos.gd"))
	court.set("positions", [p.get("position", "PG")])
	left_col.add_child(court)
	
	var sep1 = HSeparator.new()
	sep1.add_theme_constant_override("separation", 20)
	left_col.add_child(sep1)
	
	_add_section_title(left_col, "PROFILES")
	var attrs = p.get("attributes", {})
	_add_profile_row(left_col, "Outside Shooter", attrs.get("three_pt", 50))
	_add_profile_row(left_col, "Mid-range shooter", attrs.get("mid_range", 50))
	_add_profile_row(left_col, "Inside shooter", attrs.get("layup", 50))
	_add_profile_row(left_col, "Playmaker", attrs.get("passing", 50))
	_add_profile_row(left_col, "Defender", (attrs.get("perimeter_def", 50) + attrs.get("interior_def", 50))/2.0)
	
	# === MIDDLE PANELS: ATTRIBUTES (OFFENSE, DEFENSE, PHYSICAL, MENTAL) ===
	var mid_col = GridContainer.new()
	mid_col.columns = 4
	mid_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_col.size_flags_stretch_ratio = 3.5
	mid_col.add_theme_constant_override("h_separation", 24)
	top_grid.add_child(mid_col)
	
	var off_vbox = VBoxContainer.new()
	var def_vbox = VBoxContainer.new()
	var phy_vbox = VBoxContainer.new()
	var men_vbox = VBoxContainer.new()
	
	off_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	def_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phy_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	men_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_add_section_title(off_vbox, "OFFENSE")
	_add_section_title(def_vbox, "DEFENSE")
	_add_section_title(phy_vbox, "PHYSICAL")
	_add_section_title(men_vbox, "MENTAL")
	
	# Offense
	_add_attr_row(off_vbox, "3pts Shooting", attrs.get("three_pt", 50))
	_add_attr_row(off_vbox, "Mid-range", attrs.get("mid_range", 50))
	_add_attr_row(off_vbox, "Inside shooting", attrs.get("close_shot", 50))
	_add_attr_row(off_vbox, "Drive", attrs.get("layup", 50))
	_add_attr_row(off_vbox, "Free Throws", attrs.get("free_throw", 50))
	_add_attr_row(off_vbox, "Dribble", attrs.get("ball_handle", 50))
	_add_attr_row(off_vbox, "Pass", attrs.get("passing", 50))
	
	# Defense
	_add_attr_row(def_vbox, "Perimeter def", attrs.get("perimeter_def", 50))
	_add_attr_row(def_vbox, "Interior def", attrs.get("interior_def", 50))
	_add_attr_row(def_vbox, "Steal", attrs.get("steal", 50))
	_add_attr_row(def_vbox, "Block", attrs.get("block", 50))
	_add_attr_row(def_vbox, "Off. rebound", attrs.get("offensive_rebound", 50))
	_add_attr_row(def_vbox, "Def. rebound", attrs.get("defensive_rebound", 50))
	
	# Physical
	_add_attr_row(phy_vbox, "Speed", attrs.get("speed", 50))
	_add_attr_row(phy_vbox, "Stamina", attrs.get("stamina", 50))
	_add_attr_row(phy_vbox, "Jump", attrs.get("jumping", 50))
	_add_attr_row(phy_vbox, "Power", attrs.get("strength", 50))
	
	# Mental (Mocked from IQ/Clutch/Overall)
	_add_attr_row(men_vbox, "Basketball IQ", attrs.get("basketball_iq", 50))
	_add_attr_row(men_vbox, "Clutch", attrs.get("clutch", 50))
	_add_attr_row(men_vbox, "Consistency", clamp(attrs.get("basketball_iq", 50) + 5, 0, 99))
	_add_attr_row(men_vbox, "Experience", clamp(p.get("age", 20) * 3, 0, 99))
	
	mid_col.add_child(off_vbox)
	mid_col.add_child(def_vbox)
	mid_col.add_child(phy_vbox)
	mid_col.add_child(men_vbox)
	
	# === RIGHT PANEL: OVERALL RADAR ===
	var right_col = VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_stretch_ratio = 1.0
	top_grid.add_child(right_col)
	
	_add_section_title(right_col, "OVERALL")
	
	var off_avg = (attrs.get("three_pt", 50) + attrs.get("passing", 50) + attrs.get("layup", 50)) / 3.0
	var def_avg = (attrs.get("perimeter_def", 50) + attrs.get("interior_def", 50) + attrs.get("steal", 50)) / 3.0
	var phy_avg = (attrs.get("speed", 50) + attrs.get("strength", 50) + attrs.get("stamina", 50)) / 3.0
	var men_avg = (attrs.get("basketball_iq", 50) + attrs.get("clutch", 50)) / 2.0
	
	var radar = Control.new()
	radar.custom_minimum_size = Vector2(0, 180)
	radar.set_script(preload("res://scripts/radar_chart.gd"))
	radar.set("values", [off_avg, def_avg, phy_avg, men_avg])
	right_col.add_child(radar)
	
	# === BOTTOM SECTION: PERSONAL INFO ===
	var bot_grid = HBoxContainer.new()
	bot_grid.add_theme_constant_override("separation", 24)
	body.add_child(bot_grid)
	
	var b_left = VBoxContainer.new()
	b_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_grid.add_child(b_left)
	_add_section_title(b_left, "PERSONAL INFORMATION")
	_add_info_row(b_left, "Age", str(p.get("age", 20)) + " years old")
	_add_info_row(b_left, "Height", ("%0.2f" % attrs.get("height_cm", 0.0)) + " cm")
	_add_info_row(b_left, "Weight", ("%0.2f" % attrs.get("weight_kg", 0.0)) + " kg")
	_add_info_row(b_left, "Nationality", "N/A")
	
	var b_mid = VBoxContainer.new()
	b_mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_grid.add_child(b_mid)
	_add_section_title(b_mid, "CONTRACT")
	_add_info_row(b_mid, "Annual salary", "$" + _fmt(p.get("salary", 0)) + "/year")
	_add_info_row(b_mid, "Contract year", str(p.get("contract_year", 1)))

func _add_section_title(parent, title_text):
	var lbl = Label.new()
	lbl.text = title_text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	parent.add_child(lbl)
	
	var sep = ColorRect.new()
	sep.color = Color(0.25, 0.15, 0.4)
	sep.custom_minimum_size = Vector2(0, 1)
	parent.add_child(sep)

func _add_profile_row(parent, prof_name, val):
	var hbox = HBoxContainer.new()
	
	var lbl = Label.new()
	lbl.text = prof_name
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	hbox.add_child(lbl)
	
	var star_count = round(val / 20.0)
	for i in range(5):
		var st = TextureRect.new()
		st.texture = load("res://addons/at-icons/control/star.svg")
		st.custom_minimum_size = Vector2(10, 10)
		st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		st.modulate = ThemeConfig.WARNING if i < star_count else ThemeConfig.BORDER_SUBTLE
		hbox.add_child(st)

	parent.add_child(hbox)

func _add_attr_row(parent, attr_name, val):
	var hbox = HBoxContainer.new()
	
	var lbl = Label.new()
	lbl.text = attr_name
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	hbox.add_child(lbl)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(24, 20)
	var sb = StyleBoxFlat.new()
	
	if val >= 75: sb.bg_color = Color(0.1, 0.6, 0.2)
	elif val >= 60: sb.bg_color = Color(0.6, 0.6, 0.1)
	elif val >= 45: sb.bg_color = Color(0.7, 0.4, 0.1)
	else: sb.bg_color = Color(0.7, 0.2, 0.2)
	
	sb.corner_radius_top_left = 2; sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_right = 2; sb.corner_radius_bottom_left = 2
	panel.add_theme_stylebox_override("panel", sb)
	
	var vlbl = Label.new()
	vlbl.text = str(floor(val))
	vlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vlbl.add_theme_font_size_override("font_size", 11)
	panel.add_child(vlbl)
	
	hbox.add_child(panel)
	parent.add_child(hbox)

func _add_info_row(parent, k, v):
	var hbox = HBoxContainer.new()
	var lk = Label.new()
	lk.text = k
	lk.custom_minimum_size = Vector2(100, 0)
	lk.add_theme_font_size_override("font_size", 12)
	lk.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	hbox.add_child(lk)
	
	var lv = Label.new()
	lv.text = v
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.add_theme_font_size_override("font_size", 12)
	lv.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	hbox.add_child(lv)
	
	parent.add_child(hbox)

func _fmt(amount: int) -> String:
	if amount >= 1000000:
		return str(amount / 1000000.0).pad_decimals(1) + "M"
	return str(amount / 1000) + "K"

func _load_avatar(seed: String):
	if seed == "": return
	var avatar_dir = "user://avatars"
	if not DirAccess.dir_exists_absolute(avatar_dir):
		DirAccess.make_dir_absolute(avatar_dir)
		
	var file_path = avatar_dir + "/" + seed + ".png"
	if FileAccess.file_exists(file_path):
		var img = Image.new()
		if img.load(file_path) == OK:
			%Avatar.texture = ImageTexture.create_from_image(img)
	else:
		var http = HTTPRequest.new()
		add_child(http)
		http.request_completed.connect(self._on_avatar_downloaded.bind(http, file_path))
		var url = "https://api.dicebear.com/9.x/open-peeps/png?seed=" + seed.uri_encode()
		http.request(url)

func _on_avatar_downloaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_node: HTTPRequest, file_path: String):
	http_node.queue_free()
	if response_code == 200:
		var img = Image.new()
		if img.load_png_from_buffer(body) == OK:
			img.save_png(file_path)
			if %Avatar != null:
				%Avatar.texture = ImageTexture.create_from_image(img)
