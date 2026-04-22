#!/usr/bin/env bash
# SessionStart hook — Claude'a son durumu oturum basinda otomatik enjekte eder.
# Cikti stdout, Claude bunu additionalContext olarak goruyor.
# Proje-bagimsiz: CLAUDE_PROJECT_DIR veya cwd kullanir.

set -e

REPO="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$REPO" 2>/dev/null || exit 0

PROJECT_NAME=$(basename "$REPO")

echo "## $PROJECT_NAME — Oturum Basi Ozet"
echo ""

echo "### Son 3 gun commit'ler"
git log --since='3 days ago' --oneline 2>/dev/null | head -10
echo ""

echo "### Uncommitted dosya sayisi"
count=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
echo "$count dosya"
if [ "$count" -gt 15 ] 2>/dev/null; then
    echo ""
    echo "UYARI: 15 dosya esigi asildi. Yeni is baslamadan once commit-split gerek."
fi
echo ""

if [ -f TODO.md ]; then
    echo "### Aktif TODO basliklari (ilk 15)"
    grep -E '^### |^- \[ \]' TODO.md 2>/dev/null | head -15
    echo ""
fi

if [ -d docs/journal ]; then
    last_journal=$(ls -t docs/journal/*.md 2>/dev/null | head -1)
    if [ -n "$last_journal" ]; then
        echo "### En son journal girdisi"
        echo "Dosya: $last_journal"
        echo ""
        tail -40 "$last_journal"
        echo ""
    fi
fi

echo "### Kritik dosyalar / kurallar"
[ -f docs/CONTEXT_MANAGEMENT.md ] && echo "- Baglam yonetimi: docs/CONTEXT_MANAGEMENT.md"
[ -d .claude/rules ] && {
    for f in .claude/rules/architecture.md \
             .claude/rules/security-principles.md \
             .claude/rules/commit-discipline.md \
             .claude/rules/session-memory.md \
             .claude/rules/turkish-ui.md \
             .claude/rules/known-issues.md; do
        [ -f "$f" ] && echo "- $f"
    done
}

exit 0
