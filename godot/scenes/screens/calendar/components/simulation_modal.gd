extends ColorRect
class_name SimulationModal

signal cancel_requested
signal pause_requested
signal speed_changed(speed: float)
signal skip_to_match_requested
signal inbox_requested
signal play_requested
signal simulate_requested

@export var target_match: Dictionary
@export var days_to_simulate: int = 5
@export var current_progress: float = 0.0

var current_speed: int = 4

var title_lbl: Label
var subtitle_lbl: Label
var progress_bar: ProgressBar
var progress_lbl: Label
var event_log: VBoxContainer
var scroll_container: ScrollContainer
var timeline_container: HBoxContainer
var pause_btn: Button
var skip_btn: Button
var _ev_title: Label
var _footer: HBoxContainer

var _expected_days: int = 0
var _completed_days: int = 0
var _match_card: PanelContainer
var _match_prompt_btns: Array = []

func _ready():
	EventBus.time_advanced.connect(_on_time_advanced)
	EventBus.day_completed.connect(_on_day_completed)
	hide()
	color = Color(0.02, 0.01, 0.05, 0.8) # Backdrop color
	for c in get_children():
		c.queue_free()
	_build_ui()

func _on_time_advanced(progress: float):
	print("[UI DEBUG]: Sinal recebido (time_advanced): ", progress)
	update_progress(progress)

func _build_ui():
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(800, 640)
	var p_style = StyleBoxFlat.new(); p_style.bg_color = ThemeConfig.BG_APP; p_style.corner_radius_top_left=16; p_style.corner_radius_bottom_right=16; p_style.corner_radius_bottom_left=16; p_style.corner_radius_top_right=16; p_style.border_width_left=1; p_style.border_width_right=1; p_style.border_width_top=1; p_style.border_width_bottom=1; p_style.border_color=ThemeConfig.BORDER_SUBTLE
	panel.add_theme_stylebox_override("panel", p_style)
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)
	
	# HEADER
	var header = VBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 8)
	
	var live_pill = PanelContainer.new()
	live_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var lp_style = StyleBoxFlat.new(); lp_style.bg_color = ThemeConfig.BRAND_PRIMARY.lerp(Color.TRANSPARENT, 0.8); lp_style.border_width_left=1; lp_style.border_width_right=1; lp_style.border_width_top=1; lp_style.border_width_bottom=1; lp_style.border_color = ThemeConfig.BRAND_PRIMARY; lp_style.corner_radius_top_left=12; lp_style.corner_radius_bottom_right=12; lp_style.corner_radius_bottom_left=12; lp_style.corner_radius_top_right=12; lp_style.content_margin_left=12; lp_style.content_margin_right=12; lp_style.content_margin_top=4; lp_style.content_margin_bottom=4
	live_pill.add_theme_stylebox_override("panel", lp_style)
	var live_lbl = Label.new()
	live_lbl.text = "● SIMULANDO EM TEMPO REAL"
	live_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	live_lbl.add_theme_font_size_override("font_size", 10)
	live_lbl.add_theme_color_override("font_color", Color.WHITE)
	live_pill.add_child(live_lbl)
	header.add_child(live_pill)
	
	title_lbl = Label.new()
	title_lbl.text = "Avançando o tempo..."
	title_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	title_lbl.add_theme_font_size_override("font_size", 32)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title_lbl)
	
	subtitle_lbl = Label.new()
	subtitle_lbl.text = "Simulando 5 dias..."
	subtitle_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	subtitle_lbl.add_theme_font_size_override("font_size", 14)
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(subtitle_lbl)
	
	vbox.add_child(header)
	
	# TIMELINE
	timeline_container = HBoxContainer.new()
	timeline_container.alignment = BoxContainer.ALIGNMENT_CENTER
	timeline_container.add_theme_constant_override("separation", 16)
	timeline_container.custom_minimum_size = Vector2(0, 100)
	vbox.add_child(timeline_container)
	
	# PROGRESS
	var prog_vbox = VBoxContainer.new()
	prog_vbox.add_theme_constant_override("separation", 8)
	
	var prog_hbox = HBoxContainer.new()
	progress_lbl = Label.new()
	progress_lbl.text = "DIA 3 DE 5 · 60% CONCLUÍDO"
	progress_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	progress_lbl.add_theme_font_size_override("font_size", 12)
	progress_lbl.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
	prog_hbox.add_child(progress_lbl)
	
	var spacer = Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; prog_hbox.add_child(spacer)
	
	prog_vbox.add_child(prog_hbox)
	
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 8)
	progress_bar.show_percentage = false
	var pb_bg = StyleBoxFlat.new(); pb_bg.bg_color = ThemeConfig.BG_SURFACE; pb_bg.corner_radius_top_left=4; pb_bg.corner_radius_bottom_right=4; pb_bg.corner_radius_bottom_left=4; pb_bg.corner_radius_top_right=4
	var pb_fg = StyleBoxFlat.new(); pb_fg.bg_color = ThemeConfig.BRAND_PRIMARY; pb_fg.corner_radius_top_left=4; pb_fg.corner_radius_bottom_right=4; pb_fg.corner_radius_bottom_left=4; pb_fg.corner_radius_top_right=4
	progress_bar.add_theme_stylebox_override("background", pb_bg)
	progress_bar.add_theme_stylebox_override("fill", pb_fg)
	prog_vbox.add_child(progress_bar)
	
	vbox.add_child(prog_vbox)
	
	# RECENT EVENTS
	_ev_title = Label.new()
	_ev_title.text = "EVENTOS RECENTES"
	_ev_title.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	_ev_title.add_theme_font_size_override("font_size", 12)
	_ev_title.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	vbox.add_child(_ev_title)
	
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.custom_minimum_size = Vector2(0, 180)
	
	event_log = VBoxContainer.new()
	event_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_log.add_theme_constant_override("separation", 8)
	scroll_container.add_child(event_log)
	vbox.add_child(scroll_container)
	
	# FOOTER
	_footer = HBoxContainer.new()
	_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var cancel_btn = _create_action_btn("CANCELAR", Color("#EF4444"), false)
	cancel_btn.pressed.connect(_on_cancel)
	_footer.add_child(cancel_btn)
	
	pause_btn = _create_action_btn("PAUSAR", Color.WHITE, false)
	pause_btn.pressed.connect(_on_pause_toggle)
	_footer.add_child(pause_btn)
	
	var footer_spacer = Control.new(); footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _footer.add_child(footer_spacer)
	
	skip_btn = _create_action_btn("PULAR PARA O JOGO", Color("#FBBF24"), true)
	skip_btn.pressed.connect(_on_skip)
	_footer.add_child(skip_btn)
	
	vbox.add_child(_footer)

func _create_action_btn(text: String, color: Color, filled: bool) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	b.add_theme_font_size_override("font_size", 14)
	var s = StyleBoxFlat.new()
	s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8
	s.content_margin_left=24; s.content_margin_right=24; s.content_margin_top=12; s.content_margin_bottom=12
	if filled:
		s.bg_color = color
		b.add_theme_color_override("font_color", ThemeConfig.BG_APP)
		s.shadow_color = color.lerp(Color.TRANSPARENT, 0.7)
		s.shadow_size = 12
	else:
		s.bg_color = Color(0,0,0,0)
		s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1
		s.border_color = color
		b.add_theme_color_override("font_color", color)
	b.add_theme_stylebox_override("normal", s)
	b.add_theme_stylebox_override("hover", s)
	return b

func _set_ui_speed(level: int):
	current_speed = level
	if pause_btn:
		pause_btn.text = "RESUMIR" if level == 0 else "PAUSAR"
	speed_changed.emit(level)

func start_simulation(target: Dictionary, expected_days: int = 5):
	target_match = target
	show()
	current_progress = 0.0
	_expected_days = max(expected_days, 1)
	_completed_days = 0
	progress_bar.value = 0
	progress_lbl.text = "DIA 0 DE %d · 0%% CONCLUÍDO" % _expected_days
	title_lbl.text = "Avançando o tempo..."

	var opp = target.get("away_abbr", "")
	if opp.is_empty() and not target.is_empty():
		opp = target.get("description", "proximo jogo")
	subtitle_lbl.text = "Simulando até: " + opp

	for c in event_log.get_children():
		c.queue_free()

	_build_timeline(_expected_days)
	_set_ui_speed(4)

func _build_timeline(days: int):
	for c in timeline_container.get_children():
		c.queue_free()

	var season = GameManager.league.get("season", 2025)
	var user_id = GameManager.user_team_id
	var teams = GameManager.league.get("teams", [])
	var upcoming = EventManager.get_next_events(days)

	var month_abbr = ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]

	for i in range(upcoming.size()):
		if i > 0:
			var line = ColorRect.new()
			line.custom_minimum_size = Vector2(16, 2)
			line.color = ThemeConfig.BORDER_SUBTLE
			line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			timeline_container.add_child(line)

		var evt = upcoming[i]
		var event_type = evt.get("event_type", "match")
		var d = {"year": evt.get("year", season), "month": evt.get("month", 1), "day": evt.get("day", 1)}

		var box = PanelContainer.new()
		box.custom_minimum_size = Vector2(72, 90)
		var s = StyleBoxFlat.new()
		s.bg_color = ThemeConfig.BG_APP
		s.border_width_left=2; s.border_width_right=2; s.border_width_top=2; s.border_width_bottom=2
		s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8
		s.border_color = ThemeConfig.BORDER_SUBTLE
		box.add_theme_stylebox_override("panel", s)

		var m = MarginContainer.new()
		m.add_theme_constant_override("margin_left", 8)
		m.add_theme_constant_override("margin_right", 8)
		m.add_theme_constant_override("margin_top", 12)
		m.add_theme_constant_override("margin_bottom", 12)
		box.add_child(m)

		var vb = VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER

		var l_month = Label.new()
		l_month.text = month_abbr[d.month - 1]
		l_month.add_theme_font_size_override("font_size", 10)
		l_month.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
		l_month.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var l_day = Label.new()
		l_day.text = str(d.day)
		l_day.add_theme_font_size_override("font_size", 20)
		l_day.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		l_day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var l_desc = Label.new()
		match event_type:
			"match":
				var home_id = evt.get("home_team_id", 0)
				var away_id = evt.get("away_team_id", 0)
				var is_home = home_id == user_id
				var opp_id = away_id if is_home else home_id
				var opp_abbr = "???"
				for t in teams:
					if t.get("id") == opp_id:
						opp_abbr = t.get("abbreviation", "???")
						break
				l_desc.text = "vs " + opp_abbr + (" C" if is_home else " F")
			"training":
				l_desc.text = "TREINO"
			"interview":
				l_desc.text = "ENTREV."

		l_desc.add_theme_font_size_override("font_size", 10)
		l_desc.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		l_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		vb.add_child(l_month)
		vb.add_child(l_day)
		vb.add_child(l_desc)
		m.add_child(vb)

		timeline_container.add_child(box)

func log_event(text: String, date_dict: Dictionary = {}, is_critical: bool = false, is_win: bool = false):
	var p = PanelContainer.new()
	var s = StyleBoxFlat.new()
	s.bg_color = ThemeConfig.BG_SURFACE
	s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8
	s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1
	s.border_color = ThemeConfig.BORDER_SUBTLE
	p.add_theme_stylebox_override("panel", s)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	p.add_child(m)
	
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	m.add_child(h)
	
	var month_abbr = ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]
	var date_str = month_abbr[date_dict.get("month", 1) - 1] + " " + str(date_dict.get("day", 1)) if not date_dict.is_empty() else "--"
	var date = Label.new(); date.text = date_str; date.add_theme_font_size_override("font_size", 12); date.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED); date.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	h.add_child(date)
	
	var desc = Label.new(); desc.text = text; desc.add_theme_font_size_override("font_size", 14); desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(desc)
	
	if is_win:
		var badge = Label.new(); badge.text = "VITÓRIA"; badge.add_theme_font_size_override("font_size", 10); badge.add_theme_color_override("font_color", ThemeConfig.SUCCESS); badge.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		h.add_child(badge)
		
	if is_critical:
		s.border_color = Color("#FBBF24")
		s.shadow_color = Color("#FBBF24").lerp(Color.TRANSPARENT, 0.7)
		s.shadow_size = 8
		_set_ui_speed(0) # Pausa a simulação localmente
		
	event_log.add_child(p)
	
	# Scroll
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func update_progress(p: float):
	current_progress = p
	progress_bar.value = int(p * 100)
	var current_day = int(p * _expected_days) + 1
	if current_day > _expected_days: current_day = _expected_days
	progress_lbl.text = "DIA %d DE %d · %d%% CONCLUÍDO" % [current_day, _expected_days, int(p*100)]
	_update_timeline_visuals(current_day)

func _update_timeline_visuals(current_day: int):
	var i = 1
	for child in timeline_container.get_children():
		if child is PanelContainer:
			var sb = child.get_theme_stylebox("panel") as StyleBoxFlat
			if i < current_day:
				sb.border_color = Color("#10B981") # Green
				sb.shadow_size = 0
			elif i == current_day:
				sb.border_color = ThemeConfig.BRAND_PRIMARY
				sb.shadow_color = ThemeConfig.BRAND_PRIMARY.lerp(Color.TRANSPARENT, 0.7)
				sb.shadow_size = 8
			else:
				sb.border_color = ThemeConfig.BORDER_SUBTLE
				sb.shadow_size = 0
			i += 1

func _on_day_completed(summary: Dictionary):
	_completed_days += 1
	var progress = float(_completed_days) / float(_expected_days)
	EventBus.time_advanced.emit(min(progress, 1.0))

func fast_forward_complete():
	title_lbl.text = "Simulação concluída!"
	_set_ui_speed(0)
	await get_tree().create_timer(0.8).timeout
	hide()

func _on_pause_toggle():
	if current_speed == 0:
		_set_ui_speed(4)
	else:
		_set_ui_speed(0)

func _on_cancel():
	emit_signal("cancel_requested")
	hide()

func _on_skip():
	emit_signal("skip_to_match_requested")
	hide()

func show_match_prompt(match_data: Dictionary):
	title_lbl.text = "PARTIDA ENCONTRADA!"
	var home_abbr = match_data.get("home_abbr", "HOME")
	var away_abbr = match_data.get("away_abbr", "AWAY")
	var week_num = match_data.get("week", 0)
	subtitle_lbl.text = "%s vs %s — Semana %d" % [home_abbr, away_abbr, week_num]

	progress_bar.hide()
	timeline_container.hide()
	scroll_container.hide()
	if _ev_title: _ev_title.hide()
	pause_btn.hide()

	for b in _match_prompt_btns:
		if is_instance_valid(b): b.queue_free()
	_match_prompt_btns.clear()

	_match_card = PanelContainer.new()
	var mc_style = StyleBoxFlat.new()
	mc_style.bg_color = ThemeConfig.BG_SURFACE
	mc_style.corner_radius_top_left = 16
	mc_style.corner_radius_bottom_right = 16
	mc_style.corner_radius_bottom_left = 16
	mc_style.corner_radius_top_right = 16
	mc_style.border_width_left = 2
	mc_style.border_width_right = 2
	mc_style.border_width_top = 2
	mc_style.border_width_bottom = 2
	mc_style.border_color = ThemeConfig.BRAND_PRIMARY
	_match_card.add_theme_stylebox_override("panel", mc_style)
	_match_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var mc_margin = MarginContainer.new()
	mc_margin.add_theme_constant_override("margin_left", 32)
	mc_margin.add_theme_constant_override("margin_right", 32)
	mc_margin.add_theme_constant_override("margin_top", 32)
	mc_margin.add_theme_constant_override("margin_bottom", 32)
	_match_card.add_child(mc_margin)

	var mc_vbox = VBoxContainer.new()
	mc_vbox.add_theme_constant_override("separation", 16)
	mc_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	mc_margin.add_child(mc_vbox)

	var mc_versus = Label.new()
	mc_versus.text = "%s  🆚  %s" % [home_abbr, away_abbr]
	mc_versus.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	mc_versus.add_theme_font_size_override("font_size", 28)
	mc_versus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mc_vbox.add_child(mc_versus)

	var mc_week = Label.new()
	mc_week.text = "Semana %d" % week_num
	mc_week.add_theme_font_size_override("font_size", 14)
	mc_week.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	mc_week.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mc_vbox.add_child(mc_week)

	for b in _footer.get_children():
		if b is Button:
			b.hide()

	var spacer_left = Control.new()
	spacer_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(spacer_left)

	var play_btn = _create_match_btn("▶ JOGAR PARTIDA", ThemeConfig.BRAND_PRIMARY, true)
	play_btn.pressed.connect(_on_match_play)
	_footer.add_child(play_btn)

	_match_prompt_btns.append(play_btn)

	var sim_btn = _create_match_btn("SIMULAR", Color.WHITE, false)
	sim_btn.pressed.connect(_on_match_simulate)
	_footer.add_child(sim_btn)

	_match_prompt_btns.append(sim_btn)

	var spacer_right = Control.new()
	spacer_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(spacer_right)

	var parent = subtitle_lbl.get_parent().get_parent()
	parent.add_child(_match_card)

func _restore_simulation_ui():
	progress_bar.show()
	timeline_container.show()
	scroll_container.show()
	if _ev_title: _ev_title.show()
	pause_btn.show()

	if _match_card and is_instance_valid(_match_card):
		_match_card.queue_free()
	_match_card = null

	for b in _match_prompt_btns:
		if is_instance_valid(b):
			b.queue_free()
	_match_prompt_btns.clear()

	for b in _footer.get_children():
		if b is Button:
			b.show()

	title_lbl.text = "Avançando o tempo..."
	subtitle_lbl.text = "Simulando..."

func _create_match_btn(text: String, color: Color, filled: bool) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	b.add_theme_font_size_override("font_size", 14)
	b.custom_minimum_size = Vector2(180, 0)
	var s = StyleBoxFlat.new()
	s.corner_radius_top_left = 8
	s.corner_radius_bottom_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_top_right = 8
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	if filled:
		s.bg_color = color
		b.add_theme_color_override("font_color", Color.WHITE)
		s.shadow_color = color.lerp(Color.TRANSPARENT, 0.5)
		s.shadow_size = 8
	else:
		s.bg_color = Color(0, 0, 0, 0)
		s.border_width_left = 1
		s.border_width_right = 1
		s.border_width_top = 1
		s.border_width_bottom = 1
		s.border_color = color
		b.add_theme_color_override("font_color", color)
	b.add_theme_stylebox_override("normal", s)
	b.add_theme_stylebox_override("hover", s)
	return b

func _on_match_play():
	emit_signal("play_requested")

func _on_match_simulate():
	emit_signal("simulate_requested")
	_restore_simulation_ui()

func show_inbox_redirect():
	if skip_btn:
		skip_btn.text = "IR PARA CAIXA DE ENTRADA"
		skip_btn.add_theme_color_override("font_color", Color.WHITE)
		var s = skip_btn.get_theme_stylebox("normal") as StyleBoxFlat
		if s: 
			s.bg_color = ThemeConfig.DANGER
			s.border_color = ThemeConfig.DANGER
			
		if skip_btn.pressed.is_connected(_on_skip):
			skip_btn.pressed.disconnect(_on_skip)
			
		# Connect the new redirect action
		if not skip_btn.pressed.is_connected(_on_inbox_requested):
			skip_btn.pressed.connect(_on_inbox_requested)

func _on_inbox_requested():
	emit_signal("inbox_requested")
	hide()
