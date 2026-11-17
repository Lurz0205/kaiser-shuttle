import math
from PIL import Image, ImageDraw, ImageFilter

def create_shuttlecock_image(filepath="assets/images/shuttlecock.png", size=256):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    
    # Coordinate system centered at (cx, cy)
    # Forward direction (+X): Cork head
    # Backward direction (-X): Feathers
    cx = size // 2
    cy = size // 2
    
    # Scale factor
    scale = size / 128.0
    
    # Cork head parameters
    cork_x = cx + int(18 * scale)
    cork_r = int(12 * scale)
    
    # Feather cone parameters
    base_x = cx + int(8 * scale)
    base_ry = int(9 * scale)
    
    tip_x = cx - int(38 * scale)
    tip_ry = int(24 * scale)
    
    # 1. Subtle soft shadow under feathers
    shadow_pts = [
        (base_x, cy - base_ry),
        (cork_x + cork_r, cy),
        (base_x, cy + base_ry),
        (tip_x, cy + tip_ry + int(2 * scale)),
        (tip_x, cy - tip_ry - int(2 * scale))
    ]
    draw.polygon(shadow_pts, fill=(0, 0, 0, 40))
    
    # 2. Feather body background (darker interior of the shuttlecock cone)
    interior_pts = [
        (base_x, cy - base_ry + int(2 * scale)),
        (base_x, cy + base_ry - int(2 * scale)),
        (tip_x + int(4 * scale), cy + tip_ry - int(3 * scale)),
        (tip_x + int(4 * scale), cy - tip_ry + int(3 * scale))
    ]
    draw.polygon(interior_pts, fill=(210, 215, 225, 255))
    
    # 3. Individual Feathers (16 overlapping goose feathers)
    num_feathers = 14
    for i in range(num_feathers):
        # Y position of the feather tip
        frac = i / float(num_feathers - 1) # 0.0 (top) to 1.0 (bottom)
        y_tip = (cy - tip_ry) + frac * (2 * tip_ry)
        y_base = (cy - base_ry) + frac * (2 * base_ry)
        
        # Feather width
        f_width = 4.2 * scale
        
        # Layer shading: outer feathers lighter, inner ones slightly shaded
        dist_from_center = abs(frac - 0.5) * 2.0 # 0 at center, 1 at edges
        lum = int(242 + 13 * (1.0 - dist_from_center))
        feather_col = (lum, lum, min(255, lum + 5), 255)
        
        # Feather polygon (tapered vane with rounded tip)
        pts = [
            (base_x, y_base - f_width * 0.4),
            (base_x - int(8 * scale), y_base + (y_tip - y_base) * 0.2 - f_width * 0.6),
            (tip_x + int(4 * scale), y_tip - f_width),
            (tip_x, y_tip),
            (tip_x + int(4 * scale), y_tip + f_width),
            (base_x - int(8 * scale), y_base + (y_tip - y_base) * 0.2 + f_width * 0.6),
            (base_x, y_base + f_width * 0.4)
        ]
        draw.polygon(pts, fill=feather_col)
        # Delicate feather edge outline
        draw.line(pts, fill=(185, 192, 205, 180), width=max(1, int(1.2 * scale)))
        
        # Central Quill / Rachis (shaft)
        quill_pts = [
            (base_x + int(2 * scale), y_base),
            (tip_x + int(2 * scale), y_tip)
        ]
        draw.line(quill_pts, fill=(255, 255, 255, 230), width=max(1, int(1.5 * scale)))
    
    # 4. Concentric Binding Threads (Blue and Red)
    # Ribbon 1 (Outer blue thread)
    ribbon1_x = tip_x + int(15 * scale)
    r1_ry = int(base_ry + (tip_ry - base_ry) * 0.55)
    r1_pts = []
    for y_step in range(-r1_ry, r1_ry + 1, 2):
        # Elliptical arc across depth
        arch = math.cos((y_step / float(r1_ry)) * (math.pi / 2.0)) * (3.5 * scale)
        r1_pts.append((ribbon1_x + arch, cy + y_step))
    draw.line(r1_pts, fill=(40, 95, 210, 240), width=max(1, int(2.2 * scale)))
    
    # Ribbon 2 (Inner red thread)
    ribbon2_x = tip_x + int(25 * scale)
    r2_ry = int(base_ry + (tip_ry - base_ry) * 0.28)
    r2_pts = []
    for y_step in range(-r2_ry, r2_ry + 1, 2):
        arch = math.cos((y_step / float(r2_ry)) * (math.pi / 2.0)) * (2.8 * scale)
        r2_pts.append((ribbon2_x + arch, cy + y_step))
    draw.line(r2_pts, fill=(225, 45, 45, 240), width=max(1, int(2.2 * scale)))
    
    # 5. Cork Base (Dome Head at the right / +X)
    # Neck red tape
    neck_x1 = base_x
    neck_x2 = cork_x - int(2 * scale)
    neck_pts = [
        (neck_x1, cy - base_ry),
        (neck_x2, cy - cork_r + int(2 * scale)),
        (neck_x2, cy + cork_r - int(2 * scale)),
        (neck_x1, cy + base_ry)
    ]
    draw.polygon(neck_pts, fill=(215, 35, 35, 255))
    draw.line([neck_pts[0], neck_pts[1]], fill=(255, 80, 80, 200), width=int(1.5 * scale))
    draw.line([neck_pts[3], neck_pts[2]], fill=(140, 20, 20, 200), width=int(1.5 * scale))
    
    # Cork Dome (Composite leather white cork with 3D spherical gradient)
    cork_bbox = [cork_x - cork_r, cy - cork_r, cork_x + cork_r, cy + cork_r]
    # Base cork color
    draw.chord(cork_bbox, start=270, end=90, fill=(245, 248, 252, 255), outline=(170, 180, 195, 255), width=max(1, int(1.5 * scale)))
    
    # 3D Highlight & Spherical Sheen
    highlight_bbox = [cork_x - int(cork_r * 0.3), cy - int(cork_r * 0.7), cork_x + int(cork_r * 0.7), cy + int(cork_r * 0.2)]
    draw.ellipse(highlight_bbox, fill=(255, 255, 255, 180))
    
    # Gold accent badge on the cork head
    badge_pts = [
        (cork_x + int(6 * scale), cy - int(4 * scale)),
        (cork_x + int(6 * scale), cy + int(4 * scale))
    ]
    draw.line(badge_pts, fill=(235, 185, 40, 230), width=max(1, int(2.0 * scale)))
    
    # Gentle antialiasing blur pass
    im = im.filter(ImageFilter.SMOOTH_MORE)
    
    im.save(filepath, format="PNG")
    print(f"Saved shuttlecock art to {filepath} ({size}x{size})")

if __name__ == "__main__":
    create_shuttlecock_image()
