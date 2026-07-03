@tool
extends PanelContainer
class_name AttributeBadge

@export var value: String = "90":
	set(val):
		value = val
		_update_ui()

@export var badge_type: String = "ovr": # "ovr", "pos", "status"
	set(val):
		badge_type = val
		_update_ui()

@onready var label: Label = $Label

func _ready():
	_update_ui()

func _update_ui():
	if not is_inside_tree(): return
	if not label: label = $Label
	
	label.text = value
	
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left=6; style.corner_radius_bottom_right=6; style.corner_radius_top_right=6; style.corner_radius_bottom_left=6
	
	var col = Color("#94A3B8") # Muted default
	
	if not Engine.is_editor_hint():
		if badge_type == "ovr":
			style.border_width_bottom = 0
			var num_val = value.to_int()
			if num_val >= 90: col = ThemeConfig.BRAND_PRIMARY
			elif num_val >= 85: col = ThemeConfig.SUCCESS
			elif num_val >= 80: col = ThemeConfig.WARNING
			else: col = ThemeConfig.TEXT_MUTED
			style.bg_color = col
			label.add_theme_color_override("font_color", Color.WHITE)
			custom_minimum_size = Vector2(36, 24)
			
		elif badge_type == "pos":
			style.bg_color = Color(0,0,0,0)
			style.border_width_left=1; style.border_width_right=1; style.border_width_top=1; style.border_width_bottom=1
			if "G" in value: col = ThemeConfig.BRAND_PRIMARY
			elif "F" in value: col = ThemeConfig.SUCCESS
			elif "C" in value: col = ThemeConfig.DANGER
			style.border_color = col
			label.add_theme_color_override("font_color", col)
			custom_minimum_size = Vector2(40, 24)
			
		elif badge_type == "status":
			style.bg_color = Color(0,0,0,0)
			style.border_width_left=1; style.border_width_right=1; style.border_width_top=1; style.border_width_bottom=1
			if value == "ATIVO": col = ThemeConfig.SUCCESS
			elif value == "CANSADO": col = ThemeConfig.WARNING
			else: col = ThemeConfig.DANGER
			style.border_color = col
			label.add_theme_color_override("font_color", col)
			custom_minimum_size = Vector2(80, 24)
			
		label.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	else:
		# Editor fallback
		style.bg_color = Color("#5B21B6")
		label.add_theme_color_override("font_color", Color.WHITE)
		custom_minimum_size = Vector2(36, 24)
		
	add_theme_stylebox_override("panel", style)
