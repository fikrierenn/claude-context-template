---
description: Tam denetim — güvenlik + sessiz hata + mimari + perf + tip + CSS (paralel agent filosu)
---

# /full-scan

Tüm kod tabanını (veya `git diff HEAD` kapsamını) paralel agent filosuyla denetler.
Shell hook (pre-commit-antipattern) ucuz statik grep yapar; bu komut **derin agent incelemesidir**.

## Kapsam
Argüman verilmezse tüm `src/`. `diff` argümanı verilirse sadece değişen dosyalar.

## 1. Genel kalite + güvenlik (tek mesajda paralel)

```
security-reviewer    — SQLi/XSS/CSRF/secret/SSRF/open-redirect/exception-leak
silent-failure-hunter— boş catch, korumasız execute, success-on-failure, loglanmayan soft-fail
code-reviewer        — CLAUDE.md + .claude/rules uyumu, surgical change ihlali
code-optimizer       — N+1, async/sync sızması, allocation, cache, latency
type-design-analyzer — entity invariant, record/class tutarlılık, encapsulation
general-purpose      — secret/gitignore audit + CSS bütünlük (ölü sınıf, inline style, palet)
```

## 2. Domain / stack uyum denetimi (tek mesajda paralel)

Her agent önce ilgili SKILL.md'yi okur, sonra slice'ı kurallara karşı denetler (UYUYOR/İHLAL/EKSİK + file:line).

_Proje bazlı domain skill'leri buraya ekle. Örnekler:_
```
# Dotnet projesi:
general-purpose → .claude/rules/stacks/dotnet-mvc/ kurallarını tara (Dapper @Param, async void, CloseAdj vs.)

# Domain skill'li proje:
Agent(skill: <domain-skill>) → src/<DomainSlice>/ klasörünü skill kurallarına karşı denetle

# Auth/güvenlik katmanı varsa:
Agent(subagent_type: security-reviewer) → auth middleware + session + input validation
```

## 3. Sentez

- Bulguları CRITICAL/HIGH/MEDIUM/LOW sırala, file:line ver.
- Ucuz+güvenli olanları hemen fix öner; büyük/riskli olanları TODO.md Faz 2'ye yaz.
- Düzeltme sonrası build + test + (UI değiştiyse) smoke test.

## Ne zaman

- Oturum başı/sonu compliance (session-protocol Adım 5/6).
- Büyük feature batch sonrası.
- Commit öncesi derin tarama.
