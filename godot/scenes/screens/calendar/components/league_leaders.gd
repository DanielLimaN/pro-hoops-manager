extends PanelContainer
class_name LeagueLeaders

@onready var title_lbl = $Margin/VBox/Header/Title
@onready var list_container = $Margin/VBox/ListContainer

func _ready():
	var style = StyleBoxFlat.new()
	style.bg_color = ThemeConfig.BG_SURFACE
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12; style.corner_radius_bottom_right = 12
	style.border_color = ThemeConfig.BORDER_SUBTLE
	style.border_width_left = 1; style.border_width_top = 1; style.border_width_right = 1; style.border_width_bottom = 1
	add_theme_stylebox_override("panel", style)
	
	title_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	
	_populate()

func _populate():
	for c in list_container.get_children():
		c.queue_free()
		
	var leaders = [
		{"type": "PONTOS/JOGO", "name": "Marcus Silva", "team": "SP Phoenix", "val": "28.4", "color": ThemeConfig.BRAND_PRIMARY},
		{"type": "ASSISTÊNCIAS/JOGO", "name": "L. Henrique", "team": "Cangurus RJ", "val": "11.2", "color": ThemeConfig.INFO},
		{"type": "REBOTES/JOGO", "name": "K. Patterson", "team": "Jaguars BSB", "val": "14.6", "color": ThemeConfig.SUCCESS},
		{"type": "ROUBOS/JOGO", "name": "D. Santos", "team": "Trovões CWB", "val": "3.2", "color": ThemeConfig.WARNING}
	]
	
	for i in range(leaders.size()):
		var l = leaders[i]
		
		var row_container = PanelContainer.new()
		var r_style = StyleBoxFlat.new()
		r_style.bg_color = ThemeConfig.BG_SURFACE_ALT
		r_style.corner_radius_top_left = 8; r_style.corner_radius_top_right = 8
		r_style.corner_radius_bottom_left = 8; r_style.corner_radius_bottom_right = 8
		row_container.add_theme_stylebox_override("panel", r_style)
		
		var row_margin = MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 10)
		row_margin.add_theme_constant_override("margin_right", 10)
		row_margin.add_theme_constant_override("margin_top", 8)
		row_margin.add_theme_constant_override("margin_bottom", 8)
		row_container.add_child(row_margin)
		
		var row = HBoxContainer.new()
		row_margin.add_child(row)
		
		var icon = PanelContainer.new()
		icon.custom_minimum_size = Vector2(32, 32)
		var istyle = StyleBoxFlat.new()
		istyle.bg_color = l.color
		istyle.bg_color.a = 0.15 # 22 hex alpha approx
		istyle.corner_radius_top_left = 16; istyle.corner_radius_top_right = 16; istyle.corner_radius_bottom_left = 16; istyle.corner_radius_bottom_right = 16
		icon.add_theme_stylebox_override("panel", istyle)
		
		var ic = TextureRect.new()
		ic.texture = load("res://addons/at-icons/control/" + ["basketball", "signal", "arrow_down", "hand"][i] + ".svg")
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(16, 16)
		ic.modulate = l.color
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.add_child(ic)
		
		var m = MarginContainer.new()
		m.add_theme_constant_override("margin_left", 10)
		
		var vb = VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.add_theme_constant_override("separation", 0)
		var t = Label.new()
		t.text = l.type
		t.add_theme_font_size_override("font_size", 8)
		t.add_theme_color_override("font_color", ThemeConfig.TEXT_DISABLED)
		t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		
		var n = Label.new()
		n.text = l.name
		n.add_theme_font_size_override("font_size", 11)
		n.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		
		var tm = Label.new()
		tm.text = l.team
		tm.add_theme_font_size_override("font_size", 9)
		tm.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		
		vb.add_child(t)
		vb.add_child(n)
		vb.add_child(tm)
		m.add_child(vb)
		
		var v = Label.new()
		v.text = l.val
		v.add_theme_font_size_override("font_size", 16)
		v.add_theme_color_override("font_color", l.color)
		v.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
		
		row.add_child(icon)
		row.add_child(m)
		row.add_child(v)
		list_container.add_child(row_container)
