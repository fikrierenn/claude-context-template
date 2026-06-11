# SessionStart hook — Windows PowerShell versiyonu
# settings.json'da SessionStart hook olarak kaydet (bash degil .ps1)

$ErrorActionPreference = 'SilentlyContinue'
$repo = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { Get-Location }
Set-Location $repo

$projectName = Split-Path $repo -Leaf

Write-Output "## $projectName — Oturum Basi Ozet"
Write-Output ""

Write-Output "### Son 3 gun commit'ler"
git log --since='3 days ago' --oneline 2>$null | Select-Object -First 10
Write-Output ""

Write-Output "### Uncommitted dosya sayisi"
$count = (git status --porcelain 2>$null | Measure-Object -Line).Lines
Write-Output "$count dosya"
if ($count -gt 15) {
    Write-Output ""
    Write-Output "UYARI: 15 dosya esigi asildi. Yeni is baslamadan once commit-split gerek."
}
Write-Output ""

if (Test-Path "TODO.md") {
    Write-Output "### Aktif TODO basliklari (ilk 20)"
    Select-String -Path "TODO.md" -Pattern '^### |^- \[ \]|^## ' | Select-Object -First 20 | ForEach-Object { $_.Line }
    Write-Output ""
}

# Son journal
if (Test-Path "docs/journal") {
    $last = Get-ChildItem "docs/journal/*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.md" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($last) {
        Write-Output "### En son journal — $($last.Name)"
        Get-Content $last.FullName | Select-Object -Last 40
        Write-Output ""
    }
}

# Statik kod sagligi
Write-Output "### Kod sagligi sinyalleri (statik)"
$newHttp = (Select-String -Path "**/*.cs" -Pattern "new HttpClient\(\)" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
if ($newHttp -gt 0) { Write-Output "- Antipattern: new HttpClient(): $newHttp" }

$emptyCatch = (Select-String -Path "**/*.cs" -Pattern "catch\s*\(.*\)\s*\{\s*\}" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
if ($emptyCatch -gt 0) { Write-Output "- Bos catch: $emptyCatch" }

$exMsg = (Select-String -Path "**/*.cs" -Pattern "ex\.Message" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
if ($exMsg -gt 0) { Write-Output "- ex.Message sizma riski: $exMsg" }

$inlineStyle = (Select-String -Path "**/*.cshtml", "**/*.html" -Pattern 'style="' -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
if ($inlineStyle -gt 0) { Write-Output "- Statik inline style: $inlineStyle olusum" }

Write-Output ""
Write-Output "---"
Write-Output "## CLAUDE — ILK YANIT ZORUNLU FORMAT"
Write-Output ""
Write-Output "Kullanicinin ilk mesajina cevap vermeden once asagidaki ozeti ver:"
Write-Output ""
Write-Output "  **[UNCOMMITTED: $count dosya]** $(if ($count -gt 15) { '⚠️ ESIK ASILDI' } else { '✓' })"
Write-Output "  **HIGH acik:** [TODO.md'den HIGH/CRITICAL maddeleri]"
Write-Output "  **Oncelik:** [TODO Faz 0'dan ilk 1-2 madde]"
Write-Output "  Ne yapiyoruz?"
Write-Output ""
Write-Output "Bu ozeti VERMEDEN kullanicinin sorusunu yanitlama."
Write-Output "---"
