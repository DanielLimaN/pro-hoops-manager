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
	_update_ui()

func _update_ui() -> void:
	if not is_inside_tree(): return
	if label_node: label_node.text = title_text.to_upper()
	if value_node: value_node.text = value_text
	if trend_label: 
		trend_label.text = trend_text
		trend_label.add_theme_color_override("font_color", Color("#10B981") if is_positive_trend else Color("#EF4444"))
	if sub_label: sub_label.text = sub_text

func set_data(lbl: String, val: String, trd: String, up: bool, sub: String) -> void:
	title_text = lbl
	value_text = val
	trend_text = trd
	is_positive_trend = up
	sub_text = sub

func update_value(new_val: String) -> void:
	value_text = new_val
