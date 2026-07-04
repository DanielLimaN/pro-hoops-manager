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
	# Center glow
	var glow = ColorRect.new()
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gt = GradientTexture2D.new()
	var g_grad = Gradient.new()
	g_grad.set_color(0, Color("#A78BFA22"))
	g_grad.set_color(1, Color("#A78BFA00"))
	gt.gradient = g_grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.3)
	gt.fill_to = Vector2(0.8, 0.5)
	var glow_rect = TextureRect.new()
	glow_rect.texture = gt
	glow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.add_child(glow_rect)
	add_child(glow)

	# Decorative particles
	var particle_positions = [
		Vector2(711, 33), Vector2(813, 877), Vector2(735, 432), Vector2(196, 98),
		Vector2(507, 791), Vector2(7, 649), Vector2(910, 203), Vector2(1230, 780),
		Vector2(123, 420), Vector2(920, 600), Vector2(480, 150), Vector2(1120, 310),
		Vector2(200, 750), Vector2(1340, 450), Vector2(620, 810), Vector2(330, 330),
		Vector2(1080, 130), Vector2(50, 820), Vector2(1250, 550), Vector2(40, 200),
	]
	var particle_opacities = [0.46, 0.47, 0.65, 0.39, 0.36, 0.74, 0.52, 0.48, 0.31, 0.55, 0.42, 0.61, 0.38, 0.44, 0.67, 0.33, 0.58, 0.51, 0.62, 0.35]
	var particle_sizes = [Vector2(3.4, 3.1), Vector2(4.6, 3.6), Vector2(4.2, 3.6), Vector2(3.1, 3.1), Vector2(4.2, 2.5), Vector2(4.4, 2.9), Vector2(3.8, 3.8), Vector2(2.5, 2.5), Vector2(4.0, 3.0), Vector2(3.2, 3.2), Vector2(4.8, 2.8), Vector2(2.8, 2.8), Vector2(3.6, 3.6), Vector2(3.0, 4.0), Vector2(4.0, 4.0), Vector2(2.0, 2.0), Vector2(4.2, 3.0), Vector2(3.0, 3.0), Vector2(3.5, 3.5), Vector2(4.0, 2.0)]
	for i in range(particle_positions.size()):
		var particle = ColorRect.new()
		particle.position = particle_positions[i]
		particle.size = particle_sizes[i]
		particle.color = Color("#A78BFA")
		particle.modulate = Color(1, 1, 1, particle_opacities[i])
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(particle)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(800, 640)
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = ThemeConfig.BG_SURFACE
	p_style.corner_radius_top_left=20; p_style.corner_radius_bottom_right=20; p_style.corner_radius_bottom_left=20; p_style.corner_radius_top_right=20
	p_style.border_width_left=2; p_style.border_width_right=2; p_style.border_width_top=2; p_style.border_width_bottom=2
	p_style.border_color = ThemeConfig.BRAND_PRIMARY
	p_style.shadow_color = Color("#A78BFA66")
	p_style.shadow_size = 60
	p_style.shadow_offset = Vector2(0, 16)
	panel.add_theme_stylebox_override("panel", p_style)
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# HEADER
	var header = VBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	header.custom_minimum_size = Vector2(0, 0)
	
	var live_pill = PanelContainer.new()
	live_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var lp_style = StyleBoxFlat.new()
	lp_style.bg_color = Color("#A78BFA22")
	lp_style.border_width_left=1; lp_style.border_width_right=1; lp_style.border_width_top=1; lp_style.border_width_bottom=1
	lp_style.border_color = ThemeConfig.BRAND_PRIMARY
	lp_style.corner_radius_top_left=50; lp_style.corner_radius_bottom_right=50; lp_style.corner_radius_bottom_left=50; lp_style.corner_radius_top_right=50
	lp_style.content_margin_left=12; lp_style.content_margin_right=12; lp_style.content_margin_top=4; lp_style.content_margin_bottom=4
	live_pill.add_theme_stylebox_override("panel", lp_style)
	var live_lbl = Label.new()
	live_lbl.text = "AO VIVO"
	live_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	live_lbl.add_theme_font_size_override("font_size", 10)
	live_lbl.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
	live_pill.add_child(live_lbl)
	header.add_child(live_pill)
	
	title_lbl = Label.new()
	title_lbl.text = "Avançando o tempo..."
	title_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	title_lbl.add_theme_font_size_override("font_size", 38)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.add_theme_constant_override("letter_spacing", -0.5)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title_lbl)
	
	subtitle_lbl = Label.new()
	subtitle_lbl.text = "Simulando 5 dias..."
	subtitle_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	subtitle_lbl.add_theme_font_size_override("font_size", 13)
	subtitle_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(subtitle_lbl)
	
	vbox.add_child(header)
	
	# TIMELINE
	timeline_container = HBoxContainer.new()
	timeline_container.alignment = BoxContainer.ALIGNMENT_CENTER
	timeline_container.add_theme_constant_override("separation", 8)
	timeline_container.custom_minimum_size = Vector2(0, 120)
	var tl_margin = MarginContainer.new()
	tl_margin.add_theme_constant_override("margin_left", 60)
	tl_margin.add_theme_constant_override("margin_right", 60)
	tl_margin.add_theme_constant_override("margin_top", 12)
	tl_margin.add_theme_constant_override("margin_bottom", 24)
	tl_margin.add_child(timeline_container)
	vbox.add_child(tl_margin)
	
	# PROGRESS
	var prog_vbox = VBoxContainer.new()
	prog_vbox.add_theme_constant_override("separation", 12)
	
	var prog_margin = MarginContainer.new()
	prog_margin.add_theme_constant_override("margin_left", 60)
	prog_margin.add_theme_constant_override("margin_right", 60)
	
	var prog_hbox = HBoxContainer.new()
	progress_lbl = Label.new()
	progress_lbl.text = "DIA 3 DE 5 · 60% CONCLUÍDO"
	progress_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	progress_lbl.add_theme_font_size_override("font_size", 11)
	progress_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	prog_hbox.add_child(progress_lbl)
	
	var spacer = Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; prog_hbox.add_child(spacer)
	
	prog_vbox.add_child(prog_hbox)
	
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 10)
	progress_bar.show_percentage = false
	var pb_bg = StyleBoxFlat.new(); pb_bg.bg_color = Color("#1F1432"); pb_bg.corner_radius_top_left=5; pb_bg.corner_radius_bottom_right=5; pb_bg.corner_radius_bottom_left=5; pb_bg.corner_radius_top_right=5
	var pb_fg = StyleBoxFlat.new(); pb_fg.bg_color = ThemeConfig.BRAND_PRIMARY; pb_fg.corner_radius_top_left=5; pb_fg.corner_radius_bottom_right=5; pb_fg.corner_radius_bottom_left=5; pb_fg.corner_radius_top_right=5
	progress_bar.add_theme_stylebox_override("background", pb_bg)
	progress_bar.add_theme_stylebox_override("fill", pb_fg)
	prog_vbox.add_child(progress_bar)
	
	prog_margin.add_child(prog_vbox)
	vbox.add_child(prog_margin)
	
	# RECENT EVENTS
	var ev_margin = MarginContainer.new()
	ev_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ev_margin.add_theme_constant_override("margin_left", 60)
	ev_margin.add_theme_constant_override("margin_right", 60)
	
	var ev_vbox = VBoxContainer.new()
	ev_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ev_vbox.add_theme_constant_override("separation", 6)
	
	_ev_title = Label.new()
	_ev_title.text = "EVENTOS RECENTES"
	_ev_title.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
	_ev_title.add_theme_font_size_override("font_size", 9)
	_ev_title.add_theme_color_override("font_color", Color("#6B5B95"))
	_ev_title.add_theme_constant_override("letter_spacing", 1.5)
	ev_vbox.add_child(_ev_title)
	
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_log = VBoxContainer.new()
	event_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_log.add_theme_constant_override("separation", 6)
	scroll_container.add_child(event_log)
	ev_vbox.add_child(scroll_container)
	ev_margin.add_child(ev_vbox)
	vbox.add_child(ev_margin)
	
	# FOOTER
	var footer_panel = PanelContainer.new()
	var fps = StyleBoxFlat.new()
	fps.bg_color = Color("#0B0514")
	fps.border_color = Color("#1F1432")
	fps.border_width_top = 1
	footer_panel.add_theme_stylebox_override("panel", fps)
	
	var footer_margin = MarginContainer.new()
	footer_margin.add_theme_constant_override("margin_left", 32)
	footer_margin.add_theme_constant_override("margin_right", 32)
	footer_margin.add_theme_constant_override("margin_top", 16)
	footer_margin.add_theme_constant_override("margin_bottom", 16)
	
	_footer = HBoxContainer.new()
	_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var cancel_btn = _create_action_btn("CANCELAR", Color("#94A3B8"), false)
	cancel_btn.pressed.connect(_on_cancel)
	_footer.add_child(cancel_btn)
	
	pause_btn = _create_action_btn("PAUSAR", Color("#94A3B8"), false)
	pause_btn.pressed.connect(_on_pause_toggle)
	_footer.add_child(pause_btn)
	
	var footer_spacer = Control.new(); footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _footer.add_child(footer_spacer)
	
	skip_btn = _create_action_btn("PULAR", Color("#FBBF24"), true)
	skip_btn.pressed.connect(_on_skip)
	_footer.add_child(skip_btn)
	
	footer_margin.add_child(_footer)
	footer_panel.add_child(footer_margin)
	vbox.add_child(footer_panel)

func _create_action_btn(text: String, color: Color, filled: bool) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	b.add_theme_font_size_override("font_size", 11)
	var s = StyleBoxFlat.new()
	s.corner_radius_top_left=8; s.corner_radius_bottom_right=8; s.corner_radius_bottom_left=8; s.corner_radius_top_right=8
	s.content_margin_left=18; s.content_margin_right=18; s.content_margin_top=12; s.content_margin_bottom=12
	if filled:
		s.bg_color = color
		var dark_bg = Color(0.06, 0.02, 0.09, 1)
		b.add_theme_color_override("font_color", dark_bg)
		s.shadow_color = Color("#FBBF2466")
		s.shadow_size = 16
		s.shadow_offset = Vector2(0, 4)
		b.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	else:
		s.bg_color = Color("#0F0720")
		s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1
		s.border_color = Color("#2D1B4E")
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
			line.custom_minimum_size = Vector2(12, 2)
			line.color = ThemeConfig.BORDER_DEFAULT
			line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			timeline_container.add_child(line)

		var evt = upcoming[i]
		var event_type = evt.get("event_type", "match")
		var d = {"year": evt.get("year", season), "month": evt.get("month", 1), "day": evt.get("day", 1)}
		var is_match_day = event_type == "match"

		var box = PanelContainer.new()
		box.custom_minimum_size = Vector2(96, 110)
		box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var s = StyleBoxFlat.new()
		s.bg_color = Color("#150826")
		s.border_width_left=2; s.border_width_right=2; s.border_width_top=2; s.border_width_bottom=2
		s.corner_radius_top_left=10; s.corner_radius_bottom_right=10; s.corner_radius_bottom_left=10; s.corner_radius_top_right=10
		s.border_color = Color("#2D1B4E")
		box.add_theme_stylebox_override("panel", s)

		var m = MarginContainer.new()
		m.add_theme_constant_override("margin_left", 8)
		m.add_theme_constant_override("margin_right", 8)
		m.add_theme_constant_override("margin_top", 8)
		m.add_theme_constant_override("margin_bottom", 8)
		box.add_child(m)

		var vb = VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_theme_constant_override("separation", 4)

		var l_month = Label.new()
		l_month.text = month_abbr[d.month - 1]
		l_month.add_theme_font_size_override("font_size", 9)
		l_month.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
		l_month.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var l_day = Label.new()
		l_day.text = str(d.day)
		l_day.add_theme_font_size_override("font_size", 22)
		l_day.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		l_day.add_theme_color_override("font_color", Color.WHITE)
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

		l_desc.add_theme_font_size_override("font_size", 9)
		l_desc.add_theme_color_override("font_color", Color("#94A3B8"))
		l_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		vb.add_child(l_month)
		vb.add_child(l_day)
		vb.add_child(l_desc)
		m.add_child(vb)

		timeline_container.add_child(box)

func log_event(text: String, date_dict: Dictionary = {}, is_critical: bool = false, is_win: bool = false):
	var p = PanelContainer.new()
	var s = StyleBoxFlat.new()
	s.corner_radius_top_left=6; s.corner_radius_bottom_right=6; s.corner_radius_bottom_left=6; s.corner_radius_top_right=6
	s.content_margin_left=10; s.content_margin_right=10; s.content_margin_top=6; s.content_margin_bottom=6

	if is_critical or event_log.get_child_count() == 0:
		s.bg_color = Color("#A78BFA22")
		s.border_color = ThemeConfig.BRAND_PRIMARY
		s.border_width_left = 1; s.border_width_right = 1; s.border_width_top = 1; s.border_width_bottom = 1
	else:
		s.bg_color = Color("#150826")

	p.add_theme_stylebox_override("panel", s)
	
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	
	var month_abbr = ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]
	var date_str = month_abbr[date_dict.get("month", 1) - 1] + " " + str(date_dict.get("day", 1)) if not date_dict.is_empty() else "--"
	var date = Label.new(); date.text = date_str; date.add_theme_font_size_override("font_size", 11); date.add_theme_color_override("font_color", Color("#6B5B95")); date.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	h.add_child(date)
	
	var desc = Label.new(); desc.text = text; desc.add_theme_font_size_override("font_size", 12); desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL; desc.add_theme_color_override("font_color", Color.WHITE)
	h.add_child(desc)
	
	if is_win:
		var badge = Label.new(); badge.text = "VITÓRIA"; badge.add_theme_font_size_override("font_size", 9); badge.add_theme_color_override("font_color", ThemeConfig.SUCCESS); badge.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		h.add_child(badge)
		
	if is_critical:
		_set_ui_speed(0) # Pausa a simulação localmente
		
	event_log.add_child(p)
	p.move_to_front()
	
	# Scroll
	await get_tree().process_frame
	if scroll_container.get_v_scroll_bar():
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func update_progress(p: float):
	current_progress = p
	progress_bar.value = int(p * 100)
	var current_day = int(p * _expected_days) + 1
	if current_day > _expected_days: current_day = _expected_days
	progress_lbl.text = "DIA %d DE %d · %d%% CONCLUÍDO" % [current_day, _expected_days, int(p*100)]
	_update_timeline_visuals(current_day)

func _update_timeline_visuals(current_day: int):
	var card_idx = 0
	for child in timeline_container.get_children():
		if child is PanelContainer:
			card_idx += 1
			var sb = child.get_theme_stylebox("panel") as StyleBoxFlat
			if not sb:
				continue

			var is_match = false
			for c in child.find_children("*", "Label", true, false):
				if c is Label and c.text.begins_with("vs"):
					is_match = true
					break

			if card_idx < current_day:
				sb.bg_color = Color("#10B98122")
				sb.border_color = Color("#10B981")
				sb.shadow_size = 0
			elif card_idx == current_day:
				sb.bg_color = Color("#A78BFA22")
				sb.border_color = ThemeConfig.BRAND_PRIMARY
				sb.shadow_color = Color("#A78BFA88")
				sb.shadow_size = 20
			elif is_match:
				sb.bg_color = Color("#FBBF2422")
				sb.border_color = Color("#FBBF24")
				sb.shadow_color = Color("#FBBF2466")
				sb.shadow_size = 16
			else:
				sb.bg_color = Color("#150826")
				sb.border_color = Color("#2D1B4E")
				sb.shadow_size = 0
		elif child is ColorRect:
			if card_idx < current_day:
				child.color = Color("#10B981")
			elif card_idx == current_day:
				child.color = Color("#A78BFA")
			else:
				child.color = Color("#2D1B4E")

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
