# claude-context-template

**Her yeni projede kullanılabilir, Claude Code için bağlam yönetimi şablon sistemi.**

Amaç: CLAUDE.md şişkinliği, session log karmaşası, uncommitted birikmesi, bağlam kopması gibi büyüyen projelerde yaşanan sorunları **sıfır günden itibaren** önlemek.

Kaynak: `D:/Dev/reporthub` (ReportHub) projesinde canlı kurulup test edildi, proje-bağımsız hale getirildi.

---

## Hızlı Kullanım

Yeni bir projede:

```powershell
# Windows
pwsh D:\Dev\claude-context-template\bin\bootstrap.ps1 `
  -ProjectPath "D:\Dev\yeni-proje" `
  -ProjectName "YeniProje" `
  -Stack "dotnet-mvc"
```

```bash
# Unix / Git Bash
bash D:/Dev/claude-context-template/bin/bootstrap.sh \
  --path /d/Dev/yeni-proje \
  --name YeniProje \
  --stack dotnet-mvc
```

Script yapar:
1. Hedef projede `CLAUDE.md` şablonunu placeholder doldurarak oluşturur
2. `.claude/rules/` klasörüne **universal** kuralları + seçili **stack** kurallarını kopyalar
3. `.claude/hooks/session-start.sh` kopyalar, çalıştırılabilir yapar
4. `.claude/skills/session-handoff/` kopyalar
5. `.claude/settings.json` (SessionStart hook kayıtlı) oluşturur
6. `docs/journal/`, `docs/ADR/` boş klasör + README
7. `TODO.md` şablonunu doldurur
8. `docs/CONTEXT_MANAGEMENT.md` (değişmeyen anayasa) kopyalar
9. Boş proje-özel rule dosyalarını (`.claude/rules/project/`) oluşturur

Sonuç: `cd yeni-proje && claude` çalıştırınca **her oturum başı otomatik hook devreye girer**, Claude son 3 gün durumunu, TODO'yu, uncommitted sayısını görür.

---

## Desteklenen Stack'ler

Şu an hazır:
- `dotnet-mvc` — ASP.NET Core MVC + EF Core + SQL Server (+opsiyonel Razor, Stored Procedure)
- `nodejs-typescript` — Node.js + TypeScript (Express / Fastify / Next.js agnostic)
- `python-generic` — Python 3 (Django / FastAPI / Flask agnostic)

Yeni stack eklemek için: `templates/.claude/rules/stacks/<ad>/` altına kural dosyaları koy, bootstrap script'e seçenek ekle.

---

## Mimarî — 3 Katman Ayrımı

Sistem, bağlam yönetimi anayasasının **3 katman ayrımı** ilkesine göre kurulu:

| Katman | Nerede | İçerik |
|---|---|---|
| **Kimlik** | `CLAUDE.md` (proje kök) | Proje tanımı, stack, ana klasörler, link indeksi. ~100-150 satır. |
| **Kurallar** | `.claude/rules/*.md` | Davranış kuralları, konu başına dosya. Universal + stack + project-özel. |
| **Süreç** | `TODO.md`, `docs/ADR/`, `docs/journal/` | Planlar, kararlar, oturum notları. |

Aynı bilgi **tam olarak bir yerde** yaşar.

---

## Evrensel Kurallar (`_universal/`)

Her stack'te aktif:
- `commit-discipline.md` — git/commit/branch-per-ask, 15 dosya eşiği
- `session-memory.md` — bağlam disiplin kuralları (CLAUDE.md şişmesin, journal'a yaz, vb.)
- `turkish-ui.md` — (opsiyonel) Türkçe UI projelerinde UTF-8, dil kuralları

Bootstrap script `-IncludeTurkish` flag'i ile Türkçe UI kuralını dahil eder/etmez.

---

## Stack Kuralları (`stacks/<name>/`)

Stack-özel, `paths:` frontmatter ile dosya bazlı aktif. Örnek `dotnet-mvc`:
- `csharp-conventions.md` (paths: `**/*.cs`)
- `razor-conventions.md` (paths: `**/*.cshtml`)
- `sql-conventions.md` (paths: `**/*.sql`)
- `js-conventions.md` (paths: `wwwroot/assets/js/**`)

---

## Proje-Özel Kurallar (`project/`)

Bootstrap script boş şablonları kopyalar, **her projede kendi içeriğini yazarsın**:
- `architecture.md` — projenin mimari durumu + bilinen tutarsızlıklar
- `security-principles.md` — proje-özel güvenlik notları (env var kullanımı, user filter, vb.)
- `known-issues.md` — AV / IT / platform-özel bilinen sorunlar

---

## Hook: SessionStart

`session-start.sh` her oturum başında çalışır, Claude'a şunları enjekte eder:
- Son 3 gün commit'ler
- Uncommitted dosya sayısı (15+ ise UYARI)
- Aktif TODO başlıkları
- En son journal girdisi (son 40 satır)
- Kritik kural dosya linkleri

Proje-bağımsız — sadece `$CLAUDE_PROJECT_DIR` veya cwd kullanır.

---

## Skill: session-handoff

`/handoff` ile çağrılır (veya "iyi geceler", "kaydet ve kapat", "handoff" gibi ifadelerle otomatik).
- `docs/journal/YYYY-MM-DD.md` üretir veya append eder.
- Tamamlanan, yarım kalan, kararlar, yarına başlangıç noktasını yazar.
- Proje-bağımsız.

---

## Değişmeyen Anayasa: `docs/CONTEXT_MANAGEMENT.md`

Her projeye aynı dosya kopyalanır — bağlam yönetimi ilkeleri, 200 satır eşiği, compact/clear/resume kullanım kuralları, Ralph pattern, git disiplini. Bu dosya **her projenin kök referansı**.

---

## Güncelleme

Kaynak template'te bir iyileştirme olunca (örn. yeni stack, hook iyileştirmesi), projelere yaymak için:

```powershell
pwsh D:\Dev\claude-context-template\bin\bootstrap.ps1 -Update -ProjectPath "D:\Dev\proje"
```

`-Update` modu: **proje-özel dosyaları** (CLAUDE.md, TODO.md, project/*.md, journal) **ASLA ezmez**. Sadece universal rules + stack rules + hook + skill + CONTEXT_MANAGEMENT.md güncellenir.

---

## Lisans

İç kullanım. GitHub private repo olarak taşınabilir.
