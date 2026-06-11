---
name: subagent-ana-prensip
description: Subagent + skill kullanımı default — manuel iş istisnai, hatırlatma bekleme
metadata:
  type: feedback
---

Karmaşık veya çok adımlı iş = **subagent + skill varsayılan**, manuel iş istisnai. Kullanıcı söylemeden proaktif tetikle.

- 3+ dosya/klasör keşfi → `Explore` agent
- "Detaylı bak" / "yüzeysel geçme" → `code-explorer` (file:line referans)
- Mimari karar → `code-architect` veya `Plan` agent
- Bağımsız paralel işler → tek mesajda N tool call
- Yeni feature → `/feature-dev` slash
- PR review → `/review-pr` slash
- Oturum sonu → `session-handoff` skill
- 3+ adımlı plan → `plan-tracker` + TodoWrite paralel

**Why:** Tek başına 8 klasörü Read ile okumak context şişirir, paralel avantajı kaçırır.

**How to apply:** Her 3+ dosya keşfinde, her domain sorusunda — proaktif agent. Override: kullanıcı "manuel yap" derse dur.
