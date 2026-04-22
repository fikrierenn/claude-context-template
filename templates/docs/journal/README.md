# Oturum Günlükleri

Bu klasörde her çalışma gününün notu: `YYYY-MM-DD.md`.

## Neden burada?

CLAUDE.md'nin şişmesini önlemek için. Session journal'ı CLAUDE.md'de yaşamaz (bağlam anayasası § İlke 3).

## Nasıl yazılır?

`/handoff` skill'i otomatik üretir, ya da manuel:

```markdown
# Oturum Günlüğü — YYYY-MM-DD

## Ana Konu
## Tamamlananlar
## Build / Test Durumu
## Commit Durumu
## Yarım Kalan
## Kararlar
## Yarına Başlangıç Noktası
```

## Nasıl okunur?

SessionStart hook, oturum başında en son dosyanın son 40 satırını Claude'a enjekte eder. Ayrıca `grep -r "karar" docs/journal/` ile geçmiş arama yapılabilir.

## Ne zaman archive?

3 ay sonra `docs/journal/archive/YYYY-QN/` altına taşı. SessionStart sadece en son dosyayı okur, eskiler arşivlenebilir.
