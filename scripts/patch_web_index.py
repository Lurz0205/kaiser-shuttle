#!/usr/bin/env python3
import sys
import os
import re
import time

def patch_index_html(build_dir, build_hash=None):
    if not build_hash:
        build_hash = str(int(time.time()))
    index_path = os.path.join(build_dir, "index.html")
    if not os.path.exists(index_path):
        print(f"Error: {index_path} not found!")
        sys.exit(1)

    with open(index_path, "r", encoding="utf-8") as f:
        html = f.read()

    # 1. Force experimentalVK: true
    html = re.sub(r'"experimentalVK"\s*:\s*false', '"experimentalVK":true', html)

    # 2. Add version hash to index.js and pwa_fullscreen.js
    html = re.sub(r'src=["\']index\.js(?:\?v=\d+)?["\']', f'src="index.js?v={build_hash}"', html)
    html = re.sub(r'src=["\']pwa_fullscreen\.js(?:\?v=\d+)?["\']', f'src="pwa_fullscreen.js?v={build_hash}"', html)

    # 3. Replace Godot robot logo splash screen with Kaiser Shuttle branded loader
    old_status_pattern = r'<div id="status">[\s\S]*?<div id="status-notice"></div>\s*</div>'
    new_status = f'''<div id="status" style="background: radial-gradient(circle at center, #111a2e 0%, #060911 100%); display: flex; flex-direction: column; justify-content: center; align-items: center; z-index: 99999;">
\t\t\t<img id="status-splash" src="icon_192.png?v={build_hash}" alt="Kaiser Shuttle" style="width: 104px; height: 104px; border-radius: 22px; margin-bottom: 24px; box-shadow: 0 10px 35px rgba(0,0,0,0.6); object-fit: cover;">
\t\t\t<progress id="status-progress" style="width: 250px; height: 7px; border-radius: 4px; accent-color: #f59e0b;"></progress>
\t\t\t<div id="status-text" style="color: #cbd5e1; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 13px; font-weight: 600; margin-top: 14px; letter-spacing: 0.5px;">Đang tải dữ liệu trò chơi...</div>
\t\t\t<div id="status-notice"></div>
\t\t</div>'''
    html = re.sub(old_status_pattern, new_status, html)

    # 4. Enhance onProgress to update status-text percentage in real time
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
    print(f"[SUCCESS] Patched {index_path} with build hash v={build_hash}")

if __name__ == "__main__":
    b_dir = sys.argv[1] if len(sys.argv) > 1 else "build/web"
    b_hash = sys.argv[2] if len(sys.argv) > 2 else str(int(time.time()))
    patch_index_html(b_dir, b_hash)
