class_name VirtualTouchPad
extends Control

## Virtual Mobile Touch Controls - Premium Anime Esports Edition:
## - Left: Glassmorphic Capsule Drag Track with Glowing Cyber-Puck
## - Right: Ergonomic High-End Vector Action Buttons (J: Drop, K: Clear, L: Dynamic Jump/Smash)

signal shot_triggered(shot_type: String)
signal jump_triggered()

var player: BadmintonPlayer = null

# Left Touchpad Track parameters
var track_rect: Rect2 = Rect2(42.0, 560.0, 236.0, 74.0)
var knob_center: Vector2 = Vector2(160.0, 597.0)
var knob_pos: Vector2 = Vector2(160.0, 597.0)
var knob_radius: float = 30.0
var max_drag_dist: float = 82.0
var track_touch_id: int = -1
var is_dragging_knob: bool = false
var last_forward_tap_ticks: int = 0

# Right Action Buttons parameters (Ergonomic Arch layout for natural thumb sweep)
# Button J (Drop / Bỏ nhỏ - Emerald Wind)
var btn_j_center: Vector2 = Vector2(970.0, 615.0)
var btn_j_radius: float = 40.0
var btn_j_touch_id: int = -1
var btn_j_pressed: bool = false
var btn_j_scale: float = 1.0
var btn_j_press_anim: float = 0.0

# Button K (Clear / Phông sâu - Solar Amber)
var btn_k_center: Vector2 = Vector2(1078.0, 515.0)
var btn_k_radius: float = 40.0
var btn_k_touch_id: int = -1
var btn_k_pressed: bool = false
var btn_k_scale: float = 1.0
var btn_k_press_anim: float = 0.0

# Button L (Dynamic Jump & Smash - Crown Electric/Crimson)
var btn_l_center: Vector2 = Vector2(1185.0, 605.0)
var btn_l_radius: float = 48.0
var btn_l_touch_id: int = -1
var btn_l_pressed: bool = false
var btn_l_scale: float = 1.0
var btn_l_press_anim: float = 0.0

# Dynamic transition for Button L (0.0 = Ground/Jump, 1.0 = Air/Smash)
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
		knob_pos = knob_pos.lerp(knob_center, clamp(delta * 20.0, 0.0, 1.0))
		if player and is_instance_valid(player):
			player.touch_move_axis = (knob_pos.x - knob_center.x) / max_drag_dist
			if abs(player.touch_move_axis) < 0.02:
				player.touch_move_axis = 0.0
	
	# Smooth scale springs & ripple decay for buttons
	btn_j_scale = lerp(btn_j_scale, 0.88 if btn_j_pressed else 1.0, delta * 24.0)
	btn_k_scale = lerp(btn_k_scale, 0.88 if btn_k_pressed else 1.0, delta * 24.0)
	btn_l_scale = lerp(btn_l_scale, 0.88 if btn_l_pressed else 1.0, delta * 24.0)
	
	btn_j_press_anim = max(0.0, btn_j_press_anim - delta * 3.0)
	btn_k_press_anim = max(0.0, btn_k_press_anim - delta * 3.0)
	btn_l_press_anim = max(0.0, btn_l_press_anim - delta * 3.0)
	
	# L Button state: In air vs on ground
	var is_in_air = false
	if player and is_instance_valid(player):
		is_in_air = not player.is_on_ground()
	btn_l_air_prog = lerp(btn_l_air_prog, 1.0 if is_in_air else 0.0, delta * 15.0)
	
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	# Multi-touch events (mobile / tablets)
	if event is InputEventScreenTouch:
		_handle_touch(event.index, event.pressed, event.position)
	elif event is InputEventScreenDrag:
		_handle_drag(event.index, event.position)
	# Mouse fallback for desktop testing when touch mode is enabled
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if track_touch_id != 0 and btn_j_touch_id != 0 and btn_k_touch_id != 0 and btn_l_touch_id != 0:
			_handle_touch(999, event.pressed, event.position)
	elif event is InputEventMouseMotion and is_dragging_knob and track_touch_id == 999:
		_handle_drag(999, event.position)

func _handle_touch(touch_id: int, is_down: bool, pos: Vector2) -> void:
	if is_down:
		# 1. Touchpad track hit test (expanded hit padding for thumbs)
		var exp_rect = track_rect.grow(26.0)
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
		if pos.distance_to(btn_j_center) <= btn_j_radius + 20.0 and btn_j_touch_id == -1:
			btn_j_touch_id = touch_id
			btn_j_pressed = true
			btn_j_press_anim = 1.0
			shot_triggered.emit("drop")
			if player and is_instance_valid(player):
				player.touch_shot_pressed = "drop"
			return
			
		# 3. Button K (Clear)
		if pos.distance_to(btn_k_center) <= btn_k_radius + 20.0 and btn_k_touch_id == -1:
			btn_k_touch_id = touch_id
			btn_k_pressed = true
			btn_k_press_anim = 1.0
			shot_triggered.emit("clear")
			if player and is_instance_valid(player):
				player.touch_shot_pressed = "clear"
			return
			
		# 4. Button L (Dynamic Jump on ground / Smash in air)
		if pos.distance_to(btn_l_center) <= btn_l_radius + 22.0 and btn_l_touch_id == -1:
			btn_l_touch_id = touch_id
			btn_l_pressed = true
			btn_l_press_anim = 1.0
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
		
	# 1. DRAW LEFT PREMIUM CAPSULE TOUCHPAD
	_draw_left_touchpad()
	
	# 2. DRAW RIGHT ACTION BUTTONS
	_draw_button_j()
	_draw_button_k()
	_draw_button_l()

# ==============================================================================
# LEFT TOUCHPAD DRAWING (CAPSULE GLASS-MORPHISM + CYBER-PUCK)
# ==============================================================================
func _draw_left_touchpad() -> void:
	var tr = track_rect
	var cap_r = tr.size.y * 0.5
	var left_c = Vector2(tr.position.x + cap_r, tr.position.y + cap_r)
	var right_c = Vector2(tr.position.x + tr.size.x - cap_r, tr.position.y + cap_r)
	
	# Outer subtle glow aura
	var aura_col = Color(0.12, 0.65, 0.95, 0.15 if is_dragging_knob else 0.08)
	_draw_capsule_solid(left_c, right_c, cap_r + 4.0, aura_col)
	
	# Frosted dark obsidian glass body
	var body_col = Color(0.03, 0.07, 0.13, 0.82)
	_draw_capsule_solid(left_c, right_c, cap_r, body_col)
	
	# Top specular reflection rim (crescent glass gloss)
	var gloss_col = Color(0.35, 0.75, 1.0, 0.22)
	draw_line(Vector2(left_c.x, tr.position.y + 2.0), Vector2(right_c.x, tr.position.y + 2.0), gloss_col, 2.0, true)
	
	# Inner glowing track laser slot (the groove the knob slides in)
	var groove_col = Color(0.08, 0.28, 0.45, 0.60)
	draw_line(Vector2(left_c.x, knob_center.y), Vector2(right_c.x, knob_center.y), groove_col, 6.0, true)
	var groove_core = Color(0.20, 0.80, 1.0, 0.45 if is_dragging_knob else 0.25)
	draw_line(Vector2(left_c.x, knob_center.y), Vector2(right_c.x, knob_center.y), groove_core, 2.0, true)
	
	# Subtle laser tick marks on track groove
	for i in range(-3, 4):
		var tick_x = knob_center.x + i * 22.0
		var tick_h = 10.0 if i == 0 else 6.0
		var tick_alpha = 0.55 if i == 0 else 0.30
		draw_line(Vector2(tick_x, knob_center.y - tick_h * 0.5), Vector2(tick_x, knob_center.y + tick_h * 0.5), Color(0.30, 0.85, 1.0, tick_alpha), 1.5, true)
	
	# Directional Animated Arrow Chevrons
	var pulse = 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.005)
	var drag_ratio = (knob_pos.x - knob_center.x) / max_drag_dist
	
	# Left chevrons <<
	var left_active = drag_ratio < -0.15
	var l_col = Color(0.25, 0.90, 1.0, (0.95 if left_active else 0.45 * pulse))
	var lx = left_c.x - 8.0
	draw_polyline(PackedVector2Array([Vector2(lx + 8.0, knob_center.y - 8.0), Vector2(lx, knob_center.y), Vector2(lx + 8.0, knob_center.y + 8.0)]), l_col, 2.4, true)
	draw_polyline(PackedVector2Array([Vector2(lx + 16.0, knob_center.y - 8.0), Vector2(lx + 8.0, knob_center.y), Vector2(lx + 16.0, knob_center.y + 8.0)]), l_col * 0.7, 1.8, true)
	
	# Right chevrons >>
	var right_active = drag_ratio > 0.15
	var r_col = Color(0.25, 0.90, 1.0, (0.95 if right_active else 0.45 * pulse))
	var rx = right_c.x + 8.0
	draw_polyline(PackedVector2Array([Vector2(rx - 8.0, knob_center.y - 8.0), Vector2(rx, knob_center.y), Vector2(rx - 8.0, knob_center.y + 8.0)]), r_col, 2.4, true)
	draw_polyline(PackedVector2Array([Vector2(rx - 16.0, knob_center.y - 8.0), Vector2(rx - 8.0, knob_center.y), Vector2(rx - 16.0, knob_center.y + 8.0)]), r_col * 0.7, 1.8, true)
	
	# High-tech outer bevel border with corner notches
	var border_col = Color(0.25, 0.85, 1.0, 0.85 if is_dragging_knob else 0.45)
	_draw_capsule_outline(left_c, right_c, cap_r, border_col, 2.0)
	
	# -------------------------------------------------------------
	# SLIDING CYBER-PUCK (KNOB)
	# -------------------------------------------------------------
	var k_rad = knob_radius
	var k_glow_col = Color(0.15, 0.80, 1.0, 0.35 if is_dragging_knob else 0.15)
	
	# Radial glow aura
	draw_circle(knob_pos, k_rad + 6.0, k_glow_col)
	
	# Puck outer metallic rim
	draw_circle(knob_pos, k_rad, Color(0.06, 0.14, 0.22, 0.95))
	draw_arc(knob_pos, k_rad, 0.0, TAU, 36, Color(0.35, 0.90, 1.0, 0.95 if is_dragging_knob else 0.75), 2.4, true)
	
	# Puck inner core gradient
	draw_circle(knob_pos, k_rad - 5.0, Color(0.09, 0.24, 0.38, 0.95) if is_dragging_knob else Color(0.07, 0.16, 0.26, 0.95))
	draw_arc(knob_pos, k_rad - 5.0, 0.0, TAU, 32, Color(0.50, 0.95, 1.0, 0.50), 1.2, true)
	
	# Center high-tech glyph: ◀ ● ▶
	var glyph_col = Color(1.0, 1.0, 1.0, 0.95 if is_dragging_knob else 0.75)
	draw_circle(knob_pos, 4.0, glyph_col)
	# Left mini-pointer
	draw_polyline(PackedVector2Array([Vector2(knob_pos.x - 9.0, knob_center.y - 5.0), Vector2(knob_pos.x - 14.0, knob_center.y), Vector2(knob_pos.x - 9.0, knob_center.y + 5.0)]), glyph_col, 2.0, true)
	# Right mini-pointer
	draw_polyline(PackedVector2Array([Vector2(knob_pos.x + 9.0, knob_center.y - 5.0), Vector2(knob_pos.x + 14.0, knob_center.y), Vector2(knob_pos.x + 9.0, knob_center.y + 5.0)]), glyph_col, 2.0, true)
	
	# Sleek Minimalist Footwork Badge
	_draw_tech_badge("DI CHUYỂN", Vector2(knob_center.x, tr.position.y + tr.size.y + 16.0), Color(0.30, 0.85, 1.0, 0.80))

# ==============================================================================
# BUTTON J: DROP SHOT / BỎ NHỎ (EMERALD MINT)
# ==============================================================================
func _draw_button_j() -> void:
	var c = btn_j_center
	var r = btn_j_radius * btn_j_scale
	var primary_col = Color(0.10, 0.98, 0.65) # Vibrant Emerald Mint
	var base_bg = Color(0.03, 0.14, 0.09, 0.88)
	
	# Ripple wave on press
	if btn_j_press_anim > 0.01:
		var wave_r = btn_j_radius * (1.0 + (1.0 - btn_j_press_anim) * 0.45)
		draw_arc(c, wave_r, 0.0, TAU, 36, Color(primary_col.r, primary_col.g, primary_col.b, btn_j_press_anim * 0.7), 2.0, true)
	
	_draw_esports_button_base(c, r, primary_col, base_bg, btn_j_pressed)
	
	# VECTOR LOGO: AERO-DYNAMIC FEATHERED SHUTTLECOCK DIPPING OVER NET
	# 1. Stylized illuminated net pole on left-center
	var net_x = c.x - 6.0
	draw_line(Vector2(net_x, c.y - 12.0), Vector2(net_x, c.y + 14.0), Color(1.0, 1.0, 1.0, 0.85), 2.6, true)
	draw_line(Vector2(net_x - 4.0, c.y - 12.0), Vector2(net_x + 4.0, c.y - 12.0), Color(1.0, 1.0, 1.0, 0.95), 2.6, true)
	# Mini net grid hashes
	for ny in [-6.0, 0.0, 6.0]:
		draw_line(Vector2(net_x - 3.0, c.y + ny), Vector2(net_x + 3.0, c.y + ny), Color(0.60, 0.95, 0.80, 0.55), 1.2, true)
	
	# 2. Smooth aerodynamic parachute drop curve
	var curve_pts = PackedVector2Array()
	var steps = 14
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var px = lerp(c.x - 20.0, c.x + 14.0, t)
		var py = c.y - 15.0 * sin(t * PI * 0.88) + 4.0 * t
		curve_pts.append(Vector2(px, py))
	# Glowing slipstream trail
	draw_polyline(curve_pts, Color(primary_col.r, primary_col.g, primary_col.b, 0.35), 4.2, true)
	draw_polyline(curve_pts, primary_col, 2.2, true)
	
	# 3. Exquisite mini shuttlecock descending at the tip
	var tip = curve_pts[curve_pts.size() - 1]
	# Rounded cork
	draw_circle(tip, 3.4, Color(1.0, 1.0, 1.0, 0.95))
	# Feather skirt angled upward
	var f_dir = Vector2(0.6, -0.8).normalized()
	draw_polyline(PackedVector2Array([
		tip + f_dir * 1.5,
		tip + f_dir * 8.5 + f_dir.orthogonal() * 4.2,
		tip + f_dir * 9.5,
		tip + f_dir * 8.5 - f_dir.orthogonal() * 4.2,
		tip + f_dir * 1.5
	]), primary_col, 1.8, true)
	
	_draw_tech_badge("BỎ NHỎ", Vector2(c.x, c.y + r + 15.0), primary_col)

# ==============================================================================
# BUTTON K: CLEAR SHOT / PHÔNG SÂU (SOLAR AMBER)
# ==============================================================================
func _draw_button_k() -> void:
	var c = btn_k_center
	var r = btn_k_radius * btn_k_scale
	var primary_col = Color(1.0, 0.78, 0.15) # Brilliant Solar Amber
	var base_bg = Color(0.15, 0.09, 0.02, 0.88)
	
	# Ripple wave on press
	if btn_k_press_anim > 0.01:
		var wave_r = btn_k_radius * (1.0 + (1.0 - btn_k_press_anim) * 0.45)
		draw_arc(c, wave_r, 0.0, TAU, 36, Color(primary_col.r, primary_col.g, primary_col.b, btn_k_press_anim * 0.7), 2.0, true)
	
	_draw_esports_button_base(c, r, primary_col, base_bg, btn_k_pressed)
	
	# VECTOR LOGO: HIGH-ALTITUDE ROCKETING PARABOLIC LIFT
	# 1. Soaring parabolic trajectory to backcourt
	var curve_pts = PackedVector2Array()
	var steps = 16
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var px = lerp(c.x - 18.0, c.x + 16.0, t)
		var py = c.y + 13.0 - 29.0 * sin(t * PI * 0.96)
		curve_pts.append(Vector2(px, py))
	# Luminous energy glow trail
	draw_polyline(curve_pts, Color(primary_col.r, primary_col.g, primary_col.b, 0.35), 4.6, true)
	draw_polyline(curve_pts, primary_col, 2.4, true)
	
	# 2. Sonic speed rings along trajectory
	var mid_pt = curve_pts[int(steps * 0.48)]
	draw_arc(mid_pt, 5.0, -PI * 0.8, PI * 0.2, 10, Color(1.0, 0.95, 0.6, 0.75), 1.8, true)
	
	# 3. High-velocity shuttlecock rocket head with sharp arrowhead
	var end_pt = curve_pts[curve_pts.size() - 1]
	var dir = Vector2(0.9, 0.85).normalized()
	draw_circle(end_pt, 3.4, Color(1.0, 1.0, 1.0, 0.95))
	draw_polyline(PackedVector2Array([
		end_pt - dir.rotated(0.45) * 10.0,
		end_pt,
		end_pt - dir.rotated(-0.45) * 10.0
	]), primary_col, 2.4, true)
	
	_draw_tech_badge("PHÔNG SÂU", Vector2(c.x, c.y + r + 15.0), primary_col)

# ==============================================================================
# BUTTON L: DYNAMIC JUMP & SMASH (SKY CYAN & BLAZING CRIMSON)
# ==============================================================================
func _draw_button_l() -> void:
	var c = btn_l_center
	var r = btn_l_radius * btn_l_scale
	var p = btn_l_air_prog # 0.0 = Ground (Jump), 1.0 = Air (Smash)
	
	var col_jump = Color(0.10, 0.85, 1.0) # Sky Electric Cyan
	var col_smash = Color(1.0, 0.22, 0.20) # Blazing Crimson Lightning
	var cur_col = col_jump.lerp(col_smash, p)
	
	var bg_jump = Color(0.03, 0.12, 0.22, 0.90)
	var bg_smash = Color(0.22, 0.04, 0.04, 0.92)
	var cur_bg = bg_jump.lerp(bg_smash, p)
	
	# Ripple wave on press
	if btn_l_press_anim > 0.01:
		var wave_r = btn_l_radius * (1.0 + (1.0 - btn_l_press_anim) * 0.45)
		draw_arc(c, wave_r, 0.0, TAU, 36, Color(cur_col.r, cur_col.g, cur_col.b, btn_l_press_anim * 0.75), 2.4, true)
	
	_draw_esports_button_base(c, r, cur_col, cur_bg, btn_l_pressed, true)
	
	if p < 0.50:
		# -------------------------------------------------------------
		# STATE A: JUMP EMBLEM (AERODYNAMIC VALKYRIE WINGS & LIFT SHOCKWAVE)
		# -------------------------------------------------------------
		var alpha = 1.0 - p * 2.0
		var j_col = Color(col_jump.r, col_jump.g, col_jump.b, alpha)
		var glow_col = Color(1.0, 1.0, 1.0, alpha * 0.90)
		
		# Wing silhouette on left
		draw_polyline(PackedVector2Array([
			Vector2(c.x - 6.0, c.y + 4.0),
			Vector2(c.x - 17.0, c.y - 2.0),
			Vector2(c.x - 22.0, c.y - 12.0),
			Vector2(c.x - 13.0, c.y - 8.0),
			Vector2(c.x - 5.0, c.y - 2.0)
		]), j_col, 2.2, true)
		
		# Wing silhouette on right
		draw_polyline(PackedVector2Array([
			Vector2(c.x + 6.0, c.y + 4.0),
			Vector2(c.x + 17.0, c.y - 2.0),
			Vector2(c.x + 22.0, c.y - 12.0),
			Vector2(c.x + 13.0, c.y - 8.0),
			Vector2(c.x + 5.0, c.y - 2.0)
		]), j_col, 2.2, true)
		
		# Twin upward supersonic lift chevrons ︽
		draw_polyline(PackedVector2Array([
			Vector2(c.x - 9.0, c.y + 1.0),
			Vector2(c.x, c.y - 8.0),
			Vector2(c.x + 9.0, c.y + 1.0)
		]), glow_col, 2.6, true)
		draw_polyline(PackedVector2Array([
			Vector2(c.x - 9.0, c.y + 9.0),
			Vector2(c.x, c.y),
			Vector2(c.x + 9.0, c.y + 9.0)
		]), j_col, 2.2, true)
		
		# Floor takeoff energy arc
		draw_arc(Vector2(c.x, c.y + 20.0), 14.0, PI * 0.12, PI * 0.88, 14, Color(j_col.r, j_col.g, j_col.b, alpha * 0.65), 2.0, true)
		
		_draw_tech_badge("NHẢY", Vector2(c.x, c.y + r + 15.0), cur_col)
	else:
		# -------------------------------------------------------------
		# STATE B: BOOM SMASH EMBLEM (EXPLOSIVE THUNDERBOLT & IMPACT BURST)
		# -------------------------------------------------------------
		var alpha = (p - 0.50) * 2.0
		var s_col = Color(col_smash.r, col_smash.g, col_smash.b, alpha)
		var core_col = Color(1.0, 0.95, 0.70, alpha)
		
		# Aggressive downward spike lightning bolt
		var bolt_glow = PackedVector2Array([
			Vector2(c.x + 7.0, c.y - 20.0),
			Vector2(c.x - 5.0, c.y - 2.0),
			Vector2(c.x + 5.0, c.y - 1.0),
			Vector2(c.x - 9.0, c.y + 19.0)
		])
		# Outer glow bolt
		draw_polyline(bolt_glow, Color(s_col.r, s_col.g, s_col.b, alpha * 0.4), 6.5, true)
		# Crimson flame bolt
		draw_polyline(bolt_glow, s_col, 3.6, true)
		# White-hot razor core
		draw_polyline(bolt_glow, core_col, 1.8, true)
		
		# Explosive impact sparks at tip
		var impact_pt = Vector2(c.x - 9.0, c.y + 19.0)
		draw_circle(impact_pt, 4.0, core_col)
		draw_line(impact_pt, impact_pt + Vector2(-9.0, 5.0), s_col, 2.2, true)
		draw_line(impact_pt, impact_pt + Vector2(-3.0, 9.0), s_col, 2.2, true)
		draw_line(impact_pt, impact_pt + Vector2(6.0, 5.0), s_col, 2.2, true)
		
		# Dual flanking shockwave blades
		draw_line(Vector2(c.x - 17.0, c.y - 7.0), Vector2(c.x - 11.0, c.y + 5.0), Color(s_col.r, s_col.g, s_col.b, alpha * 0.7), 2.0, true)
		draw_line(Vector2(c.x + 17.0, c.y - 7.0), Vector2(c.x + 11.0, c.y + 5.0), Color(s_col.r, s_col.g, s_col.b, alpha * 0.7), 2.0, true)
		
		_draw_tech_badge("ĐẬP CẦU", Vector2(c.x, c.y + r + 15.0), cur_col)

# ==============================================================================
# COMMON DRAW HELPERS (ESPORTS BUTTON BASE, CAPSULES, BADGES)
# ==============================================================================
func _draw_esports_button_base(c: Vector2, r: float, theme_col: Color, bg_col: Color, is_down: bool, is_crown: bool = false) -> void:
	# 1. Soft atmospheric outer radial aura
	var aura_alpha = 0.28 if is_down else (0.16 if is_crown else 0.10)
	draw_circle(c, r + (7.0 if is_crown else 5.0), Color(theme_col.r, theme_col.g, theme_col.b, aura_alpha))
	
	# 2. Outer milled metallic bezel ring
	var bezel_col = Color(theme_col.r, theme_col.g, theme_col.b, 0.95 if is_down else 0.65)
	draw_arc(c, r, 0.0, TAU, 36, bezel_col, 2.8 if is_crown else 2.2, true)
	
	# Cardinal notch cuts at 0, 90, 180, 270 deg for high-tech gaming aesthetic
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var notch_dir = Vector2(cos(angle), sin(angle))
		draw_line(c + notch_dir * (r - 4.0), c + notch_dir * (r + 4.0), Color(1.0, 1.0, 1.0, 0.85), 2.0, true)
	
	# 3. Frosted obsidian glass disc interior
	draw_circle(c, r - 1.0, bg_col)
	
	# 4. Top specular reflection crescent (glossy finish)
	draw_arc(c - Vector2(0.0, 2.0), r * 0.72, -PI * 0.85, -PI * 0.15, 20, Color(1.0, 1.0, 1.0, 0.25), 1.8, true)

func _draw_capsule_solid(c1: Vector2, c2: Vector2, r: float, col: Color) -> void:
	draw_circle(c1, r, col)
	draw_circle(c2, r, col)
	var dir = (c2 - c1).normalized()
	var perp = dir.orthogonal() * r
	var pts = PackedVector2Array([
		c1 - perp,
		c2 - perp,
		c2 + perp,
		c1 + perp
	])
	draw_colored_polygon(pts, col)

func _draw_capsule_outline(c1: Vector2, c2: Vector2, r: float, col: Color, width: float) -> void:
	var segs = 14
	var pts = PackedVector2Array()
	# Left semicircular cap
	for i in range(segs + 1):
		var ang = PI * 0.5 + (PI / segs) * i
		pts.append(c1 + Vector2(cos(ang), sin(ang)) * r)
	# Right semicircular cap
	for i in range(segs + 1):
		var ang = -PI * 0.5 + (PI / segs) * i
		pts.append(c2 + Vector2(cos(ang), sin(ang)) * r)
	pts.append(pts[0])
	draw_polyline(pts, col, width, true)

func _draw_tech_badge(text: String, pos: Vector2, col: Color) -> void:
	var font = ThemeDB.fallback_font
	if not font:
		return
	var font_sz = 11
	var str_sz = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz)
	var badge_w = str_sz.x + 16.0
	var badge_h = 16.0
	var badge_rect = Rect2(pos.x - badge_w * 0.5, pos.y - badge_h * 0.5 - 2.0, badge_w, badge_h)
	
	# Dark pill background
	draw_rect(badge_rect, Color(0.02, 0.06, 0.10, 0.75), true, -1, false)
	# Outline
	draw_rect(badge_rect, Color(col.r, col.g, col.b, 0.40), false, 1.0, false)
	# Label string
	draw_string(font, Vector2(pos.x - str_sz.x * 0.5, pos.y + 3.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, col)
