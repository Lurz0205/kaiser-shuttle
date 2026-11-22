#!/usr/bin/env python3
import sys
import os
import re
import time
import shutil

def patch_index_html(build_dir, build_hash=None):
    if not build_hash:
        build_hash = str(int(time.time()))
    index_path = os.path.join(build_dir, "index.html")
    if not os.path.exists(index_path):
        print(f"Error: {index_path} not found!")
        sys.exit(1)

    # 1. Ensure logo image from TAI NGUYEN is placed into build_dir as logo_kaiser_shuttle.png
    target_logo = os.path.join(build_dir, "logo_kaiser_shuttle.png")
    if not os.path.exists(target_logo):
        src_candidates = [
            "assets/icons/logo_kaiser_shuttle.png",
            "TAI NGUYEN/Logo game tốc độ Kaiser Shuttle.png",
            os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "TAI NGUYEN", "Logo game tốc độ Kaiser Shuttle.png"),
            os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "icons", "logo_kaiser_shuttle.png")
        ]
        for src in src_candidates:
            if os.path.exists(src):
                shutil.copyfile(src, target_logo)
                print(f"[COPIED] Placed logo: {src} -> {target_logo}")
                break

    with open(index_path, "r", encoding="utf-8") as f:
        html = f.read()

    # 2. Disable experimentalVK (Godot's experimentalVK creates a hidden DOM input that causes
    # mobile browser viewport scroll/shift and breaks Backspace on Android Gboard keycode 229)
    html = re.sub(r'"experimentalVK"\s*:\s*true', '"experimentalVK":false', html)
    html = re.sub(r'"experimentalVK"\s*:\s*false', '"experimentalVK":false', html)

    # 3. Add version hash to index.js and pwa_fullscreen.js
    html = re.sub(r'src=["\']index\.js(?:\?v=\d+)?["\']', f'src="index.js?v={build_hash}"', html)
    html = re.sub(r'src=["\']pwa_fullscreen\.js(?:\?v=\d+)?["\']', f'src="pwa_fullscreen.js?v={build_hash}"', html)

    # 4. Replace CSS in <style> to center the logo and loader perfectly
    style_pattern = r'#status[\s\S]*?#status-notice\s*\{[\s\S]*?\}'
    new_style = '''html, body {
	position: fixed !important;
	top: 0 !important;
	left: 0 !important;
	width: 100% !important;
	height: 100% !important;
	overflow: hidden !important;
	margin: 0 !important;
	padding: 0 !important;
	touch-action: none !important;
	-webkit-text-size-adjust: 100% !important;
}

#canvas {
	position: fixed !important;
	top: 0 !important;
	left: 0 !important;
	width: 100% !important;
	height: 100% !important;
	display: block !important;
	outline: none !important;
}

#status {
	position: absolute;
	left: 0;
	top: 0;
	right: 0;
	bottom: 0;
	background: radial-gradient(circle at center, #111a2e 0%, #060911 100%);
	display: flex;
	flex-direction: column;
	justify-content: center;
	align-items: center;
	visibility: hidden;
	z-index: 99999;
}

#status-container {
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	width: 100%;
	max-width: 90vw;
	margin: auto;
}

#status-splash {
	display: block;
	width: min(540px, 86vw);
	max-height: 28vh;
	height: auto;
	object-fit: contain;
	margin: 0 0 24px 0;
	filter: drop-shadow(0 14px 35px rgba(0, 0, 0, 0.75));
}

#status-progress {
	display: block;
	width: min(320px, 78vw);
	height: 8px;
	border-radius: 6px;
	border: none;
	background-color: rgba(255, 255, 255, 0.12);
	accent-color: #f59e0b;
	box-shadow: 0 0 16px rgba(245, 158, 11, 0.35);
	margin: 0 auto;
}

#status-progress::-webkit-progress-bar {
	background-color: rgba(255, 255, 255, 0.12);
	border-radius: 6px;
}

#status-progress::-webkit-progress-value {
	background: linear-gradient(90deg, #f59e0b, #fbbf24);
	border-radius: 6px;
}

#status-text {
	color: #cbd5e1;
	font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
	font-size: 14px;
	font-weight: 600;
	margin-top: 14px;
	letter-spacing: 0.6px;
	text-align: center;
	text-shadow: 0 2px 4px rgba(0, 0, 0, 0.85);
}

#status-notice {
	display: none;
	background-color: #5b3943;
	border-radius: 0.5rem;
	border: 1px solid #9b3943;
	color: #e0e0e0;
	font-family: 'Noto Sans', 'Droid Sans', Arial, sans-serif;
	line-height: 1.3;
	margin: 1rem 2rem;
	overflow: hidden;
	padding: 1rem;
	text-align: center;
	z-index: 1;
}'''
    if re.search(style_pattern, html):
        html = re.sub(style_pattern, new_style, html)
    else:
        # If pattern didn't match directly, insert before </style>
        html = html.replace('</style>', f'\n{new_style}\n</style>')

    # 5. Replace Godot status HTML with centered Kaiser Shuttle logo and loader
    status_pattern = r'<div id="status"[^>]*>[\s\S]*?<div id="status-notice">[\s\S]*?</div>(?:\s*</div>)*\s*</div>'
    new_status = f'''<div id="status">
\t\t\t<div id="status-container">
\t\t\t\t<img id="status-splash" src="logo_kaiser_shuttle.png?v={build_hash}" alt="Kaiser Shuttle">
\t\t\t\t<progress id="status-progress"></progress>
\t\t\t\t<div id="status-text">Đang tải dữ liệu trò chơi...</div>
\t\t\t\t<div id="status-notice"></div>
\t\t\t</div>
\t\t</div>'''
    html = re.sub(status_pattern, new_status, html)

    # 6. Enhance onProgress to update status-text percentage in real time
    old_progress = r"'onProgress': function \(current, total\) \{[\s\S]*?\},"
    new_progress = '''\'onProgress\': function (current, total) {
\t\t\t\tconst txt = document.getElementById('status-text');
\t\t\t\tif (current > 0 && total > 0) {
\t\t\t\t\tstatusProgress.value = current;
\t\t\t\t\tstatusProgress.max = total;
\t\t\t\t\tconst pct = Math.floor((current / total) * 100);
\t\t\t\t\tif (txt) txt.textContent = 'Đang tải dữ liệu trò chơi: ' + pct + '%';
\t\t\t\t} else if (current > 0) {
\t\t\t\t\tstatusProgress.removeAttribute('value');
\t\t\t\t\tstatusProgress.removeAttribute('max');
\t\t\t\t\tconst mb = (current / 1048576).toFixed(1);
\t\t\t\t\tif (txt) txt.textContent = 'Đang tải: ' + mb + ' MB...';
\t\t\t\t}
\t\t\t},'''
    html = re.sub(old_progress, new_progress, html)

    with open(index_path, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"[SUCCESS] Patched {index_path} with build hash v={build_hash} and centered Kaiser Shuttle logo")

if __name__ == "__main__":
    b_dir = sys.argv[1] if len(sys.argv) > 1 else "build/web"
    b_hash = sys.argv[2] if len(sys.argv) > 2 else str(int(time.time()))
    patch_index_html(b_dir, b_hash)
