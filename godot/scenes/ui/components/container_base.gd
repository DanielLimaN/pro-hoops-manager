@tool
extends PanelContainer
class_name ContainerBase

func _ready():
	var style = StyleBoxFlat.new()
	if Engine.is_editor_hint():
		style.bg_color = Color("#150826")
		style.border_color = Color("#2D1B4E")
	else:
		style.bg_color = ThemeConfig.BG_SURFACE
		style.border_color = ThemeConfig.BORDER_SUBTLE
		
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	
	add_theme_stylebox_override("panel", style)
