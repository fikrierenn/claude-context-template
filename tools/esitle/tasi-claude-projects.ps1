<#
.SYNOPSIS
  Claude oturum geçmişini (~/.claude/projects) başka sürücüye taşır, eski yere bağlantı (junction) koyar.

.DESCRIPTION
  Claude geçmişi yalnız ~/.claude/projects'ten okur. Klasör D:'ye taşınır, C:'deki yol junction olur:
  Claude aynı yolu görür, veri fiziksel olarak D:'de durur (18.11.2026: BT-FIKRI C: 8,5 GB boş).

  Güvenlik:
  - Claude (masaüstü ve CLI) KAPALI olmalı; açık oturum dosyaya yazarken taşınmaz.
  - Varsayılan kip yalnız rapor verir. -Uygula ile çalışır.
  - Kopya sonrası dosya sayısı ve toplam bayt karşılaştırılır; tutmazsa hiçbir şey değişmez.
  - Eski klasör SİLİNMEZ: projects.esitle-eski-<tarih> adıyla kalır. Doğrulayınca elle silinir.
  - Geri alma: -GeriAl (junction kaldırılır, eski klasör adına döner).

.EXAMPLE
  powershell -ExecutionPolicy RemoteSigned -File tasi-claude-projects.ps1                  # rapor
  powershell -ExecutionPolicy RemoteSigned -File tasi-claude-projects.ps1 -Uygula          # taşı
  powershell -ExecutionPolicy RemoteSigned -File tasi-claude-projects.ps1 -GeriAl          # geri al
#>
[CmdletBinding()]
param(
    [string]$Hedef = 'D:\claude\projects',
    [switch]$Uygula,
    [switch]$GeriAl
)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$kaynak = Join-Path $env:USERPROFILE '.claude\projects'

function Get-Olcum {
    param([string]$Yol)
    $m = Get-ChildItem -LiteralPath $Yol -Recurse -File -Force | Measure-Object Length -Sum
    return [pscustomobject]@{ Dosya = $m.Count; Bayt = [long]$m.Sum }
}

function Test-ClaudeAcik {
    $p = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(claude|Claude)$' })
    return ($p.Count -gt 0)
}

if ($GeriAl) {
    $item = Get-Item -LiteralPath $kaynak -Force
    if ($item.LinkType -ne 'Junction') { throw "$kaynak bir junction degil; geri alinacak bir sey yok." }
    $eski = @(Get-ChildItem (Split-Path -Parent $kaynak) -Directory -Force | Where-Object { $_.Name -like 'projects.esitle-eski-*' } | Sort-Object Name -Descending)
    if ($eski.Count -eq 0) { throw "Eski klasor (projects.esitle-eski-*) bulunamadi; elle bakin." }
    if (Test-ClaudeAcik) { throw "Claude acik. Kapatip tekrar calistirin." }
    cmd /c rmdir "$kaynak" | Out-Null
    Rename-Item -LiteralPath $eski[0].FullName -NewName 'projects'
    Write-Host "Geri alindi: $kaynak yeniden gercek klasor ($($eski[0].Name) adindan). D: kopyasi yerinde duruyor: $Hedef"
    return
}

$item = Get-Item -LiteralPath $kaynak -Force
if ($item.LinkType -eq 'Junction') {
    Write-Host "Zaten tasinmis: $kaynak -> $($item.Target -join ',')"
    return
}
$olc = Get-Olcum $kaynak
$surucu = (Split-Path -Qualifier $Hedef)
$bos = (New-Object -ComObject Scripting.FileSystemObject).GetDrive($surucu).FreeSpace
Write-Host ("Kaynak : {0}  ({1} dosya, {2:N0} MB)" -f $kaynak, $olc.Dosya, ($olc.Bayt / 1MB))
Write-Host ("Hedef  : {0}  ({1} bos {2:N1} GB)" -f $Hedef, $surucu, ($bos / 1GB))
if ($bos -lt ($olc.Bayt * 1.2)) { throw "Hedef surucude yer yetmiyor." }
if (Test-Path -LiteralPath $Hedef) {
    if (@(Get-ChildItem -LiteralPath $Hedef -Force).Count -gt 0) { throw "Hedef bos degil: $Hedef. Once bakin." }
}
if (-not $Uygula) {
    Write-Host "Rapor kipi. Tasimak icin Claude'u kapatip -Uygula ile calistirin."
    return
}
if (Test-ClaudeAcik) { throw "Claude acik (masaustu ya da CLI). Kapatip tekrar calistirin; acik oturum dosyaya yaziyor olabilir." }

New-Item -ItemType Directory -Force $Hedef | Out-Null
& robocopy $kaynak $Hedef /E /COPY:DAT /DCOPY:DAT /R:1 /W:1 /NP /NFL /NDL /NJH | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy hata kodu $LASTEXITCODE; hicbir sey degistirilmedi (kaynak yerinde)." }
$hed = Get-Olcum $Hedef
if ($hed.Dosya -ne $olc.Dosya -or $hed.Bayt -ne $olc.Bayt) {
    throw ("Dogrulama tutmadi: kaynak {0}/{1} bayt, hedef {2}/{3} bayt. Kaynak yerinde, junction kurulmadi." -f $olc.Dosya, $olc.Bayt, $hed.Dosya, $hed.Bayt)
}
$eskiAd = 'projects.esitle-eski-' + (Get-Date -Format 'ddMMyyyy-HHmmss')
Rename-Item -LiteralPath $kaynak -NewName $eskiAd
cmd /c mklink /J "$kaynak" "$Hedef" | Out-Null
if (-not ((Get-Item -LiteralPath $kaynak -Force).LinkType -eq 'Junction')) {
    Rename-Item -LiteralPath (Join-Path (Split-Path -Parent $kaynak) $eskiAd) -NewName 'projects'
    throw "Junction kurulamadi; eski klasor geri adlandirildi."
}
Write-Host ("Tasindi: {0} dosya, {1:N0} MB -> {2}" -f $hed.Dosya, ($hed.Bayt / 1MB), $Hedef)
Write-Host "C: yolu artik junction. Eski kopya: $(Join-Path (Split-Path -Parent $kaynak) $eskiAd)"
Write-Host "Claude'u acip bir oturumu --resume ile dogrulayin; sonra eski kopyayi elle silin."
