extends Control

const COURT_WIDTH  = 15.24
const RIM_Z        = 14.325
const VISUAL_HALF_LENGTH = RIM_Z + 1.2 

const THREE_RADIUS = 7.24
const LANE_WIDTH   = 4.90
const LANE_DEPTH   = 5.80
const FT_RADIUS    = 1.80
const REST_RADIUS  = 1.25
const CENTER_RAD   = 1.80
const HOOP_RADIUS  = 0.23

var ppm: float = 18.0
var cx: float = 0.0
var cy: float = 0.0

func _ready():
	set_process(true)

func _process(_delta):
	queue_redraw()

func _court(mx: float, mz: float) -> Vector2:
	# For the menu, we want a half court. 
	# The hoop is at the top. So mz = VISUAL_HALF_LENGTH should be near the top.
	return Vector2(cx + mx * ppm, cy - mz * ppm)

func _draw():
	_draw_tactical_lines()
	var w = size.x
	var h = size.y
	if w <= 0 or h <= 0: return
	
	# We want the baseline (mz = VISUAL_HALF_LENGTH) to be near the top
	# and the midcourt (mz = 0) to be near the bottom.
	# So total vertical height in meters is VISUAL_HALF_LENGTH.
	ppm = min(w / (COURT_WIDTH + 2.0), h / (VISUAL_HALF_LENGTH + 2.0))
	
	cx = w / 2.0
	cy = h - ppm * 1.0 # Midcourt is at the bottom

	_draw_hardwood()
	_draw_court_lines()

func _draw_hardwood():
	var base_color = Color(0.9, 0.68, 0.38)
	var alt_color  = Color(0.85, 0.63, 0.35)
	
	var margin = 1.5
	var top_left = _court(-COURT_WIDTH/2.0 - margin, VISUAL_HALF_LENGTH + margin)
	var bot_right = _court(COURT_WIDTH/2.0 + margin, 0.0 - margin)
	
	draw_rect(Rect2(top_left.x, top_left.y, bot_right.x - top_left.x, bot_right.y - top_left.y), base_color, true)
	
	var plank_h = 1.0 * ppm
	var num_planks = int((bot_right.y - top_left.y) / plank_h) + 1
	for i in range(num_planks):
		if i % 2 == 1:
			draw_rect(Rect2(top_left.x, top_left.y + i * plank_h, bot_right.x - top_left.x, plank_h), alt_color, true)
			
	var border_color = Color(0.08, 0.12, 0.20)
	var court_tl = _court(-COURT_WIDTH/2.0, VISUAL_HALF_LENGTH)
	var court_br = _court(COURT_WIDTH/2.0, 0.0)
	
	draw_rect(Rect2(top_left.x, top_left.y, bot_right.x - top_left.x, court_tl.y - top_left.y), border_color, true) # Top
	draw_rect(Rect2(top_left.x, court_br.y, bot_right.x - top_left.x, bot_right.y - court_br.y), border_color, true) # Bottom
	draw_rect(Rect2(top_left.x, court_tl.y, court_tl.x - top_left.x, court_br.y - court_tl.y), border_color, true) # Left
	draw_rect(Rect2(court_br.x, court_tl.y, bot_right.x - court_br.x, court_br.y - court_tl.y), border_color, true) # Right

func _draw_court_lines():
	var line_color = Color(1.0, 1.0, 1.0, 0.85)
	var line_w = max(2.0, ppm * 0.06)
	
	var court_tl = _court(-COURT_WIDTH/2.0, VISUAL_HALF_LENGTH)
	var court_br = _court(COURT_WIDTH/2.0, 0.0)
	draw_rect(Rect2(court_tl.x, court_tl.y, court_br.x - court_tl.x, court_br.y - court_tl.y), line_color, false, line_w)
	
	var mid_y = _court(0.0, 0.0).y
	draw_line(Vector2(court_tl.x, mid_y), Vector2(court_br.x, mid_y), line_color, line_w, true)
	
	var center = _court(0.0, 0.0)
	draw_circle(center, CENTER_RAD * ppm, Color(0.9, 0.1, 0.1, 0.4))
	
	# Only draw half of the center circle
	_draw_dashed_arc(center, CENTER_RAD * ppm, PI, TAU, 32, line_color, line_w, true)
	
	_draw_side_premium(1.0, Color(0.1, 0.25, 0.65, 0.9)) # Blue Home Paint

func _draw_side_premium(dir: float, paint_color: Color):
	var line_color = Color(1.0, 1.0, 1.0, 0.85)
	var line_w = max(2.0, ppm * 0.06)
	
	var lw = LANE_WIDTH / 2.0 * ppm
	var ld = LANE_DEPTH * ppm
	var baseline_y = _court(0.0, dir * VISUAL_HALF_LENGTH).y
	var ft_y = baseline_y + dir * ld
	
	var p_top = min(baseline_y, ft_y)
	var paint_rect = Rect2(cx - lw, p_top, lw * 2.0, abs(ft_y - baseline_y))
	draw_rect(paint_rect, paint_color, true)
	draw_rect(paint_rect, line_color, false, line_w)
	
	var hoop_pos = _court(0.0, dir * RIM_Z)
	var rest_rad = REST_RADIUS * ppm
	var start_a = 0.0 if dir > 0 else PI
	var end_a = PI if dir > 0 else TAU
	draw_arc(hoop_pos, rest_rad, start_a, end_a, 32, line_color, line_w, true)
	
	var ft_c = Vector2(cx, ft_y)
	var ft_rad = FT_RADIUS * ppm
	draw_arc(ft_c, ft_rad, start_a, end_a, 32, line_color, line_w, true)
	_draw_dashed_arc(ft_c, ft_rad, end_a, start_a + TAU, 24, line_color, line_w, false)
	
	var sw = 6.6 * ppm
	var tp_rad = THREE_RADIUS * ppm
	var dy = sqrt(max(0.0, tp_rad * tp_rad - sw * sw))
	var clip_y = hoop_pos.y + dir * dy
	
	var angle = acos(sw / tp_rad)
	var tp_s = angle if dir > 0 else PI + angle
	var tp_e = PI - angle if dir > 0 else TAU - angle
	draw_arc(hoop_pos, tp_rad, tp_s, tp_e, 64, line_color, line_w, true)
	draw_line(Vector2(cx - sw, baseline_y), Vector2(cx - sw, clip_y), line_color, line_w, true)
	draw_line(Vector2(cx + sw, baseline_y), Vector2(cx + sw, clip_y), line_color, line_w, true)
	
	var bb_y = hoop_pos.y - dir * (HOOP_RADIUS * ppm + 1.5)
	draw_line(Vector2(hoop_pos.x - 14, bb_y), Vector2(hoop_pos.x + 14, bb_y), Color(0.2, 0.2, 0.2), line_w * 1.5, true)
	draw_circle(hoop_pos, HOOP_RADIUS * ppm, Color(0.9, 0.3, 0.1, 0.3))
	draw_arc(hoop_pos, HOOP_RADIUS * ppm, 0, TAU, 24, Color(0.95, 0.4, 0.1), line_w, true)

func _draw_dashed_arc(center: Vector2, radius: float, start_angle: float, end_angle: float, segments: int, color: Color, width: float, solid: bool):
	if solid:
		draw_arc(center, radius, start_angle, end_angle, segments, color, width, true)
		return
	var diff = end_angle - start_angle
	var step = diff / float(segments)
	for i in range(0, segments, 2):
		var a1 = start_angle + i * step
		var a2 = start_angle + (i + 1.0) * step
		var p1 = center + Vector2(cos(a1), sin(a1)) * radius
		var p2 = center + Vector2(cos(a2), sin(a2)) * radius
		draw_line(p1, p2, color, width, true)

var active_scheme: int = 0
var active_mode: String = "offense"
var positions_map: Dictionary = {}

func set_scheme(idx: int, mode: String, pmap: Dictionary):
	active_scheme = idx
	active_mode = mode
	positions_map = pmap
	queue_redraw()

func _draw_tactical_lines():
	if positions_map.is_empty(): return
	var w = size.x
	var h = size.y
	
	var pt = func(pos_key):
		var p = positions_map.get(pos_key, Vector2(0.5, 0.5))
		return Vector2(p.x * w, p.y * h)
		
	
	
	var arr_color = Color(0.9, 0.7, 0.1, 0.7) if active_mode == "offense" else Color(0.2, 0.8, 0.3, 0.7)
	var pass_color = Color(1.0, 1.0, 1.0, 0.4)
	
	if active_mode == "defense":
		if active_scheme == 1 or active_scheme == 2: # Zones
			_draw_dashed_line(pt.call("PG"), pt.call("SG"), pass_color, 2.0)
			_draw_dashed_line(pt.call("SF"), pt.call("PF"), pass_color, 2.0)
		elif active_scheme == 3: # FullCourtPress
			_draw_arrow(pt.call("PG"), pt.call("PG") + Vector2(0, 40), arr_color, 4.0)
			_draw_arrow(pt.call("SG"), pt.call("SG") + Vector2(0, 40), arr_color, 4.0)
		elif active_scheme == 4: # HalfCourtTrap
			var trap_p = pt.call("PG") + Vector2(0, 30)
			_draw_arrow(pt.call("PG"), trap_p, arr_color, 3.0)
			_draw_arrow(pt.call("SG"), trap_p, arr_color, 3.0)
		elif active_scheme == 5: # BoxAndOne
			_draw_dashed_line(pt.call("SG"), pt.call("SF"), pass_color, 2.0)
			_draw_dashed_line(pt.call("SF"), pt.call("C"), pass_color, 2.0)
			_draw_dashed_line(pt.call("C"), pt.call("PF"), pass_color, 2.0)
			_draw_dashed_line(pt.call("PF"), pt.call("SG"), pass_color, 2.0)
			_draw_arrow(pt.call("PG"), pt.call("PG") + Vector2(0, 30), arr_color, 3.0)
		return

	# Draw specific paths based on scheme (Offense)
	if active_scheme == 0: # Motion
		_draw_dashed_line(pt.call("PG"), pt.call("SG"), pass_color, 2.0)
		_draw_dashed_line(pt.call("PG"), pt.call("SF"), pass_color, 2.0)
		_draw_dashed_line(pt.call("SG"), pt.call("PF"), pass_color, 2.0)
		_draw_dashed_line(pt.call("SF"), pt.call("C"), pass_color, 2.0)
	elif active_scheme == 1: # Isolation
		_draw_dashed_line(pt.call("PG"), pt.call("SG"), pass_color, 2.0)
		_draw_dashed_line(pt.call("PG"), pt.call("SF"), pass_color, 2.0)
	elif active_scheme == 2: # PickAndRoll
		var pg_p = pt.call("PG")
		var c_p = pt.call("C")
		_draw_arrow(c_p, pg_p + Vector2(20, -20), arr_color, 4.0) # Pick
		_draw_arrow(pg_p + Vector2(20, -20), pg_p + Vector2(-30, -50), arr_color, 4.0) # PG Drive
		_draw_arrow(c_p, c_p + Vector2(0, 40), arr_color, 4.0) # Roll
	elif active_scheme == 3: # PostUp
		_draw_dashed_line(pt.call("PG"), pt.call("C"), pass_color, 3.0)
		_draw_arrow(pt.call("C"), pt.call("C") + Vector2(0, 30), arr_color, 4.0)
	elif active_scheme == 5: # Triangle
		_draw_dashed_line(pt.call("PG"), pt.call("SG"), pass_color, 2.0)
		_draw_dashed_line(pt.call("SG"), pt.call("PF"), pass_color, 2.0)
		_draw_dashed_line(pt.call("PG"), pt.call("PF"), pass_color, 2.0)
	elif active_scheme == 6: # SevenSeconds
		_draw_arrow(pt.call("PG"), pt.call("PG") + Vector2(0, -60), arr_color, 4.0)
		_draw_arrow(pt.call("SG"), pt.call("SG") + Vector2(0, -40), arr_color, 3.0)
		_draw_arrow(pt.call("SF"), pt.call("SF") + Vector2(0, -40), arr_color, 3.0)

func _draw_dashed_line(p1, p2, color, width):
	var dist = p1.distance_to(p2)
	var dir = (p2 - p1).normalized()
	var step = 10.0
	var i = 0.0
	while i < dist:
		draw_line(p1 + dir * i, p1 + dir * min(i + step/2.0, dist), color, width, true)
		i += step

func _draw_arrow(p1, p2, color, width):
	draw_line(p1, p2, color, width, true)
	var dir = (p2 - p1).normalized()
	var n = Vector2(-dir.y, dir.x)
	var head_len = 10.0
	var head_wid = 6.0
	var pts = PackedVector2Array([
		p2,
		p2 - dir * head_len + n * head_wid,
		p2 - dir * head_len - n * head_wid
	])
	draw_colored_polygon(pts, color)
