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

# HUD Athletic Gauges (Stamina, Accuracy, Flow)
var stamina_bar_bg_player: ColorRect
var stamina_bar_fill_player: ColorRect
var stamina_bar_cap_player: ColorRect
var accuracy_bar_bg_player: ColorRect
var accuracy_bar_fill_player: ColorRect
var flow_bar_bg_player: ColorRect
var flow_bar_fill_player: ColorRect

var stamina_bar_bg_ai: ColorRect
var stamina_bar_fill_ai: ColorRect
var stamina_bar_cap_ai: ColorRect
var accuracy_bar_bg_ai: ColorRect
var accuracy_bar_fill_ai: ColorRect
var flow_bar_bg_ai: ColorRect
var flow_bar_fill_ai: ColorRect

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
var pvp_landing_pending: bool = false
var pvp_landing_pending_pos: Vector2 = Vector2.ZERO
var pvp_landing_pending_is_serve: bool = false
var pvp_landing_grace_timer: float = 0.0
var is_point_transition_active: bool = false
var serve_cooldown: float = 0.0
var pvp_local_player_name: String = "PLAYER 1"
var pvp_opponent_player_name: String = "PLAYER 2"
var pvp_net_sync_timer: float = 0.0
const PVP_NET_TICK_RATE: float = 30.0 # 30 Hz fixed network tick rate for optimal WebSocket TCP throughput
const PVP_NET_SYNC_INTERVAL: float = 1.0 / PVP_NET_TICK_RATE # ~0.0333s

@onready var btn_settings: Button = $HUD/BtnSettings
@onready var settings_panel: PanelContainer = $HUD/SettingsPanel
@onready var btn_close_settings: Button = $HUD/SettingsPanel/VBox/Header/BtnClose
@onready var btn_easy: Button = $HUD/SettingsPanel/VBox/DifficultyRow/BtnEasy
@onready var btn_medium: Button = $HUD/SettingsPanel/VBox/DifficultyRow/BtnMedium
@onready var btn_hard: Button = $HUD/SettingsPanel/VBox/DifficultyRow/BtnHard
@onready var btn_squeak: Button = $HUD/SettingsPanel/VBox/SqueakRow/BtnSqueak
var bgm_match_enabled: bool = true
var bgm_match_volume: float = 0.20
var btn_bgm_match: Button = null
var slider_bgm_match: HSlider = null
var lbl_bgm_vol_match: Label = null

# Spectator Mode Parameters
var is_spectator: bool = false
var spectator_banner: Panel = null
var btn_spectator_leave: Button = null

# Virtual Mobile Controls (Touchpad + Circular Buttons J, K, L)
const VirtualTouchPadClass = preload("res://scripts/ui/virtual_touch_pad.gd")
var virtual_touch_pad: Control = null
var touch_controls_enabled: bool = false
var btn_touch_toggle: Button = null
var btn_fullscreen: Button = null
var low_graphics_mode: bool = false
var btn_low_gfx_toggle: Button = null
var prev_key_r: bool = false

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
	
	if OS.has_feature("web"):
		low_graphics_mode = true
	else:
		low_graphics_mode = false
	if shuttlecock and shuttlecock.has_method("set_low_graphics"):
		shuttlecock.set_low_graphics(low_graphics_mode)
	
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
	
	# Đảm bảo gương phản chiếu sàn thi đấu luôn hiển thị sắc nét trên bản Desktop (.exe)
	# Riêng bản Web: Tắt hoàn toàn shader screen_texture để khử triệt để GPU stall / crash WebGL
	var floor_refl = get_node_or_null("FloorReflection")
	if floor_refl:
		if OS.has_feature("web"):
			floor_refl.visible = false
		else:
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
	amb_player.volume_db = -14.0
	amb_player.bus = "Master"
	add_child(amb_player)
	amb_player.play()
	
	# Đảm bảo game tiếp tục chạy nền mượt mà khi chuyển tab hoặc cửa sổ không active
	OS.low_processor_usage_mode = false
	
	if btn_settings:
		btn_settings.focus_mode = Control.FOCUS_NONE
		btn_settings.pressed.connect(func():
			btn_settings.release_focus()
			_toggle_settings_panel()
		)
	if btn_close_settings:
		btn_close_settings.focus_mode = Control.FOCUS_NONE
		btn_close_settings.pressed.connect(func():
			btn_close_settings.release_focus()
			if settings_panel: settings_panel.visible = false
		)
	
	if btn_easy and btn_medium and btn_hard:
		btn_easy.focus_mode = Control.FOCUS_NONE
		btn_medium.focus_mode = Control.FOCUS_NONE
		btn_hard.focus_mode = Control.FOCUS_NONE
		btn_easy.pressed.connect(func():
			btn_easy.release_focus()
			set_ai_difficulty(0)
		)
		btn_medium.pressed.connect(func():
			btn_medium.release_focus()
			set_ai_difficulty(1)
		)
		btn_hard.pressed.connect(func():
			btn_hard.release_focus()
			set_ai_difficulty(2)
		)
	
	if btn_squeak:
		btn_squeak.focus_mode = Control.FOCUS_NONE
		btn_squeak.pressed.connect(func():
			btn_squeak.release_focus()
			squeak_enabled = not squeak_enabled
			_update_settings_ui()
		)
		
	# Bổ sung hàng BGM vào in-game SettingsPanel
	if settings_panel:
		settings_panel.offset_bottom = 370.0
		var vbox = settings_panel.get_node_or_null("VBox")
		if vbox:
			var bgm_row = HBoxContainer.new()
			var lbl_bgm = Label.new()
			lbl_bgm.text = "Nhạc nền trận đấu:"
			lbl_bgm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bgm_row.add_child(lbl_bgm)
			
			btn_bgm_match = Button.new()
			btn_bgm_match.focus_mode = Control.FOCUS_NONE
			btn_bgm_match.custom_minimum_size = Vector2(80, 28)
			btn_bgm_match.text = "BẬT"
			btn_bgm_match.pressed.connect(func():
				btn_bgm_match.release_focus()
				bgm_match_enabled = not bgm_match_enabled
				_update_settings_ui()
				_apply_match_bgm()
			)
			bgm_row.add_child(btn_bgm_match)
			vbox.add_child(bgm_row)
			
			var vol_row = HBoxContainer.new()
			lbl_bgm_vol_match = Label.new()
			lbl_bgm_vol_match.text = "Âm lượng nhạc: 20%"
			lbl_bgm_vol_match.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vol_row.add_child(lbl_bgm_vol_match)
			
			slider_bgm_match = HSlider.new()
			slider_bgm_match.focus_mode = Control.FOCUS_NONE
			slider_bgm_match.custom_minimum_size = Vector2(110, 24)
			slider_bgm_match.min_value = 0.0
			slider_bgm_match.max_value = 1.0
			slider_bgm_match.step = 0.05
			slider_bgm_match.value = bgm_match_volume
			slider_bgm_match.value_changed.connect(func(val: float):
				bgm_match_volume = val
				_update_settings_ui()
				_apply_match_bgm()
			)
			vol_row.add_child(slider_bgm_match)
			vbox.add_child(vol_row)
			
			var touch_row = HBoxContainer.new()
			var lbl_touch = Label.new()
			lbl_touch.text = "Phím cảm ứng ảo:"
			lbl_touch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			touch_row.add_child(lbl_touch)
			
			btn_touch_toggle = Button.new()
			btn_touch_toggle.focus_mode = Control.FOCUS_NONE
			btn_touch_toggle.custom_minimum_size = Vector2(80, 28)
			btn_touch_toggle.text = "TẮT"
			btn_touch_toggle.pressed.connect(func():
				btn_touch_toggle.release_focus()
				touch_controls_enabled = not touch_controls_enabled
				_update_settings_ui()
				if virtual_touch_pad:
					virtual_touch_pad.visible = touch_controls_enabled and (not main_menu or not main_menu.visible)
				if controls_bar:
					controls_bar.visible = (not touch_controls_enabled) and (not main_menu or not main_menu.visible)
			)
			touch_row.add_child(btn_touch_toggle)
			vbox.add_child(touch_row)
			
			var fs_row = HBoxContainer.new()
			var lbl_fs = Label.new()
			lbl_fs.text = "Toàn màn hình:"
			lbl_fs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fs_row.add_child(lbl_fs)
			
			var btn_fs_toggle = Button.new()
			btn_fs_toggle.focus_mode = Control.FOCUS_NONE
			btn_fs_toggle.custom_minimum_size = Vector2(80, 28)
			btn_fs_toggle.text = "BẬT/TẮT"
			btn_fs_toggle.pressed.connect(func():
				btn_fs_toggle.release_focus()
				_toggle_fullscreen()
			)
			fs_row.add_child(btn_fs_toggle)
			vbox.add_child(fs_row)
			
			# Hàng cấu hình đồ họa thấp (Low Graphics Mode): Chỉ hiển thị trên Web. Desktop chỉ để 1 loại đồ họa MAX
			if OS.has_feature("web"):
				var gfx_row = HBoxContainer.new()
				var lbl_gfx = Label.new()
				lbl_gfx.text = "Cấu hình đồ họa thấp:"
				lbl_gfx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				gfx_row.add_child(lbl_gfx)
				
				btn_low_gfx_toggle = Button.new()
				btn_low_gfx_toggle.focus_mode = Control.FOCUS_NONE
				btn_low_gfx_toggle.custom_minimum_size = Vector2(90, 28)
				btn_low_gfx_toggle.text = "[ BẬT ]" if low_graphics_mode else "[ TẮT ]"
				btn_low_gfx_toggle.pressed.connect(func():
					btn_low_gfx_toggle.release_focus()
					low_graphics_mode = not low_graphics_mode
					if shuttlecock and shuttlecock.has_method("set_low_graphics"):
						shuttlecock.set_low_graphics(low_graphics_mode)
					_update_settings_ui()
				)
				gfx_row.add_child(btn_low_gfx_toggle)
				vbox.add_child(gfx_row)
		
	# Tự động nhận diện thiết bị: Mặc định TẮT trên Desktop/PC, chỉ BẬT trên Mobile/Touchscreen
	var is_mobile = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	if OS.has_feature("web"):
		var js_mobile = JavaScriptBridge.eval("Boolean(/Android|iPhone|iPad|iPod/i.test(navigator.userAgent) || (navigator.maxTouchPoints && navigator.maxTouchPoints > 1))")
		if js_mobile == true or str(js_mobile).to_lower() == "true":
			is_mobile = true
	touch_controls_enabled = is_mobile
	
	# Nút Toàn Màn Hình (Fullscreen) ở góc trên bên phải màn hình (Căn chỉnh tuyệt đối, không đè nút Cài đặt)
	btn_fullscreen = Button.new()
	btn_fullscreen.focus_mode = Control.FOCUS_NONE
	btn_fullscreen.name = "BtnFullscreen"
	btn_fullscreen.text = "⛶ FULL"
	btn_fullscreen.custom_minimum_size = Vector2(70, 32)
	btn_fullscreen.position = Vector2(1194.0, 16.0)
	btn_fullscreen.tooltip_text = "Bật / Tắt Toàn màn hình (Fullscreen)"
	
	var fs_sb = StyleBoxFlat.new()
	fs_sb.bg_color = Color(0.06, 0.12, 0.20, 0.88)
	fs_sb.border_width_left = 1
	fs_sb.border_width_top = 1
	fs_sb.border_width_right = 1
	fs_sb.border_width_bottom = 1
	fs_sb.border_color = Color(0.25, 0.85, 1.0, 0.65)
	fs_sb.corner_radius_top_left = 6
	fs_sb.corner_radius_top_right = 6
	fs_sb.corner_radius_bottom_right = 6
	fs_sb.corner_radius_bottom_left = 6
	btn_fullscreen.add_theme_stylebox_override("normal", fs_sb)
	btn_fullscreen.add_theme_color_override("font_color", Color(0.35, 0.90, 1.0))
	btn_fullscreen.pressed.connect(func():
		btn_fullscreen.release_focus()
		_toggle_fullscreen()
	)
	$HUD.add_child(btn_fullscreen)
	
	_update_settings_ui()
	_setup_hud_stamina_bars()
	
	# Khởi tạo PvP Network Manager
	net_manager = PvPNetworkManager.new()
	add_child(net_manager)
	net_manager.packet_received.connect(_on_network_packet_received)
	net_manager.peer_disconnected.connect(_on_network_peer_disconnected)
	
	# Khởi tạo Main Menu & Match Setup (Kaiser Shuttle UI)
	main_menu = MainMenuController.new()
	main_menu.touch_controls_enabled = touch_controls_enabled
	$HUD.add_child(main_menu)
	main_menu.set_network_manager(net_manager)
	main_menu.start_match_requested.connect(_on_menu_start_match)
	main_menu.start_pvp_match_requested.connect(_on_menu_start_pvp_match)
	main_menu.spectate_room_requested.connect(_on_menu_spectate_room)
	main_menu.settings_updated.connect(_on_menu_settings_updated)
	main_menu.touch_toggle_requested.connect(func(en: bool):
		touch_controls_enabled = en
		_update_settings_ui()
		if virtual_touch_pad:
			virtual_touch_pad.visible = touch_controls_enabled and (not main_menu or not main_menu.visible)
		if controls_bar:
			controls_bar.visible = (not touch_controls_enabled) and (not main_menu or not main_menu.visible)
	)
	
	# Khởi tạo Touchpad di chuyển (kéo qua lại) & Cụm phím ảo J, K, L (Vector Logo)
	virtual_touch_pad = VirtualTouchPadClass.new()
	virtual_touch_pad.name = "VirtualTouchPad"
	virtual_touch_pad.set_target_player(player)
	virtual_touch_pad.shot_triggered.connect(_on_touch_shot_triggered)
	virtual_touch_pad.jump_triggered.connect(_on_touch_jump_triggered)
	$HUD.add_child(virtual_touch_pad)
	virtual_touch_pad.visible = false
	
	if btn_char_select:
		btn_char_select.focus_mode = Control.FOCUS_NONE
		btn_char_select.pressed.connect(func():
			btn_char_select.release_focus()
			_set_in_game_hud_visible(false)
			main_menu.switch_state(MainMenuController.MenuState.MATCH_SETUP)
			main_menu.visible = true
			_apply_menu_bgm()
		)
		
	if label_player_badge and player and player.stats:
		label_player_badge.text = player.stats.character_name.to_upper()
	if label_rival_badge and ai_rival and ai_rival.stats:
		label_rival_badge.text = ai_rival.stats.character_name.to_upper()
		
	# Khử toàn bộ keyboard/space focus trên mọi nút bấm
	_strip_keyboard_focus($HUD)
		
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
		controls_bar.visible = show and not touch_controls_enabled
	if btn_char_select:
		# KHÓA ĐỔI TƯỚNG TRONG TRẬN: Trong bất kỳ trận đấu nào (PvP hoặc AI), nút đổi tướng luôn ẩn
		btn_char_select.visible = false
	if btn_settings:
		btn_settings.visible = show
	if not show and label_banner:
		label_banner.visible = false
	if not show and pill_stats:
		pill_stats.visible = false
	if stamina_bar_bg_player:
		stamina_bar_bg_player.visible = show
	if accuracy_bar_bg_player:
		accuracy_bar_bg_player.visible = show
	if flow_bar_bg_player:
		flow_bar_bg_player.visible = show
	if stamina_bar_bg_ai:
		stamina_bar_bg_ai.visible = show
	if accuracy_bar_bg_ai:
		accuracy_bar_bg_ai.visible = show
	if flow_bar_bg_ai:
		flow_bar_bg_ai.visible = show
	if virtual_touch_pad:
		virtual_touch_pad.visible = show and touch_controls_enabled


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


func _toggle_fullscreen() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (window.kaiserToggleFullscreen) window.kaiserToggleFullscreen();")
	else:
		var mode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _toggle_character_select() -> void:
	# Khóa hoàn toàn đổi tướng khi đang trong trận đấu (PvP hoặc AI)
	if is_pvp_active or is_spectator or current_state == MatchState.RALLY or current_state == MatchState.SERVE or current_state == MatchState.POINT_OVER:
		return
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
	if virtual_touch_pad:
		virtual_touch_pad.set_target_player(player)
	if player:
		player.character_id = p_id
		match p_id:
			"nishikawa": player.stats = CharacterStats.create_nishikawa()
			"fuji": player.stats = CharacterStats.create_fuji()
			"wall": player.stats = CharacterStats.create_wall()
			_: player.stats = CharacterStats.create_nishikawa()
		player.move_speed_x = lerp(207.0, 238.5, (player.stats.agility - 40.0) / 59.0)
		if player.stats:
			player.stats.reset_stamina()
			player.stats.reset_torque()
		
	if ai_rival:
		ai_rival.character_id = r_id
		match r_id:
			"nishikawa": ai_rival.stats = CharacterStats.create_nishikawa()
			"fuji": ai_rival.stats = CharacterStats.create_fuji()
			"wall": ai_rival.stats = CharacterStats.create_wall()
			_: ai_rival.stats = CharacterStats.create_wall()
		ai_rival.move_speed_x = lerp(207.0, 238.5, (ai_rival.stats.agility - 40.0) / 59.0)
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
		
	# Bật hoặc tắt nhạc nền trận đấu theo thiết lập (bắt đầu lại bài nhạc từ đầu)
	_apply_match_bgm(true)


func _on_menu_settings_updated(sq: bool, bgm_en: bool = true, bgm_vol: float = 0.20, low_gfx: bool = false) -> void:
	squeak_enabled = sq
	bgm_match_enabled = bgm_en
	bgm_match_volume = bgm_vol
	if OS.has_feature("web"):
		low_graphics_mode = low_gfx
	else:
		low_graphics_mode = false
	if shuttlecock and shuttlecock.has_method("set_low_graphics"):
		shuttlecock.set_low_graphics(low_graphics_mode)
	_update_settings_ui()
	_apply_match_bgm(false)

func _create_char_stats(char_id: String) -> CharacterStats:
	match char_id:
		"nishikawa": return CharacterStats.create_nishikawa()
		"fuji": return CharacterStats.create_fuji()
		"wall": return CharacterStats.create_wall()
		_: return CharacterStats.create_nishikawa()

func _on_menu_start_pvp_match(room_code: String, is_host: bool, local_char: String, target_points: int, match_sets: int, first_server_role: String = "p1", opponent_char: String = "", local_player_name: String = "", opp_player_name: String = "") -> void:
	is_pvp_active = true
	is_pvp_host = is_host
	is_spectator = false
	pvp_room_code = room_code
	pvp_local_char = local_char
	pvp_local_player_name = local_player_name.strip_edges().to_upper() if not local_player_name.strip_edges().is_empty() else "PLAYER"
	pvp_opponent_player_name = opp_player_name.strip_edges().to_upper() if not opp_player_name.strip_edges().is_empty() else ("RIVAL" if not is_host else "GUEST")
	target_match_points = target_points
	total_match_sets = match_sets
	current_set_index = 0
	sets_won_player = 0
	sets_won_ai = 0
	score_player = 0
	score_ai = 0
	
	# Xác định quyền giao cầu ban đầu (Authoritative First Serve Coin Toss):
	var i_serve_first = (is_host and first_server_role == "p1") or (not is_host and first_server_role == "p2")
	current_server = "player" if i_serve_first else "ai"
	
	if shuttlecock:
		shuttlecock.is_network_client = not is_host
	
	if match_over_dialog:
		match_over_dialog.visible = false
	_set_in_game_hud_visible(true)
	if virtual_touch_pad:
		virtual_touch_pad.set_target_player(player)
	
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
	
	player.character_id = local_char
	player.stats = _create_char_stats(local_char)
	player.move_speed_x = lerp(207.0, 238.5, (player.stats.agility - 40.0) / 59.0)
	
	var r_char = opponent_char
	if r_char.is_empty():
		r_char = "wall" if local_char != "wall" else "nishikawa"
	ai_rival.character_id = r_char
	ai_rival.stats = _create_char_stats(r_char)
	ai_rival.move_speed_x = lerp(207.0, 238.5, (ai_rival.stats.agility - 40.0) / 59.0)
	
	if is_host:
		net_manager.send_packet({
			"t": "init",
			"char": local_char,
			"name": pvp_local_player_name,
			"pts": target_points,
			"sets": match_sets,
			"first_server": first_server_role
		})
	else:
		net_manager.send_packet({
			"t": "init_ack",
			"char": local_char,
			"name": pvp_local_player_name
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
			pvp_local_player_name,
			pvp_opponent_player_name
		)
		bwf_scoreboard.update_current_score(0, 0)
		bwf_scoreboard.set_server(current_server != "player")
		
	_update_scoreboard()
	_setup_serve(current_server)
	
	# Bật hoặc tắt nhạc nền trận đấu theo thiết lập (bắt đầu lại bài nhạc từ đầu)
	_apply_match_bgm(true)

	# Hoạt cảnh Tung Đồng Xu ngẫu nhiên (Coin Toss) trước trận đấu:
	_show_banner("🪙 ĐANG TUNG ĐỒNG XU QUYẾT ĐỊNH QUYỀN GIAO CẦU...", Color(1.0, 0.9, 0.3))
	get_tree().create_timer(1.2).timeout.connect(func():
		if not is_pvp_active: return
		if current_server == "player":
			_show_banner("🪙 BẠN THẮNG ĐỒNG XU: BẠN ĐƯỢC QUYỀN GIAO CẦU TRƯỚC!", Color(0.2, 1.0, 0.6))
		else:
			_show_banner("🪙 ĐỐI THỦ THẮNG ĐỒNG XU: ĐỐI THỦ ĐƯỢC QUYỀN GIAO CẦU TRƯỚC!", Color(1.0, 0.85, 0.2))
		get_tree().create_timer(1.0).timeout.connect(func():
			if not is_pvp_active: return
			_play_umpire_opening_call(current_server)
		)
	)


func _on_menu_spectate_room(room_code: String) -> void:
	is_spectator = true
	is_pvp_active = true
	is_pvp_host = false
	pvp_room_code = room_code.to_upper().strip_edges()
	if net_manager:
		net_manager.join_spectator(pvp_room_code)


func _start_spectator_mode(data: Dictionary) -> void:
	is_spectator = true
	is_pvp_active = true
	is_pvp_host = false
	pvp_room_code = str(data.get("code", pvp_room_code))
	target_match_points = int(data.get("pts", 11))
	total_match_sets = int(data.get("sets", 1))
	current_set_index = 0
	score_player = int(data.get("p1_pts", 0))
	score_ai = int(data.get("p2_pts", 0))
	sets_won_player = int(data.get("p1_sets", 0))
	sets_won_ai = int(data.get("p2_sets", 0))
	var srv = str(data.get("current_server", "p1"))
	current_server = "player" if srv == "p1" or srv == "player" else "ai"
	
	if shuttlecock:
		shuttlecock.is_network_client = true
	if match_over_dialog:
		match_over_dialog.visible = false
		
	main_menu.visible = false
	_set_in_game_hud_visible(true)
	if virtual_touch_pad:
		virtual_touch_pad.visible = false
	if controls_bar:
		controls_bar.visible = false
	if btn_char_select:
		btn_char_select.visible = false
		
	# Cả hai bên đều là puppet đối với spectator
	if player:
		player.is_ai = false
		player.is_remote_puppet = true
		player.court_side = "player"
		player.facing = 1.0
		var p1_char = str(data.get("p1_char", "nishikawa"))
		player.stats = _create_char_stats(p1_char)
		player.move_speed_x = lerp(207.0, 238.5, (player.stats.agility - 40.0) / 59.0)
		player.opponent_player = ai_rival
		if label_player_badge:
			label_player_badge.text = "P1: " + player.stats.character_name.to_upper()
			
	if ai_rival:
		ai_rival.is_ai = false
		ai_rival.is_remote_puppet = true
		ai_rival.court_side = "ai"
		ai_rival.facing = -1.0
		var p2_char = str(data.get("p2_char", "wall"))
		ai_rival.stats = _create_char_stats(p2_char)
		ai_rival.move_speed_x = lerp(207.0, 238.5, (ai_rival.stats.agility - 40.0) / 59.0)
		ai_rival.opponent_player = player
		if label_rival_badge:
			label_rival_badge.text = "P2: " + ai_rival.stats.character_name.to_upper()
			
	if bwf_scoreboard:
		bwf_scoreboard.reset_scoreboard(total_match_sets)
		bwf_scoreboard.set_match_mode(total_match_sets)
		var p1_name = "P1 (" + player.stats.character_name.split("(")[0].strip_edges() + ")"
		var p2_name = "P2 (" + ai_rival.stats.character_name.split("(")[0].strip_edges() + ")"
		bwf_scoreboard.set_players(p1_name, p2_name, "JP", "DK")
		bwf_scoreboard.update_current_score(score_player, score_ai)
		bwf_scoreboard.set_sets_won(sets_won_player, sets_won_ai)
		bwf_scoreboard.set_server(current_server != "player")
		
	_update_scoreboard()
	_update_hud_stamina_bars()
	_show_spectator_banner()
	_apply_match_bgm(false)


func _show_spectator_banner() -> void:
	if not spectator_banner:
		spectator_banner = Panel.new()
		spectator_banner.name = "SpectatorBanner"
		spectator_banner.custom_minimum_size = Vector2(460, 36)
		spectator_banner.position = Vector2(410, 14)
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.05, 0.16, 0.92)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.85, 0.45, 0.95, 0.8)
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_right = 6
		sb.corner_radius_bottom_left = 6
		spectator_banner.add_theme_stylebox_override("panel", sb)
		
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.anchors_preset = Control.PRESET_FULL_RECT
		hbox.add_theme_constant_override("separation", 16)
		spectator_banner.add_child(hbox)
		
		var lbl = Label.new()
		lbl.name = "LabelSpec"
		lbl.text = "👁 CHẾ ĐỘ KHÁN GIẢ • PHÒNG: " + pvp_room_code
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.modulate = Color(0.92, 0.65, 1.0)
		hbox.add_child(lbl)
		
		btn_spectator_leave = Button.new()
		btn_spectator_leave.focus_mode = Control.FOCUS_NONE
		btn_spectator_leave.text = "THOÁT (RỜI PHÒNG)"
		btn_spectator_leave.custom_minimum_size = Vector2(130, 26)
		btn_spectator_leave.add_theme_font_size_override("font_size", 11)
		
		var sb_btn = StyleBoxFlat.new()
		sb_btn.bg_color = Color(0.70, 0.20, 0.25, 0.85)
		sb_btn.corner_radius_top_left = 4
		sb_btn.corner_radius_top_right = 4
		sb_btn.corner_radius_bottom_right = 4
		sb_btn.corner_radius_bottom_left = 4
		btn_spectator_leave.add_theme_stylebox_override("normal", sb_btn)
		btn_spectator_leave.pressed.connect(func():
			btn_spectator_leave.release_focus()
			_on_spectator_leave()
		)
		hbox.add_child(btn_spectator_leave)
		
		$HUD.add_child(spectator_banner)
		
	var lbl = spectator_banner.find_child("LabelSpec", true, false) as Label
	if lbl:
		lbl.text = "👁 CHẾ ĐỘ KHÁN GIẢ • PHÒNG: " + pvp_room_code
	spectator_banner.visible = true
	_strip_keyboard_focus(spectator_banner)


func _on_spectator_leave() -> void:
	is_spectator = false
	is_pvp_active = false
	if net_manager:
		net_manager.disconnect_peer()
	if spectator_banner:
		spectator_banner.visible = false
	_set_in_game_hud_visible(false)
	if main_menu:
		main_menu.switch_state(MainMenuController.MenuState.PVP_LOBBY)
		main_menu.visible = true
	_apply_menu_bgm()

func _on_network_packet_received(data: Dictionary) -> void:
	if not is_pvp_active:
		return
	var t = str(data.get("t", ""))
	match t:
		"opp_sync":
			if ai_rival:
				var target_x = float(data.get("x", ai_rival.global_position.x))
				var target_y = float(data.get("y", ai_rival.global_position.y))
				ai_rival.net_target_pos = Vector2(target_x, target_y)
				if not ai_rival.has_net_target or ai_rival.global_position.distance_to(ai_rival.net_target_pos) > 160.0:
					ai_rival.global_position = ai_rival.net_target_pos
				ai_rival.has_net_target = true
				ai_rival.velocity.x = float(data.get("vx", 0.0))
				ai_rival.velocity.y = float(data.get("vy", 0.0))
				ai_rival.facing = float(data.get("f", -1.0))
				ai_rival.is_swinging = bool(data.get("sw", false))
				ai_rival.is_diving = bool(data.get("dv", false))
				ai_rival.walk_phase = float(data.get("wp", ai_rival.walk_phase))
				ai_rival.balance = float(data.get("bal", 100.0))
				if ai_rival.stats and data.has("stm"):
					ai_rival.stats.stamina = float(data.get("stm", ai_rival.stats.stamina))
					ai_rival.stats.max_stamina_cap = float(data.get("cap", ai_rival.stats.max_stamina_cap))
					ai_rival.stats.accuracy = float(data.get("acc", ai_rival.stats.accuracy))

		"skill_recoil":
			if player and player.stats:
				var s_loss = float(data.get("stamina_loss", 10.0))
				var b_loss = float(data.get("balance_loss", 30.0))
				var a_bonus = float(data.get("accuracy_bonus", 0.0))
				player.stats.consume_stamina_action(s_loss)
				player.balance = max(25.0, player.balance - b_loss)
				if a_bonus != 0.0:
					player.stats.accuracy = min(100.0, player.stats.accuracy + a_bonus)
				if floating_text_mgr:
					floating_text_mgr.spawn("MIRAGE RECOIL: -%d STM!" % int(s_loss), player.global_position + Vector2(0, -50), Color(0.3, 0.8, 1.0), 16)

		"opp_shot":
			# Force rally state and unlock movement immediately on receiving any opponent shot:
			current_state = MatchState.RALLY
			is_serve_in_progress = false
			is_point_transition_active = false
			is_umpire_speaking = false
			if player:
				player.is_serving_phase = false
			if ai_rival:
				ai_rival.is_serving_phase = false
			if pvp_landing_pending:
				print("[PvP] Đối thủ đã cứu cầu thành công trong cửa sổ trễ ping! Tiếp tục pha cầu.")
				pvp_landing_pending = false
			var from_pt = Vector2(float(data.get("from_x", 890.0)), float(data.get("from_y", 450.0)))
			var target_pt = Vector2(float(data.get("target_x", 390.0)), float(data.get("target_y", 550.0)))
			var s_type = str(data.get("shot_type", "clear"))
			var err = float(data.get("err", 0.0))
			var is_perf = bool(data.get("is_perf", false))
			var is_jump = bool(data.get("is_jump", false))
			var t_mult = float(data.get("t_mult", 1.0))
			var t_lvl = int(data.get("t_lvl", 0))
			var q = float(data.get("quality", 0.8))
			
			var is_incoming_smash_type = (s_type == "smash" or s_type == "boom_smash" or s_type == "kill_smash")
			
			# ZERO-LATENCY AUDIO TRIGGER: Phát âm thanh lập tức ngay khoảnh khắc nhận gói từ đối thủ (Không chờ vật lý bù trễ)
			if is_incoming_smash_type:
				sfx_smash.play()
			elif s_type == "drop":
				var dist_to_net_incoming = abs(from_pt.x - 640.0)
				if previous_shot_type == "smash" or previous_shot_type == "boom_smash" or previous_shot_type == "kill_smash" or dist_to_net_incoming < 220.0:
					_play_sfx_string()
				else:
					if sfx_chem:
						sfx_chem.pitch_scale = randf_range(0.95, 1.05)
						sfx_chem.play()
					else:
						sfx_phong.play()
			elif s_type == "clear" or s_type == "lob" or s_type == "underhand_lift" or s_type == "weak_return":
				sfx_phong.play()
			
			if ai_rival:
				ai_rival.is_swinging = true
				ai_rival.swing_timer = 0.0
				ai_rival.can_hit = false
				if ai_rival.stats and data.has("stm"):
					ai_rival.stats.stamina = float(data.get("stm", ai_rival.stats.stamina))
					ai_rival.stats.max_stamina_cap = float(data.get("cap", ai_rival.stats.max_stamina_cap))
					ai_rival.stats.accuracy = float(data.get("acc", ai_rival.stats.accuracy))
			if player:
				player.can_hit = true
				
			var is_cinematic = (s_type == "boom_smash" and is_perf) or (s_type == "tsubame_gaeshi") or (s_type == "mirage_counter")
			if is_cinematic:
				if ai_rival:
					ai_rival.pending_special_target = target_pt
					ai_rival.pending_special_shot = s_type
					ai_rival.pending_special_from = from_pt
					ai_rival.pending_special_err = err
					ai_rival.pending_special_is_perfect = is_perf
					ai_rival.pending_special_is_jump_smash = is_jump
					ai_rival.current_tension_mult = t_mult
					ai_rival.current_tension_level = t_lvl
					
				if shuttlecock:
					shuttlecock.is_active = false
					shuttlecock.is_suspended_in_smash_slowmo = true
					shuttlecock.suspended_smash_pos = from_pt
					shuttlecock.global_position = from_pt
					shuttlecock.velocity = Vector2.ZERO
					shuttlecock.last_hitter = "ai"
					shuttlecock.is_serve = false
					shuttlecock.current_shot_type = s_type
					shuttlecock.is_boom_smash = (s_type == "boom_smash")
					shuttlecock.is_tsubame_gaeshi = (s_type == "tsubame_gaeshi")
					shuttlecock.is_mirage_counter = (s_type == "mirage_counter")
					shuttlecock.is_smash = (s_type == "smash" or s_type == "boom_smash" or s_type == "kill_smash")
			else:
				if shuttlecock:
					shuttlecock.last_hitter = "ai"
					shuttlecock.is_serve = false
					shuttlecock.launch_to_target_2d(from_pt, target_pt, s_type, err, is_perf, is_jump, t_mult, t_lvl)
					# Client-side Lag Compensation (Catch-up Tick):
					if is_pvp_active and net_manager:
						var ping_ms = net_manager.current_ping
						var transit_sec = clamp(float(ping_ms) / 2000.0, 0.005, 0.050)
						var sim = 0.0
						while sim < transit_sec:
							var dt = min(1.0 / 60.0, transit_sec - sim)
							shuttlecock._physics_process(dt)
							sim += dt
				
			_on_shot_hit(s_type, is_incoming_smash_type, q, is_perf, is_jump, from_pt, "ai")

		"opp_serve":
			var s_type = str(data.get("shot_type", "clear"))
			# ZERO-LATENCY AUDIO CUE KHI ĐỐI THỦ PHÁT CẦU:
			if s_type == "drop":
				_play_sfx_string()
			else:
				sfx_phong.play()
			
			# Khi đối thủ đã phát cầu qua mạng, bên nhận lập tức dỡ bỏ mọi khóa và thực thi phát cầu:
			is_point_transition_active = false
			is_umpire_speaking = false
			serve_cooldown = 0.0
			is_serve_in_progress = false
			current_state = MatchState.SERVE
			current_server = "ai"
			_execute_serve("ai", s_type, true)
			if is_pvp_active and net_manager and shuttlecock:
				var ping_ms = net_manager.current_ping
				var transit_sec = clamp(float(ping_ms) / 2000.0, 0.005, 0.050)
				var sim = 0.0
				while sim < transit_sec:
					var dt = min(1.0 / 60.0, transit_sec - sim)
					shuttlecock._physics_process(dt)
					sim += dt

		"score_update":
			var winner = str(data.get("winner", "ai"))
			var reason = str(data.get("reason", "ĐIỂM"))
			score_player = int(data.get("p1_pts", score_player))
			score_ai = int(data.get("p2_pts", score_ai))
			sets_won_player = int(data.get("p1_sets", sets_won_player))
			sets_won_ai = int(data.get("p2_sets", sets_won_ai))
			current_server = str(data.get("next_server", "ai"))
			current_state = MatchState.POINT_OVER
			is_point_transition_active = true
			
			if data.has("cur_set"):
				current_set_index = int(data.get("cur_set", 0))
			if bwf_scoreboard and data.has("s_p1") and data.has("s_p2"):
				bwf_scoreboard.sync_full_state(
					data.get("s_p1", []),
					data.get("s_p2", []),
					data.get("s_win", []),
					current_set_index,
					int(data.get("max_sets", total_match_sets))
				)
			_update_scoreboard()
			if winner == "player":
				_show_banner("ĐIỂM CHO BẠN! - " + reason, Color(0.2, 1.0, 0.4), true, 1.5)
			else:
				_show_banner("ĐIỂM ĐỐI THỦ! - " + reason, Color(1.0, 0.4, 0.4), true, 1.5)
				
			get_tree().create_timer(1.8).timeout.connect(func():
				if is_pvp_active:
					_setup_serve(current_server)
			)

		"match_over_update":
			var winner = str(data.get("winner", "ai"))
			var champ = "BẠN" if winner == "player" else "ĐỐI THỦ"
			_show_match_over_dialog(champ)

		"countdown_start":
			if main_menu and main_menu.visible:
				main_menu.pvp_selected_points = int(data.get("pts", target_match_points))
				main_menu.pvp_selected_sets = int(data.get("sets", total_match_sets))
				if data.has("first_server"):
					main_menu.pvp_first_server = str(data.get("first_server"))
				main_menu._start_pvp_countdown()

		"init":
			if not is_pvp_host:
				var host_char = str(data.get("char", "nishikawa"))
				var host_name = str(data.get("name", "HOST"))
				pvp_opponent_player_name = host_name
				target_match_points = int(data.get("pts", 11))
				total_match_sets = int(data.get("sets", 1))
				if data.has("first_server"):
					var fs = str(data.get("first_server"))
					current_server = "player" if fs == "p2" else "ai"
					_setup_serve(current_server)
				ai_rival.character_id = host_char
				ai_rival.stats = _create_char_stats(host_char)
				ai_rival.move_speed_x = lerp(207.0, 238.5, (ai_rival.stats.agility - 40.0) / 59.0)
				if bwf_scoreboard:
					bwf_scoreboard.reset_scoreboard(total_match_sets)
					bwf_scoreboard.set_match_mode(total_match_sets)
					bwf_scoreboard.set_players(
						pvp_local_player_name,
						pvp_opponent_player_name
					)
				net_manager.send_packet({"t": "init_ack", "char": pvp_local_char, "name": pvp_local_player_name})
		"init_ack":
			if is_pvp_host:
				var guest_char = str(data.get("char", "wall"))
				var guest_name = str(data.get("name", "GUEST"))
				pvp_opponent_player_name = guest_name
				ai_rival.character_id = guest_char
				ai_rival.stats = _create_char_stats(guest_char)
				ai_rival.move_speed_x = lerp(207.0, 238.5, (ai_rival.stats.agility - 40.0) / 59.0)
				if bwf_scoreboard:
					bwf_scoreboard.set_players(
						pvp_local_player_name,
						pvp_opponent_player_name
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
				var g_type = str(data.get("type", "clear"))
				var is_g_smash = (g_type == "smash" or g_type == "boom_smash" or g_type == "kill_smash")
				_on_shot_hit(
					g_type,
					is_g_smash,
					float(data.get("q", 0.8)),
					bool(data.get("perf", false)),
					bool(data.get("jump", false)),
					Vector2(float(data.get("px", 800.0)), float(data.get("py", 400.0))),
					"ai"
				)
		"g_serve":
			if is_pvp_host and current_state == MatchState.SERVE and current_server == "ai" and not is_serve_in_progress and not is_point_transition_active and serve_cooldown <= 0.0:
				_execute_serve("ai", str(data.get("shot_type", "clear")))

		"spectator_joined":
			_start_spectator_mode(data)

		"spec_sync":
			if not is_spectator: return
			var role = str(data.get("role", "p1"))
			var target_node = player if role == "p1" else ai_rival
			if target_node:
				var target_x = float(data.get("x", target_node.global_position.x))
				var target_y = float(data.get("y", target_node.global_position.y))
				target_node.net_target_pos = Vector2(target_x, target_y)
				if not target_node.has_net_target or target_node.global_position.distance_to(target_node.net_target_pos) > 160.0:
					target_node.global_position = target_node.net_target_pos
				target_node.has_net_target = true
				target_node.velocity.x = float(data.get("vx", 0.0))
				target_node.velocity.y = float(data.get("vy", 0.0))
				target_node.facing = float(data.get("f", 1.0 if role == "p1" else -1.0))
				target_node.is_swinging = bool(data.get("sw", false))
				target_node.is_diving = bool(data.get("dv", false))
				target_node.walk_phase = float(data.get("wp", target_node.walk_phase))
				target_node.balance = float(data.get("bal", 100.0))
				if target_node.stats:
					if data.has("stm"): target_node.stats.stamina = float(data.get("stm", target_node.stats.stamina))
					if data.has("cap"): target_node.stats.max_stamina_cap = float(data.get("cap", target_node.stats.max_stamina_cap))
					if data.has("acc"): target_node.stats.accuracy = float(data.get("acc", target_node.stats.accuracy))

		"spec_shot":
			if not is_spectator: return
			var role = str(data.get("role", "p1"))
			var hitter_node = player if role == "p1" else ai_rival
			var from_pt = Vector2(float(data.get("from_x", 400.0)), float(data.get("from_y", 400.0)))
			var target_pt = Vector2(float(data.get("target_x", 890.0 if role == "p1" else 390.0)), float(data.get("target_y", 550.0)))
			var s_type = str(data.get("shot_type", "clear"))
			var err = float(data.get("err", 0.0))
			var is_perf = bool(data.get("is_perf", false))
			var is_jump = bool(data.get("is_jump", false))
			var t_mult = float(data.get("t_mult", 1.0))
			var t_lvl = int(data.get("t_lvl", 0))
			var q = float(data.get("quality", 0.8))
			var hitter_str = "player" if role == "p1" else "ai"
			
			if hitter_node:
				hitter_node.is_swinging = true
				hitter_node.swing_timer = 0.0
				hitter_node.can_hit = false
				if hitter_node.stats and data.has("stm"):
					hitter_node.stats.stamina = float(data.get("stm", hitter_node.stats.stamina))
					hitter_node.stats.max_stamina_cap = float(data.get("cap", hitter_node.stats.max_stamina_cap))
					hitter_node.stats.accuracy = float(data.get("acc", hitter_node.stats.accuracy))
					
			var other_node = ai_rival if role == "p1" else player
			if other_node:
				other_node.can_hit = true
				
			var is_cinematic = (s_type == "boom_smash" and is_perf) or (s_type == "tsubame_gaeshi") or (s_type == "mirage_counter")
			if is_cinematic and hitter_node:
				hitter_node.pending_special_target = target_pt
				hitter_node.pending_special_shot = s_type
				hitter_node.pending_special_from = from_pt
				hitter_node.pending_special_err = err
				hitter_node.pending_special_is_perfect = is_perf
				hitter_node.pending_special_is_jump_smash = is_jump
				hitter_node.current_tension_mult = t_mult
				hitter_node.current_tension_level = t_lvl
				
				if shuttlecock:
					shuttlecock.is_active = false
					shuttlecock.is_suspended_in_smash_slowmo = true
					shuttlecock.suspended_smash_pos = from_pt
					shuttlecock.global_position = from_pt
					shuttlecock.velocity = Vector2.ZERO
					shuttlecock.last_hitter = hitter_str
					shuttlecock.is_serve = false
			else:
				if shuttlecock:
					shuttlecock.last_hitter = hitter_str
					shuttlecock.is_serve = false
					shuttlecock.launch_to_target_2d(from_pt, target_pt, s_type, err, is_perf, is_jump, t_mult, t_lvl)
					if is_pvp_active and net_manager:
						var ping_ms = net_manager.current_ping
						var transit_sec = clamp(float(ping_ms) / 2000.0, 0.005, 0.050)
						var sim = 0.0
						while sim < transit_sec:
							var dt = min(1.0 / 60.0, transit_sec - sim)
							shuttlecock._physics_process(dt)
							sim += dt
					
			var is_spec_smash = (s_type == "smash" or s_type == "boom_smash" or s_type == "kill_smash")
			_on_shot_hit(s_type, is_spec_smash, q, is_perf, is_jump, from_pt, hitter_str)

		"spec_serve":
			if not is_spectator: return
			var role = str(data.get("role", "p1"))
			var s_type = str(data.get("shot_type", "clear"))
			var server_str = "player" if role == "p1" else "ai"
			_execute_serve(server_str, s_type, true)

		"spec_score":
			if not is_spectator: return
			var winner = str(data.get("winner", "player"))
			var reason = str(data.get("reason", "ĐIỂM"))
			score_player = int(data.get("p1_pts", score_player))
			score_ai = int(data.get("p2_pts", score_ai))
			sets_won_player = int(data.get("p1_sets", sets_won_player))
			sets_won_ai = int(data.get("p2_sets", sets_won_ai))
			var srv = str(data.get("next_server", "player"))
			current_server = "player" if srv == "player" or srv == "p1" else "ai"
			current_state = MatchState.POINT_OVER
			
			if data.has("cur_set"):
				current_set_index = int(data.get("cur_set", 0))
			if bwf_scoreboard and data.has("s_p1") and data.has("s_p2"):
				bwf_scoreboard.sync_full_state(
					data.get("s_p1", []),
					data.get("s_p2", []),
					data.get("s_win", []),
					current_set_index,
					int(data.get("max_sets", total_match_sets))
				)
			_update_scoreboard()
			if bwf_scoreboard:
				bwf_scoreboard.set_server(current_server != "player")
				
			var winner_label = "P1 (SÂN TRÁI)" if winner == "player" else "P2 (SÂN PHẢI)"
			_show_banner("ĐIỂM CHO %s! - %s" % [winner_label, reason], Color(0.95, 0.85, 0.25), true, 1.5)
			
			get_tree().create_timer(1.8).timeout.connect(func():
				if is_pvp_active and is_spectator:
					_setup_serve(current_server)
			)

		"spec_match_over":
			if not is_spectator: return
			var winner = str(data.get("winner", "player"))
			var champ = "P1 (" + player.stats.character_name + ")" if (player and player.stats and winner == "player") else "P2 (" + (ai_rival.stats.character_name if ai_rival and ai_rival.stats else "RIVAL") + ")"
			_show_match_over_dialog(champ)

		"room_closed":
			if is_spectator:
				_show_banner("PHÒNG THI ĐẤU ĐÃ ĐÓNG.", Color(1.0, 0.4, 0.4), true, 4.0)

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

func _strip_keyboard_focus(root_node: Node) -> void:
	if not root_node:
		return
	if root_node is BaseButton:
		root_node.focus_mode = Control.FOCUS_NONE
		if not root_node.pressed.is_connected(root_node.release_focus):
			root_node.pressed.connect(root_node.release_focus)
	for child in root_node.get_children():
		_strip_keyboard_focus(child)

func _input(event: InputEvent) -> void:
	# Khử hoàn toàn lỗi bấm SPACE / ENTER vô tình kích hoạt các nút UI (Đổi tướng, Cài đặt, Fullscreen, v.v.)
	# Các nút đó giờ chỉ cho phép dùng chuột click, không phím tắt, không enter hay space để thay click chuột
	if event is InputEventKey and (event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]):
		var cur_focus = get_viewport().gui_get_focus_owner()
		if cur_focus is BaseButton:
			cur_focus.release_focus()

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventScreenDrag) and not touch_controls_enabled:
		touch_controls_enabled = true
		if virtual_touch_pad and (not main_menu or not main_menu.visible):
			virtual_touch_pad.visible = true
		if controls_bar:
			controls_bar.visible = false
		_update_settings_ui()
		
	if main_menu and main_menu.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				if main_menu.current_state in [MainMenuController.MenuState.MATCH_SETUP, MainMenuController.MenuState.PVP_LOBBY, MainMenuController.MenuState.SETTINGS]:
					if net_manager:
						net_manager.disconnect_peer()
					main_menu.switch_state(MainMenuController.MenuState.TITLE)
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if is_spectator:
				_on_spectator_leave()
			else:
				_set_in_game_hud_visible(false)
				main_menu.switch_state(MainMenuController.MenuState.TITLE)
				main_menu.visible = true


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

	if btn_bgm_match:
		btn_bgm_match.text = "BẬT" if bgm_match_enabled else "TẮT"
		btn_bgm_match.modulate = Color(1.2, 3.2, 1.2) if bgm_match_enabled else Color(1.8, 0.6, 0.6)
	if lbl_bgm_vol_match:
		lbl_bgm_vol_match.text = "Âm lượng nhạc: %d%%" % int(round(bgm_match_volume * 100.0))
	if slider_bgm_match and abs(slider_bgm_match.value - bgm_match_volume) > 0.01:
		slider_bgm_match.value = bgm_match_volume
		
	if btn_touch_toggle:
		btn_touch_toggle.text = "BẬT" if touch_controls_enabled else "TẮT"
		btn_touch_toggle.modulate = Color(1.2, 3.2, 1.2) if touch_controls_enabled else Color(1.8, 0.6, 0.6)
	if main_menu:
		main_menu.touch_controls_enabled = touch_controls_enabled
		if main_menu.btn_touch_toggle_menu:
			main_menu.btn_touch_toggle_menu.text = "BẬT" if touch_controls_enabled else "TẮT"
			main_menu.btn_touch_toggle_menu.modulate = Color(0.2, 1.0, 0.4) if touch_controls_enabled else Color(1.0, 0.4, 0.4)

	if btn_low_gfx_toggle:
		btn_low_gfx_toggle.text = "[ BẬT ]" if low_graphics_mode else "[ TẮT ]"
		btn_low_gfx_toggle.modulate = Color(0.2, 2.5, 0.4) if low_graphics_mode else Color(1.8, 0.6, 0.6)
	var floor_refl = get_node_or_null("FloorReflection")
	if floor_refl:
		floor_refl.visible = (not low_graphics_mode) and (not OS.has_feature("web"))


func _apply_match_bgm(restart_from_beginning: bool = false) -> void:
	if not bgm_lobby:
		return
	if bgm_match_enabled:
		var target_db = linear_to_db(clamp(bgm_match_volume, 0.001, 1.0))
		bgm_lobby.volume_db = target_db
		if restart_from_beginning or not bgm_lobby.playing:
			bgm_lobby.play(0.0)
		else:
			var tw = create_tween()
			tw.tween_property(bgm_lobby, "volume_db", target_db, 0.5)
	else:
		if bgm_lobby.playing:
			var tw = create_tween()
			tw.tween_property(bgm_lobby, "volume_db", -40.0, 0.5)
			tw.finished.connect(func():
				if bgm_lobby and not bgm_match_enabled:
					bgm_lobby.stop()
			)


func _apply_menu_bgm() -> void:
	if not bgm_lobby:
		return
	var target_db = -3.0
	if not bgm_lobby.playing:
		bgm_lobby.volume_db = target_db
		bgm_lobby.play()
	else:
		var tw = create_tween()
		tw.tween_property(bgm_lobby, "volume_db", target_db, 0.5)


func _update_difficulty_buttons() -> void:
	_update_settings_ui()


func _process(delta: float) -> void:
	# Authoritative PvP Landing Grace Timer (Đợi gói cứu cầu muộn do độ trễ mạng từ Guest)
	if pvp_landing_pending:
		pvp_landing_grace_timer -= delta
		if pvp_landing_grace_timer <= 0.0:
			pvp_landing_pending = false
			_confirm_shuttlecock_landed(pvp_landing_pending_pos, pvp_landing_pending_is_serve)
			
	# Cố định tâm camera tuyệt đối tại giữa màn hình (tránh mọi lỗi trôi/lệch khung)
	if camera:
		camera.position = Vector2(640.0, 360.0)
	
	# Đồng bộ kích thước phản chiếu sàn ngay tức thì khi chuyển đổi Fullscreen / Maximize (Chỉ Desktop)
	if not OS.has_feature("web"):
		var cur_win = Vector2(DisplayServer.window_get_size())
		if cur_win != _last_window_size and cur_win.x > 0.0 and cur_win.y > 0.0:
			_update_floor_reflection()
	
	_update_hud_stamina_bars()
	
	# Camera Screen Shake
	if shake_amount > 0.0:
		if camera:
			camera.offset = Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
		shake_amount = move_toward(shake_amount, 0.0, delta * 55.0)
	else:
		if camera:
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
	
	# Authoritative WebSocket PvP Multiplayer Sync (Fixed 30Hz Tick Rate with Compact Precision)
	if is_pvp_active and not is_spectator and net_manager:
		pvp_net_sync_timer += delta
		if pvp_net_sync_timer >= PVP_NET_SYNC_INTERVAL:
			pvp_net_sync_timer = fmod(pvp_net_sync_timer, PVP_NET_SYNC_INTERVAL)
			net_manager.send_packet({
				"t": "sync",
				"x": snapped(player.global_position.x, 0.1),
				"y": snapped(player.global_position.y, 0.1),
				"vx": snapped(player.velocity.x, 0.1),
				"vy": snapped(player.velocity.y, 0.1),
				"f": player.facing,
				"sw": player.is_swinging,
				"dv": player.is_diving,
				"wp": snapped(player.walk_phase, 0.01),
				"bal": snapped(player.balance, 0.1),
				"stm": snapped(player.stats.stamina, 0.1) if player.stats else 100.0,
				"cap": snapped(player.stats.max_stamina_cap, 0.1) if player.stats else 100.0,
				"acc": snapped(player.stats.accuracy, 0.1) if player.stats else 100.0
			})
	
	_update_stats_display()
	
	# Mở khóa đánh cầu cho bên nhận cầu ngay lập tức (Zero delay, không cần đợi cầu bay qua lưới)
	if current_state == MatchState.RALLY and shuttlecock.is_active:
		if shuttlecock.last_hitter == "player":
			ai_rival.can_hit = true
		elif shuttlecock.last_hitter == "ai":
			player.can_hit = true
		prev_shuttle_x = shuttlecock.global_position.x
	
	if serve_cooldown > 0.0:
		serve_cooldown = max(0.0, serve_cooldown - delta)
		if serve_cooldown <= 0.0:
			is_point_transition_active = false
	
	# In SERVE state: player input to serve
	if current_state == MatchState.SERVE and not is_spectator:
		_process_serve_state()
	
	# Reset match key (R) - KHÓA HOÀN TOÀN khi đang trong trận PVP, Spectator, hoặc khi ngoài menu (chỉ dùng trong trận với AI)
	var cur_r = Input.is_key_pressed(KEY_R)
	var can_reset_r = not is_pvp_active and not is_spectator and not (main_menu and main_menu.visible) and (current_state == MatchState.SERVE or current_state == MatchState.RALLY or current_state == MatchState.POINT_OVER)
	if cur_r and not prev_key_r and can_reset_r:
		score_player = 0
		score_ai = 0
		_update_scoreboard()
		if ai_rival:
			ai_rival.reset_in_match_learning()
		_setup_serve("player")
		if sfx_low_ball_play:
			sfx_low_ball_play.play()
	prev_key_r = cur_r


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
	
	var call_duration: float = 2.88
	if sfx_low_ball_play and sfx_low_ball_play.stream:
		call_duration = max(call_duration, sfx_low_ball_play.stream.get_length())
	
	_show_banner("TRỌNG TÀI BẮT ĐẦU TRẬN ĐẤU (PLAY)...", Color(1.0, 0.9, 0.3))
	
	get_tree().create_timer(call_duration).timeout.connect(func():
		is_umpire_speaking = false
		if current_state == MatchState.SERVE:
			var server_name = "BẠN" if server == "player" else ("ĐỐI THỦ" if is_pvp_active else "RIVAL AI")
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
	if is_umpire_speaking or is_point_transition_active or serve_cooldown > 0.0:
		return
	var touch_shot = player.touch_shot_pressed if player else ""
	if is_pvp_active:
		if current_server == "player" and net_manager:
			if Input.is_key_pressed(KEY_K) or touch_shot == "clear":
				if player: player.touch_shot_pressed = ""
				_execute_serve("player", "clear")
				net_manager.send_packet({"t": "serve", "shot_type": "clear"})
			elif Input.is_key_pressed(KEY_J) or touch_shot == "drop":
				if player: player.touch_shot_pressed = ""
				_execute_serve("player", "drop")
				net_manager.send_packet({"t": "serve", "shot_type": "drop"})
		return
	else:
		if current_server == "player":
			if Input.is_key_pressed(KEY_K) or touch_shot == "clear":
				if player: player.touch_shot_pressed = ""
				_execute_serve("player", "clear")
			elif Input.is_key_pressed(KEY_J) or touch_shot == "drop":
				if player: player.touch_shot_pressed = ""
				_execute_serve("player", "drop")


func _on_touch_jump_triggered() -> void:
	if main_menu and main_menu.visible:
		return
	if is_umpire_speaking:
		return
	if player and is_instance_valid(player):
		player.touch_jump_pressed = true

func _on_touch_shot_triggered(shot_type: String) -> void:
	if main_menu and main_menu.visible:
		return
	if is_umpire_speaking:
		return
		
	# 1. Trong pha giao cầu:
	if current_state == MatchState.SERVE and current_server == "player":
		if not is_serve_in_progress and not is_point_transition_active and serve_cooldown <= 0.0:
			if shot_type == "clear" or shot_type == "drop":
				_execute_serve("player", shot_type)
				if is_pvp_active and net_manager:
					net_manager.send_packet({"t": "serve", "shot_type": shot_type})
		return
		
	# 2. Trong pha rally (đang đánh cầu bình thường):
	if player and is_instance_valid(player):
		if shot_type == "slide":
			player.start_slide(1.0 if player.court_side == "player" else -1.0)
		else:
			player.touch_shot_pressed = shot_type


func _setup_serve(server: String) -> void:
	pvp_landing_pending = false
	pvp_landing_grace_timer = 0.0
	current_state = MatchState.SERVE
	current_server = server
	is_serve_in_progress = false
	previous_shot_type = ""
	serve_cooldown = 0.7
	is_point_transition_active = true
	
	if rally_tension:
		rally_tension.reset()
	
	# Phục hồi an toàn tuyệt đối mọi trạng thái hiệu ứng, tránh lỗi kẹt màn hình hay timescale
	Engine.time_scale = 1.0
	if camera:
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
	
	if player:
		player.reset_position(390.0, FLOOR_Y)
		player.is_serving_phase = true
		player.is_server_turn = (server == "player")
	if ai_rival:
		ai_rival.reset_position(890.0, FLOOR_Y)
		ai_rival.is_serving_phase = true
		ai_rival.is_server_turn = (server == "ai")
	
	var serve_pos = Vector2(390.0, FLOOR_Y - 35.0) if server == "player" else Vector2(890.0, FLOOR_Y - 35.0)
	if shuttlecock:
		shuttlecock.global_position = serve_pos
		shuttlecock.velocity = Vector2.ZERO
		shuttlecock.is_active = false
		shuttlecock.is_serve = false
	prev_shuttle_x = serve_pos.x
	
	if bwf_scoreboard:
		bwf_scoreboard.set_server(server != "player")
	
	if is_umpire_speaking:
		if label_banner:
			label_banner.visible = false
			label_banner.text = ""
	else:
		var server_name = "BẠN" if server == "player" else ("ĐỐI THỦ" if is_pvp_active else "RIVAL AI")
		if is_pvp_active and server == "ai":
			_show_banner("ĐỐI THỦ ĐANG GIAO CẦU (CHỜ ĐÓN CẦU)...", Color(1.0, 0.9, 0.4))
		else:
			_show_banner("%s GIAO CẦU (BẤM J HOẶC K)" % server_name, Color(1.0, 1.0, 1.0))
		
		# AI auto serve after 0.8s (only if not in PvP)
		if server == "ai" and not is_pvp_active:
			get_tree().create_timer(0.8).timeout.connect(func():
				if current_state == MatchState.SERVE and current_server == "ai" and not is_umpire_speaking and not is_pvp_active:
					var is_short = randf() < 0.35
					var shot_type = "drop" if is_short else "clear"
					_execute_serve("ai", shot_type)
			)


func _execute_serve(server: String, shot_type: String = "clear", force_network_serve: bool = false) -> void:
	if not force_network_serve:
		if current_state != MatchState.SERVE or is_serve_in_progress or is_point_transition_active or serve_cooldown > 0.0 or is_umpire_speaking:
			return
	current_state = MatchState.RALLY
	is_serve_in_progress = true
	is_point_transition_active = false
	is_umpire_speaking = false
	serve_cooldown = 0.0
	
	if rally_tension:
		rally_tension.reset()
	if player:
		player.current_tension_mult = 1.0
		player.current_tension_level = 0
	if ai_rival:
		ai_rival.current_tension_mult = 1.0
		ai_rival.current_tension_level = 0
	
	# UNLOCK MOVEMENT FOR BOTH PLAYERS IMMEDIATELY
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
	
	current_shot_max_speed = ((86.0 if shot_type == "drop" else 104.0) * 0.80) + randf_range(-3.5, 3.5)
	if not (is_pvp_active and force_network_serve):
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
		var has_pending_special = player and player.pending_special_target != Vector2.ZERO
		var target_x = player.pending_special_target.x if has_pending_special else (shuttlecock.launch_target.x if shuttlecock else 890.0)
		var target_y = player.pending_special_target.y if has_pending_special else (shuttlecock.launch_target.y if shuttlecock else FLOOR_Y)
		var err_val = player.pending_special_err if has_pending_special else (shuttlecock.last_error_offset_x if shuttlecock else 0.0)
		var t_mult = player.current_tension_mult if player else 1.0
		var t_lvl = player.current_tension_level if player else 0
		net_manager.send_packet({
			"t": "shot",
			"from_x": contact_pos.x,
			"from_y": contact_pos.y,
			"target_x": target_x,
			"target_y": target_y,
			"shot_type": shot_type,
			"err": err_val,
			"is_perf": is_perfect,
			"is_jump": is_jump_shot,
			"t_mult": t_mult,
			"t_lvl": t_lvl,
			"quality": quality,
			"stm": player.stats.stamina if player.stats else 100.0,
			"cap": player.stats.max_stamina_cap if player.stats else 100.0,
			"acc": player.stats.accuracy if player.stats else 100.0
		})
		if shot_type == "mirage_counter":
			net_manager.send_packet({
				"t": "skill_recoil",
				"stamina_loss": 10.0,
				"balance_loss": 30.0,
				"accuracy_bonus": 0.0
			})
	elif is_pvp_active and hitter == "ai" and shot_type == "mirage_counter":
		if player and player.stats:
			player.stats.consume_stamina_action(10.0)
			player.balance = max(25.0, player.balance - 30.0)
			if floating_text_mgr:
				floating_text_mgr.spawn("MIRAGE RECOIL: -10 STM!", player.global_position + Vector2(0, -50), Color(0.3, 0.8, 1.0), 16)
	is_serve_in_progress = false
	if shuttlecock:
		shuttlecock.is_serve = false
	
	# Cập nhật Dynamic Rally Tension 2.0 (Heat Meter System)
	var is_actual_smash = (shot_type == "smash" or shot_type == "kill_smash" or shot_type == "boom_smash")
	var tension_lvl = 0
	var tension_mult = 1.0
	if rally_tension:
		var is_boom_shot = (shot_type == "boom_smash" or (is_actual_smash and quality >= 0.88))
		tension_lvl = rally_tension.add_shot(shot_type, is_actual_smash, is_boom_shot)
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
			if is_actual_smash and hitter == "player":
				ai_rival.ai_pressure_model.on_opponent_smash(shot_type == "boom_smash")
			elif shot_type == "drop":
				# Đòn bỏ nhỏ êm dịu làm nguội bớt áp lực tâm lý của AI
				ai_rival.ai_pressure_model.cool_down_pressure(0.08)
	
	var is_jump_smash = (is_jump_shot or shot_type == "kill_smash") and is_actual_smash
	var hitter_node = player if hitter == "player" else ai_rival
	var torque_mult = hitter_node.stats.get_effective_smash_speed_mult() if (hitter_node and hitter_node.stats) else 1.0
	
	# Ghi nhận trạng thái cú đánh trước đó (để phát hiện cú đỡ cầu đập bằng drop)
	var was_incoming_smash = (previous_shot_type == "smash" or previous_shot_type == "boom_smash" or previous_shot_type == "kill_smash")
	previous_shot_type = shot_type

	# 1. NISHIKAWA GOLDEN SMASH (boom_smash): Ngưng đọng 1s, sấm sét nổ vang, đảo màu trắng đen!
	if shot_type == "boom_smash" and is_perfect:
		var base_spd = 134.4 # Giảm 70%
		var floor_prox = clamp((contact_pos.y - 360.0) / 220.0, 0.0, 1.0)
		var low_smash_boost = 1.0 + floor_prox * 0.10 # Cầu càng gần sân thì đập càng nhanh hơn tí
		current_shot_max_speed = (base_spd + (quality * 8.0) + randf_range(-4.0, 4.0)) * tension_mult * torque_mult * low_smash_boost
		_trigger_perfect_impact_effect(contact_pos, hitter)
		return
		
	# 2. TSUBAME GAESHI (Fuji): Cắt xoáy lướt sà sát mép lưới, góc cắm hiểm kèm slow-mo (KHÔNG TRẮNG ĐEN)
	if shot_type == "tsubame_gaeshi":
		current_shot_max_speed = (83.2 + randf_range(-3.0, 3.0)) * tension_mult # Giảm 80%
		if is_perfect and floating_text_mgr:
			floating_text_mgr.spawn("PERFECT!", contact_pos + Vector2(0, -22), Color(1.0, 0.92, 0.25), 16)
		_trigger_fuji_cinematic_slowmo(contact_pos, hitter)
		return
		
	# 3. MIRAGE COUNTER (The Wall): Hóa giải smash, bung cầu cao nhanh về cuối sân và hồi 20% thể lực kèm slow-mo (KHÔNG TRẮNG ĐEN)
	if shot_type == "mirage_counter":
		var shield_center = hitter_node.global_position + Vector2(0.0, -32.0) if hitter_node else contact_pos
		_trigger_aoi_shield_effect(shield_center)
		_trigger_aoi_cinematic_slowmo(contact_pos, hitter)
		
		current_shot_max_speed = (97.6 + randf_range(-3.0, 3.0)) * tension_mult # Giảm 80%
		if is_perfect and floating_text_mgr:
			floating_text_mgr.spawn("PERFECT!", contact_pos + Vector2(0, -22), Color(1.0, 0.92, 0.25), 16)
		return

	# Hiển thị chữ PERFECT bay nhẹ lên trên tại vị trí đánh (Không hiện banner to giữa màn hình):
	if is_perfect and floating_text_mgr:
		floating_text_mgr.spawn("PERFECT!", contact_pos + Vector2(0, -22), Color(1.0, 0.92, 0.25), 16)

	var dist_to_net = abs(contact_pos.x - 640.0)
	var skip_audio = is_pvp_active and hitter == "ai"

	# Các cú đánh thông thường khác:
	if shot_type == "weak_return":
		if not skip_audio:
			sfx_phong.play()
		current_shot_max_speed = (57.6 + randf_range(-2.0, 2.0))
		shake_amount = 1.0
		_show_banner("CHANCE BALL!", Color(1.0, 1.0, 1.0), true, 1.0)
	elif is_actual_smash:
		if not skip_audio:
			sfx_smash.play()
		var is_kill = (shot_type == "kill_smash")
		var base_spd = 126.0 if is_kill else 99.4 # Giảm 70% (180 -> 126, 142 -> 99.4)
		var floor_prox = clamp((contact_pos.y - 360.0) / 220.0, 0.0, 1.0)
		var low_smash_boost = 1.0 + floor_prox * 0.10 # Cầu càng gần sân thì đập càng nhanh hơn tí
		current_shot_max_speed = (base_spd + (quality * 7.0) + randf_range(-4.2, 4.2)) * tension_mult * torque_mult * low_smash_boost
		
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
		if not skip_audio:
			if was_incoming_smash or is_near_net_drop:
				_play_sfx_string()
			else:
				if sfx_chem:
					sfx_chem.pitch_scale = randf_range(0.95, 1.05)
					sfx_chem.play()
				else:
					sfx_phong.play()
				
		if shuttlecock and shuttlecock.is_net_drop:
			current_shot_max_speed = (62.4 + randf_range(-3.0, 3.0)) * tension_mult # Giảm 80%
			shake_amount = 2.0
		else:
			var base_spd = 72.0 if is_perfect else 64.0 # Giảm 80% (90 -> 72, 80 -> 64)
			current_shot_max_speed = (base_spd + randf_range(-3.2, 3.2)) * tension_mult
			shake_amount = 4.0 if is_perfect else 2.0
	elif shot_type == "clear" or shot_type == "underhand_lift":
		# PHÂN LOẠI CLEAR / LIFT:
		# Nếu bung cầu gần lưới -> Âm thanh string.wav
		# Nếu phông sâu từ đáy sân -> Âm thanh phong.wav
		if not skip_audio:
			if dist_to_net < 220.0:
				_play_sfx_string()
			else:
				if sfx_phong:
					sfx_phong.pitch_scale = randf_range(0.97, 1.04)
					sfx_phong.play()
				
		var base_spd = 89.6 if is_perfect else (80.0 if quality > 0.7 else 70.4) # Giảm 80% (112 -> 89.6, 100 -> 80)
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
	# 1. Đảo màu toàn bộ game sang trắng đen manga siêu kịch tính cho cú Boom Smash (Hỗ trợ cả PC & Web)
	flash_alpha = 0.0
	if flash_rect:
		flash_rect.visible = false
	if grayscale_rect and grayscale_rect.material:
		grayscale_rect.visible = true
		grayscale_rect.material.set_shader_parameter("grayscale_amount", 1.0)
	else:
		if grayscale_rect:
			grayscale_rect.visible = false
	
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
	var n_bolts: int = 6 if low_graphics_mode else 16
	var bolts: Array = []
	for b_idx in range(n_bolts):
		var base_ang = (TAU / float(n_bolts)) * b_idx + randf_range(-0.25, 0.25)
		var max_len = randf_range(160.0, 240.0) if low_graphics_mode else randf_range(220.0, 310.0)
		var n_segs = 3 if low_graphics_mode else randi_range(7, 9)
		
		var pts: Array[Vector2] = [Vector2.ZERO]
		var cur_v = Vector2.ZERO
		var dir_main = Vector2(cos(base_ang), sin(base_ang))
		var perp = Vector2(-dir_main.y, dir_main.x)
		
		for s in range(n_segs):
			var s_len = (max_len / float(n_segs)) * randf_range(0.85, 1.25)
			var zigzag = perp * randf_range(-14.0, 14.0) if low_graphics_mode else (perp * randf_range(-25.0, 25.0))
			cur_v += dir_main * s_len + zigzag
			pts.append(cur_v)
		
		# Nhánh phụ (Sub-branches rễ cây sấm sét) - Tắt hoàn toàn trong chế độ cấu hình thấp để chống lag
		var sub_data: Array = []
		if not low_graphics_mode and randf() < 0.75 and pts.size() >= 4:
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
	
	# Hạt tia lửa điện (flying sparks) của đợt duy nhất này - Tắt trong chế độ cấu hình thấp
	var sparks: Array = []
	if not low_graphics_mode:
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
	
	# Chế độ đồ họa thấp: Chỉ vẽ 1 vòng sáng và các đường sét chính tinh giản
	if low_graphics_mode:
		nishikawa_lightning.draw_circle(origin, 18.0 * (1.0 - t * 0.7), Color(1.0, 0.85, 0.25, 0.85))
		if not impact_lightning_branches.is_empty():
			var wave_data_low = impact_lightning_branches[0]
			var bolts_low: Array = wave_data_low["bolts"]
			var wave_alpha_low = clamp(1.0 - t * 0.7, 0.0, 1.0)
			for b in bolts_low:
				var pts: Array[Vector2] = b["pts"]
				if pts.size() >= 2:
					var simple_pts = PackedVector2Array()
					for pt in pts:
						simple_pts.append(origin + pt)
					nishikawa_lightning.draw_polyline(simple_pts, Color(1.0, 0.9, 0.35, wave_alpha_low * 0.9), 2.5, true)
		return
	
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
	
	# Chế độ đồ họa thấp: Chỉ vẽ 1 vòng khiên lục giác đơn giản nhẹ nhàng
	if low_graphics_mode:
		aoi_shield.draw_arc(aoi_shield_center, r_main, 0, TAU, 16, Color(0.3, 0.8, 1.0, alpha * 0.85), 2.5, true)
		return
	
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
	if current_state != MatchState.RALLY and not pvp_landing_pending:
		return
	
	# Ngăn hoàn toàn lỗi va chạm sàn sớm trong 250ms đầu sau khi phát cầu
	if is_serve_in_progress and shuttlecock and shuttlecock.flight_time_elapsed < 0.25:
		return
	
	if is_pvp_active and not is_pvp_host:
		return
	
	# Trong trận PvP máy Host:
	# Nếu cầu chạm sàn bên phần sân của Guest (pos.x > NET_X) và KHÔNG phải lỗi chạm lưới:
	# Guest có Defensive Hit Authority. Host chờ cửa sổ trễ ping để đón cú đánh cứu cầu muộn từ Guest.
	if is_pvp_active and is_pvp_host:
		if pos.x > NET_X and not (shuttlecock and shuttlecock.is_net_fault):
			pvp_landing_pending = true
			pvp_landing_pending_pos = pos
			pvp_landing_pending_is_serve = is_serve_in_progress
			var p_ms = net_manager.current_ping if net_manager else 60
			pvp_landing_grace_timer = clamp(float(p_ms) / 1000.0 + 0.16, 0.22, 0.45)
			shake_amount = max(shake_amount, 5.0 if (shuttlecock and shuttlecock.is_smash) else 2.5)
			return
			
	_confirm_shuttlecock_landed(pos, is_serve_in_progress)


func _confirm_shuttlecock_landed(pos: Vector2, p_is_serve: bool = false) -> void:
	if is_point_transition_active:
		return
	if p_is_serve and shuttlecock and shuttlecock.flight_time_elapsed < 0.25:
		return
	is_point_transition_active = true
	pvp_landing_pending = false
	current_state = MatchState.POINT_OVER
	shake_amount = max(shake_amount, 14.0 if (shuttlecock and shuttlecock.is_smash) else 4.0)
	
	shockwave_pos = pos
	shockwave_radius = 8.0
	shockwave_alpha = 0.9 if (shuttlecock and shuttlecock.is_smash) else 0.5
	_redraw_effects()
	
	if is_pvp_active and not is_pvp_host:
		return
	
	var point_winner = ""
	var reason = ""
	
	# 1. KIỂM TRA LUẬT PHÁT CẦU (SERVE FAULT CHECK)
	if p_is_serve:
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
	if shuttlecock and shuttlecock.is_net_fault:
		_show_landing_callout(pos, "FAULT", "CHƯA QUA LƯỚI")
		if shuttlecock and shuttlecock.last_hitter == "player":
			point_winner = "ai"
			reason = "CẦU KHÔNG QUA LƯỚI! ĐIỂM CHO RIVAL AI"
		else:
			point_winner = "player"
			reason = "CẦU KHÔNG QUA LƯỚI! ĐIỂM CHO PLAYER"
	elif pos.x < LEFT_OUT_X or pos.x > RIGHT_OUT_X:
		_show_landing_callout(pos, "OUT", "NGOÀI SÂN")
		if shuttlecock and shuttlecock.last_hitter == "player":
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
	
	if is_pvp_active and not is_pvp_host:
		return
	
	if is_serve_in_progress:
		is_serve_in_progress = false
		current_state = MatchState.POINT_OVER
		is_point_transition_active = true
		var winner = "ai" if current_server == "player" else "player"
		_award_point(winner, "GIAO CẦU MẮC LƯỚI! ĐIỂM CHO %s" % ("RIVAL" if winner == "ai" else "PLAYER"))
		return
	
	get_tree().create_timer(0.35).timeout.connect(func():
		if current_state == MatchState.RALLY:
			var hitter = shuttlecock.last_hitter
			var current_x = shuttlecock.global_position.x
			if (hitter == "player" and current_x < NET_X) or (hitter == "ai" and current_x > NET_X):
				current_state = MatchState.POINT_OVER
				is_point_transition_active = true
				var winner = "ai" if hitter == "player" else "player"
				_award_point(winner, "LỖI LƯỚI! ĐIỂM CHO %s" % ("RIVAL AI" if winner == "ai" else "PLAYER"))
	)


func _award_point(winner: String, reason: String) -> void:
	if is_pvp_active and not is_pvp_host:
		return
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
			var champ = "BẠN" if sets_won_player > sets_won_ai else "ĐỐI THỦ"
			if not is_pvp_active:
				champ = "PLAYER" if sets_won_player > sets_won_ai else "RIVAL AI"
			if is_pvp_active and net_manager:
				net_manager.send_packet({
					"t": "score",
					"winner": winner,
					"reason": reason,
					"p1_pts": score_player,
					"p2_pts": score_ai,
					"p1_sets": sets_won_player,
					"p2_sets": sets_won_ai,
					"next_server": current_server,
					"cur_set": current_set_index,
					"s_p1": bwf_scoreboard.scores_p1 if bwf_scoreboard else [score_player, 0, 0],
					"s_p2": bwf_scoreboard.scores_p2 if bwf_scoreboard else [score_ai, 0, 0],
					"s_win": bwf_scoreboard.set_winners if bwf_scoreboard else [-1, -1, -1],
					"max_sets": total_match_sets
				})
				net_manager.send_packet({
					"t": "match_over",
					"winner": set_winner
				})
			_show_match_over_dialog(champ)
			return
			
		# Chuyển sang Set tiếp theo trong trận 3 Set
		var set_banner = "KẾT THÚC SET %d! [TỈ SỐ SET: %d - %d]" % [current_set_index + 1, sets_won_player, sets_won_ai]
		_show_banner(set_banner, Color(1.0, 0.90, 0.25), false)
		
		# Người thắng set trước có quyền giao cầu set sau
		current_server = set_winner
		if is_pvp_active and net_manager:
			net_manager.send_packet({
				"t": "score",
				"winner": winner,
				"reason": reason,
				"p1_pts": score_player,
				"p2_pts": score_ai,
				"p1_sets": sets_won_player,
				"p2_sets": sets_won_ai,
				"next_server": current_server,
				"cur_set": current_set_index,
				"s_p1": bwf_scoreboard.scores_p1 if bwf_scoreboard else [score_player, 0, 0],
				"s_p2": bwf_scoreboard.scores_p2 if bwf_scoreboard else [score_ai, 0, 0],
				"s_win": bwf_scoreboard.set_winners if bwf_scoreboard else [-1, -1, -1],
				"max_sets": total_match_sets
			})
			
		await get_tree().create_timer(2.2).timeout
		
		current_set_index += 1
		score_player = 0
		score_ai = 0
		if bwf_scoreboard:
			bwf_scoreboard.advance_to_next_set()
			bwf_scoreboard.update_current_score(0, 0)
			
		if bwf_scoreboard:
			bwf_scoreboard.set_server(current_server != "player")
		_setup_serve(current_server)
		return
	
	current_server = winner
	if is_pvp_active and net_manager:
		net_manager.send_packet({
			"t": "score",
			"winner": winner,
			"reason": reason,
			"p1_pts": score_player,
			"p2_pts": score_ai,
			"p1_sets": sets_won_player,
			"p2_sets": sets_won_ai,
			"next_server": current_server,
			"cur_set": current_set_index,
			"s_p1": bwf_scoreboard.scores_p1 if bwf_scoreboard else [score_player, 0, 0],
			"s_p2": bwf_scoreboard.scores_p2 if bwf_scoreboard else [score_ai, 0, 0],
			"s_win": bwf_scoreboard.set_winners if bwf_scoreboard else [-1, -1, -1],
			"max_sets": total_match_sets
		})
		
	if is_inside_tree() and get_tree():
		await get_tree().create_timer(1.2).timeout
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
		btn_again.focus_mode = Control.FOCUS_NONE
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
		btn_again.pressed.connect(func():
			btn_again.release_focus()
			_on_match_over_play_again()
		)
		btn_row.add_child(btn_again)
		
		var btn_menu = Button.new()
		btn_menu.focus_mode = Control.FOCUS_NONE
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
		btn_menu.pressed.connect(func():
			btn_menu.release_focus()
			_on_match_over_to_menu()
		)
		btn_row.add_child(btn_menu)
		
		$HUD.add_child(match_over_dialog)
		_strip_keyboard_focus(match_over_dialog)
	
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
	if virtual_touch_pad:
		virtual_touch_pad.visible = false


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
	if is_pvp_active and net_manager:
		net_manager.disconnect_peer()
		is_pvp_active = false
	_set_in_game_hud_visible(false)
	main_menu.switch_state(MainMenuController.MenuState.MATCH_SETUP)
	main_menu.visible = true
	_apply_menu_bgm()


var _last_window_size: Vector2 = Vector2.ZERO

func _update_floor_reflection() -> void:
	if OS.has_feature("web"):
		return
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
	if not label_banner:
		return
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
	
	var is_web = OS.has_feature("web")
	var use_aa = not is_web
		
	# 7. Ground Shockwave
	if shockwave_alpha > 0.01:
		var sw_col = Color(1.0, 0.95, 0.5, shockwave_alpha)
		effects_overlay.draw_arc(Vector2(shockwave_pos.x, FLOOR_Y), shockwave_radius, 0, TAU, 12 if is_web else (16 if low_graphics_mode else 36), sw_col, 3.5, use_aa)
		if not low_graphics_mode and not is_web:
			effects_overlay.draw_arc(Vector2(shockwave_pos.x, FLOOR_Y), shockwave_radius * 0.7, 0, TAU, 28, Color(1.0, 1.0, 1.0, shockwave_alpha * 0.7), 2.5, true)
		
	# 8. Golden Anime Perfect Impact Burst (Rực rỡ, lấp lánh và biến mất sau 0.4s)
	if perfect_burst_timer > 0.0:
		var p_prog = 1.0 - (perfect_burst_timer / 0.40)
		var burst_alpha = 1.0 - p_prog
		var r_outer = 25.0 + p_prog * 80.0
		var r_inner = 12.0 + p_prog * 40.0
		var col_burst = Color(perfect_burst_col.r, perfect_burst_col.g, perfect_burst_col.b, burst_alpha * 0.95)
		
		# Vòng hào quang sáng rực
		effects_overlay.draw_arc(perfect_burst_pos, r_outer, 0, TAU, 12 if is_web else (16 if low_graphics_mode else 36), col_burst, 3.0, use_aa)
		if not low_graphics_mode and not is_web:
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
		
		# Vệt bụi quét sàn dạt sang 2 bên chân
		var skid_len = 14.0 + prog * 48.0
		var dust_col = Color(0.95, 0.95, 1.0, alpha * 0.75)
		effects_overlay.draw_line(p_pos + Vector2(-8, -2), p_pos + Vector2(-skid_len, -2), dust_col, 2.0 * (1.0 - prog * 0.5), use_aa)
		effects_overlay.draw_line(p_pos + Vector2(8, -2), p_pos + Vector2(skid_len, -2), dust_col, 2.0 * (1.0 - prog * 0.5), use_aa)
		
		if not low_graphics_mode and not is_web:
			# Vòng nén sàn elip nở rộng sang 2 bên
			var rx = 16.0 + prog * 58.0
			var ry = 4.0 + prog * 9.0
			var ring_col = Color(1.0, 0.95, 0.75, alpha * 0.85)
			effects_overlay.draw_arc(p_pos, rx, 0, TAU, 24, ring_col, 2.5 * (1.0 - prog * 0.6), true)
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
		
		# Nhát chém xé gió chéo (Razor Wind Slash Path)
		var slash_len = 60.0 + p_prog * 95.0
		var slash_ang = (-0.42 if facing_dir > 0 else -PI + 0.42)
		var slash_vec = Vector2(cos(slash_ang), sin(slash_ang)) * slash_len
		var p_start = center - slash_vec * 0.45
		var p_end = center + slash_vec * 0.75
		effects_overlay.draw_line(p_start, p_end, Color(0.20, 1.8, 0.55, alpha * 0.55), 7.5, true)
		effects_overlay.draw_line(p_start, p_end, Color(0.85, 2.6, 1.4, alpha * 0.95), 2.8, true)
		
		# Chế độ đồ họa thấp: Bỏ qua bầy lá trúc và đa tầng lốc xoáy để tránh drop FPS
		if not low_graphics_mode:
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
	
	# 3. Player Flow Bar / Nộ Khí Tuyệt Kỹ (top=93.0, bottom=96.5)
	flow_bar_bg_player = ColorRect.new()
	flow_bar_bg_player.color = Color(0.08, 0.10, 0.14, 0.85)
	flow_bar_bg_player.offset_left = 425.0
	flow_bar_bg_player.offset_top = 93.0
	flow_bar_bg_player.offset_right = 565.0
	flow_bar_bg_player.offset_bottom = 96.5
	hud.add_child(flow_bar_bg_player)
	
	flow_bar_fill_player = ColorRect.new()
	flow_bar_fill_player.color = Color(0.78, 0.28, 0.95, 0.95)
	flow_bar_fill_player.position = Vector2.ZERO
	flow_bar_fill_player.size = Vector2(140.0, 3.5)
	flow_bar_bg_player.add_child(flow_bar_fill_player)
	
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
	
	# 3. AI Flow Bar / Nộ Khí Tuyệt Kỹ (top=93.0, bottom=96.5)
	flow_bar_bg_ai = ColorRect.new()
	flow_bar_bg_ai.color = Color(0.08, 0.10, 0.14, 0.85)
	flow_bar_bg_ai.offset_left = 715.0
	flow_bar_bg_ai.offset_top = 93.0
	flow_bar_bg_ai.offset_right = 855.0
	flow_bar_bg_ai.offset_bottom = 96.5
	hud.add_child(flow_bar_bg_ai)
	
	flow_bar_fill_ai = ColorRect.new()
	flow_bar_fill_ai.color = Color(0.78, 0.28, 0.95, 0.95)
	flow_bar_fill_ai.position = Vector2.ZERO
	flow_bar_fill_ai.size = Vector2(140.0, 3.5)
	flow_bar_bg_ai.add_child(flow_bar_fill_ai)


func _update_hud_stamina_bars() -> void:
	var time_val = Time.get_ticks_msec() / 1000.0
	var pulse = 0.65 + 0.35 * sin(time_val * 14.0)
	var flow_pulse = 0.75 + 0.25 * sin(time_val * 16.0)
	
	# Update Player Bars
	if player and player.stats:
		if stamina_bar_fill_player and stamina_bar_cap_player:
			var p_cap = clamp(player.stats.max_stamina_cap / 100.0, 0.0, 1.0)
			var p_val = clamp(player.stats.stamina / 100.0, 0.0, 1.0)
			stamina_bar_cap_player.size.x = 140.0 * p_cap
			stamina_bar_fill_player.size.x = 140.0 * p_val
			if player.stats.is_stamina_critical():
				stamina_bar_fill_player.color = Color(1.0, 0.18, 0.18, pulse)
			else:
				stamina_bar_fill_player.color = Color(0.2, 0.9, 0.45, 0.95)
				
		if accuracy_bar_fill_player:
			var p_acc = clamp(player.stats.accuracy / 100.0, 0.0, 1.0)
			accuracy_bar_fill_player.size.x = 140.0 * p_acc
			if player.stats.accuracy < 25.0:
				accuracy_bar_fill_player.color = Color(1.0, 0.25, 0.35, pulse)
			elif player.stats.accuracy < 50.0:
				accuracy_bar_fill_player.color = Color(1.0, 0.72, 0.20, 0.95)
			else:
				accuracy_bar_fill_player.color = Color(0.20, 0.88, 1.0, 0.95)
				
		if flow_bar_fill_player:
			var p_flow = clamp(player.stats.flow / 100.0, 0.0, 1.0)
			flow_bar_fill_player.size.x = 140.0 * p_flow
			if player.stats.can_use_special():
				flow_bar_fill_player.color = Color(1.0, 0.90, 0.25, flow_pulse)
			else:
				flow_bar_fill_player.color = Color(0.78, 0.28, 0.95, 0.95)
			
	# Update AI Rival Bars
	if ai_rival and ai_rival.stats:
		if stamina_bar_fill_ai and stamina_bar_cap_ai:
			var ai_cap = clamp(ai_rival.stats.max_stamina_cap / 100.0, 0.0, 1.0)
			var ai_val = clamp(ai_rival.stats.stamina / 100.0, 0.0, 1.0)
			stamina_bar_cap_ai.size.x = 140.0 * ai_cap
			stamina_bar_fill_ai.size.x = 140.0 * ai_val
			if ai_rival.stats.is_stamina_critical():
				stamina_bar_fill_ai.color = Color(1.0, 0.18, 0.18, pulse)
			else:
				stamina_bar_fill_ai.color = Color(0.2, 0.85, 1.0, 0.95)
				
		if accuracy_bar_fill_ai:
			var ai_acc = clamp(ai_rival.stats.accuracy / 100.0, 0.0, 1.0)
			accuracy_bar_fill_ai.size.x = 140.0 * ai_acc
			if ai_rival.stats.accuracy < 25.0:
				accuracy_bar_fill_ai.color = Color(1.0, 0.25, 0.35, pulse)
			elif ai_rival.stats.accuracy < 50.0:
				accuracy_bar_fill_ai.color = Color(1.0, 0.72, 0.20, 0.95)
			else:
				accuracy_bar_fill_ai.color = Color(0.20, 0.88, 1.0, 0.95)
				
		if flow_bar_fill_ai:
			var ai_flow = clamp(ai_rival.stats.flow / 100.0, 0.0, 1.0)
			flow_bar_fill_ai.size.x = 140.0 * ai_flow
			if ai_rival.stats.can_use_special():
				flow_bar_fill_ai.color = Color(1.0, 0.90, 0.25, flow_pulse)
			else:
				flow_bar_fill_ai.color = Color(0.78, 0.28, 0.95, 0.95)
