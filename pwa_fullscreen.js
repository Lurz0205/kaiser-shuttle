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

    // Ensure canvas stays focused when user clicks anywhere in the game viewport
    window.addEventListener('click', function(e) {
        const canvas = document.querySelector('canvas') || document.getElementById('canvas');
        if (canvas && document.activeElement !== canvas) {
            try {
                canvas.focus();
            } catch(err) {}
        }
    }, true);

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
})();
