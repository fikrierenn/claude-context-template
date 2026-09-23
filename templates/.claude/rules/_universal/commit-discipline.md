# Git / Commit Disiplini

_Her projede aynen uygulanır. `paths:` yok — compact sonrası survive._

## Commit Kuralları

0. **Commit → TODO `[x]` aynı anda.** Bir TODO maddesini kapatan commit atılırken AYNI
   ANDA o madde `TODO.md`'de `[x] ✅ <tarih> (commit <hash>)` yapılır. Commit atıp TODO'yu
   açık bırakmak **yasak** — "yapıldı ama `[ ]`" birikiminin kök sebebi budur ve liste
   bir kez yalan söylemeye başlayınca hiçbir maddesine güvenilmez. İstisna yok.

1. **Kullanıcı açıkça istemedikçe commit etme.** "commit et", "commit'le", "git commit" net komut olmadan commit yok.
   - **İstisna:** `session-handoff` skill'i, yalnızca `docs/journal/YYYY-MM-DD.md` dosyasını otomatik commit eder (başka path'e dokunmaz). Gerekçe: handoff artifactı dosyaya yazılıp bırakılırsa her oturum başında uncommitted olarak görünür ve pre-commit hook gürültü yapar.
2. **Bir commit = bir konu.** AI 3 katman birden çıkarırsa → 3 ayrı commit.
3. **Save-point commit.** Test yeşil → hemen commit (iş yarım olsa bile, `WIP:` prefix).
4. **15 dosya eşiği.** `git status` uncommitted > 15 → **yeni iş yasak**, önce commit-split.
5. **Commit mesajı:**
   ```
   <tip>: <kısa özet>

   <detay — opsiyonel>
   ```
   Tipler: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `style`, `build`.

## Branch Stratejisi

- **main** → production.
- **feature branch** → bir kullanıcı talebi = bir branch (`feature/xyz`, `fix/abc`).
- İş bitince squash-merge main'e.
- **Branch-per-ask:** Yeni talep → yeni branch.

## Zararlı Komutlar (AÇIK ONAY olmadan YASAK)

- `git push --force` / `-f` — history yeniden yaz.
- `git reset --hard` — uncommitted iş uçar.
- `git clean -fd` — untracked siler.
- `git rebase -i` — interaktif, otomatik olmaz.
- `git checkout .` / `git restore .` — tüm değişiklikleri at.

Gerekirse sor: "Bu komutu çalıştırmam emin misin? Mevcut N dosya değişikliği kaybolacak."

### Yasak liste NİYETE bakmaz — kırmızı kip geri alma

Bir kapının kırılabilirliğini kanıtlamak iki adımdır: **sabotaj** ve **geri alma**.
Sabotajı dikkatle kuruyoruz; geri almayı **refleksle** yapıyoruz — ve yasak komut tam
oraya sızıyor.

**Ölçülmüş vaka:** boş bir kırmızı-kip commit'i geri alırken `git reset --hard HEAD~1`
çalıştırıldı ve çalışma dizinindeki **commit edilmemiş bir düzeltme** de silindi. Dosya
yeniden üretilebildi — ama "kayıp olmadı" bir tedbir değildir. Doğrusu `git reset --soft
HEAD~1` ya da `git revert`ti.

> Yasak listesi, komutun hangi **niyetle** yazıldığına bakmaz. *"Zararlı komut
> çalıştırmıyorum, bir kırmızı kip geri alıyorum"* cümlesi o listeyi geçersiz kılmaz.

**Geri alma çek-listesi:**
1. Sabotaj İZİ hâlâ duruyor mu? (duruyorsa geri alma koşmamıştır — ve yeşil kalan bir
   kırmızı kip "test kör" demek DEĞİLDİR; önce sabotajın uygulandığını ölç)
2. Geri alma yolu `--hard` / `checkout -- .` **içermiyor**.
3. Çalışma dizininde commit edilmemiş iş var mı? Varsa önce onu ayır.
4. Takımın **tamamı** yeniden koşturuldu mu (yalnız sabote edilen test değil).

## Commit-Split Pattern

Uncommitted > 15 olunca:
```bash
git status                           # ne değişmiş
git diff --stat                      # kaç satır
# Bucket'lara ayır, konu başına:
git add <file1> <file2>
git commit -m "feat: <konu>"
git log --oneline -10
```

Otomasyon: `commit-splitter` subagent (her projeye eklenebilir).

## Git Hook'ları (opsiyonel)

- **pre-commit (antipattern scan):** stack-bağımlı (ör. .NET: `DateTime.Now`, `async void`, `new HttpClient()`).
- **post-commit (journal):** `docs/journal/YYYY-MM-DD.md`'ye commit özeti.

Kurulacak: `.claude/hooks/` altına, `.claude/settings.json`'da kayıtlı.
