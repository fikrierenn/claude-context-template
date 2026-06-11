---
name: session-start-briefing
description: İlk yanıtta hook çıktısını oku, uncommitted + HIGH + öncelik özetini çat diye ver
metadata:
  type: feedback
---

"Selam" veya ilk mesaja cevap vermeden önce hook + journal oku, sonra şu formatta özet ver:

```
**[UNCOMMITTED: N dosya]** ✓ / ⚠️ EŞİK AŞILDI
**HIGH açık:** [maddeler veya "yok"]
**Öncelik:** [Faz 0'dan 1-2 madde]
Ne yapıyoruz?
```

**Why:** Kullanıcı her oturum başında durumu kendisi sormak zorunda kalmamalı. Hook fire ediyor ama Claude okuyup özetlemiyor — sadece "selam, ne yapıyoruz?" diyor. Bu kabul edilemez.

**How to apply:** Her oturum, ilk kullanıcı mesajından önce hook çıktısı + journal → özet. Kullanıcı sormadan.
