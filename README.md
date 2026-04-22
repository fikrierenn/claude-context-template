# claude-context-template

**Her projede kullanılabilir, Claude Code için bağlam yönetimi şablon sistemi.**

Amaç: CLAUDE.md şişkinliği, session log karmaşası, uncommitted birikmesi, bağlam kopması gibi büyüyen projelerde yaşanan sorunları **sıfır günden itibaren** önlemek.

Kaynak: `D:/Dev/reporthub` (ReportHub) pilot projesinde canlı kurulup test edildi, proje-bağımsız hale getirildi.

- **Detaylı kullanım:** [`docs/USAGE.md`](docs/USAGE.md)
- **Real-world örüntüler:** [`docs/PATTERNS.md`](docs/PATTERNS.md)

---

## Hızlı Kullanım

### Windows (PowerShell)
```powershell
pwsh D:\Dev\claude-context-template\bin\bootstrap.ps1 `
  -ProjectPath "D:\Dev\yeni-proje" `
  -ProjectName "YeniProje" `
  -Stack dotnet-mvc
```

### Unix / Git Bash / WSL
```bash
bash /d/Dev/claude-context-template/bin/bootstrap.sh \
  --path /d/Dev/yeni-proje \
  --name YeniProje \
  --stack dotnet-mvc
```

### Script Ne Yapar

1. `CLAUDE.md` oluşturur (§0 Oturum Başı Ritüeli + proje kimliği + kurallar).
2. `.claude/rules/` — evrensel + stack + proje-özel placeholder kuralları.
3. `.claude/hooks/` — **SessionStart** (session özet) + **PreToolUse** (pre-commit antipattern) + **PostToolUse** (post-commit journal).
4. `.claude/agents/commit-splitter.md` — uncommitted böl/commit subagent'ı.
5. `.claude/skills/session-handoff/` — oturum sonu journal yazar.
6. `.claude/settings.json` — hook kayıtları.
7. `.claude/launch.json.tmpl` — Claude Preview MCP dev server config.
8. `.gitignore` — Claude Code girdileri merge edilir (`.claude/worktrees/`, `.claude/settings.local.json`).
9. `docs/` — `CONTEXT_MANAGEMENT.md` anayasa + `journal/` + `ADR/`.
10. `TODO.md` — Faz 0/1/2/3 öncelik formatı.

Sonuç: `cd yeni-proje && claude` — **her oturum başı otomatik hook**, son 3 gün durumu, TODO Faz 0, uncommitted sayısı, son journal hemen context'te.

---

## v1.1 Yeni Özellikler (22 Nisan 2026)

ReportHub pilot oturumunun öğrendikleri template'e taşındı:

- **Koşulsuz hook kuralı** (`session-protocol.md`) — context'te hook çıktısı görünse bile `bash` elle tekrar çalıştır. "Atla" varsayımı yasak.
- **Pre-commit antipattern hook** — hardcoded şifre, `DateTime.Now`, `async void`, `ex.Message` leak, `any` tipi, `print(` production vb. tespiti.
- **Post-commit journal hook** — başarılı her commit `docs/journal/YYYY-MM-DD.md`'ye otomatik eklenir.
- **commit-splitter subagent** — 15+ dosya uncommitted'ı anlamlı bucket'lara böl.
- **launch.json template** — Claude Preview MCP ile dev server bootstrap.
- **Faz 0/1/2/3 TODO formatı** — zaman-bazlı öncelik.
- **USAGE.md + PATTERNS.md** — bol örnekle kullanım kılavuzu + real-world pattern'ler.
- **.gitignore otomatik merge** — `.claude/worktrees/`, `.claude/settings.local.json` güvenli dışlanır.

---

## Desteklenen Stack'ler

| Stack | Kapsam |
|---|---|
| `dotnet-mvc` | ASP.NET Core MVC + EF Core + SQL Server, Razor, Stored Procedure, vanilla JS, Tailwind |
| `nodejs-typescript` | Node.js + TypeScript (Express / Fastify / Next.js agnostic) |
| `python-generic` | Python 3 (Django / FastAPI / Flask agnostic) |
| `none` | Stack-bağımsız, sadece universal + project-özel |

Yeni stack: `templates/.claude/rules/stacks/<ad>/` altına `.md` kurallar + bootstrap script'in stack case'ine ekle.

---

## Mimarî — 3 Katman Ayrımı

Bağlam yönetimi anayasasının **3 katman ayrımı** ilkesine göre:

| Katman | Nerede | İçerik |
|---|---|---|
| **Kimlik** | `CLAUDE.md` (proje kök) | Proje tanımı, stack, ana klasörler, link indeksi. ~150 satır. |
| **Kurallar** | `.claude/rules/*.md` | Davranış kuralları, konu başına dosya. Universal + stack + project. |
| **Süreç** | `TODO.md`, `docs/ADR/`, `docs/journal/` | Planlar, kararlar, oturum notları. |

**Aynı bilgi tam olarak bir yerde yaşar.**

---

## Evrensel Kurallar

Her stack'te aktif (`_universal/`):

- `session-protocol.md` — **koşulsuz hook kuralı**, oturum başı/ortası/sonu ritüelleri. (v1.1 YENİ)
- `commit-discipline.md` — git/commit/branch-per-ask, 15 dosya eşiği
- `session-memory.md` — bağlam disiplin kuralları
- `security-principles.md` — temel güvenlik (XSS, SQL, secrets)
- `turkish-ui.md` — opsiyonel Türkçe UI kuralları (`--no-turkish` kapatır)

---

## Proje-Özel Kurallar

Bootstrap placeholder kopyalar, her projede kendi içeriğini yazarsın (`.claude/rules/project/`):

- `architecture.md` — projenin mimari durumu + bilinen tutarsızlıklar
- `security-principles.md` — proje-özel güvenlik (env var, user filter, vb.)
- `known-issues.md` — AV / IT / platform-özel bilinen sorunlar

---

## Hook'lar

### SessionStart (`session-start.sh`)
Oturum başında otomatik. Claude'a enjekte:
- Son 3 gün commit'ler
- Uncommitted dosya sayısı (15+ ise UYARI)
- Aktif TODO başlıkları
- En son journal girdisinin son 40 satırı

### PreToolUse (`pre-commit-antipattern.sh`) — pasif default
`git commit` öncesi staged dosyaları tarar:
- **Tüm tiplerde:** Hardcoded şifre regex (`Password=<literal>`)
- **.cs:** `DateTime.Now`, `async void`, `new HttpClient()`, `ex.Message` user-facing
- **.ts/.js:** `console.log` production, `any` tipi
- **.py:** `print()` production, bare `except:`

İhlal → commit blok, stderr'da mesaj. Bypass: `CLAUDE_PRECOMMIT_SKIP=1`.

Greenfield'de pasif (bootstrap default). Aktif: `--enable-precommit-hook` veya `settings.json` elle.

### PostToolUse (`post-commit-journal.sh`)
Başarılı `git commit` sonrası `docs/journal/YYYY-MM-DD.md`'ye hash + subject + dosya listesi append.

---

## Sub-agent: commit-splitter

`.claude/agents/commit-splitter.md` — `git status > 15` olunca devreye girer.

- Dosyaları feature/scope bucket'larına atar
- Numaralı plan sunar
- Her bucket için kullanıcı onayı bekler
- `git add` + `git commit` uygular
- `--no-verify` kullanmaz, pre-commit hook'u kabul eder

Detay: [`docs/USAGE.md §6`](docs/USAGE.md#6-sub-agentlar-commit-splitter).

---

## Skill: session-handoff

`/handoff`, "iyi geceler", "kaydet ve kapat" ifadeleri → `docs/journal/YYYY-MM-DD.md` yazar:
- Tamamlananlar, yarım kalan işler, build/test durumu, yarına başlangıç noktası.

Commit etmez — kullanıcı açıkça istemediği sürece.

---

## Değişmeyen Anayasa: `docs/CONTEXT_MANAGEMENT.md`

Her projeye aynı dosya kopyalanır — bağlam yönetimi ilkeleri, 200 satır eşiği, compact/clear/resume kullanım kuralları, Ralph pattern, git disiplini. **Her projenin kök referansı.**

---

## Güncelleme

Template'te iyileştirme olduğunda projelere yaymak için:

```powershell
pwsh bootstrap.ps1 -ProjectPath "D:\Dev\proje" -Update
```

```bash
bash bootstrap.sh --path /d/Dev/proje --update
```

`-Update` / `--update` modu: **proje-özel dosyaları** (CLAUDE.md, TODO.md, project/*.md, journal, settings.json) **ASLA ezmez**. Sadece universal rules + stack rules + hook + skill + agent + CONTEXT_MANAGEMENT.md güncellenir.

Toplu güncelleme:

```bash
for p in my-api my-web my-cli; do
  bash bootstrap.sh --path "/d/Dev/$p" --update
done
```

---

## Docs

- [`docs/USAGE.md`](docs/USAGE.md) — kurulum, hook detayları, günlük workflow, SSS, bol örnek
- [`docs/PATTERNS.md`](docs/PATTERNS.md) — 10 real-world pattern (P-1..P-10), ReportHub pilot dersleri
- [`templates/docs/CONTEXT_MANAGEMENT.md`](templates/docs/CONTEXT_MANAGEMENT.md) — bağlam yönetimi anayasası

---

## Katkı

Template'e iyileştirme PR'ı açmak için:
1. Bu repo'yu clone
2. `templates/` altında değişiklik yap
3. `bin/bootstrap.sh` / `.ps1` test et: `bash bootstrap.sh --path /tmp/test-proj --stack dotnet-mvc`
4. Kurulan yapıyı gözden geçir
5. PR aç — değişiklik real-world pattern'ına dayanıyorsa `docs/PATTERNS.md`'ye yeni pattern ekle.

---

## Lisans

İç kullanım. Gerekirse private repo / takım dağıtımı.
