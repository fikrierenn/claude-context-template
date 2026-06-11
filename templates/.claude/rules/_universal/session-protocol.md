# Oturum Protokolü

_Her Claude oturumunun başı / ortası / sonu ritüelleri. Bu kural evrensel — her projede aynı._

## Neden bu dosya var

Deneyim: SessionStart hook bazen fire etmeyebiliyor. Daha kötüsü, fire ettiğinde Claude "çıktıyı context'te gördüm, yeterli" varsayımı yapıp tekrar çalıştırmayı atlıyor. O varsayım **iki ayrı hata** üretti: stale context + yanlış cevap. Kural bu sebeple **koşulsuz** hale getirildi.

## Oturum Başı — İlk yanıttan önce ZORUNLU

### Adım 1 — Hook'u KOŞULSUZ çalıştır

**Windows/PowerShell:**
```powershell
powershell -NoProfile -File .claude/hooks/session-start.ps1
```

**Unix/Bash:**
```bash
bash .claude/hooks/session-start.sh
```

**Her oturumda, istisnasız.** Context'te hook çıktısı görünüyor olsa bile tekrar çalıştır. "Hook fire etti, atla" varsayımı yasak.

Çıktı: son 3 gün commit'ler, uncommitted sayısı, 15-eşik uyarısı, aktif TODO başlıkları, son journal'ın son 40 satırı, statik kod sağlığı sinyalleri.

### Adım 2 — Son 2 journal dosyasını oku

Her ikisini de `Read` et. Özellikle bak:
- **Tamamlananlar** — son oturumda ne bitti
- **Yarım kalan işler** — nereden devam edilecek
- **Düzeltme notları** — tekrarlanmaması gereken hata

### Adım 3 — TODO.md aktif öncelikleri oku

`TODO.md` → **"BIRLESIK ONCELIK SIRASI"** bölümü. En az Faz 0 (bugün) + Faz 1'in ilk 3 maddesi.

### Adım 4 — Memory dosyalarını oku

`memory/MEMORY.md` → feedback + project + reference memory'lerini tara. Aktif feedback kuralları güncel davranışı yönlendirir.

### Adım 5 — Uncommitted durumu bil

`git status --porcelain | wc -l` — 15 üstüyse **yeni iş yasak**, önce commit-split.

### Adım 6 — Compliance scan (uncommitted varsa)

Uncommitted veya bu oturumda yazılan kod varsa tek mesajda paralel agent bat:

```
Agent(code-reviewer)         — kural uyumu + bug
Agent(silent-failure-hunter) — exception handling
Agent(security-reviewer)     — güvenlik
Agent(general-purpose)       — inline style / secret tarama
```

Bulgu yok → işe geç. HIGH/CRITICAL → önce fix.

### Kullanıcıya İLK YANIT — ZORUNLU FORMAT

Yukarıdaki adımlar sessizce yapılır. **İlk yanıt şu formatta olmalı:**

```
**[UNCOMMITTED: N dosya]** ✓ / ⚠️ EŞİK AŞILDI
**HIGH açık:** [TODO'dan HIGH/CRITICAL maddeler, yoksa "yok"]
**Öncelik:** [Faz 0'dan ilk 1-2 madde]
Ne yapıyoruz?
```

Bu özeti **vermeden** kullanıcının sorusunu yanıtlama. "Selam"a bile önce özet gelir.

---

## Oturum Ortası

### 15 dosya eşiği
Uncommitted > 15 → **yeni iş yasak**, önce commit-splitter subagent çağır.

### 3 paralel feature eşiği
Aynı anda 3'ten fazla feature branch → birini bitirmeden yenisine geçme.

### Kural değişikliği → dosyaya yaz
Kullanıcı yeni bir kural söylüyorsa hemen `.claude/rules/*.md` veya `memory/feedback_*.md` dosyasına yaz. "Aklında tut" demez.

### Memory yazma — PROAKTIF
Her oturumda gözlemlenen feedback/karar/proje durumu memory'ye yazılır. Kullanıcı söylemeden:
- Davranış düzeltmesi → `memory/feedback_<konu>.md`
- Önemli proje kararı → `memory/project_<konu>.md`
- Dış kaynak → `memory/reference_<konu>.md`
- `memory/MEMORY.md` index güncellenir

### 3+ adımlı plan → TodoWrite + plan-tracker
Kullanıcı 3+ adımlı iş tanımladıysa **kullanıcı demeden**: TodoWrite + `plan-tracker` skill. İkisi farklı amaç (in-session vs kalıcı), biri yetmez.

### Mimari karar → ADR
Mimari karar alındıysa `docs/ADR/NNN-konu.md` yaz.

---

## Oturum Sonu

### Tetikler
Kullanıcı "iyi geceler" / "handoff" / "kaydet ve kapat" / "/handoff" → `.claude/skills/session-handoff/SKILL.md` devreye girer.

### Compliance Scan (handoff öncesi ZORUNLU)
Bu oturumda değiştirilen/commit edilen dosyalar üzerinde compliance scan — aynı Adım 6 agent seti. CRITICAL/HIGH → düzelt + commit → sonra handoff. MEDIUM/LOW → handoff'ta borç olarak kaydet.

### Memory Güncelle
Oturumda öğrenilen yeni feedback/karar/proje durumu memory'ye yazılmışsa MEMORY.md index'i güncelle.

### Ne yapar (handoff skill)
`docs/journal/YYYY-MM-DD.md`'ye append eder:
Ana konu, tamamlananlar (dosya:line), build/test durumu, commit durumu, yarım kalan, kararlar, dikkat notları, yarına başlangıç noktası.

### CLAUDE.md'ye session log yazma
Session log **CLAUDE.md'ye yazılmaz**. Sadece journal'a.

---

## Ritüel atlandığında

1. **Kabul et.** "Hook fire etmedi" / "context'te vardı" mazeret değil.
2. **Anında kapat.** Hook'u manuel çalıştır, journal'i oku, TODO'yu gözden geçir.
3. **Önlemini dosyaya yaz.** `memory/feedback_<konu>.md` güncelle.
4. **Journal'a süreç notu düş.**

---

## İlişkili Dosyalar

- `docs/CONTEXT_MANAGEMENT.md` — bağlam yönetimi anayasası
- `.claude/hooks/session-start.sh` / `session-start.ps1` — oturum başı bilgi toplayıcı
- `.claude/skills/session-handoff/SKILL.md` — oturum sonu journal yazar
- `.claude/rules/commit-discipline.md` — 15 dosya eşiği
- `memory/MEMORY.md` — proje memory indeksi
- `docs/journal/` — tarihli oturum kayıtları
