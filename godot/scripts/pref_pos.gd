extends Control

var positions = ["PG"]

func _draw():
	var w = size.x
	var h = size.y
	if w <= 0 or h <= 0: return
	
	# Court background
	draw_rect(Rect2(0, 0, w, h), Color(0.08, 0.2, 0.15))
	draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.5), false, 2.0)
	
	var cx = w / 2.0
	var lane_w = w * 0.35
	draw_rect(Rect2(cx - lane_w/2.0, 0, lane_w, h * 0.5), Color(1, 1, 1, 0.5), false, 2.0)
	
	draw_arc(Vector2(cx, h * 0.5), lane_w/2.0, 0, PI, 16, Color(1, 1, 1, 0.5), 2.0, true)
	draw_arc(Vector2(cx, 0), w * 0.45, 0, PI, 32, Color(1, 1, 1, 0.5), 2.0, true)
	
	var map = {
		"PG": Vector2(cx, h * 0.8),
		"SG": Vector2(w * 0.25, h * 0.65),
		"SF": Vector2(w * 0.75, h * 0.65),
		"PF": Vector2(cx - lane_w*0.8, h * 0.25),
		"C":  Vector2(cx, h * 0.2)
	}
	
	for p in map.keys():
		var pos = map[p]
		if p in positions:
			draw_circle(pos, 10, Color(0.9, 0.25, 0.15))
			draw_arc(pos, 10, 0, TAU, 16, Color(1,1,1), 2.0, true)
		else:
			draw_circle(pos, 6, Color(0.2, 0.5, 0.3))
