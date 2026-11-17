class_name MatchReferee
extends RefCounted

const MatchConstants = preload("res://scripts/core/match_constants.gd")

# ==========================================================
# MATCH REFEREE & RULES ARBITRATION (BWF CLEAN ARCHITECTURE)
# Tái cấu trúc phân định trọng tài: Luật tính điểm, out, net, serve, set đấu
# ==========================================================

signal point_scored(winner: String, current_player_score: int, current_ai_score: int)
signal set_won(winner: String, player_sets: int, ai_sets: int)
signal match_won(winner: String)

enum MatchState {
	SERVE,
	RALLY,
	POINT_OVER,
	MATCH_OVER
}

var state: MatchState = MatchState.SERVE

var player_score: int = 0
var ai_score: int = 0
var player_sets: int = 0
var ai_sets: int = 0

var target_points: int = 7 # Mặc định 7 điểm (Arcade Fast-Paced)
var max_sets: int = 3      # Đánh 3 set thắng 2

var is_player_serving: bool = true

func reset_match() -> void:
	player_score = 0
	ai_score = 0
	player_sets = 0
	ai_sets = 0
	is_player_serving = true
	state = MatchState.SERVE

func award_point(winner: String) -> Dictionary:
	if winner == "player":
		player_score += 1
		is_player_serving = true
	else:
		ai_score += 1
		is_player_serving = false
		
	var is_set_over = false
	var is_match_over = false
	var set_winner = ""
	var match_winner = ""
	
	# Kiểm tra kết thúc set đấu:
	if player_score >= target_points and (player_score - ai_score) >= 2:
		player_sets += 1
		is_set_over = true
		set_winner = "player"
		player_score = 0
		ai_score = 0
	elif ai_score >= target_points and (ai_score - player_score) >= 2:
		ai_sets += 1
		is_set_over = true
		set_winner = "ai"
		player_score = 0
		ai_score = 0
		
	# Kiểm tra kết thúc trận đấu (Thắng 2 set):
	var required_sets_to_win = (max_sets / 2) + 1
	if player_sets >= required_sets_to_win:
		is_match_over = true
		match_winner = "player"
		state = MatchState.MATCH_OVER
	elif ai_sets >= required_sets_to_win:
		is_match_over = true
		match_winner = "ai"
		state = MatchState.MATCH_OVER
	else:
		state = MatchState.POINT_OVER
		
	return {
		"winner": winner,
		"player_score": player_score,
		"ai_score": ai_score,
		"player_sets": player_sets,
		"ai_sets": ai_sets,
		"is_set_over": is_set_over,
		"set_winner": set_winner,
		"is_match_over": is_match_over,
		"match_winner": match_winner
	}

## Bắt lỗi vạch biên chuẩn BWF
static func is_in_court(x: float) -> bool:
	return x >= MatchConstants.LEFT_OUT_X and x <= MatchConstants.RIGHT_OUT_X

## Xác định bên nào làm rơi cầu (sân trái hay sân phải)
static func get_court_side(x: float) -> String:
	return "player" if x < MatchConstants.NET_X else "ai"
