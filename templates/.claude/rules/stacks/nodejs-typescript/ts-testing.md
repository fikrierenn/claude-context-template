---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript Test Kuralları

<!-- Kaynak: ECC (github.com/affaan-m/ECC) — Türkçeye uyarlandı -->

_Stack'e özgü test katmanları — koşum disiplini `_universal/test-discipline.md`, unit test temel kuralları `ts-conventions.md`._

## Katman Ayrımı

| Katman | Araç | Kapsam |
|---|---|---|
| Unit / integration | Vitest / Jest (`*.test.ts`) | Fonksiyon, servis, component |
| E2E | **Playwright** | Kritik kullanıcı akışları |

## E2E — Playwright

- Kritik kullanıcı akışları (login, ana CRUD, ödeme vb.) için standart E2E aracı Playwright'tır.
- E2E testleri unit testlerden ayrı yaşar: `e2e/` klasörü + ayrı npm script (`test:e2e`) — unit koşumu yavaşlatmasın.
- E2E her commit'te değil, PR/CI aşamasında koşar; unit testler her zaman.
- Her yeni kullanıcı-görünür akış için en az 1 happy-path E2E senaryosu.
