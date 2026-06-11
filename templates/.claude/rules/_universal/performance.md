# Performans Disiplini

<!-- Kaynak: ECC (github.com/affaan-m/ECC) — Türkçeye uyarlandı -->

_Ölçülebilir performans kuralları — her stack'te geçerli. `paths:` yok — compact sonrası survive._

## Temel İlke: Önce Ölç

- **Erken optimizasyon yasak.** Okunabilirlikten ödün veren optimizasyon yalnız ölçülmüş darboğaz için yapılır.
- Optimizasyon iddiası ölçümle gelir: profiler çıktısı, query plan, benchmark, bundle raporu. "Daha hızlı olur gibi" gerekçe değildir.
- Önce doğru, sonra hızlı. Sıra: test yeşil → optimize et → test yine yeşil + ölçüm farkını raporla.

| Şüphe | Ölçüm aracı |
|---|---|
| Yavaş sorgu | `EXPLAIN` / query plan, slow query log |
| Yavaş endpoint | APM / middleware timing, p95-p99 latency |
| CPU / memory | Profiler (py-spy, dotnet-trace, clinic.js vb.) |
| Şişkin bundle | Bundle analyzer raporu |

## N+1 Sorgu

- Liste çek + döngüde kayıt başına sorgu = **N+1**. Eager load / join / batch ile sabit sayıda round-trip'e indir.
- ORM kullanırken üretilen SQL'i en az bir kez logla ve incele — ORM, N+1'i gizler.
- Liste endpoint'i yazınca kendine sor: "Bu sayfa kaç sorgu atıyor?" Cevap sabit bir sayı olmalı, kayıt sayısıyla artmamalı.

## Cache Disiplini

- Cache, ölçülmüş darboğaza eklenir — refleks olarak değil.
- Her cache girdisinin **invalidation stratejisi** yazılı olmalı (TTL, event-bazlı, versiyonlu key). Stratejisiz cache = stale data bug'ı.
- TTL'siz, sınırsız in-memory cache yasak (memory leak).
- User-scoped veri cache'leniyorsa key'e user id dahil — yoksa kullanıcılar arası veri sızıntısı.

## Bundle / Asset Boyutu

- Yeni bağımlılık (npm/NuGet/pip) eklemeden önce boyut + transitive bağımlılık kontrolü. Tek fonksiyon için büyük kütüphane ekleme.
- Frontend: route bazlı code-splitting; büyük kütüphaneler (chart, editor) lazy load.
- Görseller optimize (WebP/AVIF, doğru boyut), font subset.

## Algoritmik Karmaşıklık Farkındalığı

- Hot path'te iç içe döngü → O(n²) sinyali. Lookup'ı `Map` / `set` / `dict` ile O(1)'e indir.
- Döngü içinde büyük listede `includes` / `Contains` → önce set'e çevir.
- Veri boyutu varsayımını belgele: "n < 100 → basit çözüm yeterli" meşru bir karardır, ama yorum olarak yaz.

## Anti-pattern

- ❌ Ölçmeden "optimize ettim" — kanıt yok.
- ❌ Ölçülmemiş mikro-optimizasyonla okunabilirliği bozmak.
- ❌ Her şeyi cache'lemek — invalidation borcu birikir.
- ❌ N+1'i cache ile maskelemek — sorguyu düzelt.
