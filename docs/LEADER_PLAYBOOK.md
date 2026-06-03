# Leader Playbook — Template'i Ekibe Dağıtma & Yönetme

> **Kime?** Bu sistemi bir ekibe yayacak, standardı kuracak ve sürdürecek kişi (sen).
> **Söz:** Bu doküman bittiğinde; kurulumu, sürüm yönetimini, onboarding'i, governance'ı ve sorun gidermeyi **tek başına** yönetebilirsin.

İçindekiler:
- [0. Eldeki gerçek araçlar (envanter)](#0-eldeki-gerçek-araçlar)
- [1. Rollout stratejisi (pilot → yaygın)](#1-rollout-stratejisi)
- [2. Kurulum komutları](#2-kurulum-komutları)
- [3. Sürüm yönetimi (CHANGELOG + VERSION)](#3-sürüm-yönetimi)
- [4. Güncelleme: --update nasıl çalışır](#4-güncelleme)
- [5. Toplu güncelleme (tüm projeler)](#5-toplu-güncelleme)
- [6. Ekip onboarding](#6-ekip-onboarding)
- [7. Governance — kural/skill/agent yaşam döngüsü](#7-governance)
- [8. Standart belirleme (zorunlu vs opsiyonel)](#8-standart-belirleme)
- [9. Sorun giderme](#9-sorun-giderme)
- [10. Checklist'ler](#10-checklistler)

---

## 0. Eldeki gerçek araçlar

Bunlar **şu an repoda mevcut ve çalışıyor** (doğrulandı):

| Araç | Yer | Ne yapar |
|---|---|---|
| `bootstrap.ps1` | `bin/` | Windows/PowerShell kurulum + güncelleme |
| `bootstrap.sh` | `bin/` | Unix/Git Bash/WSL kurulum + güncelleme |
| `--update` modu | her iki script | Proje-özel'e dokunmadan template katmanını günceller |
| 14 evrensel kural | `templates/.claude/rules/_universal/` | Her projeye kopyalanır |
| 4 stack | `templates/.claude/rules/stacks/` | `dotnet-mvc`, `nodejs-typescript`, `python-generic`, `ai-powered` |
| Hook'lar | `templates/.claude/hooks/` | session-start, pre-commit-antipattern, post-commit-journal |
| Skill + agent | `templates/.claude/{skills,agents}/` | handoff, plan-tracker, commit-splitter |
| `CHANGELOG.md` + `VERSION` | repo kök | **YENİ** — sürüm takibi (bu playbook ile eklendi) |
| `bin/update-all.sh` | `bin/` | **YENİ** — kayıtlı tüm projeleri tek komutla günceller |

---

## 1. Rollout stratejisi

Tüm ekibe aynı anda dağıtma. **3 dalga**:

### Dalga 1 — Pilot (1 hafta)
- 1 proje + 1-2 istekli geliştirici seç.
- Template kur, gerçek işte kullan, sürtünmeyi not et.
- Proje-özel kuralları (`.claude/rules/project/`) bu projede doldur — referans olur.

### Dalga 2 — Erken benimseyenler (2 hafta)
- 3-5 proje. Pilot'tan öğrenilen sürtünmeleri gider.
- Stack başına bir örnek proje çıkar (dotnet, node, python).
- İlk **governance toplantısı**: hangi kural işe yaradı, hangisi gürültü.

### Dalga 3 — Yaygınlaştırma
- Kalan tüm projeler.
- Onboarding dökümanları (PDF seti) zorunlu okuma.
- `update-all.sh` ile merkezi güncelleme ritmi başlar.

> **Anti-pattern:** Hepsine birden zorla kurma. Pilot'suz rollout = ekip direnci + yanlış kuralların her yere yayılması.

---

## 2. Kurulum komutları

### Yeni proje
```powershell
# Windows
pwsh D:\Dev\claude-context-template\bin\bootstrap.ps1 `
  -ProjectPath "D:\Dev\yeni-proje" -ProjectName "YeniProje" -Stack dotnet-mvc
```
```bash
# Unix / Git Bash
bash /d/Dev/claude-context-template/bin/bootstrap.sh \
  --path /d/Dev/yeni-proje --name YeniProje --stack nodejs-typescript
```

### Mevcut projeye ekleme
Aynı komut. Script mevcut `.gitignore`'a append eder, `settings.json` varsa dokunmaz (uyarır), `CLAUDE.md`/`TODO.md` varsa atlar.

### Seçenekler (leader'ın bilmesi gerekenler)
| Bayrak | Etki |
|---|---|
| `-Stack` / `--stack` | `dotnet-mvc` · `nodejs-typescript` · `python-generic` · `ai-powered` · `none` |
| `--no-turkish` | Türkçe UI kuralını ekleme (İngilizce ekip) |
| `--enable-precommit-hook` | Antipattern hook'u AKTİF başlat (greenfield'de pasif default) |
| `--update` | Sadece template katmanını güncelle (bkz. §4) |
| `--force` | Mevcut dosyaların üzerine yaz (TEHLİKELİ — yedek al) |

---

## 3. Sürüm yönetimi

Ekibe dağıtırken **"hangi projede hangi sürüm var?"** sorusunu cevaplayabilmelisin. Bu yüzden:

- `VERSION` — template'in mevcut sürümü (tek satır, ör. `1.2.0`).
- `CHANGELOG.md` — her sürümde ne değişti.

### Sürüm artırma kuralı (SemVer benzeri)
| Değişiklik | Artış | Örnek |
|---|---|---|
| Yeni kural/skill/agent/stack | MINOR | 1.2 → 1.3 |
| Mevcut kural içeriği iyileştirme | PATCH | 1.2.0 → 1.2.1 |
| Kural kaldırma / kırıcı yapı değişimi | MAJOR | 1.x → 2.0 |

### Proje hangi sürümde?
Kurulumda template `VERSION`'ı projeye not düşülebilir. Hızlı kontrol:
```bash
# Projede son güncelleme tarihini gör
git -C /d/Dev/proje log -1 --format=%cd -- .claude/rules/_universal/
```

> Pratik: `--update` çalıştırınca commit mesajına template sürümünü yaz: `chore: template güncelleme (v1.3)`.

---

## 4. Güncelleme

`--update` modu **iki kategoriyi ayırır**:

| Güncellenir ✓ | Dokunulmaz ✗ (proje-özel) |
|---|---|
| `_universal/*.md` (14 kural) | `CLAUDE.md` |
| `stacks/<stack>/*.md` | `TODO.md` |
| Hook script'leri | `.claude/rules/project/*.md` |
| Skill + agent | `docs/journal/*` |
| `docs/CONTEXT_MANAGEMENT.md` | `.claude/settings.json` (elle merge) |

```bash
bash bootstrap.sh --path /d/Dev/proje --update
```

> **Kritik:** `settings.json` `--update` ile **değişmez**. Yeni hook eklediysen ekip projelerinde `settings.json`'a elle eklenmeli (bkz. §9).

---

## 5. Toplu güncelleme

Tüm ekip projelerini tek komutla güncelle: `bin/update-all.sh` (bu playbook ile eklendi).

```bash
# Proje listesini düzenle, sonra:
bash bin/update-all.sh
```

Liste dosyası: `bin/projects.txt` (her satır bir proje yolu). Örnek:
```
/d/Dev/reporthub
/d/Dev/fifo
/d/Dev/operax
```

> Güncelleme sonrası her projede smoke: `claude` aç → SessionStart hook çalışıyor mu, kurallar yükleniyor mu.

---

## 6. Ekip onboarding

Yeni geliştiriciye **bu sırayla** ver (hepsi `docs/` altında, PDF):

1. `acemi/Claude_Code_Acemi_Rehberi.pdf` — sıfırdan ilk oturum (zorunlu, 25 dk).
2. `sunum/Claude_Egitim_Sunumu.pdf` — neden bu sistem var (eğitim, 20 dk).
3. `seviye/Claude_Code_Ustalik_Yolu.pdf` — seviye yolu (Acemi→Plus).
4. Ortamına göre: `desktop/` · `chat/` · `cowork/` rehberi.
5. Senior olunca: `PROJE_OZEL_*.md` (skill/agent/hook yazma).

### Onboarding ritmi
- **Gün 1:** acemi PDF + ilk gözetimli oturum.
- **Hafta 1:** komutları kullanır (Junior).
- **Ay 1:** ilk proje-özel kuralını yazdırır (Senior'a geçiş).

---

## 7. Governance

Template canlı bir organizma — bakımsız kalırsa zarar verir.

### Aylık review (30 dk)
1. **Stale tarama:** Son 2 ayda tetiklenmeyen skill/agent var mı? → emekli et.
2. **Tekrarlanan acı:** Ekipte aynı hata 2+ projede çıktı mı? → yeni evrensel kural.
3. **Gürültü:** Bir kural sürekli yanlış tetikliyor / şikayet alıyor mu? → daralt/kaldır.
4. **Sürüm:** Değişiklik varsa `VERSION` + `CHANGELOG` güncelle, `update-all`.

### Kural/skill yaşam döngüsü
```
Doğ (2. acıda) → Büyü (kullanımda iyileştir) → Birleş (örtüşeni tek yap) → Emekli (geçersizse sil)
```

> **Altın kural:** Stale skill = aktif zarar (yanlış yönlendirir). "Belki lazım olur" diye tutma — sil, git history'de durur.

### Katkı akışı (ekip kural önerirse)
1. Önce kendi projesinde dene (`.claude/rules/project/`).
2. 2+ projede işe yaradıysa → template `_universal/`'e terfi (PR).
3. `bootstrap` listesine ekle + `CHANGELOG` + `update-all`.

---

## 8. Standart belirleme

Ekip için neyin **zorunlu** neyin **opsiyonel** olduğunu sen kararlaştırırsın.

### Önerilen zorunlu çekirdek (her projede)
- `session-protocol`, `commit-discipline`, `security-principles`, `session-memory`
- `test-discipline`, `todo-verification`, `before-major-change`
- Hook: session-start (zorunlu), post-commit-journal (zorunlu)

### Duruma göre opsiyonel
- `turkish-ui` (Türkçe UI projeleri)
- `pre-commit-antipattern` hook (olgun projelerde aç, greenfield'de kapat)
- Stack kuralları (projenin stack'ine göre)
- `llm-council`, proje-özel skill/agent

### Kararı yaz
Ekip standardını `docs/TEAM_STANDARD.md` gibi bir dosyaya yaz (template'e değil, ekip repo'suna). "Bizim ekipte şu kurallar zorunlu, şu hook açık."

---

## 9. Sorun giderme

| Belirti | Çözüm |
|---|---|
| `settings.json` mevcut, hook eklenmedi | `--update` settings'e dokunmaz. Hook kaydını elle ekle (aşağıda). |
| SessionStart hook çalışmıyor | `bash .claude/hooks/session-start.sh` elle test; chmod +x kontrol. |
| Pre-commit hep bloklu (greenfield) | Default pasif olmalı; `settings.json`'dan `PreToolUse`'u kaldır veya `CLAUDE_PRECOMMIT_SKIP=1`. |
| Toplu update bir projede patladı | `update-all.sh` o projeyi atlar, raporlar; tek tek `--update` ile bak. |
| Proje hangi sürümde belirsiz | `git log` ile `.claude/rules/_universal/` son commit; ileride VERSION not düş. |

### Hook kaydı (settings.json elle merge)
```json
{
  "hooks": {
    "SessionStart": [{ "hooks": [{ "type":"command", "command":"bash .claude/hooks/session-start.sh" }] }],
    "PostToolUse":  [{ "matcher":"Bash", "hooks":[{ "type":"command", "command":"bash .claude/hooks/post-commit-journal.sh" }] }]
  }
}
```

---

## 10. Checklist'ler

### ✅ Yeni proje rollout
- [ ] `bootstrap` doğru stack ile çalıştı
- [ ] `CLAUDE.md` §1 dolduruldu (proje kimliği)
- [ ] `.claude/rules/project/*.md` projeye göre dolduruldu
- [ ] `TODO.md` Faz 0/1 gerçek işle dolduruldu
- [ ] `claude` açıldı, SessionStart hook çalıştı (smoke)
- [ ] İlk commit + journal otomatik yazıldı (post-commit hook smoke)

### ✅ Toplu güncelleme
- [ ] `CHANGELOG`'a değişiklik yazıldı, `VERSION` artırıldı
- [ ] `bin/projects.txt` güncel
- [ ] `update-all.sh` çalıştı, rapor temiz
- [ ] Hook eklendi ise her projede `settings.json` merge edildi
- [ ] 1-2 projede smoke (oturum aç)

### ✅ Aylık governance
- [ ] Stale skill/agent tarandı, emekli edilenler silindi
- [ ] Tekrarlanan acı → yeni kural değerlendirildi
- [ ] Gürültü yapan kural daraltıldı/kaldırıldı
- [ ] Onboarding dökümanları güncel mi kontrol

### ✅ Yeni dev onboarding
- [ ] acemi PDF okutuldu + ilk gözetimli oturum
- [ ] Eğitim sunumu izletildi
- [ ] Ortam rehberi (desktop/chat/cowork) verildi
- [ ] İlk hafta sonu komutları kullanabiliyor (Junior teyit)

---

### İlişkili
- [`USAGE.md`](USAGE.md) — bootstrap detayları, SSS.
- [`GELISTIRICI_REHBERI.md`](GELISTIRICI_REHBERI.md) — araç kataloğu.
- [`PROJE_OZEL_OLUSTURMA.md`](PROJE_OZEL_OLUSTURMA.md) — yeni skill/agent/hook yazma.
- PDF seti: `docs/{acemi,seviye,desktop,chat,cowork,sunum}/`.
