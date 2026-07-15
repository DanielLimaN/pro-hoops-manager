extends Control

signal player_selected(player_data: Dictionary)
signal quick_action_requested(player_data: Dictionary, global_pos: Vector2)
signal edit_rotation_requested
signal save_rotation_requested
signal cancel_rotation_requested

const COL_BG := Color("#06030E")
const COL_TOPBAR_BG := Color("#0B0514")
const COL_BORDER := Color("#1F1432")
const COL_SURFACE := Color("#0F0720")
const COL_SURFACE_ALT := Color("#150826")
const COL_BRAND := Color("#A78BFA")
const COL_BRAND_SOFT := Color("#A78BFA22")
const COL_BRAND_ACCENT := Color("#A78BFA66")
const COL_BRAND_DEEP := Color("#7C3AED")
const COL_SUCCESS := Color("#10B981")
const COL_WARNING := Color("#FBBF24")
const COL_DANGER := Color("#EF4444")
const COL_TEXT := Color("#FFFFFF")
const COL_TEXT_SEC := Color("#E0E7FF")
const COL_TEXT_MUTED := Color("#94A3B8")
const COL_TEXT_DISABLED := Color("#6B5B95")
const COL_INFO := Color("#60A5FA")
const COL_HIGHLIGHT := Color("#F472B6")

var _active_filter: String = "TODOS"
var _edit_mode: bool = false
var _selected_player_idx: int = -1
var _replacement_source: Dictionary = {}  # Starter being replaced (set by right-click context menu)

var _player_data_cache: Array = []

var _swapped_rows: Array = []  # Array[int] — indices that were recently swapped (shows -> <- arrows)
var _swap_feedback_timer: Timer

var _player_rows: Array = []
var _filter_btns = {}
var _kpi_labels: Array = []
var _detail_panel: Control

var _quick_actions_popover: PanelContainer = null

const _QA_POPOVER = preload("res://scenes/screens/team/components/quick_actions_popover.tscn")
const _EDIT_BANNER = preload("res://scenes/screens/team/components/edit_banner.tscn")
const _CANDIDATE_SELECTOR = preload("res://scenes/screens/team/components/candidate_selector_popover.tscn")

func _ready():
	for c in get_children():
		c.queue_free()

	var bg = ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 0)
	add_child(vbox)

	_build_topbar(vbox)
	_build_content(vbox)

	_load_roster()
	
	# Swap feedback timer (auto-clears -> <- indicators)
	_swap_feedback_timer = Timer.new()
	_swap_feedback_timer.one_shot = true
	_swap_feedback_timer.timeout.connect(_clear_swap_indicators)
	add_child(_swap_feedback_timer)
	
	quick_action_requested.connect(_on_quick_action_requested)
	edit_rotation_requested.connect(_on_edit_rotation_requested)
	cancel_rotation_requested.connect(_on_cancel_rotation_requested)
	save_rotation_requested.connect(_on_save_rotation_requested)
	if _player_data_cache.size() > 0:
		_selected_player_idx = 0
		_refresh_all()

# ─── Topbar ──────────────────────────────────────────────────────────────────

func _build_topbar(parent: VBoxContainer):
	var topbar = preload("res://scenes/components/topbar.tscn").instantiate()
	topbar.screen_title = "ELENCO"
	parent.add_child(topbar)

# ─── Content ─────────────────────────────────────────────────────────────────

func _build_content(parent: VBoxContainer):
	var margin = MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)

	_build_toolbar(vbox)
	_build_kpis(vbox)
	_build_main_area(vbox)

	margin.add_child(vbox)
	parent.add_child(margin)

# ─── Toolbar (Filter Tabs + Search + Action) ────────────────────────────────

func _build_toolbar(parent: VBoxContainer):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var filters = ["TODOS", "TITULARES", "ROTAÇÃO", "LESIONADOS", "JOVENS"]
	var counts = _compute_filter_counts()
	for f in filters:
		var count = counts.get(f, 0)
		var btn = _make_filter_pill(f, count, f == _active_filter)
		tabs.add_child(btn)
		_filter_btns[f] = btn

	hbox.add_child(tabs)

	var right = preload("res://scenes/ui/components/header_filter.tscn").instantiate()
	right.search_placeholder = "Buscar jogador..."
	right.action_btn_text = "CONTRATAR"
	if right.has_node("%ActionBtn"):
		var ab = right.get_node("%ActionBtn")
		ab.icon = load("res://addons/at-icons/control/plus.svg")
		if not Engine.is_editor_hint():
			var cs = StyleBoxFlat.new()
			cs.bg_color = COL_SUCCESS
			cs.corner_radius_top_left = 8
			cs.corner_radius_bottom_right = 8
			cs.corner_radius_bottom_left = 8
			cs.corner_radius_top_right = 8
			ab.add_theme_stylebox_override("normal", cs)

	hbox.add_child(right)
	parent.add_child(hbox)

func _make_filter_pill(text: String, count: int, active: bool) -> Button:
	var btn = Button.new()
	btn.text = text + "  " + str(count)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	btn.add_theme_font_size_override("font_size", 11)

	var s = StyleBoxFlat.new()
	if active:
		s.bg_color = COL_BRAND
		btn.add_theme_color_override("font_color", COL_TEXT)
	else:
		s.bg_color = Color(1, 1, 1, 0.05)
		btn.add_theme_color_override("font_color", COL_TEXT_MUTED)

	s.corner_radius_top_left = 16
	s.corner_radius_top_right = 16
	s.corner_radius_bottom_left = 16
	s.corner_radius_bottom_right = 16
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover", s)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_stylebox_override("focus", s)

	btn.pressed.connect(func(): _on_filter_changed(text))
	return btn

# ─── KPIs ────────────────────────────────────────────────────────────────────

func _build_kpis(parent: VBoxContainer):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 12)

	var team = GameManager.get_user_team()
	var players = team.get("players", [])
	var count = players.size()

	# Compute average OVR and age from engine players
	var total_ovr = 0.0
	var total_age = 0.0
	for p in players:
		total_ovr += float(p.get("overall", 50))
		total_age += float(p.get("age", 20))

	var avg_ovr = "0.0"
	var avg_age = "0.0"
	if count > 0:
		avg_ovr = str(round((total_ovr / count) * 10.0) / 10.0)
		avg_age = str(round((total_age / count) * 10.0) / 10.0)

	# Get salary total from engine finances
	var finances = GameManager.get_finances()
	var salary_total = float(finances.get("total_salary", 0))
	var salary_str = _format_salary(int(salary_total))

	# Get chemistry from engine team
	var chemistry = str(round(team.get("chemistry", 94.0)))

	var kpis = [
		{icon = "star", title = "OVERALL MÉDIO", val = avg_ovr, sub = "/100", color = COL_BRAND},
		{icon = "calendar", title = "IDADE MÉDIA", val = avg_age, sub = "anos", color = COL_INFO},
		{icon = "coins", title = "SALÁRIO TOTAL", val = salary_str, sub = "", color = COL_SUCCESS},
		{icon = "beaker", title = "QUÍMICA", val = chemistry, sub = "/100", color = COL_HIGHLIGHT},
	]

	for k in kpis:
		var card = _make_kpi_card(k.icon, k.title, k.val, k.sub, k.color)
		hbox.add_child(card)

	parent.add_child(hbox)

func _make_kpi_card(icon_name: String, title: String, val: String, sub: String, accent: Color) -> PanelContainer:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var cs = StyleBoxFlat.new()
	cs.bg_color = COL_SURFACE
	cs.corner_radius_top_left = 8
	cs.corner_radius_top_right = 8
	cs.corner_radius_bottom_left = 8
	cs.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", cs)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)

	var icon_container = PanelContainer.new()
	icon_container.custom_minimum_size = Vector2(40, 40)
	icon_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color(accent.r, accent.g, accent.b, 0.1)
	icon_style.corner_radius_top_left = 8
	icon_style.corner_radius_bottom_right = 8
	icon_style.corner_radius_bottom_left = 8
	icon_style.corner_radius_top_right = 8
	icon_container.add_theme_stylebox_override("panel", icon_style)

	var icon = TextureRect.new()
	icon.texture = load("res://addons/at-icons/control/" + icon_name + ".svg")
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = accent
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_container.add_child(icon)

	var vbox = VBoxContainer.new()
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	title_lbl.add_theme_font_size_override("font_size", 10)
	title_lbl.add_theme_color_override("font_color", COL_TEXT_MUTED)

	var val_hbox = HBoxContainer.new()
	val_hbox.add_theme_constant_override("separation", 4)

	var val_lbl = Label.new()
	val_lbl.text = val
	val_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	val_lbl.add_theme_font_size_override("font_size", 24)
	val_lbl.add_theme_color_override("font_color", COL_TEXT)

	var sub_lbl = Label.new()
	sub_lbl.text = sub
	sub_lbl.add_theme_color_override("font_color", COL_TEXT_MUTED)
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.size_flags_vertical = Control.SIZE_SHRINK_END

	val_hbox.add_child(val_lbl)
	val_hbox.add_child(sub_lbl)
	vbox.add_child(title_lbl)
	vbox.add_child(val_hbox)
	hbox.add_child(icon_container)
	hbox.add_child(vbox)
	margin.add_child(hbox)
	card.add_child(margin)
	return card

# ─── Main Area (Table + Detail) ─────────────────────────────────────────────

func _build_main_area(parent: VBoxContainer):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 16)
	parent.add_child(hbox)

	_build_player_table(hbox)
	_build_player_detail(hbox)

# ─── Player Table ────────────────────────────────────────────────────────────

func _build_player_table(parent: HBoxContainer):
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 2.0

	var cs = StyleBoxFlat.new()
	cs.bg_color = COL_SURFACE
	cs.corner_radius_top_left = 12
	cs.corner_radius_bottom_right = 12
	cs.corner_radius_bottom_left = 12
	cs.corner_radius_top_right = 12
	card.add_theme_stylebox_override("panel", cs)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)

	# Header Row
	var cols = [
		{n = "POS", w = 48},
		{n = "JOGADOR", w = 0, expand = true},
		{n = "IDADE", w = 56},
		{n = "OVR", w = 44},
		{n = "ENERGIA", w = 80},
		{n = "CONTRATO", w = 76},
		{n = "SALÁRIO", w = 80},
		{n = "", w = 32},
	]

	var header_margin = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 20)
	header_margin.add_theme_constant_override("margin_right", 20)
	header_margin.add_theme_constant_override("margin_top", 14)
	header_margin.add_theme_constant_override("margin_bottom", 10)

	var hh = HBoxContainer.new()
	hh.add_theme_constant_override("separation", 12)

	for c in cols:
		var l = Label.new()
		l.text = c.n
		l.custom_minimum_size = Vector2(c.w, 0) if c.w > 0 else Vector2(0, 0)
		if c.get("expand", false):
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		l.add_theme_font_size_override("font_size", 10)
		l.add_theme_color_override("font_color", COL_TEXT_DISABLED)
		l.add_theme_constant_override("letter_spacing", 1)
		if c.n == "POS":
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hh.add_child(l)

	header_margin.add_child(hh)
	vb.add_child(header_margin)

	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = COL_BORDER
	vb.add_child(divider)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 0)
	list.name = "PlayerList"
	scroll.add_child(list)

	vb.add_child(scroll)
	card.add_child(vb)
	parent.add_child(card)

func _refresh_player_rows():
	_player_rows.clear()
	var list = find_child("PlayerList", true, false)
	if not list:
		print("[REFRESH] PlayerList NOT FOUND!")
		return
	var child_count_before = list.get_child_count()
	var filtered = _get_filtered_players()
	print("[REFRESH] _refresh_player_rows: list=", list.name, " children_before=", child_count_before, " filtered=", filtered.size())
	for c in list.get_children():
		c.queue_free()

	for i in range(filtered.size()):
		var d = filtered[i]
		var idx = _player_data_cache.find(d)
		var row = _make_player_row(d, idx)
		list.add_child(row)
		_player_rows.append(row)
	print("[REFRESH] _refresh_player_rows DONE: list children now=", list.get_child_count())

func _make_player_row(d: Dictionary, idx: int) -> PanelContainer:
	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var is_selected = idx == _selected_player_idx
	var rs = StyleBoxFlat.new()
	rs.bg_color = COL_BRAND_SOFT if is_selected else Color.TRANSPARENT
	rs.corner_radius_top_left = 6
	rs.corner_radius_top_right = 6
	rs.corner_radius_bottom_left = 6
	rs.corner_radius_bottom_right = 6
	rs.content_margin_left = 16
	rs.content_margin_right = 16
	rs.content_margin_top = 8
	rs.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", rs)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# POS
	var pos_lbl = Label.new()
	pos_lbl.text = d.get("pos", "PG")
	pos_lbl.custom_minimum_size = Vector2(48, 0)
	pos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pos_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	pos_lbl.add_theme_font_size_override("font_size", 11)
	pos_lbl.add_theme_color_override("font_color", COL_BRAND)

	# Player name with initials
	var name_hbox = HBoxContainer.new()
	name_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_hbox.add_theme_constant_override("separation", 8)

	var init_circle = PanelContainer.new()
	init_circle.custom_minimum_size = Vector2(24, 24)
	var init_s = StyleBoxFlat.new()
	init_s.bg_color = COL_BRAND_DEEP
	init_s.corner_radius_top_left = 12
	init_s.corner_radius_top_right = 12
	init_s.corner_radius_bottom_left = 12
	init_s.corner_radius_bottom_right = 12
	init_circle.add_theme_stylebox_override("panel", init_s)

	var init_lbl = Label.new()
	var parts = d.get("name", "?").split(" ", false)
	var initials = ""
	if parts.size() >= 2:
		initials = parts[0][0] + parts[1][0]
	else:
		initials = d.get("name", "?")[0]
	init_lbl.text = initials
	init_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	init_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	init_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	init_lbl.add_theme_font_size_override("font_size", 9)
	init_lbl.add_theme_color_override("font_color", COL_TEXT)
	init_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	init_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	init_circle.add_child(init_lbl)

	var name_vbox = VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	name_vbox.add_theme_constant_override("separation", 0)

	var name_lbl = Label.new()
	name_lbl.text = d.get("name", "Jogador")
	name_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", COL_TEXT)

	var sub_lbl = Label.new()
	sub_lbl.text = d.get("nickname", "")
	if sub_lbl.text != "":
		sub_lbl.text = "\"" + sub_lbl.text + "\""
	sub_lbl.add_theme_font_size_override("font_size", 10)
	sub_lbl.add_theme_color_override("font_color", COL_TEXT_MUTED)

	if sub_lbl.text != "":
		name_vbox.add_child(name_lbl)
		name_vbox.add_child(sub_lbl)
	else:
		var align = VBoxContainer.new()
		align.alignment = BoxContainer.ALIGNMENT_CENTER
		align.add_child(name_lbl)
		name_vbox.add_child(align)

	name_hbox.add_child(init_circle)
	name_hbox.add_child(name_vbox)

	# Age
	var age_lbl = Label.new()
	age_lbl.text = str(d.get("age", 0))
	age_lbl.custom_minimum_size = Vector2(56, 0)
	age_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	age_lbl.add_theme_font_size_override("font_size", 13)
	age_lbl.add_theme_color_override("font_color", COL_TEXT)

	# OVR badge
	var ovr_val = int(d.get("ovr", 50))
	var ovr_c = _ovr_color(ovr_val)
	var ovr_box = PanelContainer.new()
	ovr_box.custom_minimum_size = Vector2(34, 22)
	ovr_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ovr_s = StyleBoxFlat.new()
	ovr_s.bg_color = Color(ovr_c, 0.13)
	ovr_s.border_color = ovr_c
	ovr_s.border_width_left = 1
	ovr_s.border_width_right = 1
	ovr_s.border_width_top = 1
	ovr_s.border_width_bottom = 1
	ovr_s.corner_radius_top_left = 4
	ovr_s.corner_radius_top_right = 4
	ovr_s.corner_radius_bottom_left = 4
	ovr_s.corner_radius_bottom_right = 4
	ovr_s.set_content_margin_all(0)
	ovr_box.add_theme_stylebox_override("panel", ovr_s)

	var ovr_lbl = Label.new()
	ovr_lbl.text = str(ovr_val)
	ovr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ovr_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ovr_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ovr_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ovr_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	ovr_lbl.add_theme_font_size_override("font_size", 11)
	ovr_lbl.add_theme_color_override("font_color", ovr_c)
	ovr_box.add_child(ovr_lbl)

	# Energy
	var energy_lbl = Label.new()
	energy_lbl.text = str(d.get("energy", 100))
	energy_lbl.custom_minimum_size = Vector2(80, 0)
	energy_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	energy_lbl.add_theme_font_size_override("font_size", 13)
	energy_lbl.add_theme_color_override("font_color", _energy_color(d.get("energy", 100)))

	# Contract
	var contract_lbl = Label.new()
	contract_lbl.text = d.get("contract", "-")
	contract_lbl.custom_minimum_size = Vector2(76, 0)
	contract_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	contract_lbl.add_theme_font_size_override("font_size", 13)
	contract_lbl.add_theme_color_override("font_color", COL_TEXT)

	# Salary
	var salary_lbl = Label.new()
	salary_lbl.text = d.get("salary", "-")
	salary_lbl.custom_minimum_size = Vector2(80, 0)
	salary_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	salary_lbl.add_theme_font_size_override("font_size", 13)
	salary_lbl.add_theme_color_override("font_color", COL_TEXT)

	# Swap indicator (→ ← for recently swapped rows)
	var swap_indicator = HBoxContainer.new()
	swap_indicator.name = "SwapIndicator"
	swap_indicator.add_theme_constant_override("separation", 4)
	swap_indicator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swap_indicator.visible = idx in _swapped_rows

	var arrow_left = Label.new()
	arrow_left.text = "→"
	arrow_left.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	arrow_left.add_theme_font_size_override("font_size", 14)
	arrow_left.add_theme_color_override("font_color", COL_BRAND)
	swap_indicator.add_child(arrow_left)

	var arrow_right = Label.new()
	arrow_right.text = "←"
	arrow_right.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	arrow_right.add_theme_font_size_override("font_size", 14)
	arrow_right.add_theme_color_override("font_color", COL_BRAND)
	swap_indicator.add_child(arrow_right)

	hbox.add_child(swap_indicator)

	# Quick Action button
	var qa_btn = PanelContainer.new()
	qa_btn.custom_minimum_size = Vector2(32, 24)
	qa_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var qas = StyleBoxFlat.new()
	qas.bg_color = Color.TRANSPARENT
	qas.corner_radius_top_left = 4
	qas.corner_radius_top_right = 4
	qas.corner_radius_bottom_left = 4
	qas.corner_radius_bottom_right = 4
	qa_btn.add_theme_stylebox_override("panel", qas)

	var qa_icon = TextureRect.new()
	qa_icon.texture = load("res://addons/at-icons/control/ellipsis.svg") if ResourceLoader.exists("res://addons/at-icons/control/ellipsis.svg") else null
	if not qa_icon.texture:
		var qa_label = Label.new()
		qa_label.text = "···"
		qa_label.add_theme_color_override("font_color", COL_TEXT_MUTED)
		qa_btn.add_child(qa_label)
	else:
		qa_icon.custom_minimum_size = Vector2(16, 16)
		qa_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		qa_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		qa_icon.modulate = COL_TEXT_MUTED
		qa_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		qa_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		qa_btn.add_child(qa_icon)

	var qa_click = Button.new()
	qa_click.flat = true
	qa_click.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qa_click.size_flags_vertical = Control.SIZE_EXPAND_FILL
	qa_click.mouse_filter = Control.MOUSE_FILTER_STOP
	qa_click.pressed.connect(func():
		var pos = qa_btn.get_screen_position() + Vector2(qa_btn.size.x, 0)
		quick_action_requested.emit(d, pos)
	)
	qa_btn.add_child(qa_click)

	hbox.add_child(pos_lbl)
	hbox.add_child(name_hbox)
	hbox.add_child(age_lbl)
	hbox.add_child(ovr_box)
	hbox.add_child(energy_lbl)
	hbox.add_child(contract_lbl)
	hbox.add_child(salary_lbl)
	hbox.add_child(qa_btn)
	row.add_child(hbox)

	# Row click
	var row_click = Button.new()
	row_click.flat = true
	row_click.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row_click.mouse_filter = Control.MOUSE_FILTER_PASS
	row_click.pressed.connect(func():
		if not _replacement_source.is_empty():
			_execute_player_swap(_replacement_source, d)
			return
		_selected_player_idx = idx
		_refresh_all()
		player_selected.emit(d)
	)
	row.add_child(row_click)

	# Right-click guard overlay
	var rclick_guard = Button.new()
	rclick_guard.flat = true
	rclick_guard.mouse_filter = Control.MOUSE_FILTER_STOP
	rclick_guard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rclick_guard.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_on_player_right_clicked(d, get_global_mouse_position())
	)
	row.add_child(rclick_guard)

	return row

# ─── Player Detail Panel ─────────────────────────────────────────────────────

func _build_player_detail(parent: HBoxContainer):
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 1.0

	var cs = StyleBoxFlat.new()
	cs.bg_color = COL_SURFACE
	cs.corner_radius_top_left = 12
	cs.corner_radius_bottom_right = 12
	cs.corner_radius_bottom_left = 12
	cs.corner_radius_top_right = 12
	card.add_theme_stylebox_override("panel", cs)

	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 0)
	vb.name = "DetailContent"

	var placeholder = Label.new()
	placeholder.text = "Selecione um jogador"
	placeholder.add_theme_color_override("font_color", COL_TEXT_MUTED)
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(placeholder)

	scroll.add_child(vb)
	card.add_child(scroll)
	parent.add_child(card)
	_detail_panel = card

func _refresh_detail():
	var content = _detail_panel.find_child("DetailContent", true, false)
	if not content:
		return
	for c in content.get_children():
		c.queue_free()

	if _selected_player_idx < 0 or _selected_player_idx >= _player_data_cache.size():
		var placeholder = Label.new()
		placeholder.text = "Selecione um jogador"
		placeholder.add_theme_color_override("font_color", COL_TEXT_MUTED)
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(placeholder)
		return

	var d = _player_data_cache[_selected_player_idx]
	var ovr_val = int(d.get("ovr", 50))

	var main_vb = VBoxContainer.new()
	main_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vb.add_theme_constant_override("separation", 0)

	# ═══ PC HEADER (lighter bg, rounded corners) ═══

	var header_outer = MarginContainer.new()
	header_outer.add_theme_constant_override("margin_left", 24)
	header_outer.add_theme_constant_override("margin_right", 24)
	header_outer.add_theme_constant_override("margin_top", 16)
	header_outer.add_theme_constant_override("margin_bottom", 0)

	var header_panel = PanelContainer.new()
	var hp_style = StyleBoxFlat.new()
	hp_style.bg_color = Color("#120B20")
	hp_style.corner_radius_top_left = 12
	hp_style.corner_radius_top_right = 12
	hp_style.corner_radius_bottom_left = 12
	hp_style.corner_radius_bottom_right = 12
	header_panel.add_theme_stylebox_override("panel", hp_style)

	var header_vb = VBoxContainer.new()
	header_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_vb.add_theme_constant_override("separation", 12)

	var top_hbox = HBoxContainer.new()
	top_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var section = Label.new()
	section.text = "JOGADOR SELECIONADO"
	section.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	section.add_theme_font_size_override("font_size", 9)
	section.add_theme_color_override("font_color", COL_BRAND)
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(section)
	if ovr_val >= 90:
		var star_box = HBoxContainer.new()
		star_box.add_theme_constant_override("separation", 4)
		var star_icon = Label.new()
		star_icon.text = "★"
		star_icon.add_theme_color_override("font_color", COL_WARNING)
		star_icon.add_theme_font_size_override("font_size", 12)
		star_box.add_child(star_icon)
		var star_lbl = Label.new()
		star_lbl.text = "ESTRELA"
		star_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		star_lbl.add_theme_font_size_override("font_size", 9)
		star_lbl.add_theme_color_override("font_color", COL_WARNING)
		star_box.add_child(star_lbl)
		top_hbox.add_child(star_box)
	header_vb.add_child(top_hbox)

	var avatar_hbox = HBoxContainer.new()
	avatar_hbox.add_theme_constant_override("separation", 14)
	var av_container = Control.new()
	av_container.custom_minimum_size = Vector2(72, 72)
	var av_bg = PanelContainer.new()
	av_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var avs = StyleBoxFlat.new()
	avs.bg_color = Color("#7C3AED")
	avs.corner_radius_top_left = 36
	avs.corner_radius_top_right = 36
	avs.corner_radius_bottom_left = 36
	avs.corner_radius_bottom_right = 36
	avs.border_width_left = 3
	avs.border_width_right = 3
	avs.border_width_top = 3
	avs.border_width_bottom = 3
	avs.border_color = Color("#5B21B6")
	avs.shadow_size = 16
	avs.shadow_color = Color("#A78BFA66")
	avs.shadow_offset = Vector2(0, 0)
	av_bg.add_theme_stylebox_override("panel", avs)
	var initials = Label.new()
	var name_parts = d.get("name", "?").split(" ", false)
	var init_str = ""
	if name_parts.size() >= 2:
		init_str = name_parts[0][0] + name_parts[1][0]
	else:
		init_str = d.get("name", "?")[0]
	initials.text = init_str
	initials.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	initials.size_flags_vertical = Control.SIZE_EXPAND_FILL
	initials.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	initials.add_theme_font_size_override("font_size", 22)
	initials.add_theme_color_override("font_color", COL_TEXT)
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av_bg.add_child(initials)
	av_container.add_child(av_bg)

	var name_vbox = VBoxContainer.new()
	name_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	name_vbox.add_theme_constant_override("separation", 3)
	var num_lbl = Label.new()
	num_lbl.text = "#" + str(d.get("number", 0))
	num_lbl.add_theme_color_override("font_color", COL_BRAND)
	num_lbl.add_theme_font_size_override("font_size", 11)
	num_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	var name_lbl = Label.new()
	name_lbl.text = d.get("name", "Jogador")
	name_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", COL_TEXT)
	var sub_lbl = Label.new()
	sub_lbl.text = d.get("nickname", "")
	if sub_lbl.text != "":
		sub_lbl.text = "\"" + sub_lbl.text + "\""
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	sub_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
	name_vbox.add_child(num_lbl)
	name_vbox.add_child(name_lbl)
	if sub_lbl.text != "":
		name_vbox.add_child(sub_lbl)
	avatar_hbox.add_child(av_container)
	avatar_hbox.add_child(name_vbox)
	header_vb.add_child(avatar_hbox)

	var stat_hbox = HBoxContainer.new()
	stat_hbox.add_theme_constant_override("separation", 8)
	stat_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stat_val_colors = {POS = COL_BRAND, IDADE = COL_TEXT, ALTURA = COL_TEXT, OVR = COL_BRAND}
	var details = [
		{t = "POS", v = d.get("pos", "-")},
		{t = "IDADE", v = str(d.get("age", 0))},
		{t = "ALTURA", v = d.get("height", "-")},
		{t = "OVR", v = str(ovr_val)},
	]
	for det in details:
		var sp = PanelContainer.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ss = StyleBoxFlat.new()
		ss.bg_color = Color("#0B0514")
		ss.corner_radius_top_left = 6
		ss.corner_radius_top_right = 6
		ss.corner_radius_bottom_left = 6
		ss.corner_radius_bottom_right = 6
		sp.add_theme_stylebox_override("panel", ss)
		var sv = VBoxContainer.new()
		sv.alignment = BoxContainer.ALIGNMENT_CENTER
		sv.add_theme_constant_override("separation", 2)
		var sm = MarginContainer.new()
		sm.add_theme_constant_override("margin_left", 10)
		sm.add_theme_constant_override("margin_right", 10)
		sm.add_theme_constant_override("margin_top", 8)
		sm.add_theme_constant_override("margin_bottom", 8)
		var tl = Label.new()
		tl.text = det.t
		tl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		tl.add_theme_font_size_override("font_size", 8)
		tl.add_theme_color_override("font_color", Color("#6B5B95"))
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var vl = Label.new()
		vl.text = det.v
		vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
		vl.add_theme_font_size_override("font_size", 13)
		vl.add_theme_color_override("font_color", stat_val_colors.get(det.t, COL_TEXT))
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sv.add_child(tl); sv.add_child(vl)
		sm.add_child(sv); sp.add_child(sm)
		stat_hbox.add_child(sp)
	header_vb.add_child(stat_hbox)

	var inner_margin = MarginContainer.new()
	inner_margin.add_theme_constant_override("margin_left", 20)
	inner_margin.add_theme_constant_override("margin_right", 20)
	inner_margin.add_theme_constant_override("margin_top", 16)
	inner_margin.add_theme_constant_override("margin_bottom", 16)
	inner_margin.add_child(header_vb)
	header_panel.add_child(inner_margin)
	header_outer.add_child(header_panel)
	main_vb.add_child(header_outer)

	# ═══ BODY (padding, no gradient) ═══

	var body_margin = MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 24)
	body_margin.add_theme_constant_override("margin_right", 24)
	body_margin.add_theme_constant_override("margin_top", 20)
	body_margin.add_theme_constant_override("margin_bottom", 20)

	var body_vb = VBoxContainer.new()
	body_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_vb.add_theme_constant_override("separation", 20)

	var div1 = ColorRect.new()
	div1.custom_minimum_size = Vector2(0, 1)
	div1.color = COL_BORDER
	body_vb.add_child(div1)

	var attr_label = Label.new()
	attr_label.text = "ATRIBUTOS"
	attr_label.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	attr_label.add_theme_font_size_override("font_size", 10)
	attr_label.add_theme_color_override("font_color", COL_BRAND)
	body_vb.add_child(attr_label)

	var attr_vbox = VBoxContainer.new()
	attr_vbox.add_theme_constant_override("separation", 12)
	var attrs = d.get("attrs", {})
	var attr_groups = [
		{n = "FÍSICOS", c = COL_INFO, is_measure = false, keys = [
			{k = "speed", l = "Velocidade"},
			{k = "strength", l = "Força"},
			{k = "stamina", l = "Resistência"},
			{k = "jumping", l = "Salto"},
		]},
		{n = "MEDIDAS", c = COL_INFO, is_measure = true, keys = [
			{k = "height_cm", l = "Altura (cm)"},
			{k = "weight_kg", l = "Peso (kg)"},
			{k = "wingspan_cm", l = "Envergadura (cm)"},
		]},
		{n = "FINALIZAÇÃO", c = COL_BRAND, is_measure = false, keys = [
			{k = "three_pt", l = "3 Pontos"},
			{k = "mid_range", l = "Média Distância"},
			{k = "close_shot", l = "Curta Distância"},
			{k = "dunk", l = "Enterrada"},
			{k = "layup", l = "Bandeja"},
			{k = "free_throw", l = "Lance Livre"},
		]},
		{n = "MANEJO / PASSE", c = COL_BRAND, is_measure = false, keys = [
			{k = "ball_handle", l = "Manejo"},
			{k = "passing", l = "Passe"},
		]},
		{n = "DEFESA / REBOTE", c = COL_SUCCESS, is_measure = false, keys = [
			{k = "perimeter_def", l = "Defesa Perímetro"},
			{k = "interior_def", l = "Defesa Interior"},
			{k = "steal", l = "Roubo"},
			{k = "block", l = "Toco"},
			{k = "offensive_rebound", l = "Rebote Ofensivo"},
			{k = "defensive_rebound", l = "Rebote Defensivo"},
		]},
		{n = "MENTAL", c = COL_WARNING, is_measure = false, keys = [
			{k = "basketball_iq", l = "QI de Quadra"},
			{k = "clutch", l = "Clutch"},
			{k = "leadership", l = "Liderança"},
			{k = "work_ethic", l = "Ética de Trabalho"},
			{k = "potential", l = "Potencial"},
		]},
	]
	for g in attr_groups:
		var has_any = false
		for a in g.keys:
			if attrs.has(a.k):
				has_any = true
				break
		if not has_any:
			continue

		var gl = Label.new()
		gl.text = g.n
		gl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		gl.add_theme_font_size_override("font_size", 9)
		gl.add_theme_color_override("font_color", g.c)
		gl.add_theme_constant_override("letter_spacing", 1)
		attr_vbox.add_child(gl)

		for a in g.keys:
			var val = attrs.get(a.k)
			if val == null:
				continue
			if g.is_measure:
				attr_vbox.add_child(_make_attr_measure(a.l, val))
			else:
				attr_vbox.add_child(_make_attr_bar(a.l, val, g.c))
	body_vb.add_child(attr_vbox)

	var div2 = ColorRect.new()
	div2.custom_minimum_size = Vector2(0, 1)
	div2.color = COL_BORDER
	body_vb.add_child(div2)

	var lineup_hbox = HBoxContainer.new()
	var lineup_label = Label.new()
	lineup_label.text = "QUINTETO TITULAR"
	lineup_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lineup_label.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	lineup_label.add_theme_font_size_override("font_size", 10)
	lineup_label.add_theme_color_override("font_color", COL_BRAND)
	var edit_btn = PanelContainer.new()
	var ebs = StyleBoxFlat.new()
	ebs.bg_color = COL_SURFACE_ALT
	ebs.corner_radius_top_left = 4
	ebs.corner_radius_bottom_right = 4
	ebs.corner_radius_bottom_left = 4
	ebs.corner_radius_top_right = 4
	edit_btn.add_theme_stylebox_override("panel", ebs)
	var eb_margin = MarginContainer.new()
	eb_margin.add_theme_constant_override("margin_left", 8)
	eb_margin.add_theme_constant_override("margin_right", 8)
	eb_margin.add_theme_constant_override("margin_top", 4)
	eb_margin.add_theme_constant_override("margin_bottom", 4)
	var eb_hbox = HBoxContainer.new()
	eb_hbox.add_theme_constant_override("separation", 4)
	var eb_icon = TextureRect.new()
	eb_icon.texture = load("res://addons/at-icons/control/pencil.svg")
	eb_icon.custom_minimum_size = Vector2(10, 10)
	eb_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	eb_icon.modulate = COL_TEXT_MUTED
	var eb_text = Label.new()
	eb_text.text = "EDITAR"
	eb_text.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	eb_text.add_theme_font_size_override("font_size", 9)
	eb_text.add_theme_color_override("font_color", COL_TEXT_MUTED)
	eb_hbox.add_child(eb_icon)
	eb_hbox.add_child(eb_text)
	eb_margin.add_child(eb_hbox)
	edit_btn.add_child(eb_margin)

	var edit_click = Button.new()
	edit_click.flat = true
	edit_click.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	edit_click.mouse_filter = Control.MOUSE_FILTER_STOP
	edit_click.pressed.connect(func():
		edit_rotation_requested.emit()
	)
	edit_btn.add_child(edit_click)

	lineup_hbox.add_child(lineup_label)
	lineup_hbox.add_child(edit_btn)
	body_vb.add_child(lineup_hbox)

	if _edit_mode:
		var banner = _EDIT_BANNER.instantiate()
		banner.cancel_pressed.connect(func():
			set_edit_mode(false)
		)
		banner.save_pressed.connect(func():
			save_rotation_requested.emit()
			set_edit_mode(false)
		)
		body_vb.add_child(banner)

	body_margin.add_child(body_vb)
	main_vb.add_child(body_margin)

	content.add_child(main_vb)

func _make_stat_box(title: String, val: String) -> PanelContainer:
	var p = PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s = StyleBoxFlat.new()
	s.bg_color = COL_SURFACE_ALT
	s.corner_radius_top_left = 8
	s.corner_radius_bottom_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_top_right = 8
	p.add_theme_stylebox_override("panel", s)

	var v = VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)

	var t = Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 9)
	t.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	t.add_theme_color_override("font_color", COL_TEXT_MUTED)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var vl = Label.new()
	vl.text = val
	vl.add_theme_font_size_override("font_size", 16)
	vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	vl.add_theme_color_override("font_color", COL_TEXT)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	v.add_child(t)
	v.add_child(vl)
	m.add_child(v)
	p.add_child(m)
	return p

func _make_attr_bar(title: String, val: int, color: Color) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var tl = Label.new()
	tl.text = title
	tl.custom_minimum_size = Vector2(100, 0)
	tl.add_theme_color_override("font_color", COL_TEXT_MUTED)
	tl.add_theme_font_size_override("font_size", 11)

	var bar_container = VBoxContainer.new()
	bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_container.alignment = BoxContainer.ALIGNMENT_CENTER

	var track = ColorRect.new()
	track.custom_minimum_size = Vector2(0, 6)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.color = COL_SURFACE_ALT

	var fill_w = clamp(val, 0, 100) / 100.0
	var fill = TextureRect.new()
	fill.custom_minimum_size = Vector2(fill_w * 160, 6)
	fill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var g2d = GradientTexture2D.new()
	var g = Gradient.new()
	g.set_color(0, Color(color.r, color.g, color.b, 0.15))
	g.set_color(1, color)
	g2d.gradient = g
	g2d.fill_from = Vector2(0, 0)
	g2d.fill_to = Vector2(1, 0)
	fill.texture = g2d

	var bar_hbox = HBoxContainer.new()
	bar_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_hbox.add_child(fill)

	track.add_child(bar_hbox)
	bar_container.add_child(track)

	var vl = Label.new()
	vl.text = str(val)
	vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	vl.add_theme_font_size_override("font_size", 13)
	vl.add_theme_color_override("font_color", color)
	vl.custom_minimum_size = Vector2(28, 0)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	h.add_child(tl)
	h.add_child(bar_container)
	h.add_child(vl)
	return h

func _make_attr_measure(title: String, val) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var tl = Label.new()
	tl.text = title
	tl.custom_minimum_size = Vector2(100, 0)
	tl.add_theme_color_override("font_color", COL_TEXT_MUTED)
	tl.add_theme_font_size_override("font_size", 11)

	var vl = Label.new()
	vl.text = str(val)
	vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	vl.add_theme_font_size_override("font_size", 13)
	vl.add_theme_color_override("font_color", COL_TEXT)

	h.add_child(tl)
	h.add_child(vl)
	return h

# ─── Popover Handlers ─────────────────────────────────────────────────────────

func _on_quick_action_requested(player_data: Dictionary, global_pos: Vector2):
	if _quick_actions_popover:
		_quick_actions_popover.queue_free()
		_quick_actions_popover = null

	var popover = _QA_POPOVER.instantiate()
	popover.player_data = player_data
	popover.global_position = global_pos
	popover.action_selected.connect(func(action_id: String):
		print("Quick action: ", action_id)
		popover.queue_free()
		_quick_actions_popover = null
	)
	popover.closed.connect(func():
		popover.queue_free()
		_quick_actions_popover = null
	)
	add_child(popover)
	_quick_actions_popover = popover

func _on_edit_rotation_requested():
	set_edit_mode(true)

func _on_cancel_rotation_requested():
	set_edit_mode(false)

func _on_save_rotation_requested():
	print("[ROTATION] _on_save_rotation_requested START _edit_mode=", _edit_mode)
	var team_id = GameManager.user_team_id
	var player_ids: Array[int] = []
	for p in _player_data_cache:
		var pid = p.get("player_id", 0)
		if pid > 0:
			player_ids.append(pid)
	if player_ids.size() > 0:
		GameManager.set_rotation_order(team_id, player_ids)
		print("[Team] Rotation saved: ", player_ids)
	else:
		print("[Team] No player IDs in cache - saving order as player names")
	set_edit_mode(false)
	print("[ROTATION] _on_save_rotation_requested END")

# ─── Context Menu (Right-click) ──────────────────────────────────────────────

func _on_player_right_clicked(player_data: Dictionary, global_pos: Vector2) -> void:
	# Only show context menu for starters (indices 0-4)
	var idx = _player_data_cache.find(player_data)
	print("[RIGHTCLICK] player=", player_data.get("name","?"), " idx=", idx)
	if idx < 0 or idx >= 5:
		print("[RIGHTCLICK] Not a starter, returning")
		return

	# Collect same-position candidates (excluding the clicked player)
	var pos = player_data.get("pos", "")
	var same_pos_players: Array = []
	var bench_players_list: Array = []
	for p in _player_data_cache:
		if p == player_data:
			continue
		if p.get("pos", "") == pos:
			same_pos_players.append(p)
		var p_idx = _player_data_cache.find(p)
		if p_idx >= 5:
			bench_players_list.append(p)

	print("[RIGHTCLICK] same_pos=", same_pos_players.size(), " bench=", bench_players_list.size())

	# Create and show context menu
	var menu = preload("res://scenes/ui/components/context_menu.tscn").instantiate()
	menu.global_position = global_pos
	menu.set_menu_data(player_data, pos, same_pos_players, bench_players_list)
	menu.menu_item_selected.connect(_on_context_menu_action)
	menu.player_swap_requested.connect(_on_submenu_swap_requested)
	menu.closed.connect(func():
		if menu and is_instance_valid(menu):
			menu.queue_free()
	)
	add_child(menu)
	print("[RIGHTCLICK] ContextMenu added as child")


func _on_submenu_swap_requested(source: Dictionary, target: Dictionary) -> void:
	print("[SUB] _on_submenu_swap_requested: source=", source.get("name", "?"), " target=", target.get("name", "?"))
	_execute_player_swap(source, target)
	print("[SUB] _on_submenu_swap_requested END")


func _on_context_menu_action(action_id: String, player_data: Dictionary) -> void:
	match action_id:
		"view_profile":
			print("[Team] View profile for: ", player_data.get("name", ""))


func _execute_player_swap(source: Dictionary, target: Dictionary) -> void:
	print("[SWAP] _execute_player_swap START")
	print("[SWAP]   source=", source.get("name", "?"), " target=", target.get("name", "?"))
	if source == target:
		print("[SWAP]   source == target, returning")
		return

	var src_idx = _player_data_cache.find(source)
	var tgt_idx = _player_data_cache.find(target)
	print("[SWAP]   src_idx=", src_idx, " tgt_idx=", tgt_idx)

	if src_idx < 0 or tgt_idx < 0:
		print("[SWAP]   index < 0, returning")
		return

	# Swap positions in cache
	print("[SWAP]   BEFORE: [", src_idx, "]=", _player_data_cache[src_idx].get("name","?"), " [", tgt_idx, "]=", _player_data_cache[tgt_idx].get("name","?"))
	_player_data_cache[src_idx] = target
	_player_data_cache[tgt_idx] = source
	print("[SWAP]   AFTER:  [", src_idx, "]=", _player_data_cache[src_idx].get("name","?"), " [", tgt_idx, "]=", _player_data_cache[tgt_idx].get("name","?"))
	print("[SWAP]   Cache order now: ", get_cache_names())

	# Persist new order to engine
	_on_save_rotation_requested()
	print("[SWAP]   after _on_save_rotation_requested")

	# Set swap indicators for feedback
	_swapped_rows = [src_idx, tgt_idx]
	_swap_feedback_timer.start(3.0)

	# Reset replacement state and highlight the new starter
	_replacement_source = {}
	_active_filter = "TODOS"
	_selected_player_idx = src_idx  # Now holds the replacement player
	print("[SWAP]   _active_filter=", _active_filter, " _selected_player_idx=", _selected_player_idx)
	print("[SWAP]   calling _refresh_all()")
	_refresh_all()
	print("[SWAP] _execute_player_swap END")

func get_cache_names() -> Array:
	var names = []
	for p in _player_data_cache:
		names.append(p.get("name", "?"))
	return names


func _update_filter_visuals() -> void:
	for f in _filter_btns:
		var btn = _filter_btns[f]
		var counts = _compute_filter_counts()
		var count = counts.get(f, 0)
		var is_active = f == _active_filter

		var s = StyleBoxFlat.new()
		if is_active:
			s.bg_color = COL_BRAND
			btn.add_theme_color_override("font_color", COL_TEXT)
		else:
			s.bg_color = Color(1, 1, 1, 0.05)
			btn.add_theme_color_override("font_color", COL_TEXT_MUTED)
		s.corner_radius_top_left = 16
		s.corner_radius_top_right = 16
		s.corner_radius_bottom_left = 16
		s.corner_radius_bottom_right = 16
		s.content_margin_left = 16
		s.content_margin_right = 16
		s.content_margin_top = 8
		s.content_margin_bottom = 8
		btn.add_theme_stylebox_override("normal", s)
		btn.add_theme_stylebox_override("hover", s)
		btn.add_theme_stylebox_override("pressed", s)
		btn.add_theme_stylebox_override("focus", s)

		var count_str = str(count)
		var name_part = f
		btn.text = name_part + "  " + count_str


# ─── Utilities ───────────────────────────────────────────────────────────────

func _load_roster():
	_player_data_cache.clear()
	if GameManager.league.is_empty():
		# Demo data
		_player_data_cache = [
			{pos = "PG", name = "Marcus Silva", nickname = "The Maestro", age = 28, ovr = 92, energy = 88, contract = "2 anos", salary = "R$ 2.4M", status = "ATIVO", number = 7, height = "1.91m", attrs = {speed = 82, strength = 68, stamina = 90, jumping = 78, height_cm = 191, weight_kg = 88, wingspan_cm = 198, three_pt = 94, mid_range = 92, close_shot = 88, dunk = 60, layup = 90, free_throw = 96, ball_handle = 96, passing = 94, offensive_rebound = 35, perimeter_def = 78, interior_def = 40, steal = 72, block = 30, defensive_rebound = 55, basketball_iq = 92, clutch = 88, leadership = 95, work_ethic = 90, potential = 85}},
			{pos = "SG", name = "João Pedro", nickname = "Sniper", age = 26, ovr = 88, energy = 76, contract = "3 anos", salary = "R$ 1.8M", status = "ATIVO", number = 11, height = "1.96m", attrs = {speed = 80, strength = 65, stamina = 82, jumping = 84, height_cm = 196, weight_kg = 92, wingspan_cm = 205, three_pt = 95, mid_range = 88, close_shot = 82, dunk = 78, layup = 85, free_throw = 90, ball_handle = 84, passing = 78, offensive_rebound = 40, perimeter_def = 72, interior_def = 45, steal = 68, block = 35, defensive_rebound = 50, basketball_iq = 85, clutch = 82, leadership = 70, work_ethic = 88, potential = 82}},
			{pos = "SF", name = "Carlos Mendez", nickname = "El Capitán", age = 31, ovr = 86, energy = 65, contract = "1 ano", salary = "R$ 1.5M", status = "ATIVO", number = 23, height = "2.01m", attrs = {speed = 76, strength = 78, stamina = 80, jumping = 82, height_cm = 201, weight_kg = 100, wingspan_cm = 212, three_pt = 82, mid_range = 80, close_shot = 85, dunk = 84, layup = 82, free_throw = 78, ball_handle = 78, passing = 74, offensive_rebound = 70, perimeter_def = 88, interior_def = 72, steal = 80, block = 65, defensive_rebound = 78, basketball_iq = 86, clutch = 90, leadership = 92, work_ethic = 85, potential = 75}},
			{pos = "PF", name = "Anderson Costa", nickname = "The Beast", age = 29, ovr = 85, energy = 45, contract = "2 anos", salary = "R$ 1.3M", status = "CANSADO", number = 34, height = "2.06m", attrs = {speed = 68, strength = 92, stamina = 70, jumping = 88, height_cm = 206, weight_kg = 112, wingspan_cm = 218, three_pt = 60, mid_range = 70, close_shot = 88, dunk = 92, layup = 78, free_throw = 65, ball_handle = 60, passing = 52, offensive_rebound = 85, perimeter_def = 65, interior_def = 88, steal = 45, block = 82, defensive_rebound = 90, basketball_iq = 78, clutch = 72, leadership = 65, work_ethic = 80, potential = 78}},
			{pos = "C", name = "Tyrone Walker", nickname = "The Wall", age = 32, ovr = 83, energy = 30, contract = "0.5 ano", salary = "R$ 1.1M", status = "LESIONADO", number = 44, height = "2.13m", attrs = {speed = 45, strength = 95, stamina = 65, jumping = 60, height_cm = 213, weight_kg = 125, wingspan_cm = 228, three_pt = 30, mid_range = 55, close_shot = 90, dunk = 85, layup = 75, free_throw = 60, ball_handle = 35, passing = 40, offensive_rebound = 80, perimeter_def = 35, interior_def = 94, steal = 25, block = 95, defensive_rebound = 92, basketball_iq = 80, clutch = 70, leadership = 78, work_ethic = 75, potential = 70}},
			{pos = "PG", name = "Lucas Almeida", nickname = "Rookie", age = 21, ovr = 78, energy = 95, contract = "4 anos", salary = "R$ 480K", status = "ATIVO", number = 2, height = "1.85m", attrs = {speed = 88, strength = 55, stamina = 85, jumping = 80, height_cm = 185, weight_kg = 80, wingspan_cm = 195, three_pt = 80, mid_range = 76, close_shot = 72, dunk = 55, layup = 82, free_throw = 78, ball_handle = 85, passing = 82, offensive_rebound = 30, perimeter_def = 68, interior_def = 35, steal = 72, block = 20, defensive_rebound = 45, basketball_iq = 74, clutch = 65, leadership = 55, work_ethic = 92, potential = 92}},
			{pos = "SG", name = "Diego Ramos", nickname = "Flash", age = 24, ovr = 81, energy = 82, contract = "2 anos", salary = "R$ 720K", status = "ATIVO", number = 5, height = "1.93m", attrs = {speed = 92, strength = 62, stamina = 78, jumping = 90, height_cm = 193, weight_kg = 86, wingspan_cm = 200, three_pt = 86, mid_range = 82, close_shot = 78, dunk = 80, layup = 84, free_throw = 82, ball_handle = 80, passing = 72, offensive_rebound = 35, perimeter_def = 70, interior_def = 40, steal = 74, block = 30, defensive_rebound = 48, basketball_iq = 76, clutch = 78, leadership = 60, work_ethic = 85, potential = 86}},
			{pos = "SF", name = "Rafael Souza", nickname = "Iron Man", age = 27, ovr = 79, energy = 70, contract = "3 anos", salary = "R$ 650K", status = "ATIVO", number = 8, height = "1.98m", attrs = {speed = 74, strength = 76, stamina = 88, jumping = 76, height_cm = 198, weight_kg = 98, wingspan_cm = 208, three_pt = 76, mid_range = 78, close_shot = 80, dunk = 78, layup = 76, free_throw = 82, ball_handle = 72, passing = 68, offensive_rebound = 72, perimeter_def = 82, interior_def = 74, steal = 76, block = 68, defensive_rebound = 76, basketball_iq = 78, clutch = 80, leadership = 85, work_ethic = 90, potential = 80}},
			{pos = "PF", name = "Bruno Oliveira", nickname = "Hammer", age = 25, ovr = 76, energy = 88, contract = "1 ano", salary = "R$ 540K", status = "ATIVO", number = 15, height = "2.03m", attrs = {speed = 66, strength = 86, stamina = 76, jumping = 82, height_cm = 203, weight_kg = 106, wingspan_cm = 215, three_pt = 60, mid_range = 72, close_shot = 84, dunk = 88, layup = 74, free_throw = 70, ball_handle = 58, passing = 50, offensive_rebound = 82, perimeter_def = 62, interior_def = 84, steal = 42, block = 76, defensive_rebound = 86, basketball_iq = 72, clutch = 68, leadership = 62, work_ethic = 82, potential = 76}},
			{pos = "C", name = "Pedro Henrique", nickname = "Big Pete", age = 23, ovr = 74, energy = 92, contract = "4 anos", salary = "R$ 420K", status = "ATIVO", number = 50, height = "2.10m", attrs = {speed = 52, strength = 88, stamina = 72, jumping = 65, height_cm = 210, weight_kg = 118, wingspan_cm = 222, three_pt = 35, mid_range = 60, close_shot = 86, dunk = 82, layup = 72, free_throw = 68, ball_handle = 38, passing = 44, offensive_rebound = 78, perimeter_def = 38, interior_def = 88, steal = 28, block = 88, defensive_rebound = 88, basketball_iq = 74, clutch = 60, leadership = 50, work_ethic = 88, potential = 84}},
		]
	else:
		var team = GameManager.get_user_team()
		if team and team.has("players"):
			for p in team.players:
				var attrs = p.get("attributes", {})
				var injury_days = int(p.get("injury_days", 0))
				var status = "LESIONADO" if injury_days > 0 else "ATIVO"
				var stamina_val = int(attrs.get("stamina", 100))
				if stamina_val < 40 and status == "ATIVO":
					status = "CANSADO"

				var height_cm = float(attrs.get("height_cm", 190.0))
				var height_str = "%0.2fm" % (height_cm / 100.0)

				_player_data_cache.append({
					player_id = p.get("id", 0),
					pos = p.get("position", "PG"),
					name = p.get("first_name", "") + " " + p.get("last_name", "Jogador"),
					nickname = "",
					age = p.get("age", 20),
					ovr = round(p.get("overall", 50)),
					energy = stamina_val,
					contract = str(p.get("contract_year", 1)) + " anos",
					salary = _format_salary(p.get("salary", 0)),
					status = status,
					number = 0,
					height = height_str,
					attrs = attrs,
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
			# Append any players not in rotation_order
			for p in _player_data_cache:
				if not reordered.has(p):
					reordered.append(p)
			_player_data_cache = reordered

func _format_salary(val) -> String:
	if typeof(val) == TYPE_STRING:
		return val
	var v = float(val) if val else 0.0
	if v >= 1000000:
		return "R$ " + str(round(v / 100000) / 10.0) + "M"
	elif v >= 1000:
		return "R$ " + str(round(v / 1000)) + "K"
	return "R$ " + str(v)

func _get_filtered_players() -> Array:
	if _active_filter == "TODOS":
		var names = []
		for p in _player_data_cache:
			names.append(p.get("name","?"))
		var result = _player_data_cache
		return result
	var result = []
	var is_pos_filter = _active_filter in ["PG", "SG", "SF", "PF", "C"]
	for p in _player_data_cache:
		var status = p.get("status", "ATIVO")
		var age = p.get("age", 20)
		match _active_filter:
			"TITULARES":
				if p.get("pos", "") in ["PG", "SG", "SF", "PF", "C"] and _player_data_cache.find(p) < 5:
					result.append(p)
			"ROTAÇÃO":
				if _player_data_cache.find(p) >= 5 and _player_data_cache.find(p) < 10:
					result.append(p)
			"LESIONADOS":
				if status == "LESIONADO":
					result.append(p)
			"JOVENS":
				if age <= 23:
					result.append(p)
			_:
				if is_pos_filter and p.get("pos", "") == _active_filter:
					result.append(p)
	return result

func _compute_filter_counts() -> Dictionary:
	return {
		"TODOS": _player_data_cache.size(),
		"TITULARES": min(5, _player_data_cache.size()),
		"ROTAÇÃO": min(5, max(0, _player_data_cache.size() - 5)),
		"LESIONADOS": _player_data_cache.filter(func(p): return p.get("status", "ATIVO") == "LESIONADO").size(),
		"JOVENS": _player_data_cache.filter(func(p): return p.get("age", 20) <= 23).size(),
	}

func _energy_color(e: int) -> Color:
	if e >= 70:
		return COL_SUCCESS
	elif e >= 40:
		return COL_WARNING
	return COL_DANGER

func _ovr_color(ovr: int) -> Color:
	if ovr >= 90:
		return COL_BRAND
	elif ovr >= 85:
		return COL_SUCCESS
	elif ovr >= 80:
		return COL_INFO
	elif ovr >= 75:
		return COL_WARNING
	return COL_TEXT_MUTED

func _on_filter_changed(filter: String):
	_replacement_source = {}  # Exit replacement mode when user clicks a filter tab
	_active_filter = filter
	_update_filter_visuals()
	_refresh_all()

func _refresh_all():
	print("[REFRESH] _refresh_all() called (stack: ", get_stack()[1].function if get_stack().size() > 1 else "root", ")")
	var before = Time.get_ticks_msec()
	_refresh_player_rows()
	_refresh_detail()
	print("[REFRESH] _refresh_all() DONE (took ", Time.get_ticks_msec() - before, "ms)")

func _clear_swap_indicators():
	_swapped_rows = []
	_refresh_player_rows()

func set_edit_mode(enabled: bool):
	_edit_mode = enabled
	_refresh_all()

func get_filtered_count() -> int:
	return _get_filtered_players().size()
