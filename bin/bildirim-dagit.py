# -*- coding: utf-8 -*-
"""Merkez bildirimini her tüketici depoya bırakır + CLAUDE.md'ye işaretçi koyar.

⚠ DİL: üretilen dosyalar MARKDOWN'dır → düzgün Türkçe yazılır.
  `turkish-ui.md:18` — "ASCII sadeleştirme YASAK: Düzenle ✓, Duzenle ✗".
  Ev stili karışıktır ve karışık olması bilinçlidir: `bin/*.sh` ASCII Türkçe,
  `docs/`+`*.md` düzgün Türkçe. `coding-discipline`: dokunduğun dosyanın stilini
  taklit et. İlk sürümde bu karıştırıldı ve 39 depoya ASCII metin dağıtıldı —
  üstelik KARIŞIK hâlde ("yanlis" ile "doğar" aynı cümlede), ki tutarlı ASCII
  savunulabilir olsa bile karışık hâl savunulamaz.

Idempotent: işaretçi bloğu varsa DEĞİŞTİRİLİR (atlanmaz) — yoksa kaynaktaki
düzeltme depolara hiç ulaşmaz.

KURU KOŞUM: `python bildirim_dagit.py`
YAZ:        `python bildirim_dagit.py --yaz`
"""
import io
import re
import sys
from pathlib import Path

DEV = Path("D:/Dev")
MERKEZ = Path(__file__).resolve().parent.parent   # betik artik deponun ICINDE
EVREN = MERKEZ / "templates/.claude/rules/_universal"
ISARET = "<!-- merkez-bildirimi -->"
ISARET_SON = "<!-- /merkez-bildirimi -->"
YAZ = "--yaz" in sys.argv

ILERLEYEN = [
    "test-discipline.md", "error-handling.md", "commit-discipline.md",
    "todo-verification.md", "footprint-ladder.md",
]

# ── ÜRETECİN KENDİ TESTİ (kapı DEĞİL) ───────────────────────────────────────
# Merkeze "yorumda ASCII" kapısı KONMAZ: bu depo ölçtü ve reddetti (7 bulgunun
# 6'sı yanlış pozitif; `isimlendirme.md` — yanlış pozitif bastırma öğretir).
# Ama üretecin KENDİ çıktısı dar ve denetlenebilir bir kümedir; kendi metnini
# kendi üzerinde sınamak yanlış pozitif üretmez.
# ⚠ Bu bir KARA LİSTEDİR ve eksikliği GÖRÜNMEZ — yalnız bu dosyada bilerek
#   kullanılmış ASCII biçimleri yakalar, yeni bir tanesini yakalamaz.
ASCII_IZLERI = [
    "isaret", "gerekce", "olcum", "olcul", "kopyasi", "sablon", "tuketici",
    "yanlis", "kosam", "cagir", "basinda", "degil", "gecerli", "dusme",
    "bagimli", "dogar", "sozcuk", "calis", "kirici", "uyari", "kural degis",
]


def kendi_testi(metin: str, nerede: str):
    # ⚠ KOD AYIKLANIR, SONRA BAKILIR. Dosya adları ve komutlar ZORUNLU ASCII'dir
    #   (`kod-sozcukleri.ek.txt`, `TUKETICI-REHBERI.md`) — onlara bakmak testin
    #   kendisini yanlış pozitif üretir hâle getirir, ki bu depo o hatayı ölçüp
    #   bir kapıyı bu yüzden silmişti. Kural: ASCII kodda serbest, DÜZYAZIDA yasak.
    duzyazi = re.sub(r"```.*?```|`[^`]*`|\[[^\]]*\]\([^)]*\)", " ", metin, flags=re.S)
    # ⚠ IGNORECASE KULLANILMAZ — Python'un büyük/küçük eşlemesi Türkçe `ı` ile ASCII
    #   `i`yi AYNI sayar (`ı`.upper() == `I`). Yani IGNORECASE ile bu test DOĞRU
    #   Türkçeyi ("kırıcı", "uyarı", "kopyası") ASCII sanıp KIRIK verir — ilk sürümde
    #   tam bu oldu. Testin kendisi, ölçtüğü şeyin kör noktasını miras almıştı.
    #   Çözüm: harfe duyarlı ara, yalnız küçük ve Baş-harfi-büyük biçimleri dene.
    bulunan = set()
    for iz in ASCII_IZLERI:
        for kalip in (iz, iz[0].upper() + iz[1:]):
            if re.search(r"\b\w*%s\w*\b" % kalip, duzyazi):
                bulunan.add(iz)
    bulunan = sorted(bulunan)
    if bulunan:
        print("KOŞAMADI  %s içinde ASCII sadeleştirilmiş Türkçe: %s"
              % (nerede, ", ".join(bulunan)))
        print("          `turkish-ui.md:18` — ASCII sadeleştirme YASAK.")
        sys.exit(2)


def olc(depo: Path):
    ayni = sapma = yerel = 0
    bayat = []
    kdizin = depo / ".claude/rules"
    if kdizin.is_dir():
        for f in sorted(kdizin.glob("*.md")):
            merkez_es = EVREN / f.name
            if merkez_es.exists():
                if f.read_bytes() == merkez_es.read_bytes():
                    ayni += 1
                else:
                    sapma += 1
                    if f.name in ILERLEYEN:
                        bayat.append(f.name)
            else:
                yerel += 1
    return ayni, sapma, yerel, bayat


def bildirim(ad, ayni, sapma, yerel, bayat):
    toplam = ayni + sapma + yerel
    if ayni + sapma == 0:
        model = "REFERANS ya da kural kullanmıyor — kopya YOK"
        durum = ("Bu depoda şablon kurallarının kopyası **yok**. Yapılacak bir göç yok; "
                 "aşağıdaki 1. ve 2. bölümler yine de geçerlidir.")
    else:
        model = "KOPYA"
        durum = ("Bu depoda şablon kurallarının **kopyası var**. O kopyalar artık "
                 "kanonik **değil** — 3. bölümdeki göç geçerlidir.")

    bayat_blok = ""
    if bayat:
        satirlar = "\n".join("- `%s`" % b for b in bayat)
        bayat_blok = (
            "\n### Merkezin ilerlediği dosyalar — bu depoda AYRIŞMIŞ (23.09.2026)\n\n"
            "Merkez şu dosyalarda 23.09.2026'da ilerledi **ve** buradaki kopya farklı:\n\n"
            "%s\n\n"
            "⚠ **\"Ayrışmış\" bayat demek DEĞİLDİR — yön ölçülmedi.** `durum.sh` skaler\n"
            "ölçer: iki dosyanın farklı olduğunu söyler, hangisinin ileride olduğunu\n"
            "söylemez. İki tüketici bunu bağımsız olarak ölçtü ve **her dosyada her iki\n"
            "yönde de fark** buldu. Kopyayı \"bayat\" sanıp silmek, burada olgunlaşmış\n"
            "bir kuralı ekosistemden sessizce yok eder.\n\n"
            "Her farkı **üç kovadan birine** koy (`--diff` ile, tercihle değil ölçümle):\n\n"
            "| Kova | Ne yapılır |\n"
            "|---|---|\n"
            "| **MERKEZ İLERİDE** | al |\n"
            "| **KARŞILIKLI** | buradaki kısım merkeze terfi (`harvest.sh --promote`), merkezdeki alınır |\n"
            "| **YERELLEŞTİRİLMİŞ** | yapı aynı, yalnız örnek/alan farkı — **dokunma** |\n"
            % satirlar
        )

    return """%s
# MERKEZ BİLDİRİMİ — kurallar artık tek yerde (23.09.2026)

> **Kuralı kopyalama, işaret et.** Kopyalanan kural bayatlar ve iki gerçek doğar.
> Kanonik merkez: `../claude-context-template/`
> Tam rehber: `../claude-context-template/docs/TUKETICI-REHBERI.md`
> Gerekçe ve ölçüm: `../claude-context-template/docs/ASAMA-1-TEK-MERKEZ-2026-09-23.md`

## 0. BU DEPONUN ÖLÇÜMÜ (`bin/durum.sh`, 23.09.2026)

| aynı | sapma | yerel | toplam | model |
|--:|--:|--:|--:|---|
| %d | **%d** | %d | %d | %s |

%s
%s
## 1. Oturum başı

⚠ **Bu bloğu commit ederken:** `CLAUDE.md`'de başka birinin commit'lenmemiş
satırları varsa düz `git add CLAUDE.md` onları da sahiplenir. Önce
`git diff CLAUDE.md` ile bak; yabancı satır varsa ya bu bloğu geçici çıkarıp
kendi işini commit et ya da `git add -p` ile yalnız bu bloğu al.
(Ölçülmüş: bir tüketici bugün tam bunu yaşamamak için bloğu geçici olarak
çıkardı, kendi satırlarını commit etti, sonra geri koydu.)

```bash
ls ../claude-context-template/templates/.claude/rules/_universal/*.md   # 18 kanonik kural
```

Ekosistem ölçümü: 39 depo · **169 sapmış kural** · sapması sıfır olan tek depo
`bkm-magaza` — çünkü kopyalamıyor. Hedef, o satırı 39 kere yazdırmak.

## 2. Türkçe tanımlayıcı kapısı — çağır, kopyalama

Kod İngilizce, **yorum ve arayüz metni Türkçe**. Kapı yorumlara ve dizelere dokunmaz.

```bash
python ../claude-context-template/tools/turkce_tanimlayici_denetimi.py <dosya...>
```

Kancadan çağırırken üç şart:
1. **Yalnız yeni/dokunulan dosyaları ver.** Var olan Türkçe adları taramak her commit'i
   bloklar → kapı ilk gün kapatılır.
2. **Araç yoksa ya da koşamazsa SARI uyar**, sessizce geçme. Sessiz geçen kapı, hiç
   olmayan kapıdan beterdir: çalışıyor *görünür*.
3. Süpürme kipi istiyorsan `.claude/turkce-kapi.json` yaz; yoksa kapı KOŞAMADI der.

İsteğe bağlı tüketici dosyaları:
`.claude/turkce-kapi.json` (kapsam, alan adları) ·
`.claude/kod-sozcukleri.ek.txt` (bu deponun ALAN sözcükleri) ·
`.claude/turkce-taban.json` (devralınmış borcu dondurmak)

⚠ **Ak liste ayrımı:** dilin kendi sözcüğü (`Deleted`, `Timer`) → merkezdeki çekirdek
liste. Bu deponun alan adı → kendi ek dosyası. Yanlış yere konursa ya merkez bir
tüketiciye bağımlı olur ya da başka depolarda hatalı bulgu üretir.

## 3. Göç — kopyadan referansa

⚠ **TOPLU SİLME YOK.** Her sapmanın *bayat mı bilerek mi* olduğu insan kararıdır.

```bash
bash ../claude-context-template/bin/harvest.sh --diff <dosya> %s
```

| Fark neyse | Karar |
|---|---|
| Yalnız merkez ilerlemiş | **bayat** → kopyayı sil, merkeze işaret et |
| Bu depoya özgü bir gerçek | **bilerek** → kural yerel kalır, **gerekçesi dosyanın ilk satırlarına yazılır** |
| Burada olgunlaşmış, evrensel | **terfi** → `harvest.sh --promote`, silme |

Gerekçeli yerel kural deseni (`bkm-magaza/.claude/rules/capacitor-kabuk.md`):
*"Bu kural yerel, çünkü komşu depo .NET/SQL odaklı; mobil paketleme orada yok."*
**Gerekçesiz yerel kural kabul edilmiyor.**

## 4. Üç uyarı

1. **Depo adı değişecek:** `claude-context-template` → **`Norma`** (Aşama 2'de,
   `bootstrap --reference` ile birlikte). Yolu bu depoda **tek bir yere** yaz; her
   kancaya gömersen ad değiştiğinde hepsini tek tek düzeltmek zorunda kalırsın.
2. **Aynı depoda başka oturum çalışıyor olabilir.** Kırıcı dokunuştan **önce** tek
   satır haber.
3. **Önce ve sonra ölç:** `bash ../claude-context-template/bin/durum.sh`. Bu deponun
   satırında `sapma` düşmeli, `model` sütunu **REFERANS** olmalı. Ölçmediysen göç
   olmamıştır.

---
*Bu dosya merkez tarafından bırakıldı (Aşama 1 · 23.09.2026). Aşama 2 ve 3 YAPILMADI:
`bootstrap --reference` kipi yok, 37 deponun göçü her deponun kendi oturumundadır.*
""" % (ISARET, ayni, sapma, yerel, toplam, model, durum, bayat_blok, ad)


def isaretci_blok() -> str:
    return (
        "%s\n"
        "> ⚠ **KURALLAR ARTIK MERKEZDE.** Kopyalamak yerine işaret ediyoruz.\n"
        "> Oturum başında oku: [`.claude/MERKEZ-BILDIRIMI.md`](.claude/MERKEZ-BILDIRIMI.md)\n"
        "> Kanonik kurallar: `../claude-context-template/templates/.claude/rules/_universal/`\n"
        "%s" % (ISARET, ISARET_SON)
    )


BLOK = isaretci_blok()
# ⚠ Eski sürüm kapanış işaretçisi olmadan yazıldı; onu da yakalamak gerek, yoksa
#   depolarda iki blok üst üste birikir.
ESKI_BLOK = re.compile(
    re.escape(ISARET) + r".*?rules/_universal/`\n(?:" + re.escape(ISARET_SON) + r"\n?)?",
    re.S)

kendi_testi(BLOK, "CLAUDE.md işaretçi bloğu")

yazilan = md_eklenen = md_degisen = 0
mdsiz = []

for depo in sorted(p for p in DEV.iterdir() if p.is_dir()):
    if depo.name == "claude-context-template" or not (depo / ".claude").is_dir():
        continue
    ayni, sapma, yerel, bayat = olc(depo)
    icerik = bildirim(depo.name, ayni, sapma, yerel, bayat)
    kendi_testi(icerik, "%s/.claude/MERKEZ-BILDIRIMI.md" % depo.name)

    if YAZ:
        io.open(depo / ".claude/MERKEZ-BILDIRIMI.md", "w",
                encoding="utf-8", newline="\n").write(icerik)
    yazilan += 1

    cmd = depo / "CLAUDE.md"
    if not cmd.exists():
        mdsiz.append(depo.name)
        continue
    ham = io.open(cmd, encoding="utf-8-sig", errors="replace").read()
    if ESKI_BLOK.search(ham):
        yeni = ESKI_BLOK.sub(BLOK + "\n", ham, count=1)
        md_degisen += 1
    else:
        satirlar = ham.split("\n")
        kes = 1 if satirlar and satirlar[0].startswith("#") else 0
        yeni = "\n".join(satirlar[:kes] + ["", BLOK] + satirlar[kes:])
        md_eklenen += 1
    if YAZ and yeni != ham:
        io.open(cmd, "w", encoding="utf-8", newline="\n").write(yeni)

kip = "YAZILDI" if YAZ else "KURU KOŞUM (hiçbir şey yazılmadı)"
print(kip)
print("bildirim dosyası            : %d depo" % yazilan)
print("CLAUDE.md bloğu DEĞİŞTİRİLEN: %d · yeni EKLENEN: %d" % (md_degisen, md_eklenen))
print("CLAUDE.md YOK (yalnız dosya): %d — %s" % (len(mdsiz), ", ".join(mdsiz)))
