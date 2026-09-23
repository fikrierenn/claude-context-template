#Requires -Version 5.1
<#
.SYNOPSIS
    Merkez deposunu `claude-context-template` -> `Norma` olarak yeniden adlandirir
    ve eski adi JUNCTION olarak birakir.

.DESCRIPTION
    GMY karari (23.09.2026): ad `Norma`. Gerekce Latince/Turkce katman ayrimi —
    Latince altyapiya (Solum = zemin, Norma = gonye), Turkce urune (pusula, mizan,
    odak). Ad, hangi katmanda oldugunu kendisi soyler.

    NEDEN JUNCTION: ekosistemde eski adla yazilmis ~51 CANLI referans var. Duz
    yeniden adlandirma hepsini ayni anda kirardi. Junction, eski adi calisir
    tutar; referanslar depo depo duzeldikce junction silinir.
    Bir tuketicinin koydugu sart buydu: "aradaki pencerede eski ad calismaya
    devam etmeli."

    ⚠ BU BETIK NEDEN VAR (yani neden elle yapilmiyor): yeniden adlandirma, dizini
    ACIK TUTAN hicbir surec olmadiginda calisir. Merkez deposunda calisan bir
    Claude oturumunun kendi calisma dizini oradadir ve kendi kilidinden KACAMAZ —
    olculdu (23.09.2026), "Islem, baska bir islem tarafindan kullanildigindan
    dosyaya erisemiyor" hatasi alindi. Bu yuzden betik BASKA bir yerden kosar.

.EXAMPLE
    # D:\Dev'de (merkez deposunun ICINDE DEGIL) acilmis bir kabukta:
    powershell -NoProfile -ExecutionPolicy Bypass -File D:\Dev\claude-context-template\bin\ad-degistir.ps1

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\bin\ad-degistir.ps1 -WhatIf   # kuru kosum

.NOTES
    UYARI  -ExecutionPolicy Bypass SART ve orneklerde bilerek yazili. Bu makinede
      calistirma politikasi imzasiz betigi engelliyor ve sonuc YANILTICI: betigin
      KENDI on kontrolleri hic kosmaz, yani 'merkezin icinden kosuyorsun' uyarisini
      GORMEZSIN — yalnizca SecurityError gorursun ve sebebi yanlis yerde ararsin.
      Olculdu (23.09.2026, ilk kosum denemesi).
      Bayrak SURECE ozeldir: makinenin politikasini DEGISTIRMEZ. Politikayi kalici
      olarak gevsetmek bu betigin isi degildir.

    UYARI  KILIDI TUTAN, O DIZINDE ACILMIS HER SUREC OLABILIR — kendi kabugun dahil.
      Windows, bir surecin CALISMA DIZINI olan klasoru yeniden adlandirmaz.
      TANI: dizin ICINDEKI bir alt klasor yeniden adlandirilabiliyor ama TEPE dizin
      adlandirilamiyorsa, kilit bir DOSYA kilidi degil CWD kilididir.
      Olculdu: merkez deposunda acilmis bir Claude oturumu kilidi tutar ve calisma
      dizinini birakamaz (her komuttan sonra oraya geri sifirlanir). Terminali disari
      almak YETMEDI; o oturumun kapanmasi gerekti.
      Cozum: o dizinde acilmis TUM kabuklari ve oturumlari kapat, sonra kos.
#>
[CmdletBinding()]
param(
    [string]$Kok = 'D:\Dev',
    [string]$EskiAd = 'claude-context-template',
    [string]$YeniAd = 'Norma',
    [switch]$JunctionYok,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

# ⚠ HER YOL ISLEMI -LiteralPath. Olculdu: PowerShell `~` karakterini ev dizini
#   diye yorumluyor ve 8.3 kisa adli bir yol (FIKRI~1.ERE) Push-Location'i kiriyor.
#   Gercek kokte (D:\Dev) `~` yok, ama betigin dogrulugu fikstur sansina birakilmaz.

$eski = Join-Path $Kok $EskiAd
$yeni = Join-Path $Kok $YeniAd

function Durum($m) { Write-Host "  $m" }
function Kirmizi($m) { Write-Host $m -ForegroundColor Red }

Write-Host "`n=== MERKEZ ADI DEGISIMI: $EskiAd -> $YeniAd ===" -ForegroundColor Cyan

# --- ON KONTROLLER — hepsi gecmeden dokunulmaz -----------------------------
$hata = $false

if (-not (Test-Path -LiteralPath $eski)) { Kirmizi "YOK: $eski"; $hata = $true }

if (Test-Path -LiteralPath $yeni) {
    # Zaten yapilmis olabilir — idempotent davran.
    $li = (Get-Item -LiteralPath $eski -ErrorAction SilentlyContinue)
    if ($li -and $li.LinkType -eq 'Junction') {
        Write-Host "ZATEN YAPILMIS: $yeni gercek dizin, $EskiAd junction." -ForegroundColor Green
        exit 0
    }
    Kirmizi "HEDEF ZATEN VAR ve junction degil: $yeni"
    $hata = $true
}

# Calisma dizini merkezin ICINDE olmamali — kendi kilidini yaratir.
$buradayim = (Get-Location).Path
if ($buradayim -like "$eski*") {
    Kirmizi "BU KABUK MERKEZIN ICINDE: $buradayim"
    Kirmizi "  Yeniden adlandirma kendi kilidin yuzunden BASARISIZ olur."
    Kirmizi "  Cozum: '$Kok' altinda (ya da baska bir yerde) acilmis bir kabuktan kos."
    $hata = $true
}

# Commit edilmemis is varsa dokunma: yeniden adlandirma sirasinda bir sey ters
# giderse kaybi geri almak zorlasir.
if (-not $hata) {
    Push-Location -LiteralPath $eski
    try {
        # ⚠ OLCULEMEYEN TEMIZ SAYILMAZ. Ilk surum `git status` ciktisinin SATIR
        #   SAYISINA bakiyordu: git kosamazsa (UNC 'dubious ownership', git yok,
        #   yetki) cikti bos gelir, satir sayisi 0 olur ve betik "temiz" okur —
        #   sonra commit edilmemis is uzerinde yeniden adlandirma yapar.
        #   Sessizce yesil veren kontrol, kontrol degildir.
        $ciktiDurum = & git status --porcelain 2>&1
        $gitKodu = $LASTEXITCODE
        if ($gitKodu -ne 0) {
            Kirmizi "KOSAMADI: 'git status' basarisiz (cikis $gitKodu) — temizlik OLCULEMEDI."
            Kirmizi "  $($ciktiDurum | Select-Object -First 1)"
            Kirmizi "  Olculemeyen temiz sayilmaz. Once bunu duzelt (UNC icin:"
            Kirmizi "  git config --global --add safe.directory '%(prefix)///<sunucu>/<pay>/<depo>')"
            $hata = $true
        } else {
            $kirli = @($ciktiDurum | Where-Object { $_ -ne '' }).Count
            if ($kirli -gt 0) {
                Kirmizi "MERKEZDE $kirli COMMIT EDILMEMIS DOSYA VAR — once commit et."
                $hata = $true
            } else { Durum "git calisma dizini temiz (olculdu)" }
        }
    } finally { Pop-Location }
}

if ($hata) { Write-Host "`nDOKUNULMADI." -ForegroundColor Red; exit 2 }

if ($WhatIf) {
    Write-Host "`nKURU KOSUM — yapilacaklar:" -ForegroundColor Yellow
    Durum "1) $eski  ->  $yeni"
    if (-not $JunctionYok) { Durum "2) junction: $eski  ->  $yeni" }
    Durum "3) dogrulama: git + durum.sh her iki yoldan"
    exit 0
}

# --- UYGULA ----------------------------------------------------------------
Rename-Item -LiteralPath $eski -NewName $YeniAd
Durum "yeniden adlandirildi: $yeni"

if (-not $JunctionYok) {
    New-Item -ItemType Junction -Path $eski -Target $yeni | Out-Null
    Durum "junction kuruldu: $EskiAd -> $YeniAd"
}

# --- DOGRULA — yapildi demek yetmez ---------------------------------------
Write-Host "`nDogrulama:" -ForegroundColor Cyan
$tamam = $true

Push-Location -LiteralPath $yeni
try {
    $son = (& git log --oneline -1 2>$null)
    if ($son) { Durum "git (gercek yol): $son" } else { Kirmizi "  git GERCEK YOLDAN CALISMADI"; $tamam = $false }
} finally { Pop-Location }

if (-not $JunctionYok) {
    Push-Location -LiteralPath $eski
    try {
        $son2 = (& git log --oneline -1 2>$null)
        if ($son2) { Durum "git (junction): $son2" } else { Kirmizi "  git JUNCTION UZERINDEN CALISMADI"; $tamam = $false }
    } finally { Pop-Location }

    $li = Get-Item -LiteralPath $eski
    if ($li.LinkType -eq 'Junction') { Durum "link tipi: Junction" } else { Kirmizi "  link tipi Junction DEGIL: $($li.LinkType)"; $tamam = $false }
}

if (-not $tamam) {
    Kirmizi "`nDOGRULAMA GECMEDI — yukariya bak. Geri almak icin:"
    Kirmizi "  (Get-Item -LiteralPath '$eski').Delete()   # junction'i sil (ICERIGI SILMEZ)"
    Kirmizi "  Rename-Item '$yeni' -NewName '$EskiAd'"
    exit 1
}

Write-Host "`n=== TAMAM ===" -ForegroundColor Green
Write-Host @"
Sirada — junction KALICI DEGIL, silinmesi icin referanslar cevrilmeli:

  1. Bu deponun kendi ic referanslari (README, docs, bootstrap ornekleri)
  2. Tuketicilerdeki CANLI referanslar. SINIFLANDIRMA (olculdu 23.09.2026):
       canli referans     -> duzeltilir  (33'u tek satirlik CLAUDE.md isaretcisi,
                                          uretecini bir kez kosturmak yeter)
       tarihsel kayit     -> DOKUNULMAZ  (docs/journal/*, HANDOFF.md, plans/archive/*)
                                          o dosya o tarihte neyin dogru oldugunu
                                          kaydeder; adi degistirmek gecmisi tahrif eder
       worktree kopyasi   -> duzeltilmez, atilir
       gomulu sablon kopyasi -> Asama 3 isi
  3. settings.local.json'lardaki yollar — orada yanlis yol kapiyi SESSIZCE bozar
  4. Hepsi bitince junction'i sil:
       (Get-Item -LiteralPath '$eski').Delete()
     ⚠ `Remove-Item` KULLANMA: PS 5.1'de junction silerken onay sorar ve
       etkilesimsiz kabukta (hook, CI) sessizce BASARISIZ olur — olculdu.

Olcum: bash bin/durum.sh
"@
