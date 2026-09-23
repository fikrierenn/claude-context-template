#!/usr/bin/env bash
# harvest.sh — projelerde olgunlasan yetenekleri sablona GERI tasir.
#
# NEDEN VAR:
# bootstrap.sh sablondan projeye akitiyor. Ters yon yoktu. Oysa iyilestirme
# isin yapildigi yerde doguyor: 11 Haziran 2026'dan bu yana pusula 48,
# Operax 35, reporthub 28, BkmArgus 6 commit atti .claude/ altina — sablon
# ise 0. Geri akacak yol olmayinca sablon geride kaldi, geride kalinca
# "update" calistirmak projeleri GERIYE alir hale geldi, ve kimse
# calistirmadi. projects.txt'in bos kalmasinin sebebi budur.
#
# Bu script o dongunun eksik ayagi.
#
# KULLANIM:
#   bash bin/harvest.sh --scan                     Neyin geride kaldigini listeler
#   bash bin/harvest.sh --diff <dosya> <proje>     Farki gosterir
#   bash bin/harvest.sh --promote <dosya> --from <proje> --to <hedef>
#
#   <hedef>: _universal | stacks/dotnet-mvc | stacks/nodejs-typescript
#            | stacks/python-generic | stacks/ai-powered
#            (kategori `tools` ise hedef yoksayilir: kapilar hep depo kokundeki
#             tools/ altina gider, katman yok)
#
# KATEGORILER: rules · skills · agents · hooks · commands · tools
#   `tools` = python/shell KAPILAR. `.claude` altinda degil, depo kokunde durur.
#
# SINIFLANDIRMAYI MAKINE YAPMAZ.
# Bir kuralin "evrensel" olup olmadigi yargidir. Script yalnizca YAYGINLIK
# OLCER — oneri URETMEZ (esik 23.09.2026'da kaldirildi: olculdu ki en yaygin
# dosyalarin yarisi stack kuralidir). Yaygin olmak evrensel olmanin kaniti
# degildir, yalnizca isaretidir; karari insan verir.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KOK="$(dirname "$SCRIPT_DIR")"
SABLON="$KOK/templates/.claude"
DEV_KOK="${HARVEST_DEV_KOK:-$(dirname "$KOK")}"

[ -d "$SABLON" ] || { echo "HATA: sablon bulunamadi: $SABLON"; exit 1; }

# ---------------------------------------------------------------------------
# Projeleri kesfet: .claude/rules olan her klasor (sablonun kendisi haric)
# ---------------------------------------------------------------------------
projeleri_bul() {
  local liste="$SCRIPT_DIR/projects.txt"
  local bulundu=0

  # Once projects.txt — yorum olmayan satirlar
  if [ -f "$liste" ]; then
    while IFS= read -r satir; do
      case "$satir" in ""|\#*) continue ;; esac
      [ -d "$satir/.claude" ] && { echo "$satir"; bulundu=1; }
    done < "$liste"
  fi

  # projects.txt bossa otomatik kesfet
  if [ "$bulundu" = "0" ]; then
    for d in "$DEV_KOK"/*/; do
      [ -d "$d/.claude" ] || continue
      case "$(basename "$d")" in
        claude-context-template|_archive) continue ;;
      esac
      echo "${d%/}"
    done
  fi
}

# Bir kategorinin PROJE tarafindaki dizini.
# ⚠ `tools` .claude ALTINDA DEGIL, depo kokunde durur (23.09.2026'da eklendi).
# Sebep olculdu: ekosistemin en olgun kapisi (`turkce_tanimlayici_denetimi.py`)
# `tools/` altindaydi ve harvest onu HIC gormuyordu — yani "geri akis yolu var"
# cumlesi kapilar icin YANLISTI ve ilk terfi ELLE yapilmak zorunda kaldi.
proje_dizin() {
  local kategori="$1" proje="$2"
  case "$kategori" in
    tools) echo "$proje/tools" ;;
    *)     echo "$proje/.claude/$kategori" ;;
  esac
}

# Sablonda bu dosya herhangi bir katmanda var mi? Varsa yolunu doner.
sablonda_bul() {
  local kategori="$1" ad="$2" y
  if [ "$kategori" = "tools" ]; then
    [ -f "$KOK/tools/$ad" ] && { echo "$KOK/tools/$ad"; return 0; }
    return 1
  fi
  for y in "$SABLON/$kategori/_universal/$ad" \
           "$SABLON/$kategori/$ad" \
           "$SABLON/$kategori"/stacks/*/"$ad" \
           "$SABLON/$kategori/project/$ad"; do
    [ -f "$y" ] && { echo "$y"; return 0; }
  done
  return 1
}

# ---------------------------------------------------------------------------
# --scan
# ---------------------------------------------------------------------------
tara() {
  local projeler; projeler=$(projeleri_bul)
  local proje_sayisi; proje_sayisi=$(echo "$projeler" | grep -c . || true)

  echo "=== HASAT TARAMASI ==="
  echo "Sablon : $KOK  (v$( [ -f "$KOK/VERSION" ] && cat "$KOK/VERSION" || echo '?' ))"
  echo "Proje  : $proje_sayisi"
  echo

  local kategori
  for kategori in rules skills agents hooks commands tools; do

    # Tum projelerdeki dosya adlarini topla
    local gecici; gecici=$(mktemp)
    local p
    while IFS= read -r p; do
      local pdizin; pdizin=$(proje_dizin "$kategori" "$p")
      [ -d "$pdizin" ] || continue
      # skill'ler klasor, digerleri dosya
      if [ "$kategori" = "skills" ]; then
        local s
        for s in "$pdizin"/*/; do
          [ -f "$s/SKILL.md" ] && echo "$(basename "${s%/}")|$p"
        done
      else
        local f
        for f in "$pdizin"/*; do
          [ -f "$f" ] && echo "$(basename "$f")|$p"
        done
      fi
    done <<< "$projeler" > "$gecici"

    [ -s "$gecici" ] || { rm -f "$gecici"; continue; }

    # Ada gore grupla
    local basildi=0
    local ad
    while IFS= read -r ad; do
      local n; n=$(grep -c "^$ad|" "$gecici" || true)
      local ilk;  ilk=$(grep -m1 "^$ad|" "$gecici" | cut -d'|' -f2)

      local sablon_yol=""
      sablon_yol=$(sablonda_bul "$kategori" "$ad" 2>/dev/null) || sablon_yol=""

      local durum oneri
      if [ -n "$sablon_yol" ]; then
        # Sablonda var — icerik sapmis mi
        local farkli=0 pp
        while IFS= read -r pp; do
          local proje_yol
          if [ "$kategori" = "skills" ]; then
            proje_yol="$pp/.claude/skills/$ad/SKILL.md"
            [ -f "$sablon_yol" ] || continue
          else
            proje_yol="$(proje_dizin "$kategori" "$pp")/$ad"
          fi
          [ -f "$proje_yol" ] || continue
          cmp -s "$proje_yol" "$sablon_yol" || farkli=$((farkli+1))
        done < <(grep "^$ad|" "$gecici" | cut -d'|' -f2)

        [ "$farkli" = "0" ] && continue          # senkron, raporlama
        durum="SAPMA($farkli)"
        oneri="--diff ile bak"
      else
        durum="SABLONDA YOK"
        # ⚠ ESIK KALDIRILDI (23.09.2026, GMY karari — OLCUMLE).
        # Onceki hali: 5+ depo -> "_universal adayi", 2+ -> "stacks/* adayi".
        # Olculdu: esigi gecen 8 dosyanin 4'u STACK kuralidir (csharp-conventions
        # 9 depo, razor-conventions 8, sql-conventions 7, phase-review-gate 6) —
        # yani otomatik etiket ~yari yaniltiyordu. Ve bu, bu scriptin KENDI
        # basligiyla celisiyordu: "Yaygin olmak evrensel olmanin KANITI degildir."
        # Artik sayi verilir, sinif INSANA birakilir.
        if   [ "$n" -ge 5 ]; then oneri="$n depo — sinifi SEN sec"
        elif [ "$n" -ge 2 ]; then oneri="$n depo — sinifi SEN sec"
        else                      oneri="1 depo — yerel gorunuyor"
        fi
      fi

      if [ "$basildi" = "0" ]; then
        echo "--- $kategori ---"
        printf "  %-30s %5s  %-14s %-18s %s\n" "dosya" "proje" "durum" "oneri" "ornek"
        basildi=1
      fi
      printf "  %-30s %5s  %-14s %-18s %s\n" \
             "$ad" "$n" "$durum" "$oneri" "$(basename "$ilk")"
    done < <(cut -d'|' -f1 "$gecici" | sort -u)

    [ "$basildi" = "1" ] && echo
    rm -f "$gecici"
  done

  cat <<'EOF'
Sonraki adim:
  bash bin/harvest.sh --diff <dosya> <proje>
  bash bin/harvest.sh --promote <dosya> --from <proje> --to _universal

Yaygınlık evrensellik KANITI degildir, isaretidir. Karari sen ver.
EOF
}

# ---------------------------------------------------------------------------
# --diff
# ---------------------------------------------------------------------------
fark() {
  local ad="$1" proje="$2"
  [ -d "$proje" ] || proje="$DEV_KOK/$proje"
  [ -d "$proje" ] || { echo "HATA: proje bulunamadi: $2"; exit 1; }

  local kategori proje_yol=""
  for kategori in rules skills agents hooks commands tools; do
    if [ "$kategori" = "skills" ] && [ -f "$proje/.claude/skills/$ad/SKILL.md" ]; then
      proje_yol="$proje/.claude/skills/$ad/SKILL.md"; break
    elif [ -f "$(proje_dizin "$kategori" "$proje")/$ad" ]; then
      proje_yol="$(proje_dizin "$kategori" "$proje")/$ad"; break
    fi
  done
  [ -n "$proje_yol" ] || { echo "HATA: '$ad' $proje icinde bulunamadi"; exit 1; }

  local sablon_yol; sablon_yol=$(sablonda_bul "$kategori" "$ad" 2>/dev/null) || sablon_yol=""

  if [ -z "$sablon_yol" ]; then
    echo "=== '$ad' sablonda YOK — tamami yeni ==="
    echo "Kaynak: $proje_yol"
    echo "Satir : $(wc -l < "$proje_yol")"
    echo
    head -30 "$proje_yol"
    echo "..."
  else
    echo "=== '$ad' farki ==="
    echo "  sablon: $sablon_yol"
    echo "  proje : $proje_yol"
    echo
    diff -u "$sablon_yol" "$proje_yol" || true
  fi
}

# ---------------------------------------------------------------------------
# --promote
# ---------------------------------------------------------------------------
terfi() {
  local ad="$1" proje="$2" hedef="$3"
  [ -d "$proje" ] || proje="$DEV_KOK/$proje"
  [ -d "$proje" ] || { echo "HATA: proje bulunamadi"; exit 1; }

  local kategori proje_yol="" dosya_adi="$ad"
  for kategori in rules skills agents hooks commands tools; do
    if [ "$kategori" = "skills" ] && [ -f "$proje/.claude/skills/$ad/SKILL.md" ]; then
      proje_yol="$proje/.claude/skills/$ad"; dosya_adi="$ad"; break
    elif [ -f "$(proje_dizin "$kategori" "$proje")/$ad" ]; then
      proje_yol="$(proje_dizin "$kategori" "$proje")/$ad"; break
    fi
  done
  [ -n "$proje_yol" ] || { echo "HATA: '$ad' bulunamadi"; exit 1; }

  local hedef_dizin="$SABLON/$kategori/$hedef"
  # hooks/commands katmansiz durur
  case "$kategori" in
    hooks|commands) hedef_dizin="$SABLON/$kategori" ;;
    tools)          hedef_dizin="$KOK/tools" ;;   # kapilar kokte, templates/ altinda DEGIL
  esac

  mkdir -p "$hedef_dizin"

  if [ -d "$proje_yol" ]; then
    cp -r "$proje_yol" "$hedef_dizin/"
    echo "TERFI: skills/$dosya_adi -> ${hedef_dizin#$KOK/}"
  else
    cp "$proje_yol" "$hedef_dizin/$dosya_adi"
    echo "TERFI: $kategori/$dosya_adi -> ${hedef_dizin#$KOK/}"
  fi

  cat <<EOF

Yapilacaklar:
  1) Icerigi PROJE-BAGIMSIZ hale getir (proje adi, yol, domain terimi temizle)
  2) VERSION dosyasini artir + CHANGELOG.md'ye satir ekle
  3) git commit
  4) bash bin/update-all.sh  (projects.txt dolu olmali)
EOF
}

# ---------------------------------------------------------------------------
case "${1:-}" in
  --scan)    tara ;;
  --diff)    [ $# -ge 3 ] || { echo "kullanim: --diff <dosya> <proje>"; exit 1; }
             fark "$2" "$3" ;;
  --promote)
             [ $# -ge 6 ] || { echo "kullanim: --promote <dosya> --from <proje> --to <hedef>"; exit 1; }
             dosya="$2"; from=""; to=""
             shift 2
             while [ $# -gt 0 ]; do
               case "$1" in
                 --from) from="$2"; shift 2 ;;
                 --to)   to="$2";   shift 2 ;;
                 *) shift ;;
               esac
             done
             [ -n "$from" ] && [ -n "$to" ] || { echo "HATA: --from ve --to zorunlu"; exit 1; }
             terfi "$dosya" "$from" "$to" ;;
  *)
    sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
    ;;
esac
