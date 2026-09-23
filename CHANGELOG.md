# Changelog

Bicim: [Keep a Changelog](https://keepachangelog.com) · Surumleme: [SemVer](https://semver.org)

## [1.6.0] - 2026-09-23

ASAMA 2 — KOPYA KIPI VARSAYILAN OLMAKTAN CIKTI.

1.5.0 tek merkezi kurdu ama kapisi yoktu: bugun kurulan yeni bir depo yine 18 kural
kopyasi alir ve dogdugu anda 171'inci sapma adayi olurdu. Bu surum o kapiyi koyuyor.

### Degisti — KIRICI

- **`bootstrap.sh` ve `bootstrap.ps1` varsayilani artik REFERANS.** Kural dosyalari
  KOPYALANMAZ; `CLAUDE.md`'ye hangi kurallarin gecerli oldugunu ADIYLA SAYAN bir
  isaretci blogu yazilir (olculmus referans uygulama `bkm-magaza/CLAUDE.md` deseni:
  yol vermek "bir yerlerde var" der, LISTE vermek "sunlar seni baglar" der).
- **`--copy` / `-Copy` hala var ama GEREKCE ISTER** (`--reason` / `-Reason`).
  Gerekcesiz kopya reddedilir (cikis 1) ve gerekce `CLAUDE.md`'ye islenir — bir yil
  sonra okuyan "bayat mi bilerek mi" diye sormak zorunda kalmasin diye.

### Eklendi

- **`bin/_merkez_blok.py`** — isaretci blogunu CLAUDE.md'ye yazan/tazeleyen yardimci.
  Idempotent (blok varsa DEGISTIRILIR). Ayri dosya olmasinin sebebi olculdu: blok
  metni backtick, tirnak ve Turkce karakter tasiyor ve heredoc'a gomulunce kacis
  katmanlari eriyip kodu bozdu (DEVIR §7 ilk tuzagi).
- **Referans kipinde YEREL kural baglantilari merkeze cevrilir.** Sablonun CLAUDE.md'si
  metin icinde `.claude/rules/session-protocol.md` gibi yerel yollara baglanti veriyor;
  o dosyalar kopyalanmadigi icin baglantilar bosluga giderdi — ve okuyan "kural yok"
  demez, baglantiya TIKLAMAZ ve kurali hic okumaz.
- **`--update` / `-Update` kipinde isaretci TAZELENIR** — bayat bir kural listesi,
  listenin olmamasindan beterdir (okuyan onu guncel sanir).

### Duzeltildi

- **`durum.sh` REFERANS tespiti Asama 2'nin sonucunu GOREMIYORDU.** Desen yalniz
  `../<depo>/.claude/rules` bicimini taniyordu; merkezin kanonik yolunda arada
  `templates/` var. Yani `bootstrap --reference` ile kurulan depo "REFERANS" degil
  "-" gorunurdu: kapinin olctugu sey, olcmesi gereken sey degildi.
- **`python3` bu makinede YOK** (yalniz `python`) ve kod `python3` diyordu — ilgili
  adim SESSIZCE atlaniyordu. Artik komut cozumleniyor (`python3`/`python`/`py`), VE
  referans kipinde blok yazilamazsa kurulum SERT HATA verir (cikis 2). Gerekce:
  o durumda kural dosyasi da yok, isaretci de yok — geriye KURALSIZ ama "kuruldu"
  gorunen bir depo kalir.
- `bootstrap.ps1` artik **UTF-8 BOM'lu** (DEVIR §7 ikinci tuzagi: BOM'suz UTF-8 bir
  Turkce .ps1'i PS 5.1 ANSI okur).
- Bitis ozeti kipe gore dogru konusuyor (eskiden referans kipinde de "15 universal
  kopyalandi" diyordu).

### Sinandi

Yedi kosum, ikisi sabotaj: gerekcesiz `--copy` RET · varsayilan referans (kural
kopyalanmadi, 22 kural adiyla listelendi) · `durum.sh` REFERANS goruyor · `--copy
--reason` kopyaladi ve gerekceyi yazdi · **python yokken referans kipi KOSAMADI(2)
verdi** · PowerShell iki kipte de calisti · baglanti duzeltmesi sonrasi sarkan yerel
kural baglantisi 0.

## [1.5.0] - 2026-09-23

TEK MERKEZ (Asama 1 — `docs/MIMARI-KARARI-2026-09-23.md`). 1.4.0 geri akis yolunu
ekledi ama bir ay sonra yakinsama olmadi: sebep eksik ayak degil, **iki merkez**
olmasiydi. Ekosistemin en olgun kapisi sablonda degil bir TUKETICIDE (`pusula`)
duruyordu; `bkm-magaza` kurallar icin sablonu degil onu isaret ediyordu. Bu surum
o kapiyi merkeze aliyor ve sablonun kendi bayat kurallarini kapatiyor.

Olcum degismedi (39 depo · SAPMA 158 · referans 1) — tuketici deposuna dokunulmadi.
SAPMA'nin dusmesi Asama 3'un isi ve depo basina, kendi oturumunda yapilir.

### Eklendi

- **`tools/turkce_tanimlayici_denetimi.py` + `tools/kod-sozcukleri.txt`** — pusula'dan
  terfi. Uc katmanli kapi: Turkce harf taramasi + ASCII kara liste + AK LISTE.
  Yorumlari ve dizeleri BILEREK taramaz (onlar Turkce olmali).
  - Kok artik CAGIRANIN yerinden bulunur (`.git`/`.claude` yukari arama ya da
    `TURKCE_KAPI_KOK`). ⚠ Terfide duzeltilen en kritik sey: eski `__file__.parent.parent`
    merkeze tasininca kapinin SABLONU taramasina yol acardi — sessizce yesil.
  - Projeye bagli ne varsa tuketiciye tasindi: `.claude/turkce-kapi.json` (kapsam,
    alan adlari), `.claude/kod-sozcukleri.ek.txt` (deponun kendi sozcukleri),
    `.claude/turkce-taban.json` (donmus borc).
  - Alti kosumla sinandi, her biri sabotaj + geri alma ile.
- **`docs/ASAMA-1-TEK-MERKEZ-2026-09-23.md`** — 12 sapmanin tek tek siniflandirmasi
  (bayat mi / bilerek mi), GMY kararlari, Asama 3 recetesi.
- **`harvest.sh` `tools` kategorisi** — kapilar `.claude/` altinda degil depo kokunde
  durur ve harvest onlari HIC gormuyordu; ilk terfi bu yuzden elle yapildi.

### Degisti

- **`_universal/test-discipline.md`** — YAZILI KURAL ≠ UYGULANAN KURAL (on olculmus
  vaka) + davranissal kontrat > snapshot. Sablon bayatti.
- **`_universal/error-handling.md`** — "Reddet mi, Say mi?" dogrulama siniri olcutu
  (celiski→reddet, eksiklik→say) + merkezi hata siniflandirici.
- **`_universal/commit-discipline.md`** — commit → TODO `[x]` ayni anda · kirmizi kip
  geri alirken yasak liste NIYETE bakmaz (`reset --hard` vakasi).
- **`_universal/todo-verification.md`** — yeni madde acmadan once dup-grep.
- **`stacks/dotnet-mvc/csharp-conventions.md`** — `partial class` sifir-risk split +
  Blazor `.razor` code-behind nuansi. (`_universal`'a DEGIL: icerik .NET'e bagli.)
- **`harvest.sh` esigi KALDIRILDI** — "5+ depo → _universal adayi" oneri uretmeyi
  birakti. Olculdu: esigi gecen 8 dosyanin 4'u stack kuralidir; en yaygin dordu
  (9/8/8/7 depo) zaten evrensel degil. Esik, scriptin kendi basligiyla celisiyordu.
- **`_universal/footprint-ladder.md`** — icindeki proje adi sizintisi temizlendi.
- Cekirdek ak listeden 4 proje/alan adi cikarildi (`solum`, `vardiya`, `vrd`, `mizan`) —
  kanonik liste proje adi tasimaz.

### Duzeltildi (ayni gun, tuketici olcumleriyle)

- **`_universal` proje adi tasiyordu** — `work-protocol.md` bes ayri yerde bir
  tuketicinin ajan adlarini (`bkmargus-*`), `footprint-ladder.md` bir baska depoyu
  aniyordu. Temizlendi. Somut zarar: baska bir depo o kurali okuyup VAR OLMAYAN
  ajanlari cagirmaya calisir ve "danistim" sanir.
- **`durum.sh`'a MERKEZ SAGLIGI kapisi** — `_universal`'da proje adi taramasi.
  Sabotajla sinandi. Dar tutuldu (yalniz teknik baglamdaki ad): genis surum `ajan`
  adli depo yuzunden 7 bulgunun 7'sini yanlis pozitif verdi.
- **`durum.sh` artik `diff --strip-trailing-cr`** kullaniyor (`cmp -s` degil).
  ⚠ Olculdu: bugunku 169 sapmanin SIFIRI satir-sonu kaynakli, yani sayi DEGISMIYOR.
  Olcutun dogru olmasi bugun fark yaratmasindan bagimsizdir.
- **Tuketicilere birakilan bildirim dosyalari** (39 depo) ASCII sadelestirilmis Turkce
  iceriyordu — `turkish-ui.md:18` ihlali, ustelik karisik. Duzgun Turkceye cevrildi ve
  ureteci kendi ciktisini sinar hale getirildi.
- **"BAYATLAYAN" etiketi "AYRISMIS"a cevrildi.** Iki tuketici bagimsiz olarak olctu:
  bes dosyanin besinde de IKI YONDE fark var. "Bayat" sanip silmek, yerelde olgunlasan
  kurali ekosistemden sessizce yok eder. Bildirim artik uc kova gosteriyor.

### Bilinen — kapanmadi

- `session-protocol.md` ve `agent-usage.md` iki yonlu sapiyor (her iki tarafta da
  otekinde olmayan olgun icerik var); terfi karari bekliyor.
- Depo adi `Norma` olacak ama **Asama 2'de**, `bootstrap --reference` ile ayni commit'te.
  Adi degistirip davranisi birakmak kozmetiktir.
- `bin/projects.txt` 3 depo iceriyor; `harvest --scan` yalniz onlari tarar, `durum.sh`
  ise 39'unu kesfeder. Iki olcum araci ayni paydayi kullanmiyor.

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

