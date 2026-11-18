# Çıktı Yeri ve Dalsız İş Disiplini (core)

_`paths:` yok — compact sonrası da geçerli. Plan 58 (pusula/plans/58-makine-esitleme-ve-dalsiz-is-disiplini.md), 18.11.2026._

**Neden:** İki makinede (BT-FIKRI, SANAL-FIKRI) paralel oturumlar çalışıyor. Repo dışına yazılan çıktı (ör. `D:\Downloads\gorsel-ornek-liste`) hiçbir yerde kayıt bırakmadı, öbür makineye de geçmedi. Ölçüm 18.11: 9 aktif repo iki makinede ayrışmıştı, 25 repo öbür makinede hiç yoktu.

## 1. Çıktı repo içine yazılır

- Oturumun ürettiği dosya (Excel, resim, PDF, HTML rapor, CSV dökümü) → `<repo>/ciktilar/YYYY-MM-DD-<konu>/`.
- Repo dışına (`Downloads`, `Desktop`, `Temp`) çıktı **yazılmaz**. Tek istisna: kullanıcı açıkça başka yol söyledi → o zaman da `ciktilar/…/KAYIT.md`'ye yolu ve ne olduğunu yaz.
- Ara/geçici dosya → oturum scratchpad'i (çıktı değildir, eşitlenmez).
- **20 MB üstü dosya** → `ciktilar/_buyuk/…` (git dışı). `esitle` anlık görüntüsü bunu almaz ve loga yazar.
- Klasörde kısa bir `README.md`: ne, hangi kaynaktan, nasıl üretildi (betik/sorgu yolu).

## 2. Dalsız iş kaybolmaz

- Oturum bitince `SessionEnd` hook'u (`tools/esitle/esitle.ps1 -Mode Snapshot -FromHook`) kaydedilmemiş işi `wip/<MAKINE>` dalına commit'ler. Çalışma ağacına, HEAD'e ve index'e dokunmaz.
- `wip/*` dalı **teslim değildir.** İş bitince gerçek commit + doğru dal (`feat/…`, `fix/…`). `wip/*`'e elle commit atılmaz.
- Görev Zamanlayıcı (`esitle` görevi) ağ gelince iki yönlü eşitler. Öbür makinenin kaydedilmemiş işi yerelde `wip/<KARSI>` dalı olarak görünür: `git diff HEAD wip/SANAL-FIKRI`.
- **Çakışma raporu** (`%LOCALAPPDATA%\esitle\son-rapor.json`, durum `Cakisma`) oturum başında okunur. Çakışan dal elle birleştirilir; araç dokunmaz.

## 3. Sır

- `esitle`, ignore edilmemiş sır deseni (`.env`, `*.pfx`, `.secrets/`, `secrets*.json`) görürse o repoyu **atlar** (`SecretRisk`). Çözüm: dosyayı `.gitignore`'a ekle. Desen listesini gevşetme.

## Kontrol

Oturum sonunda: "Ürettiğim her dosya `ciktilar/` altında mı? Repo dışına yazdığım bir şey var mı?" Varsa taşı, yoksa `KAYIT.md`.
