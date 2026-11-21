extends Control
class_name BWFScoreboard

@onready var name_p1: Label = $BaseTexture/NameP1
@onready var name_p2: Label = $BaseTexture/NameP2
@onready var server_indicator: ColorRect = $BaseTexture/ServerIndicator

@onready var score_p1_s1: Label = $BaseTexture/Scores/Score_P1_S1
@onready var score_p1_s2: Label = $BaseTexture/Scores/Score_P1_S2
@onready var score_p1_s3: Label = $BaseTexture/Scores/Score_P1_S3

@onready var score_p2_s1: Label = $BaseTexture/Scores/Score_P2_S1
@onready var score_p2_s2: Label = $BaseTexture/Scores/Score_P2_S2
@onready var score_p2_s3: Label = $BaseTexture/Scores/Score_P2_S3

const COLOR_NEON_YELLOW = Color(0.89, 1.0, 0.08, 1.0)
const COLOR_WHITE = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_FADED = Color(0.48, 0.50, 0.52, 1.0)

var scores_p1: Array[int] = [0, 0, 0]
var scores_p2: Array[int] = [0, 0, 0]
var set_winners: Array[int] = [-1, -1, -1] # 0 = P1 won, 1 = P2 won, -1 = not done
var current_active_set: int = 0
var max_sets: int = 3

func _ready() -> void:
	custom_minimum_size = Vector2(440, 64)
	size = Vector2(440, 64)
	z_index = 100
	_ensure_nodes()
	_apply_bold_names()
	refresh_display()

func _apply_bold_names() -> void:
	var bold_font = SystemFont.new()
	bold_font.font_names = PackedStringArray(["Bahnschrift", "Segoe UI", "Arial", "Sans-Serif"])
	bold_font.font_weight = 700
	if name_p1:
		name_p1.add_theme_font_override("font", bold_font)
		name_p1.add_theme_font_size_override("font_size", 15)
	if name_p2:
		name_p2.add_theme_font_override("font", bold_font)
		name_p2.add_theme_font_size_override("font_size", 15)

func _ensure_nodes() -> void:
	if not name_p1:
		name_p1 = get_node_or_null("BaseTexture/NameP1")
		name_p2 = get_node_or_null("BaseTexture/NameP2")
		server_indicator = get_node_or_null("BaseTexture/ServerIndicator")
		score_p1_s1 = get_node_or_null("BaseTexture/Scores/Score_P1_S1")
		score_p1_s2 = get_node_or_null("BaseTexture/Scores/Score_P1_S2")
		score_p1_s3 = get_node_or_null("BaseTexture/Scores/Score_P1_S3")
		score_p2_s1 = get_node_or_null("BaseTexture/Scores/Score_P2_S1")
		score_p2_s2 = get_node_or_null("BaseTexture/Scores/Score_P2_S2")
		score_p2_s3 = get_node_or_null("BaseTexture/Scores/Score_P2_S3")

func set_match_mode(total_sets: int) -> void:
	max_sets = total_sets
	refresh_display()

func reset_scoreboard(total_sets: int = 1) -> void:
	max_sets = total_sets
	scores_p1 = [0, 0, 0]
	scores_p2 = [0, 0, 0]
	set_winners = [-1, -1, -1]
	current_active_set = 0
	refresh_display()

func set_players(p1_raw_name: String, p2_raw_name: String, _unused1: String = "", _unused2: String = "") -> void:
	_ensure_nodes()
	# Strip any parentheses or suffixes: only pure uppercase name
	var clean1 = p1_raw_name.split("(")[0].strip_edges().to_upper()
	var clean2 = p2_raw_name.split("(")[0].strip_edges().to_upper()
	if clean1.is_empty(): clean1 = "PLAYER"
	if clean2.is_empty(): clean2 = "RIVAL"
	
	name_p1.text = clean1
	name_p2.text = clean2

func set_server(is_rival: bool) -> void:
	_ensure_nodes()
	if not server_indicator: return
	server_indicator.position.y = 33 if is_rival else 2
	server_indicator.visible = true

func update_current_score(p1_pts: int, p2_pts: int) -> void:
	if current_active_set >= 0 and current_active_set < 3:
		scores_p1[current_active_set] = p1_pts
		scores_p2[current_active_set] = p2_pts
	refresh_display()

func finish_set(set_idx: int, winner_is_rival: bool) -> void:
	if set_idx >= 0 and set_idx < 3:
		set_winners[set_idx] = 1 if winner_is_rival else 0
	refresh_display()

func set_sets_won(s1: int, s2: int) -> void:
	set_winners = [-1, -1, -1]
	var idx = 0
	for i in range(s1):
		if idx < 3:
			set_winners[idx] = 0
			idx += 1
	for i in range(s2):
		if idx < 3:
			set_winners[idx] = 1
			idx += 1
	current_active_set = clamp(s1 + s2, 0, 2)
	refresh_display()

func advance_to_next_set() -> void:
	current_active_set += 1
	refresh_display()

func sync_full_state(p1_scores: Array, p2_scores: Array, winners: Array, active_set: int, total_sets: int) -> void:
	max_sets = total_sets
	current_active_set = clamp(active_set, 0, 2)
	for i in range(3):
		if i < p1_scores.size():
			scores_p1[i] = int(p1_scores[i])
		if i < p2_scores.size():
			scores_p2[i] = int(p2_scores[i])
		if i < winners.size():
			set_winners[i] = int(winners[i])
	refresh_display()

func refresh_display() -> void:
	_ensure_nodes()
	var p1_labels = [score_p1_s1, score_p1_s2, score_p1_s3]
	var p2_labels = [score_p2_s1, score_p2_s2, score_p2_s3]
	
	for i in range(3):
		var lbl1 = p1_labels[i]
		var lbl2 = p2_labels[i]
		if not lbl1 or not lbl2: continue
		
		if max_sets == 1 and i > 0:
			# Hide set 2 & 3 in 1-set match
			lbl1.text = "-"
			lbl2.text = "-"
			lbl1.modulate = COLOR_FADED
			lbl2.modulate = COLOR_FADED
			continue
			
		if i < current_active_set:
			# Finished set
			lbl1.text = str(scores_p1[i])
			lbl2.text = str(scores_p2[i])
			if set_winners[i] == 0:
				lbl1.modulate = COLOR_NEON_YELLOW
				lbl2.modulate = COLOR_WHITE
			elif set_winners[i] == 1:
				lbl1.modulate = COLOR_WHITE
				lbl2.modulate = COLOR_NEON_YELLOW
			else:
				lbl1.modulate = COLOR_WHITE
				lbl2.modulate = COLOR_WHITE
		elif i == current_active_set:
			# Active ongoing set
			lbl1.text = str(scores_p1[i])
			lbl2.text = str(scores_p2[i])
			lbl1.modulate = COLOR_WHITE
			lbl2.modulate = COLOR_WHITE
		else:
			# Future set
			lbl1.text = ""
			lbl2.text = ""
			lbl1.modulate = COLOR_FADED
			lbl2.modulate = COLOR_FADED
