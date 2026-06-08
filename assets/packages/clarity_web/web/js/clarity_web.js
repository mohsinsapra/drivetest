window.clarityLib = {
  clarityScript: function (projectId){
    (function(c,l,a,r,i,t,y){
        c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
        t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
        y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);
    })(window, document, "clarity", "script", projectId)
  },

  // --- Masking support ---
  // Exposed at the clarityLib level so it can be tested independently.
  _maskCanvas: null,
  _maskCtx: null,

  applyMasks: function (sourceCanvas) {
    var self = window.clarityLib;
    var maskRects = window.clarityMaskRects;
    var unmaskRects = window.clarityUnmaskRects;

    if ((!maskRects || maskRects.length === 0) &&
        (!unmaskRects || unmaskRects.length === 0)) {
      return sourceCanvas;
    }

    if (!self._maskCanvas) {
      self._maskCanvas = document.createElement('canvas');
      self._maskCtx = self._maskCanvas.getContext('2d');
    }

    if (self._maskCanvas.width !== sourceCanvas.width ||
        self._maskCanvas.height !== sourceCanvas.height) {
      self._maskCanvas.width = sourceCanvas.width;
      self._maskCanvas.height = sourceCanvas.height;
    }

    // Copy the original frame
    self._maskCtx.drawImage(sourceCanvas, 0, 0);

    var dpr = window.devicePixelRatio || 1;

    // Draw black rectangles over masked regions
    if (maskRects && maskRects.length > 0) {
      self._maskCtx.fillStyle = '#000000';
      for (var i = 0; i < maskRects.length; i += 4) {
        self._maskCtx.fillRect(
          maskRects[i] * dpr,
          maskRects[i + 1] * dpr,
          maskRects[i + 2] * dpr,
          maskRects[i + 3] * dpr
        );
      }
    }

    // Restore original content in unmasked regions
    if (unmaskRects && unmaskRects.length > 0) {
      for (var i = 0; i < unmaskRects.length; i += 4) {
        self._maskCtx.save();
        self._maskCtx.beginPath();
        self._maskCtx.rect(
          unmaskRects[i] * dpr,
          unmaskRects[i + 1] * dpr,
          unmaskRects[i + 2] * dpr,
          unmaskRects[i + 3] * dpr
        );
        self._maskCtx.clip();
        self._maskCtx.drawImage(sourceCanvas, 0, 0);
        self._maskCtx.restore();
      }
    }

    return self._maskCanvas;
  },

  clarityInit: function (projectId, targetFpsMax = 5, targetFpsMin = 2, quality = 0.05){
    window.clarityLib.clarityScript(projectId);
    window.isCanvasMirrorActive = false;
    (() => {
      function onReady(cb) {
        if (document.readyState === 'complete' || document.readyState === 'interactive') {
          cb();
        } else {
          document.addEventListener('DOMContentLoaded', cb);
        }
      }

      onReady(() => {
        const orig = HTMLCanvasElement.prototype.getContext;
        HTMLCanvasElement.prototype.getContext = function (t, a) {
          if (t === 'webgl' || t === 'webgl2') {
            a = Object.assign({}, a, { preserveDrawingBuffer: true });
          }
          return orig.call(this, t, a);
        };
        const overlay = document.createElement('img');
        Object.assign(overlay.style, {
          position: 'fixed',
          top: '0',
          left: '0',
          width: '100vw',
          height: '100vh',
          objectFit: 'cover',
          pointerEvents: 'none',
          background: '#000',
          display: 'block',
          visibility: 'hidden',
        });

        function addOverlay() {
          const flutterView = document.querySelector('flutter-view');
          if (flutterView) {
            flutterView.parentNode.insertBefore(overlay, flutterView);
          } else {
            document.body.appendChild(overlay);
          }
        }

        if (!document.body) {
          console.warn('⏳ Aguardando o body...');
          const observer = new MutationObserver(() => {
            if (document.body) {
              observer.disconnect();
              addOverlay();
            }
          });

          observer.observe(document.documentElement, { childList: true, subtree: true });
        } else {
          addOverlay();
        }

        let lastTime = 0;
        let targetFps = targetFpsMax;
        let lowPower = false;
        function update(now) {
          try {
            let frameInterval = 1000 / targetFps;
            if (document.hidden || !window.isCanvasMirrorActive) {
              overlay.style.visibility = 'hidden';
              requestAnimationFrame(update);
              return;
            }
            const elapsed = now - lastTime;
            if (elapsed < frameInterval) {
              requestAnimationFrame(update);
              return;
            }
            lastTime = now;
            const glass = document.querySelector('flt-glass-pane');
            const canvas = glass?.shadowRoot?.querySelector('canvas');
            if (!canvas || canvas.width === 0) return requestAnimationFrame(update);

            overlay.style.visibility = 'visible';
            const outputCanvas = window.clarityLib.applyMasks(canvas);
            const dataUrl = outputCanvas.toDataURL('image/jpeg', quality);
            overlay.src = dataUrl;
            window.lastClarityFrame = dataUrl;
          } catch (err) {
            console.warn('⚠️ Erro ao capturar canvas:', err);
          }
          lowPower = performance.now() - now > 50;
          targetFps = lowPower ? targetFpsMin : targetFpsMax;
          requestAnimationFrame(update);
        };
        requestAnimationFrame(update);
      });
    })();
}
}
