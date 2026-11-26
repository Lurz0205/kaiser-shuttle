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

# Button Skill (Active Skill / Tuyệt Kỹ - Glowing Aura)
var btn_skill_center: Vector2 = Vector2(940.0, 480.0)
var btn_skill_radius: float = 52.0
var btn_skill_touch_id: int = -1
var btn_skill_pressed: bool = false
var btn_skill_scale: float = 1.0
var _btn_skill_down_time: float = 0.0

# Button L (Dynamic Jump & Smash - Classic Warm Gold / Crimson)
var btn_l_center: Vector2 = Vector2(1180.0, 610.0)
var btn_l_radius: float = 62.0
var btn_l_touch_id: int = -1
var btn_l_pressed: bool = false
var btn_l_scale: float = 1.0
var btn_l_air_prog: float = 0.0

var _last_viewport_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	z_index = 150
	mouse_filter = MOUSE_FILTER_IGNORE
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	custom_minimum_size = Vector2(1280, 720)
	size = Vector2(1280, 720)
	position = Vector2.ZERO
	_update_layout()
	queue_redraw()

func set_target_player(p: BadmintonPlayer) -> void:
	player = p

func _update_layout() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	custom_minimum_size = Vector2(1280, 720)
	size = Vector2(1280, 720)
	position = Vector2.ZERO
	
	# Safe area padding tren khung co dinh 1280x720
	# Dịch nút di chuyển qua bên phải và lên trên 1 chút theo yêu cầu
	var track_left: float = 110.0 # Dịch tiếp qua bên phải (từ 75 lên 110)
	var pad_bottom_track: float = 88.0 # Dịch tiếp lên trên (từ 65 lên 88)
	
	# 1. LEFT TRACK: Tăng kích cỡ to hơn nữa, dễ thao tác
	var track_w: float = 350.0 # Tăng từ 320 lên 350
	var track_h: float = 112.0 # Tăng từ 100 lên 112
	track_rect = Rect2(track_left, 720.0 - pad_bottom_track - track_h, track_w, track_h)
	knob_center = track_rect.get_center()
	if not is_dragging_knob:
		knob_pos = knob_center
	knob_radius = 54.0 # Tăng kích cỡ knob từ 48 lên 54
	max_drag_dist = (track_w * 0.5) - (knob_radius * 0.55)
	
	# 2. RIGHT BUTTONS: Tăng kích cỡ các nút bấm to rõ hơn
	btn_slide_radius = 56.0 # Tăng từ 48 lên 56
	btn_j_radius = 56.0     # Tăng từ 48 lên 56
	btn_k_radius = 56.0     # Tăng từ 48 lên 56
	btn_l_radius = 74.0     # Tăng từ 62 lên 74 (Nút Smash/Jump to đại, cực dễ bấm)
	btn_skill_radius = 52.0 # Nút Tuyệt Kỹ chủ động (Shift / Skill)
	
	var pad_bottom_btn: float = 48.0 # Nâng nhẹ cụm nút lên trên
	var rx: float = 1280.0 - 45.0
	var ry: float = 720.0 - pad_bottom_btn
	
	# Button L (Jump & Smash) - Goc phai ngoai cung
	btn_l_center = Vector2(rx - btn_l_radius, ry - btn_l_radius)
	
	# Button K (Clear - Phong cau) - Nam phia tren lech trai
	btn_k_center = Vector2(rx - btn_l_radius - 105.0, ry - btn_l_radius - 128.0)
	
	# Button J (Drop - Bo nho) - Nam canh L ve phia ben trai
	btn_j_center = Vector2(rx - btn_l_radius - 170.0, ry - btn_l_radius)
	
	# Button Slide (Cuu cau / Truot san) - Nam ngoai cung ben trai
	btn_slide_center = Vector2(rx - btn_l_radius - 300.0, ry - btn_l_radius)
	
	# Button Skill (Tuyet ky chu dong) - Vong cung phia tren lech trai doi xung voi K
	btn_skill_center = Vector2(rx - btn_l_radius - 235.0, ry - btn_l_radius - 128.0)
	
	queue_redraw()

# Timers tự động giải phóng trạng thái nhấn để tránh kẹt nút trên mobile browser
var _btn_slide_down_time: float = 0.0
var _btn_j_down_time: float = 0.0
var _btn_k_down_time: float = 0.0
var _btn_l_down_time: float = 0.0

func _process(delta: float) -> void:
	if not visible:
		return
		
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
	
	# Auto-release bảo vệ chống kẹt nút (chỉ reset trạng thái visual pressed sau 0.14s, giữ touch_id đến khi nhả ngón tay để không spam lại trong _handle_drag)
	if btn_slide_pressed:
		_btn_slide_down_time += delta
		if _btn_slide_down_time > 0.14:
			btn_slide_pressed = false
			needs_redraw = true
			
	if btn_j_pressed:
		_btn_j_down_time += delta
		if _btn_j_down_time > 0.14:
			btn_j_pressed = false
			needs_redraw = true
			
	if btn_k_pressed:
		_btn_k_down_time += delta
		if _btn_k_down_time > 0.14:
			btn_k_pressed = false
			needs_redraw = true
			
	if btn_l_pressed:
		_btn_l_down_time += delta
		if _btn_l_down_time > 0.14:
			btn_l_pressed = false
			needs_redraw = true
			
	if btn_skill_pressed:
		_btn_skill_down_time += delta
		if _btn_skill_down_time > 0.14:
			btn_skill_pressed = false
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
		
	var target_skill = 0.88 if btn_skill_pressed else 1.0
	if abs(btn_skill_scale - target_skill) > 0.005:
		btn_skill_scale = lerp(btn_skill_scale, target_skill, delta * 25.0)
		needs_redraw = true
		
	if player and is_instance_valid(player) and player.stats and player.stats.can_use_special():
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

var _has_touch_input: bool = false

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	if event is InputEventScreenTouch:
		_has_touch_input = true
		_handle_touch(event.index, event.pressed, event.position)
	elif event is InputEventScreenDrag:
		_has_touch_input = true
		_handle_drag(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Chặn triệt để sự kiện chuột giả lập từ cảm ứng trên Mobile/Web (gây spam 2 lần & khóa di chuyển)
		if _has_touch_input or event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		_handle_touch(999, event.pressed, event.position)
	elif event is InputEventMouseMotion and is_dragging_knob and track_touch_id == 999:
		if _has_touch_input or event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		_handle_drag(999, event.position)

func _trigger_btn_slide(touch_id: int) -> void:
	btn_slide_touch_id = touch_id
	btn_slide_pressed = true
	_btn_slide_down_time = 0.0
	if player and is_instance_valid(player):
		player.start_slide(1.0 if player.court_side == "player" else -1.0)
	shot_triggered.emit("slide")
	queue_redraw()

func _trigger_btn_j(touch_id: int) -> void:
	btn_j_touch_id = touch_id
	btn_j_pressed = true
	_btn_j_down_time = 0.0
	if player and is_instance_valid(player):
		player.handle_touch_action("drop")
	shot_triggered.emit("drop")
	queue_redraw()

func _trigger_btn_k(touch_id: int) -> void:
	btn_k_touch_id = touch_id
	btn_k_pressed = true
	_btn_k_down_time = 0.0
	if player and is_instance_valid(player):
		player.handle_touch_action("clear")
	shot_triggered.emit("clear")
	queue_redraw()

func _trigger_btn_l(touch_id: int) -> void:
	btn_l_touch_id = touch_id
	btn_l_pressed = true
	_btn_l_down_time = 0.0
	if player and is_instance_valid(player):
		if not player.is_on_ground():
			player.handle_touch_action("smash")
			shot_triggered.emit("smash")
		else:
			player.handle_touch_jump()
			jump_triggered.emit()
	else:
		jump_triggered.emit()
	queue_redraw()

func _trigger_btn_skill(touch_id: int) -> void:
	btn_skill_touch_id = touch_id
	btn_skill_pressed = true
	_btn_skill_down_time = 0.0
	if player and is_instance_valid(player):
		player.handle_touch_action("skill")
	queue_redraw()

func _handle_touch(touch_id: int, is_down: bool, pos: Vector2) -> void:
	if is_down:
		# 1. Track Di Chuyển Trái/Phải
		var exp_rect = track_rect.grow(40.0)
		if exp_rect.has_point(pos):
			track_touch_id = touch_id
			is_dragging_knob = true
			_update_knob_drag(pos.x)
			queue_redraw()
			return
			
		# Không chặn bởi `touch_id == -1` để đảm bảo nhấp liên tục / đa ngón luôn ăn 100%
		# 2. Button Slide (Trượt sàn / Cứu cầu)
		if pos.distance_to(btn_slide_center) <= btn_slide_radius * 1.45:
			_trigger_btn_slide(touch_id)
			return
			
		# 3. Button Drop (Bỏ nhỏ - Phím J)
		if pos.distance_to(btn_j_center) <= btn_j_radius * 1.45:
			_trigger_btn_j(touch_id)
			return
			
		# 4. Button Clear (Phông sâu - Phím K)
		if pos.distance_to(btn_k_center) <= btn_k_radius * 1.45:
			_trigger_btn_k(touch_id)
			return
			
		# 5. Button Skill (Tuyệt kỹ - Phím Shift / Nộ)
		if pos.distance_to(btn_skill_center) <= btn_skill_radius * 1.45:
			_trigger_btn_skill(touch_id)
			return
			
		# 6. Button Jump / Smash (Nhảy & Đập - Phím L)
		if pos.distance_to(btn_l_center) <= btn_l_radius * 1.45:
			_trigger_btn_l(touch_id)
			return
	else:
		# Nhả ngón tay (chỉ giải phóng đúng touch_id đã giữ nút đó, không cắt ngang ngón di chuyển!)
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
			
		if touch_id == btn_skill_touch_id:
			btn_skill_touch_id = -1
			btn_skill_pressed = false
			queue_redraw()
			
		if touch_id == btn_l_touch_id:
			btn_l_touch_id = -1
			btn_l_pressed = false
			queue_redraw()

func _handle_drag(touch_id: int, pos: Vector2) -> void:
	if touch_id == track_touch_id:
		_update_knob_drag(pos.x)
		queue_redraw()
	else:
		# Hỗ trợ trượt ngón tay vào nút hành động (chỉ kích hoạt khi touch_id chưa giữ nút đó để chống spam khi giữ tay)
		if btn_slide_touch_id == -1 and not btn_slide_pressed and pos.distance_to(btn_slide_center) <= btn_slide_radius * 1.35:
			_trigger_btn_slide(touch_id)
		elif btn_j_touch_id == -1 and not btn_j_pressed and pos.distance_to(btn_j_center) <= btn_j_radius * 1.35:
			_trigger_btn_j(touch_id)
		elif btn_k_touch_id == -1 and not btn_k_pressed and pos.distance_to(btn_k_center) <= btn_k_radius * 1.35:
			_trigger_btn_k(touch_id)
		elif btn_skill_touch_id == -1 and not btn_skill_pressed and pos.distance_to(btn_skill_center) <= btn_skill_radius * 1.35:
			_trigger_btn_skill(touch_id)
		elif btn_l_touch_id == -1 and not btn_l_pressed and pos.distance_to(btn_l_center) <= btn_l_radius * 1.35:
			_trigger_btn_l(touch_id)

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

	# Button Skill: TUYỆT KỸ CHỦ ĐỘNG (SHIFT / SPECIAL)
	var can_spec = player and is_instance_valid(player) and player.stats and player.stats.can_use_special()
	var skill_active = player and is_instance_valid(player) and (player.is_fire_realm_active or player.is_ice_domain_active)
	var char_id = player.stats.character_id if (player and is_instance_valid(player) and player.stats) else ""
	var skill_col = Color(1.0, 0.40, 0.15) if char_id == "gitae" else (Color(0.35, 0.85, 1.0) if char_id == "sara" else Color(1.0, 0.85, 0.25))
	if can_spec or skill_active:
		var pulse = 0.75 + 0.25 * sin(Time.get_ticks_msec() / 120.0)
		draw_circle(btn_skill_center, (btn_skill_radius + 6.0) * btn_skill_scale, Color(skill_col.r, skill_col.g, skill_col.b, 0.35 * pulse))
	var skill_title = "TUYỆT KỸ"
	var skill_sub = "SKILL"
	if char_id == "gitae":
		skill_sub = "HỎA NGỤC" if skill_active else "HỎA DIỄM"
	elif char_id == "sara":
		skill_sub = "BĂNG GIÁ" if skill_active else "BĂNG ĐOÀN"
	_draw_classic_button(btn_skill_center, btn_skill_radius * btn_skill_scale, skill_title, skill_sub, skill_col if (can_spec or skill_active) else Color(0.60, 0.65, 0.75), btn_skill_pressed)

	# Button Jump / Smash: NHẢY & ĐẬP CẦU
	var is_air = btn_l_air_prog > 0.5
	var l_col = Color(1.0, 0.82, 0.30).lerp(Color(1.0, 0.32, 0.30), btn_l_air_prog)
	var is_sara_ice = player and is_instance_valid(player) and player.is_ice_domain_active and char_id == "sara"
	var l_title = "ĐẬP CẦU" if is_air else ("DỊCH CHUYỂN" if is_sara_ice else "BẬT NHẢY")
	var l_sub = "SMASH" if is_air else ("TELEPORT" if is_sara_ice else "JUMP")
	if is_sara_ice and not is_air:
		l_col = Color(0.35, 0.85, 1.0)
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
		var vi_font_size = 15 if not is_primary else 18
		var en_font_size = 11 if not is_primary else 13
		
		var sz_vi = font.get_string_size(title_vi, HORIZONTAL_ALIGNMENT_CENTER, -1, vi_font_size)
		var sz_en = font.get_string_size(title_en, HORIZONTAL_ALIGNMENT_CENTER, -1, en_font_size)
		
		var pos_vi = Vector2(center.x - sz_vi.x * 0.5, center.y - 3)
		var pos_en = Vector2(center.x - sz_en.x * 0.5, center.y + 13)
		
		draw_string(font, pos_vi, title_vi, HORIZONTAL_ALIGNMENT_CENTER, -1, vi_font_size, Color.WHITE if is_pressed else Color(0.98, 0.98, 0.98, 0.98))
		draw_string(font, pos_en, title_en, HORIZONTAL_ALIGNMENT_CENTER, -1, en_font_size, Color(col.r, col.g, col.b, 0.90))
