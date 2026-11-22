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
    window._kaiserPlayerName = '';
    window._kaiserNameUpdated = false;
    window._kaiserClipboard = '';

    // Khóa hoàn toàn cuộn màn hình trên mobile (Chống lệch màn hình 100%)
    function lockKaiserScroll() {
        if (window.scrollX !== 0 || window.scrollY !== 0) {
            window.scrollTo(0, 0);
        }
        if (document.body && (document.body.scrollLeft !== 0 || document.body.scrollTop !== 0)) {
            document.body.scrollLeft = 0;
            document.body.scrollTop = 0;
        }
        if (document.documentElement && (document.documentElement.scrollLeft !== 0 || document.documentElement.scrollTop !== 0)) {
            document.documentElement.scrollLeft = 0;
            document.documentElement.scrollTop = 0;
        }
    }
    window.addEventListener('scroll', lockKaiserScroll, { passive: false });
    window.addEventListener('resize', lockKaiserScroll, { passive: true });
    if (window.visualViewport) {
        window.visualViewport.addEventListener('resize', lockKaiserScroll, { passive: true });
        window.visualViewport.addEventListener('scroll', lockKaiserScroll, { passive: true });
    }

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

    // Modal nhập liệu chuẩn mực cho Mobile Web:
    // Hỗ trợ gõ phím tiếng Việt, xóa lùi (Backspace), dán mã và xóa nhanh 100%
    // Tuyệt đối không làm lệch vị trí game canvas.
    window.kaiserOpenInputModal = function(title, initialValue, maxLen, targetType) {
        var old = document.getElementById('kaiser_input_modal');
        if (old) old.remove();

        var isCode = (targetType === 'code' || targetType === 'room_code');
        var maxChars = maxLen || (isCode ? 8 : 16);

        var modal = document.createElement('div');
        modal.id = 'kaiser_input_modal';
        modal.style.cssText = [
            'position: fixed',
            'top: 0',
            'left: 0',
            'width: 100vw',
            'height: 100vh',
            'background: rgba(3, 7, 18, 0.88)',
            'backdrop-filter: blur(8px)',
            '-webkit-backdrop-filter: blur(8px)',
            'z-index: 2147483647',
            'display: flex',
            'align-items: center',
            'justify-content: center',
            'padding: 16px',
            'box-sizing: border-box',
            'font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
        ].join(';');

        var card = document.createElement('div');
        card.style.cssText = [
            'background: linear-gradient(145deg, #162035, #0a0f1d)',
            'border: 1px solid rgba(56, 189, 248, 0.45)',
            'box-shadow: 0 20px 50px rgba(0, 0, 0, 0.85), 0 0 30px rgba(56, 189, 248, 0.25)',
            'border-radius: 14px',
            'width: 100%',
            'max-width: 440px',
            'padding: 22px',
            'box-sizing: border-box',
            'text-align: center'
        ].join(';');

        var heading = document.createElement('div');
        heading.textContent = title || (isCode ? 'NHẬP MÃ PHÒNG' : 'TÊN NGƯỜI CHƠI');
        heading.style.cssText = 'color: #38bdf8; font-size: 17px; font-weight: 800; letter-spacing: 0.8px; margin-bottom: 16px; text-transform: uppercase;';
        card.appendChild(heading);

        var inputRow = document.createElement('div');
        inputRow.style.cssText = 'display: flex; gap: 8px; margin-bottom: 18px; align-items: center; justify-content: center;';

        var input = document.createElement('input');
        input.type = 'text';
        input.value = initialValue || '';
        input.maxLength = maxChars;
        input.autocomplete = 'off';
        input.autocorrect = 'off';
        input.autocapitalize = isCode ? 'characters' : 'words';
        input.spellcheck = false;
        // Font size >= 16px ngăn chặn hoàn toàn iOS Safari tự zoom màn hình
        input.style.cssText = [
            'flex: 1',
            'height: 46px',
            'background: rgba(10, 16, 28, 0.95)',
            'border: 1.5px solid #38bdf8',
            'border-radius: 8px',
            'color: #ffffff',
            'font-size: 18px',
            'font-weight: 700',
            'text-align: center',
            'letter-spacing: ' + (isCode ? '4px' : '1px'),
            'outline: none',
            'padding: 0 10px',
            'box-sizing: border-box',
            'text-transform: ' + (isCode ? 'uppercase' : 'none')
        ].join(';');

        if (isCode) {
            input.addEventListener('input', function() {
                input.value = input.value.toUpperCase();
            });
        }

        var btnClear = document.createElement('button');
        btnClear.textContent = 'XÓA';
        btnClear.style.cssText = [
            'height: 46px',
            'padding: 0 16px',
            'background: rgba(239, 68, 68, 0.25)',
            'border: 1px solid #ef4444',
            'border-radius: 8px',
            'color: #fca5a5',
            'font-size: 14px',
            'font-weight: 700',
            'cursor: pointer'
        ].join(';');
        btnClear.onclick = function() {
            input.value = '';
            input.focus();
        };

        inputRow.appendChild(input);
        inputRow.appendChild(btnClear);

        if (isCode) {
            var btnPaste = document.createElement('button');
            btnPaste.textContent = 'DÁN';
            btnPaste.style.cssText = [
                'height: 46px',
                'padding: 0 16px',
                'background: rgba(56, 189, 248, 0.25)',
                'border: 1px solid #38bdf8',
                'border-radius: 8px',
                'color: #7dd3fc',
                'font-size: 14px',
                'font-weight: 700',
                'cursor: pointer'
            ].join(';');
            btnPaste.onclick = async function() {
                var txt = await window.kaiserReadClipboard();
                if (txt) {
                    input.value = txt.trim().toUpperCase().slice(0, maxChars);
                }
                input.focus();
            };
            inputRow.appendChild(btnPaste);
        }
        card.appendChild(inputRow);

        var btnRow = document.createElement('div');
        btnRow.style.cssText = 'display: flex; gap: 12px; justify-content: center;';

        var btnCancel = document.createElement('button');
        btnCancel.textContent = 'HỦY';
        btnCancel.style.cssText = [
            'flex: 1',
            'height: 42px',
            'background: rgba(255, 255, 255, 0.12)',
            'border: 1px solid rgba(255, 255, 255, 0.25)',
            'border-radius: 8px',
            'color: #cbd5e1',
            'font-size: 14px',
            'font-weight: 700',
            'cursor: pointer'
        ].join(';');

        var btnOk = document.createElement('button');
        btnOk.textContent = 'XÁC NHẬN';
        btnOk.style.cssText = [
            'flex: 1',
            'height: 42px',
            'background: linear-gradient(135deg, #10b981, #059669)',
            'border: none',
            'border-radius: 8px',
            'color: #ffffff',
            'font-size: 14px',
            'font-weight: 800',
            'cursor: pointer',
            'box-shadow: 0 4px 14px rgba(16, 185, 129, 0.4)'
        ].join(';');

        function closeModal() {
            modal.remove();
            lockKaiserScroll();
        }

        function confirmInput() {
            var finalVal = input.value.trim();
            if (isCode) {
                finalVal = finalVal.toUpperCase();
                window._kaiserRoomCode = finalVal;
                window._kaiserCodeUpdated = true;
            } else {
                if (finalVal.length > 0) {
                    window._kaiserPlayerName = finalVal;
                    window._kaiserNameUpdated = true;
                }
            }
            closeModal();
        }

        btnCancel.onclick = closeModal;
        btnOk.onclick = confirmInput;

        input.onkeydown = function(e) {
            if (e.key === 'Enter') {
                confirmInput();
            } else if (e.key === 'Escape') {
                closeModal();
            }
        };

        btnRow.appendChild(btnCancel);
        btnRow.appendChild(btnOk);
        card.appendChild(btnRow);
        modal.appendChild(card);
        document.body.appendChild(modal);

        setTimeout(function() {
            input.focus();
            if (input.select) input.select();
            lockKaiserScroll();
        }, 80);
    };

    window.kaiserOpenCodeInputModal = function(initialCode) {
        window.kaiserOpenInputModal('NHẬP MÃ PHÒNG PVP', initialCode, 8, 'code');
        return '';
    };

    // -------------------------------------------------------------
    // AudioContext Auto-Unlock (Phát nhạc ngay khi tương tác hoặc load xong)
    // -------------------------------------------------------------
    function unlockKaiserAudio() {
        try {
            var AudioCtx = window.AudioContext || window.webkitAudioContext;
            if (AudioCtx) {
                if (window._kaiserAudioCtx && window._kaiserAudioCtx.state === 'suspended') {
                    window._kaiserAudioCtx.resume().catch(function() {});
                }
            }
        } catch(e) {}
    }
    window.addEventListener('pointerdown', unlockKaiserAudio, { passive: true });
    window.addEventListener('touchstart', unlockKaiserAudio, { passive: true });
    window.addEventListener('keydown', unlockKaiserAudio, { passive: true });

    console.log('[Kaiser] High-Performance Web Runner initialized. Native RAF Active.');
})();
