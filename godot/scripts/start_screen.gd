extends Control

func _ready():
	if GameManager.has_save() and GameManager.league.is_empty():
		GameManager.load_career()
	_build_background()
	_build_top_bar()
	_build_center_area()
	_build_news_ticker()
	_build_bottom_right()

func _make_label(txt: String, font: Font, size: int, color: Color, extra: Dictionary = {}) -> Label:
	var l = Label.new()
	l.text = txt
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	for k in extra:
		match k:
			"alignment": l.horizontal_alignment = extra[k]
			"valignment": l.vertical_alignment = extra[k]
			"autowrap": l.autowrap_mode = extra[k]
			"letter_spacing": l.add_theme_constant_override("letter_spacing", extra[k])
			"line_spacing": l.add_theme_constant_override("line_spacing", extra[k])
	return l

func _make_icon(path: String, size: float, color: Color = Color.WHITE) -> TextureRect:
	var t = TextureRect.new()
	t.texture = load(path)
	t.custom_minimum_size = Vector2(size, size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.modulate = color
	return t

func _make_style(bg: Color, border: Color = Color.TRANSPARENT, radius: float = 0) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	if border.a > 0:
		s.border_width_left = 1
		s.border_width_top = 1
		s.border_width_right = 1
		s.border_width_bottom = 1
	if radius > 0:
		s.corner_radius_top_left = radius
		s.corner_radius_top_right = radius
		s.corner_radius_bottom_right = radius
		s.corner_radius_bottom_left = radius
	return s

func _make_hover_style(bg: Color, border: Color = Color.TRANSPARENT, radius: float = 0) -> StyleBoxFlat:
	var s = _make_style(bg, border, radius)
	s.shadow_color = Color(bg, 0.4)
	s.shadow_size = 10
	return s

func _make_vbox(sep: int = 0, align: int = BoxContainer.ALIGNMENT_BEGIN) -> VBoxContainer:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.alignment = align
	return v

func _make_hbox(sep: int = 0, align: int = BoxContainer.ALIGNMENT_BEGIN) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.alignment = align
	return h

func _make_panel(style: StyleBoxFlat, min_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", style)
	if min_size != Vector2.ZERO:
		p.custom_minimum_size = min_size
	return p

func _make_margin(ml: int = 0, mt: int = 0, mr: int = 0, mb: int = 0) -> MarginContainer:
	var m = MarginContainer.new()
	if ml > 0: m.add_theme_constant_override("margin_left", ml)
	if mt > 0: m.add_theme_constant_override("margin_top", mt)
	if mr > 0: m.add_theme_constant_override("margin_right", mr)
	if mb > 0: m.add_theme_constant_override("margin_bottom", mb)
	return m

func _full_rect():
	var c = Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	return c

func _build_background():
	var bg = TextureRect.new()
	bg.texture = load("res://assets/images/start_bg.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.01, 0.05, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var court = ColorRect.new()
	court.color = Color(0.12, 0.07, 0.03, 0.6)
	court.anchor_top = 0.6
	court.anchor_bottom = 1.0
	court.anchor_left = 0.0
	court.anchor_right = 1.0
	court.offset_top = 0
	court.offset_bottom = 0
	add_child(court)

func _build_top_bar():
	var bar = Control.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_top = 32
	bar.offset_bottom = 32 + 200
	add_child(bar)

	var hbox = _make_hbox(0, BoxContainer.ALIGNMENT_CENTER)
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 40
	hbox.offset_right = -40
	bar.add_child(hbox)

	var logo_wrap = _make_hbox(14, BoxContainer.ALIGNMENT_CENTER)
	var basket = TextureRect.new()
	basket.texture = preload("res://assets/ui/logo-basketball.png")
	basket.custom_minimum_size = Vector2(56, 56)
	basket.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	basket.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_wrap.add_child(basket)
	var logo_text = _make_vbox(0, BoxContainer.ALIGNMENT_CENTER)
	logo_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var prohoops = _make_label("PRO HOOPS", ThemeConfig.FONT_INTER_BLACK, 22, Color.WHITE, {"letter_spacing": 2})
	prohoops.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	logo_text.add_child(prohoops)
	var manager = _make_label("MANAGER", ThemeConfig.FONT_INTER_BOLD, 12, Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0), {"letter_spacing": 5})
	manager.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	logo_text.add_child(manager)
	logo_wrap.add_child(logo_text)
	logo_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(logo_wrap)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(spacer)

	var top_right = _make_hbox(10, BoxContainer.ALIGNMENT_CENTER)
	top_right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var version_style = _make_style(Color(0.04, 0.02, 0.08, 0.53), Color(0x2D / 255.0, 0x1B / 255.0, 0x4E / 255.0), 4)
	version_style.content_margin_left = 10
	version_style.content_margin_top = 4
	version_style.content_margin_right = 10
	version_style.content_margin_bottom = 4
	var version = _make_panel(version_style)

	var version_hbox = _make_hbox(4, BoxContainer.ALIGNMENT_CENTER)
	var vdot = _make_circle(5, Color(0x10 / 255.0, 0xB9 / 255.0, 0x81 / 255.0))
	vdot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	version_hbox.add_child(vdot)
	var vlabel = _make_label("v1.0.0 · ONLINE", ThemeConfig.FONT_INTER_EXTRABOLD, 9, Color(0x94 / 255.0, 0xA3 / 255.0, 0xB8 / 255.0), {"letter_spacing": 0.5})
	version_hbox.add_child(vlabel)
	version.add_child(version_hbox)
	version.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_right.add_child(version)

	var icon_btn_style = _make_style(Color(0.04, 0.02, 0.08, 0.53), Color(0x2D / 255.0, 0x1B / 255.0, 0x4E / 255.0), 6)
	var icon_btns = _make_hbox(6, BoxContainer.ALIGNMENT_CENTER)
	var icon_data = ["bell", "headphones", "cog"]
	var i = 0
	for name in icon_data:
		var container = _make_panel(icon_btn_style)
		container.custom_minimum_size = Vector2(36, 36)
		container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var wrapper = Control.new()
		wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
		var center = CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		var icon = _make_icon("res://addons/at-icons/control/" + name + ".svg", 16, Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0))
		center.add_child(icon)
		wrapper.add_child(center)
		if i == 0:
			var notif_dot = _make_circle(6, Color(0xEF / 255.0, 0x44 / 255.0, 0x44 / 255.0))
			notif_dot.position = Vector2(24, 6)
			wrapper.add_child(notif_dot)
		container.add_child(wrapper)
		icon_btns.add_child(container)
		i += 1
	icon_btns.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_right.add_child(icon_btns)
	hbox.add_child(top_right)

func _make_circle(size: int, color: Color) -> PanelContainer:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	var r = ceil(size / 2.0)
	s.corner_radius_top_left = r
	s.corner_radius_top_right = r
	s.corner_radius_bottom_right = r
	s.corner_radius_bottom_left = r
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", s)
	p.custom_minimum_size = Vector2(size, size)
	return p

func _build_center_area():
	var center = Control.new()
	center.anchor_top = 0.0
	center.anchor_bottom = 1.0
	center.anchor_left = 0.0
	center.anchor_right = 1.0
	center.offset_top = 250
	center.offset_bottom = 110
	add_child(center)

	var main_hbox = _make_hbox(24)
	main_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_hbox.offset_left = 60
	main_hbox.offset_right = -60

	var hero = _make_vbox(16)
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(hero)

	var welcome_style = _make_style(Color(0x0B / 255.0, 0x05 / 255.0, 0x14 / 255.0, 0.53), Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0, 0.25), 4)
	welcome_style.content_margin_left = 12
	welcome_style.content_margin_top = 8
	welcome_style.content_margin_bottom = 8
	var welcome = _make_panel(welcome_style)
	var welcome_hbox = _make_hbox(8, BoxContainer.ALIGNMENT_BEGIN)
	var wicon = _make_icon("res://addons/at-icons/control/stars.svg", 11, Color(0xFB / 255.0, 0xBF / 255.0, 0x24 / 255.0))
	welcome_hbox.add_child(wicon)
	var wlabel = _make_label("BEM-VINDO DE VOLTA, TREINADOR", ThemeConfig.FONT_INTER, 10, Color(0xFB / 255.0, 0xBF / 255.0, 0x24 / 255.0), {"letter_spacing": 2})
	welcome_hbox.add_child(wlabel)
	welcome.add_child(welcome_hbox)
	hero.add_child(welcome)

	var big_title = _make_label("Construa sua dinastia.", ThemeConfig.FONT_INTER_BLACK, 56, Color.WHITE, {"letter_spacing": -1, "line_spacing": -2})
	big_title.text = "Construa sua\ndinastia."
	big_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	big_title.custom_minimum_size = Vector2(620, 0)
	hero.add_child(big_title)

	var subtitle = _make_label("Vença campeonatos, descubra talentos e escreva sua história na maior liga de basquete simulado.", ThemeConfig.FONT_INTER, 14, Color(0x94 / 255.0, 0xA3 / 255.0, 0xB8 / 255.0), {"line_spacing": 1})
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size = Vector2(540, 0)
	hero.add_child(subtitle)

	var stats_hbox = _make_hbox(24)
	var has_league = not GameManager.league.is_empty()
	var season = GameManager.league.get("season", 0)
	var team = GameManager.get_user_team() if has_league else {}
	var team_wins = team.get("wins", 0) if has_league else 0
	var team_losses = team.get("losses", 0) if has_league else 0
	var team_id = team.get("id", 0) if has_league else 0
	var season_label = str(max(1, season - 2024)) if has_league else "-"
	var games_label = str(team_wins + team_losses) if has_league else "-"
	var wins_label = str(team_wins) if has_league else "-"
	var rank_label = _get_team_rank(team_id) if has_league else "-"
	var hero_stat_defs = [
		["TEMPORADAS", season_label, Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0)],
		["JOGOS", games_label, Color(0xFB / 255.0, 0xBF / 255.0, 0x24 / 255.0)],
		["VITÓRIAS", wins_label, Color(0x60 / 255.0, 0xA5 / 255.0, 0xFA / 255.0)],
		["POSIÇÃO", rank_label, Color(0x10 / 255.0, 0xB9 / 255.0, 0x81 / 255.0)],
	]
	for sd in hero_stat_defs:
		var svbox = _make_vbox(2)
		var slabel = _make_label(sd[0], ThemeConfig.FONT_INTER, 9, Color(0x6B / 255.0, 0x5B / 255.0, 0x95 / 255.0), {"letter_spacing": 1.5})
		svbox.add_child(slabel)
		var vlabel = _make_label(sd[1], ThemeConfig.FONT_INTER_BLACK, 22, sd[2])
		svbox.add_child(vlabel)
		stats_hbox.add_child(svbox)
	var stats_margin = _make_margin(12, 0, 0, 0)
	stats_margin.add_child(stats_hbox)
	hero.add_child(stats_margin)

	var right_panel = _make_vbox(14)
	right_panel.custom_minimum_size = Vector2(480, 0)

	if GameManager.has_save():
		right_panel.add_child(_build_continue_card())
	else:
		var filler = ColorRect.new()
		filler.color = Color.TRANSPARENT
		filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
		right_panel.add_child(filler)

	right_panel.add_child(_build_menu_grid())

	main_hbox.add_child(right_panel)
	center.add_child(main_hbox)

func _build_continue_card() -> PanelContainer:
	var team = GameManager.get_user_team()
	var coach = GameManager.get_coach()
	if team.is_empty() or coach.is_empty():
		return _build_continue_card_static()

	var save_time = _get_save_time_string()
	var abbr = team.get("abbreviation", "PH")
	var badge_initials = abbr.substr(0, 2)
	var city = team.get("city", "")
	var name = team.get("name", "")
	var team_full_name = city + " " + name
	var coach_name_str = coach.get("name", "Treinador")
	var wins = team.get("wins", 0)
	var losses = team.get("losses", 0)
	var record_str = str(wins) + "–" + str(losses)
	var rank_str = _get_team_rank(team.get("id", 0))
	var budget_str = _get_team_budget(team)
	var next_info = _get_next_match_info()
	var next_opponent = next_info.get("opponent", "")
	var next_is_home = next_info.get("is_home", true)
	var next_comp = next_info.get("competition", "LIGA")
	var next_text = "Próximo: "

	if next_opponent.is_empty():
		next_text = "Nenhum jogo agendado"
	else:
		next_text += next_opponent + " (" + ("C" if next_is_home else "F") + ")"

	var record_color = Color(0x10 / 255.0, 0xB9 / 255.0, 0x81 / 255.0)
	var rank_color = Color(0x60 / 255.0, 0xA5 / 255.0, 0xFA / 255.0)
	var budget_color = Color(0xFB / 255.0, 0xBF / 255.0, 0x24 / 255.0)

	var cc_bg = Color(0x2A / 255.0, 0x1A / 255.0, 0x4E / 255.0, 0.80)
	var cc_border = Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0)

	var card_style = _make_style(cc_bg, cc_border, 12)
	card_style.shadow_color = Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0, 0.13)
	card_style.shadow_size = 32
	card_style.content_margin_left = 20
	card_style.content_margin_right = 20

	var card = _make_panel(card_style)
	var card_vbox = _make_vbox(0)
	card.add_child(card_vbox)

	var header = _make_hbox(8, BoxContainer.ALIGNMENT_CENTER)
	header.add_theme_constant_override("separation", 8)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var logo_small = _make_icon("res://addons/at-icons/control/basketball.svg", 16, Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0))
	var logo_small_container = _make_panel(_make_style(Color.TRANSPARENT))
	logo_small_container.add_child(logo_small)
	header.add_child(logo_small_container)

	var header_lbl = _make_label(save_time, ThemeConfig.FONT_INTER, 9, Color(0x6B / 255.0, 0x5B / 255.0, 0x95 / 255.0), {"letter_spacing": 1})
	header.add_child(header_lbl)

	var header_spacer = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)

	var header_line = ColorRect.new()
	header_line.color = Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0, 0.13)
	header_line.custom_minimum_size = Vector2(0, 1)
	header_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var header_margin = _make_margin(0, 16, 0, 8)
	header_margin.add_child(_make_vbox(0))
	header_margin.get_child(0).add_child(header)
	header_margin.get_child(0).add_child(header_line)
	card_vbox.add_child(header_margin)

	var body = _make_hbox(16)
	var team_badge_style = _make_style(Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0), Color(0x5B / 255.0, 0x21 / 255.0, 0xB6 / 255.0), 50)
	team_badge_style.shadow_color = Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0, 0.4)
	team_badge_style.shadow_size = 20
	var badge = _make_panel(team_badge_style, Vector2(72, 72))
	var badge_lbl = _make_label(badge_initials, ThemeConfig.FONT_INTER_BLACK, 24, Color.WHITE)
	badge_lbl.set_anchors_preset(Control.PRESET_CENTER)
	badge.add_child(badge_lbl)
	body.add_child(badge)

	var info_vbox = _make_vbox(4)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var team_name = _make_label(team_full_name, ThemeConfig.FONT_INTER_BOLD, 18, Color.WHITE)
	info_vbox.add_child(team_name)
	var coach_lbl = _make_label(coach_name_str, ThemeConfig.FONT_INTER, 12, Color(0x94 / 255.0, 0xA3 / 255.0, 0xB8 / 255.0))
	info_vbox.add_child(coach_lbl)
	body.add_child(info_vbox)

	var body_margin = _make_margin(0, 18, 0, 20)
	body_margin.add_child(body)
	card_vbox.add_child(body_margin)

	var stats_row_style = _make_style(Color(0.04, 0.02, 0.08, 0.69))
	stats_row_style.content_margin_left = 12
	stats_row_style.content_margin_right = 12
	stats_row_style.content_margin_top = 8
	stats_row_style.content_margin_bottom = 8
	var stats_panel = _make_panel(stats_row_style)
	var stats_hbox = _make_hbox(16)
	var stat_defs = [
		["RECORD", record_str, record_color],
		["POSIÇÃO", rank_str, rank_color],
		["ORÇAMENTO", budget_str, budget_color],
	]
	for sd in stat_defs:
		var svbox = _make_vbox(2)
		svbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var slabel = _make_label(sd[0], ThemeConfig.FONT_INTER, 9, Color(0x6B / 255.0, 0x5B / 255.0, 0x95 / 255.0), {"letter_spacing": 1.5})
		svbox.add_child(slabel)
		var vlabel = _make_label(sd[1], ThemeConfig.FONT_INTER_BLACK, 18, sd[2])
		svbox.add_child(vlabel)
		var svbox_margin = _make_margin(4, 2, 4, 2)
		svbox_margin.add_child(svbox)
		stats_hbox.add_child(svbox_margin)
	stats_panel.add_child(stats_hbox)
	var stats_margin = _make_margin(0, 12, 0, 12)
	stats_margin.add_child(stats_panel)
	card_vbox.add_child(stats_margin)

	var next_row = _make_hbox(8, BoxContainer.ALIGNMENT_CENTER)
	var nicon = _make_icon("res://addons/at-icons/control/calendar.svg", 14, Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0))
	next_row.add_child(nicon)
	var next_lbl = _make_label(next_text, ThemeConfig.FONT_INTER, 11, Color(0x94 / 255.0, 0xA3 / 255.0, 0xB8 / 255.0))
	next_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_row.add_child(next_lbl)
	var comp_badge = _make_panel(_make_style(Color(0x23 / 255.0, 0x52 / 255.0, 0x86 / 255.0, 0.13), Color(0x60 / 255.0, 0xA5 / 255.0, 0xFA / 255.0, 0.38), 4))
	var comp_lbl = _make_label(next_comp, ThemeConfig.FONT_INTER, 9, Color(0x60 / 255.0, 0xA5 / 255.0, 0xFA / 255.0))
	comp_badge.add_child(comp_lbl)
	next_row.add_child(comp_badge)
	var next_margin = _make_margin(0, 0, 0, 12)
	next_margin.add_child(next_row)
	card_vbox.add_child(next_margin)

	var continue_btn = Button.new()
	continue_btn.text = "CONTINUAR CARREIRA"
	continue_btn.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
	continue_btn.add_theme_font_size_override("font_size", 14)
	continue_btn.add_theme_color_override("font_color", Color.WHITE)
	continue_btn.add_theme_constant_override("letter_spacing", 2)
	continue_btn.custom_minimum_size = Vector2(0, 52)
	continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var btn_bg = Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0)
	var btn_style = _make_style(btn_bg, Color.TRANSPARENT, 6)
	btn_style.shadow_color = Color(0xFF / 255.0, 0xFF / 255.0, 0xFF / 255.0, 0.13)
	btn_style.shadow_size = 10
	btn_style.shadow_offset = Vector2(0, 1)
	continue_btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0x7C / 255.0, 0x3A / 255.0, 0xED / 255.0)
	continue_btn.add_theme_stylebox_override("hover", btn_hover)
	continue_btn.add_theme_stylebox_override("pressed", btn_style)
	continue_btn.pressed.connect(func():
		_show_loading(continue_btn)
		await get_tree().process_frame
		await get_tree().process_frame
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	var btn_margin = _make_margin(0, 0, 0, 20)
	btn_margin.add_child(continue_btn)
	card_vbox.add_child(btn_margin)

	return card

func _build_continue_card_static() -> PanelContainer:
	var cc_bg = Color(0x2A / 255.0, 0x1A / 255.0, 0x4E / 255.0, 0.80)
	var cc_border = Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0)
	var card_style = _make_style(cc_bg, cc_border, 12)
	card_style.shadow_color = Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0, 0.13)
	card_style.shadow_size = 32
	card_style.content_margin_left = 20
	card_style.content_margin_right = 20
	var card = _make_panel(card_style)
	var card_vbox = _make_vbox(0)
	card.add_child(card_vbox)

	var header = _make_hbox(8, BoxContainer.ALIGNMENT_CENTER)
	header.add_theme_constant_override("separation", 8)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var logo_small = _make_icon("res://addons/at-icons/control/basketball.svg", 16, Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0))
	var logo_small_container = _make_panel(_make_style(Color.TRANSPARENT))
	logo_small_container.add_child(logo_small)
	header.add_child(logo_small_container)
	var header_lbl = _make_label("SALVO", ThemeConfig.FONT_INTER, 9, Color(0x6B / 255.0, 0x5B / 255.0, 0x95 / 255.0), {"letter_spacing": 1})
	header.add_child(header_lbl)
	var header_spacer = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	var header_line = ColorRect.new()
	header_line.color = Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0, 0.13)
	header_line.custom_minimum_size = Vector2(0, 1)
	header_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var header_margin = _make_margin(0, 16, 0, 8)
	header_margin.add_child(_make_vbox(0))
	header_margin.get_child(0).add_child(header)
	header_margin.get_child(0).add_child(header_line)
	card_vbox.add_child(header_margin)

	var body = _make_hbox(16)
	var team_badge_style = _make_style(Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0), Color(0x5B / 255.0, 0x21 / 255.0, 0xB6 / 255.0), 50)
	team_badge_style.shadow_color = Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0, 0.4)
	team_badge_style.shadow_size = 20
	var badge = _make_panel(team_badge_style, Vector2(72, 72))
	var badge_lbl = _make_label("--", ThemeConfig.FONT_INTER_BLACK, 24, Color.WHITE)
	badge_lbl.set_anchors_preset(Control.PRESET_CENTER)
	badge.add_child(badge_lbl)
	body.add_child(badge)
	var info_vbox = _make_vbox(4)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var team_name = _make_label("Carreira", ThemeConfig.FONT_INTER_BOLD, 18, Color.WHITE)
	info_vbox.add_child(team_name)
	var coach_lbl = _make_label("Treinador", ThemeConfig.FONT_INTER, 12, Color(0x94 / 255.0, 0xA3 / 255.0, 0xB8 / 255.0))
	info_vbox.add_child(coach_lbl)
	body.add_child(info_vbox)
	var body_margin = _make_margin(0, 18, 0, 20)
	body_margin.add_child(body)
	card_vbox.add_child(body_margin)

	var continue_btn = Button.new()
	continue_btn.text = "CONTINUAR CARREIRA"
	continue_btn.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
	continue_btn.add_theme_font_size_override("font_size", 14)
	continue_btn.add_theme_color_override("font_color", Color.WHITE)
	continue_btn.add_theme_constant_override("letter_spacing", 2)
	continue_btn.custom_minimum_size = Vector2(0, 52)
	continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var btn_bg = Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0)
	var btn_style = _make_style(btn_bg, Color.TRANSPARENT, 6)
	btn_style.shadow_color = Color(0xFF / 255.0, 0xFF / 255.0, 0xFF / 255.0, 0.13)
	btn_style.shadow_size = 10
	btn_style.shadow_offset = Vector2(0, 1)
	continue_btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0x7C / 255.0, 0x3A / 255.0, 0xED / 255.0)
	continue_btn.add_theme_stylebox_override("hover", btn_hover)
	continue_btn.add_theme_stylebox_override("pressed", btn_style)
	continue_btn.pressed.connect(func():
		_show_loading(continue_btn)
		await get_tree().process_frame
		await get_tree().process_frame
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	var btn_margin = _make_margin(0, 0, 0, 20)
	btn_margin.add_child(continue_btn)
	card_vbox.add_child(btn_margin)

	return card

func _build_menu_grid() -> VBoxContainer:
	var grid = _make_vbox(8)
	var rows_defs = [
		[
			["NOVA CARREIRA", true],
			["CARREGAR JOGO", false],
		],
		[
			["MODO ONLINE", false],
			["CONQUISTAS", false],
		],
	]
	for row_def in rows_defs:
		var row = _make_hbox(8)
		for btn_def in row_def:
			var btn = _build_menu_btn(btn_def[0], btn_def[1])
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(btn)
		grid.add_child(row)
	return grid

func _build_menu_btn(txt: String, primary: bool) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_constant_override("letter_spacing", 1)
	btn.custom_minimum_size = Vector2(0, 48)

	var bg = Color(0x0B / 255.0, 0x05 / 255.0, 0x14 / 255.0, 0.53)
	var border = Color(0x2D / 255.0, 0x1B / 255.0, 0x4E / 255.0, 1)
	var style = _make_style(bg, border, 8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = Color(0x15 / 255.0, 0x08 / 255.0, 0x26 / 255.0, 0.7)
	hover.border_color = Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0, 0.4)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", style)

	if primary:
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.pressed.connect(func():
			GameManager.league.clear()
			get_tree().change_scene_to_file("res://scenes/new_game.tscn")
		)
	else:
		btn.add_theme_color_override("font_color", Color(0x94 / 255.0, 0xA3 / 255.0, 0xB8 / 255.0))
		btn.add_theme_color_override("font_hover_color", Color(0xE0 / 255.0, 0xE7 / 255.0, 0xFF / 255.0))
		btn.disabled = true

	return btn

func _build_news_ticker():
	var ticker = Control.new()
	ticker.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ticker.offset_top = -44
	ticker.offset_bottom = 0
	add_child(ticker)

	var ticker_bg = _make_style(Color(0x0B / 255.0, 0x05 / 255.0, 0x14 / 255.0, 0.53), Color(0x2D / 255.0, 0x1B / 255.0, 0x4E / 255.0), 8)
	ticker_bg.content_margin_left = 12
	ticker_bg.content_margin_top = 12
	ticker_bg.content_margin_right = 12
	ticker_bg.content_margin_bottom = 12
	var ticker_panel = _make_panel(ticker_bg)
	ticker_panel.anchor_left = 0
	ticker_panel.offset_left = 60
	ticker_panel.anchor_right = 0
	ticker_panel.offset_right = 860

	var ticker_hbox = _make_hbox(14, BoxContainer.ALIGNMENT_CENTER)
	ticker_panel.add_child(ticker_hbox)

	var live_style = _make_style(Color(0xEF / 255.0, 0x44 / 255.0, 0x44 / 255.0))
	var live = _make_panel(live_style)
	live.custom_minimum_size = Vector2.ZERO
	var live_hbox = _make_hbox(4, BoxContainer.ALIGNMENT_CENTER)
	var ldot = ColorRect.new()
	ldot.color = Color.WHITE
	ldot.custom_minimum_size = Vector2(5, 5)
	ldot.size = Vector2(5, 5)
	live_hbox.add_child(ldot)
	var llbl = _make_label("AO VIVO", ThemeConfig.FONT_INTER, 9, Color.WHITE, {"letter_spacing": 1})
	live_hbox.add_child(llbl)
	live.add_child(live_hbox)
	ticker_hbox.add_child(live)

	var nicon = _make_icon("res://addons/at-icons/control/file.svg", 14, Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0))
	ticker_hbox.add_child(nicon)

	var ticker_text = _make_label("Liga 2026 começa em 3 dias · Update 1.2 disponível · Canguru RJ contratam armador estrela · Patrocínio Nike renovado", ThemeConfig.FONT_INTER, 11, Color(0xE0 / 255.0, 0xE7 / 255.0, 0xFF / 255.0))
	ticker_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ticker_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	ticker_text.text_overrun_behavior = TextServer.OVERRUN_NO_TRIM
	ticker_hbox.add_child(ticker_text)

	ticker.add_child(ticker_panel)

func _build_bottom_right():
	var bottom = Control.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -44
	bottom.offset_bottom = 0
	add_child(bottom)

	var hbox = _make_hbox(8, BoxContainer.ALIGNMENT_CENTER)
	hbox.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	hbox.offset_left = 860
	hbox.offset_right = -60

	var social_hbox = _make_hbox(6)
	var social_icons = ["bell", "cog", "headphones"]
	for sname in social_icons:
		var icon = _make_icon("res://addons/at-icons/control/" + sname + ".svg", 15, Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0))
		var container = _make_panel(_make_style(Color(0x0B / 255.0, 0x05 / 255.0, 0x14 / 255.0, 0.53), Color(0x2D / 255.0, 0x1B / 255.0, 0x4E / 255.0), 50))
		container.custom_minimum_size = Vector2(36, 36)
		icon.position = Vector2(10, 10)
		container.add_child(icon)
		social_hbox.add_child(container)
	hbox.add_child(social_hbox)

	var div = ColorRect.new()
	div.color = Color(0x2D / 255.0, 0x1B / 255.0, 0x4E / 255.0)
	div.custom_minimum_size = Vector2(1, 24)
	hbox.add_child(div)

	var settings_hbox = _make_hbox(6)
	var settings_items = [
		["PERFIL", "human"],
		["SAIR", "arrow_right_from_bracket"],
	]
	for si in settings_items:
		var sbtn = _make_panel(_make_style(Color(0x0B / 255.0, 0x05 / 255.0, 0x14 / 255.0, 0.53), Color(0x2D / 255.0, 0x1B / 255.0, 0x4E / 255.0), 6))
		var sbtn_hbox = _make_hbox(6, BoxContainer.ALIGNMENT_CENTER)
		var sicon = _make_icon("res://addons/at-icons/control/" + si[1] + ".svg", 12, Color(0x94 / 255.0, 0xA3 / 255.0, 0xB8 / 255.0))
		sbtn_hbox.add_child(sicon)
		var slbl = _make_label(si[0], ThemeConfig.FONT_INTER, 10, Color(0x94 / 255.0, 0xA3 / 255.0, 0xB8 / 255.0), {"letter_spacing": 0.5})
		sbtn_hbox.add_child(slbl)
		sbtn.add_child(sbtn_hbox)
		settings_hbox.add_child(sbtn)
	hbox.add_child(settings_hbox)

	bottom.add_child(hbox)

func _show_loading(btn: Button):
	var load_bg = ColorRect.new()
	load_bg.color = Color(0.05, 0.05, 0.08, 0.9)
	load_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_parent().add_child(load_bg)

	var load_lbl = Label.new()
	load_lbl.text = "LOADING DATABASE..."
	load_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	load_lbl.add_theme_font_size_override("font_size", 24)
	load_lbl.add_theme_color_override("font_color", Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0))
	load_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	load_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	load_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	load_bg.add_child(load_lbl)

func _get_save_time_string() -> String:
	var path = GameManager.get_save_path()
	if not FileAccess.file_exists(path):
		return "SALVO"
	var mod_time = FileAccess.get_modified_time(path)
	var diff = Time.get_unix_time_from_system() - mod_time
	if diff < 60:
		return "SALVO HÁ SEGUNDOS"
	if diff < 3600:
		return "SALVO HÁ " + str(floor(diff / 60)) + " MIN"
	if diff < 86400:
		return "SALVO HÁ " + str(floor(diff / 3600)) + " H"
	return "SALVO HÁ " + str(floor(diff / 86400)) + " DIAS"

func _get_team_rank(team_id: int) -> String:
	var teams = GameManager.league.get("teams", [])
	if teams.is_empty():
		return "-"
	var sorted = teams.duplicate()
	sorted.sort_custom(func(a, b): return (a.get("wins", 0) - a.get("losses", 0)) > (b.get("wins", 0) - b.get("losses", 0)))
	for i in sorted.size():
		if sorted[i].get("id", -1) == team_id:
			return str(i + 1) + "º LUGAR"
	return "-"

func _get_next_match_info() -> Dictionary:
	var next = EventManager.get_next_match()
	if next.is_empty():
		return {}
	var league_teams = GameManager.league.get("teams", [])
	var opponent_id = next.get("home_team_id", 0)
	if opponent_id == GameManager.user_team_id:
		opponent_id = next.get("away_team_id", 0)
	var opponent_name = ""
	for t in league_teams:
		if t.get("id", 0) == opponent_id:
			opponent_name = t.get("city", "") + " " + t.get("name", "")
			break
	var is_home = next.get("home_team_id", 0) == GameManager.user_team_id
	return {
		"opponent": opponent_name,
		"is_home": is_home,
		"phase": next.get("phase_label", "LIGA"),
		"competition": "LIGA",
	}

func _get_team_budget(team: Dictionary) -> String:
	var total_salary = 0.0
	for p in team.get("players", []):
		total_salary += p.get("salary", 0)
	var remaining = 150_000_000.0 - total_salary
	if remaining < 0:
		remaining = 0
	if remaining >= 1_000_000:
		return "R$ " + str(ceil(remaining / 100_000) / 10) + "M"
	return "R$ " + str(remaining)
