class_name VirtualTouchPad
extends Control

## Virtual Mobile Touch Controls:
## - Left: Drag Touchpad (kéo qua lại mượt mà, không tách rời 2 nút)
## - Right: Circular J (Drop), K (Clear), L (Dynamic Jump & Smash) with Vector Function Logos

signal shot_triggered(shot_type: String)
signal jump_triggered()

var player: BadmintonPlayer = null

# Left Touchpad Track parameters
var track_rect: Rect2 = Rect2(45.0, 560.0, 220.0, 72.0)
var knob_center: Vector2 = Vector2(155.0, 596.0)
var knob_pos: Vector2 = Vector2(155.0, 596.0)
var knob_radius: float = 28.0
var max_drag_dist: float = 78.0
var track_touch_id: int = -1
var is_dragging_knob: bool = false
var last_forward_tap_ticks: int = 0

# Right Action Buttons parameters (Ergonomic Arch layout for right thumb)
# Button J (Drop / Bỏ nhỏ)
var btn_j_center: Vector2 = Vector2(985.0, 615.0)
var btn_j_radius: float = 38.0
var btn_j_touch_id: int = -1
var btn_j_pressed: bool = false
var btn_j_scale: float = 1.0

# Button K (Clear / Phông sâu)
var btn_k_center: Vector2 = Vector2(1090.0, 520.0)
var btn_k_radius: float = 38.0
var btn_k_touch_id: int = -1
var btn_k_pressed: bool = false
var btn_k_scale: float = 1.0

# Button L (Dynamic Jump & Smash)
var btn_l_center: Vector2 = Vector2(1195.0, 610.0)
var btn_l_radius: float = 46.0
var btn_l_touch_id: int = -1
var btn_l_pressed: bool = false
var btn_l_scale: float = 1.0

# Appearance transition for Button L (Jump on ground, Smash in air)
var btn_l_air_prog: float = 0.0

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)
	knob_center = Vector2(track_rect.position.x + track_rect.size.x * 0.5, track_rect.position.y + track_rect.size.y * 0.5)
	knob_pos = knob_center

func set_target_player(p: BadmintonPlayer) -> void:
	player = p

func _process(delta: float) -> void:
	if not visible:
		return
		
	# Smooth spring return for knob when not dragging
	if not is_dragging_knob:
		knob_pos = knob_pos.lerp(knob_center, clamp(delta * 18.0, 0.0, 1.0))
		if player and is_instance_valid(player):
			player.touch_move_axis = (knob_pos.x - knob_center.x) / max_drag_dist
			if abs(player.touch_move_axis) < 0.02:
				player.touch_move_axis = 0.0
	
	# Smooth scale springs for buttons
	btn_j_scale = lerp(btn_j_scale, 0.90 if btn_j_pressed else 1.0, delta * 24.0)
	btn_k_scale = lerp(btn_k_scale, 0.90 if btn_k_pressed else 1.0, delta * 24.0)
	btn_l_scale = lerp(btn_l_scale, 0.90 if btn_l_pressed else 1.0, delta * 24.0)
	
	# L Button state: In air vs on ground
	var is_in_air = false
	if player and is_instance_valid(player):
		is_in_air = not player.is_on_ground()
	btn_l_air_prog = lerp(btn_l_air_prog, 1.0 if is_in_air else 0.0, delta * 14.0)
	
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	# Multi-touch events (mobile / tablets)
	if event is InputEventScreenTouch:
		_handle_touch(event.index, event.pressed, event.position)
	elif event is InputEventScreenDrag:
		_handle_drag(event.index, event.position)
	# Mouse emulation (desktop browser testing)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_touch(999, event.pressed, event.position)
	elif event is InputEventMouseMotion and is_dragging_knob and track_touch_id == 999:
		_handle_drag(999, event.position)

func _handle_touch(touch_id: int, is_down: bool, pos: Vector2) -> void:
	if is_down:
		# 1. Touchpad track hit test (Expanded touch padding)
		var exp_rect = track_rect.grow(24.0)
		if exp_rect.has_point(pos) and track_touch_id == -1:
			track_touch_id = touch_id
			is_dragging_knob = true
			_update_knob_drag(pos.x)
			
			# Check forward double tap / quick flick for dive rescue
			var offset_x = pos.x - knob_center.x
			var is_forward = (offset_x > 25.0) if (player == null or player.court_side == "player") else (offset_x < -25.0)
			if is_forward:
				var now = Time.get_ticks_msec()
				if now - last_forward_tap_ticks < 320:
					if player and is_instance_valid(player):
						player.start_dive(1.0 if player.court_side == "player" else -1.0)
					last_forward_tap_ticks = 0
				else:
					last_forward_tap_ticks = now
			return
			
		# 2. Button J (Drop)
		if pos.distance_to(btn_j_center) <= btn_j_radius + 18.0 and btn_j_touch_id == -1:
			btn_j_touch_id = touch_id
			btn_j_pressed = true
			shot_triggered.emit("drop")
			if player and is_instance_valid(player):
				player.touch_shot_pressed = "drop"
			return
			
		# 3. Button K (Clear)
		if pos.distance_to(btn_k_center) <= btn_k_radius + 18.0 and btn_k_touch_id == -1:
			btn_k_touch_id = touch_id
			btn_k_pressed = true
			shot_triggered.emit("clear")
			if player and is_instance_valid(player):
				player.touch_shot_pressed = "clear"
			return
			
		# 4. Button L (Dynamic Jump on ground / Smash in air)
		if pos.distance_to(btn_l_center) <= btn_l_radius + 20.0 and btn_l_touch_id == -1:
			btn_l_touch_id = touch_id
			btn_l_pressed = true
			if player and is_instance_valid(player):
				if player.is_on_ground():
					jump_triggered.emit()
					player.touch_jump_pressed = true
				else:
					shot_triggered.emit("smash")
					player.touch_shot_pressed = "smash"
			else:
				shot_triggered.emit("smash")
			return
	else:
		# Touch up / release
		if touch_id == track_touch_id:
			track_touch_id = -1
			is_dragging_knob = false
		if touch_id == btn_j_touch_id:
			btn_j_touch_id = -1
			btn_j_pressed = false
		if touch_id == btn_k_touch_id:
			btn_k_touch_id = -1
			btn_k_pressed = false
		if touch_id == btn_l_touch_id:
			btn_l_touch_id = -1
			btn_l_pressed = false

func _handle_drag(touch_id: int, pos: Vector2) -> void:
	if touch_id == track_touch_id:
		_update_knob_drag(pos.x)

func _update_knob_drag(finger_x: float) -> void:
	var offset = clamp(finger_x - knob_center.x, -max_drag_dist, max_drag_dist)
	knob_pos.x = knob_center.x + offset
	knob_pos.y = knob_center.y
	if player and is_instance_valid(player):
		player.touch_move_axis = offset / max_drag_dist

func _draw() -> void:
	if not visible:
		return
		
	# ==========================================================
	# 1. DRAW LEFT TOUCHPAD TRACK (KÉO QUA LẠI ĐỂ DI CHUYỂN)
	# ==========================================================
	var tr = track_rect
	var corner_r = tr.size.y * 0.5
	
	# Track background capsule
	draw_rect(tr, Color(0.04, 0.08, 0.14, 0.68), true, -1, false)
	# Ambient inner highlight line
	draw_line(Vector2(tr.position.x + corner_r, knob_center.y), Vector2(tr.position.x + tr.size.x - corner_r, knob_center.y), Color(0.15, 0.45, 0.65, 0.35), 3.0, true)
	
	# Directional arrows inside track
	var arrow_col = Color(0.35, 0.85, 1.0, 0.55 if not is_dragging_knob else 0.85)
	# Left chevron <
	var lx = tr.position.x + 28.0
	var ly = knob_center.y
	draw_polyline(PackedVector2Array([Vector2(lx + 8.0, ly - 10.0), Vector2(lx - 4.0, ly), Vector2(lx + 8.0, ly + 10.0)]), arrow_col, 2.5, true)
	draw_polyline(PackedVector2Array([Vector2(lx + 18.0, ly - 10.0), Vector2(lx + 6.0, ly), Vector2(lx + 18.0, ly + 10.0)]), arrow_col * 0.65, 2.0, true)
	
	# Right chevron >
	var rx = tr.position.x + tr.size.x - 28.0
	draw_polyline(PackedVector2Array([Vector2(rx - 8.0, ly - 10.0), Vector2(rx + 4.0, ly), Vector2(rx - 8.0, ly + 10.0)]), arrow_col, 2.5, true)
	draw_polyline(PackedVector2Array([Vector2(rx - 18.0, ly - 10.0), Vector2(rx - 6.0, ly), Vector2(rx - 18.0, ly + 10.0)]), arrow_col * 0.65, 2.0, true)
	
	# Track outer border
	var track_border_col = Color(0.30, 0.88, 1.0, 0.85 if is_dragging_knob else 0.45)
	_draw_capsule_outline(tr, corner_r, track_border_col, 2.0)
	
	# Sliding thumb knob (núm tròn cảm ứng)
	var active_knob_col = Color(0.20, 0.90, 1.0, 0.95) if is_dragging_knob else Color(0.65, 0.85, 1.0, 0.80)
	# Knob glow halo
	draw_circle(knob_pos, knob_radius + 4.0, Color(0.15, 0.75, 1.0, 0.25 if is_dragging_knob else 0.12))
	# Knob core
	draw_circle(knob_pos, knob_radius, Color(0.08, 0.18, 0.30, 0.92))
	draw_arc(knob_pos, knob_radius, 0.0, TAU, 32, active_knob_col, 2.4, true)
	# Knob center grip ridges (3 khấc vân chống trượt)
	for i in [-6.0, 0.0, 6.0]:
		var ridge_h = 14.0 if i == 0.0 else 10.0
		draw_line(Vector2(knob_pos.x + i, knob_pos.y - ridge_h * 0.5), Vector2(knob_pos.x + i, knob_pos.y + ridge_h * 0.5), Color(1.0, 1.0, 1.0, 0.75), 2.0, true)
	
	# Label hint below touchpad
	_draw_hint_text("KÉO QUA LẠI ĐỂ DI CHUYỂN", Vector2(knob_center.x, tr.position.y + tr.size.y + 16.0), Color(0.70, 0.85, 1.0, 0.70), 11)

	# ==========================================================
	# 2. DRAW RIGHT CIRCULAR BUTTONS (J: DROP, K: CLEAR, L: JUMP/SMASH)
	# ==========================================================
	_draw_round_button_j()
	_draw_round_button_k()
	_draw_round_button_l()

func _draw_capsule_outline(rect: Rect2, radius: float, col: Color, width: float) -> void:
	var pts = PackedVector2Array()
	var segs = 14
	# Left semicircular cap
	var left_center = Vector2(rect.position.x + radius, rect.position.y + radius)
	for i in range(segs + 1):
		var ang = PI * 0.5 + (PI / segs) * i
		pts.append(left_center + Vector2(cos(ang), sin(ang)) * radius)
	# Right semicircular cap
	var right_center = Vector2(rect.position.x + rect.size.x - radius, rect.position.y + radius)
	for i in range(segs + 1):
		var ang = -PI * 0.5 + (PI / segs) * i
		pts.append(right_center + Vector2(cos(ang), sin(ang)) * radius)
	pts.append(pts[0])
	draw_polyline(pts, col, width, true)

func _draw_round_button_j() -> void:
	var c = btn_j_center
	var r = btn_j_radius * btn_j_scale
	var base_col = Color(0.20, 0.95, 0.65) # Vibrant Emerald Mint
	
	# Outer glow & fill
	draw_circle(c, r + 4.0, Color(base_col.r, base_col.g, base_col.b, 0.22 if btn_j_pressed else 0.10))
	draw_circle(c, r, Color(0.04, 0.16, 0.11, 0.85))
	draw_arc(c, r, 0.0, TAU, 32, base_col * (1.3 if btn_j_pressed else 0.95), 2.8, true)
	
	# Vector Logo: Net Drop (Đường cong bỏ nhỏ sà sát mép lưới)
	# 1. Mini Net pole on left
	var net_x = c.x - 7.0
	draw_line(Vector2(net_x, c.y - 12.0), Vector2(net_x, c.y + 14.0), Color(1.0, 1.0, 1.0, 0.85), 2.5, true)
	draw_line(Vector2(net_x - 4.0, c.y - 12.0), Vector2(net_x + 4.0, c.y - 12.0), Color(1.0, 1.0, 1.0, 0.95), 2.5, true)
	
	# 2. Smooth drop curve rising from left, peaking right over net, and diving steep
	var curve_pts = PackedVector2Array()
	var steps = 14
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var px = lerp(c.x - 18.0, c.x + 14.0, t)
		# Parabolic concave drop curve over net:
		var py = c.y - 15.0 * sin(t * PI * 0.85) + 3.0 * t
		curve_pts.append(Vector2(px, py))
	draw_polyline(curve_pts, base_col, 2.4, true)
	
	# 3. Delicate downward shuttlecock icon at the dive tip
	var tip = curve_pts[curve_pts.size() - 1]
	draw_circle(tip, 3.2, Color(1.0, 1.0, 1.0, 0.95))
	draw_line(tip, tip + Vector2(4.0, -7.0), base_col, 2.0, true)
	draw_line(tip, tip + Vector2(7.0, -4.0), base_col, 2.0, true)
	
	_draw_hint_text("BỎ NHỎ", Vector2(c.x, c.y + r + 15.0), base_col, 11)

func _draw_round_button_k() -> void:
	var c = btn_k_center
	var r = btn_k_radius * btn_k_scale
	var base_col = Color(1.0, 0.84, 0.25) # Vibrant Gold Amber
	
	# Outer glow & fill
	draw_circle(c, r + 4.0, Color(base_col.r, base_col.g, base_col.b, 0.22 if btn_k_pressed else 0.10))
	draw_circle(c, r, Color(0.16, 0.12, 0.04, 0.85))
	draw_arc(c, r, 0.0, TAU, 32, base_col * (1.3 if btn_k_pressed else 0.95), 2.8, true)
	
	# Vector Logo: High Clear Lift (Vòng cung phông bổng cao vút về sau sân)
	var curve_pts = PackedVector2Array()
	var steps = 16
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var px = lerp(c.x - 17.0, c.x + 15.0, t)
		var py = c.y + 12.0 - 28.0 * sin(t * PI)
		curve_pts.append(Vector2(px, py))
	draw_polyline(curve_pts, base_col, 2.6, true)
	
	# Arrowhead at apex/destination
	var end_pt = curve_pts[curve_pts.size() - 1]
	var dir = Vector2(1.0, 0.8).normalized()
	draw_line(end_pt, end_pt - dir.rotated(0.4) * 8.0, base_col, 2.4, true)
	draw_line(end_pt, end_pt - dir.rotated(-0.4) * 8.0, base_col, 2.4, true)
	
	_draw_hint_text("PHÔNG SÂU", Vector2(c.x, c.y + r + 15.0), base_col, 11)

func _draw_round_button_l() -> void:
	var c = btn_l_center
	var r = btn_l_radius * btn_l_scale
	var p = btn_l_air_prog # 0.0 = Ground (Jump), 1.0 = Air (Smash)
	
	var col_jump = Color(0.25, 0.85, 1.0) # Sky Blue Cyan
	var col_smash = Color(1.0, 0.32, 0.20) # Blazing Crimson Lightning
	var cur_col = col_jump.lerp(col_smash, p)
	
	var bg_col = Color(0.04, 0.14, 0.24, 0.88).lerp(Color(0.24, 0.06, 0.05, 0.90), p)
	
	# Outer glow & fill
	draw_circle(c, r + 5.0, Color(cur_col.r, cur_col.g, cur_col.b, 0.26 if btn_l_pressed else 0.12))
	draw_circle(c, r, bg_col)
	draw_arc(c, r, 0.0, TAU, 36, cur_col * (1.35 if btn_l_pressed else 1.0), 3.2, true)
	
	if p < 0.50:
		# LOGO A: JUMP EMBLEM (Đôi cánh bật nhảy & mũi tên hướng thiên)
		var jump_alpha = 1.0 - p * 2.0
		var j_col = Color(col_jump.r, col_jump.g, col_jump.b, jump_alpha)
		
		# Double chevron upward arrows ^ ^
		for off_y in [-5.0, 5.0]:
			var py = c.y + off_y
			draw_polyline(PackedVector2Array([Vector2(c.x - 14.0, py + 4.0), Vector2(c.x, py - 8.0), Vector2(c.x + 14.0, py + 4.0)]), j_col, 3.0, true)
		
		# Ground takeoff bounce ring
		draw_arc(Vector2(c.x, c.y + 18.0), 12.0, PI * 0.1, PI * 0.9, 12, j_col * 0.7, 2.0, true)
		_draw_hint_text("NHẢY", Vector2(c.x, c.y + r + 15.0), cur_col, 11)
	else:
		# LOGO B: EXPLOSIVE SMASH LIGHTNING BOLT (Tia sấm sét đập dứt điểm)
		var smash_alpha = (p - 0.50) * 2.0
		var s_col = Color(col_smash.r, col_smash.g, col_smash.b, smash_alpha)
		
		# Zig-zag lightning bolt striking down-left
		var bolt_pts = PackedVector2Array([
			Vector2(c.x + 6.0, c.y - 18.0),
			Vector2(c.x - 4.0, c.y - 2.0),
			Vector2(c.x + 5.0, c.y - 1.0),
			Vector2(c.x - 8.0, c.y + 18.0)
		])
		draw_polyline(bolt_pts, s_col, 3.4, true)
		draw_polyline(bolt_pts, Color(1.0, 1.0, 1.0, smash_alpha * 0.9), 1.5, true)
		
		# Impact sparks
		draw_circle(Vector2(c.x - 8.0, c.y + 18.0), 3.5, Color(1.0, 0.9, 0.3, smash_alpha))
		draw_line(Vector2(c.x - 8.0, c.y + 18.0), Vector2(c.x - 16.0, c.y + 22.0), s_col, 2.0, true)
		draw_line(Vector2(c.x - 8.0, c.y + 18.0), Vector2(c.x - 3.0, c.y + 25.0), s_col, 2.0, true)
		_draw_hint_text("ĐẬP CẦU", Vector2(c.x, c.y + r + 15.0), cur_col, 11)

func _draw_hint_text(text: String, pos: Vector2, col: Color, font_sz: int) -> void:
	var font = ThemeDB.fallback_font
	if not font:
		return
	var str_sz = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz)
	draw_string(font, Vector2(pos.x - str_sz.x * 0.5, pos.y), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, col)
