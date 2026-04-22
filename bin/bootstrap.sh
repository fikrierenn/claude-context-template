#!/usr/bin/env bash
# Yeni projeye Claude bağlam yönetimi şablonunu kurar.
# Usage:
#   bash bootstrap.sh --path /d/Dev/yeni-proje --name YeniProje --stack dotnet-mvc

set -e

TEMPLATE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES="$TEMPLATE_ROOT/templates"

PROJECT_PATH=""
PROJECT_NAME=""
STACK="none"
INCLUDE_TURKISH="true"
ENABLE_PRECOMMIT_HOOK="false"   # greenfield projede kod yok, antipattern taraması gürültü yapar
UPDATE_MODE="false"
FORCE="false"
MERGE_GITIGNORE="true"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --path)    PROJECT_PATH="$2"; shift 2 ;;
        --name)    PROJECT_NAME="$2"; shift 2 ;;
        --stack)   STACK="$2"; shift 2 ;;
        --no-turkish) INCLUDE_TURKISH="false"; shift ;;
        --enable-precommit-hook) ENABLE_PRECOMMIT_HOOK="true"; shift ;;
        --no-gitignore-merge) MERGE_GITIGNORE="false"; shift ;;
        --update)  UPDATE_MODE="true"; shift ;;
        --force)   FORCE="true"; shift ;;
        -h|--help)
            cat <<EOF
Kullanım:
  bash bootstrap.sh --path <proje-yolu> [--name <ad>] [--stack <stack>] [seçenekler]

Stack:
  dotnet-mvc | nodejs-typescript | python-generic | none

Seçenekler:
  --no-turkish               Türkçe UI kuralını ekleme (default: ekler)
  --enable-precommit-hook    settings.json'da pre-commit antipattern hook'u AKTİF et
                             (default: pasif — greenfield'de gürültü yapar)
  --no-gitignore-merge       .gitignore'ı otomatik merge etme (default: merge eder)
  --update                   Proje-özel dosyaları (CLAUDE.md, TODO.md, project/*, journal)
                             ASLA ezme. Universal rules + stack + hook + skill güncellensin.
  --force                    Mevcut dosyaların üzerine yaz (tehlikeli — yedek al)

Örnekler:
  # Yeni .NET projesi, Türkçe UI
  bash bootstrap.sh --path /d/Dev/my-api --name MyApi --stack dotnet-mvc

  # Node/TS, İngilizce UI, pre-commit hook aktif
  bash bootstrap.sh --path /d/Dev/my-app --name MyApp --stack nodejs-typescript \\
    --no-turkish --enable-precommit-hook

  # Sadece template'i güncelle (mevcut projede)
  bash bootstrap.sh --path /d/Dev/existing-proj --update
EOF
            exit 0 ;;
        *) echo "Bilinmeyen arg: $1" >&2; exit 1 ;;
    esac
done

[[ -z "$PROJECT_PATH" ]] && { echo "ERROR: --path gerekli" >&2; exit 1; }
[[ ! -d "$PROJECT_PATH" ]] && { echo "ERROR: $PROJECT_PATH bulunamadı" >&2; exit 1; }
[[ -z "$PROJECT_NAME" ]] && PROJECT_NAME="$(basename "$PROJECT_PATH")"

echo ""
echo "=== Claude Bağlam Yönetimi Bootstrap ==="
echo "Hedef: $PROJECT_PATH"
echo "Ad:    $PROJECT_NAME"
echo "Stack: $STACK"
echo "Türkçe UI: $INCLUDE_TURKISH"
echo "Pre-commit hook: $([[ "$ENABLE_PRECOMMIT_HOOK" == "true" ]] && echo "AKTİF" || echo "pasif (settings.json'dan ileride aktifleştir)")"
echo "Mod:   $([[ "$UPDATE_MODE" == "true" ]] && echo "GÜNCELLEME (project-özel dokunulmaz)" || echo "YENİ KURULUM")"
echo ""

render_template() {
    local src="$1" dst="$2"
    shift 2
    mkdir -p "$(dirname "$dst")"
    local content
    content=$(<"$src")
    while [[ $# -gt 0 ]]; do
        local key="$1" val="$2"
        content=${content//"{{$key}}"/"$val"}
        shift 2
    done
    printf '%s' "$content" > "$dst"
}

# --- 1. rules/ ---
echo "[1/8] .claude/rules/"
mkdir -p "$PROJECT_PATH/.claude/rules"

# session-protocol + commit-discipline + session-memory + security-principles her zaman
UNIVERSAL_FILES=(session-protocol.md commit-discipline.md session-memory.md security-principles.md)
[[ "$INCLUDE_TURKISH" == "true" ]] && UNIVERSAL_FILES+=(turkish-ui.md)

for f in "${UNIVERSAL_FILES[@]}"; do
    cp "$TEMPLATES/.claude/rules/_universal/$f" "$PROJECT_PATH/.claude/rules/$f"
    echo "  + rules/$f"
done

if [[ "$STACK" != "none" && -d "$TEMPLATES/.claude/rules/stacks/$STACK" ]]; then
    for f in "$TEMPLATES/.claude/rules/stacks/$STACK"/*.md; do
        cp "$f" "$PROJECT_PATH/.claude/rules/$(basename "$f")"
        echo "  + rules/$(basename "$f") (stack: $STACK)"
    done
fi

if [[ "$UPDATE_MODE" != "true" ]]; then
    mkdir -p "$PROJECT_PATH/.claude/rules/project"
    for tmpl in architecture security-principles known-issues; do
        dst="$PROJECT_PATH/.claude/rules/project/${tmpl}.md"
        if [[ ! -f "$dst" || "$FORCE" == "true" ]]; then
            render_template "$TEMPLATES/.claude/rules/project/${tmpl}.md.tmpl" "$dst" \
                "PROJECT_NAME" "$PROJECT_NAME"
            echo "  + rules/project/${tmpl}.md (placeholder)"
        else
            echo "  = rules/project/${tmpl}.md (mevcut, atlandı)"
        fi
    done
fi

# --- 2. hooks/ ---
echo "[2/8] .claude/hooks/"
mkdir -p "$PROJECT_PATH/.claude/hooks"
for h in session-start.sh pre-commit-antipattern.sh post-commit-journal.sh; do
    cp "$TEMPLATES/.claude/hooks/$h" "$PROJECT_PATH/.claude/hooks/$h"
    chmod +x "$PROJECT_PATH/.claude/hooks/$h"
    echo "  + hooks/$h (executable)"
done

# --- 3. agents/ ---
echo "[3/8] .claude/agents/"
mkdir -p "$PROJECT_PATH/.claude/agents"
cp "$TEMPLATES/.claude/agents/commit-splitter.md" "$PROJECT_PATH/.claude/agents/commit-splitter.md"
echo "  + agents/commit-splitter.md"

# --- 4. skills/ ---
echo "[4/8] .claude/skills/session-handoff/"
mkdir -p "$PROJECT_PATH/.claude/skills/session-handoff"
cp "$TEMPLATES/.claude/skills/session-handoff/SKILL.md" "$PROJECT_PATH/.claude/skills/session-handoff/SKILL.md"
echo "  + skills/session-handoff/SKILL.md"

# --- 5. settings.json ---
echo "[5/8] .claude/settings.json"
SETTINGS_DST="$PROJECT_PATH/.claude/settings.json"
FWD_PATH="${PROJECT_PATH//\\/\/}"
if [[ ! -f "$SETTINGS_DST" || "$FORCE" == "true" ]]; then
    render_template "$TEMPLATES/.claude/settings.json.tmpl" "$SETTINGS_DST" \
        "PROJECT_PATH_FWD" "$FWD_PATH"
    # Pre-commit hook pasif ise ilgili bloğu kaldır (greenfield default)
    if [[ "$ENABLE_PRECOMMIT_HOOK" != "true" ]]; then
        # Basit sed: PreToolUse bloğunu komple kaldır
        python3 -c "
import json, sys
with open('$SETTINGS_DST') as f: d = json.load(f)
d.get('hooks', {}).pop('PreToolUse', None)
with open('$SETTINGS_DST', 'w') as f: json.dump(d, f, indent=2)
" 2>/dev/null || echo "  ! python3 yok, settings.json elle düzenle (PreToolUse bloğunu çıkar)"
        echo "  + settings.json (PreToolUse pasif)"
    else
        echo "  + settings.json (3 hook aktif)"
    fi
else
    echo "  = settings.json (mevcut — elle merge et, yeni hook kayıtlarını ekle)"
fi

# --- 6. .gitignore merge ---
echo "[6/8] .gitignore"
GI_DST="$PROJECT_PATH/.gitignore"
if [[ ! -f "$GI_DST" ]]; then
    cp "$TEMPLATES/.gitignore.tmpl" "$GI_DST"
    echo "  + .gitignore (yeni, template kopyalandı)"
elif [[ "$MERGE_GITIGNORE" == "true" ]]; then
    # Claude Code entry'leri zaten var mı kontrol et
    if ! grep -q "^\.claude/worktrees/" "$GI_DST"; then
        {
            echo ""
            echo "# --- Claude Code (template bootstrap) ---"
            grep -v '^#' "$TEMPLATES/.gitignore.tmpl" | grep -v '^$' | head -10
        } >> "$GI_DST"
        echo "  ~ .gitignore (Claude Code girdileri append edildi)"
    else
        echo "  = .gitignore (Claude Code girdileri zaten var)"
    fi
else
    echo "  = .gitignore (merge atlandı, --no-gitignore-merge)"
fi

# --- 7. docs/ ---
echo "[7/8] docs/"
mkdir -p "$PROJECT_PATH/docs/journal" "$PROJECT_PATH/docs/ADR"
cp "$TEMPLATES/docs/CONTEXT_MANAGEMENT.md" "$PROJECT_PATH/docs/CONTEXT_MANAGEMENT.md"
echo "  + docs/CONTEXT_MANAGEMENT.md"

if [[ "$UPDATE_MODE" != "true" ]]; then
    cp "$TEMPLATES/docs/journal/README.md" "$PROJECT_PATH/docs/journal/README.md"
    cp "$TEMPLATES/docs/ADR/000-template.md" "$PROJECT_PATH/docs/ADR/000-template.md"
    echo "  + docs/journal/README.md"
    echo "  + docs/ADR/000-template.md"
fi

# --- 8. CLAUDE.md + TODO.md ---
if [[ "$UPDATE_MODE" != "true" ]]; then
    echo "[8/8] CLAUDE.md + TODO.md"

    case "$STACK" in
        dotnet-mvc)
            TECH_STACK="- **.NET**: ASP.NET Core MVC, EF Core, SQL Server
- **Frontend**: Razor, vanilla JS (IIFE), Tailwind
- **Test**: xUnit
- **SP-heavy**: Rapor / dashboard verisi SP'den"
            FOLDERS="- \`Controllers/\` \`Models/\` \`ViewModels/\` \`Views/\` \`Services/\`
- \`Database/\` SQL migration + SP
- \`wwwroot/assets/{js,css}/\`"
            BUILD='```bash
dotnet build --nologo
dotnet test
dotnet run
```'
            SMOKE="- Tarayıcı: http://localhost:5XXX
- DB: \`mcp__sqlserver__sql_query\`"
            CONV="- C#: \`.claude/rules/csharp-conventions.md\`
- Razor: \`.claude/rules/razor-conventions.md\`
- SQL: \`.claude/rules/sql-conventions.md\`
- JS: \`.claude/rules/js-conventions.md\`" ;;
        nodejs-typescript)
            TECH_STACK="- **Node.js**: TypeScript strict
- **Framework**: (projeye göre)
- **Test**: Vitest / Jest
- **Lint**: ESLint + Prettier"
            FOLDERS="- \`src/\` \`tests/\` \`dist/\`"
            BUILD='```bash
pnpm install
pnpm run build
pnpm test
pnpm run dev
```'
            SMOKE="- API client / tarayıcı
- \`curl\`"
            CONV="- TS: \`.claude/rules/ts-conventions.md\`" ;;
        python-generic)
            TECH_STACK="- **Python 3.11+**, type hints, strict mypy
- **Framework**: (projeye göre)
- **Test**: pytest
- **Lint**: ruff + mypy"
            FOLDERS="- \`src/\` \`tests/\` \`migrations/\`"
            BUILD='```bash
uv sync
uv run pytest
uv run <entry>
```'
            SMOKE="- API client"
            CONV="- Python: \`.claude/rules/python-conventions.md\`" ;;
        *)
            TECH_STACK="(stack tanımı bekleniyor)"
            FOLDERS="(klasör yapısı bekleniyor)"
            BUILD="(build komutları bekleniyor)"
            SMOKE="(smoke test bekleniyor)"
            CONV="(konvansiyon kuralları \`.claude/rules/\`'a eklenecek)" ;;
    esac

    ADDITIONAL=""
    [[ "$INCLUDE_TURKISH" == "true" ]] && ADDITIONAL=$'\n\n6. **Türkçe UI.** Detay: `.claude/rules/turkish-ui.md`.'

    CLAUDE_DST="$PROJECT_PATH/CLAUDE.md"
    if [[ ! -f "$CLAUDE_DST" || "$FORCE" == "true" ]]; then
        render_template "$TEMPLATES/CLAUDE.md.tmpl" "$CLAUDE_DST" \
            "PROJECT_NAME" "$PROJECT_NAME" \
            "PROJECT_DESCRIPTION" "(kısa tek cümle açıklama)" \
            "TECH_STACK_BLOCK" "$TECH_STACK" \
            "MAIN_FOLDERS_BLOCK" "$FOLDERS" \
            "BUILD_COMMANDS_BLOCK" "$BUILD" \
            "SMOKE_TEST_BLOCK" "$SMOKE" \
            "CONVENTIONS_LINKS_BLOCK" "$CONV" \
            "ADDITIONAL_PRINCIPLES" "$ADDITIONAL"
        echo "  + CLAUDE.md"
    else
        echo "  = CLAUDE.md (mevcut, atlandı — --force ile üzerine yaz)"
    fi

    TODO_DST="$PROJECT_PATH/TODO.md"
    if [[ ! -f "$TODO_DST" || "$FORCE" == "true" ]]; then
        render_template "$TEMPLATES/TODO.md.tmpl" "$TODO_DST" \
            "PROJECT_NAME" "$PROJECT_NAME"
        echo "  + TODO.md"
    else
        echo "  = TODO.md (mevcut, atlandı)"
    fi
fi

# --- Özet ---
echo ""
echo "=== Tamam ==="
echo ""
echo "Kurulan yapı:"
echo "  $PROJECT_PATH/CLAUDE.md"
echo "  $PROJECT_PATH/TODO.md"
echo "  $PROJECT_PATH/.gitignore (merged)"
echo "  $PROJECT_PATH/.claude/settings.json"
echo "  $PROJECT_PATH/.claude/rules/*.md (${#UNIVERSAL_FILES[@]} universal$([[ "$STACK" != "none" ]] && echo " + stack: $STACK"))"
echo "  $PROJECT_PATH/.claude/hooks/{session-start,pre-commit-antipattern,post-commit-journal}.sh"
echo "  $PROJECT_PATH/.claude/agents/commit-splitter.md"
echo "  $PROJECT_PATH/.claude/skills/session-handoff/SKILL.md"
echo "  $PROJECT_PATH/docs/CONTEXT_MANAGEMENT.md"
echo "  $PROJECT_PATH/docs/{journal,ADR}/"
echo ""
echo "Sonraki adım:"
echo "  1. cd \"$PROJECT_PATH\""
echo "  2. claude  # SessionStart hook devreye girer (ilk yanıttan önce 4-adım ritüel)"
echo "  3. CLAUDE.md'yi gözden geçir, placeholder'ları doldur"
echo "  4. .claude/rules/project/*.md'yi projenin ihtiyacına göre doldur"
echo "  5. Kod yazmaya başlayınca --enable-precommit-hook ile hook'u aktif et"
echo "     (veya .claude/settings.json'a PreToolUse bloğunu elle ekle)"
echo ""
