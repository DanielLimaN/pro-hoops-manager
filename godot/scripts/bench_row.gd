extends Control

var player_data: Dictionary

func _get_drag_data(at_position: Vector2):
	var preview = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.35, 0.2, 0.8, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 10
	preview.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = player_data.last_name + " (Substituir)"
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	preview.add_child(label)
	
	# Animate the preview popup
	preview.modulate = Color(1, 1, 1, 0)
	preview.scale = Vector2(0.5, 0.5)
	preview.pivot_offset = Vector2(50, 15) # approximate center
	
	var tween = preview.create_tween().set_parallel(true)
	tween.tween_property(preview, "modulate", Color(1, 1, 1, 1), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(preview, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(preview, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Animate the row to look like it was "picked up" (dimmed)
	var row_tween = create_tween()
	row_tween.tween_property(self, "modulate", Color(1, 1, 1, 0.3), 0.2)
	
	set_drag_preview(preview)
	return {"type": "bench_player", "player": player_data, "source_node": self}

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		# Restore the row when drag ends
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)
