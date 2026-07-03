@tool
extends Button
class_name IconButton

func _ready():
	var style_normal = StyleBoxFlat.new()
	var style_hover = StyleBoxFlat.new()
	var style_focus = StyleBoxEmpty.new()
	
	if Engine.is_editor_hint():
		style_normal.bg_color = Color("#150826")
		style_hover.bg_color = Color("#1A0B2E")
		style_normal.border_color = Color("#2D1B4E")
		style_hover.border_color = Color("#2D1B4E")
	else:
		style_normal.bg_color = ThemeConfig.BG_SURFACE_ALT
		style_hover.bg_color = ThemeConfig.BG_ELEVATED
		style_normal.border_color = ThemeConfig.BORDER_DEFAULT
		style_hover.border_color = ThemeConfig.BORDER_DEFAULT
		
	for s in [style_normal, style_hover]:
		s.corner_radius_top_left = 20
		s.corner_radius_top_right = 20
		s.corner_radius_bottom_left = 20
		s.corner_radius_bottom_right = 20
		s.border_width_left = 1
		s.border_width_right = 1
		s.border_width_top = 1
		s.border_width_bottom = 1
		s.content_margin_left = 8
		s.content_margin_right = 8
		s.content_margin_top = 8
		s.content_margin_bottom = 8
		
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_hover)
	add_theme_stylebox_override("focus", style_focus)
