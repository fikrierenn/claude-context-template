# TÜKETİCİ REHBERİ — bu merkezi kullanan deponun oturum başı protokolü

> Bir cümlede: **kuralı kopyalama, işaret et.** Kopyalanan kural bayatlar ve iki gerçek doğar.
> Ölçüm: 39 depoda 169 sapmış kural var; sapması **sıfır** olan tek depo, kopyalamayan depo.
>
> Ayrıntı ve gerekçeler: `docs/ASAMA-1-TEK-MERKEZ-2026-09-23.md` · `docs/MIMARI-KARARI-2026-09-23.md`

---

## 0. Dürüst durum — "her şey merkezî" HENÜZ DOĞRU DEĞİL

| Ne | Durum |
|---|---|
| `_universal` 18 kural kanonik | ✅ |
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

### Tüketicide yaşayan dosyalar (hepsi isteğe bağlı)

| Dosya | Ne |
|---|---|
| `.claude/turkce-kapi.json` | `{"kapsam":["src","tests"],"alan_adlari":["UrunAdi"],"tabanli_kokler":["legacy"],"dosya_adi_istisnalari":[]}` |
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
