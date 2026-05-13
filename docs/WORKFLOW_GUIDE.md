# Claude Code ile Akıllı Geliştirme — Kavramsal Rehber

_Projeye yeni katılan geliştiriciler ve bu sistemi kendi ekiplerine kurmak isteyenler için._  
_Teknik kurulum için bkz. [`USAGE.md`](USAGE.md) | Gerçek sorunlar için bkz. [`PATTERNS.md`](PATTERNS.md)_

---

## Problem: Claude Neden Unutuyor?

Claude Code güçlü bir araç — ama kutudan çıktığı haliyle **her sohbet sıfırdan başlar**. Dün aldığınız kararı, geçen hafta belirlediğiniz mimari kuralı, iki ay önce yazdığınız "şifre alanı için bu kütüphaneyi kullan" notunu bilmez.

Tipik belirtiler:

| Şikayet | Gerçek sebep |
|---------|-------------|
| "Dün konuştuğumuz kararı hatırlamıyor" | Karar CLAUDE.md'de değil, sohbet geçmişinde kaldı — `/compact` yedi |
| "Aynı hatayı üçüncü kez yapıyor" | Düzeltme hafızaya yazılmadı |
| "Uncommitted dosyalar birikiyor" | Oturum sonu commit disiplini yok |
| "Sub-agent kural bilmiyor" | Agent context'in dışında başlıyor |
| "CLAUDE.md her gün şişiyor" | Session notları yanlış yere yazılıyor |

Bu sistemin amacı bu sorunları **yapısal olarak** çözmek — her sohbette "bunları hatırla" demek zorunda kalmamak.

---

## Sistemin Anatomisi

Üç katman var. Aynı bilgi **tam olarak bir yerde** yaşar:

```
┌─────────────────────────────────────────┐
│  CLAUDE.md  — Kim bu proje?             │  ← Her oturumda okunur
│  (proje kimliği, kurallar, stack)       │
├─────────────────────────────────────────┤
│  .claude/rules/  — Nasıl çalışırız?     │  ← Konu bazlı kurallar
│  (güvenlik, commit, mimari, vb.)        │
├─────────────────────────────────────────┤
│  TODO.md + docs/journal/ + docs/ADR/    │  ← Ne yapıldı, ne kararlaştırıldı
│  (planlar, geçmiş kararlar, notlar)     │
└─────────────────────────────────────────┘
```

---

## Her Parça Ne İşe Yarar

### CLAUDE.md — Projenin Kimlik Kartı

Her sohbetin başında Claude'un okuduğu tek dosya. **200 satır altında tutulur.** İçerik:

- Bu proje ne, ne için var
- Hangi teknolojiler kullanılıyor
- Kırılmaz kurallar (şifreler nerede, hangi mimari zorunlu)
- Dizin yapısı kısa özeti
- Şu an kırık olan şeyler (teknik borçlar)

**Neyi içermez:** Oturum notları, günlük değişiklikler, geçmiş kararların detayı. Bunlar `docs/journal/` ve `docs/ADR/` içinde yaşar.

---

### .claude/rules/ — Davranış Kuralları

Her dosya bir konu, her konu ayrı dosya. Claude her konuyla ilgili iş yaparken bu dosyayı okur.

**Örnek dosyalar:**

| Dosya | İçerik |
|-------|--------|
| `session-protocol.md` | Oturum başı/sonu ritüeli |
| `commit-discipline.md` | Git commit formatı, 15 dosya eşiği |
| `security-principles.md` | Şifre yönetimi, input validasyonu |
| `architecture.md` | Katman ayrımı, modül yapısı |
| `plan-first.md` | Küçük iş vs büyük plan kararı |

---

### .claude/skills/ — Uzmanlık Alanları

Skill, domain bilgisini taşıyan özel bir dosyadır. Kullanıcının sorusuyla eşleşen skill(ler) otomatik olarak sistem prompt'a eklenir — Claude o konuda uzman gibi yanıt verir.

Her skill `SKILL.md` dosyasından oluşur:

```yaml
---
name: kargo-takip-uzmani
description: Kargo süreç analizi ve optimizasyon
triggers:
  - "kargo"
  - "teslimat"
  - "gönderi"
  - "takip"
---
# Kargo Takip Uzmanlık İçeriği
...
```

Kullanıcı "bu siparişin kargo durumu neden güncellenmedi?" dediğinde → trigger eşleşmesi → `kargo-takip-uzmani` skill'i devreye girer.

---

### .claude/agents/ — Özel Tarama Görevlileri

Agent, belirli bir görevi yapmak üzere spawn edilen bağımsız bir Claude örneğidir. Ana sohbeti meşgul etmez, paralel çalışabilir.

**Örnek kullanım:** Yeni bir API endpoint yazdınız. Agent otomatik olarak şunları kontrol eder:
- Yetkilendirme kontrolü var mı?
- Şifreler loglara yazılıyor mu?
- Input validasyonu yapılıyor mu?

---

### .claude/hooks/ — Otomatik Tetikleyiciler

Hook, belirli bir olay gerçekleştiğinde otomatik çalışan betiktir:

- **SessionStart:** Claude açıldığında — son commit'ler, uncommitted sayısı, aktif TODO görünür
- **PreToolUse:** `git commit` öncesi — hardcoded şifre, `console.log`, `any` tip vb. tarar
- **PostToolUse:** Başarılı commit sonrası — `docs/journal/` dosyasına otomatik satır ekler

---

### Memory Sistemi — Oturumlar Arası Hafıza

`C:\Users\[kullanıcı]\.claude\projects\[proje]\memory\` adresinde dosya tabanlı çalışır.

**MEMORY.md** her memory dosyasına pointer içerir. Memory türleri:

| Tür | Ne zaman | Örnek |
|-----|---------|-------|
| `user` | Geliştirici hakkında bir şey öğrenilince | "Kargo modülünü biliyor, ödeme kısmı yeni" |
| `feedback` | Bir yaklaşım düzeltildi | "Mock veri kullanma, gerçek servis çağır" |
| `project` | Önemli karar alındı | "Stok servisi monolitten ayrıldı, ayrı deploy" |
| `reference` | Dış sisteme pointer | "Kargo hataları Linear'da CARGO projesinde" |

Memory olmadan Claude aynı hatayı oturum oturum tekrarlayabilir.

---

### docs/journal/ — Oturum Notları

`session-handoff` skill'i tetiklendiğinde (genellikle gün sonu "iyi geceler" veya "handoff" yazınca) oluşturulur:

```markdown
# 2026-05-15 — Sipariş durumu güncelleme akışı

## Tamamlananlar
- OrderStatusService.cs tamamlandı
- Kargo entegrasyon webhook eklendi

## Yarım Kalanlar
- Bildirim e-postası template'i → Templates/OrderStatus.cshtml

## Yarına Başlangıç
1. E-posta template'ini bitir
2. Test ortamında webhook tetikle
```

Bu dosya git'e commit edilir. Geçmiş korunur.

---

### plans/ — Büyük İş Planları

3+ dosyaya dokunan her iş planlanır, onay alınır, sonra uygulanır.

---

## Tier Sistemi — Ne Zaman Plan Yazılır?

| Tier | Kural | Örnek |
|------|-------|-------|
| **1 — Trivial** | 1-2 dosya, küçük değişiklik → direkt yap | Hata mesajı düzelt |
| **2 — Standard** | 5 dosyaya kadar, bilinen pattern → TODO ekle, yap | Yeni form alanı ekle |
| **3 — Substantial** | 3+ klasör, yeni pattern, şema değişikliği → plan yaz | Ödeme entegrasyonu ekle |

**Tier 3 sinyalleri (birisi varsa → plan zorunlu):**
- Yeni veritabanı tablosu veya şema değişikliği
- Yeni dış servis entegrasyonu
- Auth veya güvenlik katmanına dokunma
- Kullanıcı arayüzünde büyük değişiklik
- Yeni npm/NuGet paketi

---

## Günlük Akış

### Sabah Açılışı

```
Claude Code açılır → session-start.sh hook otomatik çalışır
```

Ekrana gelir:
```
📌 SON 5 COMMIT:
  abc1234 feat(order): sipariş durumu güncelleme
  def5678 fix(cargo): webhook null kontrol

📝 UNCOMMITTED: 3 dosya

📓 SON JOURNAL (2026-05-14):
  [...]Yarına Başlangıç: E-posta template'ini bitir[...]

📋 AKTİF TODO:
  1. [F-01] E-posta bildirimleri — OrderStatus template
  2. [G-01] Auth middleware — admin paneli korumasız
```

Sen sadece "günaydın, nereden kalmıştık?" yazarsın.

---

### Gün İçi

**Küçük iş (Tier 1-2):**
```
Sen:    "Kargo takip sayfasında 'Bilinmiyor' yazısını 'Bilgi Yok' yap"
Claude: Dosyayı bulur, değiştirir, commit atar
```

**Büyük iş (Tier 3):**
```
Sen:    "MNG Kargo'ya ek olarak Aras Kargo da entegre edelim"
Claude: "Bu Tier 3, önce plan yazayım"
        → plans/02-aras-kargo-entegrasyon.md
        → "Onaylıyor musunuz?"
Sen:    "Evet"
Claude: Uygulamaya başlar, her adımı commit eder
```

**Güvenlik kontrolü:**
```
Sen:    /security-check
Claude: api-auth-auditor + code-reviewer paralel → rapor
```

---

### Akşam Kapanışı

```
Sen:    "iyi geceler" veya "handoff"
Claude:
  1. Bu oturumda değiştirilen kod → güvenlik taraması
  2. docs/journal/2026-05-15.md yazar
  3. Journal'ı commit eder
  4. Memory günceller
  5. Özet gösterir
```

---

## Alan Bazlı Örnekler

### E-Ticaret Platformu

**CLAUDE.md'de ne olur:**
```
Platform: Çok satıcılı e-ticaret
Stack: .NET 8 MVC + SQL Server + Redis (sepet)

Kırılmaz kurallar:
- Ödeme verisi (kart no, CVV) hiçbir zaman loglara yazılmaz
- Stok düşme ve sipariş oluşturma aynı DB transaction'ında
- Kullanıcı verileri daima tenant_id ile filtrelenir

Teknik borçlar:
- Ürün arama hâlâ LIKE '%...%' — Elasticsearch planlandı
- Sepet servisi Redis kullanıyor ama TTL ayarlı değil
```

**Örnek skill'ler:**
- `siparis-akis-uzmani` — sipariş durumu geçişleri, iptal/iade kuralları
- `stok-yonetimi-uzmani` — rezervasyon, düşme, stok senkronu
- `odeme-entegrasyon-uzmani` — Iyzico/Stripe webhook akışı

**Örnek agent:**
```markdown
# tenant-isolation-auditor
Tüm Supabase/EF sorgularını tara:
- WHERE koşulunda tenant_id var mı?
- Kullanıcının başka tenant verisine erişebilir mi?
```

---

### Kargo & Lojistik Sistemi

**CLAUDE.md'de ne olur:**
```
Platform: Kargo takip ve dağıtım yönetimi
Stack: Node.js + TypeScript + PostgreSQL

Kırılmaz kurallar:
- Gönderi durumu değişikliği webhook + DB transaction atomik
- Adres bilgisi plaintext loglara yazılmaz (KVKK)
- Kargo firması API key'leri sadece server-side env var

Teknik borçlar:
- MNG webhook signature doğrulaması eksik
- Rota optimizasyonu manuel — OR-Tools entegrasyonu planlandı
```

**Örnek skill'ler:**
- `kargo-entegrasyon-uzmani` — MNG/Aras/Yurtiçi API farkları, webhook formatları
- `rota-optimizasyon-uzmani` — TSP algoritmaları, araç kapasitesi kısıtları
- `iade-surec-uzmani` — iade kargo etiketi, depo kabul süreci

**Örnek agents:**
```markdown
# webhook-audit
Tüm webhook endpoint'lerini tara:
- Signature doğrulaması var mı?
- Idempotency key kontrolü yapılıyor mu?
- Duplicate event handle ediliyor mu?
```

---

### Depo Yönetim Sistemi (WMS)

**CLAUDE.md'de ne olur:**
```
Platform: Barkod/QR destekli depo yönetimi
Stack: ASP.NET Core + EF Core + SQL Server

Kırılmaz kurallar:
- Stok hareketleri SADECE stored procedure üzerinden — direkt INSERT/UPDATE yok
- Barkod okuma işlemi iç içe transaction açmamalı (deadlock)
- Depo lokasyonları immutable — sil değil, pasif yap

Teknik borçlar:
- Sayım farkı raporu 30k satırda timeout — sayfalama eklenecek
- RF terminali için offline mod henüz yok
```

**Örnek skill'ler:**
- `sayim-surec-uzmani` — dönem sonu sayım, fark tutanağı, düzeltme hareketleri
- `barkod-sistem-uzmani` — GS1, EAN, QR format standartları
- `fifo-lifo-uzmani` — lot takibi, FEFO (expiry date first-out)

**Örnek agents:**
```markdown
# stored-proc-auditor
src/ altındaki tüm EF sorgularını tara:
- Stok hareketi yaratan kod SADECE SP çağırıyor mu?
- Raw SQL ile INSERT/UPDATE yapan var mı? (CRITICAL)
```

---

### CRM / Müşteri Yönetimi

**CLAUDE.md'de ne olur:**
```
Platform: B2B CRM — satış takibi ve teklif yönetimi
Stack: Next.js 16 + Supabase + TypeScript

Kırılmaz kurallar:
- Müşteri verisi RLS ile izole — başka firmanın müşterisine erişilemez
- Teklif PDF'i oluşturmadan önce fiyat onay akışı tamamlanmalı
- İletişim geçmişi hiçbir zaman silinemez (soft delete zorunlu)

Teknik borçlar:
- Teklif PDF boyutu 2MB'ı aşıyor — görsel optimizasyon gerekli
- Satış pipeline raporu N+1 sorgu içeriyor
```

---

## Sık Yapılan Hatalar

**❌ CLAUDE.md'ye oturum notu yazmak**
"Bu oturumda X yapıldı" cümleleri CLAUDE.md'ye girmez. Her oturum gelir geçer, CLAUDE.md sadece "bugün geçerli" kuralları içerir.  
✅ Oturum notları → `docs/journal/YYYY-MM-DD.md`

**❌ Tier 3 işi planlamadan başlamak**
"Şunu yap" deyince Claude hemen başlar ama ortada bırakılan yarım entegrasyon temizlemek zaman alır.  
✅ 3+ klasöre dokunan her işte önce plan, sonra onay.

**❌ Memory path'ini güncellemeden paylaşmak**
`session-protocol.md`'deki memory path makineye özgüdür. Farklı bilgisayarda veya farklı kullanıcıda çalışmaz.  
✅ Her kurulumda `session-protocol.md`'de `C:\Users\[kendi-kullanıcın]\...` güncelle.

**❌ Handoff yapmadan çıkmak**
Handoff olmadan journal yazılmaz, memory güncellenmez, yarım işler kaybolur.  
✅ Her gün kapanışta "iyi geceler" veya "handoff" yaz. 2 dakika.

**❌ 15 dosya kuralını görmezden gelmek**
Çok fazla uncommitted dosya birikince ne neyin commit'i belli olmaz.  
✅ 15 eşiği geçince dur, `commit-splitter` agent'ı çağır.

---

## Yeni Projeye Kurulum (Özet)

```powershell
# Windows
pwsh D:\Dev\claude-context-template\bin\bootstrap.ps1 `
  -ProjectPath "D:\Dev\yeni-proje" `
  -ProjectName "YeniProje" `
  -Stack nodejs-typescript   # veya dotnet-mvc / python-generic / none
```

```bash
# Mac/Linux/WSL
bash /d/Dev/claude-context-template/bin/bootstrap.sh \
  --path /d/Dev/yeni-proje \
  --name YeniProje \
  --stack nodejs-typescript
```

Ardından **4 şeyi proje özelinde doldur:**

1. `CLAUDE.md` — platform kimliği, kırılmaz kurallar, teknik borçlar
2. `.claude/rules/project/architecture.md` — projenin mimari yapısı
3. `.claude/rules/project/security-principles.md` — projeye özgü güvenlik kuralları
4. `session-protocol.md` — memory path'ini kendi kullanıcı adınla güncelle

Detay: [`USAGE.md §1`](USAGE.md#1-ilk-kurulum--yeni-proje)

---

## Özet

| Olmadan | Bununla |
|---------|---------|
| Her oturumda "bu projede şu kural var" tekrarı | CLAUDE.md bir kere yaz, hep geçerli |
| Aynı hatayı tekrar tekrar yapma | Memory ile kalıcı öğrenme |
| Gün sonu "ne yapmıştık?" | Journal otomatik yazılır, commit edilir |
| Büyük işler ortada kalır | Tier sistemi → plan → onay → uygula |
| Güvenlik açıkları fark edilmeden geçer | Agent'lar proaktif tarar |
| Takımdaki herkes farklı standart uygular | Rules dosyaları herkese aynı kuralı uygular |

---

_Bu rehber `docs/WORKFLOW_GUIDE.md` konumundadır. Daha fazla gerçek örnek için [`PATTERNS.md`](PATTERNS.md) · Teknik kurulum için [`USAGE.md`](USAGE.md)_
