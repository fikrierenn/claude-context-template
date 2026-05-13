---
description: Kapsamlı güvenlik denetimi — auth, key sızıntısı, validasyon, maliyet
argument-hint: "Opsiyonel: kapsam (örn: 'app/api/orders' veya 'HEAD~1..HEAD')"
---

# /security-check [kapsam]

Güvenlik denetimi. 2-3 paralel agent ile kapsamlı tarama.

## Kullanım
```
/security-check                      # Tüm API endpoint'leri
/security-check app/api/payments/    # Belirli klasör
/security-check HEAD~1..HEAD         # Son commit
```

## Adım 1 — Kapsam Belirle

Kapsam verilmediyse:
- Next.js: `app/api/**` + `lib/**`
- ASP.NET: `Controllers/**` + `Services/**`
- Python: `routes/**` + `services/**`

## Adım 2 — Paralel Agent'lar

**Agent 1: api-auth-auditor**
- Auth kontrolü, key güvenliği, input validasyon, rate limit

**Agent 2: code-reviewer**
- TypeScript/C#/Python katılığı, cleanup, hata mesajı sızıntısı, logging

**Agent 3: silent-failure-hunter** (hata yönetimi varsa)
- Boş catch blokları, sessiz hata yutma, yanlış fallback

> Proje AI çağrısı içeriyorsa `openai-cost-guardian` veya benzeri maliyet agent'ı da ekle.

## Adım 3 — Birleşik Rapor

```
🔒 Güvenlik Raporu — [Tarih]

🔴 CRITICAL (hemen fix)
  [dosya:satır — sorun — öneri]

🟡 WARNING (bu sprint)
  [bulgular]

🟢 INFO (backlog)
  [bulgular]

ÖZET: X critical, Y warning, Z info
```

## Adım 4 — Karar

CRITICAL var mı → "Şimdi fix edelim mi?" sor.
Hayır → journal'a "bilinen borç" olarak kaydet.
