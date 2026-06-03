# Geliştirici Rehberi — Skill / Agent / Komut / Hook / Kural Kataloğu

> **Bu doküman kime?** `D:\Dev` altındaki projelerde Claude Code ile çalışan geliştiriciler.
> **Amaç:** "Şunu yapmak istiyorum, hangi şeyi nasıl tetiklerim?" sorusunu bana sormadan cevaplayın.
> Her satırda: **ne işe yarar · nasıl tetiklenir · ne döndürür**.

İçindekiler:

- [0. 30 Saniyede Karar Tablosu](#0-30-saniyede-karar-tablosu)
- [1. Temel Kavramlar](#1-temel-kavramlar)
- [2. Skill'ler (slash + doğal dil)](#2-skiller)
- [3. Agent'lar (subagent)](#3-agentlar)
- [4. Slash Komutları](#4-slash-komutları)
- [5. Hook'lar (otomatik)](#5-hooklar-otomatik)
- [6. Kurallar (`.claude/rules/`)](#6-kurallar)
- [7. Günlük Akış — Sabah / Gün İçi / Akşam](#7-günlük-akış)
- [8. Eşikler ve Otomatik Sinyaller](#8-eşikler-ve-otomatik-sinyaller)
- [9. Bir Projeye Sistemi Kurma / Güncelleme](#9-bir-projeye-sistemi-kurma--güncelleme)
- [10. SSS](#10-sss)

---

## 0. 30 Saniyede Karar Tablosu

| İstediğin şey | Tetikleyici | Tip |
|---|---|---|
| Oturum başında "nerede kaldık?" | `günaydın` / `nerede kaldık` | hook + skill |
| Gün sonu kaydet | `iyi geceler` / `/handoff` / `kaydet ve kapat` | skill |
| Çok adımlı işi plana dök | `planla` / `bu işleri kaydet` | skill (plan-tracker) |
| 15+ dosya birikti, böl | `commit-split` / `dosyaları böl` | agent (commit-splitter) |
| Zor mimari karar, kararsızım | `council this` / `hangi seçenek` / `pressure-test` | skill (llm-council) |
| Yazdığım kodu gözden geçir | `/code-check` | komut |
| Güvenlik denetimi yap | `/security-check` / `/security-review` | komut + agent |
| PR'ı baştan sona incele | `/review-pr <PR#>` | komut |
| CSS/Tailwind tutarlılığı | `/css-check` | komut |
| Yeni feature'ı mimariyle kur | `/feature-dev <açıklama>` | komut |
| Performans optimize et | "code-optimizer çağır" (.NET: `code-optimizer-dotnet`) | agent |
| Değişikliği gerçekten çalıştırıp doğrula | `/verify` | skill |
| Çok kaynaklı araştırma raporu | `/deep-research <soru>` | skill |
| CLAUDE.md'yi güncelle | `/revise-claude-md` | skill |

---

## 1. Temel Kavramlar

Dört farklı "tetiklenebilir şey" var. Farkı bilmek önemli:

| Tip | Nerede tanımlı | Nasıl çalışır | Kim çağırır |
|---|---|---|---|
| **Hook** | `.claude/hooks/*.sh` + `settings.json` | Olay tetikler (oturum başı, commit öncesi/sonrası) — **otomatik** | Harness |
| **Skill** | `.claude/skills/<ad>/SKILL.md` | `/<ad>` veya doğal dil ifadesi | Sen veya Claude |
| **Agent** | `.claude/agents/<ad>.md` | Ayrı bağlamda, izole görev yapan subagent | Genelde Claude (sen de isteyebilirsin) |
| **Komut** | `.claude/commands/<ad>.md` | `/<ad>` slash komutu | Sen |
| **Kural** | `.claude/rules/*.md` | Pasif — her oturumda context'e yüklenir, davranışı yönlendirir | — |

**Üç katman ayrımı** (her şeyin temeli):

| Katman | Dosya | İçerik |
|---|---|---|
| Kimlik | `CLAUDE.md` | Proje tanımı, stack, klasörler. ~200 satır altı. |
| Kural | `.claude/rules/*.md` | Kalıcı davranış kuralları. |
| Süreç | `TODO.md`, `docs/ADR/`, `docs/journal/` | Plan, karar, oturum notu. |

> **Aynı bilgi iki yerde yaşamaz.** Session log asla CLAUDE.md'ye yazılmaz — journal'a gider.

---

## 2. Skill'ler

Skill = belirli bir iş akışının reçetesi. `/<ad>` ile veya tablo­daki doğal dil ifadeleriyle tetiklenir.

### 2.1 `session-handoff` — Oturum sonu devir

| | |
|---|---|
| **Ne yapar** | Bugün yapılanları, build durumunu, yarım kalanları, yarına başlangıç noktasını `docs/journal/YYYY-MM-DD.md`'ye yazar. TODO.md'yi senkronlar (tamamlananları ✅ işaretler). Journal + TODO'yu **tek commit** atar. |
| **Tetik** | `/handoff` · `iyi geceler` · `kaydet ve kapat` · `devam edeceğiz` · `oturum sonu` |
| **Ters yön** | `günaydın` → en son journal'i okur, "nerede kaldık" özeti çıkarır (commit yok). |
| **Döndürür** | Journal dosyası + commit hash + 1 cümlelik özet. |
| **Commit eder mi?** | Evet — ama **sadece** journal + TODO.md. Başka hiçbir dosyaya dokunmaz. |

### 2.2 `plan-tracker` — Plan ↔ TODO.md senkronu

| | |
|---|---|
| **Ne yapar** | TodoWrite (oturum-içi geçici) durumu ile `TODO.md` (kalıcı) arasında köprü kurar. 3+ adımlı iş planlanınca maddeleri TODO.md'ye yazar; her madde bitince `[ ]` → `✅` + commit hash. |
| **Tetik** | `planla` · `todo güncelle` · `bu işleri kaydet` · uzun plan+implementation akışı başlayınca otomatik |
| **Tetiklenmez** | Tek adımlı trivial iş, soru-cevap. |
| **ID formatı** | Güvenlik `G-NN`, Mimari `M-NN`, Feature `F-NN`, Bug `B-NN`. |
| **Commit eder mi?** | Hayır — sadece yazar. Commit senin kararın. |

### 2.3 `llm-council` — 5 danışmanlı karar konseyi

| | |
|---|---|
| **Ne yapar** | Karpathy LLM Council metodolojisi. 5 paralel danışman (Contrarian, First Principles, Expansionist, Outsider, Executor) + anonim peer review + chairman sentezi. |
| **Ne zaman** | Gerçek belirsizlik + yüksek maliyetli karar: "PostgreSQL mi MongoDB mi?", "hangi modül önce?", "bu sprint mi?". |
| **Tetik** | `council this` · `war room` · `pressure-test` · `stress-test` · `hangi seçenek` · `doğru hamle mi` · `kararsız kaldım` |
| **Kullanma** | Basit evet/hayır, tek doğru cevaplı, stakes'siz sorular. Zaten onaylı planlar. |
| **Döndürür** | Council Verdict: uzlaşılan/çatışan noktalar, yakalanan blind spot'lar, net öneri + ilk adım. |

### 2.4 Yerleşik (built-in) skill'ler

Bu skill'ler Claude Code ile gelir, her projede kullanılabilir:

| Skill | Tetik | Ne yapar |
|---|---|---|
| `/verify` | `/verify` · "değişikliği doğrula" | Uygulamayı gerçekten çalıştırıp davranışı gözlemler. PR/fix doğrulama. |
| `/deep-research` | `/deep-research <soru>` | Çok kaynaklı web araştırması → çelişki kontrolü → atıflı rapor. Önce 2-3 soruyla scope daraltır. |
| `/security-review` | `/security-review` | Bekleyen değişikliklerde güvenlik denetimi. |
| `/code-review` | `/code-review [low\|med\|high\|ultra]` | Diff'i bug + sadeleştirme açısından inceler. `ultra` = bulutta multi-agent. |
| `/simplify` | `/simplify` | Değişen kodu sadeleştirir, fix uygular (bug aramaz — onun için `/code-review`). |
| `/init` | `/init` | Yeni CLAUDE.md oluşturur. |
| `/revise-claude-md` | `/revise-claude-md` | CLAUDE.md'yi oturum öğrenimleriyle günceller. |

---

## 3. Agent'lar

Agent = izole bağlamda çalışan subagent. Çoğu **proaktif** — Claude doğru anda kendi çağırır. Sen de açıkça isteyebilirsin: *"X agent'ını çağır"*.

> **Not:** Bootstrap varsayılan olarak sadece `commit-splitter`'ı kurar. Diğerleri template'te hazır — projeye ihtiyaca göre kopyalanır (bkz. §9).

### 3.1 Her zaman kurulu

#### `commit-splitter`
- **Ne yapar:** Uncommitted çalışma dizinini anlamlı bucket'lara böler, ardışık commit önerir + uygular.
- **Tetik:** `commit-split` · `dosyaları böl` · `uncommitted'i temizle` · `git status` 15 dosyayı aşınca (kural gereği yeni iş yasak).
- **Kural:** Asla `git add .` / `-A`. Bir commit = tek proje/konu. Secret/env stage'lenmez.

### 3.2 Güvenlik & Kalite (dil-bağımsız)

| Agent | Ne yapar | Ne zaman tetiklenir |
|---|---|---|
| `security-reviewer` | Defansif güvenlik denetimi. `file:line` + attack path + concrete fix snippet. Confidence ≥ 75 filtre. | Yeni endpoint / POST action / SQL / file upload / fetch sonrası, merge öncesi. |
| `api-auth-auditor` | API route taraması — auth eksikliği, açık endpoint, API key sızıntısı. | Yeni route yazılınca, oturum başı/sonu scan. |
| `code-reviewer` | Proje kılavuzu + stil + best-practice denetimi (CLAUDE.md'ye göre). | Kod yazıp commit/PR öncesi (proaktif). |
| `silent-failure-hunter` | Sessiz hata, yetersiz error handling, kötü fallback avı. | try/catch / fallback / error handling yazıldıktan sonra. |
| `comment-analyzer` | Yorumların kodla tutarlılığı, comment rot tespiti. | Büyük docstring/yorum eklendikten sonra, PR öncesi. |
| `type-design-analyzer` | Tip tasarımı — encapsulation, invariant ifadesi. Nicel puanlama. | Yeni tip eklenince, PR'da, tip refactor'ünde. |
| `pr-test-analyzer` | PR test coverage kalitesi + kritik boşluklar. | PR oluşturulduktan/güncellendikten sonra. |

### 3.3 Mimari & Keşif

| Agent | Ne yapar | Ne zaman |
|---|---|---|
| `code-architect` | Mevcut pattern'leri analiz edip feature için uygulama planı (oluşturulacak dosyalar, veri akışı, build sırası). | Yeni feature başlarken (bkz. `/feature-dev`). |
| `code-explorer` | Mevcut feature'ı derin analiz — execution path, mimari katmanlar, bağımlılıklar. | Tanımadığın koda dokunmadan önce. |
| `code-simplifier` | Karmaşık kodu sadeleştirme önerileri. | Refactor öncesi. |

### 3.4 Performans (stack-özel)

| Agent | Stack | Ne yapar |
|---|---|---|
| `code-optimizer` | TypeScript / Next.js | N+1, gereksiz re-render, bundle, memo eksikliği, async sızdırması. Diff çıktı. |
| `code-optimizer-dotnet` | ASP.NET Core + EF Core | N+1, `AsNoTracking`, async/sync sızdırması, SP timeout, allocation. Diff çıktı. |
| `bundle-guardian` | Next.js | Unused import, ağır bağımlılık, dynamic import fırsatı, First Load JS izleme. |
| `nextjs-component-reviewer` | Next.js App Router | client/server boundary, localStorage anti-pattern, loading state, hydration. |

**Doğru optimizer seçimi:** .NET projesi → `code-optimizer-dotnet`. Next.js/TS projesi → `code-optimizer`.

---

## 4. Slash Komutları

Komut = sen `/<ad>` yazarsın, Claude tanımlı akışı işletir.

| Komut | Ne yapar | Argüman |
|---|---|---|
| `/code-check` | Unstaged değişiklikleri kod kalitesi açısından inceler. | — |
| `/security-check` | Kapsamlı güvenlik denetimi — auth, key sızıntısı, validasyon, maliyet. | — |
| `/css-check` | CSS/Tailwind tasarım tutarlılığı + kalite denetimi. | — |
| `/review-pr` | Specialized agent'larla kapsamlı PR incelemesi. | `<PR#>` |
| `/feature-dev` | Codebase anlama + mimari odaklı rehberli feature geliştirme. | `<açıklama>` |

> Komut ile agent farkı: komut bir akışı başlatır (içinde birden çok agent çağırabilir); agent tek izole görev yapar.

---

## 5. Hook'lar (otomatik)

Hook'ları **sen tetiklemezsin** — olaylar tetikler. Bilmen yeterli.

### 5.1 `session-start.sh` — SessionStart

- **Tetik:** Oturum açılınca otomatik.
- **Enjekte eder:** Son 3 gün commit'ler · uncommitted sayısı (15+ ise UYARI) · aktif TODO başlıkları · her proje klasörünün son journal girdisi.
- **Kural:** Claude bunu context'te görse bile `bash .claude/hooks/session-start.sh`'ı **koşulsuz tekrar çalıştırır** (stale context riski). "Gördüm, atlıyorum" yasak.

### 5.2 `pre-commit-antipattern.sh` — PreToolUse (varsayılan pasif)

- **Tetik:** Her `git commit` öncesi staged dosyaları tarar.
- **Yakalar:** Hardcoded `Password=...` · (.cs) `DateTime.Now`, `async void`, `new HttpClient()`, `ex.Message` sızıntı · (.ts/.js) `console.log`, `any` · (.py) `print(`, bare `except:`.
- **İhlal → commit blok.** Bypass: `CLAUDE_PRECOMMIT_SKIP=1 git commit ...`.
- **Greenfield'de pasif başlar.** Aç: bootstrap `-EnablePreCommitHook` veya `settings.json` elle.

### 5.3 `post-commit-journal.sh` — PostToolUse

- **Tetik:** Başarılı `git commit` sonrası.
- **Yapar:** `docs/journal/YYYY-MM-DD.md`'ye commit hash + subject + dosya listesi append.

---

## 6. Kurallar

`.claude/rules/` altındaki `.md` dosyaları her oturumda context'e yüklenir. Sen tetiklemezsin — Claude'un davranışını yönlendirir. Bilmen gerekenler:

### Evrensel (`_universal/`, her projede)

| Dosya | Özet |
|---|---|
| `session-protocol.md` | Oturum başı/orta/sonu ritüelleri. Koşulsuz hook kuralı. |
| `commit-discipline.md` | Kullanıcı istemeden commit yok · 1 commit = 1 konu · 15 dosya eşiği · zararlı git komutları onay ister. |
| `session-memory.md` | 3 katman ayrımı · CLAUDE.md 200 satır · compact/clear/resume. |
| `security-principles.md` | Secrets env'de · parametreli SQL · XSS/CSRF/auth/hashing temelleri. |
| `coding-discipline.md` | Karpathy: spekülatif kod yasak · surgical changes · sadece istenen satıra dokun. |
| `response-style.md` | Özlülük · iltifat yok · adım duyurusu yok. |
| `before-major-change.md` | Silme/rename/refactor öncesi grep + cascade kontrol + kullanıcı onayı. |
| `file-size-discipline.md` | Yeni dosya < 300 satır · 500 = kırmızı çizgi. |
| `plan-first.md` | Tier 3 işte (3+ dosya/yeni pattern/geri alınması zor) **plan zorunlu**. |
| `error-handling.md` | Beklenen sonuç (Result) vs gerçek exception · sessiz yutma yasak. |
| `test-discipline.md` | "Bitti" demeden test çalıştır · build ≠ test · regression test yaz. |
| `todo-verification.md` | TODO iddiasını canlı kodla doğrula, sonra fix · stale-claim yakala. |
| `agent-usage.md` | Subagent delegasyonu + model katmanlama (haiku/sonnet/opus) · salt-okuma. |
| `turkish-ui.md` | UI metni Türkçe + UTF-8 · kod İngilizce. (`--no-turkish` kapatır.) |

### Stack-özel (`stacks/<ad>/`)

- `dotnet-mvc/` → csharp / razor / sql / js conventions
- `nodejs-typescript/` → ts conventions
- `python-generic/` → python conventions
- `ai-powered/` → AI/LLM konvansiyonları (model seçimi, maliyet takibi, Zod validasyon, retry)

### Proje-özel (`project/`, sen doldurursun)

`architecture.md` · `security-principles.md` · `known-issues.md` — bootstrap placeholder koyar, içeriği proje ekibi yazar.

> **Yeni kural mı söyleyeceksin?** Claude'a "şunu aklında tut" deme — ilgili `.claude/rules/*.md`'ye **yazdır**. Konuşma hafızasından kural çekilmez (compact sonrası kaybolur).

---

## 7. Günlük Akış

### Sabah
```bash
cd D:\Dev\<proje>
claude
```
SessionStart hook özet enjekte eder. `günaydın` dersen son journal'dan "nerede kaldık" özeti gelir.

### Gün içi
- Yeni feature → `/feature-dev <açıklama>` (mimari önce).
- Tanımadığın koda dokunacaksan → "code-explorer çağır".
- Kod yazdın → `/code-check` veya code-reviewer otomatik girer.
- Güvenlik-hassas kod (endpoint, SQL, upload) → `/security-check`.
- Kararsız mimari seçim → `council this`.
- Uncommitted > 15 → **dur**, `commit-split`.
- Yeni kural → `.claude/rules/`'a yazdır.
- Mimari karar → `docs/ADR/NNN-konu.md`.

### Akşam
```
iyi geceler          # veya /handoff
```
session-handoff journal'a yazar + TODO senkronlar + tek commit atar.

---

## 8. Eşikler ve Otomatik Sinyaller

| Sinyal | Aksiyon |
|---|---|
| Uncommitted > 15 | Yeni iş yasak → `commit-split` |
| CLAUDE.md > 200 satır | `.claude/rules/`'a böl |
| Aynı hatayı 2. kez | Rule/skill yaz |
| 3+ paralel feature branch | Biri bitene kadar yeni başlatma |
| 30+ gün eski TODO | Ya yap ya sil |
| Tier 3 iş (3+ dosya/yeni pattern) | Plan zorunlu (`plan-first.md`) |
| Yeni dosya > 300 satır | Önce parçala |
| Silme/rename/refactor | `before-major-change.md` çek-listesi |

---

## 9. Bir Projeye Sistemi Kurma / Güncelleme

### Yeni kurulum
```powershell
pwsh D:\Dev\claude-context-template\bin\bootstrap.ps1 `
  -ProjectPath "D:\Dev\<proje>" `
  -ProjectName "<Ad>" `
  -Stack dotnet-mvc      # nodejs-typescript | python-generic | none
```

Kurar: universal + stack rules · 3 hook · commit-splitter agent · session-handoff + plan-tracker skill · settings.json · CONTEXT_MANAGEMENT.md · journal/ADR klasörü · CLAUDE.md + TODO.md şablonu.

### Güncelleme (template iyileşti → projelere yay)
```powershell
pwsh bootstrap.ps1 -ProjectPath "D:\Dev\<proje>" -Update
```
`-Update`: universal + stack + hook + skill + agent günceller. **Proje-özel dosyalara (CLAUDE.md, TODO.md, project/*, journal, settings.json) dokunmaz.**

### Ekstra agent/komut/skill ekleme

Bootstrap her şeyi kurmaz. İhtiyaca göre template'ten kopyala:
```powershell
# Örnek: security-reviewer agent + security-check komutu ekle
Copy-Item D:\Dev\claude-context-template\templates\.claude\agents\security-reviewer.md `
  D:\Dev\<proje>\.claude\agents\
Copy-Item D:\Dev\claude-context-template\templates\.claude\commands\security-check.md `
  D:\Dev\<proje>\.claude\commands\
```
Mevcut template seçenekleri: §3 (agent), §4 (komut), §2 (skill) listelerine bak.

Detaylı kurulum/seçenekler: [`USAGE.md`](USAGE.md).

---

## 10. SSS

**S: `/handoff` ile "iyi geceler" arasında fark var mı?**
Hayır, ikisi de session-handoff'u tetikler. `günaydın` ise ters yön (okuma).

**S: Agent'ı ben mi çağırmalıyım, Claude mu?**
Çoğu proaktif — Claude doğru anda kendi çağırır. Emin değilsen açıkça iste: "security-reviewer çağır".

**S: Komut çalışmıyor / `/code-check` tanınmıyor.**
O komut o projeye kurulmamış. `.claude/commands/` içine template'ten kopyala (§9).

**S: Skill ile komut farkı ne?**
Skill doğal dille de tetiklenir (`iyi geceler`), komut sadece `/<ad>`. Skill genelde çok adımlı reçete, komut tek akış.

**S: Pre-commit hook neden bloklamıyor?**
Greenfield'de pasif başlar. Aç: `settings.json`'a `PreToolUse` bloğu ekle veya bootstrap'ta `-EnablePreCommitHook`.

**S: Yeni kural söyledim, neden bir sonraki oturumda unutuldu?**
Konuşma hafızasında değil dosyada yaşamalı. `.claude/rules/<konu>.md`'ye yazdır.

**S: Hangi optimizer'ı kullanayım?**
.NET → `code-optimizer-dotnet`. Next.js/TS → `code-optimizer`.

**S: `council this` ne zaman aşırı?**
Tek doğru cevaplı, düşük-riskli sorularda. O zaman direkt sor — konsey token israfı.

---

### İlişkili Dökümanlar
- [`PROJE_OZEL_OLUSTURMA.md`](PROJE_OZEL_OLUSTURMA.md) — **kendi projene** özel skill/agent/komut nasıl yazılır (örnekli).
- [`USAGE.md`](USAGE.md) — bootstrap kurulum detayları, hook iç işleyişi.
- [`PATTERNS.md`](PATTERNS.md) — real-world örüntüler.
- [`WORKFLOW_GUIDE.md`](WORKFLOW_GUIDE.md) — ekibe anlatma rehberi.
- [`../templates/docs/CONTEXT_MANAGEMENT.md`](../templates/docs/CONTEXT_MANAGEMENT.md) — bağlam yönetimi anayasası.
