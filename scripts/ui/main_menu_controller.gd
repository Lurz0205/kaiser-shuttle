class_name MainMenuController
extends Control

# ==========================================================
# MAIN MENU & MATCH SETUP (MINIMALIST REFINED BADMINTON UI)
# Tinh gọn, tinh tế, mang đậm phong cách giải đấu cầu lông BWF
# ==========================================================

const CustomIcon = preload("res://scripts/ui/custom_icon.gd")

signal start_match_requested(player_char: String, rival_char: String, difficulty: int, target_points: int, match_sets: int)
signal start_pvp_match_requested(room_code: String, is_host: bool, player_char: String, target_points: int, match_sets: int, first_server: String)
signal spectate_room_requested(room_code: String)
signal settings_updated(squeak: bool, bgm_enabled: bool, bgm_vol: float, low_gfx: bool)

enum MenuState {
	TITLE,
	MATCH_SETUP,
	PVP_LOBBY,
	SETTINGS
}

var current_state: MenuState = MenuState.TITLE

# Selected match parameters
var selected_player_id: String = "nishikawa"
var selected_rival_id: String = "wall"
var selected_difficulty: int = 1 # 0: Dễ, 1: Trung bình, 2: Khó
var selected_target_points: int = 11 # 11, 15, hoặc 21
var selected_match_sets: int = 1 # 1 hoặc 3 (Best of 3)

# PvP Parameters
var pvp_panel: Control
var net_manager: PvPNetworkManager = null
var pvp_room_input: LineEdit
var pvp_host_code_lbl: Label
var pvp_status_lbl: Label
var pvp_ping_lbl: Label
var pvp_current_code: String = ""
var pvp_selected_char: String = "nishikawa"
var pvp_selected_points: int = 11
var pvp_selected_sets: int = 1
var pvp_first_server: String = "p1"
var pvp_is_host: bool = false
var pvp_is_connected: bool = false
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

# UI Panels
var title_panel: Control
var setup_panel: Control
var settings_panel: Control

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
		"title": "Tia chớp vàng",
		"archetype": "TẤN CÔNG BÙNG NỔ",
		"color": Color(0.98, 0.82, 0.25, 1.0),
		"icon_type": CustomIcon.IconType.LIGHTNING,
		"power": 98,
		"agility": 78,
		"control": 74,
		"composure": 84,
		"skill_name": "Golden Smash",
		"skill_desc": "[Nội tại] Khi đầy Nộ: Cú SMASH được cưỡng ép 100% PERFECT, sấm sét ngưng đọng thời gian, giảm 50% Accuracy & 30% Thể lực đối phương!"
	},
	"fuji": {
		"name": "FUJI",
		"title": "Cơn lốc xanh",
		"archetype": "KỸ THUẬT BIẾN ẢO",
		"color": Color(0.25, 0.88, 0.60, 1.0),
		"icon_type": CustomIcon.IconType.FEATHER,
		"power": 76,
		"agility": 84,
		"control": 96,
		"composure": 86,
		"skill_name": "Tsubame Gaeshi",
		"skill_desc": "[Nội tại] Cơn lốc xanh: Cú bỏ nhỏ hóa thành Én Lượn lướt sà sát mép lưới cùng lốc xoáy ngọc bích, cắt xoáy hiểm hóc!"
	},
	"wall": {
		"name": "ISABEL",
		"title": "Nữ hoàng của đấu trường La Mã",
		"archetype": "BỨC TƯỜNG PHÒNG THỦ",
		"color": Color(0.30, 0.70, 1.0, 1.0),
		"icon_type": CustomIcon.IconType.SHIELD,
		"power": 74,
		"agility": 88,
		"control": 85,
		"composure": 96,
		"skill_name": "Mirage Shield",
		"skill_desc": "[Nội tại] Khiên La Mã: Hóa giải hoàn toàn đòn smash của đối thủ khi đầy Nộ, bung sâu cuối sân & hồi ngay 20% thể lực!"
	}
}

func _ready() -> void:
	custom_minimum_size = Vector2(1280, 720)
	size = Vector2(1280, 720)
	position = Vector2.ZERO
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	_build_ui()
	switch_state(MenuState.TITLE)

func _process(delta: float) -> void:
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
			start_pvp_match_requested.emit(pvp_current_code, pvp_is_host, pvp_selected_char, pvp_selected_points, pvp_selected_sets, pvp_first_server)
			visible = false

func _draw() -> void:
	if not visible:
		return
		
	# 1. Dark Tournament Arena Backdrop (Tinh tế, 100% che phủ gameplay sàn đấu)
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.06, 0.08, 0.12, 1.0))
	
	# Sân thi đấu thảm xanh BWF mờ ảo phía sau
	var court_rect = Rect2(180, 320, 920, 360)
	draw_rect(court_rect, Color(0.08, 0.14, 0.13, 0.60))
	draw_rect(court_rect, Color(0.20, 0.35, 0.30, 0.40), false, 2.0)
	
	# Vạch kẻ sân badminton tinh giản
	draw_line(Vector2(640, 320), Vector2(640, 680), Color(0.85, 0.90, 0.95, 0.35), 2.0) # Vạch giữa
	draw_line(Vector2(260, 320), Vector2(260, 680), Color(0.85, 0.90, 0.95, 0.20), 1.5)
	draw_line(Vector2(1020, 320), Vector2(1020, 680), Color(0.85, 0.90, 0.95, 0.20), 1.5)
	
	# Ánh sáng dịu nhẹ tập trung giữa sân (Không chớp nháy gây rối mắt)
	draw_circle(Vector2(640, 360), 420.0, Color(0.12, 0.20, 0.32, 0.18))

func switch_state(new_state: MenuState) -> void:
	current_state = new_state
	if title_panel: title_panel.visible = (new_state == MenuState.TITLE)
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
	if settings_panel: settings_panel.visible = (new_state == MenuState.SETTINGS)

func _build_ui() -> void:
	# ----------------------------------------------------
	# 1. TITLE PANEL (MÀN HÌNH CHÍNH TINH GỌN VỚI BANNER ANIME)
	# ----------------------------------------------------
	title_panel = Control.new()
	title_panel.custom_minimum_size = Vector2(1280, 720)
	title_panel.size = Vector2(1280, 720)
	title_panel.position = Vector2.ZERO
	add_child(title_panel)
	
	# Anime Cover Banner Image (Thiếu Niên Cầu Lông)
	var banner_rect = TextureRect.new()
	banner_rect.texture = preload("res://assets/images/menu_banner.png")
	banner_rect.custom_minimum_size = Vector2(1280, 720)
	banner_rect.size = Vector2(1280, 720)
	banner_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	title_panel.add_child(banner_rect)
	
	# Elegant Dark Vignette Overlay: Giữ trọn vẻ đẹp tranh anime nhưng làm dịu mắt và tôn chữ/nút bấm
	var banner_overlay = ColorRect.new()
	banner_overlay.custom_minimum_size = Vector2(1280, 720)
	banner_overlay.size = Vector2(1280, 720)
	banner_overlay.color = Color(0.04, 0.07, 0.14, 0.50)
	title_panel.add_child(banner_overlay)
	
	var title_center = VBoxContainer.new()
	title_center.custom_minimum_size = Vector2(1280, 720)
	title_center.size = Vector2(1280, 720)
	title_center.position = Vector2.ZERO
	title_center.alignment = BoxContainer.ALIGNMENT_CENTER
	title_center.add_theme_constant_override("separation", 18)
	title_panel.add_child(title_center)
	
	# Shuttlecock Vector Icon
	var logo_icon_row = HBoxContainer.new()
	logo_icon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var top_shuttle = CustomIcon.new(CustomIcon.IconType.SHUTTLECOCK, Vector2(48, 48), Color(0.95, 0.85, 0.3))
	logo_icon_row.add_child(top_shuttle)
	title_center.add_child(logo_icon_row)
	
	# Title Text
	var lbl_logo = Label.new()
	lbl_logo.text = "KAISER SHUTTLE"
	lbl_logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_logo.add_theme_font_size_override("font_size", 48)
	lbl_logo.modulate = Color(0.98, 0.95, 0.88, 1.0)
	title_center.add_child(lbl_logo)
	
	var lbl_sub = Label.new()
	lbl_sub.text = "BWF ARCADE BADMINTON"
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.add_theme_font_size_override("font_size", 14)
	lbl_sub.modulate = Color(0.65, 0.75, 0.85, 0.85)
	title_center.add_child(lbl_sub)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	title_center.add_child(spacer)
	
	# Menu Buttons - Tinh gọn, thanh lịch
	var btn_vbox = VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_vbox.add_theme_constant_override("separation", 12)
	title_center.add_child(btn_vbox)
	
	var btn_play = _create_clean_button("BẮT ĐẦU TRANH TÀI (VS AI)", Color(0.95, 0.82, 0.25), Vector2(320, 46), 15)
	btn_play.pressed.connect(func(): switch_state(MenuState.MATCH_SETUP))
	btn_vbox.add_child(btn_play)
	
	var btn_pvp = _create_clean_button("TRANH TÀI ONLINE (PVP 1V1)", Color(0.18, 0.90, 0.75), Vector2(320, 46), 15)
	btn_pvp.pressed.connect(func(): switch_state(MenuState.PVP_LOBBY))
	btn_vbox.add_child(btn_pvp)
	
	var btn_settings = _create_clean_button("CÀI ĐẶT (SETTINGS)", Color(0.40, 0.70, 0.95), Vector2(320, 42), 14)
	btn_settings.pressed.connect(func(): switch_state(MenuState.SETTINGS))
	btn_vbox.add_child(btn_settings)
	
	var btn_quit = _create_clean_button("THOÁT (QUIT)", Color(0.80, 0.35, 0.40), Vector2(320, 40), 13)
	btn_quit.pressed.connect(func(): get_tree().quit())
	btn_vbox.add_child(btn_quit)

	# ----------------------------------------------------
	# 2. MATCH SETUP PANEL (CHỌN TƯỚNG & ĐỘ KHÓ TINH TẾ)
	# ----------------------------------------------------
	setup_panel = Control.new()
	setup_panel.custom_minimum_size = Vector2(1280, 720)
	setup_panel.size = Vector2(1280, 720)
	setup_panel.position = Vector2.ZERO
	setup_panel.visible = false
	add_child(setup_panel)
	
	var setup_box = PanelContainer.new()
	setup_box.custom_minimum_size = Vector2(1040, 580)
	setup_box.size = Vector2(1040, 580)
	setup_box.position = Vector2(120, 70)
	
	var sb_setup = StyleBoxFlat.new()
	sb_setup.bg_color = Color(0.08, 0.10, 0.15, 0.98)
	sb_setup.border_width_left = 1
	sb_setup.border_width_top = 1
	sb_setup.border_width_right = 1
	sb_setup.border_width_bottom = 1
	sb_setup.border_color = Color(0.24, 0.34, 0.48, 0.75)
	sb_setup.corner_radius_top_left = 12
	sb_setup.corner_radius_top_right = 12
	sb_setup.corner_radius_bottom_right = 12
	sb_setup.corner_radius_bottom_left = 12
	sb_setup.shadow_color = Color(0, 0, 0, 0.5)
	sb_setup.shadow_size = 14
	setup_box.add_theme_stylebox_override("panel", sb_setup)
	setup_panel.add_child(setup_box)
	
	var setup_m = MarginContainer.new()
	setup_m.add_theme_constant_override("margin_left", 20)
	setup_m.add_theme_constant_override("margin_top", 16)
	setup_m.add_theme_constant_override("margin_right", 20)
	setup_m.add_theme_constant_override("margin_bottom", 16)
	setup_box.add_child(setup_m)
	
	var setup_vbox = VBoxContainer.new()
	setup_vbox.add_theme_constant_override("separation", 10)
	setup_m.add_child(setup_vbox)
	
	# Header Setup
	var setup_title = Label.new()
	setup_title.text = "THIẾT LẬP TRẬN ĐẤU (MATCH SETUP)"
	setup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	setup_title.add_theme_font_size_override("font_size", 18)
	setup_title.modulate = Color(0.95, 0.88, 0.40)
	setup_vbox.add_child(setup_title)
	
	# 3 Character Cards
	var cards_row = HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 14)
	setup_vbox.add_child(cards_row)
	
	for cid in ["nishikawa", "fuji", "wall"]:
		var card = _create_character_card(cid)
		cards_row.add_child(card)
		card_nodes[cid] = card
		
	# Difficulty Selector Row
	var diff_box = HBoxContainer.new()
	diff_box.alignment = BoxContainer.ALIGNMENT_CENTER
	diff_box.add_theme_constant_override("separation", 10)
	setup_vbox.add_child(diff_box)
	
	var lbl_diff = Label.new()
	lbl_diff.text = "ĐỘ KHÓ AI:"
	lbl_diff.add_theme_font_size_override("font_size", 12)
	lbl_diff.modulate = Color(0.75, 0.82, 0.90)
	diff_box.add_child(lbl_diff)
	
	btn_diff_easy = _create_clean_button("DỄ (EASY)", Color(0.25, 0.85, 0.50), Vector2(110, 32), 11)
	btn_diff_easy.pressed.connect(func(): _set_difficulty(0))
	diff_box.add_child(btn_diff_easy)
	
	btn_diff_medium = _create_clean_button("TRUNG BÌNH (MED)", Color(0.95, 0.80, 0.25), Vector2(130, 32), 11)
	btn_diff_medium.pressed.connect(func(): _set_difficulty(1))
	diff_box.add_child(btn_diff_medium)
	
	btn_diff_hard = _create_clean_button("KHÓ (HARD)", Color(0.95, 0.35, 0.35), Vector2(110, 32), 11)
	btn_diff_hard.pressed.connect(func(): _set_difficulty(2))
	diff_box.add_child(btn_diff_hard)
	
	# Điểm thắng ván đấu (Match Points: 11, 15, hoặc 21)
	var pts_box = HBoxContainer.new()
	pts_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pts_box.add_theme_constant_override("separation", 10)
	setup_vbox.add_child(pts_box)
	
	var lbl_pts = Label.new()
	lbl_pts.text = "ĐIỂM THẮNG (CÁCH 2 ĐIỂM):"
	lbl_pts.add_theme_font_size_override("font_size", 12)
	lbl_pts.modulate = Color(0.75, 0.82, 0.90)
	pts_box.add_child(lbl_pts)
	
	btn_pts_11 = _create_clean_button("11 ĐIỂM", Color(0.3, 0.9, 0.4), Vector2(100, 32), 11)
	btn_pts_11.pressed.connect(func(): _set_target_points(11))
	pts_box.add_child(btn_pts_11)
	
	btn_pts_15 = _create_clean_button("15 ĐIỂM", Color(0.95, 0.80, 0.25), Vector2(100, 32), 11)
	btn_pts_15.pressed.connect(func(): _set_target_points(15))
	pts_box.add_child(btn_pts_15)
	
	btn_pts_21 = _create_clean_button("21 ĐIỂM (BWF)", Color(0.95, 0.40, 0.35), Vector2(120, 32), 11)
	btn_pts_21.pressed.connect(func(): _set_target_points(21))
	pts_box.add_child(btn_pts_21)
	
	# Thể thức Set đấu (1 Set hay 3 Set - Best of 3)
	var sets_box = HBoxContainer.new()
	sets_box.alignment = BoxContainer.ALIGNMENT_CENTER
	sets_box.add_theme_constant_override("separation", 10)
	setup_vbox.add_child(sets_box)
	
	var lbl_sets = Label.new()
	lbl_sets.text = "SỐ SET ĐẤU:"
	lbl_sets.add_theme_font_size_override("font_size", 12)
	lbl_sets.modulate = Color(0.75, 0.82, 0.90)
	sets_box.add_child(lbl_sets)
	
	btn_sets_1 = _create_clean_button("1 SET (CHẠM ĐIỂM)", Color(0.35, 0.85, 1.0), Vector2(140, 32), 11)
	btn_sets_1.pressed.connect(func(): _set_match_sets(1))
	sets_box.add_child(btn_sets_1)
	
	btn_sets_3 = _create_clean_button("3 SET (BEST OF 3)", Color(0.95, 0.85, 0.25), Vector2(150, 32), 11)
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
	setup_vbox.add_child(action_row)
	
	var btn_start_match = _create_clean_button("VÀO SÂN TRANH TÀI (START)", Color(0.95, 0.82, 0.25), Vector2(280, 44), 15)
	btn_start_match.pressed.connect(_confirm_and_start_match)
	action_row.add_child(btn_start_match)
	
	var btn_back_title = _create_clean_button("QUAY LẠI", Color(0.65, 0.70, 0.80), Vector2(110, 44), 13)
	btn_back_title.pressed.connect(func(): switch_state(MenuState.TITLE))
	action_row.add_child(btn_back_title)

	# ----------------------------------------------------
	# 3. SETTINGS PANEL (CÀI ĐẶT)
	# ----------------------------------------------------
	settings_panel = Control.new()
	settings_panel.custom_minimum_size = Vector2(1280, 720)
	settings_panel.size = Vector2(1280, 720)
	settings_panel.position = Vector2.ZERO
	settings_panel.visible = false
	add_child(settings_panel)
	
	var set_box = PanelContainer.new()
	set_box.custom_minimum_size = Vector2(510, 440)
	set_box.size = Vector2(510, 440)
	set_box.position = Vector2(385, 140)
	set_box.add_theme_stylebox_override("panel", sb_setup)
	settings_panel.add_child(set_box)
	
	var set_m = MarginContainer.new()
	set_m.add_theme_constant_override("margin_left", 24)
	set_m.add_theme_constant_override("margin_top", 20)
	set_m.add_theme_constant_override("margin_right", 24)
	set_m.add_theme_constant_override("margin_bottom", 20)
	set_box.add_child(set_m)
	
	var set_vbox = VBoxContainer.new()
	set_vbox.add_theme_constant_override("separation", 16)
	set_m.add_child(set_vbox)
	
	var set_title = Label.new()
	set_title.text = "CÀI ĐẶT TRẬN ĐẤU"
	set_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_title.add_theme_font_size_override("font_size", 16)
	set_title.modulate = Color(0.40, 0.70, 0.95)
	set_vbox.add_child(set_title)
	
	# Toggle Squeak
	var squeak_row = HBoxContainer.new()
	var lbl_sq = Label.new()
	lbl_sq.text = "Tiếng rít giày sàn đấu (Shoe Squeak):"
	lbl_sq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_sq.add_theme_font_size_override("font_size", 13)
	squeak_row.add_child(lbl_sq)
	
	var btn_sq = _create_clean_button("BẬT", Color(0.3, 0.9, 0.4), Vector2(80, 30), 12)
	btn_sq.pressed.connect(func():
		squeak_enabled = not squeak_enabled
		btn_sq.text = "BẬT" if squeak_enabled else "TẮT"
		btn_sq.modulate = Color(0.3, 0.9, 0.4) if squeak_enabled else Color(0.7, 0.7, 0.7)
		settings_updated.emit(squeak_enabled, bgm_match_enabled, bgm_match_volume, low_graphics_mode)
	)
	squeak_row.add_child(btn_sq)
	set_vbox.add_child(squeak_row)
	
	# Toggle BGM Match
	var bgm_row = HBoxContainer.new()
	var lbl_bgm = Label.new()
	lbl_bgm.text = "Nhạc nền trong trận đấu (Match BGM):"
	lbl_bgm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_bgm.add_theme_font_size_override("font_size", 13)
	bgm_row.add_child(lbl_bgm)
	
	var btn_bgm = _create_clean_button("BẬT", Color(0.3, 0.9, 0.4), Vector2(80, 30), 12)
	btn_bgm.name = "BtnBgm"
	btn_bgm.pressed.connect(func():
		bgm_match_enabled = not bgm_match_enabled
		btn_bgm.text = "BẬT" if bgm_match_enabled else "TẮT"
		btn_bgm.modulate = Color(0.3, 0.9, 0.4) if bgm_match_enabled else Color(0.7, 0.7, 0.7)
		settings_updated.emit(squeak_enabled, bgm_match_enabled, bgm_match_volume, low_graphics_mode)
	)
	bgm_row.add_child(btn_bgm)
	set_vbox.add_child(bgm_row)
	
	# BGM Volume Slider
	var bgm_vol_row = HBoxContainer.new()
	var lbl_bgm_vol = Label.new()
	lbl_bgm_vol.name = "LabelBgmVol"
	lbl_bgm_vol.text = "Âm lượng nhạc nền: %d%%" % int(round(bgm_match_volume * 100.0))
	lbl_bgm_vol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_bgm_vol.add_theme_font_size_override("font_size", 13)
	bgm_vol_row.add_child(lbl_bgm_vol)
	
	var slider_bgm = HSlider.new()
	slider_bgm.name = "SliderBgm"
	slider_bgm.custom_minimum_size = Vector2(160, 24)
	slider_bgm.min_value = 0.0
	slider_bgm.max_value = 1.0
	slider_bgm.step = 0.05
	slider_bgm.value = bgm_match_volume
	slider_bgm.value_changed.connect(func(val: float):
		bgm_match_volume = val
		lbl_bgm_vol.text = "Âm lượng nhạc nền: %d%%" % int(round(val * 100.0))
		settings_updated.emit(squeak_enabled, bgm_match_enabled, bgm_match_volume, low_graphics_mode)
	)
	bgm_vol_row.add_child(slider_bgm)
	set_vbox.add_child(bgm_vol_row)
	
	# Low Graphics Mode Toggle (Chế độ cấu hình thấp cho máy yếu)
	var gfx_row = HBoxContainer.new()
	var lbl_gfx = Label.new()
	lbl_gfx.text = "Cấu hình đồ họa (Low Graphics):"
	lbl_gfx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_gfx.add_theme_font_size_override("font_size", 13)
	gfx_row.add_child(lbl_gfx)
	
	var btn_gfx = _create_clean_button("CAO (CHUẨN)", Color(0.3, 0.9, 0.4), Vector2(120, 30), 12)
	btn_gfx.pressed.connect(func():
		low_graphics_mode = not low_graphics_mode
		btn_gfx.text = "THẤP (MƯỢT)" if low_graphics_mode else "CAO (CHUẨN)"
		btn_gfx.modulate = Color(0.95, 0.82, 0.25) if low_graphics_mode else Color(0.3, 0.9, 0.4)
		settings_updated.emit(squeak_enabled, bgm_match_enabled, bgm_match_volume, low_graphics_mode)
	)
	gfx_row.add_child(btn_gfx)
	set_vbox.add_child(gfx_row)
	
	var set_close_row = HBoxContainer.new()
	set_close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	set_vbox.add_child(set_close_row)
	
	var set_close = _create_clean_button("ĐÓNG", Color(0.95, 0.85, 0.25), Vector2(130, 36), 13)
	set_close.pressed.connect(func(): switch_state(MenuState.TITLE))
	set_close_row.add_child(set_close)
	
	_build_pvp_panel(sb_setup)

func _create_character_card(cid: String) -> PanelContainer:
	var data = CHAR_DATA[cid]
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(310, 340)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_bottom", 12)
	p.add_child(m)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	m.add_child(vbox)
	
	# Header Card
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
	
	# Stat bars
	vbox.add_child(_create_stat_bar("LỰC ĐẬP", data["power"], data["color"]))
	vbox.add_child(_create_stat_bar("TỐC ĐỘ", data["agility"], Color(0.25, 0.85, 1.0)))
	vbox.add_child(_create_stat_bar("KIỂM SOÁT", data["control"], Color(0.35, 0.95, 0.55)))
	vbox.add_child(_create_stat_bar("TÂM LÝ", data["composure"], Color(0.85, 0.55, 1.0)))
	
	# Skill Details
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var skill_title = Label.new()
	skill_title.text = "Tuyệt kỹ: " + data["skill_name"]
	skill_title.add_theme_font_size_override("font_size", 12)
	skill_title.modulate = Color(0.95, 0.88, 0.35)
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
	
	# Choice Buttons
	var b_row = HBoxContainer.new()
	b_row.add_theme_constant_override("separation", 8)
	vbox.add_child(b_row)
	
	var btn_p = _create_clean_button("CHỌN PLAYER", Color(0.25, 0.85, 0.45), Vector2(0, 30), 11)
	btn_p.name = "BtnPlayer"
	btn_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_p.pressed.connect(func(): _select_player(cid))
	b_row.add_child(btn_p)
	
	var btn_r = _create_clean_button("CHỌN AI", Color(0.30, 0.70, 1.0), Vector2(0, 30), 11)
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
	
	return b

func _select_player(cid: String) -> void:
	selected_player_id = cid
	_update_setup_cards()

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
			btn_p.text = "[BẠN ĐANG CHỌN]" if is_p else "CHỌN CHO PLAYER"
			btn_p.modulate = Color(0.3, 1.8, 0.5) if is_p else Color(1, 1, 1)
			
		var btn_r = card.find_child("BtnRival", true, false) as Button
		if btn_r:
			btn_r.text = "[AI ĐANG CHỌN]" if is_r else "CHỌN CHO AI"
			btn_r.modulate = Color(0.3, 1.3, 2.5) if is_r else Color(1, 1, 1)
			
	if label_matchup_summary:
		var p_name = CHAR_DATA[selected_player_id]["name"]
		var r_name = CHAR_DATA[selected_rival_id]["name"]
		var diff_str = "DỄ" if selected_difficulty == 0 else ("TRUNG BÌNH" if selected_difficulty == 1 else "KHÓ")
		var set_str = "1 SET" if selected_match_sets == 1 else "3 SET (BEST OF 3)"
		label_matchup_summary.text = "KÈO ĐẤU:  [PLAYER: %s]   VS   [AI: %s]   •   ĐỘ KHÓ: [%s]   •   CHẠM: [%d ĐIỂM]   •   [%s]" % [p_name, r_name, diff_str, selected_target_points, set_str]

func _confirm_and_start_match() -> void:
	start_match_requested.emit(selected_player_id, selected_rival_id, selected_difficulty, selected_target_points, selected_match_sets)
	visible = false

func set_network_manager(net: PvPNetworkManager) -> void:
	net_manager = net
	if net_manager:
		net_manager.connection_status_changed.connect(_on_net_status_changed)
		net_manager.peer_connected.connect(_on_net_peer_connected)
		net_manager.peer_disconnected.connect(_on_net_peer_disconnected)
		net_manager.ping_updated.connect(_on_net_ping_updated)
		net_manager.packet_received.connect(_on_net_packet_received)

func _build_pvp_panel(sb_setup: StyleBoxFlat) -> void:
	pvp_panel = Control.new()
	pvp_panel.custom_minimum_size = Vector2(1280, 720)
	pvp_panel.size = Vector2(1280, 720)
	pvp_panel.position = Vector2.ZERO
	pvp_panel.visible = false
	add_child(pvp_panel)
	
	var pvp_box = PanelContainer.new()
	pvp_box.custom_minimum_size = Vector2(1060, 600)
	pvp_box.size = Vector2(1060, 600)
	pvp_box.position = Vector2(110, 60)
	pvp_box.add_theme_stylebox_override("panel", sb_setup)
	pvp_panel.add_child(pvp_box)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_top", 18)
	m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_bottom", 18)
	pvp_box.add_child(m)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	m.add_child(vbox)
	
	# Header
	var header_row = HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var lbl_title = Label.new()
	lbl_title.text = "TRANH TÀI ONLINE (PVP 1V1 P2P WEBRTC)"
	lbl_title.add_theme_font_size_override("font_size", 20)
	lbl_title.modulate = Color(0.20, 0.90, 0.80)
	header_row.add_child(lbl_title)
	vbox.add_child(header_row)
	
	var lbl_sub = Label.new()
	lbl_sub.text = "Kết nối trực tiếp trình duyệt - trình duyệt qua WebRTC UDP DataChannel. Không độ trễ máy chủ (15-40ms)!"
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.add_theme_font_size_override("font_size", 12)
	lbl_sub.modulate = Color(0.70, 0.80, 0.90, 0.8)
	vbox.add_child(lbl_sub)
	
	# Config row: Character + Points + Sets
	var cfg_row = HBoxContainer.new()
	cfg_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cfg_row.add_theme_constant_override("separation", 24)
	vbox.add_child(cfg_row)
	
	# Character picker
	var char_box = HBoxContainer.new()
	char_box.add_theme_constant_override("separation", 6)
	var lbl_c = Label.new()
	lbl_c.text = "TƯỚNG:"
	lbl_c.add_theme_font_size_override("font_size", 12)
	lbl_c.modulate = Color(0.85, 0.88, 0.92)
	char_box.add_child(lbl_c)
	
	for cid in ["nishikawa", "fuji", "wall"]:
		var b = _create_clean_button(CHAR_DATA[cid]["name"], CHAR_DATA[cid]["color"], Vector2(100, 32), 11)
		b.pressed.connect(func(): _select_pvp_char(cid))
		char_box.add_child(b)
		pvp_char_btns[cid] = b
	cfg_row.add_child(char_box)
	
	# Points picker
	var pts_box = HBoxContainer.new()
	pts_box.add_theme_constant_override("separation", 6)
	var lbl_p = Label.new()
	lbl_p.text = "ĐIỂM:"
	lbl_p.add_theme_font_size_override("font_size", 12)
	pts_box.add_child(lbl_p)
	for pts in [11, 15, 21]:
		var b = _create_clean_button(str(pts) + " ĐIỂM", Color(0.95, 0.82, 0.25), Vector2(75, 32), 11)
		b.pressed.connect(func(): _select_pvp_pts(pts))
		pts_box.add_child(b)
		pvp_pts_btns[pts] = b
	cfg_row.add_child(pts_box)
	
	# Sets picker
	var sets_box = HBoxContainer.new()
	sets_box.add_theme_constant_override("separation", 6)
	var lbl_s = Label.new()
	lbl_s.text = "SỐ SET:"
	lbl_s.add_theme_font_size_override("font_size", 12)
	sets_box.add_child(lbl_s)
	for s_cnt in [1, 3]:
		var b = _create_clean_button("1 SET" if s_cnt == 1 else "BEST OF 3", Color(0.35, 0.75, 1.0), Vector2(85, 32), 11)
		b.pressed.connect(func(): _select_pvp_sets(s_cnt))
		sets_box.add_child(b)
		pvp_sets_btns[s_cnt] = b
	cfg_row.add_child(sets_box)
	
	# Skill description banner below config row
	pvp_char_desc_lbl = Label.new()
	pvp_char_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pvp_char_desc_lbl.add_theme_font_size_override("font_size", 11)
	pvp_char_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(pvp_char_desc_lbl)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Two Action Cards: Host (Left) and Join (Right)
	var cards_row = HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 28)
	vbox.add_child(cards_row)
	
	# Host Card
	var host_card = PanelContainer.new()
	host_card.custom_minimum_size = Vector2(480, 260)
	var sb_card = StyleBoxFlat.new()
	sb_card.bg_color = Color(0.10, 0.14, 0.20, 0.90)
	sb_card.border_width_left = 1
	sb_card.border_width_top = 1
	sb_card.border_width_right = 1
	sb_card.border_width_bottom = 1
	sb_card.border_color = Color(0.20, 0.80, 0.65, 0.5)
	sb_card.corner_radius_top_left = 8
	sb_card.corner_radius_top_right = 8
	sb_card.corner_radius_bottom_right = 8
	sb_card.corner_radius_bottom_left = 8
	host_card.add_theme_stylebox_override("panel", sb_card)
	cards_row.add_child(host_card)
	
	var hm = MarginContainer.new()
	hm.add_theme_constant_override("margin_left", 16)
	hm.add_theme_constant_override("margin_top", 14)
	hm.add_theme_constant_override("margin_right", 16)
	hm.add_theme_constant_override("margin_bottom", 14)
	host_card.add_child(hm)
	
	var hv = VBoxContainer.new()
	hv.add_theme_constant_override("separation", 10)
	hm.add_child(hv)
	
	var h_title = Label.new()
	h_title.text = "CÁCH 1: TẠO PHÒNG (BẠN LÀ CHỦ NHÀ - P1)"
	h_title.add_theme_font_size_override("font_size", 14)
	h_title.modulate = Color(0.25, 0.90, 0.70)
	hv.add_child(h_title)
	
	var h_desc = Label.new()
	h_desc.text = "Tạo phòng và gửi mã cho bạn bè để cùng vào sân đấu (Sân trái P1)."
	h_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h_desc.add_theme_font_size_override("font_size", 11)
	h_desc.modulate = Color(0.70, 0.75, 0.85)
	hv.add_child(h_desc)
	
	var btn_gen_room = _create_clean_button("TẠO MÃ PHÒNG (HOST)", Color(0.25, 0.90, 0.70), Vector2(220, 38), 13)
	btn_gen_room.pressed.connect(_on_host_create_room)
	hv.add_child(btn_gen_room)
	
	var code_row = HBoxContainer.new()
	code_row.add_theme_constant_override("separation", 10)
	pvp_host_code_lbl = Label.new()
	pvp_host_code_lbl.text = "MÃ PHÒNG: ----"
	pvp_host_code_lbl.add_theme_font_size_override("font_size", 22)
	pvp_host_code_lbl.modulate = Color(0.98, 0.85, 0.25)
	code_row.add_child(pvp_host_code_lbl)
	
	var btn_copy = _create_clean_button("SAO CHÉP MÃ", Color(0.85, 0.85, 0.85), Vector2(110, 32), 11)
	btn_copy.pressed.connect(func():
		if not pvp_current_code.is_empty():
			DisplayServer.clipboard_set(pvp_current_code)
			btn_copy.text = "ĐÃ CHÉP!"
	)
	code_row.add_child(btn_copy)
	hv.add_child(code_row)
	
	# Join Card
	var join_card = PanelContainer.new()
	join_card.custom_minimum_size = Vector2(480, 260)
	var sb_jcard = sb_card.duplicate()
	sb_jcard.border_color = Color(0.30, 0.70, 1.0, 0.5)
	join_card.add_theme_stylebox_override("panel", sb_jcard)
	cards_row.add_child(join_card)
	
	var jm = MarginContainer.new()
	jm.add_theme_constant_override("margin_left", 16)
	jm.add_theme_constant_override("margin_top", 14)
	jm.add_theme_constant_override("margin_right", 16)
	jm.add_theme_constant_override("margin_bottom", 14)
	join_card.add_child(jm)
	
	var jv = VBoxContainer.new()
	jv.add_theme_constant_override("separation", 10)
	jm.add_child(jv)
	
	var j_title = Label.new()
	j_title.text = "CÁCH 2: THAM GIA PHÒNG (BẠN LÀ KHÁCH - P2)"
	j_title.add_theme_font_size_override("font_size", 14)
	j_title.modulate = Color(0.35, 0.75, 1.0)
	jv.add_child(j_title)
	
	var j_desc = Label.new()
	j_desc.text = "Nhập mã phòng 4 ký tự do bạn bè gửi để vào thi đấu (Sân phải P2)."
	j_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	j_desc.add_theme_font_size_override("font_size", 11)
	j_desc.modulate = Color(0.70, 0.75, 0.85)
	jv.add_child(j_desc)
	
	var input_row = HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 10)
	
	pvp_room_input = LineEdit.new()
	pvp_room_input.custom_minimum_size = Vector2(180, 38)
	pvp_room_input.placeholder_text = "MÃ (VD: 8899)"
	pvp_room_input.max_length = 6
	pvp_room_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	pvp_room_input.add_theme_font_size_override("font_size", 16)
	input_row.add_child(pvp_room_input)
	
	var btn_join = _create_clean_button("THI ĐẤU (P2)", Color(0.35, 0.75, 1.0), Vector2(110, 38), 12)
	btn_join.pressed.connect(_on_guest_join_room)
	input_row.add_child(btn_join)
	
	var btn_spec = _create_clean_button("👁 XEM (KHÁN GIẢ)", Color(0.85, 0.45, 0.95), Vector2(140, 38), 12)
	btn_spec.pressed.connect(_on_spectate_room)
	input_row.add_child(btn_spec)
	jv.add_child(input_row)
	
	# Status Bar & Back Button
	var status_bar = HBoxContainer.new()
	status_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	status_bar.add_theme_constant_override("separation", 20)
	vbox.add_child(status_bar)
	
	pvp_status_lbl = Label.new()
	pvp_status_lbl.text = "Trạng thái: Sẵn sàng kết nối WebSocket Server"
	pvp_status_lbl.add_theme_font_size_override("font_size", 13)
	pvp_status_lbl.modulate = Color(0.85, 0.90, 0.95)
	status_bar.add_child(pvp_status_lbl)
	
	pvp_ping_lbl = Label.new()
	pvp_ping_lbl.text = "Ping: -- ms"
	pvp_ping_lbl.add_theme_font_size_override("font_size", 13)
	pvp_ping_lbl.modulate = Color(0.20, 0.85, 0.50)
	status_bar.add_child(pvp_ping_lbl)

	# Server URL Config Row
	var server_cfg_row = HBoxContainer.new()
	server_cfg_row.alignment = BoxContainer.ALIGNMENT_CENTER
	server_cfg_row.add_theme_constant_override("separation", 10)
	vbox.add_child(server_cfg_row)

	var lbl_srv = Label.new()
	lbl_srv.text = "SERVER:"
	lbl_srv.add_theme_font_size_override("font_size", 11)
	lbl_srv.modulate = Color(0.7, 0.75, 0.85)
	server_cfg_row.add_child(lbl_srv)

	var input_srv = LineEdit.new()
	input_srv.text = net_manager.server_url if net_manager else "wss://kaiser-shuttle-server.onrender.com"
	input_srv.custom_minimum_size = Vector2(340, 28)
	input_srv.add_theme_font_size_override("font_size", 11)
	input_srv.text_submitted.connect(func(new_url):
		if net_manager:
			net_manager.set_custom_server_url(new_url)
	)
	input_srv.focus_exited.connect(func():
		if net_manager:
			net_manager.set_custom_server_url(input_srv.text)
	)
	server_cfg_row.add_child(input_srv)

	var btn_localhost = _create_clean_button("LOCALHOST", Color(0.8, 0.8, 0.8), Vector2(85, 26), 10)
	btn_localhost.pressed.connect(func():
		input_srv.text = "ws://127.0.0.1:8080"
		if net_manager:
			net_manager.set_custom_server_url("ws://127.0.0.1:8080")
	)
	server_cfg_row.add_child(btn_localhost)

	var btn_render = _create_clean_button("RENDER CLOUD", Color(0.3, 0.8, 0.9), Vector2(100, 26), 10)
	btn_render.pressed.connect(func():
		input_srv.text = "wss://kaiser-shuttle-server.onrender.com"
		if net_manager:
			net_manager.set_custom_server_url("wss://kaiser-shuttle-server.onrender.com")
	)
	server_cfg_row.add_child(btn_render)
	
	# Action buttons & Countdown row
	var action_center = VBoxContainer.new()
	action_center.alignment = BoxContainer.ALIGNMENT_CENTER
	action_center.add_theme_constant_override("separation", 6)
	vbox.add_child(action_center)
	
	pvp_countdown_lbl = Label.new()
	pvp_countdown_lbl.text = ""
	pvp_countdown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pvp_countdown_lbl.add_theme_font_size_override("font_size", 20)
	pvp_countdown_lbl.modulate = Color(1.0, 0.9, 0.2)
	pvp_countdown_lbl.visible = false
	action_center.add_child(pvp_countdown_lbl)
	
	btn_pvp_start = _create_clean_button("▶ BẮT ĐẦU TRẬN ĐẤU (START MATCH)", Color(0.98, 0.85, 0.25), Vector2(340, 46), 15)
	btn_pvp_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_pvp_start.visible = false
	btn_pvp_start.pressed.connect(_on_host_press_start_match)
	action_center.add_child(btn_pvp_start)
	
	var btn_back = _create_clean_button("QUAY LẠI TRANG CHÍNH", Color(0.70, 0.70, 0.75), Vector2(220, 36), 12)
	btn_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_back.pressed.connect(func():
		if net_manager:
			net_manager.disconnect_peer()
		switch_state(MenuState.TITLE)
	)
	action_center.add_child(btn_back)

func _update_pvp_controls() -> void:
	for cid in pvp_char_btns:
		var b = pvp_char_btns[cid]
		b.modulate = Color(1.3, 1.3, 1.3) if cid == pvp_selected_char else Color(0.6, 0.6, 0.6)
	for pts in pvp_pts_btns:
		var b = pvp_pts_btns[pts]
		b.modulate = Color(1.3, 1.3, 1.3) if pts == pvp_selected_points else Color(0.6, 0.6, 0.6)
	for s in pvp_sets_btns:
		var b = pvp_sets_btns[s]
		b.modulate = Color(1.3, 1.3, 1.3) if s == pvp_selected_sets else Color(0.6, 0.6, 0.6)
	if pvp_char_desc_lbl and CHAR_DATA.has(pvp_selected_char):
		var cd = CHAR_DATA[pvp_selected_char]
		pvp_char_desc_lbl.text = "⚡ TUYỆT KỸ [%s - %s]: %s" % [cd["name"], cd["skill_name"], cd["skill_desc"]]
		pvp_char_desc_lbl.modulate = cd["color"]

func _select_pvp_char(cid: String) -> void:
	pvp_selected_char = cid
	_update_pvp_controls()

func _select_pvp_pts(pts: int) -> void:
	pvp_selected_points = pts
	_update_pvp_controls()

func _select_pvp_sets(s_cnt: int) -> void:
	pvp_selected_sets = s_cnt
	_update_pvp_controls()

func _generate_room_code() -> String:
	var chars = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
	var res = ""
	for i in range(4):
		res += chars[randi() % chars.length()]
	return res

func _on_host_create_room() -> void:
	pvp_current_code = _generate_room_code()
	pvp_is_host = true
	pvp_is_connected = false
	pvp_is_counting_down = false
	if btn_pvp_start: btn_pvp_start.visible = false
	if pvp_countdown_lbl: pvp_countdown_lbl.visible = false
	if pvp_host_code_lbl:
		pvp_host_code_lbl.text = "MÃ PHÒNG: " + pvp_current_code
	if pvp_status_lbl:
		pvp_status_lbl.text = "Đang mở phòng [%s] trên WebSocket Server... Hãy gửi mã cho đối thủ!" % pvp_current_code
		pvp_status_lbl.modulate = Color(0.95, 0.85, 0.3)
	if net_manager:
		net_manager.host_room(pvp_current_code, pvp_selected_char, pvp_selected_points, pvp_selected_sets)

func _on_guest_join_room() -> void:
	if not pvp_room_input: return
	var code = pvp_room_input.text.strip_edges().to_upper()
	if code.is_empty():
		if pvp_status_lbl: pvp_status_lbl.text = "Lỗi: Vui lòng nhập mã phòng!"
		return
	pvp_current_code = code
	pvp_is_host = false
	pvp_is_connected = false
	pvp_is_counting_down = false
	if btn_pvp_start: btn_pvp_start.visible = false
	if pvp_countdown_lbl: pvp_countdown_lbl.visible = false
	if pvp_status_lbl:
		pvp_status_lbl.text = "Đang kết nối tới phòng [%s] trên WebSocket Server..." % code
		pvp_status_lbl.modulate = Color(0.3, 0.7, 1.0)
	if net_manager:
		net_manager.join_room(code, pvp_selected_char)

func _on_spectate_room() -> void:
	if not pvp_room_input: return
	var code = pvp_room_input.text.strip_edges().to_upper()
	if code.is_empty():
		if pvp_status_lbl:
			pvp_status_lbl.text = "Lỗi: Vui lòng nhập mã phòng để vào xem!"
			pvp_status_lbl.modulate = Color(1.0, 0.4, 0.4)
		return
	pvp_current_code = code
	pvp_is_host = false
	pvp_is_connected = false
	pvp_is_counting_down = false
	if btn_pvp_start: btn_pvp_start.visible = false
	if pvp_countdown_lbl: pvp_countdown_lbl.visible = false
	if pvp_status_lbl:
		pvp_status_lbl.text = "Đang kết nối xem phòng [%s] trên WebSocket Server..." % code
		pvp_status_lbl.modulate = Color(0.85, 0.45, 0.95)
	spectate_room_requested.emit(code)

func _on_net_status_changed(st: String) -> void:
	if not pvp_status_lbl: return
	match st:
		"hosting":
			pvp_status_lbl.text = "Phòng [%s] đang mở. Đang chờ đối thủ vào..." % pvp_current_code
		"connecting":
			pvp_status_lbl.text = "Đang kết nối tới phòng [%s] qua WebSocket Server..." % pvp_current_code
		"spectating":
			pvp_status_lbl.text = "👁 Đã kết nối với tư cách khán giả phòng [%s]!" % pvp_current_code
			pvp_status_lbl.modulate = Color(0.85, 0.45, 0.95)
		"disconnected":
			pvp_status_lbl.text = "Kết nối đã ngắt."
			pvp_status_lbl.modulate = Color(1.0, 0.4, 0.4)
			if btn_pvp_start: btn_pvp_start.visible = false
			pvp_is_connected = false
		"error":
			pvp_status_lbl.text = "Lỗi kết nối phòng hoặc không tìm thấy phòng."
			pvp_status_lbl.modulate = Color(1.0, 0.4, 0.4)
			if btn_pvp_start: btn_pvp_start.visible = false
			pvp_is_connected = false

func _on_net_peer_connected(is_h: bool, _room: String) -> void:
	pvp_is_connected = true
	pvp_is_host = is_h
	if is_h:
		if pvp_status_lbl:
			pvp_status_lbl.text = "🟢 ĐỐI THỦ ĐÃ VÀO PHÒNG! HÃY BẤM BẮT ĐẦU KHI SẴN SÀNG"
			pvp_status_lbl.modulate = Color(0.2, 1.0, 0.4)
		if btn_pvp_start:
			btn_pvp_start.visible = true
			btn_pvp_start.text = "▶ BẮT ĐẦU TRẬN ĐẤU (START)"
	else:
		if pvp_status_lbl:
			pvp_status_lbl.text = "🟢 ĐÃ VÀO PHÒNG! ĐANG CHỜ CHỦ PHÒNG BẮT ĐẦU..."
			pvp_status_lbl.modulate = Color(0.2, 1.0, 0.4)
		if btn_pvp_start:
			btn_pvp_start.visible = false

func _on_host_press_start_match() -> void:
	if not pvp_is_host or not pvp_is_connected:
		return
	if btn_pvp_start:
		btn_pvp_start.visible = false
	var first_srv = "p1" if randf() < 0.5 else "p2"
	pvp_first_server = first_srv
	if net_manager:
		net_manager.start_match(pvp_selected_points, pvp_selected_sets, first_srv)
	_start_pvp_countdown()

func _on_net_packet_received(data: Dictionary) -> void:
	var t = str(data.get("t", ""))
	if t == "lobby_start" or t == "countdown_start":
		pvp_selected_points = int(data.get("pts", pvp_selected_points))
		pvp_selected_sets = int(data.get("sets", pvp_selected_sets))
		if data.has("first_server"):
			pvp_first_server = str(data.get("first_server"))
		_start_pvp_countdown()

func _start_pvp_countdown() -> void:
	pvp_is_counting_down = true
	pvp_countdown_timer = 3.0
	if pvp_countdown_lbl:
		pvp_countdown_lbl.visible = true
		pvp_countdown_lbl.text = "TRẬN ĐẤU BẮT ĐẦU TRONG: 3..."
	if pvp_status_lbl:
		pvp_status_lbl.text = "🟢 TẤT CẢ SẴN SÀNG! ĐANG VÀO TRẬN..."
		pvp_status_lbl.modulate = Color(0.2, 1.0, 0.4)

func _on_net_peer_disconnected(reason: String) -> void:
	pvp_is_connected = false
	pvp_is_counting_down = false
	if btn_pvp_start: btn_pvp_start.visible = false
	if pvp_countdown_lbl: pvp_countdown_lbl.visible = false
	if pvp_status_lbl:
		pvp_status_lbl.text = "Mất kết nối: " + reason
		pvp_status_lbl.modulate = Color(1.0, 0.4, 0.4)

func _on_net_ping_updated(ping: int) -> void:
	if pvp_ping_lbl:
		pvp_ping_lbl.text = "Ping: %d ms (%s)" % [ping, "SIÊU MƯỢT" if ping < 60 else "ỔN ĐỊNH"]
