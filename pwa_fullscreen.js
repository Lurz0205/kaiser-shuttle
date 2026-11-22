// Kaiser Shuttle - High Performance Web & Mobile Platform Engine
// Optimized for 60-120+ FPS WebGL2 execution, Mobile Auto-Fullscreen, and Cache Auto-Purge
(function() {
    'use strict';

    // -------------------------------------------------------------
    // 1. Khử ServiceWorker cũ & Tự động tải mới .pck / .wasm (Bypass HTTP Cache)
    // -------------------------------------------------------------
    try {
        if ('serviceWorker' in navigator) {
            navigator.serviceWorker.getRegistrations().then(function(registrations) {
                for (var i = 0; i < registrations.length; i++) {
                    registrations[i].unregister().then(function(ok) {
                        if (ok) console.log('[Kaiser] Đã gỡ bỏ ServiceWorker cũ để cập nhật bản mới.');
                    });
                }
            }).catch(function() {});
        }
        if ('caches' in window) {
            caches.keys().then(function(names) {
                for (var j = 0; j < names.length; j++) {
                    caches.delete(names[j]);
                }
            }).catch(function() {});
        }
    } catch (e) {
        console.warn('[Kaiser] Cache purge check:', e);
    }

    // -------------------------------------------------------------
    // 1b. Transparent Network Cache-Busting cho .pck và .wasm
    // Đảm bảo trình duyệt luôn tải file mới nhất từ GitHub Pages,
    // không bao giờ bị kẹt gói cũ ở HTTP cache hay treo màn hình tải.
    // -------------------------------------------------------------
    try {
        var buildVer = Date.now();
        var origFetch = window.fetch;
        if (origFetch) {
            window.fetch = function(input, init) {
                if (typeof input === 'string') {
                    if (input.indexOf('.pck') !== -1 || input.indexOf('.wasm') !== -1) {
                        var sep = input.indexOf('?') === -1 ? '?' : '&';
                        input = input + sep + 'v=' + buildVer;
                    }
                } else if (input && input.url && typeof input.url === 'string') {
                    if (input.url.indexOf('.pck') !== -1 || input.url.indexOf('.wasm') !== -1) {
                        var sep2 = input.url.indexOf('?') === -1 ? '?' : '&';
                        input = new Request(input.url + sep2 + 'v=' + buildVer, input);
                    }
                }
                return origFetch.call(this, input, init);
            };
        }
    } catch (e) {
        console.warn('[Kaiser] Fetch cache-buster init:', e);
    }

    // -------------------------------------------------------------
    // 2. Mobile Auto-Fullscreen & Auto-Landscape (Xoay Ngang & Toàn Màn Hình Tự Động)
    // -------------------------------------------------------------
    var isMobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent) ||
                   (navigator.maxTouchPoints && navigator.maxTouchPoints > 1);

    function enterFullscreenAndLandscape() {
        var docEl = document.documentElement;
        var reqFS = docEl.requestFullscreen ||
                     docEl.webkitRequestFullscreen ||
                     docEl.mozRequestFullScreen ||
                     docEl.msRequestFullscreen;

        var isFS = document.fullscreenElement ||
                   document.webkitFullscreenElement ||
                   document.mozFullScreenElement ||
                   document.msFullscreenElement;

        if (reqFS && !isFS) {
            try {
                var p = reqFS.call(docEl);
                if (p && p.catch) p.catch(function() {});
            } catch (err) {}
        }

        if (screen.orientation && screen.orientation.lock) {
            try {
                screen.orientation.lock('landscape').catch(function() {
                    try { screen.orientation.lock('landscape-primary').catch(function() {}); } catch(e) {}
                });
            } catch (e) {}
        }
    }

    window.kaiserToggleFullscreen = function() {
        var docEl = document.documentElement;
        var isFS = document.fullscreenElement || document.webkitFullscreenElement || document.mozFullScreenElement || document.msFullscreenElement;
        if (!isFS) {
            enterFullscreenAndLandscape();
        } else {
            var exitFS = document.exitFullscreen || document.webkitExitFullscreen || document.mozCancelFullScreen || document.msExitFullscreen;
            if (exitFS) {
                try { exitFS.call(document); } catch (e) {}
            }
        }
    };

    // -------------------------------------------------------------
    // 2b. Orientation Guard: Thông báo và khóa xoay màn hình tự động
    // -------------------------------------------------------------
    function setupOrientationGuard() {
        try {
            var style = document.createElement('style');
            style.innerHTML = [
                '#kaiser_orientation_prompt {',
                '  position: fixed;',
                '  top: 0; left: 0; width: 100vw; height: 100vh;',
                '  background: radial-gradient(circle at center, #111a2e 0%, #060911 100%);',
                '  z-index: 2147483647;',
                '  display: none;',
                '  flex-direction: column;',
                '  align-items: center;',
                '  justify-content: center;',
                '  text-align: center;',
                '  color: #ffffff;',
                '  padding: 24px;',
                '  box-sizing: border-box;',
                '  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;',
                '}',
                '@media screen and (orientation: portrait) {',
                '  #kaiser_orientation_prompt { display: flex !important; }',
                '}',
                '@media screen and (orientation: landscape) {',
                '  #kaiser_orientation_prompt { display: none !important; }',
                '}',
                '@keyframes kaiserRotatePhone {',
                '  0% { transform: rotate(0deg); }',
                '  30% { transform: rotate(0deg); }',
                '  60% { transform: rotate(-90deg); }',
                '  100% { transform: rotate(-90deg); }',
                '}',
                '.kaiser-phone-anim {',
                '  font-size: 64px;',
                '  display: inline-block;',
                '  animation: kaiserRotatePhone 2s ease-in-out infinite alternate;',
                '  margin-bottom: 16px;',
                '}',
                '.kaiser-guard-title {',
                '  font-size: 22px; font-weight: 800; color: #fbbf24; margin-bottom: 10px;',
                '  letter-spacing: 0.5px; text-transform: uppercase;',
                '}',
                '.kaiser-guard-desc {',
                '  font-size: 14px; color: #cbd5e1; max-width: 320px; line-height: 1.5; margin-bottom: 24px;',
                '}',
                '.kaiser-guard-btn {',
                '  background: linear-gradient(135deg, #f59e0b, #d97706);',
                '  color: #fff; font-size: 15px; font-weight: 700; padding: 12px 28px;',
                '  border: none; border-radius: 8px; box-shadow: 0 4px 15px rgba(245, 158, 11, 0.4);',
                '  cursor: pointer;',
                '}'
            ].join('\n');
            document.head.appendChild(style);

            var overlay = document.createElement('div');
            overlay.id = 'kaiser_orientation_prompt';
            overlay.innerHTML = [
                '<div class="kaiser-phone-anim">📱</div>',
                '<div class="kaiser-guard-title">VUI LÒNG XOAY NGANG MÀN HÌNH</div>',
                '<div class="kaiser-guard-desc">Kaiser Shuttle được tối ưu hóa cho màn hình nằm ngang. Hãy bật tự động xoay và nghiêng điện thoại để thi đấu!</div>',
                '<button class="kaiser-guard-btn" onclick="kaiserToggleFullscreen()">⛶ BẬT TOÀN MÀN HÌNH & XOAY NGANG</button>'
            ].join('\n');
            document.body.appendChild(overlay);
        } catch(e) {
            console.warn('[Kaiser] Setup orientation guard:', e);
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', setupOrientationGuard);
    } else {
        setupOrientationGuard();
    }

    if (isMobile) {
        // A. Thử gọi ngay khi trang vừa tải xong
        if (document.readyState === 'complete' || document.readyState === 'interactive') {
            enterFullscreenAndLandscape();
        } else {
            window.addEventListener('DOMContentLoaded', enterFullscreenAndLandscape, { once: true });
            window.addEventListener('load', enterFullscreenAndLandscape, { once: true });
        }

        // B. Chạm màn hình lần đầu sẽ kích hoạt toàn màn hình và xoay ngang (Chỉ kích hoạt 1 lần duy nhất, tránh ngắt bàn phím ảo)
        var hasTriggeredFS = false;
        function triggerImmediateAutoFullscreen(e) {
            if (hasTriggeredFS) return;
            if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.isContentEditable)) {
                return;
            }
            if (document.activeElement && (document.activeElement.tagName === 'INPUT' || document.activeElement.tagName === 'TEXTAREA')) {
                return;
            }
            var isFS = document.fullscreenElement || document.webkitFullscreenElement || document.mozFullScreenElement || document.msFullscreenElement;
            if (!isFS) {
                hasTriggeredFS = true;
                enterFullscreenAndLandscape();
            }
        }

        window.addEventListener('touchstart', triggerImmediateAutoFullscreen, { passive: true });
        window.addEventListener('pointerdown', triggerImmediateAutoFullscreen, { passive: true });
    }

    // -------------------------------------------------------------
    // 3. Giữ Focus Canvas trên Desktop PC (Tuyệt đối KHÔNG cướp focus trên Mobile)
    // -------------------------------------------------------------
    if (!isMobile) {
        window.addEventListener('click', function(e) {
            if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.isContentEditable)) {
                return;
            }
            if (document.activeElement && (document.activeElement.tagName === 'INPUT' || document.activeElement.tagName === 'TEXTAREA')) {
                return;
            }
            var canvas = document.querySelector('canvas') || document.getElementById('canvas');
            if (canvas && e.target === canvas) {
                try { canvas.focus(); } catch(err) {}
            }
        }, false);
    }

    // -------------------------------------------------------------
    // Universal Mobile Virtual Keyboard Bridge for Godot Web:
    // Tự động đồng bộ mọi ký tự từ bàn phím di động vào game
    // -------------------------------------------------------------
    window._kaiserLastInputVal = '';
    window._kaiserLastInputSeq = 0;

    document.addEventListener('input', function(e) {
        if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA')) {
            if (e.target.value !== undefined) {
                window._kaiserLastInputVal = e.target.value;
                window._kaiserLastInputSeq = (window._kaiserLastInputSeq || 0) + 1;
            }
        }
    }, true);

    // -------------------------------------------------------------
    // 4. Clipboard & Input Helper (Tương thích 100% PC & Mobile)
    // -------------------------------------------------------------
    window._kaiserRoomCode = '';
    window._kaiserCodeUpdated = false;
    window._kaiserClipboard = '';

    window.addEventListener('paste', function(e) {
        try {
            var text = (e.clipboardData || window.clipboardData).getData('text');
            if (text) {
                window._kaiserClipboard = text.trim();
            }
        } catch(err) {}
    });

    window.kaiserCopy = function(text) {
        if (!text) return false;
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).catch(function() {
                fallbackCopy(text);
            });
            return true;
        } else {
            return fallbackCopy(text);
        }
    };

    function fallbackCopy(text) {
        try {
            var ta = document.createElement('textarea');
            ta.value = text;
            ta.style.position = 'fixed';
            ta.style.top = '-9999px';
            ta.style.opacity = '0';
            document.body.appendChild(ta);
            ta.focus();
            ta.select();
            var ok = document.execCommand('copy');
            document.body.removeChild(ta);
            return ok;
        } catch(e) {
            return false;
        }
    }

    window.kaiserReadClipboard = async function() {
        if (navigator.clipboard && navigator.clipboard.readText) {
            try {
                var text = await navigator.clipboard.readText();
                if (text) return text.trim();
            } catch(err) {}
        }
        return window._kaiserClipboard || '';
    };

    window.kaiserOpenCodeInputModal = function(initialCode) {
        var res = window.prompt('Nhập hoặc dán mã phòng PvP (4-6 ký tự):', initialCode || '');
        if (res !== null) {
            var match = res.trim().match(/[a-zA-Z0-9]{4,6}/);
            var code = match ? match[0].toUpperCase() : res.trim().slice(0, 6).toUpperCase();
            window._kaiserRoomCode = code;
            window._kaiserCodeUpdated = true;
            return code;
        }
        return '';
    };

    console.log('[Kaiser] High-Performance Web Runner initialized. Native RAF Active.');
})();
