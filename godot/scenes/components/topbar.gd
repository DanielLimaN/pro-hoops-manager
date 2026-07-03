extends PanelContainer

signal advance_requested

@export var screen_title: String = "Título da Tela"

var val_budget: Label
var val_morale: Label
var val_energy: Label

@onready var sub_lbl = %Sub
@onready var title_lbl = %Title
@onready var right_container = %TbR

func _ready():
	var tb_style = StyleBoxFlat.new()
	tb_style.bg_color = ThemeConfig.BG_APP
	tb_style.border_color = ThemeConfig.BORDER_SUBTLE
	tb_style.border_width_bottom = 1
	add_theme_stylebox_override("panel", tb_style)
	
	sub_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	sub_lbl.add_theme_font_size_override("font_size", 10)
	sub_lbl.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
	
	title_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.text = screen_title

	EventBus.date_updated.connect(_on_date_updated)
	_update_from_league()
	
	var kpis = [
		{"id": "budget", "icon": "coins", "l": "ORÇAMENTO", "v": "R$ 12.4M", "c": ThemeConfig.SUCCESS},
		{"id": "morale", "icon": "smiley_face", "l": "MORAL", "v": "87%", "c": ThemeConfig.WARNING},
		{"id": "energy", "icon": "lightning_bolt", "l": "ENERGIA", "v": "92%", "c": ThemeConfig.INFO}
	]
	
	for k in kpis:
		var kp = PanelContainer.new()
		var s = StyleBoxFlat.new()
		s.bg_color = ThemeConfig.BG_SURFACE_ALT
		s.border_color = ThemeConfig.BORDER_SUBTLE
		s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1
		s.corner_radius_top_left=8; s.corner_radius_top_right=8; s.corner_radius_bottom_left=8; s.corner_radius_bottom_right=8
		kp.add_theme_stylebox_override("panel", s)
		
		var m = MarginContainer.new()
		m.add_theme_constant_override("margin_left", 12)
		m.add_theme_constant_override("margin_right", 12)
		m.add_theme_constant_override("margin_top", 8)
		m.add_theme_constant_override("margin_bottom", 8)
		kp.add_child(m)
		
		var h = HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		
		var i = TextureRect.new()
		i.texture = load("res://addons/at-icons/control/" + k.icon + ".svg")
		i.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		i.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		i.custom_minimum_size = Vector2(16, 16)
		i.modulate = k.c
		i.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		var vb = VBoxContainer.new()
		vb.add_theme_constant_override("separation", -2)
		
		var lbl = Label.new()
		lbl.text = k.l
		lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		
		var val = Label.new()
		val.text = k.v
		val.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
		val.add_theme_font_size_override("font_size", 12)
		
		if k.id == "budget": val_budget = val
		elif k.id == "morale": val_morale = val
		elif k.id == "energy": val_energy = val
		
		vb.add_child(lbl)
		vb.add_child(val)
		h.add_child(i)
		h.add_child(vb)
		m.add_child(h)
		right_container.add_child(kp)
		
	var bell = preload("res://scenes/ui/components/icon_button.tscn").instantiate()
	bell.icon = load("res://addons/at-icons/control/bell.svg")
	bell.expand_icon = true
	bell.add_theme_constant_override("icon_max_width", 20)
	bell.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_container.add_child(bell)
	
	var av = preload("res://scenes/ui/components/primary_button.tscn").instantiate()
	av.text = "AVANÇAR"
	av.icon = load("res://addons/at-icons/control/play.svg")
	av.expand_icon = true
	av.custom_minimum_size = Vector2(140, 48)
	av.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	av.alignment = HORIZONTAL_ALIGNMENT_CENTER
	av.add_theme_constant_override("icon_max_width", 16)
	av.add_theme_constant_override("h_separation", 8)
	av.pressed.connect(func(): EventBus.advance_simulation_requested.emit({}))
	right_container.add_child(av)

func _on_date_updated(data: Dictionary):
	if data.is_empty():
		sub_lbl.text = "CARREGANDO..."
		return
	var year = data.get("year", 2025)
	var date_str = data.get("date_string", "")
	sub_lbl.text = "TEMPORADA %d — %s" % [year, date_str]

func _update_from_league():
	if GameManager.league.is_empty():
		sub_lbl.text = "CARREGANDO..."
		return
	var current_event = EventManager.get_current_event()
	if current_event.is_empty():
		sub_lbl.text = "SEM PARTIDAS AGENDADAS"
		return
	var season = current_event.get("year", 2025)
	var month = current_event.get("month", 1)
	var day = current_event.get("day", 1)
	var months = ["JANEIRO", "FEVEREIRO", "MARÇO", "ABRIL", "MAIO", "JUNHO", "JULHO", "AGOSTO", "SETEMBRO", "OUTUBRO", "NOVEMBRO", "DEZEMBRO"]
	var date_string = "%d DE %s" % [day, months[month - 1]]
	var data = {"year": season, "date_string": date_string}
	_on_date_updated(data)
