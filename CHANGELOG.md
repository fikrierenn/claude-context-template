# Değişiklik Günlüğü

Template sürüm geçmişi. Ekibe dağıtım/güncelleme bu listeye dayanır.
Sürümleme: MINOR = yeni kural/skill/stack · PATCH = içerik iyileştirme · MAJOR = kırıcı değişim.

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
