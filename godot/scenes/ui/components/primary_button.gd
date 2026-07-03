@tool
extends Button
class_name PrimaryButton

func _ready():
	var style_normal = StyleBoxFlat.new()
	var style_hover = StyleBoxFlat.new()
	
	if Engine.is_editor_hint():
		style_normal.bg_color = Color("#A78BFA")
		style_hover.bg_color = Color("#7C3AED")
	else:
		style_normal.bg_color = ThemeConfig.BRAND_PRIMARY
		style_hover.bg_color = ThemeConfig.BRAND_DEEP
		add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		
	for s in [style_normal, style_hover]:
		s.corner_radius_top_left = 8
		s.corner_radius_top_right = 8
		s.corner_radius_bottom_left = 8
		s.corner_radius_bottom_right = 8
		s.content_margin_left = 24
		s.content_margin_right = 24
		s.content_margin_top = 12
		s.content_margin_bottom = 12
		
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_hover)
	
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_color_override("font_hover_color", Color.WHITE)
	add_theme_color_override("font_pressed_color", Color.WHITE)
	add_theme_font_size_override("font_size", 14)
