# PreToolUse(Edit|Write) hook — linter/formatter config korumasi (Windows/PowerShell).
# Kaynak fikir: ECC (github.com/affaan-m/ECC) config-protection.js — PS'e uyarlandi.
# Agent lint hatasini config gevseterek gecmesin diye MEVCUT config dosyasinin
# degistirilmesini bloklar. Yeni config olusturma serbest.
# pyproject.toml bilerek listede YOK (bagimlilik degisiklikleri mesru).
# exit 0 -> izin ver | exit 2 -> BLOKLA.
# Bypass (kullanici onayindan sonra): CLAUDE_CONFIGGUARD_SKIP=1
$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if ($env:CLAUDE_CONFIGGUARD_SKIP -eq '1') { exit 0 }

$raw = [Console]::In.ReadToEnd()
$filePath = ''
try { $filePath = ($raw | ConvertFrom-Json).tool_input.file_path } catch { exit 0 }
if (-not $filePath) { exit 0 }

$base = Split-Path -Leaf $filePath

$protected = @(
    '.eslintrc', '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json', '.eslintrc.yml', '.eslintrc.yaml',
    'eslint.config.js', 'eslint.config.mjs', 'eslint.config.cjs', 'eslint.config.ts',
    '.prettierrc', '.prettierrc.js', '.prettierrc.cjs', '.prettierrc.json', '.prettierrc.yml', '.prettierrc.yaml',
    'prettier.config.js', 'prettier.config.cjs', 'prettier.config.mjs',
    'biome.json', 'biome.jsonc',
    '.ruff.toml', 'ruff.toml',
    '.editorconfig',
    '.shellcheckrc',
    '.stylelintrc', '.stylelintrc.json', '.stylelintrc.yml',
    '.markdownlint.json', '.markdownlint.yaml', '.markdownlintrc'
)

if ($protected -notcontains $base) { exit 0 }

# Yeni dosya olusturma serbest — gevsetilecek mevcut config yok
if (-not (Test-Path -LiteralPath $filePath)) { exit 0 }

[Console]::Error.WriteLine('=== CONFIG GUARD: BLOKLANDI ===')
[Console]::Error.WriteLine("  X $base degistirilemez.")
[Console]::Error.WriteLine('')
[Console]::Error.WriteLine('Lint/format kuralini gecmek icin config gevsetme — KAYNAK KODU duzelt.')
[Console]::Error.WriteLine('Mesru bir config degisikligiyse kullanicidan onay al; onay sonrasi:')
[Console]::Error.WriteLine('  CLAUDE_CONFIGGUARD_SKIP=1 ile gecici bypass')
exit 2
