# PreToolUse(Bash) hook — git guard (Windows/PowerShell).
# Kaynak fikir: ECC (github.com/affaan-m/ECC) block-no-verify.js — PS'e uyarlandi.
# Hook bypass (--no-verify, -n, core.hooksPath=) + tehlikeli git komutlarini bloklar.
# exit 0 -> izin ver | exit 2 -> BLOKLA (stderr mesaji Claude'a gider).
# Bypass (kullanici onayindan sonra): CLAUDE_GITGUARD_SKIP=1
$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if ($env:CLAUDE_GITGUARD_SKIP -eq '1') { exit 0 }

$raw = [Console]::In.ReadToEnd()
$cmd = ''
try { $cmd = ($raw | ConvertFrom-Json).tool_input.command } catch { $cmd = $raw }
if (-not $cmd) { exit 0 }
if ($cmd -notmatch '(^|[\s&;|(])git(\s|$)') { exit 0 }

# Quoted string icerigini maskele (commit mesajindaki "--no-verify" yanlis pozitif olmasin)
$masked = $cmd -replace "'[^']*'", "''" -replace '"[^"]*"', '""'

function Block-Cmd([string]$reason) {
    [Console]::Error.WriteLine('=== GIT GUARD: BLOKLANDI ===')
    [Console]::Error.WriteLine("  X $reason")
    [Console]::Error.WriteLine('')
    [Console]::Error.WriteLine('Bu komut commit-discipline kuralina aykiri. Gercekten gerekliyse')
    [Console]::Error.WriteLine('kullanicidan ACIK ONAY al; onay sonrasi bypass:')
    [Console]::Error.WriteLine('  CLAUDE_GITGUARD_SKIP=1 <komut>')
    exit 2
}

# 1. Hook bypass
if ($masked -match '(^|\s)--no-verify(\s|$)') {
    Block-Cmd "--no-verify: git hook'lari bypass edilemez"
}
if ($masked -match 'git\s+commit[^;|&]*\s-n(\s|$)') {
    Block-Cmd "git commit -n (--no-verify kisaltmasi): hook bypass edilemez"
}
if ($masked -match '(?i)-c\s*core\.hookspath=') {
    Block-Cmd 'core.hooksPath override: hook bypass edilemez'
}

# 2. Tehlikeli git komutlari (commit-discipline.md listesi)
if ($masked -match 'git\s+push[^;|&]*\s(--force|-f)(\s|$)' -and $masked -notmatch '--force-with-lease') {
    Block-Cmd 'git push --force: history yeniden yazar (--force-with-lease degerlendir)'
}
if ($masked -match 'git\s+reset[^;|&]*--hard') {
    Block-Cmd 'git reset --hard: uncommitted is kaybolur'
}
if ($masked -match 'git\s+clean[^;|&]*\s-[a-zA-Z]*f') {
    Block-Cmd 'git clean -f: untracked dosyalar silinir'
}
if ($masked -match 'git\s+(checkout|restore)\s+\.(\s|$)') {
    Block-Cmd 'git checkout/restore . : tum degisiklikler atilir'
}

exit 0
