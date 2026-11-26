class_name MainMenuController
extends Control

# ==========================================================
# MAIN MENU & LOBBY CONTROLLER (THE SPIKE CROSS STYLE)
# Tinh tế, sang trọng, mang đậm phong cách sảnh thể thao console/mobile
# 100% Pre-rendered Studio PNG Icons, Liquid Glass Shaders, 60-120 FPS
# ==========================================================

const CustomIcon = preload("res://scripts/ui/custom_icon.gd")

# Full HD Screen Backgrounds (Title vs Lobby)
const TEX_LOBBY_BG = preload("res://assets/images/lobby_locker_room.png")
const TEX_TITLE_BG = preload("res://assets/images/menu_banner.png")
const TEX_KAISER_LOGO = preload("res://assets/ui/kaiser_logo.png")

var global_bg: TextureRect = null
var global_tint: ColorRect = null

# Studio Pre-rendered High-Quality Icons (0% Vector CPU lag, 100% Anti-Aliased)
const TEX_SHUTTLECOCK = preload("res://assets/icons/icon_shuttlecock_gold.png")
const TEX_PADLOCK = preload("res://assets/icons/icon_padlock_gold.png")
const TEX_COIN = preload("res://assets/icons/icon_coin_gold.png")
const TEX_AVATAR = preload("res://assets/icons/icon_avatar_pro.png")
const TEX_PVP = preload("res://assets/icons/icon_duel_pvp.png")
const TEX_VS_AI = preload("res://assets/icons/icon_vs_ai.png")
const TEX_TROPHY = preload("res://assets/icons/icon_trophy_gold.png")
const TEX_GEAR = preload("res://assets/icons/icon_gear_silver.png")

# Top Profile Avatar (Clean Default Studio Avatar)
var top_avatar_rect: TextureRect = null

# Studio Pre-rendered Character Standees (Full & Upper-body Cropped)
const TEX_STANDEE_NISHIKAWA = preload("res://assets/characters/standee_nishikawa.png")
const TEX_STANDEE_ISABEL = preload("res://assets/characters/standee_isabel.png")

# Studio Pre-rendered Character Skill Icons
const TEX_SKILL_THUNDER = preload("res://assets/icons/skills/skill_thunder_spike.png")
const TEX_SKILL_WIND = preload("res://assets/icons/skills/skill_wind_feather.png")
const TEX_SKILL_SHIELD = preload("res://assets/icons/skills/skill_iron_shield.png")
const TEX_SKILL_FIRE = preload("res://assets/icons/skills/skill_fire_blade.png")
const TEX_SKILL_VOID = preload("res://assets/icons/skills/skill_dark_void.png")
const TEX_SKILL_FROST = preload("res://assets/icons/skills/skill_frost_spike.png")

# Liquid Glass WebGL-inspired Shader
const SHADER_LIQUID_GLASS = preload("res://shaders/liquid_glass.gdshader")

signal start_match_requested(player_char: String, rival_char: String, difficulty: int, target_points: int, match_sets: int)
signal start_pvp_match_requested(room_code: String, is_host: bool, player_char: String, target_points: int, match_sets: int, first_server: String, opponent_char: String, player_name: String, opponent_name: String)
signal spectate_room_requested(room_code: String)
signal touch_toggle_requested(enabled: bool)

var _state_switch_cooldown_until: int = 0
var touch_controls_enabled: bool = false
var btn_touch_toggle_menu: Button = null
signal settings_updated(squeak: bool, bgm_enabled: bool, bgm_vol: float, low_gfx: bool)

enum MenuState {
	TITLE,          # Màn hình bắt đầu (Press any key / touch)
	LOBBY,          # Sảnh chính (The Spike Main Lobby)
	MATCH_SELECT,   # Màn hình chọn chế độ thi đấu (Dàn card nằm ngang)
	MATCH_SETUP,    # Cấu hình chi tiết trận đấu với AI
	PVP_LOBBY,      # Phòng chờ trực tuyến thời gian thực
	ROSTER,         # Quản lý cầu thủ (Locker room grid)
	SHOP,           # Cửa hàng (Locked)
	QUESTS,         # Nhiệm vụ hàng ngày (Locked)
	SETTINGS        # Cài đặt chuyên sâu
}

var current_state: MenuState = MenuState.TITLE

# Selected match parameters
var selected_player_id: String = "nishikawa"
var selected_rival_id: String = "wall"
var selected_difficulty: int = 1 # 0: Dễ, 1: Trung bình, 2: Khó
var selected_target_points: int = 11 # 11, 15, hoặc 21
var selected_match_sets: int = 1 # 1 hoặc 3 (Best of 3)

# PvP Parameters
var net_manager: PvPNetworkManager = null
var pvp_room_input: LineEdit
var pvp_host_code_lbl: Label
var pvp_status_lbl: Label
var pvp_ping_lbl: Label
var pvp_current_code: String = ""
var pvp_selected_char: String = "nishikawa"
var pvp_opponent_char: String = "wall"
var pvp_selected_points: int = 11
var pvp_selected_sets: int = 1
var pvp_first_server: String = "p1"
var pvp_is_host: bool = false
var pvp_is_connected: bool = false
var pvp_player_name: String = "BaoHodaka"
var pvp_opponent_name: String = "PLAYER 2"
var pvp_name_input: LineEdit
var btn_pvp_start: Button
var pvp_countdown_lbl: Label
var pvp_char_desc_lbl: Label
var pvp_countdown_timer: float = 0.0
var pvp_is_counting_down: bool = false
var pvp_char_btns: Dictionary = {}
var pvp_pts_btns: Dictionary = {}
var pvp_sets_btns: Dictionary = {}

# Settings parameters
var squeak_enabled: bool = true
var bgm_match_enabled: bool = true
var bgm_match_volume: float = 0.20
var low_graphics_mode: bool = false
var screen_shake_enabled: bool = true

# UI Panels
var title_panel: Control
var lobby_panel: Control
var match_select_panel: Control
var setup_panel: Control
var pvp_panel: Control
var roster_panel: Control
var shop_panel: Control
var quests_panel: Control
var settings_panel: Control

# Top Bar Widgets
var top_bar: Control
var top_name_input: LineEdit
var nav_tabs: Dictionary = {}

# Hero Standee Node
var hero_standee: Control
var _hero_standee_material: ShaderMaterial
var _standee_breath_timer: float = 0.0
var lbl_hero_name: Label
var lbl_hero_rarity: Label
var lbl_hero_passive: Label

# Mini Music Player & Vinyl Disc Widgets
var mini_player_panel: Control = null
var vinyl_disc_ctrl: VinylDiscControl = null
var mini_player_title_lbl: Label = null
var mini_player_artist_lbl: Label = null
var mini_player_btn_play: Button = null

class VinylDiscControl extends Control:
	var rotation_angle: float = 0.0
	var is_spinning: bool = false
	
	func _ready() -> void:
		custom_minimum_size = Vector2(48, 48)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	func _process(delta: float) -> void:
		if is_spinning:
			rotation_angle = wrapf(rotation_angle + delta * 2.8, 0.0, TAU)
			queue_redraw()
	
	func set_spinning(spinning: bool) -> void:
		is_spinning = spinning
		queue_redraw()
		
	func _draw() -> void:
		var center = size * 0.5
		var radius = min(size.x, size.y) * 0.46
		
		# Outer vinyl edge
		draw_circle(center, radius, Color(0.08, 0.08, 0.10, 1.0))
		draw_arc(center, radius, 0.0, TAU, 36, Color(0.24, 0.27, 0.32, 0.9), 1.2, true)
		
		# Micro-groove rings
		draw_arc(center, radius * 0.82, 0.0, TAU, 32, Color(0.18, 0.20, 0.25, 0.7), 1.0, true)
		draw_arc(center, radius * 0.68, 0.0, TAU, 32, Color(0.16, 0.18, 0.23, 0.7), 1.0, true)
		draw_arc(center, radius * 0.54, 0.0, TAU, 32, Color(0.20, 0.22, 0.27, 0.7), 1.0, true)
		
		# Center record label
		draw_circle(center, radius * 0.38, Color(1.0, 0.82, 0.25, 0.95))
		draw_arc(center, radius * 0.38, 0.0, TAU, 24, Color(0.85, 0.65, 0.15, 1.0), 1.0, true)
		
		# Spindle hole
		draw_circle(center, radius * 0.12, Color(0.04, 0.04, 0.05, 1.0))
		
		# Spinning sheen reflection lines
		var v1 = Vector2.from_angle(rotation_angle) * (radius * 0.90)
		var v2 = Vector2.from_angle(rotation_angle + PI) * (radius * 0.90)
		draw_line(center + v1 * 0.42, center + v1, Color(1.0, 1.0, 1.0, 0.22), 2.0, true)
		draw_line(center + v2 * 0.42, center + v2, Color(1.0, 1.0, 1.0, 0.22), 2.0, true)

# Setup UI nodes
var card_nodes: Dictionary = {}
var label_matchup_summary: Label
var btn_diff_easy: Button
var btn_diff_medium: Button
var btn_diff_hard: Button
var btn_pts_11: Button
var btn_pts_15: Button
var btn_pts_21: Button
var btn_sets_1: Button
var btn_sets_3: Button

const CHAR_DATA = {
	"nishikawa": {
		"name": "NISHIKAWA",
		"title": "Tia chớp vàng - Lôi Thần",
		"archetype": "TẤN CÔNG TOÀN DIỆN",
		"rarity": "S+",
		"stars": 5,
		"color": Color(1.0, 0.82, 0.22, 1.0),
		"icon_type": CustomIcon.IconType.LIGHTNING,
		"skill_icon": TEX_SKILL_THUNDER,
		"standee": TEX_STANDEE_NISHIKAWA,
		"power": 98,
		"agility": 78,
		"control": 74,
		"composure": 84,
		"skill_name": "Golden Smash",
		"skill_desc": "Đập sấm sét cắm sàn, ngưng đọng thời gian 1s, thế giới chuyển trắng đen!",
		"passive": "Trạng thái Phấn Khích: Khi đầy Nộ, cú SMASH được cưỡng ép 100% PERFECT, sấm sét ngưng đọng thời gian!"
	},
	"fuji": {
		"name": "FUJI",
		"title": "Cơn lốc xanh - Phong Thần Tuyệt Đỉnh",
		"archetype": "KỸ THUẬT TINH TẾ",
		"rarity": "S+",
		"stars": 5,
		"color": Color(0.25, 0.90, 0.60, 1.0),
		"icon_type": CustomIcon.IconType.FEATHER,
		"skill_icon": TEX_SKILL_WIND,
		"standee": null,
		"power": 82,
		"agility": 92,
		"control": 99,
		"composure": 90,
		"skill_name": "Tsubame Gaeshi",
		"skill_desc": "Cắt xoáy lốc xoáy lướt sát mép lưới, góc lượn gục hiểm hóc sát chân lưới! (Flow: 80)",
		"passive": "Phong Thần S+: Bỏ nhỏ hóa Én Lượn lướt sà mép lưới, tích Flow cực nhanh chỉ cần 80 điểm để tung chiêu!"
	},
	"wall": {
		"name": "ISABEL",
		"title": "Nữ hoàng đấu trường La Mã",
		"archetype": "PHÒNG THỦ KIÊN CỐ",
		"rarity": "S+",
		"stars": 5,
		"color": Color(0.30, 0.75, 1.0, 1.0),
		"icon_type": CustomIcon.IconType.SHIELD,
		"skill_icon": TEX_SKILL_SHIELD,
		"standee": TEX_STANDEE_ISABEL,
		"power": 74,
		"agility": 88,
		"control": 85,
		"composure": 96,
		"skill_name": "Mirage Shield",
		"skill_desc": "Hóa giải toàn bộ cú đập smash của đối thủ, bung cầu cao sâu và hồi ngay 20% thể lực! (Flow: 90)",
		"passive": "Khiên La Mã: Hóa giải hoàn toàn đòn smash khi đầy Nộ, bung sâu cuối sân & hồi ngay 20% thể lực!"
	},
	"gitae": {
		"name": "HAN GITAE",
		"title": "Bão lửa tiên phong - Hỏa Thần",
		"archetype": "ĐẤU SĨ BÙNG NỔ",
		"rarity": "S+",
		"stars": 5,
		"color": Color(1.0, 0.42, 0.15, 1.0),
		"icon_type": CustomIcon.IconType.FIRE_BLADE,
		"skill_icon": TEX_SKILL_FIRE,
		"standee": null,
		"power": 92,
		"agility": 82,
		"control": 78,
		"composure": 94,
		"skill_name": "Infernal Flame Realm",
		"skill_desc": "Trong 5s biến nửa sân thành Hỏa Ngục: Hitbox rộng hết nửa sân, cầu dính lửa thiêu đốt đối thủ (-25 Thể lực, -30 Thăng bằng, -25 Accuracy khi đánh trả)! (Flow: 100)",
		"passive": "Hỏa Thần Cuồng Nộ: Khi kích hoạt skill, bao sân 100% không lo trượt cầu. Quả cầu lửa thiêu đốt phá vỡ bộ pháp đối phương!"
	},
	"sara": {
		"name": "SARA",
		"title": "Băng giá toàn năng - Hàn Băng Nữ Hoàng",
		"archetype": "BIẾN ẢO HƯ KHÔNG",
		"rarity": "S+",
		"stars": 5,
		"color": Color(0.35, 0.85, 1.0, 1.0),
		"icon_type": CustomIcon.IconType.STAR,
		"skill_icon": TEX_SKILL_FROST,
		"standee": null,
		"power": 80,
		"agility": 96,
		"control": 92,
		"composure": 88,
		"skill_name": "Glacial Frost Domain",
		"skill_desc": "Trong 10s đóng băng sàn đối phương (chậm 20% tốc độ). Phím Space/Jump hóa thành Dịch chuyển tức thời tới đón cầu trên không hoặc mặt đất! (Flow: 105)",
		"passive": "Hư Không Tốc Biến: Teleport thẳng tới vị trí đón cầu thuận lợi nhất, đóng băng kìm hãm bước chạy đối thủ!"
	}
}

func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	position = Vector2.ZERO
	
	low_graphics_mode = false
		
	pvp_player_name = _load_saved_player_name()
	
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			(function() {
				if (!window._kaiserPasteHandlerInstalled) {
					window._kaiserPasteHandlerInstalled = true;
					window.addEventListener('paste', function(e) {
						var clipData = e.clipboardData || window.clipboardData;
						if (clipData) {
							var txt = clipData.getData('text');
							if (txt && txt.trim()) {
								window._kaiserRoomCode = txt.trim().toUpperCase();
								window._kaiserCodeUpdated = true;
							}
						}
					});
				}
			})()
		""")
	
	_build_ui()
	var am = _get_audio()
	if am:
		am.ensure_music_playing()
	switch_state(MenuState.TITLE)

func _process(delta: float) -> void:
	# Web Mobile text sync & Paste detection
	if OS.has_feature("web"):
		var code_updated = JavaScriptBridge.eval("window._kaiserCodeUpdated === true")
		if code_updated:
			var code = str(JavaScriptBridge.eval("window._kaiserRoomCode || ''")).strip_edges().to_upper()
			JavaScriptBridge.eval("window._kaiserCodeUpdated = false")
			if pvp_room_input:
				pvp_room_input.text = code
		var name_updated = JavaScriptBridge.eval("window._kaiserNameUpdated === true")
		if name_updated:
			var new_n = str(JavaScriptBridge.eval("window._kaiserPlayerName || ''")).strip_edges()
			JavaScriptBridge.eval("window._kaiserNameUpdated = false")
			if not new_n.is_empty():
				pvp_player_name = new_n
				_save_player_name(pvp_player_name)
				if top_name_input:
					top_name_input.text = pvp_player_name
				if pvp_name_input:
					pvp_name_input.text = pvp_player_name
				
	# Standee GPU vertex breathing animation update (100% smooth 120 FPS continuous float)
	if lobby_panel and lobby_panel.visible:
		_standee_breath_timer += delta
		if _hero_standee_material:
			_hero_standee_material.set_shader_parameter("breath_time", _standee_breath_timer)
				
	# PVP Host start button dynamic verification & synchronization
	if pvp_panel and pvp_panel.visible:
		if pvp_is_host and pvp_is_connected and not pvp_is_counting_down:
			if btn_pvp_start and btn_pvp_start.disabled:
				btn_pvp_start.disabled = false
		elif not pvp_is_counting_down and (not pvp_is_host or not pvp_is_connected):
			if btn_pvp_start and not btn_pvp_start.disabled:
				btn_pvp_start.disabled = true

	if pvp_is_counting_down:
		pvp_countdown_timer -= delta
		if pvp_countdown_timer > 0.0:
			var sec = int(ceil(pvp_countdown_timer))
			if pvp_countdown_lbl:
				pvp_countdown_lbl.text = "TRẬN ĐẤU BẮT ĐẦU TRONG: %d..." % sec
		else:
			pvp_is_counting_down = false
			if pvp_countdown_lbl:
				pvp_countdown_lbl.text = "VÀO SÂN!"
			start_pvp_match_requested.emit(pvp_current_code, pvp_is_host, pvp_selected_char, pvp_selected_points, pvp_selected_sets, pvp_first_server, pvp_opponent_char, pvp_player_name, pvp_opponent_name)
			visible = false

func switch_state(new_state: MenuState) -> void:
	_state_switch_cooldown_until = Time.get_ticks_msec() + 350
	current_state = new_state
	if global_bg:
		if new_state == MenuState.TITLE:
			global_bg.texture = TEX_TITLE_BG
		else:
			global_bg.texture = TEX_LOBBY_BG
	
	if global_tint:
		# Màn hình Title và Sảnh chờ chính giữ 100% độ sáng, sắc nét nguyên bản, không bị phủ màng mờ
		global_tint.visible = (new_state in [MenuState.ROSTER, MenuState.SHOP, MenuState.SETTINGS, MenuState.QUESTS, MenuState.MATCH_SETUP, MenuState.PVP_LOBBY])
	
	# Visibility map
	if title_panel: title_panel.visible = (new_state == MenuState.TITLE)
	if lobby_panel: lobby_panel.visible = (new_state == MenuState.LOBBY)
	if match_select_panel: match_select_panel.visible = (new_state == MenuState.MATCH_SELECT)
	if setup_panel: 
		setup_panel.visible = (new_state == MenuState.MATCH_SETUP)
		if setup_panel.visible:
			_update_setup_cards()
			_update_difficulty_buttons()
			_update_points_buttons()
			_update_sets_buttons()
	if pvp_panel:
		pvp_panel.visible = (new_state == MenuState.PVP_LOBBY)
		if pvp_panel.visible:
			_update_pvp_controls()
	if roster_panel: 
		roster_panel.visible = (new_state == MenuState.ROSTER)
		if roster_panel.visible:
			_update_roster_view()
	if shop_panel: shop_panel.visible = (new_state == MenuState.SHOP)
	if quests_panel: quests_panel.visible = (new_state == MenuState.QUESTS)
	if settings_panel: settings_panel.visible = (new_state == MenuState.SETTINGS)
	
	# Top bar visibility (Always on top on all states except TITLE)
	if top_bar:
		top_bar.visible = (new_state != MenuState.TITLE)
		if top_bar.visible:
			top_bar.move_to_front()
		_update_nav_tab_indicators()
		
	# Refresh Hero Standee when entering lobby
	if new_state == MenuState.LOBBY:
		_update_hero_standee()

func _update_nav_tab_indicators() -> void:
	for tab_id in nav_tabs.keys():
		var btn = nav_tabs[tab_id] as Button
		if not btn: continue
		var is_active = false
		match tab_id:
			"lobby": is_active = (current_state == MenuState.LOBBY or current_state == MenuState.MATCH_SELECT)
			"shop": is_active = (current_state == MenuState.SHOP)
			"quests": is_active = (current_state == MenuState.QUESTS)
			"roster": is_active = (current_state == MenuState.ROSTER)
			"settings": is_active = (current_state == MenuState.SETTINGS)
		
		btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35) if is_active else Color(0.80, 0.86, 0.94))
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_active else Color(0.85, 0.90, 0.96, 0.85)

func _create_tex_icon(texture: Texture2D, target_size: Vector2) -> TextureRect:
	var tr = TextureRect.new()
	tr.texture = texture
	tr.custom_minimum_size = target_size
	tr.size = target_size
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr

func _create_spike_translucent_panel(box_size: Vector2, corner_r: int = 12, border_col: Color = Color(0.35, 0.50, 0.70, 0.50)) -> PanelContainer:
	var pc = PanelContainer.new()
	pc.custom_minimum_size = box_size
	pc.size = box_size
	
	var sb = StyleBoxFlat.new()
	# Nền bán trong suốt chuẩn The Spike: Nhìn xuyên thấu mờ ảo bối cảnh sân đấu phía sau
	sb.bg_color = Color(0.07, 0.10, 0.15, 0.65)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = border_col
	sb.corner_radius_top_left = corner_r
	sb.corner_radius_top_right = corner_r
	sb.corner_radius_bottom_right = corner_r
	sb.corner_radius_bottom_left = corner_r
	sb.shadow_size = 0 # Hoàn toàn không bị xén bóng đổ
	pc.add_theme_stylebox_override("panel", sb)
	return pc

func _build_ui() -> void:
	# ----------------------------------------------------
	# GLOBAL BACKGROUND (Sân đấu & Phòng thay đồ thể thao cao cấp)
	# ----------------------------------------------------
	global_bg = TextureRect.new()
	global_bg.texture = TEX_LOBBY_BG
	global_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	global_bg.anchor_left = 0.0
	global_bg.anchor_top = 0.0
	global_bg.anchor_right = 1.0
	global_bg.anchor_bottom = 1.0
	global_bg.offset_left = 0.0
	global_bg.offset_top = 0.0
	global_bg.offset_right = 0.0
	global_bg.offset_bottom = 0.0
	global_bg.custom_minimum_size = Vector2(1280, 720)
	global_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	global_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	global_bg.texture_filter = Control.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	global_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(global_bg)
	
	# Light Vignette để làm nổi bật bối cảnh sân đấu phía sau (The Spike Translucent Style)
	global_tint = ColorRect.new()
	global_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	global_tint.anchor_left = 0.0
	global_tint.anchor_top = 0.0
	global_tint.anchor_right = 1.0
	global_tint.anchor_bottom = 1.0
	global_tint.offset_left = 0.0
	global_tint.offset_top = 0.0
	global_tint.offset_right = 0.0
	global_tint.offset_bottom = 0.0
	global_tint.custom_minimum_size = Vector2(1280, 720)
	global_tint.color = Color(0.02, 0.05, 0.10, 0.25)
	global_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	global_tint.visible = false
	add_child(global_tint)
	
	# ----------------------------------------------------
	# 1. TITLE SCREEN (Press Any Key to Start)
	# ----------------------------------------------------
	_build_title_panel()
	
	# ----------------------------------------------------
	# 2. MAIN LOBBY SCREEN (Hero Standee + Widgets + CTA)
	# ----------------------------------------------------
	_build_lobby_panel()
	
	# ----------------------------------------------------
	# 3. MATCH SELECTION PANEL (The Spike Horizontal Cards)
	# ----------------------------------------------------
	_build_match_select_panel()
	
	# ----------------------------------------------------
	# 4. MATCH SETUP PANEL (AI Rival configuration)
	# ----------------------------------------------------
	_build_match_setup_panel()
	
	# ----------------------------------------------------
	# 5. PVP LOBBY PANEL
	# ----------------------------------------------------
	_build_pvp_panel()
	
	# ----------------------------------------------------
	# 6. ROSTER PANEL (Quản lý cầu thủ)
	# ----------------------------------------------------
	_build_roster_panel()
	
	# ----------------------------------------------------
	# 7. SHOP & QUESTS PANELS (Locked Features)
	# ----------------------------------------------------
	_build_shop_panel()
	_build_quests_panel()
	
	# ----------------------------------------------------
	# 8. SETTINGS PANEL (The Spike Stepped Bars)
	# ----------------------------------------------------
	_build_settings_panel()

	# ----------------------------------------------------
	# 9. TOP BAR (ALWAYS AT TOP OF Z-ORDER)
	# ----------------------------------------------------
	_build_top_bar()
	top_bar.move_to_front()

func _open_room_input_modal() -> void:
	if OS.has_feature("web"):
		var cur_code = pvp_room_input.text.strip_edges() if pvp_room_input else ""
		var res = JavaScriptBridge.eval("window.prompt('NHẬP MÃ PHÒNG PVP (4-6 KÝ TỰ):', '%s')" % cur_code)
		if res != null and str(res) != "null":
			var clean = str(res).strip_edges().to_upper()
			if not clean.is_empty():
				if pvp_room_input:
					pvp_room_input.text = clean.substr(0, 8)
				pvp_current_code = clean.substr(0, 8)
				JavaScriptBridge.eval("window._kaiserRoomCode = '%s'" % pvp_current_code)
	elif pvp_room_input:
		DisplayServer.virtual_keyboard_show(pvp_room_input.text)

func _open_name_input_modal() -> void:
	if OS.has_feature("web"):
		var res = JavaScriptBridge.eval("window.prompt('NHẬP TÊN NGƯỜI CHƠI (Tối đa 16 ký tự):', '%s')" % pvp_player_name)
		if res != null and str(res) != "null":
			var clean = str(res).strip_edges()
			if not clean.is_empty():
				pvp_player_name = clean.substr(0, 16)
				_save_player_name(pvp_player_name)
				if top_name_input:
					top_name_input.text = pvp_player_name
				if pvp_name_input:
					pvp_name_input.text = pvp_player_name
				JavaScriptBridge.eval("window._kaiserPlayerName = '%s'" % pvp_player_name)
	elif top_name_input:
		DisplayServer.virtual_keyboard_show(top_name_input.text)

func _paste_room_code() -> void:
	if OS.has_feature("web"):
		var clip = str(JavaScriptBridge.eval("""
			(function() {
				var res = window.prompt('DÁN HOẶC NHẬP MÃ PHÒNG (4-6 KÝ TỰ):', '');
				return res || '';
			})()
		""")).strip_edges().to_upper()
		if not clip.is_empty() and clip != "NULL":
			if pvp_room_input:
				pvp_room_input.text = clip.substr(0, 8)
			pvp_current_code = clip.substr(0, 8)
			JavaScriptBridge.eval("window._kaiserRoomCode = '%s'" % pvp_current_code)
			return
	var clip_sys = DisplayServer.clipboard_get().strip_edges().to_upper()
	if not clip_sys.is_empty() and pvp_room_input:
		pvp_room_input.text = clip_sys.substr(0, 8)
		pvp_current_code = clip_sys.substr(0, 8)

# ==========================================================
# 1. TOP BAR COMPONENT (Z-INDEX 100, CLICK-THROUGH PROOF)
# ==========================================================
func _build_top_bar() -> void:
	top_bar = Control.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.anchor_left = 0.0
	top_bar.anchor_right = 1.0
	top_bar.offset_left = 0.0
	top_bar.offset_top = 0.0
	top_bar.offset_right = 0.0
	top_bar.offset_bottom = 68.0
	top_bar.custom_minimum_size = Vector2(1280, 68)
	top_bar.position = Vector2.ZERO
	top_bar.z_index = 100
	top_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	top_bar.visible = false
	add_child(top_bar)
	
	# Liquid Glass Top Bar Background
	var bar_bg = ColorRect.new()
	bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_bg.anchor_right = 1.0
	bar_bg.anchor_bottom = 1.0
	bar_bg.offset_left = 0.0
	bar_bg.offset_top = 0.0
	bar_bg.offset_right = 0.0
	bar_bg.offset_bottom = 0.0
	bar_bg.color = Color(0.08, 0.11, 0.16, 0.90)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	top_bar.add_child(bar_bg)
	
	var h_line = ColorRect.new()
	h_line.anchor_left = 0.0
	h_line.anchor_right = 1.0
	h_line.offset_left = 0.0
	h_line.offset_right = 0.0
	h_line.offset_top = 66.5
	h_line.offset_bottom = 68.0
	h_line.color = Color(0.30, 0.45, 0.70, 0.60)
	h_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(h_line)
	
	var m = MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.anchor_right = 1.0
	m.anchor_bottom = 1.0
	m.offset_left = 0.0
	m.offset_top = 0.0
	m.offset_right = 0.0
	m.offset_bottom = 0.0
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	top_bar.add_child(m)
	
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	m.add_child(row)
	
	# Left: Player Profile Pill with Real Studio Avatar & Direct Text Input
	var prof_box = HBoxContainer.new()
	prof_box.add_theme_constant_override("separation", 10)
	prof_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prof_box.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Clean Default Avatar (Simple, sleek, unclickable)
	top_avatar_rect = TextureRect.new()
	top_avatar_rect.texture = TEX_AVATAR
	top_avatar_rect.custom_minimum_size = Vector2(38, 38)
	top_avatar_rect.size = Vector2(38, 38)
	top_avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top_avatar_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prof_box.add_child(top_avatar_rect)
	
	var name_col = VBoxContainer.new()
	name_col.alignment = BoxContainer.ALIGNMENT_CENTER
	name_col.add_theme_constant_override("separation", 2)
	name_col.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Direct Real Name Input Field (Nhập tên thật dễ dàng, không bị đơ)
	top_name_input = LineEdit.new()
	top_name_input.text = pvp_player_name
	top_name_input.custom_minimum_size = Vector2(140, 28)
	top_name_input.max_length = 16
	top_name_input.placeholder_text = "Nhập tên..."
	top_name_input.mouse_filter = Control.MOUSE_FILTER_STOP
	top_name_input.focus_mode = Control.FOCUS_ALL
	
	var sb_inp = StyleBoxFlat.new()
	sb_inp.bg_color = Color(0.12, 0.16, 0.24, 0.85)
	sb_inp.border_width_left = 1
	sb_inp.border_width_top = 1
	sb_inp.border_width_right = 1
	sb_inp.border_width_bottom = 1
	sb_inp.border_color = Color(1.0, 0.85, 0.35, 0.5)
	sb_inp.corner_radius_top_left = 4
	sb_inp.corner_radius_top_right = 4
	sb_inp.corner_radius_bottom_right = 4
	sb_inp.corner_radius_bottom_left = 4
	top_name_input.add_theme_stylebox_override("normal", sb_inp)
	top_name_input.add_theme_stylebox_override("focus", sb_inp)
	top_name_input.add_theme_font_size_override("font_size", 13)
	top_name_input.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.is_pressed():
			top_name_input.grab_focus()
			_open_name_input_modal()
	)
	top_name_input.focus_entered.connect(func():
		_open_name_input_modal()
	)
	top_name_input.text_changed.connect(func(new_text: String):
		var clean = new_text.strip_edges()
		pvp_player_name = clean if not clean.is_empty() else "BaoHodaka"
		_save_player_name(pvp_player_name)
		if pvp_name_input and pvp_name_input != top_name_input:
			pvp_name_input.text = pvp_player_name
	)
	name_col.add_child(top_name_input)
	
	prof_box.add_child(name_col)
	row.add_child(prof_box)
	
	# Currencies: Gold Coin & Locked Next Feature ("chưa có cứ ổ khóa thôi")
	row.add_child(VSeparator.new())
	
	# 1. Real Gold Coin Pill
	row.add_child(_create_currency_pill_tex(TEX_COIN, "0", Color(1.0, 0.82, 0.25)))
	
	# 2. Next Locked Feature Pill (Ổ khóa hoàng kim 3D)
	var lock_pill = PanelContainer.new()
	lock_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb_lp = StyleBoxFlat.new()
	sb_lp.bg_color = Color(0.10, 0.13, 0.18, 0.85)
	sb_lp.corner_radius_top_left = 14
	sb_lp.corner_radius_top_right = 14
	sb_lp.corner_radius_bottom_right = 14
	sb_lp.corner_radius_bottom_left = 14
	sb_lp.border_width_left = 1
	sb_lp.border_width_top = 1
	sb_lp.border_width_right = 1
	sb_lp.border_width_bottom = 1
	sb_lp.border_color = Color(0.35, 0.40, 0.50, 0.5)
	lock_pill.add_theme_stylebox_override("panel", sb_lp)
	
	var lpm = MarginContainer.new()
	lpm.add_theme_constant_override("margin_left", 8)
	lpm.add_theme_constant_override("margin_right", 10)
	lpm.add_theme_constant_override("margin_top", 4)
	lpm.add_theme_constant_override("margin_bottom", 4)
	lock_pill.add_child(lpm)
	
	var lph = HBoxContainer.new()
	lph.add_theme_constant_override("separation", 6)
	lpm.add_child(lph)
	lph.add_child(_create_tex_icon(TEX_PADLOCK, Vector2(18, 18)))
	var lp_lbl = Label.new()
	lp_lbl.text = "MỞ RỘNG CẤP 10"
	lp_lbl.add_theme_font_size_override("font_size", 11)
	lp_lbl.modulate = Color(0.70, 0.76, 0.85)
	lph.add_child(lp_lbl)
	row.add_child(lock_pill)
	
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(sp)
	
	# Top Navigation Tabs (Click-Through Guaranteed)
	var tabs_row = HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 6)
	tabs_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tabs_row.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var btn_home = _create_nav_tab("Trang Chủ", "lobby", func(): switch_state(MenuState.LOBBY))
	var btn_shop = _create_nav_tab("Cửa Hàng", "shop", func(): switch_state(MenuState.SHOP))
	var btn_quests = _create_nav_tab("Nhiệm Vụ", "quests", func(): switch_state(MenuState.QUESTS))
	var btn_roster = _create_nav_tab("Cầu Thủ", "roster", func(): switch_state(MenuState.ROSTER))
	var btn_settings = _create_nav_tab("Cài Đặt", "settings", func(): switch_state(MenuState.SETTINGS))
	
	tabs_row.add_child(btn_home)
	tabs_row.add_child(btn_shop)
	tabs_row.add_child(btn_quests)
	tabs_row.add_child(btn_roster)
	tabs_row.add_child(btn_settings)
	row.add_child(tabs_row)

func _create_currency_pill_tex(tex: Texture2D, amount_str: String, col: Color) -> PanelContainer:
	var p = PanelContainer.new()
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.15, 0.20, 0.85)
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left = 14
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(col.r, col.g, col.b, 0.45)
	p.add_theme_stylebox_override("panel", sb)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 8)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 4)
	m.add_theme_constant_override("margin_bottom", 4)
	p.add_child(m)
	
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	m.add_child(h)
	
	var icon = _create_tex_icon(tex, Vector2(22, 22))
	h.add_child(icon)
	
	var lbl = Label.new()
	lbl.text = amount_str
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.modulate = Color(0.96, 0.96, 0.96)
	h.add_child(lbl)
	
	var add_lbl = Label.new()
	add_lbl.text = "+"
	add_lbl.add_theme_font_size_override("font_size", 12)
	add_lbl.modulate = Color(col.r, col.g, col.b, 0.8)
	h.add_child(add_lbl)
	
	return p

func _create_nav_tab(title: String, tab_id: String, on_click: Callable) -> Button:
	var b = Button.new()
	b.text = title
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.custom_minimum_size = Vector2(88, 34)
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98))
	
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.12, 0.15, 0.20, 0.40)
	sb_normal.corner_radius_top_left = 6
	sb_normal.corner_radius_top_right = 6
	sb_normal.corner_radius_bottom_right = 6
	sb_normal.corner_radius_bottom_left = 6
	sb_normal.border_width_left = 1
	sb_normal.border_width_top = 1
	sb_normal.border_width_right = 1
	sb_normal.border_width_bottom = 1
	sb_normal.border_color = Color(0.30, 0.45, 0.65, 0.35)
	b.add_theme_stylebox_override("normal", sb_normal)
	
	var sb_hover = sb_normal.duplicate()
	sb_hover.bg_color = Color(0.20, 0.32, 0.48, 0.75)
	sb_hover.border_color = Color(0.45, 0.75, 1.0, 0.8)
	b.add_theme_stylebox_override("hover", sb_hover)
	b.add_theme_stylebox_override("focus", sb_hover)
	
	b.pressed.connect(on_click)
	nav_tabs[tab_id] = b
	return b

# ==========================================================
# 2. TITLE PANEL (HIGH QUALITY 3D SHUTTLECOCK ICON)
# ==========================================================
func _build_title_panel() -> void:
	title_panel = Control.new()
	title_panel.anchor_left = 0.0
	title_panel.anchor_top = 0.0
	title_panel.anchor_right = 1.0
	title_panel.anchor_bottom = 1.0
	title_panel.offset_left = 0.0
	title_panel.offset_top = 0.0
	title_panel.offset_right = 0.0
	title_panel.offset_bottom = 0.0
	title_panel.custom_minimum_size = Vector2(1280, 720)
	title_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(title_panel)
	
	# Nút bấm vào sảnh ở phía dưới màn hình (Logo game đã tích hợp trực tiếp trên artwork nền mới)
	var bottom_box = VBoxContainer.new()
	bottom_box.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_box.anchor_left = 0.5
	bottom_box.anchor_top = 1.0
	bottom_box.anchor_right = 0.5
	bottom_box.anchor_bottom = 1.0
	bottom_box.offset_left = -260.0
	bottom_box.offset_top = -105.0
	bottom_box.offset_right = 260.0
	bottom_box.offset_bottom = -45.0
	bottom_box.mouse_filter = Control.MOUSE_FILTER_PASS
	title_panel.add_child(bottom_box)
	
	var btn_start_any = _create_clean_button("CHẠM HOẶC CLICK ĐỂ VÀO GAME", Color(1.0, 0.85, 0.25), Vector2(460, 50), 14)
	btn_start_any.pressed.connect(func():
		_trigger_title_enter_game()
	)
	var b_row = HBoxContainer.new()
	b_row.alignment = BoxContainer.ALIGNMENT_CENTER
	b_row.add_child(btn_start_any)
	bottom_box.add_child(b_row)

var _is_title_transitioning: bool = false
var flash_overlay: ColorRect = null

func _trigger_title_enter_game() -> void:
	if _is_title_transitioning:
		return
	if Time.get_ticks_msec() < _state_switch_cooldown_until:
		return
	_is_title_transitioning = true
	
	# Mở khóa âm thanh tức thì
	var am = _get_audio()
	if am:
		am.ensure_music_playing()
		
	# Tạo hoặc tái sử dụng lớp phủ Flash trắng toàn màn hình
	if not flash_overlay:
		flash_overlay = ColorRect.new()
		flash_overlay.color = Color(1.0, 1.0, 1.0, 1.0)
		flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flash_overlay.z_index = 300
		flash_overlay.modulate.a = 0.0
		add_child(flash_overlay)
	
	flash_overlay.visible = true
	flash_overlay.modulate.a = 0.0
	
	# Hiệu ứng nháy flash trắng tầm 2s kèm theo fade-in / fade-out mượt mà vào lobby
	var tw = create_tween()
	# 1. Chớp lóe flash sáng cực nhanh (0.35s lên 100% trắng xóa)
	tw.tween_property(flash_overlay, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# 2. Giữ màn hình trắng sáng trong 0.25s
	tw.tween_interval(0.25)
	# 3. Khi màn hình đang trắng xóa, chuyển cảnh sang LOBBY
	tw.tween_callback(func():
		switch_state(MenuState.LOBBY)
	)
	# 4. Fade-out dịu dần từ trắng về 0.0 trong 1.40s để lộ sảnh chờ BWF (Tổng thời gian ~2.0s)
	tw.tween_property(flash_overlay, "modulate:a", 0.0, 1.40).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		flash_overlay.visible = false
		_is_title_transitioning = false
	)

func _unhandled_input(event: InputEvent) -> void:
	if current_state == MenuState.TITLE and visible:
		# CHỈ cho phép chạm màn hình (Mobile tap) hoặc click chuột trái (PC click), KHÔNG cho phép bấm phím bừa bãi
		if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
			_trigger_title_enter_game()
			get_viewport().set_input_as_handled()

# ==========================================================
# 3. MAIN LOBBY SCREEN (Hero Standee, Widgets, Primary CTA)
# ==========================================================
func _build_lobby_panel() -> void:
	lobby_panel = Control.new()
	lobby_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	lobby_panel.anchor_left = 0.0
	lobby_panel.anchor_top = 0.0
	lobby_panel.anchor_right = 1.0
	lobby_panel.anchor_bottom = 1.0
	lobby_panel.offset_left = 0.0
	lobby_panel.offset_top = 0.0
	lobby_panel.offset_right = 0.0
	lobby_panel.offset_bottom = 0.0
	lobby_panel.custom_minimum_size = Vector2(1280, 720)
	lobby_panel.position = Vector2.ZERO
	lobby_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lobby_panel.visible = false
	add_child(lobby_panel)
	
	# Center Hero Stage (Full-body Standee Nhân Vật ở Màn Hình Chính)
	hero_standee = Control.new()
	hero_standee.custom_minimum_size = Vector2(440, 580)
	hero_standee.size = Vector2(440, 580)
	hero_standee.position = Vector2(420, 95)
	hero_standee.mouse_filter = Control.MOUSE_FILTER_PASS
	lobby_panel.add_child(hero_standee)
	
	# Full Standee Texture (100% Full-body, không thanh đứng/hộp đế, lọc mượt mipmaps)
	var hero_full_standee = TextureRect.new()
	hero_full_standee.name = "HeroFullStandee"
	hero_full_standee.texture = CHAR_DATA["nishikawa"]["standee"]
	hero_full_standee.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_full_standee.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_full_standee.custom_minimum_size = Vector2(440, 560)
	hero_full_standee.size = Vector2(440, 560)
	hero_full_standee.position = Vector2.ZERO
	hero_full_standee.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	hero_full_standee.mouse_filter = Control.MOUSE_FILTER_PASS
	hero_full_standee.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			switch_state(MenuState.ROSTER)
	)
	
	# GPU Vertex Breathing Shader: Chân bám vững trên sàn (0% trôi), ngực thở phập phồng mượt mà 120 FPS
	var breath_shader = Shader.new()
	breath_shader.code = """
shader_type canvas_item;

uniform float breath_time = 0.0;

void vertex() {
	float cycle = sin(breath_time * 2.2);
	// Chân cố định vững chắc (UV.y = 1.0 -> factor = 0.0), ngực và vai nhấp nhô mềm mại
	float factor = pow(1.0 - clamp(UV.y, 0.0, 1.0), 1.25);
	VERTEX.y -= cycle * 6.5 * factor;
	VERTEX.x += (UV.x - 0.5) * cycle * 7.5 * factor;
}
"""
	_hero_standee_material = ShaderMaterial.new()
	_hero_standee_material.shader = breath_shader
	hero_full_standee.material = _hero_standee_material
	hero_standee.add_child(hero_full_standee)
	
	# Fallback display for characters without full standee
	var fallback_box = CenterContainer.new()
	fallback_box.name = "HeroFallbackBox"
	fallback_box.custom_minimum_size = Vector2(440, 560)
	fallback_box.size = Vector2(440, 560)
	fallback_box.visible = false
	fallback_box.mouse_filter = Control.MOUSE_FILTER_PASS
	hero_standee.add_child(fallback_box)
	
	var fallback_card = _create_spike_translucent_panel(Vector2(260, 320), 14, Color(0.25, 0.90, 0.60, 0.70))
	fallback_box.add_child(fallback_card)
	
	var fb_m = MarginContainer.new()
	fb_m.add_theme_constant_override("margin_left", 16)
	fb_m.add_theme_constant_override("margin_top", 16)
	fb_m.add_theme_constant_override("margin_right", 16)
	fb_m.add_theme_constant_override("margin_bottom", 16)
	fallback_card.add_child(fb_m)
	
	var fb_v = VBoxContainer.new()
	fb_v.alignment = BoxContainer.ALIGNMENT_CENTER
	fb_v.add_theme_constant_override("separation", 12)
	fb_m.add_child(fb_v)
	
	var hero_big_icon = _create_tex_icon(TEX_SKILL_WIND, Vector2(96, 96))
	hero_big_icon.name = "HeroBigIcon"
	fb_v.add_child(hero_big_icon)
	
	# Character Tag & Change Button (Floating beside Standee)
	var hero_badge = _create_spike_translucent_panel(Vector2(190, 84), 10, Color(1.0, 0.82, 0.25, 0.60))
	hero_badge.name = "HeroBadge"
	hero_badge.position = Vector2(320, 110)
	hero_badge.mouse_filter = Control.MOUSE_FILTER_PASS
	lobby_panel.add_child(hero_badge)
	
	var bm = MarginContainer.new()
	bm.add_theme_constant_override("margin_left", 12)
	bm.add_theme_constant_override("margin_top", 8)
	bm.add_theme_constant_override("margin_right", 12)
	bm.add_theme_constant_override("margin_bottom", 8)
	bm.mouse_filter = Control.MOUSE_FILTER_PASS
	hero_badge.add_child(bm)
	
	var bv = VBoxContainer.new()
	bv.add_theme_constant_override("separation", 4)
	bv.alignment = BoxContainer.ALIGNMENT_CENTER
	bv.mouse_filter = Control.MOUSE_FILTER_PASS
	bm.add_child(bv)
	
	var badge_row = HBoxContainer.new()
	badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_row.add_theme_constant_override("separation", 8)
	
	lbl_hero_rarity = Label.new()
	lbl_hero_rarity.text = "S+"
	lbl_hero_rarity.add_theme_font_size_override("font_size", 18)
	lbl_hero_rarity.modulate = Color(1.0, 0.82, 0.25)
	badge_row.add_child(lbl_hero_rarity)
	
	lbl_hero_name = Label.new()
	lbl_hero_name.text = "NISHIKAWA"
	lbl_hero_name.add_theme_font_size_override("font_size", 16)
	lbl_hero_name.modulate = Color.WHITE
	badge_row.add_child(lbl_hero_name)
	bv.add_child(badge_row)
	
	var btn_change_hero = _create_clean_button("ĐỔI CẦU THỦ", Color(0.35, 0.75, 1.0), Vector2(160, 28), 11)
	btn_change_hero.pressed.connect(func(): switch_state(MenuState.ROSTER))
	bv.add_child(btn_change_hero)
	
	# Hero Passive banner under feet (Đẩy sát đáy màn hình theo yêu cầu)
	lbl_hero_passive = Label.new()
	lbl_hero_passive.text = CHAR_DATA["nishikawa"]["passive"]
	lbl_hero_passive.custom_minimum_size = Vector2(800, 24)
	lbl_hero_passive.position = Vector2(240, 694)
	lbl_hero_passive.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_hero_passive.add_theme_font_size_override("font_size", 11)
	lbl_hero_passive.modulate = Color(0.85, 0.90, 0.98, 0.85)
	lobby_panel.add_child(lbl_hero_passive)
	
	# Left Side Widgets (Banner Event & Điểm Danh - đặt tại y=105, hoàn toàn tách biệt khỏi thanh Top Bar y=68)
	var left_col = VBoxContainer.new()
	left_col.position = Vector2(30, 105)
	left_col.custom_minimum_size = Vector2(280, 500)
	left_col.add_theme_constant_override("separation", 12)
	left_col.mouse_filter = Control.MOUSE_FILTER_PASS
	lobby_panel.add_child(left_col)
	
	var ev_card = _create_widget_card("SỰ KIỆN: LÔI THẦN NISHIKAWA", "Thời gian còn lại: 14 ngày\nNhận ngay skin & danh hiệu BWF!", Color(1.0, 0.82, 0.25))
	left_col.add_child(ev_card)
	
	var daily_card = _create_widget_card("ĐIỂM DANH HÀNG NGÀY", "Chuỗi điểm danh: 6 ngày\nNhận 500 Vàng + Quà BWF!", Color(0.30, 0.92, 0.65))
	left_col.add_child(daily_card)
	
	# Mini Music Player with Rotating Vinyl Disc (Góc dưới bên trái sảnh chờ)
	mini_player_panel = _build_mini_player()
	lobby_panel.add_child(mini_player_panel)
	
	# Bottom Right Call to Action: [ CHIÊU MỘ ] & [ TRẬN ĐẤU ] (Dịch chuyển xuống dưới sát thanh đáy)
	var cta_box = VBoxContainer.new()
	cta_box.position = Vector2(920, 560)
	cta_box.custom_minimum_size = Vector2(330, 130)
	cta_box.add_theme_constant_override("separation", 8)
	cta_box.mouse_filter = Control.MOUSE_FILTER_PASS
	lobby_panel.add_child(cta_box)
	
	var mode_summary = PanelContainer.new()
	var sb_ms = StyleBoxFlat.new()
	sb_ms.bg_color = Color(0.10, 0.13, 0.18, 0.85)
	sb_ms.corner_radius_top_left = 6
	sb_ms.corner_radius_top_right = 6
	sb_ms.corner_radius_bottom_right = 6
	sb_ms.corner_radius_bottom_left = 6
	mode_summary.add_theme_stylebox_override("panel", sb_ms)
	var ms_lbl = Label.new()
	ms_lbl.text = "  Cốt Truyện: Vòng Loại BWF  -  Chương 1 - 6"
	ms_lbl.add_theme_font_size_override("font_size", 11)
	ms_lbl.modulate = Color(0.80, 0.85, 0.92)
	mode_summary.add_child(ms_lbl)
	cta_box.add_child(mode_summary)
	
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	
	var btn_gacha = _create_clean_button("CHIÊU MỘ", Color(0.4, 0.7, 0.95), Vector2(100, 68), 12)
	btn_gacha.pressed.connect(func(): switch_state(MenuState.SHOP))
	btn_row.add_child(btn_gacha)
	
	# Primary Giant Play Button (The Spike Cross Style - Bold Clean Typography)
	var btn_play_cta = Button.new()
	btn_play_cta.text = "TRẬN ĐẤU"
	btn_play_cta.focus_mode = Control.FOCUS_NONE
	btn_play_cta.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_play_cta.custom_minimum_size = Vector2(210, 68)
	btn_play_cta.add_theme_font_size_override("font_size", 22)
	
	var sb_cta = StyleBoxFlat.new()
	sb_cta.bg_color = Color(0.96, 0.60, 0.10, 0.95)
	sb_cta.border_width_left = 2
	sb_cta.border_width_top = 2
	sb_cta.border_width_right = 2
	sb_cta.border_width_bottom = 2
	sb_cta.border_color = Color(1.0, 0.88, 0.40, 1.0)
	sb_cta.corner_radius_top_left = 12
	sb_cta.corner_radius_top_right = 12
	sb_cta.corner_radius_bottom_right = 12
	sb_cta.corner_radius_bottom_left = 12
	sb_cta.shadow_color = Color(0.96, 0.50, 0.05, 0.35)
	sb_cta.shadow_size = 8
	sb_cta.shadow_offset = Vector2(0, 3)
	btn_play_cta.add_theme_stylebox_override("normal", sb_cta)
	
	var sb_cta_h = sb_cta.duplicate()
	sb_cta_h.bg_color = Color(1.0, 0.70, 0.18, 1.0)
	sb_cta_h.border_color = Color(1.0, 1.0, 0.65, 1.0)
	btn_play_cta.add_theme_stylebox_override("hover", sb_cta_h)
	btn_play_cta.add_theme_stylebox_override("focus", sb_cta_h)
	
	btn_play_cta.pressed.connect(func():
		if Time.get_ticks_msec() < _state_switch_cooldown_until: return
		switch_state(MenuState.MATCH_SELECT)
	)
	btn_row.add_child(btn_play_cta)
	cta_box.add_child(btn_row)

func _create_widget_card(title: String, body: String, col: Color) -> PanelContainer:
	var p = _create_spike_translucent_panel(Vector2(280, 100), 10, Color(col.r, col.g, col.b, 0.45))
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_bottom", 12)
	p.add_child(m)
	
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	m.add_child(v)
	
	var t = Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 12)
	t.modulate = col
	v.add_child(t)
	
	var b = Label.new()
	b.text = body
	b.add_theme_font_size_override("font_size", 11)
	b.modulate = Color(0.75, 0.82, 0.90, 0.85)
	v.add_child(b)
	
	return p

func _update_hero_standee() -> void:
	var data = CHAR_DATA.get(selected_player_id, CHAR_DATA["nishikawa"])
	if lbl_hero_name:
		lbl_hero_name.text = data["name"]
	if lbl_hero_rarity:
		lbl_hero_rarity.text = data["rarity"]
		lbl_hero_rarity.modulate = data["color"]
	if lbl_hero_passive:
		lbl_hero_passive.text = data["passive"]
		
	if not hero_standee:
		return
		
	var full_standee = hero_standee.find_child("HeroFullStandee", true, false) as TextureRect
	var fallback_box = hero_standee.find_child("HeroFallbackBox", true, false) as Control
	
	if data.has("standee") and data["standee"] != null:
		if full_standee:
			full_standee.texture = data["standee"]
			full_standee.visible = true
		if fallback_box:
			fallback_box.visible = false
	else:
		if full_standee:
			full_standee.texture = null
			full_standee.visible = false
		if fallback_box:
			fallback_box.visible = true
			var big_icon = fallback_box.find_child("HeroBigIcon", true, false) as TextureRect
			if big_icon and data.has("skill_icon"):
				big_icon.texture = data["skill_icon"]

	# Khôi phục scale tĩnh chuẩn (hiệu ứng thở chuyển hoàn toàn sang GPU Vertex Shader)
	hero_standee.scale = Vector2.ONE

# ==========================================================
# 4. MATCH SELECTION PANEL (The Spike Horizontal Cards)
# ==========================================================
func _build_match_select_panel() -> void:
	match_select_panel = Control.new()
	match_select_panel.custom_minimum_size = Vector2(1280, 720)
	match_select_panel.size = Vector2(1280, 720)
	match_select_panel.position = Vector2.ZERO
	match_select_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match_select_panel.visible = false
	add_child(match_select_panel)
	
	var back_btn = _create_clean_button("<  QUAY LẠI TRANG CHỦ", Color(0.75, 0.82, 0.92), Vector2(180, 36), 12)
	back_btn.position = Vector2(30, 80)
	back_btn.pressed.connect(func(): switch_state(MenuState.LOBBY))
	match_select_panel.add_child(back_btn)
	
	var title_lbl = Label.new()
	title_lbl.text = "CHỌN CHẾ ĐỘ THI ĐẤU"
	title_lbl.position = Vector2(230, 84)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.modulate = Color(1.0, 0.85, 0.3)
	match_select_panel.add_child(title_lbl)
	
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(30, 135)
	scroll.custom_minimum_size = Vector2(1220, 520)
	scroll.size = Vector2(1220, 520)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	match_select_panel.add_child(scroll)
	
	var cards_row = HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 20)
	cards_row.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(cards_row)
	
	# 1. PVP Card (Studio ICON PVP)
	cards_row.add_child(_create_mode_card_tex(
		"ĐẤU ĐỐI KHÁNG TRỰC TUYẾN",
		"TRANH HÙNG ĐỈNH CAO",
		TEX_PVP,
		Color(0.20, 0.90, 0.80),
		"So tài cầu lông trực tiếp cùng bạn bè và các cao thủ.\nTạo phòng riêng hoặc gia nhập nhanh chóng.",
		"SẴN SÀNG",
		false,
		func():
			if Time.get_ticks_msec() < _state_switch_cooldown_until: return
			switch_state(MenuState.PVP_LOBBY)
	))
	
	# 2. AI Rival Card (Studio VS AI)
	cards_row.add_child(_create_mode_card_tex(
		"THỬ THÁCH ĐỐI THỦ MÁY",
		"ĐẤU ĐƠN CỌ XÁT",
		TEX_VS_AI,
		Color(1.0, 0.82, 0.25),
		"Tập luyện và tranh tài với các đối thủ máy đa phong cách.\nTùy chỉnh độ khó Dễ, Trung Bình hoặc Đỉnh Cao.",
		"SẴN SÀNG",
		false,
		func():
			if Time.get_ticks_msec() < _state_switch_cooldown_until: return
			switch_state(MenuState.MATCH_SETUP)
	))
	
	# 3. Training Card (Studio Gold Padlock Icon)
	cards_row.add_child(_create_mode_card_tex(
		"SÂN TẬP LUYỆN",
		"TẬP LUYỆN KỸ NĂNG",
		TEX_PADLOCK,
		Color(0.40, 0.70, 0.95),
		"Luyện phát cầu, tập smash chuẩn nhịp\nvà di chuyển linh hoạt trên sân.",
		"SẮP RA MẮT",
		true,
		func(): pass
	))
	
	# 4. Story Mode Card (Studio Gold Padlock Icon)
	cards_row.add_child(_create_mode_card_tex(
		"CỐT TRUYỆN THIẾU NIÊN",
		"HÀNH TRÌNH VÔ ĐỊCH",
		TEX_PADLOCK,
		Color(0.85, 0.50, 1.0),
		"Hành trình từ giải phong trào đến đỉnh cao thế giới.\nChinh phục các chặng đua kịch tính.",
		"SẮP RA MẮT",
		true,
		func(): pass
	))
	
	# 5. Tournament Cup Card (Studio Gold Padlock Icon)
	cards_row.add_child(_create_mode_card_tex(
		"GIẢI ĐẤU VÔ ĐỊCH",
		"CÚP THẾ GIỚI",
		TEX_PADLOCK,
		Color(1.0, 0.55, 0.30),
		"Vòng bảng và loại trực tiếp 16 hạt giống xuất sắc\ntranh cúp vô địch danh giá.",
		"SẮP RA MẮT",
		true,
		func(): pass
	))

func _create_mode_card_tex(title: String, tag: String, tex: Texture2D, col: Color, desc: String, status_str: String, is_locked: bool, on_click: Callable) -> PanelContainer:
	var p = _create_spike_translucent_panel(Vector2(250, 480), 14, Color(col.r, col.g, col.b, 0.50))
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_bottom", 16)
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_child(m)
	
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	m.add_child(v)
	
	var tag_lbl = Label.new()
	tag_lbl.text = tag
	tag_lbl.add_theme_font_size_override("font_size", 10)
	tag_lbl.modulate = col if not is_locked else Color(0.6, 0.65, 0.72)
	v.add_child(tag_lbl)
	
	var t_lbl = Label.new()
	t_lbl.text = title
	t_lbl.add_theme_font_size_override("font_size", 15)
	t_lbl.modulate = Color.WHITE if not is_locked else Color(0.7, 0.75, 0.8)
	v.add_child(t_lbl)
	
	var ic_stage = CenterContainer.new()
	ic_stage.custom_minimum_size = Vector2(210, 180)
	var ic_size = Vector2(120, 120) if not is_locked else Vector2(84, 84)
	var icon = _create_tex_icon(tex, ic_size)
	ic_stage.add_child(icon)
	v.add_child(ic_stage)
	
	var d_lbl = Label.new()
	d_lbl.text = desc
	d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_lbl.add_theme_font_size_override("font_size", 11)
	d_lbl.modulate = Color(0.70, 0.78, 0.88, 0.85)
	v.add_child(d_lbl)
	
	var sp = Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	
	var btn = _create_clean_button(status_str if not is_locked else "SẮP RA MẮT", col if not is_locked else Color(0.5, 0.55, 0.62), Vector2(210, 40), 12)
	if not is_locked:
		btn.pressed.connect(on_click)
	v.add_child(btn)
	
	return p

# ==========================================================
# 5. MATCH SETUP PANEL (NO CLIPPED SHADOWS)
# ==========================================================
func _build_match_setup_panel() -> void:
	setup_panel = Control.new()
	setup_panel.custom_minimum_size = Vector2(1280, 720)
	setup_panel.size = Vector2(1280, 720)
	setup_panel.position = Vector2.ZERO
	setup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_panel.visible = false
	add_child(setup_panel)
	
	var setup_box = _create_spike_translucent_panel(Vector2(1040, 560), 12, Color(0.35, 0.50, 0.75, 0.55))
	setup_box.position = Vector2(120, 85)
	setup_box.mouse_filter = Control.MOUSE_FILTER_PASS
	setup_panel.add_child(setup_box)
	
	var setup_m = MarginContainer.new()
	setup_m.add_theme_constant_override("margin_left", 20)
	setup_m.add_theme_constant_override("margin_top", 16)
	setup_m.add_theme_constant_override("margin_right", 20)
	setup_m.add_theme_constant_override("margin_bottom", 16)
	setup_m.mouse_filter = Control.MOUSE_FILTER_PASS
	setup_box.add_child(setup_m)
	
	var setup_vbox = VBoxContainer.new()
	setup_vbox.add_theme_constant_override("separation", 10)
	setup_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	setup_m.add_child(setup_vbox)
	
	var setup_title = Label.new()
	setup_title.text = "CẤU HÌNH TRANH TÀI"
	setup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	setup_title.add_theme_font_size_override("font_size", 18)
	setup_title.modulate = Color(1.0, 0.85, 0.3)
	setup_vbox.add_child(setup_title)
	
	# Character Cards
	var cards_row = HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 14)
	cards_row.mouse_filter = Control.MOUSE_FILTER_PASS
	setup_vbox.add_child(cards_row)
	
	for cid in ["nishikawa", "fuji", "wall"]:
		var card = _create_character_card(cid)
		cards_row.add_child(card)
		card_nodes[cid] = card
		
	# Difficulty Selector Row
	var diff_box = HBoxContainer.new()
	diff_box.alignment = BoxContainer.ALIGNMENT_CENTER
	diff_box.add_theme_constant_override("separation", 10)
	diff_box.mouse_filter = Control.MOUSE_FILTER_PASS
	setup_vbox.add_child(diff_box)
	
	var lbl_diff = Label.new()
	lbl_diff.text = "ĐỘ KHÓ:"
	lbl_diff.add_theme_font_size_override("font_size", 12)
	lbl_diff.modulate = Color(0.75, 0.82, 0.90)
	diff_box.add_child(lbl_diff)
	
	btn_diff_easy = _create_clean_button("DỄ", Color(0.25, 0.85, 0.50), Vector2(100, 32), 11)
	btn_diff_easy.pressed.connect(func(): _set_difficulty(0))
	diff_box.add_child(btn_diff_easy)
	
	btn_diff_medium = _create_clean_button("TRUNG BÌNH", Color(1.0, 0.80, 0.25), Vector2(120, 32), 11)
	btn_diff_medium.pressed.connect(func(): _set_difficulty(1))
	diff_box.add_child(btn_diff_medium)
	
	btn_diff_hard = _create_clean_button("ĐỈNH CAO", Color(0.95, 0.35, 0.35), Vector2(110, 32), 11)
	btn_diff_hard.pressed.connect(func(): _set_difficulty(2))
	diff_box.add_child(btn_diff_hard)
	
	# Points Selector Row
	var pts_box = HBoxContainer.new()
	pts_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pts_box.add_theme_constant_override("separation", 10)
	pts_box.mouse_filter = Control.MOUSE_FILTER_PASS
	setup_vbox.add_child(pts_box)
	
	var lbl_pts = Label.new()
	lbl_pts.text = "ĐIỂM THẮNG MỖI SET:"
	lbl_pts.add_theme_font_size_override("font_size", 12)
	lbl_pts.modulate = Color(0.75, 0.82, 0.90)
	pts_box.add_child(lbl_pts)
	
	btn_pts_11 = _create_clean_button("11 ĐIỂM", Color(0.3, 0.9, 0.4), Vector2(100, 32), 11)
	btn_pts_11.pressed.connect(func(): _set_target_points(11))
	pts_box.add_child(btn_pts_11)
	
	btn_pts_15 = _create_clean_button("15 ĐIỂM", Color(1.0, 0.80, 0.25), Vector2(100, 32), 11)
	btn_pts_15.pressed.connect(func(): _set_target_points(15))
	pts_box.add_child(btn_pts_15)
	
	btn_pts_21 = _create_clean_button("21 ĐIỂM TIÊU CHUẨN", Color(0.95, 0.40, 0.35), Vector2(160, 32), 11)
	btn_pts_21.pressed.connect(func(): _set_target_points(21))
	pts_box.add_child(btn_pts_21)
	
	# Sets Selector Row
	var sets_box = HBoxContainer.new()
	sets_box.alignment = BoxContainer.ALIGNMENT_CENTER
	sets_box.add_theme_constant_override("separation", 10)
	sets_box.mouse_filter = Control.MOUSE_FILTER_PASS
	setup_vbox.add_child(sets_box)
	
	var lbl_sets = Label.new()
	lbl_sets.text = "SỐ SET ĐẤU:"
	lbl_sets.add_theme_font_size_override("font_size", 12)
	lbl_sets.modulate = Color(0.75, 0.82, 0.90)
	sets_box.add_child(lbl_sets)
	
	btn_sets_1 = _create_clean_button("1 SET THẮNG NHANH", Color(0.35, 0.85, 1.0), Vector2(160, 32), 11)
	btn_sets_1.pressed.connect(func(): _set_match_sets(1))
	sets_box.add_child(btn_sets_1)
	
	btn_sets_3 = _create_clean_button("3 SET THẮNG 2", Color(1.0, 0.85, 0.25), Vector2(140, 32), 11)
	btn_sets_3.pressed.connect(func(): _set_match_sets(3))
	sets_box.add_child(btn_sets_3)
	
	# Matchup Summary
	label_matchup_summary = Label.new()
	label_matchup_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_matchup_summary.add_theme_font_size_override("font_size", 13)
	label_matchup_summary.modulate = Color(0.90, 0.95, 1.0)
	setup_vbox.add_child(label_matchup_summary)
	
	# Action buttons
	var action_row = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 16)
	action_row.mouse_filter = Control.MOUSE_FILTER_PASS
	setup_vbox.add_child(action_row)
	
	var btn_start_match = _create_clean_button("VÀO SÂN TRANH TÀI", Color(1.0, 0.82, 0.25), Vector2(240, 44), 15)
	btn_start_match.pressed.connect(_confirm_and_start_match)
	action_row.add_child(btn_start_match)
	
	var btn_back_title = _create_clean_button("QUAY LẠI", Color(0.65, 0.70, 0.80), Vector2(110, 44), 13)
	btn_back_title.pressed.connect(func(): switch_state(MenuState.MATCH_SELECT))
	action_row.add_child(btn_back_title)

# ==========================================================
# 6. PVP LOBBY PANEL
# ==========================================================
func _build_pvp_panel() -> void:
	pvp_panel = Control.new()
	pvp_panel.custom_minimum_size = Vector2(1280, 720)
	pvp_panel.size = Vector2(1280, 720)
	pvp_panel.position = Vector2.ZERO
	pvp_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pvp_panel.visible = false
	add_child(pvp_panel)
	
	var pvp_box = _create_spike_translucent_panel(Vector2(1040, 560), 12, Color(0.25, 0.85, 0.75, 0.50))
	pvp_box.position = Vector2(120, 85)
	pvp_box.mouse_filter = Control.MOUSE_FILTER_PASS
	pvp_panel.add_child(pvp_box)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 32)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_right", 32)
	m.add_theme_constant_override("margin_bottom", 24)
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	pvp_box.add_child(m)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	m.add_child(vbox)
	
	# Header Row
	var header_row = HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	var lbl_title = Label.new()
	lbl_title.text = "ĐẤU ĐỐI KHÁNG TRỰC TUYẾN"
	lbl_title.add_theme_font_size_override("font_size", 20)
	lbl_title.modulate = Color(0.25, 0.90, 0.85)
	header_row.add_child(lbl_title)
	
	var header_spacer = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_spacer)
	
	pvp_status_lbl = Label.new()
	pvp_status_lbl.text = "SẴN SÀNG"
	pvp_status_lbl.add_theme_font_size_override("font_size", 12)
	pvp_status_lbl.modulate = Color(0.20, 0.85, 0.50)
	header_row.add_child(pvp_status_lbl)
	
	header_row.add_child(VSeparator.new())
	
	pvp_ping_lbl = Label.new()
	pvp_ping_lbl.text = "Ping: -- ms"
	pvp_ping_lbl.add_theme_font_size_override("font_size", 12)
	pvp_ping_lbl.modulate = Color(0.35, 0.80, 1.0)
	header_row.add_child(pvp_ping_lbl)
	vbox.add_child(header_row)
	
	# Config strip
	var config_card = PanelContainer.new()
	var sb_cfg = StyleBoxFlat.new()
	sb_cfg.bg_color = Color(0.08, 0.12, 0.18, 0.90)
	sb_cfg.border_width_left = 1
	sb_cfg.border_width_top = 1
	sb_cfg.border_width_right = 1
	sb_cfg.border_width_bottom = 1
	sb_cfg.border_color = Color(0.25, 0.85, 0.75, 0.35)
	sb_cfg.corner_radius_top_left = 8
	sb_cfg.corner_radius_top_right = 8
	sb_cfg.corner_radius_bottom_right = 8
	sb_cfg.corner_radius_bottom_left = 8
	config_card.add_theme_stylebox_override("panel", sb_cfg)
	
	var cm = MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 16)
	cm.add_theme_constant_override("margin_top", 10)
	cm.add_theme_constant_override("margin_right", 16)
	cm.add_theme_constant_override("margin_bottom", 10)
	config_card.add_child(cm)
	
	var cfg_row = HBoxContainer.new()
	cfg_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cfg_row.add_theme_constant_override("separation", 14)
	cm.add_child(cfg_row)
	
	# Player Name
	var name_box = HBoxContainer.new()
	name_box.add_theme_constant_override("separation", 6)
	var lbl_n = Label.new()
	lbl_n.text = "TÊN:"
	lbl_n.add_theme_font_size_override("font_size", 12)
	lbl_n.modulate = Color(0.75, 0.82, 0.90)
	name_box.add_child(lbl_n)
	
	pvp_name_input = LineEdit.new()
	pvp_name_input.text = pvp_player_name
	pvp_name_input.custom_minimum_size = Vector2(120, 30)
	pvp_name_input.max_length = 16
	pvp_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sb_name = StyleBoxFlat.new()
	sb_name.bg_color = Color(0.12, 0.16, 0.22, 0.95)
	sb_name.corner_radius_top_left = 4
	sb_name.corner_radius_top_right = 4
	sb_name.corner_radius_bottom_right = 4
	sb_name.corner_radius_bottom_left = 4
	pvp_name_input.add_theme_stylebox_override("normal", sb_name)
	pvp_name_input.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.is_pressed():
			pvp_name_input.grab_focus()
			_open_name_input_modal()
	)
	pvp_name_input.focus_entered.connect(func():
		_open_name_input_modal()
	)
	pvp_name_input.text_changed.connect(func(new_text: String):
		var clean = new_text.strip_edges()
		pvp_player_name = clean if not clean.is_empty() else "BaoHodaka"
		_save_player_name(pvp_player_name)
		if top_name_input and top_name_input != pvp_name_input:
			top_name_input.text = pvp_player_name
	)
	name_box.add_child(pvp_name_input)
	cfg_row.add_child(name_box)
	cfg_row.add_child(VSeparator.new())
	
	# Character selector
	var char_box = HBoxContainer.new()
	char_box.add_theme_constant_override("separation", 6)
	var lbl_c = Label.new()
	lbl_c.text = "TƯỚNG:"
	lbl_c.add_theme_font_size_override("font_size", 12)
	lbl_c.modulate = Color(0.75, 0.82, 0.90)
	char_box.add_child(lbl_c)
	for cid in ["nishikawa", "fuji", "wall"]:
		var b = _create_clean_button(CHAR_DATA[cid]["name"], CHAR_DATA[cid]["color"], Vector2(96, 30), 11)
		b.pressed.connect(func(): _select_pvp_char(cid))
		char_box.add_child(b)
		pvp_char_btns[cid] = b
	cfg_row.add_child(char_box)
	cfg_row.add_child(VSeparator.new())
	
	# Points picker
	var pts_box = HBoxContainer.new()
	pts_box.add_theme_constant_override("separation", 4)
	var lbl_p = Label.new()
	lbl_p.text = "ĐIỂM:"
	lbl_p.add_theme_font_size_override("font_size", 12)
	lbl_p.modulate = Color(0.75, 0.82, 0.90)
	pts_box.add_child(lbl_p)
	for pts in [11, 21]:
		var b = _create_clean_button(str(pts), Color(0.2, 0.85, 0.75), Vector2(42, 30), 11)
		b.pressed.connect(func(): _select_pvp_pts(pts))
		pts_box.add_child(b)
		pvp_pts_btns[pts] = b
	cfg_row.add_child(pts_box)
	cfg_row.add_child(VSeparator.new())
	
	# Sets picker
	var sets_box = HBoxContainer.new()
	sets_box.add_theme_constant_override("separation", 4)
	var lbl_s = Label.new()
	lbl_s.text = "SET:"
	lbl_s.add_theme_font_size_override("font_size", 12)
	lbl_s.modulate = Color(0.75, 0.82, 0.90)
	sets_box.add_child(lbl_s)
	for s_cnt in [1, 3]:
		var b = _create_clean_button(str(s_cnt), Color(0.35, 0.75, 1.0), Vector2(40, 30), 11)
		b.pressed.connect(func(): _select_pvp_sets(s_cnt))
		sets_box.add_child(b)
		pvp_sets_btns[s_cnt] = b
	cfg_row.add_child(sets_box)
	vbox.add_child(config_card)
	
	pvp_char_desc_lbl = Label.new()
	pvp_char_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pvp_char_desc_lbl.add_theme_font_size_override("font_size", 11)
	pvp_char_desc_lbl.modulate = Color(0.70, 0.80, 0.90)
	vbox.add_child(pvp_char_desc_lbl)
	
	# Action Cards: Host vs Join
	var cards_row = HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 24)
	cards_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(cards_row)
	
	# HOST CARD
	var host_card = _create_spike_translucent_panel(Vector2(470, 230), 10, Color(0.20, 0.85, 0.65, 0.45))
	host_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_row.add_child(host_card)
	
	var hm = MarginContainer.new()
	hm.add_theme_constant_override("margin_left", 24)
	hm.add_theme_constant_override("margin_top", 20)
	hm.add_theme_constant_override("margin_right", 24)
	hm.add_theme_constant_override("margin_bottom", 20)
	host_card.add_child(hm)
	
	var hv = VBoxContainer.new()
	hv.add_theme_constant_override("separation", 14)
	hm.add_child(hv)
	
	var h_title = Label.new()
	h_title.text = "TẠO PHÒNG MỚI"
	h_title.add_theme_font_size_override("font_size", 16)
	h_title.modulate = Color(0.25, 0.95, 0.75)
	hv.add_child(h_title)
	
	var btn_gen_room = _create_clean_button("+ TẠO MÃ PHÒNG", Color(0.20, 0.85, 0.65), Vector2(240, 42), 14)
	btn_gen_room.pressed.connect(_on_host_create_room)
	hv.add_child(btn_gen_room)
	
	var code_row = HBoxContainer.new()
	code_row.add_theme_constant_override("separation", 12)
	pvp_host_code_lbl = Label.new()
	pvp_host_code_lbl.text = "MÃ: ----"
	pvp_host_code_lbl.add_theme_font_size_override("font_size", 22)
	pvp_host_code_lbl.modulate = Color(1.0, 0.88, 0.3)
	code_row.add_child(pvp_host_code_lbl)
	
	var btn_copy = _create_clean_button("CHÉP MÃ", Color(0.85, 0.85, 0.85), Vector2(100, 34), 11)
	btn_copy.pressed.connect(func():
		if not pvp_current_code.is_empty() and pvp_current_code != "----":
			if OS.has_feature("web"):
				JavaScriptBridge.eval("""
					if (navigator.clipboard && navigator.clipboard.writeText) {
						navigator.clipboard.writeText('%s').catch(function(){});
					}
				""" % pvp_current_code)
			DisplayServer.clipboard_set(pvp_current_code)
			btn_copy.text = "ĐÃ CHÉP"
			var t = get_tree().create_timer(1.8)
			t.timeout.connect(func():
				if is_instance_valid(btn_copy):
					btn_copy.text = "CHÉP MÃ"
			)
	)
	code_row.add_child(btn_copy)
	hv.add_child(code_row)
	
	# JOIN CARD
	var join_card = _create_spike_translucent_panel(Vector2(470, 230), 10, Color(0.35, 0.75, 1.0, 0.45))
	join_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_row.add_child(join_card)
	
	var jm = MarginContainer.new()
	jm.add_theme_constant_override("margin_left", 24)
	jm.add_theme_constant_override("margin_top", 20)
	jm.add_theme_constant_override("margin_right", 24)
	jm.add_theme_constant_override("margin_bottom", 20)
	join_card.add_child(jm)
	
	var jv = VBoxContainer.new()
	jv.add_theme_constant_override("separation", 14)
	jm.add_child(jv)
	
	var j_title = Label.new()
	j_title.text = "THAM GIA PHÒNG"
	j_title.add_theme_font_size_override("font_size", 16)
	j_title.modulate = Color(0.35, 0.75, 1.0)
	jv.add_child(j_title)
	
	var input_row = HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 6)
	pvp_room_input = LineEdit.new()
	pvp_room_input.placeholder_text = "MÃ PHÒNG (4 KÝ TỰ)"
	pvp_room_input.custom_minimum_size = Vector2(170, 38)
	pvp_room_input.max_length = 8
	pvp_room_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	pvp_room_input.focus_mode = Control.FOCUS_ALL
	pvp_room_input.mouse_filter = Control.MOUSE_FILTER_STOP
	pvp_room_input.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.is_pressed():
			pvp_room_input.grab_focus()
			_open_room_input_modal()
	)
	pvp_room_input.focus_entered.connect(func():
		_open_room_input_modal()
	)
	pvp_room_input.focus_exited.connect(func():
		pvp_room_input.text = pvp_room_input.text.strip_edges().to_upper()
	)
	input_row.add_child(pvp_room_input)
	
	var btn_clear_code = _create_clean_button("XÓA", Color(0.95, 0.42, 0.42), Vector2(48, 38), 11)
	btn_clear_code.pressed.connect(func():
		if pvp_room_input:
			pvp_room_input.text = ""
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window._kaiserRoomCode = ''")
	)
	input_row.add_child(btn_clear_code)
	
	var btn_paste_code = _create_clean_button("DÁN", Color(0.35, 0.75, 1.0), Vector2(48, 38), 11)
	btn_paste_code.pressed.connect(_paste_room_code)
	input_row.add_child(btn_paste_code)
	
	var btn_join = _create_clean_button("VÀO PHÒNG", Color(0.20, 0.85, 0.65), Vector2(96, 38), 12)
	btn_join.pressed.connect(_on_client_join_room)
	input_row.add_child(btn_join)
	jv.add_child(input_row)
	
	var btn_spec = _create_clean_button("THEO DÕI TRẬN ĐẤU", Color(0.70, 0.60, 0.90), Vector2(180, 34), 11)
	btn_spec.pressed.connect(_on_spectate_room)
	jv.add_child(btn_spec)
	
	# Bottom Controls
	var bot_row = HBoxContainer.new()
	bot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bot_row.add_theme_constant_override("separation", 16)
	
	btn_pvp_start = _create_clean_button("BẮT ĐẦU TRANH TÀI", Color(1.0, 0.82, 0.25), Vector2(240, 44), 14)
	btn_pvp_start.disabled = true
	btn_pvp_start.pressed.connect(_on_pvp_start_pressed)
	bot_row.add_child(btn_pvp_start)
	
	var btn_back_match = _create_clean_button("< QUAY LẠI", Color(0.65, 0.70, 0.80), Vector2(110, 44), 12)
	btn_back_match.pressed.connect(func(): switch_state(MenuState.MATCH_SELECT))
	bot_row.add_child(btn_back_match)
	vbox.add_child(bot_row)
	
	pvp_countdown_lbl = Label.new()
	pvp_countdown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pvp_countdown_lbl.add_theme_font_size_override("font_size", 14)
	pvp_countdown_lbl.modulate = Color(1.0, 0.85, 0.3)
	vbox.add_child(pvp_countdown_lbl)

# ==========================================================
# 7. ROSTER PANEL (QUẢN LÝ CẦU THỦ)
# ==========================================================
func _build_roster_panel() -> void:
	roster_panel = Control.new()
	roster_panel.custom_minimum_size = Vector2(1280, 720)
	roster_panel.size = Vector2(1280, 720)
	roster_panel.position = Vector2.ZERO
	roster_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	roster_panel.visible = false
	add_child(roster_panel)
	
	var back_btn = _create_clean_button("<  QUAY LẠI TRANG CHỦ", Color(0.75, 0.82, 0.92), Vector2(180, 36), 12)
	back_btn.position = Vector2(30, 80)
	back_btn.pressed.connect(func(): switch_state(MenuState.LOBBY))
	roster_panel.add_child(back_btn)
	
	var title_lbl = Label.new()
	title_lbl.text = "CẦU THỦ"
	title_lbl.position = Vector2(230, 84)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.modulate = Color(1.0, 0.85, 0.3)
	roster_panel.add_child(title_lbl)
	
	# Main Content Area: Left Showcase + Right Grid
	var content_row = HBoxContainer.new()
	content_row.position = Vector2(30, 130)
	content_row.custom_minimum_size = Vector2(1220, 540)
	content_row.add_theme_constant_override("separation", 24)
	content_row.mouse_filter = Control.MOUSE_FILTER_PASS
	roster_panel.add_child(content_row)
	
	# Left: Active Lineup Card with The Spike Translucent Box
	var active_box = _create_spike_translucent_panel(Vector2(380, 520), 12, Color(1.0, 0.82, 0.25, 0.65))
	active_box.name = "ActiveBox"
	active_box.mouse_filter = Control.MOUSE_FILTER_PASS
	content_row.add_child(active_box)
	
	# Right: Grid Roster
	var grid_scroll = ScrollContainer.new()
	grid_scroll.custom_minimum_size = Vector2(810, 520)
	grid_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	content_row.add_child(grid_scroll)
	
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	grid_scroll.add_child(grid)
	
	# Populate characters with pre-rendered HD skill textures
	for cid in ["nishikawa", "fuji", "wall", "gitae", "sara"]:
		var data = CHAR_DATA[cid]
		var c_card = _create_roster_card(cid, data["name"], data["rarity"], data["archetype"], data["color"], data["skill_icon"], false)
		grid.add_child(c_card)
		
	# Locked preview player (Raul)
	grid.add_child(_create_roster_card("raul", "RAUL", "S+", "BÓNG ĐÊM HUYỀN ẢO", Color(0.8, 0.3, 0.9), TEX_SKILL_VOID, true))

func _create_roster_card(cid: String, cname: String, rarity: String, arch: String, col: Color, skill_tex: Texture2D, is_locked: bool) -> PanelContainer:
	var p = _create_spike_translucent_panel(Vector2(250, 160), 10, Color(col.r, col.g, col.b, 0.50))
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	p.clip_contents = true
	
	if CHAR_DATA.has(cid) and CHAR_DATA[cid].has("standee") and CHAR_DATA[cid]["standee"] != null:
		var s_bg = _create_card_standee_bg(CHAR_DATA[cid]["standee"], Vector2(250, 160), 0.25 if not is_locked else 0.10)
		if s_bg:
			p.add_child(s_bg)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_bottom", 12)
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_child(m)
	
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	m.add_child(v)
	
	var top_r = HBoxContainer.new()
	var r_lbl = Label.new()
	r_lbl.text = rarity
	r_lbl.add_theme_font_size_override("font_size", 14)
	r_lbl.modulate = col if not is_locked else Color(0.6, 0.65, 0.7)
	top_r.add_child(r_lbl)
	
	var name_l = Label.new()
	name_l.text = " " + cname
	name_l.add_theme_font_size_override("font_size", 13)
	name_l.modulate = Color.WHITE if not is_locked else Color(0.6, 0.65, 0.7)
	top_r.add_child(name_l)
	v.add_child(top_r)
	
	var mid_r = HBoxContainer.new()
	mid_r.add_theme_constant_override("separation", 10)
	var icon = _create_tex_icon(skill_tex, Vector2(38, 38))
	if is_locked:
		icon.modulate = Color(0.6, 0.65, 0.75, 0.6)
	mid_r.add_child(icon)
	
	var a_lbl = Label.new()
	a_lbl.text = arch
	a_lbl.add_theme_font_size_override("font_size", 10)
	a_lbl.modulate = Color(0.70, 0.78, 0.88, 0.8)
	mid_r.add_child(a_lbl)
	v.add_child(mid_r)
	
	var btn = _create_clean_button("CHỌN THI ĐẤU" if not is_locked else "CHƯA MỞ", col if not is_locked else Color(0.5, 0.55, 0.6), Vector2(220, 32), 11)
	if not is_locked:
		btn.pressed.connect(func():
			_select_player(cid)
			pvp_selected_char = cid
			_update_roster_view()
		)
	v.add_child(btn)
	
	return p

func _update_roster_view() -> void:
	if not roster_panel: return
	var active_box = roster_panel.find_child("ActiveBox", true, false) as PanelContainer
	if not active_box: return
	
	for c in active_box.get_children():
		c.queue_free()
		
	var data = CHAR_DATA.get(selected_player_id, CHAR_DATA["nishikawa"])
	active_box.clip_contents = true
	
	if data.has("standee") and data["standee"] != null:
		var s_bg = _create_card_standee_bg(data["standee"], Vector2(380, 520), 0.28)
		if s_bg:
			active_box.add_child(s_bg)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_top", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_bottom", 20)
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	active_box.add_child(m)
	
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	m.add_child(v)
	
	var tag = Label.new()
	tag.text = "CẦU THỦ XUẤT TRẬN"
	tag.add_theme_font_size_override("font_size", 11)
	tag.modulate = Color(0.35, 0.85, 1.0)
	v.add_child(tag)
	
	var t_row = HBoxContainer.new()
	var r_lbl = Label.new()
	r_lbl.text = data["rarity"]
	r_lbl.add_theme_font_size_override("font_size", 22)
	r_lbl.modulate = data["color"]
	t_row.add_child(r_lbl)
	
	var n_lbl = Label.new()
	n_lbl.text = "  " + data["name"]
	n_lbl.add_theme_font_size_override("font_size", 20)
	n_lbl.modulate = Color.WHITE
	t_row.add_child(n_lbl)
	
	var sp_tr = Control.new()
	sp_tr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t_row.add_child(sp_tr)
	
	if data.has("skill_icon"):
		t_row.add_child(_create_tex_icon(data["skill_icon"], Vector2(36, 36)))
	v.add_child(t_row)
	
	var title_lbl = Label.new()
	title_lbl.text = data["title"]
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.modulate = Color(0.75, 0.82, 0.90)
	v.add_child(title_lbl)
	
	v.add_child(HSeparator.new())
	
	# Stats bars
	v.add_child(_create_stat_bar("LỰC ĐẬP", data["power"], data["color"]))
	v.add_child(_create_stat_bar("TỐC ĐỘ", data["agility"], Color(0.25, 0.85, 1.0)))
	v.add_child(_create_stat_bar("KIỂM SOÁT", data["control"], Color(0.35, 0.95, 0.55)))
	v.add_child(_create_stat_bar("TÂM LÝ", data["composure"], Color(0.85, 0.55, 1.0)))
	
	v.add_child(HSeparator.new())
	
	var sk_t = Label.new()
	sk_t.text = "Tuyệt kỹ: " + data["skill_name"]
	sk_t.add_theme_font_size_override("font_size", 12)
	sk_t.modulate = Color(1.0, 0.85, 0.3)
	v.add_child(sk_t)
	
	var sk_d = Label.new()
	sk_d.text = data["skill_desc"]
	sk_d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sk_d.add_theme_font_size_override("font_size", 10)
	sk_d.modulate = Color(0.75, 0.82, 0.90)
	v.add_child(sk_d)

# ==========================================================
# 8. SHOP & QUESTS PANELS
# ==========================================================
func _build_shop_panel() -> void:
	shop_panel = Control.new()
	shop_panel.custom_minimum_size = Vector2(1280, 720)
	shop_panel.size = Vector2(1280, 720)
	shop_panel.position = Vector2.ZERO
	shop_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_panel.visible = false
	add_child(shop_panel)
	
	var back_btn = _create_clean_button("<  QUAY LẠI TRANG CHỦ", Color(0.75, 0.82, 0.92), Vector2(180, 36), 12)
	back_btn.position = Vector2(30, 80)
	back_btn.pressed.connect(func(): switch_state(MenuState.LOBBY))
	shop_panel.add_child(back_btn)
	
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(30, 140)
	scroll.custom_minimum_size = Vector2(1220, 520)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	shop_panel.add_child(scroll)
	
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(row)
	
	row.add_child(_create_mode_card_tex("CHIÊU MỘ CẦU THỦ", "GACHA", TEX_PADLOCK, Color(1.0, 0.82, 0.25), "Kiểm tra năng lực cầu thủ\nvà chiêu mộ tân binh BWF.", "CHƯA MỞ", true, func(): pass))
	row.add_child(_create_mode_card_tex("CỬA HÀNG BÓNG", "SHOP", TEX_PADLOCK, Color(0.3, 0.9, 0.6), "Mua cầu lông thi đấu\nvà vé tham dự giải vô địch.", "CHƯA MỞ", true, func(): pass))
	row.add_child(_create_mode_card_tex("CỬA HÀNG TRANG PHỤC", "SKINS", TEX_PADLOCK, Color(0.35, 0.75, 1.0), "Trang phục thi đấu BWF\nvà vợt huyền thoại giới hạn.", "CHƯA MỞ", true, func(): pass))

func _build_quests_panel() -> void:
	quests_panel = Control.new()
	quests_panel.custom_minimum_size = Vector2(1280, 720)
	quests_panel.size = Vector2(1280, 720)
	quests_panel.position = Vector2.ZERO
	quests_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quests_panel.visible = false
	add_child(quests_panel)
	
	var back_btn = _create_clean_button("<  QUAY LẠI TRANG CHỦ", Color(0.75, 0.82, 0.92), Vector2(180, 36), 12)
	back_btn.position = Vector2(30, 80)
	back_btn.pressed.connect(func(): switch_state(MenuState.LOBBY))
	quests_panel.add_child(back_btn)
	
	var box = _create_spike_translucent_panel(Vector2(1040, 500), 12, Color(0.35, 0.50, 0.75, 0.55))
	box.position = Vector2(120, 130)
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	quests_panel.add_child(box)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 30)
	m.add_theme_constant_override("margin_top", 30)
	m.add_theme_constant_override("margin_right", 30)
	m.add_theme_constant_override("margin_bottom", 30)
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(m)
	
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	m.add_child(v)
	
	var top_r = HBoxContainer.new()
	var q_lbl = Label.new()
	q_lbl.text = "NHIỆM VỤ HÀNG NGÀY - TIẾN TRÌNH: 0 / 1000P"
	q_lbl.add_theme_font_size_override("font_size", 16)
	q_lbl.modulate = Color(1.0, 0.85, 0.3)
	top_r.add_child(q_lbl)
	v.add_child(top_r)
	
	v.add_child(_create_quest_item("Điểm danh hàng ngày", "+250P", "0/1"))
	v.add_child(_create_quest_item("Chiến thắng 2 ván đấu ở Đấu Đối Kháng Trực Tuyến", "+250P", "0/2"))
	v.add_child(_create_quest_item("Ghi 3 điểm trực tiếp từ cú SMASH hoàn hảo", "+250P", "0/3"))
	v.add_child(_create_quest_item("Thực hiện 5 pha cứu cầu trượt sàn thành công", "+250P", "0/5"))

func _create_quest_item(title: String, reward: String, prog: String) -> PanelContainer:
	var p = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.15, 0.22, 0.85)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	p.add_theme_stylebox_override("panel", sb)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_bottom", 10)
	p.add_child(m)
	
	var h = HBoxContainer.new()
	m.add_child(h)
	
	var t = Label.new()
	t.text = title + " - " + prog
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_size_override("font_size", 13)
	h.add_child(t)
	
	var r = Label.new()
	r.text = reward
	r.add_theme_font_size_override("font_size", 13)
	r.modulate = Color(1.0, 0.85, 0.3)
	h.add_child(r)
	
	var btn = _create_clean_button("DI CHUYỂN", Color(0.6, 0.65, 0.7), Vector2(110, 32), 11)
	h.add_child(btn)
	
	return p

# ==========================================================
# 9. SETTINGS PANEL (THE SPIKE STEPPED LEVEL BARS)
# ==========================================================
func _build_settings_panel() -> void:
	settings_panel = Control.new()
	settings_panel.custom_minimum_size = Vector2(1280, 720)
	settings_panel.size = Vector2(1280, 720)
	settings_panel.position = Vector2.ZERO
	settings_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_panel.visible = false
	add_child(settings_panel)
	
	var back_btn = _create_clean_button("<  QUAY LẠI TRANG CHỦ", Color(0.75, 0.82, 0.92), Vector2(180, 36), 12)
	back_btn.position = Vector2(30, 80)
	back_btn.pressed.connect(func(): switch_state(MenuState.LOBBY))
	settings_panel.add_child(back_btn)
	
	var set_box = _create_spike_translucent_panel(Vector2(1040, 520), 12, Color(0.35, 0.50, 0.75, 0.55))
	set_box.position = Vector2(120, 125)
	set_box.mouse_filter = Control.MOUSE_FILTER_PASS
	settings_panel.add_child(set_box)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_top", 20)
	m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_bottom", 20)
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	set_box.add_child(m)
	
	var main_h = HBoxContainer.new()
	main_h.add_theme_constant_override("separation", 24)
	main_h.mouse_filter = Control.MOUSE_FILTER_PASS
	m.add_child(main_h)
	
	var tabs_vbox = VBoxContainer.new()
	tabs_vbox.custom_minimum_size = Vector2(180, 480)
	tabs_vbox.add_theme_constant_override("separation", 10)
	tabs_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	main_h.add_child(tabs_vbox)
	
	var content_stack = Control.new()
	content_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_stack.mouse_filter = Control.MOUSE_FILTER_PASS
	main_h.add_child(content_stack)
	
	var p_audio = _build_settings_audio_tab()
	var p_gfx = _build_settings_gfx_tab()
	var p_acc = _build_settings_account_tab()
	
	content_stack.add_child(p_audio)
	content_stack.add_child(p_gfx)
	content_stack.add_child(p_acc)
	
	var b_audio = _create_clean_button("ÂM THANH", Color(1.0, 0.85, 0.3), Vector2(170, 42), 13)
	var b_gfx = _create_clean_button("ĐỒ HỌA", Color(0.35, 0.8, 1.0), Vector2(170, 42), 13)
	var b_acc = _create_clean_button("TÀI KHOẢN", Color(0.4, 0.9, 0.6), Vector2(170, 42), 13)
	
	b_audio.pressed.connect(func():
		p_audio.visible = true
		p_gfx.visible = false
		p_acc.visible = false
	)
	b_gfx.pressed.connect(func():
		p_audio.visible = false
		p_gfx.visible = true
		p_acc.visible = false
	)
	b_acc.pressed.connect(func():
		p_audio.visible = false
		p_gfx.visible = false
		p_acc.visible = true
	)
	
	tabs_vbox.add_child(b_audio)
	tabs_vbox.add_child(b_gfx)
	tabs_vbox.add_child(b_acc)
	
	p_audio.visible = true
	p_gfx.visible = false
	p_acc.visible = false

# ==========================================================
# MINI MUSIC PLAYER (Vinyl Disc & Track Controller)
# ==========================================================
func _get_audio() -> Node:
	if has_node("/root/AudioManager"):
		return get_node("/root/AudioManager")
	return null

func _build_mini_player() -> Control:
	var p = PanelContainer.new()
	p.name = "MiniMusicPlayer"
	p.custom_minimum_size = Vector2(280, 64)
	p.position = Vector2(30, 618)
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.11, 0.16, 0.92)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(1.0, 0.82, 0.25, 0.40)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	p.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_child(margin)
	
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(row)
	
	vinyl_disc_ctrl = VinylDiscControl.new()
	vinyl_disc_ctrl.custom_minimum_size = Vector2(48, 48)
	row.add_child(vinyl_disc_ctrl)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(info_vbox)
	
	mini_player_title_lbl = Label.new()
	mini_player_title_lbl.text = "Tokyo 2020: Badminton"
	mini_player_title_lbl.add_theme_font_size_override("font_size", 11)
	mini_player_title_lbl.modulate = Color(1.0, 0.85, 0.30)
	mini_player_title_lbl.clip_text = true
	info_vbox.add_child(mini_player_title_lbl)
	
	mini_player_artist_lbl = Label.new()
	mini_player_artist_lbl.text = "Sonic Olympic Games OST"
	mini_player_artist_lbl.add_theme_font_size_override("font_size", 9)
	mini_player_artist_lbl.modulate = Color(0.70, 0.78, 0.90)
	mini_player_artist_lbl.clip_text = true
	info_vbox.add_child(mini_player_artist_lbl)
	
	var ctrl_row = HBoxContainer.new()
	ctrl_row.add_theme_constant_override("separation", 6)
	ctrl_row.mouse_filter = Control.MOUSE_FILTER_PASS
	info_vbox.add_child(ctrl_row)
	
	var btn_prev = _create_clean_button("<", Color(0.7, 0.75, 0.85), Vector2(24, 20), 10)
	btn_prev.pressed.connect(func():
		var am = _get_audio()
		if am:
			am.prev_track()
	)
	ctrl_row.add_child(btn_prev)
	
	mini_player_btn_play = _create_clean_button("||", Color(1.0, 0.82, 0.25), Vector2(30, 20), 10)
	mini_player_btn_play.pressed.connect(func():
		var am = _get_audio()
		if am:
			am.toggle_play_pause()
	)
	ctrl_row.add_child(mini_player_btn_play)
	
	var btn_next = _create_clean_button(">", Color(0.7, 0.75, 0.85), Vector2(24, 20), 10)
	btn_next.pressed.connect(func():
		var am = _get_audio()
		if am:
			am.next_track()
	)
	ctrl_row.add_child(btn_next)
	
	# Connect to AudioManager signals
	var am = _get_audio()
	if am:
		am.track_changed.connect(_on_audio_track_changed)
		am.playback_state_changed.connect(_on_audio_playback_state_changed)
		_update_mini_player_ui()
		
	return p

func _on_audio_track_changed(_idx: int, track_info: Dictionary) -> void:
	if mini_player_title_lbl:
		mini_player_title_lbl.text = str(track_info.get("title", ""))
	if mini_player_artist_lbl:
		mini_player_artist_lbl.text = str(track_info.get("artist", ""))

func _on_audio_playback_state_changed(playing: bool) -> void:
	if mini_player_btn_play:
		mini_player_btn_play.text = "||" if playing else ">"
	if vinyl_disc_ctrl:
		vinyl_disc_ctrl.set_spinning(playing)

func _update_mini_player_ui() -> void:
	var am = _get_audio()
	if not am: return
	var cur_idx = am.current_track_idx
	if cur_idx >= 0 and cur_idx < am.PLAYLIST.size():
		var t = am.PLAYLIST[cur_idx]
		if mini_player_title_lbl: mini_player_title_lbl.text = str(t.get("title", ""))
		if mini_player_artist_lbl: mini_player_artist_lbl.text = str(t.get("artist", ""))
	var is_act = (am.is_playing and am.bgm_player and am.bgm_player.playing)
	if mini_player_btn_play:
		mini_player_btn_play.text = "||" if is_act else ">"
	if vinyl_disc_ctrl:
		vinyl_disc_ctrl.set_spinning(is_act)

func _build_settings_audio_tab() -> VBoxContainer:
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 16)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var t = Label.new()
	t.text = "CÀI ĐẶT ÂM THANH"
	t.add_theme_font_size_override("font_size", 15)
	t.modulate = Color(1.0, 0.85, 0.3)
	v.add_child(t)
	
	var am = _get_audio()
	# 1. Âm lượng hệ thống (Master)
	var cur_master = am.master_step if am else 5
	v.add_child(_create_stepped_volume_row("Âm lượng hệ thống (Toàn bộ game):", cur_master, func(step):
		var cur_am = _get_audio()
		if cur_am:
			cur_am.set_master_step(step)
	))
	
	# 2. Nhạc nền (Music - sảnh + trận đấu)
	var cur_music = am.music_step if am else 4
	v.add_child(_create_stepped_volume_row("Nhạc nền (Sảnh & Trận đấu):", cur_music, func(step):
		var cur_am = _get_audio()
		if cur_am:
			cur_am.set_music_step(step)
	))
	
	# 3. Hiệu ứng âm thanh (SFX)
	var cur_sfx = am.sfx_step if am else 5
	v.add_child(_create_stepped_volume_row("Hiệu ứng âm thanh (Đập cầu, rít giày...):", cur_sfx, func(step):
		var cur_am = _get_audio()
		if cur_am:
			cur_am.set_sfx_step(step)
	))
	
	# 4. Tùy chọn Tắt nhạc nền trong trận đấu
	var match_bgm_row = HBoxContainer.new()
	match_bgm_row.mouse_filter = Control.MOUSE_FILTER_PASS
	var match_bgm_lbl = Label.new()
	match_bgm_lbl.text = "Nhạc nền trong trận đấu:"
	match_bgm_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	match_bgm_lbl.add_theme_font_size_override("font_size", 13)
	match_bgm_row.add_child(match_bgm_lbl)
	
	var is_match_bgm = am.bgm_match_enabled if am else true
	var btn_match_bgm = _create_clean_button("BẬT" if is_match_bgm else "TẮT", Color(0.3, 0.9, 0.4) if is_match_bgm else Color(0.7, 0.7, 0.7), Vector2(90, 32), 12)
	btn_match_bgm.pressed.connect(func():
		var cur_am = _get_audio()
		if cur_am:
			var new_val = not cur_am.bgm_match_enabled
			cur_am.set_bgm_match_enabled(new_val)
			btn_match_bgm.text = "BẬT" if new_val else "TẮT"
			btn_match_bgm.modulate = Color(0.3, 0.9, 0.4) if new_val else Color(0.7, 0.7, 0.7)
	)
	match_bgm_row.add_child(btn_match_bgm)
	v.add_child(match_bgm_row)
	
	# 5. Tiếng rít giày sàn đấu
	var sq_row = HBoxContainer.new()
	sq_row.mouse_filter = Control.MOUSE_FILTER_PASS
	var sq_lbl = Label.new()
	sq_lbl.text = "Tiếng rít giày sàn đấu:"
	sq_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sq_lbl.add_theme_font_size_override("font_size", 13)
	sq_row.add_child(sq_lbl)
	
	var is_sq = am.squeak_enabled if am else squeak_enabled
	var btn_sq = _create_clean_button("BẬT" if is_sq else "TẮT", Color(0.3, 0.9, 0.4) if is_sq else Color(0.7, 0.7, 0.7), Vector2(90, 32), 12)
	btn_sq.pressed.connect(func():
		squeak_enabled = not squeak_enabled
		var cur_am = _get_audio()
		if cur_am:
			cur_am.squeak_enabled = squeak_enabled
		btn_sq.text = "BẬT" if squeak_enabled else "TẮT"
		btn_sq.modulate = Color(0.3, 0.9, 0.4) if squeak_enabled else Color(0.7, 0.7, 0.7)
		var bgm_en = cur_am.bgm_match_enabled if cur_am else true
		var bgm_vol = cur_am.step_to_linear(cur_am.music_step) if cur_am else 1.0
		settings_updated.emit(squeak_enabled, bgm_en, bgm_vol, low_graphics_mode)
	)
	sq_row.add_child(btn_sq)
	v.add_child(sq_row)
	
	return v

func _build_settings_gfx_tab() -> VBoxContainer:
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 16)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var t = Label.new()
	t.text = "CÀI ĐẶT ĐỒ HỌA VÀ HIỆU NĂNG"
	t.add_theme_font_size_override("font_size", 15)
	t.modulate = Color(0.35, 0.85, 1.0)
	v.add_child(t)
	
	if OS.has_feature("web"):
		var gfx_row = HBoxContainer.new()
		gfx_row.mouse_filter = Control.MOUSE_FILTER_PASS
		var lbl_gfx = Label.new()
		lbl_gfx.text = "Chế độ đồ họa tiết kiệm:"
		lbl_gfx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_gfx.add_theme_font_size_override("font_size", 13)
		gfx_row.add_child(lbl_gfx)
		
		var btn_gfx = _create_clean_button("[ BẬT ]" if low_graphics_mode else "[ TẮT ]", Color(0.2, 1.0, 0.4) if low_graphics_mode else Color(1.0, 0.4, 0.4), Vector2(90, 32), 12)
		btn_gfx.pressed.connect(func():
			low_graphics_mode = not low_graphics_mode
			btn_gfx.text = "[ BẬT ]" if low_graphics_mode else "[ TẮT ]"
			btn_gfx.modulate = Color(0.2, 1.0, 0.4) if low_graphics_mode else Color(1.0, 0.4, 0.4)
			settings_updated.emit(squeak_enabled, bgm_match_enabled, bgm_match_volume, low_graphics_mode)
		)
		gfx_row.add_child(btn_gfx)
		v.add_child(gfx_row)
	else:
		var lbl_pc = Label.new()
		lbl_pc.text = "Cấu hình máy: Đồ họa chất lượng cao mượt mà"
		lbl_pc.add_theme_font_size_override("font_size", 13)
		lbl_pc.modulate = Color(0.3, 0.9, 0.5)
		v.add_child(lbl_pc)
		
	var shk_row = HBoxContainer.new()
	shk_row.mouse_filter = Control.MOUSE_FILTER_PASS
	var shk_lbl = Label.new()
	shk_lbl.text = "Rung màn hình khi SMASH:"
	shk_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shk_lbl.add_theme_font_size_override("font_size", 13)
	shk_row.add_child(shk_lbl)
	
	var btn_shk = _create_clean_button("[ BẬT ]" if screen_shake_enabled else "[ TẮT ]", Color(0.3, 0.9, 0.4), Vector2(90, 32), 12)
	btn_shk.pressed.connect(func():
		screen_shake_enabled = not screen_shake_enabled
		btn_shk.text = "[ BẬT ]" if screen_shake_enabled else "[ TẮT ]"
		btn_shk.modulate = Color(0.3, 0.9, 0.4) if screen_shake_enabled else Color(0.7, 0.7, 0.7)
	)
	shk_row.add_child(btn_shk)
	v.add_child(shk_row)
	
	return v

func _build_settings_account_tab() -> VBoxContainer:
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 14)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var t = Label.new()
	t.text = "HỒ SƠ NGƯỜI CHƠI"
	t.add_theme_font_size_override("font_size", 15)
	t.modulate = Color(0.4, 0.9, 0.6)
	v.add_child(t)
	
	var id_lbl = Label.new()
	id_lbl.text = "UID: KAISER-778902  -  Máy chủ: Châu Á Thái Bình Dương"
	id_lbl.add_theme_font_size_override("font_size", 12)
	id_lbl.modulate = Color(0.75, 0.82, 0.90)
	v.add_child(id_lbl)
	
	var ver_lbl = Label.new()
	ver_lbl.text = "Phiên bản: Kaiser Shuttle v8.3.1 - Bản Tiêu Chuẩn"
	ver_lbl.add_theme_font_size_override("font_size", 12)
	ver_lbl.modulate = Color(0.65, 0.72, 0.80)
	v.add_child(ver_lbl)
	
	return v

# Stepped level bar < [][][][][] > (The Spike Signature Audio Slider)
func _create_stepped_volume_row(label_text: String, init_step: int, on_step_change: Callable) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var lbl = Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 13)
	row.add_child(lbl)
	
	var controls_box = HBoxContainer.new()
	controls_box.add_theme_constant_override("separation", 4)
	controls_box.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var cur_val = [init_step]
	var blocks: Array[ColorRect] = []
	
	var btn_left = _create_clean_button("-", Color(1.0, 0.85, 0.3), Vector2(28, 28), 14)
	controls_box.add_child(btn_left)
	
	for i in range(5):
		var b = ColorRect.new()
		b.custom_minimum_size = Vector2(16, 12 + i * 4)
		b.size_flags_vertical = Control.SIZE_SHRINK_END
		b.color = Color(1.0, 0.82, 0.25) if i < cur_val[0] else Color(0.2, 0.24, 0.32)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		controls_box.add_child(b)
		blocks.append(b)
		
	var btn_right = _create_clean_button("+", Color(1.0, 0.85, 0.3), Vector2(28, 28), 14)
	controls_box.add_child(btn_right)
	
	var update_visuals = func():
		for j in range(5):
			blocks[j].color = Color(1.0, 0.82, 0.25) if j < cur_val[0] else Color(0.2, 0.24, 0.32)
		on_step_change.call(cur_val[0])
		
	btn_left.pressed.connect(func():
		if cur_val[0] > 0:
			cur_val[0] -= 1
			update_visuals.call()
	)
	btn_right.pressed.connect(func():
		if cur_val[0] < 5:
			cur_val[0] += 1
			update_visuals.call()
	)
	
	row.add_child(controls_box)
	return row

# ==========================================================
# HELPER FACTORY METHODS
# ==========================================================
func _create_card_standee_bg(standee_tex: Texture2D, target_size: Vector2, opacity: float = 0.28) -> TextureRect:
	if not standee_tex:
		return null
	var tr = TextureRect.new()
	var atlas = AtlasTexture.new()
	atlas.atlas = standee_tex
	# Cắt nửa trên người (đầu, vai, ngực, thắt lưng)
	atlas.region = Rect2(0, 0, 1024, 850)
	tr.texture = atlas
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.modulate = Color(1.0, 1.0, 1.0, opacity)
	tr.custom_minimum_size = target_size
	tr.size = target_size
	return tr

func _create_character_card(cid: String) -> PanelContainer:
	var data = CHAR_DATA[cid]
	var p = _create_spike_translucent_panel(Vector2(310, 335), 10, Color(data["color"].r, data["color"].g, data["color"].b, 0.50))
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	p.clip_contents = true
	
	if data.has("standee") and data["standee"] != null:
		var s_bg = _create_card_standee_bg(data["standee"], Vector2(310, 335), 0.28)
		if s_bg:
			p.add_child(s_bg)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_bottom", 12)
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_child(m)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	m.add_child(vbox)
	
	var title = Label.new()
	title.text = data["name"]
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = data["color"]
	vbox.add_child(title)
	
	var arch = Label.new()
	arch.text = data["archetype"]
	arch.add_theme_font_size_override("font_size", 11)
	arch.modulate = Color(0.70, 0.80, 0.90, 0.85)
	vbox.add_child(arch)
	
	vbox.add_child(_create_stat_bar("LỰC ĐẬP", data["power"], data["color"]))
	vbox.add_child(_create_stat_bar("TỐC ĐỘ", data["agility"], Color(0.25, 0.85, 1.0)))
	vbox.add_child(_create_stat_bar("KIỂM SOÁT", data["control"], Color(0.35, 0.95, 0.55)))
	vbox.add_child(_create_stat_bar("TÂM LÝ", data["composure"], Color(0.85, 0.55, 1.0)))
	
	vbox.add_child(HSeparator.new())
	
	var skill_title = Label.new()
	skill_title.text = "Tuyệt kỹ: " + data["skill_name"]
	skill_title.add_theme_font_size_override("font_size", 12)
	skill_title.modulate = Color(1.0, 0.85, 0.35)
	vbox.add_child(skill_title)
	
	var skill_desc = Label.new()
	skill_desc.text = data["skill_desc"]
	skill_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_desc.add_theme_font_size_override("font_size", 10)
	skill_desc.modulate = Color(0.75, 0.82, 0.90, 0.85)
	vbox.add_child(skill_desc)
	
	var sp = Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(sp)
	
	var b_row = HBoxContainer.new()
	b_row.add_theme_constant_override("separation", 8)
	b_row.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(b_row)
	
	var btn_p = _create_clean_button("BẠN", Color(0.25, 0.85, 0.45), Vector2(0, 30), 11)
	btn_p.name = "BtnPlayer"
	btn_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_p.pressed.connect(func(): _select_player(cid))
	b_row.add_child(btn_p)
	
	var btn_r = _create_clean_button("ĐỐI THỦ", Color(0.30, 0.70, 1.0), Vector2(0, 30), 11)
	btn_r.name = "BtnRival"
	btn_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_r.pressed.connect(func(): _select_rival(cid))
	b_row.add_child(btn_r)
	
	return p

func _create_stat_bar(stat_name: String, val: int, col: Color) -> HBoxContainer:
	var row = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = stat_name
	lbl.custom_minimum_size = Vector2(75, 0)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.modulate = Color(0.70, 0.75, 0.82)
	row.add_child(lbl)
	
	var bar = ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0, 8)
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = 100
	bar.value = val
	bar.modulate = col
	row.add_child(bar)
	
	var val_lbl = Label.new()
	val_lbl.text = str(val)
	val_lbl.custom_minimum_size = Vector2(24, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 10)
	val_lbl.modulate = col
	row.add_child(val_lbl)
	
	return row

func _create_clean_button(text: String, col: Color, min_size: Vector2, font_size: int = 14) -> Button:
	var b = Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.pressed.connect(b.release_focus)
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.10, 0.13, 0.18, 0.95)
	sb_normal.border_width_left = 1
	sb_normal.border_width_top = 1
	sb_normal.border_width_right = 1
	sb_normal.border_width_bottom = 1
	sb_normal.border_color = Color(col.r * 0.65, col.g * 0.65, col.b * 0.65, 0.65)
	sb_normal.corner_radius_top_left = 6
	sb_normal.corner_radius_top_right = 6
	sb_normal.corner_radius_bottom_right = 6
	sb_normal.corner_radius_bottom_left = 6
	b.add_theme_stylebox_override("normal", sb_normal)
	
	var sb_hover = sb_normal.duplicate()
	sb_hover.bg_color = Color(0.15, 0.20, 0.28, 1.0)
	sb_hover.border_color = col
	b.add_theme_stylebox_override("hover", sb_hover)
	b.add_theme_stylebox_override("focus", sb_hover)
	
	var sb_pressed = sb_normal.duplicate()
	sb_pressed.bg_color = Color(0.20, 0.28, 0.40, 1.0)
	b.add_theme_stylebox_override("pressed", sb_pressed)
	
	var sb_disabled = sb_normal.duplicate()
	sb_disabled.bg_color = Color(0.08, 0.10, 0.14, 0.6)
	sb_disabled.border_color = Color(0.3, 0.35, 0.45, 0.4)
	b.add_theme_stylebox_override("disabled", sb_disabled)
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.50, 0.60, 0.7))
	
	return b

# ==========================================================
# SELECTION & GAME LOGIC METHODS
# ==========================================================
func _select_player(cid: String) -> void:
	selected_player_id = cid
	_update_setup_cards()
	_update_hero_standee()

func _select_rival(cid: String) -> void:
	selected_rival_id = cid
	_update_setup_cards()

func _set_difficulty(diff: int) -> void:
	selected_difficulty = diff
	_update_difficulty_buttons()
	_update_setup_cards()

func _set_target_points(pts: int) -> void:
	selected_target_points = pts
	_update_points_buttons()
	_update_setup_cards()

func _set_match_sets(sets: int) -> void:
	selected_match_sets = sets
	_update_sets_buttons()
	_update_setup_cards()

func _update_difficulty_buttons() -> void:
	if btn_diff_easy:
		btn_diff_easy.modulate = Color(1.2, 1.2, 1.2) if selected_difficulty == 0 else Color(0.60, 0.60, 0.60)
	if btn_diff_medium:
		btn_diff_medium.modulate = Color(1.2, 1.2, 1.2) if selected_difficulty == 1 else Color(0.60, 0.60, 0.60)
	if btn_diff_hard:
		btn_diff_hard.modulate = Color(1.2, 1.2, 1.2) if selected_difficulty == 2 else Color(0.60, 0.60, 0.60)

func _update_points_buttons() -> void:
	if btn_pts_11:
		btn_pts_11.modulate = Color(1.3, 1.3, 1.3) if selected_target_points == 11 else Color(0.60, 0.60, 0.60)
	if btn_pts_15:
		btn_pts_15.modulate = Color(1.3, 1.3, 1.3) if selected_target_points == 15 else Color(0.60, 0.60, 0.60)
	if btn_pts_21:
		btn_pts_21.modulate = Color(1.3, 1.3, 1.3) if selected_target_points == 21 else Color(0.60, 0.60, 0.60)

func _update_sets_buttons() -> void:
	if btn_sets_1:
		btn_sets_1.modulate = Color(1.3, 1.3, 1.3) if selected_match_sets == 1 else Color(0.60, 0.60, 0.60)
	if btn_sets_3:
		btn_sets_3.modulate = Color(1.3, 1.3, 1.3) if selected_match_sets == 3 else Color(0.60, 0.60, 0.60)

func _update_setup_cards() -> void:
	for cid in card_nodes.keys():
		var card = card_nodes[cid] as PanelContainer
		var is_p = (cid == selected_player_id)
		var is_r = (cid == selected_rival_id)
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.09, 0.11, 0.16, 0.95)
		sb.corner_radius_top_left = 8
		sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_right = 8
		sb.corner_radius_bottom_left = 8
		
		if is_p and is_r:
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.border_color = Color(0.90, 0.45, 0.90, 0.90)
		elif is_p:
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.border_color = Color(0.25, 0.90, 0.45, 0.90)
		elif is_r:
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.border_color = Color(0.30, 0.70, 1.0, 0.90)
		else:
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.border_color = Color(0.20, 0.25, 0.32, 0.5)
			
		card.add_theme_stylebox_override("panel", sb)
		
		var btn_p = card.find_child("BtnPlayer", true, false) as Button
		if btn_p:
			btn_p.text = "ĐANG CHỌN" if is_p else "CHỌN RA SÂN"
			btn_p.modulate = Color(0.3, 1.8, 0.5) if is_p else Color(1, 1, 1)
			
		var btn_r = card.find_child("BtnRival", true, false) as Button
		if btn_r:
			btn_r.text = "ĐỐI THỦ CHỌN" if is_r else "CHỌN ĐỐI THỦ"
			btn_r.modulate = Color(0.3, 1.3, 2.5) if is_r else Color(1, 1, 1)
			
	if label_matchup_summary:
		var p_name = CHAR_DATA[selected_player_id]["name"]
		var r_name = CHAR_DATA[selected_rival_id]["name"]
		var diff_str = "DỄ" if selected_difficulty == 0 else ("TRUNG BÌNH" if selected_difficulty == 1 else "ĐỈNH CAO")
		var set_str = "1 SET THẮNG" if selected_match_sets == 1 else "3 SET THẮNG 2"
		label_matchup_summary.text = "KÈO ĐẤU:  BẠN: %s   VS   ĐỐI THỦ: %s   -   ĐỘ KHÓ: %s   -   CHẠM: %d ĐIỂM   -   %s" % [p_name, r_name, diff_str, selected_target_points, set_str]

func _confirm_and_start_match() -> void:
	start_match_requested.emit(selected_player_id, selected_rival_id, selected_difficulty, selected_target_points, selected_match_sets)
	visible = false

# ==========================================================
# NETWORKING & PVP METHODS
# ==========================================================
func set_network_manager(net: PvPNetworkManager) -> void:
	net_manager = net
	if net_manager:
		net_manager.connection_status_changed.connect(_on_net_status_changed)
		net_manager.peer_connected.connect(_on_net_peer_connected)
		net_manager.peer_disconnected.connect(_on_net_peer_disconnected)
		net_manager.ping_updated.connect(_on_net_ping_updated)
		net_manager.packet_received.connect(_on_net_packet_received)

func _load_saved_player_name() -> String:
	if OS.has_feature("web"):
		var js_name = JavaScriptBridge.eval("localStorage.getItem('kaiser_player_name') || ''")
		if js_name is String and not js_name.strip_edges().is_empty():
			return js_name.strip_edges()
	if FileAccess.file_exists("user://player_name.txt"):
		var f = FileAccess.open("user://player_name.txt", FileAccess.READ)
		if f:
			var txt = f.get_as_text().strip_edges()
			if not txt.is_empty():
				return txt
	return "BaoHodaka"

func _save_player_name(name_str: String) -> void:
	var clean = name_str.strip_edges()
	if clean.is_empty(): clean = "BaoHodaka"
	if OS.has_feature("web"):
		JavaScriptBridge.eval("localStorage.setItem('kaiser_player_name', '%s')" % clean)
	var f = FileAccess.open("user://player_name.txt", FileAccess.WRITE)
	if f:
		f.store_string(clean)

func _select_pvp_char(cid: String) -> void:
	pvp_selected_char = cid
	selected_player_id = cid
	_update_pvp_controls()
	_update_hero_standee()
	if pvp_is_connected and net_manager:
		net_manager.send_packet({
			"type": "char_pick",
			"char": pvp_selected_char,
			"player_name": pvp_player_name
		})

func _select_pvp_pts(pts: int) -> void:
	pvp_selected_points = pts
	_update_pvp_controls()
	if pvp_is_connected and net_manager and pvp_is_host:
		net_manager.send_packet({
			"type": "match_config",
			"pts": pvp_selected_points,
			"sets": pvp_selected_sets
		})

func _select_pvp_sets(s_cnt: int) -> void:
	pvp_selected_sets = s_cnt
	_update_pvp_controls()
	if pvp_is_connected and net_manager and pvp_is_host:
		net_manager.send_packet({
			"type": "match_config",
			"pts": pvp_selected_points,
			"sets": pvp_selected_sets
		})

func _update_pvp_controls() -> void:
	for cid in pvp_char_btns.keys():
		var b = pvp_char_btns[cid] as Button
		var is_sel = (cid == pvp_selected_char)
		b.modulate = Color(1.3, 1.3, 1.3) if is_sel else Color(0.55, 0.55, 0.55)
		
	for pts in pvp_pts_btns.keys():
		var b = pvp_pts_btns[pts] as Button
		var is_sel = (pts == pvp_selected_points)
		b.modulate = Color(1.3, 1.3, 1.3) if is_sel else Color(0.55, 0.55, 0.55)
		
	for s_cnt in pvp_sets_btns.keys():
		var b = pvp_sets_btns[s_cnt] as Button
		var is_sel = (s_cnt == pvp_selected_sets)
		b.modulate = Color(1.3, 1.3, 1.3) if is_sel else Color(0.55, 0.55, 0.55)
		
	if pvp_char_desc_lbl:
		var cdata = CHAR_DATA[pvp_selected_char]
		pvp_char_desc_lbl.text = "TUYỂN THỦ: %s - %s" % [cdata["name"], cdata["skill_desc"]]
		pvp_char_desc_lbl.modulate = cdata["color"]

func _generate_room_code() -> String:
	var chars = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
	var code = ""
	for i in range(4):
		code += chars[randi() % chars.length()]
	return code

func _on_host_create_room() -> void:
	pvp_is_host = true
	pvp_current_code = _generate_room_code()
	if pvp_host_code_lbl:
		pvp_host_code_lbl.text = "MÃ: " + pvp_current_code
	if pvp_status_lbl:
		pvp_status_lbl.text = "ĐANG KẾT NỐI MÁY CHỦ..."
		pvp_status_lbl.modulate = Color(1.0, 0.85, 0.3)
	if net_manager:
		net_manager.host_room(pvp_current_code, pvp_selected_char, pvp_selected_points, pvp_selected_sets, pvp_player_name)

func _on_client_join_room() -> void:
	pvp_is_host = false
	var code = pvp_room_input.text.strip_edges().to_upper() if pvp_room_input else ""
	if code.is_empty():
		if pvp_status_lbl:
			pvp_status_lbl.text = "VUI LÒNG NHẬP MÃ PHÒNG VÀO Ô TRÊN"
			pvp_status_lbl.modulate = Color(1.0, 0.4, 0.4)
		if pvp_room_input:
			pvp_room_input.grab_focus()
			_open_room_input_modal()
		return
	pvp_current_code = code
	if net_manager:
		net_manager.join_room(code, pvp_selected_char, pvp_player_name)
		if pvp_status_lbl:
			pvp_status_lbl.text = "ĐANG VÀO PHÒNG: " + code
			pvp_status_lbl.modulate = Color(0.35, 0.75, 1.0)

func _on_spectate_room() -> void:
	var code = pvp_room_input.text.strip_edges().to_upper() if pvp_room_input else ""
	if code.is_empty():
		if pvp_status_lbl:
			pvp_status_lbl.text = "VUI LÒNG NHẬP MÃ PHÒNG ĐỂ THEO DÕI"
			pvp_status_lbl.modulate = Color(1.0, 0.4, 0.4)
		if pvp_room_input:
			pvp_room_input.grab_focus()
			_open_room_input_modal()
		return
	spectate_room_requested.emit(code)
	visible = false
	visible = false

func _on_pvp_start_pressed() -> void:
	if not pvp_is_host or not pvp_is_connected:
		return
	btn_pvp_start.disabled = true
	pvp_first_server = "p1" if (randi() % 2 == 0) else "p2"
	if net_manager:
		net_manager.send_packet({
			"t": "start_match",
			"type": "start_match",
			"first_server": pvp_first_server,
			"pts": pvp_selected_points,
			"sets": pvp_selected_sets
		})
	_start_pvp_countdown()

func _start_pvp_countdown() -> void:
	pvp_is_counting_down = true
	pvp_countdown_timer = 3.0
	if pvp_countdown_lbl:
		pvp_countdown_lbl.text = "TRẬN ĐẤU BẮT ĐẦU TRONG: 3..."
		pvp_countdown_lbl.modulate = Color(1.0, 0.88, 0.3)

func _on_net_status_changed(status: String) -> void:
	if pvp_status_lbl:
		var st_upper = status.to_upper()
		if st_upper == "CONNECTING":
			pvp_status_lbl.text = "ĐANG KẾT NỐI MÁY CHỦ..."
			pvp_status_lbl.modulate = Color(1.0, 0.85, 0.3)
		elif st_upper == "HOSTING":
			pvp_status_lbl.text = "PHÒNG MỞ: ĐANG CHỜ ĐỐI THỦ..."
			pvp_status_lbl.modulate = Color(0.25, 0.90, 0.55)
		elif st_upper == "CONNECTED":
			pvp_is_connected = true
			if pvp_is_host and btn_pvp_start:
				btn_pvp_start.disabled = false
			if not pvp_opponent_name.is_empty() and pvp_opponent_name != "PLAYER 2" and pvp_opponent_name != "ĐỐI THỦ":
				pvp_status_lbl.text = "ĐÃ KẾT NỐI VỚI " + pvp_opponent_name
			else:
				pvp_status_lbl.text = "ĐÃ KẾT NỐI VỚI ĐỐI THỦ"
			pvp_status_lbl.modulate = Color(0.20, 0.95, 0.60)
		else:
			pvp_status_lbl.text = st_upper

func _on_net_peer_connected(is_host_arg: bool = true, _room_code: String = "") -> void:
	pvp_is_connected = true
	if is_host_arg:
		pvp_is_host = true
	if pvp_is_host and btn_pvp_start:
		btn_pvp_start.disabled = false
	if not pvp_opponent_name.is_empty() and pvp_opponent_name != "PLAYER 2" and pvp_opponent_name != "ĐỐI THỦ":
		if pvp_status_lbl:
			pvp_status_lbl.text = "ĐÃ KẾT NỐI VỚI " + pvp_opponent_name
			pvp_status_lbl.modulate = Color(0.20, 0.95, 0.60)
	elif pvp_status_lbl:
		pvp_status_lbl.text = "ĐÃ KẾT NỐI VỚI ĐỐI THỦ"
		pvp_status_lbl.modulate = Color(0.20, 0.95, 0.60)
	if net_manager:
		net_manager.send_packet({
			"type": "char_pick",
			"t": "char_pick",
			"char": pvp_selected_char,
			"player_name": pvp_player_name
		})

func _on_net_peer_disconnected(reason: String = "") -> void:
	pvp_is_connected = false
	if btn_pvp_start:
		btn_pvp_start.disabled = true
	if pvp_status_lbl:
		pvp_status_lbl.text = "ĐỐI THỦ MẤT KẾT NỐI"
		pvp_status_lbl.modulate = Color(0.95, 0.35, 0.35)

func _on_net_ping_updated(ping_ms: int) -> void:
	if pvp_ping_lbl:
		pvp_ping_lbl.text = "Ping: %d ms" % ping_ms

func _on_net_packet_received(pkt: Dictionary) -> void:
	var ptype = str(pkt.get("type", pkt.get("t", "")))
	if ptype == "room_created":
		var srv_code = str(pkt.get("code", pkt.get("room_code", "")))
		if not srv_code.is_empty():
			pvp_current_code = srv_code
			if pvp_host_code_lbl:
				pvp_host_code_lbl.text = "MÃ: " + pvp_current_code
		if pvp_status_lbl:
			pvp_status_lbl.text = "PHÒNG MỞ: ĐANG CHỜ ĐỐI THỦ..."
			pvp_status_lbl.modulate = Color(0.25, 0.90, 0.55)
	elif ptype == "guest_joined":
		pvp_is_connected = true
		pvp_is_host = true
		var g_name = str(pkt.get("guest_name", "")).strip_edges()
		if not g_name.is_empty():
			pvp_opponent_name = g_name
		var g_char = str(pkt.get("guest_char", "")).strip_edges()
		if not g_char.is_empty():
			pvp_opponent_char = g_char
		if pvp_status_lbl:
			pvp_status_lbl.text = "ĐÃ KẾT NỐI VỚI " + pvp_opponent_name
			pvp_status_lbl.modulate = Color(0.20, 0.95, 0.60)
		if btn_pvp_start:
			btn_pvp_start.disabled = false
		if net_manager:
			net_manager.send_packet({
				"type": "char_pick",
				"t": "char_pick",
				"char": pvp_selected_char,
				"player_name": pvp_player_name
			})
	elif ptype == "room_joined":
		pvp_is_connected = true
		pvp_is_host = false
		var h_name = str(pkt.get("host_name", "")).strip_edges()
		if not h_name.is_empty():
			pvp_opponent_name = h_name
		var h_char = str(pkt.get("host_char", "")).strip_edges()
		if not h_char.is_empty():
			pvp_opponent_char = h_char
		pvp_selected_points = int(pkt.get("pts", pvp_selected_points))
		pvp_selected_sets = int(pkt.get("sets", pvp_selected_sets))
		_update_pvp_controls()
		if pvp_status_lbl:
			pvp_status_lbl.text = "ĐÃ KẾT NỐI VỚI " + pvp_opponent_name
			pvp_status_lbl.modulate = Color(0.20, 0.95, 0.60)
		if btn_pvp_start:
			btn_pvp_start.disabled = true
	elif ptype == "char_pick":
		var c_char = str(pkt.get("char", "")).strip_edges()
		if not c_char.is_empty():
			pvp_opponent_char = c_char
		var c_name = str(pkt.get("player_name", "")).strip_edges()
		if not c_name.is_empty():
			pvp_opponent_name = c_name
		if pvp_status_lbl and pvp_is_connected:
			pvp_status_lbl.text = "ĐÃ KẾT NỐI VỚI " + pvp_opponent_name
			pvp_status_lbl.modulate = Color(0.20, 0.95, 0.60)
		if pvp_is_host and btn_pvp_start:
			btn_pvp_start.disabled = false
	elif ptype == "match_config":
		pvp_selected_points = int(pkt.get("pts", 11))
		pvp_selected_sets = int(pkt.get("sets", 1))
		_update_pvp_controls()
	elif ptype == "countdown_start" or ptype == "start_match":
		pvp_first_server = str(pkt.get("first_server", "p1"))
		pvp_selected_points = int(pkt.get("pts", pvp_selected_points))
		pvp_selected_sets = int(pkt.get("sets", pvp_selected_sets))
		if pkt.has("p1_char"):
			if pvp_is_host:
				var p2c = str(pkt.get("p2_char", "")).strip_edges()
				if not p2c.is_empty(): pvp_opponent_char = p2c
				var p2n = str(pkt.get("p2_name", "")).strip_edges()
				if not p2n.is_empty(): pvp_opponent_name = p2n
			else:
				var p1c = str(pkt.get("p1_char", "")).strip_edges()
				if not p1c.is_empty(): pvp_opponent_char = p1c
				var p1n = str(pkt.get("p1_name", "")).strip_edges()
				if not p1n.is_empty(): pvp_opponent_name = p1n
		_start_pvp_countdown()
