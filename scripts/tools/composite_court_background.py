import os
from PIL import Image, ImageFilter, ImageEnhance

def generate_perfect_court_background():
    bg_src = r"C:\Users\sieut\.gemini\antigravity\brain\1c65eb4a-1be9-4d1b-977b-b853216b922a\badminton_arena_side_scroll_1794935462318.jpg"
    out_dst = r"assets\images\stadium_court.png"
    
    # 1. Base Arena Background (Full HD 1920x1080)
    # Giữ nguyên 100% sân 3D Olympic siêu thực của ảnh AI gốc, không vẽ đè bất kỳ lớp sân nào lên trên!
    bg = Image.open(bg_src).resize((1920, 1080), Image.Resampling.LANCZOS)
    
    # Tinh chỉnh độ tương phản, độ sắc nét và màu sắc rực rỡ chân thực
    enh_col = ImageEnhance.Color(bg)
    bg_vibrant = enh_col.enhance(1.08)
    
    enh_sharp = ImageEnhance.Sharpness(bg_vibrant)
    bg_sharp = enh_sharp.enhance(1.25)
    
    enh_con = ImageEnhance.Contrast(bg_sharp)
    bg_final = enh_con.enhance(1.04)
    
    bg_final.save(out_dst, "PNG", optimize=True)
    print(f"Successfully exported clean pure stadium court to {out_dst}")

if __name__ == "__main__":
    generate_perfect_court_background()
