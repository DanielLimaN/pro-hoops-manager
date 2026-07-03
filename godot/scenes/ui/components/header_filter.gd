@tool
extends HBoxContainer
class_name HeaderFilter

@export var search_placeholder: String = "Buscar...":
	set(val):
		search_placeholder = val
		if has_node("%SearchEdit"):
			%SearchEdit.placeholder_text = val

@export var show_search: bool = true:
	set(val):
		show_search = val
		if has_node("%SearchPanel"):
			%SearchPanel.visible = val

@export var show_filter_btn: bool = true:
	set(val):
		show_filter_btn = val
		if has_node("%FilterBtn"):
			%FilterBtn.visible = val

@export var show_action_btn: bool = true:
	set(val):
		show_action_btn = val
		if has_node("%ActionBtn"):
			%ActionBtn.visible = val

@export var action_btn_text: String = "NOVO":
	set(val):
		action_btn_text = val
		if has_node("%ActionBtn"):
			%ActionBtn.text = val

@export var show_unread_badge: bool = false:
	set(val):
		show_unread_badge = val
		if has_node("%UnreadBadge"):
			%UnreadBadge.visible = val

@export var badge_text: String = "5 NÃO LIDAS":
	set(val):
		badge_text = val
		if has_node("%BadgeText"):
			%BadgeText.text = val

func _ready():
	_update_styles()
	search_placeholder = search_placeholder
	action_btn_text = action_btn_text
	show_search = show_search
	show_filter_btn = show_filter_btn
	show_action_btn = show_action_btn
	show_unread_badge = show_unread_badge
	badge_text = badge_text

func _update_styles():
	if not has_node("%SearchPanel"): return
	
	var ss = StyleBoxFlat.new()
	if Engine.is_editor_hint():
		ss.bg_color = Color("#150826")
		ss.border_color = Color("#2D1B4E")
	else:
		ss.bg_color = ThemeConfig.BG_ELEVATED
		ss.border_color = ThemeConfig.BORDER_DEFAULT
		
	ss.corner_radius_top_left=8; ss.corner_radius_bottom_right=8; ss.corner_radius_bottom_left=8; ss.corner_radius_top_right=8
	ss.border_width_left=1; ss.border_width_right=1; ss.border_width_top=1; ss.border_width_bottom=1
	%SearchPanel.add_theme_stylebox_override("panel", ss)
	
	if not Engine.is_editor_hint():
		%SearchEdit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		%SearchEdit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		%SearchIcon.modulate = ThemeConfig.TEXT_MUTED
	
	if has_node("%UnreadBadge") and not Engine.is_editor_hint():
		var bs = StyleBoxFlat.new()
		bs.bg_color = ThemeConfig.BRAND_PRIMARY
		bs.corner_radius_top_left = 6
		bs.corner_radius_bottom_right = 6
		bs.corner_radius_bottom_left = 6
		bs.corner_radius_top_right = 6
		%UnreadBadge.add_theme_stylebox_override("panel", bs)
		%BadgeIcon.modulate = Color.WHITE
		%BadgeText.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		%BadgeText.add_theme_font_size_override("font_size", 11)
		%BadgeText.add_theme_color_override("font_color", Color.WHITE)
