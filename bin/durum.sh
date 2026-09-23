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
#   KOPYA VAR .claude/rules altinda sablon kurallarindan EN AZ BIR kopya var.
#             ⚠ ORAN DEMEK DEGILDIR. Eskiden "KOPYA" yaziyordu ve bir tuketici
#             hakli olarak itiraz etti: kendi satiri `sapma 1 · yerel 12` idi,
#             yani 13 kuralin 12'si o deponun KENDI kurali — "KOPYA" etiketi
#             orani oldugundan buyuk gosteriyordu. Oran icin ayni/sapma/yerel
#             sutunlarina bak; bu sutun yalnizca "kopya var mi" sorusunu yanitlar.
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

t_ayni=0; t_sapma=0; t_yerel=0; t_depo=0; t_referans=0; t_referans_bos=0
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
        # ⚠ SATIR SONU YOKSAYILIR (23.09.2026). Eskiden `cmp -s` idi: Windows'ta
        # core.autocrlf ile checkout edilen bir kopya, ICERIGI AYNI olsa bile
        # "sapmis" sayilirdi — kapi kendi kor noktasini miras alir sinifi.
        # OLCULDU: bugun 169 sapmanin SIFIRI salt satir-sonu kaynakli, yani bu
        # degisiklik sayiyi DEGISTIRMIYOR. Yine de dogru olcut budur; aksi halde
        # yarin bir depo checkout edildiginde sayi sebepsiz siser.
        if diff -q --strip-trailing-cr "$f" "$EVREN/$n" >/dev/null 2>&1
        then ayni=$((ayni+1)); else sapma=$((sapma+1)); fi
      else
        yerel=$((yerel+1))
      fi
    done
  fi
  toplam=$((ayni+sapma+yerel))

  model="KOPYA VAR"
  if [ "$((ayni+sapma))" = "0" ]; then
    # ⚠ DESEN GENISLETILDI (Asama 2, 23.09.2026). Eski hali yalniz
    # `../<depo>/.claude/rules` bicimini taniyordu; merkezin kanonik yolu ise
    # `../<merkez>/templates/.claude/rules/...` — yani ARADA `templates/` var ve
    # eski desen onu KACIRIYORDU. Olculdu: bootstrap --reference ile kurulan bir
    # depo "REFERANS" degil "-" gorunurdu, yani Asama 2'nin sonucu kendi olcum
    # aracinda GORUNMEZDI. Kapinin olctugu sey, olcmesi gereken sey degildi.
    if [ -f "$d/CLAUDE.md" ] && grep -qE 'merkez-bildirimi|templates/\.claude/rules|\.\./[A-Za-z0-9_-]+/\.claude/rules|kurallar.*komsu|KURALLAR BU DEPODA DEGIL|KURALLAR BU DEPODA DEĞİL|KURALLAR ARTIK MERKEZDE' "$d/CLAUDE.md" 2>/dev/null; then
      model="REFERANS"; t_referans=$((t_referans+1))
      # Hic kurali olmayan depo da bu testi gecer. Ayri say: aksi halde
      # "referans modeli N depo" satiri GOCU oldugundan buyuk gosterir.
      [ "$toplam" = "0" ] && t_referans_bos=$((t_referans_bos+1))
    else
      model="-"
    fi
  fi

  printf '%-22s %6d %6d %6d %6d  %s\n' "$ad" "$ayni" "$sapma" "$yerel" "$toplam" "$model"
  t_ayni=$((t_ayni+ayni)); t_sapma=$((t_sapma+sapma)); t_yerel=$((t_yerel+yerel))
done

echo
echo "TOPLAM: $t_depo depo · ayni $t_ayni · SAPMA $t_sapma · yerel $t_yerel · referans modeli $t_referans depo"
# ⚠ REFERANS SAYISI GOCU OLDUGUNDAN BUYUK GOSTEREBILIR — bilerek ayristiriliyor.
# Bir depo "kopyasi yok + CLAUDE.md merkeze isaret ediyor" testini geciyorsa
# REFERANS sayilir. Ama HIC KURALI OLMAYAN bir depo da bu testi gecer: o goc
# etmis degildir, yalnizca hicbir zaman kopyalamamistir.
# GERCEK GOC = kopyasi OLAN bir deponun kopyalari birakip isaretciye gecmesi.
if [ "$t_referans_bos" -gt 0 ]; then
  echo "       ⚠ bunun $t_referans_bos tanesinin HIC kurali yok — goc etmedi, hic kopyalamadi."
  echo "         Gercek goc gostergesi: SAPMA'nin dusmesi ($t_sapma) — referans sayisinin artmasi degil."
fi

# ---------------------------------------------------------------------------
# MERKEZIN KENDI SAGLIGI — evrensel katmanda proje adi var mi?
# NEDEN (olculdu 23.09.2026, bir tuketici bildirdi): `work-protocol.md` bes ayri
# yerde bir tuketicinin ajan adlarini tasiyordu, `footprint-ladder.md` bir baska
# depoyu aniyordu. `harvest --promote` ciktisindaki "iceriği PROJE-BAGIMSIZ hale
# getir" adimi iki kez atlanmisti. Somut zarar: baska bir depo o kurali okuyup
# VAR OLMAYAN ajanlari cagirmaya calisir ve "danistim" sanir.
# Depo adlari kok dizinden turetilir, yani yeni depo listeye kendiliginden girer.
#
# ⚠ BU KAPININ NE YAKALAMADIGI — YAZILI OLMASI SART (yoksa "temiz" yanlis guven verir):
#   Yalniz TEKNIK BAGLAMDAKI ad yakalanir: `ad-`, `/ad`, `\ad`, `ad/`, `` `ad` ``.
#   Yani `bkmargus-sp-first` ve `D:\Dev\pusula` yakalanir; duz cumle icindeki
#   "pusula'dan uyarlandi" YAKALANMAZ.
#   SEBEP OLCULDU: ilk surum duz metne de bakiyordu ve `ajan` adli depo yuzunden
#   `agent-usage.md`'de 7 bulgunun 7'si YANLIS POZITIF cikti ("ajan" siradan bir
#   Turkce sozcuk). Bu depo ayni sinifta bir kapiyi zaten olcup SILMISTI
#   (7 bulgunun 6'si yanlis pozitif) — gerekce: yanlis pozitif BASTIRMA ogretir,
#   ve bastirma kurali ikinci kez oldurur. Dar ve dogru > genis ve gurultulu.
# ---------------------------------------------------------------------------
depo_adlari=""
for d in "$DEV"/*/; do
  ad="$(basename "$d")"
  case "$ad" in claude-context-template) continue ;; esac
  [ ${#ad} -ge 4 ] || continue
  depo_adlari="${depo_adlari}${depo_adlari:+|}${ad}"
done
if [ -n "$depo_adlari" ]; then
  DESEN="[\`/\\]($depo_adlari)|($depo_adlari)[-/\\\`]"
  sizinti=$(grep -roEil "$DESEN" "$EVREN" 2>/dev/null | wc -l)
  echo
  if [ "$sizinti" = "0" ]; then
    echo "MERKEZ SAGLIGI: _universal proje adi tasimiyor · TEMIZ"
  else
    echo "MERKEZ SAGLIGI: _universal icinde PROJE ADI gecen $sizinti dosya — evrensel katman"
    echo "                proje-bagimsiz olmali. Tuketici var olmayan seyi cagirir:"
    grep -roEin "$DESEN" "$EVREN" 2>/dev/null | sed 's|^|                  |' | head -10
  fi
fi
echo
echo "Sapmanin sebebi bu tablodan GORUNMEZ (bayat mi, bilerek mi). Siradaki adim:"
echo "  bash bin/harvest.sh --diff <dosya> <proje>   tek dosyanin farki"
