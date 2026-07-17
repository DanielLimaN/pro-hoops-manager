extends PanelContainer

signal advance_requested

@export var screen_title: String = "Título da Tela"

@onready var val_budget = %ValBudget
@onready var val_morale = %ValMorale
@onready var val_energy = %ValEnergy

@onready var sub_lbl = %Sub
@onready var title_lbl = %Title
@onready var btn_avancar = %AvancarBtn

func _ready():
	title_lbl.text = screen_title
	EventBus.date_updated.connect(_on_date_updated)
	_update_from_league()
	
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
