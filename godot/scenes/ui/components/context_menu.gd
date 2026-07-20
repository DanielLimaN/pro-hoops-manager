@tool
extends Control
class_name ContextMenu

signal menu_item_selected(action_id: String, player_data: Dictionary)
signal player_swap_requested(source_data: Dictionary, target_data: Dictionary)
signal closed

var player_data: Dictionary = {} :
	set(d):
		player_data = d
		if is_node_ready():
			_refresh()

var same_position_players: Array = []
var bench_players: Array = []
var player_position: String = ""

var _submenu: PanelContainer = null

var _option_replace: PanelContainer
var _backdrop: Control

var _menu_panel: PanelContainer
var _init_lbl: Label
var _name_lbl: Label
var _sub_lbl: Label
var _target_pos: Vector2 = Vector2.ZERO

const BG_COLOR = Color("#0F0720")
const BORDER_COLOR = Color("#FBBF24")
const SUB_BORDER_COLOR = Color("#3B82F6")

func spawn_at(pos: Vector2):
	_target_pos = pos + Vector2(10, 10)
	if _menu_panel and is_instance_valid(_menu_panel):
		_menu_panel.global_position = _clamp_to_viewport(_target_pos, _menu_panel)

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_backdrop()
	_build_menu()
	_refresh()
	if _target_pos != Vector2.ZERO and _menu_panel:
		_menu_panel.global_position = _clamp_to_viewport(_target_pos, _menu_panel)

func _clamp_to_viewport(target_pos: Vector2, control: Control, margin: int = 8) -> Vector2:
	# Tenta usar o tamanho real do control; se ainda não foi calculado,
	# usa combined_minimum_size como estimativa conservadora
	var control_size: Vector2 = control.size
	if control_size.y <= 0:
		control_size = control.get_combined_minimum_size()
		if control_size.y <= 0:
			control_size = control.custom_minimum_size

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var clamped: Vector2 = target_pos

	# Clamp horizontal
	var max_x: float = viewport_size.x - control_size.x - margin
	clamped.x = clampf(clamped.x, margin, maxf(margin, max_x))

	# Clamp vertical: se ultrapassar a borda inferior, sobe o menu
	var max_y: float = viewport_size.y - control_size.y - margin
	clamped.y = clampf(clamped.y, margin, maxf(margin, max_y))

	return clamped

func _build_backdrop():
	_backdrop = Control.new()
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(_on_backdrop_gui_input)
	add_child(_backdrop)
	move_child(_backdrop, 0)

func _build_menu():
	var menu_style = StyleBoxFlat.new()
	menu_style.bg_color = BG_COLOR
	menu_style.border_color = BORDER_COLOR
	menu_style.border_width_left = 2
	menu_style.border_width_top = 2
	menu_style.border_width_right = 2
	menu_style.border_width_bottom = 2
	menu_style.corner_radius_top_left = 12
	menu_style.corner_radius_top_right = 12
	menu_style.corner_radius_bottom_left = 12
	menu_style.corner_radius_bottom_right = 12
	menu_style.shadow_color = Color(0, 0, 0, 0.8)
	menu_style.shadow_size = 32
	menu_style.shadow_offset = Vector2(0, 12)
	menu_style.content_margin_left = 0
	menu_style.content_margin_top = 0
	menu_style.content_margin_right = 0
	menu_style.content_margin_bottom = 0
	_menu_panel = PanelContainer.new()
	_menu_panel.add_theme_stylebox_override("panel", menu_style)
	_menu_panel.custom_minimum_size = Vector2(280, 0)
	add_child(_menu_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_menu_panel.add_child(vbox)

	# ── Header Gradient ──
	var header_panel = PanelContainer.new()
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color("#FBBF24")
	header_style.corner_radius_top_left = 10
	header_style.corner_radius_top_right = 10
	header_style.content_margin_left = 14
	header_style.content_margin_top = 10
	header_style.content_margin_right = 14
	header_style.content_margin_bottom = 10
	header_panel.add_theme_stylebox_override("panel", header_style)
	vbox.add_child(header_panel)

	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	header_panel.add_child(header_hbox)

	var avatar = PanelContainer.new()
	var av_style = StyleBoxFlat.new()
	av_style.bg_color = Color("#A78BFA")
	av_style.border_color = Color("#0B0514")
	av_style.border_width_left = 2
	av_style.border_width_top = 2
	av_style.border_width_right = 2
	av_style.border_width_bottom = 2
	av_style.corner_radius_top_left = 14
	av_style.corner_radius_top_right = 14
	av_style.corner_radius_bottom_right = 14
	av_style.corner_radius_bottom_left = 14
	avatar.add_theme_stylebox_override("panel", av_style)
	avatar.custom_minimum_size = Vector2(28, 28)
	header_hbox.add_child(avatar)
	
	_init_lbl = Label.new()
	_init_lbl.text = "MS"
	_init_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_init_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_init_lbl.add_theme_color_override("font_color", Color.WHITE)
	if not Engine.is_editor_hint(): _init_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	_init_lbl.add_theme_font_size_override("font_size", 10)
	avatar.add_child(_init_lbl)

	var titles_vbox = VBoxContainer.new()
	titles_vbox.add_theme_constant_override("separation", 1)
	titles_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(titles_vbox)

	_name_lbl = Label.new()
	_name_lbl.text = "Marcus Silva"
	_name_lbl.add_theme_color_override("font_color", Color("#0B0514"))
	if not Engine.is_editor_hint(): _name_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	_name_lbl.add_theme_font_size_override("font_size", 12)
	titles_vbox.add_child(_name_lbl)

	_sub_lbl = Label.new()
	_sub_lbl.text = "PG · #7 · OVR 92"
	_sub_lbl.add_theme_color_override("font_color", Color(0x0b/255.0, 0x05/255.0, 0x14/255.0, 0.53))
	if not Engine.is_editor_hint(): _sub_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	_sub_lbl.add_theme_font_size_override("font_size", 9)
	titles_vbox.add_child(_sub_lbl)

	var close_btn = PanelContainer.new()
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0x0b/255.0, 0x05/255.0, 0x14/255.0, 0.53)
	close_style.corner_radius_top_left = 10
	close_style.corner_radius_top_right = 10
	close_style.corner_radius_bottom_right = 10
	close_style.corner_radius_bottom_left = 10
	close_btn.add_theme_stylebox_override("panel", close_style)
	close_btn.custom_minimum_size = Vector2(20, 20)
	close_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header_hbox.add_child(close_btn)

	var cross_icon = TextureRect.new()
	var cross_path = "res://addons/at-icons/control/cross.svg"
	if ResourceLoader.exists(cross_path):
		cross_icon.texture = load(cross_path)
	cross_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cross_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cross_icon.custom_minimum_size = Vector2(10, 10)
	cross_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cross_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cross_icon.modulate = Color("#1F1432") # Preto/roxo bem escuro para contrastar no amarelo
	close_btn.add_child(cross_icon)

	# Fazer o botão de fechar funcionar ao clique (botão invisível em cima dele)
	var real_close_btn = Button.new()
	real_close_btn.flat = true
	real_close_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	real_close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	real_close_btn.pressed.connect(_close)
	close_btn.add_child(real_close_btn)

	var action_margin = MarginContainer.new()
	action_margin.add_theme_constant_override("margin_left", 8)
	action_margin.add_theme_constant_override("margin_right", 8)
	action_margin.add_theme_constant_override("margin_bottom", 8)
	vbox.add_child(action_margin)

	var actions_vbox = VBoxContainer.new()
	actions_vbox.add_theme_constant_override("separation", 2)
	action_margin.add_child(actions_vbox)

	_option_replace = _make_menu_item("replace", "arrow_right_arrow_left", "Substituir na Rotação", "Trocar por reserva disponível", Color("#3B82F6"), true)
	actions_vbox.add_child(_option_replace)
	
	actions_vbox.add_child(_make_menu_item("view_profile", "human", "Ver Perfil Completo", "Atributos, histórico, contrato", Color("#A78BFA"), false))
	actions_vbox.add_child(_make_menu_item("renew_contract", "file", "Renovar Contrato", "Expira em 2 anos · R$ 2.4M/mês", Color("#10B981"), false, true))
	actions_vbox.add_child(_make_menu_item("training", "basketball", "Programa Individual", "Designar treino específico", Color("#60A5FA"), false))
	actions_vbox.add_child(_make_menu_item("chat", "speech_bubble_exclamation", "Conversar", "Discussão sobre forma/papel", Color("#F472B6"), false))
	
	var div = ColorRect.new()
	div.color = Color("#1F1432")
	div.custom_minimum_size = Vector2(0, 1)
	actions_vbox.add_child(div)
	
	actions_vbox.add_child(_make_menu_item("sell", "tag", "Listar para Venda", "Disponibilizar no mercado", Color("#FBBF24"), false))
	actions_vbox.add_child(_make_menu_item("release", "doorway_exit", "Dispensar Jogador", "Rescindir contrato", Color("#EF4444"), false))

func _make_menu_item(action_id: String, icon_name: String, title: String, subtitle: String, tint: Color, has_submenu: bool, show_action_tag: bool = false) -> PanelContainer:
	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var s_normal = StyleBoxFlat.new()
	s_normal.bg_color = Color.TRANSPARENT
	s_normal.content_margin_left = 12
	s_normal.content_margin_right = 12
	s_normal.content_margin_top = 10
	s_normal.content_margin_bottom = 10
	s_normal.corner_radius_top_left = 6
	s_normal.corner_radius_top_right = 6
	s_normal.corner_radius_bottom_right = 6
	s_normal.corner_radius_bottom_left = 6
	row.add_theme_stylebox_override("panel", s_normal)

	var s_hover = s_normal.duplicate()
	s_hover.bg_color = Color(tint, 0.13)
	s_hover.border_width_left = 1
	s_hover.border_width_top = 1
	s_hover.border_width_right = 1
	s_hover.border_width_bottom = 1
	s_hover.border_color = tint

	if show_action_tag:
		s_normal.bg_color = Color(tint, 0.13)
		s_normal.border_width_left = 1
		s_normal.border_width_top = 1
		s_normal.border_width_right = 1
		s_normal.border_width_bottom = 1
		s_normal.border_color = tint

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)

	var ic_panel = PanelContainer.new()
	var ic_style = StyleBoxFlat.new()
	ic_style.bg_color = Color(tint, 0.13)
	ic_style.corner_radius_top_left = 6
	ic_style.corner_radius_top_right = 6
	ic_style.corner_radius_bottom_right = 6
	ic_style.corner_radius_bottom_left = 6
	ic_panel.add_theme_stylebox_override("panel", ic_style)
	ic_panel.custom_minimum_size = Vector2(28, 28)
	ic_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(ic_panel)

	# Injetando o icone do at-icons
	if icon_name != "":
		var icon_path = "res://addons/at-icons/control/" + icon_name + ".svg"
		if ResourceLoader.exists(icon_path):
			var icon_rect = TextureRect.new()
			icon_rect.texture = load(icon_path)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.custom_minimum_size = Vector2(14, 14)
			icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			icon_rect.modulate = tint
			ic_panel.add_child(icon_rect)
			
	var text_vbox = VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 1)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(text_vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	if not Engine.is_editor_hint(): title_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	title_lbl.add_theme_font_size_override("font_size", 13)
	text_vbox.add_child(title_lbl)
	
	var sub_lbl = Label.new()
	sub_lbl.text = subtitle
	sub_lbl.add_theme_color_override("font_color", Color("#6B5B95") if not show_action_tag else tint)
	if not Engine.is_editor_hint(): sub_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	sub_lbl.add_theme_font_size_override("font_size", 11)
	text_vbox.add_child(sub_lbl)
	
	if show_action_tag:
		var action_panel = PanelContainer.new()
		var action_s = StyleBoxFlat.new()
		action_s.bg_color = Color(tint, 0.13)
		action_s.border_width_left = 1
		action_s.border_width_top = 1
		action_s.border_width_right = 1
		action_s.border_width_bottom = 1
		action_s.border_color = tint
		action_s.corner_radius_top_left = 3
		action_s.corner_radius_top_right = 3
		action_s.corner_radius_bottom_right = 3
		action_s.corner_radius_bottom_left = 3
		action_panel.add_theme_stylebox_override("panel", action_s)
		action_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var act_l = Label.new()
		act_l.text = "AÇÃO"
		act_l.add_theme_color_override("font_color", tint)
		if not Engine.is_editor_hint(): act_l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		act_l.add_theme_font_size_override("font_size", 9)
		action_panel.add_child(act_l)
		hbox.add_child(action_panel)
	
	# Garantir que os labels/texturas dentro do row não interfiram no hover
	_make_children_ignore_mouse(row)
	
	row.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if has_submenu:
				# 🔥 Clique no item "Substituir na Rotação" → abre submenu
				_show_submenu()
			else:
				menu_item_selected.emit(action_id, player_data)
				_close()
	)
	
	row.mouse_entered.connect(func(): 
		row.add_theme_stylebox_override("panel", s_hover))
	row.mouse_exited.connect(func(): 
		row.add_theme_stylebox_override("panel", s_normal if not show_action_tag else s_hover))

	return row

func _create_icon(icon_name: String, size: int, color: Color) -> TextureRect:
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_path = "res://addons/at-icons/control/" + icon_name + ".svg"
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	icon.modulate = color
	return icon

func _show_submenu():
	_hide_submenu()
	# Deduplica: jogadores em same_position_players não devem aparecer
	# duas vezes (eles também estão em bench_players no player_row.gd)
	var seen_ids: Dictionary = {}
	var candidates: Array = []
	for p in same_position_players + bench_players:
		var pid = p.get("player_id", 0)
		if not seen_ids.has(pid):
			seen_ids[pid] = true
			candidates.append(p)
	print("[ContextMenu] _show_submenu candidates=", candidates.size(), " same_pos=", same_position_players.size(), " bench=", bench_players.size())
	if candidates.is_empty():
		print("[ContextMenu] ❌ NO CANDIDATES — submenu não será exibido")
		return
	
	var submenu_scene = load("res://scenes/ui/components/substitution_submenu.tscn")
	if not submenu_scene:
		print("[ContextMenu] ❌ substitution_submenu.tscn FAILED TO LOAD")
		return
	print("[ContextMenu] ✅ substitution_submenu.tscn loaded OK")
	
	_submenu = submenu_scene.instantiate()
	add_child(_submenu)
	print("[ContextMenu] ✅ Submenu instanciado e adicionado à cena")
	
	_submenu.setup(player_data, player_position, candidates)
	_submenu.player_swap_requested.connect(func(src, tgt):
		player_swap_requested.emit(src, tgt)
		_close()
	)

	_position_submenu()

func _position_submenu():
	if not _submenu: return
	var main_pos = _menu_panel.global_position
	var main_size = _menu_panel.size
	var sub_x = main_pos.x + main_size.x + 12
	var sub_y = _option_replace.get_global_rect().position.y - 12
	_submenu.global_position = _clamp_to_viewport(Vector2(sub_x, sub_y), _submenu)

func _hide_submenu():

	if _submenu and is_instance_valid(_submenu): _submenu.queue_free()
	_submenu = null

func _make_children_ignore_mouse(node: Control):
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_make_children_ignore_mouse(child)

func set_menu_data(data: Dictionary, pos: String, same_pos_players: Array, bench_players_list: Array):
	player_data = data; player_position = pos; same_position_players = same_pos_players; bench_players = bench_players_list
	_refresh()

func _refresh():
	if not is_node_ready() or player_data.is_empty(): return
	
	if _name_lbl and player_data.has("name"):
		_name_lbl.text = player_data.name
		
	if _init_lbl and player_data.has("name"):
		var parts = player_data.name.split(" ", false)
		if parts.size() >= 2:
			_init_lbl.text = parts[0][0] + parts[1][0]
		elif parts.size() > 0:
			_init_lbl.text = parts[0][0]
			
	if _sub_lbl:
		var num = player_data.get("number", 0)
		var ovr = player_data.get("ovr", 80)
		_sub_lbl.text = player_position + " · #" + str(num) + " · OVR " + str(ovr)
		
	# Injetar Portrait se existir
	if player_data.has("portrait_config") and _init_lbl:
		var avatar_panel = _init_lbl.get_parent()
		var portrait_scene_path = "res://scenes/ui/components/PortraitRenderer.tscn"
		if ResourceLoader.exists(portrait_scene_path):
			_init_lbl.hide()
			var pr = load(portrait_scene_path).instantiate()
			pr.custom_minimum_size = Vector2(28, 28)
			pr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			
			var st = avatar_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			st.bg_color = Color("#150826") # Fundo escuro para contrastar o pixel art
			st.border_color = Color("#0B0514")
			st.border_width_left = 2
			st.border_width_top = 2
			st.border_width_right = 2
			st.border_width_bottom = 2
			avatar_panel.add_theme_stylebox_override("panel", st)
			
			avatar_panel.add_child(pr)
			pr.render_portrait(player_data.portrait_config)
func _on_backdrop_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: _close()

func _close():
	_hide_submenu(); closed.emit(); queue_free()
