extends SceneTree

func _init():
	print("Starting theme update...")
	var theme_path = "res://theme.tres"
	var theme = ResourceLoader.load(theme_path) as Theme
	if not theme:
		theme = Theme.new()
	
	# Load font (fallback to default if not found)
	var font = null
	if ResourceLoader.exists("res://addons/at-icons/fonts/Inter-Bold.ttf"):
		font = load("res://addons/at-icons/fonts/Inter-Bold.ttf")
	
	# --- PrimaryButton ---
	theme.add_type(&"PrimaryButton")
	theme.set_type_variation(&"PrimaryButton", &"Button")
	
	var pb_normal = StyleBoxFlat.new()
	pb_normal.bg_color = Color("#A78BFA") # BRAND_PRIMARY
	pb_normal.corner_radius_top_left = 8; pb_normal.corner_radius_bottom_right = 8
	pb_normal.corner_radius_top_right = 8; pb_normal.corner_radius_bottom_left = 8
	pb_normal.content_margin_left = 24; pb_normal.content_margin_right = 24
	pb_normal.content_margin_top = 12; pb_normal.content_margin_bottom = 12
	
	var pb_hover = pb_normal.duplicate()
	pb_hover.bg_color = Color("#7C3AED") # BRAND_DEEP
	
	theme.set_stylebox("normal", &"PrimaryButton", pb_normal)
	theme.set_stylebox("hover", &"PrimaryButton", pb_hover)
	theme.set_stylebox("pressed", &"PrimaryButton", pb_hover)
	theme.set_color("font_color", &"PrimaryButton", Color.WHITE)
	theme.set_color("font_hover_color", &"PrimaryButton", Color.WHITE)
	if font: theme.set_font("font", &"PrimaryButton", font)
	theme.set_font_size("font_size", &"PrimaryButton", 14)
	
	# --- TabButton ---
	theme.add_type(&"TabButton")
	theme.set_type_variation(&"TabButton", &"Button")
	
	var tab_normal = StyleBoxFlat.new()
	tab_normal.bg_color = Color(0,0,0,0)
	tab_normal.content_margin_left = 16; tab_normal.content_margin_right = 16
	tab_normal.content_margin_top = 8; tab_normal.content_margin_bottom = 8
	tab_normal.corner_radius_top_left = 8; tab_normal.corner_radius_top_right = 8
	tab_normal.corner_radius_bottom_left = 8; tab_normal.corner_radius_bottom_right = 8
	
	var tab_active = tab_normal.duplicate()
	tab_active.bg_color = Color("#A78BFA")
	
	theme.set_stylebox("normal", &"TabButton", tab_normal)
	theme.set_stylebox("hover", &"TabButton", tab_normal)
	# pressed/active can be handled by toggling theme_type_variation, but we'll set a standard
	theme.set_color("font_color", &"TabButton", Color("#94A3B8")) # TEXT_MUTED
	theme.set_color("font_hover_color", &"TabButton", Color.WHITE)
	if font: theme.set_font("font", &"TabButton", font)
	theme.set_font_size("font_size", &"TabButton", 12)
	
	# Active tab variation
	theme.add_type(&"TabButtonActive")
	theme.set_type_variation(&"TabButtonActive", &"Button")
	theme.set_stylebox("normal", &"TabButtonActive", tab_active)
	theme.set_stylebox("hover", &"TabButtonActive", tab_active)
	theme.set_color("font_color", &"TabButtonActive", Color.WHITE)
	if font: theme.set_font("font", &"TabButtonActive", font)
	theme.set_font_size("font_size", &"TabButtonActive", 12)
	
	# --- IconButton ---
	theme.add_type(&"IconButton")
	theme.set_type_variation(&"IconButton", &"Button")
	var ib_normal = StyleBoxFlat.new()
	ib_normal.bg_color = Color("#150826")
	ib_normal.corner_radius_top_left = 20; ib_normal.corner_radius_top_right = 20
	ib_normal.corner_radius_bottom_left = 20; ib_normal.corner_radius_bottom_right = 20
	ib_normal.border_width_left = 1; ib_normal.border_width_right = 1
	ib_normal.border_width_top = 1; ib_normal.border_width_bottom = 1
	ib_normal.border_color = Color("#2D1B4E")
	
	var ib_hover = ib_normal.duplicate()
	ib_hover.bg_color = Color("#1A0B2E")
	
	theme.set_stylebox("normal", &"IconButton", ib_normal)
	theme.set_stylebox("hover", &"IconButton", ib_hover)
	theme.set_stylebox("pressed", &"IconButton", ib_hover)
	theme.set_stylebox("focus", &"IconButton", StyleBoxEmpty.new())
	
	var err = ResourceSaver.save(theme, theme_path)
	print("Theme update finished. Error Code: ", err)
	quit()
