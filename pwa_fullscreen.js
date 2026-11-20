// Kaiser Shuttle PWA & Mobile Fullscreen Helper
(function() {
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
