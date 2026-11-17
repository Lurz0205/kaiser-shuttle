import os
from PIL import Image, ImageEnhance
import numpy as np

def generate_perfect_court_background():
    bg_src = r"C:\Users\sieut\.gemini\antigravity\brain\1c65eb4a-1be9-4d1b-977b-b853216b922a\badminton_arena_side_scroll_1794935462318.jpg"
    out_dst = r"assets\images\stadium_court.png"
    
    # 1. Base Arena Background (Full HD 1920x1080)
    # Giữ nguyên 100% sân 3D Olympic siêu thực của ảnh AI gốc, không vẽ thêm bất kỳ đối tượng nào.
    im = Image.open(bg_src).resize((1920, 1080), Image.Resampling.LANCZOS)
    
    # Dịch toàn bộ sân lùi về 1 tí (35px trong 1080p = 23.3px trong 720p)
    # để vạch ngang giữa sân gốc nằm chính xác tại FLOOR_Y = 550.0 nơi chân người chơi đứng!
    shift_y = 35
    arr = np.array(im)
    new_arr = np.zeros_like(arr)
    new_arr[:1080 - shift_y, :] = arr[shift_y:, :]
    
    # Mở rộng sàn gỗ ở đáy liền mạch
    for r in range(1080 - shift_y, 1080):
        src_r = (1080 - shift_y - 1) - (r - (1080 - shift_y)) % 16
        new_arr[r, :] = arr[src_r, :]
        
    res_img = Image.fromarray(new_arr)
    
    # Tinh chỉnh tương phản và màu sắc chân thực
    enh_col = ImageEnhance.Color(res_img)
    im_vibrant = enh_col.enhance(1.08)
    enh_sharp = ImageEnhance.Sharpness(im_vibrant)
    im_sharp = enh_sharp.enhance(1.20)
    enh_con = ImageEnhance.Contrast(im_sharp)
    im_final = enh_con.enhance(1.04)
    
    im_final.save(out_dst, "PNG", optimize=True)
    print(f"Successfully generated clean stadium court (line at exactly 550.0) at {out_dst}")

if __name__ == "__main__":
    generate_perfect_court_background()
