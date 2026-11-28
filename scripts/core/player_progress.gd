class_name PlayerProgress
extends RefCounted

# ==========================================================
# PLAYER PROGRESS, ECONOMY, UPGRADES, QUESTS & TOURNAMENT
# - Tất cả 5 nhân vật đều có tổng chỉ số MAX = 360 (cân bằng tuyệt đối)
# - Min LV (Lv 0) = Max - 10 (tổng 320); Max LV (Lv 10) = Max (tổng 360)
#   -> Không quá chênh lệch giữa Min LV và Max LV (~11%)
# ==========================================================

const SAVE_PATH = "user://player_progress.cfg"
const MAX_STAT_LEVEL: int = 10

const MAX_STATS := {
	"nishikawa": {"power": 99, "agility": 87, "control": 84, "composure": 90}, # 360
	"fuji":      {"power": 82, "agility": 91, "control": 99, "composure": 88}, # 360
	"wall":      {"power": 78, "agility": 90, "control": 93, "composure": 99}, # 360
	"gitae":     {"power": 96, "agility": 86, "control": 82, "composure": 96}, # 360
	"sara":      {"power": 82, "agility": 97, "control": 93, "composure": 88}, # 360
}

const CUPS := {
	"rookie": {
		"id": "rookie",
		"name": "GIẢI PHONG TRÀO (ROOKIE CUP)",
		"desc": "3 vòng đấu khởi động. AI cấp Dễ -> Trung Bình.",
		"rounds": [
			{"char": "wall", "diff": 0, "pts": 7, "label": "TỨ KẾT"},
			{"char": "fuji", "diff": 0, "pts": 7, "label": "BÁN KẾT"},
			{"char": "gitae", "diff": 1, "pts": 11, "label": "CHUNG KẾT"},
		],
		"reward_gold": 400,
		"reward_gems": 15,
		"color": Color(0.30, 0.90, 0.55)
	},
	"national": {
		"id": "national",
		"name": "GIẢI QUỐC GIA (NATIONAL OPEN)",
		"desc": "3 vòng đấu căng thẳng. AI Trung Bình -> Đỉnh Cao.",
		"rounds": [
			{"char": "gitae", "diff": 1, "pts": 11, "label": "TỨ KẾT"},
			{"char": "sara", "diff": 1, "pts": 11, "label": "BÁN KẾT"},
			{"char": "nishikawa", "diff": 2, "pts": 11, "label": "CHUNG KẾT"},
		],
		"reward_gold": 800,
		"reward_gems": 35,
		"color": Color(0.35, 0.80, 1.0)
	},
	"world": {
		"id": "world",
		"name": "GIẢI THẾ GIỚI BWF (KAISER WORLD)",
		"desc": "4 trận đỉnh cao gặp toàn bộ Siêu Sao S+ ở cấp Đỉnh Cao!",
		"rounds": [
			{"char": "wall", "diff": 2, "pts": 11, "label": "VÒNG 1/8"},
			{"char": "fuji", "diff": 2, "pts": 11, "label": "TỨ KẾT"},
			{"char": "gitae", "diff": 2, "pts": 11, "label": "BÁN KẾT"},
			{"char": "sara", "diff": 2, "pts": 15, "label": "CHUNG KẾT THẾ GIỚI"},
		],
		"reward_gold": 1500,
		"reward_gems": 80,
		"color": Color(1.0, 0.82, 0.25)
	}
}

static var _loaded: bool = false
static var gold_coins: int = 200
static var gems: int = 10
static var stat_levels: Dictionary = {} # { cid: {"power": 0..10, "agility": 0..10, "control": 0..10, "composure": 0..10} }
static var quests: Dictionary = {
	"daily_login": {"prog": 1, "target": 1, "claimed": false, "gold": 150, "gems": 5, "title": "Điểm danh hàng ngày"},
	"pvp_wins": {"prog": 0, "target": 2, "claimed": false, "gold": 300, "gems": 15, "title": "Chiến thắng 2 trận Đấu Đối Kháng (PvP)"},
	"perfect_smashes": {"prog": 0, "target": 3, "claimed": false, "gold": 200, "gems": 10, "title": "Ghi 3 điểm từ cú SMASH hoàn hảo"},
	"dive_saves": {"prog": 0, "target": 5, "claimed": false, "gold": 200, "gems": 10, "title": "Thực hiện 5 pha bay người cứu cầu thành công"},
}
static var cups_won: Dictionary = {"rookie": 0, "national": 0, "world": 0}
static var unlocked_trails: Array = ["default"]
static var equipped_trail: String = "default"

const SHOP_TRAILS := {
	"lightning": {"name": "Vệt Cầu Lôi Quang", "desc": "Hiệu ứng vệt cầu tia chớp vàng rực rỡ.", "cost": 300, "color": Color(1.0, 0.85, 0.25)},
	"frost":     {"name": "Vệt Cầu Băng Tuyết", "desc": "Hiệu ứng vệt cầu băng xanh ngọc mát lạnh.", "cost": 350, "color": Color(0.35, 0.85, 1.0)},
	"flame":     {"name": "Vệt Cầu Hỏa Diệm", "desc": "Hiệu ứng vệt cầu lửa cam đỏ rực cháy.", "cost": 400, "color": Color(1.0, 0.42, 0.15)},
}


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	for cid in MAX_STATS.keys():
		if not stat_levels.has(cid):
			stat_levels[cid] = {"power": 0, "agility": 0, "control": 0, "composure": 0}
	var cfg = ConfigFile.new()
	var loaded_ok = (cfg.load(SAVE_PATH) == OK)
	if OS.has_feature("web"):
		var js_json = JavaScriptBridge.eval("localStorage.getItem('kaiser_progress_v1') || ''")
		if js_json is String and not js_json.strip_edges().is_empty():
			var parsed = JSON.parse_string(js_json)
			if parsed is Dictionary:
				gold_coins = int(parsed.get("gold", gold_coins))
				gems = int(parsed.get("gems", gems))
				var lvls = parsed.get("levels", {})
				if lvls is Dictionary:
					for cid in lvls.keys():
						if stat_levels.has(cid) and lvls[cid] is Dictionary:
							for k in ["power", "agility", "control", "composure"]:
								stat_levels[cid][k] = clampi(int(lvls[cid].get(k, 0)), 0, MAX_STAT_LEVEL)
				var qd = parsed.get("quests", {})
				if qd is Dictionary:
					for qid in quests.keys():
						if qd.has(qid) and qd[qid] is Dictionary:
							quests[qid]["prog"] = int(qd[qid].get("prog", quests[qid]["prog"]))
							quests[qid]["claimed"] = bool(qd[qid].get("claimed", false))
				var cw = parsed.get("cups", {})
				if cw is Dictionary:
					for cup_id in cups_won.keys():
						cups_won[cup_id] = int(cw.get(cup_id, 0))
				var tr = parsed.get("trails", ["default"])
				if tr is Array:
					unlocked_trails = []
					for t in tr:
						var ts = str(t)
						if not unlocked_trails.has(ts):
							unlocked_trails.append(ts)
					if not unlocked_trails.has("default"):
						unlocked_trails.append("default")
				var eq_t = str(parsed.get("equipped_trail", "default"))
				if unlocked_trails.has(eq_t):
					equipped_trail = eq_t
				return
	if loaded_ok:
		gold_coins = int(cfg.get_value("wallet", "gold", gold_coins))
		gems = int(cfg.get_value("wallet", "gems", gems))
		for cid in MAX_STATS.keys():
			for k in ["power", "agility", "control", "composure"]:
				stat_levels[cid][k] = clampi(int(cfg.get_value("levels_" + cid, k, 0)), 0, MAX_STAT_LEVEL)
		for qid in quests.keys():
			quests[qid]["prog"] = int(cfg.get_value("quests", qid + "_prog", quests[qid]["prog"]))
			quests[qid]["claimed"] = bool(cfg.get_value("quests", qid + "_claimed", false))
		for cup_id in cups_won.keys():
			cups_won[cup_id] = int(cfg.get_value("cups", cup_id, 0))
		var cfg_tr = cfg.get_value("shop", "trails", ["default"])
		if cfg_tr is Array:
			unlocked_trails = []
			for t in cfg_tr:
				var ts = str(t)
				if not unlocked_trails.has(ts):
					unlocked_trails.append(ts)
			if not unlocked_trails.has("default"):
				unlocked_trails.append("default")
		var cfg_eq = str(cfg.get_value("shop", "equipped_trail", "default"))
		if unlocked_trails.has(cfg_eq):
			equipped_trail = cfg_eq


static func save() -> void:
	ensure_loaded()
	var cfg = ConfigFile.new()
	cfg.set_value("wallet", "gold", gold_coins)
	cfg.set_value("wallet", "gems", gems)
	for cid in stat_levels.keys():
		for k in ["power", "agility", "control", "composure"]:
			cfg.set_value("levels_" + cid, k, stat_levels[cid][k])
	for qid in quests.keys():
		cfg.set_value("quests", qid + "_prog", quests[qid]["prog"])
		cfg.set_value("quests", qid + "_claimed", quests[qid]["claimed"])
	for cup_id in cups_won.keys():
		cfg.set_value("cups", cup_id, cups_won[cup_id])
	cfg.set_value("shop", "trails", unlocked_trails)
	cfg.set_value("shop", "equipped_trail", equipped_trail)
	cfg.save(SAVE_PATH)
	if OS.has_feature("web"):
		var payload = {
			"gold": gold_coins,
			"gems": gems,
			"levels": stat_levels,
			"quests": quests,
			"cups": cups_won,
			"trails": unlocked_trails,
			"equipped_trail": equipped_trail
		}
		var json_str = JSON.stringify(payload).replace("'", "\\'")
		JavaScriptBridge.eval("localStorage.setItem('kaiser_progress_v1', '%s');" % json_str)


static func get_stat_level(cid: String, stat_key: String) -> int:
	ensure_loaded()
	if stat_levels.has(cid):
		return int(stat_levels[cid].get(stat_key, 0))
	return 0


static func get_effective_stat(cid: String, stat_key: String) -> int:
	ensure_loaded()
	var max_v = int(MAX_STATS.get(cid, MAX_STATS["nishikawa"]).get(stat_key, 85))
	var lvl = get_stat_level(cid, stat_key)
	return (max_v - MAX_STAT_LEVEL) + clampi(lvl, 0, MAX_STAT_LEVEL)


static func get_max_stat(cid: String, stat_key: String) -> int:
	return int(MAX_STATS.get(cid, MAX_STATS["nishikawa"]).get(stat_key, 85))


static func get_upgrade_cost(cid: String, stat_key: String) -> int:
	var lvl = get_stat_level(cid, stat_key)
	if lvl >= MAX_STAT_LEVEL:
		return 0
	return 50 + lvl * 25


static func upgrade_stat(cid: String, stat_key: String) -> bool:
	ensure_loaded()
	if not stat_levels.has(cid):
		return false
	var lvl = get_stat_level(cid, stat_key)
	if lvl >= MAX_STAT_LEVEL:
		return false
	var cost = get_upgrade_cost(cid, stat_key)
	if gold_coins < cost:
		return false
	gold_coins -= cost
	stat_levels[cid][stat_key] = lvl + 1
	save()
	return true


static func add_rewards(add_gold: int, add_gems: int = 0) -> void:
	ensure_loaded()
	gold_coins += max(0, add_gold)
	gems += max(0, add_gems)
	save()


static func add_quest_progress(qid: String, amount: int = 1) -> void:
	ensure_loaded()
	if quests.has(qid):
		quests[qid]["prog"] = min(quests[qid]["target"], int(quests[qid]["prog"]) + amount)
		save()


static func claim_quest(qid: String) -> bool:
	ensure_loaded()
	if not quests.has(qid):
		return false
	var q = quests[qid]
	if q["claimed"] or int(q["prog"]) < int(q["target"]):
		return false
	q["claimed"] = true
	gold_coins += int(q["gold"])
	gems += int(q["gems"])
	save()
	return true


static func record_cup_win(cup_id: String) -> void:
	ensure_loaded()
	if cups_won.has(cup_id):
		cups_won[cup_id] = int(cups_won[cup_id]) + 1
		save()


static func buy_or_equip_trail(trail_id: String) -> bool:
	ensure_loaded()
	if trail_id == "default" or trail_id in unlocked_trails:
		equipped_trail = trail_id
		save()
		return true
	if not SHOP_TRAILS.has(trail_id):
		return false
	var cost = int(SHOP_TRAILS[trail_id]["cost"])
	if gold_coins < cost:
		return false
	gold_coins -= cost
	unlocked_trails.append(trail_id)
	equipped_trail = trail_id
	save()
	return true


static func exchange_gems_for_gold(gem_cost: int = 10, gold_gain: int = 250) -> bool:
	ensure_loaded()
	if gems < gem_cost:
		return false
	gems -= gem_cost
	gold_coins += gold_gain
	save()
	return true
