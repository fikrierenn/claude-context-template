# Değişiklik Günlüğü

Template sürüm geçmişi. Ekibe dağıtım/güncelleme bu listeye dayanır.
Sürümleme: MINOR = yeni kural/skill/stack · PATCH = içerik iyileştirme · MAJOR = kırıcı değişim.

## [1.3.0] — 2026-06-11

ECC (github.com/affaan-m/ECC, MIT) deposu tarandı; generic kullanılabilir tüm özellikler template kataloğuna uyarlandı. ECC-altyapısına bağımlı parçalar (instinct, hookify, loop, sessions CLI, agentshield, node hook runtime) bilinçli dışarıda bırakıldı.

### Eklendi
- **13 yeni agent:** `planner`, `architect`, `build-error-resolver`, `doc-updater`, `e2e-runner`, `performance-optimizer`, `refactor-cleaner`, `tdd-guide`, `database-reviewer`, `docs-lookup` + dil-özel reviewer'lar (`csharp-reviewer`, `typescript-reviewer`, `python-reviewer`).
- **23 yeni skill:** süreç (tdd-workflow, verification-loop, git-workflow, github-ops, coding-standards, search-first, codebase-onboarding, architecture-decision-records, strategic-compact, context-budget, prompt-optimizer, production-audit, security-scan) + teknik pattern (api-design, backend-patterns, frontend-patterns, database-migrations, deployment-patterns, docker-patterns, e2e-testing, dotnet-patterns, python-patterns, python-testing).
- **8 yeni komut:** `/plan`, `/checkpoint`, `/build-fix`, `/refactor-clean`, `/test-coverage`, `/update-docs`, `/pr`, `/aside`. (`/plan` + `/pr` template'in `plans/NN-*.md` kuralına hizalandı.)
- **2 yeni hook (sh + ps1 çift platform):** `pre-bash-git-guard` (--no-verify / hooksPath bypass + force-push / reset --hard / clean -f bloğu) ve `pre-config-protection` (mevcut linter/formatter config gevşetme bloğu). Settings şablonlarına bağlandı; pre-commit-antipattern gibi pasif default.
- **1 yeni evrensel kural:** `performance.md` (önce ölç, N+1, cache invalidation, bundle, karmaşıklık).
- **10 yeni stack kuralı (Türkçeye çevrildi):** dotnet-mvc `csharp-{patterns,testing,security}` · nodejs-typescript `ts-{patterns,testing,security}` · python-generic `python-{patterns,testing,security,fastapi}`.

### Değişti
- Bootstrap hook kopyalama dinamikleşti: `templates/.claude/hooks/` altındaki tüm `.sh` + `.ps1` dosyaları kurulur (hardcoded 3'lü liste kalktı).
- Bootstrap evrensel kural listesine `performance.md` eklendi.
- `GELISTIRICI_REHBERI.md` kataloğu yeni agent/skill/komut/hook/kurallarla genişletildi.

## [1.2.0] — 2026-06-03

### Eklendi
- 4 yeni evrensel kural: `todo-verification`, `test-discipline`, `agent-usage`, `error-handling`.
- Bootstrap artık **14 evrensel kuralın tümünü** kopyalıyor (önceden yalnızca 4'ünü).
- Yazılımcı dökümantasyonu: `GELISTIRICI_REHBERI`, `PROJE_OZEL_KAVRAM`, `PROJE_OZEL_ORNEK_SENARYO`, `PROJE_OZEL_OLUSTURMA`.
- Görsel PDF rehber seti: acemi + seviye + desktop + chat + cowork + eğitim sunumu.
- `LEADER_PLAYBOOK.md` — ekibe dağıtma/yönetme rehberi.
- `VERSION` + `CHANGELOG.md` — sürüm takibi.
- `bin/update-all.sh` — kayıtlı tüm projeleri toplu güncelleme.

### Değişti
- Multi-project proje-adı hardcode'u tamamen kaldırıldı → tek `docs/journal/YYYY-MM-DD.md` (generic, tekil repo).
- `session-handoff`, `commit-splitter`, hook'lar, plan şablonları generic'leştirildi.

### Kaldırıldı
- Proje-adı bulaşmış stray root kurallar (`rules/{commit-discipline,plan-first,session-memory,session-protocol,sql-server-conventions}.md`).

## [1.1.0] — 2026-04-22

### Eklendi
- Koşulsuz hook kuralı (`session-protocol`), pre-commit antipattern hook, post-commit journal hook.
- `commit-splitter` subagent, Faz 0/1/2/3 TODO formatı, USAGE + PATTERNS dökümanları.
- `.gitignore` otomatik merge.

## [1.0.0] — başlangıç

### Eklendi
- İlk template: 3 katman ayrımı, evrensel kurallar, stack kuralları (dotnet-mvc/nodejs-typescript/python-generic), bootstrap.ps1/.sh, session-handoff skill, CONTEXT_MANAGEMENT anayasa.
