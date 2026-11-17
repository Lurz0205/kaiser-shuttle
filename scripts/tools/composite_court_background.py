import math
import os
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

def generate_perfect_court_background():
    bg_src = r"C:\Users\sieut\.gemini\antigravity\brain\1c65eb4a-1be9-4d1b-977b-b853216b922a\badminton_arena_side_scroll_1794935462318.jpg"
    out_dst = r"assets\images\stadium_court.png"
    
    # 1. Base Arena Background (Full HD 1920x1080)
    bg = Image.open(bg_src).resize((1920, 1080), Image.Resampling.LANCZOS)
    
    # Enhance background contrast & sharpness
    bg_sharp = bg.filter(ImageFilter.UnsharpMask(radius=1.2, percent=125, threshold=2))
    enh_col = ImageEnhance.Color(bg_sharp)
    bg_vibrant = enh_col.enhance(1.05)
    
    # Overlay for Court Mat & Crisp BWF Tournament Lines
    overlay = Image.new("RGBA", (1920, 1080), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    
    # Exact Coordinate Mapping (1920x1080 = 1.5x of Godot 1280x720):
    # Floor line Y = 550.0 * 1.5 = 825.0
    # Net X = 640.0 * 1.5 = 960.0
    # Left Baseline X = 140.0 * 1.5 = 210.0 (EXACT match to LEFT_OUT_X = 140.0)
    # Right Baseline X = 1140.0 * 1.5 = 1710.0 (EXACT match to RIGHT_OUT_X = 1140.0)
    # Short Service Left X = 450.0 * 1.5 = 675.0 (EXACT match to SHORT_SERVICE_LEFT = 450.0)
    # Short Service Right X = 830.0 * 1.5 = 1245.0 (EXACT match to SHORT_SERVICE_RIGHT = 830.0)
    # Left Court Center X = 390.0 * 1.5 = 585.0 (Dead center of left half court: (140 + 640)/2 = 390.0)
    # Right Court Center X = 890.0 * 1.5 = 1335.0 (Dead center of right half court: (640 + 1140)/2 = 890.0)
    
    # Court Depth (Y from 480 to 620 in Godot -> 720 to 930 in 1080p)
    # y_mid = (720 + 930) / 2 = 825.0 -> FLOOR_Y (550.0) is DEAD CENTER of court depth!
    y_top = 720
    y_bot = 930
    y_mid = 825
    
    # -------------------------------------------------------------
    # 1. OUTER SAFETY RUN-OFF MAT (Dark Forest Green)
    # -------------------------------------------------------------
    # Extends 50px outside each baseline into the wooden floor
    x_apron_left_top = 150
    x_apron_left_bot = 120
    x_apron_right_top = 1770
    x_apron_right_bot = 1800
    
    apron_pts = [
        (x_apron_left_top, y_top - 6),
        (x_apron_right_top, y_top - 6),
        (x_apron_right_bot, y_bot + 6),
        (x_apron_left_bot, y_bot + 6)
    ]
    draw.polygon(apron_pts, fill=(18, 68, 42, 245))
    
    # -------------------------------------------------------------
    # 2. OFFICIAL TOURNAMENT VINYL MAT (BWF Green)
    # -------------------------------------------------------------
    x_mat_left_top = 180
    x_mat_left_bot = 160
    x_mat_right_top = 1740
    x_mat_right_bot = 1760
    
    court_mat_pts = [
        (x_mat_left_top, y_top),
        (x_mat_right_top, y_top),
        (x_mat_right_bot, y_bot),
        (x_mat_left_bot, y_bot)
    ]
    draw.polygon(court_mat_pts, fill=(28, 130, 80, 255))
    
    # Soft Arena Overhead Lighting Sheen in active playing field
    sheen_pts = [
        (210, y_top + 6),
        (1710, y_top + 6),
        (1710, y_bot - 8),
        (210, y_bot - 8)
    ]
    draw.polygon(sheen_pts, fill=(45, 165, 102, 70))
    
    # Wood Floor Trim Edges (Outer border transition)
    draw.line([(x_apron_left_bot, y_bot + 6), (x_apron_right_bot, y_bot + 6)], fill=(195, 145, 55, 220), width=3)
    draw.line([(x_apron_left_top, y_top - 6), (x_apron_right_top, y_top - 6)], fill=(25, 18, 10, 180), width=3)
    
    # -------------------------------------------------------------
    # 3. HIGH-CONTRAST BWF COURT MARKINGS (IN vs OUT RESOLUTION)
    # -------------------------------------------------------------
    col_line = (255, 255, 255, 255)
    col_line_glow = (255, 255, 255, 95)
    col_gold_accent = (255, 225, 75, 235)
    
    # BASELINES: Left = 210, Right = 1710 (EXACT match to LEFT_OUT_X = 140.0, RIGHT_OUT_X = 1140.0)
    x_bl_left = 210
    x_bl_right = 1710
    
    # A. Sidelines (Top & Bottom horizontal boundaries)
    draw.line([(x_bl_left, y_top), (x_bl_right, y_top)], fill=col_line, width=4)
    draw.line([(x_bl_left, y_bot), (x_bl_right, y_bot)], fill=col_line, width=5)
    
    # B. Left Baseline (Ultra-clear white line with high-contrast indicator)
    draw.line([(x_bl_left, y_top - 2), (x_bl_left, y_bot + 2)], fill=col_line_glow, width=12)
    draw.line([(x_bl_left, y_top), (x_bl_left, y_bot)], fill=col_line, width=5)
    # Bold golden tick at player running axis (y_mid)
    draw.line([(x_bl_left - 12, y_mid), (x_bl_left + 12, y_mid)], fill=col_gold_accent, width=5)
    
    # C. Right Baseline (Ultra-clear white line with high-contrast indicator)
    draw.line([(x_bl_right, y_top - 2), (x_bl_right, y_bot + 2)], fill=col_line_glow, width=12)
    draw.line([(x_bl_right, y_top), (x_bl_right, y_bot)], fill=col_line, width=5)
    # Bold golden tick at player running axis (y_mid)
    draw.line([(x_bl_right - 12, y_mid), (x_bl_right + 12, y_mid)], fill=col_gold_accent, width=5)
    
    # D. Corner L-Brackets at all four boundary corners
    corner_arm = 36
    # Top-Left corner
    draw.line([(x_bl_left, y_top), (x_bl_left + corner_arm, y_top)], fill=col_gold_accent, width=4)
    draw.line([(x_bl_left, y_top), (x_bl_left, y_top + corner_arm)], fill=col_gold_accent, width=4)
    # Bottom-Left corner
    draw.line([(x_bl_left, y_bot), (x_bl_left + corner_arm, y_bot)], fill=col_gold_accent, width=4)
    draw.line([(x_bl_left, y_bot), (x_bl_left, y_bot - corner_arm)], fill=col_gold_accent, width=4)
    # Top-Right corner
    draw.line([(x_bl_right, y_top), (x_bl_right - corner_arm, y_top)], fill=col_gold_accent, width=4)
    draw.line([(x_bl_right, y_top), (x_bl_right, y_top + corner_arm)], fill=col_gold_accent, width=4)
    # Bottom-Right corner
    draw.line([(x_bl_right, y_bot), (x_bl_right - corner_arm, y_bot)], fill=col_gold_accent, width=4)
    draw.line([(x_bl_right, y_bot), (x_bl_right, y_bot - corner_arm)], fill=col_gold_accent, width=4)
    
    # E. Short Service Lines (EXACT match to SHORT_SERVICE_LEFT = 450.0, SHORT_SERVICE_RIGHT = 830.0)
    # Left: 450.0 * 1.5 = 675
    # Right: 830.0 * 1.5 = 1245
    x_ssl_left = 675
    x_ssl_right = 1245
    draw.line([(x_ssl_left, y_top), (x_ssl_left, y_bot)], fill=col_line, width=4)
    draw.line([(x_ssl_right, y_top), (x_ssl_right, y_bot)], fill=col_line, width=4)
    
    # F. Center Service Lines (Horizontal at y_mid = 825, running from Baseline to Short Service Line)
    # Left court center line (from 210 to 675)
    draw.line([(x_bl_left, y_mid), (x_ssl_left, y_mid)], fill=(255, 255, 255, 185), width=3)
    # Right court center line (from 1245 to 1710)
    draw.line([(x_ssl_right, y_mid), (x_bl_right, y_mid)], fill=(255, 255, 255, 185), width=3)
    
    # -------------------------------------------------------------
    # 4. COURT CENTER MARKERS (MID-COURT SWEET SPOTS)
    # -------------------------------------------------------------
    # Left Half-Court Center: 390.0 * 1.5 = 585
    # Right Half-Court Center: 890.0 * 1.5 = 1335
    for cx in [585, 1335]:
        draw.ellipse([cx - 20, y_mid - 20, cx + 20, y_mid + 20], outline=(255, 255, 255, 75), width=2)
        draw.ellipse([cx - 5, y_mid - 5, cx + 5, y_mid + 5], fill=(255, 255, 255, 120))
    
    # -------------------------------------------------------------
    # 5. PROFESSIONAL BADMINTON NET (NET_X = 640.0 -> 960 in 1080p)
    # -------------------------------------------------------------
    net_x = 960
    net_top_y = 590
    net_bot_y = 825
    
    # Dark fine mesh body
    mesh_box = [net_x - 3, net_top_y, net_x + 3, net_bot_y]
    draw.rectangle(mesh_box, fill=(20, 28, 40, 220))
    
    # Mesh texture lines
    for gy in range(net_top_y + 12, net_bot_y, 14):
        draw.line([(net_x - 3, gy), (net_x + 3, gy)], fill=(120, 140, 165, 160), width=1)
    
    # Net Posts (Cột lưới 2 bên)
    post_col = (20, 24, 32, 255)
    draw.rectangle([net_x - 4, net_top_y - 6, net_x - 1, net_bot_y + 6], fill=post_col)
    draw.rectangle([net_x + 1, net_top_y - 6, net_x + 4, net_bot_y + 6], fill=post_col)
    
    # Heavy White Top Tape (Viền mép trên màu trắng sắc nét của lưới)
    draw.rectangle([net_x - 5, net_top_y - 4, net_x + 5, net_top_y + 4], fill=(255, 255, 255, 255))
    draw.rectangle([net_x - 4, net_top_y - 2, net_x + 4, net_top_y + 2], fill=(240, 245, 255, 255))
    
    # Bottom Base Mounts
    draw.ellipse([net_x - 10, net_bot_y - 4, net_x + 10, net_bot_y + 8], fill=(15, 18, 24, 230))
    
    # -------------------------------------------------------------
    # 6. COMPOSITE AND SAVE
    # -------------------------------------------------------------
    final_img = Image.alpha_composite(bg_vibrant.convert("RGBA"), overlay)
    final_img.convert("RGB").save(out_dst, "PNG", optimize=True)
    print(f"Successfully generated perfect court stadium image at {out_dst}")

if __name__ == "__main__":
    generate_perfect_court_background()
