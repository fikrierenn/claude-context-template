---
paths:
  - "**/*.cs"
---

# C# Konvansiyonları

## Controller Action'ları
- `public async Task<IActionResult> ActionName(...)` — hep async.
- Admin/yetkili action → class-level `[Authorize(Roles="admin")]`. Anonim → `[AllowAnonymous]`.
- POST → `[HttpPost]` + `[ValidateAntiForgeryToken]` + route attribute.
- Dönüş: ViewModel wrap. Entity direkt view'a gitmesin (mass assignment + coupling).

## EF Core
- DbContext: `AddDbContext` (scoped default). `AddDbContextPool` gerek varsa.
- **Read-only** query → `.AsNoTracking()` her yerde.
- Async: `.ToListAsync()`, `.FirstOrDefaultAsync()`, `.AnyAsync()` — sync yok.
- `SaveChangesAsync()` (await).

## ADO.NET SP Çalıştırma (SP-heavy projede)
```csharp
using var connection = new SqlConnection(connString);
await connection.OpenAsync();
using var cmd = new SqlCommand(procName, connection) {
    CommandType = CommandType.StoredProcedure,
    CommandTimeout = 120
};
cmd.Parameters.AddRange(parameters.ToArray());
using var reader = await cmd.ExecuteReaderAsync();
```
- `procName` **asla user-input** — admin'in onayladığı SP adı.
- Parametre tipi `SqlDbType` ile explicit.
- Connection string **env var**'dan — hardcode yasak.

## Exception Handling
```csharp
catch (SqlException sex) { _logger.LogError(sex, "..."); TempData["Message"] = "Veritabanı hatası."; }
catch (Exception ex)     { _logger.LogError(ex, "...");  TempData["Message"] = "Beklenmedik hata."; }
```
- User'a `ex.Message` **gösterme** — stack / connection string sızar.
- Sessiz `catch {}` yasak (en azından `_logger.LogWarning`).

## Nullability
- `<Nullable>enable</Nullable>` varsayılan.
- `!` null-forgiving sadece gerçekten null olmayacağında.
- Default: `string.Empty` veya `?`.

## Async / await
- `async void` yasak (event handler hariç).
- Library'de `ConfigureAwait(false)`, app code'da gerek yok.

## DI
- Constructor injection. Property injection yasak.
- `IHttpClientFactory` — `new HttpClient()` asla.
- `DateTime.UtcNow` tercih — `DateTime.Now` timezone sorunlu.

## Audit Logging
Create/Update/Delete + login + export + critical config change:
```csharp
await _auditLog.LogAsync(new AuditLogEntry {
    EventType = "user_update",
    TargetType = "user",
    TargetKey = user.UserId.ToString(),
    NewValuesJson = AuditLogService.ToJson(new { ... })
});
```

## Naming
- PascalCase: class, method, property, public field.
- camelCase: local, parameter, private field.
- `_underscorePrefix`: private readonly (`_context`, `_logger`).
- `I` prefix: interface.
- `Async` suffix: async method.
