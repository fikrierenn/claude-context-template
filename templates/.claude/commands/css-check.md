---
description: CSS/Tailwind tasarım tutarlılığı ve kalite denetimi
argument-hint: "Opsiyonel: belirli component, sayfa veya klasör"
---

# /css-check

Unstaged değişikliklerdeki (`git diff`) CSS ve Tailwind kullanımını denetle.
$ARGUMENTS verilmişse sadece o kapsama bak.

## 1. Tailwind Tutarlılığı
- Proje renk paleti dışında hardcoded değer var mı? (`text-[#ff0000]`, `bg-[#1a2b3c]` vb.)
- `tailwind.config` token'ları yerine arbitrary value kullanılmış mı? (`p-[13px]` → `p-3` olmalı mı?)
- Aynı class kombinasyonu farklı yerlerde tekrar ediyor mu? (component çıkarmak gerekiyor mu?)

## 2. Responsive Tasarım
- Mobile-first yazılmış mı? (`md:`, `lg:` prefix'leri doğru sırada mı?)
- Breakpoint atlama var mı? (mobil ve masaüstü var ama tablet yok?)
- Overflow/scroll sorunu yaratabilecek fixed genişlik var mı? (`w-[400px]`)

## 3. Dark Mode
- `dark:` prefix'i gereken yerlerde var mı?
- Hardcoded beyaz/siyah renk dark mode'u bozuyor mu?

## 4. Erişilebilirlik (a11y)
- Etkileşimli element `focus:` state var mı?
- Kontrast sorunu yaratacak renk kombinasyonu var mı?
- `sr-only` gereken görsel-only element var mı?

## 5. Gereksiz Karmaşıklık
- `!important` kullanımı var mı? (neden gerekti?)
- Aşırı specificity sorunu (`class` zinciri çok uzun mu?)
- Inline `style=` kullanımı? (Tailwind class tercih edilmeli)

## Çıktı Formatı

```
CRITICAL:
  - [dosya:satır/component] açıklama + öneri

TUTARSIZLIK:
  - [dosya] açıklama + öneri

İYİLEŞTİRME ÖNERİSİ:
  - açıklama

PASSED: [geçen kontroller]
```
