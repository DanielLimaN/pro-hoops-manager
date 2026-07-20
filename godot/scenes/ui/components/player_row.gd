@tool
extends PanelContainer
class_name PlayerRow

@export var is_selected: bool = false:
	set(val):
		is_selected = val
		_update_styles()

@export var player_data: Dictionary = {}:
	set(val):
		player_data = val
		_update_data()

var star_texture = preload("res://addons/at-icons/control/star.svg")

signal pressed
signal rotation_updated

var _is_hovered: bool = false
var _tween: Tween

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	
	# 🔥 CRÍTICO: Todos os filhos devem IGNORAR mouse, senão Labels/TextureRects
	# interceptam o clique antes do PanelContainer receber o gui_input.
	_recursive_set_mouse_ignore(self)
	
	# Garantir que o estilo seja local para cada instância poder animar separadamente
	var style = get_theme_stylebox("panel")
	if style:
		add_theme_stylebox_override("panel", style.duplicate())
		
	_update_styles(0.0)
	
	if player_data.size() > 0:
		_update_data()
	elif Engine.is_editor_hint():
		player_data = {"pos": "PG", "in": "MS", "n": "Marcus Silva", "sub": "The Maestro", "i": 28, "ovr": 92, "en": 88, "ct": "2 anos", "sal": "R$ 2.4M", "st": "ATIVO"}
		_update_data()

func _recursive_set_mouse_ignore(node: Node):
	for child in node.get_children():
		if child is Control and child != self:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_recursive_set_mouse_ignore(child)

func _on_mouse_entered():
	_is_hovered = true
	_update_styles(0.15)

func _on_mouse_exited():
	_is_hovered = false
	_update_styles(0.15)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_show_context_menu()

func _show_context_menu():
	# FECHAR MENUS ABERTOS ANTES DE CRIAR UM NOVO (Resolve os menus duplicados)
	for child in get_tree().current_scene.get_children():
		if child.name == "ContextMenu":
			child.queue_free()
			
	var context_menu_scene = load("res://scenes/ui/components/context_menu.tscn")
	if not context_menu_scene: return
	var menu = context_menu_scene.instantiate()
	menu.name = "ContextMenu"
	
	var pos = player_data.get("pos", "PG")
	var same_pos = []
	var bench = []
	
	var team = GameManager.get_user_team()
	if team and team.has("players"):
		var players = team.players
		var clicked_id = player_data.get("player_id", 0)
		
		var rotation = team.get("rotation_order", [])
		var has_rotation = rotation.size() > 0
		
		if has_rotation:
			# Rotation definida: candidatos são quem NÃO está no quinteto titular
			var is_starter = false
			var idx = rotation.find(clicked_id)
			if idx >= 0 and idx < 5:
				is_starter = true
			
			for i in range(rotation.size()):
				var pid = rotation[i]
				if is_starter and i < 5: continue
				if not is_starter and i >= 5: continue
				
				var candidate = _find_player_by_id(players, pid)
				if candidate:
					var bp_dict = _format_player_data(candidate)
					bench.append(bp_dict)
					if bp_dict.get("pos") == pos:
						same_pos.append(bp_dict)
		else:
			# Sem rotation definida: todos os outros jogadores são candidatos
			for p in players:
				var pid = p.get("id", -1)
				if pid == clicked_id: continue
				var bp_dict = _format_player_data(p)
				bench.append(bp_dict)
				if bp_dict.get("pos") == pos:
					same_pos.append(bp_dict)
					
	menu.set_menu_data(player_data, pos, same_pos, bench)
	menu.player_swap_requested.connect(_on_player_swap_requested)
	
	var parent = get_tree().current_scene
	if parent:
		parent.add_child(menu)
		# Agora informamos a posição do mouse para o Menu se autoposicionar dentro do Canvas
		if menu.has_method("spawn_at"):
			menu.spawn_at(get_global_mouse_position())

func _find_player_by_id(players: Array, pid: int) -> Dictionary:
	for p in players:
		if p.get("id", -1) == pid:
			return p
	return {}

func _format_player_data(p: Dictionary) -> Dictionary:
	return {
		"player_id": p.get("id", 0),
		"pos": p.get("position", "PG"),
		"name": p.get("first_name", "") + " " + p.get("last_name", "Jogador"),
		"age": p.get("age", 20),
		"ovr": round(p.get("overall", 50))
	}
	
func _on_player_swap_requested(source: Dictionary, target: Dictionary):
	var team = GameManager.get_user_team()
	if team and team.has("rotation_order"):
		var rotation = team.get("rotation_order", [])
		var s_id = source.get("player_id")
		var t_id = target.get("player_id")
		
		var s_idx = rotation.find(s_id)
		var t_idx = rotation.find(t_id)
		
		if s_idx >= 0 and t_idx >= 0:
			var temp = rotation[s_idx]
			rotation[s_idx] = rotation[t_idx]
			rotation[t_idx] = temp
			
			GameManager.set_rotation_order(GameManager.user_team_id, rotation)
			rotation_updated.emit()

func _update_styles(duration: float = 0.0):
	var root_style = get_theme_stylebox("panel") as StyleBoxFlat
	if not root_style: return
		
	var target_bg = Color.TRANSPARENT
	var target_border = 0
	var name_color = ThemeConfig.TEXT_SEC
	
	if is_selected:
		target_bg = ThemeConfig.BRAND_SOFT
		target_border = 3
		name_color = ThemeConfig.TEXT
	elif _is_hovered:
		target_bg = Color(ThemeConfig.BRAND_SOFT.r, ThemeConfig.BRAND_SOFT.g, ThemeConfig.BRAND_SOFT.b, 0.06)
		target_border = 3
		name_color = ThemeConfig.TEXT
		
	root_style.border_color = ThemeConfig.BRAND_PRIMARY
	
	if Engine.is_editor_hint(): duration = 0.0
	
	if _tween and _tween.is_running():
		_tween.kill()
		
	if duration <= 0.0:
		root_style.bg_color = target_bg
		root_style.border_width_left = target_border
		if has_node("%NameLabel"):
			%NameLabel.add_theme_color_override("font_color", name_color)
	else:
		_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(root_style, "bg_color", target_bg, duration)
		_tween.tween_property(root_style, "border_width_left", target_border, duration)
		if has_node("%NameLabel"):
			# A cor da fonte precisa ser setada por tween step ou color_override, 
			# Tween em font_color não é trivial se o override não existir antes, então apenas aplicamos direto
			%NameLabel.add_theme_color_override("font_color", name_color)

func _update_data():
	if not is_inside_tree() or player_data.is_empty(): return
	
	var pos = player_data.get("pos", "PG")
	var ovr = player_data.get("ovr", 80)
	var en = player_data.get("energy", 100)
	
	# PosBadge
	%PosLabel.text = pos
	var pos_style = %PosBadge.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if pos == "PG":
		pos_style.bg_color = ThemeConfig.BRAND_SOFT
		pos_style.border_color = ThemeConfig.BRAND_PRIMARY
		%PosLabel.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
	elif pos == "SG":
		pos_style.bg_color = Color("#60A5FA22")
		pos_style.border_color = ThemeConfig.INFO
		%PosLabel.add_theme_color_override("font_color", ThemeConfig.INFO)
	else:
		pos_style.bg_color = Color(ThemeConfig.BORDER_DEFAULT, 0.22)
		pos_style.border_color = ThemeConfig.BORDER_DEFAULT
		%PosLabel.add_theme_color_override("font_color", ThemeConfig.TEXT_SEC)
	%PosBadge.add_theme_stylebox_override("panel", pos_style)
	
	# Avatar
	var full_name = player_data.get("name", "Player Name")
	var init_str = "XX"
	var name_parts = full_name.split(" ", false)
	if name_parts.size() >= 2:
		init_str = name_parts[0][0] + name_parts[1][0]
	elif name_parts.size() == 1:
		init_str = name_parts[0][0]
	
	if player_data.has("portrait_config"):
		%InitialsLabel.hide()
		%Portrait.show()
		%Portrait.render_portrait(player_data.portrait_config)
	else:
		%InitialsLabel.show()
		%InitialsLabel.text = init_str
		if has_node("%Portrait"):
			%Portrait.hide()
	
	var avatar_style = %AvatarPanel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if player_data.has("portrait_config"):
		# Fundo neutro/escuro sutil para destacar o pixel art
		avatar_style.bg_color = Color(0, 0, 0, 0.2)
	else:
		if pos in ["PG", "SF", "PF"]:
			avatar_style.bg_color = ThemeConfig.BRAND_DEEP
		else:
			avatar_style.bg_color = Color("#2563EB") # fallback blue darkened
	%AvatarPanel.add_theme_stylebox_override("panel", avatar_style)
	
	# Name & Nick
	%NameLabel.text = full_name
	
	var nick = player_data.get("nickname", "")
	%NickLabel.text = nick.to_upper() if nick != "" else ""
	
	# Age
	%AgeLabel.text = str(player_data.get("age", 0))
	
	# OVR
	%OvrLabel.text = str(int(ovr))
	var ovr_style = %OvrBadge.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	var ovr_color = ThemeConfig.BRAND_PRIMARY if ovr >= 90 else ThemeConfig.SUCCESS
	var ovr_bg_color = Color(ovr_color, 0.133)
	
	ovr_style.bg_color = ovr_bg_color
	ovr_style.border_color = ovr_color
	%OvrLabel.add_theme_color_override("font_color", ovr_color)
	%OvrBadge.add_theme_stylebox_override("panel", ovr_style)
	
	# Form (Stars)
	var form_val = 3
	if ovr >= 90: form_val = 5
	elif ovr >= 85: form_val = 4
	
	var i = 0
	for star in %StarsHBox.get_children():
		star.modulate = ThemeConfig.WARNING if i < form_val else ThemeConfig.BORDER_DEFAULT
		i += 1
	
	# Energy
	%EnergyBarFill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	%EnergyBarFill.custom_minimum_size.x = 74 * (en / 100.0)
	%EnergyLabel.text = str(en) + "%"
	
	# Contract
	%ContractLabel.text = player_data.get("contract", "")
	
	# Salary
	%SalaryLabel.text = player_data.get("salary", "")
	
	# Status
	var st = player_data.get("status", "ATIVO")
	%StatusLabel.text = st
	
	var status_style = %StatusBg.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	var st_color = ThemeConfig.SUCCESS
	if st == "CANSADO":
		st_color = ThemeConfig.WARNING
	elif st == "LESIONADO":
		st_color = ThemeConfig.DANGER
		
	status_style.bg_color = Color(st_color.r, st_color.g, st_color.b, 0.133)
	status_style.border_color = st_color
	%StatusLabel.add_theme_color_override("font_color", st_color)
	%StatusBg.add_theme_stylebox_override("panel", status_style)
