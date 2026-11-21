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
})();
