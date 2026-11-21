extends Area2D
class_name Shuttlecock

signal landed(floor_pos_2d: Vector2)
signal hit_net()

# ==========================================================
# SHUTTLECOCK 2D PHYSICS (ANIME HIGH CLEAR & FAST BURST DECAY)
# ==========================================================

@export var tuning: GameTuning
@export var is_network_client: bool = false

var is_active: bool = false
var floor_contact_timer: float = 0.0
var has_emitted_landed: bool = false
var is_smash: bool = false
var is_boom_smash: bool = false
var is_tsubame_gaeshi: bool = false
var is_mirage_counter: bool = false
var is_jump_drop: bool = false
var is_serve: bool = false
var is_net_fault: bool = false
var is_weak_return: bool = false
var last_error_offset_x: float = 0.0
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

# Smash trajectory parameters (Cắm dốc, tốc độ cao, đảm bảo vượt qua lưới an toàn)
var smash_u_net: float = 0.5
var smash_h_net: float = 125.0
var smash_net_boost: float = 0.0
var is_ground_smash: bool = false
var is_kill_smash: bool = false

# Dynamic 2D Velocity (for HUD speed display and angle rotation)
var velocity: Vector2 = Vector2.ZERO

# Landing prediction
var predicted_landing_2d: Vector2 = Vector2.ZERO
var predicted_flight_time: float = 0.0

# Pre-rendered Texture Ribbon Trails (0% CPU load, full GPU hardware interpolation)
const TEX_TRAIL_LIGHTNING: Texture2D = preload("res://assets/images/trails/trail_lightning_gold.png")
const TEX_TRAIL_EMERALD: Texture2D = preload("res://assets/images/trails/trail_emerald_vortex.png")
const TEX_TRAIL_SPEED: Texture2D = preload("res://assets/images/trails/trail_speed_white.png")
const TEX_TRAIL_MIRAGE: Texture2D = preload("res://assets/images/trails/trail_mirage_cyan.png")

# Visual Trail & Ground Shadow
var trail_points: Array[Vector2] = []
const MAX_TRAIL: int = 26
var low_graphics_mode: bool = false

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
	
	# Mặc định đồ họa cao kể cả trên Web
	low_graphics_mode = false
	
	if trail:
		trail.top_level = true
		trail.clear_points()
		var curve = Curve.new()
		curve.add_point(Vector2(0.0, 1.0))
		curve.add_point(Vector2(0.35, 0.85))
		curve.add_point(Vector2(1.0, 0.08))
		trail.width_curve = curve
		trail.width = 22.0
		trail.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		trail.joint_mode = Line2D.LINE_JOINT_ROUND
		trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		trail.end_cap_mode = Line2D.LINE_CAP_ROUND
		trail.antialiased = not OS.has_feature("web")
		trail.texture = TEX_TRAIL_SPEED
		trail.default_color = Color(1.0, 1.0, 1.0, 0.85)
		if low_graphics_mode:
			trail.visible = false
	
	if lightning_trail:
		lightning_trail.top_level = true
		lightning_trail.draw.connect(_on_lightning_trail_draw)
		if low_graphics_mode:
			lightning_trail.visible = false
	
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
	last_error_offset_x = error_offset_x
	
	var final_target_x = target_pt.x + error_offset_x
	if shot_type == "weak_return":
		error_offset_x = 0.0
		# Cầu non (Chance Ball) luôn rơi ở vùng từ gần lưới tới giữa sân đối thủ:
		if final_target_x > t_res.net_x:
			final_target_x = clamp(final_target_x, 720.0, 880.0)
		else:
			final_target_x = clamp(final_target_x, 400.0, 560.0)
	var dx = final_target_x - from_pt.x
	dist_x = max(abs(dx), 15.0)
	var facing = 1.0 if dx >= 0 else -1.0
	
	if is_smash:
		var v_base = t_res.boom_smash_speed if is_boom_smash else t_res.smash_speed
		if is_kill_smash:
			# ĐẬP DỨT ĐIỂM CẦU NON (Tăng tốc độ thêm 10%: 0.21s - 0.29s):
			flight_duration = clamp(dist_x / (v_base * 1.15), 0.21, 0.29)
		else:
			# ĐẬP CẦU TỐC ĐỘ CAO (Tăng tốc độ thêm 10%: 0.39s - 0.59s):
			flight_duration = clamp(dist_x / (v_base * 0.72), 0.39, 0.59)
		h_apex = h_start
		is_ground_smash = false
				
	elif shot_type == "drop":
		var dist_net = clamp(abs(t_res.net_x - from_pt.x), 15.0, dist_x - 20.0)
		drop_u_net = clamp(dist_net / max(dist_x, 1.0), 0.05, 0.95)
		
		is_net_drop = (dist_net < 220.0 and dist_x < 280.0)
		if is_net_drop:
			# VÊ CẦU SÁT LƯỚI (Tăng tốc độ thêm 10%: 0.91s - 1.11s):
			flight_duration = clamp(dist_x / 176.0, 0.91, 1.11)
		else:
			# BỎ NHỎ Ở ĐOẠN GIỮA SÂN VÀ SÂN SAU (Tăng tốc độ thêm 10%: 0.96s - 1.19s):
			flight_duration = clamp(dist_x / 493.0, 0.96, 1.19)
		
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
		# TSUBAME GAESHI (Én lượn trở về - Tăng tốc độ thêm 10%: 0.68s - 0.80s):
		flight_duration = clamp(dist_x / 545.0, 0.68, 0.80)
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
		# MIRAGE COUNTER (The Wall): Bung cầu cao nhanh về cuối sân (Tăng tốc độ thêm 10%: 1.09s - 1.19s):
		h_apex = 320.0
		flight_duration = clamp(dist_x / 545.0, 1.09, 1.19)
		
	elif shot_type == "underhand_lift":
		# BUNG CẦU THẤP TAY: Cao vút anime 340px, sâu cuối sân (2.05s)
		h_apex = t_res.lift_apex_h
		flight_duration = t_res.lift_flight_time
		
	elif shot_type == "weak_return":
		# CẦU NON BỔNG LƠ LỬNG (CHANCE BALL / POP-UP FLOAT, 1.84s):
		h_apex = 390.0
		flight_duration = 1.84
		h_apex = 390.0
		flight_duration = 2.02
		
	elif shot_type == "drive":
		h_apex = t_res.net_height + 14.0
		flight_duration = max(0.44, dist_x / (t_res.drive_speed * 0.55))
		
	else: # "clear" / "lob" / "serve"
		# PHÔNG CẦU / PHÁT CẦU: Cao vút, rơi cuối sân (2.18s)
		h_apex = t_res.clear_apex_h
		flight_duration = t_res.clear_flight_time
	
	# Gia tốc nhịp cầu theo Escalating Tension (cầu bay nhanh hơn khi rally kéo dài)
	if not is_weak_return and not is_serve and tension_speed_mult > 1.0:
		flight_duration = flight_duration / tension_speed_mult
	
	launch_target = Vector2(final_target_x, floor_y)
	flight_time_elapsed = 0.0
	floor_contact_timer = 0.0
	has_emitted_landed = false
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
			has_emitted_landed = true
			if not is_network_client:
				hit_net.emit()
				landed.emit(global_position)
			if landing_indicator:
				landing_indicator.visible = false
			return
	
	# Chạm sàn (Floor Landing Check) - Ngăn hoàn toàn lỗi ngộ nhận chạm sàn ngay khi vừa rời mặt vợt (p < 0.18 / p < 0.25)
	var can_land_on_floor = p >= 1.0 or (h <= 0.0 and (p > 0.25 if is_serve else p > 0.18))
	if can_land_on_floor:
		global_position.y = floor_y
		velocity = Vector2.ZERO
		
		# Cho phép cửa sổ 80ms chạm sàn cứu cầu (Floor scoop/dive rescue leeway)
		floor_contact_timer += delta
		if floor_contact_timer >= 0.08:
			is_active = false
			is_perfect = false
			if landing_indicator:
				landing_indicator.visible = false
			if lightning_trail:
				lightning_trail.queue_redraw()
			if not is_network_client and not has_emitted_landed:
				has_emitted_landed = true
				landed.emit(global_position)
	
	_sync_shadow()
	_update_trail()
	_update_landing_indicator()


func set_low_graphics(enabled: bool) -> void:
	low_graphics_mode = enabled
	if low_graphics_mode:
		if trail:
			trail.visible = false
			trail.clear_points()
		trail_points.clear()
		if lightning_trail:
			lightning_trail.visible = false
	else:
		if trail:
			trail.visible = true
		if lightning_trail and not OS.has_feature("web"):
			lightning_trail.visible = true


func _sync_shadow() -> void:
	if shadow_node:
		if OS.has_feature("web"):
			shadow_node.visible = false
			return
		shadow_node.visible = true
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
	if low_graphics_mode:
		trail.visible = false
		trail.clear_points()
		return
	trail.visible = true
	trail.clear_points()
	trail.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	
	if is_boom_smash or tension_level == 2:
		trail.texture = TEX_TRAIL_LIGHTNING
		trail.default_color = Color(1.2, 1.1, 0.9, 1.0)
		trail.width = 42.0
	elif is_tsubame_gaeshi:
		trail.texture = TEX_TRAIL_EMERALD
		trail.default_color = Color(1.0, 1.2, 1.0, 1.0)
		trail.width = 36.0
	elif is_mirage_counter:
		trail.texture = TEX_TRAIL_MIRAGE
		trail.default_color = Color(1.0, 1.2, 1.3, 1.0)
		trail.width = 34.0
	elif is_weak_return:
		trail.texture = TEX_TRAIL_SPEED
		trail.default_color = Color(1.0, 1.0, 1.0, 0.95)
		trail.width = 24.0
	elif is_smash:
		trail.texture = TEX_TRAIL_LIGHTNING
		trail.default_color = Color(1.2, 0.9, 0.6, 0.95)
		trail.width = 32.0
	else:
		trail.texture = TEX_TRAIL_SPEED
		trail.default_color = Color(1.0, 1.0, 1.0, 0.85)
		trail.width = 22.0


func _update_trail() -> void:
	if not trail:
		return
	if low_graphics_mode:
		trail.visible = false
		trail.clear_points()
		trail_points.clear()
		return
	trail.visible = true
	trail_points.push_front(global_position)
	if trail_points.size() > MAX_TRAIL:
		trail_points.pop_back()
	
	trail.clear_points()
	for pt in trail_points:
		trail.add_point(pt)
	
	# Trên Web: Dải Ribbon Texture đã bao hàm đầy đủ hiệu ứng sét/gió lộng lẫy, không cần redraw vector CPU
	# Trên Desktop: Giữ cả hai để tối đa hóa độ sắc nét đa lớp
	if lightning_trail and not OS.has_feature("web"):
		lightning_trail.queue_redraw()


func _on_lightning_trail_draw() -> void:
	if not is_boom_smash and not is_tsubame_gaeshi:
		return
	if trail_points.size() < 2:
		return
	
	var is_web = OS.has_feature("web")
	var use_aa = not is_web
	var n_pts = trail_points.size()
	var time_sec = Time.get_ticks_msec() / 1000.0
	
	# ==========================================================
	# 1. FUJI - CƠN LỐC XANH (EMERALD GALE VORTEX TWIN-HELIX)
	# ==========================================================
	if is_tsubame_gaeshi:
		var helix1_pts = PackedVector2Array()
		var helix2_pts = PackedVector2Array()
		
		for i in range(n_pts):
			var pt = trail_points[i]
			var frac = 1.0 - float(i) / float(n_pts)
			var next_pt = trail_points[max(0, i - 1)] if i > 0 else (pt + velocity.normalized() * 5.0)
			var diff = (next_pt - pt).normalized()
			var perp = Vector2(-diff.y, diff.x)
			
			var wave = sin(time_sec * 18.0 + float(i) * 0.65) * (14.0 * frac)
			helix1_pts.append(pt + perp * wave)
			helix2_pts.append(pt - perp * wave)
		
		if helix1_pts.size() >= 2:
			# Dải lốc xoáy ngọc lục bảo 1 (Emerald Outer Ribbon)
			lightning_trail.draw_polyline(helix1_pts, Color(0.25, 1.8, 0.55, 0.85), 3.8, use_aa)
			if not is_web:
				# Lõi gió bão trắng ngọc sáng rực (Jade-White Core)
				lightning_trail.draw_polyline(helix1_pts, Color(0.85, 2.4, 1.2, 0.95), 1.6, true)
			
		if helix2_pts.size() >= 2:
			# Dải áp suất khí xoáy ngược chiều 2 (Cyan-Mint Spiral Ribbon)
			lightning_trail.draw_polyline(helix2_pts, Color(0.30, 1.6, 0.95, 0.75), 3.0, use_aa)
			if not is_web:
				lightning_trail.draw_polyline(helix2_pts, Color(0.90, 2.4, 1.8, 0.95), 1.4, true)
			
		# Lốc xoáy mini bao bọc quả cầu đang lao dốc (Cork Vortex Aura)
		if is_active:
			lightning_trail.draw_arc(global_position, 16.0, time_sec * 14.0, time_sec * 14.0 + PI * 1.35, 12 if is_web else 16, Color(0.35, 2.0, 0.75, 0.90), 2.4, use_aa)
			if not is_web:
				lightning_trail.draw_arc(global_position, 9.0, -time_sec * 18.0, -time_sec * 18.0 + PI * 1.2, 16, Color(0.85, 2.4, 1.4, 0.95), 1.8, true)
			
			# Vệt khí cắt gió (Wind Slash Crescents)
			for w in range(2 if is_web else 3):
				var ang = time_sec * 12.0 + (TAU / 3.0) * w
				var w_pos = global_position + Vector2(cos(ang), sin(ang)) * 14.0
				var w_end = w_pos + Vector2(-sin(ang), cos(ang)) * 10.0
				lightning_trail.draw_line(w_pos, w_end, Color(0.6, 2.2, 0.9, 0.85), 1.8, use_aa)
		return

	# ==========================================================
	# 2. NISHIKAWA - TIA CHỚP VÀNG (GOLDEN LIGHTNING BOLTS)
	# ==========================================================
	var step = 2 if is_web else 1
	for i in range(0, n_pts - 1, step):
		var p1 = trail_points[i]
		var p2 = trail_points[min(i + step, n_pts - 1)]
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
		
		if not is_web:
			# Outer electric golden aura (Desktop)
			var glow_col = Color(3.8, 2.6, 0.25, frac * 0.85)
			lightning_trail.draw_polyline(bolt_pts, glow_col, 5.0 * frac, true)
		
		# Inner blinding core
		var core_col = Color(4.8, 4.4, 2.0, frac * 0.98)
		lightning_trail.draw_polyline(bolt_pts, core_col, 2.5 * frac, use_aa)
		
		# Branching spark off trail
		if not is_web and i % 3 == 0 and frac > 0.30 and randf() < 0.65:
			var branch_dir = perp * (1.0 if randf() < 0.5 else -1.0)
			var branch_end = m1 + branch_dir * randf_range(12.0, 26.0) * frac + diff.normalized() * randf_range(-6.0, 6.0)
			lightning_trail.draw_line(m1, branch_end, Color(3.8, 2.8, 0.4, frac * 0.85), 1.6, true)
	
	# Electric spark aura crackling around the shuttlecock cork head in flight
	if is_active:
		var n_sp = 2 if is_web else 4
		for k in range(n_sp):
			var sp_ang = randf_range(0, TAU)
			var sp_r = randf_range(6.0, 18.0)
			var p_sp1 = global_position + Vector2(cos(sp_ang), sin(sp_ang)) * sp_r
			var p_sp2 = p_sp1 + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
			lightning_trail.draw_line(p_sp1, p_sp2, Color(4.8, 4.4, 2.0, 0.95), 1.8, use_aa)


# ==========================================================
# SHUTTLECOCK DRAWING (TEXTURE SPRITE REPLACES EXPENSIVE VECTORS)
# ==========================================================

func _draw() -> void:
	# Quả cầu đã được nâng cấp lên Texture 2D độ phân giải cao dạng ảnh thực tế (shuttlecock.png)
	# qua node Sprite2D, loại bỏ hoàn toàn các lệnh vẽ polygon và circle tốn kém mỗi frame.
	pass


# ==========================================================
# FUJI TSUBAME GAESHI FOLIAGE LEAVES EFFECT
# ==========================================================

func _spawn_fuji_leaf() -> void:
	var leaf_cols = [
		Color(0.24, 0.88, 0.38, 0.95), # Fresh Bamboo Green
		Color(0.18, 0.78, 0.30, 0.95), # Lush Leaf Green
		Color(0.48, 0.96, 0.42, 0.95), # Light Spring Leaf Green
		Color(0.20, 0.92, 0.60, 0.95), # Emerald Wind Gale
		Color(0.62, 0.90, 0.28, 0.95)  # Golden Leaf Green
	]
	
	# Sinh 2 lá phong/trúc lượn xoáy theo ngọn gió Cơn lốc xanh
	for k in range(2):
		var spawn_pos = global_position + Vector2(randf_range(-12.0, 12.0), randf_range(-10.0, 10.0))
		var col = leaf_cols[randi() % leaf_cols.size()]
		var vel_back = -velocity.x * randf_range(0.06, 0.12)
		var leaf = {
			"pos": spawn_pos,
			"vel": Vector2(vel_back + randf_range(-22.0, 22.0), randf_range(20.0, 56.0)),
			"rot": randf_range(0.0, TAU),
			"spin": randf_range(-4.5, 4.5),
			"size": randf_range(8.0, 13.5),
			"life": randf_range(0.70, 0.95),
			"max_life": 0.95,
			"col": col,
			"wobble_freq": randf_range(4.0, 7.5),
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
