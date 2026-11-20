class_name CharacterStats
extends Resource

# ==========================================================
# ATHLETIC STAMINA & KINETIC TORQUE MODEL (KHÔNG DÙNG HP)
# 4 Chỉ số cốt lõi thể thao chuyên nghiệp:
# - Power: Uy lực smash, vận tốc đỉnh cao
# - Agility: Tốc độ di chuyển, bộ pháp bứt tốc
# - Control: Cảm giác vợt, độ rộng Golden Sweet Spot
# - Composure: Bản lĩnh lì đòn, giảm hao mòn thể lực khi rally kéo dài
# ==========================================================

@export var character_name: String = "Player"
@export var character_id: String = "nishikawa"
@export var special_skill_id: String = "golden_smash"
@export var special_skill_name: String = "Nishikawa Golden Smash"

@export_range(40.0, 99.0, 1.0) var power: float = 85.0
@export_range(40.0, 99.0, 1.0) var agility: float = 80.0
@export_range(40.0, 99.0, 1.0) var control: float = 80.0
@export_range(40.0, 99.0, 1.0) var composure: float = 80.0

# Dynamic Kinetic Smash Torque (Lực bùng nổ khi smash)
var smash_torque: float = 1.0 # [0.5 -> 1.0]
var consecutive_smashes: int = 0

# Athletic Stamina & Rally Exhaustion Ceiling
var stamina: float = 100.0 # Thể lực hiện tại [0.0 -> 100.0]
var max_stamina_cap: float = 100.0 # Trần thể lực hồi tối đa (giảm dần khi pha cầu kéo dài)

# Athletic Accuracy & Shot Precision [0.0 -> 100.0]
# Liên kết chặt chẽ đa yếu tố: Thể lực (Stamina) + Thăng bằng (Balance) + Căng thẳng (Tension)
var accuracy: float = 100.0

# Flow / Momentum Gauge [0.0 -> 100.0] (Thanh Hưng Phấn / Nộ Kích Hoạt Tuyệt Kỹ)
var flow: float = 0.0
var is_special_primed: bool = false


func add_flow(amount: float) -> void:
	flow = clamp(flow + amount, 0.0, 100.0)


func can_use_special() -> bool:
	return flow >= 100.0


func prime_special() -> bool:
	if can_use_special():
		is_special_primed = true
		return true
	return false


func consume_flow() -> void:
	flow = 0.0
	is_special_primed = false


func reset_stamina() -> void:
	stamina = 100.0
	max_stamina_cap = 100.0
	accuracy = 100.0
	is_special_primed = false
	reset_torque()


func reset_torque() -> void:
	smash_torque = 1.0
	consecutive_smashes = 0


## Cập nhật thể lực theo thời gian thực (delta):
## - Di chuyển chạy: tiêu hao thể lực (-8.0/s)
## - Nhịp độ chậm / đứng yên: hồi chậm theo thời gian (+9.0/s) nhưng không vượt quá trần max_stamina_cap
## - Khi pha cầu giằng co kéo dài lâu: trần thể lực tối đa tự động giảm dần!
func update_stamina(delta: float, is_moving: bool, is_slow_tempo: bool, rally_time: float, rally_hits: int, stamina_efficiency: float = 1.0) -> void:
	# Trần thể lực tối đa co lại hợp lý theo độ dài pha cầu (Rally Drag Exhaustion):
	# Composure cao giúp duy trì trần thể lực tốt hơn
	var comp_factor = lerp(1.2, 0.70, (composure - 40.0) / 59.0)
	var drag_penalty = (float(rally_hits) * 0.85 + rally_time * 0.35) * comp_factor * stamina_efficiency
	max_stamina_cap = clamp(100.0 - drag_penalty, 42.0, 100.0)
	
	if is_moving:
		# Chạy di chuyển tiêu hao thể lực theo hiệu suất bộ pháp
		var drain_rate = 8.0 * (1.1 - (agility / 100.0) * 0.2) * stamina_efficiency
		stamina = max(0.0, stamina - delta * drain_rate)
	elif is_slow_tempo:
		# Nhịp độ êm dịu (Tension 0) / đứng thở: Hồi nhanh dần dần
		if stamina < max_stamina_cap:
			stamina = min(max_stamina_cap, stamina + delta * 11.0)
	else:
		# Nhịp độ dồn dập nhưng tạm dừng chân đứng vững: Hồi phục tốt
		if stamina < max_stamina_cap:
			stamina = min(max_stamina_cap, stamina + delta * 6.0)


## Tiêu hao thể lực theo hành động (Smash, Jump)
func consume_stamina_action(amount: float) -> void:
	stamina = max(0.0, stamina - amount)


## Tốc độ di chuyển bắt đầu giảm từ 50% thể lực (50% -> 25% giảm rất nhẹ, dưới 25% giảm rõ rệt, max 50%)
func get_speed_multiplier() -> float:
	if stamina >= 50.0:
		return 1.0
	elif stamina >= 25.0:
		# Từ 50% đến 25%: Giảm rất nhẹ từ 1.0 về 0.88 (chỉ giảm tối đa 12%)
		var p = (stamina - 25.0) / 25.0
		return lerp(0.88, 1.0, p)
	else:
		# Dưới 25%: Càng ít càng giảm rõ rệt, giảm max 50% tốc độ di chuyển (về 0.50 tại 0%)
		var p = clamp(stamina / 25.0, 0.0, 1.0)
		return lerp(0.50, 0.88, pow(p, 1.25))


func is_stamina_critical() -> bool:
	return stamina <= 25.0


## Khi thực hiện cú Smash: Tiêu hao thể lực và lực bùng nổ
func on_smash_executed(is_boom: bool = false, is_chance_ball: bool = false) -> void:
	if is_chance_ball:
		# ĐẬP DỨT ĐIỂM CẦU NON (CHANCE BALL / KILL SMASH):
		var drain_cb = 2.0 if character_id == "nishikawa" else 4.0
		consume_stamina_action(drain_cb)
		smash_torque = 1.0
		consecutive_smashes = 0
		return

	consecutive_smashes += 1
	if consecutive_smashes == 1:
		smash_torque = 1.0
	elif consecutive_smashes == 2:
		smash_torque = 0.94 if character_id == "nishikawa" else 0.84
	else:
		smash_torque = 0.88 if character_id == "nishikawa" else 0.70
	
	# Tiêu hao thể lực cho cú smash:
	# Nishikawa: đập thường 3.0, đập skill (Boom Smash) 6.0, dứt điểm 2.0
	# Nhân vật khác: đập thường 5.0, đập skill 7.0, dứt điểm 4.0
	var drain = 0.0
	if character_id == "nishikawa":
		drain = 6.0 if is_boom else 3.0
	else:
		drain = 7.0 if is_boom else 5.0
	consume_stamina_action(drain)


## Tiêu hao thể lực của người phòng thủ khi đỡ cú Smash (chống spam đập của Nishikawa):
## 1. Perfect block: -1.0 thể lực
## 2. Đỡ bình thường (trong hitbox, tư thế tốt, timing chuẩn): -2.0 thể lực
## 3. Đỡ lúc mất thế (mất cân bằng, chính xác thấp, thể lực yếu, khoảng cách gần, tốc độ cao): -2.0 đến -6.0 thể lực
func on_smash_defended(quality: float, is_perfect: bool, defender_balance: float = 100.0, smash_dist: float = 600.0, is_underhand: bool = false, shuttle_speed: float = 0.0) -> void:
	# 1. Perfect Block: Đỡ hoàn hảo tại đỉnh điểm, bảo toàn thể lực (-1.0 thể lực)
	if is_perfect or quality >= 0.95:
		consume_stamina_action(1.0)
		return
		
	# 2. Đánh giá mức độ bất lợi / mất thế (Vulnerability Factor: 0.0 -> 1.0):
	# - Mất cân bằng: balance < 65
	var v_balance = clamp((65.0 - defender_balance) / 55.0, 0.0, 1.0)
	# - Độ chính xác suy giảm: accuracy < 55
	var v_accuracy = clamp((55.0 - accuracy) / 45.0, 0.0, 1.0)
	# - Thể lực đang kiệt quệ: stamina < 40
	var v_stamina = clamp((40.0 - stamina) / 35.0, 0.0, 1.0)
	# - Timing với tay / chất lượng tiếp xúc: quality < 0.80
	var v_quality = clamp((0.80 - quality) / 0.40, 0.0, 1.0)
	# - Đập ở cự ly gần / sát lưới (smash_dist < 520px): phản xạ gắt hơn
	var v_dist = clamp((520.0 - smash_dist) / 280.0, 0.0, 1.0)
	# - Tiếp xúc thấp sát sàn (underhand dig)
	var v_underhand = 0.20 if is_underhand else 0.0
	# - Tốc độ cầu cao (nếu có truyền vào, > 1100 px/s)
	var v_speed = clamp((shuttle_speed - 1100.0) / 400.0, 0.0, 1.0) * 0.15 if shuttle_speed > 1100.0 else 0.0
	
	# Tổng hợp chỉ số mất thế:
	var vulnerability = clamp(
		v_balance * 0.25 +
		v_accuracy * 0.20 +
		v_stamina * 0.20 +
		v_quality * 0.20 +
		v_dist * 0.15 +
		v_underhand +
		v_speed,
		0.0, 1.0
	)
	
	# Đỡ bình thường: 2.0 thể lực | Mất thế: scale từ 2.0 đến 6.0 thể lực
	var drain = lerp(2.0, 6.0, vulnerability)
	consume_stamina_action(drain)


## Cơ chế "Kinetic Reset": 1 cú Drop êm ái hoặc Clear thả lỏng hồi 100% torque (nhưng TUYỆT ĐỐI không hồi thể lực khi đánh cầu!)
## Clear tiêu hao 3.0 thể lực, Drop tiêu hao 1.5 thể lực:
func on_reset_shot(shot_type: String = "clear") -> void:
	reset_torque()
	var drain = 1.5 if (shot_type == "drop" or shot_type == "tsubame_gaeshi") else 3.0
	consume_stamina_action(drain)


# ==========================================================
# ACCURACY & SHOT PRECISION MODEL
# ==========================================================

## 1. Hệ số Thể Lực (Stamina Factor): Thể lực tụt làm tay run, chân nặng
func get_stamina_accuracy_factor() -> float:
	if stamina >= 75.0:
		return 1.0
	elif stamina >= 50.0:
		# 50% - 75%: bắt đầu mỏi tay, accuracy giảm từ 100% về 78%
		return lerp(0.78, 1.0, (stamina - 50.0) / 25.0)
	elif stamina >= 25.0:
		# 25% - 50%: cơ bắp mỏi nhừ, accuracy giảm mạnh từ 78% về 48%
		return lerp(0.48, 0.78, (stamina - 25.0) / 25.0)
	else:
		# < 25% (Vùng kiệt sức đỏ): Tay run lắc, accuracy rơi tự do từ 48% về 18%
		return lerp(0.18, 0.48, stamina / 25.0)


## 2. Hệ số Thăng Bằng (Balance Factor): Nhoài người / cứu cầu sát sàn làm giảm độ ổn định
func get_balance_accuracy_factor(balance: float) -> float:
	return clamp(balance / 100.0, 0.35, 1.0)


## 3. Hệ số Căng Thẳng (Tension Factor): Áp lực tâm lý từ rally giằng co
func get_tension_accuracy_factor(tension_level: int) -> float:
	var comp_buff = lerp(0.85, 1.15, (composure - 40.0) / 59.0)
	var tension_penalty = 0.0
	if tension_level == 1:
		tension_penalty = 0.08
	elif tension_level == 2:
		tension_penalty = 0.18
	elif tension_level >= 3:
		tension_penalty = 0.28
	return clamp(1.0 - (tension_penalty / comp_buff), 0.55, 1.0)


## Cập nhật Accuracy mỗi frame
func update_accuracy(delta: float, balance: float, tension_level: int) -> void:
	var f_sta = get_stamina_accuracy_factor()
	var f_bal = get_balance_accuracy_factor(balance)
	var f_ten = get_tension_accuracy_factor(tension_level)
	
	# Chỉ số Control giúp giữ độ chính xác nền tảng tốt hơn
	var ctrl_bonus = lerp(0.92, 1.08, (control - 40.0) / 59.0)
	var target_acc = 100.0 * f_sta * f_bal * f_ten * ctrl_bonus
	
	# TRẦN KHỐNG CHẾ THEO THỂ LỰC (Stamina Accuracy Ceiling):
	# Khi thể lực cạn kiệt, trần Accuracy bị ghìm chặt, không thể duy trì độ chính xác cao được!
	var stamina_cap_acc = clamp(stamina * 1.25 + 18.0, 18.0, 100.0)
	target_acc = min(target_acc, stamina_cap_acc)
	target_acc = clamp(target_acc, 0.0, 100.0)
	
	# Tốc độ co/dãn của độ chính xác: tụt nhanh khi mất thăng bằng, hồi từ từ khi ổn định bộ pháp
	var rate = 45.0 if accuracy > target_acc else 28.0
	accuracy = move_toward(accuracy, target_acc, delta * rate)


## Co giãn Hitbox & Sweetspot theo Accuracy [100% -> 58%]
func get_hitbox_scale() -> float:
	return lerp(0.58, 1.0, clamp(accuracy / 100.0, 0.0, 1.0))


## Accuracy thấp hoặc Thể lực cạn kiệt hoặc Mất thăng bằng mới có tỉ lệ bung Cầu Non (Weak Return / Chance Ball)
func should_pop_weak_return(is_incoming_smash: bool, defender_balance: float = 100.0) -> bool:
	# Nếu người phòng thủ đang vững vàng (balance cao, accuracy cao, thể lực tốt): TUYỆT ĐỐI KHÔNG bung cầu non!
	if defender_balance >= 60.0 and accuracy >= 50.0 and stamina >= 35.0:
		return false
	var acc_p = clamp((50.0 - accuracy) / 50.0, 0.0, 1.0) if accuracy < 50.0 else 0.0
	var sta_p = clamp((30.0 - stamina) / 30.0, 0.0, 1.0) if stamina < 30.0 else 0.0
	var bal_p = clamp((50.0 - defender_balance) / 50.0, 0.0, 1.0) if defender_balance < 50.0 else 0.0
	var base_chance = (acc_p * 0.25) + (sta_p * 0.25) + (bal_p * 0.20)
	if is_incoming_smash:
		base_chance += 0.10
	return randf() < clamp(base_chance, 0.0, 0.55)


## Accuracy thấp (< 50%) hoặc Thể lực cạn kiệt (< 35%) sẽ tạo ra lỗi đánh hỏng (rúc lưới, out sân, đánh hụt)
func check_unforced_blunder(shot_type: String = "") -> String:
	# Cú bỏ nhỏ (drop) tuyệt đối không rúc lưới gây mất điểm lãng xẹt
	if shot_type == "drop" or shot_type == "tsubame_gaeshi" or shot_type == "mirage_counter":
		return "none"
		
	var is_smash_shot = (shot_type == "smash" or shot_type == "kill_smash" or shot_type == "boom_smash")
	# Chỉ kích hoạt nguy cơ đánh hỏng khi thể lực hoặc accuracy ở mức cạn kiệt nguy hiểm (< 25% accuracy hoặc < 18% thể lực)
	var acc_p = clamp((25.0 - accuracy) / 25.0, 0.0, 1.0) if accuracy < 25.0 else 0.0
	var sta_p = clamp((18.0 - stamina) / 18.0, 0.0, 1.0) if stamina < 18.0 else 0.0
	
	if acc_p <= 0.0 and sta_p <= 0.0:
		return "none"
	
	var err_chance = 0.0
	if is_smash_shot:
		err_chance = (acc_p * 0.20) + (sta_p * 0.18)
	else:
		err_chance = (acc_p * 0.12) + (sta_p * 0.10)
		
	if randf() > err_chance:
		return "none"
	
	var roll = randf()
	if roll < 0.12:
		return "net"   # Tỉ lệ rúc lưới cực thấp (12%), tránh cảm giác tự hủy ức chế
	elif roll < 0.75:
		return "out"   # Out sân (bay vọt qua biên)
	else:
		return "whiff" # Đánh mép khung vợt


## Hệ số nhân tốc độ smash dựa trên Torque và Thể lực hiện tại
func get_effective_smash_speed_mult() -> float:
	var power_bonus = lerp(0.92, 1.10, (power - 40.0) / 59.0)
	var stamina_mult = 1.0
	if stamina < 25.0:
		stamina_mult = lerp(0.40, 1.0, clamp(stamina / 25.0, 0.0, 1.0)) # Thể lực đỏ: smash xìu lực, chỉ còn 40% - 55% tốc độ
	return smash_torque * power_bonus * stamina_mult


## Thời gian trễ thu vợt (Recovery delay) tăng thêm khi bị Overheat
func get_recovery_delay_penalty() -> float:
	if smash_torque < 0.70:
		return 0.14
	elif smash_torque < 0.85:
		return 0.06
	return 0.0


## Tính toán sai số đa yếu tố (Multi-Factor Error Spread)
func calculate_error_spread(timing_quality: float, is_perfect: bool, is_off_balance: bool, tension_level: int) -> float:
	if is_perfect:
		return 0.0
	
	if tension_level == 0:
		return randf_range(-4.0, 4.0)
	
	var balance_factor = 2.2 if is_off_balance else 1.0
	var timing_factor = clamp(1.0 - timing_quality, 0.1, 0.6)
	var tension_factor = 1.6 if tension_level >= 2 else 1.0
	var control_factor = lerp(1.25, 0.75, (control - 40.0) / 59.0)
	
	var risk_score = balance_factor * timing_factor * tension_factor * control_factor
	
	if risk_score > 1.35:
		var dir = 1.0 if randf() < 0.5 else -1.0
		return dir * randf_range(12.0, 26.0)
	elif risk_score > 0.85:
		return randf_range(-8.0, 8.0)
		
	return randf_range(-4.0, 4.0)


# ==========================================================
# PRESET ARCHETYPES
# ==========================================================

static func create_default() -> Resource:
	var s = load("res://scripts/core/character_stats.gd").new()
	s.character_id = "default"
	s.character_name = "Player"
	s.special_skill_id = "power_smash"
	s.special_skill_name = "Power Smash"
	s.power = 85.0
	s.agility = 80.0
	s.control = 80.0
	s.composure = 80.0
	return s

static func create_nishikawa() -> Resource:
	var s = load("res://scripts/core/character_stats.gd").new()
	s.character_id = "nishikawa"
	s.character_name = "Nishikawa (Tia chớp vàng)"
	s.special_skill_id = "golden_smash"
	s.special_skill_name = "Golden Smash"
	s.power = 96.0
	s.agility = 78.0
	s.control = 75.0
	s.composure = 82.0
	return s

static func create_fuji() -> Resource:
	var s = load("res://scripts/core/character_stats.gd").new()
	s.character_id = "fuji"
	s.character_name = "Fuji (Cơn lốc xanh)"
	s.special_skill_id = "tsubame_gaeshi"
	s.special_skill_name = "Tsubame Gaeshi"
	s.power = 78.0
	s.agility = 86.0
	s.control = 96.0
	s.composure = 85.0
	return s

static func create_wall() -> Resource:
	var s = load("res://scripts/core/character_stats.gd").new()
	s.character_id = "wall"
	s.character_name = "Isabel (Nữ hoàng của đấu trường La Mã)"
	s.special_skill_id = "mirage_counter"
	s.special_skill_name = "Mirage Shield"
	s.power = 75.0
	s.agility = 88.0
	s.control = 84.0
	s.composure = 96.0
	return s

static func create_cannon() -> Resource:
	return create_nishikawa()

static func create_maestro() -> Resource:
	return create_fuji()
