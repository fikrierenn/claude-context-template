---
paths:
  - "**/*.cs"
  - "**/*.csproj"
---

# C# Test Kuralları

<!-- Kaynak: ECC (github.com/affaan-m/ECC) — Türkçeye uyarlandı -->

_xUnit araç seti ve test organizasyonu — koşum disiplini `_universal/test-discipline.md`._

## Araç Seti

| Amaç | Araç |
|---|---|
| Unit / integration | **xUnit** |
| Assertion | FluentAssertions |
| Mock | Moq veya NSubstitute (projede tek tip seç) |
| Gerçek altyapı (DB, queue) | Testcontainers |

## Organizasyon

- `tests/` klasörü `src/` yapısını aynalar.
- Unit / integration / E2E ayrımı net — ayrı proje veya kategori.
- Test adı **davranışı** anlatır, implementasyonu değil:

```csharp
public sealed class OrderServiceTests
{
    [Fact]
    public async Task FindByIdAsync_ReturnsOrder_WhenOrderExists()
    {
        // Arrange
        // Act
        // Assert
    }
}
```

## ASP.NET Core Integration Test

- `WebApplicationFactory<TEntryPoint>` ile gerçek HTTP pipeline üzerinden test et.
- Auth, validation ve serialization **HTTP üzerinden** doğrulanır — middleware bypass edilmez.

## Coverage

- Hedef %80+ satır; öncelik: domain logic, validation, auth, hata yolları.
- CI'da `dotnet test` + coverage toplama açık.
