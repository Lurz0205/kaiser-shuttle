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
    pw = tw + 22 * SCALE
    ph = 19 * SCALE
    rx = cx - pw * 0.5
    ry = cy - ph * 0.5
    
    # Pill bg
    draw.rounded_rectangle([rx, ry, rx + pw, ry + ph], radius=ph * 0.5, fill=(6, 16, 26, 215), outline=(theme_rgb[0], theme_rgb[1], theme_rgb[2], 150), width=max(1, int(1.5 * SCALE)))
    # Text
    tx = cx - tw * 0.5 - bbox[0]
    ty = cy - th * 0.5 - bbox[1] - 1 * SCALE
    draw.text((tx, ty), text, font=fnt, fill=(theme_rgb[0], theme_rgb[1], theme_rgb[2], 245))

def draw_cardinal_notches(draw, cx, cy, r, length=8*SCALE, width=int(2*SCALE), col=(255, 255, 255, 210)):
    for ang in [0, math.pi * 0.5, math.pi, math.pi * 1.5]:
        dx = math.cos(ang)
        dy = math.sin(ang)
        p1 = (cx + dx * (r - length * 0.5), cy + dy * (r - length * 0.5))
        p2 = (cx + dx * (r + length * 0.5), cy + dy * (r + length * 0.5))
        draw.line([p1, p2], fill=col, width=width)

# ------------------------------------------------------------------------------
# 1. TRACK BACKGROUND (270 x 112)
# ------------------------------------------------------------------------------
def render_track():
    W, H = 270, 112
    img = create_canvas(W, H)
    draw = ImageDraw.Draw(img)
    
    cy = 49 * SCALE
    r = 38 * SCALE
    x1 = (14 + 38) * SCALE
    x2 = (256 - 38) * SCALE
    
    # Outer Glow layer
    draw_capsule(draw, x1, cy - r, x2, cy + r, r + 4 * SCALE, fill=(30, 160, 240, 35))
    # Obsidian frosted glass body
    draw_capsule(draw, x1, cy - r, x2, cy + r, r, fill=(8, 18, 30, 220))
    # Outer Metallic Border Rim
    border_col = (55, 205, 255, 185)
    draw_capsule(draw, x1, cy - r, x2, cy + r, r, fill=None, outline=border_col, width=max(1, int(2.4 * SCALE)))
    # Top specular rim reflection
    draw.line([x1, cy - r + 3 * SCALE, x2, cy - r + 3 * SCALE], fill=(120, 210, 255, 80), width=max(1, int(2 * SCALE)))
    # Inner Laser Groove Slot
    draw.line([x1, cy, x2, cy], fill=(15, 60, 95, 175), width=max(1, int(8 * SCALE)))
    draw.line([x1, cy, x2, cy], fill=(60, 210, 255, 115), width=max(1, int(2.6 * SCALE)))
    
    # Laser tick marks
    track_cx = (x1 + x2) * 0.5
    for i in range(-3, 4):
        tx = track_cx + i * 24 * SCALE
        th = (12 if i == 0 else 8) * SCALE
        t_col = (80, 220, 255, 170 if i == 0 else 85)
        draw.line([tx, cy - th * 0.5, tx, cy + th * 0.5], fill=t_col, width=max(1, int(1.8 * SCALE)))
        
    # Chevrons << and >>
    lx = x1 - 10 * SCALE
    draw.line([(lx + 9*SCALE, cy - 9*SCALE), (lx, cy), (lx + 9*SCALE, cy + 9*SCALE)], fill=(70, 225, 255, 195), width=max(1, int(2.8 * SCALE)))
    draw.line([(lx + 19*SCALE, cy - 9*SCALE), (lx + 10*SCALE, cy), (lx + 19*SCALE, cy + 9*SCALE)], fill=(70, 225, 255, 115), width=max(1, int(2 * SCALE)))
    
    rx = x2 + 10 * SCALE
    draw.line([(rx - 9*SCALE, cy - 9*SCALE), (rx, cy), (rx - 9*SCALE, cy + 9*SCALE)], fill=(70, 225, 255, 195), width=max(1, int(2.8 * SCALE)))
    draw.line([(rx - 19*SCALE, cy - 9*SCALE), (rx - 10*SCALE, cy), (rx - 19*SCALE, cy + 9*SCALE)], fill=(70, 225, 255, 115), width=max(1, int(2 * SCALE)))
    
    # Bottom tech badge
    draw_pill_badge(draw, track_cx, 100 * SCALE, "DI CHUYỂN", (70, 215, 255), font_size=11)
    
    return finalize(img, W, H)

# ------------------------------------------------------------------------------
# 2. TOUCH KNOB (84 x 84)
# ------------------------------------------------------------------------------
def render_knob():
    W, H = 84, 84
    img = create_canvas(W, H)
    draw = ImageDraw.Draw(img)
    
    cx, cy = (W * 0.5) * SCALE, (H * 0.5) * SCALE
    r = 34 * SCALE
    
    # Outer Glow
    draw.ellipse([cx - r - 7*SCALE, cy - r - 7*SCALE, cx + r + 7*SCALE, cy + r + 7*SCALE], fill=(40, 200, 255, 45))
    # Puck Metallic Dark Rim
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(12, 28, 45, 245), outline=(90, 230, 255, 240), width=max(1, int(3.0 * SCALE)))
    # Inner Cyber Gradient Disc
    r_in = r - 6 * SCALE
    draw.ellipse([cx - r_in, cy - r_in, cx + r_in, cy + r_in], fill=(20, 55, 88, 245), outline=(130, 240, 255, 120), width=max(1, int(1.8 * SCALE)))
    # Top Glass Arc Reflection
    draw.arc([cx - r_in + 2*SCALE, cy - r_in + 1*SCALE, cx + r_in - 2*SCALE, cy + r_in - 1*SCALE], 200, 340, fill=(255, 255, 255, 115), width=max(1, int(2.2 * SCALE)))
    
    # Center Glyphs: ◀ ● ▶
    draw.ellipse([cx - 5*SCALE, cy - 5*SCALE, cx + 5*SCALE, cy + 5*SCALE], fill=(255, 255, 255, 250))
    # Left arrow ◀
    draw.polygon([(cx - 11*SCALE, cy - 7*SCALE), (cx - 19*SCALE, cy), (cx - 11*SCALE, cy + 7*SCALE)], fill=(255, 255, 255, 235))
    # Right arrow ▶
    draw.polygon([(cx + 11*SCALE, cy - 7*SCALE), (cx + 19*SCALE, cy), (cx + 11*SCALE, cy + 7*SCALE)], fill=(255, 255, 255, 235))
    
    return finalize(img, W, H)

# ------------------------------------------------------------------------------
# 3. BUTTON SLIDE: DIVE RESCUE (118 x 140)
# ------------------------------------------------------------------------------
def render_btn_slide():
    W, H = 118, 140
    img = create_canvas(W, H)
    draw = ImageDraw.Draw(img)
    
    cx, cy = (W * 0.5) * SCALE, 52 * SCALE
    r = 46 * SCALE
    theme_rgb = (0, 225, 255) # Cyber Cyan / Ice Aqua
    
    # 1. Soft atmospheric outer aura
    draw.ellipse([cx - r - 7*SCALE, cy - r - 7*SCALE, cx + r + 7*SCALE, cy + r + 7*SCALE], fill=(0, 225, 255, 38))
    # 2. Obsidian Glass Disc Body
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(6, 26, 38, 235))
    # 3. Outer Milled Metallic Bezel Rim
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(0, 240, 255, 240), width=max(1, int(2.8 * SCALE)))
    draw_cardinal_notches(draw, cx, cy, r, length=9*SCALE)
    # 4. Top specular glass arc
    draw.arc([cx - r + 6*SCALE, cy - r + 4*SCALE, cx + r - 6*SCALE, cy + r - 4*SCALE], 200, 340, fill=(255, 255, 255, 80), width=max(1, int(2.2 * SCALE)))
    
    # 5. ICON: Horizontal Slide Floor Line + Forward Motion Trail + Extended Racket Dig
    # Floor line
    draw.line([(cx - 28*SCALE, cy + 16*SCALE), (cx + 28*SCALE, cy + 16*SCALE)], fill=(120, 220, 255, 140), width=max(1, int(2.0 * SCALE)))
    
    # Speed streaks
    draw.line([(cx - 28*SCALE, cy + 9*SCALE), (cx + 4*SCALE, cy + 9*SCALE)], fill=(0, 225, 255, 130), width=max(1, int(2.8 * SCALE)))
    draw.line([(cx - 32*SCALE, cy + 2*SCALE), (cx - 8*SCALE, cy + 2*SCALE)], fill=(0, 225, 255, 90), width=max(1, int(2.0 * SCALE)))
    draw.line([(cx - 25*SCALE, cy - 5*SCALE), (cx - 14*SCALE, cy - 5*SCALE)], fill=(0, 225, 255, 60), width=max(1, int(1.8 * SCALE)))
    
    # Slanted sliding athlete body / arrow
    # Forward thrust arrow reaching right
    arrow = [
        (cx - 16*SCALE, cy + 9*SCALE),
        (cx + 8*SCALE, cy + 7*SCALE),
        (cx + 20*SCALE, cy - 1*SCALE),
        (cx + 12*SCALE, cy - 12*SCALE),
        (cx + 2*SCALE, cy - 3*SCALE)
    ]
    draw.polygon(arrow, fill=(0, 225, 255, 140), outline=(255, 255, 255, 230))
    draw.line(arrow + [arrow[0]], fill=theme_rgb, width=max(1, int(2.6 * SCALE)))
    
    # Extended Racket & Shuttlecock low rescue point
    tip_x, tip_y = cx + 22 * SCALE, cy + 8 * SCALE
    # Cork
    draw.ellipse([tip_x - 4*SCALE, tip_y - 4*SCALE, tip_x + 4*SCALE, tip_y + 4*SCALE], fill=(255, 255, 255, 255))
    # Feathers pointing backward-up
    fdx, fdy = -0.7 * SCALE, -0.7 * SCALE
    p1 = (tip_x + fdx * 2, tip_y + fdy * 2)
    p2 = (tip_x + fdx * 9 - fdy * 4, tip_y + fdy * 9 + fdx * 4)
    p3 = (tip_x + fdx * 11, tip_y + fdy * 11)
    p4 = (tip_x + fdx * 9 + fdy * 4, tip_y + fdy * 9 - fdx * 4)
    draw.polygon([p1, p2, p3, p4], fill=(theme_rgb[0], theme_rgb[1], theme_rgb[2], 220), outline=(255, 255, 255, 190))
    
    # Bottom badge
    draw_pill_badge(draw, cx, 124 * SCALE, "TRƯỢT", theme_rgb, font_size=11)
    
    return finalize(img, W, H)

# ------------------------------------------------------------------------------
# 4. BUTTON J: DROP SHOT (118 x 140)
# ------------------------------------------------------------------------------
def render_btn_drop():
    W, H = 118, 140
    img = create_canvas(W, H)
    draw = ImageDraw.Draw(img)
    
    cx, cy = (W * 0.5) * SCALE, 52 * SCALE
    r = 46 * SCALE
    theme_rgb = (25, 250, 160) # Emerald Mint
    
    # 1. Soft atmospheric outer aura
    draw.ellipse([cx - r - 7*SCALE, cy - r - 7*SCALE, cx + r + 7*SCALE, cy + r + 7*SCALE], fill=(25, 250, 160, 38))
    # 2. Obsidian Glass Disc Body
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(8, 28, 20, 235))
    # 3. Outer Milled Metallic Bezel Rim
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(35, 255, 175, 240), width=max(1, int(2.8 * SCALE)))
    draw_cardinal_notches(draw, cx, cy, r, length=9*SCALE)
    # 4. Top specular glass arc
    draw.arc([cx - r + 6*SCALE, cy - r + 4*SCALE, cx + r - 6*SCALE, cy + r - 4*SCALE], 200, 340, fill=(255, 255, 255, 80), width=max(1, int(2.2 * SCALE)))
    
    # 5. ICON: Badminton Net Pole + Aerodynamic Drop Arc + Feathered Cork
    net_x = cx - 7 * SCALE
    draw.line([net_x, cy - 15*SCALE, net_x, cy + 17*SCALE], fill=(255, 255, 255, 240), width=max(1, int(3.2 * SCALE)))
    draw.line([net_x - 6*SCALE, cy - 15*SCALE, net_x + 6*SCALE, cy - 15*SCALE], fill=(255, 255, 255, 255), width=max(1, int(3.2 * SCALE)))
    for ny in [-7, 0, 7]:
        draw.line([net_x - 5*SCALE, cy + ny*SCALE, net_x + 5*SCALE, cy + ny*SCALE], fill=(160, 250, 210, 165), width=max(1, int(1.6 * SCALE)))
        
    steps = 24
    curve_pts = []
    for i in range(steps + 1):
        t = i / steps
        px = cx + (-25 + 43 * t) * SCALE
        py = cy + (-18 * math.sin(t * math.pi * 0.90) + 6 * t) * SCALE
        curve_pts.append((px, py))
        
    for i in range(len(curve_pts) - 1):
        draw.line([curve_pts[i], curve_pts[i+1]], fill=(theme_rgb[0], theme_rgb[1], theme_rgb[2], 95), width=max(1, int(5.5 * SCALE)))
    for i in range(len(curve_pts) - 1):
        draw.line([curve_pts[i], curve_pts[i+1]], fill=theme_rgb, width=max(1, int(2.8 * SCALE)))
        
    tip_x, tip_y = curve_pts[-1]
    draw.ellipse([tip_x - 4.5*SCALE, tip_y - 4.5*SCALE, tip_x + 4.5*SCALE, tip_y + 4.5*SCALE], fill=(255, 255, 255, 255))
    fdx, fdy = 0.6 * SCALE, -0.8 * SCALE
    p1 = (tip_x + fdx * 2, tip_y + fdy * 2)
    p2 = (tip_x + fdx * 11 - fdy * 5, tip_y + fdy * 11 + fdx * 5)
    p3 = (tip_x + fdx * 13, tip_y + fdy * 13)
    p4 = (tip_x + fdx * 11 + fdy * 5, tip_y + fdy * 11 - fdx * 5)
    draw.polygon([p1, p2, p3, p4], fill=(theme_rgb[0], theme_rgb[1], theme_rgb[2], 225), outline=(255, 255, 255, 185))
    
    # Bottom badge
    draw_pill_badge(draw, cx, 124 * SCALE, "BỎ NHỎ", theme_rgb, font_size=11)
    
    return finalize(img, W, H)

# ------------------------------------------------------------------------------
# 5. BUTTON K: CLEAR SHOT (118 x 140)
# ------------------------------------------------------------------------------
def render_btn_clear():
    W, H = 118, 140
    img = create_canvas(W, H)
    draw = ImageDraw.Draw(img)
    
    cx, cy = (W * 0.5) * SCALE, 52 * SCALE
    r = 46 * SCALE
    theme_rgb = (255, 195, 30) # Solar Amber
    
    # 1. Soft atmospheric outer aura
    draw.ellipse([cx - r - 7*SCALE, cy - r - 7*SCALE, cx + r + 7*SCALE, cy + r + 7*SCALE], fill=(255, 195, 30, 38))
    # 2. Obsidian Glass Disc Body
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(30, 20, 6, 235))
    # 3. Outer Milled Metallic Bezel Rim
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 210, 50, 240), width=max(1, int(2.8 * SCALE)))
    draw_cardinal_notches(draw, cx, cy, r, length=9*SCALE)
    # 4. Top specular glass arc
    draw.arc([cx - r + 6*SCALE, cy - r + 4*SCALE, cx + r - 6*SCALE, cy + r - 4*SCALE], 200, 340, fill=(255, 255, 255, 80), width=max(1, int(2.2 * SCALE)))
    
    # 5. ICON: Parabolic Lift + Arrowhead
    steps = 24
    curve_pts = []
    for i in range(steps + 1):
        t = i / steps
        px = cx + (-23 + 44 * t) * SCALE
        py = cy + (16 - 35 * math.sin(t * math.pi * 0.95)) * SCALE
        curve_pts.append((px, py))
        
    for i in range(len(curve_pts) - 1):
        draw.line([curve_pts[i], curve_pts[i+1]], fill=(theme_rgb[0], theme_rgb[1], theme_rgb[2], 95), width=max(1, int(6.0 * SCALE)))
    for i in range(len(curve_pts) - 1):
        draw.line([curve_pts[i], curve_pts[i+1]], fill=theme_rgb, width=max(1, int(3.0 * SCALE)))
        
    mid_idx = int(steps * 0.46)
    mx, my = curve_pts[mid_idx]
    draw.arc([mx - 8*SCALE, my - 8*SCALE, mx + 8*SCALE, my + 8*SCALE], 150, 340, fill=(255, 245, 160, 210), width=max(1, int(2.2 * SCALE)))
    
    ex, ey = curve_pts[-1]
    draw.ellipse([ex - 4.5*SCALE, ey - 4.5*SCALE, ex + 4.5*SCALE, ey + 4.5*SCALE], fill=(255, 255, 255, 255))
    v_dir = (0.75, 0.66)
    p_l = (ex - 13*SCALE * v_dir[0] + 8*SCALE * v_dir[1], ey - 13*SCALE * v_dir[1] - 8*SCALE * v_dir[0])
    p_r = (ex - 13*SCALE * v_dir[0] - 8*SCALE * v_dir[1], ey - 13*SCALE * v_dir[1] + 8*SCALE * v_dir[0])
    draw.line([p_l, (ex, ey), p_r], fill=theme_rgb, width=max(1, int(3.2 * SCALE)))
    
    # Bottom badge
    draw_pill_badge(draw, cx, 124 * SCALE, "PHÔNG SÂU", theme_rgb, font_size=11)
    
    return finalize(img, W, H)

# ------------------------------------------------------------------------------
# 6. BUTTON L (JUMP): VALKYRIE WINGS (136 x 160)
# ------------------------------------------------------------------------------
def render_btn_jump():
    W, H = 136, 160
    img = create_canvas(W, H)
    draw = ImageDraw.Draw(img)
    
    cx, cy = (W * 0.5) * SCALE, 60 * SCALE
    r = 55 * SCALE
    theme_rgb = (25, 215, 255) # Sky Electric Cyan
    
    # 1. Soft atmospheric outer aura
    draw.ellipse([cx - r - 8*SCALE, cy - r - 8*SCALE, cx + r + 8*SCALE, cy + r + 8*SCALE], fill=(25, 215, 255, 45))
    # 2. Obsidian Glass Disc Body
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(6, 24, 40, 240))
    # 3. Outer Milled Metallic Bezel Rim
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(55, 230, 255, 245), width=max(1, int(3.4 * SCALE)))
    draw_cardinal_notches(draw, cx, cy, r, length=11*SCALE, width=int(2.6*SCALE))
    # 4. Top specular glass arc
    draw.arc([cx - r + 7*SCALE, cy - r + 5*SCALE, cx + r - 7*SCALE, cy + r - 5*SCALE], 200, 340, fill=(255, 255, 255, 90), width=max(1, int(2.4 * SCALE)))
    
    # 5. ICON: Valkyrie Wings & Upward Chevrons
    wing_l = [
        (cx - 8*SCALE, cy + 6*SCALE),
        (cx - 22*SCALE, cy - 2*SCALE),
        (cx - 31*SCALE, cy - 17*SCALE),
        (cx - 18*SCALE, cy - 11*SCALE),
        (cx - 7*SCALE, cy - 2*SCALE)
    ]
    draw.polygon(wing_l, fill=(25, 215, 255, 125), outline=theme_rgb)
    draw.line(wing_l + [wing_l[0]], fill=theme_rgb, width=max(1, int(2.6 * SCALE)))
    
    wing_r = [
        (cx + 8*SCALE, cy + 6*SCALE),
        (cx + 22*SCALE, cy - 2*SCALE),
        (cx + 31*SCALE, cy - 17*SCALE),
        (cx + 18*SCALE, cy - 11*SCALE),
        (cx + 7*SCALE, cy - 2*SCALE)
    ]
    draw.polygon(wing_r, fill=(25, 215, 255, 125), outline=theme_rgb)
    draw.line(wing_r + [wing_r[0]], fill=theme_rgb, width=max(1, int(2.6 * SCALE)))
    
    # Twin Upward Chevrons ︽
    draw.line([(cx - 13*SCALE, cy + 2*SCALE), (cx, cy - 10*SCALE), (cx + 13*SCALE, cy + 2*SCALE)], fill=(255, 255, 255, 255), width=max(1, int(3.6 * SCALE)))
    draw.line([(cx - 13*SCALE, cy + 12*SCALE), (cx, cy), (cx + 13*SCALE, cy + 12*SCALE)], fill=theme_rgb, width=max(1, int(3.0 * SCALE)))
    
    # Shockwave arc
    draw.arc([cx - 18*SCALE, cy + 15*SCALE, cx + 18*SCALE, cy + 35*SCALE], 20, 160, fill=(60, 220, 255, 170), width=max(1, int(2.4 * SCALE)))
    
    # Bottom badge
    draw_pill_badge(draw, cx, 141 * SCALE, "NHẢY", theme_rgb, font_size=12)
    
    return finalize(img, W, H)

# ------------------------------------------------------------------------------
# 7. BUTTON L (SMASH): CRIMSON LIGHTNING BOLT (136 x 160)
# ------------------------------------------------------------------------------
def render_btn_smash():
    W, H = 136, 160
    img = create_canvas(W, H)
    draw = ImageDraw.Draw(img)
    
    cx, cy = (W * 0.5) * SCALE, 60 * SCALE
    r = 55 * SCALE
    theme_rgb = (255, 45, 45) # Blazing Crimson
    
    # 1. Soft atmospheric outer aura
    draw.ellipse([cx - r - 8*SCALE, cy - r - 8*SCALE, cx + r + 8*SCALE, cy + r + 8*SCALE], fill=(255, 45, 45, 50))
    # 2. Obsidian Glass Disc Body
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(42, 8, 8, 245))
    # 3. Outer Milled Metallic Bezel Rim
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 70, 70, 250), width=max(1, int(3.4 * SCALE)))
    draw_cardinal_notches(draw, cx, cy, r, length=11*SCALE, width=int(2.6*SCALE))
    # 4. Top specular glass arc
    draw.arc([cx - r + 7*SCALE, cy - r + 5*SCALE, cx + r - 7*SCALE, cy + r - 5*SCALE], 200, 340, fill=(255, 255, 255, 90), width=max(1, int(2.4 * SCALE)))
    
    # 5. ICON: Downward Lightning Spike + Impact Sparks
    bolt_pts = [
        (cx + 10*SCALE, cy - 27*SCALE),
        (cx - 7*SCALE, cy - 2*SCALE),
        (cx + 7*SCALE, cy - 1*SCALE),
        (cx - 12*SCALE, cy + 26*SCALE)
    ]
    for i in range(len(bolt_pts) - 1):
        draw.line([bolt_pts[i], bolt_pts[i+1]], fill=(255, 45, 45, 130), width=max(1, int(9 * SCALE)))
    for i in range(len(bolt_pts) - 1):
        draw.line([bolt_pts[i], bolt_pts[i+1]], fill=(255, 50, 50, 255), width=max(1, int(4.6 * SCALE)))
    for i in range(len(bolt_pts) - 1):
        draw.line([bolt_pts[i], bolt_pts[i+1]], fill=(255, 245, 210, 255), width=max(1, int(2.2 * SCALE)))
        
    ip_x, ip_y = bolt_pts[-1]
    draw.ellipse([ip_x - 5.5*SCALE, ip_y - 5.5*SCALE, ip_x + 5.5*SCALE, ip_y + 5.5*SCALE], fill=(255, 255, 220, 255))
    draw.line([(ip_x, ip_y), (ip_x - 12*SCALE, ip_y + 7*SCALE)], fill=theme_rgb, width=max(1, int(2.8 * SCALE)))
    draw.line([(ip_x, ip_y), (ip_x - 4*SCALE, ip_y + 12*SCALE)], fill=theme_rgb, width=max(1, int(2.8 * SCALE)))
    draw.line([(ip_x, ip_y), (ip_x + 9*SCALE, ip_y + 7*SCALE)], fill=theme_rgb, width=max(1, int(2.8 * SCALE)))
    
    draw.line([(cx - 23*SCALE, cy - 9*SCALE), (cx - 15*SCALE, cy + 7*SCALE)], fill=(255, 90, 90, 190), width=max(1, int(2.6 * SCALE)))
    draw.line([(cx + 23*SCALE, cy - 9*SCALE), (cx + 15*SCALE, cy + 7*SCALE)], fill=(255, 90, 90, 190), width=max(1, int(2.6 * SCALE)))
    
    # Bottom badge
    draw_pill_badge(draw, cx, 141 * SCALE, "ĐẬP CẦU", theme_rgb, font_size=12)
    
    return finalize(img, W, H)

def main():
    out_dir = "assets/ui/touch"
    os.makedirs(out_dir, exist_ok=True)
    
    track = render_track()
    track.save(os.path.join(out_dir, "touch_track.png"))
    print("Saved touch_track.png (270x112)")
    
    knob = render_knob()
    knob.save(os.path.join(out_dir, "touch_knob.png"))
    print("Saved touch_knob.png (84x84)")
    
    slide = render_btn_slide()
    slide.save(os.path.join(out_dir, "btn_slide.png"))
    print("Saved btn_slide.png (118x140)")

    drop = render_btn_drop()
    drop.save(os.path.join(out_dir, "btn_drop.png"))
    print("Saved btn_drop.png (118x140)")
    
    clear = render_btn_clear()
    clear.save(os.path.join(out_dir, "btn_clear.png"))
    print("Saved btn_clear.png (118x140)")
    
    jump = render_btn_jump()
    jump.save(os.path.join(out_dir, "btn_jump.png"))
    print("Saved btn_jump.png (136x160)")
    
    smash = render_btn_smash()
    smash.save(os.path.join(out_dir, "btn_smash.png"))
    print("Saved btn_smash.png (136x160)")
    
    # Create montage for inspection artifact
    montage = Image.new("RGBA", (850, 360), (10, 15, 25, 255))
    montage.paste(track, (20, 40), track)
    montage.paste(knob, (113, 54), knob)
    montage.paste(slide, (310, 20), slide)
    montage.paste(drop, (440, 20), drop)
    montage.paste(clear, (570, 20), clear)
    montage.paste(jump, (700, 10), jump)
    montage.paste(smash, (700, 180), smash)
    
    artifact_path = "C:/Users/sieut/.gemini/antigravity/brain/1c65eb4a-1be9-4d1b-977b-b853216b922a/touch_controls_preview.png"
    montage.save(artifact_path)
    print("Saved montage artifact to", artifact_path)

if __name__ == "__main__":
    main()
