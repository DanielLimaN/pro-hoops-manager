extends PanelContainer

signal advance_requested

@export var screen_title: String = "Título da Tela"

@onready var val_budget = %ValBudget
@onready var val_morale = %ValMorale
@onready var val_energy = %ValEnergy

@onready var sub_lbl = %Sub
@onready var title_lbl = %Title
@onready var btn_avancar = %AvancarBtn

func set_title(new_title: String, new_subtitle: String = ""):
	if title_lbl:
		title_lbl.text = new_title
	if sub_lbl and new_subtitle != "":
		sub_lbl.text = new_subtitle

func _ready():
	title_lbl.text = screen_title
	
	# Assinar os eventos globais de tempo e status
	EventBus.date_updated.connect(_on_date_updated)
	if EventBus.has_signal("stats_updated"):
		EventBus.stats_updated.connect(_on_stats_updated)
		
	# Checar de forma segura se a SimulationBridge existe globalmente para conectar os dados em tempo real
	if Engine.has_singleton("SimulationBridge"):
		var bridge = Engine.get_singleton("SimulationBridge")
		if bridge.has_signal("on_stats_updated"):
			bridge.on_stats_updated.connect(_on_stats_updated)
	
	# Puxar dados estáticos do banco logo que a tela abre
	_update_from_league()
	_update_pills()
	
	if btn_avancar:
		btn_avancar.pressed.connect(func(): EventBus.advance_simulation_requested.emit({}))

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

func _update_pills():
	_fetch_initial_stats()

func _fetch_initial_stats():
	var user_team_id = GameManager.user_team_id
	var teams = GameManager.league.get("teams", [])
	var t = {}
	for team in teams:
		if team.get("id", -1) == user_team_id:
			t = team
			break
			
	if t.is_empty(): 
		return

	var total_salary = 0
	var total_morale = 0.0
	var total_stamina = 0.0
	var players = t.get("players", [])
	
	for p in players:
		total_salary += p.get("salary", 0)
		total_morale += p.get("morale", 100.0)
		var attrs = p.get("attributes", {})
		total_stamina += attrs.get("stamina", 100.0)

	var budget_cap = 150000000 # Assume Teto de 150M de Orçamento
	var remaining_budget = budget_cap - total_salary
	var budget_m = float(remaining_budget) / 1000000.0
	if val_budget:
		val_budget.text = "R$ %.1fM" % budget_m
	
	var avg_morale = 100.0
	var avg_stamina = 100.0
	if players.size() > 0:
		avg_morale = total_morale / players.size()
		avg_stamina = total_stamina / players.size()
	
	if val_morale:
		val_morale.text = "%d%%" % int(avg_morale)
	if val_energy:
		val_energy.text = "%d%%" % int(avg_stamina)

func _on_stats_updated(safe_data: Dictionary):
	if safe_data == null or safe_data.is_empty():
		return
		
	var budget = safe_data.get("budget", 0.0)
	if val_budget and budget > 0.0:
		val_budget.text = "R$ %.1fM" % (budget / 1000000.0)
	
	var morale = safe_data.get("morale", 100.0)
	if val_morale:
		val_morale.text = "%d%%" % int(morale)
	
	var energy = safe_data.get("energy", 100.0)
	if val_energy:
		val_energy.text = "%d%%" % int(energy)
