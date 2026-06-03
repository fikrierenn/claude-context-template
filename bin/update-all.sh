#!/usr/bin/env bash
# update-all.sh — kayitli tum projeleri template'in son surumune gunceller.
# Her proje icin: bootstrap.sh --update (proje-ozel dosyalara DOKUNMAZ).
#
# Kullanim:
#   1) bin/projects.txt'i duzenle (her satir bir proje yolu, # ile yorum).
#   2) bash bin/update-all.sh
#
# Cikti: her proje icin OK / ATLANDI / HATA + ozet.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP="$SCRIPT_DIR/bootstrap.sh"
LIST="$SCRIPT_DIR/projects.txt"
VERSION_FILE="$(dirname "$SCRIPT_DIR")/VERSION"
VERSION="$( [ -f "$VERSION_FILE" ] && cat "$VERSION_FILE" || echo "?" )"

[ -f "$BOOTSTRAP" ] || { echo "HATA: bootstrap.sh bulunamadi: $BOOTSTRAP"; exit 1; }
[ -f "$LIST" ]      || { echo "HATA: proje listesi yok: $LIST  (her satir bir proje yolu)"; exit 1; }

echo "=== Template toplu guncelleme (v$VERSION) ==="
ok=0; skip=0; fail=0; failed_list=""

while IFS= read -r line || [ -n "$line" ]; do
  # yorum/bos satir atla
  line="$(echo "$line" | sed 's/#.*//' | xargs 2>/dev/null || true)"
  [ -z "$line" ] && continue

  if [ ! -d "$line" ]; then
    echo "  ATLANDI (yol yok): $line"; skip=$((skip+1)); continue
  fi
  if [ ! -d "$line/.claude" ]; then
    echo "  ATLANDI (template kurulu degil): $line"; skip=$((skip+1)); continue
  fi

  echo ""
  echo ">>> $line"
  if bash "$BOOTSTRAP" --path "$line" --update >/tmp/update_out 2>&1; then
    echo "  OK"; ok=$((ok+1))
  else
    echo "  HATA (detay: /tmp/update_out son 5 satir):"
    tail -5 /tmp/update_out | sed 's/^/    /'
    fail=$((fail+1)); failed_list="$failed_list $line"
  fi
done < "$LIST"

echo ""
echo "=== Ozet: $ok OK · $skip atlandi · $fail hata ==="
[ -n "$failed_list" ] && echo "Hatali projeler:$failed_list"
echo ""
echo "Hatirlatma:"
echo "  - Yeni hook eklendiyse her projede .claude/settings.json elle merge edilmeli (--update settings'e dokunmaz)."
echo "  - 1-2 projede smoke: 'claude' ac, SessionStart hook calisiyor mu kontrol et."
echo "  - Guncelleme commit'inde surumu yaz: chore: template guncelleme (v$VERSION)"

[ "$fail" -eq 0 ]
