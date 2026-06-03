# Projeye Özel Skill / Agent / Komut Oluşturma Rehberi

> **Bu doküman kime?** Bir projede tekrar tekrar aynı şeyi Claude'a anlatmaktan yorulan geliştirici.
> **Tez:** Template'in evrensel kuralları projenin **domain bilgisini** bilmez. Onu bir kez kodlarsın, bir daha anlatmazsın.

İçindekiler:
- [1. Neden Proje-Özel? (Önem)](#1-neden-proje-özel-önem)
- [2. Hangisini Yapmalı: Skill / Agent / Komut / Kural](#2-hangisini-yapmalı)
- [3. Anatomi — Frontmatter Sözleşmesi](#3-anatomi--frontmatter-sözleşmesi)
- [4. Skill Örnekleri (generic)](#4-skill-örnekleri-generic)
- [5. Agent Örnekleri (generic)](#5-agent-örnekleri-generic)
- [6. Tasarım İlkeleri (mutlaka uygula)](#6-tasarım-i̇lkeleri-mutlaka-uygula)
- [7. Eklemediysen Eksiksin — Tavsiye Edilenler](#7-eklemediysen-eksiksin)
- [8. Oluştur · Kaydet · Test Et](#8-oluştur--kaydet--test-et)

---

## 1. Neden Proje-Özel? (Önem)

Evrensel kurallar (`_universal/`) her projede aynıdır: commit disiplini, güvenlik temelleri, oturum protokolü. Ama **senin projenin** şunları kimse bilmez:

- **Domain kuralları:** "İade kaydı silinmez, ters kayıt atılır." "Ledger üç tabloda eşzamanlı tutarlı olmalı." Bunu her oturumda yeniden anlatırsan token + zaman yanar, üstelik bir gün **anlatmayı unutursun** → sessiz veri bozulması.
- **Mevzuat / regülasyon:** Fatura tarih kuralı, KDV tevkifat, saklama süresi. LLM "genel" bilir ama senin ülkene/sektörüne özgü detayı uydurabilir. Doğrulama noktalarını + kaynakları skill'e gömersen halüsinasyon riski düşer.
- **Mimari değişmezler:** "Dapper kullanıyoruz, EF değil." "Single-tenant, CompanyId her sorguda." "SP'de THROW kodu 50000-59999." Yeni kod bunlara uymazsa hata.
- **Tekrarlayan hatalar:** Aynı bug ikinci kez çıktıysa, çözümü bir **checklist skill**'ine yaz. Üçüncü kez çıkmaz.
- **Maliyetli işler:** Build/test/schema kontrolü — ucuz bir agent'a (haiku) yaptır, ana bağlamı şişirme.

**Tek cümle:** Proje-özel skill/agent = *kurumsal hafıza*. Bir kez yaz, ekipteki herkes (ve gelecekteki sen) aynı standartla çalışsın.

---

## 2. Hangisini Yapmalı?

| Durum | Çözüm | Neden |
|---|---|---|
| Kod yazarken uyulacak **standart / reçete** | **Skill** | Doğal dille de tetiklenir, çok adımlı rehber tutar |
| **İzole, ağır analiz** (ana bağlamı kirletmeden) | **Agent** | Kendi context'inde çalışır, sonucu özet döner |
| Sık başlattığın **sabit akış** (`/x`) | **Komut** | Tek tetik, parametre alır |
| Her oturumda **pasif** geçerli davranış | **Kural** (`.claude/rules/`) | Tetik yok, sürekli yüklü |
| **Tekrarlayan tek mesaj** | (skill'e gerek yok) | CLAUDE.md'ye bir satır |

Karar testi:
- "Claude'un kendi başına, doğru anda çağırmasını ister miyim?" → **Agent** (proaktif description).
- "Ben açıkça `/x` veya doğal dille çağırırım." → **Skill** veya **Komut**.
- "Hiç çağrılmasın, hep arka planda geçerli olsun." → **Kural**.

---

## 3. Anatomi — Frontmatter Sözleşmesi

Bir skill/agent dosyasının frontmatter'ı **en kritik kısımdır** — Claude'un onu *ne zaman* çağıracağını buradan anlar.

```markdown
---
name: domain-auditor                    # kebab-case, klasör adıyla aynı
description: >                           # ← ROUTER. Tetik ifadelerini buraya göm.
  <Ne yapar> + <ne zaman tetiklenir: tam ifadeler> + <ne ZAMAN tetiklenmez>
  + <tamamlayıcı/karşıt skill referansı>.
allowed-tools: Read, Grep, Glob          # skill için (Edit/Write/Bash yetkisini KISITLA)
tools: Bash, Read, Grep                  # agent için
user-invocable: true                     # /<name> ile çağrılabilir mi
model: inherit | haiku | sonnet | opus   # iş ağırlığına göre (bkz. §6)
---

# <Başlık> Skill/Agent

## Amaç
<tek paragraf>

## Ne zaman çağrılır / çağrılmaz
## Adım adım / Checklist
## Kurallar / Kısıtlar
## Çıktı formatı
## İlişkili dosyalar
```

**Altın kural — description = tetik sözleşmesi.** Zengin yaz:

> `description: ... "iade faturası", "fatura iptal", "VUK", "e-fatura senaryo" denildiğinde veya M03/e-Belge modülü yazarken çağrılır. SALT-REHBER — kod yazmadan önce doğrulanacak noktaları verir.`

Buradaki tırnak içi ifadeler = router anahtar kelimeleri. Ne kadar gerçekçi ifade koyarsan, Claude o kadar isabetli tetikler.

---

## 4. Skill Örnekleri (generic)

Aşağıdakiler gerçek projelerden damıtılmış **pattern**'ler — kendi domain'ine uyarla.

### 4.1 Domain Denetçi (gap + dead-code analizi)

```markdown
---
name: domain-auditor
description: <Domain> uzmanı denetçi. Tüm modülleri endüstri-standart özellik
  checklist'iyle karşılaştırır; EKSİK (gap) ve FAZLA (dead code, kullanılmayan
  tablo/fonksiyon, over-engineering) çıkarır. "gap analizi", "eksik tara",
  "modülleri denetle", "fazla/eksik çıkar" denildiğinde tetiklenir.
allowed-tools: Read, Grep, Glob, Bash, Agent
user-invocable: true
---
```
**Önem:** Domain'in olgunlaşmış endüstri standardını LLM kısmen bilir; checklist'i skill'e gömünce her denetim aynı kapsamda olur. Hem eksiği hem **fazlayı** (gereksiz kod) bulması kritik — sadece "ekle" değil "sil" de der.

### 4.2 Mevzuat / Regülasyon Rehberi (SALT-REHBER)

```markdown
---
name: compliance-advisor
description: <Sektör> regülasyon doğrulama rehberi. Kod yazmadan ÖNCE
  doğrulanacak noktaları + resmi kaynakları verir. "<regülasyon adı>",
  "<senaryo>" denildiğinde veya ilgili modül yazarken çağrılır.
  SALT-REHBER — mevzuatı dayatmaz, doğrulama noktası + kaynak listeler.
allowed-tools: Read, Grep, Glob
---
```
**Önem:** En tehlikeli alan halüsinasyon. Skill kararı **vermez**, "şu noktayı şu kaynaktan doğrula" der. `SALT-REHBER` etiketi = yazmaya yetkisi yok, sadece yönlendirir.

### 4.3 Idempotent Migration Yazıcı

```markdown
---
name: migration-writer
description: Idempotent SQL/schema migration yazar. CREATE IF NOT EXISTS /
  CREATE OR ALTER pattern. Yedek almadan silme YASAK kuralını uygular.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---
```
**Önem:** Migration iki kez çalışınca patlamamalı. "Silme yasak / önce yedek" gibi geri-alınamaz işlem kuralını skill garanti eder.

### 4.4 Ekran / UX Standardı (iki tamamlayıcı skill)

İki ayrı skill, biri **etkileşim/akış**, diğeri **kanıtlı tasarım**:

```markdown
name: screen-ux-standard
description: Ekranları kullanıcı-dostu yapma standardı — form akışı, otomatik
  doldurma, klavye, boş durum, hata geri bildirimi. "ekran gözden geçir",
  "ux", "kullanıcı dostu yap" denildiğinde. ux-design-patterns ile tamamlayıcı.
---
name: ux-design-patterns
description: KANITLI UX pattern'leriyle tasarla (NNGroup, Baymard, Fiori).
  Data grid, combobox/typeahead, inline validasyon. screen-ux-standard
  (etkileşim) ile tamamlayıcı; bu skill = kanıtlı tasarım kuralları.
```
**Önem:** İki skill birbirine atıfta bulunur → Claude ikisini birlikte kullanır. Sorumluluğu bölmek tek dev fil-skill'den iyi.

### 4.5 Yazım-Anı Kalite Checklist'i

```markdown
---
name: code-quality-checklist
description: Kod yazarken/düzenlerken otomatik danış. Yaygın hataları yazım
  sırasında önle (handoff taraması SON doğrulama olsun). "checklist",
  "kontrol", "kalite kontrol" ile çağrılır.
allowed-tools: Read, Grep, Glob
---
```
**Önem:** Hatayı commit sonrası yakalamak yerine **yazarken** önle. Proje-özgü 10-15 maddelik somut liste (template'in generic kuralından daha keskin).

### 4.6 Harici Entegrasyon Standardı

```markdown
---
name: <vendor>-integration
description: <Servis/SDK> çağırma standardı. Doğru config, hata yönetimi,
  soft-fail, timeout, sık-yapılan-hata giderme. "<servis> çağır" denildiğinde
  veya <namespace/import> içeren kod yazarken danış.
allowed-tools: Read, Grep, Glob, Edit, Bash
---
```
**Önem:** Bir 3rd-party API'nin doğru kullanımı (retry, rate-limit, "0 sonuç" sorun giderme) tek yerde. Yeni dev SDK'yı yanlış kullanmaz.

### 4.7 Rakip / Pazar Analizi

```markdown
---
name: competitor-analyst
description: Feature tasarlanırken rakiplerle karşılaştırıp parite +
  farklılaşma + eksik tespit eder. Proje notlarını (analiz md/xlsx) tarar.
  "rakip incele", "parite analizi", "X nasıl yapıyor" denildiğinde veya
  yeni modül planı öncesi tetiklenir.
allowed-tools: Read, Grep, Glob, Bash, Agent
---
```
**Önem:** Ürün kararlarını "biz ne sunuyoruz, rakip ne sunuyor" zeminine oturtur. Kaynak dosyaları (analiz dökümanları) okur — uydurmaz.

---

## 5. Agent Örnekleri (generic)

Agent = izole bağlamda çalışan, sonucu özet dönen subagent. **Maliyet bilinçli model seçimi** burada kritik.

### 5.1 Ucuz Kapı Bekçileri (haiku, salt-okuma)

| Agent | Model | Ne yapar |
|---|---|---|
| `build-validator` | **haiku** | Projeyi derler, hata/uyarı sayısını dosya:satır ile raporlar. Kod yazmaz. |
| `test-runner` | **haiku** | Testleri çalıştırır, geçen/başarısız/atlanan + başarısız metod raporlar. Test eksikse uyarır. |
| `db-schema-checker` | **haiku** | Şema dosyaları ↔ canlı DB farkını bulur (eksik tablo, çalışmamış seed). Salt-okuma. |

```markdown
---
name: build-validator
description: Projeyi derler, hata ve uyarı sayısını dosya/satır/kod ile raporlar.
  Sprint/görev sonunda veya "build al", "derlemeyi kontrol et" denildiğinde
  proaktif çağır. Salt derleme — kod yazmaz.
tools: Bash, Read, Grep, Glob
model: haiku
---
```
**Önem:** Mekanik, akıl-yürütme gerektirmeyen iş → en ucuz model. Ana döngünün context'ini şişirmeden "yeşil mi?" cevabını verir. Her görev sonunda bedavaya çalışır.

### 5.2 İş-Doğruluğu Denetçisi (opus, salt-okuma)

```markdown
---
name: sql-sp-reviewer
description: SQL katmanını DOĞRULUK açısından denetler. Transaction atomikliği,
  hata kod aralığı, ledger tutarlılığı (üç tablo eşzamanlı), immutability/reversal
  (silme yerine ters kayıt), tenant predikatı, çift-post koruması. SP/şema
  yazıldıktan sonra proaktif çağır. security-reviewer SQL injection bakar;
  bu agent SQL'in İŞ DOĞRULUĞUNA bakar. Salt-okuma.
tools: Read, Grep, Glob, Bash
model: opus
---
```
**Önem:** İki nokta. (1) **Sorumluluk ayrımı** — security-reviewer ≠ bu agent; description'da net belirtilmiş, çakışmazlar. (2) Para/ledger gibi **sessiz bozulma = felaket** alanda en güçlü model (opus). Yanlış pozitif maliyeti, kaçırma maliyetinden ucuz.

### 5.3 Çeviri / Port Agent'ı (opus, paralel fan-out)

```markdown
---
name: pgsql-porter
description: T-SQL nesnelerini PostgreSQL'e port eder — mantığı KORUYARAK
  sözdizimi çevirir; semantik kayma riskini (NULL, implicit cast, transaction,
  para yuvarlama) işaretler. Yanlış port = sessiz veri bozulması → yüksek-titizlik.
  SALT-OKUMA: ported SQL'i metin döndürür, ana döngü yazar + test eder.
  Birden çok nesne varsa paralel fan-out.
tools: Read, Grep, Glob
model: opus
---
```
**Önem:** (1) Agent **yazmaz**, metin döndürür — ana döngü uygular + test eder (güvenli sınır). (2) `paralel fan-out` = 10 SP varsa 10 agent eşzamanlı → duvar-saati 10× düşer.

### 5.4 Dış Kaynak Araştırmacısı (opus)

```markdown
---
name: reference-researcher
description: Dış açık-kaynak proje + resmi doküman üzerinden DERİN domain/mimari
  araştırması. Kaynakları gerçeğinden okuyup (clone/WebFetch) uyarlanabilir
  pattern çıkarır. "X nasıl çözmüş", "referans incele" gibi araştırma turlarında.
  Stack KOPYALAMAZ — sadece domain/model dersi alır. Üretim kodu DEĞİŞTİRMEZ.
tools: Read, Grep, Glob, Bash, WebFetch, WebSearch
model: opus
---
```
**Önem:** "Olgun projeler bu problemi nasıl çözmüş?" sorusunu gerçek kaynaktan cevaplar (eğitim verisinden uydurmaz). `Stack KOPYALAMAZ` kısıtı → körü körüne taklit etmez, ders alır.

---

## 6. Tasarım İlkeleri (mutlaka uygula)

Bunlar gözlemlenen en değerli pattern'ler — **kullanmıyorsan eksiksin**:

1. **Model katmanlama (maliyet ↔ risk).**
   - `haiku` → mekanik, salt-okuma (build, test, schema diff, format).
   - `sonnet`/`inherit` → standart kod yazma/review.
   - `opus` → sessiz-bozulma riski yüksek akıl yürütme (ledger, port, mimari karar).
   *Her şeyi opus yapmak = para yakmak. Her şeyi haiku = kaçırılan bug.*

2. **Salt-okuma vs yazma ayrımı.** Analiz/denetim agent'ı `tools`'tan `Edit`/`Write`'ı **çıkar**. "Raporla, çözme." Karar + uygulama ana döngüde kalır → kontrol sende.

3. **`SALT-REHBER` / `SALT-OKUMA` etiketi.** Mevzuat/denetim skill'leri karar dayatmaz, doğrulama noktası + kaynak verir. Halüsinasyonu kararı insana bırakarak söndürür.

4. **Sorumluluk ayrımı + çapraz atıf.** Çakışabilecek iki agent/skill description'da birbirine atıf yapsın ("X şuna bakar, ben buna"). Hem çakışma önlenir hem birlikte tetiklenirler.

5. **Tamamlayıcı skill çifti.** Büyük bir konuyu (örn. UX) "etkileşim" + "kanıtlı tasarım" diye ikiye böl. Tek dev skill'den okunabilir + isabetli.

6. **Proaktif description.** Agent'ın kendi tetiklenmesini istiyorsan description'a "...yazıldıktan sonra **proaktif çağır**" yaz + gerçek tetik ifadeleri göm.

7. **Paralel fan-out.** Çok-bağımsız-birim işlerde (N dosya port, N modül denetim) "birden çok varsa paralel" de → eşzamanlı agent'lar.

8. **Geri-alınamaz işlem kuralını skill'e göm.** "Silme yasak, ters kayıt", "önce yedek", "idempotent" — skill garantici olsun, insan hafızasına bırakma.

9. **"Neden"i yaz.** Kuralın gerekçesini ekle ("yanlış port = sessiz veri bozulması"). Claude gerekçeyi görünce titizlik seviyesini ayarlar.

---

## 7. Eklemediysen Eksiksin

Çoğu projede olması gereken ama sık atlanan skill/agent'lar:

| Öneri | Tip | Ne yapar / Neden |
|---|---|---|
| **domain-glossary** | Skill/Kural | Projenin terim sözlüğü (kısaltma, modül kodu, durum makinesi). Yeni dev + LLM aynı dili konuşur. |
| **release-checklist** | Skill | Sürüm öncesi: migration sırası, env var, geri-alma planı, smoke senaryosu. Unutulan adım = prod kazası. |
| **data-migration-safety** | Skill/Agent | Veri taşıyan migration öncesi: satır sayısı doğrulama, dry-run, rollback scripti. Geri-alınamaz → en yüksek risk. |
| **api-contract-guard** | Agent (ro) | Public endpoint/response şeması değişti mi? Breaking change uyarısı. Client'ları kırmamak için. |
| **perf-budget** | Agent (ro) | Sorgu/sayfa/bundle eşiği aşıldı mı? N+1, eksik index, ağır import. |
| **dependency-audit** | Agent (haiku) | Yeni paket: lisans, boyut, bakım durumu, CVE. Supply-chain hijyeni. |
| **error-taxonomy** | Skill | Hata kodu/aralık standardı + log seviyesi. Tutarlı hata yönetimi. |
| **seed-data-guard** | Agent | Zorunlu seed/lookup verisi eksik mi (ülke, KDV oranı, rol)? Boş ortamda app patlamasın. |
| **commit-message-domain** | Skill | Projeye özel commit scope/tip sözlüğü. (commit-discipline'ı genişletir.) |

Hepsini birden yapma — **acıyı çektiğin yerden** başla. İkinci kez aynı hata/soru → o an bir skill doğmalı.

---

## 8. Oluştur · Kaydet · Test Et

### Skill oluştur
```bash
mkdir -p .claude/skills/<ad>
# .claude/skills/<ad>/SKILL.md yaz (frontmatter + gövde — §3)
```

### Agent oluştur
```bash
# .claude/agents/<ad>.md yaz (frontmatter: name, description, tools, model)
```

### Komut oluştur
```bash
# .claude/commands/<ad>.md yaz (frontmatter: description; gövde = akış)
```

### Tetik testi
- Skill/Komut: yeni oturumda `/<ad>` görünüyor mu? Description'daki ifadeyi doğal dille söyle, tetikleniyor mu?
- Agent: description'daki senaryoyu yaz, Claude kendi çağırıyor mu? Çağırmıyorsa description'a daha somut tetik ifadesi ekle.
- `model: haiku` agent'ı: gerçekten ucuz işi mi yapıyor, yoksa akıl yürütme mi gerekti (o zaman sonnet/opus)?

### Sürdür
- Skill yanlış tetikleniyor → description'ı daralt/genişlet.
- Aynı düzeltmeyi 2. kez yaptın → skill'e madde ekle.
- Skill domain'i kaydı → ilgili `.claude/rules/` veya CLAUDE.md link indeksinden referans ver.

---

### İlişkili Dökümanlar
- [`PROJE_OZEL_KAVRAM.md`](PROJE_OZEL_KAVRAM.md) — *neden/niçin* var, ne zaman doğar (kavramsal temel).
- [`GELISTIRICI_REHBERI.md`](GELISTIRICI_REHBERI.md) — mevcut skill/agent/komut kataloğu.
- [`USAGE.md`](USAGE.md) — bootstrap kurulum.
- [`../templates/docs/CONTEXT_MANAGEMENT.md`](../templates/docs/CONTEXT_MANAGEMENT.md) — bağlam yönetimi anayasası.
