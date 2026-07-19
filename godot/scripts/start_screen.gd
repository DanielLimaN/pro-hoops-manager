extends Control

func _ready():
	if GameManager.has_save() and GameManager.league.is_empty():
		GameManager.load_career()
	_populate_top_bar()
	_populate_hero_welcome()
	_populate_hero_title()
	_populate_hero_subtitle()
	_populate_hero_stats()
	_populate_continue_card()
	_populate_menu_grid()
	_populate_news_ticker()
	_populate_bottom_right()


# =============================================================================
#  HELPERS
# =============================================================================

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


# =============================================================================
#  TOP BAR
# =============================================================================

func _populate_top_bar():
	# Update version label text — the rest of the TopBar is fully defined in the scene
	$"TopBar/TopBarHBox/TopRightWrap/VersionPanel/VersionHBox/VersionLabel".text = "v1.0.0 · ONLINE"


# =============================================================================
#  HERO SECTION
# =============================================================================

func _populate_hero_welcome():
	# Apply the welcome badge style over the scene's panel
	var welcome = get_node_or_null("CenterArea/MainHBox/HeroSection/HeroWelcomeWrapper/HeroWelcome")
	if welcome == null:
		welcome = get_node_or_null("CenterArea/MainHBox/HeroSection/HeroWelcome")
	if welcome == null:
		return
		
	var style := _make_style(
		Color(0x0B / 255.0, 0x05 / 255.0, 0x14 / 255.0, 0.53),
		Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0, 0.25),
		4
	)
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	welcome.add_theme_stylebox_override("panel", style)


func _populate_hero_title():
	# Scene already has the correct text and font overrides; nothing to do.
	pass


func _populate_hero_subtitle():
	# Scene already has the correct text and font overrides; nothing to do.
	pass


func _populate_hero_stats():
	# Populate the four stat values from saved league data or show dashes.
	var has_league := not GameManager.league.is_empty()
	var season: int = GameManager.league.get("season", 0)
	var team := GameManager.get_user_team() if has_league else {}
	var team_wins: int = team.get("wins", 0) if has_league else 0
	var team_losses: int = team.get("losses", 0) if has_league else 0
	var team_id: int = team.get("id", 0) if has_league else 0

	$"CenterArea/MainHBox/HeroSection/HeroStats/StatTempVBox/StatTempValue".text = \
		str(max(1, season - 2024)) if has_league else "-"
	$"CenterArea/MainHBox/HeroSection/HeroStats/StatGamesVBox/StatGamesValue".text = \
		str(team_wins + team_losses) if has_league else "-"
	$"CenterArea/MainHBox/HeroSection/HeroStats/StatWinsVBox/StatWinsValue".text = \
		str(team_wins) if has_league else "-"
	$"CenterArea/MainHBox/HeroSection/HeroStats/StatPosVBox/StatPosValue".text = \
		_get_team_rank(team_id) if has_league else "-"


# =============================================================================
#  CONTINUE CARD
# =============================================================================

func _populate_continue_card():
	var card := $"CenterArea/MainHBox/RightPanel/ContinueCard"

	if not GameManager.has_save():
		card.visible = false
		return

	card.visible = true

	var team := GameManager.get_user_team()
	var coach := GameManager.get_coach()

	if team.is_empty() or coach.is_empty():
		# Save exists but data not fully loaded yet
		$"CenterArea/MainHBox/RightPanel/ContinueCard/CardPanel/CardVBox/CardHeaderWrap/CardHeaderVBox/CardHeaderHBox/CardHeaderTime".text = "SALVO"
		_connect_continue_button()
		return

	# Gather all dynamic data
	var save_time := _get_save_time_string()
	var abbr: String = team.get("abbreviation", "PH")
	var badge_initials: String = abbr.substr(0, 2)
	var coach_name_str: String = coach.get("name", "Treinador")
	var wins: int = team.get("wins", 0)
	var losses: int = team.get("losses", 0)
	var record_str := str(wins) + "\u2013" + str(losses)
	var rank_str := _get_team_rank(team.get("id", 0))
	var budget_str := _get_team_budget(team)
	var next_info := _get_next_match_info()
	var next_opponent: String = next_info.get("opponent", "")
	var next_comp: String = next_info.get("competition", "LIGA")

	var next_text := "Nenhum jogo agendado"
	if not next_opponent.is_empty():
		var is_home_local: bool = next_info.get("is_home", true)
		next_text = next_opponent + " (" + ("C" if is_home_local else "F") + ")"

	var season: int = GameManager.league.get("season", 2025)
	var season_str := "Temporada " + str(season)
	var week_str := "Semana " + str(GameManager.league.get("week", 1))

	# ── Update existing scene nodes ──────────────────────────────────────────

	# Header
	$"CenterArea/MainHBox/RightPanel/ContinueCard/CardPanel/CardVBox/CardHeaderWrap/CardHeaderVBox/CardHeaderHBox/CardHeaderTime".text = save_time

	# Body
	var card_badge_panel = $"CenterArea/MainHBox/RightPanel/ContinueCard/CardPanel/CardVBox/CardBodyWrap/CardBodyHBox/CardBadge"
	var card_badge_lbl = $"CenterArea/MainHBox/RightPanel/ContinueCard/CardPanel/CardVBox/CardBodyWrap/CardBodyHBox/CardBadge/CardBadgeLabel"
	
	card_badge_lbl.text = badge_initials
	var shield_path = "res://assets/teams/%s.png" % abbr.to_lower()
	if ResourceLoader.exists(shield_path):
		card_badge_lbl.hide()
		var tex_rect = card_badge_panel.get_node_or_null("TeamShield")
		if not tex_rect:
			tex_rect = TextureRect.new()
			tex_rect.name = "TeamShield"
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			
			# Margens negativas para o escudo "vazar" e ficar consideravelmente maior
			var expand_margin = 15.0
			tex_rect.offset_left = -expand_margin
			tex_rect.offset_top = -expand_margin
			tex_rect.offset_right = expand_margin
			tex_rect.offset_bottom = expand_margin
			
			card_badge_panel.add_child(tex_rect)
		
		tex_rect.texture = load(shield_path)
		tex_rect.show()
		var sty = card_badge_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if sty:
			sty.bg_color = Color(0,0,0,0)
			sty.border_width_left = 0
			sty.border_width_right = 0
			sty.border_width_top = 0
			sty.border_width_bottom = 0
			sty.shadow_size = 0
			card_badge_panel.add_theme_stylebox_override("panel", sty)
	else:
		card_badge_lbl.show()
		var tex_rect = card_badge_panel.get_node_or_null("TeamShield")
		if tex_rect: tex_rect.hide()

	$"CenterArea/MainHBox/RightPanel/ContinueCard/CardPanel/CardVBox/CardBodyWrap/CardBodyHBox/CardInfoVBox/CardInfoTag".text = abbr + " \u00b7 CONFER\u00caNCIA SUL"
	$"CenterArea/MainHBox/RightPanel/ContinueCard/CardPanel/CardVBox/CardBodyWrap/CardBodyHBox/CardInfoVBox/CardInfoName".text = coach_name_str
	$"CenterArea/MainHBox/RightPanel/ContinueCard/CardPanel/CardVBox/CardBodyWrap/CardBodyHBox/CardInfoVBox/CardInfoSeasonHBox/CardInfoSeason".text = season_str
	$"CenterArea/MainHBox/RightPanel/ContinueCard/CardPanel/CardVBox/CardBodyWrap/CardBodyHBox/CardInfoVBox/CardInfoSeasonHBox/CardInfoWeek".text = week_str

	# Stats row
	$"CenterArea/MainHBox/RightPanel/ContinueCard/CardPanel/CardVBox/CardStatsPanel/CardStatsHBox/StatRecordVBox/StatRecordValue".text = record_str
	$"CenterArea/MainHBox/RightPanel/ContinueCard/CardPanel/CardVBox/CardStatsPanel/CardStatsHBox/StatRankVBox/StatRankValue".text = rank_str
	$"CenterArea/MainHBox/RightPanel/ContinueCard/CardPanel/CardVBox/CardStatsPanel/CardStatsHBox/StatBudgetVBox/StatBudgetValue".text = budget_str

	# Next match
	$"CenterArea/MainHBox/RightPanel/ContinueCard/CardPanel/CardVBox/CardNextWrap/CardNextVBox/CardNextHBox/CardNextTextVBox/CardNextMatch".text = next_text
	$"CenterArea/MainHBox/RightPanel/ContinueCard/CardPanel/CardVBox/CardNextWrap/CardNextVBox/CardNextHBox/CardNextCompBadge/CardNextCompLabel".text = next_comp

	# Continue button
	_connect_continue_button()


func _connect_continue_button() -> void:
	var btn = get_node_or_null("CenterArea/MainHBox/RightPanel/ContinueCard/CardPanel/CardVBox/CardBtnMargin/CardBtnWrap")
	if btn == null:
		btn = get_node_or_null("CenterArea/MainHBox/RightPanel/ContinueCard/CardPanel/CardVBox/CardBtnWrap")
	if btn == null:
		return
	if not btn.gui_input.is_connected(_on_continue_button_click):
		btn.gui_input.connect(_on_continue_button_click)


func _on_continue_button_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_loading()
		await get_tree().process_frame
		await get_tree().process_frame
		get_tree().change_scene_to_file("res://scenes/main.tscn")


# =============================================================================
#  MENU GRID
# =============================================================================

func _populate_menu_grid():
	var has_save := GameManager.has_save()

	# ── Nova Carreira — always enabled ──
	var new_career := $"CenterArea/MainHBox/RightPanel/MenuGrid/MenuRow1/MenuItemNewCareer"
	_setup_menu_item_hover(new_career)
	if not new_career.gui_input.is_connected(_on_new_career_click):
		new_career.gui_input.connect(_on_new_career_click)

	# ── Carregar Jogo — enabled only if a save exists ──
	var load_game := $"CenterArea/MainHBox/RightPanel/MenuGrid/MenuRow1/MenuItemLoadGame"
	if has_save:
		load_game.modulate = Color.WHITE
		$"CenterArea/MainHBox/RightPanel/MenuGrid/MenuRow1/MenuItemLoadGame/ItemLGHBox/ItemLGTextVBox/ItemLGTitle".add_theme_color_override("font_color", Color.WHITE)
		$"CenterArea/MainHBox/RightPanel/MenuGrid/MenuRow1/MenuItemLoadGame/ItemLGHBox/ItemLGTextVBox/ItemLGDesc".text = "5 saves dispon\u00edveis"
		_setup_menu_item_hover(load_game)
		if not load_game.gui_input.is_connected(_on_load_game_click):
			load_game.gui_input.connect(_on_load_game_click)


func _setup_menu_item_hover(item: PanelContainer) -> void:
	var style := item.get_theme_stylebox("panel")
	if style == null:
		return

	var hover_style: StyleBoxFlat
	if style is StyleBoxFlat:
		hover_style = style.duplicate() as StyleBoxFlat
		hover_style.bg_color = Color(0x15 / 255.0, 0x08 / 255.0, 0x26 / 255.0, 0xB3 / 255.0)
		hover_style.border_color = Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0, 0x66 / 255.0)
	else:
		# Fallback: create a fresh hover style
		hover_style = _make_hover_style(
			Color(0x15 / 255.0, 0x08 / 255.0, 0x26 / 255.0, 0xB3 / 255.0),
			Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0, 0x66 / 255.0),
			8
		)
		hover_style.content_margin_left = 12
		hover_style.content_margin_top = 12
		hover_style.content_margin_right = 12
		hover_style.content_margin_bottom = 12

	# Avoid duplicate signal connections from repeated calls
	if not item.mouse_entered.is_connected(_on_hover_enter.bind(item, hover_style)):
		item.mouse_entered.connect(_on_hover_enter.bind(item, hover_style))
	if not item.mouse_exited.is_connected(_on_hover_exit.bind(item, style)):
		item.mouse_exited.connect(_on_hover_exit.bind(item, style))


func _on_hover_enter(item: PanelContainer, hover_style: StyleBoxFlat) -> void:
	item.add_theme_stylebox_override("panel", hover_style)


func _on_hover_exit(item: PanelContainer, normal_style: StyleBoxFlat) -> void:
	item.add_theme_stylebox_override("panel", normal_style)


func _on_new_career_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GameManager.league.clear()
		get_tree().change_scene_to_file("res://scenes/new_game.tscn")


func _on_load_game_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_loading()
		await get_tree().process_frame
		await get_tree().process_frame
		get_tree().change_scene_to_file("res://scenes/main.tscn")


# =============================================================================
#  NEWS TICKER
# =============================================================================

func _populate_news_ticker():
	# Scene already has all the news ticker content; no runtime changes needed.
	pass


# =============================================================================
#  BOTTOM RIGHT
# =============================================================================

func _populate_bottom_right():
	# Scene already has all bottom-right icons and labels; no runtime changes needed.
	pass


# =============================================================================
#  LOADING OVERLAY
# =============================================================================

func _show_loading() -> void:
	var load_bg := ColorRect.new()
	load_bg.color = Color(0.05, 0.05, 0.08, 0.9)
	load_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_parent().add_child(load_bg)

	var load_lbl := Label.new()
	load_lbl.text = "LOADING DATABASE..."
	load_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	load_lbl.add_theme_font_size_override("font_size", 24)
	load_lbl.add_theme_color_override("font_color", Color(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0))
	load_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	load_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	load_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	load_bg.add_child(load_lbl)


# =============================================================================
#  DATA HELPERS
# =============================================================================

func _get_save_time_string() -> String:
	var path := GameManager.get_save_path()
	if not FileAccess.file_exists(path):
		return "SALVO"
	var mod_time := FileAccess.get_modified_time(path)
	var diff := Time.get_unix_time_from_system() - mod_time
	if diff < 60:
		return "SALVO H\u00c1 SEGUNDOS"
	if diff < 3600:
		return "SALVO H\u00c1 " + str(floor(diff / 60)) + " MIN"
	if diff < 86400:
		return "SALVO H\u00c1 " + str(floor(diff / 3600)) + " H"
	return "SALVO H\u00c1 " + str(floor(diff / 86400)) + " DIAS"


func _get_team_rank(team_id: int) -> String:
	var teams: Array = GameManager.league.get("teams", [])
	if teams.is_empty():
		return "-"
	var sorted: Array = teams.duplicate()
	sorted.sort_custom(func(a, b): return (a.get("wins", 0) - a.get("losses", 0)) > (b.get("wins", 0) - b.get("losses", 0)))
	for i in sorted.size():
		if sorted[i].get("id", -1) == team_id:
			return str(i + 1) + "\u00ba LUGAR"
	return "-"


func _get_next_match_info() -> Dictionary:
	var next := EventManager.get_next_match()
	if next.is_empty():
		return {}
	var league_teams: Array = GameManager.league.get("teams", [])
	var opponent_id: int = next.get("home_team_id", 0)
	if opponent_id == GameManager.user_team_id:
		opponent_id = next.get("away_team_id", 0)
	var opponent_name := ""
	for t in league_teams:
		if t.get("id", 0) == opponent_id:
			opponent_name = t.get("city", "") + " " + t.get("name", "")
			break
	var is_home_local: bool = next.get("home_team_id", 0) == GameManager.user_team_id
	return {
		"opponent": opponent_name,
		"is_home": is_home_local,
		"phase": next.get("phase_label", "LIGA"),
		"competition": "LIGA",
	}


func _get_team_budget(team: Dictionary) -> String:
	var total_salary := 0.0
	for p in team.get("players", []):
		total_salary += p.get("salary", 0)
	var remaining := 150_000_000.0 - total_salary
	if remaining < 0:
		remaining = 0
	if remaining >= 1_000_000:
		return "R$ " + str(ceil(remaining / 100_000) / 10) + "M"
	return "R$ " + str(remaining)
