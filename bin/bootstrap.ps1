#Requires -Version 5.1
<#
.SYNOPSIS
    Yeni projeye Claude bağlam yönetimi şablonunu kurar.

.DESCRIPTION
    Universal + stack kurallarını, hook'ları, skill'i, agent'ı, CLAUDE.md +
    TODO.md şablonlarını hedef projeye kopyalar, placeholder'ları doldurur.
    .gitignore'a Claude Code girdilerini append eder.

.PARAMETER ProjectPath
    Hedef proje yolu (mutlaka mevcut olmalı).

.PARAMETER ProjectName
    Proje adı (CLAUDE.md ve şablonlarda kullanılır).

.PARAMETER Stack
    Stack kuralı: dotnet-mvc | nodejs-typescript | python-generic | none

.PARAMETER IncludeTurkish
    Türkçe UI kuralını ekle (varsayılan: evet).

.PARAMETER EnablePreCommitHook
    settings.json'da pre-commit antipattern hook'u AKTİF başlat.
    Default pasif — greenfield'de kod yok, gürültü yapar.

.PARAMETER NoGitignoreMerge
    .gitignore'a Claude Code girdileri ekleme (default: ekler).

.PARAMETER Update
    Sadece universal + stack + hook + skill + CONTEXT_MANAGEMENT güncelle.
    Proje-özel dosyalara (CLAUDE.md, TODO.md, project/*, journal) DOKUNMA.

.PARAMETER Force
    Mevcut dosyaların üzerine yaz (tehlikeli — yedek al).

.EXAMPLE
    pwsh bootstrap.ps1 -ProjectPath D:\Dev\yeni-proje -ProjectName YeniProje -Stack dotnet-mvc

.EXAMPLE
    pwsh bootstrap.ps1 -ProjectPath D:\Dev\my-app -Stack nodejs-typescript -IncludeTurkish:$false -EnablePreCommitHook
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ProjectPath,
    [string]$ProjectName,
    [ValidateSet('dotnet-mvc','nodejs-typescript','python-generic','none')]
    [string]$Stack = 'none',
    [switch]$IncludeTurkish = $true,
    [switch]$EnablePreCommitHook,
    [switch]$NoGitignoreMerge,
    [switch]$Update,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$TemplateRoot = Split-Path -Parent $PSScriptRoot
$TemplatesDir = Join-Path $TemplateRoot 'templates'

if (-not (Test-Path $ProjectPath)) { throw "ProjectPath bulunamadi: $ProjectPath" }
if (-not $ProjectName) {
    $ProjectName = Split-Path -Leaf $ProjectPath
    Write-Host "ProjectName belirlenmedi, kullaniliyor: $ProjectName" -ForegroundColor Yellow
}

Write-Host "`n=== Claude Baglam Yonetimi Bootstrap ===" -ForegroundColor Cyan
Write-Host "Hedef: $ProjectPath"
Write-Host "Ad:    $ProjectName"
Write-Host "Stack: $Stack"
Write-Host "Turkce UI: $IncludeTurkish"
Write-Host "Pre-commit hook: $(if ($EnablePreCommitHook) {'AKTIF'} else {'pasif (settings.json\'dan ileride aktiflestir)'})"
Write-Host "Mod:   $(if ($Update) {'GUNCELLEME (project-ozel dokunulmaz)'} else {'YENI KURULUM'})"
Write-Host ""

function Copy-Template {
    param([string]$Src, [string]$Dst, [hashtable]$Replacements = @{})

    $content = Get-Content -Raw -Path $Src -Encoding UTF8
    foreach ($key in $Replacements.Keys) {
        $content = $content -replace [regex]::Escape("{{$key}}"), $Replacements[$key]
    }
    $dstDir = Split-Path -Parent $Dst
    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
    Set-Content -Path $Dst -Value $content -Encoding UTF8 -NoNewline
}

function Ensure-Dir { param([string]$Path); if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null } }

$fwdPath = ($ProjectPath -replace '\\','/')

# --- 1. .claude/rules/ ---
Write-Host "[1/8] .claude/rules/" -ForegroundColor Green
Ensure-Dir "$ProjectPath/.claude/rules"

$universalFiles = @('session-protocol.md','commit-discipline.md','session-memory.md','security-principles.md')
if ($IncludeTurkish) { $universalFiles += 'turkish-ui.md' }
foreach ($f in $universalFiles) {
    Copy-Item -Path "$TemplatesDir/.claude/rules/_universal/$f" -Destination "$ProjectPath/.claude/rules/$f" -Force
    Write-Host "  + rules/$f"
}

if ($Stack -ne 'none') {
    $stackDir = "$TemplatesDir/.claude/rules/stacks/$Stack"
    if (Test-Path $stackDir) {
        Get-ChildItem -Path $stackDir -Filter '*.md' | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination "$ProjectPath/.claude/rules/$($_.Name)" -Force
            Write-Host "  + rules/$($_.Name) (stack: $Stack)"
        }
    }
}

if (-not $Update) {
    Ensure-Dir "$ProjectPath/.claude/rules/project"
    $projectTmpls = @{
        'architecture.md.tmpl'         = 'architecture.md'
        'security-principles.md.tmpl'  = 'security-principles.md'
        'known-issues.md.tmpl'         = 'known-issues.md'
    }
    foreach ($tmpl in $projectTmpls.Keys) {
        $dst = "$ProjectPath/.claude/rules/project/$($projectTmpls[$tmpl])"
        if (-not (Test-Path $dst) -or $Force) {
            Copy-Template -Src "$TemplatesDir/.claude/rules/project/$tmpl" -Dst $dst `
                -Replacements @{ 'PROJECT_NAME' = $ProjectName }
            Write-Host "  + rules/project/$($projectTmpls[$tmpl]) (placeholder)"
        } else {
            Write-Host "  = rules/project/$($projectTmpls[$tmpl]) (mevcut, atlandi)"
        }
    }
}

# --- 2. .claude/hooks/ ---
Write-Host "[2/8] .claude/hooks/" -ForegroundColor Green
Ensure-Dir "$ProjectPath/.claude/hooks"
foreach ($h in @('session-start.sh','pre-commit-antipattern.sh','post-commit-journal.sh')) {
    Copy-Item -Path "$TemplatesDir/.claude/hooks/$h" -Destination "$ProjectPath/.claude/hooks/$h" -Force
    Write-Host "  + hooks/$h"
}

# --- 3. .claude/agents/ ---
Write-Host "[3/8] .claude/agents/" -ForegroundColor Green
Ensure-Dir "$ProjectPath/.claude/agents"
Copy-Item -Path "$TemplatesDir/.claude/agents/commit-splitter.md" -Destination "$ProjectPath/.claude/agents/commit-splitter.md" -Force
Write-Host "  + agents/commit-splitter.md"

# --- 4. .claude/skills/session-handoff/ ---
Write-Host "[4/8] .claude/skills/session-handoff/" -ForegroundColor Green
Ensure-Dir "$ProjectPath/.claude/skills/session-handoff"
Copy-Item -Path "$TemplatesDir/.claude/skills/session-handoff/SKILL.md" -Destination "$ProjectPath/.claude/skills/session-handoff/SKILL.md" -Force
Write-Host "  + skills/session-handoff/SKILL.md"

# --- 5. .claude/settings.json ---
Write-Host "[5/8] .claude/settings.json" -ForegroundColor Green
$settingsDst = "$ProjectPath/.claude/settings.json"
if (-not (Test-Path $settingsDst) -or $Force) {
    Copy-Template -Src "$TemplatesDir/.claude/settings.json.tmpl" -Dst $settingsDst `
        -Replacements @{ 'PROJECT_PATH_FWD' = $fwdPath }
    if (-not $EnablePreCommitHook) {
        $json = Get-Content -Raw -Path $settingsDst | ConvertFrom-Json
        if ($json.hooks.PreToolUse) {
            $json.hooks.PSObject.Properties.Remove('PreToolUse')
            $json | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsDst -Encoding UTF8
        }
        Write-Host "  + settings.json (PreToolUse pasif)"
    } else {
        Write-Host "  + settings.json (3 hook aktif)"
    }
} else {
    Write-Host "  = settings.json (mevcut - elle merge et, yeni hook kayitlarini ekle)" -ForegroundColor Yellow
}

# --- 6. .gitignore merge ---
Write-Host "[6/8] .gitignore" -ForegroundColor Green
$giDst = "$ProjectPath/.gitignore"
if (-not (Test-Path $giDst)) {
    Copy-Item -Path "$TemplatesDir/.gitignore.tmpl" -Destination $giDst -Force
    Write-Host "  + .gitignore (yeni)"
} elseif (-not $NoGitignoreMerge) {
    $existing = Get-Content -Raw -Path $giDst
    if ($existing -notmatch '\.claude/worktrees/') {
        $tmplLines = Get-Content -Path "$TemplatesDir/.gitignore.tmpl" | Where-Object { $_ -and $_ -notmatch '^\s*#' } | Select-Object -First 10
        $append = "`n# --- Claude Code (template bootstrap) ---`n" + ($tmplLines -join "`n") + "`n"
        Add-Content -Path $giDst -Value $append
        Write-Host "  ~ .gitignore (Claude Code girdileri eklendi)"
    } else {
        Write-Host "  = .gitignore (Claude Code girdileri zaten var)"
    }
} else {
    Write-Host "  = .gitignore (merge atlandi)"
}

# --- 7. docs/ ---
Write-Host "[7/8] docs/" -ForegroundColor Green
Ensure-Dir "$ProjectPath/docs/journal"
Ensure-Dir "$ProjectPath/docs/ADR"
Copy-Item -Path "$TemplatesDir/docs/CONTEXT_MANAGEMENT.md" -Destination "$ProjectPath/docs/CONTEXT_MANAGEMENT.md" -Force
Write-Host "  + docs/CONTEXT_MANAGEMENT.md"

if (-not $Update) {
    Copy-Item -Path "$TemplatesDir/docs/journal/README.md" -Destination "$ProjectPath/docs/journal/README.md" -Force
    Copy-Item -Path "$TemplatesDir/docs/ADR/000-template.md" -Destination "$ProjectPath/docs/ADR/000-template.md" -Force
    Write-Host "  + docs/journal/README.md"
    Write-Host "  + docs/ADR/000-template.md"
}

# --- 8. CLAUDE.md + TODO.md ---
if (-not $Update) {
    Write-Host "[8/8] CLAUDE.md + TODO.md" -ForegroundColor Green

    $stackBlocks = @{
        'dotnet-mvc' = @{
            TECH_STACK = "- **.NET**: ASP.NET Core MVC, EF Core, SQL Server`n- **Frontend**: Razor Views, vanilla JS (IIFE), Tailwind`n- **Test**: xUnit`n- **SP-heavy**: Raporlar / dashboard verisi stored procedure'dan"
            FOLDERS    = "- ``Controllers/`` ``Models/`` ``ViewModels/`` ``Views/`` ``Services/```n- ``Database/`` SQL migration + SP`n- ``wwwroot/assets/{js,css}/``"
            BUILD      = "``````bash`ndotnet build --nologo`ndotnet test`ndotnet run  # http://localhost:5XXX`n``````"
            SMOKE      = "- Tarayici: http://localhost:5XXX`n- DB: ``mcp__sqlserver__sql_query``"
            CONV       = "- C#: ``.claude/rules/csharp-conventions.md```n- Razor: ``.claude/rules/razor-conventions.md```n- SQL: ``.claude/rules/sql-conventions.md```n- JS: ``.claude/rules/js-conventions.md``"
        }
        'nodejs-typescript' = @{
            TECH_STACK = "- **Node.js**: TypeScript, strict mode`n- **Framework**: (Express / Fastify / Next.js - proje bazli)`n- **Test**: Vitest / Jest`n- **Lint**: ESLint + Prettier"
            FOLDERS    = "- ``src/`` ``tests/`` ``dist/``"
            BUILD      = "``````bash`npnpm install`npnpm run build`npnpm test`npnpm run dev`n``````"
            SMOKE      = "- Tarayici veya API client`n- ``curl``"
            CONV       = "- TS: ``.claude/rules/ts-conventions.md``"
        }
        'python-generic' = @{
            TECH_STACK = "- **Python 3.11+**, type hints, strict mypy`n- **Framework**: (Django / FastAPI / Flask - proje bazli)`n- **Test**: pytest`n- **Lint**: ruff + mypy"
            FOLDERS    = "- ``src/`` ``tests/`` ``migrations/``"
            BUILD      = "``````bash`nuv sync`nuv run pytest`nuv run <entry>`n``````"
            SMOKE      = "- Tarayici veya API client"
            CONV       = "- Python: ``.claude/rules/python-conventions.md``"
        }
        'none' = @{
            TECH_STACK = "(stack tanimi bekleniyor)"
            FOLDERS    = "(klasor yapisi bekleniyor)"
            BUILD      = "(build komutlari bekleniyor)"
            SMOKE      = "(smoke test bekleniyor)"
            CONV       = "(konvansiyon kurallari ``.claude/rules/``'a eklenecek)"
        }
    }

    $b = $stackBlocks[$Stack]
    $additional = if ($IncludeTurkish) { "`n`n6. **Turkce UI.** Detay: ``.claude/rules/turkish-ui.md``." } else { "" }

    $claudeDst = "$ProjectPath/CLAUDE.md"
    if (-not (Test-Path $claudeDst) -or $Force) {
        Copy-Template -Src "$TemplatesDir/CLAUDE.md.tmpl" -Dst $claudeDst -Replacements @{
            'PROJECT_NAME'           = $ProjectName
            'PROJECT_DESCRIPTION'    = "(kisa tek cumle aciklama)"
            'TECH_STACK_BLOCK'       = $b.TECH_STACK
            'MAIN_FOLDERS_BLOCK'     = $b.FOLDERS
            'BUILD_COMMANDS_BLOCK'   = $b.BUILD
            'SMOKE_TEST_BLOCK'       = $b.SMOKE
            'CONVENTIONS_LINKS_BLOCK'= $b.CONV
            'ADDITIONAL_PRINCIPLES'  = $additional
        }
        Write-Host "  + CLAUDE.md"
    } else {
        Write-Host "  = CLAUDE.md (mevcut, atlandi - -Force ile uzerine yaz)" -ForegroundColor Yellow
    }

    $todoDst = "$ProjectPath/TODO.md"
    if (-not (Test-Path $todoDst) -or $Force) {
        Copy-Template -Src "$TemplatesDir/TODO.md.tmpl" -Dst $todoDst -Replacements @{ 'PROJECT_NAME' = $ProjectName }
        Write-Host "  + TODO.md"
    } else {
        Write-Host "  = TODO.md (mevcut, atlandi)" -ForegroundColor Yellow
    }
}

# --- Ozet ---
Write-Host "`n=== Tamam ===`n" -ForegroundColor Green
Write-Host "Kurulan yapi:"
Write-Host "  $ProjectPath/CLAUDE.md"
Write-Host "  $ProjectPath/TODO.md"
Write-Host "  $ProjectPath/.gitignore (merged)"
Write-Host "  $ProjectPath/.claude/settings.json"
Write-Host "  $ProjectPath/.claude/rules/*.md ($($universalFiles.Count) universal$(if ($Stack -ne 'none') {" + stack: $Stack"}))"
Write-Host "  $ProjectPath/.claude/hooks/{session-start,pre-commit-antipattern,post-commit-journal}.sh"
Write-Host "  $ProjectPath/.claude/agents/commit-splitter.md"
Write-Host "  $ProjectPath/.claude/skills/session-handoff/SKILL.md"
Write-Host "  $ProjectPath/docs/CONTEXT_MANAGEMENT.md"
Write-Host "  $ProjectPath/docs/{journal,ADR}/"
Write-Host ""
Write-Host "Sonraki adim:" -ForegroundColor Cyan
Write-Host "  1. cd `"$ProjectPath`""
Write-Host "  2. claude  # SessionStart hook devreye girer (ilk yanittan once 4-adim rituel)"
Write-Host "  3. CLAUDE.md'yi gozden gecir, placeholder'lari doldur"
Write-Host "  4. .claude/rules/project/*.md'yi projenin ihtiyacina gore doldur"
Write-Host "  5. Kod yazmaya baslayinca -EnablePreCommitHook ile hook'u aktif et"
Write-Host ""
