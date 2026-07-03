extends Control

var values = [50.0, 50.0, 50.0, 50.0]

func _draw():
	var labels = ["Offense", "Defense", "Physical", "Mental"]
	var center = size / 2.0
	var radius = min(center.x, center.y) - 25.0
	if radius <= 0: return
	
	# Draw background web
	for i in range(1, 6):
		var r = radius * (i / 5.0)
		_draw_polygon_outline(center, r, 4, Color(1, 1, 1, 0.15))
		
	# Draw axes and labels
	var font = ThemeDB.fallback_font
	for i in range(4):
		var angle = i * PI/2.0 - PI/2.0
		var pt = center + Vector2(cos(angle), sin(angle)) * radius
		draw_line(center, pt, Color(1, 1, 1, 0.2), 1.0, true)
		
		var lbl = labels[i]
		var sz = font.get_string_size(lbl, 0, -1, 11)
		var lbl_pt = center + Vector2(cos(angle), sin(angle)) * (radius + 15.0)
		var tpos = lbl_pt - sz/2.0 + Vector2(0, 4)
		draw_string(font, tpos, lbl, 0, -1, 11, Color(0.7, 0.8, 0.9))
		
	# Draw data polygon
	var pts = PackedVector2Array()
	for i in range(4):
		var angle = i * PI/2.0 - PI/2.0
		var r = radius * (clamp(values[i], 0.0, 100.0) / 100.0)
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	
	draw_colored_polygon(pts, Color(0.95, 0.35, 0.15, 0.6))
	pts.append(pts[0])
	draw_polyline(pts, Color(0.95, 0.35, 0.15, 1.0), 2.0, true)

func _draw_polygon_outline(center, r, sides, color):
	var pts = PackedVector2Array()
	for i in range(sides):
		var angle = i * TAU/sides - PI/2.0
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	pts.append(pts[0])
	draw_polyline(pts, color, 1.0, true)
