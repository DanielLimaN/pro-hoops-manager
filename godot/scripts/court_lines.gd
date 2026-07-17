extends Control

func _draw():
	var w = size.x
	var h = size.y

	# The design uses a 1440x360 viewport for the court perspective.
	# Scale lines proportionally to the actual control size.
	var scale_x = w / 1440.0
	var scale_y = h / 360.0

	var color = Color("#FB923C30")  # orange #FB923C at ~19% opacity
	var width = 1.0

	# Top line — full width at top of container
	draw_line(Vector2(0, 0), Vector2(w, 0), color, width)
	# Bottom line — centered section at container bottom
	draw_line(Vector2(400 * scale_x, h), Vector2(1040 * scale_x, h), color, width)
	# Middle line — centered
	draw_line(Vector2(520 * scale_x, 240 * scale_y), Vector2(920 * scale_x, 240 * scale_y), color, width)
	# Inner line — centered
	draw_line(Vector2(620 * scale_x, 140 * scale_y), Vector2(820 * scale_x, 140 * scale_y), color, width)
