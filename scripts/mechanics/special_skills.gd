class_name SpecialSkills
extends RefCounted

# ==========================================================
# ANIME SPECIAL SKILLS & MOMENTUM BURSTS
# 1. NISHIKAWA GOLDEN SMASH: Cú đập ngưng đọng, thế giới trắng đen, sấm sét nổ vang
# 2. TSUBAME GAESHI (Fuji): Én lượn trở về - Cắt xoáy sà sát mép lưới, góc lượn hiểm sát mặt sàn
# 3. MIRAGE COUNTER (The Wall): Ảo ảnh phản đòn - Dư ảnh hóa giải smash và phản tạt siêu tốc
# ==========================================================

const GOLDEN_SMASH: String = "golden_smash"
const TSUBAME_GAESHI: String = "tsubame_gaeshi"
const MIRAGE_COUNTER: String = "mirage_counter"

static func get_skill_name(skill_id: String) -> String:
	match skill_id:
		GOLDEN_SMASH:
			return "NISHIKAWA: GOLDEN SMASH!"
		TSUBAME_GAESHI:
			return "FUJI: TSUBAME GAESHI!"
		MIRAGE_COUNTER:
			return "AOI: MIRAGE COUNTER!"
		_:
			return "SPECIAL MOVE!"

static func get_skill_color(skill_id: String) -> Color:
	match skill_id:
		GOLDEN_SMASH:
			return Color(3.8, 2.6, 0.4, 1.0) # Vàng kim lôi đình
		TSUBAME_GAESHI:
			return Color(0.2, 3.2, 1.8, 1.0) # Lục bảo én lượn
		MIRAGE_COUNTER:
			return Color(0.3, 1.8, 3.8, 1.0) # Lam ảnh thần thuẫn
		_:
			return Color(1.0, 1.0, 1.0, 1.0)
