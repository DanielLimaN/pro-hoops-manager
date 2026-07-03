extends Control

var player_data: Dictionary
signal player_swapped(starter, bench_player)

var is_hovered = false
var base_scale = Vector2(1, 1)

func _ready():
	# Explicitly set pivot to center for 80x50 size used in team.gd
	pivot_offset = Vector2(40, 25)

func _process(_delta):
	# Handle hover animation during drag
	if get_viewport().gui_is_dragging():
		var mpos = get_global_mouse_position()
		var over = get_global_rect().has_point(mpos)
		if over and not is_hovered:
			is_hovered = true
			_animate_hover(true)
		elif not over and is_hovered:
			is_hovered = false
			_animate_hover(false)
	elif is_hovered:
		is_hovered = false
		_animate_hover(false)

func _animate_hover(hovering: bool):
	var tween = create_tween()
	if hovering:
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(self, "modulate", Color(1.3, 1.3, 1.5, 1.0), 0.15)
	else:
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 1.0), 0.15)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "bench_player"

func _drop_data(_at_position: Vector2, data: Variant):
	# Pop animation on successful drop
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", Color(0.5, 1.5, 0.5, 1.0), 0.1) # Greenish flash
	tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 1.0), 0.2)
	
	player_swapped.emit(player_data, data.player)
