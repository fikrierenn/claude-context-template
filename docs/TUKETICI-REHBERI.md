# TÜKETİCİ REHBERİ — bu merkezi kullanan deponun oturum başı protokolü

> Bir cümlede: **kuralı kopyalama, işaret et.** Kopyalanan kural bayatlar ve iki gerçek doğar.
> Ölçüm: 39 depoda 169 sapmış kural var; sapması **sıfır** olan tek depo, kopyalamayan depo.
>
> Ayrıntı ve gerekçeler: `docs/ASAMA-1-TEK-MERKEZ-2026-09-23.md` · `docs/MIMARI-KARARI-2026-09-23.md`

---

## 0. Dürüst durum — "her şey merkezî" HENÜZ DOĞRU DEĞİL

| Ne | Durum |
|---|---|
| `_universal` 19 kural kanonik (24.09: `naming-conventions.md` eklendi) | ✅ |
| Türkçe tanımlayıcı kapısı merkezde | ✅ |
| `bootstrap --reference` kipi (Aşama 2) | ✅ **var — ve artık VARSAYILAN** |
| 37 deponun göçü (Aşama 3) | ❌ yapılmadı — depo başına, kendi oturumunda |

### Yeni depo kuruyorsan

```bash
bash ../claude-context-template/bin/bootstrap.sh --path <yol> --name <ad> --stack <stack>
```

Kural dosyası **kopyalanmaz**; `CLAUDE.md`'ne hangi kuralların geçerli olduğu **adıyla**
yazılır. Gerçekten kopya gerekiyorsa (hava boşluğu, merkeze erişimsiz makine):

```bash
bash ../claude-context-template/bin/bootstrap.sh --path <yol> --copy --reason "<neden>"
```

Gerekçesiz `--copy` **reddedilir**, ve verilen gerekçe `CLAUDE.md`'ye işlenir.
Windows: `bin/bootstrap.ps1` aynı sözleşmeyi taşır (`-Copy -Reason`).

⚠ Bu depo Aşama 2'de **`Norma`** adını alacak. Bu yüzden yolu deponuzda **tek bir yere**
yazın (`CLAUDE.md` oturum-başı bölümü). Her kancaya gömerseniz ad değiştiğinde hepsini
tek tek düzeltmek zorunda kalırsınız.

---

## 1. Oturum başı — ZORUNLU

```bash
ls ../claude-context-template/templates/.claude/rules/_universal/*.md   # 18 kanonik kural
```

Deponuzda `.claude/rules/*.md` **kopyası** varsa o dosyalar kanonik **değildir**. Merkez
23.09.2026'da altı kuralda ilerledi; birebir kopya taşıyan 11 depo o gün bayatladı:

| Kural | Ne değişti |
|---|---|
| `_universal/test-discipline.md` | YAZILI KURAL ≠ UYGULANAN KURAL (10 ölçülmüş vaka) |
| `_universal/error-handling.md` | "Reddet mi / Say mı" doğrulama sınırı ölçütü |
| `_universal/commit-discipline.md` | commit→TODO `[x]` aynı anda · kırmızı kip geri alırken `reset --hard` yasak |
| `_universal/todo-verification.md` | yeni madde açmadan dup-grep |
| `_universal/footprint-ladder.md` | içindeki proje adı sızıntısı temizlendi |
| `stacks/dotnet-mvc/csharp-conventions.md` | `partial class` sıfır-risk split · Blazor `.razor` nüansı |

### ⚠ "Kanonik kuralı al" ≠ "o kural bu depoda bir şey değiştirir"

Bir tüketici bunu ölçtü ve tablo öğretici (kendi deposunda, üç merkez kuralı için):

| Kural | O depodaki gerçek karşılığı |
|---|---|
| `performance.md` | N+1 taraması **tek** yer buldu, `IMemoryCache` kullanımı **0** → bir TODO satırı, davranış değişikliği değil |
| `error-handling.md` | **Gerçek değişiklik.** "REDDET / SAY" ölçütü mevcut ETL kapısını **bölüyor**: negatif stok fiziksel olarak imkânsız (çelişki → REDDET), eşleşmeyen kayıt gerçekten eksik (→ SAY). Plan gerektiriyor |
| `test-discipline.md` | Otomatik test projesi yok → bugün uygulanacak yer **yok**, değeri gelecekte |

Üçünden **biri** gerçekten bir şey değiştirdi. Referansa geçmek kuralları *geçerli*
kılar; hangisinin bu depoda karşılığı olduğunu **ölçmek** ayrı iştir ve atlanırsa
"18 kural aldık" cümlesi bir şey ifade etmez.

---

## 2. Türkçe tanımlayıcı kapısı — çağırın, kopyalamayın

```bash
python ../claude-context-template/tools/turkce_tanimlayici_denetimi.py <dosya...>
```

Kod İngilizce, **yorum ve UI metni Türkçe**. Kapı yorumlara ve dizelere bilerek dokunmaz.

**Kancadan çağırırken üç şart** (ölçülmüş desen: `bkm-magaza/.claude/hooks/pre-commit-denetim.sh`):

1. **Yalnız yeni/dokunulan dosyaları verin.** Mevcut Türkçe adları taramak her commit'i
   bloklar → kapı ilk gün kapatılır. (Kimse 500 ihlalli bir kapıyı açık tutmaz.)
2. **Araç yoksa ya da koşamazsa SARI uyarın**, sessizce geçmeyin. Sessiz geçen kapı,
   hiç olmayan kapıdan beterdir: çalışıyor *görünür*.
3. Süpürme kipi istiyorsanız `.claude/turkce-kapi.json` yazın; yoksa kapı KOŞAMADI der.
   ⚠ **Ek ak liste adımı KAPIDAN ÖNCE gelir:** ürün/şirket/şema adlarınızı (`Solum`, `Bkm`, `Vardiya`…) önce
   `.claude/kod-sozcukleri.ek.txt`ye yazın. Ölçüldü (Solum, 24.09): ilk koşumda en sık bulgu ürünün kendi adıydı
   (61 kez) — kapıya güven ilk koşumda kazanılır ya da kaybedilir.
   ℹ Test metodu ADLARI taranmaz (1.7.2): `[Fact]`/`[Theory]`/`[Test]` özniteliği taşıyan metot ve `def test_*` adı
   insan mesajıdır, Türkçe cümle olabilir; gövdesi ve sınıf adı taranır.
4. **Dokunulan dosya tamamen temiz** kuralı için kancadan `--tabansiz` ile çağırın (1.7.0): taban yok
   sayılır, staged dosyada tek Türkçe ad BLOKLAR; dokunulmayan dosyaya bakılmaz. Taban yalnız süpürme/haritada
   borcu gösterir. `.js/.py/.ps1/.sql` dosyaları argüman kipinde otomatik desteklenir.

### Tüketicide yaşayan dosyalar (hepsi isteğe bağlı)

| Dosya | Ne |
|---|---|
| `.claude/turkce-kapi.json` | `{"kapsam":["src","tests"],"alan_adlari":["UrunAdi"],"tabanli_kokler":["legacy"],"dosya_adi_istisnalari":[],"uzantilar":[".cs",".razor",".js",".py",".ps1",".sql"],"bicim":true,"bilesen":{"onekler":["btn","form","view"]}}` — `uzantilar` yoksa süpürme yalnız .cs/.razor (1.7.0); `bicim`/`bilesen` yoksa o katmanlar kapalı (1.8.0, opt-in) |
| `.claude/kod-sozcukleri.ek.txt` | deponuzun **alan** sözcükleri, satır başına bir tane |
| `.claude/turkce-taban.json` | devralınmış borcu dondurmak (çırcır): `{"dosyalar":{"legacy/X.cs":12}}` |

### ⚠ Ak listeye sözcük eklerken ayrım — yanlış uygulanırsa kapı bozulur

| Sözcük türü | Nereye | Yanlış yere konursa |
|---|---|---|
| **Dilin kendi sözcüğü** (`Deleted`, `Timer`, `Retention`) | merkezdeki **çekirdek** liste | ek dosyaya taşınırsa, taşımayan her depoda yanlış pozitif doğar — ve yanlış pozitif **bastırma öğretir**, kural ikinci kez ölür |
| **Proje / alan adınız** (ürün, şirket, şema terimi) | kendi **ek** dosyanız | merkezde durursa merkez size bağımlı hale gelir |

---

## 3. Göç — kopyadan referansa

⚠ **Toplu silme yok.** Her sapmanın *bayat mı bilerek mi* olduğu insan kararıdır; makine
ayıramaz. Dosya dosya:

```bash
bash ../claude-context-template/bin/harvest.sh --diff <dosya> <bu-depo>
```

| Fark neyse | Karar |
|---|---|
| Yalnız merkez ilerlemiş | **bayat** → kopyayı sil, merkeze işaret et |
| Deponuza özgü bir gerçek | **bilerek** → kural yerel kalır, **gerekçesi dosyanın ilk satırlarına yazılır** |
| Deponuzda olgunlaşmış, evrensel | **terfi** → `harvest.sh --promote`, silme |

Gerekçeli yerel kural deseni (`bkm-magaza/.claude/rules/capacitor-kabuk.md`):

> *"Bu kural **yerel**, çünkü komşu depo .NET/SQL odaklı; mobil paketleme orada yok."*

**Gerekçesiz yerel kural kabul edilmiyor** — gerekçesi yazılmayan yerel kural, bir yıl
sonra "bayat mı bilerek mi" sorusunu yeniden doğurur.

Sonra `CLAUDE.md`'nizin başına işaretçiyi yazın. Kanıtlanmış örnek `D:\Dev\bkm-magaza\CLAUDE.md`:
başta *"ANA ŞEMA VE KURALLAR BU DEPODA DEĞİL"* uyarısı, ardından "Oturum başı — ZORUNLU"
bölümünde **hangi kuralların okunacağını sayan** bir liste.

---

## 4. Üç uyarı

1. **Aynı depoda başka oturum çalışıyor olabilir.** Kırıcı dokunuştan **önce** tek satır
   haber (Solum'un `tuketici-haberi.md` deseni — orada beş kez ihlal edilmiş).
2. **Önce ve sonra ölçün:** `bash ../claude-context-template/bin/durum.sh`. Deponuzun
   satırında `sapma` düşmeli, `model` sütunu **REFERANS** olmalı. Ölçmediyseniz göç
   olmamıştır.
3. **`harvest.sh --scan` ekosistemi taramaz** — `bin/projects.txt` doluysa yalnız oradaki
   depolara bakar (bugün 3). Ekosistem ölçümü `durum.sh`'tır. İki aracın paydası farklı.
