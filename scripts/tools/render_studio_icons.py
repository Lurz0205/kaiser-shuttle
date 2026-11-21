import os
import math
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_DIR = os.path.abspath("assets/icons")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def create_super_sampled(size=128, factor=4):
    ss = size * factor
    img = Image.new("RGBA", (ss, ss), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    return img, draw, ss

def downsample(img, target_size=128):
    return img.resize((target_size, target_size), Image.Resampling.LANCZOS)

# ---------------------------------------------------------
# 1. Quả cầu lông hoàng kim BWF 3D (Shuttlecock)
# ---------------------------------------------------------
def render_shuttlecock(path, size=128):
    img, draw, S = create_super_sampled(size)
    cx, cy = S * 0.5, S * 0.5
    
    # Cork (Đầu bần tròn ở phía dưới)
    cork_r = S * 0.16
    cork_y = S * 0.76
    
    # Glow sau lưng
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse([cx - S*0.35, cy - S*0.35, cx + S*0.35, cy + S*0.35], fill=(255, 215, 60, 45))
    glow = glow.filter(ImageFilter.GaussianBlur(S * 0.08))
    img.alpha_composite(glow)
    
    # Váy lông vũ (Feather skirt) xòe lên trên
    skirt_pts = [
        (cx - S * 0.14, cork_y - cork_r * 0.4),
        (cx - S * 0.42, S * 0.18),
        (cx + S * 0.42, S * 0.18),
        (cx + S * 0.14, cork_y - cork_r * 0.4)
    ]
    # Nền bán trong suốt của cánh lông
    draw.polygon(skirt_pts, fill=(255, 255, 255, 40))
    
    # Từng nan lông vũ (16 nan lông thanh mảnh)
    num_feathers = 13
    for i in range(num_feathers):
        t = i / (num_feathers - 1)
        top_x = cx - S * 0.38 + t * (S * 0.76)
        top_y = S * 0.18 + math.sin(t * math.pi) * (S * 0.04)
        bot_x = cx - S * 0.12 + t * (S * 0.24)
        bot_y = cork_y - cork_r * 0.3
        
        # Thân cọng lông
        feather_col = (255, 250, 230, 240) if (i % 2 == 0) else (240, 230, 190, 200)
        draw.line([(bot_x, bot_y), (top_x, top_y)], fill=feather_col, width=int(S * 0.022))
        
        # Mép lông trên cùng hình bầu dục
        f_tip_r = S * 0.038
        draw.ellipse([top_x - f_tip_r, top_y - f_tip_r, top_x + f_tip_r, top_y + f_tip_r], fill=(255, 255, 255, 230))
        draw.ellipse([top_x - f_tip_r, top_y - f_tip_r, top_x + f_tip_r, top_y + f_tip_r], outline=(255, 210, 80, 180), width=int(S * 0.008))
        
    # Hai vòng đai chỉ đan ngang (Binding threads)
    for band_y_ratio in [0.38, 0.52]:
        by = S * band_y_ratio
        bw = S * (0.22 + (0.76 - 0.22) * (1.0 - (band_y_ratio - 0.18) / 0.58) * 0.5)
        draw.line([(cx - bw, by), (cx + bw, by)], fill=(255, 180, 40, 230), width=int(S * 0.024))
        draw.line([(cx - bw, by), (cx + bw, by)], fill=(255, 255, 255, 180), width=int(S * 0.010))

    # Băng dính đỏ BWF giữa đế bần và cánh lông
    tape_h = S * 0.04
    draw.rectangle([cx - S * 0.15, cork_y - cork_r - tape_h*0.3, cx + S * 0.15, cork_y - cork_r + tape_h*0.7], fill=(220, 40, 40, 255))
    draw.rectangle([cx - S * 0.15, cork_y - cork_r, cx + S * 0.15, cork_y - cork_r + tape_h*0.2], fill=(255, 215, 60, 255))

    # Đế bần (Cork) 3D có bóng đổ và highlight
    draw.ellipse([cx - cork_r, cork_y - cork_r, cx + cork_r, cork_y + cork_r], fill=(245, 240, 225, 255))
    # Đổ bóng cong 3D cho đế bần
    draw.arc([cx - cork_r, cork_y - cork_r, cx + cork_r, cork_y + cork_r], 0, 180, fill=(180, 160, 130, 255), width=int(S * 0.035))
    # Highlight bóng sáng ngọc trai
    hl_r = cork_r * 0.45
    draw.ellipse([cx - hl_r * 0.6, cork_y - hl_r * 0.9, cx + hl_r * 0.6, cork_y - hl_r * 0.3], fill=(255, 255, 255, 220))

    final = downsample(img, size)
    final.save(path, "PNG")
    print(f"Saved: {path}")

# ---------------------------------------------------------
# 2. Ổ khóa hoàng kim 3D (The Spike Gold Padlock)
# ---------------------------------------------------------
def render_gold_padlock(path, size=128):
    img, draw, S = create_super_sampled(size)
    cx, cy = S * 0.5, S * 0.5
    
    # Còng khóa kim loại chữ U (Shackle)
    shackle_r = S * 0.22
    shackle_cy = S * 0.38
    shackle_th = int(S * 0.09)
    
    # Bạc kim sáng bóng
    draw.arc([cx - shackle_r, shackle_cy - shackle_r, cx + shackle_r, shackle_cy + shackle_r], 180, 360, fill=(230, 235, 245, 255), width=shackle_th)
    draw.line([(cx - shackle_r, shackle_cy), (cx - shackle_r, S * 0.52)], fill=(210, 215, 225, 255), width=shackle_th)
    draw.line([(cx + shackle_r, shackle_cy), (cx + shackle_r, S * 0.52)], fill=(210, 215, 225, 255), width=shackle_th)
    # Highlight kim loại
    draw.arc([cx - shackle_r, shackle_cy - shackle_r, cx + shackle_r, shackle_cy + shackle_r], 210, 330, fill=(255, 255, 255, 255), width=int(shackle_th * 0.35))

    # Thân khóa hoàng kim 3D (Lock body)
    body_w, body_h = S * 0.64, S * 0.46
    bx1, by1 = cx - body_w * 0.5, S * 0.48
    bx2, by2 = cx + body_w * 0.5, by1 + body_h
    corner_r = int(S * 0.08)
    
    # Bóng đổ mềm dưới thân khóa
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle([bx1 - S*0.02, by1 + S*0.04, bx2 + S*0.02, by2 + S*0.06], radius=corner_r, fill=(0, 0, 0, 100))
    shadow = shadow.filter(ImageFilter.GaussianBlur(S * 0.04))
    img.alpha_composite(shadow)
    
    # Thân khóa chính: Gradient mạ vàng
    draw.rounded_rectangle([bx1, by1, bx2, by2], radius=corner_r, fill=(245, 175, 25, 255), outline=(255, 230, 130, 255), width=int(S * 0.024))
    # Bevel highlight trên cùng
    draw.rounded_rectangle([bx1 + S*0.03, by1 + S*0.03, bx2 - S*0.03, by1 + body_h * 0.45], radius=int(corner_r*0.6), fill=(255, 210, 60, 255))
    
    # Lỗ khóa (Keyhole đen huyền bí)
    kh_y = by1 + body_h * 0.52
    kh_r = S * 0.065
    draw.ellipse([cx - kh_r, kh_y - kh_r, cx + kh_r, kh_y + kh_r], fill=(30, 35, 45, 255))
    draw.polygon([(cx - kh_r * 0.55, kh_y), (cx + kh_r * 0.55, kh_y), (cx + kh_r * 0.8, kh_y + kh_r * 1.8), (cx - kh_r * 0.8, kh_y + kh_r * 1.8)], fill=(30, 35, 45, 255))
    draw.ellipse([cx - kh_r * 0.4, kh_y - kh_r * 0.4, cx + kh_r * 0.4, kh_y + kh_r * 0.4], fill=(10, 12, 16, 255))

    final = downsample(img, size)
    final.save(path, "PNG")
    print(f"Saved: {path}")

# ---------------------------------------------------------
# 3. Đồng xu vàng hoàng kim 3D (Gold Coin)
# ---------------------------------------------------------
def render_gold_coin(path, size=128):
    img, draw, S = create_super_sampled(size)
    cx, cy = S * 0.5, S * 0.5
    r = S * 0.42
    
    # Shadow
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.ellipse([cx - r, cy - r + S*0.04, cx + r, cy + r + S*0.04], fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(S * 0.03))
    img.alpha_composite(shadow)
    
    # Vành ngoài vàng đậm
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(230, 150, 15, 255), outline=(255, 225, 110, 255), width=int(S * 0.035))
    # Vòng nhẫn trong sáng bóng
    inner_r = r * 0.82
    draw.ellipse([cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r], fill=(255, 195, 35, 255), outline=(210, 130, 10, 255), width=int(S * 0.02))
    
    # Ngôi sao 4 cánh chạm nổi 3D ở giữa
    star_pts = [
        (cx, cy - inner_r * 0.65),
        (cx + inner_r * 0.22, cy - inner_r * 0.22),
        (cx + inner_r * 0.65, cy),
        (cx + inner_r * 0.22, cy + inner_r * 0.22),
        (cx, cy + inner_r * 0.65),
        (cx - inner_r * 0.22, cy + inner_r * 0.22),
        (cx - inner_r * 0.65, cy),
        (cx - inner_r * 0.22, cy - inner_r * 0.22)
    ]
    draw.polygon(star_pts, fill=(255, 245, 170, 255))
    
    # Glare lấp lánh góc trên trái
    draw.ellipse([cx - inner_r * 0.6, cy - inner_r * 0.65, cx - inner_r * 0.3, cy - inner_r * 0.35], fill=(255, 255, 255, 200))

    final = downsample(img, size)
    final.save(path, "PNG")
    print(f"Saved: {path}")

# ---------------------------------------------------------
# 4. Avatar Profile Cầu thủ Thể thao Pro
# ---------------------------------------------------------
def render_avatar_pro(path, size=128):
    img, draw, S = create_super_sampled(size)
    cx, cy = S * 0.5, S * 0.5
    r = S * 0.44
    
    # Vòng tròn viền mạ vàng
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(25, 32, 45, 255), outline=(255, 205, 50, 255), width=int(S * 0.038))
    
    # Đầu nhân vật (Head)
    head_r = S * 0.18
    head_y = S * 0.36
    draw.ellipse([cx - head_r, head_y - head_r, cx + head_r, head_y + head_r], fill=(255, 218, 185, 255))
    
    # Tóc anime đen vuốt thể thao
    hair_pts = [
        (cx - head_r * 1.1, head_y),
        (cx - head_r * 0.9, head_y - head_r * 1.2),
        (cx - head_r * 0.3, head_y - head_r * 1.3),
        (cx + head_r * 0.4, head_y - head_r * 1.25),
        (cx + head_r * 1.1, head_y),
        (cx + head_r * 0.8, head_y - head_r * 0.5),
        (cx + head_r * 0.3, head_y - head_r * 0.8),
        (cx - head_r * 0.2, head_y - head_r * 0.7),
        (cx - head_r * 0.7, head_y - head_r * 0.4)
    ]
    draw.polygon(hair_pts, fill=(35, 40, 50, 255))
    
    # Băng đô đỏ thể thao
    draw.arc([cx - head_r*1.05, head_y - head_r*0.9, cx + head_r*1.05, head_y + head_r*0.3], 200, 340, fill=(230, 45, 45, 255), width=int(S * 0.05))

    # Thân áo đấu (Jersey)
    jersey_pts = [
        (cx - S * 0.32, S * 0.88),
        (cx - S * 0.22, S * 0.54),
        (cx - S * 0.10, S * 0.52),
        (cx + S * 0.10, S * 0.52),
        (cx + S * 0.22, S * 0.54),
        (cx + S * 0.32, S * 0.88)
    ]
    draw.polygon(jersey_pts, fill=(235, 75, 40, 255))
    # Cổ áo chữ V
    draw.polygon([(cx - S*0.08, S*0.52), (cx + S*0.08, S*0.52), (cx, S*0.62)], fill=(255, 218, 185, 255))

    final = downsample(img, size)
    final.save(path, "PNG")
    print(f"Saved: {path}")

# ---------------------------------------------------------
# 5. Icon 2 cây vợt đan chéo nhau PvP (Crossed Racquets)
# ---------------------------------------------------------
def render_duel_pvp(path, size=128):
    img, draw, S = create_super_sampled(size)
    cx, cy = S * 0.5, S * 0.5
    
    head_r = S * 0.17
    # Vợt 1: Xanh ngọc Cyan (Tây Bắc sang Đông Nam)
    c1 = (S * 0.30, S * 0.30)
    draw.ellipse([c1[0] - head_r, c1[1] - head_r, c1[0] + head_r, c1[1] + head_r], outline=(30, 210, 200, 255), width=int(S * 0.032))
    # Lưới vợt
    for k in [-0.5, 0.0, 0.5]:
        draw.line([(c1[0] - head_r*0.7, c1[1] + k*head_r), (c1[0] + head_r*0.7, c1[1] + k*head_r)], fill=(150, 240, 235, 140), width=int(S * 0.012))
        draw.line([(c1[0] + k*head_r, c1[1] - head_r*0.7), (c1[0] + k*head_r, c1[1] + head_r*0.7)], fill=(150, 240, 235, 140), width=int(S * 0.012))
    # Cán vợt 1
    draw.line([(c1[0] + head_r*0.7, c1[1] + head_r*0.7), (S * 0.85, S * 0.85)], fill=(200, 210, 220, 255), width=int(S * 0.035))
    draw.line([(S * 0.68, S * 0.68), (S * 0.85, S * 0.85)], fill=(30, 210, 200, 255), width=int(S * 0.055))

    # Vợt 2: Vàng Cam Gold (Đông Bắc sang Tây Nam)
    c2 = (S * 0.70, S * 0.30)
    draw.ellipse([c2[0] - head_r, c2[1] - head_r, c2[0] + head_r, c2[1] + head_r], outline=(255, 180, 30, 255), width=int(S * 0.032))
    for k in [-0.5, 0.0, 0.5]:
        draw.line([(c2[0] - head_r*0.7, c2[1] + k*head_r), (c2[0] + head_r*0.7, c2[1] + k*head_r)], fill=(255, 220, 150, 140), width=int(S * 0.012))
        draw.line([(c2[0] + k*head_r, c2[1] - head_r*0.7), (c2[0] + k*head_r, c2[1] + head_r*0.7)], fill=(255, 220, 150, 140), width=int(S * 0.012))
    # Cán vợt 2
    draw.line([(c2[0] - head_r*0.7, c2[1] + head_r*0.7), (S * 0.15, S * 0.85)], fill=(200, 210, 220, 255), width=int(S * 0.035))
    draw.line([(S * 0.32, S * 0.68), (S * 0.15, S * 0.85)], fill=(255, 180, 30, 255), width=int(S * 0.055))

    final = downsample(img, size)
    final.save(path, "PNG")
    print(f"Saved: {path}")

# ---------------------------------------------------------
# 6. Cúp vô địch vàng 3D (Trophy)
# ---------------------------------------------------------
def render_trophy_gold(path, size=128):
    img, draw, S = create_super_sampled(size)
    cx = S * 0.5
    
    # Chén cúp
    cup_pts = [
        (cx - S * 0.28, S * 0.20),
        (cx + S * 0.28, S * 0.20),
        (cx + S * 0.24, S * 0.52),
        (cx, S * 0.64),
        (cx - S * 0.24, S * 0.52)
    ]
    draw.polygon(cup_pts, fill=(255, 195, 35, 255), outline=(255, 235, 140, 255))
    # Quai cúp
    draw.arc([cx - S * 0.38, S * 0.26, cx - S * 0.16, S * 0.52], 90, 270, fill=(240, 170, 20, 255), width=int(S * 0.04))
    draw.arc([cx + S * 0.16, S * 0.26, cx + S * 0.38, S * 0.52], -90, 90, fill=(240, 170, 20, 255), width=int(S * 0.04))
    # Trụ & Đế cúp
    draw.line([(cx, S * 0.64), (cx, S * 0.76)], fill=(210, 145, 15, 255), width=int(S * 0.06))
    draw.rounded_rectangle([cx - S * 0.22, S * 0.76, cx + S * 0.22, S * 0.88], radius=int(S * 0.03), fill=(180, 120, 10, 255), outline=(255, 220, 90, 255), width=int(S * 0.02))

    final = downsample(img, size)
    final.save(path, "PNG")
    print(f"Saved: {path}")

# ---------------------------------------------------------
# 7. Bánh răng cài đặt mạ bạc (Gear)
# ---------------------------------------------------------
def render_gear_silver(path, size=128):
    img, draw, S = create_super_sampled(size)
    cx, cy = S * 0.5, S * 0.5
    outer_r = S * 0.38
    inner_r = S * 0.18
    teeth = 6
    
    for i in range(teeth):
        ang = i * (math.pi * 2.0 / teeth)
        t_w = S * 0.12
        t_len = S * 0.10
        tx = cx + math.cos(ang) * (outer_r + t_len * 0.5)
        ty = cy + math.sin(ang) * (outer_r + t_len * 0.5)
        draw.ellipse([tx - t_w*0.5, ty - t_w*0.5, tx + t_w*0.5, ty + t_w*0.5], fill=(200, 215, 230, 255))
        
    draw.ellipse([cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r], fill=(185, 200, 215, 255), outline=(245, 250, 255, 255), width=int(S * 0.03))
    draw.ellipse([cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r], fill=(20, 25, 35, 255), outline=(130, 145, 160, 255), width=int(S * 0.02))

    final = downsample(img, size)
    final.save(path, "PNG")
    print(f"Saved: {path}")

if __name__ == "__main__":
    render_shuttlecock(os.path.join(OUTPUT_DIR, "icon_shuttlecock_gold.png"))
    render_gold_padlock(os.path.join(OUTPUT_DIR, "icon_padlock_gold.png"))
    render_gold_coin(os.path.join(OUTPUT_DIR, "icon_coin_gold.png"))
    render_avatar_pro(os.path.join(OUTPUT_DIR, "icon_avatar_pro.png"))
    render_duel_pvp(os.path.join(OUTPUT_DIR, "icon_duel_pvp.png"))
    render_trophy_gold(os.path.join(OUTPUT_DIR, "icon_trophy_gold.png"))
    render_gear_silver(os.path.join(OUTPUT_DIR, "icon_gear_silver.png"))
    print("ALL STUDIO ICONS RENDERED SUCCESSFULLY!")
