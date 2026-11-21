class_name VirtualTouchPad
extends Control

# ==========================================================
# VIRTUAL MOBILE TOUCH CONTROLS - CLASSIC MINIMAL ATHLETIC
# Tối giản, thanh lịch, tinh tế - Tự vẽ vector mượt mà, 0% máy móc
# 60-120 FPS siêu mượt trên Web & Mobile Browser
# ==========================================================

signal shot_triggered(shot_type: String)
signal jump_triggered()

var player: BadmintonPlayer = null

# Left Touchpad Track parameters (Thanh trượt ngang classic tối giản)
var track_rect: Rect2 = Rect2(98.0, 560.0, 240.0, 72.0)
var knob_center: Vector2 = Vector2(218.0, 596.0)
var knob_pos: Vector2 = Vector2(218.0, 596.0)
var knob_radius: float = 30.0
var max_drag_dist: float = 84.0
var track_touch_id: int = -1
var is_dragging_knob: bool = false

# Right Action Buttons parameters (Arch layout tự nhiên cho ngón tay cái)
# Button Slide (Cứu cầu / Trượt sàn - Classic Ice Blue)
var btn_slide_center: Vector2 = Vector2(850.0, 610.0)
var btn_slide_radius: float = 42.0
var btn_slide_touch_id: int = -1
var btn_slide_pressed: bool = false
var btn_slide_scale: float = 1.0

# Button J (Drop / Bỏ nhỏ - Classic Emerald)
var btn_j_center: Vector2 = Vector2(965.0, 610.0)
var btn_j_radius: float = 42.0
var btn_j_touch_id: int = -1
var btn_j_pressed: bool = false
var btn_j_scale: float = 1.0

# Button K (Clear / Phông sâu - Classic Amber)
var btn_k_center: Vector2 = Vector2(1075.0, 500.0)
var btn_k_radius: float = 42.0
var btn_k_touch_id: int = -1
var btn_k_pressed: bool = false
var btn_k_scale: float = 1.0

# Button L (Dynamic Jump & Smash - Classic Warm Gold / Crimson)
var btn_l_center: Vector2 = Vector2(1185.0, 595.0)
var btn_l_radius: float = 52.0
var btn_l_touch_id: int = -1
var btn_l_pressed: bool = false
var btn_l_scale: float = 1.0
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
	
	# Smooth return for knob when not dragging
	if not is_dragging_knob:
		var prev_knob = knob_pos
		knob_pos = knob_pos.lerp(knob_center, clamp(delta * 22.0, 0.0, 1.0))
		if knob_pos.distance_squared_to(prev_knob) > 0.05:
			needs_redraw = true
		if player and is_instance_valid(player):
			player.touch_move_axis = (knob_pos.x - knob_center.x) / max_drag_dist
			if abs(player.touch_move_axis) < 0.02:
				player.touch_move_axis = 0.0
	else:
		needs_redraw = true
	
	# Smooth button scale transitions
	var target_slide = 0.88 if btn_slide_pressed else 1.0
	if abs(btn_slide_scale - target_slide) > 0.005:
		btn_slide_scale = lerp(btn_slide_scale, target_slide, delta * 25.0)
		needs_redraw = true
		
	var target_j = 0.88 if btn_j_pressed else 1.0
	if abs(btn_j_scale - target_j) > 0.005:
		btn_j_scale = lerp(btn_j_scale, target_j, delta * 25.0)
		needs_redraw = true
		
	var target_k = 0.88 if btn_k_pressed else 1.0
	if abs(btn_k_scale - target_k) > 0.005:
		btn_k_scale = lerp(btn_k_scale, target_k, delta * 25.0)
		needs_redraw = true
		
	var target_l = 0.88 if btn_l_pressed else 1.0
	if abs(btn_l_scale - target_l) > 0.005:
		btn_l_scale = lerp(btn_l_scale, target_l, delta * 25.0)
		needs_redraw = true
	
	# Jump to Smash transition
	var is_in_air = false
	if player and is_instance_valid(player):
		is_in_air = not player.is_on_ground()
	var target_air = 1.0 if is_in_air else 0.0
	if abs(btn_l_air_prog - target_air) > 0.01:
		btn_l_air_prog = lerp(btn_l_air_prog, target_air, delta * 16.0)
		needs_redraw = true
		
	if needs_redraw:
		queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	if event is InputEventScreenTouch:
		_handle_touch(event.index, event.pressed, event.position)
	elif event is InputEventScreenDrag:
		_handle_drag(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if track_touch_id != 0 and btn_slide_touch_id != 0 and btn_j_touch_id != 0 and btn_k_touch_id != 0 and btn_l_touch_id != 0:
			_handle_touch(999, event.pressed, event.position)
	elif event is InputEventMouseMotion and is_dragging_knob and track_touch_id == 999:
		_handle_drag(999, event.position)

func _handle_touch(touch_id: int, is_down: bool, pos: Vector2) -> void:
	if is_down:
		# Track
		var exp_rect = track_rect.grow(26.0)
		if exp_rect.has_point(pos) and track_touch_id == -1:
			track_touch_id = touch_id
			is_dragging_knob = true
			_update_knob_drag(pos.x)
			queue_redraw()
			return
			
		# Slide Button
		if pos.distance_to(btn_slide_center) <= btn_slide_radius * 1.35 and btn_slide_touch_id == -1:
			btn_slide_touch_id = touch_id
			btn_slide_pressed = true
			shot_triggered.emit("slide")
			queue_redraw()
			return
			
		# Drop Button (J)
		if pos.distance_to(btn_j_center) <= btn_j_radius * 1.35 and btn_j_touch_id == -1:
			btn_j_touch_id = touch_id
			btn_j_pressed = true
			shot_triggered.emit("drop")
			queue_redraw()
			return
			
		# Clear Button (K)
		if pos.distance_to(btn_k_center) <= btn_k_radius * 1.35 and btn_k_touch_id == -1:
			btn_k_touch_id = touch_id
			btn_k_pressed = true
			shot_triggered.emit("clear")
			queue_redraw()
			return
			
		# Jump / Smash Button (L)
		if pos.distance_to(btn_l_center) <= btn_l_radius * 1.35 and btn_l_touch_id == -1:
			btn_l_touch_id = touch_id
			btn_l_pressed = true
			if player and not player.is_on_ground():
				shot_triggered.emit("smash")
			else:
				jump_triggered.emit()
			queue_redraw()
			return
	else:
		if touch_id == track_touch_id:
			track_touch_id = -1
			is_dragging_knob = false
			if player and is_instance_valid(player):
				player.touch_move_axis = 0.0
			queue_redraw()
			
		if touch_id == btn_slide_touch_id:
			btn_slide_touch_id = -1
			btn_slide_pressed = false
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
			player.touch_move_axis = 1.0
		elif offset < -DEADZONE:
			player.touch_move_axis = -1.0
		else:
			player.touch_move_axis = 0.0

func _draw() -> void:
	if not visible:
		return
		
	# ----------------------------------------------------
	# 1. LEFT TRACK: Thanh trượt ngang classic tối giản
	# ----------------------------------------------------
	var track_h = track_rect.size.y
	var track_w = track_rect.size.x
	var track_r = track_h * 0.5
	
	# Background capsule mờ dịu
	var tr_bg = Color(0.06, 0.09, 0.14, 0.50)
	var tr_border = Color(0.85, 0.90, 0.98, 0.25)
	
	# Vẽ thân thanh trượt
	draw_rect(Rect2(track_rect.position.x + track_r, track_rect.position.y, track_w - track_h, track_h), tr_bg)
	draw_circle(Vector2(track_rect.position.x + track_r, knob_center.y), track_r, tr_bg)
	draw_circle(Vector2(track_rect.end.x - track_r, knob_center.y), track_r, tr_bg)
	
	# Viền thanh trượt mảnh mai
	draw_line(Vector2(track_rect.position.x + track_r, track_rect.position.y), Vector2(track_rect.end.x - track_r, track_rect.position.y), tr_border, 1.5)
	draw_line(Vector2(track_rect.position.x + track_r, track_rect.end.y), Vector2(track_rect.end.x - track_r, track_rect.end.y), tr_border, 1.5)
	draw_arc(Vector2(track_rect.position.x + track_r, knob_center.y), track_r, PI * 0.5, PI * 1.5, 16, tr_border, 1.5)
	draw_arc(Vector2(track_rect.end.x - track_r, knob_center.y), track_r, -PI * 0.5, PI * 0.5, 16, tr_border, 1.5)
	
	# Vạch tâm định vị & mũi tên điều hướng classic
	draw_line(Vector2(knob_center.x, knob_center.y - 10), Vector2(knob_center.x, knob_center.y + 10), Color(0.8, 0.85, 0.9, 0.35), 1.5)
	# Mũi tên trái / phải nhỏ
	_draw_small_arrow(Vector2(track_rect.position.x + track_r + 14, knob_center.y), -1)
	_draw_small_arrow(Vector2(track_rect.end.x - track_r - 14, knob_center.y), 1)

	# Con trượt Knob (Tròn tối giản thanh lịch)
	var knob_r = knob_radius
	var knob_bg = Color(0.18, 0.24, 0.34, 0.85) if is_dragging_knob else Color(0.12, 0.16, 0.24, 0.75)
	var knob_border = Color(1.0, 0.85, 0.35, 0.90) if is_dragging_knob else Color(0.90, 0.94, 1.0, 0.60)
	draw_circle(knob_pos, knob_r, knob_bg)
	draw_arc(knob_pos, knob_r, 0, TAU, 24, knob_border, 2.0)
	draw_circle(knob_pos, knob_r * 0.35, knob_border)

	# ----------------------------------------------------
	# 2. RIGHT ACTION BUTTONS: Vòng tròn classic thanh lịch
	# ----------------------------------------------------
	# Button Slide: CỨU CẦU
	_draw_classic_button(btn_slide_center, btn_slide_radius * btn_slide_scale, "CỨU CẦU", "SLIDE", Color(0.35, 0.85, 1.0), btn_slide_pressed)

	# Button Drop: BỎ NHỎ
	_draw_classic_button(btn_j_center, btn_j_radius * btn_j_scale, "BỎ NHỎ", "DROP", Color(0.30, 0.92, 0.65), btn_j_pressed)

	# Button Clear: PHÔNG CẦU
	_draw_classic_button(btn_k_center, btn_k_radius * btn_k_scale, "PHÔNG", "CLEAR", Color(1.0, 0.80, 0.25), btn_k_pressed)

	# Button Jump / Smash: NHẢY & ĐẬP
	var is_air = btn_l_air_prog > 0.5
	var l_col = Color(1.0, 0.82, 0.30).lerp(Color(1.0, 0.35, 0.30), btn_l_air_prog)
	var l_title = "ĐẬP CẦU" if is_air else "BẬT NHẢY"
	var l_sub = "SMASH" if is_air else "JUMP"
	_draw_classic_button(btn_l_center, btn_l_radius * btn_l_scale, l_title, l_sub, l_col, btn_l_pressed, true)

func _draw_small_arrow(pos: Vector2, dir: int) -> void:
	var pts = PackedVector2Array([
		Vector2(pos.x + dir * 6, pos.y - 5),
		Vector2(pos.x - dir * 4, pos.y),
		Vector2(pos.x + dir * 6, pos.y + 5)
	])
	draw_polyline(pts, Color(0.85, 0.9, 0.95, 0.4), 1.5)

func _draw_classic_button(center: Vector2, radius: float, title_vi: String, title_en: String, col: Color, is_pressed: bool, is_primary: bool = false) -> void:
	var bg_col = Color(0.08, 0.11, 0.16, 0.65)
	if is_pressed:
		bg_col = Color(col.r * 0.35, col.g * 0.35, col.b * 0.35, 0.85)
		
	# Vòng tròn nền
	draw_circle(center, radius, bg_col)
	
	# Viền thanh thoát
	var border_w = 2.4 if is_primary else 1.8
	var border_col = col if is_pressed else Color(col.r, col.g, col.b, 0.70)
	draw_arc(center, radius, 0, TAU, 32, border_col, border_w)
	
	# Vòng nhẫn trang trí bên trong
	draw_arc(center, radius * 0.82, 0, TAU, 24, Color(border_col.r, border_col.g, border_col.b, 0.30), 1.0)
	
	# Chữ hiển thị
	var font = ThemeDB.fallback_font
	if font:
		var vi_font_size = 12 if not is_primary else 13
		var en_font_size = 9 if not is_primary else 10
		
		var sz_vi = font.get_string_size(title_vi, HORIZONTAL_ALIGNMENT_CENTER, -1, vi_font_size)
		var sz_en = font.get_string_size(title_en, HORIZONTAL_ALIGNMENT_CENTER, -1, en_font_size)
		
		var pos_vi = Vector2(center.x - sz_vi.x * 0.5, center.y - 2)
		var pos_en = Vector2(center.x - sz_en.x * 0.5, center.y + 12)
		
		draw_string(font, pos_vi, title_vi, HORIZONTAL_ALIGNMENT_CENTER, -1, vi_font_size, Color.WHITE if is_pressed else Color(0.96, 0.96, 0.96, 0.95))
		draw_string(font, pos_en, title_en, HORIZONTAL_ALIGNMENT_CENTER, -1, en_font_size, Color(col.r, col.g, col.b, 0.85))
