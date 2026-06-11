# PreToolUse(Bash) hook — `git commit` oncesi antipattern tarayici (Windows/PowerShell).
# settings.json PreToolUse(Bash) ile bagli. stdin'den JSON okur: { tool_input: { command } }.
# Sadece `git commit` komutunda staged dosyalari tarar.
# exit 0 -> izin ver | exit 2 -> commit'i BLOKLA (stdout mesaji user'a gider).
$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- stdin JSON -> komut ---
$raw = [Console]::In.ReadToEnd()
$cmd = ''
try { $cmd = ($raw | ConvertFrom-Json).tool_input.command } catch { $cmd = $raw }
if ($cmd -notmatch '(^|[\s&;])git\s+commit(\s|$)') { exit 0 }

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $root

$staged = git diff --cached --name-only --diff-filter=ACM 2>$null
if (-not $staged) { exit 0 }

$violations = @()
foreach ($f in $staged) {
    if (-not (Test-Path $f)) { continue }
    $c = Get-Content $f -Raw -Encoding UTF8
    $ext = [System.IO.Path]::GetExtension($f)

    # --- C# antipatterns ---
    if ($ext -eq '.cs') {
        if ($c -match 'catch\s*\([^)]*\)\s*\{\s*\}') {
            $violations += "$f : bos catch — logla ya da yeniden firlat"
        }
        if ($c -match '(TempData\[|ViewBag\.|Error\s*=|Message\s*=).*ex\.Message') {
            $violations += "$f : ex.Message kullaniciya sizinti — generic mesaj + ILogger kullan"
        }
        if ($c -match 'DateTime\.Now\b') {
            $violations += "$f : DateTime.Now — DateTime.UtcNow kullan"
        }
        if ($c -match 'new\s+HttpClient\s*\(') {
            $violations += "$f : new HttpClient() — IHttpClientFactory / typed client kullan"
        }
        if ($c -match 'async\s+void\b' -and $c -notmatch 'EventArgs') {
            $violations += "$f : async void — event handler disinda yasak"
        }
        if ($c -match '(Query|Execute)\w*\s*[<(][^;]*\$"') {
            $violations += "$f : Dapper string interpolation — SQLi riski, @Param kullan"
        }
    }

    # --- View antipatterns ---
    if ($ext -eq '.cshtml' -or $ext -eq '.html' -or $ext -eq '.razor') {
        $inline = [regex]::Matches($c, 'style="[^"]*"') | Where-Object { $_.Value -notmatch '@' }
        if ($inline.Count -gt 0) {
            $violations += "$f : $($inline.Count) statik inline style — utility class kullan"
        }
    }

    # --- JS antipatterns ---
    if ($ext -eq '.js' -or $ext -eq '.ts') {
        if ($c -match 'console\.log\(') {
            $violations += "$f : console.log — production'da kaldir"
        }
        if ($c -match 'debugger\b') {
            $violations += "$f : debugger ifadesi — kaldir"
        }
    }

    # --- Python antipatterns ---
    if ($ext -eq '.py') {
        if ($c -match 'except\s*:') {
            $violations += "$f : bare except — spesifik exception yaz"
        }
        if ($c -match 'print\s*\(') {
            $violations += "$f : print() — logging modulu kullan"
        }
    }

    # --- Secret (tum dosyalar) ---
    if ($c -match 'Password=[A-Za-z0-9!@#\$%\^&\*\+\._-]{4,}' -or
        $c -match '(AIza[0-9A-Za-z_-]{20}|gsk_[0-9A-Za-z]{20}|sk-[A-Za-z0-9]{40}|AKIA[0-9A-Z]{16})') {
        $violations += "$f : hardcoded secret/sifre — env var veya secrets manager kullan"
    }
}

if ($violations.Count -gt 0) {
    Write-Output "=== PRE-COMMIT ANTIPATTERN: BLOKLANDI ==="
    $violations | ForEach-Object { Write-Output "  X $_" }
    Write-Output ""
    Write-Output "Duzelt sonra commit. Override: git commit --no-verify (ihlali journal'a yaz)."
    exit 2
}
exit 0
