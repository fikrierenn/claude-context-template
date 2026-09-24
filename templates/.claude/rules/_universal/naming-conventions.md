# Adlandırma Standardı (naming-conventions)

**Tek cümle:** kod İngilizce, biçim dile göre TEK, bileşen adı önekli kebab-case, yorum/UI Türkçe.
Bu dosya *ne* olduğunu söyler; *nasıl zorlandığını* son bölüm söyler. Kural metni davranış
değiştirmez, kapı değiştirir (`evidence-discipline.md`).

**Neden var (24.09.2026, bkm-magaza ölçümü):** aynı depoda `btn-okut` · `guncelle-btn` · `btnCihaz`
· `gorunumUrun` · `tip-DİĞER` bir arada; 202 bileşen adının 111'i Türkçe, 28'i camelCase id, buton
eki 1 kez önek 6 kez sonek. Kod tarafında 1174 Türkçe tanımlayıcı / 43 dosya. Hiçbiri "hata" vermedi;
hepsi okuyanın zamanını yedi ve iki geliştirici aynı şeye iki ad verdi. GMY: *"yeni projelerde böyle
hatalar olmasın, standartlarımız oluşmalı"* — yeni proje bu dosyayı `bootstrap` ile doğuştan alır.

## 1. Dil

| Alan | Dil |
|---|---|
| Tanımlayıcı: sınıf · metot · değişken · parametre · dosya · CSS sınıf/id · rota · JSON alanı · SQL tablo/kolon | **İngilizce** |
| Yorum · günlük · UI metni · hata mesajı · commit mesajı · belge | **Türkçe**, UTF-8, ASCII sadeleştirme YOK (`turkish-ui.md`) |
| Ürün/şirket/şema **alan adı** (`Bkm`, `Zirve`, `fsm`) | çevrilmez; tüketicinin `.claude/kod-sozcukleri.ek.txt` listesinde |

- Türkçe sözcük ASCII'ye indirgenerek tanımlayıcı **yapılmaz** (`Urun`, `Kayit`, `sikistir`). Çevir.
- **Türkçe okunuşu argo/cinsel çağrışımlı** hiçbir sözcük — İngilizce olsa bile — tanımlayıcıda, sözlükte,
  örnek veride kullanılmaz (`got`, `am`, `meme`, `sik*`, `bok`, `kaka`…). `got` → `obtained`.
- Bir dosyaya dokunan, **o dosyanın tamamını** standarda getirir (üye değil, dosya). Dokunulmayan dosya rahat.

## 2. Biçim — dil başına TEK biçim

| Dil | Tür/sınıf | Metot/fonksiyon | Değişken/parametre | Sabit | Özel alan |
|---|---|---|---|---|---|
| C# | `PascalCase` | `PascalCase`, async → `…Async` | `camelCase` | `PascalCase` | `_camelCase` |
| JavaScript/TypeScript | `PascalCase` | `camelCase` | `camelCase` | `UPPER_SNAKE` | — |
| Python | `PascalCase` | `snake_case` | `snake_case` | `UPPER_SNAKE` | `_snake` |
| PowerShell | — | `Verb-Noun` (onaylı fiil: Get Set New Remove Invoke Test Start Stop Write Read Convert Select Where) | `$PascalCase` param · `$camelCase` yerel | `$UPPER_SNAKE` | — |
| SQL (T-SQL) | tablo `PascalCase` tekil (`Device`, `Person`) | yordam `PascalCase` fiil-nesne (`GetDeviceList`) | kolon `PascalCase`; anahtar `Id`, yabancı `<Entity>Id` | — | — |
| CSS / DOM | `kebab-case` (bkz. §3) | — | — | `--kebab-token` | — |

- **Kısaltma yok**, yerleşik olanlar dışında: `Id Url Uri Http Json Xml Sql Api Ui Db Io Ip Dns Tls Ok`. `btn`, `img`,
  `msg`, `tmp`, `cfg`, `ctx` yalnız CSS öneki ve tek harfli lambda dışında **kullanılmaz** (`message`, `image`).
- Boolean `is/has/can/should` ile başlar (`isActive`, `HasStock`). Koleksiyon çoğul (`devices`), tekil eleman tekil.
- Asenkron C# metodu `Async` ile biter; olay işleyici `on<Event>`; fabrika `create<X>`; dönüştürücü `to<X>`.

## 3. Bileşen adları (CSS sınıfı, DOM id, veri-öznitelik)

- **kebab-case, küçük harf, İngilizce**; camelCase id yok, alt çizgi yok, Türkçe harf yok.
- **Tip ÖNEKİ**, sonek değil: `btn-scan`, `form-code`, `view-product`, `field-email`, `tab-devices`, `card-shelf`,
  `badge-campaign`, `alert-amber`, `list-results`, `table-devices`, `row-device`, `chip-filter`, `modal-cover`, `toast-update`.
  Kapalı önek kümesi: `btn form view field tab card badge alert list table row cell chip filter modal overlay toast nav header footer section`.
  Tüketici önek kümesini `.claude/turkce-kapi.json` → `"bilesen": {"onekler": [...]}` ile verir (boş liste = varsayılan küme).
- **Değişken (variant) ayrı sınıf:** `btn-primary`, `btn-secondary`, `btn-danger`, `btn-small` — eleman adına yapışmaz
  (`guncelle-btn` ✗, `birincil-btn` ✗ → `btn-update btn-primary`).
- **Durum ayrı sınıf:** `is-active`, `is-hidden`, `is-empty`, `is-loading`, `has-error` (`stoklu`/`yok`/`acik` ✗).
- id yalnız tekil düğüm için, aynı kurallarla (`#view-search`, `#field-query`); JS `dataset` anahtarları camelCase (DOM dönüşümü).
- CSS özel özellikler `--color-primary`, `--space-2`; medya/durum sınıfları JS ile aynı adı taşır.

## 4. Dosya, dizin, rota, JSON, git

| Ne | Kural | Örnek |
|---|---|---|
| C# dosya | tip adı = dosya adı | `DeviceRegistry.cs` |
| JS/TS · Python · CSS · HTML · SQL · PS1 dosya | `kebab-case` (Python modülü `snake_case`) | `product-search.js`, `schema_drift_check.py`, `install-service.ps1` |
| Dizin | `kebab-case`; .NET proje dizini proje adı | `wwwroot/`, `tools/server/` |
| HTTP rota | `kebab-case`, çoğul kaynak, fiil yok | `/api/products/{id}/campaign`, `/api/devices/{id}/revoke` (POST) |
| JSON alanı | `camelCase`, İngilizce | `discountedPrice`, `stockId` |
| Ortam değişkeni | `UPPER_SNAKE`, ürün öneki | `BKM_DB_HOST` |
| Git dalı | `tip/kısa-kebab` | `feat/device-sessions` |
| Test adı | okunur cümle; dil serbest (Türkçe cümle olabilir) | `Firma_gecisi_cihazi_dusurmez` |

**Sözleşme adları kapıda:** `.claude/turkce-kapi.json` → `"sozlesme_adlari"` — Türkçe kalan tel/kolon adları BORÇ olarak geçer, alan adı değildir; İngilizceye geçince satır silinir (1.8.1).

**Sözleşmeler (istemciye/DB'ye görünen ad) değişince:** eski ad bir sürüm **çift** yaşar (çift rota, `[JsonPropertyName]`
ile eski tel adı, görünüm/eşanlamlı kolon), istemci turu biter, sonra kalkar. Sözleşmeyi sessizce değiştirmek yasak.

## 5. Zorlama — hangi satırı hangi kapı tutuyor

| Kural | Kapı | Durum |
|---|---|---|
| §1 tanımlayıcı İngilizce (C#, Razor, JS, Python, PowerShell, SQL) | `tools/turkce_tanimlayici_denetimi.py` — Türkçe harf · Türkçe kök · **ak liste** (`tools/kod-sozcukleri.txt` + tüketici ek listesi); `--tabansiz` ile "dokunulan dosya tamamen temiz" | **VAR** (1.7.0) |
| §1 argo okunuşlu sözcük | ak liste bu sözcükleri **içermez**; ekleyen çıkarır | VAR (sözlük kuralı) |
| §2 biçim (case) | `turkce_tanimlayici_denetimi.py` ayar `"bicim": true` — bildirilen adın dile göre biçimi | **VAR** (1.8.0, opt-in) |
| §3 bileşen adı (kebab · tip öneki · -btn yasak · ak liste) | aynı araç, ayar `"bilesen": {"onekler": […]}` — .css seçicileri, .html class/id, .js class/id dizeleri | **VAR** (1.8.0, opt-in) |
| §4 dosya adı · rota · JSON alanı · env · git dalı | — | **YOK** — gözle; bu satır kapı gelince güncellenir |
| Yorum/UI Türkçe, ASCII sadeleştirme yok | araç yorumlara bilerek dokunmaz; ASCII kapısı denendi, yanlış pozitif yüzünden reddedildi (bkm-magaza D-011) | gözle |

Kapısı olmayan satır **kural değil niyettir** — bu tabloda "YOK" yazan her satır için kapı gelmeden
"uyguluyoruz" denmez (`evidence-discipline.md`).
