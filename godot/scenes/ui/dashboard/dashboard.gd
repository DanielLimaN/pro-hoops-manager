extends Control

var inbox_row_scene = preload("res://scenes/ui/dashboard/components/dashboard_inbox_row.tscn")
var recent_row_scene = preload("res://scenes/ui/dashboard/components/dashboard_recent_row.tscn")
var kpi_scene = preload("res://scenes/ui/components/status_card.tscn")
var hero_scene = preload("res://scenes/ui/dashboard/components/next_match_hero.tscn")
var standings_scene = preload("res://scenes/ui/dashboard/components/standings_table.tscn")

@onready var margin = $Margin
@onready var vbox = $Margin/VBox
@onready var topbar = $Margin/VBox/TopBar
@onready var kpi_row = $Margin/VBox/KPIRow
@onready var next_match_host = $Margin/VBox/MainGrid/LeftCol/NextMatchHost
@onready var standings_host = $Margin/VBox/MainGrid/LeftCol/StandingsHost
@onready var recent_list = %RecentList

var hero_instance
var standings_instance

## 🚀 O GRANDE DESPERTAR!
## Aqui é onde a mágica começa. O Dashboard acorda, liga os radares para escutar os eventos 
## do universo (SimulationBridge e EventBus), prepara os cards de KPI (aquelas estatísticas bonitonas)
## e dá o pontapé inicial puxando os dados fresquinhos do banco!
func _ready() -> void:
	SimulationBridge.on_stats_updated.connect(_on_stats_updated)
	EventBus.day_completed.connect(_on_day_completed)
	EventBus.stats_updated.connect(_on_stats_updated)
	
	_setup_kpis()
	
	hero_instance = hero_scene.instantiate()
	next_match_host.add_child(hero_instance)
	hero_instance.simulate_requested.connect(_on_simulate)
	
	standings_instance = standings_scene.instantiate()
	standings_instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
	standings_host.add_child(standings_instance)
	
	if topbar:
		topbar.advance_requested.connect(_on_advance)
		var lbl = topbar.get_node_or_null("%ScreenTitle")
		if not lbl:
			lbl = topbar.get_node_or_null("ScreenTitle")
		if lbl:
			lbl.text = "Dashboard"

	_refresh_data()

## 📊 FÁBRICA DE KPIs
## Essa função é como um gerente organizando a mesa de trabalho. 
## Ela prepara 6 cartõezinhos (cenas pre-fabricadas) vazios para os KPIs: 
## Posição, Vitórias, Pontos, Defesa, Lesionados e Assistências. 
## (Eles serão preenchidos de verdade depois, na função `_update_kpis`).
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

## 📬 O CARTEIRO CHEGOU!
## Essa função varre a caixa de entrada do General Manager. 
## Ela limpa a lista antiga, puxa os e-mails novos do Motor do Jogo (GameManager), 
## descobre quem mandou (se foi a diretoria, o médico ou um jogador resmungão),
## pinta o ícone com a cor certa e entrega tudo bonitinho nas linhas da tela!
func _populate_inbox():
	var inbox_list = %InboxList
	for child in inbox_list.get_children():
		child.queue_free()
		
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

	var badge = %UnreadBadge
	if badge:
		badge.text = " %d NOVAS " % unread_count
	
	for m in msgs:
		var row = inbox_row_scene.instantiate()
		inbox_list.add_child(row)
		
		row.get_node("%Title").text = m.t
		row.get_node("%Subtitle").text = m.s
		row.get_node("%Time").text = m.time
		
		var p = "res://addons/at-icons/control/" + m.icon + ".svg"
		if ResourceLoader.exists(p):
			row.get_node("%Icon").texture = load(p)
		row.get_node("%Icon").modulate = m.c_ic
		
		var ic_pnl = row.get_node("%IconPanel")
		ic_pnl.self_modulate = m.c_bg
		
		row.get_node("%UnreadDot").visible = m.unread

## 🔄 HORA DO REFRESH!
## Chamada toda vez que o dia passa ou os dados mudam. 
## É o maestro mandando a orquestra tocar de novo: atualiza o Próximo Jogo, 
## re-escreve a Tabela de Classificação, puxa os Últimos Resultados, 
## lê os novos E-mails e recalcula os KPIs. Tudo atualizadíssimo!
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

## ⏪ MÁQUINA DO TEMPO (Últimos Jogos)
## Dá uma olhada no calendário passado e pega os últimos 5 jogos do seu time.
## Ela pinta os quadradinhos de "V" (Verde/Vitória) ou "D" (Vermelho/Derrota) lá no topo,
## e constrói as linhas detalhadas mostrando quem você esmagou (ou para quem perdeu), 
## com direito a saldo de pontos e tudo!
func _populate_recent():
	var r_list = %RecentList
	for child in r_list.get_children():
		child.queue_free()
		
	var user_team = GameManager.user_team_id
	var sched = GameManager.get_schedule()
	var recent_games = []
	for g in sched:
		if g.get("played", false) and (g.get("home_team", -1) == user_team or g.get("away_team", -1) == user_team):
			recent_games.append(g)
	
	# Keep only last 5
	if recent_games.size() > 5:
		recent_games = recent_games.slice(recent_games.size() - 5, recent_games.size())
		
	var form_box = %FormBox
	if form_box:
		for c in form_box.get_children():
			c.queue_free()
		for g in recent_games:
			var is_home = g.get("home_team", -1) == user_team
			var h_score = g.get("home_score", 0)
			var a_score = g.get("away_score", 0)
			var won = (is_home and h_score > a_score) or (not is_home and a_score > h_score)
			
			var l = Label.new()
			l.text = "V" if won else "D"
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
			l.add_theme_font_size_override("font_size", 11)
			l.add_theme_color_override("font_color", ThemeConfig.SUCCESS if won else ThemeConfig.DANGER)
			form_box.add_child(l)
	
	recent_games.reverse() # newest first
	for g in recent_games:
		var is_home = g.get("home_team", -1) == user_team
		var h_score = g.get("home_score", 0)
		var a_score = g.get("away_score", 0)
		var won = (is_home and h_score > a_score) or (not is_home and a_score > h_score)
		var opp_id = g.get("away_team", -1) if is_home else g.get("home_team", -1)
		var opp = _find_team(GameManager.league.teams, opp_id)
		var us_score = h_score if is_home else a_score
		var them_score = a_score if is_home else h_score
		
		var row = recent_row_scene.instantiate()
		r_list.add_child(row)
		
		var result_label = row.get_node("%ResultLabel")
		result_label.text = "V" if won else "D"
		result_label.add_theme_color_override("font_color", ThemeConfig.SUCCESS if won else ThemeConfig.DANGER)
		
		var result_badge = row.get_node_or_null("%ResultBadge")
		if result_badge:
			result_badge.self_modulate = ThemeConfig.SUCCESS if won else ThemeConfig.DANGER
		
		row.get_node("%OpponentLabel").text = opp.get("name", "Opponent") if opp else "Opponent"
		row.get_node("%ScoreLabel").text = str(us_score) + "-" + str(them_score)
		
		var diff = us_score - them_score
		var diff_label = row.get_node("%DiffLabel")
		diff_label.text = ("+" if diff > 0 else "") + str(diff)
		diff_label.add_theme_color_override("font_color", ThemeConfig.SUCCESS if diff > 0 else ThemeConfig.DANGER)
		
		var type_label = row.get_node_or_null("%TypeLabel")
		if type_label:
			type_label.text = "vs" if is_home else "@"
		else:
			var hal = row.get_node_or_null("%HomeAwayLabel")
			if hal:
				hal.text = "vs" if is_home else "@"

## 💊 PÍLULAS DE STATUS (TopBar)
## Calcula a saúde financeira e mental da sua dinastia!
## Soma o salário de todos os jogadores para saber quanto dinheiro sobrou, 
## e tira a média de Moral e Energia do elenco para jogar aqueles números vitais 
## lá na barra superior do jogo.
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

## 📈 O CALCULADOR IMPLACÁVEL
## Aqui é onde a matemática pesada acontece! 
## Conta quantos pontos fizemos, quantos tomamos, qual nossa taxa de vitória, 
## acha nossa posição na tabela e conta quantos jogadores estão no DM (Departamento Médico).
## Depois de suar a camisa calculando, preenche aqueles 6 cartões do topo com os números reais.
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
	for i in range(sorted.size()):
		if sorted[i].get("id", -1) == user_team:
			pos = i + 1
			
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

## 🕵️‍♂️ DETETIVE DE TIMES
## Um simples investigador particular: você dá o número do RG (id) do time, 
## e ele varre a liga inteira até te devolver a ficha completa do time procurado.
func _find_team(teams: Array, id: int) -> Dictionary:
	for t in teams:
		if t.id == id: return t
	return {}

## ⏩ O BOTÃO DO DESTINO (Simular Partida)
## Quando o usuário clica em "SIMULAR PARTIDA" ou "ASSISTIR SIMULAÇÃO", 
## essa função avisa o GameManager quem vai jogar contra quem, e nos teletransporta 
## direto para a tela do estádio (`match.tscn`)!
func _on_simulate():
	var next_match = EventManager.get_next_match()
	if not next_match.is_empty():
		GameManager.pending_home_id = next_match.get("home_team_id", 0)
		GameManager.pending_away_id = next_match.get("away_team_id", 0)
		get_tree().change_scene_to_file("res://scenes/match.tscn")

## ⏳ ACELERAR O TEMPO
## Avisa o universo (EventBus) que o usuário clicou em avançar o dia. 
## Isso faz a engrenagem do jogo girar e as coisas acontecerem nos bastidores!
func _on_advance():
	EventBus.advance_simulation_requested.emit({})

## 📡 RÁDIO DA DIRETORIA (Stats Updated)
## Fica com a orelha em pé escutando a SimulationBridge. 
## Se uma partida acabou de acontecer (em tempo real), pega os dados mastigados 
## e atualiza o cartão de vitórias e a moral/energia/orçamento do TopBar instantaneamente!
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

## 🌙 BOA NOITE! (Day Completed)
## O sol se pôs no universo do basquete. Um dia inteiro de simulações acabou. 
## Quando isso acontece, ele chama o `_refresh_data()` para atualizar a tela inteira 
## com as novidades do novo dia que acabou de nascer!
func _on_day_completed(summary: Dictionary):
	_refresh_data()
