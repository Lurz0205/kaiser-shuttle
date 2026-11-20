import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SCALE = 4
FONT_PATH = "C:/Windows/Fonts/segoeuib.ttf"

def get_font(size):
    return ImageFont.truetype(FONT_PATH, int(size * SCALE))

def create_canvas(w, h):
    return Image.new("RGBA", (int(w * SCALE), int(h * SCALE)), (0, 0, 0, 0))

def finalize(img, w, h):
    return img.resize((int(w), int(h)), Image.Resampling.LANCZOS)

def draw_capsule(draw, x1, y1, x2, y2, r, fill, outline=None, width=1):
    # Capsule along X: (x1, y) to (x2, y) with radius r
    cy = (y1 + y2) * 0.5
    draw.ellipse([x1 - r, cy - r, x1 + r, cy + r], fill=fill, outline=outline, width=width)
    draw.ellipse([x2 - r, cy - r, x2 + r, cy + r], fill=fill, outline=outline, width=width)
    draw.rectangle([x1, cy - r, x2, cy + r], fill=fill)
    if outline and width > 0:
        draw.line([x1, cy - r, x2, cy - r], fill=outline, width=width)
        draw.line([x1, cy + r, x2, cy + r], fill=outline, width=width)
        draw.arc([x1 - r, cy - r, x1 + r, cy + r], 90, 270, fill=outline, width=width)
        draw.arc([x2 - r, cy - r, x2 + r, cy + r], 270, 90, fill=outline, width=width)

def draw_pill_badge(draw, cx, cy, text, theme_rgb, font_size=11):
    fnt = get_font(font_size)
    bbox = fnt.getbbox(text)
    tw = (bbox[2] - bbox[0])
    th = (bbox[3] - bbox[1])
    pw = tw + 20 * SCALE
    ph = 18 * SCALE
    rx = cx - pw * 0.5
    ry = cy - ph * 0.5
    
    # Pill bg
    draw.rounded_rectangle([rx, ry, rx + pw, ry + ph], radius=ph * 0.5, fill=(6, 16, 26, 210), outline=(theme_rgb[0], theme_rgb[1], theme_rgb[2], 140), width=max(1, int(1.5 * SCALE)))
    # Text
    tx = cx - tw * 0.5 - bbox[0]
    ty = cy - th * 0.5 - bbox[1] - 1 * SCALE
    draw.text((tx, ty), text, font=fnt, fill=(theme_rgb[0], theme_rgb[1], theme_rgb[2], 240))

def draw_cardinal_notches(draw, cx, cy, r, length=8*SCALE, width=int(2*SCALE), col=(255, 255, 255, 210)):
    for ang in [0, math.pi * 0.5, math.pi, math.pi * 1.5]:
        dx = math.cos(ang)
        dy = math.sin(ang)
        p1 = (cx + dx * (r - length * 0.5), cy + dy * (r - length * 0.5))
        p2 = (cx + dx * (r + length * 0.5), cy + dy * (r + length * 0.5))
        draw.line([p1, p2], fill=col, width=width)

# ------------------------------------------------------------------------------
# 1. TRACK BACKGROUND (260 x 108)
# ------------------------------------------------------------------------------
def render_track():
    W, H = 260, 108
    img = create_canvas(W, H)
    draw = ImageDraw.Draw(img)
    
    # Capsule geometry
    # Original rect: (42, 560, 236, 74)
    # Inside 260 x 108: track body from x=12 to x=248, y=10 to y=84, h=74, r=37
    # center y = 47
    cy = 47 * SCALE
    r = 37 * SCALE
    x1 = (12 + 37) * SCALE
    x2 = (248 - 37) * SCALE
    
    # Outer Glow layer
    draw_capsule(draw, x1, cy - r, x2, cy + r, r + 4 * SCALE, fill=(30, 160, 240, 35))
    
    # Obsidian frosted glass body
    draw_capsule(draw, x1, cy - r, x2, cy + r, r, fill=(8, 18, 30, 215))
    
    # Outer Metallic Border Rim
    border_col = (55, 205, 255, 180)
    draw_capsule(draw, x1, cy - r, x2, cy + r, r, fill=None, outline=border_col, width=max(1, int(2.2 * SCALE)))
    
    # Top specular rim reflection
    draw.line([x1, cy - r + 3 * SCALE, x2, cy - r + 3 * SCALE], fill=(120, 210, 255, 75), width=max(1, int(2 * SCALE)))
    
    # Inner Laser Groove Slot
    draw.line([x1, cy, x2, cy], fill=(15, 60, 95, 170), width=max(1, int(7 * SCALE)))
    draw.line([x1, cy, x2, cy], fill=(60, 210, 255, 110), width=max(1, int(2.5 * SCALE)))
    
    # Laser tick marks
    track_cx = (x1 + x2) * 0.5
    for i in range(-3, 4):
        tx = track_cx + i * 22 * SCALE
        th = (11 if i == 0 else 7) * SCALE
        t_col = (80, 220, 255, 160 if i == 0 else 80)
        draw.line([tx, cy - th * 0.5, tx, cy + th * 0.5], fill=t_col, width=max(1, int(1.8 * SCALE)))
        
    # Chevrons << and >>
    # Left <<
    lx = x1 - 10 * SCALE
    draw.line([(lx + 9*SCALE, cy - 9*SCALE), (lx, cy), (lx + 9*SCALE, cy + 9*SCALE)], fill=(70, 225, 255, 190), width=max(1, int(2.6 * SCALE)))
    draw.line([(lx + 18*SCALE, cy - 9*SCALE), (lx + 9*SCALE, cy), (lx + 18*SCALE, cy + 9*SCALE)], fill=(70, 225, 255, 110), width=max(1, int(2 * SCALE)))
    
    # Right >>
    rx = x2 + 10 * SCALE
    draw.line([(rx - 9*SCALE, cy - 9*SCALE), (rx, cy), (rx - 9*SCALE, cy + 9*SCALE)], fill=(70, 225, 255, 190), width=max(1, int(2.6 * SCALE)))
    draw.line([(rx - 18*SCALE, cy - 9*SCALE), (rx - 9*SCALE, cy), (rx - 18*SCALE, cy + 9*SCALE)], fill=(70, 225, 255, 110), width=max(1, int(2 * SCALE)))
    
    # Bottom tech badge
    draw_pill_badge(draw, track_cx, 97 * SCALE, "DI CHUYỂN", (70, 215, 255), font_size=11)
    
    return finalize(img, W, H)

# ------------------------------------------------------------------------------
# 2. TOUCH KNOB (76 x 76)
# ------------------------------------------------------------------------------
def render_knob():
    W, H = 76, 76
    img = create_canvas(W, H)
    draw = ImageDraw.Draw(img)
    
    cx, cy = (W * 0.5) * SCALE, (H * 0.5) * SCALE
    r = 30 * SCALE
    
    # Outer Glow
    draw.ellipse([cx - r - 6*SCALE, cy - r - 6*SCALE, cx + r + 6*SCALE, cy + r + 6*SCALE], fill=(40, 200, 255, 45))
    
    # Puck Metallic Dark Rim
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(12, 28, 45, 245), outline=(90, 230, 255, 240), width=max(1, int(2.8 * SCALE)))
    
    # Inner Cyber Gradient Disc
    r_in = r - 5 * SCALE
    draw.ellipse([cx - r_in, cy - r_in, cx + r_in, cy + r_in], fill=(20, 55, 88, 245), outline=(130, 240, 255, 120), width=max(1, int(1.6 * SCALE)))
    
    # Top Glass Arc Reflection
    draw.arc([cx - r_in + 2*SCALE, cy - r_in + 1*SCALE, cx + r_in - 2*SCALE, cy + r_in - 1*SCALE], 200, 340, fill=(255, 255, 255, 110), width=max(1, int(2 * SCALE)))
    
    # Center Glyphs: ◀ ● ▶
    draw.ellipse([cx - 4.5*SCALE, cy - 4.5*SCALE, cx + 4.5*SCALE, cy + 4.5*SCALE], fill=(255, 255, 255, 245))
    # Left arrow ◀
    draw.polygon([(cx - 10*SCALE, cy - 6*SCALE), (cx - 17*SCALE, cy), (cx - 10*SCALE, cy + 6*SCALE)], fill=(255, 255, 255, 230))
    # Right arrow ▶
    draw.polygon([(cx + 10*SCALE, cy - 6*SCALE), (cx + 17*SCALE, cy), (cx + 10*SCALE, cy + 6*SCALE)], fill=(255, 255, 255, 230))
    
    return finalize(img, W, H)

# ------------------------------------------------------------------------------
# 3. BUTTON J: DROP SHOT (104 x 124)
# ------------------------------------------------------------------------------
def render_btn_drop():
    W, H = 104, 124
    img = create_canvas(W, H)
    draw = ImageDraw.Draw(img)
    
    cx, cy = (W * 0.5) * SCALE, 46 * SCALE
    r = 40 * SCALE
    theme_rgb = (25, 250, 160) # Emerald Mint
    
    # 1. Soft atmospheric outer aura
    draw.ellipse([cx - r - 6*SCALE, cy - r - 6*SCALE, cx + r + 6*SCALE, cy + r + 6*SCALE], fill=(25, 250, 160, 35))
    
    # 2. Obsidian Glass Disc Body
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(8, 28, 20, 230))
    
    # 3. Outer Milled Metallic Bezel Rim
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(35, 255, 175, 235), width=max(1, int(2.6 * SCALE)))
    draw_cardinal_notches(draw, cx, cy, r)
    
    # 4. Top specular glass arc
    draw.arc([cx - r + 5*SCALE, cy - r + 3*SCALE, cx + r - 5*SCALE, cy + r - 3*SCALE], 200, 340, fill=(255, 255, 255, 75), width=max(1, int(2 * SCALE)))
    
    # 5. ICON: Badminton Net Pole + Aerodynamic Drop Arc + Feathered Cork
    net_x = cx - 6 * SCALE
    # White net post
    draw.line([net_x, cy - 13*SCALE, net_x, cy + 15*SCALE], fill=(255, 255, 255, 235), width=max(1, int(3 * SCALE)))
    draw.line([net_x - 5*SCALE, cy - 13*SCALE, net_x + 5*SCALE, cy - 13*SCALE], fill=(255, 255, 255, 255), width=max(1, int(3 * SCALE)))
    # Net grid hashes
    for ny in [-6, 0, 6]:
        draw.line([net_x - 4*SCALE, cy + ny*SCALE, net_x + 4*SCALE, cy + ny*SCALE], fill=(160, 250, 210, 160), width=max(1, int(1.5 * SCALE)))
        
    # Drop Arc Curve (parabolic descent over net)
    steps = 24
    curve_pts = []
    for i in range(steps + 1):
        t = i / steps
        px = cx + (-22 + 38 * t) * SCALE
        py = cy + (-16 * math.sin(t * math.pi * 0.90) + 5 * t) * SCALE
        curve_pts.append((px, py))
        
    # Glow polyline
    for i in range(len(curve_pts) - 1):
        draw.line([curve_pts[i], curve_pts[i+1]], fill=(theme_rgb[0], theme_rgb[1], theme_rgb[2], 90), width=max(1, int(5 * SCALE)))
    for i in range(len(curve_pts) - 1):
        draw.line([curve_pts[i], curve_pts[i+1]], fill=theme_rgb, width=max(1, int(2.6 * SCALE)))
        
    # Mini Shuttlecock descending at tip
    tip_x, tip_y = curve_pts[-1]
    # Rounded white cork
    draw.ellipse([tip_x - 4*SCALE, tip_y - 4*SCALE, tip_x + 4*SCALE, tip_y + 4*SCALE], fill=(255, 255, 255, 255))
    # Feather skirt angled up-left
    fdx, fdy = 0.6 * SCALE, -0.8 * SCALE
    p1 = (tip_x + fdx * 2, tip_y + fdy * 2)
    p2 = (tip_x + fdx * 10 - fdy * 5, tip_y + fdy * 10 + fdx * 5)
    p3 = (tip_x + fdx * 12, tip_y + fdy * 12)
    p4 = (tip_x + fdx * 10 + fdy * 5, tip_y + fdy * 10 - fdx * 5)
    draw.polygon([p1, p2, p3, p4], fill=(theme_rgb[0], theme_rgb[1], theme_rgb[2], 220), outline=(255, 255, 255, 180))
    
    # Bottom badge
    draw_pill_badge(draw, cx, 110 * SCALE, "BỎ NHỎ", theme_rgb, font_size=11)
    
    return finalize(img, W, H)

# ------------------------------------------------------------------------------
# 4. BUTTON K: CLEAR SHOT (104 x 124)
# ------------------------------------------------------------------------------
def render_btn_clear():
    W, H = 104, 124
    img = create_canvas(W, H)
    draw = ImageDraw.Draw(img)
    
    cx, cy = (W * 0.5) * SCALE, 46 * SCALE
    r = 40 * SCALE
    theme_rgb = (255, 195, 30) # Solar Amber
    
    # 1. Soft atmospheric outer aura
    draw.ellipse([cx - r - 6*SCALE, cy - r - 6*SCALE, cx + r + 6*SCALE, cy + r + 6*SCALE], fill=(255, 195, 30, 35))
    
    # 2. Obsidian Glass Disc Body
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(30, 20, 6, 230))
    
    # 3. Outer Milled Metallic Bezel Rim
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 210, 50, 235), width=max(1, int(2.6 * SCALE)))
    draw_cardinal_notches(draw, cx, cy, r)
    
    # 4. Top specular glass arc
    draw.arc([cx - r + 5*SCALE, cy - r + 3*SCALE, cx + r - 5*SCALE, cy + r - 3*SCALE], 200, 340, fill=(255, 255, 255, 75), width=max(1, int(2 * SCALE)))
    
    # 5. ICON: Soaring Parabolic Lift to Backcourt + Speed Rings + Arrowhead
    steps = 24
    curve_pts = []
    for i in range(steps + 1):
        t = i / steps
        px = cx + (-20 + 38 * t) * SCALE
        py = cy + (14 - 31 * math.sin(t * math.pi * 0.95)) * SCALE
        curve_pts.append((px, py))
        
    for i in range(len(curve_pts) - 1):
        draw.line([curve_pts[i], curve_pts[i+1]], fill=(theme_rgb[0], theme_rgb[1], theme_rgb[2], 90), width=max(1, int(5.5 * SCALE)))
    for i in range(len(curve_pts) - 1):
        draw.line([curve_pts[i], curve_pts[i+1]], fill=theme_rgb, width=max(1, int(2.8 * SCALE)))
        
    # Sonic speed rings at apex
    mid_idx = int(steps * 0.46)
    mx, my = curve_pts[mid_idx]
    draw.arc([mx - 7*SCALE, my - 7*SCALE, mx + 7*SCALE, my + 7*SCALE], 150, 340, fill=(255, 245, 160, 200), width=max(1, int(2 * SCALE)))
    
    # High-velocity rocket arrowhead at end
    ex, ey = curve_pts[-1]
    draw.ellipse([ex - 4*SCALE, ey - 4*SCALE, ex + 4*SCALE, ey + 4*SCALE], fill=(255, 255, 255, 255))
    # Arrow wings
    v_dir = (0.75, 0.66) # flight direction
    p_l = (ex - 12*SCALE * v_dir[0] + 7*SCALE * v_dir[1], ey - 12*SCALE * v_dir[1] - 7*SCALE * v_dir[0])
    p_r = (ex - 12*SCALE * v_dir[0] - 7*SCALE * v_dir[1], ey - 12*SCALE * v_dir[1] + 7*SCALE * v_dir[0])
    draw.line([p_l, (ex, ey), p_r], fill=theme_rgb, width=max(1, int(3 * SCALE)))
    
    # Bottom badge
    draw_pill_badge(draw, cx, 110 * SCALE, "PHÔNG SÂU", theme_rgb, font_size=11)
    
    return finalize(img, W, H)

# ------------------------------------------------------------------------------
# 5. BUTTON L (JUMP): VALKYRIE WINGS (120 x 140)
# ------------------------------------------------------------------------------
def render_btn_jump():
    W, H = 120, 140
    img = create_canvas(W, H)
    draw = ImageDraw.Draw(img)
    
    cx, cy = (W * 0.5) * SCALE, 52 * SCALE
    r = 48 * SCALE
    theme_rgb = (25, 215, 255) # Sky Electric Cyan
    
    # 1. Soft atmospheric outer aura
    draw.ellipse([cx - r - 7*SCALE, cy - r - 7*SCALE, cx + r + 7*SCALE, cy + r + 7*SCALE], fill=(25, 215, 255, 40))
    
    # 2. Obsidian Glass Disc Body
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(6, 24, 40, 235))
    
    # 3. Outer Milled Metallic Bezel Rim
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(55, 230, 255, 240), width=max(1, int(3.2 * SCALE)))
    draw_cardinal_notches(draw, cx, cy, r, length=10*SCALE, width=int(2.4*SCALE))
    
    # 4. Top specular glass arc
    draw.arc([cx - r + 6*SCALE, cy - r + 4*SCALE, cx + r - 6*SCALE, cy + r - 4*SCALE], 200, 340, fill=(255, 255, 255, 85), width=max(1, int(2.2 * SCALE)))
    
    # 5. ICON: Aerodynamic Valkyrie Wings & Upward Supersonic Lift Chevrons
    # Left Wing
    wing_l = [
        (cx - 7*SCALE, cy + 5*SCALE),
        (cx - 19*SCALE, cy - 2*SCALE),
        (cx - 27*SCALE, cy - 15*SCALE),
        (cx - 16*SCALE, cy - 10*SCALE),
        (cx - 6*SCALE, cy - 2*SCALE)
    ]
    draw.polygon(wing_l, fill=(25, 215, 255, 120), outline=theme_rgb)
    draw.line(wing_l + [wing_l[0]], fill=theme_rgb, width=max(1, int(2.4 * SCALE)))
    
    # Right Wing
    wing_r = [
        (cx + 7*SCALE, cy + 5*SCALE),
        (cx + 19*SCALE, cy - 2*SCALE),
        (cx + 27*SCALE, cy - 15*SCALE),
        (cx + 16*SCALE, cy - 10*SCALE),
        (cx + 6*SCALE, cy - 2*SCALE)
    ]
    draw.polygon(wing_r, fill=(25, 215, 255, 120), outline=theme_rgb)
    draw.line(wing_r + [wing_r[0]], fill=theme_rgb, width=max(1, int(2.4 * SCALE)))
    
    # Twin Upward Chevrons ︽
    draw.line([(cx - 11*SCALE, cy + 2*SCALE), (cx, cy - 9*SCALE), (cx + 11*SCALE, cy + 2*SCALE)], fill=(255, 255, 255, 255), width=max(1, int(3.2 * SCALE)))
    draw.line([(cx - 11*SCALE, cy + 11*SCALE), (cx, cy), (cx + 11*SCALE, cy + 11*SCALE)], fill=theme_rgb, width=max(1, int(2.6 * SCALE)))
    
    # Takeoff shockwave arc
    draw.arc([cx - 16*SCALE, cy + 13*SCALE, cx + 16*SCALE, cy + 31*SCALE], 20, 160, fill=(60, 220, 255, 160), width=max(1, int(2.2 * SCALE)))
    
    # Bottom badge
    draw_pill_badge(draw, cx, 123 * SCALE, "NHẢY", theme_rgb, font_size=12)
    
    return finalize(img, W, H)

# ------------------------------------------------------------------------------
# 6. BUTTON L (SMASH): BLAZING CRIMSON LIGHTNING BOLT (120 x 140)
# ------------------------------------------------------------------------------
def render_btn_smash():
    W, H = 120, 140
    img = create_canvas(W, H)
    draw = ImageDraw.Draw(img)
    
    cx, cy = (W * 0.5) * SCALE, 52 * SCALE
    r = 48 * SCALE
    theme_rgb = (255, 45, 45) # Blazing Crimson
    
    # 1. Soft atmospheric outer aura
    draw.ellipse([cx - r - 7*SCALE, cy - r - 7*SCALE, cx + r + 7*SCALE, cy + r + 7*SCALE], fill=(255, 45, 45, 45))
    
    # 2. Obsidian Glass Disc Body (Ruby Black)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(42, 8, 8, 240))
    
    # 3. Outer Milled Metallic Bezel Rim
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 70, 70, 245), width=max(1, int(3.2 * SCALE)))
    draw_cardinal_notches(draw, cx, cy, r, length=10*SCALE, width=int(2.4*SCALE))
    
    # 4. Top specular glass arc
    draw.arc([cx - r + 6*SCALE, cy - r + 4*SCALE, cx + r - 6*SCALE, cy + r - 4*SCALE], 200, 340, fill=(255, 255, 255, 85), width=max(1, int(2.2 * SCALE)))
    
    # 5. ICON: Aggressive Downward Lightning Spike + Impact Sparks + Shockwave Blades
    bolt_pts = [
        (cx + 9*SCALE, cy - 24*SCALE),
        (cx - 6*SCALE, cy - 2*SCALE),
        (cx + 6*SCALE, cy - 1*SCALE),
        (cx - 11*SCALE, cy + 23*SCALE)
    ]
    
    # Outer glow bolt
    for i in range(len(bolt_pts) - 1):
        draw.line([bolt_pts[i], bolt_pts[i+1]], fill=(255, 45, 45, 120), width=max(1, int(8 * SCALE)))
    # Crimson bolt
    for i in range(len(bolt_pts) - 1):
        draw.line([bolt_pts[i], bolt_pts[i+1]], fill=(255, 50, 50, 255), width=max(1, int(4.2 * SCALE)))
    # Razor white-hot core
    for i in range(len(bolt_pts) - 1):
        draw.line([bolt_pts[i], bolt_pts[i+1]], fill=(255, 245, 210, 255), width=max(1, int(2 * SCALE)))
        
    # Impact explosion point
    ip_x, ip_y = bolt_pts[-1]
    draw.ellipse([ip_x - 5*SCALE, ip_y - 5*SCALE, ip_x + 5*SCALE, ip_y + 5*SCALE], fill=(255, 255, 220, 255))
    draw.line([(ip_x, ip_y), (ip_x - 11*SCALE, ip_y + 6*SCALE)], fill=theme_rgb, width=max(1, int(2.6 * SCALE)))
    draw.line([(ip_x, ip_y), (ip_x - 4*SCALE, ip_y + 11*SCALE)], fill=theme_rgb, width=max(1, int(2.6 * SCALE)))
    draw.line([(ip_x, ip_y), (ip_x + 8*SCALE, ip_y + 6*SCALE)], fill=theme_rgb, width=max(1, int(2.6 * SCALE)))
    
    # Dual flanking shockwave slash blades
    draw.line([(cx - 20*SCALE, cy - 8*SCALE), (cx - 13*SCALE, cy + 6*SCALE)], fill=(255, 90, 90, 180), width=max(1, int(2.4 * SCALE)))
    draw.line([(cx + 20*SCALE, cy - 8*SCALE), (cx + 13*SCALE, cy + 6*SCALE)], fill=(255, 90, 90, 180), width=max(1, int(2.4 * SCALE)))
    
    # Bottom badge
    draw_pill_badge(draw, cx, 123 * SCALE, "ĐẬP CẦU", theme_rgb, font_size=12)
    
    return finalize(img, W, H)

def main():
    out_dir = "assets/ui/touch"
    os.makedirs(out_dir, exist_ok=True)
    
    track = render_track()
    track.save(os.path.join(out_dir, "touch_track.png"))
    print("Saved touch_track.png (260x108)")
    
    knob = render_knob()
    knob.save(os.path.join(out_dir, "touch_knob.png"))
    print("Saved touch_knob.png (76x76)")
    
    drop = render_btn_drop()
    drop.save(os.path.join(out_dir, "btn_drop.png"))
    print("Saved btn_drop.png (104x124)")
    
    clear = render_btn_clear()
    clear.save(os.path.join(out_dir, "btn_clear.png"))
    print("Saved btn_clear.png (104x124)")
    
    jump = render_btn_jump()
    jump.save(os.path.join(out_dir, "btn_jump.png"))
    print("Saved btn_jump.png (120x140)")
    
    smash = render_btn_smash()
    smash.save(os.path.join(out_dir, "btn_smash.png"))
    print("Saved btn_smash.png (120x140)")
    
    # Create montage for inspection artifact
    montage = Image.new("RGBA", (700, 320), (10, 15, 25, 255))
    montage.paste(track, (20, 30), track)
    montage.paste(knob, (112, 46), knob)
    montage.paste(drop, (300, 20), drop)
    montage.paste(clear, (420, 20), clear)
    montage.paste(jump, (540, 10), jump)
    montage.paste(smash, (540, 160), smash)
    
    artifact_path = "C:/Users/sieut/.gemini/antigravity/brain/1c65eb4a-1be9-4d1b-977b-b853216b922a/touch_controls_preview.png"
    montage.save(artifact_path)
    print("Saved montage artifact to", artifact_path)

if __name__ == "__main__":
    main()
