# PostToolUse hook (PowerShell) — tool ciktisi >50 satir ise journal'a uyari ekle.
# Buyuk cikti baglami hizla doldurur; farkindalik icin log.
$ErrorActionPreference = 'SilentlyContinue'
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $j = $raw | ConvertFrom-Json } catch { exit 0 }

$tool = $j.tool_name
$out = $j.tool_response.output
if (-not $out) { exit 0 }
$lines = ([regex]::Matches([string]$out, "`n")).Count + 1
if ($lines -le 50) { exit 0 }

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$today = Get-Date -Format 'yyyy-MM-dd'
$jdir = Join-Path $root 'docs\journal'
New-Item -ItemType Directory -Force $jdir | Out-Null
$journal = Join-Path $jdir "$today.md"
if (-not (Test-Path $journal)) { "# Oturum Gunlugu - $today`n" | Out-File $journal -Encoding utf8 }
if (-not (Select-String -Path $journal -Pattern '^## Buyuk Tool Ciktilari' -Quiet)) {
    "`n## Buyuk Tool Ciktilari`n" | Out-File $journal -Append -Encoding utf8
}
"- $(Get-Date -Format HH:mm): ``$tool`` -> $lines satir (>50)" | Out-File $journal -Append -Encoding utf8
exit 0
