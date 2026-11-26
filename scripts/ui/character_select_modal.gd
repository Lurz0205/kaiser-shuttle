class_name CharacterSelectModal
extends Control

# ==========================================================
# CHARACTER SELECT MODAL (MÀN HÌNH CHỌN VẬN ĐỘNG VIÊN)
# - Chọn nhân vật cho Player (Trái) và AI Rival (Phải)
# - Hiển thị 3 thẻ tuyển thủ với phong cách, 4 chỉ số và Tuyệt kỹ riêng biệt
# ==========================================================

const CustomIcon = preload("res://scripts/ui/custom_icon.gd")

signal characters_confirmed(player_char_id: String, rival_char_id: String)

var selected_player_id: String = "nishikawa"
var selected_rival_id: String = "wall"

var panel_container: PanelContainer
var label_matchup: Label
var card_nodes: Dictionary = {}

const CHAR_DATA = {
	"nishikawa": {
		"name": "NISHIKAWA",
		"title": "Tia chớp vàng (S+)",
		"archetype": "TẤN CÔNG BÙNG NỔ",
		"color": Color(1.0, 0.78, 0.18, 1.0),
		"icon_type": CustomIcon.IconType.LIGHTNING,
		"power": 98,
		"agility": 78,
		"control": 74,
		"composure": 84,
		"skill_name": "Golden Smash (Flow 100)",
		"skill_desc": "Đập sấm sét cắm sàn, ngưng đọng thời gian 1s, thế giới chuyển trắng đen!"
	},
	"fuji": {
		"name": "FUJI",
		"title": "Cơn lốc xanh (S+)",
		"archetype": "KỸ THUẬT BIẾN ẢO",
		"color": Color(0.2, 0.88, 0.55, 1.0),
		"icon_type": CustomIcon.IconType.FEATHER,
		"power": 82,
		"agility": 92,
		"control": 99,
		"composure": 90,
		"skill_name": "Tsubame Gaeshi (Flow 80)",
		"skill_desc": "Phong Thần S+: Cắt xoáy lốc lướt sà mép lưới, góc lượn gục hiểm sát mép lưới!"
	},
	"wall": {
		"name": "ISABEL",
		"title": "Nữ hoàng đấu trường La Mã (S+)",
		"archetype": "BỨC TƯỜNG PHÒNG THỦ",
		"color": Color(0.25, 0.65, 1.0, 1.0),
		"icon_type": CustomIcon.IconType.SHIELD,
		"power": 74,
		"agility": 88,
		"control": 85,
		"composure": 96,
		"skill_name": "Mirage Shield (Flow 90)",
		"skill_desc": "Khiên La Mã - Hóa giải cú đập smash của đối thủ, bung cầu cao sâu và lập tức hồi 20% thể lực!"
	},
	"gitae": {
		"name": "HAN GITAE",
		"title": "Bão lửa tiên phong (S+)",
		"archetype": "ĐẤU SĨ BÙNG NỔ",
		"color": Color(1.0, 0.42, 0.15, 1.0),
		"icon_type": CustomIcon.IconType.FIRE_BLADE,
		"power": 92,
		"agility": 82,
		"control": 78,
		"composure": 94,
		"skill_name": "Infernal Flame Realm (Flow 100)",
		"skill_desc": "Trong 5s biến nửa sân thành Hỏa Ngục: Hitbox rộng hết nửa sân, cầu dính lửa thiêu đốt đối thủ (-5 Thể lực, -5 Thăng bằng, -5 Accuracy)! Nạp Flow nhanh (+28 Flow/hit) để spam liên tục!"
	},
	"sara": {
		"name": "SARA",
		"title": "Băng giá toàn năng (S+)",
		"archetype": "BIẾN ẢO HƯ KHÔNG",
		"color": Color(0.35, 0.85, 1.0, 1.0),
		"icon_type": CustomIcon.IconType.STAR,
		"power": 80,
		"agility": 96,
		"control": 92,
		"composure": 88,
		"skill_name": "Glacial Frost Domain (Flow 105)",
		"skill_desc": "Trong 10s đóng băng sàn đối phương (chậm 20% tốc độ), biến Hitbox Băng và đánh auto Perfect (0 Flow). Phím Space/Jump hóa thành Dịch chuyển tức thời tới đón cầu!"
	}
}

func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	visible = false
	_build_ui()
	_update_card_styles()

func open(cur_player_id: String = "nishikawa", cur_rival_id: String = "wall") -> void:
	selected_player_id = cur_player_id
	selected_rival_id = cur_rival_id
	_update_card_styles()
	visible = true

func close() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_C:
			close()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_confirm_selection()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_1:
			_select_player("nishikawa")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2:
			_select_player("fuji")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3:
			_select_player("wall")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_4:
			_select_player("gitae")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_5:
			_select_player("sara")
			get_viewport().set_input_as_handled()

func _build_ui() -> void:
	# 1. Dark Backdrop
	var bg = ColorRect.new()
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.color = Color(0.03, 0.04, 0.07, 0.88)
	add_child(bg)
	
	# 2. Centered Modal Box
	panel_container = PanelContainer.new()
	panel_container.anchors_preset = Control.PRESET_CENTER
	panel_container.custom_minimum_size = Vector2(980, 540)
	panel_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.07, 0.09, 0.14, 0.98)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.28, 0.40, 0.65, 0.85)
	style_box.corner_radius_top_left = 16
	style_box.corner_radius_top_right = 16
	style_box.corner_radius_bottom_right = 16
	style_box.corner_radius_bottom_left = 16
	style_box.shadow_color = Color(0, 0, 0, 0.6)
	style_box.shadow_size = 18
	panel_container.add_theme_stylebox_override("panel", style_box)
	add_child(panel_container)
	
	var root_vbox = VBoxContainer.new()
	root_vbox.layout_mode = 2
	root_vbox.add_theme_constant_override("separation", 14)
	
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 24)
	margin_container.add_theme_constant_override("margin_top", 18)
	margin_container.add_theme_constant_override("margin_right", 24)
	margin_container.add_theme_constant_override("margin_bottom", 18)
	margin_container.add_child(root_vbox)
	panel_container.add_child(margin_container)
	
	# Header
	var lbl_title = Label.new()
	lbl_title.text = "CHỌN VẬN ĐỘNG VIÊN (CHARACTER SELECT)"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.modulate = Color(1.0, 0.90, 0.3)
	root_vbox.add_child(lbl_title)
	
	var lbl_subtitle = Label.new()
	lbl_subtitle.text = "Chọn nhân vật cho PLAYER (Bên Trái) và ĐỐI THỦ AI (Bên Phải)"
	lbl_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_subtitle.add_theme_font_size_override("font_size", 13)
	lbl_subtitle.modulate = Color(0.7, 0.8, 0.9, 0.8)
	root_vbox.add_child(lbl_subtitle)
	
	# Scrollable Cards Row (Hỗ trợ mở rộng không giới hạn nhân vật)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(930, 330)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)
	
	var cards_row = HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 16)
	scroll.add_child(cards_row)
	
	for char_id in CHAR_DATA.keys():
		var card = _create_character_card(char_id)
		cards_row.add_child(card)
		card_nodes[char_id] = card
		
	# Matchup Status Label
	label_matchup = Label.new()
	label_matchup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_matchup.add_theme_font_size_override("font_size", 15)
	label_matchup.modulate = Color(1.0, 1.0, 1.0, 0.95)
	root_vbox.add_child(label_matchup)
	
	# Bottom Action Buttons
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	root_vbox.add_child(btn_row)
	
	var btn_start = Button.new()
	btn_start.focus_mode = Control.FOCUS_NONE
	btn_start.pressed.connect(btn_start.release_focus)
	btn_start.text = "BẮT ĐẦU TRẬN ĐẤU"
	btn_start.custom_minimum_size = Vector2(240, 42)
	btn_start.add_theme_font_size_override("font_size", 16)
	btn_start.modulate = Color(1.2, 1.1, 0.5)
	btn_start.pressed.connect(_confirm_selection)
	btn_row.add_child(btn_start)
	
	var btn_close = Button.new()
	btn_close.focus_mode = Control.FOCUS_NONE
	btn_close.pressed.connect(btn_close.release_focus)
	btn_close.text = "ĐÓNG"
	btn_close.custom_minimum_size = Vector2(130, 42)
	btn_close.pressed.connect(close)
	btn_row.add_child(btn_close)

func _create_character_card(char_id: String) -> PanelContainer:
	var data = CHAR_DATA[char_id]
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(270, 310)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	p.add_child(m)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	m.add_child(vbox)
	
	# Header Card
	var h_row = HBoxContainer.new()
	h_row.add_theme_constant_override("separation", 6)
	vbox.add_child(h_row)
	
	var ico = CustomIcon.new(data["icon_type"], Vector2(22, 22), data["color"])
	h_row.add_child(ico)
	
	var title = Label.new()
	title.text = data["name"]
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = data["color"]
	h_row.add_child(title)
	
	var arch = Label.new()
	arch.text = data["archetype"]
	arch.add_theme_font_size_override("font_size", 12)
	arch.modulate = Color(0.75, 0.85, 0.95, 0.85)
	vbox.add_child(arch)
	
	# Stat bars
	vbox.add_child(_create_stat_row("POWER", data["power"], data["color"]))
	vbox.add_child(_create_stat_row("AGILITY", data["agility"], Color(0.2, 0.85, 1.0)))
	vbox.add_child(_create_stat_row("CONTROL", data["control"], Color(0.3, 0.95, 0.5)))
	vbox.add_child(_create_stat_row("COMPOSURE", data["composure"], Color(0.85, 0.5, 1.0)))
	
	# Skill Box
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var skill_title = Label.new()
	skill_title.text = "Tuyệt kỹ: " + data["skill_name"]
	skill_title.add_theme_font_size_override("font_size", 13)
	skill_title.modulate = Color(1.0, 0.90, 0.3)
	vbox.add_child(skill_title)
	
	var skill_desc = Label.new()
	skill_desc.text = data["skill_desc"]
	skill_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_desc.add_theme_font_size_override("font_size", 11)
	skill_desc.modulate = Color(0.8, 0.85, 0.9, 0.75)
	vbox.add_child(skill_desc)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Selection buttons
	var b_row = HBoxContainer.new()
	b_row.alignment = BoxContainer.ALIGNMENT_CENTER
	b_row.add_theme_constant_override("separation", 8)
	vbox.add_child(b_row)
	
	var btn_p = Button.new()
	btn_p.focus_mode = Control.FOCUS_NONE
	btn_p.pressed.connect(btn_p.release_focus)
	btn_p.name = "BtnPlayer"
	btn_p.text = "CHỌN PLAYER"
	btn_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_p.pressed.connect(func(): _select_player(char_id))
	b_row.add_child(btn_p)
	
	var btn_r = Button.new()
	btn_r.focus_mode = Control.FOCUS_NONE
	btn_r.pressed.connect(btn_r.release_focus)
	btn_r.name = "BtnRival"
	btn_r.text = "CHỌN AI"
	btn_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_r.pressed.connect(func(): _select_rival(char_id))
	b_row.add_child(btn_r)
	
	return p

func _create_stat_row(stat_name: String, val: int, col: Color) -> HBoxContainer:
	var row = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = stat_name
	lbl.custom_minimum_size = Vector2(80, 0)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = Color(0.7, 0.75, 0.8)
	row.add_child(lbl)
	
	var bar = ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0, 10)
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = 100
	bar.value = val
	bar.modulate = col
	row.add_child(bar)
	
	var val_lbl = Label.new()
	val_lbl.text = str(val)
	val_lbl.custom_minimum_size = Vector2(25, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 11)
	val_lbl.modulate = col
	row.add_child(val_lbl)
	
	return row

func _select_player(char_id: String) -> void:
	selected_player_id = char_id
	_update_card_styles()

func _select_rival(char_id: String) -> void:
	selected_rival_id = char_id
	_update_card_styles()

func _update_card_styles() -> void:
	for char_id in card_nodes.keys():
		var card = card_nodes[char_id] as PanelContainer
		var is_p = (char_id == selected_player_id)
		var is_r = (char_id == selected_rival_id)
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.09, 0.11, 0.17, 0.95)
		sb.corner_radius_top_left = 10
		sb.corner_radius_top_right = 10
		sb.corner_radius_bottom_right = 10
		sb.corner_radius_bottom_left = 10
		
		if is_p and is_r:
			sb.border_width_left = 3
			sb.border_width_top = 3
			sb.border_width_right = 3
			sb.border_width_bottom = 3
			sb.border_color = Color(0.9, 0.4, 0.9, 0.95)
		elif is_p:
			sb.border_width_left = 3
			sb.border_width_top = 3
			sb.border_width_right = 3
			sb.border_width_bottom = 3
			sb.border_color = Color(0.2, 0.9, 0.4, 0.95) # Xanh lá Player
		elif is_r:
			sb.border_width_left = 3
			sb.border_width_top = 3
			sb.border_width_right = 3
			sb.border_width_bottom = 3
			sb.border_color = Color(0.2, 0.6, 1.0, 0.95) # Xanh lam AI
		else:
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.border_color = Color(0.2, 0.25, 0.35, 0.6)
			
		card.add_theme_stylebox_override("panel", sb)
		
		# Update button states
		var btn_p = card.find_child("BtnPlayer", true, false) as Button
		if btn_p:
			btn_p.text = "ĐANG CHỌN" if is_p else "CHỌN RA SÂN"
			btn_p.modulate = Color(0.4, 2.0, 0.6) if is_p else Color(1, 1, 1)
			
		var btn_r = card.find_child("BtnRival", true, false) as Button
		if btn_r:
			btn_r.text = "ĐỐI THỦ CHỌN" if is_r else "CHỌN ĐỐI THỦ"
			btn_r.modulate = Color(0.4, 1.5, 3.0) if is_r else Color(1, 1, 1)
			
	if label_matchup:
		var p_name = CHAR_DATA[selected_player_id]["name"]
		var r_name = CHAR_DATA[selected_rival_id]["name"]
		label_matchup.text = "KÈO ĐẤU:  BẠN: %s   VS   ĐỐI THỦ: %s" % [p_name, r_name]

func _confirm_selection() -> void:
	characters_confirmed.emit(selected_player_id, selected_rival_id)
	close()
