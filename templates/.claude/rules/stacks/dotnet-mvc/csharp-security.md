---
paths:
  - "**/*.cs"
  - "**/appsettings*.json"
---

# C# Güvenlik Kuralları

<!-- Kaynak: ECC (github.com/affaan-m/ECC) — Türkçeye uyarlandı -->

_Stack'e özgü ekler — genel ilkeler `_universal/security-principles.md`; SQL detayı `sql-conventions.md`; XSS/form `razor-conventions.md`._

## Secret Yönetimi (.NET katmanları)

| Ortam | Mekanizma |
|---|---|
| Lokal geliştirme | `dotnet user-secrets` |
| Production | Env var / secret manager (Key Vault vb.) |

- `appsettings.*.json` gerçek credential içermez — repo'ya girer.
- Eksik config'de fail-fast:

```csharp
var apiKey = builder.Configuration["OpenAI:ApiKey"]
    ?? throw new InvalidOperationException("OpenAI:ApiKey is not configured.");
```

## Dinamik Sorgu Kompozisyonu

Parametreli sorgu temel kuraldır (bkz. `sql-conventions.md`). Ek olarak: **sort alanı ve filter operatörü parametrelenemez** — SQL'e girmeden whitelist ile doğrula:

```csharp
private static readonly HashSet<string> AllowedSortFields = new() { "CreatedAt", "Name" };

var safeSort = AllowedSortFields.Contains(sortField) ? sortField : "CreatedAt";
```

## Input Validation

- DTO doğrulaması uygulama sınırında: data annotations, FluentValidation veya explicit guard clause.
- `ModelState.IsValid` kontrolü iş mantığından **önce** — invalid model ile devam etme.

## Auth

- Custom token parsing yazma — framework auth handler kullan.
- Authorization policy'leri endpoint/handler sınırında zorla (`[Authorize(Policy = ...)]`), servis içinde elle role string karşılaştırma yapma.
- Raw token, parola, PII loglanmaz.
