extends Area2D
class_name Shuttlecock

signal landed(floor_pos_2d: Vector2)
signal hit_net()

# ==========================================================
# SHUTTLECOCK 2D PHYSICS (ANIME HIGH CLEAR & FAST BURST DECAY)
# ==========================================================

@export var tuning: GameTuning

var is_active: bool = false
var is_smash: bool = false
var is_boom_smash: bool = false
var is_tsubame_gaeshi: bool = false
var is_mirage_counter: bool = false
var is_jump_drop: bool = false
var is_serve: bool = false
var is_net_fault: bool = false
var is_weak_return: bool = false
var tension_speed_mult: float = 1.0
var tension_level: int = 0
var last_hitter: String = "" # "player" or "ai"

# Super slow-mo suspension (Vợt sắp chạm cầu trong 1s slow-mo, hết slow-mo mới đập)
var is_suspended_in_smash_slowmo: bool = false
var suspended_smash_pos: Vector2 = Vector2.ZERO

var current_shot_type: String = "clear"

# Trajectory parameters
var launch_from: Vector2 = Vector2(390.0, 515.0)
var launch_target: Vector2 = Vector2(740.0, 550.0)
var flight_duration: float = 1.0
var flight_time_elapsed: float = 0.0

var h_start: float = 35.0
var h_apex: float = 370.0

# Drop shot parameters (Thuần 1 vòng cung lõm tự nhiên, không cong vẹo hàm bậc 3)
var drop_u_net: float = 0.5
var drop_h_net: float = 142.0
var drop_A: float = 0.0
var drop_B: float = 0.0
var drop_alpha: float = 2.0
var is_net_drop: bool = false
var dist_x: float = 100.0

# Smash trajectory parameters (Phẳng, góc thoai thoải, qua lưới 100% kể cả đứng dưới đất)
var smash_u_net: float = 0.5
var smash_h_net: float = 125.0
var is_ground_smash: bool = false
var is_kill_smash: bool = false

# Dynamic 2D Velocity (for HUD speed display and angle rotation)
var velocity: Vector2 = Vector2.ZERO

# Landing prediction
var predicted_landing_2d: Vector2 = Vector2.ZERO
var predicted_flight_time: float = 0.0

# Visual Trail & Ground Shadow
var trail_points: Array[Vector2] = []
const MAX_TRAIL: int = 26

var is_perfect: bool = false

@onready var trail: Line2D = $Trail2D
@onready var lightning_trail: Node2D = $LightningTrail
@onready var leaf_trail: Node2D = $LeafTrail
@onready var shadow_node: Node2D = $ShadowNode

# Fuji Tsubame Gaeshi - Foliage Leaves System
var fuji_h_control: float = 160.0
var fuji_leaves: Array = []
var fuji_leaf_spawn_timer: float = 0.0

# Landing indicator node drawn on ground
var landing_indicator: Node2D = null

# Backward compatibility getter for 3D state if needed
var pos_3d: Vector3:
	get:
		var floor_y = tuning.floor_y if tuning else 550.0
		return Vector3(global_position.x, max(0.0, floor_y - global_position.y), 0.0)
	set(val):
		var floor_y = tuning.floor_y if tuning else 550.0
		global_position = Vector2(val.x, floor_y - val.y)


func _ready() -> void:
	if not tuning:
		tuning = load("res://resources/GameTuning.tres")
	
	if trail:
		trail.top_level = true
		trail.clear_points()
		var curve = Curve.new()
		curve.add_point(Vector2(0.0, 1.0))
		curve.add_point(Vector2(1.0, 0.05))
		trail.width_curve = curve
		trail.width = 9.0
		trail.antialiased = true
		trail.default_color = Color(1.0, 1.0, 1.0, 0.85)
	
	if lightning_trail:
		lightning_trail.top_level = true
		lightning_trail.draw.connect(_on_lightning_trail_draw)
	
	if not leaf_trail:
		if has_node("LeafTrail"):
			leaf_trail = $LeafTrail
		else:
			leaf_trail = Node2D.new()
			leaf_trail.top_level = true
			add_child(leaf_trail)
	if leaf_trail and not leaf_trail.draw.is_connected(_on_fuji_leaf_draw):
		leaf_trail.top_level = true
		leaf_trail.draw.connect(_on_fuji_leaf_draw)
	
	_create_landing_indicator()
	queue_redraw()


func _create_landing_indicator() -> void:
	landing_indicator = Node2D.new()
	landing_indicator.top_level = true
	landing_indicator.visible = false
	add_child(landing_indicator)
	# Đã xóa vị trí hiển thị cầu rơi để người chơi tự quan sát và phán đoán In / Out


# ==========================================================
# TỐC ĐỘ CẦU: ĐOẠN ĐẦU NHANH CỰC NGẮN (7%) -> HÃM GẮT VỀ SAU
# ==========================================================
const P_FAST: float = 0.07 # 7% thời gian đầu xé gió, 93% sau giảm tốc rõ rệt

static func get_speed_factor(p: float) -> float:
	var cp = clamp(p, 0.0, 1.0)
	if cp <= P_FAST:
		# 7% đầu: Tốc độ cao bùng nổ (1.0 -> 0.80)
		return 1.0 - 0.20 * pow(cp / P_FAST, 2.0)
	else:
		# 93% sau: Hãm phanh gắt do sức cản không khí lông vũ (0.80 -> 0.20)
		return 0.20 + 0.60 * exp(-4.8 * (cp - P_FAST))


static func get_speed_integral(p: float) -> float:
	var cp = clamp(p, 0.0, 1.0)
	if cp <= P_FAST:
		return cp - (0.20 / (3.0 * (P_FAST * P_FAST))) * pow(cp, 3.0)
	else:
		var I_fast = P_FAST - (0.20 * P_FAST) / 3.0
		return I_fast + 0.20 * (cp - P_FAST) + (0.60 / 4.8) * (1.0 - exp(-4.8 * (cp - P_FAST)))


static func get_total_integral() -> float:
	var I_fast = P_FAST - (0.20 * P_FAST) / 3.0
	var rem = 1.0 - P_FAST
	return I_fast + 0.20 * rem + (0.60 / 4.8) * (1.0 - exp(-4.8 * rem))


# ==========================================================
# LAUNCH TO TARGET (HOÀN TOÀN ĐỐI XỨNG PLAYER VÀ AI)
# ==========================================================

func launch_to_target_2d(from_pt: Vector2, target_pt: Vector2, shot_type: String, error_offset_x: float = 0.0, p_is_perfect: bool = false, p_is_jump_smash: bool = false, p_tension_mult: float = 1.0, p_tension_level: int = 0) -> void:
	var t_res = tuning if tuning else GameTuning.new()
	var floor_y = t_res.floor_y
	
	is_suspended_in_smash_slowmo = false
	current_shot_type = shot_type
	is_kill_smash = (shot_type == "kill_smash")
	is_smash = (shot_type == "smash" or shot_type == "boom_smash" or shot_type == "kill_smash")
	is_boom_smash = (shot_type == "boom_smash")
	is_tsubame_gaeshi = (shot_type == "tsubame_gaeshi")
	is_mirage_counter = (shot_type == "mirage_counter")
	is_weak_return = (shot_type == "weak_return")
	tension_speed_mult = max(1.0, p_tension_mult)
	tension_level = p_tension_level
	# Chỉ kích hoạt sấm sét cho cú nhảy đập Perfect (không áp dụng cho clear/drop)
	is_perfect = (p_is_perfect and (p_is_jump_smash or is_kill_smash))
	is_net_fault = false
	
	launch_from = from_pt
	global_position = from_pt
	velocity = Vector2.ZERO
	flight_time_elapsed = 0.0
	h_start = max(5.0, floor_y - from_pt.y)
	is_jump_drop = (shot_type == "drop" and h_start > t_res.net_height + 25.0)
	
	var final_target_x = target_pt.x + error_offset_x
	var dx = final_target_x - from_pt.x
	dist_x = max(abs(dx), 15.0)
	var facing = 1.0 if dx >= 0 else -1.0
	
	if is_smash:
		var v_base = t_res.boom_smash_speed if is_boom_smash else t_res.smash_speed
		if is_kill_smash:
			# ĐẬP DỨT ĐIỂM CẦU NON CỰC NHANH (0.18s - 0.25s):
			flight_duration = clamp(dist_x / (v_base * 1.05), 0.18, 0.25)
		else:
			# ĐẬP CẦU TỐC ĐỘ CAO XÉ GIÓ (0.30s - 0.46s), nhanh gấp 4 lần phông cầu
			flight_duration = clamp(dist_x / (v_base * 0.72), 0.30, 0.46)
		h_apex = h_start
		
		# Quỹ đạo cắm thẳng xuống sàn phía đối phương (không bẻ cong nâng khống độ cao)
		var dist_net = abs(t_res.net_x - from_pt.x)
		smash_u_net = clamp(dist_net / max(dist_x, 1.0), 0.05, 0.95)
		is_ground_smash = false
		smash_h_net = h_start * (1.0 - smash_u_net)
				
	elif shot_type == "drop":
		var dist_net = clamp(abs(t_res.net_x - from_pt.x), 15.0, dist_x - 20.0)
		drop_u_net = clamp(dist_net / max(dist_x, 1.0), 0.05, 0.95)
		
		is_net_drop = (dist_net < 220.0 and dist_x < 280.0)
		if is_net_drop:
			# VÊ CẦU SÁT LƯỚI: Bay mềm mại, thanh thoát (0.80s - 0.98s, tăng tốc nhẹ so với trước)
			flight_duration = clamp(dist_x / 200.0, 0.80, 0.98)
		else:
			# BỎ NHỎ Ở ĐOẠN GIỮA SÂN VÀ SÂN SAU: Nhanh đoạn đầu, bay thanh thoát (0.85s - 1.05s)
			flight_duration = clamp(dist_x / 560.0, 0.85, 1.05)
		
		# Quỹ đạo thuần 1 vòng cung lõm (Concave down, h''(u) <= 0 tuyệt đối):
		# Không gãy khúc, không cong vẹo hàm bậc 3: Xuất phát ngang/bổng 5 độ rồi rơi cong đều qua lưới
		if is_jump_drop or h_start >= t_res.net_height + 30.0:
			# NHẢY DROPSHOT:
			# Đi ngang hoặc nhích nhẹ lên trời góc 5 độ tùy cự ly xa lưới
			drop_h_net = t_res.net_height + 35.0 # 145.0px (an toàn cao hơn lưới 110px tận 35px)
			var rise_deg = clamp((dist_net - 140.0) / 260.0, 0.0, 1.0) * 26.0
			drop_A = rise_deg
		elif h_start < t_res.net_height:
			# CỨU CẦU DƯỚI LƯỚI / THẤP TAY:
			drop_h_net = t_res.net_height + 28.0 # 138.0px
			drop_A = (drop_h_net - h_start) * 2.2
		else:
			# ĐỨNG BỎ NHỎ Ở GIỮA SÂN:
			drop_h_net = t_res.net_height + 32.0 # 142.0px
			drop_A = clamp((drop_h_net - h_start) * 0.8, 8.0, 28.0)
			
		drop_B = h_start + drop_A
		var num = h_start + drop_A * drop_u_net - drop_h_net
		var ratio = clamp(num / max(drop_B, 0.001), 0.001, 0.999)
		drop_alpha = clamp(log(ratio) / log(drop_u_net), 1.25, 4.5)
		
	elif shot_type == "tsubame_gaeshi":
		# TSUBAME GAESHI (Én lượn trở về - Cắt xoáy lướt sà sát mép lưới):
		# Tốc độ lướt nhanh hơn (0.60s - 0.70s), điểm rơi cắm dốc sà sát lưới
		flight_duration = clamp(dist_x / 620.0, 0.60, 0.70)
		var dist_net = clamp(abs(t_res.net_x - from_pt.x), 15.0, dist_x - 20.0)
		drop_u_net = clamp(dist_net / max(dist_x, 1.0), 0.15, 0.85)
		drop_h_net = t_res.net_height + 12.0 # Lướt sà sát mép lưới 12px
		# Quỹ đạo Bezier Parabol mượt mà C-vô hạn:
		# h(u) = (1 - u)^2 * h_start + 2 * (1 - u) * u * fuji_h_control
		# Đảm bảo đường cong mượt mà tuyệt đối không có góc gập, điểm gấp hay bước nhảy bậc thang!
		var denom = 2.0 * drop_u_net * (1.0 - drop_u_net)
		var base_term = pow(1.0 - drop_u_net, 2.0) * h_start
		fuji_h_control = max(drop_h_net + 8.0, (drop_h_net - base_term) / max(denom, 0.05))
		
	elif shot_type == "mirage_counter":
		# MIRAGE COUNTER (The Wall): Bung cầu cao nhanh về cuối sân (0.96s - 1.05s)
		# Chỉ nhanh hơn phông/lift thường (1.15s) một tí xíu, bay cao vút ra cuối sân và hoàn toàn có thể đón đỡ được
		h_apex = 320.0
		flight_duration = clamp(dist_x / 620.0, 0.96, 1.05)
		
	elif shot_type == "underhand_lift":
		# BUNG CẦU THẤP TAY: Cao vút anime 340px, sâu cuối sân
		h_apex = t_res.lift_apex_h
		flight_duration = t_res.lift_flight_time
		
	elif shot_type == "weak_return":
		# CẦU NON BỔNG LƠ LỬNG (CHANCE BALL / POP-UP FLOAT):
		# Rơi nông ở khoảng giữa sân đối thủ, độ cao cực bổng (390px), bay lơ lửng 1.62s (chậm hơn 15%)
		# để đối phương dễ dàng định vị, bứt tốc bật nhảy BOOM SMASH dứt điểm!
		h_apex = 390.0
		flight_duration = 1.62
		
	elif shot_type == "drive":
		h_apex = t_res.net_height + 14.0
		flight_duration = max(0.35, dist_x / (t_res.drive_speed * 0.55))
		
	else: # "clear" / "lob" / "serve"
		# PHÔNG CẦU: Cao vút 370px, bay thẳng hơi cong, cuối sân rơi gần thẳng đứng
		h_apex = t_res.clear_apex_h
		flight_duration = t_res.clear_flight_time
	
	# Gia tốc nhịp cầu theo Escalating Tension (cầu bay nhanh hơn khi rally kéo dài)
	if not is_weak_return and not is_serve and tension_speed_mult > 1.0:
		flight_duration = flight_duration / tension_speed_mult
	
	launch_target = Vector2(final_target_x, floor_y)
	flight_time_elapsed = 0.0
	is_active = true
	
	global_position = from_pt
	velocity = _calc_velocity_at(0.0)
	
	predicted_landing_2d = launch_target
	predicted_flight_time = flight_duration
	
	_update_trail_styling()
	_update_landing_indicator()


# Backward compatibility wrapper for Vector3
func launch_to_target(from_3d: Vector3, target_3d: Vector3, shot_type: String, error_offset: Vector3 = Vector3.ZERO) -> void:
	var floor_y = tuning.floor_y if tuning else 550.0
	var from_2d = Vector2(from_3d.x, floor_y - from_3d.y)
	var target_2d = Vector2(target_3d.x, floor_y - target_3d.y)
	launch_to_target_2d(from_2d, target_2d, shot_type, error_offset.x)


# ==========================================================
# TRAJECTORY POSITION & VELOCITY CALCULATION
# ==========================================================

func _calc_height_at(p: float) -> float:
	var cp = clamp(p, 0.0, 1.0)
	var I_p = get_speed_integral(cp)
	var I_tot = get_total_integral()
	var u = clamp(I_p / I_tot, 0.0, 1.0) # Tiến độ không gian [0 -> 1]
	var t_res = tuning if tuning else GameTuning.new()
	
	if is_smash:
		# QUỸ ĐẠO SMASH THỰC TẾ: Đường đập cắm thẳng từ điểm tiếp xúc xuống sàn đối phương
		# 1 là đủ độ cao sẽ bay thẳng qua lưới cắm xuống sân đối phương
		# 2 là không đủ độ cao sẽ đập trúng lưới và rụng thẳng xuống đất
		return max(0.0, h_start * (1.0 - u))
		
	elif current_shot_type == "tsubame_gaeshi":
		# Đường bay Én lượn: Parabol Bezier mượt mà C-vô hạn lướt sát mặt lưới không một góc gập
		var ux = 1.0 - pow(1.0 - cp, 1.35)
		var h = pow(1.0 - ux, 2.0) * h_start + 2.0 * (1.0 - ux) * ux * fuji_h_control
		return max(0.0, h)
		
	elif current_shot_type == "drop":
		var u_drop: float = 0.0
		if is_net_drop:
			u_drop = 1.15 * cp - 0.15 * cp * cp
		else:
			# Nhanh đoạn đầu, sau đó hãm phanh êm ái khi qua lưới
			u_drop = 1.35 * cp - 0.35 * cp * cp
		
		# ĐƯỜNG CONG THUẦN 1 VÒNG CUNG LÕM (CONCAVE DOWN, h''(u) <= 0):
		# Xuất phát ngang / bổng nhẹ 5 độ tùy khoảng cách, đạt đỉnh mượt mà rồi rơi cong đều qua lưới cắm xuống sàn
		# TUYỆT ĐỐI KHÔNG CÓ ĐIỂM UỐN, KHÔNG CONG LÊN CONG XUỐNG NHƯ HÀM BẬC 3
		var h = h_start + drop_A * u_drop - drop_B * pow(u_drop, drop_alpha)
		return max(0.0, h)
		
	elif current_shot_type == "clear" or current_shot_type == "underhand_lift" or current_shot_type == "mirage_counter":
		# PHÔNG CẦU / COUNTER LIFT: Cao vút 320-370px, sâu cuối sân
		var t = pow(u, 0.88)
		var arc = sin(PI * t)
		return max(0.0, h_start * (1.0 - u) + (h_apex - h_start * 0.25) * arc)
		
	else:
		# DRIVE / OTHER
		var arc = 4.0 * u * (1.0 - u)
		return max(0.0, h_start * (1.0 - u) + (h_apex - h_start * 0.4) * arc)


func _calc_pos_at(p: float) -> Vector2:
	var cp = clamp(p, 0.0, 1.0)
	var I_p = get_speed_integral(cp)
	var I_tot = get_total_integral()
	var u = clamp(I_p / I_tot, 0.0, 1.0)
	
	# Horizontal progression: Clear & Lift cover 93% distance early; Smash bursts then decelerates into floor!
	var ux = u
	if is_smash:
		ux = pow(u, 0.92)
	elif current_shot_type == "clear" or current_shot_type == "underhand_lift" or current_shot_type == "mirage_counter":
		ux = 1.0 - pow(1.0 - u, 2.0)
	elif current_shot_type == "tsubame_gaeshi":
		ux = 1.0 - pow(1.0 - cp, 1.35)
	elif current_shot_type == "drop":
		if is_net_drop:
			ux = 1.15 * cp - 0.15 * cp * cp
		else:
			# Bỏ nhỏ ở đoạn giữa sân / xa: Nhanh đoạn đầu, sau đó giảm tốc
			ux = 1.35 * cp - 0.35 * cp * cp
	
	var dx = launch_target.x - launch_from.x
	var x = launch_from.x + dx * ux
	var floor_y = tuning.floor_y if tuning else 550.0
	var h = _calc_height_at(cp)
	return Vector2(x, floor_y - h)


func _calc_velocity_at(p: float) -> Vector2:
	var cp = clamp(p, 0.0, 1.0)
	var dp = 0.003
	var p1 = _calc_pos_at(cp)
	var p2 = _calc_pos_at(min(1.0, cp + dp))
	return (p2 - p1) / (dp * max(flight_duration, 0.01))


# ==========================================================
# PREDICT LANDING
# ==========================================================

func predict_landing(_custom_pos: Vector3 = Vector3.ZERO, _custom_vel: Vector3 = Vector3.ZERO) -> Dictionary:
	return {
		"pos_3d": Vector3(predicted_landing_2d.x, 0.0, 0.0),
		"pos_2d": predicted_landing_2d,
		"time": max(0.0, flight_duration - flight_time_elapsed),
		"hit_net": false
	}


# ==========================================================
# PHYSICS PROCESS (PURE 2D)
# ==========================================================

func _physics_process(delta: float) -> void:
	_update_fuji_leaves(delta)
	
	if is_suspended_in_smash_slowmo:
		global_position = suspended_smash_pos + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		_sync_shadow()
		if lightning_trail:
			lightning_trail.queue_redraw()
		return
		
	if not is_active:
		_sync_shadow()
		if landing_indicator:
			landing_indicator.visible = false
		return
	
	# Fuji Tsubame Gaeshi - Rơi lá cây lượn theo vệt cầu:
	if current_shot_type == "tsubame_gaeshi":
		fuji_leaf_spawn_timer -= delta
		if fuji_leaf_spawn_timer <= 0.0:
			fuji_leaf_spawn_timer = 0.026
			_spawn_fuji_leaf()
	
	var t_res = tuning if tuning else GameTuning.new()
	var floor_y = t_res.floor_y
	flight_time_elapsed += delta
	var p = clamp(flight_time_elapsed / max(flight_duration, 0.01), 0.0, 1.0)
	
	var prev_x = global_position.x
	
	# Vị trí tức thời từ hàm quỹ đạo
	var cur_pos = _calc_pos_at(p)
	global_position = cur_pos
	var h = max(0.0, floor_y - global_position.y)
	
	# Vận tốc tức thời (để quay đầu cầu tự nhiên và đo km/h)
	velocity = _calc_velocity_at(p)
	if velocity.length() > 20.0:
		rotation = lerp_angle(rotation, velocity.angle(), 0.35)
	
	# Kiểm tra va chạm lưới (Net Collision Check)
	var dx = launch_target.x - launch_from.x
	var crossed_net = (prev_x <= t_res.net_x and global_position.x >= t_res.net_x) or (prev_x >= t_res.net_x and global_position.x <= t_res.net_x)
	if crossed_net and abs(global_position.x - prev_x) > 0.001:
		var frac_net = clamp((t_res.net_x - prev_x) / (global_position.x - prev_x), 0.0, 1.0)
		var prev_h = max(0.0, floor_y - _calc_pos_at(clamp((flight_time_elapsed - delta) / max(flight_duration, 0.01), 0.0, 1.0)).y)
		var h_at_crossing = lerp(prev_h, h, frac_net)
		if current_shot_type != "drop" and current_shot_type != "tsubame_gaeshi" and h_at_crossing <= t_res.net_height:
			# Vướng lưới! Rơi thẳng xuống chân cột lưới
			global_position.x = t_res.net_x - sign(dx) * 8.0
			global_position.y = floor_y
			velocity = Vector2.ZERO
			is_smash = false
			is_boom_smash = false
			is_active = false
			is_net_fault = true
			hit_net.emit()
			if landing_indicator:
				landing_indicator.visible = false
			landed.emit(global_position)
			return
	
	# Chạm sàn (Floor Landing Check)
	if p >= 1.0 or h <= 0.0:
		global_position.y = floor_y
		is_active = false
		is_perfect = false
		velocity = Vector2.ZERO
		if landing_indicator:
			landing_indicator.visible = false
		if lightning_trail:
			lightning_trail.queue_redraw()
		landed.emit(global_position)
	
	_sync_shadow()
	_update_trail()
	_update_landing_indicator()


func _sync_shadow() -> void:
	if shadow_node:
		var floor_y = tuning.floor_y if tuning else 550.0
		shadow_node.global_position = Vector2(global_position.x, floor_y)
		var h = max(0.0, floor_y - global_position.y)
		var scale_val = clamp(1.0 - h * 0.0028, 0.35, 1.0)
		shadow_node.scale = Vector2(scale_val * 1.5, scale_val * 0.6)
		shadow_node.modulate.a = clamp(1.0 - h * 0.0024, 0.2, 0.65)


func _update_landing_indicator() -> void:
	if landing_indicator:
		landing_indicator.visible = false


func _update_trail_styling() -> void:
	trail_points.clear()
	if not trail:
		return
	trail.clear_points()
	if is_weak_return:
		trail.default_color = Color(3.5, 2.8, 0.4, 0.95) # Golden Chance Ball
		trail.width = 13.0
	elif is_tsubame_gaeshi:
		trail.default_color = Color(0.18, 0.95, 0.38, 0.95) # Vibrant Leaf/Foliage Green
		trail.width = 14.0
	elif is_mirage_counter:
		trail.default_color = Color(0.4, 2.0, 3.8, 1.0) # Cyan Mirage Phantom HDR
		trail.width = 16.0
	elif tension_level == 2:
		trail.default_color = Color(3.8, 2.4, 0.3, 1.0) # Lethal Gold Lightning
		trail.width = 16.0
	elif tension_level == 1:
		trail.default_color = Color(0.2, 0.85, 1.0, 0.95) # Electric Cyan Trail
		trail.width = 11.0
	elif is_boom_smash:
		trail.default_color = Color(3.8, 2.6, 0.4, 1.0) # Golden Lightning HDR
		trail.width = 18.0
	elif is_smash:
		trail.default_color = Color(3.2, 1.6, 0.2, 0.95) # Orange Spike HDR
		trail.width = 14.0
	else:
		trail.default_color = Color(1.0, 1.0, 1.0, 0.85) # Crisp White Feather Wind
		trail.width = 8.5


func _update_trail() -> void:
	if not trail:
		return
	trail_points.push_front(global_position)
	if trail_points.size() > MAX_TRAIL:
		trail_points.pop_back()
	
	trail.clear_points()
	for pt in trail_points:
		trail.add_point(pt)
	
	if lightning_trail:
		lightning_trail.queue_redraw()


func _on_lightning_trail_draw() -> void:
	if not is_boom_smash:
		return
	if trail_points.size() < 2:
		return
	
	var n_pts = trail_points.size()
	for i in range(n_pts - 1):
		var p1 = trail_points[i]
		var p2 = trail_points[i + 1]
		var diff = p2 - p1
		var seg_len = diff.length()
		if seg_len < 1.5:
			continue
		
		var frac = 1.0 - float(i) / float(n_pts)
		var perp = Vector2(-diff.y, diff.x).normalized()
		var jitter_mag = 8.5 * frac
		
		var m1 = p1.lerp(p2, 0.35) + perp * randf_range(-jitter_mag, jitter_mag)
		var m2 = p1.lerp(p2, 0.70) + perp * randf_range(-jitter_mag, jitter_mag)
		
		var bolt_pts = PackedVector2Array([p1, m1, m2, p2])
		
		# Outer electric golden aura (Sấm sét màu vàng ánh kim HDR)
		var glow_col = Color(3.8, 2.6, 0.25, frac * 0.85)
		lightning_trail.draw_polyline(bolt_pts, glow_col, 5.0 * frac, true)
		
		# Inner blinding core (Lõi vàng trắng siêu sáng)
		var core_col = Color(4.8, 4.4, 2.0, frac * 0.98)
		lightning_trail.draw_polyline(bolt_pts, core_col, 2.0 * frac, true)
		
		# Branching spark off trail (Tia sét vàng phân nhánh)
		if i % 3 == 0 and frac > 0.30 and randf() < 0.65:
			var branch_dir = perp * (1.0 if randf() < 0.5 else -1.0)
			var branch_end = m1 + branch_dir * randf_range(12.0, 26.0) * frac + diff.normalized() * randf_range(-6.0, 6.0)
			lightning_trail.draw_line(m1, branch_end, Color(3.8, 2.8, 0.4, frac * 0.85), 1.6, true)
	
	# Electric spark aura crackling around the shuttlecock cork head in flight (Tia điện vàng quanh đầu cầu)
	if is_active:
		for k in range(4):
			var sp_ang = randf_range(0, TAU)
			var sp_r = randf_range(6.0, 18.0)
			var p_sp1 = global_position + Vector2(cos(sp_ang), sin(sp_ang)) * sp_r
			var p_sp2 = p_sp1 + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
			lightning_trail.draw_line(p_sp1, p_sp2, Color(4.8, 4.4, 2.0, 0.95), 1.8, true)


# ==========================================================
# VECTOR SHUTTLECOCK DRAWING
# ==========================================================

func _draw() -> void:
	var feather_pts = PackedVector2Array([
		Vector2(2.0, -4.0),
		Vector2(-18.0, -10.0),
		Vector2(-18.0, 10.0),
		Vector2(2.0, 4.0)
	])
	draw_polygon(feather_pts, PackedColorArray([Color(0.95, 0.95, 1.0, 0.95)]))
	draw_polyline(feather_pts, Color(0.15, 0.2, 0.3, 0.9), 1.5, true)
	
	draw_line(Vector2(-8, -7), Vector2(-8, 7), Color(0.85, 0.2, 0.2, 0.85), 2.0, true)
	draw_line(Vector2(-13, -9), Vector2(-13, 9), Color(0.2, 0.4, 0.8, 0.85), 1.5, true)
	
	draw_circle(Vector2(5.0, 0.0), 5.5, Color(1.0, 1.0, 1.0, 1.0), true, -1.0, true)
	draw_circle(Vector2(5.0, 0.0), 5.5, Color(0.1, 0.1, 0.15, 0.9), false, 1.5, true)
	draw_line(Vector2(2.0, -5.0), Vector2(2.0, 5.0), Color(0.9, 0.2, 0.2, 1.0), 2.5, true)


# ==========================================================
# FUJI TSUBAME GAESHI FOLIAGE LEAVES EFFECT
# ==========================================================

func _spawn_fuji_leaf() -> void:
	var spawn_pos = global_position + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
	var leaf_cols = [
		Color(0.24, 0.88, 0.38, 0.95), # Fresh Bamboo Green
		Color(0.18, 0.78, 0.30, 0.95), # Lush Leaf Green
		Color(0.48, 0.96, 0.42, 0.95), # Light Spring Leaf Green
		Color(0.62, 0.90, 0.28, 0.95)  # Golden Leaf Green
	]
	var col = leaf_cols[randi() % leaf_cols.size()]
	var vel_back = -velocity.x * 0.08
	var leaf = {
		"pos": spawn_pos,
		"vel": Vector2(vel_back + randf_range(-16.0, 16.0), randf_range(24.0, 48.0)),
		"rot": randf_range(0.0, TAU),
		"spin": randf_range(-3.5, 3.5),
		"size": randf_range(7.5, 12.0),
		"life": randf_range(0.65, 0.90),
		"max_life": 0.85,
		"col": col,
		"wobble_freq": randf_range(3.5, 6.0),
		"wobble_phase": randf_range(0.0, TAU)
	}
	fuji_leaves.append(leaf)
	if leaf_trail:
		leaf_trail.queue_redraw()


func _update_fuji_leaves(delta: float) -> void:
	if fuji_leaves.is_empty():
		return
	
	for i in range(fuji_leaves.size() - 1, -1, -1):
		var lf = fuji_leaves[i]
		lf["life"] -= delta
		if lf["life"] <= 0.0:
			fuji_leaves.remove_at(i)
			continue
		
		lf["wobble_phase"] += lf["wobble_freq"] * delta
		var sway_x = sin(lf["wobble_phase"]) * 20.0
		lf["pos"].x += (lf["vel"].x + sway_x) * delta
		lf["pos"].y += lf["vel"].y * delta
		lf["rot"] += lf["spin"] * delta
	
	if leaf_trail:
		leaf_trail.queue_redraw()


func _on_fuji_leaf_draw() -> void:
	if fuji_leaves.is_empty() or not leaf_trail:
		return
		
	for lf in fuji_leaves:
		var frac = clamp(lf["life"] / lf["max_life"], 0.0, 1.0)
		var alpha = sin(frac * PI)
		var pos = lf["pos"]
		var rot = lf["rot"]
		var sz = lf["size"] * (0.8 + 0.2 * frac)
		var col = lf["col"]
		col.a = alpha * 0.95
		
		var cos_r = cos(rot)
		var sin_r = sin(rot)
		
		var local_pts = [
			Vector2(-sz * 0.7, 0.0),
			Vector2(-sz * 0.25, sz * 0.38),
			Vector2(sz * 0.45, sz * 0.30),
			Vector2(sz * 1.0, 0.0),
			Vector2(sz * 0.45, -sz * 0.30),
			Vector2(-sz * 0.25, -sz * 0.38)
		]
		var poly = PackedVector2Array()
		for lp in local_pts:
			poly.append(Vector2(
				pos.x + lp.x * cos_r - lp.y * sin_r,
				pos.y + lp.x * sin_r + lp.y * cos_r
			))
		
		leaf_trail.draw_colored_polygon(poly, col)
		
		var rim_col = Color(0.12, 0.60, 0.22, alpha * 0.90)
		var poly_loop = poly.duplicate()
		poly_loop.append(poly[0])
		leaf_trail.draw_polyline(poly_loop, rim_col, 1.1, true)
		
		var v0 = pos + Vector2(-sz * 0.5 * cos_r, -sz * 0.5 * sin_r)
		var v1 = pos + Vector2(sz * 0.85 * cos_r, sz * 0.85 * sin_r)
		var vein_col = Color(0.85, 1.0, 0.75, alpha * 0.80)
		leaf_trail.draw_line(v0, v1, vein_col, 1.0, true)
