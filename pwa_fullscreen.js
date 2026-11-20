// Kaiser Shuttle PWA & Mobile Fullscreen Helper + Background Execution Shim
(function() {
    // -------------------------------------------------------------
    // 1. Keep Game Loop running in background tabs & unfocused windows
    // Browsers pause native requestAnimationFrame in background tabs.
    // We maintain a dedicated Web Worker timer (16ms = ~60 FPS) to trigger
    // queued rAF callbacks whenever document.hidden is true.
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
            if (document.hidden && callbacks.size > 0) {
                const now = e.data;
                const batch = Array.from(callbacks.entries());
                callbacks.clear();
                for (let i = 0; i < batch.length; i++) {
                    try {
                        batch[i][1](now);
                    } catch (err) {
                        console.error('[Kaiser BG rAF] Error executing callback:', err);
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
            if (!document.hidden || !worker) {
                nativeRAF(function(time) {
                    if (callbacks.has(id)) {
                        callbacks.delete(id);
                        try {
                            callback(time);
                        } catch (err) {
                            console.error('[Kaiser rAF] Error executing callback:', err);
                        }
                    }
                });
            }
            return id;
        };
    }

    if (nativeCAF) {
        window.cancelAnimationFrame = function(id) {
            callbacks.delete(id);
            nativeCAF(id);
        };
    }

    // Keep AudioContext resumed across visibility changes & blur
    function keepAudioAlive() {
        if (window.AudioContext || window.webkitAudioContext) {
            const AudioCtx = window.AudioContext || window.webkitAudioContext;
            if (window._kaiserAudioCtx && window._kaiserAudioCtx.state === 'suspended') {
                window._kaiserAudioCtx.resume().catch(() => {});
            }
        }
    }
    document.addEventListener('visibilitychange', keepAudioAlive);
    window.addEventListener('focus', keepAudioAlive);
    window.addEventListener('blur', keepAudioAlive);

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
