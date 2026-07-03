@tool
extends PanelContainer
class_name InboxItem

@export var event_type: String = "info":
	set(val):
		event_type = val
		_update_ui()

@export var title_text: String = "":
	set(val):
		title_text = val
		_update_ui()

@export var body_text: String = "":
	set(val):
		body_text = val
		_update_ui()

@export var severity: String = "info":
	set(val):
		severity = val
		_update_ui()

@export var sender_name: String = "":
	set(val):
		sender_name = val
		_update_ui()

@onready var icon_label: Label = $HBox/IconBox/IconLabel
@onready var title_label: Label = $HBox/TextCol/Title
@onready var body_label: Label = $HBox/TextCol/Body
@onready var tag_label: Label = $HBox/TagBox/TagLabel

func _ready():
	if Engine.is_editor_hint():
		return
	var style = StyleBoxFlat.new()
	style.bg_color = ThemeConfig.BG_SURFACE
	style.corner_radius_top_left = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_top_right = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = ThemeConfig.BORDER_SUBTLE
	add_theme_stylebox_override("panel", style)

	_update_ui()

func set_data(event: Dictionary):
	event_type = event.get("event_type", "info")
	title_text = event.get("title", "")
	body_text = event.get("body", "")
	severity = event.get("severity", "info")
	sender_name = event.get("sender_name", "")

func _update_ui():
	if not is_inside_tree():
		return

	var sev_color = ThemeConfig.INFO
	var sev_icon = "•"
	var sev_tag = "INFO"

	match event_type:
		"match_result":
			sev_color = ThemeConfig.SUCCESS if "Vitória" in title_text else ThemeConfig.DANGER
			sev_icon = "🏀"
			sev_tag = "JOGO"
		"injury":
			sev_color = ThemeConfig.DANGER
			sev_icon = "+"
			sev_tag = "LESÃO"
		"league_news":
			sev_color = ThemeConfig.WARNING
			sev_icon = "!"
			sev_tag = "NOTÍCIA"
		_:
			sev_color = ThemeConfig.INFO
			sev_icon = "•"
			sev_tag = "INFO"

	match severity:
		"critical":
			sev_color = ThemeConfig.DANGER
		"warning":
			sev_color = ThemeConfig.WARNING

	if icon_label:
		icon_label.text = sev_icon
		icon_label.add_theme_color_override("font_color", sev_color)
	if title_label:
		title_label.text = title_text
	if body_label:
		body_label.text = body_text
	if tag_label:
		tag_label.text = sev_tag
		tag_label.add_theme_color_override("font_color", sev_color)

	# Tag box border
	var tag_box = $HBox/TagBox
	if tag_box:
		var s = StyleBoxFlat.new()
		s.border_width_left = 1
		s.border_width_top = 1
		s.border_width_right = 1
		s.border_width_bottom = 1
		s.border_color = sev_color
		s.corner_radius_top_left = 4
		s.corner_radius_bottom_right = 4
		s.corner_radius_bottom_left = 4
		s.corner_radius_top_right = 4
		s.bg_color = Color(0, 0, 0, 0)
		tag_box.add_theme_stylebox_override("panel", s)
