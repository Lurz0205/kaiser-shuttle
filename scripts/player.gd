extends CharacterBody2D
class_name BadmintonPlayer

const AIPressureModel = preload("res://scripts/ai/ai_pressure_model.gd")
const CharacterStats = preload("res://scripts/core/character_stats.gd")

signal shot_hit(shot_type: String, is_smash: bool, quality: float, is_perfect: bool, is_jump_shot: bool, contact_pos: Vector2)
signal shot_whiffed()
signal jump_taken(takeoff_pos: Vector2, facing_dir: float)
signal shoe_squeak_triggered()

# Squeak audio tracking
var was_in_air_prev: bool = false
var prev_velocity_x: float = 0.0
var squeak_cooldown: float = 0.0

@export var is_ai: bool = false
@export var court_side: String = "player" # "player" (left) or "ai" (right)
@export var tuning: GameTuning
@export var ai_difficulty: int = 1 # 0: EASY (Dễ), 1: MEDIUM (TB), 2: HARD (Khó)
@export var stats: CharacterStats

# Movement parameters (Athletic badminton footwork scale)
var move_speed_x: float = 245.0
const JUMP_FORCE: float = -880.0
const GRAVITY: float = 2400.0

# Court limits (Cho phép di chuyển ra khỏi biên sân 1 đoạn ngắn)
var min_x: float = 20.0
var max_x: float = 620.0 # Stay on left before net at 640

# Hit mechanics
var can_hit: bool = true # ONE-HIT RULE
var is_serving_phase: bool = true # Lock movement during serve
var prev_key_j: bool = false
var prev_key_k: bool = false
var prev_key_l: bool = false
var prev_key_u: bool = false

# AI Decision and reaction parameters
var ai_reaction_timer: float = 0.0
var ai_has_reacted: bool = false
var ai_imprecision_x: float = 0.0
var ai_last_tracked_shuttle_time: float = -1.0
var ai_pressure_model: AIPressureModel = AIPressureModel.new()

# AI Adaptive In-Match Learning (CHỈ TRONG TRẬN ĐẤU ĐÓ)
var opp_recent_shots: Array[String] = [] # Lịch sử 10 cú đánh gần nhất của người chơi
var opp_recent_pos_x: Array[float] = [] # Vị trí X của người chơi khi đánh
var opp_consecutive_drops: int = 0 # Đếm số quả drop liên tiếp của người chơi
var opp_consecutive_clears: int = 0
var opp_consecutive_smashes: int = 0
var opp_is_camping_back: bool = false # Người chơi có đang đứng im ở sân sau không
var opp_camping_back_counter: int = 0
var opp_drop_ratio: float = 0.0 # Tỉ lệ spam drop trong các pha gần nhất
var ai_last_shot_chosen: String = "" # Cú đánh gần nhất AI đã tung ra (để mix up trước/sau)

# Rally Tension & Shot Speed scaling
var current_tension_mult: float = 1.0
var current_tension_level: int = 0
var rally_time: float = 0.0
var rally_hits: int = 0
var balance: float = 100.0 # Thăng bằng động học [0.0 -> 100.0]

# Bay Người Cứu Cầu (Diving Save Mechanics: nhấp đúp phím DD để phóng người tới lưới)
var is_diving: bool = false
var is_sliding: bool = false # Tương thích ngược với hệ thống trượt sàn
var dive_timer: float = 0.0
var dive_duration: float = 0.40
var dive_dir: float = 1.0
var slide_dir: float = 1.0
var slide_timer: float = 0.0
var slide_duration: float = 0.40
var dive_has_hit: bool = false

var is_getting_up: bool = false
var get_up_timer: float = 0.0
var get_up_duration: float = 0.22

var tap_d_timer: float = 0.0
const DOUBLE_TAP_WINDOW: float = 0.24 # 240ms cửa sổ nhấp đúp phím DD
var prev_key_d_raw: bool = false
var prev_key_a_raw: bool = false

# Kinematics & Animation
var walk_phase: float = 0.0
var is_swinging: bool = false
var swing_timer: float = 0.0
var swing_prog: float = 0.0
var swing_recovery: float = 0.0
const SWING_DURATION: float = 0.18
var swing_cooldown: float = 0.0
const SWING_COOLDOWN_MAX: float = 0.5 # Chỉ cho phép vung vợt 0.5s 1 lần
var input_buffer_shot: String = ""
var input_buffer_timer: float = 0.0
const INPUT_BUFFER_WINDOW: float = 0.16 # 160ms cửa sổ đệm phím bấm đón đầu cầu
var facing: float = 1.0 # 1.0 = right, -1.0 = left

# Pending Perfect Smash & Special Skills (giữ cầu lơ lửng trong slow-mo tại điểm chạm vợt, hết slow-mo mới phóng đi)
var pending_special_target: Vector2 = Vector2.ZERO
var pending_special_shot: String = ""
var pending_special_from: Vector2 = Vector2.ZERO
var pending_special_err: float = 0.0
var pending_special_is_perfect: bool = false
var pending_special_is_jump_smash: bool = false

# Backward compatibility alias
var pending_smash_target: Vector2 = Vector2.ZERO
var pending_smash_shot: String = ""
var pending_smash_from: Vector2 = Vector2.ZERO
var pending_smash_err: float = 0.0

# Continuous Articulated Joint Kinematics
var joint_torso: float = 0.0

# Legs: Thigh angle and Backward Knee Flexion (Always >= 0, bends calf backwards)
var joint_thigh_l: float = -0.12
var joint_knee_flex_l: float = 0.20
var joint_thigh_r: float = 0.12
var joint_knee_flex_r: float = 0.20

# Back Arm (Off-arm, Layer 1)
var joint_upper_off: float = 0.35
var joint_fore_off: float = 0.70

# Front Arm (Racket arm, Layer 3)
var joint_upper_racket: float = 0.55
var joint_fore_racket: float = 1.05
var joint_racket_angle: float = -0.75

# Colors (Athletic Tournament Competitor)
var col_skin: Color = Color(1.0, 0.86, 0.72)
var col_jersey: Color = Color(0.92, 0.22, 0.2) # Player Crimson
var col_shorts: Color = Color(0.12, 0.13, 0.18)
var col_accent: Color = Color(1.0, 0.8, 0.2)
var col_racket: Color = Color(1.0, 0.85, 0.2)
var col_ring: Color = Color(0.2, 0.9, 0.4)

var current_ground_y: float = 550.0
var shuttlecock: Shuttlecock = null
var opponent_player: BadmintonPlayer = null


func _ready() -> void:
	if not stats:
		stats = CharacterStats.create_wall() if is_ai else CharacterStats.create_nishikawa()
	
	if not tuning:
		tuning = load("res://resources/GameTuning.tres")
	if tuning:
		move_speed_x = tuning.move_speed_x
		current_ground_y = tuning.floor_y
		
	if stats:
		# Agility quyết định tốc độ di chuyển thể thao [230px/s -> 265px/s]
		move_speed_x = lerp(230.0, 265.0, (stats.agility - 40.0) / 59.0)
		
	if court_side == "ai":
		min_x = 660.0
		max_x = 1260.0 # Cho phép AI lùi sâu ra sau vạch biên 1140px đón phông
		facing = -1.0
		col_jersey = Color(0.2, 0.35, 0.8) # AI Navy Blue
		col_accent = Color(0.0, 0.85, 1.0)
		col_racket = Color(0.2, 0.8, 1.0)
		col_ring = Color(1.0, 0.8, 0.2)
	else:
		min_x = 20.0 # Cho phép Người chơi lùi ra sau vạch biên 140px đón phông
		max_x = 620.0
		facing = 1.0
		col_jersey = Color(0.92, 0.22, 0.2)
		col_accent = Color(1.0, 0.8, 0.2)
		col_racket = Color(1.0, 0.85, 0.2)
		col_ring = Color(0.2, 0.9, 0.4)
	
	global_position.y = current_ground_y
	queue_redraw()


func reset_position(serve_x: float, serve_y: float) -> void:
	current_ground_y = serve_y
	global_position = Vector2(serve_x, serve_y)
	velocity = Vector2.ZERO
	can_hit = true
	is_serving_phase = true # Locked during serve!
	is_swinging = false
	swing_timer = 0.0
	swing_recovery = 0.0
	swing_cooldown = 0.0
	input_buffer_shot = ""
	input_buffer_timer = 0.0
	pending_special_target = Vector2.ZERO
	pending_smash_target = Vector2.ZERO
	walk_phase = 0.0
	current_tension_mult = 1.0
	current_tension_level = 0
	rally_time = 0.0
	rally_hits = 0
	balance = 100.0
	is_diving = false
	is_sliding = false
	is_getting_up = false
	dive_timer = 0.0
	slide_timer = 0.0
	get_up_timer = 0.0
	dive_has_hit = false
	tap_d_timer = 0.0
	prev_key_d_raw = false
	prev_key_a_raw = false
	facing = -1.0 if court_side == "ai" else 1.0
	if stats:
		stats.reset_stamina()
	if is_ai and ai_pressure_model:
		ai_pressure_model.reset()
	queue_redraw()


func reset_in_match_learning() -> void:
	opp_recent_shots.clear()
	opp_recent_pos_x.clear()
	opp_consecutive_drops = 0
	opp_consecutive_clears = 0
	opp_consecutive_smashes = 0
	opp_is_camping_back = false
	opp_camping_back_counter = 0
	opp_drop_ratio = 0.0
	ai_last_shot_chosen = ""


func record_opponent_shot(shot_type: String, hitter_pos_x: float) -> void:
	if not is_ai:
		return
	opp_recent_shots.push_front(shot_type)
	if opp_recent_shots.size() > 10:
		opp_recent_shots.pop_back()
		
	opp_recent_pos_x.push_front(hitter_pos_x)
	if opp_recent_pos_x.size() > 10:
		opp_recent_pos_x.pop_back()
		
	if shot_type == "drop" or shot_type == "tsubame_gaeshi":
		opp_consecutive_drops += 1
		opp_consecutive_clears = 0
		opp_consecutive_smashes = 0
	elif shot_type == "clear" or shot_type == "underhand_lift":
		opp_consecutive_clears += 1
		opp_consecutive_drops = 0
		opp_consecutive_smashes = 0
	elif shot_type == "smash" or shot_type == "boom_smash" or shot_type == "kill_smash":
		opp_consecutive_smashes += 1
		opp_consecutive_drops = 0
		opp_consecutive_clears = 0
	else:
		opp_consecutive_drops = 0
		opp_consecutive_clears = 0
		opp_consecutive_smashes = 0
		
	var drop_count = 0
	for s in opp_recent_shots:
		if s == "drop" or s == "tsubame_gaeshi":
			drop_count += 1
	opp_drop_ratio = float(drop_count) / float(max(1, opp_recent_shots.size()))
	
	# Người chơi đứng ở sân sau (hitter_pos_x < 390.0)
	if hitter_pos_x < 390.0:
		opp_camping_back_counter += 1
	else:
		opp_camping_back_counter = max(0, opp_camping_back_counter - 1)
	opp_is_camping_back = (opp_camping_back_counter >= 2)


func _physics_process(delta: float) -> void:
	if tuning:
		current_ground_y = tuning.floor_y
		move_speed_x = tuning.move_speed_x
	
	# Gravity relative to flat ground
	if global_position.y < current_ground_y or velocity.y < 0.0:
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
		global_position.y = current_ground_y
	
	if not is_serving_phase:
		rally_time += delta
		if shuttlecock:
			rally_hits = shuttlecock.tension_level
	
	if is_ai:
		if ai_pressure_model:
			ai_pressure_model.update(delta)
		_process_ai(delta)
	else:
		_process_player_input(delta)
		
	# Cập nhật Thể lực & Giảm tốc độ di chuyển từ 100% về 50% khi thể lực còn từ 25% tới 0%:
	var is_moving_footwork = is_on_ground() and abs(velocity.x) > 15.0
	var is_slow_tempo = (current_tension_level == 0)
	if stats:
		stats.update_stamina(delta, is_moving_footwork, is_slow_tempo, rally_time, rally_hits)
		var stamina_speed_mult = stats.get_speed_multiplier()
		velocity.x *= stamina_speed_mult
		stats.update_accuracy(delta, balance, current_tension_level)
	
	# TỰ ĐỘNG CỨU CẦU KHI BAY NGƯỜI (AUTOMATIC DIVE RESCUE):
	# Nếu bay người tới vị trí cầu và chạm vào hitbox cứu cầu thì tự động xúc đỡ cầu ngay lập tức!
	if is_diving and not dive_has_hit and can_hit and shuttlecock and shuttlecock.is_active:
		var s_pt = shuttlecock.global_position
		var db_box = get_dive_rescue_box_global()
		if db_box.grow(20.0).has_point(s_pt):
			var perf_box = get_dive_rescue_perfect_box_global()
			var is_perf = perf_box.grow(12.0).has_point(s_pt)
			var q = 1.0 if is_perf else 0.70
			dive_has_hit = true
			_execute_dive_rescue({"can_hit": true, "zone": "dive", "quality": q, "is_perfect": is_perf})
	
	# Input Buffer: Kiểm tra đón đầu phím bấm trong cửa sổ 160ms
	if not is_ai and input_buffer_timer > 0.0:
		var hit_status = get_hit_status()
		if hit_status["can_hit"]:
			var act_shot = input_buffer_shot
			input_buffer_shot = ""
			input_buffer_timer = 0.0
			_trigger_shot(act_shot, hit_status)
		else:
			input_buffer_timer -= delta
			if input_buffer_timer <= 0.0:
				input_buffer_shot = ""
				is_swinging = true
				swing_timer = 0.0
				swing_recovery = 0.0
				swing_cooldown = SWING_COOLDOWN_MAX
				shot_whiffed.emit()
	
	# Swing timer & Smooth Follow-through blend
	if is_swinging:
		swing_timer += delta
		swing_prog = clamp(swing_timer / SWING_DURATION, 0.0, 1.0)
		if swing_timer >= SWING_DURATION:
			is_swinging = false
			swing_recovery = 1.0
	elif swing_recovery > 0.0:
		swing_recovery = move_toward(swing_recovery, 0.0, delta * 4.2)
	
	# Swing cooldown timer (Chỉ cho phép vung vợt 0.5s 1 lần)
	if swing_cooldown > 0.0:
		swing_cooldown = max(0.0, swing_cooldown - delta)
	
	# Squeak cooldown timer
	if squeak_cooldown > 0.0:
		squeak_cooldown = max(0.0, squeak_cooldown - delta)
	
	# Movement integration (Pure 2D)
	var was_in_air_before_move = not is_on_ground() and global_position.y < current_ground_y - 15.0
	
	global_position.x += velocity.x * delta
	global_position.y += velocity.y * delta
	
	global_position.x = clamp(global_position.x, min_x, max_x)
	var just_landed = false
	if global_position.y >= current_ground_y:
		if was_in_air_before_move and velocity.y >= 0.0:
			just_landed = true
		global_position.y = current_ground_y
		velocity.y = 0.0
	
	var currently_on_ground = is_on_ground()
	
	was_in_air_prev = not currently_on_ground and global_position.y < current_ground_y - 20.0
	
	# Động học Thăng bằng (Dynamic Balance Tracking):
	if just_landed:
		balance = max(55.0, balance - 15.0)
	elif is_diving or is_sliding:
		balance = 30.0
	elif is_getting_up:
		balance = move_toward(balance, 100.0, delta * 75.0)
	elif not currently_on_ground:
		balance = move_toward(balance, 80.0, delta * 30.0)
	elif currently_on_ground and prev_velocity_x * velocity.x < -60.0:
		balance = max(45.0, balance - 20.0) # Phanh gấp đổi hướng 180 độ
	else:
		# Di chuyển bình thường trên sàn luôn hồi phục và duy trì 100% thăng bằng!
		balance = move_toward(balance, 100.0, delta * 95.0)
		
	prev_velocity_x = velocity.x
	
	# Walk cycle animation
	if is_on_ground() and abs(velocity.x) > 10.0:
		walk_phase += delta * (abs(velocity.x) / move_speed_x) * 14.0
	else:
		walk_phase = lerp(walk_phase, 0.0, 10.0 * delta)
	
	# ==========================================================
	# CỬ ĐỘNG KHỚP NỐI LIÊN TỤC (SMOOTH ARTICULATED KINEMATICS)
	# ==========================================================
	_update_joint_kinematics(delta)
	
	queue_redraw()


func is_on_ground() -> bool:
	return abs(global_position.y - current_ground_y) < 2.0 and velocity.y >= 0.0


func _update_joint_kinematics(delta: float) -> void:
	var in_air = not is_on_ground() and global_position.y < current_ground_y - 25.0
	var is_moving = is_on_ground() and abs(velocity.x) > 10.0
	var is_moving_back = is_on_ground() and (facing * velocity.x < -10.0) # Lùi về sau
	var is_moving_fwd = is_on_ground() and (facing * velocity.x > 10.0)   # Tiến về trước
	
	var target_torso: float = 0.0
	var target_thigh_l: float = 0.0
	var target_knee_flex_l: float = 0.20
	var target_thigh_r: float = 0.0
	var target_knee_flex_r: float = 0.20
	
	var target_upper_off: float = 0.0
	var target_fore_off: float = 0.0
	var target_upper_racket: float = 0.0
	var target_fore_racket: float = 0.0
	var target_racket_angle: float = 0.0
	
	if is_swinging:
		var p = swing_prog
		if p < 0.30:
			# Windup: Giương vợt ra sau, cẳng tay giơ cao, ngực ưỡn lấy đà
			var sp = p / 0.30
			target_torso = lerp(0.0, -facing * 0.35, sp)
			target_upper_racket = lerp(-facing * 1.5, -facing * 2.3, sp)
			target_fore_racket = lerp(-facing * 2.2, -facing * 2.85, sp) # Cẳng tay hướng lên trên!
			target_racket_angle = lerp(-1.10, -2.40, sp)
			target_upper_off = lerp(facing * 0.6, facing * 1.2, sp)
			target_fore_off = lerp(facing * 1.0, facing * 1.6, sp)
		elif p < 0.70:
			# Forward Whip: Vụt mạnh qua đầu, duỗi tay cắm thẳng vào điểm tiếp xúc!
			var sp = (p - 0.30) / 0.40
			target_torso = lerp(-facing * 0.35, facing * 0.45, sp)
			target_upper_racket = lerp(-facing * 2.3, facing * 1.4, sp)
			target_fore_racket = lerp(-facing * 2.85, facing * 1.55, sp)
			target_racket_angle = lerp(-2.40, 0.75, sp)
			target_upper_off = lerp(facing * 1.2, -facing * 0.5, sp)
			target_fore_off = lerp(facing * 1.6, -facing * 0.3, sp)
		else:
			# Follow-through: Hạ vợt quét chéo hông mượt mà
			var sp = (p - 0.70) / 0.30
			target_torso = lerp(facing * 0.45, facing * 0.22, sp)
			target_upper_racket = lerp(facing * 1.4, facing * 0.75, sp)
			target_fore_racket = lerp(facing * 1.55, facing * 0.45, sp)
			target_racket_angle = lerp(0.75, 1.40, sp)
			target_upper_off = -facing * 0.45
			target_fore_off = -facing * 0.25
			
	elif swing_recovery > 0.0:
		# Hồi về vị trí thủ (Recovery blend - không giật frame)
		target_torso = lerp(0.0, facing * 0.20, swing_recovery)
		target_upper_racket = lerp(facing * 0.55, facing * 0.75, swing_recovery)
		target_fore_racket = lerp(facing * 1.05, facing * 0.55, swing_recovery)
		target_racket_angle = lerp(-0.75, 1.40, swing_recovery)
		target_upper_off = lerp(facing * 0.35, -facing * 0.40, swing_recovery)
		target_fore_off = lerp(facing * 0.70, -facing * 0.20, swing_recovery)
		
	elif is_diving or is_sliding:
		# ==========================================================
		# BAY NGƯỜI CỨU CẦU (DIVING RESCUE POSTURE):
		# Thân rạp ngang song song sàn, tay cầm vợt duỗi thẳng hết cỡ về trước, 2 chân duỗi sau
		# ==========================================================
		target_torso = facing * 1.35 # Thân người nằm ngang song song mặt đất
		target_upper_racket = facing * 1.55 # Cánh tay duỗi thẳng hướng về phía trước
		target_fore_racket = facing * 1.55  # Cẳng tay duỗi thẳng theo cánh tay
		target_racket_angle = -0.22         # Mặt vợt ngửa nhẹ đón xúc cầu
		target_upper_off = -facing * 1.15   # Tay sau duỗi ngược ra sau giữ thăng bằng
		target_fore_off = -facing * 1.35
		target_thigh_r = -facing * 0.85     # Chân duỗi thẳng về phía sau
		target_knee_flex_r = 0.20
		target_thigh_l = -facing * 0.70     # Chân sau duỗi theo
		target_knee_flex_l = 0.35
		
	elif is_getting_up:
		# ==========================================================
		# ĐỨNG DẬY SAU CÚ TRƯỢT (GETTING UP POSTURE):
		# ==========================================================
		var p_up = clamp(get_up_timer / max(get_up_duration, 0.01), 0.0, 1.0)
		target_torso = lerp(facing * 0.60, 0.0, p_up)
		target_upper_racket = lerp(facing * 1.2, facing * 0.55, p_up)
		target_fore_racket = lerp(facing * 1.4, facing * 1.05, p_up)
		target_racket_angle = -0.75
		target_upper_off = lerp(facing * 0.8, facing * 0.35, p_up)
		target_fore_off = lerp(facing * 1.0, facing * 0.70, p_up)
		target_thigh_r = lerp(facing * 0.45, facing * 0.12, p_up)
		target_knee_flex_r = lerp(0.60, 0.20, p_up)
		target_thigh_l = lerp(-facing * 0.40, -facing * 0.12, p_up)
		target_knee_flex_l = lerp(0.70, 0.20, p_up)
		
	elif in_air:
		# ==========================================================
		# TRÊN KHÔNG (JUMP POSTURE): 2 CHÂN CO NHẸ VỀ PHÍA SAU
		# ==========================================================
		target_torso = -facing * 0.28
		# Cánh tay và cẳng tay cầm vợt HƯỚNG LÊN TRÊN sau đầu (Spike ready)
		target_upper_racket = -facing * 2.25
		target_fore_racket = -facing * 2.85 # Hướng thẳng lên trời!
		target_racket_angle = -2.40         # Cán vợt dựng hướng lên và ra sau đầu
		# Tay sau chỉ điểm cầu bổng
		target_upper_off = facing * 1.20
		target_fore_off = facing * 1.60
		
		# 2 chân co gối hướng về phía sau (-facing)
		target_thigh_r = -facing * 0.40
		target_knee_flex_r = 0.75 # Khớp gối co gập về sau
		target_thigh_l = -facing * 0.52
		target_knee_flex_l = 0.85 # Khớp gối co gập về sau
		
	elif is_moving_back:
		# ==========================================================
		# DI CHUYỂN LÙI: TAY ĐƯA VỢT VỀ PHÍA SAU ĐẦU, CẲNG TAY HƯỚNG LÊN TRÊN
		# ==========================================================
		target_torso = -facing * 0.10
		# Bắp tay mở ra sau và hướng lên
		target_upper_racket = -facing * 2.20
		# CẲNG TAY HƯỚNG LÊN TRÊN (không bao giờ chúc xuống đất!)
		target_fore_racket = -facing * 2.85
		# Cán vợt dựng lên cao qua đầu đón cầu phông/smash
		target_racket_angle = -2.35
		
		# Tay sau đưa ra trước ngực chỉ cầu giữ thăng bằng
		target_upper_off = facing * 0.95
		target_fore_off = facing * 1.45
		
		# Bộ pháp bước lùi tự nhiên (Backpedal Chassé)
		var stride = sin(walk_phase)
		target_thigh_l = -facing * (stride * 0.40 + 0.25)
		target_knee_flex_l = clamp(-stride, 0.0, 0.8) * 0.65 + 0.15
		target_thigh_r = facing * (stride * 0.40 - 0.15)
		target_knee_flex_r = clamp(stride, 0.0, 0.8) * 0.65 + 0.15
		
	elif is_moving_fwd:
		# ==========================================================
		# DI CHUYỂN TỚI: TAY CẦM VỢT Ở TRƯỚC NHƯ BÌNH THƯỜNG
		# ==========================================================
		target_torso = facing * 0.22
		# Tay cầm vợt giơ trước ngực sẵn sàng vồ cầu / tạt cầu
		target_upper_racket = facing * 0.65
		target_fore_racket = facing * 1.15
		target_racket_angle = -0.68
		# Tay sau hơi hạ về sau thân
		target_upper_off = -facing * 0.40
		target_fore_off = -facing * 0.20
		
		# Chân sải bước chạy về trước (Đùi sải tới lui, gối co tự nhiên khi bước)
		var stride = sin(walk_phase)
		target_thigh_r = facing * (stride * 0.55)
		target_knee_flex_r = clamp(-stride, 0.0, 1.0) * 0.80 + 0.15
		target_thigh_l = -facing * (stride * 0.55)
		target_knee_flex_l = clamp(stride, 0.0, 1.0) * 0.80 + 0.15
		
	else:
		# ==========================================================
		# ĐỨNG THỦ BÌNH THƯỜNG (READY GUARD STANCE)
		# ==========================================================
		target_torso = 0.0
		target_upper_racket = facing * 0.55
		target_fore_racket = facing * 1.05
		target_racket_angle = -0.75
		target_upper_off = facing * 0.35
		target_fore_off = facing * 0.70
		
		target_thigh_l = -facing * 0.12
		target_knee_flex_l = 0.20
		target_thigh_r = facing * 0.12
		target_knee_flex_r = 0.20
	
	# NỘI SUY GÓC KHỚP MƯỢT MÀ (SMOOTH INTERPOLATION - ZERO SNAPPING)
	joint_torso = lerp_angle(joint_torso, target_torso, 20.0 * delta)
	joint_thigh_l = lerp_angle(joint_thigh_l, target_thigh_l, 20.0 * delta)
	joint_knee_flex_l = lerp(joint_knee_flex_l, target_knee_flex_l, 20.0 * delta)
	joint_thigh_r = lerp_angle(joint_thigh_r, target_thigh_r, 20.0 * delta)
	joint_knee_flex_r = lerp(joint_knee_flex_r, target_knee_flex_r, 20.0 * delta)
	joint_upper_off = lerp_angle(joint_upper_off, target_upper_off, 22.0 * delta)
	joint_fore_off = lerp_angle(joint_fore_off, target_fore_off, 22.0 * delta)
	joint_upper_racket = lerp_angle(joint_upper_racket, target_upper_racket, 24.0 * delta)
	joint_fore_racket = lerp_angle(joint_fore_racket, target_fore_racket, 24.0 * delta)
	joint_racket_angle = lerp_angle(joint_racket_angle, target_racket_angle, 26.0 * delta)


func start_dive(dir: float = 1.0) -> void:
	if is_diving or is_getting_up or not is_on_ground() or is_serving_phase:
		return
	
	# CHỈ CHO PHÉP BAY NGƯỜI VỀ PHÍA LƯỚI / SÂN ĐỐI PHƯƠNG:
	var forward_dir = 1.0 if court_side == "player" else -1.0
	is_diving = true
	is_sliding = true
	dive_dir = forward_dir
	slide_dir = forward_dir
	dive_timer = 0.0
	slide_timer = 0.0
	dive_duration = 0.40
	slide_duration = 0.40
	dive_has_hit = false
	
	# TUYỆT ĐỐI GIỮ FACING HƯỚNG VỀ LƯỚI / ĐỐI THỦ:
	facing = forward_dir
	
	# Vận tốc bay người bùng nổ về phía lưới:
	velocity.x = forward_dir * (move_speed_x * 2.35)
	velocity.y = -65.0 # Nhấc bổng người nhẹ trên không
	
	# Tiêu hao 22 thể lực:
	if stats:
		stats.consume_stamina_action(22.0)
		
	# Mất thăng bằng trong cú bay người:
	balance = 30.0
	
	# Âm thanh ma sát cọ sàn: (Ngoại trừ ấn double 2 lần để cứu cầu theo yêu cầu của user)
	squeak_cooldown = 0.35


func start_slide(dir: float = 1.0) -> void:
	start_dive(dir)


func _process_player_input(delta: float) -> void:
	if is_serving_phase:
		velocity.x = 0.0
		return
	
	# Đếm lùi timer nhấp đúp:
	if tap_d_timer > 0.0:
		tap_d_timer = max(0.0, tap_d_timer - delta)
		
	var cur_d_raw = Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	var cur_a_raw = Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	
	# Nhấp đúp phím D (phải / hướng tới lưới) để BAY NGƯỜI CỨU CẦU:
	# Lưu ý: Nhấn A (lùi sau) tuyệt đối KHÔNG kích hoạt bay người để tránh lật ngược hướng nhân vật!
	if cur_d_raw and not prev_key_d_raw:
		if tap_d_timer > 0.0 and not is_diving and not is_getting_up and is_on_ground():
			start_dive(1.0)
			tap_d_timer = 0.0
		else:
			tap_d_timer = DOUBLE_TAP_WINDOW
			# Tiếng rít giày phát ra khi ấn nút di chuyển (ngoại trừ ấn double cứu cầu):
			if is_on_ground() and not is_diving and not is_getting_up and squeak_cooldown <= 0.0:
				squeak_cooldown = 0.12
				shoe_squeak_triggered.emit()
				
	if cur_a_raw and not prev_key_a_raw:
		# Tiếng rít giày phát ra khi ấn nút di chuyển A:
		if is_on_ground() and not is_diving and not is_getting_up and squeak_cooldown <= 0.0:
			squeak_cooldown = 0.12
			shoe_squeak_triggered.emit()
			
	prev_key_d_raw = cur_d_raw
	prev_key_a_raw = cur_a_raw
	
	if is_diving:
		dive_timer += delta
		slide_timer = dive_timer
		var p_dive = clamp(dive_timer / dive_duration, 0.0, 1.0)
		if p_dive < 0.50:
			velocity.x = dive_dir * (move_speed_x * 2.35)
		else:
			var p_slide = (p_dive - 0.50) / 0.50
			velocity.x = dive_dir * lerp(move_speed_x * 1.85, move_speed_x * 0.25, p_slide)
			
		if dive_timer >= dive_duration:
			is_diving = false
			is_sliding = false
			is_getting_up = true
			get_up_timer = 0.0
			var sta = stats.stamina if stats else 100.0
			# Thể lực thấp làm giảm tốc độ đứng dậy [0.22s khi sung mãn -> 0.68s khi cạn thể lực]:
			get_up_duration = lerp(0.68, 0.22, clamp(sta / 80.0, 0.0, 1.0))
	elif is_getting_up:
		get_up_timer += delta
		velocity.x = move_toward(velocity.x, 0.0, delta * 900.0)
		if get_up_timer >= get_up_duration:
			is_getting_up = false
	else:
		var move_x = 0.0
		if cur_a_raw:
			move_x -= 1.0
		if cur_d_raw:
			move_x += 1.0
		
		velocity.x = move_x * move_speed_x
		
		# Jump: Space, W, or Up
		if (Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) and is_on_ground():
			velocity.y = JUMP_FORCE
			jump_taken.emit(Vector2(global_position.x, current_ground_y), facing)
			if stats:
				stats.consume_stamina_action(5.0)
	
	# Swing / Shot trigger: Player can ALWAYS swing anytime!
	var cur_j = Input.is_key_pressed(KEY_J)
	var cur_k = Input.is_key_pressed(KEY_K)
	var cur_l = Input.is_key_pressed(KEY_L) or Input.is_key_pressed(KEY_ENTER)
	
	var shot_pressed = ""
	if cur_j and not prev_key_j:
		shot_pressed = "drop"
	elif cur_k and not prev_key_k:
		shot_pressed = "clear"
	elif cur_l and not prev_key_l:
		shot_pressed = "smash"
		
	prev_key_j = cur_j
	prev_key_k = cur_k
	prev_key_l = cur_l
	
	if shot_pressed != "":
		# CHỈ CHO PHÉP VUNG VỢT 0.5S 1 LẦN (SWING COOLDOWN):
		if swing_cooldown > 0.0:
			return
		
		# 1. KIỂM TRA VA CHẠM NGAY LẬP TỨC (0ms DELAY):
		var hit_status = get_hit_status()
		if hit_status["can_hit"]:
			input_buffer_shot = ""
			input_buffer_timer = 0.0
			_trigger_shot(shot_pressed, hit_status)
		else:
			# 2. NẾU BẤM SỚM MỘT VÀI FRAME (ĐÓN ĐẦU CẦU), LƯU VÀO BỘ ĐỆM 160ms
			# Ngay khi cầu vừa chạm vào mép hitbox sẽ lập tức đánh trúng, không bao giờ bị hụt oan!
			input_buffer_shot = shot_pressed
			input_buffer_timer = INPUT_BUFFER_WINDOW


func _trigger_shot(shot_pressed: String, hit_status: Dictionary) -> void:
	if is_diving or is_sliding:
		if not dive_has_hit:
			dive_has_hit = true
			_execute_dive_rescue(hit_status)
		return
		
	swing_cooldown = SWING_COOLDOWN_MAX
	is_swinging = true
	swing_timer = 0.0
	swing_recovery = 0.0
	
	var is_incoming_smash = (shuttlecock.is_smash or shuttlecock.is_boom_smash or shuttlecock.is_kill_smash or shuttlecock.current_shot_type == "kill_smash")
	var is_incoming_chance = (shuttlecock.is_weak_return or shuttlecock.current_shot_type == "weak_return")
	var is_wall_counter = stats and (stats.character_id == "wall" or stats.special_skill_id == "mirage_counter") and stats.can_use_special()
	# Mirage Counter chỉ dùng để thủ phản đòn khi đối phương SMASH, KHÔNG kích hoạt khi đối phương bung Cầu Non (Chance Ball)!
	var is_wall_counter_eligible = is_incoming_smash and is_wall_counter
	var s_h = current_ground_y - shuttlecock.global_position.y
	var is_in_air = not is_on_ground() and global_position.y < current_ground_y - 25.0
	
	if shot_pressed == "smash":
		# KHÔNG THỂ ĐỠ CẦU ĐẬP BẰNG NÚT ĐẬP CẦU (L) TRỪ KHI KÍCH HOẠT MIRAGE COUNTER:
		if is_incoming_smash and not is_wall_counter:
			shot_whiffed.emit()
			return
		
		# CHỈ ĐẬP KHI Ở TRÊN ĐẦU HOẶC ĐANG NHẢY HOẶC KHI ĐỐI THỦ BUNG CẦU NON (CHANCE BALL):
		var is_high_reach = (hit_status["zone"] == "overhead" and s_h >= 130.0)
		var is_air_smash = (is_in_air and s_h >= 120.0)
		if is_wall_counter and is_incoming_smash:
			_execute_hit("mirage_counter", hit_status)
		elif is_air_smash or is_high_reach or is_incoming_chance:
			_execute_hit("smash", hit_status)
		else:
			_execute_fault_smash_into_net(hit_status)
	else:
		if is_wall_counter_eligible:
			_execute_hit("mirage_counter", hit_status)
		else:
			_execute_hit(shot_pressed, hit_status)


# ==========================================================
# AI TỰ ĐỘNG DUY TRÌ GIỮA SÂN & DI CHUYỂN TRƯỚC SAU ĐÁNH CẦU
# ==========================================================

func _process_ai(delta: float) -> void:
	if is_serving_phase:
		velocity.x = 0.0
		return
	
	if is_diving:
		dive_timer += delta
		slide_timer = dive_timer
		var p_dive = clamp(dive_timer / dive_duration, 0.0, 1.0)
		if p_dive < 0.50:
			velocity.x = dive_dir * (move_speed_x * 2.35)
		else:
			var p_slide = (p_dive - 0.50) / 0.50
			velocity.x = dive_dir * lerp(move_speed_x * 1.85, move_speed_x * 0.25, p_slide)
		if dive_timer >= dive_duration:
			is_diving = false
			is_sliding = false
			is_getting_up = true
			get_up_timer = 0.0
			var sta = stats.stamina if stats else 100.0
			get_up_duration = lerp(0.68, 0.22, clamp(sta / 80.0, 0.0, 1.0))
		return
	elif is_getting_up:
		get_up_timer += delta
		velocity.x = move_toward(velocity.x, 0.0, delta * 900.0)
		if get_up_timer >= get_up_duration:
			is_getting_up = false
		return
	
	# Vị trí trung tâm hồi về linh hoạt theo thói quen đối thủ (In-Match Adaptation)
	var dynamic_home_x: float = 920.0
	if ai_difficulty == 2:
		# HARD AI: Thích nghi thói quen người chơi trong trận đấu
		if opp_consecutive_drops >= 2 or opp_drop_ratio >= 0.45 or opp_is_camping_back:
			# Người chơi có thói quen spam bỏ nhỏ / đứng im sân sau: AI dâng cao (815px) đón đầu
			# Tiết kiệm thể lực di chuyển và chặn đứng exploit
			dynamic_home_x = 815.0
		elif opp_consecutive_clears >= 2:
			# Người chơi liên tục phông sâu: AI lùi nhẹ đón bật nhảy đập
			dynamic_home_x = 945.0
		elif stats and stats.stamina < 50.0:
			# Tiết kiệm thể lực: Đứng chuẩn T-junction (890px), giảm quãng đường chạy
			dynamic_home_x = 890.0
		else:
			dynamic_home_x = 910.0
	elif ai_difficulty == 1:
		# MEDIUM AI: Thích nghi vừa phải
		if opp_consecutive_drops >= 3 or opp_drop_ratio >= 0.60:
			dynamic_home_x = 850.0
		elif stats and stats.stamina < 40.0:
			dynamic_home_x = 905.0
		else:
			dynamic_home_x = 920.0
	else:
		dynamic_home_x = 920.0
	
	if not shuttlecock or not shuttlecock.is_active:
		# Hồi về vị trí giữa sân
		velocity.x = move_toward(velocity.x, (dynamic_home_x - global_position.x) * 2.8, move_speed_x * 0.85)
		ai_has_reacted = false
		ai_reaction_timer = 0.0
		return
	
	var s_pos = shuttlecock.global_position
	var s_vel = shuttlecock.velocity
	
	# 1. KHI AI VỪA ĐÁNH XONG (CẦU ĐANG BAY SANG SÂN NGƯỜI CHƠI): AI HỒI VỀ VỊ TRÍ CHIẾN THUẬT
	if shuttlecock.last_hitter == "ai" or not can_hit or s_vel.x < -10.0:
		ai_has_reacted = false
		ai_reaction_timer = 0.0
		var diff_home = dynamic_home_x - global_position.x
		if abs(diff_home) > 15.0:
			velocity.x = sign(diff_home) * move_speed_x * 0.75
		else:
			velocity.x = 0.0
		return
	
	# 2. XỬ LÝ PHẢN XẠ AI (REACTION TIME DỰA TRÊN ĐỘ KHÓ)
	if not ai_has_reacted:
		if ai_last_tracked_shuttle_time != shuttlecock.flight_duration:
			ai_last_tracked_shuttle_time = shuttlecock.flight_duration
			var is_incoming_smash_shot = (shuttlecock.is_smash or shuttlecock.is_boom_smash)
			var is_incoming_tsubame = (shuttlecock.current_shot_type == "tsubame_gaeshi" or shuttlecock.is_tsubame_gaeshi)
			var is_incoming_drop = (shuttlecock.current_shot_type == "drop")
			var is_incoming_chance = (shuttlecock.is_weak_return or shuttlecock.current_shot_type == "weak_return")
			
			if is_incoming_chance:
				# Với Cầu Non (Chance Ball): AI nhận diện cơ hội dứt điểm lập tức, không delay, không lệch vị trí
				ai_reaction_timer = 0.02
				ai_imprecision_x = 0.0
			elif is_incoming_tsubame:
				# Cú cắt xoáy ảo diệu của Fuji làm đối thủ giật mình / khựng phán đoán:
				ai_reaction_timer = randf_range(0.20, 0.28)
				ai_imprecision_x = randf_range(-15.0, 15.0)
			else:
				match ai_difficulty:
					0: # DỄ:
						# Nếu là quả đập trúng tầm đứng, AI phản xạ 0.20s để vẫn có thể đỡ được khi bóng tới gần
						if is_incoming_smash_shot:
							ai_reaction_timer = 0.20
							ai_imprecision_x = randf_range(-25.0, 25.0)
						elif is_incoming_drop:
							ai_reaction_timer = 0.32
							ai_imprecision_x = randf_range(-35.0, 35.0)
						else:
							ai_reaction_timer = 0.35
							ai_imprecision_x = randf_range(-40.0, 40.0)
					1: # TRUNG BÌNH:
						# Phản xạ cực nhanh với dropshot để chạy lên lưới cứu bỏ nhỏ
						if is_incoming_drop:
							ai_reaction_timer = 0.03 if (opp_consecutive_drops >= 2 or opp_is_camping_back) else 0.05
							ai_imprecision_x = randf_range(-6.0, 6.0)
						elif is_incoming_smash_shot:
							ai_reaction_timer = 0.14
							ai_imprecision_x = randf_range(-14.0, 14.0)
						else:
							ai_reaction_timer = 0.16
							ai_imprecision_x = randf_range(-15.0, 15.0)
					2: # KHÓ: Phản xạ cực nhanh 0.02s, bắt bài bỏ nhỏ tức thì
						if is_incoming_drop:
							ai_reaction_timer = 0.01 if (opp_consecutive_drops >= 1 or opp_is_camping_back) else 0.02
						else:
							ai_reaction_timer = 0.02
						ai_imprecision_x = 0.0
		
		ai_reaction_timer -= delta
		if ai_reaction_timer > 0.0:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			return
		else:
			ai_has_reacted = true
	
	# 3. KHI CẦU ĐANG BAY VỀ PHÍA SÂN AI: DI CHUYỂN ĐÓN ĐIỂM RƠI THEO ĐỘ KHÓ
	var pred_x = shuttlecock.predicted_landing_2d.x
	var is_drop = (shuttlecock.current_shot_type == "drop" or shuttlecock.current_shot_type == "tsubame_gaeshi")
	var is_chance_ball = (shuttlecock.is_weak_return or shuttlecock.current_shot_type == "weak_return")
	
	# AI PHÁN ĐOÁN CẦU OUT BIÊN SAU (RIGHT_OUT_X = 1140.0):
	# Nếu cầu bay bổng vọt xà ra ngoài biên sau, AI phán đoán và bỏ cầu (Leave the ball)!
	var is_heading_out = (pred_x > 1140.0 and shuttlecock.velocity.x > 0.0)
	var ai_judges_out = false
	if is_heading_out:
		if pred_x > 1160.0:
			var judge_chance = 0.82 if ai_difficulty == 0 else (0.96 if ai_difficulty == 1 else 1.0)
			ai_judges_out = (randf() < judge_chance)
		else:
			var judge_chance = 0.50 if ai_difficulty == 0 else (0.85 if ai_difficulty == 1 else 0.98)
			ai_judges_out = (randf() < judge_chance)
	
	var diff_speed_scale = 0.72
	var sprint_scale = 1.05
	var min_net_approach = 710.0
	match ai_difficulty:
		0: # DỄ
			diff_speed_scale = 0.72
			sprint_scale = 1.05
			min_net_approach = 710.0
		1: # TRUNG BÌNH
			diff_speed_scale = 0.88
			sprint_scale = 1.30 # Nước rút nhanh lên đón dropshot hoặc áp sát dứt điểm cầu non!
			min_net_approach = 670.0 # Bám sát lưới hơn
		2: # KHÓ
			diff_speed_scale = 1.02
			sprint_scale = 1.38
			min_net_approach = 665.0
			
	var target_x: float
	if ai_judges_out:
		# BỎ CẦU OUT: Dừng lại trong sân (1080px), không đuổi bóng ra ngoài biên, đứng nhìn cầu rơi ăn điểm!
		target_x = 1080.0
	elif is_chance_ball:
		# CHỦ ĐỘNG DÂNG CAO ĐÓN ĐẦU CẦU NON (MID-COURT INTERCEPTION):
		target_x = clamp(pred_x - 90.0, 770.0, 840.0)
	else:
		target_x = clamp(pred_x + ai_imprecision_x + (10.0 if is_drop else 15.0), min_net_approach, 1140.0)
	var diff_x = target_x - global_position.x
	
	# Scramble run tracking: AI phải chạy đuổi bóng tốc độ cao tạo áp lực thể chất / tâm lý
	if abs(diff_x) > 130.0 and abs(velocity.x) > 170.0 and ai_pressure_model:
		ai_pressure_model.on_scramble_run(delta)
	
	# Hesitation factor: Bị vặn sườn (wrong foot) hoặc áp lực tâm lý cao làm khựng bước
	var hesitation_factor = 1.0
	if ai_pressure_model and ai_pressure_model.hesitation_timer > 0.0:
		hesitation_factor = 0.45
	
	var effective_speed = move_speed_x * diff_speed_scale * (sprint_scale if (is_drop or is_chance_ball) else 1.0) * hesitation_factor
	
	if abs(diff_x) > 8.0:
		velocity.x = sign(diff_x) * effective_speed
		
		# AI bay người cứu cầu (Diving Save) khi bóng rơi sát lưới và thấp:
		if not is_diving and not is_getting_up and is_on_ground() and ai_difficulty >= 1 and stats and stats.stamina > 25.0:
			var dist_to_target = abs(diff_x)
			var is_desperate_reach = dist_to_target > 120.0 and dist_to_target < 260.0
			var is_low_danger_ball = s_pos.y > 440.0 and shuttlecock.velocity.y > 0.0
			# AI chỉ bay người về phía lưới (diff_x < 0):
			if diff_x < 0.0 and is_desperate_reach and is_low_danger_ball and randf() < (0.60 if ai_difficulty == 2 else 0.30):
				start_dive(-1.0)
	else:
		velocity.x = 0.0
	
	# 4. AI CHỦ ĐỘNG BẬT NHẢY SMASH (JUMP SMASH INTERCEPTION)
	# Không nhảy nếu AI phán đoán cầu bay Out!
	# Và KIỂM TRA THỂ LỰC & ACCURACY:
	# AI KHÓ (Hard): Bậc thầy kiểm soát thể lực, nếu Stamina < 48% thì tuyệt đối dừng nhảy đập phông thường
	# để bảo toàn thể lực trong các pha cầu bền bỉ, chỉ bật nhảy khi có cơ hội cầu non (Chance Ball)!
	var is_exhausted = stats and (stats.stamina < (48.0 if ai_difficulty == 2 else 25.0) or stats.accuracy < 35.0)
	if is_on_ground() and can_hit and not ai_judges_out and not is_exhausted and not shuttlecock.is_smash and not shuttlecock.is_boom_smash and not shuttlecock.is_kill_smash:
		var is_chance_ball_drop = (shuttlecock.is_weak_return or shuttlecock.current_shot_type == "weak_return")
		var is_high_clear = (shuttlecock.current_shot_type == "clear" or shuttlecock.current_shot_type == "underhand_lift")
		var dist_x_shuttle = abs(global_position.x - s_pos.x)
		
		if is_chance_ball_drop:
			# ĐÓN BẬT NHẢY DỨT ĐIỂM CẦU NON (CHANCE BALL JUMP SMASH):
			# AI phải đã tới sát vị trí đón đầu giữa sân (cách target_x <= 16px) và cầu đã tới cự ly chuẩn ngang (dist_x <= 55px)
			# và quả cầu đang rơi xuống trong tầm với bật nhảy chuẩn (Y từ 210 đến 330, vận tốc Y đi xuống)
			var is_near_intercept_spot = abs(global_position.x - target_x) <= 16.0
			var is_aligned_x = dist_x_shuttle <= 55.0 and is_near_intercept_spot
			var is_dropping_in_overhead = (s_pos.y >= 210.0 and s_pos.y <= 330.0 and shuttlecock.velocity.y > 0.0)
			
			if is_aligned_x and is_dropping_in_overhead:
				var jump_chance = 0.98 if ai_difficulty >= 1 else 0.80
				if randf() < jump_chance:
					velocity.y = JUMP_FORCE
					jump_taken.emit(Vector2(global_position.x, current_ground_y), facing)
					if stats:
						stats.consume_stamina_action(5.0)
		elif is_high_clear and ai_difficulty > 0:
			# ĐÓN BẬT NHẢY ĐẬP PHÔNG CẦU CAO SÂU (CLEAR / LIFT JUMP SMASH):
			# AI Hard chỉ nhảy nếu thể lực dồi dào (> 52%)
			var ai_stamina_ok = (stats.stamina >= 52.0) if (ai_difficulty == 2 and stats) else true
			var is_close_x = dist_x_shuttle <= 75.0
			var is_in_range_x = (s_pos.x > 760.0 and s_pos.x < 1120.0)
			var is_dropping_overhead = (s_pos.y >= 190.0 and s_pos.y <= 320.0 and shuttlecock.velocity.y > 0.0)
			
			if ai_stamina_ok and is_close_x and is_in_range_x and is_dropping_overhead:
				var jump_chance = 0.88 if ai_difficulty == 2 else 0.50
				if randf() < jump_chance:
					velocity.y = JUMP_FORCE
					jump_taken.emit(Vector2(global_position.x, current_ground_y), facing)
					if stats:
						stats.consume_stamina_action(5.0)
	
	# 5. AI KIỂM TRA ĐÁNH CẦU & CHỌN ĐÒN ĐÁNH CHIẾN THUẬT (SMART SHOT SELECTION)
	var hit_status = get_hit_status()
	if hit_status["can_hit"] and can_hit:
		if swing_cooldown > 0.0:
			return
		
		# NẾU AI PHÁN ĐOÁN CẦU OUT: BỎ CẦU ĐỂ ĂN ĐIỂM! TUYỆT ĐỐI KHÔNG VUNG VỢT!
		if ai_judges_out:
			return
		
		# Với dropshot: AI TB không bị hụt ngớ ngẩn (chỉ hụt 4%), lunge vớt cầu lên
		if is_drop:
			var drop_fail_chance = 0.28 if ai_difficulty == 0 else 0.04
			if randf() < drop_fail_chance:
				return
			
		var opp_x = opponent_player.global_position.x if opponent_player else 360.0
		var opp_balance = opponent_player.balance if opponent_player else 100.0
		var opp_is_vulnerable = (opp_balance < 65.0) or (opponent_player and (opponent_player.is_getting_up or opponent_player.is_diving))
		var player_is_back = (opp_x < 390.0)
		var player_is_front = (opp_x > 470.0)
		var player_is_mid = (opp_x >= 390.0 and opp_x <= 470.0)
		var in_air = not is_on_ground()
		var zone = hit_status["zone"]
		var s_h = current_ground_y - s_pos.y
		var is_incoming_smash = shuttlecock and (shuttlecock.is_smash or shuttlecock.is_boom_smash or shuttlecock.is_kill_smash or shuttlecock.current_shot_type == "kill_smash")
		
		# ==========================================================
		# ĐỐI THỦ ĐẬP CẦU: AI PHÒNG THỦ & CÂN BẰNG TỈ LỆ ĐỠ ĐẬP
		# ==========================================================
		if is_incoming_smash:
			# NẾU LÀ THE WALL VÀ ĐẦY FLOW: KÍCH HOẠT TUYỆT KỸ ẢO ẢNH PHẢN ĐÒN (MIRAGE COUNTER)!
			if stats and (stats.character_id == "wall" or stats.special_skill_id == "mirage_counter") and stats.can_use_special():
				stats.prime_special()
				_execute_hit("mirage_counter", hit_status)
				return
				
			var is_boom = shuttlecock.is_boom_smash
			var is_kill = shuttlecock.is_kill_smash or (shuttlecock.current_shot_type == "kill_smash")
			if ai_pressure_model:
				ai_pressure_model.on_opponent_smash(is_boom)
			
			# TỈ LỆ THẤT BẠI KHI ĐỠ SMASH CỦA CÁC CẤP ĐỘ AI:
			var smash_fail_chance = 0.0
			if is_kill:
				# KILL SMASH (DỨT ĐIỂM CẦU NON): Tỉ lệ ăn điểm áp đảo (62% - 88%)!
				if ai_difficulty == 0:
					smash_fail_chance = 0.88
				elif ai_difficulty == 1:
					smash_fail_chance = 0.76
				else:
					smash_fail_chance = 0.62
			elif ai_difficulty == 0:
				# AI DỄ: Nếu đập thường trúng tầm đứng, AI có thể đỡ được ~55% (thất bại 45%).
				# Nếu là Boom Smash cực mạnh: AI Dễ hụt 80%!
				smash_fail_chance = 0.80 if is_boom else 0.45
			elif ai_difficulty == 1:
				# AI TRUNG BÌNH: Cân bằng để player có thể ghi điểm bằng quả đập!
				# Boom Smash xé gió: AI TB thất bại 52%!
				# Smash thường: AI TB thất bại 30% (nhất là khi cầu cắm góc xa hoặc AI đang di chuyển)!
				var dist_from_ai = abs(global_position.x - s_pos.x)
				var pos_penalty = 0.16 if dist_from_ai > 55.0 else 0.0
				var press_penalty = (ai_pressure_model.pressure * 0.18) if ai_pressure_model else 0.0
				smash_fail_chance = (0.52 if is_boom else 0.30) + pos_penalty + press_penalty
			else:
				# AI KHÓ: Chỉ hụt 15% trước Boom Smash
				var press_penalty = (ai_pressure_model.pressure * 0.10) if ai_pressure_model else 0.0
				smash_fail_chance = (0.15 if is_boom else 0.04) + press_penalty
			
			if randf() < smash_fail_chance:
				# AI phản xạ không kịp quả đập dốc sấm sét -> ĐÁNH HỤT SMASH! Player ghi điểm!
				return
			
			# NẾU MAY MẮN ĐỠ ĐƯỢC CÚ KILL SMASH -> LẬT KÈO THẦN SẦU!
			if is_kill:
				# AI phản xạ kỳ tích: Hất bổng sâu vút về góc xa sau lưng Player (LẬT KÈO)!
				# Bên đập vừa lao lên sát lưới dứt điểm bị vặn sườn nặng nề:
				if opponent_player:
					opponent_player.balance = max(25.0, opponent_player.balance - 30.0)
				_execute_counter_turnaround_hit(hit_status)
				return
			
			# AI đỡ thành công: Nhưng CHỈ KHI ACCURACY < 50% mới có tỉ lệ bung cầu non bổng (Weak Return / Chance Ball)!
			var ai_acc = stats.accuracy if stats else 100.0
			if ai_acc < 50.0 and ai_pressure_model and ai_pressure_model.should_pop_weak_return(ai_difficulty, ai_acc):
				_execute_hit("weak_return", hit_status)
				return
			
			if s_pos.x < 780.0 or player_is_back or opp_is_camping_back:
				# Chặn kê cầu bỏ nhỏ sát lưới ép đối thủ sân sau phải chạy lên
				_execute_hit("drop", hit_status)
			else:
				# Bung cầu cao sâu về đáy sân để cứu thua và thoát thế ép
				_execute_hit("underhand_lift", hit_status)
			return
		
		# ==========================================================
		# KIỂM TRA LỖI RÚC LƯỚI KHI BỊ DỒN ÉP CỰC HẠN (CHỈ KHI ACCURACY < 50%)
		# CHỈ ĐẬP HỎNG RÚC LƯỚI NẾU AI ĐANG TRÊN KHÔNG CỐ SMASH!
		# TUYỆT ĐỐI KHÔNG RÚC LƯỚI KHI ĐỠ HOẶC BỎ NHỎ -> Biến thành bung cầu non (Chance Ball) cho người chơi
		# ==========================================================
		var ai_acc_fault = stats.accuracy if stats else 100.0
		if ai_acc_fault < 50.0 and ai_pressure_model and ai_pressure_model.should_net_fault(ai_difficulty, ai_acc_fault):
			if in_air and zone == "overhead":
				_execute_fault_smash_into_net(hit_status)
			else:
				_execute_hit("weak_return", hit_status)
			return
		
		# ==========================================================
		# ĐÁNH GIÁ CƠ HỘI ĐẬP CẦU (CHỈ KHI ĐỐI THỦ PHÔNG CẦU BỔNG SÂU CLEAR / LIFT HOẶC CHANCE BALL):
		# ==========================================================
		var is_chance_ball_incoming = (shuttlecock.is_weak_return or shuttlecock.current_shot_type == "weak_return")
		if is_chance_ball_incoming:
			# NẾU LÀ CẦU NON CHANCE BALL: AI chủ động đập dứt điểm hoặc bỏ nhỏ lừa người, KHÔNG kích hoạt khiên thủ Mirage Counter
			if is_exhausted:
				_execute_hit("drop" if randf() < 0.65 else "clear", hit_status)
				return
			var smash_chance = 1.0 if ai_difficulty == 2 else (0.92 if ai_difficulty == 1 else 0.82)
			if randf() < smash_chance:
				_execute_hit("smash", hit_status)
				return
			else:
				# Thi thoảng lừa bỏ nhỏ sát lưới
				_execute_hit("drop", hit_status)
				return
				
		var is_high_clear_lob = (shuttlecock.current_shot_type == "clear" or shuttlecock.current_shot_type == "underhand_lift")
		
		# CHIẾN THUẬT TIẾT KIỆM THỂ LỰC TRONG PHA CẦU DÀI:
		# Khi Stamina thấp, AI chủ động phông sâu cao vút (Clear / Lift) về cuối sân đối thủ,
		# buộc người chơi phải lùi xa, đồng thời kéo dài thời gian bay để AI kịp hồi phục thể lực (+9/s khi đứng yên/di chuyển chậm)
		if (ai_difficulty == 2 and stats and stats.stamina < 50.0) or (ai_difficulty == 1 and stats and stats.stamina < 35.0):
			if zone == "underhand":
				_execute_hit("underhand_lift", hit_status)
			else:
				_execute_hit("clear", hit_status)
			return
		
		# A. NẾU AI ĐANG TRÊN KHÔNG (CHỦ ĐỘNG NHẢY ĐẬP CẦU BỔNG):
		if in_air:
			if stats and stats.can_use_special():
				if stats.character_id == "nishikawa":
					_execute_hit("smash", hit_status)
					return
				elif stats.character_id == "fuji" and (player_is_back or opp_is_camping_back):
					_execute_hit("drop", hit_status)
					return
			if is_high_clear_lob and s_h >= 150.0:
				if is_exhausted:
					# Thể lực hoặc Accuracy cạn kiệt: Đánh Clear để hồi phục
					_execute_hit("clear", hit_status)
					return
				elif ai_difficulty == 2: # KHÓ:
					# Phán đoán chiến thuật đỉnh cao:
					# - Nếu người chơi mất thăng bằng hoặc đang dâng lên lưới: SMASH dứt điểm ngay!
					# - Nếu người chơi đang đứng chôn chân ở sân sau (player_is_back / opp_is_camping_back):
					#   AI Hard không đập thẳng vào người chơi mà chém bỏ nhỏ (Drop) sát lưới ép người chơi phải chạy 200px!
					if opp_is_vulnerable or player_is_front:
						_execute_hit("smash", hit_status)
					elif player_is_back or opp_is_camping_back:
						if randf() < 0.85:
							_execute_hit("drop", hit_status)
						else:
							_execute_hit("smash", hit_status)
					else:
						# Người chơi ở giữa sân: Phối hợp smash 65%, drop 35%
						_execute_hit("smash" if randf() < 0.65 else "drop", hit_status)
				elif ai_difficulty == 1: # TRUNG BÌNH:
					if opp_is_vulnerable or player_is_front:
						_execute_hit("smash" if randf() < 0.80 else "clear", hit_status)
					elif player_is_back or opp_is_camping_back:
						_execute_hit("drop" if randf() < 0.60 else "smash", hit_status)
					else:
						var r = randf()
						if r < 0.50:
							_execute_hit("smash", hit_status)
						elif r < 0.80:
							_execute_hit("clear", hit_status)
						else:
							_execute_hit("drop", hit_status)
				else: # DỄ:
					_execute_hit("clear" if randf() > 0.4 else "drop", hit_status)
			else:
				# Không phải cầu bổng để đập: Chỉ đánh Drop hoặc Clear
				_execute_hit("drop" if randf() < 0.45 else "clear", hit_status)
			return
		
		# B. NẾU AI ĐANG Ở DƯỚI ĐẤT:
		# TUYỆT ĐỐI KHÔNG DÙNG SMASH KHI ĐỨNG DƯỚI ĐẤT
		# Chỉ đánh Phông cầu (Clear), Bỏ nhỏ (Drop), hoặc Bung bổng (Lift):
		if zone == "overhead":
			if ai_difficulty == 2:
				# HARD AI: Điều hướng người chơi tối đa (Chạy 4 góc)
				if player_is_front:
					_execute_hit("clear", hit_status)
				elif player_is_back or opp_is_camping_back:
					_execute_hit("drop", hit_status)
				else:
					# Người chơi ở giữa sân: Luân phiên kéo dãn trước/sau
					if ai_last_shot_chosen == "drop":
						_execute_hit("clear", hit_status)
					else:
						_execute_hit("drop", hit_status)
			elif ai_difficulty == 1:
				if player_is_front:
					_execute_hit("clear", hit_status)
				elif player_is_back or opp_is_camping_back:
					_execute_hit("drop" if randf() < 0.75 else "clear", hit_status)
				else:
					_execute_hit("clear" if randf() < 0.60 else "drop", hit_status)
			else: # DỄ
				if player_is_front:
					_execute_hit("clear", hit_status)
				elif player_is_back:
					_execute_hit("drop", hit_status)
				else:
					_execute_hit("clear" if randf() < 0.65 else "drop", hit_status)
				
		elif zone == "underhand":
			# CẦU Ở TẦM THẤP (DƯỚI LƯỚI / TRƯỚC LƯỚI / VỚT CẦU):
			# ĐÂY LÀ ĐIỂM CỐT LÕI ĐỂ BẺ GÃY TRICK LỎ SPAM DROP!
			if ai_difficulty == 2:
				# HARD AI:
				if player_is_back or opp_is_camping_back or opp_consecutive_drops >= 2:
					# Người chơi đang đứng im sân sau: AI TUYỆT ĐỐI KHÔNG BUNG BỔNG (LIFT) VỀ TẬN CHÂN NGƯỜI CHƠI NỮA!
					# 95% AI thực hiện cú chém vớt bỏ nhỏ sát lưới (Drop) ép người chơi phải chạy 200px lên lưới!
					if randf() < 0.95:
						_execute_hit("drop", hit_status)
					else:
						_execute_hit("underhand_lift", hit_status)
				elif player_is_front:
					# Người chơi vừa lao lên lưới: Bung bổng sâu tận góc sân sau (Lift) để người chơi phải giật lùi!
					_execute_hit("underhand_lift", hit_status)
				else:
					# Người chơi ở giữa: Luân chuyển kéo dãn đội hình
					if ai_last_shot_chosen == "drop":
						_execute_hit("underhand_lift", hit_status)
					else:
						_execute_hit("drop", hit_status)
			elif ai_difficulty == 1:
				# MEDIUM AI:
				if player_is_back or opp_is_camping_back or opp_consecutive_drops >= 3:
					# 70% bỏ nhỏ sát lưới ép di chuyển, 30% bung bổng
					if randf() < 0.70:
						_execute_hit("drop", hit_status)
					else:
						_execute_hit("underhand_lift", hit_status)
				elif player_is_front:
					_execute_hit("underhand_lift", hit_status)
				else:
					_execute_hit("underhand_lift" if randf() < 0.60 else "drop", hit_status)
			else:
				# EASY AI: Giữ nguyên cơ chế cơ bản
				if s_pos.x < 780.0:
					if player_is_back:
						_execute_hit("drop", hit_status)
					else:
						_execute_hit("underhand_lift", hit_status)
				else:
					_execute_hit("underhand_lift", hit_status)
		else:
			_execute_hit("clear", hit_status)


# ==========================================================
# RECTANGULAR HITBOXES & DISTINCT GOLDEN PERFECT HITBOX
# Hitbox & Sweetspot co giãn linh hoạt theo Accuracy [100% -> 58%]
# ==========================================================

func get_hitbox_scale() -> float:
	if stats:
		return stats.get_hitbox_scale()
	return 1.0


func get_overhead_box_local() -> Rect2:
	var s = get_hitbox_scale()
	var base_w = 150.0
	var base_h = 111.0
	var base_x = -60.0 if facing > 0 else -90.0
	var base_y = -176.0
	var cx = base_x + base_w * 0.5
	var cy = base_y + base_h * 0.5
	var w = base_w * s
	var h = base_h * s
	return Rect2(cx - w * 0.5, cy - h * 0.5, w, h)


func get_overhead_perfect_box_local() -> Rect2:
	var s = get_hitbox_scale()
	var ctrl = stats.control if stats else 80.0
	var base_w = lerp(52.0, 72.0, (ctrl - 40.0) / 59.0)
	var base_h = lerp(36.0, 48.0, (ctrl - 40.0) / 59.0)
	var base_x = (10.0 - (base_w - 60.0) * 0.5) if facing > 0 else (-70.0 - (base_w - 60.0) * 0.5)
	var base_y = -170.0 - (base_h - 42.0) * 0.5
	var cx = base_x + base_w * 0.5
	var cy = base_y + base_h * 0.5
	var w = base_w * s
	var h = base_h * s
	return Rect2(cx - w * 0.5, cy - h * 0.5, w, h)


func get_underhand_box_local() -> Rect2:
	var s = get_hitbox_scale()
	var base_w = 105.0
	var base_h = 80.0
	var base_x = -20.0 if facing > 0 else -85.0
	var base_y = -70.0
	if is_sliding:
		# Khi trượt sàn (Slide Dive): Mở rộng tầm với vươn dài về trước 55px và rạp sát sàn
		base_w += 55.0
		base_h += 15.0
		base_x += (20.0 if facing > 0 else -75.0)
		base_y += 10.0
	var cx = base_x + base_w * 0.5
	var cy = base_y + base_h * 0.5
	var w = base_w * s
	var h = base_h * s
	return Rect2(cx - w * 0.5, cy - h * 0.5, w, h)


func get_underhand_perfect_box_local() -> Rect2:
	var s = get_hitbox_scale()
	var ctrl = stats.control if stats else 80.0
	var base_w = lerp(44.0, 62.0, (ctrl - 40.0) / 59.0)
	var base_h = lerp(38.0, 52.0, (ctrl - 40.0) / 59.0)
	var base_x = (15.0 - (base_w - 50.0) * 0.5) if facing > 0 else (-65.0 - (base_w - 50.0) * 0.5)
	var base_y = -52.0 - (base_h - 45.0) * 0.5
	if is_sliding:
		base_w += 35.0
		base_h += 10.0
		base_x += (20.0 if facing > 0 else -55.0)
		base_y += 8.0
	var cx = base_x + base_w * 0.5
	var cy = base_y + base_h * 0.5
	var w = base_w * s
	var h = base_h * s
	return Rect2(cx - w * 0.5, cy - h * 0.5, w, h)


func get_overhead_box_global() -> Rect2:
	var r = get_overhead_box_local()
	return Rect2(global_position + r.position, r.size)


func get_overhead_perfect_box_global() -> Rect2:
	var r = get_overhead_perfect_box_local()
	return Rect2(global_position + r.position, r.size)


func get_underhand_box_global() -> Rect2:
	var r = get_underhand_box_local()
	return Rect2(global_position + r.position, r.size)


func get_underhand_perfect_box_global() -> Rect2:
	var r = get_underhand_perfect_box_local()
	return Rect2(global_position + r.position, r.size)


func get_dive_rescue_box_local() -> Rect2:
	var s = get_hitbox_scale()
	var base_w = 165.0
	var base_h = 90.0
	var base_x = 25.0 if facing > 0 else -190.0
	var base_y = -75.0
	var cx = base_x + base_w * 0.5
	var cy = base_y + base_h * 0.5
	var w = base_w * s
	var h = base_h * s
	return Rect2(cx - w * 0.5, cy - h * 0.5, w, h)


func get_dive_rescue_perfect_box_local() -> Rect2:
	var s = get_hitbox_scale()
	var ctrl = stats.control if stats else 80.0
	var base_w = lerp(65.0, 85.0, (ctrl - 40.0) / 59.0)
	var base_h = lerp(45.0, 60.0, (ctrl - 40.0) / 59.0)
	var base_x = (90.0 - (base_w - 75.0) * 0.5) if facing > 0 else (-165.0 - (base_w - 75.0) * 0.5)
	var base_y = -60.0 - (base_h - 50.0) * 0.5
	var cx = base_x + base_w * 0.5
	var cy = base_y + base_h * 0.5
	var w = base_w * s
	var h = base_h * s
	return Rect2(cx - w * 0.5, cy - h * 0.5, w, h)


func get_dive_rescue_box_global() -> Rect2:
	var r = get_dive_rescue_box_local()
	return Rect2(global_position + r.position, r.size)


func get_dive_rescue_perfect_box_global() -> Rect2:
	var r = get_dive_rescue_perfect_box_local()
	return Rect2(global_position + r.position, r.size)


func get_hit_status() -> Dictionary:
	if not shuttlecock or not shuttlecock.is_active or not can_hit:
		return {"can_hit": false, "zone": "none", "quality": 0.0, "is_perfect": false}
	
	var is_air = not is_on_ground() and global_position.y < current_ground_y - 35.0
	var s_pt = shuttlecock.global_position
	
	# Mở rộng vùng kiểm tra 20px theo kích thước thực của quả cầu (đầu bần + lông vũ)
	# Ngay khi bất kỳ góc nào của quả cầu chạm vào mép hitbox là sáng lên và cho phép đánh ngay lập tức!
	const SHUTTLE_RADIUS: float = 20.0
	
	# 1. OVERHEAD BOX
	var ob_box = get_overhead_box_global()
	if ob_box.grow(SHUTTLE_RADIUS).has_point(s_pt):
		var perf_box = get_overhead_perfect_box_global()
		var is_perf = perf_box.grow(10.0).has_point(s_pt)
		var quality = 1.0 if is_perf else 0.75
		return {"can_hit": true, "zone": "overhead", "quality": quality, "is_perfect": is_perf}
	
	# 2. UNDERHAND / MID-BODY BOX:
	# Hoạt động cả khi đứng dưới sàn lẫn khi đang nhảy (tránh lỗi đánh hụt ngang ngực khi nhảy đón cầu)
	var ub_box = get_underhand_box_global()
	if ub_box.grow(SHUTTLE_RADIUS).has_point(s_pt):
		var perf_box = get_underhand_perfect_box_global()
		var is_perf = perf_box.grow(10.0).has_point(s_pt)
		var quality = 1.0 if is_perf else 0.80
		var zone_type = "overhead" if is_air else "underhand"
		return {"can_hit": true, "zone": zone_type, "quality": quality, "is_perfect": is_perf}
	
	# 3. DIVE RESCUE BOX (Khi đang bay người cứu cầu)
	if is_diving or is_sliding:
		var db_box = get_dive_rescue_box_global()
		if db_box.grow(SHUTTLE_RADIUS).has_point(s_pt):
			var perf_box = get_dive_rescue_perfect_box_global()
			var is_perf = perf_box.grow(12.0).has_point(s_pt)
			var quality = 1.0 if is_perf else 0.70
			return {"can_hit": true, "zone": "dive", "quality": quality, "is_perfect": is_perf}
	
	return {"can_hit": false, "zone": "none", "quality": 0.0, "is_perfect": false}


# ==========================================================
# DIVE RESCUE & SHOT EXECUTION
# ==========================================================

func _execute_dive_rescue(hit_status: Dictionary = {}) -> void:
	if hit_status.is_empty():
		hit_status = get_hit_status()
		
	can_hit = false
	if opponent_player:
		opponent_player.can_hit = true
	is_swinging = true
	swing_timer = 0.0
	swing_recovery = 0.0
	swing_cooldown = SWING_COOLDOWN_MAX
	
	var is_perfect = hit_status.get("is_perfect", false)
	var quality = hit_status.get("quality", 0.70)
	var cur_acc = stats.accuracy if stats else 100.0
	var cur_sta = stats.stamina if stats else 100.0
	if stats:
		stats.add_flow(20.0)
	
	# Đánh giá độ chuẩn xác cú bay người cứu cầu:
	# Cứu cầu luôn là bỏ nhỏ:
	# - Đúng vị trí + accuracy >= 50% -> Bỏ nhỏ sát mép lưới (drop)
	# - Thiếu chính xác (accuracy < 50%, hoặc kiệt sức sta < 15%) -> Cầu bay cao hơn lưới (weak_return) tạo cơ hội dứt điểm!
	var is_accurate = (is_perfect or quality >= 0.70) and (cur_acc >= 50.0) and (cur_sta >= 15.0)
	if not is_accurate and (cur_acc >= 50.0) and (cur_sta >= 15.0) and randf() < 0.75:
		is_accurate = true
		
	var from_2d = shuttlecock.global_position
	var actual_shot = ""
	var target_x = 0.0
	var err_offset_x = 0.0
	
	if is_accurate:
		# CÚ BỎ NHỎ SÁT MÉP LƯỚI (TIGHT NET DROP / HAIRPIN):
		actual_shot = "drop"
		target_x = 705.0 if facing > 0 else 575.0
	else:
		# THIẾU CHÍNH XÁC -> CẦU BAY CAO HƠN LƯỚI TẠO CƠ HỘI ĐỐI PHƯƠNG DỨT ĐIỂM (POP-UP / WEAK RETURN):
		actual_shot = "weak_return"
		target_x = 860.0 if facing > 0 else 420.0
		
	shuttlecock.last_hitter = court_side
	shuttlecock.launch_to_target_2d(from_2d, Vector2(target_x, current_ground_y), actual_shot, err_offset_x, is_accurate, false, current_tension_mult, current_tension_level)
	shot_hit.emit(actual_shot, false, quality, is_accurate, false, from_2d)
	
	if stats:
		stats.on_reset_shot()


func _execute_counter_turnaround_hit(hit_status: Dictionary = {}) -> void:
	# CÚ PHẢN ĐÒN LẬT KÈO (CLUTCH COUNTER TURNAROUND):
	# Khi may mắn đỡ trúng quả Kill Smash, hất vút quả cầu về góc xa sau lưng đối thủ!
	can_hit = false
	if opponent_player:
		opponent_player.can_hit = true
	is_swinging = true
	swing_timer = 0.0
	swing_recovery = 0.0
	swing_cooldown = SWING_COOLDOWN_MAX
	
	var from_2d = shuttlecock.global_position
	var target_x = 1105.0 if facing > 0 else 175.0 # Rơi tít góc sâu đáy sân đối thủ (an toàn trong vạch biên)
	shuttlecock.last_hitter = court_side
	shuttlecock.launch_to_target_2d(from_2d, Vector2(target_x, current_ground_y), "underhand_lift", 0.0, true, false, current_tension_mult, current_tension_level)
	shot_hit.emit("underhand_lift", false, 0.95, true, false, from_2d)
	if stats:
		stats.on_reset_shot()


func _execute_hit(shot_type: String, hit_status: Dictionary = {}) -> void:
	if hit_status.is_empty():
		hit_status = get_hit_status()
		
	# KHI ĐANG BAY NGƯỜI CỨU CẦU: LUÔN THỰC HIỆN CÚ CỨU CẦU BỎ NHỎ
	if is_diving or is_sliding:
		_execute_dive_rescue(hit_status)
		return
		
	if is_ai:
		ai_last_shot_chosen = shot_type
		
	var is_air = not is_on_ground() and global_position.y < current_ground_y - 25.0
	
	# NỘI TẠI NISHIKAWA (GOLDEN CANNON):
	# CHỈ KHI SMASH VÀ ĐẦY FLOW (Flow >= 100): Cưỡng ép cú đập thành PERFECT (Quality = 1.0),
	# chuyển thành cú đập Golden Smash (boom_smash) với cinematic sấm sét ngưng đọng thời gian!
	# Các cú đánh thường (Clear, Drop, Underhand Lift) vẫn thực hiện bình thường và KHÔNG tiêu hao Flow.
	var is_attempting_smash = (shot_type == "smash" or shot_type == "boom_smash" or shot_type == "kill_smash")
	var is_nishikawa_golden_smash = stats and (stats.character_id == "nishikawa" or stats.special_skill_id == "golden_smash") and stats.can_use_special() and is_attempting_smash
	if is_nishikawa_golden_smash:
		shot_type = "boom_smash"
		hit_status["is_perfect"] = true
		hit_status["quality"] = 1.0
	
	# NỘI TẠI THE WALL / AOI (MIRAGE COUNTER):
	# Khi đỡ cầu Smash hoặc Cầu Non (Chance Ball) lúc đầy Flow (Flow >= 100):
	# Cưỡng ép kích hoạt tuyệt kỹ Mirage Counter (dù bấm Smash, Drop hay Clear)!
	var is_incoming_smash = shuttlecock and (shuttlecock.is_smash or shuttlecock.is_boom_smash or shuttlecock.is_kill_smash or shuttlecock.current_shot_type == "kill_smash")
	var is_incoming_chance = shuttlecock and (shuttlecock.is_weak_return or shuttlecock.current_shot_type == "weak_return")
	var is_wall_auto_counter = is_incoming_smash and stats and (stats.character_id == "wall" or stats.special_skill_id == "mirage_counter") and stats.can_use_special()
	if is_wall_auto_counter:
		shot_type = "mirage_counter"
	
	# AI TUYỆT ĐỐI BỊ CẤM SMASH KHI Ở DƯỚI ĐẤT HOẶC KHI CẦU ĐẾN KHÔNG PHẢI PHÔNG BỔNG (TRỪ KHI LÀ CẦU NON CHANCE BALL HOẶC NISHIKAWA ĐẦY FLOW):
	var is_chance_ball = shuttlecock and (shuttlecock.is_weak_return or shuttlecock.current_shot_type == "weak_return")
	if not is_nishikawa_golden_smash and is_ai and (shot_type == "smash" or shot_type == "boom_smash"):
		var is_clear_lift = (shuttlecock.current_shot_type == "clear" or shuttlecock.current_shot_type == "underhand_lift")
		if not is_chance_ball and (not is_air or not is_clear_lift):
			shot_type = "clear"
			
	# Loại bỏ toàn bộ các cú drive gây nhầm lẫn:
	if shot_type == "drive":
		shot_type = "clear"
	
	# RÀNG BUỘC SMASH TUYỆT ĐỐI (KỂ CẢ PLAYER VÀ AI, TRỪ KHI NISHIKAWA KÍCH HOẠT ĐẶC QUYỀN FLOW SMASH):
	if not is_nishikawa_golden_smash and (shot_type == "smash" or shot_type == "boom_smash" or shot_type == "kill_smash"):
		var s_h = current_ground_y - shuttlecock.global_position.y
		var is_valid_smash = is_chance_ball or (is_air and s_h >= 120.0) or (s_h >= 130.0)
		if not is_valid_smash or (not is_chance_ball and (shuttlecock.is_smash or shuttlecock.is_boom_smash or shuttlecock.is_kill_smash)):
			# Không đủ điều kiện đập (cầu thường / cầu thấp / phản smash): ĐẬP VÀO LƯỚI!
			_execute_fault_smash_into_net(hit_status)
			return
			
	can_hit = false
	if opponent_player:
		opponent_player.can_hit = true
	is_swinging = true
	swing_timer = 0.0
	swing_recovery = 0.0
	swing_cooldown = SWING_COOLDOWN_MAX
	
	var quality = 1.0 if is_nishikawa_golden_smash else hit_status.get("quality", 0.75)
	var is_perfect = true if is_nishikawa_golden_smash else hit_status.get("is_perfect", false)
	var is_underhand = (hit_status.get("zone", "") == "underhand")
	
	# ĐỠ CẦU SMASH: Đánh giá Timing tốt / xấu và tác động lên Accuracy & Balance:
	if is_incoming_smash:
		var is_kill = shuttlecock and (shuttlecock.is_kill_smash or shuttlecock.current_shot_type == "kill_smash")
		var is_nishikawa_attacker = opponent_player and opponent_player.stats and (opponent_player.stats.character_id == "nishikawa" or opponent_player.stats.special_skill_id == "golden_smash")
		if is_nishikawa_attacker:
			if shot_type == "mirage_counter":
				# ĐỠ BẰNG ISABEL BLOCK (MIRAGE COUNTER):
				# Chịu trừ 30% thể lực từ uy lực sấm sét của Nishikawa trước,
				# sau đó mới được hồi lại +20% thể lực từ khiên Mirage Shield!
				if stats:
					stats.consume_stamina_action(30.0)
			else:
				# CÚ ĐẬP LÔI ĐÌNH CỦA NISHIKAWA ĐÁNH TRÚNG NGƯỜI ĐỠ THƯỜNG:
				# Giảm 50% Accuracy và 30% Thể lực của người đỡ (chấn động cổ tay cực mạnh)!
				if stats:
					stats.consume_stamina_action(30.0)
					stats.accuracy = max(0.0, stats.accuracy - 50.0)
				balance = max(10.0, balance - 35.0)
		elif is_kill:
			if is_perfect or quality >= 0.85:
				# NẾU MAY MẮN / CĂN CHUẨN ĐỠ ĐƯỢC KILL SMASH: LẬT KÈO!
				# Bên đập vừa lao lên lưới bị trừng phạt thăng bằng nặng nề:
				if opponent_player:
					opponent_player.balance = max(25.0, opponent_player.balance - 30.0)
				balance = min(100.0, balance + 10.0)
			else:
				# Đỡ ẩu quả Kill Smash sấm sét: văng rúc lưới!
				_execute_fault_smash_into_net(hit_status)
				return
		elif is_perfect or quality >= 0.88:
			# TIMING TỐT: Clean block / absorption, hấp thụ lực tốt, không giảm accuracy
			balance = min(100.0, balance + 5.0)
		elif quality >= 0.65:
			# TIMING TRUNG BÌNH: Cổ tay chịu rung chấn, giảm nhẹ vừa phải Accuracy (không làm tụt quá nhanh sau 2-3 quả)
			if stats:
				var pen = randf_range(5.0, 9.0)
				stats.accuracy = max(5.0, stats.accuracy - pen)
				balance = max(35.0, balance - 15.0)
		else:
			# TIMING XẤU: Bị ép góc / chạm mép khung vợt -> Rung lắc nặng, Accuracy rơi tự do!
			if stats:
				var pen = randf_range(20.0, 30.0)
				stats.accuracy = max(0.0, stats.accuracy - pen)
				balance = max(15.0, balance - 32.0)
	
	if is_wall_auto_counter:
		shot_type = "mirage_counter"
	
	# ==========================================================
	# ĐỠ CÚ TSUBAME GAESHI CỦA FUJI (CÂN BẰNG NERF THEO YÊU CẦU):
	# - Đỡ không làm mất thể lực, chỉ làm mất balance và 10% accuracy.
	# - Đỡ bằng J/K bình thường (không phải trượt cứu cầu): chỉ có 30% tỉ lệ tạo chance ball
	#   (nếu chỉ số thể lực/accuracy đang yếu thì cộng dồn tỉ lệ này).
	# - Trượt cứu cầu: KHÔNG tạo chance ball (chỉ tạo chance ball khi chỉ số đang yếu).
	# ==========================================================
	var is_incoming_tsubame = not is_incoming_smash and shuttlecock and (shuttlecock.current_shot_type == "tsubame_gaeshi" or shuttlecock.is_tsubame_gaeshi)
	if is_incoming_tsubame and shot_type != "mirage_counter":
		if stats:
			stats.accuracy = max(5.0, stats.accuracy - 10.0)
		balance = max(20.0, balance - 25.0)
		
		var is_diving_or_sliding = is_diving or is_sliding
		if not is_diving_or_sliding:
			var weak_extra = 0.0
			if stats:
				var acc_p = clamp((50.0 - stats.accuracy) / 50.0, 0.0, 1.0) if stats.accuracy < 50.0 else 0.0
				var sta_p = clamp((35.0 - stats.stamina) / 35.0, 0.0, 1.0) if stats.stamina < 35.0 else 0.0
				weak_extra = (acc_p * 0.25) + (sta_p * 0.25)
			var chance_ball_rate = 0.30 + weak_extra
			if randf() < chance_ball_rate:
				shot_type = "weak_return"
		else:
			# Trượt cứu cầu: Chỉ tạo chance ball khi chỉ số đang yếu:
			var cur_acc = stats.accuracy if stats else 100.0
			var cur_sta = stats.stamina if stats else 100.0
			if cur_acc < 50.0 or cur_sta < 20.0:
				if randf() < 0.40:
					shot_type = "weak_return"
	
	# KIỂM TRA LỖI ĐÁNH HỎNG (UNFORCED BLUNDER) KHI ACCURACY < 50% HOẶC STAMINA < 35%:
	var blunder = "none"
	if stats and not is_perfect and not is_wall_auto_counter and not is_nishikawa_golden_smash and shot_type != "mirage_counter":
		blunder = stats.check_unforced_blunder(shot_type)
	
	if blunder == "whiff":
		# ĐÁNH HỤT: vung vợt trượt qua quả cầu!
		shot_whiffed.emit()
		return
	elif blunder == "net":
		# KHÔNG QUA LƯỚI: rúc lưới!
		_execute_fault_smash_into_net(hit_status)
		return
	var is_blunder_out = (blunder == "out")
	
	var from_2d = shuttlecock.global_position
	
	var aim_x_offset: float = 0.0
	if not is_ai:
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			aim_x_offset = 60.0
		elif Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			aim_x_offset = -60.0
	
	var actual_shot = shot_type
	var target_x: float = 0.0
	
	# OFF-BALANCE LUNGE & ACCURACY DEGRADATION -> WEAK RETURN (CẦU NON / CHANCE BALL):
	# CHỈ KHI ACCURACY < 50% MỚI CÓ TỈ LỆ NHỎ TĂNG DẦN BUNG CẦU NON (CHANCE BALL)
	var s_h = current_ground_y - from_2d.y
	var is_low_accuracy = (stats and stats.accuracy < 50.0)
	var is_off_balance = is_underhand and not is_perfect and abs(velocity.x) > 170.0 and s_h < 42.0 and is_low_accuracy
	var accuracy_pop_weak = false
	if stats and not is_perfect and not is_nishikawa_golden_smash and shot_type != "smash" and shot_type != "boom_smash" and shot_type != "mirage_counter":
		accuracy_pop_weak = stats.should_pop_weak_return(is_incoming_smash)
	
	if is_nishikawa_golden_smash or shot_type == "boom_smash":
		actual_shot = "boom_smash"
		var base_smash_x = 1040.0
		var final_smash_x = base_smash_x if facing > 0 else (1280.0 - base_smash_x)
		target_x = final_smash_x + facing * (aim_x_offset * 0.35)
		if facing > 0:
			target_x = clamp(target_x, 700.0, 1070.0)
		else:
			target_x = clamp(target_x, 210.0, 580.0)
		if stats:
			stats.consume_flow()
	elif is_off_balance or accuracy_pop_weak or shot_type == "weak_return":
		actual_shot = "weak_return"
		# Rơi nông ở khoảng giữa sân đối thủ để đối phương lao lên dứt điểm
		target_x = 880.0 if facing > 0 else 400.0
	elif shot_type == "drop":
		var is_fuji = stats and (stats.character_id == "fuji" or stats.special_skill_id == "tsubame_gaeshi")
		if is_fuji and stats.can_use_special():
			actual_shot = "tsubame_gaeshi"
			target_x = 705.0 if facing > 0 else 575.0
			if stats:
				stats.consume_flow()
				balance = min(100.0, balance + 15.0)
				stats.accuracy = min(100.0, stats.accuracy + 10.0)
		else:
			actual_shot = "drop"
			var net_x_val = tuning.net_x if tuning else 640.0
			var dist_to_net = abs(net_x_val - from_2d.x)
			var is_near = dist_to_net < 220.0
			
			if is_near:
				# VÊ CẦU SÁT LƯỚI:
				if facing > 0:
					# Player đánh sang sân AI (X > 640)
					target_x = 715.0 if is_perfect else 755.0
					target_x += aim_x_offset * 0.20
					target_x = max(target_x, net_x_val + 55.0)
				else:
					# AI đánh sang sân Player (X < 640)
					target_x = 565.0 if is_perfect else 525.0
					target_x -= aim_x_offset * 0.20
					target_x = min(target_x, net_x_val - 55.0)
			else:
				# BỎ NHỎ Ở XA:
				if is_perfect:
					var base_drop_x = 730.0 if facing > 0 else 550.0
					target_x = base_drop_x + facing * (aim_x_offset * 0.35)
					if facing > 0:
						target_x = max(target_x, net_x_val + 65.0)
					else:
						target_x = min(target_x, net_x_val - 65.0)
				else:
					var base_drop_x = 780.0 if facing > 0 else 500.0
					if dist_to_net > 330.0:
						base_drop_x += facing * 15.0
					target_x = base_drop_x + facing * (aim_x_offset * 0.35)
					if facing > 0:
						target_x = max(target_x, net_x_val + 75.0)
					else:
						target_x = min(target_x, net_x_val - 75.0)
	elif shot_type == "mirage_counter":
		actual_shot = "mirage_counter"
		# Bung sâu cao vút về đáy sân đối phương:
		target_x = 1110.0 if facing > 0 else 170.0
		if stats:
			# Hồi phục 20% thể lực và phục hồi độ chính xác:
			stats.stamina = min(stats.max_stamina_cap, stats.stamina + 20.0)
			stats.accuracy = min(100.0, stats.accuracy + 15.0)
			stats.consume_flow()
	elif shot_type == "smash":
		if is_chance_ball:
			# ĐẬP DỨT ĐIỂM CẦU NON (KILL SMASH):
			actual_shot = "kill_smash"
			var opp_pos_x = opponent_player.global_position.x if opponent_player else (920.0 if facing > 0 else 360.0)
			if facing > 0:
				# Player đập sang sân AI:
				if opp_pos_x < 920.0:
					target_x = 1045.0 + aim_x_offset * 0.3 # Bắn sâu góc xa đáy sân
				else:
					target_x = 770.0 + aim_x_offset * 0.3  # Cắm dốc gần lưới
			else:
				# AI đập sang sân Player:
				if opp_pos_x > 360.0:
					target_x = 235.0 - aim_x_offset * 0.3
				else:
					target_x = 510.0 - aim_x_offset * 0.3
		else:
			actual_shot = "smash"
			var base_smash_x = 1000.0 if is_air else 960.0
			var final_smash_x = base_smash_x if facing > 0 else (1280.0 - base_smash_x)
			target_x = final_smash_x + facing * (aim_x_offset * 0.35)
		
		# RÀNG BUỘC SMASH TUYỆT ĐỐI NẰM AN TOÀN TRONG SÂN (Cách vạch biên ít nhất 70px):
		if facing > 0:
			target_x = clamp(target_x, 700.0, 1070.0)
		else:
			target_x = clamp(target_x, 210.0, 580.0)
	elif shot_type == "drive":
		actual_shot = "drive"
		var base_drive_x = 1010.0 if facing > 0 else 270.0
		target_x = base_drive_x + facing * (aim_x_offset * 0.35)
		if facing > 0:
			target_x = clamp(target_x, 700.0, 1080.0)
		else:
			target_x = clamp(target_x, 200.0, 580.0)
	else: # shot_type == "clear" hoặc "underhand_lift"
		if is_underhand or shot_type == "underhand_lift":
			actual_shot = "underhand_lift"
			if is_incoming_smash and shuttlecock and (shuttlecock.is_kill_smash or shuttlecock.current_shot_type == "kill_smash"):
				# CÚ HẤT LẬT KÈO (CLUTCH COUNTER LIFT):
				# Hất vút sâu tít đáy sân đối thủ khiến bên vừa đập bị vặn sườn (an toàn trong biên)!
				target_x = 1105.0 if facing > 0 else 175.0
			elif is_perfect:
				# CÚ BUNG CẦU PERFECT: Sâu sát mép biên cuối sân, TUYỆT ĐỐI KHÔNG BAO GIỜ OUT!
				var base_lift_x = 1100.0 if facing > 0 else 180.0
				target_x = base_lift_x + facing * (aim_x_offset * 0.25)
				target_x = clamp(target_x, 700.0, 1115.0) if facing > 0 else clamp(target_x, 165.0, 580.0)
			elif quality >= 0.70:
				var base_lift_x = 1025.0 if facing > 0 else 255.0
				target_x = base_lift_x + facing * (aim_x_offset * 0.35)
			else:
				# TIMING CHƯA CHUẨN: Bung non lơ lửng giữa sân (Chance Ball cho đối thủ)
				var base_lift_x = 880.0 if facing > 0 else 400.0
				target_x = base_lift_x + facing * (aim_x_offset * 0.35)
		else:
			actual_shot = "clear"
			if is_perfect:
				# CÚ PHÔNG CẦU PERFECT: Bay sâu tít cuối sân, TUYỆT ĐỐI KHÔNG BAO GIỜ OUT!
				var base_clear_x = 1105.0 if facing > 0 else 175.0
				target_x = base_clear_x + facing * (aim_x_offset * 0.25)
				target_x = clamp(target_x, 700.0, 1115.0) if facing > 0 else clamp(target_x, 165.0, 580.0)
			elif quality >= 0.70:
				var base_clear_x = 1030.0 if facing > 0 else 250.0
				target_x = base_clear_x + facing * (aim_x_offset * 0.35)
			else:
				# TIMING CHƯA CHUẨN: Phông non giữa sân
				var base_clear_x = 890.0 if facing > 0 else 390.0
				target_x = base_clear_x + facing * (aim_x_offset * 0.35)
	
	# Dynamic Kinetic Smash Torque & Reset
	var is_smash_hit = (actual_shot == "smash" or actual_shot == "boom_smash" or actual_shot == "kill_smash")
	var is_chance_ball_smash = (actual_shot == "kill_smash")
	if is_smash_hit:
		if stats:
			stats.on_smash_executed(actual_shot == "boom_smash" or actual_shot == "kill_smash", is_chance_ball_smash)
		var rec_penalty = stats.get_recovery_delay_penalty() if stats else 0.0
		if is_chance_ball_smash:
			rec_penalty = 0.0 # Không bị trễ hồi chiêu khi dứt điểm cầu non
		swing_cooldown = SWING_COOLDOWN_MAX + rec_penalty
	else:
		if stats:
			stats.on_reset_shot()
		swing_cooldown = SWING_COOLDOWN_MAX
	
	# Multi-Factor Error Spread: Cầu chỉ có nguy cơ bay OUT khi hội tụ (Tension cao + Mất thăng bằng + Timing ẩu)
	var err_offset_x: float = 0.0
	var is_weak_smash = is_smash_hit and shuttlecock and (shuttlecock.is_weak_return or shuttlecock.current_shot_type == "weak_return")
	if is_perfect:
		err_offset_x = 0.0
	elif actual_shot != "weak_return" and not is_weak_smash:
		if stats:
			err_offset_x = stats.calculate_error_spread(quality, is_perfect, is_off_balance, current_tension_level)
		elif not is_perfect and quality < 0.70:
			if shot_type == "drop":
				err_offset_x = facing * ((1.0 - quality) * randf_range(10.0, 25.0))
			else:
				err_offset_x = -facing * (1.0 - quality) * 40.0
				
	# Xử lý sai số hoặc lỗi đánh bóng Out sân khi Accuracy < 50%:
	if is_blunder_out:
		target_x = 1175.0 if facing > 0 else 105.0
		err_offset_x = 0.0
	elif is_smash_hit:
		if facing > 0:
			err_offset_x = min(err_offset_x, 1075.0 - target_x)
		else:
			err_offset_x = max(err_offset_x, 205.0 - target_x)
	elif is_perfect:
		# ĐẢM BẢO TUYỆT ĐỐI CÚ ĐÁNH PERFECT KHÔNG BAO GIỜ VĂNG RA NGOÀI SÂN:
		err_offset_x = 0.0
		if facing > 0:
			target_x = clamp(target_x, 700.0, 1115.0)
		else:
			target_x = clamp(target_x, 165.0, 580.0)
	
	shuttlecock.last_hitter = court_side
	var is_any_smash = (actual_shot == "smash" or actual_shot == "boom_smash" or actual_shot == "kill_smash")
	var is_jump_smash_shot = (is_air or actual_shot == "kill_smash") and is_any_smash
	
	# Tích lũy Flow (Hưng Phấn / Nộ) (Không cộng nộ cho cú đánh vừa kích hoạt tiêu thụ Flow):
	var is_flow_special_shot = (actual_shot == "boom_smash" or actual_shot == "mirage_counter" or actual_shot == "tsubame_gaeshi")
	if stats and not is_flow_special_shot:
		if is_perfect:
			stats.add_flow(25.0)
		elif quality >= 0.75:
			stats.add_flow(10.0)
		else:
			stats.add_flow(5.0)
	
	# NGƯNG ĐỌNG TRONG SLOW-MO TẠI THỜI ĐIỂM TIẾP XÚC CẦU:
	# Áp dụng cho:
	# 1. Boom Smash (Nishikawa) khi đánh Perfect (1.0s slowmo sấm sét, trắng đen)
	# 2. Tsubame Gaeshi (Fuji) (0.48s slowmo gió lướt lá cây, không trắng đen)
	# 3. Mirage Counter (The Wall / Aoi) (1.55s slowmo khiên năng lượng, không trắng đen)
	var is_cinematic_slowmo = (actual_shot == "boom_smash" and is_perfect) or (actual_shot == "tsubame_gaeshi") or (actual_shot == "mirage_counter")
	if is_cinematic_slowmo:
		# SLOW-MO LÚC VỢT TIẾP XÚC CẦU:
		# Giữ quả cầu lơ lửng ngay trước mặt vợt, TUYỆT ĐỐI CHƯA PHÓNG CẦU ĐI!
		# Khi hết thời lượng slow-mo thì mới thực sự vung vợt/khiên phóng cầu bay qua lưới!
		shuttlecock.is_active = false
		shuttlecock.is_suspended_in_smash_slowmo = true
		shuttlecock.suspended_smash_pos = from_2d
		shuttlecock.global_position = from_2d
		shuttlecock.velocity = Vector2.ZERO
		
		pending_special_target = Vector2(target_x, current_ground_y)
		pending_special_shot = actual_shot
		pending_special_from = from_2d
		pending_special_err = err_offset_x
		pending_special_is_perfect = is_perfect
		pending_special_is_jump_smash = is_jump_smash_shot
		
		pending_smash_target = pending_special_target
		pending_smash_shot = pending_special_shot
		pending_smash_from = pending_special_from
		pending_smash_err = pending_special_err
		
		# Khởi động vung vợt từ từ tiến sát vào quả cầu
		is_swinging = true
		swing_timer = 0.02
		swing_recovery = 0.0
		
		shot_hit.emit(actual_shot, is_any_smash, quality, is_perfect, (is_air or actual_shot == "kill_smash"), from_2d)
		return
	
	shuttlecock.launch_to_target_2d(from_2d, Vector2(target_x, current_ground_y), actual_shot, err_offset_x, is_perfect, is_jump_smash_shot, current_tension_mult, current_tension_level)
	shot_hit.emit(actual_shot, is_any_smash, quality, is_perfect, is_air, from_2d)


func execute_pending_special() -> void:
	if pending_special_target != Vector2.ZERO and shuttlecock:
		shuttlecock.is_suspended_in_smash_slowmo = false
		shuttlecock.is_active = true
		shuttlecock.last_hitter = court_side
		shuttlecock.launch_to_target_2d(
			pending_special_from,
			pending_special_target,
			pending_special_shot,
			pending_special_err,
			pending_special_is_perfect,
			pending_special_is_jump_smash,
			current_tension_mult,
			current_tension_level
		)
		pending_special_target = Vector2.ZERO
		pending_smash_target = Vector2.ZERO


func execute_pending_smash() -> void:
	execute_pending_special()


func _execute_fault_smash_into_net(_hit_status: Dictionary = {}) -> void:
	can_hit = false
	if opponent_player:
		opponent_player.can_hit = true
	is_swinging = true
	swing_timer = 0.0
	swing_recovery = 0.0
	swing_cooldown = SWING_COOLDOWN_MAX
	
	var is_air = not is_on_ground() and global_position.y < current_ground_y - 25.0
	var from_2d = shuttlecock.global_position
	var net_x_val = tuning.net_x if tuning else 640.0
	
	# Đập cắm thẳng vào lưới đối phương:
	var target_net_x = net_x_val + facing * 12.0
	shuttlecock.last_hitter = court_side
	shuttlecock.launch_to_target_2d(from_2d, Vector2(target_net_x, current_ground_y), "smash", 0.0, false, false, current_tension_mult, current_tension_level)
	shot_hit.emit("smash", false, 0.25, false, is_air, from_2d)


# ==========================================================
# ARTICULATED GEOMETRIC CHARACTER RENDERING (SOLID BLOCKS)
# ==========================================================

func _draw() -> void:
	var hit_status = get_hit_status()
	var in_range = hit_status["can_hit"]
	var is_perfect = hit_status["is_perfect"]
	var is_in_air = not is_on_ground() and global_position.y < current_ground_y - 25.0
	
	# 1. Oval ground shadow
	draw_ellipse_shape(Vector2(0, 0), 32.0, 12.0, Color(0.05, 0.08, 0.12, 0.45))
	
	# Dual Athletic Gauges (Stamina & Accuracy) dưới chân:
	if stats:
		var time_val = Time.get_ticks_msec() / 1000.0
		var bar_w = 46.0
		var bar_h = 3.5
		var bar_x = -bar_w * 0.5
		
		# --- GAUGE 1: THỂ LỰC (STAMINA) ---
		var sta_y = 9.0
		draw_rect(Rect2(bar_x - 1.0, sta_y - 1.0, bar_w + 2.0, bar_h + 2.0), Color(0.06, 0.08, 0.12, 0.85), true)
		var cap_ratio = clamp(stats.max_stamina_cap / 100.0, 0.0, 1.0)
		var cap_w = bar_w * cap_ratio
		draw_rect(Rect2(bar_x, sta_y, bar_w, bar_h), Color(0.12, 0.14, 0.18, 0.70), true) # Khóa kiệt sức
		draw_rect(Rect2(bar_x, sta_y, cap_w, bar_h), Color(0.18, 0.22, 0.28, 0.85), true) # Có thể hồi
		
		var cur_sta_w = bar_w * clamp(stats.stamina / 100.0, 0.0, 1.0)
		var sta_col: Color
		if stats.is_stamina_critical():
			var pulse = 0.65 + 0.35 * sin(time_val * 14.0)
			sta_col = Color(1.0, 0.18, 0.18, pulse) # ĐỎ RỰC CẢNH BÁO
		else:
			sta_col = Color(0.22, 0.95, 0.45, 0.90) if not is_ai else Color(0.20, 0.85, 1.0, 0.90)
		if cur_sta_w > 0.0:
			draw_rect(Rect2(bar_x, sta_y, cur_sta_w, bar_h), sta_col, true)
		if cap_ratio < 0.98:
			draw_line(Vector2(bar_x + cap_w, sta_y - 1.0), Vector2(bar_x + cap_w, sta_y + bar_h + 1.0), Color(1.0, 0.85, 0.2, 0.95), 1.2, true)
			
		# --- GAUGE 2: ĐỘ CHÍNH XÁC (ACCURACY) ---
		var acc_y = 14.5
		draw_rect(Rect2(bar_x - 1.0, acc_y - 1.0, bar_w + 2.0, bar_h + 2.0), Color(0.06, 0.08, 0.12, 0.85), true)
		draw_rect(Rect2(bar_x, acc_y, bar_w, bar_h), Color(0.14, 0.16, 0.22, 0.75), true)
		
		var cur_acc_w = bar_w * clamp(stats.accuracy / 100.0, 0.0, 1.0)
		var acc_col: Color
		if stats.accuracy < 25.0:
			var pulse = 0.65 + 0.35 * sin(time_val * 16.0)
			acc_col = Color(1.0, 0.25, 0.35, pulse) # ĐỎ TÍA NGUY HIỂM CAO
		elif stats.accuracy < 50.0:
			acc_col = Color(1.0, 0.72, 0.20, 0.95) # VÀNG CAM CẢNH BÁO ĐÁNH HỎNG
		else:
			acc_col = Color(0.20, 0.88, 1.0, 0.90) # CYAN XANH LAM CHUẨN XÁC
			
		if cur_acc_w > 0.0:
			draw_rect(Rect2(bar_x, acc_y, cur_acc_w, bar_h), acc_col, true)
			
		# Vạch chia ngưỡng 50% nguy hiểm (Danger Threshold Mark)
		draw_line(Vector2(bar_x + bar_w * 0.5, acc_y - 1.0), Vector2(bar_x + bar_w * 0.5, acc_y + bar_h + 1.0), Color(0.85, 0.85, 0.9, 0.5), 1.0, true)
		
		# --- GAUGE 3: THANH FLOW / NỘ TUYỆT KỸ (MOMENTUM GAUGE) ---
		var flow_y = 20.0
		draw_rect(Rect2(bar_x - 1.0, flow_y - 1.0, bar_w + 2.0, bar_h + 2.0), Color(0.06, 0.08, 0.12, 0.85), true)
		draw_rect(Rect2(bar_x, flow_y, bar_w, bar_h), Color(0.12, 0.14, 0.20, 0.75), true)
		
		var cur_flow_w = bar_w * clamp(stats.flow / 100.0, 0.0, 1.0)
		var flow_col: Color
		if stats.can_use_special():
			var pulse = 0.75 + 0.25 * sin(time_val * 16.0)
			flow_col = Color(1.0, 0.90, 0.25, pulse) # VÀNG KIM TỰ KÍCH HOẠT KHI TUNG ĐÒN
		else:
			flow_col = Color(0.75, 0.30, 0.90, 0.85) # TÍM NỘ KHÍ TÍCH LŨY
			
		if cur_flow_w > 0.0:
			draw_rect(Rect2(bar_x, flow_y, cur_flow_w, bar_h), flow_col, true)
			
		# Báo hiệu Sẵn sàng Tuyệt kỹ Nộ khí:
		if stats.can_use_special():
			draw_arc(Vector2(0, -60), 40.0, 0, TAU, 24, Color(1.0, 0.85, 0.2, 0.55), 1.8, true)
	
	# 2. HÌNH HỘP VUÔNG VẮN HITBOX & VÙNG PERFECT RÕ RÀNG (CO GIÃN THEO ACCURACY)
	var ob_in = in_range and hit_status["zone"] == "overhead"
	var ob_rect = get_overhead_box_local()
	var ob_col = Color(1.0, 0.9, 0.2, 0.65) if ob_in else Color(0.2, 0.9, 0.4, 0.22)
	var ob_fill = Color(1.0, 0.9, 0.2, 0.08) if ob_in else Color(0.2, 0.9, 0.4, 0.02)
	draw_rect(ob_rect, ob_fill)
	draw_rect(ob_rect, ob_col, false, 1.2 if not ob_in else 1.8)
	
	# VÙNG ĐIỂM NGỌT PERFECT (HOÀN HẢO TRÊN CAO)
	var sw_rect = get_overhead_perfect_box_local()
	var sw_is_hot = ob_in and is_perfect
	var sw_col = Color(3.8, 2.8, 0.4, 1.0) if sw_is_hot else Color(1.0, 0.85, 0.2, 0.55)
	var sw_fill = Color(1.0, 0.85, 0.2, 0.35) if sw_is_hot else Color(1.0, 0.85, 0.2, 0.06)
	draw_rect(sw_rect, sw_fill)
	draw_rect(sw_rect, sw_col, false, 2.5 if sw_is_hot else 1.5)
	
	var b_len = min(12.0, sw_rect.size.x * 0.25)
	var sw_x = sw_rect.position.x
	var sw_y = sw_rect.position.y
	var sw_w = sw_rect.size.x
	var sw_h = sw_rect.size.y
	draw_line(Vector2(sw_x, sw_y), Vector2(sw_x + b_len, sw_y), sw_col, 2.5, true)
	draw_line(Vector2(sw_x, sw_y), Vector2(sw_x, sw_y + b_len), sw_col, 2.5, true)
	draw_line(Vector2(sw_x + sw_w, sw_y), Vector2(sw_x + sw_w - b_len, sw_y), sw_col, 2.5, true)
	draw_line(Vector2(sw_x + sw_w, sw_y), Vector2(sw_x + sw_w, sw_y + b_len), sw_col, 2.5, true)
	draw_line(Vector2(sw_x, sw_y + sw_h), Vector2(sw_x + b_len, sw_y + sw_h), sw_col, 2.5, true)
	draw_line(Vector2(sw_x, sw_y + sw_h), Vector2(sw_x, sw_y + sw_h - b_len), sw_col, 2.5, true)
	draw_line(Vector2(sw_x + sw_w, sw_y + sw_h), Vector2(sw_x + sw_w - b_len, sw_y + sw_h), sw_col, 2.5, true)
	draw_line(Vector2(sw_x + sw_w, sw_y + sw_h), Vector2(sw_x + sw_w, sw_y + sw_h - b_len), sw_col, 2.5, true)
	
	if not is_in_air:
		var ub_in = in_range and hit_status["zone"] == "underhand"
		var ub_rect = get_underhand_box_local()
		var ub_col = Color(0.2, 1.0, 1.0, 0.65) if ub_in else Color(0.2, 0.85, 1.0, 0.20)
		var ub_fill = Color(0.2, 1.0, 1.0, 0.08) if ub_in else Color(0.2, 0.85, 1.0, 0.02)
		draw_rect(ub_rect, ub_fill)
		draw_rect(ub_rect, ub_col, false, 1.2 if not ub_in else 1.8)
		
		var ub_sw_rect = get_underhand_perfect_box_local()
		var ub_is_hot = ub_in and is_perfect
		var ub_sw_col = Color(0.3, 3.0, 2.5, 1.0) if ub_is_hot else Color(0.2, 0.9, 1.0, 0.50)
		var ub_sw_fill = Color(0.2, 0.9, 1.0, 0.35) if ub_is_hot else Color(0.2, 0.9, 1.0, 0.06)
		draw_rect(ub_sw_rect, ub_sw_fill)
		draw_rect(ub_sw_rect, ub_sw_col, false, 2.5 if ub_is_hot else 1.5)
	
	# HITBOX CỨU CẦU KHI BAY NGƯỜI (DIVE RESCUE HITBOX):
	if is_diving:
		var db_in = in_range and hit_status["zone"] == "dive"
		var db_rect = get_dive_rescue_box_local()
		var db_col = Color(0.2, 1.0, 1.0, 0.90) if db_in else Color(0.2, 0.85, 1.0, 0.45)
		var db_fill = Color(0.2, 1.0, 1.0, 0.20) if db_in else Color(0.2, 0.85, 1.0, 0.06)
		draw_rect(db_rect, db_fill)
		draw_rect(db_rect, db_col, false, 2.2 if db_in else 1.5)
		
		var db_sw_rect = get_dive_rescue_perfect_box_local()
		var db_is_hot = db_in and is_perfect
		var db_sw_col = Color(3.8, 2.8, 0.4, 1.0) if db_is_hot else Color(1.0, 0.85, 0.2, 0.70)
		var db_sw_fill = Color(1.0, 0.85, 0.2, 0.40) if db_is_hot else Color(1.0, 0.85, 0.2, 0.12)
		draw_rect(db_sw_rect, db_sw_fill)
		draw_rect(db_sw_rect, db_sw_col, false, 2.8 if db_is_hot else 1.8)
	
	# ==========================================================
	# 3. NHÂN VẬT KHỐI HÌNH HỌC VÀ KHỚP XOAY (ARTICULATED MANNEQUIN)
	# ==========================================================
	var time_val = Time.get_ticks_msec() / 1000.0
	var hip_y = -62.0
	if is_diving or is_sliding:
		hip_y = -30.0
	elif is_getting_up:
		var p_up = clamp(get_up_timer / max(get_up_duration, 0.01), 0.0, 1.0)
		hip_y = lerp(-30.0, -62.0, p_up)
	elif is_on_ground():
		if abs(velocity.x) > 10.0:
			hip_y += abs(sin(walk_phase * 2.0)) * 3.5
		else:
			hip_y += sin(time_val * 4.5) * 1.8
	else:
		hip_y = -64.0
	
	var hip_pos = Vector2(0, hip_y)
	var shoulder_offset = Vector2(sin(joint_torso), -cos(joint_torso)) * 44.0
	var shoulder_pos = hip_pos + shoulder_offset
	var head_pos = shoulder_pos + Vector2(sin(joint_torso), -cos(joint_torso)) * 18.0
	
	# Màu sắc vùng khuất phía sau (Back limbs depth shading)
	var col_skin_back = Color(col_skin.r * 0.72, col_skin.g * 0.72, col_skin.b * 0.78)
	var col_jersey_back = Color(col_jersey.r * 0.68, col_jersey.g * 0.68, col_jersey.b * 0.75)
	var col_shorts_back = Color(col_shorts.r * 0.70, col_shorts.g * 0.70, col_shorts.b * 0.75)
	var col_accent_back = Color(col_accent.r * 0.70, col_accent.g * 0.70, col_accent.b * 0.75)
	
	# Tính toán vị trí các khớp chân (Natural human biomechanics)
	var hip_l = hip_pos + Vector2(-facing * 4.0, 4.0)
	var hip_r = hip_pos + Vector2(facing * 4.0, 4.0)
	
	var knee_l = hip_l + Vector2(sin(joint_thigh_l), cos(joint_thigh_l)) * 28.0
	var calf_ang_l = joint_thigh_l - facing * joint_knee_flex_l
	var foot_l = knee_l + Vector2(sin(calf_ang_l), cos(calf_ang_l)) * 26.0
	
	var knee_r = hip_r + Vector2(sin(joint_thigh_r), cos(joint_thigh_r)) * 28.0
	var calf_ang_r = joint_thigh_r - facing * joint_knee_flex_r
	var foot_r = knee_r + Vector2(sin(calf_ang_r), cos(calf_ang_r)) * 26.0
	
	# LAYER 1: VÙNG KHUẤT PHÍA SAU (ĐẰNG SAU THÂN NGƯỜI)
	# -------------------------------------------------------------------------
	# 1. Chân sau (Back Leg)
	draw_tapered_limb(hip_l, knee_l, 7.0, 5.0, col_shorts_back) # Thigh
	draw_circle(knee_l, 5.0, col_shorts_back, true, -1.0, true)  # Knee Joint
	draw_tapered_limb(knee_l, foot_l, 4.6, 3.8, col_skin_back)   # Calf / Shin
	draw_capsule_segment(foot_l - Vector2(0, 5), foot_l, 3.8, Color(0.75, 0.75, 0.78)) # Sock
	_draw_shoe(foot_l, facing, col_accent_back)                 # Athletic Shoe
	
	# 2. Tay sau / Tay không cầm vợt (Off-Arm - Nằm hẳn ở phía sau thân)
	var shoulder_off = shoulder_pos + Vector2(-facing * 7.0, 2.0)
	var elbow_off = shoulder_off + Vector2(sin(joint_upper_off), cos(joint_upper_off)) * 21.0
	var hand_off = elbow_off + Vector2(sin(joint_fore_off), cos(joint_fore_off)) * 19.0
	draw_capsule_segment(shoulder_off, shoulder_off + (elbow_off - shoulder_off) * 0.45, 5.0, col_jersey_back) # Ống tay sau
	draw_tapered_limb(shoulder_off, elbow_off, 4.8, 4.0, col_skin_back) # Bicep sau
	draw_circle(elbow_off, 4.0, col_skin_back, true, -1.0, true)         # Khuỷu tay sau
	draw_tapered_limb(elbow_off, hand_off, 4.0, 3.6, col_skin_back)     # Cẳng tay sau
	draw_circle(hand_off, 4.2, col_skin_back, true, -1.0, true)          # Bàn tay sau
	
	# LAYER 2: THÂN NGƯỜI & ĐẦU (NẰM Ở GIỮA, ĐÈ LÊN TAY SAU VÀ CHÂN SAU)
	# -------------------------------------------------------------------------
	# Quần đùi (Pelvis block)
	var pelvis_pts = PackedVector2Array([
		hip_pos + Vector2(-10, -4),
		hip_pos + Vector2(10, -4),
		hip_pos + Vector2(11, 10),
		hip_pos + Vector2(-11, 10)
	])
	draw_colored_polygon(pelvis_pts, col_shorts)
	
	# Áo thi đấu (Torso Jersey Block)
	var torso_normal = Vector2(-facing * cos(joint_torso), -sin(joint_torso))
	var p_sh_r = shoulder_pos + torso_normal * 12.0
	var p_sh_l = shoulder_pos - torso_normal * 12.0
	var p_hip_r = hip_pos + torso_normal * 9.0
	var p_hip_l = hip_pos - torso_normal * 9.0
	var jersey_pts = PackedVector2Array([p_sh_l, p_sh_r, p_hip_r, p_hip_l])
	if facing < 0.0:
		jersey_pts.reverse()
	draw_colored_polygon(jersey_pts, col_jersey)
	draw_polyline(jersey_pts, Color(1.0, 1.0, 1.0, 0.3), 1.5, true)
	# Sọc thể thao áo
	draw_line(shoulder_pos, hip_pos, col_accent, 3.5, true)
	
	# Đầu & Tóc thể thao
	draw_capsule_segment(shoulder_pos, head_pos, 4.0, col_skin) # Cổ
	draw_circle(head_pos, 11.5, col_skin, true, -1.0, true)      # Khuôn mặt
	# Băng đô thể thao (Headband)
	draw_line(head_pos + Vector2(-10, -3), head_pos + Vector2(10, -3), col_accent, 4.0, true)
	# Tóc thể thao vuốt nhọn
	var hair_poly = PackedVector2Array([
		head_pos + Vector2(-facing * 11, -3),
		head_pos + Vector2(-facing * 15, -11),
		head_pos + Vector2(-facing * 8, -17),
		head_pos + Vector2(0, -16),
		head_pos + Vector2(facing * 8, -14),
		head_pos + Vector2(facing * 11, -3),
		head_pos + Vector2(0, -6)
	])
	if facing < 0.0:
		hair_poly.reverse()
	draw_colored_polygon(hair_poly, col_shorts)
	# Mắt nhìn tập trung
	draw_circle(head_pos + Vector2(facing * 6.5, -1.5), 2.2, Color(0.1, 0.12, 0.15), true, -1.0, true)
	
	# LAYER 3: VÙNG NỔI BẬT PHÍA TRƯỚC (ĐÈ LÊN THÂN NGƯỜI)
	# -------------------------------------------------------------------------
	# 1. Chân trước (Front Leg)
	draw_tapered_limb(hip_r, knee_r, 8.5, 6.0, col_shorts) # Thigh
	draw_circle(knee_r, 6.0, col_shorts, true, -1.0, true)  # Knee Joint
	draw_tapered_limb(knee_r, foot_r, 5.5, 4.2, col_skin)   # Muscular Calf / Shin
	draw_capsule_segment(foot_r - Vector2(0, 6), foot_r, 4.2, Color(0.95, 0.95, 0.95)) # White Sock
	_draw_shoe(foot_r, facing, col_accent)                 # Athletic Shoe
	
	# 2. Tay trước / Tay cầm vợt (Racket Arm - Nổi bật đè trước ngực và thân)
	var shoulder_racket = shoulder_pos + Vector2(facing * 6.0, 0.0)
	var elbow_racket = shoulder_racket + Vector2(sin(joint_upper_racket), cos(joint_upper_racket)) * 23.0
	var hand_racket = elbow_racket + Vector2(sin(joint_fore_racket), cos(joint_fore_racket)) * 21.0
	
	# Ống tay áo thi đấu phía trước
	draw_capsule_segment(shoulder_racket, shoulder_racket + (elbow_racket - shoulder_racket) * 0.45, 6.5, col_jersey)
	draw_tapered_limb(shoulder_racket, elbow_racket, 5.8, 5.0, col_skin) # Bắp tay vạm vỡ
	draw_circle(elbow_racket, 5.0, col_skin, true, -1.0, true)           # Khớp khuỷu tay
	draw_tapered_limb(elbow_racket, hand_racket, 5.0, 4.4, col_skin)     # Cẳng tay trước
	draw_circle(hand_racket, 5.2, col_skin, true, -1.0, true)            # Bàn tay nắm vợt
	# Băng cổ tay nổi bật (Wristband)
	draw_line(hand_racket - (hand_racket - elbow_racket).normalized() * 5.0, hand_racket, col_accent, 5.0, true)
	
	# 3. Cây vợt cầu lông (Badminton Racket)
	# Vector hướng cán vợt: facing lật hướng X hoàn toàn đối xứng giữa Player và AI
	var racket_dir = Vector2(facing * cos(joint_racket_angle), sin(joint_racket_angle)).normalized()
	var grip_end = hand_racket - racket_dir * 8.0
	var shaft_end = hand_racket + racket_dir * 32.0
	var head_center = shaft_end + racket_dir * 18.0
	
	# Cán cầm vợt (Grip wrap)
	draw_line(grip_end, hand_racket + racket_dir * 4.0, Color(0.95, 0.95, 0.95), 4.5, true)
	# Thân đũa vợt (Carbon Shaft)
	draw_line(hand_racket + racket_dir * 4.0, shaft_end, Color(0.25, 0.3, 0.38), 3.0, true)
	# Khung mặt vợt (Isometric Oval Head)
	_draw_racket_head(head_center, racket_dir.angle(), col_racket)
	
	# 4. Vệt gió chém khi vung vợt (Wind Slash Effect)
	if is_swinging:
		var slash_p = swing_prog
		var slash_alpha = (1.0 - slash_p) * 0.85
		var slash_rad = 66.0
		var ang_start = -PI * 0.75 if facing > 0 else -PI * 0.25
		var ang_end = PI * 0.30 if facing > 0 else PI * 0.70
		draw_arc(shoulder_pos, slash_rad, min(ang_start, ang_end), max(ang_start, ang_end), 24, Color(1.0, 1.0, 1.0, slash_alpha), 3.5, true)
	
	# 5. Vệt gió bay người & bụi ma sát sàn khi bay người cứu cầu (Diving Speed Lines & Skid)
	if is_diving or is_sliding:
		var p_dive = clamp(dive_timer / max(dive_duration, 0.01), 0.0, 1.0)
		var dive_fade = 1.0 - p_dive
		# Vệt gió bay người xé không khí (Speed Lines):
		var trail_len = 50.0 * dive_fade
		var trail_start = hip_pos - Vector2(dive_dir * trail_len, 0.0)
		draw_line(trail_start, hip_pos, Color(1.0, 1.0, 1.0, 0.55 * dive_fade), 3.0, true)
		draw_line(trail_start - Vector2(0, 10), hip_pos - Vector2(0, 10), Color(0.2, 0.85, 1.0, 0.40 * dive_fade), 2.0, true)
		draw_line(trail_start + Vector2(0, 10), hip_pos + Vector2(0, 10), Color(0.2, 0.85, 1.0, 0.40 * dive_fade), 2.0, true)
		
		# Vệt ma sát sàn thi đấu khi tiếp thảm:
		var skid_fade = 1.0 - (slide_timer / max(slide_duration, 0.01))
		var skid_len = 45.0 * skid_fade
		var skid_start = Vector2(-slide_dir * skid_len, 0.0)
		var skid_end = Vector2(slide_dir * 16.0, 0.0)
		draw_line(skid_start, skid_end, Color(1.0, 1.0, 1.0, 0.45 * skid_fade), 4.0, true)
		draw_line(skid_start - Vector2(0, 2), skid_end - Vector2(0, 2), Color(0.9, 0.95, 1.0, 0.25 * skid_fade), 2.0, true)
		draw_circle(skid_start + Vector2(-slide_dir * 6.0, -2.0), 4.5 * skid_fade, Color(1.0, 1.0, 1.0, 0.35 * skid_fade))
		draw_circle(skid_start + Vector2(-slide_dir * 14.0, -5.0), 3.0 * skid_fade, Color(1.0, 1.0, 1.0, 0.25 * skid_fade))


func _draw_shoe(foot_pos: Vector2, dir: float, col: Color) -> void:
	var heel_top = foot_pos + Vector2(-dir * 6.0, -3.0)
	var instep = foot_pos + Vector2(dir * 2.0, -6.0)
	var toe_top = foot_pos + Vector2(dir * 12.0, -2.0)
	var toe_bot = foot_pos + Vector2(dir * 12.0, 2.5)
	var heel_bot = foot_pos + Vector2(-dir * 6.0, 2.5)
	var shoe_pts = PackedVector2Array([heel_top, instep, toe_top, toe_bot, heel_bot])
	if dir < 0.0:
		shoe_pts.reverse()
	draw_colored_polygon(shoe_pts, col)
	# Đế giày cao su chuyên dụng thi đấu (Gum sole)
	draw_line(heel_bot, toe_bot, Color(0.95, 0.8, 0.3), 2.5, true)


func _draw_racket_head(center: Vector2, angle: float, col: Color) -> void:
	var rx = 14.0
	var ry = 18.0
	var pts = PackedVector2Array()
	var segs = 24
	for i in range(segs):
		var a = (TAU / segs) * i
		var local_pt = Vector2(cos(a) * rx, sin(a) * ry)
		var rot_pt = local_pt.rotated(angle + PI * 0.5)
		pts.append(center + rot_pt)
	
	# Lưới cước đan (Cross strings)
	var norm_axis = Vector2(-sin(angle), cos(angle))
	var par_axis = Vector2(cos(angle), sin(angle))
	draw_line(center - norm_axis * 9.0, center + norm_axis * 9.0, Color(0.9, 0.95, 1.0, 0.65), 1.0, true)
	draw_line(center - par_axis * 12.0, center + par_axis * 12.0, Color(0.9, 0.95, 1.0, 0.65), 1.0, true)
	# Khung vành vợt
	draw_polyline(pts, col, 2.8, true)
	draw_line(pts[pts.size() - 1], pts[0], col, 2.8, true)


func draw_capsule_segment(p1: Vector2, p2: Vector2, radius: float, col: Color) -> void:
	draw_line(p1, p2, col, radius * 2.0, true)
	draw_circle(p1, radius, col, true, -1.0, true)
	draw_circle(p2, radius, col, true, -1.0, true)


func draw_tapered_limb(p1: Vector2, p2: Vector2, r1: float, r2: float, col: Color) -> void:
	var dir = (p2 - p1).normalized()
	var normal = Vector2(-dir.y, dir.x)
	var pts = PackedVector2Array([
		p1 + normal * r1,
		p2 + normal * r2,
		p2 - normal * r2,
		p1 - normal * r1
	])
	draw_colored_polygon(pts, col)
	draw_circle(p1, r1, col, true, -1.0, true)
	draw_circle(p2, r2, col, true, -1.0, true)


func draw_ellipse_shape(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	var segs = 20
	for i in range(segs):
		var ang = (TAU / segs) * i
		pts.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_colored_polygon(pts, col)
