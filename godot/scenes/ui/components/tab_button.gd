@tool
extends Button
class_name TabButton

@export var is_active: bool = false:
	set(val):
		is_active = val
		_update_styles()

func _ready():
	_update_styles()

func _update_styles():
	var style_normal = StyleBoxFlat.new()
	var style_active = StyleBoxFlat.new()
	
	style_normal.bg_color = Color(0,0,0,0)
	if Engine.is_editor_hint():
		style_active.bg_color = Color("#A78BFA")
	else:
		style_active.bg_color = ThemeConfig.BRAND_PRIMARY
		add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		
	for s in [style_normal, style_active]:
		s.corner_radius_top_left = 8
		s.corner_radius_top_right = 8
		s.corner_radius_bottom_left = 8
		s.corner_radius_bottom_right = 8
		s.content_margin_left = 16
		s.content_margin_right = 16
		s.content_margin_top = 8
		s.content_margin_bottom = 8
		
	if is_active:
		add_theme_stylebox_override("normal", style_active)
		add_theme_stylebox_override("hover", style_active)
		add_theme_color_override("font_color", Color.WHITE)
		add_theme_color_override("font_hover_color", Color.WHITE)
	else:
		add_theme_stylebox_override("normal", style_normal)
		add_theme_stylebox_override("hover", style_normal)
		add_theme_color_override("font_color", Color("#94A3B8")) # TEXT_MUTED
		add_theme_color_override("font_hover_color", Color.WHITE)
		
	add_theme_color_override("font_pressed_color", Color.WHITE)
	add_theme_font_size_override("font_size", 12)
