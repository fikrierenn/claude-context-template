# Somut Senaryo: Skill'i Neden İsterim, Ne Sağlar, Sana Nasıl Yaptırırım

> **Bu doküman kime?** "Tamam anladım da, *somut olarak* niye bir ERP danışmanı skill'i isteyeyim? Bana ne kazandırır? Claude'a **ne yazarım** da oluşturur?" diyen geliştirici.
> **Format:** İki gerçek örnek, baştan sona. Soyut ilke yok — acı, fayda, içerik, **kopyala-yapıştır prompt**, önce/sonra.

İçindekiler:
- [Önce: 30 saniyede mantık](#önce-30-saniyede-mantık)
- [Örnek 1 — ERP Danışmanı Skill'i](#örnek-1--erp-danışmanı-skilli)
- [Örnek 2 — Fatura Mevzuatı Skill'i](#örnek-2--fatura-mevzuatı-skilli)
- [Sana komut verme kalıpları (kopyala-yapıştır)](#sana-komut-verme-kalıpları)
- [Skill çalışırken neye benzer (önce/sonra)](#skill-çalışırken-neye-benzer)
- [Sık sorular](#sık-sorular)

---

## Önce: 30 saniyede mantık

Bir skill **bana (Claude'a) verdiğin kalıcı bir uzmanlık dosyasıdır.** İçine ne yazarsan, o konuda o şekilde davranırım — her oturum, hatırlatmana gerek kalmadan.

- **Neden isterim?** Çünkü her oturumda sana "biz ERP yapıyoruz, fatura şöyle kesilir, iade şöyle olur" diye baştan anlatmaktan yoruluyorsun. Bir kez yaz, bir daha anlatma.
- **Bana ne sağlar?** (1) Tutarlılık — her seferinde aynı doğru cevap. (2) Hız — anlatma zamanı sıfır. (3) Güvenlik — domain kuralını uydurmam, dosyadaki kaynağa bakarım.
- **Sen ne yaparsın?** Bana 3-4 cümlelik bir istek yazarsın ("şu konuda bir skill oluştur, şunları bilsin, şu ifadelerle tetiklensin"). Ben dosyayı yazarım. Onaylarsın. Biter.

---

## Örnek 1 — ERP Danışmanı Skill'i

### Neden oluştururum? (hangi acı?)

ERP projende yeni bir modül (sipariş, stok, cari) tasarlıyorsun. Bana her sorduğunda:
- "Bizim ERP single-tenant mı multi mi?" → her oturum tekrar açıklıyorsun.
- "Stok hareketi nasıl tutuluyor?" → tekrar.
- "Bu feature endüstri standardında var mı, eksik mi?" → ben genel cevap veriyorum, **senin** ERP'ne özgü değil.
- Ben bazen "şöyle yapılır" diye **genel bir ERP** mantığı uyduruyorum, seninkine uymuyor.

Bu acı, modül başına saatlerce tekrar + yanlış varsayım demek.

### Neden kullanmam gerekir?

Çünkü skill yoksa ben **her oturumda sıfırdan** başlarım. Dün anlattığını bugün bilmem. Skill = o anlattıklarının kalıcı hali. Kullanmazsan tekrar tekrar aynı şeyi yazarsın ve bir gün yazmayı unutursun → yanlış modül.

### Bana ne sağlar? (somut)

- **Modül tasarlarken** "endüstri-standart ERP'de bu modülde şu şu özellikler olur; sende şu var, şu eksik (gap), şu fazla (gereksiz)" diye **senin koduna bakarak** söylerim.
- "Logo/Mikro/SAP bunu nasıl yapıyor" sorusuna **proje notlarındaki** rakip analizine bakarak cevap veririm — uydurmadan.
- Her yeni modülde aynı kapsamda denetim → tutarlı.

### Nelerden oluşur? (skill'in içeriği)

Bir ERP danışmanı skill'i tipik olarak şunları içerir:

1. **Domain bilgisi:** ERP'nin mimari değişmezleri (single-tenant, her sorguda firma filtresi, ledger üç tabloda tutarlı, vb.).
2. **Modül checklist'i:** Her ERP modülünün endüstri-standart özellik listesi (sipariş modülü = onay akışı + iskonto + irsaliye bağı + iade...).
3. **Tetik ifadeleri:** "modül analizi", "gap analizi", "eksik tara" gibi — ne dediğinde devreye gireceği.
4. **Kaynak referansları:** Projedeki rakip analizi / referans dökümanları (varsa) — bunları okur, uydurmaz.
5. **Çıktı formatı:** EKSİK/FAZLA tablosu, öncelik.
6. **Kısıt:** "Sadece denetler, kod yazmaz" gibi (salt-rehber).

### Sana nasıl yaptırırım? (TAM PROMPT — kopyala, doldur, yapıştır)

```
Bana bir "erp-danismani" skill'i oluştur.

Ne yapsın: ERP modüllerimi endüstri-standart özellik checklist'iyle
karşılaştırsın, EKSİK (gap) ve FAZLA (gereksiz kod) çıkarsın.

Projemin değişmezleri: single-tenant, her sorguda CompanyId filtresi,
stok hareketi StockMovement tablosunda, muhasebe AccountMovement'ta,
ikisi her zaman tutarlı olmalı.

Şu ifadelerle tetiklensin: "modül analizi", "gap analizi", "eksik tara",
"erp denetimi".

Sadece denetlesin, kod yazmasın (salt-okuma). Çıktı: EKSİK/FAZLA tablosu.
Varsa docs/ altındaki rakip/referans analizi dosyalarını okusun.
```

Bu kadar. Ben bu istekten `.claude/skills/erp-danismani/SKILL.md` dosyasını yazarım, sana gösteririm, onaylarsın.

> Eksik bıraktığın yeri ben sorarım ("modül listesi nerede?", "rakip analizi dosyası var mı?"). Her detayı bilmen gerekmez — kabaca anlat, ben netleştiririm.

---

## Örnek 2 — Fatura Mevzuatı Skill'i

### Neden oluştururum? (hangi acı?)

Fatura / irsaliye / iade modülü yazıyorsun. Mevzuat (VUK, KDV, e-Belge) hatası = **yasal risk + para cezası**. Acı şu:
- Ben "fatura tarihi" kuralını **genel** biliyorum ama senin ülkene/sektörüne özgü detayı (sevk tarihi + 7 gün, e-fatura vs e-arşiv ayrımı) **uydurabilirim.**
- Sen her fatura işinde bana mevzuatı baştan hatırlatıyorsun.
- Bir gün hatırlatmayı unutuyorsun → ben yanlış varsayımla kod yazıyorum → yasal hata.

### Neden kullanmam gerekir?

Mevzuat en tehlikeli alan: ben **kendinden emin yanlış** cevap verebilirim (halüsinasyon). Skill bunu söndürür çünkü skill bana "karar verme, şu noktaları şu kaynaktan **doğrula**" der. Kullanmazsan benim genel bilgime güvenmiş olursun — riskli.

### Bana ne sağlar? (somut)

- Fatura modülü yazmadan **önce** "şu mevzuat noktalarını doğrula: tarih kuralı, tevkifat, iptal/düzeltme akışı" diye **kontrol listesi + kaynak** çıkarırım.
- "İade faturası nasıl kesilir" dediğinde mevzuat senaryosunu adımlarım, uydurmadan.
- Karar **sende** kalır — ben mevzuatı dayatmam, doğrulanacak noktaları gösteririm (SALT-REHBER). Yanlış kararı zorlamam.

### Nelerden oluşur?

1. **Kapsam:** Hangi evrak tipleri (fatura, irsaliye, iade, e-Belge, iptal/düzeltme).
2. **Doğrulama noktaları:** Kod yazmadan önce bakılacak mevzuat maddeleri (tarih kuralları, KDV, tevkifat, saklama).
3. **Senaryolar:** "Yanlış kesilmiş fatura iptal/düzeltme", "GİB'e gitmiş vs sistem-içi evrak ayrımı".
4. **Kaynaklar:** İlgili kanun/tebliğ referansları (uydurma değil, isimli kaynak).
5. **Tetik ifadeleri:** "iade faturası", "fatura iptal", "fatura tarihi kuralı", "VUK", "e-fatura senaryo".
6. **Kritik etiket:** `SALT-REHBER` — mevzuatı dayatmaz, doğrulanacak noktaları + kaynakları listeler. Kararı sana bırakır.

### Sana nasıl yaptırırım? (TAM PROMPT)

```
Bana bir "fatura-mevzuat" skill'i oluştur.

Ne yapsın: Fatura/irsaliye/iade/e-Belge modülü yazmadan ÖNCE, doğrulanacak
mevzuat noktalarını + resmi kaynakları listelesin. Karar dayatmasın —
SALT-REHBER olsun, kararı bana bıraksın.

Kapsasın: fatura tarih kuralı, KDV/tevkifat, iade faturası senaryosu,
yanlış fatura iptal vs düzeltme akışı, e-fatura/e-arşiv ayrımı.

Şu ifadelerle tetiklensin: "iade faturası", "fatura iptal", "fatura düzelt",
"fatura tarihi kuralı", "VUK", "e-fatura senaryo".

Mevzuatı uydurma — her madde için kaynak (kanun/tebliğ adı) belirtsin.
Emin olmadığın yerde "bunu mali müşavire doğrulat" desin.
```

Ben bundan `.claude/skills/fatura-mevzuat/SKILL.md`'yi yazarım. Mevzuat detayını **sen veya mali müşavirin** doldurur — ben iskeleti + bildiğim genel çerçeveyi kurarım, kesin maddeleri sen onaylarsın.

> Önemli: Mevzuat skill'inde ben "kesin doğru" iddia etmem. Skill'in işi beni **doğrulamaya zorlamak** — yanlış güvenle kod yazmamı engellemek.

---

## Sana komut verme kalıpları

Hangi araç istediğine göre bana şöyle yazarsın. Hepsi çalışır — detayı eksik bırakırsan ben sorarım.

### Skill istemek
```
Bana "<ad>" adında bir skill oluştur.
Ne yapsın: <bir cümle>
Bilmesi gerekenler: <domain kuralların>
Şu ifadelerle tetiklensin: <gerçek cümleler>
Kısıt: <salt-okuma mı, kod yazsın mı, karar dayatsın mı>
```

### Agent istemek (ağır/izole iş)
```
Bana "<ad>" agent'ı oluştur.
İzole olarak şunu yapsın: <denetim/analiz/araştırma>
Salt-okuma olsun, rapor dönsün (kod yazmasın).
Model: ucuz mekanik iş → haiku / yüksek-risk akıl → opus.
Şu durumda proaktif çağrılsın: <ne zaman>
```

### Hook istemek (otomatik/unutulmasın)
```
Bana bir hook oluştur.
Şu olayda çalışsın: commit öncesi / oturum başı / dosya yazımı sonrası
Şunu yapsın: <tara/blokla/bildir/kaydet>
settings.json kaydını da yap.
```

### Komut istemek (/x)
```
Bana "/<ad>" komutu oluştur.
Çalıştırınca şu akışı yapsın: <adımlar>
```

> **En kısa hali bile yeter:** *"Bana migration yazarken idempotent olmayı ve önce yedek almayı hatırlatan bir skill yap."* Gerisini ben sorarım/doldururum.

---

## Skill çalışırken neye benzer (önce/sonra)

### ÖNCE (skill yok)
```
Sen:    Sipariş modülüne iade ekleyeceğim.
Claude: Tamam, genel olarak iade için bir endpoint + status alanı eklerim...
        (senin ERP'nin ledger kuralını bilmez, stok geri-alımını atlar,
         CompanyId filtresini unutabilir)
Sen:    Yok, bizde iade ters stok hareketi atar, muhasebeye de yansır,
        hep CompanyId filtresi olur... (10 dk anlatım)
```

### SONRA (erp-danismani + reversal skill var)
```
Sen:    Sipariş modülüne iade ekleyeceğim. (veya: "gap analizi yap")
Claude: (skill devrede) Endüstri-standart iade akışı: ters stok hareketi +
        muhasebe yansıması + iade faturası bağı. Sende eksik: muhasebe
        yansıması yok (gap). CompanyId filtresi şart. İade = silme değil
        ters kayıt. Şu sırayla yapalım mı?
```

Fark: 10 dakikalık anlatım → 0. Yanlış varsayım → 0. Tutarlılık → her seferinde.

---

## Sık sorular

**S: Skill'i ben mi yazmalıyım, sen mi?**
Ben yazarım. Sen ne istediğini 3-4 cümleyle söyle, ben `.claude/skills/<ad>/SKILL.md`'yi oluştururum, onaylarsın.

**S: Mevzuat detayını bilmiyorum, yine de skill isteyebilir miyim?**
Evet. İskeleti + tetikleri ben kurarım, kesin maddeleri sonra sen/mali müşavirin doldurur. Skill'in asıl değeri: beni "doğrula, uydurma" moduna sokmak.

**S: Kötü olursa?**
Sil. Skill bir dosya — `.claude/skills/<ad>/` klasörünü silersin, biter. Yanlış tetikleniyorsa "tetik ifadelerini daralt" dersin, düzeltirim.

**S: Kaç tane skill yapayım?**
Acıyı çektiğin yerden başla. İlk 1-2 tane yeter. Aynı şeyi 2. kez anlattığında "bunu skill yap" de.

**S: Skill mi kural mı agent mi, hangisi?**
Karıştırma — bana "şunu istiyorum" diye anlat, **doğru tipi ben seçerim** ve gerekçesini söylerim. Kavramsal ayrım: [`PROJE_OZEL_KAVRAM.md`](PROJE_OZEL_KAVRAM.md).

---

### İlişkili Dökümanlar
- [`PROJE_OZEL_KAVRAM.md`](PROJE_OZEL_KAVRAM.md) — neden/niçin, zihinsel model.
- [`PROJE_OZEL_OLUSTURMA.md`](PROJE_OZEL_OLUSTURMA.md) — teknik yazım detayı (frontmatter, örnek katalog).
- [`GELISTIRICI_REHBERI.md`](GELISTIRICI_REHBERI.md) — mevcut araç kataloğu.
