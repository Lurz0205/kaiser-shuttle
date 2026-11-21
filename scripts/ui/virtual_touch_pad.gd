class_name VirtualTouchPad
extends Control

# ==========================================================
# VIRTUAL MOBILE TOUCH CONTROLS - RESPONSIVE & HIGH IMPACT
# Tự động co giãn theo mọi kích thước màn hình (Responsive Anchored)
# Cụm phím to rõ, độ nhạy cao, bấm ăn 100% không trượt lệnh!
# ==========================================================

signal shot_triggered(shot_type: String)
signal jump_triggered()

var player: BadmintonPlayer = null

# Left Touchpad Track parameters (Thanh trượt ngang classic tối giản)
var track_rect: Rect2 = Rect2(35.0, 580.0, 280.0, 84.0)
var knob_center: Vector2 = Vector2(175.0, 622.0)
var knob_pos: Vector2 = Vector2(175.0, 622.0)
var knob_radius: float = 38.0
var max_drag_dist: float = 95.0
var track_touch_id: int = -1
var is_dragging_knob: bool = false

# Right Action Buttons parameters (Arch layout tự nhiên cho ngón tay cái)
# Button Slide (Cứu cầu / Trượt sàn - Classic Ice Blue)
var btn_slide_center: Vector2 = Vector2(850.0, 620.0)
var btn_slide_radius: float = 48.0
var btn_slide_touch_id: int = -1
var btn_slide_pressed: bool = false
var btn_slide_scale: float = 1.0

# Button J (Drop / Bỏ nhỏ - Classic Emerald)
var btn_j_center: Vector2 = Vector2(970.0, 620.0)
var btn_j_radius: float = 48.0
var btn_j_touch_id: int = -1
var btn_j_pressed: bool = false
var btn_j_scale: float = 1.0

# Button K (Clear / Phông sâu - Classic Amber)
var btn_k_center: Vector2 = Vector2(1070.0, 490.0)
var btn_k_radius: float = 48.0
var btn_k_touch_id: int = -1
var btn_k_pressed: bool = false
var btn_k_scale: float = 1.0

# Button L (Dynamic Jump & Smash - Classic Warm Gold / Crimson)
var btn_l_center: Vector2 = Vector2(1180.0, 610.0)
var btn_l_radius: float = 62.0
var btn_l_touch_id: int = -1
var btn_l_pressed: bool = false
var btn_l_scale: float = 1.0
var btn_l_air_prog: float = 0.0

var _last_viewport_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	var vp = get_viewport()
	if vp:
		vp.size_changed.connect(_update_layout)
	_update_layout()
	queue_redraw()

func set_target_player(p: BadmintonPlayer) -> void:
	player = p

func _update_layout() -> void:
	var vp = get_viewport()
	if not vp:
		return
	var vp_size = get_viewport_rect().size
	if vp_size.x <= 0 or vp_size.y <= 0:
		return
	_last_viewport_size = vp_size
	
	# Scale factor dựa trên chiều cao (chuẩn 720p)
	var s = clamp(vp_size.y / 720.0, 0.85, 1.25)
	
	# Safe area padding
	var pad_bottom = 32.0 * s
	var pad_side = 32.0 * s
	
	# 1. LEFT TRACK: Neo góc dưới bên trái
	var track_w = 280.0 * s
	var track_h = 84.0 * s
	track_rect = Rect2(pad_side, vp_size.y - pad_bottom - track_h, track_w, track_h)
	knob_center = track_rect.get_center()
	if not is_dragging_knob:
		knob_pos = knob_center
	knob_radius = 38.0 * s
	max_drag_dist = (track_w * 0.5) - (knob_radius * 0.6)
	
	# 2. RIGHT BUTTONS: Cụm phím neo góc dưới bên phải theo vòng cung ngón tay
	var r_std = 48.0 * s
	var r_big = 62.0 * s
	btn_slide_radius = r_std
	btn_j_radius = r_std
	btn_k_radius = r_std
	btn_l_radius = r_big
	
	var rx = vp_size.x - pad_side
	var ry = vp_size.y - pad_bottom
	
	# Button L (Jump & Smash) - Góc phải ngoài cùng, to nhất
	btn_l_center = Vector2(rx - r_big, ry - r_big)
	
	# Button K (Clear - Phông cầu) - Nằm phía trên lệch trái một chút
	btn_k_center = Vector2(rx - r_big - (88.0 * s), ry - r_big - (105.0 * s))
	
	# Button J (Drop - Bỏ nhỏ) - Nằm cạnh L về phía bên trái
	btn_j_center = Vector2(rx - r_big - (148.0 * s), ry - r_big)
	
	# Button Slide (Cứu cầu / Trượt sàn) - Nằm ngoài cùng bên trái của cụm phím
	btn_slide_center = Vector2(rx - r_big - (262.0 * s), ry - r_big)
	
	queue_redraw()

func _process(delta: float) -> void:
	if not visible:
		return
		
	var vp_size = get_viewport_rect().size
	if vp_size != _last_viewport_size:
		_update_layout()
		
	var needs_redraw = false
	
	# Smooth return for knob when not dragging
	if not is_dragging_knob:
		var prev_knob = knob_pos
		knob_pos = knob_pos.lerp(knob_center, clamp(delta * 24.0, 0.0, 1.0))
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
		btn_l_air_prog = lerp(btn_l_air_prog, target_air, delta * 18.0)
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
		# 1. Track Di Chuyển Trái/Phải (Hitbox hào phóng)
		var exp_rect = track_rect.grow(35.0)
		if exp_rect.has_point(pos) and track_touch_id == -1:
			track_touch_id = touch_id
			is_dragging_knob = true
			_update_knob_drag(pos.x)
			queue_redraw()
			return
			
		# Hitbox bán kính mở rộng 1.45x để đảm bảo chạm mép vẫn ăn 100%
		# 2. Button Slide (Trượt sàn / Cứu cầu)
		if pos.distance_to(btn_slide_center) <= btn_slide_radius * 1.45 and btn_slide_touch_id == -1:
			btn_slide_touch_id = touch_id
			btn_slide_pressed = true
			if player and is_instance_valid(player):
				player.start_slide(1.0 if player.court_side == "player" else -1.0)
			shot_triggered.emit("slide")
			queue_redraw()
			return
			
		# 3. Button Drop (Bỏ nhỏ - Phím J)
		if pos.distance_to(btn_j_center) <= btn_j_radius * 1.45 and btn_j_touch_id == -1:
			btn_j_touch_id = touch_id
			btn_j_pressed = true
			if player and is_instance_valid(player):
				player.touch_shot_pressed = "drop"
			shot_triggered.emit("drop")
			queue_redraw()
			return
			
		# 4. Button Clear (Phông sâu - Phím K)
		if pos.distance_to(btn_k_center) <= btn_k_radius * 1.45 and btn_k_touch_id == -1:
			btn_k_touch_id = touch_id
			btn_k_pressed = true
			if player and is_instance_valid(player):
				player.touch_shot_pressed = "clear"
			shot_triggered.emit("clear")
			queue_redraw()
			return
			
		# 5. Button Jump / Smash (Nhảy & Đập - Phím L)
		if pos.distance_to(btn_l_center) <= btn_l_radius * 1.45 and btn_l_touch_id == -1:
			btn_l_touch_id = touch_id
			btn_l_pressed = true
			if player and is_instance_valid(player):
				if not player.is_on_ground():
					player.touch_shot_pressed = "smash"
					shot_triggered.emit("smash")
				else:
					player.touch_jump_pressed = true
					jump_triggered.emit()
			else:
				jump_triggered.emit()
			queue_redraw()
			return
	else:
		# Nhả ngón tay
		if touch_id == track_touch_id or (touch_id == 999 and track_touch_id != -1):
			track_touch_id = -1
			is_dragging_knob = false
			if player and is_instance_valid(player):
				player.touch_move_axis = 0.0
			queue_redraw()
			
		if touch_id == btn_slide_touch_id or (touch_id == 999 and btn_slide_touch_id != -1):
			btn_slide_touch_id = -1
			btn_slide_pressed = false
			queue_redraw()
			
		if touch_id == btn_j_touch_id or (touch_id == 999 and btn_j_touch_id != -1):
			btn_j_touch_id = -1
			btn_j_pressed = false
			queue_redraw()
			
		if touch_id == btn_k_touch_id or (touch_id == 999 and btn_k_touch_id != -1):
			btn_k_touch_id = -1
			btn_k_pressed = false
			queue_redraw()
			
		if touch_id == btn_l_touch_id or (touch_id == 999 and btn_l_touch_id != -1):
			btn_l_touch_id = -1
			btn_l_pressed = false
			queue_redraw()

func _handle_drag(touch_id: int, pos: Vector2) -> void:
	if touch_id == track_touch_id or (touch_id == 999 and track_touch_id != -1):
		_update_knob_drag(pos.x)
		queue_redraw()

func _update_knob_drag(finger_x: float) -> void:
	var offset = clamp(finger_x - knob_center.x, -max_drag_dist, max_drag_dist)
	knob_pos.x = knob_center.x + offset
	knob_pos.y = knob_center.y
	if player and is_instance_valid(player):
		const DEADZONE: float = 8.0
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
	var tr_bg = Color(0.06, 0.09, 0.14, 0.55)
	var tr_border = Color(0.85, 0.90, 0.98, 0.35)
	
	# Thân thanh trượt
	draw_rect(Rect2(track_rect.position.x + track_r, track_rect.position.y, track_w - track_h, track_h), tr_bg)
	draw_circle(Vector2(track_rect.position.x + track_r, knob_center.y), track_r, tr_bg)
	draw_circle(Vector2(track_rect.end.x - track_r, knob_center.y), track_r, tr_bg)
	
	# Viền thanh trượt
	draw_line(Vector2(track_rect.position.x + track_r, track_rect.position.y), Vector2(track_rect.end.x - track_r, track_rect.position.y), tr_border, 1.8)
	draw_line(Vector2(track_rect.position.x + track_r, track_rect.end.y), Vector2(track_rect.end.x - track_r, track_rect.end.y), tr_border, 1.8)
	draw_arc(Vector2(track_rect.position.x + track_r, knob_center.y), track_r, PI * 0.5, PI * 1.5, 18, tr_border, 1.8)
	draw_arc(Vector2(track_rect.end.x - track_r, knob_center.y), track_r, -PI * 0.5, PI * 0.5, 18, tr_border, 1.8)
	
	# Vạch tâm định vị & mũi tên điều hướng
	draw_line(Vector2(knob_center.x, knob_center.y - 12), Vector2(knob_center.x, knob_center.y + 12), Color(0.8, 0.85, 0.9, 0.40), 1.8)
	_draw_small_arrow(Vector2(track_rect.position.x + track_r + 16, knob_center.y), -1)
	_draw_small_arrow(Vector2(track_rect.end.x - track_r - 16, knob_center.y), 1)

	# Con trượt Knob (Tròn tối giản thanh lịch, to rõ)
	var knob_r = knob_radius
	var knob_bg = Color(0.20, 0.28, 0.40, 0.90) if is_dragging_knob else Color(0.14, 0.18, 0.28, 0.80)
	var knob_border = Color(1.0, 0.85, 0.35, 0.95) if is_dragging_knob else Color(0.92, 0.95, 1.0, 0.70)
	draw_circle(knob_pos, knob_r, knob_bg)
	draw_arc(knob_pos, knob_r, 0, TAU, 28, knob_border, 2.4)
	draw_circle(knob_pos, knob_r * 0.38, knob_border)

	# ----------------------------------------------------
	# 2. RIGHT ACTION BUTTONS: Vòng tròn to rõ, màu sắc trực quan
	# ----------------------------------------------------
	# Button Slide: CỨU CẦU / TRƯỢT SÀN
	_draw_classic_button(btn_slide_center, btn_slide_radius * btn_slide_scale, "TRƯỢT", "SLIDE", Color(0.35, 0.85, 1.0), btn_slide_pressed)

	# Button Drop: BỎ NHỎ
	_draw_classic_button(btn_j_center, btn_j_radius * btn_j_scale, "BỎ NHỎ", "DROP", Color(0.30, 0.94, 0.65), btn_j_pressed)

	# Button Clear: PHÔNG CẦU
	_draw_classic_button(btn_k_center, btn_k_radius * btn_k_scale, "PHÔNG", "CLEAR", Color(1.0, 0.82, 0.25), btn_k_pressed)

	# Button Jump / Smash: NHẢY & ĐẬP CẦU
	var is_air = btn_l_air_prog > 0.5
	var l_col = Color(1.0, 0.82, 0.30).lerp(Color(1.0, 0.32, 0.30), btn_l_air_prog)
	var l_title = "ĐẬP CẦU" if is_air else "BẬT NHẢY"
	var l_sub = "SMASH" if is_air else "JUMP"
	_draw_classic_button(btn_l_center, btn_l_radius * btn_l_scale, l_title, l_sub, l_col, btn_l_pressed, true)

func _draw_small_arrow(pos: Vector2, dir: int) -> void:
	var pts = PackedVector2Array([
		Vector2(pos.x + dir * 8, pos.y - 7),
		Vector2(pos.x - dir * 5, pos.y),
		Vector2(pos.x + dir * 8, pos.y + 7)
	])
	draw_polyline(pts, Color(0.85, 0.9, 0.95, 0.5), 1.8)

func _draw_classic_button(center: Vector2, radius: float, title_vi: String, title_en: String, col: Color, is_pressed: bool, is_primary: bool = false) -> void:
	var bg_col = Color(0.08, 0.12, 0.18, 0.70)
	if is_pressed:
		bg_col = Color(col.r * 0.40, col.g * 0.40, col.b * 0.40, 0.90)
		
	# Vòng tròn nền
	draw_circle(center, radius, bg_col)
	
	# Viền chính
	var border_w = 2.8 if is_primary else 2.0
	var border_col = col if is_pressed else Color(col.r, col.g, col.b, 0.80)
	draw_arc(center, radius, 0, TAU, 32, border_col, border_w)
	
	# Vòng nhẫn trang trí bên trong
	draw_arc(center, radius * 0.82, 0, TAU, 28, Color(border_col.r, border_col.g, border_col.b, 0.35), 1.2)
	
	# Chữ hiển thị
	var font = ThemeDB.fallback_font
	if font:
		var vi_font_size = 14 if not is_primary else 16
		var en_font_size = 10 if not is_primary else 11
		
		var sz_vi = font.get_string_size(title_vi, HORIZONTAL_ALIGNMENT_CENTER, -1, vi_font_size)
		var sz_en = font.get_string_size(title_en, HORIZONTAL_ALIGNMENT_CENTER, -1, en_font_size)
		
		var pos_vi = Vector2(center.x - sz_vi.x * 0.5, center.y - 3)
		var pos_en = Vector2(center.x - sz_en.x * 0.5, center.y + 13)
		
		draw_string(font, pos_vi, title_vi, HORIZONTAL_ALIGNMENT_CENTER, -1, vi_font_size, Color.WHITE if is_pressed else Color(0.98, 0.98, 0.98, 0.98))
		draw_string(font, pos_en, title_en, HORIZONTAL_ALIGNMENT_CENTER, -1, en_font_size, Color(col.r, col.g, col.b, 0.90))
