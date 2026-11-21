import os
import math
from PIL import Image, ImageDraw, ImageFilter

os.makedirs("assets/icons/skills", exist_ok=True)

CANVAS_SIZE = 512
FINAL_SIZE = 128
SCALE = CANVAS_SIZE // FINAL_SIZE

def create_base_canvas():
    return Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))

def draw_outer_glow_ring(draw, center, radius, color, width=16):
    cx, cy = center
    # Multi-layer glow
    for i in range(4):
        alpha = int(color[3] * (1.0 - i * 0.22))
        w = width + i * 8
        c = (color[0], color[1], color[2], alpha)
        draw.ellipse([cx - radius - i*4, cy - radius - i*4, cx + radius + i*4, cy + radius + i*4], outline=c, width=w)

def render_thunder_spike():
    # Nishikawa: Golden Lightning Spike
    im = create_base_canvas()
    draw = ImageDraw.Draw(im)
    cx, cy = 256, 256
    
    # Outer dark hexagon shield background
    hex_pts = []
    for a in range(6):
        angle = math.radians(a * 60 - 30)
        hex_pts.append((cx + 200 * math.cos(angle), cy + 200 * math.sin(angle)))
    draw.polygon(hex_pts, fill=(20, 24, 35, 230), outline=(255, 215, 60, 220), width=14)
    
    # Inner glow
    draw_outer_glow_ring(draw, (cx, cy), 130, (255, 200, 40, 80), width=24)
    
    # Twin jagged electric lightning bolts
    bolt = [
        (256, 70), (290, 190), (250, 210), (315, 200),
        (210, 440), (250, 290), (195, 305), (230, 180), (180, 195)
    ]
    # Gold outer glow
    for w in [32, 22, 12]:
        draw.line(bolt + [(256, 70)], fill=(255, 170, 20, 90), width=w, joint="curve")
    draw.polygon(bolt, fill=(255, 235, 120, 255), outline=(255, 160, 20, 255), width=8)
    
    # Electric sparks
    for angle_deg in [30, 90, 150, 210, 270, 330]:
        rad = math.radians(angle_deg)
        sx = cx + 140 * math.cos(rad)
        sy = cy + 140 * math.sin(rad)
        draw.ellipse([sx - 12, sy - 12, sx + 12, sy + 12], fill=(255, 255, 220, 240))
        
    return im.resize((FINAL_SIZE, FINAL_SIZE), Image.Resampling.LANCZOS)

def render_wind_feather():
    # Fuji: Cyan Wind Blade & Wing Feather
    im = create_base_canvas()
    draw = ImageDraw.Draw(im)
    cx, cy = 256, 256
    
    # Circular shield
    draw.ellipse([cx - 200, cy - 200, cx + 200, cy + 200], fill=(16, 28, 30, 230), outline=(60, 225, 175, 220), width=14)
    draw_outer_glow_ring(draw, (cx, cy), 130, (40, 230, 180, 80), width=24)
    
    # Elegant curved wind feather blade
    feather_pts = [
        (130, 390), (190, 330), (230, 240), (270, 150), (370, 90),
        (330, 160), (320, 240), (280, 310), (210, 370), (130, 390)
    ]
    draw.polygon(feather_pts, fill=(90, 245, 210, 255), outline=(40, 180, 150, 255), width=8)
    
    # Second sweeping wind stream
    wind_pts = [
        (160, 230), (220, 180), (300, 160), (380, 190),
        (310, 210), (240, 220), (160, 230)
    ]
    draw.polygon(wind_pts, fill=(160, 255, 240, 230))
    # Feather quill shaft
    draw.line([(110, 420), (380, 85)], fill=(240, 255, 255, 255), width=10)
    
    return im.resize((FINAL_SIZE, FINAL_SIZE), Image.Resampling.LANCZOS)

def render_iron_shield():
    # The Wall: Heavy Armored Titanium Crest Shield
    im = create_base_canvas()
    draw = ImageDraw.Draw(im)
    cx, cy = 256, 256
    
    # Shield shape points
    shield_pts = [
        (cx, 75), (395, 125), (375, 305), (cx, 445), (137, 305), (117, 125)
    ]
    # Glow
    draw.polygon(shield_pts, fill=(18, 25, 42, 240), outline=(85, 175, 255, 230), width=16)
    
    # Inner metal plate
    inner_pts = [
        (cx, 115), (360, 155), (345, 285), (cx, 400), (167, 285), (152, 155)
    ]
    draw.polygon(inner_pts, fill=(30, 45, 75, 255), outline=(130, 210, 255, 200), width=8)
    
    # Heavy Cross emblem in center
    draw.line([(cx, 150), (cx, 370)], fill=(120, 200, 255, 255), width=24)
    draw.line([(190, 230), (322, 230)], fill=(120, 200, 255, 255), width=24)
    draw.ellipse([cx - 24, 230 - 24, cx + 24, 230 + 24], fill=(230, 245, 255, 255))
    
    return im.resize((FINAL_SIZE, FINAL_SIZE), Image.Resampling.LANCZOS)

def render_fire_blade():
    # Han Gitae: Fire Blade / Inferno Wings
    im = create_base_canvas()
    draw = ImageDraw.Draw(im)
    cx, cy = 256, 256
    
    draw.ellipse([cx - 200, cy - 200, cx + 200, cy + 200], fill=(32, 18, 14, 230), outline=(255, 110, 45, 220), width=14)
    draw_outer_glow_ring(draw, (cx, cy), 130, (255, 90, 30, 90), width=24)
    
    # Blazing curved scythe flame
    flame1 = [(cx, 410), (160, 330), (150, 200), (220, 140), (256, 75), (292, 140), (362, 200), (352, 330)]
    draw.polygon(flame1, fill=(255, 70, 20, 255), outline=(255, 140, 40, 255), width=8)
    
    # Inner intense flame
    flame2 = [(cx, 380), (190, 300), (190, 210), (cx, 130), (322, 210), (322, 300)]
    draw.polygon(flame2, fill=(255, 205, 50, 255))
    
    # Core bright white flame
    flame3 = [(cx, 350), (225, 290), (cx, 200), (287, 290)]
    draw.polygon(flame3, fill=(255, 255, 220, 255))
    
    return im.resize((FINAL_SIZE, FINAL_SIZE), Image.Resampling.LANCZOS)

def render_dark_void():
    # Raul: Shadow Void & Violet Arc
    im = create_base_canvas()
    draw = ImageDraw.Draw(im)
    cx, cy = 256, 256
    
    draw.ellipse([cx - 200, cy - 200, cx + 200, cy + 200], fill=(22, 15, 32, 230), outline=(190, 80, 240, 220), width=14)
    draw_outer_glow_ring(draw, (cx, cy), 130, (180, 60, 235, 90), width=24)
    
    # Crescent Dark Moon Void
    draw.ellipse([cx - 130, cy - 130, cx + 130, cy + 130], fill=(210, 110, 255, 255))
    draw.ellipse([cx - 85, cy - 110, cx + 145, cy + 120], fill=(20, 14, 30, 255))
    
    # Violet Dark Spark
    for d in range(4):
        ang = math.radians(d * 90 + 45)
        px = cx + 145 * math.cos(ang)
        py = cy + 145 * math.sin(ang)
        draw.line([(cx, cy), (px, py)], fill=(240, 170, 255, 240), width=8)
        draw.ellipse([px - 14, py - 14, px + 14, py + 14], fill=(255, 240, 255, 255))
        
    return im.resize((FINAL_SIZE, FINAL_SIZE), Image.Resampling.LANCZOS)

def render_frost_spike():
    # Sara: Crystal Ice Diamond with Glacial Spikes
    im = create_base_canvas()
    draw = ImageDraw.Draw(im)
    cx, cy = 256, 256
    
    draw.ellipse([cx - 200, cy - 200, cx + 200, cy + 200], fill=(14, 25, 38, 230), outline=(80, 215, 255, 220), width=14)
    draw_outer_glow_ring(draw, (cx, cy), 130, (60, 210, 255, 90), width=24)
    
    # 8-point Ice Snowflake / Glacial Star
    for angle_deg in [0, 45, 90, 135, 180, 225, 270, 315]:
        rad = math.radians(angle_deg)
        x_end = cx + 145 * math.cos(rad)
        y_end = cy + 145 * math.sin(rad)
        draw.line([(cx, cy), (x_end, y_end)], fill=(120, 230, 255, 255), width=12)
        # Small branch
        rad_b1 = rad + 0.5
        rad_b2 = rad - 0.5
        bx = cx + 90 * math.cos(rad)
        by = cy + 90 * math.sin(rad)
        draw.line([(bx, by), (bx + 35 * math.cos(rad_b1), by + 35 * math.sin(rad_b1))], fill=(180, 245, 255, 255), width=8)
        draw.line([(bx, by), (bx + 35 * math.cos(rad_b2), by + 35 * math.sin(rad_b2))], fill=(180, 245, 255, 255), width=8)
        
    # Center diamond
    dia = [(cx, cy - 50), (cx + 50, cy), (cx, cy + 50), (cx - 50, cy)]
    draw.polygon(dia, fill=(240, 255, 255, 255), outline=(80, 200, 255, 255), width=6)
    
    return im.resize((FINAL_SIZE, FINAL_SIZE), Image.Resampling.LANCZOS)

def main():
    icons = {
        "skill_thunder_spike.png": render_thunder_spike(),
        "skill_wind_feather.png": render_wind_feather(),
        "skill_iron_shield.png": render_iron_shield(),
        "skill_fire_blade.png": render_fire_blade(),
        "skill_dark_void.png": render_dark_void(),
        "skill_frost_spike.png": render_frost_spike()
    }
    for fname, img in icons.items():
        out_p = os.path.join("assets/icons/skills", fname)
        img.save(out_p, format="PNG")
        print(f"Generated {out_p}")

if __name__ == "__main__":
    main()
