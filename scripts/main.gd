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
const SHORT_SERVICE_LEFT: float = 450.0
const SHORT_SERVICE_RIGHT: float = 830.0
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
@onready var scoreboard: PanelContainer = $HUD/ScoreBoard
@onready var controls_bar: PanelContainer = $HUD/ControlsBar
@onready var label_score: Label = $HUD/ScoreBoard/Inner/LabelScore
@onready var label_player_badge: Label = $HUD/ScoreBoard/Inner/BadgePlayer/LabelPlayer
@onready var label_rival_badge: Label = $HUD/ScoreBoard/Inner/BadgeRival/LabelRival
@onready var pill_stats: Panel = $HUD/ScoreBoard/Inner/PillStats
@onready var label_spike_stats: Label = $HUD/ScoreBoard/Inner/PillStats/LabelSpikeStats
@onready var label_banner: Label = $HUD/LabelBanner
@onready var flash_rect: ColorRect = $HUD/FlashRect
@onready var grayscale_rect: ColorRect = $HUD/GrayscaleRect
@onready var nishikawa_lightning: Node2D = $NishikawaLightning
@onready var aoi_shield: Node2D = $AoiShield

# AOI Mirage Shield Barrier Effect
var aoi_shield_active: bool = false
var aoi_shield_timer: float = 0.0
var aoi_shield_duration: float = 1.55
var aoi_shield_center: Vector2 = Vector2.ZERO
var aoi_shield_start_ticks: int = 0

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

# Takeoff Jump Effects (Hiệu ứng dậm nhảy bùng nổ mặt sàn)
var jump_takeoff_effects: Array = []

# Settings UI & Character Select
const CharacterStats = preload("res://scripts/core/character_stats.gd")
const MainMenuController = preload("res://scripts/ui/main_menu_controller.gd")
@onready var btn_char_select: Button = $HUD/BtnCharSelect
var main_menu: MainMenuController

@onready var btn_settings: Button = $HUD/BtnSettings
@onready var settings_panel: PanelContainer = $HUD/SettingsPanel
@onready var btn_close_settings: Button = $HUD/SettingsPanel/VBox/Header/BtnClose
@onready var btn_easy: Button = $HUD/SettingsPanel/VBox/DifficultyRow/BtnEasy
@onready var btn_medium: Button = $HUD/SettingsPanel/VBox/DifficultyRow/BtnMedium
@onready var btn_hard: Button = $HUD/SettingsPanel/VBox/DifficultyRow/BtnHard
@onready var btn_squeak: Button = $HUD/SettingsPanel/VBox/SqueakRow/BtnSqueak

# Audio (Smash, Phong, Rít giày, Sấm sét, AOI Block & Slowmo, Dây vợt net, Gió Fuji, Chém cầu sau sân, Trọng tài)
@onready var sfx_smash: AudioStreamPlayer = $Audio/SFXSmash
@onready var sfx_phong: AudioStreamPlayer = $Audio/SFXPong
@onready var sfx_squeak: AudioStreamPlayer = $Audio/SFXSqueak
@onready var sfx_electric: AudioStreamPlayer = $Audio/SFXElectric
@onready var sfx_aoi_block: AudioStreamPlayer = $Audio/SFXAoiBlock
@onready var sfx_aoi_slowmo: AudioStreamPlayer = $Audio/SFXAoiSlowmo
@onready var sfx_string: AudioStreamPlayer = $Audio/SFXString
@onready var sfx_fuji_wind: AudioStreamPlayer = $Audio/SFXFujiWind
@onready var sfx_chem: AudioStreamPlayer = $Audio/SFXChem
@onready var sfx_low_ball_play: AudioStreamPlayer = $Audio/SFXLowBallPlay
@onready var bgm_lobby: AudioStreamPlayer = $Audio/BGMLobby

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
	
	# Đảm bảo gương phản chiếu sàn thi đấu luôn hiển thị sắc nét
	var floor_refl = get_node_or_null("FloorReflection")
	if floor_refl:
		floor_refl.visible = true
	
	# Tách riêng hiệu ứng động (shockwave, burst, jump takeoff) ra overlay độc lập để không vẽ lại toàn bộ sân vận động
	effects_overlay = Node2D.new()
	effects_overlay.name = "EffectsOverlay"
	effects_overlay.z_index = 50
	add_child(effects_overlay)
	effects_overlay.draw.connect(_on_effects_overlay_draw)
	
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
	
	# Khởi tạo Main Menu & Match Setup (Kaiser Shuttle UI)
	main_menu = MainMenuController.new()
	$HUD.add_child(main_menu)
	main_menu.start_match_requested.connect(_on_menu_start_match)
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
	if scoreboard:
		scoreboard.visible = show
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


func _on_menu_start_match(p_id: String, r_id: String, diff: int) -> void:
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
		set_ai_difficulty(diff)
		
	# Cập nhật tên huy hiệu trên HUD
	if label_player_badge and player and player.stats:
		label_player_badge.text = player.stats.character_name.to_upper()
	if label_rival_badge and ai_rival and ai_rival.stats:
		label_rival_badge.text = ai_rival.stats.character_name.to_upper()
		
	# Reset điểm và bắt đầu giao cầu
	score_player = 0
	score_ai = 0
	_update_scoreboard()
	_setup_serve("player")
	
	# Báo hiệu bắt đầu trận đấu (Love all, play audio):
	if sfx_low_ball_play:
		sfx_low_ball_play.play()
		
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


func _unhandled_input(event: InputEvent) -> void:
	if main_menu and main_menu.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				if main_menu.current_state == MainMenuController.MenuState.MATCH_SETUP or main_menu.current_state == MainMenuController.MenuState.SETTINGS:
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
	
	# AOI Mirage Shield Animation update (dùng real-time ticks để bung mượt suốt 1.55s slow-mo):
	if aoi_shield_active:
		var elapsed_real = (Time.get_ticks_msec() - aoi_shield_start_ticks) / 1000.0
		aoi_shield_timer = elapsed_real
		if aoi_shield_timer >= aoi_shield_duration:
			aoi_shield_active = false
		if aoi_shield:
			aoi_shield.queue_redraw()
	
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


func _process_serve_state() -> void:
	if main_menu and main_menu.visible:
		return
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
	
	player.reset_position(360.0, FLOOR_Y)
	ai_rival.reset_position(920.0, FLOOR_Y)
	
	# Movement strictly locked during serve
	player.is_serving_phase = true
	ai_rival.is_serving_phase = true
	
	var serve_pos = Vector2(390.0, FLOOR_Y - 35.0) if server == "player" else Vector2(890.0, FLOOR_Y - 35.0)
	shuttlecock.global_position = serve_pos
	shuttlecock.velocity = Vector2.ZERO
	shuttlecock.is_active = false
	shuttlecock.is_serve = false
	prev_shuttle_x = serve_pos.x
	
	var server_name = "PLAYER" if server == "player" else "RIVAL AI"
	_show_banner("%s GIAO CẦU (BẤM J HOẶC K)" % server_name, Color(1.0, 1.0, 1.0))
	
	# AI auto serve after 0.8s
	if server == "ai":
		get_tree().create_timer(0.8).timeout.connect(func():
			if current_state == MatchState.SERVE and current_server == "ai":
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
		# Khi giao ngắn (drop): target 860px (vượt qua vạch SHORT_SERVICE_RIGHT 830px)
		target_pos = Vector2(1040.0, FLOOR_Y) if shot_type == "clear" else Vector2(860.0, FLOOR_Y)
	else:
		# Khi AI giao ngắn: target 420px (vượt qua vạch SHORT_SERVICE_LEFT 450px)
		target_pos = Vector2(240.0, FLOOR_Y) if shot_type == "clear" else Vector2(420.0, FLOOR_Y)
	
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
		_show_banner("CHANCE BALL!", Color(3.8, 2.5, 0.4), true, 1.0)
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
		
	# 2. Cinematic Super Slow-mo tại điểm chạm vợt (GIỮ NGUYÊN MÀU SẮC ĐỒ HỌA, TUYỆT ĐỐI KHÔNG TRẮNG ĐEN)
	if grayscale_rect:
		grayscale_rect.visible = false
	shake_amount = 12.0
	Engine.time_scale = 0.05
	if camera:
		camera.zoom = Vector2(1.08, 1.08)
		
	var tree = get_tree()
	if tree:
		await tree.create_timer(0.48, true, false, true).timeout
		
	# 3. KHI HẾT 0.48S SLOW-MO: VUNG VỢT VÀ THỰC SỰ PHÓNG CẦU ĐI!
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
			# Người chơi phát cầu: phải qua vạch SHORT_SERVICE_RIGHT (830px) và không ra ngoài
			if pos.x < SHORT_SERVICE_RIGHT:
				point_winner = "ai"
				reason = "GIAO CẦU CHƯA QUA VẠCH! ĐIỂM CHO RIVAL AI"
			elif pos.x > RIGHT_OUT_X:
				point_winner = "ai"
				reason = "GIAO CẦU NGOÀI BIÊN! ĐIỂM CHO RIVAL AI"
			else:
				point_winner = "player"
				reason = "ACE! ĐIỂM GIAO CẦU CHO PLAYER!"
		else:
			# AI phát cầu: phải qua vạch SHORT_SERVICE_LEFT (450px) và không ra ngoài
			if pos.x > SHORT_SERVICE_LEFT:
				point_winner = "player"
				reason = "GIAO CẦU CHƯA QUA VẠCH! ĐIỂM CHO PLAYER"
			elif pos.x < LEFT_OUT_X:
				point_winner = "player"
				reason = "GIAO CẦU NGOÀI BIÊN! ĐIỂM CHO PLAYER"
			else:
				point_winner = "ai"
				reason = "ACE! ĐIỂM GIAO CẦU CHO RIVAL AI!"
		
		_award_point(point_winner, reason)
		return
	
	# 2. RALLY BÌNH THƯỜNG
	if shuttlecock.is_net_fault:
		if shuttlecock.last_hitter == "player":
			point_winner = "ai"
			reason = "CẦU KHÔNG QUA LƯỚI! ĐIỂM CHO RIVAL AI"
		else:
			point_winner = "player"
			reason = "CẦU KHÔNG QUA LƯỚI! ĐIỂM CHO PLAYER"
	elif pos.x < LEFT_OUT_X or pos.x > RIGHT_OUT_X:
		if shuttlecock.last_hitter == "player":
			point_winner = "ai"
			reason = "NGOÀI BIÊN! ĐIỂM CHO RIVAL AI"
		else:
			point_winner = "player"
			reason = "NGOÀI BIÊN! ĐIỂM CHO PLAYER"
	else:
		# In court
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
	
	if is_serve_in_progress:
		is_serve_in_progress = false
		current_state = MatchState.POINT_OVER
		var winner = "ai" if current_server == "player" else "player"
		_award_point(winner, "GIAO CAU MAC LUOI! DIEM CHO %s" % ("RIVAL" if winner == "ai" else "PLAYER"))
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
	
	if score_player >= MATCH_POINT or score_ai >= MATCH_POINT:
		var champ = "PLAYER" if score_player >= MATCH_POINT else "RIVAL AI"
		_show_banner("[ %s CHIẾN THẮNG VÁN ĐẤU! ]" % champ, Color(3.0, 2.5, 0.4))
		await get_tree().create_timer(2.2).timeout
		score_player = 0
		score_ai = 0
		_update_scoreboard()
	
	await get_tree().create_timer(1.2).timeout
	current_server = winner
	_setup_serve(current_server)


func _update_scoreboard() -> void:
	label_score.text = "%d  -  %d" % [score_player, score_ai]


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
	# ==========================================================
	# 1. LUXURIOUS ARENA STADIUM DOME & ROOF TRUSSES (y = 0 -> 240)
	# ==========================================================
	# Deep navy tournament arena gradient wall
	draw_rect(Rect2(0, 0, 1280, 240), Color(0.045, 0.06, 0.095, 1.0))
	draw_rect(Rect2(0, 160, 1280, 80), Color(0.065, 0.085, 0.13, 0.65))
	
	# Arena Structural Steel Trusses & Catwalk Girders
	# Main overhead horizontal girder
	draw_line(Vector2(0, 38), Vector2(1280, 38), Color(0.18, 0.22, 0.30, 0.85), 4.0, true)
	draw_line(Vector2(0, 78), Vector2(1280, 78), Color(0.14, 0.17, 0.24, 0.75), 3.0, true)
	
	# Cross-truss chevron structural struts
	for tx in range(0, 1280, 80):
		draw_line(Vector2(tx, 38), Vector2(tx + 40, 78), Color(0.16, 0.20, 0.28, 0.6), 2.0, true)
		draw_line(Vector2(tx + 40, 78), Vector2(tx + 80, 38), Color(0.16, 0.20, 0.28, 0.6), 2.0, true)
		draw_line(Vector2(tx, 0), Vector2(tx, 38), Color(0.12, 0.15, 0.22, 0.5), 1.5, true)
	
	# Secondary roof framework lines
	for ly in [115, 160, 205]:
		draw_line(Vector2(0, ly), Vector2(1280, ly), Color(0.10, 0.13, 0.19, 0.45), 1.5, true)
	for lx in range(120, 1280, 200):
		draw_line(Vector2(lx, 78), Vector2(lx, 240), Color(0.10, 0.13, 0.19, 0.45), 1.5, true)
		
	# Championship Digital Jumbotron Display in Top Center
	var jumbo_rect = Rect2(470, 10, 340, 24)
	draw_rect(jumbo_rect, Color(0.06, 0.09, 0.14, 0.95))
	draw_rect(jumbo_rect, Color(0.20, 0.65, 0.95, 0.85), false, 1.5)
	# Digital LED text accent dots
	draw_circle(Vector2(482, 22), 3.0, Color(0.3, 0.9, 0.5, 0.9))
	draw_circle(Vector2(798, 22), 3.0, Color(0.3, 0.9, 0.5, 0.9))
	
	# Overhead Stadium Floodlight Rigs & Volumetric Light Cones (4 Light Pods)
	var light_xs = [220.0, 490.0, 790.0, 1060.0]
	for lx in light_xs:
		# Volumetric Soft Light Cone (Atmospheric stadium illumination casting down)
		var cone_pts = PackedVector2Array([
			Vector2(lx - 22, 50),
			Vector2(lx + 22, 50),
			Vector2(lx + 130, 560),
			Vector2(lx - 130, 560)
		])
		draw_colored_polygon(cone_pts, Color(0.92, 0.96, 1.0, 0.028))
		
		# Floodlight casing
		draw_rect(Rect2(lx - 26, 36, 52, 14), Color(0.12, 0.15, 0.20, 1.0))
		draw_line(Vector2(lx - 26, 36), Vector2(lx + 26, 36), Color(0.35, 0.42, 0.52, 0.9), 2.0, true)
		# Glowing Lamp Head (Cluster of 4 bright stadium LEDs)
		for led_i in range(4):
			var led_x = lx - 18 + led_i * 12
			draw_circle(Vector2(led_x, 48), 4.2, Color(1.0, 0.98, 0.88, 0.95))
			draw_circle(Vector2(led_x, 48), 6.5, Color(1.0, 0.95, 0.70, 0.35))
			
	# ==========================================================
	# 2. GRANDSTAND SPECTATOR TIERS & CHEERING CROWD (y = 230 -> 415)
	# ==========================================================
	# Grandstand background wall
	draw_rect(Rect2(0, 230, 1280, 185), Color(0.08, 0.10, 0.15, 1.0))
	
	# 4 Seating Tiers (Stepped depth with lighting rims)
	var tier_ys = [240, 280, 325, 370]
	var tier_cols = [
		Color(0.10, 0.12, 0.18, 1.0),
		Color(0.12, 0.15, 0.22, 1.0),
		Color(0.14, 0.18, 0.26, 1.0),
		Color(0.16, 0.21, 0.30, 1.0)
	]
	for idx in range(tier_ys.size()):
		var ty = tier_ys[idx]
		var th = 42.0 if idx < 3 else 46.0
		draw_rect(Rect2(0, ty, 1280, th), tier_cols[idx])
		draw_line(Vector2(0, ty), Vector2(1280, ty), Color(0.25, 0.32, 0.44, 0.85), 2.0, true)
		
		# Audience Silhouettes seated in rows (Vibrant atmosphere with flags & cheer batons)
		var step_x = 24
		var seed_offset = idx * 13
		for cx in range(16, 1264, step_x):
			var p_h = 10.0 + (int(cx * 7 + seed_offset) % 7)
			var head_y = ty + 16.0 - p_h * 0.5
			# Head
			var shirt_col = Color(0.18 + (int(cx * 3) % 20) * 0.015, 0.22 + (int(cx * 5) % 25) * 0.015, 0.32 + (int(cx * 11) % 35) * 0.015, 0.85)
			draw_circle(Vector2(cx, head_y), 4.5, Color(0.20, 0.24, 0.34, 0.9))
			# Shoulders / Torso
			draw_rect(Rect2(cx - 7, head_y + 4, 14, 14), shirt_col)
			# Cheering sticks / glowing mini batons
			if (cx + seed_offset) % 48 == 0:
				var baton_col = Color(0.3, 0.9, 1.0, 0.75) if (cx % 96 == 0) else Color(1.0, 0.85, 0.3, 0.75)
				draw_line(Vector2(cx + 6, head_y + 2), Vector2(cx + 10, head_y - 8), baton_col, 2.0, true)
				
	# Chrome guardrail across front of grandstand
	draw_line(Vector2(0, 414), Vector2(1280, 414), Color(0.40, 0.48, 0.60, 0.95), 3.0, true)
	for rx in range(40, 1280, 90):
		draw_line(Vector2(rx, 395), Vector2(rx, 415), Color(0.35, 0.42, 0.55, 0.9), 2.0, true)
		
	# ==========================================================
	# 3. HIGH-TECH LED PERIMETER ADVERTISEMENT BOARDS (y = 415 -> 480)
	# ==========================================================
	draw_rect(Rect2(0, 415, 1280, 65), Color(0.06, 0.07, 0.10, 1.0))
	# Glowing top LED neon rim (Electric Cyan)
	draw_line(Vector2(0, 415), Vector2(1280, 415), Color(0.20, 0.80, 1.0, 0.95), 3.0, true)
	draw_line(Vector2(0, 418), Vector2(1280, 418), Color(0.10, 0.45, 0.75, 0.80), 1.5, true)
	
	# Segmented LED Tournament Sponsor Boards
	var boards = [
		{"name": "LI-NING", "col": Color(0.95, 0.25, 0.20), "x1": 20, "x2": 240},
		{"name": "BWF WORLD TOUR", "col": Color(1.0, 0.82, 0.25), "x1": 260, "x2": 520},
		{"name": "KAISER SHUTTLE", "col": Color(0.30, 0.88, 1.0), "x1": 540, "x2": 740},
		{"name": "YONEX", "col": Color(0.25, 0.85, 0.50), "x1": 760, "x2": 1020},
		{"name": "VICTOR", "col": Color(0.35, 0.65, 1.0), "x1": 1040, "x2": 1260}
	]
	for b in boards:
		var bx1: float = b["x1"]
		var bx2: float = b["x2"]
		var bw: float = bx2 - bx1
		var bcol: Color = b["col"]
		# Board background panel
		draw_rect(Rect2(bx1, 424, bw, 48), Color(0.08, 0.11, 0.16, 0.95))
		draw_rect(Rect2(bx1, 424, bw, 48), Color(bcol.r * 0.6, bcol.g * 0.6, bcol.b * 0.6, 0.5), false, 1.2)
		# Digital glowing brand accent line & logo shape
		draw_line(Vector2(bx1 + 10, 432), Vector2(bx2 - 10, 432), Color(bcol.r, bcol.g, bcol.b, 0.85), 2.0, true)
		# Geometric brand icon
		var cx = bx1 + bw * 0.5
		draw_circle(Vector2(cx - 36, 452), 6.0, Color(bcol.r, bcol.g, bcol.b, 0.9))
		draw_circle(Vector2(cx + 36, 452), 6.0, Color(bcol.r, bcol.g, bcol.b, 0.9))
		draw_line(Vector2(cx - 24, 452), Vector2(cx + 24, 452), Color(1.0, 1.0, 1.0, 0.9), 3.0, true)
		# Bottom board bezel
		draw_line(Vector2(bx1 + 5, 468), Vector2(bx2 - 5, 468), Color(bcol.r, bcol.g, bcol.b, 0.5), 1.5, true)
		
	# Bottom metallic kick-plate of the LED barrier
	draw_line(Vector2(0, 480), Vector2(1280, 480), Color(0.22, 0.28, 0.38, 0.9), 2.5, true)
	
	# ==========================================================
	# 4. POLISHED HARDWOOD GYMNASIUM PARQUET FLOOR (y = 480 -> 720)
	# ==========================================================
	# Rich warm honey maple gym flooring
	draw_rect(Rect2(0, 480, 1280, 240), Color(0.28, 0.20, 0.14, 1.0))
	# Darker edge gradient at very bottom
	draw_rect(Rect2(0, 640, 1280, 80), Color(0.20, 0.14, 0.10, 0.45))
	
	# Parquet wood plank horizontal seams
	for wy in range(495, 720, 22):
		draw_line(Vector2(0, wy), Vector2(1280, wy), Color(0.22, 0.15, 0.10, 0.7), 1.2, true)
	# Staggered vertical plank joints
	for wy in range(495, 720, 22):
		var x_shift = (int(wy * 4.3) % 95)
		for wx in range(x_shift, 1280, 110):
			draw_line(Vector2(wx, wy), Vector2(wx, wy + 22), Color(0.18, 0.12, 0.08, 0.6), 1.0, true)
			
	# ==========================================================
	# 5. TOURNAMENT GREEN BWF BADMINTON COURT MAT (y = 485 -> 615)
	# ==========================================================
	var court_mat_pts = PackedVector2Array([
		Vector2(190, 485),  # Top-Left (Far baseline)
		Vector2(1090, 485), # Top-Right (Far baseline)
		Vector2(1210, 615), # Bottom-Right (Near baseline)
		Vector2(70, 615)    # Bottom-Left (Near baseline)
	])
	# Premium BWF Tournament Green Mat (Deep, non-glare, professional green)
	draw_colored_polygon(court_mat_pts, Color(0.13, 0.52, 0.32, 1.0))
	
	# Court interior subtle light sheen
	var inner_sheen_pts = PackedVector2Array([
		Vector2(260, 492),
		Vector2(1020, 492),
		Vector2(1120, 595),
		Vector2(160, 595)
	])
	draw_colored_polygon(inner_sheen_pts, Color(0.18, 0.62, 0.38, 0.25))
	
	# 6. CRISP WHITE PERSPECTIVE COURT MARKINGS
	# Outer border lines (Doubles outer boundary)
	draw_polyline(court_mat_pts, Color(1.0, 1.0, 1.0, 0.95), 3.8, true)
	draw_line(court_mat_pts[3], court_mat_pts[0], Color(1.0, 1.0, 1.0, 0.95), 3.8, true)
	
	# Singles side lines (2.5D perspective)
	draw_line(Vector2(220, 485), Vector2(105, 615), Color(1.0, 1.0, 1.0, 0.70), 2.2, true)
	draw_line(Vector2(1060, 485), Vector2(1175, 615), Color(1.0, 1.0, 1.0, 0.70), 2.2, true)
	
	# Center depth line
	draw_line(Vector2(640, 485), Vector2(640, 615), Color(1.0, 1.0, 1.0, 0.88), 3.0, true)
	
	# Short service lines with 2.5D perspective
	draw_line(Vector2(495, 485), Vector2(445, 615), Color(1.0, 1.0, 1.0, 0.82), 2.5, true)
	draw_line(Vector2(785, 485), Vector2(835, 615), Color(1.0, 1.0, 1.0, 0.82), 2.5, true)
	
	# Doubles long service lines (Near back baseline)
	draw_line(Vector2(208, 495), Vector2(1072, 495), Color(1.0, 1.0, 1.0, 0.60), 2.0, true)
	draw_line(Vector2(85, 605), Vector2(1195, 605), Color(1.0, 1.0, 1.0, 0.60), 2.0, true)
	
	# Main 2D Player Walking Axis Line at FLOOR_Y = 550
	draw_line(Vector2(130, FLOOR_Y), Vector2(1150, FLOOR_Y), Color(1.0, 1.0, 1.0, 0.55), 1.8, true)
	
	# Baseline markers on player axis
	draw_line(Vector2(LEFT_OUT_X, FLOOR_Y - 12), Vector2(LEFT_OUT_X, FLOOR_Y + 12), Color(1.0, 1.0, 1.0, 0.95), 3.0, true)
	draw_line(Vector2(RIGHT_OUT_X, FLOOR_Y - 12), Vector2(RIGHT_OUT_X, FLOOR_Y + 12), Color(1.0, 1.0, 1.0, 0.95), 3.0, true)
	
	# Sports duffel bags on floor edge
	var bag_l_pts = PackedVector2Array([
		Vector2(55, 548), Vector2(50, 520), Vector2(70, 502), Vector2(105, 502), Vector2(120, 524), Vector2(115, 548)
	])
	draw_colored_polygon(bag_l_pts, Color(0.14, 0.15, 0.18, 1.0))
	draw_polyline(bag_l_pts, Color(0.88, 0.22, 0.2, 0.9), 2.5, true)
	draw_line(Vector2(65, 520), Vector2(105, 520), Color(0.95, 0.85, 0.2, 0.9), 2.0, true)
	
	var bag_r_pts = PackedVector2Array([
		Vector2(1160, 548), Vector2(1155, 522), Vector2(1175, 504), Vector2(1210, 504), Vector2(1225, 525), Vector2(1220, 548)
	])
	draw_colored_polygon(bag_r_pts, Color(0.12, 0.14, 0.20, 1.0))
	draw_polyline(bag_r_pts, Color(0.1, 0.8, 0.95, 0.9), 2.5, true)
	draw_line(Vector2(1172, 522), Vector2(1210, 522), Color(1.0, 1.0, 1.0, 0.8), 2.0, true)
	
	# ==========================================================
	# 7. AUTHENTIC 2.5D WOVEN BADMINTON NET (NET_X = 640)
	# ==========================================================
	var net_far_bot = Vector2(640, 485)
	var net_far_top = Vector2(640, 375)
	var net_near_bot = Vector2(640, 615)
	var net_near_top = Vector2(640, 505)
	
	var net_mesh_pts = PackedVector2Array([net_far_top, net_near_top, net_near_bot, net_far_bot])
	# Semi-transparent dark mesh
	draw_colored_polygon(net_mesh_pts, Color(0.10, 0.14, 0.20, 0.65))
	
	# Horizontal grid cords across depth (8 cords)
	for i in range(1, 9):
		var frac = i / 9.0
		var p_top = net_far_top.lerp(net_near_top, frac)
		var p_bot = net_far_bot.lerp(net_near_bot, frac)
		draw_line(p_top, p_bot, Color(0.92, 0.94, 0.98, 0.40), 1.0, true)
	
	# Vertical height mesh lines (7 lines)
	for h_idx in range(1, 7):
		var h_frac = h_idx / 7.0
		var p_far = net_far_top.lerp(net_far_bot, h_frac)
		var p_near = net_near_top.lerp(net_near_bot, h_frac)
		draw_line(p_far, p_near, Color(0.92, 0.94, 0.98, 0.40), 1.0, true)
	
	# Far Tournament Net Post (Deep Red & Tension Winch)
	draw_line(net_far_bot + Vector2(0, 4), net_far_top - Vector2(0, 4), Color(0.85, 0.18, 0.14, 1.0), 6.0, true)
	draw_circle(net_far_top - Vector2(0, 4), 5.0, Color(1.0, 0.85, 0.2, 1.0), true, -1.0, true)
	
	# Near Tournament Net Post (Foreground Solid Post)
	draw_line(net_near_bot + Vector2(0, 6), net_near_top - Vector2(0, 6), Color(0.85, 0.18, 0.14, 1.0), 7.5, true)
	draw_circle(net_near_top - Vector2(0, 6), 6.0, Color(1.0, 0.85, 0.2, 1.0), true, -1.0, true)
	
	# Crisp White Top Net Tape (From Far to Near post)
	draw_line(net_far_top, net_near_top, Color(1.0, 1.0, 1.0, 1.0), 4.8, true)
	# Bottom Net Binding Cord
	draw_line(net_far_bot, net_near_bot, Color(0.85, 0.88, 0.92, 0.75), 2.0, true)


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
	
	# 10. Floating Combat Text (Popup PERFECT bay nhẹ lên trên)
	if floating_text_mgr:
		floating_text_mgr.draw(effects_overlay)


# ==========================================================
# HUD ATHLETIC GAUGES (THANH THỂ LỰC & ĐỘ CHÍNH XÁC ACCURACY)
# ==========================================================

func _setup_hud_stamina_bars() -> void:
	var inner = get_node_or_null("HUD/ScoreBoard/Inner")
	if not inner:
		return
	
	# --- PLAYER 1 (Dưới BadgePlayer: left=16, right=140) ---
	# 1. Player Stamina Bar (top=47, bottom=51.5)
	stamina_bar_bg_player = ColorRect.new()
	stamina_bar_bg_player.color = Color(0.08, 0.10, 0.14, 0.85)
	stamina_bar_bg_player.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stamina_bar_bg_player.offset_left = 16.0
	stamina_bar_bg_player.offset_top = 47.0
	stamina_bar_bg_player.offset_right = 140.0
	stamina_bar_bg_player.offset_bottom = 51.5
	inner.add_child(stamina_bar_bg_player)
	
	stamina_bar_cap_player = ColorRect.new()
	stamina_bar_cap_player.color = Color(0.25, 0.30, 0.38, 0.45)
	stamina_bar_cap_player.position = Vector2.ZERO
	stamina_bar_cap_player.size = Vector2(124.0, 4.5)
	stamina_bar_bg_player.add_child(stamina_bar_cap_player)
	
	stamina_bar_fill_player = ColorRect.new()
	stamina_bar_fill_player.color = Color(0.2, 0.9, 0.45, 0.95)
	stamina_bar_fill_player.position = Vector2.ZERO
	stamina_bar_fill_player.size = Vector2(124.0, 4.5)
	stamina_bar_bg_player.add_child(stamina_bar_fill_player)
	
	# 2. Player Accuracy Bar (top=53.5, bottom=58)
	accuracy_bar_bg_player = ColorRect.new()
	accuracy_bar_bg_player.color = Color(0.08, 0.10, 0.14, 0.85)
	accuracy_bar_bg_player.set_anchors_preset(Control.PRESET_TOP_LEFT)
	accuracy_bar_bg_player.offset_left = 16.0
	accuracy_bar_bg_player.offset_top = 53.5
	accuracy_bar_bg_player.offset_right = 140.0
	accuracy_bar_bg_player.offset_bottom = 58.0
	inner.add_child(accuracy_bar_bg_player)
	
	accuracy_bar_fill_player = ColorRect.new()
	accuracy_bar_fill_player.color = Color(0.20, 0.88, 1.0, 0.95)
	accuracy_bar_fill_player.position = Vector2.ZERO
	accuracy_bar_fill_player.size = Vector2(124.0, 4.5)
	accuracy_bar_bg_player.add_child(accuracy_bar_fill_player)
	
	# Vạch cảnh báo 50% nguy hiểm đánh hỏng
	var tick_p = ColorRect.new()
	tick_p.color = Color(1.0, 1.0, 1.0, 0.4)
	tick_p.position = Vector2(62.0, -1.0)
	tick_p.size = Vector2(1.0, 6.5)
	accuracy_bar_bg_player.add_child(tick_p)
	
	# --- RIVAL AI (Dưới BadgeRival: left=-140, right=-16) ---
	# 1. AI Stamina Bar (top=47, bottom=51.5)
	stamina_bar_bg_ai = ColorRect.new()
	stamina_bar_bg_ai.color = Color(0.08, 0.10, 0.14, 0.85)
	stamina_bar_bg_ai.anchor_left = 1.0
	stamina_bar_bg_ai.anchor_right = 1.0
	stamina_bar_bg_ai.offset_left = -140.0
	stamina_bar_bg_ai.offset_top = 47.0
	stamina_bar_bg_ai.offset_right = -16.0
	stamina_bar_bg_ai.offset_bottom = 51.5
	inner.add_child(stamina_bar_bg_ai)
	
	stamina_bar_cap_ai = ColorRect.new()
	stamina_bar_cap_ai.color = Color(0.25, 0.30, 0.38, 0.45)
	stamina_bar_cap_ai.position = Vector2.ZERO
	stamina_bar_cap_ai.size = Vector2(124.0, 4.5)
	stamina_bar_bg_ai.add_child(stamina_bar_cap_ai)
	
	stamina_bar_fill_ai = ColorRect.new()
	stamina_bar_fill_ai.color = Color(0.2, 0.85, 1.0, 0.95)
	stamina_bar_fill_ai.position = Vector2.ZERO
	stamina_bar_fill_ai.size = Vector2(124.0, 4.5)
	stamina_bar_bg_ai.add_child(stamina_bar_fill_ai)
	
	# 2. AI Accuracy Bar (top=53.5, bottom=58)
	accuracy_bar_bg_ai = ColorRect.new()
	accuracy_bar_bg_ai.color = Color(0.08, 0.10, 0.14, 0.85)
	accuracy_bar_bg_ai.anchor_left = 1.0
	accuracy_bar_bg_ai.anchor_right = 1.0
	accuracy_bar_bg_ai.offset_left = -140.0
	accuracy_bar_bg_ai.offset_top = 53.5
	accuracy_bar_bg_ai.offset_right = -16.0
	accuracy_bar_bg_ai.offset_bottom = 58.0
	inner.add_child(accuracy_bar_bg_ai)
	
	accuracy_bar_fill_ai = ColorRect.new()
	accuracy_bar_fill_ai.color = Color(0.20, 0.88, 1.0, 0.95)
	accuracy_bar_fill_ai.position = Vector2.ZERO
	accuracy_bar_fill_ai.size = Vector2(124.0, 4.5)
	accuracy_bar_bg_ai.add_child(accuracy_bar_fill_ai)
	
	var tick_ai = ColorRect.new()
	tick_ai.color = Color(1.0, 1.0, 1.0, 0.4)
	tick_ai.position = Vector2(62.0, -1.0)
	tick_ai.size = Vector2(1.0, 6.5)
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
