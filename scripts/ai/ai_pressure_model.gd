class_name AIPressureModel
extends RefCounted

# ==========================================================
# AI PSYCHOLOGICAL PRESSURE & DECISION MODEL 2.0
# Giải pháp kết thúc rally tự nhiên & chân thực:
# 1. KHÔNG tự hủy ngẫu nhiên bắn cầu văng xa ra ngoài biên.
# 2. Khi bị dồn ép (Opponent Smash, rượt đuổi tốc độ cao, nhịp độ Climax):
#    - Tăng cơ hội bung Cầu Non (Weak Return / Chance Ball) ngay giữa sân cho người chơi smash dứt điểm!
#    - Thi thoảng kê lưới hỏng (rúc lưới) trong thế với người cực hạn.
# 3. Ngập ngừng đổi hướng (Wrong-foot hesitation) khi bị lừa đòn điều cầu.
# ==========================================================

var pressure: float = 0.0 # Thang đo áp lực tâm lý [0.0 -> 1.0]
var hesitation_timer: float = 0.0


func reset() -> void:
	pressure = 0.0
	hesitation_timer = 0.0


func update(delta: float) -> void:
	# Áp lực tự động phân rã êm ái khi nhịp độ chậm lại hoặc sau pha bóng
	if pressure > 0.0:
		pressure = max(0.0, pressure - delta * 0.18)
	if hesitation_timer > 0.0:
		hesitation_timer = max(0.0, hesitation_timer - delta)


## Tích lũy áp lực khi đối thủ tung cú Smash
func on_opponent_smash(is_boom: bool) -> void:
	var inc = 0.35 if is_boom else 0.22
	pressure = clamp(pressure + inc, 0.0, 1.0)


## Tích lũy áp lực khi phải bứt tốc đuổi bóng (Scramble run)
func on_scramble_run(delta: float) -> void:
	# Tăng dần theo thời gian nước rút
	pressure = clamp(pressure + delta * 0.25, 0.0, 1.0)


## Khi nhịp độ Rally Tension bước vào giai đoạn nóng (Momentum/Climax)
func on_tension_step(tension_level: int) -> void:
	if tension_level == 2:
		pressure = clamp(pressure + 0.15, 0.0, 1.0)
	elif tension_level == 1:
		pressure = clamp(pressure + 0.06, 0.0, 1.0)


## Hạ bớt áp lực khi có cú điều cầu êm dịu (Drop/Clear chậm)
func cool_down_pressure(amount: float = 0.12) -> void:
	pressure = max(0.0, pressure - amount)


## Kiểm tra cơ hội bung Cầu Non (Chance Ball) cho người chơi kết liễu
## CHỈ KHI ACCURACY < 50% MỚI CÓ THỂ MẮC LỖI BUNG CẦU NON
func should_pop_weak_return(difficulty: int, accuracy: float = 100.0) -> bool:
	if accuracy >= 50.0:
		return false
	if pressure < 0.35:
		return false
	
	var p = clamp((50.0 - accuracy) / 50.0, 0.0, 1.0)
	var base_chance = 0.0
	match difficulty:
		0: # DỄ: Áp lực vừa phải + accuracy < 50%
			base_chance = pow(p, 1.2) * (0.20 + pressure * 0.25)
		1: # TRUNG BÌNH: Cân bằng
			base_chance = pow(p, 1.3) * (0.10 + pressure * 0.20)
		2: # KHÓ: Vững vàng
			base_chance = pow(p, 1.5) * (pressure * 0.12)
			
	return randf() < base_chance


## Kiểm tra lỗi rúc lưới khi đỡ cầu quá sát sàn dưới áp lực lớn
## CHỈ KHI ACCURACY < 50% MỚI CÓ THỂ MẮC LỖI RÚC LƯỚI
func should_net_fault(difficulty: int, accuracy: float = 100.0) -> bool:
	if accuracy >= 50.0:
		return false
	if pressure < 0.50:
		return false
	
	var p = clamp((50.0 - accuracy) / 50.0, 0.0, 1.0)
	var fault_rate = 0.0
	match difficulty:
		0: fault_rate = pow(p, 1.3) * 0.08 * pressure
		1: fault_rate = pow(p, 1.4) * 0.035 * pressure
		2: fault_rate = pow(p, 1.5) * 0.01 * pressure
	return randf() < fault_rate


## Kiểm tra giật mình vặn sườn khi đối thủ lừa hướng đánh (Wrong-foot)
func trigger_wrong_foot(prev_moving_dir: float, new_target_dir: float) -> float:
	if pressure > 0.25 and (prev_moving_dir * new_target_dir < -0.1):
		hesitation_timer = lerp(0.06, 0.14, pressure)
		return hesitation_timer
	return 0.0
