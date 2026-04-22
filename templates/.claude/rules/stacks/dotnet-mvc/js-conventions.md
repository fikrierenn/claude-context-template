---
paths:
  - "wwwroot/assets/js/**/*.js"
  - "wwwroot/js/**/*.js"
---

# Vanilla JavaScript Konvansiyonları

## Dosya + IIFE
```js
(function() {
    "use strict";
    var state = { ... };
    function privateHelper() { ... }
    window.myFeatureAction = function() { ... };  // gerekirse expose
    init();
})();
```
Her dosya IIFE ile sarılı, global namespace korunur.

## Kurallar
- **Framework yok** — React/Vue/jQuery eklenmiyor.
- **Fetch API** — XHR yok.
- **`innerHTML` yasak** user-data içerse (XSS). `createElement` + `textContent` kullan.
- **`eval()` yasak.** Dinamik dispatch: `window[funcName]` veya object map.
- **`addEventListener`** — inline `onclick` yok.

## Event Delegation
Çok sayıda dinamik element için parent'a tek listener:
```js
container.addEventListener('click', function(e) {
    var btn = e.target.closest('.action-btn');
    if (!btn) return;
    handleAction(btn.dataset.id);
});
```

## Fetch Pattern
```js
fetch('/api/endpoint?x=' + encodeURIComponent(val))
    .then(r => r.json())
    .then(data => {
        if (!data.success) { showError(data.error); return; }
        render(data);
    })
    .catch(err => showError('Beklenmedik hata: ' + err.message));
```

## AntiForgery (POST)
```js
fetch('/api/x', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'RequestVerificationToken': document.querySelector('input[name="__RequestVerificationToken"]').value
    },
    body: JSON.stringify(payload)
});
```

## Drag-Drop (native)
```js
el.draggable = true;
el.addEventListener('dragstart', e => e.dataTransfer.setData('text/plain', idx));
el.addEventListener('dragover', e => e.preventDefault());
el.addEventListener('drop', e => { e.preventDefault(); reorder(...); });
```
Re-render'da listener'lar birikmesin → event delegation veya AbortController.

## State
- IIFE-local default.
- Global sadece açık isimlendirilmiş (`window.__FeatureState`).
- Cross-file: `document.dispatchEvent(new CustomEvent('xyzReady', { detail }))`.

## Syntax Check
Her edit sonrası:
```bash
node -e "new Function(require('fs').readFileSync('path/to.js','utf8'))"
```
Stop hook otomatik çağırabilir.
