# Mimari Kararı — şablon bir ÇATI olur: kopyalama değil referans

> Tarih: 2026-09-23 · Karar veren: GMY (*"solum gibi orası da bu işleri yapan bir skill/hook
> framework'ü gibi olmalı"*) · Ölçen ve yazan: bkm-magaza oturumu (SANAL-FIKRI)
> Ölçüm aracı: `bin/durum.sh` (bu kararla birlikte eklendi)

## 1. Ölçüm — 39 depo tarandı

```
TOPLAM: 39 depo · aynı 41 · SAPMA 158 · yerel 139 · referans modeli 1 depo
```

| Depo | aynı | sapma | yerel | model |
|---|--:|--:|--:|---|
| ajan | 1 | **16** | 16 | KOPYA |
| Operax | 1 | **15** | 10 | KOPYA |
| hal | 0 | **14** | 10 | KOPYA |
| BkmArgus · yonbkm | 3 / 4 | **13** | 8 / 7 | KOPYA |
| **pusula** | 3 | **12** | 7 | KOPYA |
| reporthub · mizan · spendmev3 | 0-1 | **12-13** | 2-11 | KOPYA |
| **bkm-magaza** | 0 | **0** | 1 | **REFERANS** |

Tek bir kuralın hâli: `turkish-ui.md` **11 depoda, 10 farklı içerik**; sapma 123 satıra kadar
çıkıyor — yani ayar farkı değil, **farklı kuşaklar** aynı anda canlı.

## 2. Teşhis — mimari değil, TÜKETİM MODELİ

`CHANGELOG 1.4.0` (23.08) şunu yazmıştı: *"Sebep mimari değildi — `_universal`/`stacks`/`project`
ayrımı doğruydu, bootstrap çalışıyordu. Sebep **geri akış yolunun olmamasıydı**."* Geri akış
(`harvest.sh`) eklendi. **Bir ay sonra ölçüm: yakınsama olmadı.** Demek ki eksik ayak o değildi.

Gerçek sebep, bir basamak daha derinde:

> **Şablon dosyaları KOPYALIYOR. Kopya, doğduğu anda ikinci bir gerçek olur.**

Kopya modelinde sapma *kaçınılmaz* ve *görünmez*: kimse 158 dosyayı elle diff'lemez, bu yüzden
`update` çalıştırılmaz, çalıştırılmayınca merkez geri kalır, geri kalınca çalıştırmak daha da
riskli olur. Kendini besleyen döngü.

**Karşı kanıt aynı ölçümde:** 39 depodan sapması sıfır olan **tek** depo `bkm-magaza` — çünkü
kopyalamıyor. `CLAUDE.md`'si şunu diyor:

> *"ANA ŞEMA VE KURALLAR BU DEPODA DEĞİL… Aynı bilgi iki yerde durmaz — kopyalamak yerine işaret
> ediyoruz (kopyalanan kural bayatlar ve iki gerçek doğar)."*

Ve bir tek bilinçli yerel kuralı var (`capacitor-kabuk.md`, gerekçesi dosyanın başında yazılı).

## 3. İkinci bulgu — İKİ MERKEZ var

Şablon kanonik sanılıyor, ama:
- `pusula` şablondan **12 kural sapmış** ve kendisi bir *tüketici*;
- ekosistemin en olgun kapısı (`turkce_tanimlayici_denetimi.py`, 406 satır, üç katman, 338
  sözcüklük ak liste) **pusula'da**, şablonda **yok**;
- `bkm-magaza` kurallar için pusula'yı işaret ediyor, şablonu değil.

Yani fiilen iki merkez yarışıyor. Tek merkez olmadan referans modeli de kurulamaz.

## 4. Karar

**Şablon, Solum'un runtime için olduğu şeyin geliştirme-zamanı karşılığı olur.**

| | Solum (runtime) | Şablon (geliştirme-zamanı) |
|---|---|---|
| İçerik | kimlik, yetki, CRUD, web kabuğu | kurallar, skill'ler, kancalar, kapılar |
| Tüketim | `ProjectReference` / NuGet — **referans** | **referans** (yol), kopya değil |
| Kırıcı değişiklik | derleme kırılır, hemen görünür | kapı/kural değişir, `durum.sh` gösterir |
| Geri akış | tüketici isteği (İSTEK-NN) | `harvest.sh --promote` |
| Sürüm | lockstep + CHANGELOG | VERSION + CHANGELOG |

Dört ilke:

1. **TEK MERKEZ.** `_universal` kanoniktir. pusula'daki olgun kapılar buraya terfi eder
   (`harvest.sh --promote` zaten bunun için var), sonra pusula da tüketici olur.
2. **KOPYA DEĞİL REFERANS.** Tüketicinin `CLAUDE.md`'si kanonik yolu işaret eder ve hangi
   kuralların geçerli olduğunu sayar. `bootstrap` yeni projeye **işaretçi** kurar, dosya değil.
3. **YEREL KURAL MEŞRUDUR — ama gerekçesi dosyada yazılı olur.** (`capacitor-kabuk.md` deseni:
   *"Bu kural yerel, çünkü komşu depo .NET/SQL odaklı; mobil paketleme orada yok."*)
4. **SAPMA ÖLÇÜLEBİLİR OLUR.** `bin/durum.sh` her depoyu AYNI / SAPMA / YEREL / REFERANS diye
   sınıflar. Ölçülmeyen yakınsama olmaz — bu belgenin kendisi o ölçümle yazıldı.

### Reddedilenler ve gerekçeleri

| Seçenek | Neden hayır |
|---|---|
| **Forklamak** | Bu tabloyu üreten şeyin ta kendisi. Çare hastalık olamaz |
| **Solum'a taşımak** | Solum runtime NuGet paketi dağıtıyor; kapıları xunit testi (yalnız .NET) — ekosistemde python/JS/markdown depoları var. Lockstep sürüm treni bir kapı düzeltmesini paket sürümüne bağlardı. 39 deponun çoğu Solum kullanmıyor |
| **Yeni ortak depo** | `footprint-ladder` 6. basamak. Şablon zaten var ve mimarisi doğru; 1. basamak (mevcudu genişlet) yetiyor |
| **Depoyu yeniden adlandırmak** | Ad (`template`) "bir kez damgala" çağrıştırıyor, doğru eleştiri — ama darboğaz ad değil tüketim modeli. Model düzelmeden ad değişikliği kozmetik olur; sonraya bırakıldı |

## 5. Göç — aşamalı, her aşama ölçülür

`durum.sh` çıktısı ilerleme göstergesidir: **referans modeli 1 → 39**, **SAPMA 158 → 0**.

| Aşama | Ne | Kim |
|---|---|---|
| 0 | `durum.sh` (bitti) — taban ölçüm alındı | ✅ |
| 1 | pusula'nın olgun kapıları `_universal`'a terfi (`harvest --promote`) → tek merkez | GMY onayı |
| 2 | `bootstrap --reference` kipi: yeni proje kopya değil işaretçi alır | şablon oturumu |
| 3 | Depo depo göç: kopyalar silinir, `CLAUDE.md` işaretçiye döner, yerel kurallar gerekçeleriyle kalır | her deponun kendi oturumu |
| 4 | Sapma sıfırlanınca `harvest` tek yön kalır: yerelde olgunlaşan → merkeze | — |

⚠ **3. aşama tek oturumda yapılmaz.** 37 depoda kopya var, bazılarında başka oturumlar çalışıyor,
ve her sapmanın *bilerek mi bayat mı* olduğu insan kararı. Depo başına, kendi oturumunda.

## 6. Bu kararın kendi kapısı

Karar yazıldı ama **kapısı yok**: bir depo yarın yine kopya alabilir. `durum.sh` bunu *raporlar*,
engellemez. Engelleme 2. aşamada `bootstrap`'a girer (kopya kipi varsayılan olmaktan çıkar).
O güne kadar bu belge **yazılı ama zorlanmayan** bir kuraldır ve bu ekosistemin en pahalı hata
sınıfı tam olarak budur (bkm-magaza'da üç kez ölçüldü: B-15 şema, D-008 saklama, D-010 dosya boyutu).
