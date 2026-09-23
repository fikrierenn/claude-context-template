#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Tüketicinin CLAUDE.md'sine MERKEZ BLOĞUNU yazar (varsa tazeler).

`bootstrap.sh` / `bootstrap.ps1` çağırır:
    python bin/_merkez_blok.py <CLAUDE.md yolu> <blok metni>

NEDEN AYRI DOSYA: blok metni tırnak, ters bölü, backtick ve Türkçe karakter
içeriyor. Bunu bash heredoc'una gömmek kaçış katmanlarını üst üste bindiriyor ve
ilk denemede `\\n` dizileri gerçek satır sonuna dönüşüp gömülü Python'ı bozdu —
sessizce değil, ama bozdu. Ayrı dosya hem okunur hem TEK BAŞINA sınanabilir.
(`footprint-ladder` 1. basamak değil 2.: mevcut kabı zorlamak yerine doğru kabı seç.)

Blok, dosyanın BAŞLIĞINDAN HEMEN SONRA durur — başlık ilk satırda kalsın diye.
Idempotent: blok varsa DEĞİŞTİRİLİR, ikinci kez eklenmez.

Çıkış: 0 yazıldı · 1 hedef yok · 2 argüman hatası
"""
import io
import re
import sys

ISARET_BAS = "<!-- merkez-bildirimi -->"
ISARET_SON = "<!-- /merkez-bildirimi -->"
BLOK_DESENI = re.compile(
    re.escape(ISARET_BAS) + r".*?" + re.escape(ISARET_SON) + r"\n?", re.S)


def baglanti_duzelt(metin: str, merkez: str, kurallar: list) -> str:
    """Referans kipinde YEREL kural bağlantılarını merkeze çevirir.

    ⚠ NEDEN GEREKLİ (ölçüldü 23.09.2026): şablonun `CLAUDE.md`'si metin içinde
      `.claude/rules/session-protocol.md` gibi YEREL yollara bağlantı veriyor.
      Referans kipinde o dosyalar KOPYALANMADIĞI için bağlantılar boşluğa gider —
      ve okuyan "kural burada olmalıydı, yok" demez; **bağlantıya tıklamaz ve
      kuralı hiç okumaz**. İşaretçi bloğu doğru yeri gösterirken metnin geri
      kalanının yanlış yeri göstermesi, işaretçiyi de değersizleştirir.
    """
    for ad in kurallar:
        metin = metin.replace(
            ".claude/rules/%s" % ad,
            "%s/templates/.claude/rules/_universal/%s" % (merkez, ad))
    return metin


def yaz(hedef: str, blok: str, merkez: str = "", kurallar=None) -> int:
    try:
        ham = io.open(hedef, encoding="utf-8-sig", errors="replace").read()
    except OSError:
        return 1

    if BLOK_DESENI.search(ham):
        yeni = BLOK_DESENI.sub(lambda _: blok + "\n", ham, count=1)
    else:
        satirlar = ham.split("\n")
        kes = 1 if satirlar and satirlar[0].startswith("#") else 0
        yeni = "\n".join(satirlar[:kes] + ["", blok] + satirlar[kes:])

    if merkez and kurallar:
        yeni = baglanti_duzelt(yeni, merkez, kurallar)

    if yeni != ham:
        io.open(hedef, "w", encoding="utf-8", newline="\n").write(yeni)
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("kullanim: _merkez_blok.py <CLAUDE.md> <blok> [merkez] [kural,kural,...]",
              file=sys.stderr)
        sys.exit(2)
    merkez = sys.argv[3] if len(sys.argv) > 3 else ""
    kurallar = [k for k in sys.argv[4].split(",") if k] if len(sys.argv) > 4 else []
    sys.exit(yaz(sys.argv[1], sys.argv[2], merkez, kurallar))
