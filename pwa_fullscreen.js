// Kaiser Shuttle PWA & Mobile Fullscreen Helper + Resilient Background Execution
(function() {
    // -------------------------------------------------------------
    // 1. Resilient Game Loop across Background Tabs & Tab Switches
    // Browsers pause or throttle native requestAnimationFrame in background tabs.
    // A dedicated Web Worker timer (16ms = ~60 FPS) ticks callbacks when hidden.
    // On tab restore (visibilitychange / focus), any pending callbacks are
    // immediately executed and nativeRAF resumes smoothly without deadlock.
    // -------------------------------------------------------------
    const callbacks = new Map();
    let nextId = 1;
    let worker = null;
    const nativeRAF = window.requestAnimationFrame ? window.requestAnimationFrame.bind(window) : null;
    const nativeCAF = window.cancelAnimationFrame ? window.cancelAnimationFrame.bind(window) : null;

    try {
        const workerCode = "setInterval(function() { postMessage(performance.now()); }, 16);";
        const blob = new Blob([workerCode], { type: "application/javascript" });
        worker = new Worker(URL.createObjectURL(blob));
        worker.onmessage = function(e) {
            // While tab is in background, drive the loop using worker ticks
            if (document.hidden && callbacks.size > 0) {
                const now = e.data;
                const batch = Array.from(callbacks.entries());
                callbacks.clear();
                for (let i = 0; i < batch.length; i++) {
                    try {
                        batch[i][1](now);
                    } catch (err) {
                        console.error('[Kaiser BG rAF] Error:', err);
                    }
                }
            }
        };
        console.log('[Kaiser Shuttle] Background WebWorker ticker initialized.');
    } catch (e) {
        console.warn('[Kaiser Shuttle] WebWorker background ticker could not start:', e);
    }

    if (nativeRAF) {
        window.requestAnimationFrame = function(callback) {
            const id = nextId++;
            callbacks.set(id, callback);

            // ALWAYS schedule nativeRAF so it fires naturally when active
            nativeRAF(function(time) {
                if (callbacks.has(id)) {
                    callbacks.delete(id);
                    try {
                        callback(time);
                    } catch (err) {
                        console.error('[Kaiser rAF] Error:', err);
                    }
                }
            });

            return id;
        };

        window.cancelAnimationFrame = function(id) {
            callbacks.delete(id);
            if (nativeCAF) nativeCAF(id);
        };
    }

    // When returning to tab, immediately ensure loop is running and canvas is focused!
    function onTabRestored() {
        if (!document.hidden) {
            // 1. If any callback was queued by Godot while in background, flush it immediately!
            if (callbacks.size > 0) {
                const now = performance.now();
                const batch = Array.from(callbacks.entries());
                callbacks.clear();
                for (let i = 0; i < batch.length; i++) {
                    try {
                        batch[i][1](now);
                    } catch (err) {
                        console.error('[Kaiser rAF] Restore Error:', err);
                    }
                }
            }

            // 2. Refocus Godot Canvas so clicks and keys register immediately
            const canvas = document.querySelector('canvas') || document.getElementById('canvas');
            if (canvas) {
                try {
                    canvas.focus();
                } catch(e) {}
            }

            // 3. Resume AudioContext
            if (window.AudioContext || window.webkitAudioContext) {
                if (window._kaiserAudioCtx && window._kaiserAudioCtx.state === 'suspended') {
                    window._kaiserAudioCtx.resume().catch(() => {});
                }
            }
        }
    }

    document.addEventListener('visibilitychange', onTabRestored);
    window.addEventListener('focus', onTabRestored);
    window.addEventListener('pageshow', onTabRestored);

    // Release any stuck pointer/mouse drag on window blur
    window.addEventListener('blur', function() {
        const canvas = document.querySelector('canvas') || document.getElementById('canvas');
        if (canvas) {
            try {
                canvas.dispatchEvent(new PointerEvent('pointerup', { bubbles: true }));
                canvas.dispatchEvent(new MouseEvent('mouseup', { bubbles: true }));
            } catch(e) {}
        }
    });

    // Ensure canvas stays focused when user clicks, but NEVER steal focus from text inputs or modals!
    window.addEventListener('click', function(e) {
        if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.isContentEditable || e.target.closest('#kaiser_code_modal'))) {
            return;
        }
        if (document.activeElement && (document.activeElement.tagName === 'INPUT' || document.activeElement.tagName === 'TEXTAREA')) {
            return;
        }
        const canvas = document.querySelector('canvas') || document.getElementById('canvas');
        if (canvas && document.activeElement !== canvas) {
            try {
                canvas.focus();
            } catch(err) {}
        }
    }, false);

    // Global Paste Listener for Web (captures Ctrl+V / browser paste)
    window._kaiserClipboard = '';
    window.addEventListener('paste', function(e) {
        try {
            var text = (e.clipboardData || window.clipboardData).getData('text');
            if (text) {
                window._kaiserClipboard = text.trim();
                var input = document.getElementById('kaiser_code_input');
                if (input) {
                    var match = text.match(/[a-zA-Z0-9]{4,6}/);
                    input.value = match ? match[0].toUpperCase() : text.slice(0, 6).toUpperCase();
                }
            }
        } catch(err) {}
    });

    // -------------------------------------------------------------
    // 2. PWA Install & Fullscreen Handling
    // -------------------------------------------------------------
    let deferredPrompt = null;

    // Listen for PWA Install Prompt
    window.addEventListener('beforeinstallprompt', (e) => {
        e.preventDefault();
        deferredPrompt = e;
        console.log('[Kaiser PWA] App install prompt ready');
        window.kaiserCanInstall = true;
    });

    window.kaiserPromptInstall = function() {
        if (deferredPrompt) {
            deferredPrompt.prompt();
            deferredPrompt.userChoice.then((choiceResult) => {
                if (choiceResult.outcome === 'accepted') {
                    console.log('[Kaiser PWA] User accepted install prompt');
                }
                deferredPrompt = null;
            });
        }
    };

    // Fullscreen Toggle Helper
    window.kaiserToggleFullscreen = function() {
        const docEl = document.documentElement;
        const isFullscreen = document.fullscreenElement || document.webkitFullscreenElement || document.mozFullScreenElement || document.msFullscreenElement;
        
        if (!isFullscreen) {
            if (docEl.requestFullscreen) {
                docEl.requestFullscreen().catch(err => console.log('Fullscreen err:', err));
            } else if (docEl.webkitRequestFullscreen) {
                docEl.webkitRequestFullscreen();
            } else if (docEl.mozRequestFullScreen) {
                docEl.mozRequestFullScreen();
            } else if (docEl.msRequestFullscreen) {
                docEl.msRequestFullscreen();
            }
            if (screen.orientation && screen.orientation.lock) {
                screen.orientation.lock('landscape').catch(() => {});
            }
        } else {
            if (document.exitFullscreen) {
                document.exitFullscreen().catch(err => console.log('Exit fullscreen err:', err));
            } else if (document.webkitExitFullscreen) {
                document.webkitExitFullscreen();
            } else if (document.mozCancelFullScreen) {
                document.mozCancelFullScreen();
            } else if (document.msExitFullscreen) {
                document.msExitFullscreen();
            }
        }
    };

    // Auto-enter fullscreen on user first touch if on mobile device
    let hasAttemptedMobileFs = false;
    function attemptMobileFullscreen() {
        if (hasAttemptedMobileFs) return;
        const isMobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
        if (isMobile) {
            hasAttemptedMobileFs = true;
            window.kaiserToggleFullscreen();
        }
    }

    window.addEventListener('touchstart', attemptMobileFullscreen, { once: true, passive: true });
    window.addEventListener('pointerdown', attemptMobileFullscreen, { once: true, passive: true });

    // -------------------------------------------------------------
    // 3. Native HTML Code Input & Clipboard Helper (100% Mobile & PC Support)
    // -------------------------------------------------------------
    window._kaiserRoomCode = '';
    window._kaiserCodeUpdated = false;

    window.kaiserCopy = function(text) {
        if (!text) return false;
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).then(function() {
                console.log('[Kaiser] Copied to clipboard:', text);
            }).catch(function() {
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
            } catch(err) {
                console.warn('[Kaiser] Clipboard read permission denied:', err);
            }
        }
        return window._kaiserClipboard || '';
    };

    window.kaiserOpenCodeInputModal = function(initialCode) {
        // Remove existing modal if any
        var old = document.getElementById('kaiser_code_modal');
        if (old) old.remove();

        var overlay = document.createElement('div');
        overlay.id = 'kaiser_code_modal';
        overlay.style.cssText = 'position:fixed;top:0;left:0;width:100vw;height:100vh;background:rgba(4,8,16,0.85);z-index:999999;display:flex;align-items:center;justify-content:center;backdrop-filter:blur(6px);font-family:sans-serif;touch-action:manipulation;';

        var card = document.createElement('div');
        card.style.cssText = 'background:#0f172a;border:2px solid #38bdf8;border-radius:14px;padding:24px;width:90%;max-width:380px;box-shadow:0 12px 36px rgba(0,0,0,0.7);text-align:center;box-sizing:border-box;color:#fff;';

        var title = document.createElement('h3');
        title.innerText = 'NHẬP MÃ PHÒNG (PVP)';
        title.style.cssText = 'margin:0 0 8px 0;font-size:18px;color:#38bdf8;letter-spacing:1px;font-weight:bold;';
        card.appendChild(title);

        var sub = document.createElement('div');
        sub.innerText = 'Gõ mã hoặc bấm nút Dán bên dưới để vào phòng';
        sub.style.cssText = 'font-size:12px;color:#94a3b8;margin-bottom:18px;line-height:1.4;';
        card.appendChild(sub);

        var input = document.createElement('input');
        input.id = 'kaiser_code_input';
        input.type = 'text';
        input.maxLength = 6;
        input.value = initialCode || '';
        input.placeholder = 'MÃ PHÒNG (VD: 8899)';
        input.autocomplete = 'off';
        input.autocapitalize = 'characters';
        input.inputMode = 'text';
        input.style.cssText = 'width:100%;height:52px;font-size:22px;font-weight:bold;text-align:center;color:#f8fafc;background:#1e293b;border:2px solid #64748b;border-radius:10px;outline:none;letter-spacing:4px;box-sizing:border-box;margin-bottom:16px;text-transform:uppercase;';
        input.onfocus = function() { input.style.borderColor = '#38bdf8'; };
        input.onblur = function() { input.style.borderColor = '#64748b'; };
        input.oninput = function() { input.value = input.value.toUpperCase(); };
        card.appendChild(input);

        var btnRow = document.createElement('div');
        btnRow.style.cssText = 'display:flex;gap:10px;margin-bottom:12px;';

        var btnPaste = document.createElement('button');
        btnPaste.innerHTML = '📋 DÁN MÃ';
        btnPaste.style.cssText = 'flex:1;height:44px;background:#f59e0b;color:#000;font-weight:bold;font-size:14px;border:none;border-radius:8px;cursor:pointer;touch-action:manipulation;';
        btnPaste.onclick = async function() {
            var txt = await window.kaiserReadClipboard();
            if (txt) {
                var match = txt.match(/[a-zA-Z0-9]{4,6}/);
                input.value = match ? match[0].toUpperCase() : txt.slice(0, 6).toUpperCase();
                btnPaste.innerHTML = '✓ ĐÃ DÁN!';
                setTimeout(function() { btnPaste.innerHTML = '📋 DÁN MÃ'; }, 1500);
            } else {
                var manual = window.prompt('Dán hoặc nhập mã phòng vào đây:', input.value);
                if (manual !== null) {
                    var m2 = manual.trim().match(/[a-zA-Z0-9]{4,6}/);
                    input.value = m2 ? m2[0].toUpperCase() : manual.trim().slice(0, 6).toUpperCase();
                }
            }
        };
        btnRow.appendChild(btnPaste);

        var btnConfirm = document.createElement('button');
        btnConfirm.innerHTML = '✓ XÁC NHẬN';
        btnConfirm.style.cssText = 'flex:1.2;height:44px;background:#0284c7;color:#fff;font-weight:bold;font-size:14px;border:none;border-radius:8px;cursor:pointer;touch-action:manipulation;';
        btnConfirm.onclick = function() {
            var val = input.value.trim().toUpperCase();
            window._kaiserRoomCode = val;
            window._kaiserCodeUpdated = true;
            overlay.remove();
            var canvas = document.querySelector('canvas') || document.getElementById('canvas');
            if (canvas) canvas.focus();
        };
        btnRow.appendChild(btnConfirm);
        card.appendChild(btnRow);

        var btnClose = document.createElement('button');
        btnClose.innerHTML = '✕ ĐÓNG';
        btnClose.style.cssText = 'width:100%;height:36px;background:transparent;color:#94a3b8;font-size:13px;border:1px solid #475569;border-radius:8px;cursor:pointer;touch-action:manipulation;';
        btnClose.onclick = function() {
            overlay.remove();
            var canvas = document.querySelector('canvas') || document.getElementById('canvas');
            if (canvas) canvas.focus();
        };
        card.appendChild(btnClose);

        input.onkeydown = function(e) {
            if (e.key === 'Enter') {
                btnConfirm.click();
            }
        };

        overlay.appendChild(card);
        document.body.appendChild(overlay);

        setTimeout(function() {
            input.focus();
            input.select();
        }, 50);
    };
})();
