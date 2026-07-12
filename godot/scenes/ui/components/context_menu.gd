@tool
extends PanelContainer
class_name ContextMenu

## Emitted when a simple menu action is clicked (e.g. "view_profile").
signal menu_item_selected(action_id: String, player_data: Dictionary)

## Emitted when a player is chosen from a submenu to swap.
signal player_swap_requested(source_data: Dictionary, target_data: Dictionary)

## Emitted when the menu is dismissed.
signal closed

# ─── Data ──────────────────────────────────────────────────────────────────────

## The player data dictionary for the clicked starter row.
var player_data: Dictionary = {} :
	set(d):
		player_data = d
		if is_node_ready():
			_refresh()

## Array of candidate Dictionaries for same-position replacement.
var same_position_players: Array = []

## Array of candidate Dictionaries for bench replacement.
var bench_players: Array = []

## The position string (PG, SG, SF, PF, C) of the clicked starter.
var player_position: String = ""

# ─── Submenu state ─────────────────────────────────────────────────────────────

var _submenu: PanelContainer = null
var _submenu_open_queued: bool = false
var _submenu_close_queued: bool = false
var _submenu_timer: Timer
var _current_submenu_target: String = ""

# ─── Node references ───────────────────────────────────────────────────────────

var _header_lbl: Label
var _option_same: PanelContainer
var _option_bench: PanelContainer
var _option_profile: PanelContainer
var _backdrop: Control

# ─── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready():
	_build_backdrop()
	_build_menu()
	_build_submenu_timer()
	_refresh()


func _build_backdrop():
	_backdrop = Control.new()
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(_on_backdrop_gui_input)
	add_child(_backdrop)
	move_child(_backdrop, 0)


func _build_submenu_timer():
	_submenu_timer = Timer.new()
	_submenu_timer.one_shot = true
	_submenu_timer.timeout.connect(_on_submenu_timer_timeout)
	add_child(_submenu_timer)


func _build_menu():
	# ── Menu panel style ─────────────────────────────────────────────────
	var menu_style = StyleBoxFlat.new()
	if Engine.is_editor_hint():
		menu_style.bg_color = Color("#0F0720")
		menu_style.border_color = Color("#1F1432")
	else:
		menu_style.bg_color = ThemeConfig.BG_SURFACE
		menu_style.border_color = ThemeConfig.BORDER_SUBTLE
	menu_style.corner_radius_top_left = 8
	menu_style.corner_radius_top_right = 8
	menu_style.corner_radius_bottom_left = 8
	menu_style.corner_radius_bottom_right = 8
	menu_style.border_width_left = 1
	menu_style.border_width_top = 1
	menu_style.border_width_right = 1
	menu_style.border_width_bottom = 1
	menu_style.shadow_color = Color(0, 0, 0, 0.6)
	menu_style.shadow_size = 24
	menu_style.shadow_offset = Vector2(0, 4)
	menu_style.content_margin_left = 0
	menu_style.content_margin_top = 0
	menu_style.content_margin_right = 0
	menu_style.content_margin_bottom = 0
	add_theme_stylebox_override("panel", menu_style)

	mouse_filter = Control.MOUSE_FILTER_PASS

	# ── Menu layout ─────────────────────────────────────────────────────
	var vbox = VBoxContainer.new()
	vbox.name = "MenuVBox"
	vbox.add_theme_constant_override("separation", 0)
	vbox.modulate = Color.WHITE
	add_child(vbox)

	# ── Section header: "SUBSTITUIR" ────────────────────────────────────
	var header_margin = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 12)
	header_margin.add_theme_constant_override("margin_right", 12)
	header_margin.add_theme_constant_override("margin_top", 10)
	header_margin.add_theme_constant_override("margin_bottom", 4)

	_header_lbl = Label.new()
	_header_lbl.text = "SUBSTITUIR"
	if not Engine.is_editor_hint():
		_header_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		_header_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	else:
		_header_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
	_header_lbl.add_theme_font_size_override("font_size", 9)
	_header_lbl.add_theme_constant_override("letter_spacing", 1)
	header_margin.add_child(_header_lbl)
	vbox.add_child(header_margin)

	# ── Option 1: Same Position (with submenu) ──────────────────────────
	_option_same = _make_menu_item("same_position", "arrow_right_arrow_left", "", true)
	vbox.add_child(_option_same)

	# ── Option 2: Bench (with submenu) ──────────────────────────────────
	_option_bench = _make_menu_item("bench", "human", "", true)
	vbox.add_child(_option_bench)

	# ── Divider ─────────────────────────────────────────────────────────
	var div_container = MarginContainer.new()
	div_container.add_theme_constant_override("margin_left", 8)
	div_container.add_theme_constant_override("margin_right", 8)
	div_container.add_theme_constant_override("margin_top", 4)
	div_container.add_theme_constant_override("margin_bottom", 4)

	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if Engine.is_editor_hint():
		divider.color = Color("#1F1432")
	else:
		divider.color = ThemeConfig.BORDER_SUBTLE
	div_container.add_child(divider)
	vbox.add_child(div_container)

	# ── Option 3: View Full Profile (no submenu) ────────────────────────
	_option_profile = _make_menu_item("view_profile", "arrow_up_right", "Ver Perfil Completo", false)
	vbox.add_child(_option_profile)

	# ── Bottom padding ──────────────────────────────────────────────────
	var bottom_pad = MarginContainer.new()
	bottom_pad.add_theme_constant_override("margin_bottom", 4)
	vbox.add_child(bottom_pad)


# ─── Creates a single menu item row ────────────────────────────────────────────

func _make_menu_item(action_id: String, icon_name: String, label: String, has_submenu: bool) -> PanelContainer:
	var row = PanelContainer.new()
	row.name = "MenuItem_" + action_id
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_STOP

	# Store metadata
	row.set_meta("action_id", action_id)
	row.set_meta("has_submenu", has_submenu)

	# Default (no-hover) style
	var s_normal = StyleBoxFlat.new()
	s_normal.bg_color = Color.TRANSPARENT
	s_normal.corner_radius_top_left = 6
	s_normal.corner_radius_top_right = 6
	s_normal.corner_radius_bottom_left = 6
	s_normal.corner_radius_bottom_right = 6
	s_normal.content_margin_left = 8
	s_normal.content_margin_right = 8
	s_normal.content_margin_top = 5
	s_normal.content_margin_bottom = 5
	row.add_theme_stylebox_override("panel", s_normal)

	# Hover style
	var s_hover = s_normal.duplicate()
	if Engine.is_editor_hint():
		s_hover.bg_color = Color("#A78BFA22")
	else:
		s_hover.bg_color = ThemeConfig.BORDER_ACCENT_SOFT
		s_hover.bg_color.a = 0.13

	# ── Row content ─────────────────────────────────────────────────────
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Icon
	if not icon_name.is_empty():
		var icon = TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(14, 14)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var icon_path = "res://addons/at-icons/control/" + icon_name + ".svg"
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		if Engine.is_editor_hint():
			icon.modulate = Color("#94A3B8")
		else:
			icon.modulate = ThemeConfig.TEXT_MUTED
		hbox.add_child(icon)

	# Label
	var lbl = Label.new()
	lbl.name = "Label"
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not Engine.is_editor_hint():
		lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
		lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
	else:
		lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(0, 18)
	hbox.add_child(lbl)

	# Chevron for submenu items
	if has_submenu:
		var chevron = TextureRect.new()
		chevron.name = "Chevron"
		chevron.custom_minimum_size = Vector2(12, 12)
		chevron.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chevron.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var chevron_path = "res://addons/at-icons/control/arrow_right.svg"
		if ResourceLoader.exists(chevron_path):
			chevron.texture = load(chevron_path)
		if Engine.is_editor_hint():
			chevron.modulate = Color("#94A3B8")
		else:
			chevron.modulate = ThemeConfig.TEXT_MUTED
		hbox.add_child(chevron)

	row.add_child(hbox)

	# ── Clickable overlay (for non-submenu items) ───────────────────────
	if not has_submenu:
		var click_btn = Button.new()
		click_btn.flat = true
		click_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		click_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		click_btn.pressed.connect(func():
			menu_item_selected.emit(action_id, player_data)
			_close()
		)
		row.add_child(click_btn)

	# ── Hover highlight via mouse_entered/exited on the row ─────────────
	var is_hovered := false
	var has_submenu_local = has_submenu

	row.mouse_entered.connect(func():
		is_hovered = true
		row.add_theme_stylebox_override("panel", s_hover)
		if has_submenu_local:
			_queue_open_submenu(action_id)
	)
	row.mouse_exited.connect(func():
		is_hovered = false
		row.add_theme_stylebox_override("panel", s_normal)
		if has_submenu_local:
			_queue_close_submenu()
	)

	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	return row


# ─── Submenu ───────────────────────────────────────────────────────────────────

func _queue_open_submenu(action_id: String):
	_submenu_open_queued = true
	_submenu_close_queued = false
	_current_submenu_target = action_id
	_submenu_timer.start(0.15)


func _queue_close_submenu():
	if _submenu_close_queued:
		return
	_submenu_close_queued = true
	_submenu_open_queued = false
	_submenu_timer.start(0.25)


func _on_submenu_timer_timeout():
	if _submenu_open_queued:
		_show_submenu()
	elif _submenu_close_queued:
		if _submenu and not _is_mouse_over_submenu():
			_hide_submenu()


func _is_mouse_over_submenu() -> bool:
	if not _submenu or not is_instance_valid(_submenu):
		return false
	var mouse_pos = get_global_mouse_position()
	var submenu_rect = Rect2(_submenu.global_position, _submenu.size)
	return submenu_rect.has_point(mouse_pos)


func _show_submenu():
	_hide_submenu()

	var candidates: Array = []
	match _current_submenu_target:
		"same_position":
			candidates = same_position_players
		"bench":
			candidates = bench_players

	if candidates.is_empty():
		return

	_submenu = PanelContainer.new()
	_submenu.name = "Submenu"
	_submenu.mouse_filter = Control.MOUSE_FILTER_STOP

	# Submenu style
	var s = StyleBoxFlat.new()
	if Engine.is_editor_hint():
		s.bg_color = Color("#0F0720")
		s.border_color = Color("#1F1432")
	else:
		s.bg_color = ThemeConfig.BG_SURFACE
		s.border_color = ThemeConfig.BORDER_SUBTLE
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.shadow_color = Color(0, 0, 0, 0.6)
	s.shadow_size = 20
	s.shadow_offset = Vector2(0, 4)
	s.content_margin_left = 0
	s.content_margin_top = 0
	s.content_margin_right = 0
	s.content_margin_bottom = 0
	_submenu.add_theme_stylebox_override("panel", s)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)

	for candidate in candidates:
		var item = _make_submenu_item(candidate)
		vbox.add_child(item)

	_submenu.add_child(vbox)
	add_child(_submenu)

	# Position submenu to the right of the main menu, aligned with the triggering item
	_position_submenu()

	# Submenu hover tracking
	_submenu.mouse_entered.connect(func():
		_submenu_open_queued = false
		_submenu_close_queued = false
		_submenu_timer.stop()
	)
	_submenu.mouse_exited.connect(func():
		_queue_close_submenu()
	)


func _position_submenu():
	if not _submenu:
		return

	# Find which option triggered the submenu
	var source_item: PanelContainer
	match _current_submenu_target:
		"same_position":
			source_item = _option_same
		"bench":
			source_item = _option_bench
		_:
			return

	if not source_item or not is_instance_valid(source_item):
		return

	# Position: right of the main menu, vertically aligned with the source item
	var main_pos = global_position
	var main_size = size
	var item_global = source_item.get_global_rect()

	var sub_x = main_pos.x + main_size.x - 4  # slight overlap
	var sub_y = item_global.position.y - 4   # slight overlap with item

	_submenu.global_position = Vector2(sub_x, sub_y)

	# Ensure submenu stays within screen bounds
	var screen_size = DisplayServer.window_get_size()
	var sub_end = _submenu.global_position + _submenu.size
	if sub_end.x > screen_size.x:
		# Move submenu to the LEFT of the main menu if it overflows right
		_submenu.global_position.x = main_pos.x - _submenu.size.x + 4
	if sub_end.y > screen_size.y:
		_submenu.global_position.y = screen_size.y - _submenu.size.y - 8
	if _submenu.global_position.y < 0:
		_submenu.global_position.y = 8


func _make_submenu_item(candidate: Dictionary) -> PanelContainer:
	var item = PanelContainer.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	item.custom_minimum_size = Vector2(180, 32)

	# Default style
	var s_normal = StyleBoxFlat.new()
	s_normal.bg_color = Color.TRANSPARENT
	s_normal.content_margin_left = 10
	s_normal.content_margin_right = 10
	s_normal.content_margin_top = 5
	s_normal.content_margin_bottom = 5
	item.add_theme_stylebox_override("panel", s_normal)

	# Hover style
	var s_hover = s_normal.duplicate()
	if Engine.is_editor_hint():
		s_hover.bg_color = Color("#A78BFA22")
	else:
		s_hover.bg_color = ThemeConfig.BORDER_ACCENT_SOFT
		s_hover.bg_color.a = 0.13

	# ── Content: Name + OVR badge + Age ─────────────────────────────────
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Name
	var name_lbl = Label.new()
	name_lbl.text = candidate.get("name", "Jogador")
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not Engine.is_editor_hint():
		name_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
		name_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
	else:
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Truncate long names
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hbox.add_child(name_lbl)

	# OVR badge
	var ovr_val = int(candidate.get("ovr", 50))
	var ovr_c = _ovr_color(ovr_val)
	var ovr_lbl = Label.new()
	ovr_lbl.text = str(ovr_val)
	ovr_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	ovr_lbl.add_theme_font_size_override("font_size", 10)
	ovr_lbl.add_theme_color_override("font_color", ovr_c)
	ovr_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(ovr_lbl)

	# Age
	var age_lbl = Label.new()
	age_lbl.text = str(candidate.get("age", 0))
	age_lbl.add_theme_font_size_override("font_size", 10)
	if not Engine.is_editor_hint():
		age_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	else:
		age_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
	age_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(age_lbl)

	item.add_child(hbox)

	# ── Click handler ───────────────────────────────────────────────────
	var click_btn = Button.new()
	click_btn.flat = true
	click_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	click_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var source = player_data
	click_btn.pressed.connect(func():
		player_swap_requested.emit(source, candidate)
		_close()
	)
	item.add_child(click_btn)

	# ── Hover ───────────────────────────────────────────────────────────
	var is_hov := false
	item.mouse_entered.connect(func():
		is_hov = true
		item.add_theme_stylebox_override("panel", s_hover)
	)
	item.mouse_exited.connect(func():
		is_hov = false
		item.add_theme_stylebox_override("panel", s_normal)
	)

	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	return item


func _ovr_color(ovr: int) -> Color:
	if ovr >= 85:
		return Color("#A78BFA")
	elif ovr >= 75:
		return Color("#60A5FA")
	elif ovr >= 65:
		return Color("#FBBF24")
	else:
		return Color("#94A3B8")


func _hide_submenu():
	if _submenu and is_instance_valid(_submenu):
		_submenu.queue_free()
	_submenu = null
	_submenu_open_queued = false
	_submenu_close_queued = false
	_submenu_timer.stop()


# ─── Public API ───────────────────────────────────────────────────────────────

## Set the display data and refresh labels.
## `data`: the clicked starter's data dict.
## `pos`: position string (PG/SG/SF/PF/C).
## `same_pos_players`: Array of candidate player dicts with the same position.
## `bench_players_list`: Array of candidate player dicts from the bench.
func set_menu_data(data: Dictionary, pos: String, same_pos_players: Array, bench_players_list: Array):
	player_data = data
	player_position = pos
	same_position_players = same_pos_players
	bench_players = bench_players_list
	_refresh()


# ─── Internal ─────────────────────────────────────────────────────────────────

func _refresh():
	if not is_node_ready():
		return

	# Update dynamic labels
	var same_lbl = _find_label(_option_same)
	if same_lbl:
		var count = same_position_players.size()
		if count == 1:
			same_lbl.text = "%s (1 disponível)" % [player_position]
		else:
			same_lbl.text = "%s (%d disponíveis)" % [player_position, count]

	var bench_lbl = _find_label(_option_bench)
	if bench_lbl:
		var count = bench_players.size()
		if count == 1:
			bench_lbl.text = "Reservas (1 disponível)"
		else:
			bench_lbl.text = "Reservas (%d disponíveis)" % [count]


func _find_label(container: PanelContainer) -> Label:
	if not container:
		return null
	return container.find_child("Label", true, false)


func _on_backdrop_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close()


func _close():
	_hide_submenu()
	closed.emit()
	queue_free()


# ─── Editor hint data ─────────────────────────────────────────────────────────
func _editor_hint_setup():
	if Engine.is_editor_hint() and not is_inside_tree():
		player_position = "PG"
		same_position_players = [
			{name = "Lucas Almeida", ovr = 78, age = 21},
			{name = "Felipe Santos", ovr = 72, age = 25},
		]
		bench_players = [
			{name = "Diego Ramos", ovr = 81, age = 24},
			{name = "Rafael Souza", ovr = 79, age = 27},
			{name = "Bruno Oliveira", ovr = 76, age = 25},
		]
		_refresh()
