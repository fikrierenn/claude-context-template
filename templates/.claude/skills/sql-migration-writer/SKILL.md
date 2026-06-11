---
name: sql-migration-writer
description: İdempotent SQL migration/schema yazar. CREATE TABLE / ALTER / SP pattern'lerini takip eder. Yedek almadan silme YASAK kuralını uygular, mevcut şemayı ezmemeyi garanti eder.
---

# SQL Migration Writer

## Ne zaman tetiklenir

- "Yeni tablo ekle / migration yaz"
- "Kolona X ekle"
- Yeni slice için schema değişikliği
- Stored procedure CREATE OR ALTER

## Önkoşullar

1. **Mevcut şemayı oku** — migration dosyalarına bak, mevcut tabloları anla.
2. **UPDATE öncesi SELECT + WHERE zorunlu** — bare UPDATE asla.
3. **Yedek almadan DROP/TRUNCATE yasak** — kullanıcıya onaylat.
4. **Migration numarası** — mevcut en yükseği bul, +1 ile devam.

---

## Motor Seçimi

Proje hangi motoru kullanıyorsa o bölümü uygula. DB-agnostik projelerde FluentMigrator veya EF Core Migrations tercih et.

---

## SQL Server Şablonları

### Şablon 1 — Yeni Tablo (idempotent)

```sql
-- Migration NN: <Açıklama> | Tarih: YYYY-MM-DD
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'table_name' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.table_name (
        id          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_table_name PRIMARY KEY,
        name        NVARCHAR(200)     NOT NULL,
        created_at  DATETIME2(0)      NOT NULL CONSTRAINT DF_table_name_created_at DEFAULT GETUTCDATE()
    );
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_table_name_name')
    CREATE UNIQUE NONCLUSTERED INDEX IX_table_name_name ON dbo.table_name(name);
GO
```

### Şablon 2 — Kolon Ekleme

```sql
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.table_name') AND name = 'new_col')
    ALTER TABLE dbo.table_name ADD new_col NVARCHAR(100) NULL;
GO
```

### Şablon 3 — SP

```sql
CREATE OR ALTER PROCEDURE dbo.usp_name @param1 INT AS
BEGIN SET NOCOUNT ON; -- body END
GO
```

---

## PostgreSQL Şablonları

### Şablon 1 — Yeni Tablo (idempotent)

```sql
-- Migration NN: <Açıklama> | Tarih: YYYY-MM-DD
CREATE TABLE IF NOT EXISTS table_name (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(200) NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS ix_table_name_name ON table_name(name);
```

### Şablon 2 — Kolon Ekleme

```sql
ALTER TABLE table_name ADD COLUMN IF NOT EXISTS new_col VARCHAR(100);
```

### Şablon 3 — Upsert

```sql
INSERT INTO table_name (id, name) VALUES (@id, @name)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
```

---

## MySQL Şablonları

### Şablon 1 — Yeni Tablo (idempotent)

```sql
CREATE TABLE IF NOT EXISTS table_name (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(200) NOT NULL,
    created_at DATETIME     NOT NULL DEFAULT UTC_TIMESTAMP()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE UNIQUE INDEX IF NOT EXISTS ix_table_name_name ON table_name(name);
```

### Şablon 2 — Kolon Ekleme

```sql
-- MySQL'de IF NOT EXISTS ALTER yoktur; uygulama katmanında kontrol et
-- veya stored procedure ile sar
ALTER TABLE table_name ADD COLUMN new_col VARCHAR(100) NULL;
```

### Şablon 3 — Upsert

```sql
INSERT INTO table_name (id, name) VALUES (@id, @name)
ON DUPLICATE KEY UPDATE name = VALUES(name);
```

---

## Evrensel Kurallar

- İsimlendirme: `snake_case` (3 motorda unquoted çalışır)
- UTC kaydet (`GETUTCDATE()` / `NOW()` / `UTC_TIMESTAMP()`)
- Mevcut migration'ı düzenleme — her zaman yeni dosya
- `DROP TABLE` öncesi kullanıcıya sor + yedek
- `WHERE` olmadan UPDATE asla

## Yaygın Hatalar

- ❌ `WHERE` olmadan UPDATE
- ❌ `DROP TABLE` öncesi BACKUP yok
- ❌ Motor-özel syntax yanlış motorda çalıştırmak
- ❌ Mevcut migration'ı güncelleme
