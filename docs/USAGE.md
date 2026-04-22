# Kullanım Kılavuzu

Detaylı örneklerle Claude Context Template kurulum, kullanım ve güncelleme.

- [1. İlk Kurulum — Yeni Proje](#1-ilk-kurulum--yeni-proje)
- [2. Mevcut Projeye Ekleme](#2-mevcut-projeye-ekleme)
- [3. Template Güncelleme (--update)](#3-template-güncelleme---update)
- [4. İlk Claude Oturumu](#4-ilk-claude-oturumu)
- [5. Hook'lar Ne Yapar?](#5-hooklar-ne-yapar)
- [6. Sub-agent'lar: commit-splitter](#6-sub-agentlar-commit-splitter)
- [7. Skill'ler: session-handoff](#7-skillar-session-handoff)
- [8. Günlük Workflow](#8-günlük-workflow)
- [9. Sık Yapılan Hatalar](#9-sık-yapılan-hatalar)
- [10. Sıkça Sorulan Sorular](#10-sıkça-sorulan-sorular)

---

## 1. İlk Kurulum — Yeni Proje

Diyelim `D:\Dev\my-api` adında yeni bir .NET API projen var, boş ya da birkaç dosyalı. Kurulumu tek komutla yap:

### Windows (PowerShell)

```powershell
pwsh D:\Dev\claude-context-template\bin\bootstrap.ps1 `
  -ProjectPath "D:\Dev\my-api" `
  -ProjectName "MyApi" `
  -Stack dotnet-mvc
```

### Unix / Git Bash / WSL

```bash
bash /d/Dev/claude-context-template/bin/bootstrap.sh \
  --path /d/Dev/my-api \
  --name MyApi \
  --stack dotnet-mvc
```

**Çıktı (özetle):**

```
=== Claude Bağlam Yönetimi Bootstrap ===
Hedef: D:\Dev\my-api
Ad:    MyApi
Stack: dotnet-mvc
Türkçe UI: true
Pre-commit hook: pasif (settings.json'dan ileride aktifleştir)
Mod:   YENİ KURULUM

[1/8] .claude/rules/
  + rules/session-protocol.md
  + rules/commit-discipline.md
  + rules/session-memory.md
  + rules/security-principles.md
  + rules/turkish-ui.md
  + rules/csharp-conventions.md (stack: dotnet-mvc)
  + rules/razor-conventions.md (stack: dotnet-mvc)
  + rules/sql-conventions.md (stack: dotnet-mvc)
  + rules/js-conventions.md (stack: dotnet-mvc)
  + rules/project/architecture.md (placeholder)
  + rules/project/security-principles.md (placeholder)
  + rules/project/known-issues.md (placeholder)
[2/8] .claude/hooks/
  + hooks/session-start.sh (executable)
  + hooks/pre-commit-antipattern.sh (executable)
  + hooks/post-commit-journal.sh (executable)
[3/8] .claude/agents/
  + agents/commit-splitter.md
[4/8] .claude/skills/session-handoff/
  + skills/session-handoff/SKILL.md
[5/8] .claude/settings.json
  + settings.json (PreToolUse pasif)
[6/8] .gitignore
  + .gitignore (yeni, template kopyalandı)
[7/8] docs/
  + docs/CONTEXT_MANAGEMENT.md
  + docs/journal/README.md
  + docs/ADR/000-template.md
[8/8] CLAUDE.md + TODO.md
  + CLAUDE.md
  + TODO.md

=== Tamam ===
```

### Seçenekler

| Argüman | Açıklama | Default |
|---|---|---|
| `--path` / `-ProjectPath` | Hedef proje yolu (zorunlu) | — |
| `--name` / `-ProjectName` | Proje adı (şablonlarda yerleşir) | path sonu |
| `--stack` / `-Stack` | `dotnet-mvc`, `nodejs-typescript`, `python-generic`, `none` | `none` |
| `--no-turkish` / `-IncludeTurkish:$false` | Türkçe UI kuralını ekleme | ekler |
| `--enable-precommit-hook` / `-EnablePreCommitHook` | Antipattern hook'u aktif başlat | pasif |
| `--no-gitignore-merge` / `-NoGitignoreMerge` | `.gitignore`'a Claude Code girdileri ekleme | ekler |
| `--update` / `-Update` | Sadece template dosyalarını güncelle, proje-özel'e dokunma | yeni kurulum |
| `--force` / `-Force` | Mevcut dosyaların üzerine yaz | atlar |

### Kurulum Sonrası İlk İş

```bash
cd D:\Dev\my-api
claude
```

Claude açılır açılmaz SessionStart hook devreye girer ve git/TODO/journal özetini sana gösterir. İlk yanıttan önce Claude `CLAUDE.md`'yi ve `.claude/rules/`'ı okur.

**İlk oturumda yapman gerekenler:**

1. `CLAUDE.md` aç → `§1 Proje Kimliği`'ni doldur (proje amacı, tech stack ek detay, ana klasörler).
2. `.claude/rules/project/architecture.md` aç → mimari notlarını yaz.
3. `.claude/rules/project/security-principles.md` aç → projenin güvenlik önceliklerini yaz.
4. `.claude/rules/project/known-issues.md` aç → bilinen sorunları yaz.
5. `TODO.md` aç → Faz 0/1/2/3 maddelerini gerçek iş listene göre doldur.

---

## 2. Mevcut Projeye Ekleme

Devam eden bir projede (kod zaten var, git history zaten var) bu sistemi eklemek.

```bash
bash bootstrap.sh --path /d/Dev/existing-project --stack nodejs-typescript
```

**Fark:** `.gitignore`, `.claude/settings.json` gibi dosyalar mevcut olabilir. Script bu durumda:
- `.gitignore` → mevcut içeriğin sonuna Claude Code girdilerini **append** eder (zaten varsa atlar).
- `.claude/settings.json` → dokunmaz, uyarı verir ("mevcut — elle merge et").
- `CLAUDE.md` / `TODO.md` → dokunmaz (`--force` gerekir).

Script çalıştıktan sonra:

```bash
# Mevcut settings.json'ın içeriğini template ile karşılaştır
diff .claude/settings.json /d/Dev/claude-context-template/templates/.claude/settings.json.tmpl

# Pre-commit hook ve post-commit hook kayıtlarını mevcut settings.json'a ekle
# (elle veya editörle)
```

---

## 3. Template Güncelleme (`--update`)

Template'te iyileştirme olunca (örn. yeni stack, hook fix, evrensel kural güncelleme), projelere yaymak için:

```bash
bash bootstrap.sh --path /d/Dev/my-api --update
```

**Bu mod:**
- Universal rules (`_universal/*.md`) → güncellenir ✓
- Stack rules (`stacks/<name>/*.md`) → güncellenir ✓
- Hook script'leri → güncellenir ✓
- Skill'ler + agent'lar → güncellenir ✓
- `docs/CONTEXT_MANAGEMENT.md` → güncellenir ✓
- `CLAUDE.md` → **dokunulmaz** ✗ (proje-özel)
- `TODO.md` → **dokunulmaz** ✗
- `.claude/rules/project/*.md` → **dokunulmaz** ✗
- `docs/journal/*.md` → **dokunulmaz** ✗
- `.claude/settings.json` → **dokunulmaz** ✗ (elle merge edilir)

### Birden fazla projeye toplu güncelleme

```bash
for p in my-api my-web my-cli; do
  bash bootstrap.sh --path "/d/Dev/$p" --update
done
```

---

## 4. İlk Claude Oturumu

### Oturum Açılışı — Beklenen Davranış

Claude `claude` komutuyla açılır açılmaz:

1. **SessionStart hook fire eder** (`session-start.sh`), Claude'a özet enjekte eder:
   ```
   ## MyApi — Oturum Basi Ozet
   ### Son 3 gun commit'ler
   a1b2c3d feat: login endpoint
   ### Uncommitted dosya sayisi
   3 dosya
   ### Aktif TODO basliklari (ilk 15)
   - BIRLESIK ONCELIK SIRASI
     - Faz 0 — Bugün
     ...
   ### En son journal girdisi
   Dosya: docs/journal/2026-04-22.md
   ...
   ```

2. **CLAUDE.md context'e enjekte edilir** (tüm kurallar dahil).

3. Claude **§0 Oturum Başı Ritüeli**'ne göre `bash .claude/hooks/session-start.sh` koşulsuz çalıştırır, son 2 journal dosyasını okur, TODO Faz 0'ı gözden geçirir.

4. Ancak bundan sonra sorunu yanıtlar.

### Örnek Konuşma

**Sen:** `günaydın`

**Claude (ritüel sonrası):**
> Dünün journal'ından devam:
> - Faz 0 (bugün, 2 saat): Login validator eksik, signup flow test yok.
> - 3 uncommitted dosya (eşik 15 — temiz).
>
> Sıradan başlayalım mı, yoksa farklı bir konu mu?

Bu yanıt **hafıza tahmini değil** — hook çıktısı + journal + TODO okumasından geliyor.

---

## 5. Hook'lar Ne Yapar?

### 5.1 `session-start.sh` — SessionStart hook

**Tetikleyici:** Claude oturumu açıldığında otomatik (veya elle çalıştırarak).

**Yaptığı:**
- `git log --since="3 days ago"` → son 3 gün commit'ler
- `git status --porcelain | wc -l` → uncommitted sayısı, 15+ ise UYARI
- `TODO.md` başlık satırları (ilk 15 line)
- `docs/journal/` en son dosyanın son 40 satırı
- Kritik rule dosyalarına link indeksi

**Çıktı örneği:**

```
## MyApi — Oturum Basi Ozet
### Son 3 gun commit'ler
a1b2c3d feat: login endpoint
### Uncommitted dosya sayisi
17 dosya

UYARI: 15 dosya esigi asildi. Yeni is baslamadan once commit-split gerek.
...
```

### 5.2 `pre-commit-antipattern.sh` — PreToolUse hook

**Tetikleyici:** Claude her Bash komutu çalıştırmadan önce hook fire eder. Hook içinde kontrol: `git commit` komutu mu? Değilse exit 0. İse staged dosyaları tarar.

**Taradığı antipatterns:**
- **Tüm dosyalarda:** Hardcoded `Password=...` literal'leri
- **.cs dosyalarında:** `DateTime.Now` (UTC yok), `async void` (event harici), `new HttpClient()`, `ex.Message` user'a sızıntı (TempData/ViewBag/Json)
- **.ts/.tsx/.js dosyalarında:** `console.log` production, `any` tipi
- **.py dosyalarında:** `print(` production, `except:` bare

**Bloklanırsa:**
```
=== PRE-COMMIT ANTIPATTERN SCAN: BLOKLANDI ===
  X src/auth.ts:45: 'any' kullanimi (strict tip ver)
Commit iptal edildi. Once issue'lari duzelt, sonra tekrar commit'le.
Gecici bypass: CLAUDE_PRECOMMIT_SKIP=1 git commit ...
```

**Greenfield projelerde pasif başlar** (bootstrap default). `--enable-precommit-hook` ile açık başlat veya sonra `settings.json` elle düzenle.

### 5.3 `post-commit-journal.sh` — PostToolUse hook

**Tetikleyici:** Claude her Bash çalıştıktan sonra. Başarılı `git commit` ise journal'a append.

**Yaptığı:**
- `docs/journal/YYYY-MM-DD.md` (bugünün dosyası) — yoksa oluştur, varsa append
- `## Commit'ler` bölümü yoksa ekle
- Commit hash + subject + dosya listesi yaz

**Örnek çıktı (journal içinde):**

```markdown
## Commit'ler

### `a1b2c3d` — feat: login endpoint

Dosyalar (4):
- src/routes/login.ts
- src/auth/hash.ts
- tests/login.test.ts
- CHANGELOG.md
```

Bu sayede tarihli commit özetini elle yazmana gerek yok — her commit otomatik journal'a işler.

---

## 6. Sub-agent'lar: commit-splitter

`.claude/agents/commit-splitter.md` altında tanımlı. Claude'a "commit-split yap" / "65 dosyayı böl" / "uncommitted temizle" dediğinde devreye girer.

### Ne zaman çalıştır

- `git status` 15+ dosya → **kural: yeni iş yasak**, önce split.
- Feature branch merge öncesi temizlik.
- Uzun bir coding seans sonrası (tüm değişiklikleri tek commit yapmak anti-pattern).

### Nasıl çağır

```
> commit-splitter subagent'ı çağır, 65 dosyayı bölsün
```

veya:

```
> /commit-split
```

(Claude Code subagent'ı otomatik tanır ve Agent tool ile çağırır.)

### Agent ne yapar

1. `git status --short` + `git diff --stat` ile değişiklikleri analiz eder.
2. Dosyaları **bucket**'lara atar:
   - Path pattern (örn. `src/auth/*` → auth bucket)
   - Feature ilişkisi (model + migration + controller + test birlikte)
3. Numaralı plan sunar:
   ```
   1. feat(auth): login endpoint (4 dosya)
   2. feat(reports): data filter (6 dosya)
   3. chore: dependency update (2 dosya)
   ```
4. Sen onay verince **o bucket'ı stage + commit** eder.
5. Bir sonraki bucket'a geçer.

### Kurallar

- `git add .` / `-A` **yasak** — yanlış bucket'a dosya kaçar.
- Secret/env dosyaları stage'lenmez.
- 15 dosya commit başına eşik.
- `git reset HEAD~1 --soft` son commit'i geri alabilir (sen isterse).

---

## 7. Skill'ler: session-handoff

`.claude/skills/session-handoff/SKILL.md` altında tanımlı. Oturum sonunda çağrılır:

- `/handoff` slash komutu
- "iyi geceler", "kaydet ve kapat", "devam edeceğiz" gibi ifadeler

### Ne yapar

`docs/journal/YYYY-MM-DD.md` dosyasına append eder:

- **Ana konu** — bu oturumun hedefi
- **Tamamlananlar** — dosya:line referanslı
- **Build / test durumu** — yeşil / kırmızı / çalıştırılmadı
- **Commit durumu** — uncommitted sayısı, yeni commit'ler
- **Yarım kalan işler** — nereden devam
- **Kararlar** — ADR'ye gidecek mi
- **Yarına başlangıç noktası** — 1-3 somut adım

### Örnek çıktı

```markdown
# Oturum Günlüğü — 2026-04-22

## Ana konu
Login endpoint + rate limit

## Tamamlananlar
- `src/routes/login.ts:15` — PBKDF2 password hash
- `src/middleware/rate-limit.ts:1` — IP-based rate limit (5/dk)
- `tests/login.test.ts:1` — 8 test case

## Build / test
✓ pnpm test yeşil (23/23)
✓ pnpm build yeşil

## Yarım kalan
- Rate limit Redis backend bağlantısı (şimdilik in-memory)
- CSRF token login response'una eklenmedi

## Yarına
1. Redis rate-limit backend
2. CSRF token ekle + test
3. `/me` endpoint başla
```

### Commit etmez

Skill sadece journal yazar. Kullanıcı açıkça "commit et" demedikçe commit yapılmaz.

---

## 8. Günlük Workflow

### Sabah

```
$ cd /d/Dev/my-api
$ claude
```

Claude: _(ritüel sonrası)_ "Dün rate limit bitti, bugün CSRF sırada. Başlayalım mı?"

### Gün İçi

- Her büyük task → `security-review` skill'i öncesi/sonrası.
- Her 3 commit → `git push origin main` (veya feature branch).
- Uncommitted > 15 → **dur**, commit-splitter çağır.
- Yeni bir kural kullanıcıdan → anında `.claude/rules/` veya ilgili dosyaya yaz.
- Mimari karar → `docs/ADR/NNN-konu.md` yaz.

### Akşam

```
Sen: iyi geceler
Claude: _(handoff skill çalışır)_ "Journal yazıldı. 3 commit var, push edildi. Yarın için..."
```

Veya:

```
Sen: /handoff
```

---

## 9. Sık Yapılan Hatalar

### ❌ Hook çıktısını gördüm, `bash` tekrar çalıştırmaya gerek yok

**Yanlış.** Koşulsuz kural (session-protocol.md §1): Her oturum başında `bash .claude/hooks/session-start.sh` mutlaka çalıştırılır. Context stale olabilir, fresh çıktı farklı olabilir.

### ❌ Uncommitted 30 dosya var ama yeni iş başlayalım

**Yanlış.** Kural: 15+ dosya → yeni iş yasak, önce commit-split. Kod dağılır, context kaybolur.

### ❌ Yeni kural geldi, aklımda tutayım

**Yanlış.** Kurallar konuşma hafızasında yaşamaz. Dosyaya yaz (`.claude/rules/<konu>.md`).

### ❌ Mimari karar aldım, devam edelim

**Yanlış.** `docs/ADR/` yaz, kısa bir karar kaydı. 6 ay sonra "niye böyle yapmıştık?" sorusuna cevap olur.

### ❌ Session log'u CLAUDE.md'ye yazayım

**Yanlış.** 200 satır eşiği var. Session log journal'a gider, CLAUDE.md sadece değişmez kimlik + kural.

### ❌ Pre-commit hook greenfield projemde hep blok ediyor

**Doğru davranış:** Bootstrap default'u pasif. Kod yazmaya başladıkça `--enable-precommit-hook` ile aç.

---

## 10. Sıkça Sorulan Sorular

### S: Mevcut `.gitignore`'ım var, ezilir mi?
**C:** Hayır. Script append eder, zaten varsa atlar. `--no-gitignore-merge` ile tamamen kapatabilirsin.

### S: `settings.json` mevcutsa ne olur?
**C:** Script dokunmaz, uyarı verir. Hook kayıtlarını elle ekle:

```json
{
  "hooks": {
    "SessionStart": [{ "hooks": [{ "type": "command", "command": "bash D:/Dev/proje/.claude/hooks/session-start.sh" }] }],
    "PreToolUse":   [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "bash D:/Dev/proje/.claude/hooks/pre-commit-antipattern.sh" }] }],
    "PostToolUse":  [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "bash D:/Dev/proje/.claude/hooks/post-commit-journal.sh" }] }]
  }
}
```

### S: Template'te iyileştirme yaptım, projeme nasıl yayarım?
**C:** `bash bootstrap.sh --path /d/Dev/proje --update`. Universal + stack + hook güncellenir, proje-özel dosyalar dokunulmaz.

### S: Yeni bir stack ekleyeceğim (Go, Rust, Java). Nasıl?
**C:** `templates/.claude/rules/stacks/<ad>/` altına `<ad>-conventions.md` + varsa ek dosyalar koy. `bootstrap.sh`'deki `STACK=...` case'ine ekle. Test et: `bash bootstrap.sh --stack <ad> --path /tmp/test`.

### S: Pre-commit hook kuralları projeye göre farklı olsun istiyorum.
**C:** `.claude/hooks/pre-commit-antipattern.sh` dosyasını projede düzenle — template'ten kopyalandıktan sonra tamamen proje-yerel. Template'i korumak için o projeye `--update` geçme, yeni versiyonu elle merge et.

### S: "Pre-commit hook bloklamıyor, hiçbir şey olmuyor"
**C:** Kontrol:
1. `.claude/settings.json` içinde `PreToolUse` bloğu var mı?
2. `bash .claude/hooks/pre-commit-antipattern.sh` komutu chmod +x?
3. Hook stderr'a yazıyor — Claude görüyor mu? Terminal'de elle test:
   ```bash
   echo '{"tool_input":{"command":"git commit -m test"}}' | bash .claude/hooks/pre-commit-antipattern.sh; echo "EXIT=$?"
   ```

### S: Post-commit journal hook çalıştı ama dosya güncellemedi
**C:** Hook son commit HEAD'i okur. Eğer PreToolUse hook commit'i blokladıysa, ortada commit yok, hook exit 0'la atlıyor. Commit başarılıysa `git log -1` kontrol et ve yeniden dene.

### S: CLAUDE.md 200 satırı aştı, ne yapayım?
**C:** İçeriği `.claude/rules/<konu>.md` altında konulara böl. CLAUDE.md link indeksi olsun. Detay: `.claude/rules/session-memory.md`.

### S: Claude her seferinde hook çıktısını gördüğü halde sanki görmemiş gibi davranıyor
**C:** Koşulsuz kural (§0) tam olarak bu sorunu çözüyor. Context'te hook çıktısı olsa bile tekrar `bash` çalıştır kuralı. Aksi hatalı cevap üretir. Bu dersi `.claude/rules/session-protocol.md` içinde ayrıntılı anlatıyor.

### S: Node/Python projelerinde pre-commit hook scanı C#'a göre ince kalmış
**C:** Doğru — generic bir başlangıç. Projede özelleştir, PR açarsan template'e geri alırım:

```bash
cd /d/Dev/my-node-api
edit .claude/hooks/pre-commit-antipattern.sh
# case "*.ts") ... ekle
```

### S: `.claude/worktrees/` nedir, niye gitignore'da?
**C:** Cowork (Claude Code'un IDE modu) sandbox altında her agent kendi izole worktree'sinde çalışır — `.claude/worktrees/<agent-id>/`. Bunlar geçici kopyalar, versiyon kontrolüne gitmez.

### S: Birden fazla oturumda aynı TODO düştü, nasıl bir priorityleyim?
**C:** `TODO.md` "BIRLESIK ONCELIK SIRASI" formatı bunu çözer:
- Faz 0 (bugün): blocker, kritik güvenlik, hızlı bug
- Faz 1 (bu hafta): yüksek öncelik
- Faz 2 (bu ay): orta öncelik, refactor
- Faz 3 (çeyrek): temizlik, test coverage

Kısa ID (G-01, M-02, F-01) commit mesajlarında ve journal'da referans verir.

---

## Devamı

- [PATTERNS.md](PATTERNS.md) — real-world commit-split, hook disable, consolidated-commit örüntüleri.
- [docs/CONTEXT_MANAGEMENT.md](../templates/docs/CONTEXT_MANAGEMENT.md) — bağlam yönetimi ilkeleri anayasası.
