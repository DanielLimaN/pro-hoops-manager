extends Control

# ENGINE CONNECTED - Strategy internal state
var _pace: int = 1  # 0=LENTO, 1=MÉDIO, 2=RÁPIDO
var _offensive_focus: int = 0  # 0=PERÍMETRO, 1=GARRAFÃO, 2=BALANCEADO
var _defensive_focus: int = 0  # 0=INDIVIDUAL, 1=ZONA 2-3, 2=PRESSÃO
var _aggressiveness: int = 1  # 0=PASSIVO, 1=EQUILIBRADO, 2=AGRESSIVO

# ENGINE CONNECTED - Cached data from engine
var _team_data: Dictionary = {}
var _opponent_data: Dictionary = {}
var _starting_five: Array = []
var _opponent_abbr: String = "???"
var _next_match: Dictionary = {}
var _has_data: bool = false

# Position court positions (meter-based coordinates)
const POS_POSITIONS: Dictionary = {
	"PG": Vector2(0.0, 9.5),    # top of the key, above 3pt arc
	"SG": Vector2(-5.0, 8.5),   # left wing at 3pt line
	"SF": Vector2(5.0, 8.5),    # right wing at 3pt line
	"PF": Vector2(-2.5, 5.5),   # left elbow / mid-post
	"C": Vector2(1.5, 3.5),     # low post / dunker spot
}

const COURT_WIDTH_M: float = 15.24
const COURT_VISUAL_HALF: float = 15.525

func _ready():
	# ENGINE CONNECTED
	_fetch_data()
	
	for c in get_children():
		c.queue_free()
		
	var bg = ColorRect.new()
	bg.color = ThemeConfig.BG_APP
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.theme_type_variation = "ScreenMargin"
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.theme_type_variation = "ScreenVBox"
	margin.add_child(vbox)
	
	_build_top_bar(vbox)
	_build_tabs(vbox)
	_build_kpis(vbox)
	
	var content = HBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 24)
	vbox.add_child(content)
	
	_build_left_col(content)
	_build_center_col(content)
	_build_right_col(content)
	
	_reposition_players.call_deferred()


# ═══════════════════════════════════════════════════════════════
# ENGINE CONNECTED - Data fetching
# ═══════════════════════════════════════════════════════════════

func _fetch_data() -> void:
	# Fetch user team
	_team_data = GameManager.get_user_team()
	_has_data = not _team_data.is_empty()
	
	if _has_data:
		var players: Array = _team_data.get("players", [])
		_starting_five = _get_starting_five(players)
	
	# Fetch next match and opponent
	_next_match = EventManager.get_next_match()
	if not _next_match.is_empty():
		var user_id: int = GameManager.user_team_id
		var is_home: bool = _next_match.get("home_team_id", 0) == user_id
		var opp_id: int = _next_match.get("away_team_id", 0) if is_home else _next_match.get("home_team_id", 0)
		_opponent_data = GameManager.get_team(opp_id)
		
		if not _opponent_data.is_empty():
			_opponent_abbr = _opponent_data.get("abbreviation", "???")
		else:
			# Fallback: find abbreviation from league teams
			for t in GameManager.league.get("teams", []):
				if t.get("id") == opp_id:
					_opponent_abbr = t.get("abbreviation", "???")
					break
			if _opponent_abbr == "???":
				_opponent_abbr = "TIME"


# ═══════════════════════════════════════════════════════════════
# ENGINE CONNECTED - Starting Five Selection
# ═══════════════════════════════════════════════════════════════

func _get_starting_five(players: Array) -> Array:
	if players.is_empty():
		return []
	
	var positions: Array = ["PG", "SG", "SF", "PF", "C"]
	var by_pos: Dictionary = {}
	for pos in positions:
		by_pos[pos] = []
	
	for p in players:
		var pos: String = p.get("position", "")
		if by_pos.has(pos):
			by_pos[pos].append(p)
	
	# Sort each position group by overall descending
	for pos in positions:
		by_pos[pos].sort_custom(func(a, b): return a.get("overall", 0) > b.get("overall", 0))
	
	var result: Array = []
	for pos in positions:
		var group: Array = by_pos.get(pos, [])
		if not group.is_empty():
			result.append(group[0])
	
	return result


# ═══════════════════════════════════════════════════════════════
# ENGINE CONNECTED - KPI Calculations
# ═══════════════════════════════════════════════════════════════

func _calc_attack_rating(players: Array) -> int:
	if players.is_empty():
		return 0
	var total: float = 0.0
	var weight_sum: float = 0.0
	for p in players:
		var pos: String = p.get("position", "")
		var ovr: float = p.get("overall", 50)
		# PG, SG, SF weigh more for offensive rating
		var weight: float = 1.2 if pos in ["PG", "SG", "SF"] else 0.8
		total += ovr * weight
		weight_sum += weight
	if weight_sum == 0:
		return 0
	return clampi(int(total / weight_sum), 0, 99)

func _calc_defense_rating(players: Array) -> int:
	if players.is_empty():
		return 0
	var total: float = 0.0
	for p in players:
		var attrs: Dictionary = p.get("attributes", {})
		var d: float = attrs.get("defense", attrs.get("perimeter_def", 50))
		var s: float = attrs.get("steals", attrs.get("steal", 50))
		var b: float = attrs.get("blocks", attrs.get("block", 50))
		total += (d + s + b) / 3.0
	return clampi(int(total / players.size()), 0, 99)

func _calc_chemistry_rating(players: Array) -> int:
	if players.is_empty():
		return 0
	var total: float = 0.0
	for p in players:
		total += p.get("morale", 50)
	return clampi(int(total / players.size()), 0, 99)

func _calc_advantage() -> int:
	var user_players: Array = _team_data.get("players", [])
	var opp_players: Array = _opponent_data.get("players", [])
	if user_players.is_empty() or opp_players.is_empty():
		return 0
	var user_avg: float = _avg_overall(user_players)
	var opp_avg: float = _avg_overall(opp_players)
	return int(user_avg - opp_avg)

func _avg_overall(players: Array) -> float:
	if players.is_empty():
		return 0.0
	var total: float = 0.0
	for p in players:
		total += p.get("overall", 50)
	return total / players.size()

func _calc_minutes(ovr: int) -> int:
	if ovr >= 90:
		return 36
	elif ovr >= 85:
		return 32
	elif ovr >= 80:
		return 28
	else:
		return 24

func _get_initials(p: Dictionary) -> String:
	var first: String = p.get("first_name", "")
	var last: String = p.get("last_name", "")
	if not first.is_empty() and not last.is_empty():
		return first.substr(0, 1).to_upper() + last.substr(0, 1).to_upper()
	elif not first.is_empty():
		return first.substr(0, 2).to_upper()
	return "XX"

func _format_salary(val) -> String:
	var v: float = float(val) if val else 0.0
	if v >= 1000000:
		return "R$ " + str(round(v / 100000) / 10.0) + "M"
	elif v >= 1000:
		return "R$ " + str(round(v / 1000)) + "K"
	return "R$ " + str(v)

func _get_pos_color(pos: String) -> Color:
	match pos:
		"PG": return ThemeConfig.BRAND_PRIMARY
		"SG": return Color("#3B82F6")
		"SF": return ThemeConfig.SUCCESS
		"PF": return ThemeConfig.WARNING
		"C": return ThemeConfig.DANGER
	return ThemeConfig.BRAND_PRIMARY

func _get_team_avg_attr(players: Array, primary: String, fallback: String) -> float:
	if players.is_empty():
		return 50.0
	var total: float = 0.0
	for p in players:
		var attrs: Dictionary = p.get("attributes", {})
		total += attrs.get(primary, attrs.get(fallback, 50))
	return total / players.size()


# ═══════════════════════════════════════════════════════════════
# UI Builders (unchanged structure, dynamic data)
# ═══════════════════════════════════════════════════════════════

func _build_top_bar(parent: Node):
	var topbar_scene = preload("res://scenes/components/topbar.tscn")
	var tb = topbar_scene.instantiate()
	tb.screen_title = "TÁTICA"
	parent.add_child(tb)

func _create_kpi_badge(title: String, val: String, color: Color, icon: String) -> PanelContainer:
	var p = PanelContainer.new()
	var s = StyleBoxFlat.new(); s.bg_color = Color(0,0,0,0); s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = ThemeConfig.BORDER_SUBTLE; s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8
	p.add_theme_stylebox_override("panel", s)
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 12)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 16); m.add_theme_constant_override("margin_right", 16); m.add_theme_constant_override("margin_top", 8); m.add_theme_constant_override("margin_bottom", 8); m.add_child(h); p.add_child(m)
	var l_icon = Label.new(); l_icon.text = icon; l_icon.add_theme_color_override("font_color", color); l_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; h.add_child(l_icon)
	var vb = VBoxContainer.new(); vb.alignment = BoxContainer.ALIGNMENT_CENTER
	var l_title = Label.new(); l_title.text = title; l_title.add_theme_font_size_override("font_size", 8); l_title.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); l_title.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); vb.add_child(l_title)
	var l_val = Label.new(); l_val.text = val; l_val.add_theme_font_size_override("font_size", 14); l_val.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); vb.add_child(l_val)
	h.add_child(vb)
	return p

func _build_tabs(parent: Node):
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 32)
	
	var tabs = ["ESCALAÇÃO", "ESQUEMA OFENSIVO", "ESQUEMA DEFENSIVO", "JOGADAS ENSAIADAS"]
	var tab_box = HBoxContainer.new()
	tab_box.add_theme_constant_override("separation", 8)
	for i in range(tabs.size()):
		var b = Button.new()
		b.text = tabs[i]
		b.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		b.add_theme_font_size_override("font_size", 12)
		var s = StyleBoxFlat.new(); s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8; s.content_margin_left=16; s.content_margin_right=16; s.content_margin_top=8; s.content_margin_bottom=8
		b.add_theme_constant_override("h_separation", 8)
		if i == 0:
			b.icon = load("res://addons/at-icons/control/clipboard.svg")
			s.bg_color = ThemeConfig.BRAND_PRIMARY; s.border_width_bottom=0
			b.add_theme_color_override("font_color", Color.WHITE)
			b.add_theme_color_override("icon_normal_color", Color.WHITE)
			b.add_theme_color_override("icon_hover_color", Color.WHITE)
			b.add_theme_color_override("icon_focus_color", Color.WHITE)
		else:
			if i == 1: b.icon = load("res://addons/at-icons/control/cross.svg")
			elif i == 2: b.icon = load("res://addons/at-icons/control/shield.svg")
			elif i == 3: b.icon = load("res://addons/at-icons/control/arrows_clockwise.svg")
			s.bg_color = Color(0,0,0,0); s.border_width_bottom=0
			b.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
			b.add_theme_color_override("icon_normal_color", ThemeConfig.TEXT_MUTED)
			b.add_theme_color_override("icon_hover_color", ThemeConfig.TEXT_MUTED)
			b.add_theme_color_override("icon_focus_color", ThemeConfig.TEXT_MUTED)
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", s)
		tab_box.add_child(b)
	
	h.add_child(tab_box)
	
	var space = Control.new(); space.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(space)
	
	var presets = HBoxContainer.new(); presets.add_theme_constant_override("separation", 16)
	
	var btn_preset = Button.new(); btn_preset.text = "PRESET: 'CORRE-CORRE'"; btn_preset.icon = load("res://addons/at-icons/control/bookmark.svg"); btn_preset.add_theme_constant_override("h_separation", 8); btn_preset.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); btn_preset.add_theme_font_size_override("font_size", 12)
	var s_pre = StyleBoxFlat.new(); s_pre.bg_color = Color(0,0,0,0); s_pre.border_width_left=1; s_pre.border_width_right=1; s_pre.border_width_top=1; s_pre.border_width_bottom=1; s_pre.border_color = ThemeConfig.BORDER_SUBTLE; s_pre.corner_radius_top_left=8; s_pre.corner_radius_bottom_right=8; s_pre.corner_radius_bottom_left=8; s_pre.corner_radius_top_right=8; s_pre.content_margin_left=16; s_pre.content_margin_right=16
	btn_preset.add_theme_stylebox_override("normal", s_pre)
	btn_preset.pressed.connect(func():
		_pace = 2
		_offensive_focus = 0
		_defensive_focus = 0
		_aggressiveness = 2
		_update_btn_group_visual("_pace", 2)
		_update_btn_group_visual("_offensive_focus", 0)
		_update_btn_group_visual("_defensive_focus", 0)
		_update_btn_group_visual("_aggressiveness", 2)
		_apply_tactic_to_engine()
	)
	presets.add_child(btn_preset)
	
	var btn_reset = Button.new(); btn_reset.text = "RESETAR"; btn_reset.icon = load("res://addons/at-icons/control/arrow_counterclockwise.svg"); btn_reset.add_theme_constant_override("h_separation", 8); btn_reset.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); btn_reset.add_theme_font_size_override("font_size", 12)
	var s_res = StyleBoxFlat.new(); s_res.bg_color = Color(0,0,0,0); s_res.border_width_left=1; s_res.border_width_right=1; s_res.border_width_top=1; s_res.border_width_bottom=1; s_res.border_color = ThemeConfig.BORDER_SUBTLE; s_res.corner_radius_top_left=8; s_res.corner_radius_bottom_right=8; s_res.corner_radius_bottom_left=8; s_res.corner_radius_top_right=8; s_res.content_margin_left=16; s_res.content_margin_right=16
	btn_reset.add_theme_stylebox_override("normal", s_res)
	btn_reset.pressed.connect(func():
		_pace = 1
		_offensive_focus = 0
		_defensive_focus = 0
		_aggressiveness = 1
		_update_btn_group_visual("_pace", 1)
		_update_btn_group_visual("_offensive_focus", 0)
		_update_btn_group_visual("_defensive_focus", 0)
		_update_btn_group_visual("_aggressiveness", 1)
		_apply_tactic_to_engine()
	)
	presets.add_child(btn_reset)
	
	h.add_child(presets)
	parent.add_child(h)

# ENGINE CONNECTED - KPI cards now use real team data
func _build_kpis(parent: Node):
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	
	var players: Array = _team_data.get("players", []) if _has_data else []
	
	var attack_val: int = _calc_attack_rating(players)
	var defense_val: int = _calc_defense_rating(players)
	var chemistry_val: int = _calc_chemistry_rating(players)
	var advantage_val: int = _calc_advantage()
	
	h.add_child(_create_stat_card("ATAQUE", attack_val, ThemeConfig.BRAND_PRIMARY, "cross"))
	h.add_child(_create_stat_card("DEFESA", defense_val, Color("#3B82F6"), "shield"))
	h.add_child(_create_stat_card("QUÍMICA", chemistry_val, ThemeConfig.DANGER, "beaker"))
	h.add_child(_create_stat_card("VANTAGEM vs " + _opponent_abbr, advantage_val, ThemeConfig.SUCCESS, "arrow_up_right", true))
	
	parent.add_child(h)

func _create_stat_card(title: String, val: int, color: Color, icon: String, is_diff: bool = false) -> PanelContainer:
	var p = PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s = StyleBoxFlat.new(); s.bg_color = ThemeConfig.BG_SURFACE; s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8
	s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = ThemeConfig.BORDER_SUBTLE
	p.add_theme_stylebox_override("panel", s)
	
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 16); m.add_theme_constant_override("margin_right", 16); m.add_theme_constant_override("margin_top", 12); m.add_theme_constant_override("margin_bottom", 12); p.add_child(m)
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", 8); m.add_child(v)
	
	var htop = HBoxContainer.new(); htop.add_theme_constant_override("separation", 12)
	var ic = PanelContainer.new(); ic.custom_minimum_size = Vector2(32, 32)
	var sic = StyleBoxFlat.new(); sic.bg_color = Color(color.r, color.g, color.b, 0.1); sic.corner_radius_top_left=8; sic.corner_radius_bottom_right=8; sic.corner_radius_bottom_left=8; sic.corner_radius_top_right=8; ic.add_theme_stylebox_override("panel", sic)
	var lic = TextureRect.new()
	lic.texture = load("res://addons/at-icons/control/" + icon + ".svg")
	lic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lic.custom_minimum_size = Vector2(16, 16)
	lic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lic.modulate = color
	lic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.add_child(lic); htop.add_child(ic)
	
	var vtext = VBoxContainer.new(); vtext.alignment = BoxContainer.ALIGNMENT_CENTER
	var t = Label.new(); t.text = title; t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_font_size_override("font_size", 10); t.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); vtext.add_child(t)
	
	var th2 = HBoxContainer.new()
	var vl = Label.new(); vl.text = "+" + str(val) if is_diff else str(val); vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); vl.add_theme_font_size_override("font_size", 20); th2.add_child(vl)
	var suf = Label.new(); suf.text = " pts" if is_diff else " /100"; suf.add_theme_font_size_override("font_size", 10); suf.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); suf.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM; th2.add_child(suf)
	vtext.add_child(th2)
	htop.add_child(vtext)
	v.add_child(htop)
	
	var bar = ColorRect.new(); bar.custom_minimum_size = Vector2(0, 4); bar.color = ThemeConfig.BG_ELEVATED
	var bfill = TextureRect.new(); bfill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bfill.custom_minimum_size = Vector2(0, 4); bfill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var g2 = GradientTexture2D.new(); var g = Gradient.new()
	g.set_color(0, Color(color.r, color.g, color.b, 0.3)); g.set_color(1, color)
	g2.gradient = g; g2.fill_from = Vector2(0,0); g2.fill_to = Vector2(1,0)
	bfill.texture = g2
	# Mock width
	var bar_fill = Control.new()
	bar_fill.custom_minimum_size = Vector2(200 if not is_diff else 120, 4)
	bar_fill.add_child(bfill)
	bar.add_child(bar_fill)
	
	v.add_child(bar)
	return p

# ENGINE CONNECTED - Strategy buttons now connected to internal state
func _build_left_col(parent: Node):
	var p = preload("res://scenes/ui/components/container_base.tscn").instantiate()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL; p.size_flags_vertical = Control.SIZE_EXPAND_FILL; p.size_flags_stretch_ratio = 1.0
	var bg_grad = TextureRect.new(); var g2d = GradientTexture2D.new(); var g = Gradient.new(); g.set_color(0, Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.15)); g.set_color(1, Color(0,0,0,0)); g2d.gradient = g; g2d.fill_from = Vector2(0.5, 0); g2d.fill_to = Vector2(0.5, 0.6); bg_grad.texture = g2d; bg_grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg_grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); p.add_child(bg_grad)
	
	var scroll = ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var m = MarginContainer.new(); m.size_flags_horizontal = Control.SIZE_EXPAND_FILL; m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24); m.add_theme_constant_override("margin_top", 24); m.add_theme_constant_override("margin_bottom", 24)
	var vb = VBoxContainer.new(); vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vb.add_theme_constant_override("separation", 24)
	
	var hl = Label.new(); hl.text = "ESTRATÉGIA GERAL"; hl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); hl.add_theme_font_size_override("font_size", 10); hl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hl.add_theme_constant_override("letter_spacing", 1)
	var hbox = HBoxContainer.new(); hbox.add_theme_constant_override("separation", 8)
	var icon = TextureRect.new(); icon.texture = load("res://addons/at-icons/control/sliders.svg"); icon.custom_minimum_size = Vector2(14, 14); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.modulate = ThemeConfig.TEXT_MUTED; hbox.add_child(icon); hbox.add_child(hl); vb.add_child(hbox)
	
	vb.add_child(_create_btn_group("RITMO DE JOGO", ["LENTO", "MÉDIO", "RÁPIDO"], _pace, ["play", "fast_forward", "lightning_bolt"], "_pace"))
	vb.add_child(_create_btn_group("FOCO OFENSIVO", ["PERÍMETRO", "GARRAFÃO", "BALANCEADO"], _offensive_focus, ["target", "cube", "balance"], "_offensive_focus"))
	vb.add_child(_create_btn_group("FOCO DEFENSIVO", ["INDIVIDUAL", "ZONA 2-3", "PRESSÃO"], _defensive_focus, ["human", "grid_fine", "shield"], "_defensive_focus"))
	vb.add_child(_create_btn_group("AGRESSIVIDADE", ["PASSIVO", "EQUILIBRADO", "AGRESSIVO"], _aggressiveness, ["shield", "scales", "fire"], "_aggressiveness"))
	
	var sep = HSeparator.new(); vb.add_child(sep)
	
	vb.add_child(_create_slider_row("INTENSIDADE 3PT", 70, ThemeConfig.BRAND_PRIMARY))
	vb.add_child(_create_slider_row("GARRAFÃO", 30, Color("#3B82F6")))
	vb.add_child(_create_slider_row("ROTAÇÃO RESERVAS", 55, ThemeConfig.SUCCESS))
	
	m.add_child(vb); scroll.add_child(m); p.add_child(scroll); parent.add_child(p)

# ENGINE CONNECTED - Button group with pressed connections and visual updates
func _create_btn_group(title: String, opts: Array, active_idx: int, icons: Array, var_name: String = "") -> VBoxContainer:
	var vb = VBoxContainer.new(); vb.add_theme_constant_override("separation", 8)
	vb.set_meta("var_name", var_name)
	vb.set_meta("opts", opts)
	vb.set_meta("icons", icons)
	
	var tl = Label.new(); tl.text = title; tl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); tl.add_theme_font_size_override("font_size", 10); tl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	vb.add_child(tl)
	
	var hb = HBoxContainer.new(); hb.add_theme_constant_override("separation", 8)
	for i in range(opts.size()):
		var b = Button.new(); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var t = opts[i]
		b.text = t
		if icons.size() > i:
			b.icon = load("res://addons/at-icons/control/" + icons[i] + ".svg")
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); b.add_theme_font_size_override("font_size", 10)
		
		var s = StyleBoxFlat.new(); s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8; s.content_margin_top=8; s.content_margin_bottom=8
		s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1
		if i == active_idx:
			s.bg_color = Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.1)
			s.border_color = ThemeConfig.BRAND_PRIMARY
			b.add_theme_color_override("font_color", Color.WHITE)
			b.add_theme_color_override("icon_normal_color", Color.WHITE)
			b.add_theme_color_override("icon_hover_color", Color.WHITE)
			b.add_theme_color_override("icon_focus_color", Color.WHITE)
		else:
			s.bg_color = ThemeConfig.BG_APP
			s.border_color = ThemeConfig.BORDER_SUBTLE
			b.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
			b.add_theme_color_override("icon_normal_color", ThemeConfig.TEXT_MUTED)
			b.add_theme_color_override("icon_hover_color", ThemeConfig.TEXT_MUTED)
			b.add_theme_color_override("icon_focus_color", ThemeConfig.TEXT_MUTED)
		
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", s)
		
		# ENGINE CONNECTED - Button pressed updates internal state and visual
		var idx = i
		b.pressed.connect(func():
			_on_strategy_btn_pressed(var_name, idx)
		)
		
		hb.add_child(b)
	vb.add_child(hb)
	return vb

# ENGINE CONNECTED - Handle strategy button press
func _on_strategy_btn_pressed(var_name: String, idx: int) -> void:
	match var_name:
		"_pace":
			_pace = idx
		"_offensive_focus":
			_offensive_focus = idx
		"_defensive_focus":
			_defensive_focus = idx
		"_aggressiveness":
			_aggressiveness = idx
		_:
			return
	
	# Find and update the button group visual in the tree
	_update_btn_group_visual(var_name, idx)
	_apply_tactic_to_engine()

# ─────────────────────────────────────────────────────────────
# ENGINE CONNECTED - Apply strategy to simulation engine
# ─────────────────────────────────────────────────────────────

func _apply_tactic_to_engine() -> void:
	# Convert local strategy state to engine tactic config
	var off: String
	var three_freq: float
	match _offensive_focus:
		0:  # PERÍMETRO
			off = "Motion"
			three_freq = 75.0
		1:  # GARRAFÃO
			off = "PostUp"
			three_freq = 25.0
		_:  # BALANCEADO
			off = "Motion"
			three_freq = 50.0
	
	var deff: String
	match _defensive_focus:
		0:  # INDIVIDUAL
			deff = "ManToMan"
		1:  # ZONA 2-3
			deff = "Zone2_3"
		_:  # PRESSÃO
			deff = "FullCourtPress"
	
	var pace_val: float
	match _pace:
		0: pace_val = 30.0  # LENTO
		1: pace_val = 50.0  # MÉDIO
		_: pace_val = 80.0  # RÁPIDO
	
	var phys_val: float
	match _aggressiveness:
		0: phys_val = 25.0  # PASSIVO
		1: phys_val = 50.0  # EQUILIBRADO
		_: phys_val = 80.0  # AGRESSIVO
	
	var tactic: Dictionary = {
		"offensive": off,
		"defensive": deff,
		"pace": pace_val,
		"three_frequency": three_freq,
		"physicality": phys_val,
	}
	
	GameManager.set_tactic(GameManager.user_team_id, tactic)

# ENGINE CONNECTED - Update button group visual to show new active state
func _update_btn_group_visual(var_name: String, active_idx: int) -> void:
	# Search all children for the VBoxContainer with matching var_name meta
	for child in get_children():
		_recursive_update_btn_visual(child, var_name, active_idx)

func _recursive_update_btn_visual(node: Node, var_name: String, active_idx: int) -> void:
	if node is VBoxContainer and node.has_meta("var_name") and node.get_meta("var_name") == var_name:
		# Found the button group - update button visuals
		var opts: Array = node.get_meta("opts")
		var icons: Array = node.get_meta("icons")
		# Child 0 is the title label, child 1 is the HBoxContainer with buttons
		if node.get_child_count() < 2:
			return
		var hb = node.get_child(1)
		if not (hb is HBoxContainer):
			return
		
		for i in range(hb.get_child_count()):
			var b = hb.get_child(i)
			if not (b is Button):
				continue
			
			var s = StyleBoxFlat.new(); s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8; s.content_margin_top=8; s.content_margin_bottom=8
			s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1
			if i == active_idx:
				s.bg_color = Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.1)
				s.border_color = ThemeConfig.BRAND_PRIMARY
				b.add_theme_color_override("font_color", Color.WHITE)
				b.add_theme_color_override("icon_normal_color", Color.WHITE)
				b.add_theme_color_override("icon_hover_color", Color.WHITE)
				b.add_theme_color_override("icon_focus_color", Color.WHITE)
			else:
				s.bg_color = ThemeConfig.BG_APP
				s.border_color = ThemeConfig.BORDER_SUBTLE
				b.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
				b.add_theme_color_override("icon_normal_color", ThemeConfig.TEXT_MUTED)
				b.add_theme_color_override("icon_hover_color", ThemeConfig.TEXT_MUTED)
				b.add_theme_color_override("icon_focus_color", ThemeConfig.TEXT_MUTED)
			
			b.add_theme_stylebox_override("normal", s)
			b.add_theme_stylebox_override("hover", s)
		return
	
	# Recurse into children
	for child in node.get_children():
		_recursive_update_btn_visual(child, var_name, active_idx)

func _create_slider_row(title: String, val: int, color: Color) -> VBoxContainer:
	var vb = VBoxContainer.new(); vb.add_theme_constant_override("separation", 8)
	var hb = HBoxContainer.new()
	var tl = Label.new(); tl.text = title; tl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); tl.add_theme_font_size_override("font_size", 10); tl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hb.add_child(tl)
	var space = Control.new(); space.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hb.add_child(space)
	var vl = Label.new(); vl.text = str(val) + "%"; vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); vl.add_theme_font_size_override("font_size", 12); vl.add_theme_color_override("font_color", color); hb.add_child(vl)
	vb.add_child(hb)
	
	var bar = ColorRect.new(); bar.custom_minimum_size = Vector2(0, 6); bar.color = ThemeConfig.BG_ELEVATED
	var fill = TextureRect.new(); fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var g2d = GradientTexture2D.new(); var g = Gradient.new(); g.set_color(0, Color(color.r, color.g, color.b, 0.2)); g.set_color(1, color)
	g2d.gradient = g; g2d.fill_from = Vector2(0, 0); g2d.fill_to = Vector2(1, 0); fill.texture = g2d
	var fctrl = Control.new(); fctrl.custom_minimum_size = Vector2(val * 2.5, 6); fctrl.add_child(fill); bar.add_child(fctrl)
	
	var thumb = Panel.new(); thumb.custom_minimum_size = Vector2(12, 12); thumb.position = Vector2(val * 2.5 - 6, -3)
	var st = StyleBoxFlat.new(); st.bg_color = Color.WHITE; st.corner_radius_top_left=6; st.corner_radius_bottom_right=6; st.corner_radius_bottom_left=6; st.corner_radius_top_right=6; thumb.add_theme_stylebox_override("panel", st)
	bar.add_child(thumb)
	vb.add_child(bar)
	return vb

# ENGINE CONNECTED - Center col with real starting five
func _build_center_col(parent: Node):
	var p = preload("res://scenes/ui/components/container_base.tscn").instantiate()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL; p.size_flags_vertical = Control.SIZE_EXPAND_FILL; p.size_flags_stretch_ratio = 1.8
	var bg_grad = TextureRect.new(); var g2d = GradientTexture2D.new(); var g = Gradient.new(); g.set_color(0, Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.15)); g.set_color(1, Color(0,0,0,0)); g2d.gradient = g; g2d.fill_from = Vector2(0.5, 0); g2d.fill_to = Vector2(0.5, 0.6); bg_grad.texture = g2d; bg_grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg_grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); p.add_child(bg_grad)
	
	var m = MarginContainer.new(); m.size_flags_horizontal = Control.SIZE_EXPAND_FILL; m.size_flags_vertical = Control.SIZE_EXPAND_FILL; m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24); m.add_theme_constant_override("margin_top", 24); m.add_theme_constant_override("margin_bottom", 24)
	var vb = VBoxContainer.new(); vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vb.size_flags_vertical = Control.SIZE_EXPAND_FILL; vb.add_theme_constant_override("separation", 16)
	
	var htop = HBoxContainer.new(); htop.add_theme_constant_override("separation", 16); htop.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var hl = Label.new(); hl.text = "QUINTETO TITULAR"; hl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); hl.add_theme_font_size_override("font_size", 10); hl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hl.add_theme_constant_override("letter_spacing", 1)
	var hb_icon = HBoxContainer.new(); hb_icon.add_theme_constant_override("separation", 8)
	var icon = TextureRect.new(); icon.texture = load("res://addons/at-icons/control/human.svg"); icon.custom_minimum_size = Vector2(14, 14); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.modulate = ThemeConfig.TEXT_MUTED; hb_icon.add_child(icon); hb_icon.add_child(hl); htop.add_child(hb_icon)
	
	var space = Control.new(); space.size_flags_horizontal = Control.SIZE_EXPAND_FILL; htop.add_child(space)
	
	# ENGINE CONNECTED - Dynamic stats based on starting five
	if not _starting_five.is_empty():
		var total_ovr: int = 0
		var total_age: int = 0
		var total_salary: int = 0
		for player in _starting_five:
			total_ovr += player.get("overall", 50)
			total_age += player.get("age", 25)
			total_salary += player.get("salary", 0)
		
		var avg_ovr: int = int(total_ovr / _starting_five.size())
		var avg_age: float = float(total_age) / _starting_five.size()
		var salary_str: String = _format_salary(total_salary)
		
		htop.add_child(_create_stat("OVR", str(avg_ovr)))
		htop.add_child(_create_stat("IDADE MÉDIA", "%.1f" % avg_age))
		htop.add_child(_create_stat("SALÁRIO", salary_str, ThemeConfig.SUCCESS))
	else:
		htop.add_child(_create_stat("OVR", "--"))
		htop.add_child(_create_stat("IDADE MÉDIA", "--"))
		htop.add_child(_create_stat("SALÁRIO", "--", ThemeConfig.SUCCESS))
	
	var btn_edit = Button.new(); btn_edit.text = "EDITAR"; btn_edit.icon = load("res://addons/at-icons/control/pencil.svg"); btn_edit.add_theme_constant_override("h_separation", 4); btn_edit.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); btn_edit.add_theme_font_size_override("font_size", 10)
	var se = StyleBoxFlat.new(); se.bg_color = Color(0,0,0,0); se.border_width_left=1; se.border_width_right=1; se.border_width_top=1; se.border_width_bottom=1; se.border_color = ThemeConfig.BORDER_SUBTLE; se.corner_radius_top_left=6; se.corner_radius_bottom_right=6; se.corner_radius_bottom_left=6; se.corner_radius_top_right=6; se.content_margin_left=12; se.content_margin_right=12
	btn_edit.add_theme_stylebox_override("normal", se)
	btn_edit.pressed.connect(func():
		# Switch to the "ESCALAÇÃO" tab and enable edit mode
		print("[Tactics] Edit mode requested")
	)
	htop.add_child(btn_edit)
	vb.add_child(htop)
	
	# Court
	var court_panel = PanelContainer.new(); court_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sc = StyleBoxFlat.new(); sc.bg_color = ThemeConfig.BG_APP; sc.corner_radius_top_left=12; sc.corner_radius_bottom_right=12; sc.corner_radius_bottom_left=12; sc.corner_radius_top_right=12; sc.border_width_left=1; sc.border_width_right=1; sc.border_width_top=1; sc.border_width_bottom=1; sc.border_color = ThemeConfig.BORDER_SUBTLE
	court_panel.add_theme_stylebox_override("panel", sc)
	court_panel.clip_contents = true
	
	var court = Control.new()
	court.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	court.set_script(preload("res://scripts/menu_court.gd"))
	court_panel.add_child(court)
	
	var cnodes = Control.new()
	cnodes.name = "PlayerNodes"
	cnodes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	court_panel.add_child(cnodes)
	
	# ENGINE CONNECTED - Real players from starting five
	for player in _starting_five:
		var pos: String = player.get("position", "PG")
		var initials: String = _get_initials(player)
		var pname: String = player.get("first_name", "Jogador")
		var ovr: String = str(player.get("overall", 50))
		var color: Color = _get_pos_color(pos)
		var meter_pos: Vector2 = POS_POSITIONS.get(pos, Vector2(0.0, 9.0))
		_add_court_node(cnodes, pos, initials, pname, ovr, color, meter_pos)
	
	vb.add_child(court_panel)
	
	# ENGINE CONNECTED - Dynamic minutes based on overall
	var hmin = HBoxContainer.new(); hmin.add_theme_constant_override("separation", 16); hmin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var lmin = Label.new(); lmin.text = "MINUTAGEM:"; lmin.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); lmin.add_theme_font_size_override("font_size", 10); lmin.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hmin.add_child(lmin)
	
	if not _starting_five.is_empty():
		for player in _starting_five:
			var pos: String = player.get("position", "")
			var ovr: int = player.get("overall", 50)
			var mins: int = _calc_minutes(ovr)
			var initials: String = _get_initials(player)
			var color: Color = _get_pos_color(pos)
			hmin.add_child(_create_min_box(initials, str(mins) + "min", color))
	else:
		# Fallback empty state
		hmin.add_child(_create_min_box("--", "--", ThemeConfig.TEXT_MUTED))
	
	vb.add_child(hmin)
	
	m.add_child(vb); p.add_child(m); parent.add_child(p)

func _create_stat(title: String, val: String, color: Color = Color.WHITE) -> HBoxContainer:
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 6)
	var t = Label.new(); t.text = title; t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_font_size_override("font_size", 10); t.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	var v = Label.new(); v.text = val; v.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); v.add_theme_font_size_override("font_size", 12); v.add_theme_color_override("font_color", color)
	h.add_child(t); h.add_child(v); return h

func _create_min_box(pos: String, min: String, color: Color) -> PanelContainer:
	var p = PanelContainer.new()
	var s = StyleBoxFlat.new(); s.bg_color = Color(0,0,0,0); s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = color; s.corner_radius_top_left=4; s.corner_radius_bottom_right=4; s.corner_radius_bottom_left=4; s.corner_radius_top_right=4
	p.add_theme_stylebox_override("panel", s)
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 0)
	var p1 = PanelContainer.new()
	var s1 = StyleBoxFlat.new(); s1.bg_color = Color(color.r, color.g, color.b, 0.2); s1.corner_radius_top_left=3; s1.corner_radius_bottom_left=3; p1.add_theme_stylebox_override("panel", s1)
	var m1 = MarginContainer.new(); m1.add_theme_constant_override("margin_left", 6); m1.add_theme_constant_override("margin_right", 6); p1.add_child(m1)
	var l1 = Label.new(); l1.text = pos; l1.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); l1.add_theme_font_size_override("font_size", 10); l1.add_theme_color_override("font_color", color); m1.add_child(l1)
	
	var p2 = PanelContainer.new()
	var s2 = StyleBoxFlat.new(); s2.bg_color = Color(0,0,0,0); p2.add_theme_stylebox_override("panel", s2)
	var m2 = MarginContainer.new(); m2.add_theme_constant_override("margin_left", 6); m2.add_theme_constant_override("margin_right", 6); p2.add_child(m2)
	var l2 = Label.new(); l2.text = min; l2.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); l2.add_theme_font_size_override("font_size", 10); m2.add_child(l2)
	
	h.add_child(p1); h.add_child(p2); p.add_child(h)
	return p

func _meter_to_screen(mx: float, mz: float, court_size: Vector2) -> Vector2:
	var w = court_size.x
	var h = court_size.y
	if w <= 0 or h <= 0:
		return Vector2.ZERO
	var ppm = min(w / (COURT_WIDTH_M + 2.0), h / (COURT_VISUAL_HALF + 2.0))
	var cx = w / 2.0
	var cy = h - ppm * 1.0
	return Vector2(cx + mx * ppm, cy - mz * ppm)

func _add_court_node(parent: Control, pos: String, initials: String, pname: String, ovr: String, color: Color, meter_pos: Vector2):
	var c = Control.new()
	c.set_meta("meter_pos", meter_pos)
	
	if initials.is_empty():
		initials = pos
	
	var circ = PanelContainer.new(); circ.position = Vector2(-24, -24); circ.custom_minimum_size = Vector2(48, 48)
	var sc = StyleBoxFlat.new(); sc.bg_color = color; sc.corner_radius_top_left=24; sc.corner_radius_bottom_right=24; sc.corner_radius_bottom_left=24; sc.corner_radius_top_right=24
	sc.border_width_left=2; sc.border_width_right=2; sc.border_width_top=2; sc.border_width_bottom=2; sc.border_color = Color.WHITE
	circ.add_theme_stylebox_override("panel", sc)
	var num_lbl = Label.new(); num_lbl.text = initials; num_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); num_lbl.add_theme_font_size_override("font_size", 16); num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	circ.add_child(num_lbl)
	c.add_child(circ)
	
	var info = PanelContainer.new(); info.position = Vector2(-30, 24); info.custom_minimum_size = Vector2(60, 24)
	var si = StyleBoxFlat.new(); si.bg_color = ThemeConfig.BG_APP; si.border_width_left=1; si.border_width_right=1; si.border_width_top=1; si.border_width_bottom=1; si.border_color=ThemeConfig.BORDER_SUBTLE; si.corner_radius_top_left=4; si.corner_radius_bottom_right=4; si.corner_radius_bottom_left=4; si.corner_radius_top_right=4
	info.add_theme_stylebox_override("panel", si)
	var vb = VBoxContainer.new(); vb.add_theme_constant_override("separation", 0); vb.alignment = BoxContainer.ALIGNMENT_CENTER
	var h = HBoxContainer.new(); h.alignment = BoxContainer.ALIGNMENT_CENTER; h.add_theme_constant_override("separation", 2)
	var pl = Label.new(); pl.text = pos; pl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); pl.add_theme_font_size_override("font_size", 9); pl.add_theme_color_override("font_color", color); h.add_child(pl)
	var ol = Label.new(); ol.text = "· " + ovr; ol.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); ol.add_theme_font_size_override("font_size", 9); h.add_child(ol)
	vb.add_child(h)
	var nl = Label.new(); nl.text = pname; nl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); nl.add_theme_font_size_override("font_size", 9); nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(nl)
	info.add_child(vb)
	c.add_child(info)
	parent.add_child(c)


func _reposition_players():
	var cnodes = find_child("PlayerNodes", true, false)
	if not cnodes:
		return
	var court_size = cnodes.size
	if court_size.x <= 0 or court_size.y <= 0:
		_reposition_players.call_deferred()
		return
	for child in cnodes.get_children():
		var meter_pos = child.get_meta("meter_pos", Vector2.ZERO)
		if meter_pos != Vector2.ZERO:
			child.position = _meter_to_screen(meter_pos.x, meter_pos.y, court_size)


# ENGINE CONNECTED - Right col with real opponent data
func _build_right_col(parent: Node):
	var p = preload("res://scenes/ui/components/container_base.tscn").instantiate()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL; p.size_flags_vertical = Control.SIZE_EXPAND_FILL; p.size_flags_stretch_ratio = 1.0
	var bg_grad = TextureRect.new(); var g2d = GradientTexture2D.new(); var g = Gradient.new(); g.set_color(0, Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.15)); g.set_color(1, Color(0,0,0,0)); g2d.gradient = g; g2d.fill_from = Vector2(0.5, 0); g2d.fill_to = Vector2(0.5, 0.6); bg_grad.texture = g2d; bg_grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg_grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); p.add_child(bg_grad)
	
	var scroll = ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var m = MarginContainer.new(); m.size_flags_horizontal = Control.SIZE_EXPAND_FILL; m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24); m.add_theme_constant_override("margin_top", 24); m.add_theme_constant_override("margin_bottom", 24)
	var vb = VBoxContainer.new(); vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vb.add_theme_constant_override("separation", 24)
	
	var htop = HBoxContainer.new()
	var hl = Label.new(); hl.text = "ANÁLISE DO ADVERSÁRIO"; hl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); hl.add_theme_font_size_override("font_size", 10); hl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); hl.add_theme_constant_override("letter_spacing", 1)
	var hbox = HBoxContainer.new(); hbox.add_theme_constant_override("separation", 8)
	var icon = TextureRect.new(); icon.texture = load("res://addons/at-icons/control/magnifying_glass.svg"); icon.custom_minimum_size = Vector2(14, 14); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.modulate = ThemeConfig.TEXT_MUTED; hbox.add_child(icon); hbox.add_child(hl); htop.add_child(hbox)
	var space = Control.new(); space.size_flags_horizontal = Control.SIZE_EXPAND_FILL; htop.add_child(space)
	
	# ENGINE CONNECTED - Days until next match
	var days_until: String = _calc_days_until_next_match()
	var days = Label.new(); days.text = days_until; days.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); days.add_theme_font_size_override("font_size", 10); days.add_theme_color_override("font_color", ThemeConfig.WARNING); htop.add_child(days)
	vb.add_child(htop)
	
	# ENGINE CONNECTED - Opponent team info
	var opp_name: String = _opponent_data.get("name", "A definir")
	var opp_city: String = _opponent_data.get("city", "")
	var opp_wins: int = _opponent_data.get("wins", 0)
	var opp_losses: int = _opponent_data.get("losses", 0)
	var opp_abbr_logo: String = _opponent_data.get("abbreviation", _opponent_abbr)
	var opp_id: int = _opponent_data.get("id", 0)
	
	# Calculate standings position
	var opp_pos: int = _calc_standings_position(opp_id)
	var opp_pos_text: String = str(opp_pos) + "º lugar" if opp_pos > 0 else "--"
	
	# Determine if home or away
	var is_home: bool = true
	var location_text: String = "@ Casa"
	if not _next_match.is_empty():
		is_home = _next_match.get("home_team_id", 0) == GameManager.user_team_id
		location_text = "@ Casa" if is_home else "@ Fora"
	
	var team_box = HBoxContainer.new(); team_box.add_theme_constant_override("separation", 16)
	var tlogo = PanelContainer.new(); tlogo.custom_minimum_size = Vector2(48, 48)
	var st = StyleBoxFlat.new(); st.bg_color = ThemeConfig.DANGER; st.corner_radius_top_left=24; st.corner_radius_bottom_right=24; st.corner_radius_bottom_left=24; st.corner_radius_top_right=24; tlogo.add_theme_stylebox_override("panel", st)
	var tl_lbl = Label.new(); tl_lbl.text = opp_abbr_logo; tl_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK); tl_lbl.add_theme_font_size_override("font_size", 14); tl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tl_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; tlogo.add_child(tl_lbl)
	team_box.add_child(tlogo)
	var tvb = VBoxContainer.new(); tvb.alignment = BoxContainer.ALIGNMENT_CENTER
	var tname = Label.new(); tname.text = opp_name if opp_city.is_empty() else opp_city + " " + opp_name; tname.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); tname.add_theme_font_size_override("font_size", 16); tvb.add_child(tname)
	var tstat = Label.new(); tstat.text = str(opp_wins) + "V - " + str(opp_losses) + "D · " + opp_pos_text + " · " + location_text; tstat.add_theme_font_size_override("font_size", 12); tstat.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); tvb.add_child(tstat)
	team_box.add_child(tvb)
	vb.add_child(team_box)
	
	# ENGINE CONNECTED - Generated analysis items
	var analysis: Array = _generate_analysis()
	for item in analysis:
		vb.add_child(_create_adv_stat(
			item.get("title", ""),
			item.get("val", ""),
			item.get("color", ThemeConfig.TEXT_MUTED),
			item.get("icon", "arrow_right"),
			item.get("active", false)
		))
	
	# ENGINE CONNECTED - Assistant recommendation with real player names
	var rec = PanelContainer.new()
	var sr = StyleBoxFlat.new(); sr.bg_color = Color(ThemeConfig.BRAND_PRIMARY.r, ThemeConfig.BRAND_PRIMARY.g, ThemeConfig.BRAND_PRIMARY.b, 0.1); sr.border_width_left=1; sr.border_width_right=1; sr.border_width_top=1; sr.border_width_bottom=1; sr.border_color = ThemeConfig.BRAND_PRIMARY; sr.corner_radius_top_left=8; sr.corner_radius_bottom_right=8; sr.corner_radius_bottom_left=8; sr.corner_radius_top_right=8
	rec.add_theme_stylebox_override("panel", sr)
	var rm = MarginContainer.new(); rm.add_theme_constant_override("margin_left", 16); rm.add_theme_constant_override("margin_right", 16); rm.add_theme_constant_override("margin_top", 16); rm.add_theme_constant_override("margin_bottom", 16); rec.add_child(rm)
	var rv = VBoxContainer.new(); rv.add_theme_constant_override("separation", 12); rm.add_child(rv)
	var rhl = Label.new(); rhl.text = "RECOMENDAÇÃO DO ASSISTENTE"; rhl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); rhl.add_theme_font_size_override("font_size", 10); rhl.add_theme_color_override("font_color", ThemeConfig.WARNING)
	var rhbox = HBoxContainer.new(); rhbox.add_theme_constant_override("separation", 8)
	var ricon = TextureRect.new(); ricon.texture = load("res://addons/at-icons/control/star.svg"); ricon.custom_minimum_size = Vector2(14, 14); ricon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ricon.modulate = ThemeConfig.WARNING; rhbox.add_child(ricon); rhbox.add_child(rhl); rv.add_child(rhbox)
	var rdesc = Label.new(); rdesc.text = _generate_recommendation(); rdesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; rdesc.add_theme_font_size_override("font_size", 12); rdesc.custom_minimum_size = Vector2(100, 0); rv.add_child(rdesc)
	var rbtn = Button.new(); rbtn.text = "APLICAR ESTRATÉGIA"; rbtn.icon = load("res://addons/at-icons/control/magic_wand.svg"); rbtn.add_theme_constant_override("h_separation", 8); rbtn.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); rbtn.add_theme_font_size_override("font_size", 12)
	var srb = StyleBoxFlat.new(); srb.bg_color = ThemeConfig.BRAND_PRIMARY; srb.corner_radius_top_left=6; srb.corner_radius_bottom_right=6; srb.corner_radius_bottom_left=6; srb.corner_radius_top_right=6; srb.content_margin_top=8; srb.content_margin_bottom=8
	rbtn.add_theme_stylebox_override("normal", srb)
	rbtn.pressed.connect(func():
		_apply_tactic_to_engine()
		print("[Tactics] Strategy applied to engine")
	)
	rv.add_child(rbtn)
	vb.add_child(rec)
	
	var p2 = PanelContainer.new(); p2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sp2 = StyleBoxFlat.new(); sp2.bg_color = ThemeConfig.BG_APP; sp2.corner_radius_top_left=12; sp2.corner_radius_bottom_right=12; sp2.corner_radius_bottom_left=12; sp2.corner_radius_top_right=12; sp2.border_width_left=1; sp2.border_width_right=1; sp2.border_width_top=1; sp2.border_width_bottom=1; sp2.border_color = ThemeConfig.BORDER_SUBTLE
	p2.add_theme_stylebox_override("panel", sp2)
	var m2 = MarginContainer.new(); m2.add_theme_constant_override("margin_left", 16); m2.add_theme_constant_override("margin_right", 16); m2.add_theme_constant_override("margin_top", 16); m2.add_theme_constant_override("margin_bottom", 16); p2.add_child(m2)
	var v2 = VBoxContainer.new(); v2.add_theme_constant_override("separation", 16); m2.add_child(v2)
	
	# ENGINE CONNECTED - Plays with real player names
	var pg_name: String = _get_player_name_by_pos("PG")
	var sg_name: String = _get_player_name_by_pos("SG")
	var sf_name: String = _get_player_name_by_pos("SF")
	var pf_name: String = _get_player_name_by_pos("PF")
	var c_name: String = _get_player_name_by_pos("C")
	
	if pg_name == "": pg_name = "PG"
	if sg_name == "": sg_name = "SG"
	if sf_name == "": sf_name = "SF"
	if pf_name == "": pf_name = "PF"
	if c_name == "": c_name = "C"
	
	var jtop = HBoxContainer.new()
	var jl = Label.new(); jl.text = "JOGADAS ENSAIADAS"; jl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); jl.add_theme_font_size_override("font_size", 10); jl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); jl.add_theme_constant_override("letter_spacing", 1); jtop.add_child(jl)
	var jsp = Control.new(); jsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; jtop.add_child(jsp)
	var jc = Label.new(); jc.text = "4/8"; jc.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); jc.add_theme_font_size_override("font_size", 10); jc.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); jtop.add_child(jc)
	v2.add_child(jtop)
	
	v2.add_child(_create_play("Pick & Roll Alto", pg_name + " - " + c_name, 5, "link"))
	v2.add_child(_create_play("Drive & Kick", sg_name + " - " + sf_name + " 3pt", 4, "arrow_right"))
	v2.add_child(_create_play("Iso Wing", sf_name + " · 1v1", 4, "target"))
	v2.add_child(_create_play("Post-Up Pivô", c_name + " · garrafão", 3, "clock"))
	v2.add_child(_create_play("Transition Break", "Defesa - Ataque rápido", 4, "lightning_bolt"))
	
	vb.add_child(p2)
	
	m.add_child(vb); scroll.add_child(m); p.add_child(scroll); parent.add_child(p)


# ═══════════════════════════════════════════════════════════════
# ENGINE CONNECTED - Opponent Analysis
# ═══════════════════════════════════════════════════════════════

func _calc_days_until_next_match() -> String:
	if _next_match.is_empty():
		return "---"
	var today: Dictionary = Time.get_date_dict_from_system()
	var match_day: int = _next_match.get("day", 0)
	var match_month: int = _next_match.get("month", 0)
	var match_year: int = _next_match.get("year", 0)
	
	if match_day == 0:
		return "---"
	
	var unix_now: int = Time.get_unix_time_from_datetime_dict({
		"year": today.year, "month": today.month, "day": today.day,
		"hour": 0, "minute": 0, "second": 0
	})
	var unix_match: int = Time.get_unix_time_from_datetime_dict({
		"year": match_year, "month": match_month, "day": match_day,
		"hour": 0, "minute": 0, "second": 0
	})
	
	var diff_days: int = int((unix_match - unix_now) / 86400)
	if diff_days < 0:
		return "HOJE"
	elif diff_days == 0:
		return "HOJE"
	elif diff_days == 1:
		return "1 DIA"
	else:
		return str(diff_days) + " DIAS"

func _calc_standings_position(team_id: int) -> int:
	var teams: Array = GameManager.league.get("teams", [])
	if teams.is_empty():
		return 0
	
	# Sort by win-loss differential (higher first)
	var sorted: Array = teams.duplicate()
	sorted.sort_custom(func(a, b):
		var a_diff: int = a.get("wins", 0) - a.get("losses", 0)
		var b_diff: int = b.get("wins", 0) - b.get("losses", 0)
		if a_diff != b_diff:
			return a_diff > b_diff
		return a.get("wins", 0) > b.get("wins", 0)
	)
	
	for i in range(sorted.size()):
		if sorted[i].get("id", 0) == team_id:
			return i + 1
	return 0

func _generate_analysis() -> Array:
	var result: Array = []
	if not _has_data or _opponent_data.is_empty():
		return result
	
	var user_players: Array = _team_data.get("players", [])
	var opp_players: Array = _opponent_data.get("players", [])
	
	if user_players.is_empty() or opp_players.is_empty():
		return result
	
	# Compare 3PT
	var user_3pt: float = _get_team_avg_attr(user_players, "three_point", "three_pt")
	var opp_3pt: float = _get_team_avg_attr(opp_players, "three_point", "three_pt")
	
	# Compare defense
	var user_def: float = _get_team_avg_attr(user_players, "defense", "perimeter_def")
	var opp_def: float = _get_team_avg_attr(opp_players, "defense", "perimeter_def")
	
	# Compare interior (rebounding + blocks)
	var user_reb: float = _get_team_avg_attr(user_players, "rebounding", "offensive_rebound")
	var opp_reb: float = _get_team_avg_attr(opp_players, "rebounding", "offensive_rebound")
	
	# Compare stamina/fatigue (bench depth proxy via stamina)
	var user_stam: float = _get_team_avg_attr(user_players, "stamina", "stamina")
	var opp_stam: float = _get_team_avg_attr(opp_players, "stamina", "stamina")
	
	# 3PT comparison
	if user_3pt > opp_3pt:
		result.append({"title": "Vantagem nos 3pts", "val": str(int(user_3pt)) + " OVR", "color": ThemeConfig.SUCCESS, "icon": "arrow_up_right", "active": false})
	else:
		result.append({"title": "Desvantagem nos 3pts", "val": str(int(opp_3pt)) + " OVR", "color": Color("#3B82F6"), "icon": "arrow_down_right", "active": true})
	
	# Defense comparison
	if user_def > opp_def:
		result.append({"title": "Defesa superior", "val": str(int(user_def)) + " OVR", "color": ThemeConfig.SUCCESS, "icon": "arrow_up_right", "active": false})
	else:
		result.append({"title": "Defesa do perímetro fraca", "val": str(int(opp_def)) + " OVR", "color": Color("#3B82F6"), "icon": "arrow_down_right", "active": true})
	
	# Interior game comparison
	if user_reb > opp_reb:
		result.append({"title": "Forte no garrafão", "val": str(int(user_reb)) + " OVR", "color": ThemeConfig.DANGER, "icon": "arrow_up_right", "active": false})
	else:
		result.append({"title": "Garrafão vulnerável", "val": str(int(opp_reb)) + " OVR", "color": ThemeConfig.DANGER, "icon": "arrow_down_right", "active": true})
	
	# Stamina / bench
	if user_stam > opp_stam:
		result.append({"title": "Mais fôlego no banco", "val": str(int(user_stam)) + " STA", "color": ThemeConfig.SUCCESS, "icon": "arrow_up_right", "active": false})
	else:
		result.append({"title": "Pouca rotação no banco", "val": str(int(opp_stam)) + " STA", "color": ThemeConfig.SUCCESS, "icon": "arrow_down_right", "active": true})
	
	return result

func _generate_recommendation() -> String:
	if not _has_data or _opponent_data.is_empty() or _starting_five.is_empty():
		return "Nenhum dado disponível. Inicie ou carregue uma temporada para ver recomendações."
	
	var user_players: Array = _team_data.get("players", [])
	var opp_players: Array = _opponent_data.get("players", [])
	
	if user_players.is_empty() or opp_players.is_empty():
		return "Dados incompletos para gerar recomendação."
	
	var user_3pt: float = _get_team_avg_attr(user_players, "three_point", "three_pt")
	var opp_3pt: float = _get_team_avg_attr(opp_players, "three_point", "three_pt")
	var user_def: float = _get_team_avg_attr(user_players, "defense", "perimeter_def")
	var opp_def: float = _get_team_avg_attr(opp_players, "defense", "perimeter_def")
	var user_reb: float = _get_team_avg_attr(user_players, "rebounding", "offensive_rebound")
	var opp_reb: float = _get_team_avg_attr(opp_players, "rebounding", "offensive_rebound")
	
	var pg_name: String = _get_player_name_by_pos("PG")
	var c_name: String = _get_player_name_by_pos("C")
	
	var parts: Array = []
	
	if user_3pt > opp_3pt:
		parts.append("Explore o perímetro com " + pg_name + ".")
		parts.append("Aumente intensidade 3PT para 80%+.")
	else:
		parts.append("Evite o jogo de perímetro, o oponente é forte de fora.")
		parts.append("Use transição rápida para pegar a defesa desprevenida.")
	
	if user_def < opp_def:
		parts.append("A defesa adversária é forte, use Pick & Roll com " + pg_name + " e " + c_name + ".")
	else:
		parts.append("Sua defesa é sólida, pressione a saída de bola.")
	
	if user_reb < opp_reb:
		parts.append("Cuidado com o garrafão adversário, feche o rebote defensivo.")
	else:
		parts.append("Domine o garrafão com " + c_name + " no ataque.")
	
	return " ".join(parts)

func _get_player_name_by_pos(pos: String) -> String:
	for p in _starting_five:
		if p.get("position", "") == pos:
			return p.get("first_name", "Jogador")
	return ""

func _create_adv_stat(title: String, val: String, color: Color, icon: String, active: bool = false) -> HBoxContainer:
	var h = HBoxContainer.new()
	var p = PanelContainer.new()
	if active:
		var sp = StyleBoxFlat.new(); sp.bg_color = Color(0,0,0,0); sp.border_width_left=1; sp.border_width_right=1; sp.border_width_top=1; sp.border_width_bottom=1; sp.border_color = color; sp.corner_radius_top_left=4; sp.corner_radius_bottom_right=4; sp.corner_radius_bottom_left=4; sp.corner_radius_top_right=4
		p.add_theme_stylebox_override("panel", sp)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 8); m.add_theme_constant_override("margin_right", 8); m.add_theme_constant_override("margin_top", 4); m.add_theme_constant_override("margin_bottom", 4); p.add_child(m)
	var hb = HBoxContainer.new(); hb.add_theme_constant_override("separation", 8); m.add_child(hb)
	
	var i = TextureRect.new(); i.texture = load("res://addons/at-icons/control/" + icon + ".svg"); i.custom_minimum_size = Vector2(16, 16); i.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; i.modulate = color; i.size_flags_vertical = Control.SIZE_SHRINK_CENTER; hb.add_child(i)
	var t = Label.new(); t.text = title; t.add_theme_font_size_override("font_size", 12); hb.add_child(t)
	h.add_child(p)
	
	var space = Control.new(); space.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(space)
	var v = Label.new(); v.text = val; v.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); v.add_theme_font_size_override("font_size", 12); v.add_theme_color_override("font_color", color); h.add_child(v)
	return h

func _create_play(title: String, sub: String, stars: int, icon: String) -> PanelContainer:
	var p = PanelContainer.new()
	var s = StyleBoxFlat.new(); s.bg_color = Color(0,0,0,0); s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color = ThemeConfig.BORDER_SUBTLE; s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8
	p.add_theme_stylebox_override("panel", s)
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", 12); m.add_theme_constant_override("margin_right", 12); m.add_theme_constant_override("margin_top", 8); m.add_theme_constant_override("margin_bottom", 8); p.add_child(m)
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", 16); m.add_child(h)
	
	var ic = TextureRect.new(); ic.texture = load("res://addons/at-icons/control/" + icon + ".svg"); ic.custom_minimum_size = Vector2(16, 16); ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ic.modulate = ThemeConfig.TEXT_MUTED; ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER; h.add_child(ic)
	
	var v = VBoxContainer.new(); v.alignment = BoxContainer.ALIGNMENT_CENTER
	var t = Label.new(); t.text = title; t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD); t.add_theme_font_size_override("font_size", 12); v.add_child(t)
	var su = Label.new(); su.text = sub; su.add_theme_font_size_override("font_size", 10); su.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); v.add_child(su)
	h.add_child(v)
	
	var space = Control.new(); space.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(space)
	
	var sbox = HBoxContainer.new(); sbox.add_theme_constant_override("separation", 2); sbox.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(5):
		var st = TextureRect.new(); st.texture = load("res://addons/at-icons/control/star.svg"); st.custom_minimum_size = Vector2(10, 10); st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		st.modulate = ThemeConfig.WARNING if i < stars else ThemeConfig.BORDER_SUBTLE
		sbox.add_child(st)
	h.add_child(sbox)
	
	return p
