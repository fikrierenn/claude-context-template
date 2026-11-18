# esitle — makineler arası iki yönlü git eşitleme

Plan 58 (`pusula/plans/58-makine-esitleme-ve-dalsiz-is-disiplini.md`). Kural: `templates/.claude/rules/_universal/cikti-yeri.md`.

## Ne yapar

| Adım | Ne | Dokunduğu yer |
|---|---|---|
| 1. Snapshot | Kaydedilmemiş işi `wip/<MAKINE>` dalına commit'ler | Yalnız `refs/heads/wip/<MAKINE>`. Çalışma ağacı, HEAD, index aynen kalır |
| 2. Fetch | Hub'daki tüm makine ad alanlarını çeker | `refs/esitle/<M>/*` |
| 3. Converge | Karşıda olan dalı oluşturur, geride olanı ileri sarar, ayrışmışı çakışma yoksa birleştirir | Yerel dallar. Aktif dal yalnız `merge --ff-only` ile, git yerel değişikliği ezecekse atlanır |
| 4. Push | Kendi dallarını hub'a gönderir | Hub'da yalnız `refs/makine/<MAKINE>/*` |

İki makine de aynı görevi çalıştırır; ikişer koşudan sonra iki taraf aynı commit'e oturur.
Karşının **kaydedilmemiş** işi çalışma ağacına uygulanmaz, yerelde `wip/<KARSI>` dalı olarak durur:

```
git diff HEAD wip/SANAL-FIKRI
```

Çakışma (`Cakisma`) hiçbir dala dokunmaz. `%USERPROFILE%\.esitle\son-rapor.json` içinde görünür ve çıkış kodu 3 olur. Elle birleştirilir.

## Kurulum (her makinede bir kez)

```
powershell -ExecutionPolicy Bypass -File tools\esitle\kur.ps1
```

- Görev Zamanlayıcı `esitle`: oturum açılınca, 30 dakikada bir ve ağ bağlanınca çalışır.
- `~/.claude/settings.json` → `SessionEnd` hook'u (oturum bitince anlık görüntü). Yedek: `settings.json.esitle-yedek-*`.
- `~/.claude/CLAUDE.md` → `cikti-yeri.md` import'u. Tüm projelerde yüklenir.
- Makine `esitle.json > machines` içinde olmalı (`BT-FIKRI` → `D:\Dev`, `SANAL-FIKRI` → `C:\dev`).

Hub'da olmayan repo: `kur.ps1 -HubOlustur nexusflow.git` (paylaşılan sunucuya yazar, adı açıkça verilen olur).
Kaldırma: `kur.ps1 -Kaldir`.

## Elle

```
powershell -File tools\esitle\esitle.ps1 -Mode Sync       # tam eşitleme
powershell -File tools\esitle\esitle.ps1 -Mode Report     # ağsız durum tablosu
powershell -File tools\esitle\esitle.ps1 -Mode Snapshot -RepoPath D:\Dev\pusula -Message "not"
```

Çıkış kodları: `0` tamam · `1` hata veya sır riski · `2` hub erişilemiyor · `3` çakışma var.
Log: `%USERPROFILE%\.esitle\esitle.log` (AppData değil: Claude masaüstü MSIX sanallaştırması hook ile görevin loglarını ayırıyordu).

## Sınırlar

- **Dal silme yayılmaz.** Bir makinede silinen dal karşıda duruyorsa bir sonraki eşitlemede geri gelir (hiçbir şey kaybolmasın kuralı). Kalıcı silmek için iki makinede de sil; araç her makinenin hub'daki kendi bölümünü yerel dallara göre budar.
- **Ortak geçmişi olmayan dal** (`IlgisizGecmis`) ve **çakışma** (`Cakisma`) elle çözülür; araç dokunmaz, çıkış kodu 3.
- **Karşının kaydedilmemiş işi** çalışma klasörüne uygulanmaz; yerelde `wip/<KARSI>` dalı olarak durur ve geri gönderilmez.

## Güvenlik

- Ignore edilmemiş sır deseni (`.env`, `*.pfx`, `.secrets/`, `secrets*.json`, …) → o repo **atlanır** (`SecretRisk`).
- 20 MB üstü dosya anlık görüntüye girmez, loga yazılır.
- Force push yalnız kendi ad alanına (`refs/makine/<MAKINE>/*`). Commit kuralındaki tek onaylı istisna.
- Ayna push'u projenin pre-push kapısını atlar (`--no-verify`): build/test her 30 dk koşmaz. Teslim push'ları (`origin`) kapıdan geçmeye devam eder.

## Oturum geçmişi (Faz 2)

Claude Code geçmişi (`~/.claude/projects/<kodlanmış-yol>/*.jsonl`) makineye özgü klasörde durur. `esitle` her Sync'te:

- **Gönderir:** kendi oturumlarını hub'da `_oturumlar\<MAKINE>\<repo>\` altına gzip'li kopyalar (ekleme/güncelleme, silme yok) ve `dizin.json` yazar (kimlik, tarih, boyut, ilk istek). Git'e girmez: boyut ve iş verisi.
- **Alır:** karşı makinenin son `importDays` (14) gündeki oturumlarını yerel proje klasörüne açar → `claude --resume` listesinde görünür. Eskiler kimlikle: `esitle.ps1 -Mode Sessions -SessionId <id>` (hepsi: `-AllSessions`).
- Yereldeki daha yeni dosya ezilmez. İçeri alınıp değişmeyen dosya geri gönderilmez; burada devam ettirilirse bu makinenin adıyla gönderilir.
- Masaüstü uygulamasının kenar çubuğu listesi taşınmaz (uygulama iç verisi); alınan oturumlar `claude --resume` ile açılır.

**Maskeleme:** `%USERPROFILE%\.esitle\gizli-degerler.txt` (git dışı, her makinede ayrı; satır başına bir değer, `#` yorum, en az 4 karakter) içindeki değerler oturum dosyaları hub'a giderken `***` olur (JSON-kaçışlı biçimi de). Liste değişince o makinenin arşivi bir kez baştan yazılır; yerelde karşılığı kalmamış hub dosyaları da yerinde maskelenir. Yerel oturum dosyalarına dokunulmaz. Listeyi araç doldurmaz: değerleri kullanıcı yazar (araç ya da Claude sırları toplamaz).

**C: dolu ise:** `tasi-claude-projects.ps1` geçmişi `D:\claude\projects`'e taşır, eski yere junction koyar (Claude kapalıyken, `-Uygula`; eski kopya silinmez; `-GeriAl` var).

## Test

```
Invoke-Pester tools\esitle\tests
```
