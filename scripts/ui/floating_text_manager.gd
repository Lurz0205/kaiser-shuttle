class_name FloatingTextManager
extends RefCounted

# ==========================================================
# FLOATING COMBAT TEXT (POPUP CHỮ BAY TINH TẾ)
# - Thay thế banner to giữa màn hình cho PERFECT!
# - Nhảy chữ "PERFECT!" ngay tại vị trí tiếp xúc vợt bay nhẹ lên trên
# ==========================================================

class FloatingItem:
	var text: String
	var pos: Vector2
	var color: Color
	var timer: float = 0.0
	var max_time: float = 0.55
	var font_size: int = 15

var items: Array[FloatingItem] = []

func spawn(p_text: String, p_pos: Vector2, p_color: Color = Color(1.0, 0.92, 0.25), p_font_size: int = 15, p_duration: float = 0.55) -> void:
	var item = FloatingItem.new()
	item.text = p_text
	item.pos = p_pos
	item.color = p_color
	item.font_size = p_font_size
	item.max_time = p_duration
	item.timer = p_duration
	items.append(item)

func update(delta: float) -> bool:
	var need_redraw = false
	var i = items.size() - 1
	while i >= 0:
		var it = items[i]
		it.timer -= delta
		it.pos.y -= delta * 40.0 # Bay nhẹ nhàng lên phía trên
		need_redraw = true
		if it.timer <= 0.0:
			items.remove_at(i)
		i -= 1
	return need_redraw

func draw(canvas: CanvasItem, font: Font = null) -> void:
	var f = font if font else ThemeDB.fallback_font
	if not f:
		return
	for it in items:
		var prog = 1.0 - (it.timer / it.max_time)
		var alpha = clamp(1.0 - pow(prog, 1.5), 0.0, 1.0)
		var shadow_col = Color(0.02, 0.03, 0.05, alpha * 0.85)
		var text_col = Color(it.color.r, it.color.g, it.color.b, alpha)
		
		# Bóng đổ sắc nét
		canvas.draw_string(f, it.pos + Vector2(1.5, 1.5), it.text, HORIZONTAL_ALIGNMENT_CENTER, -1, it.font_size, shadow_col)
		canvas.draw_string(f, it.pos, it.text, HORIZONTAL_ALIGNMENT_CENTER, -1, it.font_size, text_col)
