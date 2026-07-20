@tool
extends PanelContainer
class_name SubstitutionCandidateRow

# ═══════════════════════════════════════════════
# Signals
# ═══════════════════════════════════════════════

signal swap_requested(target_data: Dictionary)

# ═══════════════════════════════════════════════
# Exported visual resources (designer configures
# these in the Inspector — NO code-created visuals)
# ═══════════════════════════════════════════════

@export var style_normal: StyleBox
@export var style_hover: StyleBox
@export var style_current: StyleBox
@export var style_avatar_normal: StyleBox
@export var style_avatar_current: StyleBox

# ═══════════════════════════════════════════════
# Exported textures / scenes
# ═══════════════════════════════════════════════

@export var icon_check: Texture2D
@export var icon_chevron: Texture2D
@export var portrait_renderer_scene: PackedScene

# ═══════════════════════════════════════════════
# Node references (resolved via % unique names —
# most reliable approach in Godot 4 for @tool)
# ═══════════════════════════════════════════════

@onready var _name_label: Label = %NameLbl
@onready var _position_label: Label = %PositionLbl
@onready var _overall_label: Label = %OvrLbl
@onready var _avatar_container: PanelContainer = %Avatar
@onready var _avatar_initials_label: Label = %InitialsLbl
@onready var _status_icon: TextureRect = %ActionIcon

# ═══════════════════════════════════════════════
# Internal state
# ═══════════════════════════════════════════════

var _target_data: Dictionary = {}
var _is_current: bool = false

# ═══════════════════════════════════════════════
# Public API — called by SubstitutionSubmenu
# ═══════════════════════════════════════════════

func setup(source_player: Dictionary, target: Dictionary) -> void:
	var pname: String = target.get("name", "?")
	print("[CandRow] setup() chamado para: ", pname)

	_target_data = target
	_is_current = target.get("player_id", 0) == source_player.get("player_id", -1)

	# Inject data into labels
	if _name_label:
		_name_label.text = pname
		print("[CandRow]   ✅ name_label = ", pname)
	else:
		print("[CandRow]   ❌ name_label é NULL!")

	if _position_label:
		_position_label.text = target.get("pos", "")
	if _overall_label:
		_overall_label.text = "OVR " + str(target.get("ovr", 80))

	# Apply style based on current-state
	_apply_base_style()

	# Render avatar (portrait or initials fallback)
	_setup_avatar(target)

	# Configure status icon
	_setup_status_icon()

# ═══════════════════════════════════════════════
# Private helpers
# ═══════════════════════════════════════════════

func _apply_base_style() -> void:
	if _is_current:
		if style_current:
			add_theme_stylebox_override(&"panel", style_current)
		if style_avatar_current and _avatar_container:
			_avatar_container.add_theme_stylebox_override(&"panel", style_avatar_current)
	else:
		if style_normal:
			add_theme_stylebox_override(&"panel", style_normal)
		if style_avatar_normal and _avatar_container:
			_avatar_container.add_theme_stylebox_override(&"panel", style_avatar_normal)

func _setup_avatar(target: Dictionary) -> void:
	if not _avatar_container or not _avatar_initials_label:
		return

	# Remove any dynamically added portrait renderers (keep scene-baked children)
	for child in _avatar_container.get_children():
		if child != _avatar_initials_label:
			child.queue_free()

	_avatar_initials_label.visible = false

	if portrait_renderer_scene and target.has("portrait_config"):
		var pr := portrait_renderer_scene.instantiate()
		pr.custom_minimum_size = Vector2(34, 34)
		pr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_avatar_container.add_child(pr)
		if pr.has_method("render_portrait"):
			pr.render_portrait(target.portrait_config)
	else:
		# Fallback: show initials
		_avatar_initials_label.visible = true
		var player_name: String = target.get("name", "X")
		var parts: PackedStringArray = player_name.split(" ", false)
		_avatar_initials_label.text = (parts[0][0] + parts[1][0]) \
			if parts.size() >= 2 \
			else parts[0][0]

func _setup_status_icon() -> void:
	if not _status_icon:
		return
	if _is_current:
		_status_icon.texture = icon_check
		_status_icon.modulate = Color("#3B82F6")
	else:
		_status_icon.texture = icon_chevron
		_status_icon.modulate = Color("#6B5B95")

# ═══════════════════════════════════════════════
# Input handling
# ═══════════════════════════════════════════════

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
		and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT:
		swap_requested.emit(_target_data)

# ═══════════════════════════════════════════════
# Ready
# ═══════════════════════════════════════════════

func _ready() -> void:
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)

	# Children must not steal clicks / hover events
	_make_children_ignore_mouse(self)

func _make_children_ignore_mouse(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_make_children_ignore_mouse(child)

# ═══════════════════════════════════════════════
# Hover feedback
# ═══════════════════════════════════════════════

func _on_hover() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if _is_current:
		if style_current:
			add_theme_stylebox_override("panel", style_current)
	else:
		if style_hover:
			add_theme_stylebox_override("panel", style_hover)
		if _status_icon:
			_status_icon.modulate = Color("#3B82F6")

func _on_exit() -> void:
	_apply_base_style()

	if not _is_current and _status_icon:
		_status_icon.modulate = Color("#6B5B95")
