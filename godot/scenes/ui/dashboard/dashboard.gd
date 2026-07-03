extends Control

var kpi_scene = preload("res://scenes/ui/components/status_card.tscn")
var hero_scene = preload("res://scenes/ui/dashboard/components/next_match_hero.tscn")
var standings_scene = preload("res://scenes/ui/dashboard/components/standings_table.tscn")

@onready var margin = $Margin
@onready var vbox = $Margin/VBox
@onready var topbar = $Margin/VBox/TopBar
@onready var kpi_row = $Margin/VBox/KPIRow
@onready var next_match_host = $Margin/VBox/MainGrid/LeftCol/NextMatchHost
@onready var standings_host = $Margin/VBox/MainGrid/LeftCol/StandingsHost
@onready var recent_list = $Margin/VBox/MainGrid/RightCol/RecentPanel/VBox/RecentList

var hero_instance
var standings_instance

func _ready() -> void:
	SimulationBridge.on_stats_updated.connect(_on_stats_updated)
	EventBus.day_completed.connect(_on_day_completed)
	EventBus.stats_updated.connect(_on_stats_updated)
	
	var bg = ColorRect.new()
	bg.color = ThemeConfig.BG_APP
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)
	
	_setup_kpis()
	
	hero_instance = hero_scene.instantiate()
	next_match_host.add_child(hero_instance)
	hero_instance.simulate_requested.connect(_on_simulate)
	
	standings_instance = standings_scene.instantiate()
	standings_instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
	standings_host.add_child(standings_instance)
	
	if topbar:
		topbar.advance_requested.connect(_on_advance)
	
	_style_panels()
	_refresh_data()

func _style_panels():
	var inbox_panel = $Margin/VBox/MainGrid/RightCol/InboxPanel
	var recent_panel = $Margin/VBox/MainGrid/RightCol/RecentPanel
	
	inbox_panel.set_script(preload("res://scenes/ui/components/container_base.gd"))
	inbox_panel._ready()
	recent_panel.set_script(preload("res://scenes/ui/components/container_base.gd"))
	recent_panel._ready()
	
	inbox_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	recent_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _setup_kpis() -> void:
	var kpis = [
		{"l": "POSIÇÃO", "v": "1º", "t": "Zona Neutra", "up": true, "s": "vs sem. passada"},
		{"l": "VITÓRIAS", "v": "0-0", "t": "Forma: V V", "up": true, "s": "taxa de vitória"},
		{"l": "PONTOS/JOGO", "v": "0.0", "t": "+0.0", "up": true, "s": "vs média liga"},
		{"l": "DEFESA", "v": "0.0", "t": "-0.0", "up": false, "s": "pontos sofridos"},
		{"l": "LESIONADOS", "v": "0", "t": "+0", "up": false, "s": "esta semana"},
		{"l": "ASSIST/JOGO", "v": "0.0", "t": "+0.0", "up": true, "s": "vs média"},
	]
	for k in kpis:
		var c = kpi_scene.instantiate()
		kpi_row.add_child(c)
		c.set_data(k.l, k.v, k.t, k.up, k.s)

func _populate_inbox():
	var inbox = $Margin/VBox/MainGrid/RightCol/InboxPanel
	for c in inbox.get_children():
		c.queue_free()
		
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	
	# Header
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var ic_path = "res://addons/at-icons/control/mailbox.svg"
	var ic = TextureRect.new()
	if ResourceLoader.exists(ic_path):
		ic.texture = load(ic_path)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.custom_minimum_size = Vector2(16, 16)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.modulate = ThemeConfig.BRAND_PRIMARY
	h.add_child(ic)
	
	var l = Label.new()
	l.text = "CAIXA DE ENTRADA"
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
	l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	l.add_theme_constant_override("letter_spacing", 2)
	h.add_child(l)
	
	var pill = Label.new()
	pill.text = " 12 NOVAS "
	var ps = StyleBoxFlat.new()
	ps.bg_color = ThemeConfig.DANGER
	ps.corner_radius_top_left = 6; ps.corner_radius_bottom_right = 6; ps.corner_radius_top_right = 6; ps.corner_radius_bottom_left = 6
	pill.add_theme_stylebox_override("normal", ps)
	pill.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	pill.add_theme_font_size_override("font_size", 11)
	h.add_child(pill)
	vb.add_child(h)
	
	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(0, 1)
	div.color = Color("#2D1B4E")
	vb.add_child(div)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var msg_vbox = VBoxContainer.new()
	msg_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(msg_vbox)
	vb.add_child(scroll)
	
	# Messages from Engine
	var raw_msgs = GameManager.get_inbox()
	var msgs = []
	var unread_count = 0
	for r in raw_msgs:
		var unread = not r.get("read", false)
		if unread:
			unread_count += 1
		
		var icon = "text"
		var bg_color = Color("#172554")
		var ic_color = Color("#3B82F6")
		
		var role = str(r.get("sender_role", "")).to_lower()
		if "coach" in role or "treinador" in role or "player" in role or "jogador" in role:
			icon = "help-circle"
			bg_color = Color("#422006")
			ic_color = ThemeConfig.WARNING
		elif "med" in role or "médic" in role:
			icon = "activity"
			bg_color = Color("#450A0A")
			ic_color = ThemeConfig.DANGER
		elif "diretor" in role or "presid" in role or "board" in role:
			icon = "target"
			bg_color = Color("#2E1065")
			ic_color = ThemeConfig.BRAND_PRIMARY
			
		var body_preview = str(r.get("body", "")).substr(0, 45) + "..." if str(r.get("body", "")).length() > 45 else str(r.get("body", ""))
			
		msgs.append({
			"t": r.get("subject", ""),
			"s": r.get("sender_name", "") + " - " + body_preview,
			"time": r.get("date_received", ""),
			"icon": icon,
			"c_bg": bg_color,
			"c_ic": ic_color,
			"unread": unread
		})

	pill.text = " %d NOVAS " % unread_count
	
	for m in msgs:
		var root = MarginContainer.new()
		var btn = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var n_style = StyleBoxEmpty.new()
		var h_style = StyleBoxFlat.new()
		h_style.bg_color = ThemeConfig.BG_ELEVATED
		h_style.corner_radius_top_left = 6; h_style.corner_radius_bottom_right = 6; h_style.corner_radius_top_right = 6; h_style.corner_radius_bottom_left = 6
		btn.add_theme_stylebox_override("normal", n_style)
		btn.add_theme_stylebox_override("hover", h_style)
		btn.add_theme_stylebox_override("pressed", h_style)
		btn.add_theme_stylebox_override("focus", n_style)
		root.add_child(btn)
		
		var pad = MarginContainer.new()
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pad.add_theme_constant_override("margin_left", 16)
		pad.add_theme_constant_override("margin_right", 16)
		pad.add_theme_constant_override("margin_top", 12)
		pad.add_theme_constant_override("margin_bottom", 12)
		root.add_child(pad)
		
		var row = HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 16)
		pad.add_child(row)
		
		# Icon Box
		var ic_pnl = PanelContainer.new()
		ic_pnl.custom_minimum_size = Vector2(40, 40)
		ic_pnl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ic_pnl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ics = StyleBoxFlat.new()
		ics.bg_color = m.c_bg
		ics.corner_radius_top_left = 8; ics.corner_radius_bottom_right = 8; ics.corner_radius_top_right = 8; ics.corner_radius_bottom_left = 8
		ic_pnl.add_theme_stylebox_override("panel", ics)
		
		var ic_tex = TextureRect.new()
		var p = "res://addons/at-icons/control/" + m.icon + ".svg"
		if ResourceLoader.exists(p):
			ic_tex.texture = load(p)
		ic_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic_tex.custom_minimum_size = Vector2(20, 20)
		ic_tex.modulate = m.c_ic
		
		var ic_c = CenterContainer.new()
		ic_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic_c.add_child(ic_tex)
		ic_pnl.add_child(ic_c)
		row.add_child(ic_pnl)
		
		# Text Column
		var text_col = VBoxContainer.new()
		text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.alignment = BoxContainer.ALIGNMENT_CENTER
		var title = Label.new()
		title.text = m.t
		title.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		title.add_theme_color_override("font_color", Color.WHITE)
		title.add_theme_font_size_override("font_size", 13)
		var sub = Label.new()
		sub.text = m.s
		sub.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		sub.add_theme_font_size_override("font_size", 12)
		text_col.add_child(title)
		text_col.add_child(sub)
		row.add_child(text_col)
		
		# Time & Dot Column
		var r_col = VBoxContainer.new()
		r_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r_col.alignment = BoxContainer.ALIGNMENT_CENTER
		r_col.add_theme_constant_override("separation", 6)
		var t_lbl = Label.new()
		t_lbl.text = m.time
		t_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		t_lbl.add_theme_font_size_override("font_size", 11)
		t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r_col.add_child(t_lbl)
		
		if m.unread:
			var d_pnl = PanelContainer.new()
			d_pnl.custom_minimum_size = Vector2(6, 6)
			d_pnl.size_flags_horizontal = Control.SIZE_SHRINK_END
			var ds = StyleBoxFlat.new()
			ds.bg_color = ThemeConfig.BRAND_PRIMARY
			ds.corner_radius_top_left = 3; ds.corner_radius_bottom_right = 3; ds.corner_radius_top_right = 3; ds.corner_radius_bottom_left = 3
			d_pnl.add_theme_stylebox_override("panel", ds)
			r_col.add_child(d_pnl)
		else:
			var dot = ColorRect.new()
			dot.custom_minimum_size = Vector2(6, 6)
			dot.color = Color(0,0,0,0)
			r_col.add_child(dot)
			
		row.add_child(r_col)
		msg_vbox.add_child(root)
		
	var m_cont = MarginContainer.new()
	m_cont.add_theme_constant_override("margin_left", 32)
	m_cont.add_theme_constant_override("margin_top", 24)
	m_cont.add_theme_constant_override("margin_right", 32)
	m_cont.add_theme_constant_override("margin_bottom", 24)
	m_cont.add_child(vb)
	inbox.add_child(m_cont)

func _refresh_data() -> void:
	var next_match = EventManager.get_next_match()

	if not next_match.is_empty():
		hero_instance.setup(next_match)
		hero_instance.show()
	else:
		hero_instance.hide()
		
	standings_instance.refresh(GameManager.league.teams)
	
	_populate_recent()
	_populate_inbox()
	_update_pills()
	_update_kpis()

func _populate_recent():
	var panel = $Margin/VBox/MainGrid/RightCol/RecentPanel
	for c in panel.get_children():
		c.queue_free()
		
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	
	# Header
	var header = HBoxContainer.new()
	var tit = Label.new()
	tit.text = "ÚLTIMOS RESULTADOS"
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	tit.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
	tit.add_theme_constant_override("letter_spacing", 2)
	tit.add_theme_font_size_override("font_size", 12)
	header.add_child(tit)
	
	var user_team = GameManager.user_team_id
	var sched = GameManager.get_schedule()
	var recent_games = []
	for g in sched:
		if g.get("played", false) and (g.get("home_team", -1) == user_team or g.get("away_team", -1) == user_team):
			recent_games.append(g)
	
	# Keep only last 5
	if recent_games.size() > 5:
		recent_games = recent_games.slice(recent_games.size() - 5, recent_games.size())
		
	var form_box = HBoxContainer.new()
	form_box.add_theme_constant_override("separation", 4)
	for g in recent_games:
		var is_home = g.get("home_team", -1) == user_team
		var h_score = g.get("home_score", 0)
		var a_score = g.get("away_score", 0)
		var won = (is_home and h_score > a_score) or (not is_home and a_score > h_score)
		var pnl = PanelContainer.new()
		pnl.custom_minimum_size = Vector2(16, 16)
		pnl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var ps = StyleBoxFlat.new()
		ps.bg_color = Color("#06030E")
		ps.corner_radius_top_left = 4; ps.corner_radius_bottom_right = 4; ps.corner_radius_top_right = 4; ps.corner_radius_bottom_left = 4
		ps.border_width_left = 1; ps.border_width_top = 1; ps.border_width_right = 1; ps.border_width_bottom = 1
		ps.border_color = ThemeConfig.SUCCESS if won else ThemeConfig.DANGER
		pnl.add_theme_stylebox_override("panel", ps)
		var l = Label.new()
		l.text = "V" if won else "D"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		l.add_theme_font_size_override("font_size", 9)
		l.add_theme_color_override("font_color", ThemeConfig.SUCCESS if won else ThemeConfig.DANGER)
		pnl.add_child(l)
		form_box.add_child(pnl)
		
	header.add_child(form_box)
	vb.add_child(header)
	
	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(0, 1)
	div.color = Color("#2D1B4E")
	vb.add_child(div)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 24)
	scroll.add_child(list_vbox)
	vb.add_child(scroll)
	
	recent_games.reverse() # newest first
	for g in recent_games:
		var is_home = g.get("home_team", -1) == user_team
		var h_score = g.get("home_score", 0)
		var a_score = g.get("away_score", 0)
		var won = (is_home and h_score > a_score) or (not is_home and a_score > h_score)
		var opp_id = g.get("away_team", -1) if is_home else g.get("home_team", -1)
		var opp = _find_team(GameManager.league.teams, opp_id)
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		
		# V/D Badge
		var badge = PanelContainer.new()
		badge.custom_minimum_size = Vector2(24, 24)
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bs = StyleBoxFlat.new()
		bs.bg_color = Color("#06030E")
		bs.corner_radius_top_left = 6; bs.corner_radius_bottom_right = 6; bs.corner_radius_top_right = 6; bs.corner_radius_bottom_left = 6
		bs.border_width_left = 1; bs.border_width_top = 1; bs.border_width_right = 1; bs.border_width_bottom = 1
		bs.border_color = ThemeConfig.SUCCESS if won else ThemeConfig.DANGER
		badge.add_theme_stylebox_override("panel", bs)
		var bl = Label.new()
		bl.text = "V" if won else "D"
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		bl.add_theme_color_override("font_color", ThemeConfig.SUCCESS if won else ThemeConfig.DANGER)
		bl.add_theme_font_size_override("font_size", 12)
		badge.add_child(bl)
		row.add_child(badge)
		
		# Home/Away indicator
		var ha = Label.new()
		ha.text = "vs" if is_home else "@"
		ha.custom_minimum_size = Vector2(16, 0)
		ha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ha.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		ha.add_theme_font_size_override("font_size", 12)
		row.add_child(ha)
		
		# Opponent Name
		var opp_lbl = Label.new()
		opp_lbl.text = opp.get("name", "Opponent") if opp else "Opponent"
		opp_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opp_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		opp_lbl.add_theme_color_override("font_color", Color.WHITE)
		opp_lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(opp_lbl)
		
		# Score
		var score_lbl = Label.new()
		var us_score = h_score if is_home else a_score
		var them_score = a_score if is_home else h_score
		score_lbl.text = str(us_score) + "-" + str(them_score)
		score_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		score_lbl.add_theme_color_override("font_color", Color.WHITE)
		score_lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(score_lbl)
		
		# Diff
		var diff = us_score - them_score
		var diff_lbl = Label.new()
		diff_lbl.text = ("+" if diff > 0 else "") + str(diff)
		diff_lbl.custom_minimum_size = Vector2(24, 0)
		diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		diff_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		diff_lbl.add_theme_color_override("font_color", ThemeConfig.SUCCESS if diff > 0 else ThemeConfig.DANGER)
		diff_lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(diff_lbl)
		
		var r_pad = MarginContainer.new()
		r_pad.add_theme_constant_override("margin_left", 8)
		r_pad.add_theme_constant_override("margin_right", 8)
		r_pad.add_child(row)
		list_vbox.add_child(r_pad)
		
	var pad = MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 32)
	pad.add_theme_constant_override("margin_top", 24)
	pad.add_theme_constant_override("margin_right", 32)
	pad.add_theme_constant_override("margin_bottom", 24)
	pad.add_child(vb)
	panel.add_child(pad)

func _update_pills():
	var user_team = GameManager.user_team_id
	var t = _find_team(GameManager.league.teams, user_team)
	if not t: return

	var total_salary = 0
	var total_morale = 0.0
	var total_stamina = 0.0
	for p in t.players:
		total_salary += p.get("salary", 0)
		total_morale += p.get("morale", 100.0)
		var attrs = p.get("attributes", {})
		total_stamina += attrs.get("stamina", 100.0)

	var budget_cap = 150000000 # 150M budget cap assumption
	var remaining_budget = budget_cap - total_salary
	var budget_m = float(remaining_budget) / 1000000.0
	if topbar and topbar.val_budget:
		topbar.val_budget.text = "R$ %.1fM" % budget_m
	
	var avg_morale = 100.0
	var avg_stamina = 100.0
	if t.players.size() > 0:
		avg_morale = total_morale / t.players.size()
		avg_stamina = total_stamina / t.players.size()
	
	if topbar and topbar.val_morale:
		topbar.val_morale.text = "%d%%" % int(avg_morale)
	if topbar and topbar.val_energy:
		topbar.val_energy.text = "%d%%" % int(avg_stamina)

func _update_kpis():
	var user_team = GameManager.user_team_id
	var t = _find_team(GameManager.league.teams, user_team)
	if not t: return
	
	var sched = GameManager.get_schedule()
	var points_scored = 0
	var points_allowed = 0
	var total_assists = 0.0
	var current_week = 1
	for g in sched:
		if not g.get("played", false):
			current_week = g.get("week", 1)
			break
		if g.get("played", false):
			if g.get("home_team", -1) == user_team:
				points_scored += g.get("home_score", 0)
				points_allowed += g.get("away_score", 0)
			elif g.get("away_team", -1) == user_team:
				points_scored += g.get("away_score", 0)
				points_allowed += g.get("home_score", 0)
				
	# Calculate total assists from players
	for p in t.players:
		var stats = p.get("stats_season", {})
		var games = stats.get("games_played", 0)
		var assists = stats.get("assists", 0.0)
		if games > 0:
			total_assists += assists * games
			
	var total_games = t.get("wins", 0) + t.get("losses", 0)
	var ppg = float(points_scored) / total_games if total_games > 0 else 0.0
	var oppg = float(points_allowed) / total_games if total_games > 0 else 0.0
	var apg = float(total_assists) / total_games if total_games > 0 else 0.0
	var win_rate = float(t.get("wins", 0)) / total_games * 100.0 if total_games > 0 else 0.0
	
	var sorted = GameManager.league.teams.duplicate()
	sorted.sort_custom(func(a, b): return a.get("wins", 0) > b.get("wins", 0) if a.get("wins", 0) != b.get("wins", 0) else a.get("losses", 0) < b.get("losses", 0))
	var pos = 1
	var league_total_ppg = 0.0
	for i in range(sorted.size()):
		if sorted[i].get("id", -1) == user_team:
			pos = i + 1
		# calculate league average ppg
		var team_total_games = sorted[i].get("wins", 0) + sorted[i].get("losses", 0)
		if team_total_games > 0:
			# Not exact without tracking every team's scores, but we can do a rough estimate or just show a diff from 100
			pass
			
	var injured_count = 0
	for p in t.players:
		if p.get("injury_days", 0) > 0:
			injured_count += 1
	
	var kpis = kpi_row.get_children()
	kpis[0].set_data("POSIÇÃO", str(pos) + "º", "Conferência", true, "")
	kpis[1].set_data("VITÓRIAS", str(t.get("wins", 0)) + "-" + str(t.get("losses", 0)), "%.1f%%" % win_rate, win_rate >= 50.0, "taxa de vitória")
	kpis[2].set_data("PONTOS/JOGO", "%.1f" % ppg, "", ppg > 100.0, "ofensiva")
	kpis[3].set_data("DEFESA", "%.1f" % oppg, "", oppg < 100.0, "pontos sofridos")
	kpis[4].set_data("LESIONADOS", str(injured_count), "", injured_count == 0, "no departamento médico")
	kpis[5].set_data("ASSIST/JOGO", "%.1f" % apg, "", apg > 20.0, "trabalho em equipe")

func _find_team(teams: Array, id: int) -> Dictionary:
	for t in teams:
		if t.id == id: return t
	return {}

func _on_simulate():
	var next_match = EventManager.get_next_match()
	if not next_match.is_empty():
		GameManager.pending_home_id = next_match.get("home_team_id", 0)
		GameManager.pending_away_id = next_match.get("away_team_id", 0)
		get_tree().change_scene_to_file("res://scenes/match.tscn")

func _on_advance():
	EventBus.advance_simulation_requested.emit({})

func _on_stats_updated(safe_data: Dictionary):
	if safe_data == null or safe_data.is_empty():
		return
	var wins = safe_data.get("wins", 0)
	var losses = safe_data.get("losses", 0)
	
	var kpis = kpi_row.get_children()
	if kpis.size() >= 2:
		kpis[1].update_value(str(wins) + "-" + str(losses))
	
	var budget = safe_data.get("budget", 0.0)
	if topbar and topbar.val_budget:
		topbar.val_budget.text = "R$ %.1fM" % (budget / 1000000.0)
	
	var morale = safe_data.get("morale", 100.0)
	if topbar and topbar.val_morale:
		topbar.val_morale.text = "%d%%" % int(morale)
	
	var energy = safe_data.get("energy", 100.0)
	if topbar and topbar.val_energy:
		topbar.val_energy.text = "%d%%" % int(energy)

func _on_day_completed(summary: Dictionary):
	_refresh_data()
