@tool
extends PanelContainer
class_name PlayerProfilePanel

# ═══════════════════════════════════════
#  Header Section
# ═══════════════════════════════════════
@onready var avatar_panel: PanelContainer = %AvatarPanel
@onready var initials_label: Label = %AvatarInitials
@onready var number_label: Label = %JerseyNumber
@onready var name_label: Label = %PlayerName
@onready var nickname_label: Label = %PlayerNickname
@onready var position_label: Label = %PlayerPos
@onready var ovr_label: Label = %PlayerOvr
@onready var age_label: Label = %PlayerAge
@onready var height_meta_label: Label = %PlayerHeight

# ═══════════════════════════════════════
#  Tab Buttons
# ═══════════════════════════════════════
@onready var btn_atrib: Button = %BtnAtrib
@onready var btn_contrato: Button = %BtnContrato
@onready var btn_historico: Button = %BtnHistorico
@onready var btn_stats: Button = %BtnStats
@onready var btn_lesoes: Button = %BtnLesoes
@onready var btn_relacoes: Button = %BtnRelacoes

# ═══════════════════════════════════════
#  Tab Content Containers
# ═══════════════════════════════════════
@onready var tab_atrib: ScrollContainer = %TabAtrib
@onready var tab_contrato: ScrollContainer = %TabContrato
@onready var tab_historico: ScrollContainer = %TabHistorico
@onready var tab_stats: ScrollContainer = %TabStats
@onready var tab_lesoes: ScrollContainer = %TabLesoes
@onready var tab_relacoes: ScrollContainer = %TabRelacoes

# ═══════════════════════════════════════
#  Measurements (Atrib tab)
# ═══════════════════════════════════════
@onready var measure_height: Label = %MeasureHeight
@onready var measure_weight: Label = %MeasureWeight
@onready var measure_wingspan: Label = %MeasureWingspan

# ═══════════════════════════════════════
#  Attribute Category Containers
#  Each contains child VBoxContainers whose
#  names are Rust attribute keys (e.g. "speed")
# ═══════════════════════════════════════
@onready var fisico_container: VBoxContainer = %FisicoContainer
@onready var arremesso_container: VBoxContainer = %ArremessoContainer
@onready var bola_container: VBoxContainer = %BolaContainer
@onready var defesa_container: VBoxContainer = %DefesaContainer

# ═══════════════════════════════════════
#  Contract Tab
# ═══════════════════════════════════════
@onready var salary_label: Label = %ContractSalary
@onready var years_left_label: Label = %ContractYears
@onready var status_label: Label = %ContractStatus

# ═══════════════════════════════════════
#  Attribute Category → Key Mappings
# ═══════════════════════════════════════
const FISICO_KEYS := ["speed", "strength", "stamina", "jumping"]
const ARREMESSO_KEYS := ["three_pt", "mid_range", "close_shot", "dunk", "layup", "free_throw"]
const BOLA_KEYS := ["ball_handle", "passing"]
const DEFESA_KEYS := ["offensive_rebound", "perimeter_def", "interior_def", "steal", "block", "defensive_rebound"]


# ═══════════════════════════════════════
#  Lifecycle
# ═══════════════════════════════════════
func _ready() -> void:
	# Safety: avoid running UI logic in editor preview context
	if Engine.is_editor_hint():
		return
	_connect_tabs()
	_show_tab(0)
	
	show()
	print("PlayerProfilePanel ready — global_pos=", global_position, " size=", size, " visible=", is_visible_in_tree(), " owner=", owner)


# ═══════════════════════════════════════
#  Public: display_player(data)
#  Receives the same dictionary format from
#  _player_data_cache (populated by _load_roster).
# ═══════════════════════════════════════
func display_player(data: Dictionary) -> void:
	if not is_node_ready():
		return

	# ── Safety: show placeholder fallback if data is empty ──
	if data.is_empty():
		name_label.text = "Nenhum jogador"
		position_label.text = "-"
		ovr_label.text = "0"
		number_label.text = "#-"
		age_label.text = "0"
		height_meta_label.text = "-"
		nickname_label.text = ""
		initials_label.text = "?"
		initials_label.show()

		measure_height.text = "-"
		measure_weight.text = "-"
		measure_wingspan.text = "-"

		# Reset all attr bars to 0
		var empty_attrs := {}
		_update_attr_bars(empty_attrs)

		salary_label.text = "-"
		years_left_label.text = "-"
		status_label.text = "-"

		_show_tab(0)
		return

	# ── Header ──
	name_label.text = data.get("name", "Jogador")
	position_label.text = data.get("pos", "-")
	ovr_label.text = str(data.get("ovr", 0))
	number_label.text = "#" + str(data.get("number", "-"))
	age_label.text = str(data.get("age", 0))
	height_meta_label.text = data.get("height", "-")

	var nick: String = data.get("nickname", "")
	nickname_label.text = '"' + nick + '"' if not nick.is_empty() else ""

	# ── Portrait / Avatar (preserved from team.gd _refresh_detail) ──
	_render_portrait(data)

	# ── Measurements ──
	var attrs: Dictionary = data.get("attrs", {})
	var height_cm: float = float(attrs.get("height_cm", 0))
	measure_height.text = "%0.2fm" % (height_cm / 100.0) if height_cm > 0 else "-"
	measure_weight.text = str(attrs.get("weight_kg", 0)) + " kg"
	measure_wingspan.text = str(attrs.get("wingspan_cm", 0)) + " cm"

	# ── Attribute Bars ──
	_update_attr_bars(attrs)

	# ── Contract ──
	salary_label.text = data.get("salary", "-")
	years_left_label.text = data.get("contract", "-")
	status_label.text = data.get("status", "-")

	# Default to first tab
	_show_tab(0)


# ═══════════════════════════════════════
#  Private: _render_portrait
#  Preserved identically from team.gd
#  _refresh_detail() lines 253-292
# ═══════════════════════════════════════
func _render_portrait(data: Dictionary) -> void:
	var portrait_node: Control = avatar_panel.get_node_or_null("Portrait")
	if not portrait_node:
		var pr_scene: PackedScene = load("res://scenes/ui/components/PortraitRenderer.tscn")
		if pr_scene:
			portrait_node = pr_scene.instantiate()
			portrait_node.name = "Portrait"
			portrait_node.set_anchors_preset(Control.PRESET_FULL_RECT)
			avatar_panel.add_child(portrait_node)

	var style: StyleBoxFlat = avatar_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style:
		if data.has("portrait_config"):
			initials_label.hide()
			if portrait_node:
				portrait_node.show()
				if portrait_node.has_method("render_portrait"):
					portrait_node.render_portrait(data.portrait_config)
			style.bg_color = Color(0, 0, 0, 0.2)
		else:
			initials_label.show()
			var name_parts: Array = data.get("name", "X").split(" ", false)
			if name_parts.size() >= 2:
				initials_label.text = name_parts[0][0] + name_parts[1][0]
			else:
				initials_label.text = name_parts[0][0] if name_parts.size() > 0 else "XX"
			if portrait_node:
				portrait_node.hide()
			style.bg_color = Color(0.486, 0.227, 0.933)  # BRAND_DEEP

	avatar_panel.add_theme_stylebox_override("panel", style)


# ═══════════════════════════════════════
#  Private: _update_attr_bars
#  Iterates each category container's children.
#  Each child VBoxContainer's name IS the
#  attribute key (e.g. "speed", "three_pt").
#  Each child has a Label named "Value" and
#  a ProgressBar named "Bar".
# ═══════════════════════════════════════
func _update_attr_bars(attrs: Dictionary) -> void:
	var categories := {
		fisico_container: FISICO_KEYS,
		arremesso_container: ARREMESSO_KEYS,
		bola_container: BOLA_KEYS,
		defesa_container: DEFESA_KEYS,
	}

	for container: VBoxContainer in categories.keys():
		for key: String in categories[container]:
			var row: Node = container.get_node_or_null(key)
			if not row:
				continue
			var value: float = float(attrs.get(key, 50))
			var rounded: int = int(round(value))

			var val_lbl: Label = row.get_node("Value") as Label
			if val_lbl:
				val_lbl.text = str(rounded)

			var bar: ProgressBar = row.get_node("Bar") as ProgressBar
			if bar:
				bar.value = value


# ═══════════════════════════════════════
#  Private: _connect_tabs
# ═══════════════════════════════════════
func _connect_tabs() -> void:
	var tabs: Array[Button] = [btn_atrib, btn_contrato, btn_historico, btn_stats, btn_lesoes, btn_relacoes]
	for i in tabs.size():
		var idx := i
		tabs[idx].pressed.connect(func(): _show_tab(idx))


# ═══════════════════════════════════════
#  Private: _show_tab
# ═══════════════════════════════════════
func _show_tab(index: int) -> void:
	var content: Array[ScrollContainer] = [tab_atrib, tab_contrato, tab_historico, tab_stats, tab_lesoes, tab_relacoes]
	var buttons: Array[Button] = [btn_atrib, btn_contrato, btn_historico, btn_stats, btn_lesoes, btn_relacoes]

	for i in content.size():
		content[i].visible = (i == index)
		buttons[i].button_pressed = (i == index)
