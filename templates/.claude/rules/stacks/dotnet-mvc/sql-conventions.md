---
paths:
  - "**/*.sql"
---

# SQL + Stored Procedure Konvansiyonları (SQL Server)

## Dosya
- Migration: `Database/NN_KisaAciklama.sql` — numaralı.
- SP: `Database/sp_PascalCase.sql` (veya `Database/StoredProcedures/`).
- Function: `Database/fn_PascalCase.sql`.
- Seed: `Database/NN_SeedX.sql`.

## Idempotency Zorunlu
```sql
-- Tablo
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Foo')
BEGIN
    CREATE TABLE dbo.Foo (...);
END
GO

-- Kolon
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('dbo.User') AND name = 'Dept')
BEGIN
    ALTER TABLE dbo.User ADD Dept NVARCHAR(100) NULL;
END
GO

-- Index
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Foo_Bar')
BEGIN
    CREATE INDEX IX_Foo_Bar ON dbo.Foo(Bar);
END
GO
```

## Naming

| Obje | Kural |
|---|---|
| Table | PascalCase, İngilizce, tekil (`User`, `Report`) |
| Column | PascalCase (`UserId`, `CreatedAt`) |
| PK | `[Table]Id` |
| FK | `[Referenced]Id` |
| Index | `IX_[Table]_[Cols]` |
| SP | `sp_PascalCase` |
| TVF | `fn_PascalCase` |
| View | `vw_PascalCase` |
| Parameter | `@PascalCase`, İngilizce |

## SP Şablonu
```sql
CREATE OR ALTER PROCEDURE dbo.sp_XyzReport
    @StartDate DATE,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @EndDate IS NULL SET @EndDate = GETDATE();
    SELECT ... FROM ... WHERE Date BETWEEN @StartDate AND @EndDate;
END
GO
```
- `SET NOCOUNT ON` zorunlu.
- `CREATE OR ALTER` (SQL Server 2016+).
- Default parametre değeri — özellikle preview için NULL kabul eden.

## Inline TVF (reuse + dashboard için)
```sql
CREATE OR ALTER FUNCTION dbo.fn_KpiOzet(@Date DATE)
RETURNS TABLE
AS RETURN (SELECT COUNT(*) AS Total FROM ... WHERE D = @Date);
GO
```
- **Inline** (`RETURNS TABLE AS RETURN (...)`) — performans için.
- **Multi-statement TVF yasak** — optimizer kör eder.

## Güvenlik
- **Dinamik SQL yasak** (`EXEC(@sql)` + user input).
- `STRING_SPLIT` parametreli parsing için güvenli.
- DB user'a sadece SP `EXEC` izni — tabloya direkt `SELECT` yok.
