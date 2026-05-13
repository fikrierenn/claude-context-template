---
description: Mevcut unstaged değişiklikleri kod kalitesi açısından incele
argument-hint: "Opsiyonel: belirli dosya veya konu (örn: 'src/api/' veya 'auth değişiklikleri')"
---

# /code-check

Unstaged değişiklikleri (`git diff`) al ve şunları kontrol et:

## 1. CLAUDE.md Kural Uyumu
- Projenin kırılmaz kurallarına uyuluyor mu?
- Yasaklanan pattern'ler kullanılmış mı? (`any` tip, `console.log`, inline SQL vb.)

## 2. Tip Güvenliği
- TypeScript: `any` kullanımı var mı?
- Null/undefined guard eksik mi?
- Return tipleri belirtilmiş mi?

## 3. Hata Yönetimi
- try/catch eksik endpoint var mı?
- Sessiz hata yutan boş catch blokları?
- Hata mesajı kullanıcıya sızıyor mu?

## 4. Güvenlik
- Hardcoded şifre, token, API key var mı?
- Input validasyonu yapılıyor mu?
- Auth kontrolü eksik endpoint var mı?

## 5. Temizlik
- Temp dosya cleanup (`finally` bloğu) var mı?
- Kullanılmayan import'lar?
- Dead code?

## Çıktı Formatı

```
CRITICAL (hemen fix):
  - [dosya:satır] açıklama

IMPORTANT (bu oturumda fix):
  - [dosya:satır] açıklama

LOW (backlog):
  - [dosya:satır] açıklama

PASSED: [geçen kontroller özet]
```

$ARGUMENTS varsa sadece o kapsama odaklan.
