# claude-context-template (→ Norma) — kuralların tek merkezi (v1.8.2)

**BKM'nin bütün depolarının doğuştan aldığı çalışma disiplini: 19 evrensel kural, kapılar ve ortak sözlük — tek yerde.**
Kural bir depoya kopyalanmaz, işaret edilir; kopyalanan kural bayatlar ve iki gerçek doğar. Depo adı yakında **Norma** (Latince: ölçü, kural) olacak.

*v1.8.2 · 19 kural · ak liste 3.067 sözcük · 37 tüketici depo.*

## Ne var

- **`templates/.claude/rules/_universal/`** — evrensel kurallar: kanıt disiplini (ölç, sonra yaz), plan-first, commit disiplini, hata yönetimi, test
  disiplini, dosya boyutu, ayak izi merdiveni, güvenlik, oturum protokolü, Türkçe UI ve **adlandırma standardı** (`naming-conventions.md`: dil ·
  dil başına tek biçim · bileşen adı önekli kebab · sözleşme çift yaşatma · zorlama tablosu).
- **`tools/turkce_tanimlayici_denetimi.py`** — adlandırma kapısı: C#, Razor, JS/TS, Python, PowerShell, SQL, CSS/HTML; Türkçe harf · Türkçe kök ·
  ak liste · biçim · bileşen katmanları; `--tabansiz` ("dokunulan dosya tamamen temiz"), `sozlesme_adlari` (tel/kolon adı borcu), test adları kapı dışı.
  `tools/kod-sozcukleri.txt` çekirdek sözlük — dilin sözcüğü buraya, alan adı tüketicinin ek dosyasına.
- **`bin/`** — `bootstrap` (yeni depo kurulumu), `harvest` (yerel kuralı merkeze terfi), `durum.sh` (ekosistem sapma ölçümü), `bildirim-dagit`.
- **`docs/TUKETICI-REHBERI.md`** — bir depo bu merkezi nasıl tüketir; **`CHANGELOG.md`** — her sürüm ölçümüyle.

## İlke

Kural metni davranış değiştirmez, **kapı** değiştirir. Bu depodaki her kural için ya bir kapı vardır ya da "kapısı yok — niyettir" yazılıdır; iki
tüketici aynı kusuru ölçmeden bir kural genelleşmez, bir kapı yanlış pozitif üretiyorsa kapı düzeltilir, bastırma öğretilmez.

## BKM Kitap yazılım omurgası — bu depo nerede duruyor

BKM Kitap'ta yazılım tek tek uygulamalar değil, birbirine oturan **katmanlar** olarak büyüyor. Beş depo, tek omurga:

| Katman | Depo | Görevi |
|---|---|---|
| **Kurallar** | [claude-context-template](https://github.com/fikrierenn/claude-context-template) (→ *Norma*) | Her deponun doğuştan aldığı 19 evrensel kural, kapılar, adlandırma standardı, 3.000+ sözcüklük ak liste. Kopyalanmaz, işaret edilir. |
| **Ortak .NET katmanı** | [Solum](https://github.com/fikrierenn/Solum) | Kimlik, yetki, çok kiracılılık, denetim izi, migrasyon, şema sapma doğrulaması — bir kez yazılır, her ürün referansla alır. |
| **Veri gerçeği** | [pusula](https://github.com/fikrierenn/pusula) | ERP · Encore · Zirve · panel şemalarının **ölçülmüş** tanımı (10.000+ satır YAML), 150+ sorgu, 40+ plan. Her rapor ve uygulama buradan beslenir; iki gerçek doğmaz. |
| **Ölçüm aracı** | [sqlcli](https://github.com/fikrierenn/sqlcli) | "İddia değil ölçüm": profilli SQL CLI, salt-okuma muhafızı, `assert`/`lookup`, çıkış sözleşmesi 0/1/2. Kapıların ve şemanın ölçüm eli. |
| **Ürünler** | [bkm-magaza](https://github.com/fikrierenn/bkm-magaza) ve diğerleri (vardiya, anlık ciro, etiket, el terminali…) | Sahada çalışan uygulamalar. İlk örnek bkm-magaza: ~200 mağaza personelinin telefonunda ürün bulma. |

**Yön (GMY, 2026):** bütün uygulamalar **tek kullanıcı ve yetki yönetimine** taşınır (Solum İSTEK-31: kişi → çalışma dönemi → hesap → cihaz;
kimlik İK sisteminden türer, işten çıkış uygulamayı kendiliğinden kapatır). Yeni bir uygulama bu omurgaya oturur; kendi kullanıcı tablosunu,
kendi kuralını, kendi şema kopyasını yazmaz.

**Çalışma ilkeleri (hepsi kapıyla zorlanır, niyet olarak bırakılmaz):** önce ölç, sonra yaz · kural değil kapı · sözleşme değişince eskisi bir sürüm
çift yaşar · kod İngilizce, insan dili Türkçe · hiçbir sır depoya girmez · her commit tek konu, her kapı sabotajla kırılabilir olduğunu kanıtlar.

---

## Ayrıntılar (teknik README, korunuyor)

### claude-context-template

**Her projede kullanılabilir, Claude Code için bağlam yönetimi şablon sistemi.**

Amaç: CLAUDE.md şişkinliği, session log karmaşası, uncommitted birikmesi, bağlam kopması gibi büyüyen projelerde yaşanan sorunları **sıfır günden itibaren** önlemek.

Kaynak: `D:/Dev/reporthub` (ReportHub) pilot projesinde canlı kurulup test edildi, proje-bağımsız hale getirildi.

- **Deploy / devir:** [`docs/DEPLOY.md`](docs/DEPLOY.md) — template'i temiz paketleyip ekibe verme (`python bin/package.py`)
- **Geliştirici kataloğu:** [`docs/GELISTIRICI_REHBERI.md`](docs/GELISTIRICI_REHBERI.md) — neyi nasıl tetiklerim (skill/agent/komut/hook/kural)
- **Somut senaryo:** [`docs/PROJE_OZEL_ORNEK_SENARYO.md`](docs/PROJE_OZEL_ORNEK_SENARYO.md) — ERP/fatura skill örneği: ne sağlar, sana ne yazdırırım (kopyala-yapıştır prompt)
- **Proje-özel kavram:** [`docs/PROJE_OZEL_KAVRAM.md`](docs/PROJE_OZEL_KAVRAM.md) — skill/agent/hook neden/niçin var, ne zaman doğar (zihinsel model)
- **Proje-özel oluşturma:** [`docs/PROJE_OZEL_OLUSTURMA.md`](docs/PROJE_OZEL_OLUSTURMA.md) — kendi domain'ine özel skill/agent/komut yazma (örnekli)
- **Detaylı kullanım:** [`docs/USAGE.md`](docs/USAGE.md)
- **Real-world örüntüler:** [`docs/PATTERNS.md`](docs/PATTERNS.md)
- **Ekibe anlatma rehberi:** [`docs/WORKFLOW_GUIDE.md`](docs/WORKFLOW_GUIDE.md) — sistemi meslektaşlara açıklamak için

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

## v1.3 Yeni Özellikler (11 Haziran 2026) — ECC Portu

[ECC](https://github.com/affaan-m/ECC) (MIT) deposundaki generic özellikler template kataloğuna uyarlandı:

- **13 agent** — planner, architect, build-error-resolver, tdd-guide, refactor-cleaner, performance-optimizer, e2e-runner, doc-updater, docs-lookup, database-reviewer + csharp/typescript/python reviewer'ları.
- **23 skill** — tdd-workflow, verification-loop, git-workflow, github-ops, search-first, codebase-onboarding, strategic-compact, context-budget, security-scan, api-design, backend/frontend-patterns, database-migrations, docker/deployment-patterns, e2e-testing, dotnet/python pattern'leri vb.
- **8 komut** — `/plan`, `/checkpoint`, `/build-fix`, `/refactor-clean`, `/test-coverage`, `/update-docs`, `/pr`, `/aside`.
- **2 hook (sh+ps1)** — `pre-bash-git-guard` (hook bypass + tehlikeli git komutları bloğu), `pre-config-protection` (linter config gevşetme bloğu).
- **11 kural** — evrensel `performance.md` + 10 stack kuralı (Türkçeye çevrildi).
- Bootstrap: hook kopyalama dinamik, tüm `.sh`/`.ps1` kurulur.

Katalog detayı: [`docs/GELISTIRICI_REHBERI.md`](docs/GELISTIRICI_REHBERI.md). ECC-altyapısına bağımlı parçalar (instinct, hookify, loop, sessions CLI) bilinçli port edilmedi.

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

Her stack'te aktif (`_universal/`), bootstrap hepsini kopyalar:

- `session-protocol.md` — **koşulsuz hook kuralı**, oturum başı/ortası/sonu ritüelleri
- `session-memory.md` — bağlam disiplin kuralları, 3 katman ayrımı
- `commit-discipline.md` — git/commit/branch-per-ask, 15 dosya eşiği
- `security-principles.md` — temel güvenlik (XSS, SQL, secrets)
- `coding-discipline.md` — Karpathy: spekülatif kod yasak, surgical changes
- `response-style.md` — özlülük, iltifat/adım-duyurusu yok
- `before-major-change.md` — silme/rename/refactor öncesi grep + cascade + onay
- `file-size-discipline.md` — yeni dosya < 300 satır, 500 = kırmızı çizgi
- `plan-first.md` — Tier 3 işte plan zorunlu
- `error-handling.md` — beklenen sonuç vs gerçek exception, sessiz yutma yasak
- `test-discipline.md` — "bitti" demeden önce test çalıştır (build ≠ test)
- `todo-verification.md` — TODO iddiasını canlı kodla doğrula, sonra fix
- `agent-usage.md` — subagent delegasyonu + model katmanlama (haiku/sonnet/opus)
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
