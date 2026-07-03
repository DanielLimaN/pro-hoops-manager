@tool
extends PanelContainer
class_name PlayerRow

@export var is_selected: bool = false:
	set(val):
		is_selected = val
		_update_styles()

@export var player_data: Dictionary = {}:
	set(val):
		player_data = val
		_update_data()

func _ready():
	_update_styles()
	if player_data.size() > 0:
		_update_data()
	elif Engine.is_editor_hint():
		player_data = {"pos": "PG", "in": "MS", "n": "Marcus Silva", "sub": "The Maestro", "i": 28, "ovr": 92, "en": 88, "ct": "2 anos", "sal": "R$ 2.4M", "st": "ATIVO"}
		_update_data()

func _update_styles():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0,0,0,0)
	
	if Engine.is_editor_hint():
		style.border_color = Color("#2D1B4E")
	else:
		style.border_color = ThemeConfig.BORDER_SUBTLE
		
	style.border_width_bottom = 1
	
	if is_selected:
		if not Engine.is_editor_hint():
			style.border_color = ThemeConfig.BRAND_PRIMARY
		else:
			style.border_color = Color("#A78BFA")
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		$Gradient.show()
	else:
		$Gradient.hide()
		
	add_theme_stylebox_override("panel", style)

func _update_data():
	if not is_inside_tree() or player_data.is_empty(): return
	
	%PosBadge.badge_type = "pos"
	%PosBadge.value = player_data.get("pos", "PG")
	
	%Initials.text = player_data.get("in", "XX")
	%NameLbl.text = player_data.get("n", "Player Name")
	%SubLbl.text = player_data.get("sub", "")
	%AgeLbl.text = str(player_data.get("i", 0))
	
	%OvrBadge.badge_type = "ovr"
	%OvrBadge.value = str(player_data.get("ovr", 0))
	
	var en = player_data.get("en", 100)
	%EnergyFill.custom_minimum_size.x = 60 * (en / 100.0)
	%EnergyLbl.text = str(en) + "%"
	
	if not Engine.is_editor_hint():
		var pcol = ThemeConfig.BRAND_PRIMARY if "G" in player_data.get("pos", "PG") else (ThemeConfig.SUCCESS if "F" in player_data.get("pos", "PG") else ThemeConfig.WARNING)
		if player_data.get("pos", "PG") == "C": pcol = ThemeConfig.DANGER
		if is_selected:
			%AvatarPanel.get_theme_stylebox("panel").bg_color = ThemeConfig.BRAND_PRIMARY
		else:
			%AvatarPanel.get_theme_stylebox("panel").bg_color = pcol
			
		%EnergyFill.color = ThemeConfig.SUCCESS if en > 60 else (ThemeConfig.WARNING if en > 40 else ThemeConfig.DANGER)
		
		# Stars
		var ovr = player_data.get("ovr", 0)
		var star_count = 1 if player_data.get("st", "") == "LESIONADO" else 3
		if ovr >= 90: star_count = 5
		elif ovr >= 85: star_count = 4
		var i = 0
		for star in %Stars.get_children():
			star.modulate = ThemeConfig.WARNING if i < star_count else ThemeConfig.BORDER_SUBTLE
			i += 1
			
		%ContractLbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		%SalaryLbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		%NameLbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		%SubLbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		%AgeLbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	
	%ContractLbl.text = player_data.get("ct", "")
	if player_data.get("ct", "") == "0.5 ano" and not Engine.is_editor_hint():
		%ContractLbl.add_theme_color_override("font_color", ThemeConfig.WARNING)
	else:
		%ContractLbl.remove_theme_color_override("font_color")
		
	%SalaryLbl.text = player_data.get("sal", "")
	
	%StatusBadge.badge_type = "status"
	%StatusBadge.value = player_data.get("st", "ATIVO")
