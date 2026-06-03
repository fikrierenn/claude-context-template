---
name: presentation-builder
description: Yüksek-kaliteli, etkileyici sunum/slayt destesi üretir (HTML→PDF, isteğe bağlı PPTX). Generic AI-slop slayttan kaçınır; tasarım sistemi (palet, tipografi, motif, ızgara) uygular. "sunum hazırla", "slayt yap", "deck oluştur", "eğitim sunumu", "presentation" denildiğinde tetiklenir. 16:9, kapak + bölüm ayraçları + içerik + kapanış (sandwich), her sayfada imza/footer. Çıktı: docs/<konu>/ altında .html + .pdf (+ istenirse .pptx).
allowed-tools: Read, Write, Edit, Bash, Glob
user-invocable: true
model: inherit
---

# presentation-builder Skill

## Amaç
"Boring slayt" üretme. Tasarım sistemine bağlı, sunumda gösterilebilir, etkileyici deck üret. Varsayılan motor: **HTML + CSS → Chromium (playwright) → PDF** (en yüksek görsel kontrol). İstenirse pptxgenjs ile editable PPTX.

## Ne zaman
- Eğitim, tanıtım, mimari anlatım, pitch, retro sunumu.
- Kullanıcı "sunum/slayt/deck/presentation" dediğinde.

## Süreç (6 adım)

### 1. Brief çıkar (kısa)
Sor (yoksa makul varsay): konu, hedef kitle (acemi/teknik/yönetici), slayt sayısı (~10-18), ton (kurumsal/enerjik), dil, imza/marka, çıktı (PDF / PDF+PPTX).

### 2. Anlatı yayını kur (story arc)
Slayt sırası rastgele değil. İskelet:
1. **Kapak** (koyu, büyük başlık + alt başlık)
2. **Gündem / harita** (ne anlatılacak)
3. **Bağlam / problem** (neden önemli)
4. **Bölüm ayraçları** (koyu, dev numara — ritim verir)
5. **İçerik slaytları** (her biri TEK fikir)
6. **Kanıt / önce-sonra / stat** (somut)
7. **Özet tablo / harita**
8. **Kapanış** (koyu, tek güçlü cümle + çağrı)

### 3. Tasarım sistemi seç (ZORUNLU — tutarlılık)

**Palet:** konuya özel, generic mavi'ye kaçma. Tek renk %60-70 baskın + 1-2 destek + 1 keskin vurgu. Koyu kapak/ayraç/kapanış, açık içerik (sandwich).

| Tema | Baskın | Destek | Vurgu |
|---|---|---|---|
| Midnight Executive | `#1E2761` | `#CADCFC` | `#FFFFFF` |
| Ocean Depth | `#065A82` | `#1C7293` | `#02C39A` |
| Forest | `#2C5F2D` | `#97BC62` | `#F5F5F5` |
| Cherry Bold | `#990011` | `#FCF6F5` | `#2F3C7E` |

**Tipografi:** karakterli başlık + temiz gövde. Başlık 32-44pt bold, bölüm 20-24pt, gövde 13-15pt, alt 9-11pt mute.

**Motif (tek, her slaytta tekrarla):** renkli daire içinde ikon / numara rozeti / yumuşak gölgeli yuvarlak kart / kalın tek-kenar vurgu. Birini seç, sonuna kadar taşı.

**İkonlar — emoji DEĞİL, profesyonel set.** Açık-kaynak SVG kütüphanesi kullan (telif-temiz): Lucide (`npm i lucide-static`, MIT) veya Tabler. SVG'yi inline göm, `stroke="currentColor"` ile renklendir, renkli daire içine koy. Emoji son çare.
```js
const fs=require("fs");
function ic(name,size=22){let s=fs.readFileSync(`node_modules/lucide-static/icons/${name}.svg`,"utf8");
  return s.replace(/width="24"/,`width="${size}"`).replace(/height="24"/,`height="${size}"`);}
```

**İnfografik kullan (sadece kart+metin değil):** donut/halka (yüzde stat — SVG `stroke-dasharray`), yatay/dikey bar (karşılaştırma), katmanlı 3D stack (mimari — kademeli offset + gölge), akış/timeline (ok'lu node'lar), büyük stat rakamı. Her bölümde en az bir gerçek görsel öğe.

### 4. HTML/CSS üret
- `@page { size: 297mm 167mm; margin:0 }` (16:9). Her slayt `.slide` (tam sayfa, `page-break-after`).
- Kapak/ayraç/kapanış: degrade koyu zemin. İçerik: beyaz/açık.
- Kart = `border-radius` + yumuşak `box-shadow` + ince renkli kenar.
- Her slaytta footer imza + sayfa no.
- **Görsel öğesiz slayt YASAK** — ikon, diyagram (inline SVG), stat callout, kart ızgarası, önce/sonra.

### 5. Render (PDF)
```bash
python - <<'PY'
from playwright.sync_api import sync_playwright
import pathlib
uri=pathlib.Path("DECK.html").resolve().as_uri()
with sync_playwright() as p:
    b=p.chromium.launch(); pg=b.new_page()
    pg.goto(uri,wait_until="networkidle")
    pg.pdf(path="DECK.pdf",prefer_css_page_size=True,print_background=True)
    b.close()
PY
```
PPTX istenirse: pptxgenjs (native şekil/metin/tablo) — editable.

### 6. QA (ZORUNLU — taze göz)
Slaytları görsele çevir, **bir subagent'a** denetlet (sen kodu yazdın, beklediğini görürsün):
```bash
python - <<'PY'
from playwright.sync_api import sync_playwright; import pathlib
with sync_playwright() as p:
    b=p.chromium.launch(); pg=b.new_page({} if False else None)
    pg=b.new_page(viewport={"width":1280,"height":720})
    pg.goto(pathlib.Path("DECK.html").resolve().as_uri(),wait_until="networkidle")
    pg.screenshot(path="_qa.png",full_page=True); b.close()
PY
```
Ara: taşma/kesik metin, çakışma, kenar boşluğu < 0.5", düşük kontrast, hizalama, boş placeholder. Bir tur düzelt-doğrula, sonra dur. Sub-pixel takıntısı yok.

## Tasarım Kuralları (AI-slop'tan kaçın)

- ❌ Başlık altına dekoratif çizgi (AI imzası).
- ❌ Full-width renkli header/footer bar, yan şerit (talep edilmedikçe).
- ❌ Krem/bej varsayılan zemin → beyaz veya marka paleti.
- ❌ Sadece-metin slayt → her slayda görsel.
- ❌ Tüm renkler eşit ağırlık → biri baskın olsun.
- ❌ Aynı düzeni 16 kez → kart/sütun/stat/ayraç ile ritim değiştir.
- ❌ Gövde metni ortalama → sola hizala (sadece başlık ortalanır).
- ✅ Bölüm ayraç slaytları (dev numara) ritim verir.
- ✅ Stat callout (60-72pt rakam) ve tek-cümle quote slaytları nefes açar.

## Çıktı Konumu
`docs/<konu-slug>/` altında: `<konu>.html` (kaynak), `<konu>.pdf` (sunum). İmza/marka her sayfada.

## İlişkili
- HTML→PDF: playwright (chromium). PPTX: pptxgenjs.
- Anti-slop ilkeleri: pptx skill tasarım notları ile uyumlu.
