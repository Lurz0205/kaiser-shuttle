class_name CustomIcon
extends Control

# ==========================================================
# CUSTOM DRAWN VECTOR ICONS (NO SYSTEM EMOJIS / NO OS ICONS)
# Tinh tế, tối giản, thanh lịch mang phong cách thể thao classic
# Tự vẽ 100% bằng CanvasItem _draw() - Không dùng font ngoài, không lag
# ==========================================================

enum IconType {
	NONE,
	PLAY,
	GEAR,
	CLOSE,
	LIGHTNING,
	FEATHER,
	SHIELD,
	SHUTTLECOCK,
	SWAP,
	STAR,
	CHECK,
	FIRE_BLADE,
	DOT,
	LOCK,
	COIN,
	TICKET,
	RACQUETS_CROSS,
	TROPHY,
	BOOK_STORY,
	TARGET_TRAINING,
	PENCIL,
	HOME,
	SHOP,
	QUEST,
	ROSTER,
	SOUND,
	DISPLAY,
	GAMEPAD,
	USER
}

@export var icon_type: IconType = IconType.NONE:
	set(val):
		icon_type = val
		queue_redraw()

@export var icon_color: Color = Color.WHITE:
	set(val):
		icon_color = val
		queue_redraw()

@export var glow_color: Color = Color(1, 1, 1, 0.3):
	set(val):
		glow_color = val
		queue_redraw()

@export var line_width: float = 2.0:
	set(val):
		line_width = val
		queue_redraw()

func _init(p_type: IconType = IconType.NONE, p_size: Vector2 = Vector2(24, 24), p_color: Color = Color.WHITE) -> void:
	icon_type = p_type
	custom_minimum_size = p_size
	size = p_size
	icon_color = p_color
	mouse_filter = MOUSE_FILTER_IGNORE

func _draw() -> void:
	var w = size.x
	var h = size.y
	if w <= 1.0 or h <= 1.0:
		return
		
	match icon_type:
		IconType.PLAY:
			_draw_play(w, h)
		IconType.GEAR:
			_draw_gear(w, h)
		IconType.CLOSE:
			_draw_close(w, h)
		IconType.LIGHTNING:
			_draw_lightning(w, h)
		IconType.FEATHER:
			_draw_feather(w, h)
		IconType.SHIELD:
			_draw_shield(w, h)
		IconType.SHUTTLECOCK:
			_draw_shuttlecock(w, h)
		IconType.SWAP:
			_draw_swap(w, h)
		IconType.STAR:
			_draw_star(w, h)
		IconType.CHECK:
			_draw_check(w, h)
		IconType.FIRE_BLADE:
			_draw_fire_blade(w, h)
		IconType.DOT:
			_draw_dot(w, h)
		IconType.LOCK:
			_draw_lock(w, h)
		IconType.COIN:
			_draw_coin(w, h)
		IconType.TICKET:
			_draw_ticket(w, h)
		IconType.RACQUETS_CROSS:
			_draw_racquets_cross(w, h)
		IconType.TROPHY:
			_draw_trophy(w, h)
		IconType.BOOK_STORY:
			_draw_book_story(w, h)
		IconType.TARGET_TRAINING:
			_draw_target_training(w, h)
		IconType.PENCIL:
			_draw_pencil(w, h)
		IconType.HOME:
			_draw_home(w, h)
		IconType.SHOP:
			_draw_shop(w, h)
		IconType.QUEST:
			_draw_quest(w, h)
		IconType.ROSTER:
			_draw_roster(w, h)
		IconType.SOUND:
			_draw_sound(w, h)
		IconType.DISPLAY:
			_draw_display(w, h)
		IconType.GAMEPAD:
			_draw_gamepad(w, h)
		IconType.USER:
			_draw_user(w, h)

# 1. Play Triangle
func _draw_play(w: float, h: float) -> void:
	var pts = PackedVector2Array([
		Vector2(w * 0.24, h * 0.16),
		Vector2(w * 0.86, h * 0.50),
		Vector2(w * 0.24, h * 0.84)
	])
	draw_colored_polygon(pts, icon_color)

# 2. Classic Minimal Gear
func _draw_gear(w: float, h: float) -> void:
	var center = Vector2(w * 0.5, h * 0.5)
	var outer_r = min(w, h) * 0.42
	var inner_r = outer_r * 0.48
	var tooth_len = outer_r * 0.24
	var teeth_count = 6
	for i in range(teeth_count):
		var ang = (PI * 2.0 / teeth_count) * i
		var dir = Vector2(cos(ang), sin(ang))
		var norm = Vector2(-dir.y, dir.x)
		var t_half = outer_r * 0.22
		var p1 = center + dir * (outer_r - 1) - norm * t_half
		var p2 = center + dir * (outer_r + tooth_len) - norm * (t_half * 0.65)
		var p3 = center + dir * (outer_r + tooth_len) + norm * (t_half * 0.65)
		var p4 = center + dir * (outer_r - 1) + norm * t_half
		draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), icon_color)
		
	draw_circle(center, outer_r, icon_color)
	draw_circle(center, inner_r, Color(0.08, 0.10, 0.14, 1.0))

# 3. Close Cross (X)
func _draw_close(w: float, h: float) -> void:
	var pad_x = w * 0.22
	var pad_y = h * 0.22
	draw_line(Vector2(pad_x, pad_y), Vector2(w - pad_x, h - pad_y), icon_color, line_width, true)
	draw_line(Vector2(w - pad_x, pad_y), Vector2(pad_x, h - pad_y), icon_color, line_width, true)

# 4. Lightning Bolt (Nishikawa)
func _draw_lightning(w: float, h: float) -> void:
	var pts = PackedVector2Array([
		Vector2(w * 0.60, h * 0.05),
		Vector2(w * 0.18, h * 0.52),
		Vector2(w * 0.48, h * 0.52),
		Vector2(w * 0.36, h * 0.95),
		Vector2(w * 0.86, h * 0.44),
		Vector2(w * 0.54, h * 0.44)
	])
	draw_colored_polygon(pts, icon_color)

# 5. Feather (Fuji)
func _draw_feather(w: float, h: float) -> void:
	var pts = PackedVector2Array([
		Vector2(w * 0.18, h * 0.88),
		Vector2(w * 0.28, h * 0.62),
		Vector2(w * 0.44, h * 0.32),
		Vector2(w * 0.78, h * 0.08),
		Vector2(w * 0.82, h * 0.24),
		Vector2(w * 0.72, h * 0.54),
		Vector2(w * 0.52, h * 0.78),
		Vector2(w * 0.32, h * 0.88)
	])
	draw_colored_polygon(pts, icon_color)
	draw_line(Vector2(w * 0.18, h * 0.88), Vector2(w * 0.78, h * 0.08), Color(1.0, 1.0, 1.0, 0.8), 1.5, true)

# 6. Shield (Isabel / The Wall)
func _draw_shield(w: float, h: float) -> void:
	var pts = PackedVector2Array([
		Vector2(w * 0.16, h * 0.14),
		Vector2(w * 0.84, h * 0.14),
		Vector2(w * 0.84, h * 0.56),
		Vector2(w * 0.50, h * 0.90),
		Vector2(w * 0.16, h * 0.56)
	])
	draw_colored_polygon(pts, icon_color)
	draw_line(Vector2(w * 0.5, h * 0.20), Vector2(w * 0.5, h * 0.76), Color(0.1, 0.15, 0.22, 0.9), 1.8)

# 7. Badminton Shuttlecock
func _draw_shuttlecock(w: float, h: float) -> void:
	# Cork (bottom rounded hemisphere)
	var cork_center = Vector2(w * 0.5, h * 0.78)
	var cork_r = w * 0.16
	draw_circle(cork_center, cork_r, Color(0.96, 0.94, 0.86, 1.0))
	
	# Feather cone outline
	var skirt_pts = PackedVector2Array([
		Vector2(w * 0.35, h * 0.72),
		Vector2(w * 0.12, h * 0.18),
		Vector2(w * 0.88, h * 0.18),
		Vector2(w * 0.65, h * 0.72)
	])
	draw_colored_polygon(skirt_pts, Color(icon_color.r, icon_color.g, icon_color.b, 0.30))
	
	# Feather spines
	var count = 5
	for i in range(count):
		var t = float(i) / (count - 1)
		var top_x = lerp(w * 0.16, w * 0.84, t)
		var bot_x = lerp(w * 0.38, w * 0.62, t)
		draw_line(Vector2(bot_x, h * 0.72), Vector2(top_x, h * 0.18), icon_color, 1.4, true)
		
	# Band rings
	draw_line(Vector2(w * 0.24, h * 0.48), Vector2(w * 0.76, h * 0.48), icon_color, 1.2)
	draw_line(Vector2(w * 0.20, h * 0.32), Vector2(w * 0.80, h * 0.32), icon_color, 1.2)

# 8. Character Swap Arrows
func _draw_swap(w: float, h: float) -> void:
	draw_line(Vector2(w * 0.15, h * 0.35), Vector2(w * 0.75, h * 0.35), icon_color, line_width, true)
	draw_line(Vector2(w * 0.58, h * 0.20), Vector2(w * 0.78, h * 0.35), icon_color, line_width, true)
	draw_line(Vector2(w * 0.58, h * 0.50), Vector2(w * 0.78, h * 0.35), icon_color, line_width, true)
	
	draw_line(Vector2(w * 0.85, h * 0.65), Vector2(w * 0.25, h * 0.65), icon_color, line_width, true)
	draw_line(Vector2(w * 0.42, h * 0.50), Vector2(w * 0.22, h * 0.65), icon_color, line_width, true)
	draw_line(Vector2(w * 0.42, h * 0.80), Vector2(w * 0.22, h * 0.65), icon_color, line_width, true)

# 9. 5-Point Star
func _draw_star(w: float, h: float) -> void:
	var center = Vector2(w * 0.5, h * 0.5)
	var r_out = min(w, h) * 0.46
	var r_in = r_out * 0.42
	var pts = PackedVector2Array()
	for i in range(10):
		var ang = -PI * 0.5 + i * (PI / 5.0)
		var r = r_out if (i % 2 == 0) else r_in
		pts.append(center + Vector2(cos(ang), sin(ang)) * r)
	draw_colored_polygon(pts, icon_color)

# 10. Checkmark
func _draw_check(w: float, h: float) -> void:
	var p1 = Vector2(w * 0.18, h * 0.52)
	var p2 = Vector2(w * 0.42, h * 0.78)
	var p3 = Vector2(w * 0.85, h * 0.22)
	draw_line(p1, p2, icon_color, line_width + 0.8, true)
	draw_line(p2, p3, icon_color, line_width + 0.8, true)

# 11. Flame Blade
func _draw_fire_blade(w: float, h: float) -> void:
	var pts = PackedVector2Array([
		Vector2(w * 0.5, h * 0.05),
		Vector2(w * 0.75, h * 0.35),
		Vector2(w * 0.85, h * 0.70),
		Vector2(w * 0.50, h * 0.95),
		Vector2(w * 0.15, h * 0.70),
		Vector2(w * 0.25, h * 0.35)
	])
	draw_colored_polygon(pts, icon_color)

# 12. Dot
func _draw_dot(w: float, h: float) -> void:
	var center = Vector2(w * 0.5, h * 0.5)
	var r = min(w, h) * 0.38
	draw_circle(center, r, icon_color)

# 13. Classic Padlock (Ổ khóa vẽ tay)
func _draw_lock(w: float, h: float) -> void:
	# Shackle (U-shaped metal arc on top)
	var shackle_center = Vector2(w * 0.5, h * 0.40)
	var shackle_r = w * 0.24
	draw_arc(shackle_center, shackle_r, PI, PI * 2.0, 16, icon_color, line_width * 1.3)
	draw_line(Vector2(w * 0.5 - shackle_r, h * 0.40), Vector2(w * 0.5 - shackle_r, h * 0.52), icon_color, line_width * 1.3)
	draw_line(Vector2(w * 0.5 + shackle_r, h * 0.40), Vector2(w * 0.5 + shackle_r, h * 0.52), icon_color, line_width * 1.3)
	
	# Lock body (rounded rectangle)
	var body_rect = Rect2(w * 0.20, h * 0.50, w * 0.60, h * 0.44)
	var body_pts = PackedVector2Array([
		Vector2(body_rect.position.x, body_rect.position.y),
		Vector2(body_rect.end.x, body_rect.position.y),
		Vector2(body_rect.end.x, body_rect.end.y),
		Vector2(body_rect.position.x, body_rect.end.y)
	])
	draw_colored_polygon(body_pts, icon_color)
	
	# Keyhole (Dark center cutout: circle + slit)
	var kh_center = Vector2(w * 0.5, h * 0.66)
	draw_circle(kh_center, w * 0.08, Color(0.08, 0.10, 0.14, 1.0))
	draw_line(kh_center, Vector2(w * 0.5, h * 0.82), Color(0.08, 0.10, 0.14, 1.0), 2.2)

# 14. Classic Gold Coin (Đồng xu vàng)
func _draw_coin(w: float, h: float) -> void:
	var center = Vector2(w * 0.5, h * 0.5)
	var r = min(w, h) * 0.44
	draw_circle(center, r, icon_color)
	# Inner decorative ring
	draw_arc(center, r * 0.74, 0, TAU, 24, Color(0.12, 0.14, 0.20, 0.5), 1.4)
	# Center star or emblem
	var star_pts = PackedVector2Array()
	for i in range(8):
		var ang = i * (PI / 4.0)
		var rad = (r * 0.45) if (i % 2 == 0) else (r * 0.22)
		star_pts.append(center + Vector2(cos(ang), sin(ang)) * rad)
	draw_colored_polygon(star_pts, Color(0.12, 0.14, 0.20, 0.7))

# 15. Classic Tournament Ticket (Vé thi đấu)
func _draw_ticket(w: float, h: float) -> void:
	var rect = Rect2(w * 0.12, h * 0.22, w * 0.76, h * 0.56)
	var pts = PackedVector2Array([
		Vector2(rect.position.x, rect.position.y),
		Vector2(rect.end.x, rect.position.y),
		Vector2(rect.end.x, rect.end.y),
		Vector2(rect.position.x, rect.end.y)
	])
	draw_colored_polygon(pts, icon_color)
	# Notches on sides
	draw_circle(Vector2(rect.position.x, h * 0.5), h * 0.12, Color(0.08, 0.10, 0.15, 1.0))
	draw_circle(Vector2(rect.end.x, h * 0.5), h * 0.12, Color(0.08, 0.10, 0.15, 1.0))
	# Dashed perforations
	draw_line(Vector2(w * 0.38, rect.position.y + 4), Vector2(w * 0.38, rect.end.y - 4), Color(0.08, 0.10, 0.15, 0.8), 1.2)

# 16. Crossed Badminton Racquets (Đấu đối kháng 1v1 PvP)
func _draw_racquets_cross(w: float, h: float) -> void:
	# Racquet 1: top-left to bot-right
	var c1 = Vector2(w * 0.28, h * 0.28)
	var r_head = min(w, h) * 0.20
	draw_arc(c1, r_head, 0, TAU, 18, icon_color, 1.8)
	# String lines in head
	draw_line(Vector2(c1.x - r_head * 0.6, c1.y), Vector2(c1.x + r_head * 0.6, c1.y), icon_color, 1.0)
	draw_line(Vector2(c1.x, c1.y - r_head * 0.6), Vector2(c1.x, c1.y + r_head * 0.6), icon_color, 1.0)
	# Shaft and grip
	var shaft_start1 = c1 + Vector2(r_head * 0.7, r_head * 0.7)
	var shaft_end1 = Vector2(w * 0.85, h * 0.85)
	draw_line(shaft_start1, shaft_end1, icon_color, 1.8)
	draw_line(shaft_end1 - Vector2(w * 0.15, h * 0.15), shaft_end1, Color(1.0, 1.0, 1.0, 0.85), 2.8)

	# Racquet 2: top-right to bot-left
	var c2 = Vector2(w * 0.72, h * 0.28)
	draw_arc(c2, r_head, 0, TAU, 18, icon_color, 1.8)
	draw_line(Vector2(c2.x - r_head * 0.6, c2.y), Vector2(c2.x + r_head * 0.6, c2.y), icon_color, 1.0)
	draw_line(Vector2(c2.x, c2.y - r_head * 0.6), Vector2(c2.x, c2.y + r_head * 0.6), icon_color, 1.0)
	var shaft_start2 = c2 + Vector2(-r_head * 0.7, r_head * 0.7)
	var shaft_end2 = Vector2(w * 0.15, h * 0.85)
	draw_line(shaft_start2, shaft_end2, icon_color, 1.8)
	draw_line(shaft_end2 - Vector2(-w * 0.15, h * 0.15), shaft_end2, Color(1.0, 1.0, 1.0, 0.85), 2.8)

# 17. Classic Trophy (Cúp vô địch)
func _draw_trophy(w: float, h: float) -> void:
	# Cup bowl
	var pts_cup = PackedVector2Array([
		Vector2(w * 0.28, h * 0.18),
		Vector2(w * 0.72, h * 0.18),
		Vector2(w * 0.68, h * 0.52),
		Vector2(w * 0.50, h * 0.64),
		Vector2(w * 0.32, h * 0.52)
	])
	draw_colored_polygon(pts_cup, icon_color)
	# Handles on both sides
	draw_arc(Vector2(w * 0.24, h * 0.35), h * 0.14, PI * 0.5, PI * 1.5, 12, icon_color, 1.8)
	draw_arc(Vector2(w * 0.76, h * 0.35), h * 0.14, -PI * 0.5, PI * 0.5, 12, icon_color, 1.8)
	# Stem
	draw_line(Vector2(w * 0.5, h * 0.64), Vector2(w * 0.5, h * 0.78), icon_color, 2.5)
	# Base
	var base_rect = Rect2(w * 0.30, h * 0.78, w * 0.40, h * 0.12)
	draw_rect(base_rect, icon_color)

# 18. Story Book (Cuốn sách cốt truyện)
func _draw_book_story(w: float, h: float) -> void:
	# Open book pages
	var left_page = PackedVector2Array([
		Vector2(w * 0.50, h * 0.25),
		Vector2(w * 0.16, h * 0.20),
		Vector2(w * 0.16, h * 0.78),
		Vector2(w * 0.50, h * 0.86)
	])
	var right_page = PackedVector2Array([
		Vector2(w * 0.50, h * 0.25),
		Vector2(w * 0.84, h * 0.20),
		Vector2(w * 0.84, h * 0.78),
		Vector2(w * 0.50, h * 0.86)
	])
	draw_colored_polygon(left_page, icon_color)
	draw_colored_polygon(right_page, Color(icon_color.r * 0.85, icon_color.g * 0.85, icon_color.b * 0.85, icon_color.a))
	# Spine
	draw_line(Vector2(w * 0.50, h * 0.22), Vector2(w * 0.50, h * 0.88), Color(0.1, 0.12, 0.18, 0.8), 2.0)

# 19. Target Training (Bia tập luyện)
func _draw_target_training(w: float, h: float) -> void:
	var center = Vector2(w * 0.5, h * 0.5)
	var r = min(w, h) * 0.44
	draw_arc(center, r, 0, TAU, 24, icon_color, 1.8)
	draw_arc(center, r * 0.62, 0, TAU, 20, icon_color, 1.5)
	draw_circle(center, r * 0.26, icon_color)
	# Crosshairs
	draw_line(Vector2(center.x - r * 1.1, center.y), Vector2(center.x + r * 1.1, center.y), icon_color, 1.2)
	draw_line(Vector2(center.x, center.y - r * 1.1), Vector2(center.x, center.y + r * 1.1), icon_color, 1.2)

# 20. Pencil (Bút chì chỉnh sửa)
func _draw_pencil(w: float, h: float) -> void:
	var pts = PackedVector2Array([
		Vector2(w * 0.20, h * 0.80),
		Vector2(w * 0.25, h * 0.65),
		Vector2(w * 0.68, h * 0.22),
		Vector2(w * 0.82, h * 0.36),
		Vector2(w * 0.39, h * 0.79)
	])
	draw_colored_polygon(pts, icon_color)
	# Tip
	var tip = PackedVector2Array([
		Vector2(w * 0.20, h * 0.80),
		Vector2(w * 0.25, h * 0.65),
		Vector2(w * 0.39, h * 0.79)
	])
	draw_colored_polygon(tip, Color(0.12, 0.14, 0.20, 0.8))

# 21. Home (Ngôi nhà / Trang chủ)
func _draw_home(w: float, h: float) -> void:
	var roof_pts = PackedVector2Array([
		Vector2(w * 0.50, h * 0.16),
		Vector2(w * 0.86, h * 0.48),
		Vector2(w * 0.14, h * 0.48)
	])
	draw_colored_polygon(roof_pts, icon_color)
	var body_rect = Rect2(w * 0.24, h * 0.48, w * 0.52, h * 0.38)
	draw_rect(body_rect, icon_color)
	# Door cutout
	var door_rect = Rect2(w * 0.40, h * 0.62, w * 0.20, h * 0.24)
	draw_rect(door_rect, Color(0.08, 0.10, 0.14, 1.0))

# 22. Shop (Cửa hàng / Mái hiên)
func _draw_shop(w: float, h: float) -> void:
	# Awning
	var awning_pts = PackedVector2Array([
		Vector2(w * 0.16, h * 0.26),
		Vector2(w * 0.84, h * 0.26),
		Vector2(w * 0.90, h * 0.48),
		Vector2(w * 0.10, h * 0.48)
	])
	draw_colored_polygon(awning_pts, icon_color)
	# Pillars & counter
	draw_line(Vector2(w * 0.20, h * 0.48), Vector2(w * 0.20, h * 0.82), icon_color, 1.8)
	draw_line(Vector2(w * 0.80, h * 0.48), Vector2(w * 0.80, h * 0.82), icon_color, 1.8)
	draw_line(Vector2(w * 0.14, h * 0.82), Vector2(w * 0.86, h * 0.82), icon_color, 2.0)

# 23. Quest (Tấm bảng nhiệm vụ)
func _draw_quest(w: float, h: float) -> void:
	var board_rect = Rect2(w * 0.20, h * 0.20, w * 0.60, h * 0.68)
	draw_rect(board_rect, icon_color)
	# Clip at top
	draw_rect(Rect2(w * 0.38, h * 0.14, w * 0.24, h * 0.12), Color(0.12, 0.14, 0.20, 0.9))
	# Tasks lines
	draw_line(Vector2(w * 0.30, h * 0.40), Vector2(w * 0.70, h * 0.40), Color(0.08, 0.10, 0.14, 1.0), 1.8)
	draw_line(Vector2(w * 0.30, h * 0.55), Vector2(w * 0.70, h * 0.55), Color(0.08, 0.10, 0.14, 1.0), 1.8)
	draw_line(Vector2(w * 0.30, h * 0.70), Vector2(w * 0.55, h * 0.70), Color(0.08, 0.10, 0.14, 1.0), 1.8)

# 24. Roster (Nhóm cầu thủ)
func _draw_roster(w: float, h: float) -> void:
	# Center player
	draw_circle(Vector2(w * 0.50, h * 0.32), w * 0.14, icon_color)
	var body_pts = PackedVector2Array([
		Vector2(w * 0.28, h * 0.82),
		Vector2(w * 0.36, h * 0.54),
		Vector2(w * 0.64, h * 0.54),
		Vector2(w * 0.72, h * 0.82)
	])
	draw_colored_polygon(body_pts, icon_color)
	# Side heads
	draw_circle(Vector2(w * 0.24, h * 0.42), w * 0.10, Color(icon_color.r, icon_color.g, icon_color.b, 0.75))
	draw_circle(Vector2(w * 0.76, h * 0.42), w * 0.10, Color(icon_color.r, icon_color.g, icon_color.b, 0.75))

# 25. Sound Speaker (Loa âm thanh)
func _draw_sound(w: float, h: float) -> void:
	var pts = PackedVector2Array([
		Vector2(w * 0.20, h * 0.38),
		Vector2(w * 0.38, h * 0.38),
		Vector2(w * 0.62, h * 0.20),
		Vector2(w * 0.62, h * 0.80),
		Vector2(w * 0.38, h * 0.62),
		Vector2(w * 0.20, h * 0.62)
	])
	draw_colored_polygon(pts, icon_color)
	# Sound waves
	draw_arc(Vector2(w * 0.62, h * 0.50), w * 0.16, -PI * 0.3, PI * 0.3, 10, icon_color, 1.6)
	draw_arc(Vector2(w * 0.62, h * 0.50), w * 0.28, -PI * 0.3, PI * 0.3, 12, icon_color, 1.6)

# 26. Display (Màn hình hiển thị)
func _draw_display(w: float, h: float) -> void:
	var screen_rect = Rect2(w * 0.15, h * 0.18, w * 0.70, h * 0.52)
	draw_rect(screen_rect, icon_color, false, 2.0)
	# Stand
	draw_line(Vector2(w * 0.50, h * 0.70), Vector2(w * 0.50, h * 0.84), icon_color, 2.2)
	draw_line(Vector2(w * 0.32, h * 0.84), Vector2(w * 0.68, h * 0.84), icon_color, 2.2)

# 27. Gamepad
func _draw_gamepad(w: float, h: float) -> void:
	var body_rect = Rect2(w * 0.15, h * 0.28, w * 0.70, h * 0.46)
	draw_rect(body_rect, icon_color, false, 2.0)
	# D-Pad cross
	draw_line(Vector2(w * 0.32, h * 0.44), Vector2(w * 0.32, h * 0.58), icon_color, 1.8)
	draw_line(Vector2(w * 0.25, h * 0.51), Vector2(w * 0.39, h * 0.51), icon_color, 1.8)
	# Action buttons
	draw_circle(Vector2(w * 0.64, h * 0.45), 2.2, icon_color)
	draw_circle(Vector2(w * 0.72, h * 0.51), 2.2, icon_color)
	draw_circle(Vector2(w * 0.64, h * 0.57), 2.2, icon_color)

# 28. User Avatar
func _draw_user(w: float, h: float) -> void:
	draw_circle(Vector2(w * 0.50, h * 0.34), w * 0.18, icon_color)
	var body_pts = PackedVector2Array([
		Vector2(w * 0.22, h * 0.84),
		Vector2(w * 0.32, h * 0.56),
		Vector2(w * 0.68, h * 0.56),
		Vector2(w * 0.78, h * 0.84)
	])
	draw_colored_polygon(body_pts, icon_color)
