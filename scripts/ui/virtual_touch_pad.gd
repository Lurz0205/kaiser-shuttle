class_name VirtualTouchPad
extends Control

## Virtual Mobile Touch Controls - Studio Pre-rendered Graphic Edition:
## - Left: Pre-rendered Glassmorphic Capsule Track & Glowing Cyber-Puck
## - Right: Pre-rendered Graphic Action Buttons (J: Drop, K: Clear, L: Dynamic Jump/Smash)
## - GPU Textured Quad rendering: 0 per-frame vector math, 60fps locked on mobile web

signal shot_triggered(shot_type: String)
signal jump_triggered()

# Pre-rendered UI Assets
const TEX_TRACK = preload("res://assets/ui/touch/touch_track.png")
const TEX_KNOB = preload("res://assets/ui/touch/touch_knob.png")
const TEX_BTN_DROP = preload("res://assets/ui/touch/btn_drop.png")
const TEX_BTN_CLEAR = preload("res://assets/ui/touch/btn_clear.png")
const TEX_BTN_JUMP = preload("res://assets/ui/touch/btn_jump.png")
const TEX_BTN_SMASH = preload("res://assets/ui/touch/btn_smash.png")

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
# Button J (Drop / Bỏ nhỏ - Emerald Mint)
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
	queue_redraw()

func set_target_player(p: BadmintonPlayer) -> void:
	player = p

func _process(delta: float) -> void:
	if not visible:
		return
		
	var needs_redraw = false
	
	# Smooth spring return for knob when not dragging
	if not is_dragging_knob:
		var prev_knob = knob_pos
		knob_pos = knob_pos.lerp(knob_center, clamp(delta * 20.0, 0.0, 1.0))
		if knob_pos.distance_squared_to(prev_knob) > 0.05:
			needs_redraw = true
		if player and is_instance_valid(player):
			player.touch_move_axis = (knob_pos.x - knob_center.x) / max_drag_dist
			if abs(player.touch_move_axis) < 0.02:
				player.touch_move_axis = 0.0
	else:
		needs_redraw = true
	
	# Smooth scale springs & ripple decay for buttons
	var target_j_scale = 0.88 if btn_j_pressed else 1.0
	if abs(btn_j_scale - target_j_scale) > 0.005:
		btn_j_scale = lerp(btn_j_scale, target_j_scale, delta * 24.0)
		needs_redraw = true
		
	var target_k_scale = 0.88 if btn_k_pressed else 1.0
	if abs(btn_k_scale - target_k_scale) > 0.005:
		btn_k_scale = lerp(btn_k_scale, target_k_scale, delta * 24.0)
		needs_redraw = true
		
	var target_l_scale = 0.88 if btn_l_pressed else 1.0
	if abs(btn_l_scale - target_l_scale) > 0.005:
		btn_l_scale = lerp(btn_l_scale, target_l_scale, delta * 24.0)
		needs_redraw = true
	
	if btn_j_press_anim > 0.0:
		btn_j_press_anim = max(0.0, btn_j_press_anim - delta * 3.0)
		needs_redraw = true
	if btn_k_press_anim > 0.0:
		btn_k_press_anim = max(0.0, btn_k_press_anim - delta * 3.0)
		needs_redraw = true
	if btn_l_press_anim > 0.0:
		btn_l_press_anim = max(0.0, btn_l_press_anim - delta * 3.0)
		needs_redraw = true
	
	# L Button state: In air vs on ground
	var is_in_air = false
	if player and is_instance_valid(player):
		is_in_air = not player.is_on_ground()
	var target_air_prog = 1.0 if is_in_air else 0.0
	if abs(btn_l_air_prog - target_air_prog) > 0.01:
		btn_l_air_prog = lerp(btn_l_air_prog, target_air_prog, delta * 15.0)
		needs_redraw = true
	
	if needs_redraw:
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
			queue_redraw()
			return
			
		# 2. Button J (Drop)
		if pos.distance_to(btn_j_center) <= btn_j_radius + 20.0 and btn_j_touch_id == -1:
			btn_j_touch_id = touch_id
			btn_j_pressed = true
			btn_j_press_anim = 1.0
			shot_triggered.emit("drop")
			if player and is_instance_valid(player):
				player.touch_shot_pressed = "drop"
			queue_redraw()
			return
			
		# 3. Button K (Clear)
		if pos.distance_to(btn_k_center) <= btn_k_radius + 20.0 and btn_k_touch_id == -1:
			btn_k_touch_id = touch_id
			btn_k_pressed = true
			btn_k_press_anim = 1.0
			shot_triggered.emit("clear")
			if player and is_instance_valid(player):
				player.touch_shot_pressed = "clear"
			queue_redraw()
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
			queue_redraw()
			return
	else:
		# Touch up / release
		if touch_id == track_touch_id:
			track_touch_id = -1
			is_dragging_knob = false
			if player and is_instance_valid(player):
				player.touch_move_axis = 0.0
			queue_redraw()
		if touch_id == btn_j_touch_id:
			btn_j_touch_id = -1
			btn_j_pressed = false
			queue_redraw()
		if touch_id == btn_k_touch_id:
			btn_k_touch_id = -1
			btn_k_pressed = false
			queue_redraw()
		if touch_id == btn_l_touch_id:
			btn_l_touch_id = -1
			btn_l_pressed = false
			queue_redraw()

func _handle_drag(touch_id: int, pos: Vector2) -> void:
	if touch_id == track_touch_id:
		_update_knob_drag(pos.x)
		queue_redraw()

func _update_knob_drag(finger_x: float) -> void:
	var offset = clamp(finger_x - knob_center.x, -max_drag_dist, max_drag_dist)
	knob_pos.x = knob_center.x + offset
	knob_pos.y = knob_center.y
	if player and is_instance_valid(player):
		const DEADZONE: float = 10.0
		if offset > DEADZONE:
			player.touch_move_axis = 1.0 # 1 tốc độ di chuyển tới duy nhất, không tăng tuyến tính
		elif offset < -DEADZONE:
			player.touch_move_axis = -1.0 # 1 tốc độ di chuyển lui duy nhất, không tăng tuyến tính
		else:
			player.touch_move_axis = 0.0

func _draw() -> void:
	if not visible:
		return
		
	# 1. Left Touchpad Track (Pre-rendered texture)
	# Texture size is 260x108, inner capsule is 236x74 offset by (12, 10)
	var track_draw_rect = Rect2(track_rect.position.x - 12.0, track_rect.position.y - 10.0, 260.0, 108.0)
	draw_texture_rect(TEX_TRACK, track_draw_rect, false)
	
	# 2. Sliding Cyber-Puck Knob (Pre-rendered texture)
	# Texture size is 76x76, center is at (38, 38)
	var knob_draw_rect = Rect2(knob_pos.x - 38.0, knob_pos.y - 38.0, 76.0, 76.0)
	var knob_mod = Color(1.25, 1.25, 1.25, 1.0) if is_dragging_knob else Color.WHITE
	draw_texture_rect(TEX_KNOB, knob_draw_rect, false, knob_mod)
	
	# 3. Button J (Drop Shot - Emerald Mint)
	# Texture size is 104x124, button center is at (52, 46)
	var sz_j = Vector2(104.0, 124.0) * btn_j_scale
	var pos_j = btn_j_center - Vector2(52.0, 46.0) * btn_j_scale
	var mod_j = Color(1.3, 1.3, 1.3, 1.0) if btn_j_pressed else Color.WHITE
	draw_texture_rect(TEX_BTN_DROP, Rect2(pos_j, sz_j), false, mod_j)
	if btn_j_press_anim > 0.01:
		var wave_r = btn_j_radius * (1.0 + (1.0 - btn_j_press_anim) * 0.45)
		draw_arc(btn_j_center, wave_r, 0.0, TAU, 24, Color(0.1, 0.98, 0.65, btn_j_press_anim * 0.7), 2.0, true)
	
	# 4. Button K (Clear Shot - Solar Amber)
	var sz_k = Vector2(104.0, 124.0) * btn_k_scale
	var pos_k = btn_k_center - Vector2(52.0, 46.0) * btn_k_scale
	var mod_k = Color(1.3, 1.3, 1.3, 1.0) if btn_k_pressed else Color.WHITE
	draw_texture_rect(TEX_BTN_CLEAR, Rect2(pos_k, sz_k), false, mod_k)
	if btn_k_press_anim > 0.01:
		var wave_r = btn_k_radius * (1.0 + (1.0 - btn_k_press_anim) * 0.45)
		draw_arc(btn_k_center, wave_r, 0.0, TAU, 24, Color(1.0, 0.78, 0.15, btn_k_press_anim * 0.7), 2.0, true)
	
	# 5. Button L (Dynamic Jump & Smash - Crossfaded)
	# Texture size is 120x140, button center is at (60, 52)
	var sz_l = Vector2(120.0, 140.0) * btn_l_scale
	var pos_l = btn_l_center - Vector2(60.0, 52.0) * btn_l_scale
	var mod_l = Color(1.3, 1.3, 1.3, 1.0) if btn_l_pressed else Color.WHITE
	var p_air = clamp(btn_l_air_prog, 0.0, 1.0)
	if p_air < 0.98:
		draw_texture_rect(TEX_BTN_JUMP, Rect2(pos_l, sz_l), false, Color(mod_l.r, mod_l.g, mod_l.b, (1.0 - p_air)))
	if p_air > 0.02:
		draw_texture_rect(TEX_BTN_SMASH, Rect2(pos_l, sz_l), false, Color(mod_l.r, mod_l.g, mod_l.b, p_air))
	if btn_l_press_anim > 0.01:
		var wave_r = btn_l_radius * (1.0 + (1.0 - btn_l_press_anim) * 0.45)
		var cur_ring_col = Color(0.1, 0.85, 1.0).lerp(Color(1.0, 0.22, 0.2), p_air)
		draw_arc(btn_l_center, wave_r, 0.0, TAU, 24, Color(cur_ring_col.r, cur_ring_col.g, cur_ring_col.b, btn_l_press_anim * 0.75), 2.4, true)
