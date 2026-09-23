#!/usr/bin/env bash
# durum.sh — EKOSISTEM DURUMU: kim sabloni KOPYALIYOR, kim REFERANS veriyor, kim sapti.
#
# NEDEN VAR (2026-09-23): harvest.sh "SAPMA(3)" diyor ama SEBEBINI soylemiyor —
# kopya bayat mi, yoksa bilerek mi degistirilmis? Insan 19 dosyayi elle diff'lemek
# zorunda kaliyor ve bu yuzden kimse yapmiyor. Olculdu: turkish-ui.md 11 depoda,
# 10 FARKLI icerik; sapma 123 satira kadar cikiyor (farkli kusaklar).
#
# Bu script siniflandirir:
#   AYNI    kopya sablonla birebir
#   SAPMA   kopya var, icerik farkli (bayat ya da yerel degisiklik)
#   YEREL   sablonda olmayan kural (mesru olabilir)
#   -       kopya YOK (depo referans veriyor ya da o kurali kullanmiyor)
#
# Ve depo basina bir MODEL tahmini verir:
#   KOPYA     .claude/rules altinda sablon kurallarinin kopyalari var
#   REFERANS  kopya yok ama CLAUDE.md baska bir depodaki kurallara isaret ediyor
#             (olculmus saglikli desen: bkm-magaza — 0 kopya, 1 bilincli yerel kural)
#
# Cikis: 0 her zaman (rapor aracidir, kapi degil).
set -uo pipefail
KOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVREN="$KOK/templates/.claude/rules/_universal"
DEV="$(cd "$KOK/.." && pwd)"

[ -d "$EVREN" ] || { echo "KOSAMADI: kanonik kural dizini yok: $EVREN"; exit 2; }
SABLON_SAYI=$(ls "$EVREN"/*.md 2>/dev/null | wc -l)

echo "=== EKOSISTEM DURUMU ==="
echo "Sablon : $KOK (v$(cat "$KOK/VERSION" 2>/dev/null || echo '?')) · _universal $SABLON_SAYI kural"
echo "Kok    : $DEV"
echo
printf '%-22s %6s %6s %6s %6s  %s\n' "depo" "ayni" "sapma" "yerel" "toplam" "model"
printf '%-22s %6s %6s %6s %6s  %s\n' "----" "----" "-----" "-----" "------" "-----"

t_ayni=0; t_sapma=0; t_yerel=0; t_depo=0; t_referans=0
for d in "$DEV"/*/; do
  ad="$(basename "$d")"
  [ "$ad" = "claude-context-template" ] && continue
  [ -d "$d.claude" ] || continue
  t_depo=$((t_depo+1))

  ayni=0; sapma=0; yerel=0
  if [ -d "$d.claude/rules" ]; then
    for f in "$d.claude/rules"/*.md; do
      [ -f "$f" ] || continue
      n="$(basename "$f")"
      if [ -f "$EVREN/$n" ]; then
        if cmp -s "$f" "$EVREN/$n"; then ayni=$((ayni+1)); else sapma=$((sapma+1)); fi
      else
        yerel=$((yerel+1))
      fi
    done
  fi
  toplam=$((ayni+sapma+yerel))

  model="KOPYA"
  if [ "$((ayni+sapma))" = "0" ]; then
    if [ -f "$d/CLAUDE.md" ] && grep -qE '\.\./[A-Za-z0-9_-]+/\.claude/rules|kurallar.*komsu|KURALLAR BU DEPODA DEGIL|KURALLAR BU DEPODA DEĞİL' "$d/CLAUDE.md" 2>/dev/null; then
      model="REFERANS"; t_referans=$((t_referans+1))
    else
      model="-"
    fi
  fi

  printf '%-22s %6d %6d %6d %6d  %s\n' "$ad" "$ayni" "$sapma" "$yerel" "$toplam" "$model"
  t_ayni=$((t_ayni+ayni)); t_sapma=$((t_sapma+sapma)); t_yerel=$((t_yerel+yerel))
done

echo
echo "TOPLAM: $t_depo depo · ayni $t_ayni · SAPMA $t_sapma · yerel $t_yerel · referans modeli $t_referans depo"
echo
echo "Sapmanin sebebi bu tablodan GORUNMEZ (bayat mi, bilerek mi). Siradaki adim:"
echo "  bash bin/harvest.sh --diff <dosya> <proje>   tek dosyanin farki"
