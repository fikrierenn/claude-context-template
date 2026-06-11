---
name: todo-stale-claim
description: TODO/journal'da HIGH yazılı = kanıt değil, hipotez — action öncesi file:line doğrula
metadata:
  type: feedback
---

TODO.md / journal / memory'deki HIGH/CRITICAL bulgular **kanıt değil, hipotez**. Action almadan önce `Read` veya `Grep` ile file:line doğrulaması zorunlu.

**Why:** "Post-review hardening" commit'leri sonrası backlog stale kalabiliyor. 7 kapalı maddeyi açık sanıp fix'lemeye başlamak zaman kaybı + gereksiz diff.

**How to apply:**
- HIGH listesi gördüğünde paralel Read+Grep (tek mesajda)
- Son 7 günde "hardening" / "fix(security)" commit varsa → backlog muhtemelen stale, tam sweep
- Sonucu kullanıcıya tablo göster (iddia | kod kanıtı | açık/kapalı), onay almadan fix etme
- Kapanmış maddeleri `[x] ✅ KAPALI <tarih>` olarak işaretle
