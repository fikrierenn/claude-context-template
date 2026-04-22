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
UPDATE_MODE="false"
FORCE="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --path)    PROJECT_PATH="$2"; shift 2 ;;
        --name)    PROJECT_NAME="$2"; shift 2 ;;
        --stack)   STACK="$2"; shift 2 ;;
        --no-turkish) INCLUDE_TURKISH="false"; shift ;;
        --update)  UPDATE_MODE="true"; shift ;;
        --force)   FORCE="true"; shift ;;
        -h|--help)
            cat <<EOF
Kullanım:
  bash bootstrap.sh --path <proje-yolu> [--name <ad>] [--stack <stack>] [--no-turkish] [--update] [--force]

Stack: dotnet-mvc | nodejs-typescript | python-generic | none
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
        # Bash parameter expansion — multi-line ve ozel karakterleri tolere eder
        content=${content//"{{$key}}"/"$val"}
        shift 2
    done
    printf '%s' "$content" > "$dst"
}

# --- 1. rules/ ---
echo "[1/7] .claude/rules/"
mkdir -p "$PROJECT_PATH/.claude/rules"

UNIVERSAL_FILES=(commit-discipline.md session-memory.md security-principles.md)
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
echo "[2/7] .claude/hooks/"
mkdir -p "$PROJECT_PATH/.claude/hooks"
cp "$TEMPLATES/.claude/hooks/session-start.sh" "$PROJECT_PATH/.claude/hooks/session-start.sh"
chmod +x "$PROJECT_PATH/.claude/hooks/session-start.sh"
echo "  + hooks/session-start.sh (executable)"

# --- 3. skills/ ---
echo "[3/7] .claude/skills/session-handoff/"
mkdir -p "$PROJECT_PATH/.claude/skills/session-handoff"
cp "$TEMPLATES/.claude/skills/session-handoff/SKILL.md" "$PROJECT_PATH/.claude/skills/session-handoff/SKILL.md"
echo "  + skills/session-handoff/SKILL.md"

# --- 4. settings.json ---
echo "[4/7] .claude/settings.json"
SETTINGS_DST="$PROJECT_PATH/.claude/settings.json"
FWD_PATH="${PROJECT_PATH//\\/\/}"
if [[ ! -f "$SETTINGS_DST" || "$FORCE" == "true" ]]; then
    render_template "$TEMPLATES/.claude/settings.json.tmpl" "$SETTINGS_DST" \
        "PROJECT_PATH_FWD" "$FWD_PATH"
    echo "  + settings.json"
else
    echo "  = settings.json (mevcut — elle merge et, SessionStart hook kaydını ekle)"
fi

# --- 5. docs/ ---
echo "[5/7] docs/"
mkdir -p "$PROJECT_PATH/docs/journal" "$PROJECT_PATH/docs/ADR"
cp "$TEMPLATES/docs/CONTEXT_MANAGEMENT.md" "$PROJECT_PATH/docs/CONTEXT_MANAGEMENT.md"
echo "  + docs/CONTEXT_MANAGEMENT.md"

if [[ "$UPDATE_MODE" != "true" ]]; then
    cp "$TEMPLATES/docs/journal/README.md" "$PROJECT_PATH/docs/journal/README.md"
    cp "$TEMPLATES/docs/ADR/000-template.md" "$PROJECT_PATH/docs/ADR/000-template.md"
    echo "  + docs/journal/README.md"
    echo "  + docs/ADR/000-template.md"
fi

# --- 6. CLAUDE.md + TODO.md ---
if [[ "$UPDATE_MODE" != "true" ]]; then
    echo "[6/7] CLAUDE.md + TODO.md"

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
    [[ "$INCLUDE_TURKISH" == "true" ]] && ADDITIONAL=$'\n6. **Türkçe UI.** Detay: `.claude/rules/turkish-ui.md`.'

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

# --- 7. Özet ---
echo ""
echo "[7/7] Tamam."
echo ""
echo "Kurulan yapı:"
echo "  $PROJECT_PATH/CLAUDE.md"
echo "  $PROJECT_PATH/TODO.md"
echo "  $PROJECT_PATH/.claude/settings.json"
echo "  $PROJECT_PATH/.claude/rules/*.md (${#UNIVERSAL_FILES[@]} universal$([[ "$STACK" != "none" ]] && echo " + stack: $STACK"))"
echo "  $PROJECT_PATH/.claude/hooks/session-start.sh"
echo "  $PROJECT_PATH/.claude/skills/session-handoff/SKILL.md"
echo "  $PROJECT_PATH/docs/CONTEXT_MANAGEMENT.md"
echo "  $PROJECT_PATH/docs/{journal,ADR}/"
echo ""
echo "Sonraki adım:"
echo "  1. cd \"$PROJECT_PATH\""
echo "  2. claude  # SessionStart hook devreye girer"
echo "  3. CLAUDE.md'yi gözden geçir, placeholder'ları doldur"
echo "  4. .claude/rules/project/*.md'yi projenin ihtiyacına göre doldur"
echo ""
