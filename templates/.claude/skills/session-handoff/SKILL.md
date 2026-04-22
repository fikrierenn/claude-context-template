---
name: session-handoff
description: Oturum sonu ozet yazar. Bugun yapilanlari, build durumunu, yarim kalan islari, yarina baslangic noktasini docs/journal/YYYY-MM-DD.md dosyasina yazar. Kullanici "handoff", "oturum sonu", "iyi geceler", "kaydet ve kapat", "gunaydin ozet" gibi ifadeler kullandiginda veya /handoff calistirildiginda devreye gir.
allowed-tools: Read, Edit, Write, Bash, Grep, Glob
user-invocable: true
model: inherit
---

# Oturum Devir Skill'i

## Amac
Her oturum sonunda (veya baslangicinda ozet almak icin), gun icinde olanlari kalici bir journal dosyasina yazar. Boylece:
- CLAUDE.md'ye session log yazilmaz (temizlik korunur).
- Yarinki Claude ne olduguna bakar (SessionStart hook otomatik okur).
- Gecmis kararlar grep'lenebilir.

## Kaynak Dosya
`docs/journal/YYYY-MM-DD.md` — format `%Y-%m-%d`. Yoksa olustur, varsa append.

## Cikti Sablonu
```markdown
# Oturum Gunlugu — YYYY-MM-DD

## Ana Konu
<1-2 cumle: bu oturumda asil hedef>

## Tamamlananlar
- Madde 1 (dosya:line referansi)
- Madde 2

## Build / Test Durumu
- build: yesil / kirmizi / calistirilmadi
- test: X yesil, Y kirmizi / calistirilmadi
- lint / syntax: OK / ERR

## Commit Durumu
- Uncommitted: N
- Yeni commit'ler: <liste>

## Yarim Kalan / Yarin'a
- Madde 1 — neden yarim, nereden devam
- Madde 2

## Kararlar
- <Bu oturumda alinan kararlar>
- <ADR'ye yazilmis mi?>

## Dikkat Edilmesi Gerekenler
- <Memory hatasi, yanlis varsayim>

## Yarina Baslangic Noktasi
1. <Kritik 1. adim>
2. <2. adim>
3. <3. adim>
```

## Adim Adim

### 1. Bilgi Topla
```bash
date +%Y-%m-%d                           # tarih
git status --porcelain | wc -l           # uncommitted
git log --since=midnight --oneline       # bugun commit'ler
git diff --stat                          # kaç satir degisti
```

### 2. Journal Kontrol
```bash
JOURNAL="docs/journal/$(date +%Y-%m-%d).md"
```
Yoksa `mkdir -p docs/journal` + sablondan olustur. Varsa en altta `---` + `## Oturum N` bolumu ekle.

### 3. Konusma Baglamini Oku
Bu oturumdaki:
- Kullanici mesajlarinin ozeti
- Yaptigin degisiklikler
- Todo list durumu

Bu bilgilerden "Tamamlananlar", "Yarim Kalan", "Kararlar" bolumlerini cikar.

### 4. Dosyaya Yaz
- Dosya yoksa: sablondan yeni.
- Varsa: append.

### 5. Ozet Goster
5-10 satir:
```
Oturum kaydedildi: docs/journal/2026-04-22.md
- Tamamlanan: 4 madde
- Yarim kalan: 2 madde
- Uncommitted: 12 dosya (15 altinda, iyi)
- Yarina baslangic: <ilk adim>
```

## Tetikleyici Durumlar
- "iyi geceler" → otomatik cagir, journal yaz, ozet ver.
- "/handoff" → aciklik.
- "devam edecegiz" → mevcut durumu kaydet.
- "gunaydin" → ters yon: en son journal'i oku, "nerede kaldik" ozet.

## Dikkat
1. **Hic journal yoksa:** `docs/journal/` olustur.
2. **Commit etmeye karar verme** — kullanici ister.
3. **CLAUDE.md'ye ekleme** — session log 200 satir kuralini bozar.
4. **Ust uste yazim:** Ayni gun 2. kez → `## Oturum 2`.
5. **Yerel dil** (Turkce/Ingilizce) projeye gore.

## Iliskili
- SessionStart hook: en son journal'i oturum basinda Claude'a enjekte eder.
- `docs/CONTEXT_MANAGEMENT.md`: anayasa.
