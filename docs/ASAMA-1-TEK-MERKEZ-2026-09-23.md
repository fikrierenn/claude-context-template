# AŞAMA 1 — TEK MERKEZ (2026-09-23)

> Kaynak kararlar: `docs/MIMARI-KARARI-2026-09-23.md` · Devir: `docs/DEVIR-2026-09-23.md`
> Bu belge Aşama 1'in **ölçümüdür**: ne terfi etti, 12 sapma nasıl sınıflandı, hangi
> kararlar GMY tarafından verildi, tüketicinin Aşama 3'te ne yapması gerekiyor.
>
> ⚠ **Aşama 3'e (37 deponun göçü) girilmedi.** O, depo başına, kendi oturumunda.

---

## 0. Taban ölçüm — değişmedi

```
Sablon : claude-context-template (v1.4.0) · _universal 18 kural
TOPLAM : 39 depo · ayni 41 · SAPMA 158 · yerel 139 · referans modeli 1 depo
```

Doğrulandı (`bash bin/durum.sh`), oturum başında.

### ⚠ Oturum SONUNDA aynı ölçüm — sayı YÜKSELDİ

```
TOPLAM : 39 depo · ayni 30 · SAPMA 169 · yerel 139 · referans modeli 1 depo
```

**aynı 41 → 30 · SAPMA 158 → 169.** Hiçbir tüketici deposuna dokunulmadı. Sebep:
merkezdeki 6 kural dosyası ilerledi, ve o dosyaların **birebir aynı** kopyasını taşıyan
11 depo bir anda "sapmış" oldu.

📐 **Bu bir gerileme değil, teşhisin kendisinin ölçülmesi.** Kopya modelinde merkezi
iyileştirmenin *bedeli* sapmadır: merkez her ilerlediğinde tüm kopyalar bayatlar, ve
kimse 169 dosyayı elle diff'lemeyeceği için merkez ilerlemekten *çekinir* hale gelir —
`CHANGELOG 1.4.0`'ın tarif ettiği kendini besleyen döngü tam olarak budur.

Referans modelinde bu sayı **artamaz**: işaret edilen dosya ilerleyince tüketici de
ilerlemiş olur. Yani 169, Aşama 2 ve 3'ün gerekçesidir — ertelemenin değil.

**Ek ölçüm — sayının kaçı gürültü? Sıfırı.** İki kez ölçüldü (158'de ve 169'da):
sapmaların **tamamı** gerçek içerik farkı, hiçbiri salt satır-sonu (CRLF/LF) değil.

Ama **tek dosyanın diff derinliği** satır sonundan şişiyor: `commit-discipline` 143 → 33
satır, `session-protocol` 255 → 125, bir tüketicide `footprint-ladder` 78 → **2**.
Sapma *sayısı* doğru, sapma *derinliği* okunurken `--strip-trailing-cr` şart.

Bir tüketici "`durum.sh` sapmayı şişiriyor, `cmp -s` satır sonunu sapma sayıyor" diye
bildirdi. **Ölçüldü: sayı şişmiyor** — kendi verdikleri örneklerde bile CR yoksayınca
fark 2/50/57/68/63 satır, yani hiçbiri sıfır değil. Buna rağmen `durum.sh`
`diff --strip-trailing-cr`'ye geçirildi: bugün sonucu değiştirmiyor ama yarın Windows'ta
`core.autocrlf` ile checkout edilen bir kopya sebepsiz sapmasın diye. Ölçütün doğru
olması, bugün fark yaratmasından bağımsızdır.

---

## 1. Terfi eden: pusula'nın olgun kapısı

| Ne | Nereden | Nereye |
|---|---|---|
| `turkce_tanimlayici_denetimi.py` (406 satır) | `pusula/tools/` | `tools/` (depo kökü) |
| `kod-sozcukleri.txt` (çekirdek ak liste) | `pusula/tools/` | `tools/` (depo kökü) |

Bugün pusula'ya eklenen 5 İngilizce sözcük (`Blanked`, `Deleted`, `Stop`, `Retention`,
`Timer`) terfide geldi (devir §4 şartı). ⚠ Bunlar **çekirdek listede kalmalı** — beşi de
jenerik programlama sözcüğü, hiçbiri bir depoya özgü değil (§1.3'teki ayrım).

### 1.1 Yer kararı — neden `templates/` altında DEĞİL (§8.4)

GMY kararı: **depo kökünde `tools/`**. Üç ölçülmüş gerekçe:

1. **`bootstrap.sh` `hooks/` altından yalnız `*.sh` ve `*.ps1` kopyalıyor.** Kapı
   `templates/.claude/hooks/` altına konsaydı kopya kipinde **sessizce atlanırdı** —
   kapı "kuruldu" görünür, hiçbir şey koşmazdı. (Tam olarak `test-discipline` §
   *yazılı kural ≠ uygulanan kural* sınıfı.)
2. **`bkm-magaza` kapıyı bugün zaten `../pusula/tools/…` diye çağırıyor.** Merkez de
   kökte `tools/` tutunca referans yolunun **şekli değişmiyor**.
3. `bin/` (durum, harvest) zaten kökte: çatının **araçları** kökte, `templates/` ise
   tüketiciye giden **şablon**. Python kapısı kanca değil **araçtır**; kancalar
   (`pre-commit-*.sh`) onu çağırır.

### 1.2 Terfide düzeltilen en kritik şey — kapı yanlış depoyu tarıyordu

Kapı pusula'dayken `KOK = Path(__file__).parent.parent` **doğruydu**: araç deponun
içindeydi. Merkeze taşınınca aynı satır **merkezin kökünü** verir — yani kapı, çağıran
deponun kodunu değil **şablonu** tarar ve *"0 bulgu, geçti"* derdi.

Kök artık **çağıranın yerinden** bulunur (cwd'den yukarı `.git`/`.claude`; zorlama:
`TURKCE_KAPI_KOK`). Sınandı (§1.4 A).

### 1.3 Projeye bağlı ne varsa dışarı çıktı

Merkezde artık `vardiya-app` / `Bkm` / `dashboard` gibi tek bir ad yok.

| Tüketicide yaşayan | Ne |
|---|---|
| `<kök>/.claude/turkce-kapi.json` | `kapsam` · `tabanli_kokler` · `alan_adlari` · `dosya_adi_istisnalari` |
| `<kök>/.claude/kod-sozcukleri.ek.txt` | deponun kendi İngilizce sözcükleri (ops.) |
| `<kök>/.claude/turkce-taban.json` | donmuş borç — çırcır tabanı (ops.) |

**Taban neden tüketicide:** donmuş borç o deponun gerçeğidir; merkeze konsaydı bir
deponun borcu ötekinin kapısını gevşetirdi.

**Hangi sözcük NEREYE — ayrım (yanlış uygulanırsa kapı bozulur):**

| Sözcük türü | Nereye | Yanlış yere konursa |
|---|---|---|
| **Dilin kendi sözcüğü** (`Deleted`, `Stop`, `Timer`, `Retention`) | **çekirdek** liste | ek dosyaya taşınırsa, taşımayan her depoda yanlış pozitif doğar — ve yanlış pozitif **bastırma öğretir**, kural ikinci kez ölür |
| **Proje/alan adı** (ürün, şirket, şema terimi) | **ek** dosya | merkezde durursa merkez o tüketiciye bağımlı hale gelir |

Ölçülmüş sızıntı §1.3 sonundadır (`solum`/`vardiya`/`vrd`/`mizan`) — dördü de ikinci
kümedendi ve merkezden çıkarıldı. Birinci kümeden hiçbir şey çıkarılmadı.

**Ek sözlük (§8.5 kararı):** depo-yerel dosya, kendiliğinden bulunur. Ortam değişkeni
(`BKM_SOZLUK_EK`) elendi — ayarlanmazsa kapı sessizce dar dağarcıkla koşar ve fark
edilmez. Dosya **yoksa** hata değil (yokluk dağarcığı daraltır = kapıyı sıkıştırır,
güvenli yön); **varsa ama okunamıyorsa** KOŞAMADI (sessiz geçmek yasak).

⚠ **Merkezden çıkarılan 4 sözcük:** `solum`, `vardiya`, `vrd`, `mizan` — bunlar proje/
alan adıydı ve kanonik listeye sızmıştı. Aşama 3'te pusula göç ederken kendi
`kod-sozcukleri.ek.txt`'sine ya da `alan_adlari`'na yazmalı, yoksa kapı onları
"ak listede YOK" diye kırar.

### 1.4 Sınama — altı koşum, her biri sabotaj + geri alma ile

| # | Koşum | Beklenen | Sonuç |
|---|---|--:|--:|
| A | Ayarsız süpürme, sahte tüketici depoda | KOŞAMADI (2) + **kökü tüketici göstersin** | ✅ |
| B | Türkçe tanımlayıcılı `.cs` | KIRIK (1) | ✅ |
| C | İngilizce kod + **Türkçe yorum ve dize** | geçti (0) | ✅ |
| G/H/I | `alan_adlari` → boşalt (sabotaj) → geri al | 0 → 1 → 0 | ✅ |
| D/K | ek sözlük ekle → sil (sabotaj) | 0 → 1 | ✅ |
| F | ek sözlük VAR ama okunamıyor | KOŞAMADI (2) | ✅ |

**Sınama iki gerçek hata buldu — ikisi de yazılırken görünmüyordu:**

1. **Yarım taşıma (benim eklediğim ayar):** `alan_adlari` önce yalnız kara liste
   katmanında okunuyordu; ak liste katmanı aynı adı *"tanımıyorum"* diye kırıyordu.
   Ayar "serbest" diyor, kapı kırıyordu. Düzeltildi. — pusula'nın kendi kuralı:
   *"yarım yapılmış taşıma, hiç yapılmamış olandan kötüdür."*
2. **Ölçüm hatası (bende):** `out=$(…) | tail -1; echo $?` kalıbı **tail'in** çıkışını
   veriyor, python'unkini değil → kırmızı bir koşumu "geçti" okudum. Devir §7'deki
   *"yanlış payda"* sınıfının aynısı. Çıkış kodu artık borusuz ölçülüyor.

**Bilinen keskin kenar (düzeltilmedi, bilerek):** kara listedeki iki harfli sözcükler
(`Ek`, `Kur`) dosya adında `\b` olmadan aranıyor → içinde `Ek` geçen İngilizce dosya adı
yanlış pozitif verebilir. Sınamada bunu ben yaşadım (`Ek.cs`). Düzeltmek kara liste
eşleşmesini değiştirir ve **pusula'daki canlı davranışı** oynatır; Aşama 3'te o deponun
kendi oturumunda ölçülerek yapılmalı.

---

## 2. 12 SAPMANIN SINIFLANDIRMASI — bayat mı, bilerek mi

Yöntem: `harvest.sh --diff` + iki taraftaki son değişiklik tarihi + içeriğin
**proje-bağımlılığı**. Tercihle değil ölçümle.

> ⚠ Tarih tek başına kanıt değil — 12'nin 11'inde pusula daha yeni, ama bunların
> yarısı yerel eklemedir. Karar içeriğe bakılarak verildi.

### 2.1 ŞABLON BAYAT — pusula kanonik (5) → **terfi edildi**

| Dosya | Ne eksikti | Nereye gitti |
|---|---|---|
| `test-discipline.md` | **YAZILI KURAL ≠ UYGULANAN KURAL** (10 ölçülmüş vaka) + davranışsal kontrat > snapshot | `_universal` |
| `error-handling.md` | **Reddet mi / Say mı** ölçütü (çelişki→reddet, eksiklik→say) + merkezi hata sınıflandırıcı | `_universal` |
| `commit-discipline.md` | commit → TODO `[x]` aynı anda · **kırmızı kip geri alma** (yasak liste niyete bakmaz) | `_universal` |
| `todo-verification.md` | yeni madde öncesi **dup-grep** | `_universal` |
| `file-size-discipline.md` | C# `partial class` sıfır-risk split · Blazor `.razor` code-behind nüansı | **`stacks/dotnet-mvc`** |

Not: sonuncusu `_universal`'a **gitmedi** — içeriği .NET'e bağlı. `_universal`'a yalnız
stack katmanına işaret eden bir satır eklendi.

`error-handling`'e giren *"Reddet mi / Say mı"* ölçütü aslında **iki depoda bağımsız
olgunlaşmış**: `dogrulama-siniri.md` 4 depoda ayrı bir kural olarak duruyor, pusula ise
onu `error-handling` içine yazmış. Merkezde artık tek yerde.

### 2.2 BİLEREK YEREL — şablon kanonik kalır (5)

| Dosya | pusula'nın eklediği | Neden yerel |
|---|---|---|
| `coding-discipline.md` | Blazor auth, Lucide ikon circuit çökmesi, pyodbc/pymssql collation | Tamamı stack dersi — `stacks/*` malzemesi, `_universal` değil |
| `before-major-change.md` | "İlk dokunuş" kuralı: bilinmeyen tabloya sorgudan önce şemaya bak | ERP/şema katmanına bağlı; genel karşılığı (`önce oku, mevcut kalıbı taklit et`) şablonda zaten var |
| `session-memory.md` | `docs/journal/<proje>/` alt dizini | pusula **çok ürünlü** bir depo; tek ürünlü depoda gereksiz |
| `turkish-ui.md` | "Rule katmanı: on-demand … plan-12 WS-2" satırı | pusula'nın kendi plan numarasına atıf |
| `footprint-ladder.md` | BKM'ye özgü basamaklar (sema-entity, dashboard sayfası) | **Şablonunki daha yeni ve genelleştirilmiş** (24.08) — bu sapmada bayat olan pusula |

⚠ `footprint-ladder` bu listenin tersini gösteriyor: **her sapmada merkez haksız değil.**
Tarihe bakıp "proje hep daha yeni" varsaymak bu dosyada yanlış sonuç verirdi.

### 2.3 KARMA — iki yönlü, **karar bekliyor** (2)

| Dosya | Merkez lehine | Tüketici lehine |
|---|---|---|
| `session-protocol.md` | pusula **5 bölüm kaybetmiş**: memory okuma adımı, compliance scan, zorunlu ilk-yanıt formatı, TodoWrite+plan-tracker, PowerShell varyantı | pusula'nın **"ara journal"** bölümü (oturum sürerken periyodik kayıt) merkezde yok ve evrensel |
| `agent-usage.md` | — | **§7 Rol & Derinlik** (leaf/orchestrator, `max_concurrent=3`, derinlik ≤2) olgun ve evrensel; merkezde yok |

Bu ikisi GMY'nin onayladığı "5 bayat kural" kapsamının dışındaydı, bu yüzden
**dokunulmadı**. İkisi de terfi adayı — kapsamı kendiliğinden genişletmemek için
karara bırakıldı.

### 2.4 Tabloya sığmayan: pusula'nın 7 yerel kuralı

`emitter-ayrimi` · `erp-write-policy` · `olctum-mu-cikardim-mi` · `renk-standardi` ·
`semantic-layer` · `sql-server-conventions` (597 satır) · `sunum-dili`.

İkisi yaygın ve evrensel görünüyor: `olctum-mu-cikardim-mi.md` (5 depo) ve
`dogrulama-siniri.md` (4 depo). Aşama 3'te ele alınacak — bu oturumun kapsamında değildi.

---

## 3. GMY KARARLARI (devir §8)

| # | Soru | Karar |
|---|---|---|
| 1 | Depo adı | **`Norma`** (Latince gönye; `Solum` ile aynı katman dili). ⚠ **Şimdi değil** — Aşama 2'de `bootstrap --reference` ile **aynı commit'te**. Adı değiştirip davranışı bırakmak kozmetiktir. |
| 2 | Kanonik kural kümesi | Bayat olan 5 kural **şimdi** terfi etsin (yapıldı, §2.1) |
| 3 | Yerel kural eşiği | **Eşik kaldırıldı** — `harvest` artık öneri üretmiyor |
| 4 | Kapıların yeri | **Depo kökünde `tools/`** (yapıldı, §1.1) |
| 5 | Proje-yerel ek sözlük | **Depo-yerel dosya, kendiliğinden bulunur** (yapıldı, §1.3) |

### 3.1 Eşik neden kaldırıldı — ölçüm

`harvest.sh` "5+ depo → `_universal` adayı, 2+ → `stacks/*` adayı" diyordu. Ölçüldü:

| Dosya | Depo | Gerçek sınıf |
|---|--:|---|
| `csharp-conventions.md` | 9 | **stack** |
| `razor-conventions.md` | 8 | **stack** |
| `architecture.md` | 8 | proje |
| `sql-conventions.md` | 7 | **stack** |
| `advisor-skills.md` | 7 | evrensel olabilir |
| `phase-review-gate.md` | 6 | **stack/süreç** |
| `inline-style-guard.md` | 6 | **stack** |
| `olctum-mu-cikardim-mi.md` | 5 | **evrensel** |

Eşiği geçen 8 dosyanın yarısı stack kuralı — **en yaygın dördü** (9/8/8/7) zaten evrensel
değil. Yani eşiği yükseltmek isabeti artırmıyor. Dahası eşik, `harvest.sh`'ın **kendi
başlığıyla** çelişiyordu: *"Yaygın olmak evrensel olmanın KANITI değildir."* Script artık
sayıyı verip sınıfı insana bırakıyor.

---

## 4. `harvest.sh` artık kapıları da görüyor

Ölçülmüş boşluk: harvest kategorileri `rules/skills/agents/hooks/commands` idi ve hepsi
`.claude/` altını arıyordu. **Ekosistemin en olgun kapısı `tools/` altındaydı ve harvest
onu hiç görmüyordu** — yani "geri akış yolu var" cümlesi kapılar için yanlıştı ve bu
terfi **elle** yapılmak zorunda kaldı.

`tools` kategorisi eklendi: proje tarafında `<proje>/tools/`, merkez tarafında
`<kök>/tools/` (katmansız — kapıların `_universal`/`stacks` ayrımı yok).

---

## 5. TÜKETİCİ NE YAPACAK (Aşama 3 reçetesi — bu oturumda UYGULANMADI)

Kapıyı kopyalama; **çağır**:

```bash
python ../claude-context-template/tools/turkce_tanimlayici_denetimi.py <dosya...>
```

Kancadan çağırırken üç şart (`bkm-magaza/.claude/hooks/pre-commit-denetim.sh` deseni):
1. Yalnız **yeni/dokunulan** dosyaları ver — mevcut Türkçe adlara bakmak her commit'i
   bloklar ve kapı ilk gün kapatılır.
2. Araç yoksa ya da koşamazsa **SARI uyar**, sessizce geçme.
3. Süpürme kipini kullanacaksan `.claude/turkce-kapi.json` yaz; yoksa KOŞAMADI der.

İsteğe bağlı: `.claude/kod-sozcukleri.ek.txt` (kendi İngilizce sözcüklerin),
`.claude/turkce-taban.json` (devralınmış borcu dondurmak için).

---

## 5.5 TÜKETİCİLERDEN GELEN DÜZELTMELER (aynı gün, ölçümle)

Aşama 1 yayımlandıktan sonra üç tüketici oturumu ölçüm gönderdi. Dördü kabul edildi,
biri ölçülerek reddedildi. **Hepsi merkezin kendi kusuruydu.**

| # | Bildiren | Bulgu | Sonuç |
|---|---|---|---|
| 1 | bkm-magaza | 5 İngilizce sözcük ek sözlüğün gerekçesi değil — jenerik programlama sözcükleri, çekirdekte kalmalı | **kabul**, araç + belge düzeltildi (§1.3 ayrım tablosu) |
| 2 | bkm-magaza | Dağıtılan bildirim dosyaları **ASCII sadeleştirilmiş Türkçe** içeriyor — `turkish-ui.md:18` ihlali, üstelik karışık ("yanlis" ile "doğar" yan yana) | **kabul**, 39 depoda yeniden üretildi |
| 3 | reporthub | `_universal/work-protocol.md`'de **bkmargus ×5**, `footprint-ladder.md`'de **pusula ×1** — evrensel katmanda proje adı | **kabul**, temizlendi + `durum.sh`'a kapı eklendi |
| 4 | reporthub + BkmArgus (bağımsız) | "BAYATLAYAN kopyalar" etiketi **tek yönlü okutuyor**; her beş dosyada da iki yönde fark var, "bayat" sanıp silmek yerelde olgunlaşanı yok eder | **kabul**, etiket "AYRIŞMIŞ" + üç kova oldu |
| 5 | BkmArgus | `durum.sh` `cmp -s` yüzünden satır sonunu sapma sayıyor, 169 şişik | **ölçülerek reddedildi** — 169'un sıfırı CR kaynaklı (§0). Ölçüt yine de düzeltildi |

📐 **Ders:** beşinin de kaynağı merkezdi ve beşi de merkezde **görünmüyordu**. Tüketici
tarafı, merkezin kör noktasını gören tek yer — çünkü kuralı *kullanan* orası. Bu, kararın
"geri akış" ayağının kural metniyle değil **ölçümle** işlediğinin ilk kanıtı.

### Merkezin kendi kapısı — `_universal`'da proje adı taraması

`durum.sh` artık kendi sağlığını da raporluyor. Sabotajla sınandı (kırmızı gördü, geri
alındı, iz kalmadı).

⚠ **Ne yakalamadığı yazılı:** yalnız teknik bağlamdaki ad (`ad-`, `/ad`, `` `ad` ``)
yakalanır; düz cümledeki *"pusula'dan uyarlandı"* **yakalanmaz**. Sebep ölçüldü: geniş
sürüm, `ajan` adlı depo yüzünden `agent-usage.md`'de **7 bulgunun 7'sini yanlış pozitif**
verdi ("ajan" sıradan bir Türkçe sözcük). Bu ekosistem aynı sınıfta bir kapıyı zaten
ölçüp silmişti — yanlış pozitif bastırma öğretir.

### Bildirim dosyasının kendi testi

Üreteç, ürettiği metni kendi üzerinde sınıyor (kapı değil — merkeze "yorumda ASCII"
kapısı **konmadı**, çünkü bu depo onu ölçüp reddetmişti). İki sınama:
- ASCII sokulunca **KOŞAMADI (2)** veriyor.
- Düzgün Türkçe (ALL-CAPS dahil) **yanlış pozitif üretmiyor**.

⚠ İlk sürümü kırıktı ve ders kayda değer: `re.IGNORECASE` Python'da Türkçe `ı` ile ASCII
`i`yi **aynı sayıyor** (`"ı".upper() == "I"`), bu yüzden test *"kırıcı"*, *"uyarı"*,
*"kopyası"* gibi **doğru** sözcükleri ASCII sanıp kırıyordu. Yani testin kendisi,
ölçtüğü şeyin kör noktasını miras almıştı — `test-discipline` § *kapı kendi kör noktasını
miras alır* maddesinin canlı örneği.

## 6. AÇIK KALANLAR

1. **`session-protocol` ve `agent-usage`** (§2.3) — iki yönlü sapma, terfi kararı bekliyor.
2. **Aşama 2** — `bootstrap --reference` kipi + depo adının `Norma` olması (aynı commit).
3. **Aşama 3** — 37 depo, her biri kendi oturumunda. Sıra önerisi devir §6'da.
4. **pusula'nın kendi göçü** — kopyaları bırakıp referansa geçerken `solum`/`vardiya`/
   `vrd`/`mizan` sözcüklerini kendi ek dosyasına taşımalı (§1.3).
5. **İki ölçüm aracı aynı paydayı kullanmıyor.** `durum.sh` 39 depoyu kendiliğinden
   keşfediyor; `harvest.sh --scan` ise `bin/projects.txt` doluysa yalnız oradaki **3**
   depoyu tarıyor (BkmArgus, Operax, reporthub). Yani `--scan` çıktısı "ekosistem"
   sanılırsa eksik okunur — devir §7'deki *yanlış payda* tuzağının bir başka yüzü.
6. **Ad değişiminin kapsamı: ham sayı DEĞİL, SINIFLANDIRMA kullanılmalı.**
   Eski adı taşıyan dosyalar dört ayrı türdedir ve üçüne farklı davranılır:

   | Tür | Ne yapılır |
   |---|---|
   | **Canlı referans** (`CLAUDE.md`, kanca, kurulum betiği) | düzeltilir |
   | **Tarihsel kayıt** (`docs/journal/*`, `HANDOFF.md`) | ⚠ **DOKUNULMAZ** — o dosya o tarihte neyin doğru olduğunu kaydeder; adı değiştirmek geçmişi tahrif etmektir |
   | **Atılabilir kopya** (`*/worktrees/*` altında aynı dosyanın tekrarı) | düzeltilmez, atılır |
   | **Gömülü şablon kopyası** | Aşama 3 işi, ad işi değil |

   ⚠ **Ölçülmüş:** bir tüketicinin (`AtlasOPS`) içinde `claude-context-template/` diye
   **gömülü bir merkez kopyası** var (README + `docs/USAGE.md`). Merkezin kendisinin bir
   tüketicinin içine kopyalanmış olması, kopya modelinin en saf hâli — ve `durum.sh` onu
   ayrı depo olarak değil AtlasOPS'un parçası olarak görüyor, yani **169/170 sayısına
   hiç girmiyor.**

   Ham sayı üç kez ölçüldü ve üçünde de farklı çıktı (sıfır → 28 → 69), çünkü ölçümler
   ya kesikti ya dağıtımın ortasında koştu. **Bu sayıya ben ~71 dosya ekledim** (39
   bildirim + 32 `CLAUDE.md` işaretçisi). Aşama 2 planı sayıya değil yukarıdaki
   sınıflandırmaya dayandırılmalı; geçiş bitene kadar `durum.sh` eski adla kalan **canlı
   referans** sayısını raporlamalı (tarihsel kayıtlar hariç tutularak).

6b. **Ad değişiminin eski hâli (kayıt için).** Bir tüketici `claude-context-template`
   dizesini **4 depoda 28 dosyada** ölçtü (AtlasOPS 24 · ChocoTR 2 · duaasistan 1 ·
   BkmArgus 1) — ve bunu daha önce "sıfır" diye bildirdiğini kendisi düzeltti.
   ⚠ **Bu sayıya ben 71 dosya EKLEDİM** (39 bildirim + 32 `CLAUDE.md` işaretçisi), yani
   Aşama 2'deki yeniden adlandırmanın yükü ~99 dosya. Her depoda yol **tek yerde**
   olduğu için düzeltme depo başına iki dosya, ama toplam sayı `durum.sh`'ta
   ölçülebilir olmalı: eski adla kalan dosya sıfıra inene kadar raporlanmalı, yoksa
   28'in 26'sı düzelir, ikisi yıllarca sessizce yanlış yolu gösterir.
7. **`harvest.sh --promote` güvenli değil** — ham `cp`, hedefi ezer. Hedefte
   commit'lenmemiş değişiklik varsa reddetmeli ya da `<dosya>.oneri` yazıp diff
   bırakmalı. Eşzamanlı iki oturumda bugünkü hâliyle veri kaybı üretir (reporthub
   bildirdi ve bu yüzden merkeze yazmaktan kaçındı — doğru davranış).
8. **16 terfi adayı bekliyor** (`reporthub/docs/MERKEZ-TERFI-ONERISI-2026-09-23.md`) +
   BkmArgus'tan 4 aday (15 dosya eşiği, faz kapanış zinciri, bloklayan danışman kapısı,
   `advisor-skills` deseni). Hiçbiri bu oturumda uygulanmadı — onaylanan kapsam dışıydı.
9. **Bu kararın hâlâ kapısı yok.** `durum.sh` raporlar, engellemez. Engelleme Aşama 2'de
   `bootstrap`'a girer. O güne kadar bu belge *yazılı ama zorlanmayan* bir kuraldır —
   ve bu ekosistemin en pahalı hata sınıfı tam olarak budur.
