extends Node2D

const COURT_WIDTH  = 15.24
const HALF_WIDTH   = COURT_WIDTH / 2.0
const RIM_Z        = 14.325
const VISUAL_HALF_LENGTH = RIM_Z + 1.2 
const COURT_LENGTH_VISUAL = VISUAL_HALF_LENGTH * 2.0

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

var current_angles = []
var ball_angle: float = 0.0
var target_positions: Array = []
var ball_target:   Vector2 = Vector2.ZERO
var current_positions: Array = []
var current_ball_pos: Vector2 = Vector2.ZERO
var ball_altitude: float = 1.0
var player_altitudes: Array = []

func _ready():
	for i in range(10):
		current_positions.append(Vector2.ZERO)
		player_altitudes.append(0.0)
	_update_layout()

func _update_layout():
	var vp = get_viewport_rect().size
	var parent = get_parent()
	if parent and parent is Control:
		vp = parent.size
		
	if vp.x <= 0 or vp.y <= 0:
		return
	var area_w = vp.x - 40
	var area_h = vp.y - 40
	cx = vp.x / 2.0
	cy = vp.y / 2.0
	ppm = min((area_w) / COURT_WIDTH, (area_h) / COURT_LENGTH_VISUAL)

func _process(delta):
	_update_layout()
	var events = GameManager.match_events
	var latest_alts = []
	var latest_angles = []
	var prev_ball_target = ball_target
	if events.size() > 0:
		var latest = events[events.size() - 1]
		target_positions.clear()
		for pos in latest.positions:
			target_positions.append(_court(pos.x, pos.z))
			latest_alts.append(pos.get("y", 0.0))
			latest_angles.append(-float(pos.get("angle", 0.0)))
		ball_target   = _court(latest.ball.x, latest.ball.z)
		ball_altitude = latest.ball.y

	var smooth = 1.0 - exp(-10.0 * delta)
	while current_angles.size() < target_positions.size():
		current_angles.append(0.0)
	
	for i in range(min(target_positions.size(), current_positions.size())):
		current_positions[i] = current_positions[i].lerp(target_positions[i], smooth)
		if i < latest_alts.size() and i < player_altitudes.size():
			player_altitudes[i] = lerp(player_altitudes[i], float(latest_alts[i]), smooth)
		if i < latest_angles.size():
			current_angles[i] = lerp_angle(current_angles[i], float(latest_angles[i]), smooth)
	
	current_ball_pos = current_ball_pos.lerp(ball_target, smooth)
	var ball_vel = ball_target - prev_ball_target
	if ball_vel.length() > 0.01:
		ball_angle = lerp_angle(ball_angle, ball_vel.angle(), smooth * 1.5)
	
	queue_redraw()

func _court(mx: float, mz: float) -> Vector2:
	return Vector2(cx + mx * ppm, cy - mz * ppm)

func _draw():
	_draw_hardwood()
	_draw_court_lines()
	_draw_players()
	_draw_ball()

func _draw_hardwood():
	var base_color = Color(0.9, 0.68, 0.38)
	var alt_color  = Color(0.85, 0.63, 0.35)
	
	var margin = 1.5
	var top_left = _court(-HALF_WIDTH - margin, VISUAL_HALF_LENGTH + margin)
	var bot_right = _court(HALF_WIDTH + margin, -VISUAL_HALF_LENGTH - margin)
	
	# Draw base rect
	draw_rect(Rect2(top_left.x, top_left.y, bot_right.x - top_left.x, bot_right.y - top_left.y), base_color, true)
	
	# Draw plank stripes (horizontal for visual flair)
	var plank_h = 1.0 * ppm
	var num_planks = int((bot_right.y - top_left.y) / plank_h) + 1
	for i in range(num_planks):
		if i % 2 == 1:
			draw_rect(Rect2(top_left.x, top_left.y + i * plank_h, bot_right.x - top_left.x, plank_h), alt_color, true)
			
	# Border color
	var border_color = Color(0.08, 0.12, 0.20)
	var court_tl = _court(-HALF_WIDTH, VISUAL_HALF_LENGTH)
	var court_br = _court(HALF_WIDTH, -VISUAL_HALF_LENGTH)
	
	# Paint outside area border
	draw_rect(Rect2(top_left.x, top_left.y, bot_right.x - top_left.x, court_tl.y - top_left.y), border_color, true) # Top
	draw_rect(Rect2(top_left.x, court_br.y, bot_right.x - top_left.x, bot_right.y - court_br.y), border_color, true) # Bottom
	draw_rect(Rect2(top_left.x, court_tl.y, court_tl.x - top_left.x, court_br.y - court_tl.y), border_color, true) # Left
	draw_rect(Rect2(court_br.x, court_tl.y, bot_right.x - court_br.x, court_br.y - court_tl.y), border_color, true) # Right

func _draw_court_lines():
	var line_color = Color(1.0, 1.0, 1.0, 0.85)
	var line_w = max(2.0, ppm * 0.06)
	
	var court_tl = _court(-HALF_WIDTH, VISUAL_HALF_LENGTH)
	var court_br = _court(HALF_WIDTH, -VISUAL_HALF_LENGTH)
	draw_rect(Rect2(court_tl.x, court_tl.y, court_br.x - court_tl.x, court_br.y - court_tl.y), line_color, false, line_w)
	
	# Midcourt
	var mid_y = _court(0.0, 0.0).y
	draw_line(Vector2(court_tl.x, mid_y), Vector2(court_br.x, mid_y), line_color, line_w, true)
	
	# Center circle
	var center = _court(0.0, 0.0)
	draw_circle(center, CENTER_RAD * ppm, Color(0.9, 0.1, 0.1, 0.4)) # Red logo area
	draw_arc(center, CENTER_RAD * ppm, 0, TAU, 64, line_color, line_w, true)
	
	_draw_side_premium(1.0, Color(0.1, 0.25, 0.65, 0.9)) # Blue Home Paint
	_draw_side_premium(-1.0, Color(0.85, 0.15, 0.15, 0.9)) # Red Away Paint

func _draw_side_premium(dir: float, paint_color: Color):
	var line_color = Color(1.0, 1.0, 1.0, 0.85)
	var line_w = max(2.0, ppm * 0.06)
	
	var lw = LANE_WIDTH / 2.0 * ppm
	var ld = LANE_DEPTH * ppm
	var baseline_y = _court(0.0, dir * VISUAL_HALF_LENGTH).y
	var ft_y = baseline_y + dir * ld
	
	# Painted Lane
	var p_top = min(baseline_y, ft_y)
	var paint_rect = Rect2(cx - lw, p_top, lw * 2.0, abs(ft_y - baseline_y))
	draw_rect(paint_rect, paint_color, true)
	draw_rect(paint_rect, line_color, false, line_w)
	
	# Restricted area (arco de baixo do garrafao)
	var hoop_pos = _court(0.0, dir * RIM_Z)
	var rest_rad = REST_RADIUS * ppm
	var start_a = 0.0 if dir > 0 else PI
	var end_a = PI if dir > 0 else TAU
	draw_arc(hoop_pos, rest_rad, start_a, end_a, 32, line_color, line_w, true)
	
	# FT Circle
	var ft_c = Vector2(cx, ft_y)
	var ft_rad = FT_RADIUS * ppm
	draw_arc(ft_c, ft_rad, start_a, end_a, 32, line_color, line_w, true)
	_draw_dashed_arc(ft_c, ft_rad, end_a, start_a + TAU, 24, line_color, line_w)
	
	# 3PT Line
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
	
	# Backboard & Hoop
	var bb_y = hoop_pos.y - dir * (HOOP_RADIUS * ppm + 1.5)
	draw_line(Vector2(hoop_pos.x - 14, bb_y), Vector2(hoop_pos.x + 14, bb_y), Color(0.2, 0.2, 0.2), line_w * 1.5, true)
	draw_circle(hoop_pos, HOOP_RADIUS * ppm, Color(0.9, 0.3, 0.1, 0.3)) # Hoop net tint
	draw_arc(hoop_pos, HOOP_RADIUS * ppm, 0, TAU, 24, Color(0.95, 0.4, 0.1), line_w, true)

func _draw_dashed_arc(center: Vector2, radius: float, start_angle: float, end_angle: float, segments: int, color: Color, width: float):
	var diff = end_angle - start_angle
	var step = diff / float(segments)
	for i in range(0, segments, 2):
		var a1 = start_angle + i * step
		var a2 = start_angle + (i + 1.0) * step
		var p1 = center + Vector2(cos(a1), sin(a1)) * radius
		var p2 = center + Vector2(cos(a2), sin(a2)) * radius
		draw_line(p1, p2, color, width, true)

func _draw_players():
	if GameManager.match_events.is_empty(): return
	var font = ThemeDB.fallback_font

	for i in range(min(current_positions.size(), 10)):
		var pos = current_positions[i]
		var is_home = i < 5
		var alt = player_altitudes[i] if i < player_altitudes.size() else 0.0
		var scale_f = 1.0 + alt * 0.4
		var rad = clamp(ppm * 0.40 * scale_f, 12.0, 35.0)
		
		# Shadow
		var s_rad = rad * 1.1
		var s_alpha = max(0.1, 0.6 - alt * 0.15)
		var s_offset = Vector2(1.5, 2.5 + alt * 6.0)
		draw_circle(pos + s_offset, s_rad, Color(0, 0, 0, s_alpha))
		
		# Base Jersey Color
		var j_col = Color(0.15, 0.40, 0.90) if is_home else Color(0.90, 0.20, 0.25)
		draw_circle(pos, rad, j_col)
		
		# Inner gradient effect (pseudo-3D specular highlight)
		draw_circle(pos - Vector2(rad*0.2, rad*0.2), rad * 0.8, j_col.lightened(0.2))
		
		# Premium border
		draw_arc(pos, rad, 0, TAU, 32, Color(1, 1, 1, 0.95), max(2.0, rad * 0.15), true)
		
		# Direction indicator
		if i < current_angles.size():
			var a = current_angles[i]
			var dir = Vector2(cos(a), sin(a))
			var p1 = pos + dir * rad * 1.3
			var p2 = pos + dir.rotated(0.4) * rad * 0.8
			var p3 = pos + dir.rotated(-0.4) * rad * 0.8
			draw_polygon(PackedVector2Array([p1, p2, p3]), PackedColorArray([Color(1, 1, 1, 0.9)]))
		
		# Numbers
		if font:
			var num = str(i + 1)
			var fs = int(rad * 1.25)
			var sz = font.get_string_size(num, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
			var t_pos = pos - sz / 2.0 + Vector2(0, fs * 0.35)
			
			draw_string_outline(font, t_pos, num, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, max(2, int(rad*0.2)), Color(0,0,0,0.85))
			draw_string(font, t_pos, num, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(1,1,1,1))

func _draw_ball():
	var pos = current_ball_pos
	var alt = max(0.0, ball_altitude - 1.0)
	var base_r = ppm * 0.25
	var rad = clamp(base_r * (1.0 + alt * 0.3), 5.0, 26.0)
	
	var s_alpha = max(0.05, 0.6 - alt * 0.1)
	var s_rad = base_r * (1.0 + alt * 0.1)
	draw_circle(pos + Vector2(2.0, 4.0 + alt * 6.0), s_rad, Color(0, 0, 0, s_alpha))
	
	# Orange sphere
	draw_circle(pos, rad, Color(0.90, 0.45, 0.05))
	draw_circle(pos - Vector2(rad*0.2, rad*0.2), rad*0.7, Color(1.0, 0.65, 0.25))
	
	# Basketball lines
	var line_w = max(1.0, rad*0.1)
	draw_arc(pos, rad, 0, TAU, 32, Color(0.1, 0.05, 0.0, 0.95), line_w, true)
	draw_line(pos - Vector2(rad, 0), pos + Vector2(rad, 0), Color(0.1, 0.05, 0.0, 0.8), line_w, true)
	draw_line(pos - Vector2(0, rad), pos + Vector2(0, rad), Color(0.1, 0.05, 0.0, 0.8), line_w, true)
	
	# Trajectory indicator (ponta) if it's moving fast
	if alt > 0.1:
		var dir = Vector2(cos(ball_angle), sin(ball_angle))
		var tip = pos + dir * rad * 1.8
		var left = pos + dir.rotated(0.5) * rad * 1.1
		var right = pos + dir.rotated(-0.5) * rad * 1.1
		draw_polygon(PackedVector2Array([tip, left, right]), PackedColorArray([Color(1.0, 0.8, 0.2, 0.9)]))

func clear_court():
	target_positions.clear(); current_positions.clear(); player_altitudes.clear()
	for i in range(10): current_positions.append(Vector2.ZERO); player_altitudes.append(0.0)
	ball_target = Vector2.ZERO; current_ball_pos = Vector2.ZERO
	queue_redraw()
