@tool
extends PanelContainer
class_name StatusCard

@export var title_text: String = "POSIÇÃO":
	set(val):
		title_text = val
		_update_ui()

@export var value_text: String = "1º":
	set(val):
		value_text = val
		_update_ui()

@export var trend_text: String = "+1":
	set(val):
		trend_text = val
		_update_ui()

@export var is_positive_trend: bool = true:
	set(val):
		is_positive_trend = val
		_update_ui()

@export var sub_text: String = "vs média":
	set(val):
		sub_text = val
		_update_ui()

@onready var label_node: Label = $VBox/Top/Label
@onready var value_node: Label = $VBox/Value
@onready var trend_label: Label = $VBox/Trend/TrendValue
@onready var sub_label: Label = $VBox/Trend/SubText

func _ready() -> void:
	# Only configure theme if we have access to it, avoiding errors in Editor without Autoloads loaded fully
	var style = StyleBoxFlat.new()
	if Engine.is_editor_hint():
		style.bg_color = Color("#0F0720")
		style.border_color = Color("#2D1B4E")
	else:
		style.bg_color = ThemeConfig.BG_SURFACE
		style.border_color = ThemeConfig.BORDER_DEFAULT
		
	style.corner_radius_top_left = 16; style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16; style.corner_radius_bottom_right = 16
	style.border_width_left = 1; style.border_width_top = 1; style.border_width_right = 1; style.border_width_bottom = 1
	style.content_margin_left = 16; style.content_margin_top = 16
	style.content_margin_right = 16; style.content_margin_bottom = 16
	add_theme_stylebox_override("panel", style)
	
	if label_node and not Engine.is_editor_hint():
		label_node.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		label_node.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	if value_node and not Engine.is_editor_hint():
		value_node.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	if trend_label and not Engine.is_editor_hint():
		trend_label.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	if sub_label and not Engine.is_editor_hint():
		sub_label.add_theme_font_override("font", ThemeConfig.FONT_INTER)
		
	_update_ui()

func _update_ui() -> void:
	if not is_inside_tree(): return
	if label_node: label_node.text = title_text.to_upper()
	if value_node: value_node.text = value_text
	if trend_label: 
		trend_label.text = trend_text
		if Engine.is_editor_hint():
			trend_label.add_theme_color_override("font_color", Color("#10B981") if is_positive_trend else Color("#EF4444"))
		else:
			trend_label.add_theme_color_override("font_color", ThemeConfig.SUCCESS if is_positive_trend else ThemeConfig.DANGER)
	if sub_label: sub_label.text = sub_text

# Keep compatibility with old dashboard script
func set_data(lbl: String, val: String, trd: String, up: bool, sub: String) -> void:
	title_text = lbl
	value_text = val
	trend_text = trd
	is_positive_trend = up
	sub_text = sub

func update_value(new_val: String) -> void:
	print("[UI DEBUG]: Atualizando StatusCard '", title_text, "' com valor: ", new_val)
	value_text = new_val
