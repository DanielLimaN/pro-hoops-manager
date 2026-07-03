extends PanelContainer

signal simulate_requested

# We will store references to dynamically update them
var date_lbl: Label
var type_pill: Label
var home_circle_bg: PanelContainer
var home_abbr: Label
var home_name: Label
var home_record: Label
var away_circle_bg: PanelContainer
var away_abbr: Label
var away_name: Label
var away_record: Label
var ha_pill: Label
var prediction: Label

func _ready() -> void:
	for c in get_children():
		c.queue_free()
		
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color("#150826")
	p_style.corner_radius_top_left = 12; p_style.corner_radius_top_right = 12
	p_style.corner_radius_bottom_left = 12; p_style.corner_radius_bottom_right = 12
	p_style.border_color = ThemeConfig.BORDER_DEFAULT
	p_style.border_width_left = 1; p_style.border_width_top = 1; p_style.border_width_right = 1; p_style.border_width_bottom = 1
	add_theme_stylebox_override("panel", p_style)
	self.clip_contents = true
	
	var grad = Gradient.new()
	grad.set_color(0, Color("#261347")) # Lighter purple at top left
	grad.set_color(1, Color("#0F0720")) # Dark purple at bottom right
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(1, 1)
	
	var bg_grad = TextureRect.new()
	bg_grad.texture = tex
	bg_grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_grad)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)
	
	# TOP ROW
	var top_row = HBoxContainer.new()
	vbox.add_child(top_row)
	
	var title_box = HBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dot = ColorRect.new()
	dot.custom_minimum_size = Vector2(6, 6)
	dot.color = ThemeConfig.BRAND_PRIMARY
	# Simulate dot glow with a panel? A simple ColorRect works, maybe a StyleBoxFlat for rounded dot
	var dot_pnl = PanelContainer.new()
	var dot_style = StyleBoxFlat.new()
	dot_style.bg_color = ThemeConfig.BRAND_PRIMARY
	dot_style.corner_radius_top_left = 4; dot_style.corner_radius_bottom_right = 4; dot_style.corner_radius_top_right = 4; dot_style.corner_radius_bottom_left = 4
	dot_style.shadow_color = Color(ThemeConfig.BRAND_PRIMARY, 0.6)
	dot_style.shadow_size = 4
	dot_pnl.add_theme_stylebox_override("panel", dot_style)
	dot_pnl.custom_minimum_size = Vector2(8, 8)
	dot_pnl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_box.add_child(dot_pnl)
	
	var title_lbl = Label.new()
	title_lbl.text = "PRÓXIMO JOGO"
	title_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	title_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
	title_lbl.add_theme_constant_override("letter_spacing", 2)
	title_box.add_child(title_lbl)
	top_row.add_child(title_box)
	
	var right_top = HBoxContainer.new()
	right_top.add_theme_constant_override("separation", 12)
	date_lbl = Label.new()
	date_lbl.text = "SEX, 25 NOV • 20H30"
	date_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	date_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	date_lbl.add_theme_font_size_override("font_size", 12)
	date_lbl.add_theme_constant_override("letter_spacing", 1)
	right_top.add_child(date_lbl)
	
	type_pill = Label.new()
	type_pill.text = " LIGA "
	var tp_style = StyleBoxFlat.new()
	tp_style.bg_color = Color("#1E3A8A") # Dark blue
	tp_style.border_color = Color("#3B82F6") # Light blue border
	tp_style.border_width_left = 1; tp_style.border_width_top = 1; tp_style.border_width_right = 1; tp_style.border_width_bottom = 1
	tp_style.corner_radius_top_left = 4; tp_style.corner_radius_bottom_right = 4; tp_style.corner_radius_top_right = 4; tp_style.corner_radius_bottom_left = 4
	tp_style.content_margin_left = 6; tp_style.content_margin_right = 6
	type_pill.add_theme_stylebox_override("normal", tp_style)
	type_pill.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	type_pill.add_theme_font_size_override("font_size", 11)
	type_pill.add_theme_color_override("font_color", Color("#93C5FD"))
	right_top.add_child(type_pill)
	top_row.add_child(right_top)
	
	# CENTER MATCHUP
	var matchup_row = HBoxContainer.new()
	matchup_row.alignment = BoxContainer.ALIGNMENT_CENTER
	matchup_row.add_theme_constant_override("separation", 64)
	vbox.add_child(matchup_row)
	
	# Home Team Col
	var home_col = VBoxContainer.new()
	home_col.alignment = BoxContainer.ALIGNMENT_CENTER
	var hc_center = CenterContainer.new()
	home_circle_bg = PanelContainer.new()
	home_circle_bg.custom_minimum_size = Vector2(96, 96)
	var hc_style = StyleBoxFlat.new()
	hc_style.bg_color = ThemeConfig.BRAND_PRIMARY
	hc_style.corner_radius_top_left = 48; hc_style.corner_radius_bottom_right = 48; hc_style.corner_radius_top_right = 48; hc_style.corner_radius_bottom_left = 48
	hc_style.shadow_color = Color(ThemeConfig.BRAND_PRIMARY, 0.4)
	hc_style.shadow_size = 32
	hc_style.border_width_left = 2; hc_style.border_width_top = 2; hc_style.border_width_right = 2; hc_style.border_width_bottom = 2
	hc_style.border_color = Color(1,1,1,0.2)
	home_circle_bg.add_theme_stylebox_override("panel", hc_style)
	home_abbr = Label.new()
	home_abbr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home_abbr.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	home_abbr.add_theme_font_size_override("font_size", 24)
	home_abbr.add_theme_color_override("font_color", Color.WHITE)
	var hm_center = CenterContainer.new()
	hm_center.add_child(home_abbr)
	home_circle_bg.add_child(hm_center)
	hc_center.add_child(home_circle_bg)
	home_col.add_child(hc_center)
	
	home_name = Label.new()
	home_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home_name.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	home_name.add_theme_font_size_override("font_size", 16)
	home_name.add_theme_color_override("font_color", Color.WHITE)
	home_col.add_child(home_name)
	
	home_record = Label.new()
	home_record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home_record.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	home_record.add_theme_font_size_override("font_size", 12)
	home_record.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	home_col.add_child(home_record)
	matchup_row.add_child(home_col)
	
	# VS Col
	var vs_col = VBoxContainer.new()
	vs_col.alignment = BoxContainer.ALIGNMENT_CENTER
	vs_col.add_theme_constant_override("separation", 8)
	
	ha_pill = Label.new()
	ha_pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hap_style = StyleBoxFlat.new()
	hap_style.bg_color = ThemeConfig.BRAND_PRIMARY
	hap_style.corner_radius_top_left = 6; hap_style.corner_radius_bottom_right = 6; hap_style.corner_radius_top_right = 6; hap_style.corner_radius_bottom_left = 6
	hap_style.content_margin_left = 12; hap_style.content_margin_right = 12; hap_style.content_margin_top = 4; hap_style.content_margin_bottom = 4
	ha_pill.add_theme_stylebox_override("normal", hap_style)
	ha_pill.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	ha_pill.add_theme_font_size_override("font_size", 11)
	ha_pill.add_theme_color_override("font_color", Color("#06030E")) # Very dark text for contrast
	var hac = CenterContainer.new()
	hac.add_child(ha_pill)
	vs_col.add_child(hac)
	
	var vs_lbl = Label.new()
	vs_lbl.text = "VS"
	vs_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	vs_lbl.add_theme_font_size_override("font_size", 32)
	vs_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DISABLED) # Muted purple
	vs_col.add_child(vs_lbl)
	
	prediction = Label.new()
	prediction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prediction.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	prediction.add_theme_font_size_override("font_size", 12)
	prediction.add_theme_color_override("font_color", ThemeConfig.SUCCESS)
	vs_col.add_child(prediction)
	matchup_row.add_child(vs_col)
	
	# Away Team Col
	var away_col = VBoxContainer.new()
	away_col.alignment = BoxContainer.ALIGNMENT_CENTER
	var ac_center = CenterContainer.new()
	away_circle_bg = PanelContainer.new()
	away_circle_bg.custom_minimum_size = Vector2(96, 96)
	var ac_style = StyleBoxFlat.new()
	ac_style.bg_color = ThemeConfig.DANGER
	ac_style.corner_radius_top_left = 48; ac_style.corner_radius_bottom_right = 48; ac_style.corner_radius_top_right = 48; ac_style.corner_radius_bottom_left = 48
	ac_style.border_width_left = 4; ac_style.border_width_top = 4; ac_style.border_width_right = 4; ac_style.border_width_bottom = 4
	ac_style.border_color = Color("#7F1D1D") # Darker red border (inner shadow simulation)
	away_circle_bg.add_theme_stylebox_override("panel", ac_style)
	away_abbr = Label.new()
	away_abbr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	away_abbr.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	away_abbr.add_theme_font_size_override("font_size", 24)
	away_abbr.add_theme_color_override("font_color", Color.WHITE)
	var am_center = CenterContainer.new()
	am_center.add_child(away_abbr)
	away_circle_bg.add_child(am_center)
	ac_center.add_child(away_circle_bg)
	away_col.add_child(ac_center)
	
	away_name = Label.new()
	away_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	away_name.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	away_name.add_theme_font_size_override("font_size", 16)
	away_name.add_theme_color_override("font_color", Color.WHITE)
	away_col.add_child(away_name)
	
	away_record = Label.new()
	away_record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	away_record.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	away_record.add_theme_font_size_override("font_size", 12)
	away_record.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	away_col.add_child(away_record)
	matchup_row.add_child(away_col)
	
	# BOTTOM ROW BUTTONS
	var bot_row = HBoxContainer.new()
	bot_row.add_theme_constant_override("separation", 16)
	bot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(bot_row)
	
	var btn1 = _create_action_btn("DEFINIR ESCALAÇÃO", "clipboard", false)
	var btn2 = _create_action_btn("ANALISAR ADVERSÁRIO", "magnifying_glass", false)
	var btn3 = _create_action_btn("ASSISTIR SIMULAÇÃO", "play", true)
	btn1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_row.add_child(btn1)
	bot_row.add_child(btn2)
	bot_row.add_child(btn3)
	
	btn3.pressed.connect(func(): emit_signal("simulate_requested"))

func _create_action_btn(txt: String, icon_name: String, is_primary: bool) -> Button:
	var btn = Button.new()
	btn.text = " " + txt
	
	var path = "res://addons/at-icons/control/" + icon_name + ".svg"
	if ResourceLoader.exists(path):
		btn.icon = load(path)
	btn.expand_icon = true
	btn.add_theme_constant_override("icon_max_width", 16)
	
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8; style.corner_radius_bottom_right = 8; style.corner_radius_top_right = 8; style.corner_radius_bottom_left = 8
	style.content_margin_left = 16; style.content_margin_right = 16; style.content_margin_top = 16; style.content_margin_bottom = 16
	
	if is_primary:
		style.bg_color = ThemeConfig.BRAND_DEEP
		style.border_width_left = 0
		btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		style.bg_color = Color(0,0,0,0) # transparent
		style.border_color = ThemeConfig.BORDER_DEFAULT
		style.border_width_left = 1; style.border_width_top = 1; style.border_width_right = 1; style.border_width_bottom = 1
		btn.add_theme_color_override("font_color", Color.WHITE)
		
	var hover = style.duplicate()
	if is_primary:
		hover.bg_color = ThemeConfig.BRAND_PRIMARY
	else:
		hover.bg_color = ThemeConfig.BG_ELEVATED
		
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", style)
	btn.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	
	return btn

func setup(data: Dictionary) -> void:
	var day = data.get("day", 1)
	var month = data.get("month", 1)
	var hour = data.get("hour", 20)
	var min = data.get("minute", 0)
	var months = ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]
	date_lbl.text = "%d %s • %dh%02d" % [day, months[month - 1], hour, min]

	var user_team = GameManager.user_team_id
	var home_id = data.get("home_team_id", 0)
	var away_id = data.get("away_team_id", 0)
	var is_home = home_id == user_team
	ha_pill.text = " CASA " if is_home else " FORA "

	var league_teams = GameManager.league.teams
	var ht = _find_team(league_teams, home_id)
	var at = _find_team(league_teams, away_id)

	home_abbr.text = ht.abbreviation if ht else "H"
	away_abbr.text = at.abbreviation if at else "A"
	home_name.text = ht.name.to_upper() if ht else "HOME"
	away_name.text = at.name.to_upper() if at else "AWAY"
	home_record.text = str(ht.wins) + "V - " + str(ht.losses) + "D" + (" • " + str(ht.id) + "º LUGAR" if false else "")
	away_record.text = str(at.wins) + "V - " + str(at.losses) + "D" + (" • " + str(at.id) + "º LUGAR" if false else "")

	prediction.text = "Previsão: 58% V"

func _find_team(teams: Array, id: int) -> Dictionary:
	for t in teams:
		if t.id == id: return t
	return {}
