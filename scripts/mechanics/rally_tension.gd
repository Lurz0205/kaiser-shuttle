class_name RallyTension
extends RefCounted

# ==========================================================
# DYNAMIC RALLY TENSION 2.0 (HEAT METER SYSTEM)
# Nhịp độ trận đấu tăng dần theo độ căng thẳng của pha bóng:
# - 0-10 chạm đầu: Thăm dò / Điều cầu chiến thuật (Heat < 26, tốc độ 1.0x)
# - 11-25 chạm: Cao trào bùng nổ (Heat 26-65, tốc độ ~1.10x)
# - 26-35+ chạm: Vùng cực hạn / Tử chiến (Heat > 65, tốc độ 1.25x-1.30x)
# - Có thể chủ động HẠ NHIỆT (Cooling) bằng đòn bỏ nhỏ / điều cầu chậm rãi!
# ==========================================================

var hits: int = 0
var heat: float = 0.0 # Thang đo nhiệt độ [0.0 -> 100.0]
var soft_streak: int = 0 # Đếm chuỗi các cú đánh êm dịu làm nguội nhịp cầu

var tension_level: int:
	get:
		return get_tension_level()


func reset() -> void:
	hits = 0
	heat = 0.0
	soft_streak = 0


## Cập nhật nhịp độ dựa trên đòn đánh cụ thể (Smash kích nhiệt, Drop làm nguội)
func add_shot(shot_type: String, is_smash: bool, is_boom: bool = false) -> int:
	hits += 1
	
	if is_boom:
		# Boom Smash: Kích hoạt nhiệt lượng bùng nổ cực mạnh
		heat = clamp(heat + 14.0, 0.0, 100.0)
		soft_streak = 0
	elif is_smash:
		# Smash thường: Đẩy nhiệt độ lên cao
		heat = clamp(heat + 9.5, 0.0, 100.0)
		soft_streak = 0
	elif shot_type == "drive":
		# Đấu drive cận lưới: Tăng nhiệt độ
		heat = clamp(heat + 5.0, 0.0, 100.0)
		soft_streak = 0
	elif shot_type == "drop" or shot_type == "weak_return":
		# HẠ NHIỆT (COOLING): Bỏ nhỏ êm dịu cắt đứt nhịp tấn công
		soft_streak += 1
		var cool_val = 4.5 + (soft_streak * 2.0)
		heat = max(0.0, heat - cool_val)
	else:
		# Phông cầu (Clear) / Bung bổng (Lift):
		if soft_streak > 0:
			# Đang trong pha hạ nhịp điều bóng: Giữ nhịp ổn định hoặc làm nguội nhẹ
			heat = max(0.0, heat - 1.5)
		else:
			# Giằng co đôi công bình thường: Mỗi nhịp tích lũy nhẹ ~2.4 điểm
			# (Mất ~11 nhịp đôi công để chạm ngưỡng 26 điểm - Bước vào Giai đoạn 2)
			# (Mất ~28-30 nhịp đôi công để chạm ngưỡng 66 điểm - Bước vào Giai đoạn 3)
			heat = clamp(heat + 2.4, 0.0, 100.0)
			
	return get_tension_level()


## Tương thích ngược với hàm add_hit() cũ
func add_hit() -> int:
	return add_shot("clear", false, false)


func cool_down(amount: float) -> void:
	heat = max(0.0, heat - amount)


func get_tension_level() -> int:
	if heat >= 66.0:
		return 2 # GODLY CLIMAX (Tử chiến vùng cực hạn)
	elif heat >= 26.0:
		return 1 # RISING MOMENTUM (Cao trào bùng nổ)
	return 0     # NEUTRAL TACTICAL (Thăm dò chiến thuật)


func get_speed_multiplier() -> float:
	match get_tension_level():
		2:
			# Gia tốc 1.25x -> 1.30x
			var p = clamp((heat - 66.0) / 34.0, 0.0, 1.0)
			return lerp(1.25, 1.30, p)
		1:
			# Gia tốc 1.08x -> 1.15x
			var p = clamp((heat - 26.0) / 40.0, 0.0, 1.0)
			return lerp(1.08, 1.15, p)
		_:
			return 1.0


func get_tension_color() -> Color:
	match get_tension_level():
		2:
			return Color(3.8, 2.4, 0.3, 1.0) # Sét vàng chói lóa
		1:
			return Color(0.2, 0.85, 1.0, 1.0) # Tia điện xanh neon
		_:
			return Color(1.0, 1.0, 1.0, 0.9)  # Trắng bạc thể thao


func get_status_color() -> Color:
	return get_tension_color()


func get_status_text() -> String:
	var spd = get_speed_multiplier()
	match get_tension_level():
		2:
			return "LETHAL ZONE [x%.2f]" % spd
		1:
			return "MOMENTUM [x%.2f]" % spd
		_:
			return "" # 10 quả đầu giao tranh êm dịu không hiện chữ gây rối mắt
