# Deploy / Devir Rehberi

> Template'i ekibe/başkasına **temiz** vermek için. Kişisel ve şişkin dosyalar (sunum, journal, node_modules, ikon setleri, PDF'ler) paketlenmez.

## Hızlı paketleme

```bash
# Sadece template dağıtımı (≈0.2 MB)
python bin/package.py

# + eğitim kiti (PDF + PPTX, ayrı zip ≈2 MB)
python bin/package.py --training
```

Çıktı: `dist/` altında
- `claude-context-template-v<VERSION>.zip` — dağıtılacak template
- `egitim-kit-v<VERSION>.zip` — (opsiyonel) acemi/seviye/ortam PDF'leri + eğitim sunumu

> `dist/` gitignore'lu — repoya girmez.

## Pakette NE VAR / NE YOK

| İçinde ✓ | Dışında ✗ (kişisel / şişme) |
|---|---|
| `templates/**` (.claude şablonu, 11 skill, hook, agent, kural, plans, ADR, CONTEXT_MANAGEMENT) | `docs/sunum/` (kişisel sunum + node_modules) |
| `bin/bootstrap.ps1/.sh`, `update-all.sh`, `projects.txt` | `docs/journal/` (oturum günlükleri) |
| `README`, `CHANGELOG`, `VERSION` | `docs/{acemi,seviye,desktop,chat,cowork}/` PDF'leri (eğitim kitine taşındı) |
| Rehber md'leri (GELISTIRICI, LEADER_PLAYBOOK, PROJE_OZEL_*, USAGE, PATTERNS, WORKFLOW) | `node_modules`, `_icons`, `_icons_red`, `__pycache__` |
| | `TUM_PROJE_KODLARI.txt`, `kodlari_topla_v2.bat` (eski dump) |
| | `bkm-sunum` skill (kullanıcı-seviyesi, BKM'ye özel — paylaşılmaz) |

Allowlist tabanlı: yeni kişisel dosya eklesen bile pakete sızmaz (sadece `bin/package.py` içindeki listede olanlar girer).

## Devralan ne yapacak (kısa)

1. Zip'i aç.
2. `README.md` oku → `docs/LEADER_PLAYBOOK.md` (kurulum + ekip yayılımı).
3. Kendi projesine kur:
   ```bash
   bash bin/bootstrap.sh --path /yol/proje --name Proje --stack none
   ```
4. İlk oturum: `cd proje && claude` → SessionStart hook devreye girer.

## Yeni dosya tipi pakete girsin istiyorsan

`bin/package.py` → `TEMPLATE_INCLUDE` listesine ekle. Hariç tutulacaksa `EXCLUDE`'a yaz.

## Sürüm

Devirden önce `VERSION` + `CHANGELOG.md` güncel mi kontrol et — zip adı `VERSION`'dan gelir.
