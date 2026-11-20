import os
from PIL import Image, ImageDraw, ImageFont

def create_pwa_icon(size: int, output_path: str, maskable: bool = False):
    img = Image.new("RGBA", (size, size), (7, 12, 22, 255))
    draw = ImageDraw.Draw(img)
    
    # Outer glowing border
    pad = int(size * 0.08) if maskable else int(size * 0.04)
    r = int(size * 0.22)
    draw.rounded_rectangle([pad, pad, size - pad, size - pad], radius=r, fill=(12, 20, 36, 255), outline=(0, 229, 255, 220), width=max(2, int(size * 0.015)))
    
    cx = size // 2
    cy = int(size * 0.44)
    scale = size / 512.0
    
    # Gold electric lightning bolt in background
    bolt_pts = [
        (cx + int(30 * scale), cy - int(120 * scale)),
        (cx - int(25 * scale), cy - int(10 * scale)),
        (cx + int(20 * scale), cy),
        (cx - int(45 * scale), cy + int(110 * scale)),
        (cx + int(10 * scale), cy + int(20 * scale)),
        (cx - int(10 * scale), cy + int(10 * scale)),
        (cx + int(50 * scale), cy - int(80 * scale))
    ]
    draw.polygon(bolt_pts, fill=(255, 179, 0, 180), outline=(255, 235, 59, 255))
    
    # Center shuttlecock cork
    cork_y = cy + int(50 * scale)
    cork_r = int(24 * scale)
    draw.ellipse([cx - cork_r, cork_y - cork_r, cx + cork_r, cork_y + cork_r], fill=(255, 255, 255, 255), outline=(0, 229, 255, 255), width=max(2, int(size * 0.01)))
    
    # Shuttlecock feathers spreading upward
    feather_pts = [
        (cx - cork_r, cork_y - int(5 * scale)),
        (cx - int(65 * scale), cy - int(60 * scale)),
        (cx - int(45 * scale), cy - int(80 * scale)),
        (cx, cy - int(70 * scale)),
        (cx + int(45 * scale), cy - int(80 * scale)),
        (cx + int(65 * scale), cy - int(60 * scale)),
        (cx + cork_r, cork_y - int(5 * scale))
    ]
    draw.polygon(feather_pts, fill=(18, 50, 80, 220), outline=(0, 229, 255, 255), width=max(2, int(size * 0.01)))
    
    # Feather inner spines
    for fx in [-40, -15, 15, 40]:
        draw.line([(cx, cork_y), (cx + int(fx * scale), cy - int(65 * scale))], fill=(0, 229, 255, 200), width=max(1, int(size * 0.006)))
    
    # Text badge "KAISER"
    text_y = int(size * 0.76)
    font_size = max(14, int(size * 0.10))
    try:
        font = ImageFont.truetype("arialbd.ttf", font_size)
    except:
        font = ImageFont.load_default()
        
    text = "KAISER"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text((cx - tw // 2, text_y), text, fill=(255, 255, 255, 255), font=font)
    
    sub_text = "SHUTTLE"
    sub_font_size = max(10, int(size * 0.06))
    try:
        sub_font = ImageFont.truetype("arial.ttf", sub_font_size)
    except:
        sub_font = ImageFont.load_default()
    s_bbox = draw.textbbox((0, 0), sub_text, font=sub_font)
    stw = s_bbox[2] - s_bbox[0]
    draw.text((cx - stw // 2, text_y + int(font_size * 1.15)), sub_text, fill=(0, 229, 255, 220), font=sub_font)
    
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    img.save(output_path, "PNG")
    print(f"Generated icon: {output_path} ({size}x{size})")

if __name__ == "__main__":
    create_pwa_icon(192, "assets/icons/icon_192.png")
    create_pwa_icon(512, "assets/icons/icon_512.png")
    create_pwa_icon(512, "assets/icons/icon_maskable.png", maskable=True)
