class_name CustomIcon
extends Control

# ==========================================================
# CUSTOM DRAWN VECTOR ICONS (NO SYSTEM EMOJIS / NO OS ICONS)
# Mathematically rendered crisp vector icons for Kaiser Shuttle
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
	DOT
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

# 1. Play Triangle
func _draw_play(w: float, h: float) -> void:
	var pts = PackedVector2Array([
		Vector2(w * 0.22, h * 0.15),
		Vector2(w * 0.88, h * 0.50),
		Vector2(w * 0.22, h * 0.85)
	])
	draw_colored_polygon(pts, icon_color)
	draw_polyline(pts, Color(icon_color.r, icon_color.g, icon_color.b, 0.4), 1.5)

# 2. Cyber Gear / Settings
func _draw_gear(w: float, h: float) -> void:
	var center = Vector2(w * 0.5, h * 0.5)
	var outer_r = min(w, h) * 0.44
	var inner_r = outer_r * 0.52
	var tooth_len = outer_r * 0.26
	
	# Draw teeth
	var teeth_count = 6
	for i in range(teeth_count):
		var ang = (PI * 2.0 / teeth_count) * i
		var dir = Vector2(cos(ang), sin(ang))
		var norm = Vector2(-dir.y, dir.x)
		var t_half = outer_r * 0.22
		var p1 = center + dir * (outer_r - 2) - norm * t_half
		var p2 = center + dir * (outer_r + tooth_len) - norm * (t_half * 0.7)
		var p3 = center + dir * (outer_r + tooth_len) + norm * (t_half * 0.7)
		var p4 = center + dir * (outer_r - 2) + norm * t_half
		draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), icon_color)
		
	# Draw ring & center cutout
	draw_circle(center, outer_r, icon_color)
	draw_circle(center, inner_r, Color(0.06, 0.08, 0.12, 1.0))
	draw_arc(center, inner_r, 0, PI * 2.0, 16, icon_color, 1.5)

# 3. Close Cross (X)
func _draw_close(w: float, h: float) -> void:
	var pad_x = w * 0.22
	var pad_y = h * 0.22
	draw_line(Vector2(pad_x, pad_y), Vector2(w - pad_x, h - pad_y), icon_color, line_width, true)
	draw_line(Vector2(w - pad_x, pad_y), Vector2(pad_x, h - pad_y), icon_color, line_width, true)

# 4. Lightning Bolt (Nishikawa Emblem)
func _draw_lightning(w: float, h: float) -> void:
	var pts = PackedVector2Array([
		Vector2(w * 0.60, h * 0.05),
		Vector2(w * 0.18, h * 0.52),
		Vector2(w * 0.48, h * 0.52),
		Vector2(w * 0.36, h * 0.95),
		Vector2(w * 0.86, h * 0.44),
		Vector2(w * 0.54, h * 0.44)
	])
	# Outer glow
	draw_polyline(pts, Color(icon_color.r, icon_color.g, icon_color.b, 0.4), 3.0)
	# Body
	draw_colored_polygon(pts, icon_color)
	# Inner sharp core
	var core_pts = PackedVector2Array([
		Vector2(w * 0.58, h * 0.15),
		Vector2(w * 0.32, h * 0.50),
		Vector2(w * 0.52, h * 0.50),
		Vector2(w * 0.44, h * 0.85),
		Vector2(w * 0.76, h * 0.46),
		Vector2(w * 0.54, h * 0.46)
	])
	draw_colored_polygon(core_pts, Color(1.0, 1.0, 0.85, 0.9))

# 5. Feather / Gale Blade (Fuji Emblem)
func _draw_feather(w: float, h: float) -> void:
	# Curved graceful feather
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
	# Feather vane cuts
	draw_line(Vector2(w * 0.18, h * 0.88), Vector2(w * 0.78, h * 0.08), Color(1.0, 1.0, 1.0, 0.8), 1.6, true)
	draw_line(Vector2(w * 0.40, h * 0.55), Vector2(w * 0.65, h * 0.45), Color(1.0, 1.0, 1.0, 0.5), 1.2)
	draw_line(Vector2(w * 0.52, h * 0.38), Vector2(w * 0.75, h * 0.28), Color(1.0, 1.0, 1.0, 0.5), 1.2)

# 6. Aegis Shield (Aoi Emblem)
func _draw_shield(w: float, h: float) -> void:
	var pts = PackedVector2Array([
		Vector2(w * 0.15, h * 0.12),
		Vector2(w * 0.85, h * 0.12),
		Vector2(w * 0.85, h * 0.58),
		Vector2(w * 0.50, h * 0.92),
		Vector2(w * 0.15, h * 0.58)
	])
	draw_colored_polygon(pts, icon_color)
	# Inner crest border
	var inner_pts = PackedVector2Array([
		Vector2(w * 0.24, h * 0.20),
		Vector2(w * 0.76, h * 0.20),
		Vector2(w * 0.76, h * 0.55),
		Vector2(w * 0.50, h * 0.82),
		Vector2(w * 0.24, h * 0.55)
	])
	draw_colored_polygon(inner_pts, Color(icon_color.r * 0.4, icon_color.g * 0.5, icon_color.b * 0.7, 0.95))
	draw_polyline(inner_pts, Color(1.0, 1.0, 1.0, 0.7), 1.4)
	# Center cross line
	draw_line(Vector2(w * 0.5, h * 0.24), Vector2(w * 0.5, h * 0.74), Color(1.0, 1.0, 1.0, 0.85), 1.5)

# 7. Badminton Shuttlecock
func _draw_shuttlecock(w: float, h: float) -> void:
	# Cork (bottom rounded hemisphere)
	var cork_center = Vector2(w * 0.5, h * 0.78)
	var cork_r = w * 0.18
	draw_circle(cork_center, cork_r, Color(0.95, 0.92, 0.85, 1.0))
	
	# Feather cone (flaring upwards)
	var skirt_pts = PackedVector2Array([
		Vector2(w * 0.35, h * 0.72),
		Vector2(w * 0.12, h * 0.18),
		Vector2(w * 0.88, h * 0.18),
		Vector2(w * 0.65, h * 0.72)
	])
	draw_colored_polygon(skirt_pts, Color(0.95, 0.96, 1.0, 0.25))
	
	# Feather spines
	var count = 5
	for i in range(count):
		var t = float(i) / (count - 1)
		var top_x = lerp(w * 0.15, w * 0.85, t)
		var bot_x = lerp(w * 0.38, w * 0.62, t)
		draw_line(Vector2(bot_x, h * 0.72), Vector2(top_x, h * 0.18), icon_color, 1.4, true)
		
	# Band rings
	draw_line(Vector2(w * 0.24, h * 0.48), Vector2(w * 0.76, h * 0.48), Color(0.2, 0.6, 1.0, 0.8), 1.5)
	draw_line(Vector2(w * 0.20, h * 0.34), Vector2(w * 0.80, h * 0.34), Color(0.2, 0.6, 1.0, 0.8), 1.5)

# 8. Character Swap Arrows
func _draw_swap(w: float, h: float) -> void:
	# Top arrow pointing right
	draw_line(Vector2(w * 0.15, h * 0.35), Vector2(w * 0.75, h * 0.35), icon_color, line_width, true)
	draw_line(Vector2(w * 0.60, h * 0.20), Vector2(w * 0.78, h * 0.35), icon_color, line_width, true)
	draw_line(Vector2(w * 0.60, h * 0.50), Vector2(w * 0.78, h * 0.35), icon_color, line_width, true)
	
	# Bottom arrow pointing left
	draw_line(Vector2(w * 0.85, h * 0.65), Vector2(w * 0.25, h * 0.65), icon_color, line_width, true)
	draw_line(Vector2(w * 0.40, h * 0.50), Vector2(w * 0.22, h * 0.65), icon_color, line_width, true)
	draw_line(Vector2(w * 0.40, h * 0.80), Vector2(w * 0.22, h * 0.65), icon_color, line_width, true)

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
	draw_line(p1, p2, icon_color, line_width + 1.0, true)
	draw_line(p2, p3, icon_color, line_width + 1.0, true)

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
	var inner_pts = PackedVector2Array([
		Vector2(w * 0.5, h * 0.30),
		Vector2(w * 0.65, h * 0.55),
		Vector2(w * 0.50, h * 0.82),
		Vector2(w * 0.35, h * 0.55)
	])
	draw_colored_polygon(inner_pts, Color(1.0, 1.0, 0.4, 0.9))

# 12. Clean Glowing Pip/Dot
func _draw_dot(w: float, h: float) -> void:
	var center = Vector2(w * 0.5, h * 0.5)
	var r = min(w, h) * 0.38
	draw_circle(center, r + 2.0, Color(icon_color.r, icon_color.g, icon_color.b, 0.35))
	draw_circle(center, r, icon_color)
	draw_circle(center, r * 0.4, Color.WHITE)
