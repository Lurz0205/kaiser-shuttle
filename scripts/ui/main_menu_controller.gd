class_name MainMenuController
extends Control

# ==========================================================
# MAIN MENU & MATCH SETUP (MINIMALIST REFINED BADMINTON UI)
# Tinh gọn, tinh tế, mang đậm phong cách giải đấu cầu lông BWF
# ==========================================================

const CustomIcon = preload("res://scripts/ui/custom_icon.gd")

signal start_match_requested(player_char: String, rival_char: String, difficulty: int, target_points: int)
signal settings_updated(squeak: bool)

enum MenuState {
	TITLE,
	MATCH_SETUP,
	SETTINGS
}

var current_state: MenuState = MenuState.TITLE

# Selected match parameters
var selected_player_id: String = "nishikawa"
var selected_rival_id: String = "wall"
var selected_difficulty: int = 1 # 0: Dễ, 1: Trung bình, 2: Khó
var selected_target_points: int = 11 # 11, 15, hoặc 21

# Settings parameters
var squeak_enabled: bool = true

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
	
	var btn_play = _create_clean_button("BẮT ĐẦU TRANH TÀI (PLAY)", Color(0.95, 0.82, 0.25), Vector2(300, 46), 15)
	btn_play.pressed.connect(func(): switch_state(MenuState.MATCH_SETUP))
	btn_vbox.add_child(btn_play)
	
	var btn_settings = _create_clean_button("CÀI ĐẶT (SETTINGS)", Color(0.40, 0.70, 0.95), Vector2(300, 42), 14)
	btn_settings.pressed.connect(func(): switch_state(MenuState.SETTINGS))
	btn_vbox.add_child(btn_settings)
	
	var btn_quit = _create_clean_button("THOÁT (QUIT)", Color(0.80, 0.35, 0.40), Vector2(300, 40), 13)
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
	set_box.custom_minimum_size = Vector2(460, 320)
	set_box.size = Vector2(460, 320)
	set_box.position = Vector2(410, 200)
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
		settings_updated.emit(squeak_enabled)
	)
	squeak_row.add_child(btn_sq)
	set_vbox.add_child(squeak_row)
	
	var set_close_row = HBoxContainer.new()
	set_close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	set_vbox.add_child(set_close_row)
	
	var set_close = _create_clean_button("ĐÓNG", Color(0.95, 0.85, 0.25), Vector2(130, 36), 13)
	set_close.pressed.connect(func(): switch_state(MenuState.TITLE))
	set_close_row.add_child(set_close)

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
		label_matchup_summary.text = "KÈO ĐẤU:  [PLAYER: %s]   VS   [AI: %s]   •   ĐỘ KHÓ: [%s]   •   CHẠM: [%d ĐIỂM]" % [p_name, r_name, diff_str, selected_target_points]

func _confirm_and_start_match() -> void:
	start_match_requested.emit(selected_player_id, selected_rival_id, selected_difficulty, selected_target_points)
	visible = false
