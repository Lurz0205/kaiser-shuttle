extends Node2D

const RallyTension = preload("res://scripts/mechanics/rally_tension.gd")
const AIPressureModel = preload("res://scripts/ai/ai_pressure_model.gd")

enum MatchState { SERVE, RALLY, POINT_OVER }
var current_state: MatchState = MatchState.SERVE

# Score
var score_player: int = 0
var score_ai: int = 0
const MATCH_POINT: int = 11
var current_server: String = "player"
var is_serve_in_progress: bool = false
var current_shot_max_speed: float = 0.0

# Court geometry (Pure 2D Side-View)
const NET_X: float = 640.0
const NET_HEIGHT: float = 110.0 # Lưới nâng cao lên 110px ngang tầm cổ vận động viên
const LEFT_OUT_X: float = 140.0
const RIGHT_OUT_X: float = 1140.0
const SHORT_SERVICE_LEFT: float = 495.0
const SHORT_SERVICE_RIGHT: float = 785.0
const FLOOR_Y: float = 550.0

# Camera Shake & Impact Frame
var shake_amount: float = 0.0
var flash_alpha: float = 0.0
var shockwave_pos: Vector2 = Vector2.ZERO
var shockwave_radius: float = 0.0
var shockwave_alpha: float = 0.0

# Perfect Hit Burst & Banner tween
var banner_tween: Tween = null
var perfect_burst_pos: Vector2 = Vector2.ZERO
var perfect_burst_timer: float = 0.0
var perfect_burst_col: Color = Color(1.0, 0.9, 0.2)
const FloatingTextManager = preload("res://scripts/ui/floating_text_manager.gd")
var floating_text_mgr: FloatingTextManager = FloatingTextManager.new()
var effects_overlay: Node2D = null

@onready var camera: Camera2D = $Camera2D
@onready var player: BadmintonPlayer = $Player
@onready var ai_rival: BadmintonPlayer = $AIRival
@onready var shuttlecock: Shuttlecock = $Shuttlecock

# HUD
@onready var bwf_scoreboard: BWFScoreboard = $HUD/BWFScoreboard
@onready var scoreboard: PanelContainer = get_node_or_null("HUD/ScoreBoard")
@onready var controls_bar: PanelContainer = $HUD/ControlsBar
@onready var label_score: Label = get_node_or_null("HUD/ScoreBoard/Inner/LabelScore")
@onready var label_player_badge: Label = get_node_or_null("HUD/ScoreBoard/Inner/BadgePlayer/LabelPlayer")
@onready var label_rival_badge: Label = get_node_or_null("HUD/ScoreBoard/Inner/BadgeRival/LabelRival")
@onready var pill_stats: Panel = $HUD/PillStats
@onready var label_spike_stats: Label = $HUD/PillStats/LabelSpikeStats
@onready var label_banner: Label = $HUD/LabelBanner
@onready var flash_rect: ColorRect = $HUD/FlashRect
@onready var grayscale_rect: ColorRect = $HUD/GrayscaleRect
@onready var nishikawa_lightning: Node2D = $NishikawaLightning
@onready var aoi_shield: Node2D = $IsabelShield

# Isabel (The Wall) Mirage Shield Barrier Effect
var aoi_shield_active: bool = false
var aoi_shield_timer: float = 0.0
var aoi_shield_duration: float = 1.55
var aoi_shield_center: Vector2 = Vector2.ZERO
var aoi_shield_start_ticks: int = 0

# Match Rules & Target Points
var target_match_points: int = 11
var total_match_sets: int = 1
var current_set_index: int = 0
var sets_won_player: int = 0
var sets_won_ai: int = 0
var is_umpire_speaking: bool = false
var match_over_dialog: PanelContainer = null

# HUD Athletic Gauges (Stamina & Accuracy)
var stamina_bar_bg_player: ColorRect
var stamina_bar_fill_player: ColorRect
var stamina_bar_cap_player: ColorRect
var accuracy_bar_bg_player: ColorRect
var accuracy_bar_fill_player: ColorRect

var stamina_bar_bg_ai: ColorRect
var stamina_bar_fill_ai: ColorRect
var stamina_bar_cap_ai: ColorRect
var accuracy_bar_bg_ai: ColorRect
var accuracy_bar_fill_ai: ColorRect

# Nishikawa Impact Lightning (Slow-mo chung với game, sau đó mới tỏa ra bình thường)
var impact_lightning_pos: Vector2 = Vector2.ZERO
var impact_lightning_active: bool = false
var impact_lightning_in_slowmo: bool = false
var impact_lightning_burst_timer: float = 0.0
var impact_lightning_anim_t: float = 0.0
var impact_lightning_p_burst: float = 0.0
var impact_start_ticks: int = 0
const SLOWMO_LIGHTNING_DURATION: float = 1.0
const BURST_LIGHTNING_DURATION: float = 0.28
var impact_lightning_branches: Array = []

# Fuji Emerald Gale Vortex Slowmo Effect (Cơn lốc xanh)
var fuji_slowmo_active: bool = false
var fuji_slowmo_timer: float = 0.0
const FUJI_SLOWMO_DURATION: float = 0.48
var fuji_slowmo_center: Vector2 = Vector2.ZERO
var fuji_slowmo_start_ticks: int = 0
var fuji_slowmo_facing: float = 1.0
var fuji_slowmo_leaves: Array = []

# Takeoff Jump Effects (Hiệu ứng dậm nhảy bùng nổ mặt sàn)
var jump_takeoff_effects: Array = []

# Settings UI & Character Select
const CharacterStats = preload("res://scripts/core/character_stats.gd")
const MainMenuController = preload("res://scripts/ui/main_menu_controller.gd")
const PvPNetworkManager = preload("res://scripts/network/pvp_network_manager.gd")
@onready var btn_char_select: Button = $HUD/BtnCharSelect
var main_menu: MainMenuController
var net_manager: PvPNetworkManager
var is_pvp_active: bool = false
var is_pvp_host: bool = false
var pvp_room_code: String = ""
var pvp_local_char: String = "nishikawa"

@onready var btn_settings: Button = $HUD/BtnSettings
@onready var settings_panel: PanelContainer = $HUD/SettingsPanel
@onready var btn_close_settings: Button = $HUD/SettingsPanel/VBox/Header/BtnClose
@onready var btn_easy: Button = $HUD/SettingsPanel/VBox/DifficultyRow/BtnEasy
@onready var btn_medium: Button = $HUD/SettingsPanel/VBox/DifficultyRow/BtnMedium
@onready var btn_hard: Button = $HUD/SettingsPanel/VBox/DifficultyRow/BtnHard
@onready var btn_squeak: Button = $HUD/SettingsPanel/VBox/SqueakRow/BtnSqueak

# Audio (Smash, Phong, Rít giày, Sấm sét, Isabel Block & Slowmo, Dây vợt net, Gió Fuji, Chém cầu sau sân, Trọng tài)
@onready var sfx_smash: AudioStreamPlayer = $Audio/SFXSmash
@onready var sfx_phong: AudioStreamPlayer = $Audio/SFXPong
@onready var sfx_squeak: AudioStreamPlayer = $Audio/SFXSqueak
@onready var sfx_electric: AudioStreamPlayer = $Audio/SFXElectric
@onready var sfx_aoi_block: AudioStreamPlayer = $Audio/SFXIsabelBlock
@onready var sfx_aoi_slowmo: AudioStreamPlayer = $Audio/SFXIsabelSlowmo
@onready var sfx_string: AudioStreamPlayer = $Audio/SFXString
@onready var sfx_fuji_wind: AudioStreamPlayer = $Audio/SFXFujiWind
@onready var sfx_chem: AudioStreamPlayer = $Audio/SFXChem
@onready var sfx_low_ball_play: AudioStreamPlayer = $Audio/SFXLowBallPlay
@onready var bgm_lobby: AudioStreamPlayer = $Audio/BGMLobby
var amb_player: AudioStreamPlayer = null

# Multi-sample sound pools (phát random không lặp lại)
var sfx_string_streams: Array[AudioStream] = []
var last_string_idx: int = -1

var sfx_squeak_streams: Array[AudioStream] = []
var last_squeak_idx: int = -1
var last_squeak_msec: int = 0
const SQUEAK_MIN_INTERVAL_MS: int = 140

var previous_shot_type: String = ""

# Game feel toggles
var squeak_enabled: bool = true

# Escalating Rally Tension
var rally_tension: RallyTension = RallyTension.new()

var prev_shuttle_x: float = 0.0


func _ready() -> void:
	# Nạp các biến thể âm thanh string (ngẫu nhiên không trùng lặp)
	sfx_string_streams.append(preload("res://assets/audio/string1.wav"))
	sfx_string_streams.append(preload("res://assets/audio/string2.wav"))
	
	# Nạp 6 biến thể tiếng rít giày sàn đấu
	sfx_squeak_streams.append(preload("res://assets/audio/squeak_1.wav"))
	sfx_squeak_streams.append(preload("res://assets/audio/squeak_2.wav"))
	sfx_squeak_streams.append(preload("res://assets/audio/squeak_3.wav"))
	sfx_squeak_streams.append(preload("res://assets/audio/squeak_4.wav"))
	sfx_squeak_streams.append(preload("res://assets/audio/squeak_5.wav"))
	sfx_squeak_streams.append(preload("res://assets/audio/squeak_6.wav"))

	camera.position = Vector2(640.0, 360.0)
	camera.zoom = Vector2(1.0, 1.0)
	camera.offset = Vector2.ZERO
	
	player.shuttlecock = shuttlecock
	ai_rival.shuttlecock = shuttlecock
	player.opponent_player = ai_rival
	ai_rival.opponent_player = player
	
	player.shot_hit.connect(_on_shot_hit.bind("player"))
	ai_rival.shot_hit.connect(_on_shot_hit.bind("ai"))
	
	# Âm thanh rít giày chỉ phát khi người chơi bấm nút di chuyển (Tắt rít bên AI theo yêu cầu)
	player.shoe_squeak_triggered.connect(_on_shoe_squeak)
	
	# Hiệu ứng dậm nhảy bùng nổ mặt sàn
	player.jump_taken.connect(_on_jump_taken)
	ai_rival.jump_taken.connect(_on_jump_taken)
	
	shuttlecock.landed.connect(_on_shuttlecock_landed)
	shuttlecock.hit_net.connect(_on_shuttlecock_hit_net)
	
	if flash_rect:
		flash_rect.visible = false
	
	if grayscale_rect:
		grayscale_rect.visible = false
		if grayscale_rect.material:
			grayscale_rect.material.set_shader_parameter("grayscale_amount", 0.0)
	
	if nishikawa_lightning:
		nishikawa_lightning.draw.connect(_on_nishikawa_lightning_draw)
	if aoi_shield:
		aoi_shield.draw.connect(_on_aoi_shield_draw)
	
	# Background Court Texture (Sân đấu Full HD 1920x1080 dạng ảnh tĩnh siêu thực thay thế toàn bộ vector)
	var bg_court = Sprite2D.new()
	bg_court.name = "BackgroundCourt"
	bg_court.texture = preload("res://assets/images/stadium_court.png")
	bg_court.position = Vector2(640.0, 360.0)
	bg_court.scale = Vector2(1280.0 / 1920.0, 720.0 / 1080.0)
	bg_court.z_index = -100
	add_child(bg_court)
	move_child(bg_court, 0)
	
	# Đảm bảo gương phản chiếu sàn thi đấu luôn hiển thị sắc nét trên mọi độ phân giải & Fullscreen
	var floor_refl = get_node_or_null("FloorReflection")
	if floor_refl:
		floor_refl.visible = true
		_update_floor_reflection()
		get_viewport().size_changed.connect(_update_floor_reflection)
	
	# Tách riêng hiệu ứng động (shockwave, burst, jump takeoff) ra overlay độc lập để không vẽ lại toàn bộ sân vận động
	effects_overlay = Node2D.new()
	effects_overlay.name = "EffectsOverlay"
	effects_overlay.z_index = 50
	add_child(effects_overlay)
	effects_overlay.draw.connect(_on_effects_overlay_draw)
	
	# Âm thanh môi trường sân thi đấu nhẹ nhàng liên tục (Khử hiện tượng ngắt âm nền đột ngột ở tai nghe)
	amb_player = AudioStreamPlayer.new()
	amb_player.name = "AMBStadium"
	var amb_stream = preload("res://assets/audio/stadium_ambience.wav")
	if amb_stream is AudioStreamWAV:
		(amb_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	amb_player.stream = amb_stream
	amb_player.volume_db = -24.0
	amb_player.bus = "Master"
	add_child(amb_player)
	amb_player.play()
	
	if btn_settings:
		btn_settings.pressed.connect(_toggle_settings_panel)
	if btn_close_settings:
		btn_close_settings.pressed.connect(func(): if settings_panel: settings_panel.visible = false)
	
	if btn_easy and btn_medium and btn_hard:
		btn_easy.pressed.connect(func(): set_ai_difficulty(0))
		btn_medium.pressed.connect(func(): set_ai_difficulty(1))
		btn_hard.pressed.connect(func(): set_ai_difficulty(2))
	
	if btn_squeak:
		btn_squeak.pressed.connect(func():
			squeak_enabled = not squeak_enabled
			_update_settings_ui()
		)
		
	_update_settings_ui()
	_setup_hud_stamina_bars()
	
	# Khởi tạo PvP Network Manager
	net_manager = PvPNetworkManager.new()
	add_child(net_manager)
	net_manager.packet_received.connect(_on_network_packet_received)
	net_manager.peer_disconnected.connect(_on_network_peer_disconnected)
	
	# Khởi tạo Main Menu & Match Setup (Kaiser Shuttle UI)
	main_menu = MainMenuController.new()
	$HUD.add_child(main_menu)
	main_menu.set_network_manager(net_manager)
	main_menu.start_match_requested.connect(_on_menu_start_match)
	main_menu.start_pvp_match_requested.connect(_on_menu_start_pvp_match)
	main_menu.settings_updated.connect(_on_menu_settings_updated)
	
	if btn_char_select:
		btn_char_select.pressed.connect(func():
			_set_in_game_hud_visible(false)
			main_menu.switch_state(MainMenuController.MenuState.MATCH_SETUP)
			main_menu.visible = true
			if bgm_lobby and not bgm_lobby.playing:
				bgm_lobby.volume_db = -3.0
				bgm_lobby.play()
		)
		
	if label_player_badge and player and player.stats:
		label_player_badge.text = player.stats.character_name.to_upper()
	if label_rival_badge and ai_rival and ai_rival.stats:
		label_rival_badge.text = ai_rival.stats.character_name.to_upper()
		
	# Phát nhạc nền sảnh chờ BWF Li-Ning
	if bgm_lobby:
		if bgm_lobby.stream is AudioStreamOggVorbis:
			(bgm_lobby.stream as AudioStreamOggVorbis).loop = true
		bgm_lobby.volume_db = -3.0
		bgm_lobby.play()
		
	# Mở Main Menu ngay khi vào game và ẩn toàn bộ in-game HUD
	_set_in_game_hud_visible(false)
	main_menu.visible = true
	main_menu.switch_state(MainMenuController.MenuState.TITLE)


func _set_in_game_hud_visible(show: bool) -> void:
	if bwf_scoreboard:
		bwf_scoreboard.visible = show
	if scoreboard:
		scoreboard.visible = false # Legacy scoreboard stays hidden
	if controls_bar:
		controls_bar.visible = show
	if btn_char_select:
		btn_char_select.visible = show
	if btn_settings:
		btn_settings.visible = show
	if not show and label_banner:
		label_banner.visible = false
	if not show and pill_stats:
		pill_stats.visible = false
	if stamina_bar_bg_player:
		stamina_bar_bg_player.visible = show
	if stamina_bar_bg_ai:
		stamina_bar_bg_ai.visible = show


func _play_sfx_string() -> void:
	if not sfx_string or sfx_string_streams.is_empty():
		return
	var n = sfx_string_streams.size()
	var idx = randi() % n
	if n > 1 and idx == last_string_idx:
		idx = (idx + 1) % n
	last_string_idx = idx
	sfx_string.stream = sfx_string_streams[idx]
	sfx_string.pitch_scale = randf_range(0.97, 1.03)
	sfx_string.play()


func _on_shoe_squeak() -> void:
	if not squeak_enabled or not sfx_squeak or sfx_squeak_streams.is_empty():
		return
	var now = Time.get_ticks_msec()
	if now - last_squeak_msec < SQUEAK_MIN_INTERVAL_MS:
		return
	last_squeak_msec = now
	
	var n = sfx_squeak_streams.size()
	var idx = randi() % n
	if n > 1 and idx == last_squeak_idx:
		idx = (idx + 1 + (randi() % (n - 1))) % n
	last_squeak_idx = idx
	
	# Ngắt âm trước đó để tránh phát đè lên nhau khi spam nút di chuyển:
	if sfx_squeak.playing:
		sfx_squeak.stop()
		
	sfx_squeak.stream = sfx_squeak_streams[idx]
	sfx_squeak.pitch_scale = randf_range(0.97, 1.04)
	sfx_squeak.play()


func _on_jump_taken(takeoff_pos: Vector2, facing_dir: float) -> void:
	jump_takeoff_effects.append({
		"pos": takeoff_pos,
		"timer": 0.35,
		"dur": 0.35,
		"dir": facing_dir
	})
	_redraw_effects()


func _redraw_effects() -> void:
	if effects_overlay:
		effects_overlay.queue_redraw()


func _toggle_settings_panel() -> void:
	if not settings_panel:
		return
	settings_panel.visible = not settings_panel.visible
	_update_settings_ui()


func _toggle_character_select() -> void:
	if not main_menu:
		return
	if main_menu.visible and main_menu.current_state == MainMenuController.MenuState.MATCH_SETUP:
		main_menu.visible = false
		_set_in_game_hud_visible(true)
	else:
		_set_in_game_hud_visible(false)
		main_menu.switch_state(MainMenuController.MenuState.MATCH_SETUP)
		main_menu.visible = true


func _on_menu_start_match(p_id: String, r_id: String, diff: int, target_points: int = 11, match_sets: int = 1) -> void:
	target_match_points = target_points
	total_match_sets = match_sets
	current_set_index = 0
	sets_won_player = 0
	sets_won_ai = 0
	score_player = 0
	score_ai = 0
	current_server = "player"
	
	if shuttlecock:
		shuttlecock.is_network_client = false
	
	if match_over_dialog:
		match_over_dialog.visible = false
	_set_in_game_hud_visible(true)
	if player:
		match p_id:
			"nishikawa": player.stats = CharacterStats.create_nishikawa()
			"fuji": player.stats = CharacterStats.create_fuji()
			"wall": player.stats = CharacterStats.create_wall()
			_: player.stats = CharacterStats.create_nishikawa()
		player.move_speed_x = lerp(230.0, 265.0, (player.stats.agility - 40.0) / 59.0)
		if player.stats:
			player.stats.reset_stamina()
			player.stats.reset_torque()
		
	if ai_rival:
		match r_id:
			"nishikawa": ai_rival.stats = CharacterStats.create_nishikawa()
			"fuji": ai_rival.stats = CharacterStats.create_fuji()
			"wall": ai_rival.stats = CharacterStats.create_wall()
			_: ai_rival.stats = CharacterStats.create_wall()
		ai_rival.move_speed_x = lerp(230.0, 265.0, (ai_rival.stats.agility - 40.0) / 59.0)
		if ai_rival.stats:
			ai_rival.stats.reset_stamina()
			ai_rival.stats.reset_torque()
		ai_rival.reset_in_match_learning()
		set_ai_difficulty(diff)
		
	# Cập nhật tên huy hiệu trên HUD
	if label_player_badge and player and player.stats:
		label_player_badge.text = player.stats.character_name.to_upper()
	if label_rival_badge and ai_rival and ai_rival.stats:
		label_rival_badge.text = ai_rival.stats.character_name.to_upper()
		
	# Khởi tạo bảng điểm BWF chuẩn truyền hình
	if bwf_scoreboard:
		bwf_scoreboard.reset_scoreboard(total_match_sets)
		var p_name = p_id.to_upper()
		var r_name = r_id.to_upper()
		if player and player.stats:
			p_name = player.stats.character_name.split("(")[0].strip_edges().to_upper()
		if ai_rival and ai_rival.stats:
			r_name = ai_rival.stats.character_name.split("(")[0].strip_edges().to_upper()
		var flag_p1 = "JP" if p_id == "nishikawa" or p_id == "fuji" else "DK"
		var flag_p2 = "DK" if r_id == "wall" else "JP"
		bwf_scoreboard.set_players(p_name, r_name, flag_p1, flag_p2)
		bwf_scoreboard.update_current_score(0, 0)
		bwf_scoreboard.set_server(false)
		
	# Reset điểm và bắt đầu giao cầu
	_update_scoreboard()
	_setup_serve("player")
	_play_umpire_opening_call("player")
		
	# Dừng nhạc sảnh chờ khi vào trận (fade-out 0.8s)
	if bgm_lobby and bgm_lobby.playing:
		var tween = create_tween()
		tween.tween_property(bgm_lobby, "volume_db", -35.0, 0.8)
		tween.finished.connect(func():
			if bgm_lobby:
				bgm_lobby.stop()
				bgm_lobby.volume_db = -3.0
		)


func _on_menu_settings_updated(sq: bool) -> void:
	squeak_enabled = sq
	_update_settings_ui()

func _create_char_stats(char_id: String) -> CharacterStats:
	match char_id:
		"nishikawa": return CharacterStats.create_nishikawa()
		"fuji": return CharacterStats.create_fuji()
		"wall": return CharacterStats.create_wall()
		_: return CharacterStats.create_nishikawa()

func _on_menu_start_pvp_match(room_code: String, is_host: bool, local_char: String, target_points: int, match_sets: int) -> void:
	is_pvp_active = true
	is_pvp_host = is_host
	pvp_room_code = room_code
	pvp_local_char = local_char
	target_match_points = target_points
	total_match_sets = match_sets
	current_set_index = 0
	sets_won_player = 0
	sets_won_ai = 0
	score_player = 0
	score_ai = 0
	current_server = "player"
	
	if shuttlecock:
		shuttlecock.is_network_client = true
	
	if match_over_dialog:
		match_over_dialog.visible = false
	_set_in_game_hud_visible(true)
	
	# TRONG PVP: CẢ 2 NGƯỜI CHƠI ĐỀU LUÔN ĐIỀU KHIỂN NHÂN VẬT SÂN TRÁI CỦA MÌNH ($Player)
	# ĐỐI THỦ LUÔN HIỆN Ở SÂN PHẢI ($AIRival) VÀ BỊ KHÓA HOÀN TOÀN BÀN PHÍM (is_remote_puppet = true)
	player.is_ai = false
	player.is_remote_puppet = false
	player.court_side = "player"
	player.facing = 1.0
	player.min_x = 20.0
	player.max_x = 620.0
	
	ai_rival.is_ai = false
	ai_rival.is_remote_puppet = true
	ai_rival.court_side = "ai"
	ai_rival.facing = -1.0
	ai_rival.min_x = 660.0
	ai_rival.max_x = 1260.0
	
	player.stats = _create_char_stats(local_char)
	player.move_speed_x = lerp(230.0, 265.0, (player.stats.agility - 40.0) / 59.0)
	
	if is_host:
		ai_rival.stats = _create_char_stats("wall")
		ai_rival.move_speed_x = lerp(230.0, 265.0, (ai_rival.stats.agility - 40.0) / 59.0)
		net_manager.send_packet({
			"t": "init",
			"char": local_char,
			"pts": target_points,
			"sets": match_sets
		})
	else:
		ai_rival.stats = _create_char_stats("nishikawa")
		ai_rival.move_speed_x = lerp(230.0, 265.0, (ai_rival.stats.agility - 40.0) / 59.0)
		net_manager.send_packet({
			"t": "init_ack",
			"char": local_char
		})
		
	if player.stats:
		player.stats.reset_stamina()
		player.stats.reset_torque()
	if ai_rival.stats:
		ai_rival.stats.reset_stamina()
		ai_rival.stats.reset_torque()
		
	if bwf_scoreboard:
		bwf_scoreboard.reset_scoreboard(total_match_sets)
		bwf_scoreboard.set_match_mode(total_match_sets)
		bwf_scoreboard.set_players(
			player.stats.character_name.to_upper(),
			ai_rival.stats.character_name.to_upper()
		)
		bwf_scoreboard.update_current_score(0, 0)
		bwf_scoreboard.set_server(false)
		
	_update_scoreboard()
	_setup_serve("player")
	_show_banner("BẠN ĐANG Ở SÂN TRÁI - ĐỐI THỦ Ở SÂN PHẢI!", Color(0.2, 0.9, 0.8))
	
	if bgm_lobby and bgm_lobby.playing:
		var tween = create_tween()
		tween.tween_property(bgm_lobby, "volume_db", -35.0, 0.8)
		tween.finished.connect(func():
			if bgm_lobby:
				bgm_lobby.stop()
				bgm_lobby.volume_db = -3.0
		)

func _on_network_packet_received(data: Dictionary) -> void:
	if not is_pvp_active:
		return
	var t = str(data.get("t", ""))
	match t:
		"tick":
			# Both players receive p1 (local left) and p2 (opponent right) from server
			var p2_data = data.get("p2", {})
			if p2_data is Dictionary and ai_rival:
				ai_rival.global_position.x = lerp(ai_rival.global_position.x, float(p2_data.get("x", ai_rival.global_position.x)), 0.65)
				ai_rival.global_position.y = lerp(ai_rival.global_position.y, float(p2_data.get("y", ai_rival.global_position.y)), 0.65)
				ai_rival.velocity.x = float(p2_data.get("vx", 0.0))
				ai_rival.velocity.y = float(p2_data.get("vy", 0.0))
				ai_rival.facing = float(p2_data.get("f", -1.0))
				ai_rival.is_swinging = bool(p2_data.get("sw", false))
				ai_rival.is_diving = bool(p2_data.get("dv", false))

			var ball_data = data.get("ball", {})
			if ball_data is Dictionary and shuttlecock:
				shuttlecock.global_position.x = lerp(shuttlecock.global_position.x, float(ball_data.get("x", shuttlecock.global_position.x)), 0.70)
				shuttlecock.global_position.y = lerp(shuttlecock.global_position.y, float(ball_data.get("y", shuttlecock.global_position.y)), 0.70)
				shuttlecock.velocity.x = float(ball_data.get("vx", 0.0))
				shuttlecock.velocity.y = float(ball_data.get("vy", 0.0))
				shuttlecock.is_active = bool(ball_data.get("act", false))
				shuttlecock.is_serve = bool(ball_data.get("srv", false))

		"shot_fx":
			var shot_type = str(data.get("shot_type", "clear"))
			var is_smash = bool(data.get("is_smash", false))
			if is_smash and sfx_smash:
				sfx_smash.play()
			elif sfx_phong:
				sfx_phong.play()

		"point_scored":
			var winner_role = str(data.get("winner", "p1"))
			var reason = str(data.get("reason", "ĐIỂM TRỰC TIẾP"))
			var is_my_point = (winner_role == "p1" and is_pvp_host) or (winner_role == "p2" and not is_pvp_host)
			
			score_player = int(data.get("p1_pts", score_player)) if is_pvp_host else int(data.get("p2_pts", score_player))
			score_ai = int(data.get("p2_pts", score_ai)) if is_pvp_host else int(data.get("p1_pts", score_ai))
			sets_won_player = int(data.get("p1_sets", sets_won_player)) if is_pvp_host else int(data.get("p2_sets", sets_won_player))
			sets_won_ai = int(data.get("p2_sets", sets_won_ai)) if is_pvp_host else int(data.get("p1_sets", sets_won_ai))
			
			_update_scoreboard()
			if is_my_point:
				_show_banner("ĐIỂM CHO BẠN! - " + reason, Color(0.2, 1.0, 0.4), true, 1.5)
			else:
				_show_banner("ĐIỂM ĐỐI THỦ! - " + reason, Color(1.0, 0.4, 0.4), true, 1.5)

		"serve_ready":
			var srv_role = str(data.get("server", "p1"))
			var i_am_server = (srv_role == "p1" and is_pvp_host) or (srv_role == "p2" and not is_pvp_host)
			current_server = "player" if i_am_server else "ai"
			current_state = MatchState.SERVE
			is_serve_in_progress = true
			if i_am_server:
				_show_banner("LƯỢT BẠN PHÁT CẦU (BẤM J HOẶC K)", Color(0.95, 0.85, 0.2))
			else:
				_show_banner("ĐỐI THỦ ĐANG PHÁT CẦU...", Color(0.7, 0.8, 0.9))

		"match_over":
			var match_winner = str(data.get("winner", "p1"))
			var i_won = (match_winner == "p1" and is_pvp_host) or (match_winner == "p2" and not is_pvp_host)
			_show_match_over_dialog("player" if i_won else "ai")

		"init":
			if not is_pvp_host:
				var host_char = str(data.get("char", "nishikawa"))
				target_match_points = int(data.get("pts", 11))
				total_match_sets = int(data.get("sets", 1))
				ai_rival.stats = _create_char_stats(host_char)
				ai_rival.move_speed_x = lerp(230.0, 265.0, (ai_rival.stats.agility - 40.0) / 59.0)
				if bwf_scoreboard:
					bwf_scoreboard.reset_scoreboard(total_match_sets)
					bwf_scoreboard.set_match_mode(total_match_sets)
					bwf_scoreboard.set_players(
						player.stats.character_name.to_upper(),
						ai_rival.stats.character_name.to_upper()
					)
				net_manager.send_packet({"t": "init_ack", "char": pvp_local_char})
		"init_ack":
			if is_pvp_host:
				var guest_char = str(data.get("char", "wall"))
				ai_rival.stats = _create_char_stats(guest_char)
				ai_rival.move_speed_x = lerp(230.0, 265.0, (ai_rival.stats.agility - 40.0) / 59.0)
				if bwf_scoreboard:
					bwf_scoreboard.set_players(
						player.stats.character_name.to_upper(),
						ai_rival.stats.character_name.to_upper()
					)
		"h_sync":
			if not is_pvp_host:
				# Cập nhật đối thủ trên máy Guest ($AIRival ở sân phải):
				ai_rival.global_position.x = lerp(ai_rival.global_position.x, float(data.get("ox", ai_rival.global_position.x)), 0.75)
				ai_rival.global_position.y = lerp(ai_rival.global_position.y, float(data.get("oy", ai_rival.global_position.y)), 0.75)
				ai_rival.velocity.x = float(data.get("ovx", 0.0))
				ai_rival.velocity.y = float(data.get("ovy", 0.0))
				ai_rival.facing = float(data.get("of", -1.0))
				ai_rival.is_swinging = bool(data.get("osw", false))
				ai_rival.is_diving = bool(data.get("odv", false))
				
				# Cập nhật quả cầu trên máy Guest:
				shuttlecock.global_position = Vector2(float(data.get("bx", 640.0)), float(data.get("by", 300.0)))
				shuttlecock.velocity = Vector2(float(data.get("bvx", 0.0)), float(data.get("bvy", 0.0)))
				shuttlecock.rotation = float(data.get("brot", 0.0))
				shuttlecock.is_active = bool(data.get("bact", false))
				shuttlecock.is_serve = bool(data.get("bsrv", false))
				shuttlecock.last_hitter = "ai" if str(data.get("blast", "")) == "opponent" else "player"
				
				# Cập nhật điểm số trên máy Guest:
				score_player = int(data.get("p1_pts", score_player))
				score_ai = int(data.get("p2_pts", score_ai))
				sets_won_player = int(data.get("s1_sets", sets_won_player))
				sets_won_ai = int(data.get("s2_sets", sets_won_ai))
				current_server = "player" if str(data.get("srv", "")) == "player" else "ai"
				current_state = int(data.get("st", current_state))
				_update_scoreboard()
		"g_pos":
			if is_pvp_host:
				# Cập nhật đối thủ trên máy Host ($AIRival ở sân phải):
				ai_rival.global_position.x = lerp(ai_rival.global_position.x, float(data.get("ox", ai_rival.global_position.x)), 0.75)
				ai_rival.global_position.y = lerp(ai_rival.global_position.y, float(data.get("oy", ai_rival.global_position.y)), 0.75)
				ai_rival.velocity.x = float(data.get("ovx", 0.0))
				ai_rival.velocity.y = float(data.get("ovy", 0.0))
				ai_rival.facing = float(data.get("of", -1.0))
				ai_rival.is_swinging = bool(data.get("osw", false))
				ai_rival.is_diving = bool(data.get("odv", false))
		"g_hit":
			if is_pvp_host:
				_on_shot_hit(
					str(data.get("type", "clear")),
					bool(data.get("smash", false)),
					float(data.get("q", 0.8)),
					bool(data.get("perf", false)),
					bool(data.get("jump", false)),
					Vector2(float(data.get("px", 800.0)), float(data.get("py", 400.0))),
					"ai"
				)
		"g_serve":
			if is_pvp_host and current_state == MatchState.SERVE and current_server == "ai":
				_execute_serve("ai", str(data.get("shot_type", "clear")))

func _on_network_peer_disconnected(reason: String) -> void:
	if is_pvp_active:
		_show_banner("ĐỐI THỦ ĐÃ NGẮT KẾT NỐI! (" + reason + ")", Color(1.0, 0.4, 0.4))
		is_pvp_active = false
		get_tree().create_timer(2.5).timeout.connect(func():
			if main_menu:
				main_menu.switch_state(MainMenuController.MenuState.TITLE)
				main_menu.visible = true
				_set_in_game_hud_visible(false)
		)

func _unhandled_input(event: InputEvent) -> void:
	if main_menu and main_menu.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				if main_menu.current_state in [MainMenuController.MenuState.MATCH_SETUP, MainMenuController.MenuState.PVP_LOBBY, MainMenuController.MenuState.SETTINGS]:
					if net_manager:
						net_manager.disconnect_peer()
					main_menu.switch_state(MainMenuController.MenuState.TITLE)
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			_toggle_character_select()
		elif event.keycode == KEY_ESCAPE:
			_set_in_game_hud_visible(false)
			main_menu.switch_state(MainMenuController.MenuState.TITLE)
			main_menu.visible = true
		elif event.keycode == KEY_1:
			set_ai_difficulty(0)
		elif event.keycode == KEY_2:
			set_ai_difficulty(1)
		elif event.keycode == KEY_3:
			set_ai_difficulty(2)
		elif event.keycode == KEY_O:
			_toggle_settings_panel()


func set_ai_difficulty(diff: int) -> void:
	if not ai_rival:
		return
	ai_rival.ai_difficulty = diff
	_update_settings_ui()
	var diff_names = ["DỄ", "TRUNG BÌNH", "KHÓ"]
	var d_str = diff_names[clamp(diff, 0, 2)]
	print("Độ khó AI được đặt thành: %s" % d_str)
	if is_inside_tree() and label_banner and current_state != MatchState.POINT_OVER:
		var orig_text = label_banner.text
		label_banner.text = "AI: %s" % d_str
		get_tree().create_timer(1.2).timeout.connect(func():
			if label_banner and label_banner.text == "AI: %s" % d_str:
				label_banner.text = orig_text
		)


func _update_settings_ui() -> void:
	if not ai_rival:
		return
	var cur = ai_rival.ai_difficulty
	if btn_easy:
		btn_easy.modulate = Color(3.5, 2.8, 0.4) if cur == 0 else Color(0.75, 0.75, 0.75, 0.8)
	if btn_medium:
		btn_medium.modulate = Color(3.5, 2.8, 0.4) if cur == 1 else Color(0.75, 0.75, 0.75, 0.8)
	if btn_hard:
		btn_hard.modulate = Color(3.5, 2.8, 0.4) if cur == 2 else Color(0.75, 0.75, 0.75, 0.8)
		
	if btn_squeak:
		btn_squeak.text = "BẬT" if squeak_enabled else "TẮT"
		btn_squeak.modulate = Color(1.2, 3.2, 1.2) if squeak_enabled else Color(1.8, 0.6, 0.6)
		
	if btn_settings:
		btn_settings.modulate = Color(3.2, 2.6, 0.5) if (settings_panel and settings_panel.visible) else Color(1.0, 1.0, 1.0)


func _update_difficulty_buttons() -> void:
	_update_settings_ui()


func _process(delta: float) -> void:
	# Cố định tâm camera tuyệt đối tại giữa màn hình (tránh mọi lỗi trôi/lệch khung)
	camera.position = Vector2(640.0, 360.0)
	
	# Đồng bộ kích thước phản chiếu sàn ngay tức thì khi chuyển đổi Fullscreen / Maximize
	var cur_win = Vector2(DisplayServer.window_get_size())
	if cur_win != _last_window_size and cur_win.x > 0.0 and cur_win.y > 0.0:
		_update_floor_reflection()
	
	_update_hud_stamina_bars()
	
	# Camera Screen Shake
	if shake_amount > 0.0:
		camera.offset = Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
		shake_amount = move_toward(shake_amount, 0.0, delta * 55.0)
	else:
		camera.offset = Vector2.ZERO
	
	# Impact Flash decay
	if flash_alpha > 0.0:
		flash_alpha = move_toward(flash_alpha, 0.0, delta * 12.0)
		if flash_rect:
			flash_rect.color = Color(1.0, 1.0, 1.0, flash_alpha)
			flash_rect.visible = (flash_alpha > 0.01)
	
	# Shockwave animation
	if shockwave_alpha > 0.0:
		shockwave_radius += delta * 280.0
		shockwave_alpha = move_toward(shockwave_alpha, 0.0, delta * 3.5)
		_redraw_effects()
	
	# Perfect Hit Burst decay
	if perfect_burst_timer > 0.0:
		perfect_burst_timer = max(0.0, perfect_burst_timer - delta)
		_redraw_effects()
		
	# Floating Combat Text update (chữ PERFECT bay nhẹ lên trên)
	if floating_text_mgr and floating_text_mgr.update(delta):
		_redraw_effects()
	
	# Jump Takeoff Effects update
	if not jump_takeoff_effects.is_empty():
		var need_redraw = false
		for i in range(jump_takeoff_effects.size() - 1, -1, -1):
			var eff = jump_takeoff_effects[i]
			eff["timer"] -= delta
			need_redraw = true
			if eff["timer"] <= 0.0:
				jump_takeoff_effects.remove_at(i)
		if need_redraw:
			_redraw_effects()
	
	# Nishikawa Lightning update:
	# Giai đoạn 1: Slow-mo chung với game (bò từ từ quanh vợt và quả cầu, bị đảo màu trắng đen)
	# Giai đoạn 2: Sau khi hết slow-mo (đập cầu) -> Tỏa ra bình thường ở tốc độ 100% rồi biến mất
	if impact_lightning_active:
		if impact_lightning_in_slowmo:
			var elapsed_real = (Time.get_ticks_msec() - impact_start_ticks) / 1000.0
			var p_slow = clamp(elapsed_real / SLOWMO_LIGHTNING_DURATION, 0.0, 1.0)
			# Trong 1s slow-mo, tia sét bò chậm từ 0 -> 28% độ dài quanh vợt và cầu
			impact_lightning_anim_t = p_slow * 0.28
			impact_lightning_p_burst = 0.0
		else:
			impact_lightning_burst_timer += delta
			var p_burst = clamp(impact_lightning_burst_timer / BURST_LIGHTNING_DURATION, 0.0, 1.0)
			impact_lightning_p_burst = p_burst
			# Khi hết slow-mo, phóng tỏa cực nhanh ở tốc độ bình thường từ 28% -> 100%
			impact_lightning_anim_t = lerp(0.28, 1.0, p_burst)
			if p_burst >= 1.0:
				impact_lightning_active = false
		
		if nishikawa_lightning:
			nishikawa_lightning.queue_redraw()
	
	# Isabel Mirage Shield Animation update (dùng real-time ticks để bung mượt suốt 1.55s slow-mo):
	if aoi_shield_active:
		var elapsed_real = (Time.get_ticks_msec() - aoi_shield_start_ticks) / 1000.0
		aoi_shield_timer = elapsed_real
		if aoi_shield_timer >= aoi_shield_duration:
			aoi_shield_active = false
		if aoi_shield:
			aoi_shield.queue_redraw()
	
	# Fuji Emerald Gale Slow-mo Animation update (Cơn lốc xanh ngưng đọng real-time):
	if fuji_slowmo_active:
		var elapsed_real = (Time.get_ticks_msec() - fuji_slowmo_start_ticks) / 1000.0
		fuji_slowmo_timer = elapsed_real
		if fuji_slowmo_timer >= FUJI_SLOWMO_DURATION:
			fuji_slowmo_active = false
		_redraw_effects()
	
	# Authoritative WebSocket PvP Multiplayer Sync (Mirrored 100% independent low-latency)
	if is_pvp_active and net_manager:
		net_manager.send_packet({
			"t": "player_input",
			"x": player.global_position.x,
			"y": player.global_position.y,
			"vx": player.velocity.x,
			"vy": player.velocity.y,
			"sw": player.is_swinging,
			"dv": player.is_diving
		})
	
	_update_stats_display()
	
	# Mở khóa đánh cầu cho bên nhận cầu ngay lập tức (Zero delay, không cần đợi cầu bay qua lưới)
	if current_state == MatchState.RALLY and shuttlecock.is_active:
		if shuttlecock.last_hitter == "player":
			ai_rival.can_hit = true
		elif shuttlecock.last_hitter == "ai":
			player.can_hit = true
		prev_shuttle_x = shuttlecock.global_position.x
	
	# In SERVE state: player input to serve
	if current_state == MatchState.SERVE:
		_process_serve_state()
	
	# Reset match key (R)
	if Input.is_key_pressed(KEY_R):
		score_player = 0
		score_ai = 0
		_update_scoreboard()
		if ai_rival:
			ai_rival.reset_in_match_learning()
		_setup_serve("player")
		if sfx_low_ball_play:
			sfx_low_ball_play.play()


func _update_stats_display() -> void:
	if not label_spike_stats:
		return
	
	var is_smash_event = shuttlecock and (shuttlecock.is_smash or shuttlecock.is_boom_smash or shuttlecock.is_kill_smash)
	if pill_stats:
		pill_stats.visible = is_smash_event
		
	if not is_smash_event:
		return
		
	var speed_val = current_shot_max_speed
	var p_jump = max(FLOOR_Y - player.global_position.y, 0.0) / 45.0
	var ai_jump = max(FLOOR_Y - ai_rival.global_position.y, 0.0) / 45.0
	var jump_height_m = max(p_jump, ai_jump)
	
	var tension_str = ""
	if rally_tension and rally_tension.tension_level > 0:
		tension_str = "   •   %s" % rally_tension.get_status_text()
	
	if shuttlecock.is_boom_smash:
		label_spike_stats.text = "%.0f km/h  •  %.2fm%s  [GOLDEN BOOM!]" % [speed_val, jump_height_m, tension_str]
		label_spike_stats.modulate = Color(3.8, 2.5, 0.4, 1.0)
	elif shuttlecock.is_kill_smash:
		label_spike_stats.text = "%.0f km/h  •  %.2fm%s  [KILL SMASH]" % [speed_val, jump_height_m, tension_str]
		label_spike_stats.modulate = Color(3.5, 1.5, 0.3, 1.0)
	else:
		label_spike_stats.text = "%.0f km/h  •  %.2fm%s  [SMASH]" % [speed_val, jump_height_m, tension_str]
		label_spike_stats.modulate = Color(3.0, 1.8, 0.3, 1.0)


func _play_umpire_opening_call(server: String = "player") -> void:
	is_umpire_speaking = true
	if sfx_low_ball_play:
		sfx_low_ball_play.play()
	if label_banner:
		label_banner.visible = false
		label_banner.text = ""
	
	get_tree().create_timer(1.7).timeout.connect(func():
		is_umpire_speaking = false
		if current_state == MatchState.SERVE:
			var server_name = "PLAYER" if server == "player" else "RIVAL AI"
			_show_banner("%s GIAO CẦU (BẤM J HOẶC K)" % server_name, Color(1.0, 1.0, 1.0))
			if server == "ai" and not is_pvp_active:
				get_tree().create_timer(0.8).timeout.connect(func():
					if current_state == MatchState.SERVE and current_server == "ai" and not is_umpire_speaking and not is_pvp_active:
						var is_short = randf() < 0.35
						var shot_type = "drop" if is_short else "clear"
						_execute_serve("ai", shot_type)
				)
	)


func _process_serve_state() -> void:
	if main_menu and main_menu.visible:
		return
	if is_umpire_speaking:
		return
	if is_pvp_active:
		if current_server == "player" and net_manager:
			if Input.is_key_pressed(KEY_K):
				net_manager.send_packet({"t": "serve", "shot_type": "clear"})
			elif Input.is_key_pressed(KEY_J):
				net_manager.send_packet({"t": "serve", "shot_type": "drop"})
		return
	else:
		if current_server == "player":
			if Input.is_key_pressed(KEY_K):
				# High Deep Serve to opponent baseline
				_execute_serve("player", "clear")
			elif Input.is_key_pressed(KEY_J):
				# Short Serve skimming over net
				_execute_serve("player", "drop")


func _setup_serve(server: String) -> void:
	current_state = MatchState.SERVE
	current_server = server
	is_serve_in_progress = false
	previous_shot_type = ""
	
	if rally_tension:
		rally_tension.reset()
	
	# Phục hồi an toàn tuyệt đối mọi trạng thái hiệu ứng, tránh lỗi kẹt màn hình hay timescale
	Engine.time_scale = 1.0
	camera.position = Vector2(640.0, 360.0)
	camera.zoom = Vector2(1.0, 1.0)
	camera.offset = Vector2.ZERO
	shake_amount = 0.0
	impact_lightning_active = false
	if grayscale_rect:
		grayscale_rect.visible = false
		if grayscale_rect.material:
			grayscale_rect.material.set_shader_parameter("grayscale_amount", 0.0)
	if sfx_electric and sfx_electric.playing:
		sfx_electric.stop()
	if shuttlecock:
		shuttlecock.is_suspended_in_smash_slowmo = false
		shuttlecock.tension_speed_mult = 1.0
		shuttlecock.tension_level = 0
	if player:
		player.pending_smash_target = Vector2.ZERO
		player.swing_cooldown = 0.0
		player.current_tension_mult = 1.0
		player.current_tension_level = 0
	if ai_rival:
		ai_rival.pending_smash_target = Vector2.ZERO
		ai_rival.swing_cooldown = 0.0
		ai_rival.current_tension_mult = 1.0
		ai_rival.current_tension_level = 0
		if ai_rival.ai_pressure_model:
			ai_rival.ai_pressure_model.reset()
	
	player.reset_position(390.0, FLOOR_Y)
	ai_rival.reset_position(890.0, FLOOR_Y)
	
	# Movement strictly locked during serve
	player.is_serving_phase = true
	ai_rival.is_serving_phase = true
	
	var serve_pos = Vector2(390.0, FLOOR_Y - 35.0) if server == "player" else Vector2(890.0, FLOOR_Y - 35.0)
	shuttlecock.global_position = serve_pos
	shuttlecock.velocity = Vector2.ZERO
	shuttlecock.is_active = false
	shuttlecock.is_serve = false
	prev_shuttle_x = serve_pos.x
	
	if is_umpire_speaking:
		if label_banner:
			label_banner.visible = false
			label_banner.text = ""
	else:
		var server_name = "PLAYER" if server == "player" else "RIVAL AI"
		_show_banner("%s GIAO CẦU (BẤM J HOẶC K)" % server_name, Color(1.0, 1.0, 1.0))
		
		# AI auto serve after 0.8s (only if not in PvP)
		if server == "ai" and not is_pvp_active:
			get_tree().create_timer(0.8).timeout.connect(func():
				if current_state == MatchState.SERVE and current_server == "ai" and not is_umpire_speaking and not is_pvp_active:
					var is_short = randf() < 0.35
					var shot_type = "drop" if is_short else "clear"
					_execute_serve("ai", shot_type)
			)


func _execute_serve(server: String, shot_type: String = "clear") -> void:
	current_state = MatchState.RALLY
	is_serve_in_progress = true
	
	if rally_tension:
		rally_tension.reset()
	if player:
		player.current_tension_mult = 1.0
		player.current_tension_level = 0
	if ai_rival:
		ai_rival.current_tension_mult = 1.0
		ai_rival.current_tension_level = 0
	
	# UNLOCK MOVEMENT FOR BOTH PLAYERS
	player.is_serving_phase = false
	ai_rival.is_serving_phase = false
	
	# Xóa thông báo giao cầu ngay khi bắt đầu pha cầu
	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()
	if label_banner:
		label_banner.visible = false
		label_banner.text = ""
	
	var from_pos = Vector2(player.global_position.x + 30.0, FLOOR_Y - 35.0) if server == "player" else Vector2(ai_rival.global_position.x - 30.0, FLOOR_Y - 35.0)
	var target_pos: Vector2
	if server == "player":
		# Khi giao ngắn (drop): target 815px (vượt qua vạch SHORT_SERVICE_RIGHT 785px)
		target_pos = Vector2(1070.0, FLOOR_Y) if shot_type == "clear" else Vector2(815.0, FLOOR_Y)
	else:
		# Khi AI giao ngắn: target 465px (vượt qua vạch SHORT_SERVICE_LEFT 495px)
		target_pos = Vector2(210.0, FLOOR_Y) if shot_type == "clear" else Vector2(465.0, FLOOR_Y)
	
	shuttlecock.is_serve = true
	shuttlecock.last_hitter = server
	shuttlecock.launch_to_target_2d(from_pos, target_pos, shot_type, 0.0, false, false, 1.0, 0)
	previous_shot_type = shot_type
	
	current_shot_max_speed = (86.0 if shot_type == "drop" else 104.0) + randf_range(-3.5, 3.5)
	if shot_type == "drop":
		_play_sfx_string()
	else:
		sfx_phong.play()
	
	if server == "player":
		player.can_hit = false
		ai_rival.can_hit = true
	else:
		ai_rival.can_hit = false
		player.can_hit = true


func _world_to_screen(world_pos: Vector2) -> Vector2:
	if not camera:
		return world_pos
	var cam_center = camera.position + camera.offset
	var vp_size = get_viewport_rect().size
	return (world_pos - cam_center) * camera.zoom + vp_size * 0.5


func _on_shot_hit(shot_type: String, is_smash: bool, quality: float, is_perfect: bool, is_jump_shot: bool, contact_pos: Vector2, hitter: String) -> void:
	if is_pvp_active and net_manager and hitter == "player":
		net_manager.send_packet({
			"t": "hit",
			"shot_type": shot_type,
			"is_smash": is_smash,
			"is_perf": is_perfect,
			"px": contact_pos.x,
			"py": contact_pos.y
		})
	is_serve_in_progress = false
	if shuttlecock:
		shuttlecock.is_serve = false
	
	# Cập nhật Dynamic Rally Tension 2.0 (Heat Meter System)
	var tension_lvl = 0
	var tension_mult = 1.0
	if rally_tension:
		var is_boom_shot = (shot_type == "boom_smash" or (is_smash and quality >= 0.88))
		tension_lvl = rally_tension.add_shot(shot_type, is_smash, is_boom_shot)
		tension_mult = rally_tension.get_speed_multiplier()
	
	if player:
		player.current_tension_mult = tension_mult
		player.current_tension_level = tension_lvl
	if ai_rival:
		ai_rival.current_tension_mult = tension_mult
		ai_rival.current_tension_level = tension_lvl
		if hitter == "player":
			ai_rival.record_opponent_shot(shot_type, contact_pos.x)
		if ai_rival.ai_pressure_model:
			if (is_smash or shot_type == "smash" or shot_type == "boom_smash") and hitter == "player":
				ai_rival.ai_pressure_model.on_opponent_smash(shot_type == "boom_smash")
			elif shot_type == "drop":
				# Đòn bỏ nhỏ êm dịu làm nguội bớt áp lực tâm lý của AI
				ai_rival.ai_pressure_model.cool_down_pressure(0.08)
	
	var is_jump_smash = (is_jump_shot or shot_type == "kill_smash") and (is_smash or shot_type == "smash" or shot_type == "boom_smash" or shot_type == "kill_smash")
	var hitter_node = player if hitter == "player" else ai_rival
	var torque_mult = hitter_node.stats.get_effective_smash_speed_mult() if (hitter_node and hitter_node.stats) else 1.0
	
	# Ghi nhận trạng thái cú đánh trước đó (để phát hiện cú đỡ cầu đập bằng drop)
	var was_incoming_smash = (previous_shot_type == "smash" or previous_shot_type == "boom_smash" or previous_shot_type == "kill_smash")
	previous_shot_type = shot_type

	# 1. NISHIKAWA GOLDEN SMASH (boom_smash): Ngưng đọng 1s, sấm sét nổ vang, đảo màu trắng đen!
	if shot_type == "boom_smash" and is_perfect:
		var base_spd = 192.0
		current_shot_max_speed = (base_spd + (quality * 8.0) + randf_range(-4.0, 4.0)) * tension_mult * torque_mult
		_trigger_perfect_impact_effect(contact_pos, hitter)
		return
		
	# 2. TSUBAME GAESHI (Fuji): Cắt xoáy lướt sà sát mép lưới, góc cắm hiểm kèm slow-mo (KHÔNG TRẮNG ĐEN)
	if shot_type == "tsubame_gaeshi":
		current_shot_max_speed = (104.0 + randf_range(-3.0, 3.0)) * tension_mult
		if is_perfect and floating_text_mgr:
			floating_text_mgr.spawn("PERFECT!", contact_pos + Vector2(0, -22), Color(1.0, 0.92, 0.25), 16)
		_trigger_fuji_cinematic_slowmo(contact_pos, hitter)
		return
		
	# 3. MIRAGE COUNTER (The Wall): Hóa giải smash, bung cầu cao nhanh về cuối sân và hồi 20% thể lực kèm slow-mo (KHÔNG TRẮNG ĐEN)
	if shot_type == "mirage_counter":
		var shield_center = hitter_node.global_position + Vector2(0.0, -32.0) if hitter_node else contact_pos
		_trigger_aoi_shield_effect(shield_center)
		_trigger_aoi_cinematic_slowmo(contact_pos, hitter)
		
		current_shot_max_speed = (122.0 + randf_range(-3.0, 3.0)) * tension_mult
		if is_perfect and floating_text_mgr:
			floating_text_mgr.spawn("PERFECT!", contact_pos + Vector2(0, -22), Color(1.0, 0.92, 0.25), 16)
		return

	# Hiển thị chữ PERFECT bay nhẹ lên trên tại vị trí đánh (Không hiện banner to giữa màn hình):
	if is_perfect and floating_text_mgr:
		floating_text_mgr.spawn("PERFECT!", contact_pos + Vector2(0, -22), Color(1.0, 0.92, 0.25), 16)

	var dist_to_net = abs(contact_pos.x - 640.0)

	# Các cú đánh thông thường khác:
	if shot_type == "weak_return":
		sfx_phong.play()
		current_shot_max_speed = (72.0 + randf_range(-2.0, 2.0))
		shake_amount = 1.0
		_show_banner("CHANCE BALL!", Color(1.0, 1.0, 1.0), true, 1.0)
	elif is_smash or shot_type == "smash" or shot_type == "kill_smash":
		sfx_smash.play()
		var is_kill = (shot_type == "kill_smash")
		var base_spd = 180.0 if is_kill else 142.0
		current_shot_max_speed = (base_spd + (quality * 7.0) + randf_range(-4.2, 4.2)) * tension_mult * torque_mult
		
		# Screen shake & impact flash theo lực đập thông thường:
		shake_amount = 22.0 if is_kill else 14.0
		flash_alpha = 0.45 if is_kill else 0.28
		if flash_rect:
			flash_rect.visible = true
		
	elif shot_type == "drop":
		# PHÂN LOẠI DROP:
		# 1. Đỡ cầu đập bằng drop HOẶC drop sát mép lưới -> Âm thanh string.wav
		# 2. Cắt / chém drop từ sau sân -> Âm thanh chem_cau.wav
		var is_near_net_drop = (dist_to_net < 220.0) or (shuttlecock and shuttlecock.is_net_drop)
		if was_incoming_smash or is_near_net_drop:
			_play_sfx_string()
		else:
			if sfx_chem:
				sfx_chem.pitch_scale = randf_range(0.95, 1.05)
				sfx_chem.play()
			else:
				sfx_phong.play()
				
		if shuttlecock and shuttlecock.is_net_drop:
			current_shot_max_speed = (78.0 + randf_range(-3.0, 3.0)) * tension_mult
			shake_amount = 2.0
		else:
			var base_spd = 90.0 if is_perfect else 80.0
			current_shot_max_speed = (base_spd + randf_range(-3.2, 3.2)) * tension_mult
			shake_amount = 4.0 if is_perfect else 2.0
	elif shot_type == "clear" or shot_type == "underhand_lift":
		# PHÂN LOẠI CLEAR / LIFT:
		# Nếu bung cầu gần lưới -> Âm thanh string.wav
		# Nếu phông sâu từ đáy sân -> Âm thanh phong.wav
		if dist_to_net < 220.0:
			_play_sfx_string()
		else:
			if sfx_phong:
				sfx_phong.pitch_scale = randf_range(0.97, 1.04)
				sfx_phong.play()
				
		var base_spd = 112.0 if is_perfect else (100.0 if quality > 0.7 else 88.0)
		current_shot_max_speed = (base_spd + (quality * 5.0) + randf_range(-3.5, 3.5)) * tension_mult
		shake_amount = 6.0 if is_perfect else max(shake_amount, 2.5)
	else:
		if sfx_phong:
			sfx_phong.pitch_scale = randf_range(0.97, 1.04)
			sfx_phong.play()
		var base_spd = 112.0 if is_perfect else (100.0 if quality > 0.7 else 88.0)
		current_shot_max_speed = (base_spd + (quality * 5.0) + randf_range(-3.5, 3.5)) * tension_mult
		shake_amount = 6.0 if is_perfect else max(shake_amount, 2.5)


func _trigger_perfect_impact_effect(hit_pos: Vector2, hitter: String = "player") -> void:
	# 1. Đảo màu toàn bộ game sang trắng đen (không flash màn hình trắng)
	flash_alpha = 0.0
	if flash_rect:
		flash_rect.visible = false
	if grayscale_rect and grayscale_rect.material:
		grayscale_rect.visible = true
		grayscale_rect.material.set_shader_parameter("grayscale_amount", 1.0)
	
	# 2. Phát âm thanh tích điện giật sấm sét (Electric Sound) trong lúc ngưng đọng
	if sfx_electric:
		sfx_electric.pitch_scale = randf_range(0.96, 1.04)
		sfx_electric.play()
	
	# 3. Khởi tạo sấm sét màu vàng Nishikawa chính xác tại điểm chạm vợt (1 đợt duy nhất)
	impact_lightning_pos = hit_pos
	impact_start_ticks = Time.get_ticks_msec()
	impact_lightning_active = true
	impact_lightning_in_slowmo = true
	impact_lightning_burst_timer = 0.0
	impact_lightning_anim_t = 0.0
	impact_lightning_p_burst = 0.0
	_generate_nishikawa_branches()
	if nishikawa_lightning:
		nishikawa_lightning.queue_redraw()
	
	# 4. SUPER SLOW-MOTION (LÚC VỢT SẮP CHẠM CẦU - CẦU ĐANG LƠ LỬNG TRƯỚC MẶT VỢT):
	# Tốc độ thời gian 0.05 (5% tốc độ thực). Cả động tác tay vung, quả cầu, người chơi
	# và cả tia sấm sét đều bò chậm rãi trong super slow-mo, quả cầu CHƯA BỊ ĐẬP!
	Engine.time_scale = 0.05
	if camera:
		camera.zoom = Vector2(1.08, 1.08)
	
	# Chờ đúng 1.0 giây thời gian thực tế (wall-clock time)
	var tree = get_tree()
	if tree:
		await tree.create_timer(1.0, true, false, true).timeout
	
	# 5. KHI HẾT 1S SLOW-MO: LÚC NÀY MỚI THỰC SỰ ĐẬP CẦU!
	# Tia sét chuyển sang giai đoạn phóng tỏa ở tốc độ 100% bình thường
	impact_lightning_in_slowmo = false
	impact_lightning_burst_timer = 0.0
	
	if sfx_electric and sfx_electric.playing:
		sfx_electric.stop()
	if sfx_smash:
		sfx_smash.play()
	shake_amount = 35.0
	
	# THỰC HIỆN CÚ ĐẬP: Phóng quả cầu đi với tốc độ cực đại lúc này!
	var hitter_node = player if hitter == "player" else ai_rival
	if hitter_node:
		hitter_node.execute_pending_smash()
	
	# Phục hồi tốc độ game bình thường
	Engine.time_scale = 1.0
	
	# Phục hồi êm ái màu sắc game từ trắng đen đảo màu về bình thường và nhả zoom
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if grayscale_rect and grayscale_rect.material:
		tw.tween_method(func(val: float):
			if grayscale_rect and grayscale_rect.material:
				grayscale_rect.material.set_shader_parameter("grayscale_amount", val)
				if val <= 0.01:
					grayscale_rect.visible = false
		, 1.0, 0.0, 0.22)
	if camera:
		tw.tween_property(camera, "zoom", Vector2(1.0, 1.0), 0.22)


func _trigger_fuji_cinematic_slowmo(hit_pos: Vector2, hitter: String = "player") -> void:
	# 1. Phát âm thanh lúc tiếp xúc vợt (tiếng chạm string đanh + tiếng gió cánh én):
	_play_sfx_string()
	if sfx_fuji_wind:
		sfx_fuji_wind.pitch_scale = randf_range(0.98, 1.02)
		sfx_fuji_wind.play()
		
	# 2. Khởi tạo hiệu ứng slow-mo Cơn lốc xanh (Emerald Gale Vortex):
	fuji_slowmo_center = hit_pos
	fuji_slowmo_start_ticks = Time.get_ticks_msec()
	fuji_slowmo_timer = 0.0
	fuji_slowmo_facing = 1.0 if hitter == "player" else -1.0
	fuji_slowmo_leaves.clear()
	
	# Sinh 14 lá trúc bay lượn xoáy ốc quanh tâm chém gió
	var leaf_cols = [
		Color(0.25, 0.90, 0.40),
		Color(0.18, 0.82, 0.35),
		Color(0.50, 0.98, 0.45),
		Color(0.20, 0.95, 0.65),
		Color(0.70, 0.92, 0.30)
	]
	for i in range(14):
		fuji_slowmo_leaves.append({
			"ang0": randf_range(0, TAU),
			"dist0": randf_range(16.0, 36.0),
			"dist_speed": randf_range(70.0, 140.0),
			"spin_dir": 1.0 if randf() < 0.7 else -1.0,
			"spin_speed": randf_range(6.0, 12.0),
			"size": randf_range(8.0, 13.0),
			"col": leaf_cols[randi() % leaf_cols.size()]
		})
	fuji_slowmo_active = true
	_redraw_effects()
		
	# 3. Cinematic Super Slow-mo tại điểm chạm vợt (GIỮ NGUYÊN MÀU SẮC ĐỒ HỌA, TUYỆT ĐỐI KHÔNG TRẮNG ĐEN)
	if grayscale_rect:
		grayscale_rect.visible = false
	shake_amount = 14.0
	Engine.time_scale = 0.05
	if camera:
		camera.zoom = Vector2(1.08, 1.08)
		
	var tree = get_tree()
	if tree:
		await tree.create_timer(FUJI_SLOWMO_DURATION, true, false, true).timeout
		
	# 4. KHI HẾT 0.48S SLOW-MO: VUNG VỢT VÀ THỰC SỰ PHÓNG CẦU ĐI!
	fuji_slowmo_active = false
	_redraw_effects()
	var hitter_node = player if hitter == "player" else ai_rival
	if hitter_node:
		hitter_node.execute_pending_special()
		
	# Phát âm thanh chém xé gió khi quả cầu vút đi qua mép lưới:
	if sfx_chem:
		sfx_chem.pitch_scale = randf_range(1.05, 1.14)
		sfx_chem.play()
		
	# Phục hồi tốc độ game bình thường và trả zoom camera êm ái
	Engine.time_scale = 1.0
	if camera:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(camera, "zoom", Vector2(1.0, 1.0), 0.22)


func _trigger_aoi_cinematic_slowmo(hit_pos: Vector2, hitter: String = "player") -> void:
	# 1. Phát âm thanh lúc slow-mo của AOI (aoi slowmo effect)
	if sfx_aoi_slowmo:
		sfx_aoi_slowmo.pitch_scale = randf_range(0.98, 1.02)
		sfx_aoi_slowmo.play()
		
	# 2. Cinematic Super Slow-mo tại điểm chạm vợt (GIỮ NGUYÊN MÀU SẮC ĐỒ HỌA, TUYỆT ĐỐI KHÔNG TRẮNG ĐEN)
	if grayscale_rect:
		grayscale_rect.visible = false
	shake_amount = 14.0
	Engine.time_scale = 0.05
	if camera:
		camera.zoom = Vector2(1.08, 1.08)
		
	var tree = get_tree()
	if tree:
		# Thời gian kéo dài hiệu ứng slow-mo khớp chính xác với thời lượng 1.55s của audio aoi_slowmo
		await tree.create_timer(1.55, true, false, true).timeout
		
	# 3. KHI HẾT 1.55S SLOW-MO: BẮT ĐẦU ĐÁNH BÓNG - TIẾNG ĐÁNH BÓNG THAY BẰNG TIẾNG AOI BLOCK!
	var hitter_node = player if hitter == "player" else ai_rival
	if hitter_node:
		hitter_node.execute_pending_special()
		
	# Tiếng đánh bóng được thay bằng tiếng AOI block theo yêu cầu người dùng:
	if sfx_aoi_block:
		sfx_aoi_block.pitch_scale = randf_range(0.98, 1.02)
		sfx_aoi_block.play()
		
	# Phục hồi tốc độ game bình thường và trả zoom camera êm ái
	Engine.time_scale = 1.0
	if camera:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(camera, "zoom", Vector2(1.0, 1.0), 0.22)


func _generate_nishikawa_branches() -> void:
	impact_lightning_branches.clear()
	# CHỈ 1 ĐỢT TỎA DUY NHẤT: Bùng nổ từ tâm ra ngoài trong suốt 1s slow-mo
	var n_bolts: int = 16
	var bolts: Array = []
	for b_idx in range(n_bolts):
		var base_ang = (TAU / float(n_bolts)) * b_idx + randf_range(-0.25, 0.25)
		var max_len = randf_range(220.0, 310.0)
		var n_segs = randi_range(7, 9)
		
		var pts: Array[Vector2] = [Vector2.ZERO]
		var cur_v = Vector2.ZERO
		var dir_main = Vector2(cos(base_ang), sin(base_ang))
		var perp = Vector2(-dir_main.y, dir_main.x)
		
		for s in range(n_segs):
			var s_len = (max_len / float(n_segs)) * randf_range(0.85, 1.25)
			var zigzag = perp * randf_range(-25.0, 25.0)
			cur_v += dir_main * s_len + zigzag
			pts.append(cur_v)
		
		# Nhánh phụ (Sub-branches rễ cây sấm sét)
		var sub_data: Array = []
		if randf() < 0.75 and pts.size() >= 4:
			var f_idx = randi_range(2, pts.size() - 2)
			var f_pt = pts[f_idx]
			var f_ang = base_ang + randf_range(0.40, 0.75) * (1.0 if randf() < 0.5 else -1.0)
			var f_dir = Vector2(cos(f_ang), sin(f_ang))
			var f_perp = Vector2(-f_dir.y, f_dir.x)
			var f_len = randf_range(50.0, 110.0)
			var s_pts: Array[Vector2] = [f_pt]
			var f_cur = f_pt
			for fs in range(3):
				f_cur += f_dir * (f_len / 3.0) + f_perp * randf_range(-14.0, 14.0)
				s_pts.append(f_cur)
			sub_data.append({"pts": s_pts, "fork_u": float(f_idx) / float(pts.size() - 1)})
		
		bolts.append({
			"pts": pts,
			"subs": sub_data,
			"max_len": max_len
		})
	
	# Hạt tia lửa điện (flying sparks) của đợt duy nhất này
	var sparks: Array = []
	for sp in range(20):
		var sp_ang = randf_range(0, TAU)
		var sp_speed = randf_range(180.0, 320.0)
		sparks.append({"ang": sp_ang, "speed": sp_speed, "len": randf_range(14.0, 30.0)})
	
	impact_lightning_branches = [{
		"bolts": bolts,
		"sparks": sparks
	}]


func _on_nishikawa_lightning_draw() -> void:
	if not impact_lightning_active:
		return
	
	var t = clamp(impact_lightning_anim_t, 0.0, 1.0)
	if t >= 1.0 and not impact_lightning_in_slowmo:
		return
	
	# Vì NishikawaLightning là Node2D trong world Main (đứng trước HUD / GrayscaleRect),
	# nên vị trí trực tiếp trong world space là impact_lightning_pos!
	var origin = impact_lightning_pos
	
	# 1. Tâm cầu năng lượng chớp giật
	var pulse_speed = 1.6 if impact_lightning_in_slowmo else 6.0
	var pulse = fmod((Time.get_ticks_msec() / 1000.0) * pulse_speed, 1.0)
	var cr_r1 = 18.0 + pulse * 36.0
	var cr_alpha = (1.0 - pulse) * (1.0 - t * 0.7)
	nishikawa_lightning.draw_arc(origin, cr_r1, 0, TAU, 32, Color(3.8, 2.8, 0.3, cr_alpha * 0.75), 2.2, true)
	nishikawa_lightning.draw_circle(origin, 15.0 * (1.0 - t * 0.85), Color(4.8, 4.4, 2.0, 0.95 * (1.0 - t * 0.7)))
	nishikawa_lightning.draw_circle(origin, 30.0 * (1.0 - t * 0.85), Color(3.8, 2.6, 0.2, 0.50 * (1.0 - t * 0.7)))
	
	# 2. CHỈ 1 ĐỢT TỎA DUY NHẤT: Lan tỏa từ tâm ra ngoài, to ra nhỏ, đoạn trước thu nhỏ rồi mất
	if impact_lightning_branches.is_empty():
		return
	var wave_data = impact_lightning_branches[0]
	
	# ĐOẠN ĐẦU CỦA TIA SÉT: Phóng từ tâm ra ngoài
	var u_head = clamp(t * 1.25, 0.0, 1.0)
	
	# ĐOẠN ĐUÔI CỦA TIA SÉT: Trong slow-mo (t <= 0.28) đuôi vẫn ở gốc (0.0).
	# Khi sang giai đoạn phóng tỏa ở tốc độ thường, đuôi co lại và tiêu biến:
	var u_tail = 0.0
	if not impact_lightning_in_slowmo:
		u_tail = clamp((impact_lightning_p_burst - 0.15) / 0.85, 0.0, 1.0)
	
	if u_tail >= u_head:
		return
	
	var wave_alpha = clamp(1.0 - u_tail * 0.88, 0.0, 1.0)
	var bolts: Array = wave_data["bolts"]
	
	for b in bolts:
		var pts: Array[Vector2] = b["pts"]
		var n_pts = pts.size()
		if n_pts < 2:
			continue
		var m_segs = n_pts - 1
		
		# Cắt đoạn tia sét đang hoạt động giữa u_tail và u_head
		var active_pts = PackedVector2Array()
		
		# Điểm đầu tại u_tail
		var k_tail = int(floor(u_tail * m_segs))
		k_tail = clamp(k_tail, 0, m_segs - 1)
		var frac_tail = (u_tail * m_segs) - float(k_tail)
		var p_tail = pts[k_tail].lerp(pts[k_tail + 1], frac_tail)
		active_pts.append(origin + p_tail)
		
		# Các đỉnh trung gian
		for k in range(k_tail + 1, m_segs + 1):
			var u_k = float(k) / float(m_segs)
			if u_k >= u_head:
				break
			var jitter = Vector2(randf_range(-4.5, 4.5), randf_range(-4.5, 4.5)) * (1.0 - u_k * 0.4)
			active_pts.append(origin + pts[k] + jitter)
		
		# Điểm ngọn tại u_head
		var k_head = int(floor(u_head * m_segs))
		k_head = clamp(k_head, 0, m_segs - 1)
		var frac_head = (u_head * m_segs) - float(k_head)
		var p_head = pts[k_head].lerp(pts[k_head + 1], frac_head)
		active_pts.append(origin + p_head)
		
		if active_pts.size() < 2:
			continue
		
		# ĐỘ DÀY: Gần tâm u=0 rất to (8.0px), ra ngoài u=1 vuốt nhọn (1.8px) rồi nhỏ dần biến mất
		var u_mid = (u_tail + u_head) * 0.5
		var stroke_w = lerp(8.0, 1.8, u_mid) * (1.0 - u_tail * 0.65)
		
		# 1. Hào quang vàng hổ phách ngoài cùng
		var halo_col = Color(1.0, 0.72, 0.05, wave_alpha * 0.65)
		nishikawa_lightning.draw_polyline(active_pts, halo_col, stroke_w * 1.6, true)
		
		# 2. Vầng sáng vàng kim rực rỡ
		var glow_col = Color(3.8, 2.6, 0.25, wave_alpha * 0.90)
		nishikawa_lightning.draw_polyline(active_pts, glow_col, stroke_w, true)
		
		# 3. Lõi sét trắng vàng chói lòa
		var core_col = Color(4.8, 4.4, 2.0, wave_alpha * 0.98)
		nishikawa_lightning.draw_polyline(active_pts, core_col, stroke_w * 0.45, true)
		
		# Nhánh phụ (Sub-forks)
		var subs: Array = b["subs"]
		for sub_data in subs:
			var fork_u: float = sub_data["fork_u"]
			if u_tail <= fork_u and u_head >= fork_u:
				var s_fork = clamp((u_head - fork_u) / (1.0 - fork_u), 0.0, 1.0)
				var sub_pts: Array[Vector2] = sub_data["pts"]
				if sub_pts.size() >= 2:
					var f_active = PackedVector2Array()
					var s_n = sub_pts.size()
					var f_count = int(ceil(s_fork * float(s_n)))
					f_count = clamp(f_count, 2, s_n)
					for f_i in range(f_count):
						var f_jitt = Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
						f_active.append(origin + sub_pts[f_i] + f_jitt)
					if f_active.size() >= 2:
						nishikawa_lightning.draw_polyline(f_active, glow_col, stroke_w * 0.7, true)
						nishikawa_lightning.draw_polyline(f_active, core_col, stroke_w * 0.35, true)
	
	# Hạt tia lửa điện phóng ra theo sóng (Flying electric sparks)
	var sparks: Array = wave_data["sparks"]
	for sp in sparks:
		var sp_dist = sp["speed"] * t * (1.0 - t * 0.25)
		var sp_ang = sp["ang"]
		var sp_dir = Vector2(cos(sp_ang), sin(sp_ang))
		var sp_start = origin + sp_dir * sp_dist
		var sp_end = sp_start + sp_dir * (sp["len"] * (1.0 - t * 0.8))
		nishikawa_lightning.draw_line(sp_start, sp_end, Color(4.8, 4.2, 1.8, wave_alpha * 0.9), 1.8 * (1.0 - t * 0.7), true)


func _trigger_aoi_shield_effect(pos: Vector2) -> void:
	aoi_shield_center = pos
	aoi_shield_active = true
	aoi_shield_start_ticks = Time.get_ticks_msec()
	aoi_shield_timer = 0.0
	if aoi_shield:
		aoi_shield.queue_redraw()


func _on_aoi_shield_draw() -> void:
	if not aoi_shield_active or not aoi_shield:
		return
		
	var p = clamp(aoi_shield_timer / aoi_shield_duration, 0.0, 1.0)
	# Expands outward with smooth cubic ease-out:
	var expand_t = 1.0 - pow(1.0 - p, 2.5)
	var r_main = lerp(20.0, 76.0, expand_t)
	var r_outer = lerp(24.0, 115.0, expand_t)
	var alpha = 1.0 - pow(p, 1.3)
	
	# 1. Soft radial energy core glow
	aoi_shield.draw_circle(aoi_shield_center, r_main * 0.65, Color(0.12, 0.60, 1.0, alpha * 0.28))
	
	# 2. Glowing Hexagonal Aegis Barrier
	var hex_pts = PackedVector2Array()
	var spin = p * 0.25
	for i in range(6):
		var ang = (TAU / 6.0) * i - (PI / 6.0) + spin
		hex_pts.append(aoi_shield_center + Vector2(cos(ang), sin(ang)) * r_main)
	
	var hex_loop = hex_pts.duplicate()
	hex_loop.append(hex_pts[0])
	
	# Translucent cyan barrier interior
	aoi_shield.draw_colored_polygon(hex_pts, Color(0.08, 0.45, 0.90, alpha * 0.22))
	# Glowing cyan-blue hex outline
	aoi_shield.draw_polyline(hex_loop, Color(0.30, 0.82, 1.0, alpha * 0.95), 3.2, true)
	# Inner bright white-blue rim
	aoi_shield.draw_polyline(hex_loop, Color(0.85, 0.96, 1.0, alpha * 0.75), 1.4, true)
	
	# 3. Radiant Aegis Crest Lines (Tia sáng chữ thập tỏa sáng ở tâm khiên)
	var cross_len = r_main * 0.60
	aoi_shield.draw_line(aoi_shield_center - Vector2(cross_len, 0), aoi_shield_center + Vector2(cross_len, 0), Color(0.5, 0.9, 1.0, alpha * 0.65), 2.2, true)
	aoi_shield.draw_line(aoi_shield_center - Vector2(0, cross_len * 1.1), aoi_shield_center + Vector2(0, cross_len * 1.1), Color(0.5, 0.9, 1.0, alpha * 0.65), 2.2, true)
	
	# 4. Expanding Outer Shockwave Ring (Vòng sóng năng lượng tỏa ra xung quanh)
	aoi_shield.draw_arc(aoi_shield_center, r_outer, 0, TAU, 36, Color(0.35, 0.85, 1.0, (1.0 - p) * 0.65), 2.2, true)
	
	# 5. Hexagonal Shard Sparks (Các tia tinh thể năng lượng phân tán ra ngoài)
	for i in range(6):
		var ang = (TAU / 6.0) * i - (PI / 6.0) + spin
		var dir = Vector2(cos(ang), sin(ang))
		var spark_pos = aoi_shield_center + dir * (r_main + p * 28.0)
		var spark_r = max(0.8, 3.8 * (1.0 - p))
		aoi_shield.draw_circle(spark_pos, spark_r, Color(0.75, 0.95, 1.0, alpha * 0.90))


func _show_landing_callout(pos: Vector2, status: String, subtitle: String = "") -> void:
	# status: "IN", "OUT", "FAULT"
	var container = PanelContainer.new()
	container.z_index = 95
	
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.set_content_margin_all(5)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	
	var title_col = Color(0.25, 1.25, 0.5) # IN (Xanh ngọc rực rỡ)
	var bg_col = Color(0.04, 0.16, 0.08, 0.92)
	var border_col = Color(0.3, 1.1, 0.6, 0.95)
	
	if status == "OUT":
		title_col = Color(1.25, 0.25, 0.25) # OUT (Đỏ rực)
		bg_col = Color(0.18, 0.04, 0.04, 0.92)
		border_col = Color(1.0, 0.35, 0.35, 0.95)
	elif status == "FAULT":
		title_col = Color(1.25, 0.85, 0.2) # FAULT (Vàng hổ phách)
		bg_col = Color(0.18, 0.12, 0.03, 0.92)
		border_col = Color(1.0, 0.85, 0.3, 0.95)
		
	style.bg_color = bg_col
	style.border_color = border_col
	container.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var lbl_title = Label.new()
	lbl_title.text = status
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.modulate = title_col
	lbl_title.add_theme_font_size_override("font_size", 20)
	lbl_title.add_theme_constant_override("outline_size", 4)
	lbl_title.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05, 0.95))
	vbox.add_child(lbl_title)
	
	if subtitle != "":
		var lbl_sub = Label.new()
		lbl_sub.text = subtitle
		lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_sub.modulate = Color(0.95, 0.98, 1.0, 0.85)
		lbl_sub.add_theme_font_size_override("font_size", 10)
		lbl_sub.add_theme_constant_override("outline_size", 2)
		lbl_sub.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
		vbox.add_child(lbl_sub)
		
	container.add_child(vbox)
	
	# Canh giữa tại vị trí tiếp đất của quả cầu
	var spawn_x = clamp(pos.x - 45.0, 45.0, 1180.0)
	var spawn_y = FLOOR_Y - 55.0
	container.position = Vector2(spawn_x, spawn_y)
	container.scale = Vector2(0.65, 0.65)
	container.pivot_offset = Vector2(45.0, 22.0)
	add_child(container)
	
	# Pop-up animation nảy thể thao hiện đại:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(container, "scale", Vector2(1.05, 1.05), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(container, "position:y", spawn_y - 25.0, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(container, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_property(container, "modulate:a", 0.0, 0.85).set_delay(0.35)
	tween.chain().tween_callback(container.queue_free)


func _on_shuttlecock_landed(pos: Vector2, _floor_3d: Vector3 = Vector3.ZERO) -> void:
	if current_state != MatchState.RALLY:
		return
	
	current_state = MatchState.POINT_OVER
	shake_amount = max(shake_amount, 14.0 if shuttlecock.is_smash else 4.0)
	
	shockwave_pos = pos
	shockwave_radius = 8.0
	shockwave_alpha = 0.9 if shuttlecock.is_smash else 0.5
	_redraw_effects()
	
	var point_winner = ""
	var reason = ""
	
	# 1. KIỂM TRA LUẬT PHÁT CẦU (SERVE FAULT CHECK)
	if is_serve_in_progress:
		is_serve_in_progress = false
		if current_server == "player":
			# Người chơi phát cầu: phải qua vạch SHORT_SERVICE_RIGHT (785px) và không ra ngoài
			if pos.x < SHORT_SERVICE_RIGHT:
				point_winner = "ai"
				reason = "GIAO CẦU CHƯA QUA VẠCH! ĐIỂM CHO RIVAL AI"
				_show_landing_callout(pos, "FAULT", "CHƯA QUA VẠCH")
			elif pos.x > RIGHT_OUT_X:
				point_winner = "ai"
				reason = "GIAO CẦU NGOÀI BIÊN! ĐIỂM CHO RIVAL AI"
				_show_landing_callout(pos, "OUT", "NGOÀI SÂN")
			else:
				point_winner = "player"
				reason = "ACE! ĐIỂM GIAO CẦU CHO PLAYER!"
				_show_landing_callout(pos, "IN", "+1 POINT")
		else:
			# AI phát cầu: phải qua vạch SHORT_SERVICE_LEFT (495px) và không ra ngoài
			if pos.x > SHORT_SERVICE_LEFT:
				point_winner = "player"
				reason = "GIAO CẦU CHƯA QUA VẠCH! ĐIỂM CHO PLAYER"
				_show_landing_callout(pos, "FAULT", "CHƯA QUA VẠCH")
			elif pos.x < LEFT_OUT_X:
				point_winner = "player"
				reason = "GIAO CẦU NGOÀI BIÊN! ĐIỂM CHO PLAYER"
				_show_landing_callout(pos, "OUT", "NGOÀI SÂN")
			else:
				point_winner = "ai"
				reason = "ACE! ĐIỂM GIAO CẦU CHO RIVAL AI!"
				_show_landing_callout(pos, "IN", "+1 POINT")
		
		_award_point(point_winner, reason)
		return
	
	# 2. RALLY BÌNH THƯỜNG
	if shuttlecock.is_net_fault:
		_show_landing_callout(pos, "FAULT", "CHƯA QUA LƯỚI")
		if shuttlecock.last_hitter == "player":
			point_winner = "ai"
			reason = "CẦU KHÔNG QUA LƯỚI! ĐIỂM CHO RIVAL AI"
		else:
			point_winner = "player"
			reason = "CẦU KHÔNG QUA LƯỚI! ĐIỂM CHO PLAYER"
	elif pos.x < LEFT_OUT_X or pos.x > RIGHT_OUT_X:
		_show_landing_callout(pos, "OUT", "NGOÀI SÂN")
		if shuttlecock.last_hitter == "player":
			point_winner = "ai"
			reason = "NGOÀI BIÊN! ĐIỂM CHO RIVAL AI"
		else:
			point_winner = "player"
			reason = "NGOÀI BIÊN! ĐIỂM CHO PLAYER"
	else:
		# In court
		_show_landing_callout(pos, "IN", "+1 POINT")
		if pos.x < NET_X:
			point_winner = "ai"
			reason = "ĐIỂM CHO RIVAL AI!"
		else:
			point_winner = "player"
			reason = "ĐIỂM CHO PLAYER!"
	
	_award_point(point_winner, reason)


func _on_shuttlecock_hit_net() -> void:
	if current_state != MatchState.RALLY:
		return
	shake_amount = max(shake_amount, 3.0)
	
	# Khóa ngay lập tức việc vung vợt đánh cầu của cả 2 bên khi cầu đã vướng lưới:
	shuttlecock.is_net_fault = true
	if player:
		player.can_hit = false
	if ai_rival:
		ai_rival.can_hit = false
	
	_show_landing_callout(shuttlecock.global_position, "FAULT", "CẦU MẮC LƯỚI")
	
	if is_serve_in_progress:
		is_serve_in_progress = false
		current_state = MatchState.POINT_OVER
		var winner = "ai" if current_server == "player" else "player"
		_award_point(winner, "GIAO CẦU MẮC LƯỚI! ĐIỂM CHO %s" % ("RIVAL" if winner == "ai" else "PLAYER"))
		return
	
	get_tree().create_timer(0.35).timeout.connect(func():
		if current_state == MatchState.RALLY:
			var hitter = shuttlecock.last_hitter
			var current_x = shuttlecock.global_position.x
			if (hitter == "player" and current_x < NET_X) or (hitter == "ai" and current_x > NET_X):
				current_state = MatchState.POINT_OVER
				var winner = "ai" if hitter == "player" else "player"
				_award_point(winner, "LỖI LƯỚI! ĐIỂM CHO %s" % ("RIVAL AI" if winner == "ai" else "PLAYER"))
	)


func _award_point(winner: String, reason: String) -> void:
	if winner == "player":
		score_player += 1
		if player and player.stats:
			player.stats.add_flow(15.0)
		_show_banner(reason, Color(0.4, 2.0, 0.6))
	else:
		score_ai += 1
		if ai_rival and ai_rival.stats:
			ai_rival.stats.add_flow(15.0)
		_show_banner(reason, Color(2.0, 0.4, 0.4))
	
	_update_scoreboard()
	
	# ==========================================================
	# BWF DEUCE & SET / MATCH WINNING RULES (LUẬT THI ĐẤU BWF)
	# ==========================================================
	var max_cap = 30 if target_match_points == 21 else (target_match_points + 6)
	var diff = abs(score_player - score_ai)
	var is_set_won = false
	var set_winner = ""
	
	if score_player >= target_match_points or score_ai >= target_match_points:
		if diff >= 2 or score_player >= max_cap or score_ai >= max_cap:
			is_set_won = true
			set_winner = "player" if score_player > score_ai else "ai"
		else:
			# Deuce: Cách 2 điểm mới ăn
			_show_banner("DEUCE! CÁCH 2 ĐIỂM ĐỂ THẮNG (%d - %d)" % [score_player, score_ai], Color(1.0, 0.88, 0.35))
	
	if is_set_won:
		current_state = MatchState.POINT_OVER
		var winner_is_ai = (set_winner == "ai")
		if winner_is_ai:
			sets_won_ai += 1
		else:
			sets_won_player += 1
			
		if bwf_scoreboard:
			bwf_scoreboard.finish_set(current_set_index, winner_is_ai)
			
		var is_match_over = false
		if total_match_sets == 1:
			is_match_over = true
		else:
			# Best of 3 sets: Thắng 2 set là vô địch
			if sets_won_player >= 2 or sets_won_ai >= 2:
				is_match_over = true
				
		if is_match_over:
			var champ = "PLAYER" if sets_won_player > sets_won_ai else "RIVAL AI"
			_show_match_over_dialog(champ)
			return
			
		# Chuyển sang Set tiếp theo trong trận 3 Set
		var set_banner = "KẾT THÚC SET %d! [TỈ SỐ SET: %d - %d]" % [current_set_index + 1, sets_won_player, sets_won_ai]
		_show_banner(set_banner, Color(1.0, 0.90, 0.25), false)
		await get_tree().create_timer(2.2).timeout
		
		current_set_index += 1
		score_player = 0
		score_ai = 0
		if bwf_scoreboard:
			bwf_scoreboard.advance_to_next_set()
			bwf_scoreboard.update_current_score(0, 0)
			
		# Người thắng set trước có quyền giao cầu set sau
		current_server = set_winner
		if bwf_scoreboard:
			bwf_scoreboard.set_server(current_server != "player")
		_setup_serve(current_server)
		return
	
	await get_tree().create_timer(1.2).timeout
	current_server = winner
	if bwf_scoreboard:
		bwf_scoreboard.set_server(current_server != "player")
	_setup_serve(current_server)


func _show_match_over_dialog(champ: String) -> void:
	if not match_over_dialog:
		match_over_dialog = PanelContainer.new()
		match_over_dialog.custom_minimum_size = Vector2(500, 250)
		match_over_dialog.position = Vector2(390, 235)
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.08, 0.13, 0.96)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.95, 0.82, 0.25, 0.95)
		sb.corner_radius_top_left = 12
		sb.corner_radius_top_right = 12
		sb.corner_radius_bottom_right = 12
		sb.corner_radius_bottom_left = 12
		sb.shadow_color = Color(0, 0, 0, 0.65)
		sb.shadow_size = 12
		match_over_dialog.add_theme_stylebox_override("panel", sb)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 24)
		margin.add_theme_constant_override("margin_top", 20)
		margin.add_theme_constant_override("margin_right", 24)
		margin.add_theme_constant_override("margin_bottom", 20)
		match_over_dialog.add_child(margin)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 14)
		margin.add_child(vbox)
		
		var lbl_title = Label.new()
		lbl_title.name = "LabelTitle"
		lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_title.add_theme_font_size_override("font_size", 20)
		vbox.add_child(lbl_title)
		
		var lbl_score_res = Label.new()
		lbl_score_res.name = "LabelScoreRes"
		lbl_score_res.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_score_res.add_theme_font_size_override("font_size", 28)
		lbl_score_res.modulate = Color(1.0, 1.0, 1.0)
		vbox.add_child(lbl_score_res)
		
		var lbl_sub = Label.new()
		lbl_sub.name = "LabelSub"
		lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_sub.add_theme_font_size_override("font_size", 12)
		lbl_sub.modulate = Color(0.70, 0.78, 0.88)
		vbox.add_child(lbl_sub)
		
		var btn_row = HBoxContainer.new()
		btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_row.add_theme_constant_override("separation", 16)
		vbox.add_child(btn_row)
		
		var btn_again = Button.new()
		btn_again.text = "CHƠI LẠI (PLAY AGAIN)"
		btn_again.custom_minimum_size = Vector2(190, 42)
		btn_again.add_theme_font_size_override("font_size", 13)
		var sb_again = StyleBoxFlat.new()
		sb_again.bg_color = Color(0.12, 0.40, 0.22, 0.95)
		sb_again.border_width_left = 1
		sb_again.border_width_top = 1
		sb_again.border_width_right = 1
		sb_again.border_width_bottom = 1
		sb_again.border_color = Color(0.35, 0.95, 0.55)
		sb_again.corner_radius_top_left = 6
		sb_again.corner_radius_top_right = 6
		sb_again.corner_radius_bottom_right = 6
		sb_again.corner_radius_bottom_left = 6
		btn_again.add_theme_stylebox_override("normal", sb_again)
		btn_again.pressed.connect(_on_match_over_play_again)
		btn_row.add_child(btn_again)
		
		var btn_menu = Button.new()
		btn_menu.text = "MENU CHÍNH (MAIN MENU)"
		btn_menu.custom_minimum_size = Vector2(190, 42)
		btn_menu.add_theme_font_size_override("font_size", 13)
		var sb_menu = StyleBoxFlat.new()
		sb_menu.bg_color = Color(0.18, 0.22, 0.32, 0.95)
		sb_menu.border_width_left = 1
		sb_menu.border_width_top = 1
		sb_menu.border_width_right = 1
		sb_menu.border_width_bottom = 1
		sb_menu.border_color = Color(0.45, 0.70, 0.95)
		sb_menu.corner_radius_top_left = 6
		sb_menu.corner_radius_top_right = 6
		sb_menu.corner_radius_bottom_right = 6
		sb_menu.corner_radius_bottom_left = 6
		btn_menu.add_theme_stylebox_override("normal", sb_menu)
		btn_menu.pressed.connect(_on_match_over_to_menu)
		btn_row.add_child(btn_menu)
		
		$HUD.add_child(match_over_dialog)
	
	var lbl_title = match_over_dialog.find_child("LabelTitle", true, false) as Label
	var lbl_score_res = match_over_dialog.find_child("LabelScoreRes", true, false) as Label
	var lbl_sub = match_over_dialog.find_child("LabelSub", true, false) as Label
	
	if lbl_title:
		lbl_title.text = "[ %s CHIẾN THẮNG TRẬN ĐẤU! ]" % champ
		lbl_title.modulate = Color(0.35, 2.0, 0.6) if champ == "PLAYER" else Color(2.0, 0.45, 0.45)
	if lbl_score_res:
		if total_match_sets == 1:
			lbl_score_res.text = "%d   -   %d" % [score_player, score_ai]
		else:
			lbl_score_res.text = "TỈ SỐ SET: %d   -   %d" % [sets_won_player, sets_won_ai]
	if lbl_sub:
		var mode_str = "1 SET" if total_match_sets == 1 else "BEST OF 3 SETS"
		lbl_sub.text = "THỂ THỨC: %s (CHẠM %d ĐIỂM) • BWF RULES" % [mode_str, target_match_points]
		
	match_over_dialog.visible = true


func _on_match_over_play_again() -> void:
	if match_over_dialog:
		match_over_dialog.visible = false
	current_set_index = 0
	sets_won_player = 0
	sets_won_ai = 0
	score_player = 0
	score_ai = 0
	if bwf_scoreboard:
		bwf_scoreboard.reset_scoreboard(total_match_sets)
		bwf_scoreboard.update_current_score(0, 0)
		bwf_scoreboard.set_server(false)
	_update_scoreboard()
	if player and player.stats:
		player.stats.reset_stamina()
		player.stats.reset_torque()
	if ai_rival and ai_rival.stats:
		ai_rival.stats.reset_stamina()
		ai_rival.stats.reset_torque()
		ai_rival.reset_in_match_learning()
	current_server = "player"
	_setup_serve("player")
	_play_umpire_opening_call("player")


func _on_match_over_to_menu() -> void:
	if match_over_dialog:
		match_over_dialog.visible = false
	_set_in_game_hud_visible(false)
	main_menu.switch_state(MainMenuController.MenuState.MATCH_SETUP)
	main_menu.visible = true
	if bgm_lobby and not bgm_lobby.playing:
		bgm_lobby.volume_db = -3.0
		bgm_lobby.play()


var _last_window_size: Vector2 = Vector2.ZERO

func _update_floor_reflection() -> void:
	var floor_refl = get_node_or_null("FloorReflection")
	if not floor_refl or not floor_refl.material:
		return
	var vp = get_viewport()
	if not vp:
		return
	var win_size = Vector2(DisplayServer.window_get_size())
	if win_size.x <= 0.0 or win_size.y <= 0.0:
		win_size = Vector2(1280.0, 720.0)
	_last_window_size = win_size
	
	# Tính chuẩn xác tuyệt đối tọa độ UV sàn theo chế độ canvas_items & keep aspect:
	# Cửa sổ nhỏ, Phóng to Maximized, Fullscreen 1080p, 2K, 4K, hay màn hình 16:10 / Ultrawide
	var scale_factor = min(win_size.x / 1280.0, win_size.y / 720.0)
	var rendered_h = 720.0 * scale_factor
	var offset_y = (win_size.y - rendered_h) * 0.5
	var floor_pixel_y = offset_y + FLOOR_Y * scale_factor
	var uv_y = clamp(floor_pixel_y / win_size.y, 0.1, 0.95)
	(floor_refl.material as ShaderMaterial).set_shader_parameter("floor_uv_y", uv_y)


func _update_scoreboard() -> void:
	if label_score:
		label_score.text = "%d  -  %d" % [score_player, score_ai]
	if bwf_scoreboard:
		bwf_scoreboard.update_current_score(score_player, score_ai)
		bwf_scoreboard.set_server(current_server != "player")


func _show_banner(text: String, col: Color, auto_hide: bool = false, duration: float = 1.0) -> void:
	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()
		
	label_banner.text = text
	label_banner.modulate = col
	label_banner.visible = true
	label_banner.scale = Vector2(1.25, 1.25)
	
	banner_tween = create_tween()
	banner_tween.tween_property(label_banner, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if auto_hide:
		banner_tween.tween_interval(duration)
		banner_tween.tween_property(label_banner, "modulate:a", 0.0, 0.22)
		banner_tween.tween_callback(func(): label_banner.visible = false)


# ==========================================================
# CLASSIC 2D BADMINTON LEAGUE ARENA (PHOTO 3 & 4 STYLE)
# ==========================================================

func _draw() -> void:
	# Toàn bộ sân vận động & mặt sân đã được pre-bake thành texture ảnh tĩnh 'stadium_court.png'
	# giúp tối ưu hóa vượt bậc, loại bỏ hơn 400 lệnh vẽ vector mỗi frame.
	pass


func _on_effects_overlay_draw() -> void:
	if not effects_overlay:
		return
		
	# 7. Ground Shockwave
	if shockwave_alpha > 0.01:
		var sw_col = Color(1.0, 0.95, 0.5, shockwave_alpha)
		effects_overlay.draw_arc(Vector2(shockwave_pos.x, FLOOR_Y), shockwave_radius, 0, TAU, 36, sw_col, 4.0, true)
		effects_overlay.draw_arc(Vector2(shockwave_pos.x, FLOOR_Y), shockwave_radius * 0.7, 0, TAU, 28, Color(1.0, 1.0, 1.0, shockwave_alpha * 0.7), 2.5, true)
		
	# 8. Golden Anime Perfect Impact Burst (Rực rỡ, lấp lánh và biến mất sau 0.4s)
	if perfect_burst_timer > 0.0:
		var p_prog = 1.0 - (perfect_burst_timer / 0.40)
		var burst_alpha = 1.0 - p_prog
		var r_outer = 25.0 + p_prog * 80.0
		var r_inner = 12.0 + p_prog * 40.0
		var col_burst = Color(perfect_burst_col.r, perfect_burst_col.g, perfect_burst_col.b, burst_alpha * 0.95)
		
		# Vòng hào quang sáng rực
		effects_overlay.draw_arc(perfect_burst_pos, r_outer, 0, TAU, 36, col_burst, 3.5, true)
		effects_overlay.draw_arc(perfect_burst_pos, r_inner, 0, TAU, 28, Color(1.0, 1.0, 1.0, burst_alpha), 2.0, true)
		
		# 8 tia chớp năng lượng phát tán theo các góc
		for i in range(8):
			var ang = (TAU / 8.0) * i + p_prog * 0.45
			var dir = Vector2(cos(ang), sin(ang))
			var p1 = perfect_burst_pos + dir * (r_inner * 0.6)
			var p2 = perfect_burst_pos + dir * (r_outer * 1.15)
			effects_overlay.draw_line(p1, p2, col_burst, 2.5, true)
	
	# 9. Jump Takeoff Burst & Floor Dust Skid Effects (Hiệu ứng dậm nhảy mặt sàn)
	for eff in jump_takeoff_effects:
		var timer: float = eff["timer"]
		var dur: float = eff["dur"]
		var prog: float = clamp(1.0 - (timer / dur), 0.0, 1.0)
		var p_pos: Vector2 = eff["pos"]
		var alpha: float = (1.0 - prog) * 0.90
		
		# Vòng nén sàn elip nở rộng sang 2 bên
		var rx = 16.0 + prog * 58.0
		var ry = 4.0 + prog * 9.0
		var ring_col = Color(1.0, 0.95, 0.75, alpha * 0.85)
		effects_overlay.draw_arc(p_pos, rx, 0, TAU, 28, ring_col, 3.0 * (1.0 - prog * 0.6), true)
		
		# Vệt bụi quét sàn dạt sang 2 bên chân
		var skid_len = 14.0 + prog * 48.0
		var dust_col = Color(0.95, 0.95, 1.0, alpha * 0.75)
		effects_overlay.draw_line(p_pos + Vector2(-8, -2), p_pos + Vector2(-skid_len, -2), dust_col, 2.5 * (1.0 - prog * 0.5), true)
		effects_overlay.draw_line(p_pos + Vector2(8, -2), p_pos + Vector2(skid_len, -2), dust_col, 2.5 * (1.0 - prog * 0.5), true)
		
		# Tia khí đẩy bật nhảy vọt lên
		for off_x in [-14.0, 0.0, 14.0]:
			var y_start = p_pos.y - 4.0 - prog * 8.0
			var y_end = y_start - (14.0 + prog * 28.0)
			effects_overlay.draw_line(Vector2(p_pos.x + off_x, y_start), Vector2(p_pos.x + off_x, y_end), Color(1.0, 1.0, 1.0, alpha * 0.6), 2.0, true)
	
	# 10. Fuji Emerald Gale Vortex (Hiệu ứng ngưng đọng slow-mo Cơn lốc xanh)
	if fuji_slowmo_active:
		var p_prog = clamp(fuji_slowmo_timer / FUJI_SLOWMO_DURATION, 0.0, 1.0)
		var alpha = sin(p_prog * PI)
		var center = fuji_slowmo_center
		var facing_dir = fuji_slowmo_facing
		
		# A. Lốc xoáy ngọc bích tâm điểm (Vortex Eye Aura)
		var r_eye = 16.0 + p_prog * 24.0
		effects_overlay.draw_circle(center, r_eye * 0.65, Color(0.85, 2.5, 1.3, alpha * 0.40))
		effects_overlay.draw_circle(center, r_eye * 1.35, Color(0.20, 1.85, 0.60, alpha * 0.22))
		
		# B. Các vòng sóng xung kích gió bão nở rộng (Expanding Wind Pressure Rings)
		var r_ring1 = 20.0 + p_prog * 85.0
		effects_overlay.draw_arc(center, r_ring1, 0, TAU, 36, Color(0.30, 2.0, 0.75, alpha * 0.85), 3.0, true)
		effects_overlay.draw_arc(center, r_ring1 * 0.65, 0, TAU, 28, Color(0.90, 2.6, 1.4, alpha * 0.90), 1.8, true)
		
		# C. 3 dải lưỡi gió xoáy lượn vòng (Gale Vortex Blades)
		var base_spin = p_prog * 14.0 * facing_dir
		for b in range(3):
			var ang_start = base_spin + (TAU / 3.0) * b
			var ang_end = ang_start + PI * 0.75
			var r_blade = 28.0 + p_prog * 38.0 + b * 6.0
			effects_overlay.draw_arc(center, r_blade, ang_start, ang_end, 20, Color(0.25, 2.2, 0.70, alpha * 0.90), 3.2, true)
			effects_overlay.draw_arc(center, r_blade, ang_start + 0.1, ang_end - 0.1, 16, Color(0.90, 2.8, 1.5, alpha * 0.98), 1.5, true)
			
		# D. Nhát chém xé gió chéo (Razor Wind Slash Path)
		var slash_len = 60.0 + p_prog * 95.0
		var slash_ang = (-0.42 if facing_dir > 0 else -PI + 0.42)
		var slash_vec = Vector2(cos(slash_ang), sin(slash_ang)) * slash_len
		var p_start = center - slash_vec * 0.45
		var p_end = center + slash_vec * 0.75
		effects_overlay.draw_line(p_start, p_end, Color(0.20, 1.8, 0.55, alpha * 0.55), 7.5, true)
		effects_overlay.draw_line(p_start, p_end, Color(0.85, 2.6, 1.4, alpha * 0.95), 2.8, true)
		
		# E. Bầy lá trúc bay lượn xoáy ốc trong slow-mo (Slow-mo Orbiting Bamboo Leaves)
		for lf in fuji_slowmo_leaves:
			var ang = lf["ang0"] + p_prog * lf["spin_speed"] * lf["spin_dir"]
			var dist = lf["dist0"] + p_prog * lf["dist_speed"]
			var leaf_pos = center + Vector2(cos(ang), sin(ang)) * dist
			var leaf_rot = ang + p_prog * 6.0
			var sz = lf["size"]
			var col = lf["col"]
			col.a = alpha * 0.95
			
			var cos_r = cos(leaf_rot)
			var sin_r = sin(leaf_rot)
			var pts = PackedVector2Array([
				leaf_pos + Vector2(-sz * 0.7 * cos_r, -sz * 0.7 * sin_r),
				leaf_pos + Vector2(-sz * 0.25 * cos_r + sz * 0.38 * sin_r, -sz * 0.25 * sin_r - sz * 0.38 * cos_r),
				leaf_pos + Vector2(sz * 0.45 * cos_r + sz * 0.30 * sin_r, sz * 0.45 * sin_r - sz * 0.30 * cos_r),
				leaf_pos + Vector2(sz * 1.0 * cos_r, sz * 1.0 * sin_r),
				leaf_pos + Vector2(sz * 0.45 * cos_r - sz * 0.30 * sin_r, sz * 0.45 * sin_r + sz * 0.30 * cos_r),
				leaf_pos + Vector2(-sz * 0.25 * cos_r - sz * 0.38 * sin_r, -sz * 0.25 * sin_r + sz * 0.38 * cos_r)
			])
			effects_overlay.draw_colored_polygon(pts, col)
			effects_overlay.draw_polyline(pts, Color(0.9, 2.4, 1.2, alpha * 0.8), 1.0, true)
	
	# 11. Floating Combat Text (Popup PERFECT bay nhẹ lên trên)
	if floating_text_mgr:
		floating_text_mgr.draw(effects_overlay)


# ==========================================================
# HUD ATHLETIC GAUGES (THANH THỂ LỰC & ĐỘ CHÍNH XÁC ACCURACY)
# ==========================================================

func _setup_hud_stamina_bars() -> void:
	var hud = get_node_or_null("HUD")
	if not hud:
		return
	
	# --- PLAYER 1 (Dưới BWFScoreboard cánh trái: left=425, right=565, top=82) ---
	# 1. Player Stamina Bar
	stamina_bar_bg_player = ColorRect.new()
	stamina_bar_bg_player.color = Color(0.08, 0.10, 0.14, 0.85)
	stamina_bar_bg_player.offset_left = 425.0
	stamina_bar_bg_player.offset_top = 82.0
	stamina_bar_bg_player.offset_right = 565.0
	stamina_bar_bg_player.offset_bottom = 86.5
	hud.add_child(stamina_bar_bg_player)
	
	stamina_bar_cap_player = ColorRect.new()
	stamina_bar_cap_player.color = Color(0.25, 0.30, 0.38, 0.45)
	stamina_bar_cap_player.position = Vector2.ZERO
	stamina_bar_cap_player.size = Vector2(140.0, 4.5)
	stamina_bar_bg_player.add_child(stamina_bar_cap_player)
	
	stamina_bar_fill_player = ColorRect.new()
	stamina_bar_fill_player.color = Color(0.2, 0.9, 0.45, 0.95)
	stamina_bar_fill_player.position = Vector2.ZERO
	stamina_bar_fill_player.size = Vector2(140.0, 4.5)
	stamina_bar_bg_player.add_child(stamina_bar_fill_player)
	
	# 2. Player Accuracy Bar (top=88, bottom=91.5)
	accuracy_bar_bg_player = ColorRect.new()
	accuracy_bar_bg_player.color = Color(0.08, 0.10, 0.14, 0.85)
	accuracy_bar_bg_player.offset_left = 425.0
	accuracy_bar_bg_player.offset_top = 88.0
	accuracy_bar_bg_player.offset_right = 565.0
	accuracy_bar_bg_player.offset_bottom = 91.5
	hud.add_child(accuracy_bar_bg_player)
	
	accuracy_bar_fill_player = ColorRect.new()
	accuracy_bar_fill_player.color = Color(0.20, 0.88, 1.0, 0.95)
	accuracy_bar_fill_player.position = Vector2.ZERO
	accuracy_bar_fill_player.size = Vector2(140.0, 4.5)
	accuracy_bar_bg_player.add_child(accuracy_bar_fill_player)
	
	# Vạch cảnh báo 50% nguy hiểm đánh hỏng
	var tick_p = ColorRect.new()
	tick_p.color = Color(1.0, 1.0, 1.0, 0.4)
	tick_p.position = Vector2(70.0, -1.0)
	tick_p.size = Vector2(1.0, 5.5)
	accuracy_bar_bg_player.add_child(tick_p)
	
	# --- RIVAL AI (Dưới BWFScoreboard cánh phải: left=715, right=855, top=82) ---
	# 1. AI Stamina Bar
	stamina_bar_bg_ai = ColorRect.new()
	stamina_bar_bg_ai.color = Color(0.08, 0.10, 0.14, 0.85)
	stamina_bar_bg_ai.offset_left = 715.0
	stamina_bar_bg_ai.offset_top = 82.0
	stamina_bar_bg_ai.offset_right = 855.0
	stamina_bar_bg_ai.offset_bottom = 86.5
	hud.add_child(stamina_bar_bg_ai)
	
	stamina_bar_cap_ai = ColorRect.new()
	stamina_bar_cap_ai.color = Color(0.25, 0.30, 0.38, 0.45)
	stamina_bar_cap_ai.position = Vector2.ZERO
	stamina_bar_cap_ai.size = Vector2(140.0, 4.5)
	stamina_bar_bg_ai.add_child(stamina_bar_cap_ai)
	
	stamina_bar_fill_ai = ColorRect.new()
	stamina_bar_fill_ai.color = Color(0.2, 0.85, 1.0, 0.95)
	stamina_bar_fill_ai.position = Vector2.ZERO
	stamina_bar_fill_ai.size = Vector2(140.0, 4.5)
	stamina_bar_bg_ai.add_child(stamina_bar_fill_ai)
	
	# 2. AI Accuracy Bar (top=88, bottom=91.5)
	accuracy_bar_bg_ai = ColorRect.new()
	accuracy_bar_bg_ai.color = Color(0.08, 0.10, 0.14, 0.85)
	accuracy_bar_bg_ai.offset_left = 715.0
	accuracy_bar_bg_ai.offset_top = 88.0
	accuracy_bar_bg_ai.offset_right = 855.0
	accuracy_bar_bg_ai.offset_bottom = 91.5
	hud.add_child(accuracy_bar_bg_ai)
	
	accuracy_bar_fill_ai = ColorRect.new()
	accuracy_bar_fill_ai.color = Color(0.95, 0.75, 0.25, 0.95)
	accuracy_bar_fill_ai.position = Vector2.ZERO
	accuracy_bar_fill_ai.size = Vector2(140.0, 4.5)
	accuracy_bar_bg_ai.add_child(accuracy_bar_fill_ai)
	
	var tick_ai = ColorRect.new()
	tick_ai.color = Color(1.0, 1.0, 1.0, 0.4)
	tick_ai.position = Vector2(70.0, -1.0)
	tick_ai.size = Vector2(1.0, 5.5)
	accuracy_bar_bg_ai.add_child(tick_ai)


func _update_hud_stamina_bars() -> void:
	var time_val = Time.get_ticks_msec() / 1000.0
	var pulse = 0.65 + 0.35 * sin(time_val * 14.0)
	
	# Update Player Bars
	if player and player.stats:
		if stamina_bar_fill_player and stamina_bar_cap_player:
			var p_cap = clamp(player.stats.max_stamina_cap / 100.0, 0.0, 1.0)
			var p_val = clamp(player.stats.stamina / 100.0, 0.0, 1.0)
			stamina_bar_cap_player.size.x = 124.0 * p_cap
			stamina_bar_fill_player.size.x = 124.0 * p_val
			if player.stats.is_stamina_critical():
				stamina_bar_fill_player.color = Color(1.0, 0.18, 0.18, pulse)
			else:
				stamina_bar_fill_player.color = Color(0.2, 0.9, 0.45, 0.95)
				
		if accuracy_bar_fill_player:
			var p_acc = clamp(player.stats.accuracy / 100.0, 0.0, 1.0)
			accuracy_bar_fill_player.size.x = 124.0 * p_acc
			if player.stats.accuracy < 25.0:
				accuracy_bar_fill_player.color = Color(1.0, 0.25, 0.35, pulse)
			elif player.stats.accuracy < 50.0:
				accuracy_bar_fill_player.color = Color(1.0, 0.72, 0.20, 0.95)
			else:
				accuracy_bar_fill_player.color = Color(0.20, 0.88, 1.0, 0.95)
			
	# Update AI Rival Bars
	if ai_rival and ai_rival.stats:
		if stamina_bar_fill_ai and stamina_bar_cap_ai:
			var ai_cap = clamp(ai_rival.stats.max_stamina_cap / 100.0, 0.0, 1.0)
			var ai_val = clamp(ai_rival.stats.stamina / 100.0, 0.0, 1.0)
			stamina_bar_cap_ai.size.x = 124.0 * ai_cap
			stamina_bar_fill_ai.size.x = 124.0 * ai_val
			if ai_rival.stats.is_stamina_critical():
				stamina_bar_fill_ai.color = Color(1.0, 0.18, 0.18, pulse)
			else:
				stamina_bar_fill_ai.color = Color(0.2, 0.85, 1.0, 0.95)
				
		if accuracy_bar_fill_ai:
			var ai_acc = clamp(ai_rival.stats.accuracy / 100.0, 0.0, 1.0)
			accuracy_bar_fill_ai.size.x = 124.0 * ai_acc
			if ai_rival.stats.accuracy < 25.0:
				accuracy_bar_fill_ai.color = Color(1.0, 0.25, 0.35, pulse)
			elif ai_rival.stats.accuracy < 50.0:
				accuracy_bar_fill_ai.color = Color(1.0, 0.72, 0.20, 0.95)
			else:
				accuracy_bar_fill_ai.color = Color(0.20, 0.88, 1.0, 0.95)
