
# Referencia ao tema global
extends Node
class_name TeamScreen

var _player_data_cache: Array = []
var _player_rows: Array = []
var _selected_player_idx: int = -1
var _replacement_source: Dictionary = {}
var _active_filter: String = "TODOS"
var _substitutions_in: Array = []
var _substitutions_out: Array = []
var _edit_mode: bool = false
var _filter_btns: Dictionary = {}
var _quick_actions_popover = null

# Preloads de Cenas
const _EDIT_BANNER = preload("res://scenes/screens/team/components/edit_banner.tscn")
const _QA_POPOVER = preload("res://scenes/screens/team/components/quick_actions_popover.tscn")
const _PLAYER_ROW_SCENE = preload("res://scenes/ui/components/player_row.tscn")

signal player_selected(data)
signal quick_action_requested(data, pos)
signal edit_rotation_requested
signal save_rotation_requested

var _active_tab_style: StyleBoxFlat
var _inactive_tab_style: StyleBoxFlat
var _active_lbl_settings: LabelSettings
var _inactive_lbl_settings: LabelSettings
var _active_badge_style: StyleBoxFlat
var _inactive_badge_style: StyleBoxFlat
var _active_badge_lbl_settings: LabelSettings
var _inactive_badge_lbl_settings: LabelSettings

func _ready():
	_setup_topbar()
	_load_roster()
	_setup_tabs()
	_refresh_all()

func _setup_tabs():
	var tabs_inner = find_child("TabsInner", true, false)
	if not tabs_inner: return
	
	var todos = tabs_inner.get_node("Todos")
	var titulares = tabs_inner.get_node("Titulares")
	
	_active_tab_style = todos.get_theme_stylebox("panel")
	_inactive_tab_style = titulares.get_theme_stylebox("panel")
	
	_active_lbl_settings = todos.get_node("HBoxContainer/MainLbl").label_settings
	_inactive_lbl_settings = titulares.get_node("HBoxContainer/MainLbl").label_settings
	
	_active_badge_style = todos.get_node("HBoxContainer/BadgeContainer").get_theme_stylebox("panel")
	_inactive_badge_style = titulares.get_node("HBoxContainer/BadgeContainer").get_theme_stylebox("panel")
	
	_active_badge_lbl_settings = todos.get_node("HBoxContainer/BadgeContainer/CountLbl").label_settings
	_inactive_badge_lbl_settings = titulares.get_node("HBoxContainer/BadgeContainer/CountLbl").label_settings
	
	for t in tabs_inner.get_children():
		var btn = t.get_node_or_null("ClickArea")
		if btn:
			var filter_name = t.get_node("HBoxContainer/MainLbl").text
			btn.pressed.connect(func(): _on_filter_clicked(filter_name))

func _on_filter_clicked(filter_name: String):
	_active_filter = filter_name
	_refresh_all()

func _setup_topbar():
	var topbar_node = find_child("TopBar", true, false)
	if topbar_node and topbar_node.has_method("set_title"):
		topbar_node.set_title("ELENCO")

func _refresh_all():
	if _selected_player_idx < 0 and _player_data_cache.size() > 0:
		_selected_player_idx = 0
		
	_update_kpis()
	_update_filter_visuals()
	_refresh_player_rows()
	_refresh_detail()

func _update_filter_visuals():
	var tabs_inner = find_child("TabsInner", true, false)
	if not tabs_inner: return
	
	var counts = {
		"TODOS": _player_data_cache.size(),
		"TITULARES": 0,
		"ROTAÇÃO": 0,
		"LESIONADOS": 0,
		"JOVENS": 0
	}
	for p in _player_data_cache:
		var idx = _player_data_cache.find(p)
		if idx < 5: counts["TITULARES"] += 1
		elif idx >= 5 and idx < 10: counts["ROTAÇÃO"] += 1
		if p.get("status") == "LESIONADO": counts["LESIONADOS"] += 1
		if int(p.get("age", 0)) <= 22: counts["JOVENS"] += 1
		
	for t in tabs_inner.get_children():
		var lbl = t.get_node_or_null("HBoxContainer/MainLbl")
		if not lbl: continue
		var filter_name = lbl.text
		
		var count_lbl = t.get_node("HBoxContainer/BadgeContainer/CountLbl")
		count_lbl.text = str(counts.get(filter_name, 0))
		
		if filter_name == _active_filter:
			t.add_theme_stylebox_override("panel", _active_tab_style)
			lbl.label_settings = _active_lbl_settings
			t.get_node("HBoxContainer/BadgeContainer").add_theme_stylebox_override("panel", _active_badge_style)
			count_lbl.label_settings = _active_badge_lbl_settings
		else:
			t.add_theme_stylebox_override("panel", _inactive_tab_style)
			lbl.label_settings = _inactive_lbl_settings
			t.get_node("HBoxContainer/BadgeContainer").add_theme_stylebox_override("panel", _inactive_badge_style)
			count_lbl.label_settings = _inactive_badge_lbl_settings

func _update_kpis():
	var team = GameManager.get_user_team()
	
	# Fallback dummy values caso não haja time carregado
	var total_ovr = 824.0
	var total_age = 263.0
	var total_salary = 8200000.0
	var count = 10
	var chemistry = 94
	
	if team and team.has("players"):
		var players = team.players
		count = max(players.size(), 1)
		chemistry = round(team.get("chemistry", 94.0))
		
		if players.size() > 0:
			total_ovr = 0.0
			total_age = 0.0
			total_salary = 0.0
			for p in players:
				total_ovr += float(p.get("overall", 50))
				total_age += float(p.get("age", 20))
				total_salary += float(p.get("salary", 0))
		
	var avg_ovr = total_ovr / count
	var avg_age = total_age / count
	
	var salary_str = "R$ 0"
	var unit_str = ""
	if total_salary >= 1000000:
		salary_str = "R$ %.1f" % (total_salary / 1000000.0)
		unit_str = "M/ano"
	else:
		salary_str = "R$ %d" % (total_salary / 1000)
		unit_str = "K/ano"

	var ovr_card = find_child("OverallMedioCard", true, false)
	if ovr_card:
		var lbl = ovr_card.find_child("ValLbl", true, false)
		if lbl: lbl.text = "%.1f" % avg_ovr

	var age_card = find_child("IdadeMediaCard", true, false)
	if age_card:
		var lbl = age_card.find_child("ValLbl", true, false)
		if lbl: lbl.text = "%.1f" % avg_age
		
	var sal_card = find_child("SalarioTotalCard", true, false)
	if sal_card:
		var lbl = sal_card.find_child("ValLbl", true, false)
		if lbl: lbl.text = salary_str
		var unit = sal_card.find_child("UnitLbl", true, false)
		if unit: unit.text = unit_str

	var chem_card = find_child("QuimicaCard", true, false)
	if chem_card:
		var lbl = chem_card.find_child("ValLbl", true, false)
		if lbl: lbl.text = str(chemistry)

func _get_filtered_players() -> Array:
	if _active_filter == "TODOS":
		return _player_data_cache
	
	var filtered = []
	for p in _player_data_cache:
		var idx = _player_data_cache.find(p)
		if _active_filter == "TITULARES" and idx < 5:
			filtered.append(p)
		elif _active_filter == "ROTAÇÃO" and idx >= 5 and idx < 10:
			filtered.append(p)
		elif _active_filter == "LESIONADOS" and p.get("status") == "LESIONADO":
			filtered.append(p)
		elif _active_filter == "JOVENS" and int(p.get("age", 0)) <= 22:
			filtered.append(p)
	return filtered

func _refresh_player_rows():
	_player_rows.clear()
	var list = get_node_or_null("%PlayerList")
	if not list: return
	for c in list.get_children(): c.queue_free()

	for i in range(_get_filtered_players().size()):
		var d = _get_filtered_players()[i]
		var idx = _player_data_cache.find(d)
		var row = _PLAYER_ROW_SCENE.instantiate()
		row.player_data = d
		row.is_selected = (idx == _selected_player_idx)
		
		# Conecta o clique na linha para selecionar o jogador
		row.pressed.connect(func():
			_selected_player_idx = idx
			player_selected.emit(d)
			_refresh_player_rows()
			_refresh_detail()
		)
		
		# Atualiza a lista quando houver troca pelo context menu
		row.rotation_updated.connect(func():
			_load_roster()
			_refresh_all()
		)
		
		list.add_child(row)
		_player_rows.append(row)

func _refresh_detail():
	var panel: PlayerProfilePanel = get_node_or_null("%PlayerProfilePanel") as PlayerProfilePanel
	if not panel:
		# Fallback: search subtree by class type
		panel = find_child("PlayerProfilePanel", true, false) as PlayerProfilePanel
	if not panel:
		return
	
	if _selected_player_idx < 0 or _selected_player_idx >= _player_data_cache.size():
		panel.visible = false
		return
	
	panel.visible = true
	panel.display_player(_player_data_cache[_selected_player_idx])

func _load_roster():
	_player_data_cache.clear()
	var team = GameManager.get_user_team()
	if team and team.has("players") and team.players.size() > 0:
		for p in team.players:
			var attrs = p.get("attributes", {})
			var injury_days = int(p.get("injury_days", 0))
			var status = "LESIONADO" if injury_days > 0 else "ATIVO"
			var stamina_val = int(attrs.get("stamina", 100))
			if stamina_val < 40 and status == "ATIVO":
				status = "CANSADO"

			var height_cm = float(attrs.get("height_cm", 190.0))
			var height_str = "%0.2fm" % (height_cm / 100.0)
			
			var sal = p.get("salary", 0)
			var sal_str = "R$ %.1fM" % (float(sal) / 1000000.0) if sal >= 1000000 else "R$ %dK" % (sal / 1000)

			_player_data_cache.append({
				player_id = p.get("id", 0),
				pos = p.get("position", "PG"),
				name = p.get("first_name", "") + " " + p.get("last_name", "Jogador"),
				nickname = "",
				age = p.get("age", 20),
				ovr = round(p.get("overall", 50)),
				energy = stamina_val,
				contract = str(p.get("contract_year", 1)) + " anos",
				salary = sal_str,
				status = status,
				number = p.get("id", 0) % 99,
				height = height_str,
				attrs = attrs,
				portrait_config = p.get("portrait_config", {})
			})
		
		# Reorder cache to match engine rotation_order if set
		var rotation_order = team.get("rotation_order", [])
		if rotation_order.size() > 0:
			var reordered = []
			for pid in rotation_order:
				var idx = -1
				for i in range(_player_data_cache.size()):
					if _player_data_cache[i].get("player_id", 0) == pid:
						idx = i
						break
				if idx >= 0:
					reordered.append(_player_data_cache[idx])
			for p in _player_data_cache:
				if not reordered.has(p):
					reordered.append(p)
			_player_data_cache = reordered
	else:
		# Fallback dummy data for editor testing
		_player_data_cache = [
			{pos = "PG", name = "Marcus Silva", nickname = "The Maestro", age = 28, ovr = 92, energy = 88, contract = "2 anos", salary = "R$ 2.4M", status = "ATIVO", number = 7, height = "1.91m", attrs = {speed = 82, strength = 68, stamina = 90, jumping = 78, height_cm = 191, weight_kg = 88, wingspan_cm = 198, three_pt = 94, mid_range = 92, close_shot = 88, dunk = 60, layup = 90, free_throw = 96, ball_handle = 96, passing = 94, offensive_rebound = 35, perimeter_def = 78, interior_def = 40, steal = 72, block = 30, defensive_rebound = 55, basketball_iq = 92, clutch = 88, leadership = 95, work_ethic = 90, potential = 85}},
			{pos = "SG", name = "João Pedro", nickname = "Sniper", age = 26, ovr = 88, energy = 76, contract = "3 anos", salary = "R$ 1.8M", status = "ATIVO", number = 11, height = "1.96m", attrs = {speed = 80, strength = 65, stamina = 82, jumping = 84, height_cm = 196, weight_kg = 92, wingspan_cm = 205, three_pt = 95, mid_range = 88, close_shot = 82, dunk = 78, layup = 85, free_throw = 90, ball_handle = 84, passing = 78, offensive_rebound = 40, perimeter_def = 72, interior_def = 45, steal = 68, block = 35, defensive_rebound = 50, basketball_iq = 85, clutch = 82, leadership = 70, work_ethic = 88, potential = 82}},
			{pos = "SF", name = "Carlos Mendez", nickname = "", age = 24, ovr = 82, energy = 95, contract = "1 ano", salary = "R$ 1.2M", status = "ATIVO", number = 23, height = "2.01m", attrs = {}},
			{pos = "PF", name = "Anderson Costa", nickname = "The Wall", age = 31, ovr = 85, energy = 80, contract = "4 anos", salary = "R$ 3.0M", status = "ATIVO", number = 34, height = "2.08m", attrs = {}},
			{pos = "C", name = "Tyrone Walker", nickname = "Big T", age = 29, ovr = 89, energy = 70, contract = "2 anos", salary = "R$ 4.5M", status = "CANSADO", number = 55, height = "2.13m", attrs = {}},
			{pos = "PG", name = "Lucas Almeida", nickname = "Flash", age = 21, ovr = 75, energy = 100, contract = "0.5 ano", salary = "R$ 400K", status = "ATIVO", number = 0, height = "1.85m", attrs = {}},
			{pos = "SG", name = "Diego Ramos", nickname = "", age = 25, ovr = 78, energy = 92, contract = "2 anos", salary = "R$ 800K", status = "ATIVO", number = 13, height = "1.93m", attrs = {}},
			{pos = "SF", name = "Rafael Souza", nickname = "", age = 27, ovr = 80, energy = 85, contract = "1 ano", salary = "R$ 1.1M", status = "ATIVO", number = 9, height = "2.00m", attrs = {}},
			{pos = "PF", name = "Bruno Oliveira", nickname = "", age = 22, ovr = 74, energy = 98, contract = "3 anos", salary = "R$ 600K", status = "ATIVO", number = 21, height = "2.06m", attrs = {}},
			{pos = "C", name = "Pedro Henrique", nickname = "", age = 30, ovr = 76, energy = 65, contract = "1 ano", salary = "R$ 900K", status = "LESIONADO", number = 42, height = "2.11m", attrs = {}}
		]
