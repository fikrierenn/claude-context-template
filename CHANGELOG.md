# Changelog

Bicim: [Keep a Changelog](https://keepachangelog.com) · Surumleme: [SemVer](https://semver.org)

## [1.4.0] - 2026-08-23

Sablon 11 Haziran'dan 23 Agustos'a kadar **0 commit** aldi. Ayni donemde
projeler .claude/ altina 100'un uzerinde commit atti (pusula 48, Operax 35,
reporthub 28, BkmArgus 6). Sebep mimari degildi — `_universal`/`stacks`/`project`
ayrimi dogruydu, bootstrap calisiyordu. Sebep **geri akis yolunun olmamasiydi**:
iyilestirme isin yapildigi yerde doguyor, merkeze donemiyor, merkez geride
kaliyor, geride kalinca `update` projeleri GERIYE alacagi icin kimse
calistirmiyor. Bu surum o dongunun eksik ayagini ekliyor.

### Eklendi

- **`bin/harvest.sh`** — ters yon. Projelerde olgunlasan yetenegi sablona tasir.
  - `--scan` neyin geride kaldigini listeler (yayginlik + sapma)
  - `--diff <dosya> <proje>` farki gosterir
  - `--promote <dosya> --from <proje> --to <hedef>` terfi ettirir
  - Siniflandirmayi (universal/stack/local) **makine yapmaz**; yayginlik olcer, oneri verir, karari insan verir.
  - `projects.txt` bossa `D:\Dev` altinda `.claude/` olan projeleri otomatik kesfeder.

- **`_universal/evidence-discipline.md`** — olc, dogrula ya da "DOGRULANMADI" de.
  Alt-ajan ciktisi kanit degildir. (Tarama: 8 hedef projenin **hicbirinde** yoktu.)

- **`_universal/work-protocol.md`** — Danis → Yap → Kontrol Ettir → Smoke.
  (8 projeden 7'sinde yoktu.)

- **`_universal/footprint-ladder.md`** — yeni yetenek en dar basamakta.

- **`_universal/skills/cati-degerlendirme`** — dis bir catiyi (ABP, XAF, Orchard,
  Aspire, Clean Architecture sablonlari…) inceleyip ondan ne alinacagina karar
  verme danismani. Kopya olcumu, cati/kutuphane/sablon ayrimi, aktif tuketici
  kosulu, mekanizma-esleme ayrimi, strangler goc modeli.

- **`_universal/skills/surum-disiplini`** — paket surumleme ve degisiklik gunlugu.
  SemVer karari, CHANGELOG bakimi, public API yuzeyi izleme
  (`Microsoft.CodeAnalysis.PublicApiAnalyzers`), sinsi kirici degisiklikler.

- **`hooks/pre-edit-advisor-gate.sh`** — bir alana oturumdaki ILK dokunusu
  **BLOKLAR**, hangi danismana danisilacagini soyler.

- **`hooks/pre-commit-review-gate.sh`** — staged dosyalara gore zorunlu
  denetcileri hesaplar; mesajda `[reviewed: ...]` ya da
  `[review-skipped: <gerekce>]` yoksa commit'i **BLOKLAR**.

### Onemli — hook'lar esleme dosyasi ISTER

Iki hook da **mekanizma**dir; hangi yolun hangi danismana/denetciye gittigi
**projeye ozeldir** ve sync EDILMEZ. Her projede su iki dosya olusturulmali:

```
.claude/advisor-map.conf    alan::desen1,desen2::danisman::gerekce
.claude/review-map.conf     etiket::grep-deseni::gerekce
```

Esleme dosyasi yoksa hook sessizce gecer (bloklamaz). Bu bilincli: yanlis
danismani isaret etmektense hic isaret etmemek yeglenir.

Gerekce olculdu: hook'lar once BkmArgus'un kendi danismanlarini gövdeye gömülü
tasiyordu. Operax'a tasindiginda orada o danismanlar yok — kapi bloklayip **var
olmayan** bir danismani isaret ediyordu.

### Duzeltildi

- **`projects.txt` bostu** — tum satirlar yorumdu, `update-all.sh` hic gercek bir
  projeye yoneltilmemisti. Uc proje ile dolduruldu (hepsi degil; uc proje
  calisirsa genisletilir).

