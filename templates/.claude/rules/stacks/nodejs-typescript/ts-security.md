---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript Güvenlik Kuralları

<!-- Kaynak: ECC (github.com/affaan-m/ECC) — Türkçeye uyarlandı -->

_Stack'e özgü ekler — genel ilkeler `_universal/security-principles.md`'de, burada tekrarlanmaz._

## Secret Yönetimi — Startup'ta Fail-Fast

```typescript
// ASLA: hardcoded secret
const apiKey = "sk-proj-xxxxx"

// HER ZAMAN: env var + varlık kontrolü
const apiKey = process.env.API_KEY

if (!apiKey) {
  throw new Error('API_KEY not configured')
}
```

- Eksik env var **ilk istekte değil, uygulama açılışında** patlasın — env doğrulamasını tek modülde topla (örn. `src/env.ts`, Zod şemasıyla).
- Kodun geri kalanı `process.env`'e doğrudan dokunmaz; doğrulanmış env modülünü import eder.
- `.env*` dosyaları `.gitignore`'da; `console.log` ile token/secret basmak yasak (bkz. `_universal/security-principles.md`).
