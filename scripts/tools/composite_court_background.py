import os
from PIL import Image, ImageEnhance
import numpy as np

def generate_perfect_court_background():
    bg_src = r"C:\Users\sieut\.gemini\antigravity\brain\1c65eb4a-1be9-4d1b-977b-b853216b922a\badminton_arena_side_scroll_1794935462318.jpg"
    out_dst = r"assets\images\stadium_court.png"
    
    # 1. Base Arena Background (Full HD 1920x1080)
    im = Image.open(bg_src).resize((1920, 1080), Image.Resampling.LANCZOS)
    arr = np.array(im)
    
    # 2. Dịch trục Y xuống dưới 41px in 1080p (27.3px in 720p)
    # để vạch GIỮA sân gốc nằm chính xác tại FLOOR_Y = 550.0 nơi chân người chơi đứng
    shift_y = 41
    new_arr = np.zeros_like(arr)
    new_arr[shift_y:, :] = arr[:1080 - shift_y, :]
    for r in range(shift_y):
        new_arr[r, :] = arr[0, :]
    im_shifted = Image.fromarray(new_arr)
    
    # 3. Kéo dãn bề ngang (X) với tỉ lệ 1.269 tâm tại X = 960 (640 in 720p)
    # Kết quả:
    # - Baseline trái nằm chính xác tại X_720 = 140.0 (LEFT_OUT_X)
    # - Baseline phải nằm chính xác tại X_720 = 1140.0 (RIGHT_OUT_X)
    # - Vạch giao cầu gần trái nằm tại X_720 = 495.0
    # - Vạch giao cầu gần phải nằm tại X_720 = 785.0
    scale_x = 1.269
    new_w = int(1920 * scale_x)
    stretched = im_shifted.resize((new_w, 1080), Image.Resampling.LANCZOS)
    
    left = (new_w - 1920) // 2
    cropped = stretched.crop((left, 0, left + 1920, 1080))
    
    # 4. Tinh chỉnh độ tương phản và màu sắc chân thực
    enh_col = ImageEnhance.Color(cropped)
    im_vibrant = enh_col.enhance(1.08)
    enh_sharp = ImageEnhance.Sharpness(im_vibrant)
    im_sharp = enh_sharp.enhance(1.22)
    enh_con = ImageEnhance.Contrast(im_sharp)
    im_final = enh_con.enhance(1.04)
    
    im_final.save(out_dst, "PNG", optimize=True)
    print(f"Successfully generated wide stadium court (Baselines at 140 & 1140) at {out_dst}")

if __name__ == "__main__":
    generate_perfect_court_background()
