---
name: commit-no-ask
description: Kullanıcı açıkça söylemeden commit atma
metadata:
  type: feedback
---

Commit = kullanıcı net söylemeli: "commit et", "commit'le", "git commit". Bu olmadan — kod bitse de, test yeşil olsa da — commit atma.

**Why:** Otomatik commit kullanıcıyı şaşırtır, geri alma zor.

**How to apply:** Her zaman bekle. İstisna: `session-handoff` skill yalnızca journal + TODO'yu otomatik commit eder (başka path'e dokunmaz).
