---
paths:
  - "**/*.cs"
---

# C# Pattern'leri

<!-- Kaynak: ECC (github.com/affaan-m/ECC) — Türkçeye uyarlandı -->

_API yanıt zarfı, repository, options pattern ve DI lifetime — `csharp-conventions.md`'yi tamamlar._

## API Yanıt Zarfı

```csharp
public sealed record ApiResponse<T>(
    bool Success,
    T? Data = default,
    string? Error = null,
    object? Meta = null);
```

- Tüm API endpoint'leri aynı zarfı döner; `Error` generic mesajdır, exception detayı sızmaz.

## Repository Pattern

```csharp
public interface IRepository<T>
{
    Task<IReadOnlyList<T>> FindAllAsync(CancellationToken cancellationToken);
    Task<T?> FindByIdAsync(Guid id, CancellationToken cancellationToken);
    Task<T> CreateAsync(T entity, CancellationToken cancellationToken);
    Task<T> UpdateAsync(T entity, CancellationToken cancellationToken);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken);
}
```

- Her async imzada `CancellationToken` — istek iptal olunca sorgu da iptal olsun.
- "Bulunamadı" → `null` döner, exception değil (bkz. `_universal/error-handling.md`).

## Options Pattern

Config string'lerini kod içinde dağıtma — strongly-typed options:

```csharp
public sealed class PaymentsOptions
{
    public const string SectionName = "Payments";
    public required string BaseUrl { get; init; }
    public required string ApiKeySecretName { get; init; }
}

// Program.cs
builder.Services.Configure<PaymentsOptions>(
    builder.Configuration.GetSection(PaymentsOptions.SectionName));
```

- Servisler `IOptions<PaymentsOptions>` alır; `Configuration["Payments:BaseUrl"]` saçılması yasak.

## DI Lifetime Seçimi

| Lifetime | Ne zaman |
|---|---|
| **Singleton** | Stateless / paylaşılan servis |
| **Scoped** | Request'e bağlı state (DbContext, current user) |
| **Transient** | Hafif, saf worker |

- Lifetime'ı bilinçli seç — varsayılan refleksle ekleme. Singleton içine scoped inject etmek runtime hatasıdır.
- Servis sınırlarında interface'e bağımlı ol; constructor bağımlılığı şişiyorsa (5+) sorumluluğu böl.
