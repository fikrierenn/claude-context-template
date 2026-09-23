#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TÜRKÇE TANIMLAYICI KAPISI — kod İngilizce, UI Türkçe (`turkish-ui.md`).

═══ YAKALAMA SÖZLEŞMESİ ═══════════════════════════════════════════════════════
YAKALAR:
  • C#/Razor kodunda TANIMLAYICI konumunda Türkçe kelime: sınıf, metot, property,
    alan, yerel değişken, parametre adları (`Sube`, `MudurAdi`, `KisiGunOku`…).
  • Türkçe karakter taşıyan tanımlayıcı (`Ölçüm`, `Şube`).
  • Türkçe dosya adı (`SubeKapsamiTests.cs`).

YAKALAMAZ:
  • YORUMLAR ve DİZELER — onlar Türkçe OLMALI (UI metni, hata mesajı, açıklama).
    Satırdan çıkarılır.
  • SQL metinlerindeki kolon adları (dize içinde, yukarıdaki sebeple elenir).
  • Listede olmayan Türkçe kelime. Liste elle yazılmıştır ve EKSİKTİR —
    `olctum-mu-cikardim-mi.md` § "liste elle yazılmaz" ihlali, bilerek: kelime
    kümesini veriden türetmenin yolu yok. Yeni ihlal görülünce listeye eklenir.
  • Alan adları: tüketicinin `alan_adlari` listesi (ürün/şirket adı, çevrilmez).

BİLİNEN ATLATMA:
  • Kelimeyi listede olmayan bir Türkçe kelimeyle yazmak (`Magaza` yerine `Dukkan`).
  • Türkçe kelimeyi kısaltmak (`Sb` = şube).

YÜKSELTME YOLU:
  ✅ YAPILDI (V-19, 19.09): kara listenin YANINA ak liste kondu
    (`kod-sozcukleri.txt`, aracın yanında). Bildirilen her adın her sözcüğü
    dağarcıkta olmak zorunda; olmayan sözcük KIRIK verir ve iki seçenek sunar —
    İngilizceyse dosyaya BİR SATIR ekle, Türkçeyse ÇEVİR.
  ⚠ AK LİSTE KURULURKEN İKİ KAÇAK BULDU: `LikeKacir` ve `CalistirAsync` aylardır
    koddaydı; kara listede o kelimeler olmadığı için kapı onları HİÇ görmemişti
    (`EscapeLike` / `RunAsync` yapıldı). Yani "kara listenin eksikliği görünmez"
    bir teori değil, bu depoda ÖLÇÜLMÜŞ bir olgudur.

KAPININ ÜÇ KATMANI (Solum'un ayrımı + V-19):
  • Türkçe HARF taraması (`ıİşŞğĞüÜöÖçÇ`) — kapalı küme, kaçış YOK.
  • ASCII'ye çevrilmiş Türkçe KELİME listesi — kara liste; hızlı ve açık mesaj
    verir ama eksikliği GÖRÜNMEZ, tek başına GÜVENCE DEĞİLDİR.
  • AK LİSTE (V-19) — bildirilen adlardaki her sözcük dağarcıkta mı? Eksikliği
    İNSANA SORAR: yanlış pozitifin bedeli bir satır, yanlış negatifin bedeli
    görünmeyen bir ihlal.
  ⚠ 1.8.0 (24.09.2026): BİÇİM ve BİLEŞEN katmanları (opt-in: ayar "bicim": true, "bilesen": {"onekler": […]}) —
    naming-conventions.md §2/§3'ün kapısı: dil başına case; CSS/DOM adı kebab + tip öneki + ak liste, -btn soneki yasak.
    .css/.html yalnız bileşen katmanıyla taranır (UI metni Türkçe harf doludur, tanımlayıcı katmanı oraya girmez).
  ⚠ 1.7.2 (24.09.2026): TEST METODU ADI taranmaz, gövdesi taranır — Solum ölçümü: 4087 bulgunun %78'i test
    adıydı; test adı bir iddiadır, insan mesajıdır (Türkçe kalır). Sınır ölçülebilir işaretten: test özniteliği /
    `def test_*`. Ayrıca REHBER: ek ak liste (ürün adı) adımı kapıdan ÖNCE gelir — ilk koşumda en sık bulgu ürünün
    kendi adı çıkmasın (Solum: `Solum` 61 kez).
  ⚠ 1.7.0 (24.09.2026): DİL PROFİLLERİ — `.js/.mjs/.ts · .py · .ps1/.psm1 · .sql` de taranır
    (yorum/dize soyutlama + bildirim desenleri + anahtar sözcükler dile göre). Süpürmede OPT-IN:
    ayar `"uzantilar": [...]`; argüman kipinde desteklenen her uzantı işlenir. `--tabansiz` bayrağı
    tabanı yok sayar ("dokunulan dosya tamamen temiz"). İsteyen: bkm-magaza (bir gecede 9 Türkçe
    Python fonksiyonu + JS yardımcıları kapıdan sessizce geçti — ölçüldü).
  ⚠ KÖR NOKTA KAPANDI (19.09): `.razor` uzantısı ne süpürmede vardı ne de
    razor sayılıyordu. Dashboard'ın 61 UI dosyası HİÇ bakılmamıştı; elle
    verilse C# gibi işlenip UI metnine Türkçe-harf taraması uygulanırdı.
    "dashboard taranıyor" cümlesi doğruydu, KAPSAMI yanlıştı — uzantı listesi
    bir yerden türetilmiyordu, elle yazılmıştı.
  ⚠ Ak liste dosyası okunamazsa kapı KOŞAMADI der — sessizce kara listeye düşmek
    YASAK, çünkü o hâlde kapı çalışıyor GÖRÜNÜR.
═══════════════════════════════════════════════════════════════════════════════

MERKEZE TERFİ (23.09.2026 — `docs/MIMARI-KARARI-2026-09-23.md` Aşama 1):
  Bu kapı `pusula`da doğdu ve orada olgunlaştı; ekosistemin en olgun kapısıydı ve
  ŞABLONDA YOKTU — yani iki merkez yarışıyordu. Buraya terfi etti, kanonik olan bu
  kopyadır. Tüketici KOPYALAMAZ, yol ile ÇAĞIRIR:

      python ../claude-context-template/tools/turkce_tanimlayici_denetimi.py <dosya...>

  (Ölçülmüş örnek: `bkm-magaza/.claude/hooks/pre-commit-denetim.sh` bu deseni
  komşu depoya karşı bugün zaten kullanıyor.)

  PROJEYE BAĞLI OLAN HER ŞEY DIŞARI ÇIKARILDI — merkezde `vardiya-app`/`Bkm` gibi
  bir ad kalmadı. Tüketici tarafında yaşayanlar:
    `<kök>/.claude/turkce-kapi.json`       kapsam · taban kökleri · alan adları
    `<kök>/.claude/kod-sozcukleri.ek.txt`  deponun kendi İngilizce sözcükleri (ops.)
    `<kök>/.claude/turkce-taban.json`      donmuş borç — çırcır tabanı (ops.)
  Merkezde duran: bu betik + `kod-sozcukleri.txt` (çekirdek ak liste).
  ⚠ İKİSİ BİRLİKTE TAŞINIR: ak liste `Path(__file__).parent`'a göre bulunur.
═══════════════════════════════════════════════════════════════════════════════

NEDEN VAR: 19.09.2026 oturumunda GMY **dört kez** aynı şeyi söylemek zorunda
kaldı ("hâlâ Türkçe isim kullanıyorsun"). Kural yazılıydı ve okunmuştu; çiğneyeni
gören yoktu. `test-discipline.md` § yazılı kural ≠ uygulanan kural.

Kullanım:
    python <merkez>/tools/turkce_tanimlayici_denetimi.py [dosya ...]
    (dosya verilmezse `.claude/turkce-kapi.json` içindeki KAPSAM taranır;
     ayar yoksa süpürme kipi KOŞAMADI der — sessiz yeşil YOK)
    Kök normalde çağıranın dizininden yukarı (.git/.claude) bulunur;
    `TURKCE_KAPI_KOK` ortam değişkeniyle zorlanabilir.

Çıkış: 0 geçti · 1 KIRIK · 2 KOŞAMADI
"""
from __future__ import annotations

import io
import json
import os
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
sys.stderr.reconfigure(encoding="utf-8")


# ── KÖK — TÜKETİCİNİN kökü, aracın kendi kökü DEĞİL ─────────────────────────
# ⚠ TERFİDE DÜZELTİLEN EN KRİTİK ŞEY (23.09.2026). Kapı pusula'dayken
#   `KOK = Path(__file__).parent.parent` doğruydu: araç deponun içindeydi.
#   Merkeze taşınınca aynı satır MERKEZİN kökünü verir — yani kapı, çağıran
#   deponun kodunu değil ŞABLONU tarardı ve "0 bulgu, geçti" derdi.
#   Sessizce yeşil veren kapı, kapı değildir (`test-discipline` § yazılı kural
#   ≠ uygulanan kural). Kök artık ÇAĞIRANIN yerinden bulunur.
def kok_bul() -> Path:
    zorlanan = os.environ.get("TURKCE_KAPI_KOK")
    if zorlanan:
        return Path(zorlanan).resolve()
    p = Path.cwd().resolve()
    for aday in (p, *p.parents):
        if (aday / ".git").exists() or (aday / ".claude").is_dir():
            return aday
    return p


KOK = kok_bul()

# ── PROJE AYARI — kapsam/alan adları TÜKETİCİDE yaşar ───────────────────────
# Merkeze taşınan kapı, tüketicinin dizin adlarını BİLEMEZ. Bu yüzden kapsam
# artık koda gömülü değil: `<kök>/.claude/turkce-kapi.json`.
#   {"kapsam": ["src", "tests"], "tabanli_kokler": ["legacy"],
#    "alan_adlari": ["Vardiya", "Bkm"], "dosya_adi_istisnalari": ["VardiyaModels"]}
# Dosya YOKSA kapı susmaz: süpürme kipinde KOŞAMADI der (aşağıda), argüman
# kipinde (kancaların kullandığı kip) ayarsız da tam çalışır.
AYAR_DOSYASI = KOK / ".claude" / "turkce-kapi.json"


def ayar_yukle() -> dict:
    if not AYAR_DOSYASI.exists():
        return {}
    try:
        return json.loads(io.open(AYAR_DOSYASI, encoding="utf-8").read())
    except (ValueError, OSError):
        return {}


AYAR = ayar_yukle()

# KAPSAM = yeni yazılan kod. Eski kod kapsam DIŞI — oradaki Türkçe adlar
# devralınmış borçtur ve bu kapı onları toptan kırmızıya çevirseydi kapı
# KAPATILIRDI (kimse 500 ihlalli bir kapıyı açık tutmaz).
# ⚠ ÇIRCIR — DOGDUGU DEPODA OLCULMUS GEREKCE (V-08, 19.09): `dashboard` kapsama
#   alindi ama TEMIZ DEGIL —
#   olculdu: 85 dosyada 2.431 bulgu. Iki secenek vardi ve ikisi de kotuydu:
#     (a) kapsama alma  -> dashboard KOR kalir (bugune kadarki hal)
#     (b) kapsama al ve bloklama -> 2.431 hatayla kapi ILK GUN KAPATILIR
#   Ucuncu yol secildi: CIRCIR. Her dosyanin bugunku sayisi TAVAN
#   (`<kök>/.claude/turkce-taban.json`). ARTIS kirar, azalis "tabani guncelle" der,
#   YENI dosya temiz olmak zorunda (taban 0).
#   Yani borc DONDURULUYOR, gizlenmiyor: sayisi dosyada YAZILI ve her kosumda
#   ekrana basiliyor.
KAPSAM = AYAR.get("kapsam", [])
TABANLI_KOKLER = tuple(AYAR.get("tabanli_kokler", []))   # circir yalniz burada; otekiler SIFIR tolerans
# Süpürme kipinin taradığı uzantılar (1.7.0). VARSAYILAN ESKİ KÜME — yeni diller OPT-IN:
#   {"uzantilar": [".cs", ".razor", ".js", ".mjs", ".py", ".ps1", ".sql"]}
#   Argüman kipinde (kanca dosya verir) desteklenen her uzantı işlenir; süpürmede yalnız bu liste —
#   yoksa mevcut tüketicilerin (Vardiya, dashboard) süpürmesi bir gecede yeni bulgularla kırılırdı.
SUPURME_UZANTILARI = tuple(AYAR.get("uzantilar", [".cs", ".cshtml", ".razor"]))
# ── 1.8.0 (24.09.2026): BİÇİM ve BİLEŞEN katmanları — OPT-IN, naming-conventions.md §2/§3'ün kapısı ──────────
#   "bicim": true                       → bildirilen adın dile göre biçimi (C# PascalCase, Python snake_case, JS camelCase,
#                                          PowerShell Verb-Noun, SQL PascalCase) denetlenir
#   "bilesen": {"onekler": [...]}       → .css seçicileri ve .html/.js/.mjs içindeki class/id dizeleri: kebab-case,
#                                          İngilizce (ak liste), İLK parça tip öneki (btn form view …) ya da durum (is/has),
#                                          -btn/-dugme/-buton soneki YASAK. Özel önek listesi verilmezse varsayılan küme.
#   Varsayılan KAPALI: mevcut tüketicilerin kapısı bir gecede yeni sınıf bulguyla kırılmaz (1.7.0 uzantı kararıyla aynı).
BICIM_ACIK = bool(AYAR.get("bicim", False))
BILESEN_AYAR = AYAR.get("bilesen")            # None = kapalı
BILESEN_ONEKLERI = set((BILESEN_AYAR or {}).get("onekler") or
    "btn form view field tab card badge alert list table row cell chip filter modal overlay toast nav header footer section "
    "panel menu icon label input select text link img grid col page app".split()) | {"is", "has"}

# ⚠ TABAN TÜKETİCİDE DURUR, MERKEZDE DEĞİL. Donmuş borç o deponun gerçeğidir;
#   merkeze konsaydı bir deponun borcu ötekinin kapısını gevşetirdi.
TABAN_DOSYASI = KOK / ".claude" / "turkce-taban.json"

# Alan adları (ürün/şirket adı — çevrilmez) tüketiciden gelir; merkezde
# gömülü bir `Vardiya`/`Bkm` listesi başka depoda anlamsızdır.
ALAN_ADLARI = set(AYAR.get("alan_adlari", []))
ALAN_ADLARI_KUCUK = {a.lower() for a in ALAN_ADLARI}   # ak liste katmanı küçük harf karşılaştırır
DOSYA_ADI_ISTISNALARI = set(AYAR.get("dosya_adi_istisnalari", []))

TURKCE_KELIMELER = [
    "Sube", "Mudur", "Kisi", "Gun", "Tarih", "Onay", "Sifre", "Kullanici",
    "Sayfa", "Deger", "Adi", "Hata", "Kesim", "Ozet", "Uyum", "Kaynak",
    "Bant", "Satir", "Durum", "Gorev", "Bolum", "Personel", "Sicil",
    "Eksik", "Fazla", "Giris", "Cikis", "Mola", "Calisma", "Devir",
    "Sayim", "Olcum", "Yazilma", "Aciklama", "Kaydeden", "Yetki", "Izin",
    "Rapor", "Tablo", "Sorgu", "Kapsam", "Nufus", "Fabrika", "Istemci",
    "Yanit", "Sonuc", "Mevcut", "Onceki", "Yeni", "Eski", "Toplam",
    "Bugun", "Secili", "Gecerli", "Bos", "Dolu", "Temizle", "Kur",
    "Oku", "Yaz", "Sil", "Ekle", "Guncelle", "Bul", "Ara", "Getir",
    "Kaydet", "Yukle", "Baslat", "Bitir", "Kontrol", "Denetim", "Damga",
    "Onek", "Artik", "Islem", "Ayrac", "Suzgec", "Kirilim", "Ortak",
    # 19.09 ikinci tur — ilk listede YOKTU ve kactilar (sozlesmedeki
    # "BILINEN ATLATMA" maddesinin ilk gerceklesmesi):
    "Kaydeden", "Dakika", "Metin", "Muaf", "Mesai", "Kadro", "Ek",
    "Yukleyici", "Bicim", "Sabit", "Kur", "Uret", "Cevir", "Hazirla",
]
TURKCE_HARF = "ıİşŞğĞüÜöÖçÇ"

# ── AK LİSTE (V-19) — kapının ÜÇÜNCÜ yarısı ─────────────────────────────────
# Kara liste "şu kelimeler yasak" der ve eksikliği GÖRÜNMEZ. Ak liste "yalnız bu
# sözcükler serbest" der ve eksikliği HER YENİ SÖZCÜKTE İNSANA SORAR.
#
# ⚠ KURULURKEN İKİ KAÇAK BULDU: `LikeKacir` ve `CalistirAsync` aylardır koddaydı,
#   kara listede o kelimeler olmadığı için kapı onları HİÇ görmemişti.
# ⚠ ÇEKİRDEK LİSTE ARACIN YANINDA DURUR (yol bağımlılığı: ikisi birlikte taşınır).
SOZLUK_DOSYASI = Path(__file__).resolve().parent / "kod-sozcukleri.txt"

# ── EK SÖZLÜK — tüketicinin kendi İngilizce sözcükleri (GMY kararı 23.09.2026) ──
# ⚠ AYRIM — hangi sözcük NEREYE (bu satır yanlış uygulanırsa kapı bozulur):
#   • Dilin kendi sözcüğü (`Deleted`, `Stop`, `Timer`, `Retention`) → ÇEKİRDEK liste.
#     Bunlar her .NET/JS deposunda geçer; ek dosyaya taşınırlarsa taşımayan her
#     depoda yanlış pozitif doğar ve yanlış pozitif BASTIRMA öğretir.
#   • Proje/alan adı (ürün, şirket, şema terimi) → EK dosya. Merkezde bir deponun
#     alan adı durursa merkez o tüketiciye bağımlı hale gelir.
#   Ölçülmüş sızıntı: terfi sırasında çekirdek listede `solum`/`vardiya`/`vrd`/
#   `mizan` bulundu — dördü de alan adıydı ve çıkarıldı.
# Dosya YOKSA hata değil: yokluk dağarcığı DARALTIR, yani kapıyı SIKIŞTIRIR —
# güvenli yön budur (`taban_yukle` ile aynı gerekçe).
EK_SOZLUK_DOSYASI = KOK / ".claude" / "kod-sozcukleri.ek.txt"

# Yalnız BİLDİRİM yerleri taranır (tip · metot · özellik adı). Kullanım yerleri
# değil: aynı adı iki kez bildirmiyoruz ve kullanım taraması dış kütüphane adlarını
# (Dapper, Identity) da çekerdi — dağarcık şişer, kapı gürültülenir.
BILDIRIM_DESENLERI = [
    re.compile(r"\b(?:class|record|struct|interface|enum)\s+(\w+)"),
    re.compile(r"\b(?:public|private|internal|protected)\s+"
               r"(?:static\s+|async\s+|sealed\s+|override\s+|new\s+)*"
               r"[\w<>?,\[\]\.]+\s+(\w+)\s*[\(\{=;]"),
]
SOZCUK_PARCA = re.compile(r"[A-ZÇĞİÖŞÜ][a-zçğıöşü0-9]*|[a-zçğıöşü0-9]+")

# C# anahtar sözcükleri dağarcığa girmez.
CS_ANAHTAR = set("""abstract as async await base bool break byte case catch char checked class
const continue decimal default delegate do double else enum event explicit extern false finally
fixed float for foreach get goto if implicit in int interface internal is lock long namespace new
null object operator out override params private protected public readonly ref return sbyte sealed
set short sizeof stackalloc static string struct switch this throw true try typeof uint ulong
unchecked unsafe ushort using var virtual void volatile while record init with when and or not
nameof value global file required scoped""".split())


def taban_yukle() -> dict:
    """Circir tabani: {dosya yolu -> izin verilen bulgu sayisi}.

    ⚠ Dosya YOKSA kapi KOSAMADI demez, TABANSIZ calisir (yani sifir tolerans) —
      cunku tabanin yoklugu kapiyi GEVSETMEZ, SIKISTIRIR. Guvenli yon budur.
    """
    if not TABAN_DOSYASI.exists():
        return {}
    try:
        return json.loads(io.open(TABAN_DOSYASI, encoding="utf-8").read()).get("dosyalar", {})
    except (ValueError, OSError):
        return {}


def _sozcukleri_oku(yol: Path) -> set:
    sozcukler = set()
    for satir in io.open(yol, encoding="utf-8"):
        satir = satir.strip()
        if satir and not satir.startswith("#"):
            sozcukler.add(satir.lower())
    return sozcukler


def dagarcigi_yukle():
    """Ak liste = çekirdek + (varsa) deponun ek sözlüğü.

    ÇEKİRDEK yoksa KOŞAMADI — sessizce kara listeye düşmek YASAK.
    EK yoksa sorun değil — eksikliği kapıyı gevşetmez, sıkıştırır.
    """
    if not SOZLUK_DOSYASI.exists():
        return None
    sozcukler = _sozcukleri_oku(SOZLUK_DOSYASI)
    if EK_SOZLUK_DOSYASI.exists():
        try:
            sozcukler |= _sozcukleri_oku(EK_SOZLUK_DOSYASI)
        except OSError:
            # ⚠ VAR AMA OKUNAMIYOR: yokluktan farklıdır ve sessiz geçilemez —
            #   dağarcık dar kalır, kapı yanlış pozitif üretir ve sebebi görünmez.
            print(f"KOSAMADI  ek sozluk VAR ama okunamadi: {EK_SOZLUK_DOSYASI}")
            sys.exit(2)
    return sozcukler or None

# Kod dışı bırakılacaklar: yorum + dize
# SATIR YORUMU icin `[^\n]*` kullanilir, `.*$` DEGIL.
# Gerekce olculdu (19.09.2026): `re.S` bayragiyla `.` newline de esler ve
# `$` yalniz dosya sonunda durur -> ilk `//` yorumundan itibaren dosyanin
# TAMAMI siliniyordu, yani hicbir C# dosyasi gercekte denetlenmiyordu.
# Kapi SESSIZCE yesil veriyordu; kirmizi kip kosulmasaydi gorulmezdi.
YORUM = re.compile(r"//[^\n]*|/\*.*?\*/|@\*.*?\*@", re.S)
DIZE = re.compile(r'"""[\s\S]*?"""|"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\'')
RAZOR_METIN = re.compile(r">[^<>{}@]*<")          # HTML metin düğümleri


def _gosterim(p: Path) -> str:
    """Yolu kısa göster — komut satırından göreli yol verilmişse relative_to çöker."""
    try:
        return str(p.resolve().relative_to(KOK))
    except ValueError:
        return str(p)


def _satir_koru(m: re.Match) -> str:
    """Eşleşmeyi siler AMA satır sayısını korur — yoksa satır numarası kayar
    ve bulgu yanlış satırı gösterir (ilk sürümde tam bu oldu)."""
    return chr(10) * m.group(0).count(chr(10))


# Razor'da KOD yalnız `@` ile başlayan ifadelerdedir: `@Model.Foo`, `@Bar(x)`,
# `@if (…)`, `@code { … }`. Gerisi HTML metnidir ve TÜRKÇE OLMALI.
# İlk sürüm tersini yapıyordu (HTML metnini çıkarıp kalanı kod saymak) ve
# `Toplam @VrdFormat…` gibi satırlarda UI metnini tanımlayıcı sandı.
RAZOR_IFADE = re.compile(r"@[A-Za-z_][\w.]*(?:\([^)]*\))?")

# ── DİL PROFİLLERİ (1.7.0, 24.09.2026 — bkm-magaza isteği: "tüm kodu tara") ──────
# NEDEN: kapı yalnız .cs/.razor görüyordu; tüketicinin araçları (.py/.ps1), tarayıcı kodu (.js) ve
# şema betikleri (.sql) hiç taranmıyordu — ölçüldü: bkm-magaza'da bir gecede 9 Türkçe Python
# fonksiyonu ve JS yardımcıları kapıdan sessizce geçti. Her dil için üç şey gerekir: yorum ve dize
# SOYUTLAMA (yoksa Türkçe yorum "ihlal" sayılır — ilk denemede .ps1 başlığı tam böyle yakalandı),
# BİLDİRİM desenleri (ak liste yalnız bildirilen ada bakar) ve o dilin ANAHTAR sözcükleri.
# ⚠ Bildirim deseni `params=True` ise grup bir PARAMETRE LİSTESİDİR: virgülle bölünür, varsayılan/tip kırpılır.
YORUM_PY  = re.compile(r"#[^\n]*")
YORUM_PS  = re.compile(r"<#.*?#>|#[^\n]*", re.S)
YORUM_SQL = re.compile(r"--[^\n]*|/\*.*?\*/", re.S)
DIZE_JS   = re.compile(r'`(?:[^`\\]|\\.)*`|"(?:[^"\\\n]|\\.)*"|\'(?:[^\'\\\n]|\\.)*\'', re.S)
DIZE_PY   = re.compile(r'"""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\'|"(?:[^"\\\n]|\\.)*"|\'(?:[^\'\\\n]|\\.)*\'')
DIZE_PS   = re.compile(r'@"[\s\S]*?"@|@\'[\s\S]*?\'@|"(?:[^"`\n]|`.)*"|\'(?:[^\'\n]|\'\')*\'', re.S)
DIZE_SQL  = re.compile(r"N?'(?:[^']|'')*'")
_JS_AD = r"([A-Za-z_$][\w$]*)"
DIL_PROFILLERI = {
    ".cs":     dict(yorum=YORUM, dize=DIZE, bildirim=None, anahtar=set()),        # None = mevcut C# desenleri
    ".razor":  dict(yorum=YORUM, dize=DIZE, bildirim=None, anahtar=set()),
    ".cshtml": dict(yorum=YORUM, dize=DIZE, bildirim=None, anahtar=set()),
    ".js": dict(yorum=YORUM, dize=DIZE_JS, anahtar=set("""function class const let var return if else for while do switch case
        break continue new this extends super import export from default async await try catch finally throw typeof instanceof
        void delete in of null undefined true false yield static get set constructor document window console module require""".split()),
        bildirim=[(re.compile(r"\b(?:function|class)\s+" + _JS_AD), False),
                  (re.compile(r"\b(?:const|let|var)\s+" + _JS_AD), False),
                  (re.compile(r"\b(?:const|let|var)\s+\{([^}]*)\}\s*="), True),          # const { a, b } = …
                  (re.compile(r"\bfunction\b[\w$\s]*\(([^)]*)\)"), True),                 # function f(a, b)
                  (re.compile(r"\(([^()]*)\)\s*=>"), True),                               # (a, b) => …
                  (re.compile(r"^\s*(?:async\s+)?" + _JS_AD + r"\s*\([^)]*\)\s*\{", re.M), False)]),  # method kısayolu
    ".py": dict(yorum=YORUM_PY, dize=DIZE_PY, anahtar=set("""def class return if elif else for while in not and or is None True
        False import from as with try except finally raise lambda yield pass break continue global nonlocal assert del print self
        cls args kwargs main""".split()),
        bildirim=[(re.compile(r"\bclass\s+(\w+)"), False),                  # sıra 0 = sınıf (PascalCase)
                  (re.compile(r"\bdef\s+(\w+)"), False),                    # sıra 1 = fonksiyon (snake_case)
                  (re.compile(r"\bdef\s+\w+\s*\(([^)]*)\)"), True),
                  (re.compile(r"^\s*(\w+)\s*(?::[^=\n]+)?=(?!=)", re.M), False),
                  (re.compile(r"\bfor\s+(\w+)\s+in\b"), False),
                  (re.compile(r"\bas\s+(\w+)"), False)]),
    ".ps1": dict(yorum=YORUM_PS, dize=DIZE_PS, anahtar=set("""function param begin process end if else elseif foreach for while
        switch return try catch finally throw in exit true false null env args psscriptroot erroractionpreference lastexitcode
        matches host error input pscmdlet myinvocation""".split()),
        bildirim=[(re.compile(r"\bfunction\s+([\w-]+)"), False),
                  (re.compile(r"\$([A-Za-z_]\w*)\s*=(?!=)"), False),
                  (re.compile(r"\bforeach\s*\(\s*\$(\w+)"), False),
                  (re.compile(r"\bparam\s*\(([\s\S]*?)\)\s*(?:\n|$)", re.M), True),
                  (re.compile(r"^\s*\[[^\]]*\]\s*\$(\w+)", re.M), False)]),
    ".sql": dict(yorum=YORUM_SQL, dize=DIZE_SQL, anahtar=set("""create table alter add drop index view procedure proc function
        schema type declare select from where and or not null int bigint smallint tinyint bit nvarchar varchar nchar char datetime
        datetime2 date time decimal numeric float real money varbinary binary uniqueidentifier xml text primary key constraint
        default unique identity go begin end if exists insert update delete into values set as on join left right inner outer
        order by group having top with nolock exec execute returns return case when then else max min sum count distinct
        cast convert isnull coalesce dbo sys object_id""".split()),
        bildirim=[(re.compile(r"\bCREATE\s+(?:OR\s+ALTER\s+)?(?:TABLE|VIEW|PROCEDURE|PROC|FUNCTION|INDEX|SCHEMA|TYPE|TRIGGER)\s+(?:[\w\[\]]+\.)*\[?(\w+)\]?", re.I), False),
                  (re.compile(r"\bALTER\s+TABLE\s+[\w.\[\]]+\s+ADD\s+\[?(\w+)\]?", re.I), False),
                  (re.compile(r"\bDECLARE\s+@(\w+)", re.I), False),
                  (re.compile(r"^\s*\[?(\w+)\]?\s+(?:int|bigint|smallint|tinyint|bit|n?varchar|n?char|datetime2?|date|time|decimal|numeric|float|real|money|varbinary|binary|uniqueidentifier|xml|n?text|image)\b", re.I | re.M), False)]),
}
DIL_PROFILLERI[".mjs"] = DIL_PROFILLERI[".cjs"] = DIL_PROFILLERI[".ts"] = DIL_PROFILLERI[".js"]
DIL_PROFILLERI[".psm1"] = DIL_PROFILLERI[".ps1"]
DESTEKLENEN_UZANTILAR = tuple(DIL_PROFILLERI)
BILESEN_UZANTILARI = (".css", ".html", ".htm")      # yalnız bileşen katmanı tarar (1.8.0)


def profil_bul(yol: Path) -> dict | None:
    return DIL_PROFILLERI.get(yol.suffix.lower())


# ── TEST METODU ADI TARANMAZ (1.7.2, 24.09.2026 — Solum ölçümü) ─────────────────────────────
# Solum'da 381 dosya: 4087 bulgunun %78'i (2864) TEST METODU ADIydı; src/ yalnız %9. Bir test adı çağrılmaz,
# tek okunduğu yer koşucu çıktısıdır — yani İNSAN MESAJI (yorum/UI sınıfı, Türkçe kalır; naming-conventions §4
# "test adı okunur cümle, dil serbest"). 2864 gürültü bastırma öğretir, bastırma kuralı öldürür. Sınır NİYETTEN
# değil ÖLÇÜLEBİLİR işaretten: C#'ta test özniteliği ([Fact]/[Theory]/[Test]/[TestMethod]…) taşıyan metodun ADI,
# Python'da `def test_*` ADI yerine nötr `TestCase`/`test_case` konur; GÖVDE ve sınıf adı taranmaya devam eder.
# JS/Pester testleri zaten dize (`it("…")`, `It "…"`), ayrıca iş gerekmez.
TEST_OZNITELIK = re.compile(r"^\s*\[(?:Fact|Theory|Test|TestMethod|DataTestMethod|TestCase|InlineData|MemberData|ClassData|Trait|Category)\b")
CS_METOT = re.compile(r"^(\s*(?:public|private|internal|protected)\s+(?:static\s+|async\s+|virtual\s+|override\s+)*[\w<>\[\],?.]+\s+)(\w+)(\s*\()")
PY_TEST = re.compile(r"\bdef\s+test_\w+")


def test_adlarini_maskele(temiz: str, uzanti: str) -> str:
    if uzanti == ".py":
        return PY_TEST.sub("def test_case", temiz)
    if uzanti != ".cs":
        return temiz
    out, bekleyen = [], False
    for satir in temiz.split("\n"):
        if TEST_OZNITELIK.match(satir):
            bekleyen = True; out.append(satir); continue
        if bekleyen:
            m = CS_METOT.match(satir)
            if m:
                satir = m.group(1) + "TestCase" + m.group(3) + satir[m.end():]; bekleyen = False
            elif satir.strip():
                bekleyen = False          # öznitelikten sonra başka bir şey geldi
        out.append(satir)
    return "\n".join(out)


def _parametre_adlari(liste: str) -> list[str]:
    """`a, b = 1, *args, [tip]$Ad, x: int = 3` → ad listesi. Varsayılan/tip/yıkıcı kırpılır."""
    adlar = []
    for parca in liste.split(","):
        parca = re.sub(r"=.*$", "", parca.strip())          # varsayılan değer
        parca = re.sub(r"\[[^\]]*\]", " ", parca)           # [tip]
        parca = re.sub(r":.*$", "", parca)                   # tip ipucu (py)
        m = re.search(r"[$*]*([A-Za-z_]\w*)\s*$", parca)
        if m:
            adlar.append(m.group(1))
    return adlar


KOD_BLOK_BAS = re.compile(r"@(?:code|functions)\s*\{")


def _kod_blok_satirlari(metin: str) -> set:
    """`@code { … }` / `@functions { … }` gövdesinin 1-tabanlı satır numaraları.

    ⚠ BU BLOK 19.09'A KADAR HİÇ DENETLENMEDİ. `RAZOR_IFADE` deseni `@code`i
      tek sözcük olarak eşleyip GÖVDEYİ atıyordu; dashboard'ın .razor
      dosyalarında ise C#'ın TAMAMI orada durur. Yani kapı ".razor taranıyor"
      derken yalnız markup'taki `@Ifade` referanslarını görüyordu — bildirimleri
      DEĞİL. Kırmızı kip koşulmasaydı görülmezdi: `private int SatirSayisi`
      eklendi, kapı YEŞİL kaldı.
      Sınıf: `test-discipline.md` § YAZILI KURAL ≠ UYGULANAN KURAL.

    Süslü parantez sayımı yorum/dize AYIKLANDIKTAN sonra yapılır — yoksa
    bir dizedeki `}` bloğu erken kapatır.
    """
    satirlar = set()
    for m in KOD_BLOK_BAS.finditer(metin):
        i = m.end() - 1
        derinlik = 0
        while i < len(metin):
            if metin[i] == "{":
                derinlik += 1
            elif metin[i] == "}":
                derinlik -= 1
                if derinlik == 0:
                    break
            i += 1
        bas = metin.count(chr(10), 0, m.start()) + 1
        son = metin.count(chr(10), 0, min(i, len(metin) - 1)) + 1
        satirlar.update(range(bas, son + 1))
    return satirlar


def soyutla(metin: str, razor: bool, profil: dict | None = None):
    """(temiz metin, @code gövde satırları) döner.

    Razor'da iki AYRI bölge vardır ve aynı muameleyi göremezler:
      • markup  — UI metni Türkçe OLMALI; yalnız `@Ifade` referansları koddur.
      • @code   — düpedüz C#; harf taraması dahil TAM denetim görür.
    """
    yorum = (profil or {}).get("yorum", YORUM)
    dize = (profil or {}).get("dize", DIZE)
    metin = yorum.sub(_satir_koru, metin)
    metin = dize.sub(_satir_koru, metin)
    if not razor:
        return metin, set()
    kod_satir = _kod_blok_satirlari(metin)
    return chr(10).join(
        satir if i in kod_satir else " ".join(RAZOR_IFADE.findall(satir))
        for i, satir in enumerate(metin.splitlines(), 1)), kod_satir


def kod_kismi(metin: str, razor: bool) -> str:
    """Kod DIŞINI çıkar. Razor'da tersi: yalnız `@` ifadelerini TUT."""
    metin = YORUM.sub(_satir_koru, metin)
    metin = DIZE.sub(_satir_koru, metin)
    if razor:
        # satır yapısını koru: her satırda yalnız @ifadelerini bırak
        return chr(10).join(" ".join(RAZOR_IFADE.findall(satir)) for satir in metin.splitlines())
    return metin


def ihlaller(yol: Path) -> list[tuple[int, str, str]]:
    # ⚠ Razor'da TÜRKÇE HARF denetimi YAPILMAZ: UI metni Türkçe harf doludur ve
    #   kalan HTML parçalarını koddan ayırmak güvenilir değil. Razor'da yalnız
    #   KELİME listesi aranır (tanımlayıcı adları). C#'ta ikisi de aranır.
    razor = yol.suffix.lower() in (".cshtml", ".razor")
    if yol.suffix.lower() in BILESEN_UZANTILARI:
        return []                              # .css/.html: yalnız bileşen katmanı (UI metni Türkçe harf doludur)
    ham = io.open(yol, encoding="utf-8-sig", errors="replace").read()
    bulgular: list[tuple[int, str, str]] = []

    # Dosya adı
    ad = yol.stem
    for k in TURKCE_KELIMELER:
        if re.search(rf"{k}", ad) and ad not in DOSYA_ADI_ISTISNALARI:
            bulgular.append((0, ad, f"dosya adı Türkçe: {k}"))
            break

    satirlar = ham.splitlines()
    temiz_metin, kod_satir = soyutla(ham, razor, profil_bul(yol))
    temiz_metin = test_adlarini_maskele(temiz_metin, yol.suffix.lower())
    temiz = temiz_metin.splitlines()
    for i, satir in enumerate(temiz, 1):
        if not satir.strip():
            continue
        # Harf taraması: C# dosyasının tamamında, razor'da YALNIZ @code gövdesinde
        # (markup'ta Türkçe harf UI metnidir, ihlal değil).
        for ch in (satir if (not razor or i in kod_satir) else ""):
            if ch in TURKCE_HARF:
                bulgular.append((i, satirlar[i - 1].strip()[:90], f"tanımlayıcıda Türkçe harf '{ch}'"))
                break
        else:
            for k in TURKCE_KELIMELER:
                if re.search(rf"\b\w*{k}\w*\b", satir):
                    eslesen = re.search(rf"\b\w*{k}\w*\b", satir).group(0)
                    # Alan adları (ürün/şirket) serbest — `.claude/turkce-kapi.json`
                    if eslesen in ALAN_ADLARI:
                        continue
                    bulgular.append((i, satirlar[i - 1].strip()[:90], f"Türkçe tanımlayıcı: {eslesen}"))
                    break
    return bulgular


def bilinmeyen_sozcukler(yol: Path, dagarcik: set) -> list:
    """Ak liste denetimi: bildirilen adlardaki sozcukler dagarcikta var mi?

    UYARI  KARA LISTEDEN FARKI BU: kara liste "su kelime yasak" der ve listede
      olmayan Turkce kelimeyi HIC gormez. Ak liste "bu sozcugu tanimiyorum" der —
      yani eksikligi INSANA SORAR. Yanlis pozitifin bedeli bir satir eklemek,
      yanlis negatifin bedeli gorunmeyen bir ihlal.
    """
    uzanti = yol.suffix.lower()
    profil = profil_bul(yol)
    if profil is None or uzanti == ".cshtml":
        return []   # .cshtml'de bildirim yok; markup adlarini taramak gurultu uretir
    ham = io.open(yol, encoding="utf-8-sig", errors="replace").read()
    temiz, kod_satir = soyutla(ham, razor=(uzanti == ".razor"), profil=profil)
    temiz = test_adlarini_maskele(temiz, uzanti)
    # Dil desenleri (1.7.0): C#/Razor mevcut desenler; ötekiler profilden. Anahtar sözcükler dile göre.
    desenler = [(d, False) for d in BILDIRIM_DESENLERI] if profil["bildirim"] is None else profil["bildirim"]
    anahtar = CS_ANAHTAR | profil["anahtar"]
    if uzanti == ".razor":
        # Ak liste yalniz @code GOVDESINE bakar: markup'ta bildirim yoktur ve
        # `@Ifade` referanslarini bildirim sanmak gurultu uretir.
        temiz = chr(10).join(satir if i in kod_satir else ""
                             for i, satir in enumerate(temiz.splitlines(), 1))
    satirlar = ham.splitlines()

    bulgular = []
    gorulen = set()
    for desen, param_listesi in desenler:
        for m in desen.finditer(temiz):
            adlar = _parametre_adlari(m.group(1)) if param_listesi else [m.group(1)]
            satir_no = temiz[:m.start()].count(chr(10)) + 1
            for ad in adlar:
              if ad.lower() in anahtar:
                continue
              for w in SOZCUK_PARCA.findall(ad.replace("-", " ")):
                wl = w.lower()
                # ⚠ ALAN ADLARI BURADA DA GEÇERLİ (23.09.2026, sınamada yakalandı).
                #   `alan_adlari` önce yalnız kara liste katmanında okunuyordu; ak
                #   liste katmanı aynı adı "tanımıyorum" diye KIRIK veriyordu. Ayar
                #   "serbest" diyor, kapı kırıyordu — yarım taşınmış soyutlama, hiç
                #   taşınmamıştan kötüdür (`test-discipline` § yarım taşıma).
                if len(wl) < 2 or wl.isdigit() or wl in anahtar or wl in dagarcik \
                        or wl in ALAN_ADLARI_KUCUK:
                    continue
                if wl in gorulen:
                    continue
                gorulen.add(wl)
                metin = satirlar[satir_no - 1].strip()[:90] if satir_no <= len(satirlar) else ""
                bulgular.append((satir_no, metin, "ak listede YOK: '%s' (ad: %s)" % (w, ad)))
    return bulgular


# ── BİÇİM KATMANI (1.8.0) ─────────────────────────────────────────────────────
# Bildirilen adın biçimi dile uymalı. Yalnız bildirim desenlerinin yakaladığı adlar (ak liste katmanıyla aynı yüzey).
# Sınırlar bilerek: C# alanı `_camel` serbest; PS değişkeni Pascal ya da camel (param/yerel ayrımı desenle güvenilir değil);
# SQL kısıt önekleri PK_/IX_/FK_/DF_/UQ_/CK_ serbest; tek harf ve sayı-eki serbest. Test adları zaten maskeli.
import re as _re
PASCAL = _re.compile(r"^[A-Z][A-Za-z0-9]*$")
CAMEL = _re.compile(r"^[a-z][A-Za-z0-9]*$")
SNAKE = _re.compile(r"^_{0,2}[a-z][a-z0-9_]*$")
UPPER = _re.compile(r"^_{0,2}[A-Z][A-Z0-9_]*$")
VERB_NOUN = _re.compile(r"^[A-Z][a-z]+-[A-Z][A-Za-z0-9]+$")
SQL_KISIT = _re.compile(r"^(PK|IX|FK|DF|UQ|CK)_")


def bicim_ihlali(ad: str, uzanti: str, desen_sira: int) -> str | None:
    """None = uygun; aksi hâlde beklenen biçim metni."""
    if len(ad) <= 1 or ad.isdigit():
        return None
    if uzanti in (".cs", ".razor"):
        return None if (PASCAL.match(ad) or _re.match(r"^_[a-z]\w*$", ad)) else "PascalCase (C# tür/üye; özel alan _camelCase)"
    if uzanti == ".py":
        if desen_sira == 0:                            # class
            return None if PASCAL.match(ad) else "PascalCase (Python sınıf)"
        if desen_sira == 1:                            # def
            return None if SNAKE.match(ad) else "snake_case (Python fonksiyon)"
        return None if (SNAKE.match(ad) or UPPER.match(ad)) else "snake_case (değişken) ya da UPPER_SNAKE (sabit)"
    if uzanti in (".js", ".mjs", ".cjs", ".ts"):
        return None if (CAMEL.match(ad) or PASCAL.match(ad) or UPPER.match(ad) or ad.startswith("$")) else "camelCase (JS) / PascalCase (sınıf) / UPPER_SNAKE (sabit)"
    if uzanti in (".ps1", ".psm1"):
        if "-" in ad:
            return None if VERB_NOUN.match(ad) else "Verb-Noun (PowerShell fonksiyon: Get-Item)"
        return None if (PASCAL.match(ad) or CAMEL.match(ad) or UPPER.match(ad)) else "PascalCase param / camelCase yerel (alt çizgi yok)"
    if uzanti == ".sql":
        return None if (PASCAL.match(ad) or SQL_KISIT.match(ad)) else "PascalCase (SQL tablo/kolon/yordam; kısıt PK_/IX_/FK_ öneki)"
    return None


def bicim_bulgulari(yol: Path) -> list[tuple[int, str, str]]:
    if not BICIM_ACIK:
        return []
    uzanti = yol.suffix.lower(); profil = profil_bul(yol)
    if profil is None or uzanti == ".cshtml":
        return []
    ham = io.open(yol, encoding="utf-8-sig", errors="replace").read()
    temiz, _ = soyutla(ham, razor=(uzanti == ".razor"), profil=profil)
    temiz = test_adlarini_maskele(temiz, uzanti)
    desenler = [(d, False) for d in BILDIRIM_DESENLERI] if profil["bildirim"] is None else profil["bildirim"]
    satirlar = ham.splitlines(); bulgular = []; gorulen = set()
    for sira, (desen, param_listesi) in enumerate(desenler):
        for m in desen.finditer(temiz):
            adlar = _parametre_adlari(m.group(1)) if param_listesi else [m.group(1)]
            satir_no = temiz[:m.start()].count(chr(10)) + 1
            for ad in adlar:
                if ad.lower() in (CS_ANAHTAR | profil["anahtar"]) or ad in gorulen or ad == "TestCase":
                    continue
                sebep = bicim_ihlali(ad, uzanti, sira)
                if sebep:
                    gorulen.add(ad)
                    metin = satirlar[satir_no - 1].strip()[:90] if satir_no <= len(satirlar) else ""
                    bulgular.append((satir_no, metin, f"biçim: '{ad}' → {sebep}"))
    return bulgular


# ── BİLEŞEN KATMANI (1.8.0) — CSS sınıfı / DOM id / data-* ───────────────────────────────────────
# naming-conventions.md §3: kebab-case · İngilizce (ak liste) · ilk parça TİP ÖNEKİ ya da durum (is-/has-) · -btn/-dugme
# soneki yasak. Kaynaklar: .css seçicileri; .html class="…"/id="…"; .js/.mjs class/id DİZELERİ (el('tag','sınıf'),
# $('#id'), classList.add('x'), querySelector('.x'/'#x'), getElementById('x'), className = '…'). Dizeler bilerek
# taranır — burada dize bir tanımlayıcıdır. HTML/CSS/JS'te başka dize taranmaz.
KEBAB = _re.compile(r"^[a-z][a-z0-9]*(-[a-z0-9]+)*$")
HEX_RENK = _re.compile(r"^[0-9a-fA-F]{3}$|^[0-9a-fA-F]{6}$|^[0-9a-fA-F]{8}$")
YASAK_SONEK = ("-btn", "-dugme", "-buton", "-button")
CSS_SECICI = _re.compile(r"(?<![\w-])([.#])([A-Za-z_][\w-]*)")
HTML_OZNITELIK = _re.compile(r'\b(?:class|id|for)\s*=\s*"([^"]+)"')
JS_BILESEN = [
    _re.compile(r"\bel\(\s*'[a-z0-9]+'\s*,\s*'([^']*)'"),
    _re.compile(r"\$\(\s*'#([\w-]+)'"),
    _re.compile(r"classList\.(?:add|remove|toggle|contains|replace)\(\s*'([^']*)'"),
    _re.compile(r"querySelector(?:All)?\(\s*'[.#]([\w-]+)"),
    _re.compile(r"getElementById\(\s*'([\w-]+)'"),
    _re.compile(r"className\s*=\s*'([^']*)'"),
    _re.compile(r'\b(?:class|id)="([^"]+)"'),          # JS içindeki HTML şablon parçaları
]
CSS_SOZDE = {"hover", "focus", "active", "root", "before", "after", "not", "first-child", "last-child", "nth-child",
             "disabled", "checked", "empty", "focus-visible", "focus-within", "visited", "link", "target", "placeholder"}


def _bilesen_adlari(yol: Path, ham: str) -> list[tuple[int, str]]:
    uzanti = yol.suffix.lower(); adlar = []
    def ekle(m_start, adlar_metni):
        satir_no = ham[:m_start].count(chr(10)) + 1
        for a in adlar_metni.split():
            adlar.append((satir_no, a))
    if uzanti == ".css":
        temiz = _re.sub(r"/\*.*?\*/", lambda m: chr(10) * m.group(0).count(chr(10)), ham, flags=_re.S)
        for m in CSS_SECICI.finditer(temiz):
            ad = m.group(2)
            if m.group(1) == "#" and HEX_RENK.match(ad):
                continue                       # renk, seçici değil
            if ad in CSS_SOZDE or ad.startswith("-"):
                continue
            ekle(m.start(), ad)
    elif uzanti in (".html", ".htm"):
        for m in HTML_OZNITELIK.finditer(ham):
            ekle(m.start(), m.group(1))
    elif uzanti in (".js", ".mjs", ".cjs", ".ts"):
        for desen in JS_BILESEN:
            for m in desen.finditer(ham):
                ekle(m.start(), m.group(1))
    return adlar


def bilesen_bulgulari(yol: Path, dagarcik: set) -> list[tuple[int, str, str]]:
    if BILESEN_AYAR is None or yol.suffix.lower() not in (".css", ".html", ".htm", ".js", ".mjs", ".cjs", ".ts"):
        return []
    ham = io.open(yol, encoding="utf-8-sig", errors="replace").read()
    satirlar = ham.splitlines(); bulgular = []; gorulen = set()
    for satir_no, ad in _bilesen_adlari(yol, ham):
        if not ad or ad in gorulen or ad.startswith("{") or ad.startswith("$"):
            continue
        gorulen.add(ad)
        metin = satirlar[satir_no - 1].strip()[:90] if satir_no <= len(satirlar) else ""
        sebepler = []
        if not KEBAB.match(ad):
            sebepler.append("kebab-case değil")
        if ad.endswith(YASAK_SONEK):
            sebepler.append("tip eki SONDA (btn-… biçiminde başa)")
        parcalar = ad.replace("_", "-").split("-")
        if KEBAB.match(ad) and parcalar[0] not in BILESEN_ONEKLERI:
            sebepler.append(f"ilk parça tip öneki değil ('{parcalar[0]}'; izinli: {' '.join(sorted(BILESEN_ONEKLERI))[:60]}…)")
        yabanci = [p for p in parcalar if p and not p.isdigit() and p.lower() not in dagarcik and p.lower() not in ALAN_ADLARI_KUCUK]
        if yabanci:
            sebepler.append("ak listede YOK: " + ", ".join(f"'{p}'" for p in yabanci[:3]))
        if sebepler:
            bulgular.append((satir_no, metin, f"bileşen '{ad}': " + " · ".join(sebepler)))
    return bulgular


# ── BAYRAKLAR (1.7.0) ─────────────────────────────────────────────────────────
# --tabansiz : tabanı YOK say — "dokunulan dosya tamamen temiz olmalı" kuralı için (bkm-magaza, GMY 24.09:
#              "dokundukça o dosyadaki her şeyi düzelt"). Kanca staged dosyaları bu bayrakla verir; taban
#              yalnız süpürme/haritada borcu göstermeye yarar. Dokunulmayan dosyaya kimse bakmaz.
BAYRAKLAR = {a for a in sys.argv[1:] if a.startswith("--")}
TABANSIZ = "--tabansiz" in BAYRAKLAR
HEPSI = "--hepsi" in BAYRAKLAR      # bulguların tamamını bas (harita/toplu çeviri için); varsayılan ilk 6
ARGUMANLAR = [a for a in sys.argv[1:] if not a.startswith("--")]
hedefler: list[Path] = []
if ARGUMANLAR:
    hedefler = [Path(a) for a in ARGUMANLAR if Path(a).exists() and Path(a).suffix.lower() in DESTEKLENEN_UZANTILAR + BILESEN_UZANTILARI]
else:
    ATLANAN = {"obj", "bin", "node_modules", ".git", "dist", "www"}
    for k in KAPSAM:
        for uzanti in SUPURME_UZANTILARI:
            hedefler += [p for p in (KOK / k).rglob("*" + uzanti)
                         if not (ATLANAN & set(p.parts))]

if not hedefler:
    if ARGUMANLAR:
        print("KOŞAMADI  verilen yolların hiçbiri yok ya da uzantısı desteklenmiyor "
              f"({', '.join(DESTEKLENEN_UZANTILAR)}) — dosya adlarını kontrol et")
    elif not KAPSAM:
        # ⚠ AYARSIZ SÜPÜRME SESSİZ YEŞİL VERMEZ. Kapsamı boş bir kapı "0 bulgu,
        #   geçti" derse kurulu GÖRÜNÜR ama hiçbir şeye bakmıyordur.
        print(f"KOŞAMADI  kapsam tanımlı değil — {AYAR_DOSYASI} yok ya da 'kapsam' boş.")
        print(f"          Kök şu bulundu: {KOK}")
        print('          Örnek: {"kapsam": ["src", "tests"], "alan_adlari": ["Urun"]}')
        print("          (Kancalar dosya adlarını argüman verir; o kip ayarsız da çalışır.)")
    else:
        print(f"KOŞAMADI  taranacak dosya bulunamadı — kapsam yolları değişmiş olabilir: {KAPSAM}")
    sys.exit(2)

print("═" * 74)
print("TÜRKÇE TANIMLAYICI DENETİMİ — kod İngilizce, UI/yorum Türkçe")
print("═" * 74)

DAGARCIK = dagarcigi_yukle()
if DAGARCIK is None:
    print(f"KOSAMADI  ak liste okunamadi ({SOZLUK_DOSYASI}) — kapinin ikinci "
          "yarisi CALISMIYOR demektir; sessizce kara listeye dusmek YASAK")
    sys.exit(2)

TABAN = taban_yukle()


def tabanli_mi(yol: Path) -> bool:
    rel = yol.relative_to(KOK).as_posix() if str(yol).startswith(str(KOK)) else yol.as_posix()
    return rel.startswith(TABANLI_KOKLER)


toplam = 0
dondurulan = 0      # tabanin ALTINDA ya da ESIT kalan (borc, yeni ihlal degil)
gevseyen = []       # taban DUSMUS: tabani sikistirma firsati
for p in sorted(hedefler):
    b = ihlaller(p) + bilinmeyen_sozcukler(p, DAGARCIK) + bicim_bulgulari(p) + bilesen_bulgulari(p, DAGARCIK)
    rel = p.relative_to(KOK).as_posix() if str(p).startswith(str(KOK)) else p.as_posix()
    izin = 0 if TABANSIZ else (TABAN.get(rel, 0) if tabanli_mi(p) else 0)

    if len(b) <= izin:
        # Taban ALTINDA ya da esit — bu bir BORC, yeni ihlal degil.
        dondurulan += len(b)
        if len(b) < izin:
            gevseyen.append((rel, izin, len(b)))
        continue

    asim = b[izin:] if izin else b
    toplam += len(asim)
    print(f"\nKIRIK {_gosterim(p)}" + (f"  (taban {izin}, şimdi {len(b)})" if izin else ""))
    for satir, metin, sebep in (asim if HEPSI else asim[:6]):
        print(f"   satır {satir:>4}: {sebep}")
        if metin:
            print(f"              {metin}")
    if len(asim) > 6 and not HEPSI:
        print(f"   … {len(asim) - 6} bulgu daha")

print()
if toplam:
    print(f"KIRIK · {toplam} bulgu. Kod İngilizce olmalı (turkish-ui.md); yorum ve UI")
    print("        metni Türkçe KALIR — bu kapı onlara dokunmaz.")
    print("        'ak listede YOK' bulgusu iki seçenek sunar: sözcük İngilizceyse")
    print(f"        {EK_SOZLUK_DOSYASI} dosyasina BİR SATIR ekle, Türkçeyse ÇEVİR.")
    sys.exit(1)
if gevseyen:
    print(f"BİLGİ  {len(gevseyen)} dosya tabanının ALTINDA — tabanı SIKIŞTIR "
          f"({TABAN_DOSYASI}). Çırcır ancak sıkıştırılırsa ilerler.")
    for rel, izin, simdi in gevseyen[:5]:
        print(f"       · {rel}: {izin} → {simdi}")
print(f"Denetim geçti · {len(hedefler)} dosya · ak liste {len(DAGARCIK)} sözcük · "
      f"dondurulmuş borç {dondurulan} bulgu ({len(TABAN)} dosya)")
