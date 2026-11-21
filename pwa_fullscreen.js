// Kaiser Shuttle - High Performance Web & Mobile Platform Engine
// Optimized for 60-120+ FPS WebGL2 execution, Mobile Auto-Fullscreen, and Cache Auto-Purge
(function() {
    'use strict';

    // -------------------------------------------------------------
    // 1. Triệt để khử Cache cũ & Hủy đăng ký ServiceWorker cũ
    // Đảm bảo thiết bị di động luôn tự động tải về bản cập nhật mới nhất
    // mà người dùng KHÔNG BAO GIỜ phải tự xóa dữ liệu duyệt web thủ công.
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
    // 1b. Tích hợp thư viện Liquid Glass (ybouane/liquidglass WebGL)
    // -------------------------------------------------------------
    try {
        var lgScript = document.createElement('script');
        lgScript.type = 'module';
        lgScript.innerHTML = "import { LiquidGlass } from 'https://cdn.jsdelivr.net/npm/@ybouane/liquidglass/dist/index.js'; window.LiquidGlass = LiquidGlass; console.log('[Kaiser] ybouane/liquidglass WebGL engine loaded.');";
        document.head.appendChild(lgScript);
    } catch (e) {
        console.warn('[Kaiser] LiquidGlass CDN load:', e);
    }

    // -------------------------------------------------------------
    // 2. Mobile Auto-Fullscreen & Auto-Landscape (Xoay Ngang & Toàn Màn Hình Tự Động)
    // "Mới vào thì tự full màn hình và xoay ngang luôn, không đợi người dùng tự bấm full"
    // -------------------------------------------------------------
    var isMobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent) ||
                   (navigator.maxTouchPoints && navigator.maxTouchPoints > 2);

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

    if (isMobile) {
        // A. Thử gọi ngay khi trang vừa tải xong
        if (document.readyState === 'complete' || document.readyState === 'interactive') {
            enterFullscreenAndLandscape();
        } else {
            window.addEventListener('DOMContentLoaded', enterFullscreenAndLandscape, { once: true });
            window.addEventListener('load', enterFullscreenAndLandscape, { once: true });
        }

        // B. Do nhiều trình duyệt (Mobile Chrome / Safari) yêu cầu ít nhất 1 cử chỉ chạm (User Gesture)
        // để cấp quyền Fullscreen & Screen Orientation Lock:
        // Đặt bộ bắt chạm trên toàn màn hình với capture: true để NGAY KHI NGƯỜI DÙNG CHẠM PHÁT ĐẦU TIÊN
        // (chạm màn hình để chơi hay bấm nút) -> Lập tức bung Fullscreen và xoay ngang tức thì!
        var autoFsDone = false;
        function triggerImmediateAutoFullscreen() {
            if (autoFsDone) return;
            autoFsDone = true;
            enterFullscreenAndLandscape();

            // Đảm bảo canvas nhận tiêu điểm ngay để nhận phím/chạm
            var cv = document.querySelector('canvas') || document.getElementById('canvas');
            if (cv) {
                try { cv.focus(); } catch(e) {}
            }
        }

        ['pointerdown', 'touchstart', 'touchend', 'click', 'keydown'].forEach(function(evt) {
            window.addEventListener(evt, triggerImmediateAutoFullscreen, { capture: true, passive: true });
        });
    }

    // -------------------------------------------------------------
    // 3. Giữ Focus Canvas (Không cướp focus của ô nhập liệu / Modal)
    // -------------------------------------------------------------
    window.addEventListener('click', function(e) {
        if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.isContentEditable || e.target.closest('#kaiser_code_modal'))) {
            return;
        }
        if (document.activeElement && (document.activeElement.tagName === 'INPUT' || document.activeElement.tagName === 'TEXTAREA')) {
            return;
        }
        var canvas = document.querySelector('canvas') || document.getElementById('canvas');
        if (canvas && document.activeElement !== canvas) {
            try { canvas.focus(); } catch(err) {}
        }
    }, false);

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
