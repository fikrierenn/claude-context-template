#!/usr/bin/env bash
# SessionStart hook — Claude'a son durumu oturum basinda otomatik enjekte eder.

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
    echo "### Aktif TODO basliklari (ilk 20)"
    grep -E '^### |^- \[ \]|^## ' TODO.md 2>/dev/null | head -20
    echo ""
fi

# Son journal girdisi
if [ -d docs/journal ]; then
    last=$(ls -t docs/journal/*.md 2>/dev/null | grep -v README | head -1)
    if [ -n "$last" ]; then
        echo "### En son journal girdisi — $last"
        tail -40 "$last"
        echo ""
    fi
fi

# Statik kod sagligi sinyalleri
echo "### Kod sagligi sinyalleri (statik)"
new_http=$(grep -rn "new HttpClient()" --include="*.cs" 2>/dev/null | wc -l | tr -d ' ')
[ "$new_http" -gt 0 ] && echo "- Antipattern: new HttpClient(): $new_http"

empty_catch=$(grep -rn "catch\s*(.*)\s*{[[:space:]]*}" --include="*.cs" 2>/dev/null | wc -l | tr -d ' ')
[ "$empty_catch" -gt 0 ] && echo "- Bos catch: $empty_catch"

ex_msg=$(grep -rn "ex\.Message" --include="*.cs" 2>/dev/null | wc -l | tr -d ' ')
[ "$ex_msg" -gt 0 ] && echo "- ex.Message sizma riski: $ex_msg"

inline_style=$(grep -rn 'style="' --include="*.cshtml" --include="*.html" 2>/dev/null | wc -l | tr -d ' ')
[ "$inline_style" -gt 0 ] && echo "- Statik inline style: $inline_style olusum (utility class'a tasi)"

echo ""

# Memory sistemi var mi?
if [ -d "$(dirname "$REPO")/../.claude/projects" ]; then
    echo "### Memory sistemi"
    echo "- Detay icin: memory/MEMORY.md"
    echo ""
fi

echo "---"
echo "## CLAUDE — ILK YANIT ZORUNLU FORMAT"
echo ""
echo "Kullanicinin ilk mesajina cevap vermeden once asagidaki ozeti ver:"
echo ""
echo "  **[UNCOMMITTED: $count dosya]** $([ "$count" -gt 15 ] && echo '⚠️ ESIK ASILDI' || echo '✓')"
echo "  **HIGH acik:** [TODO.md'den HIGH/CRITICAL maddeleri]"
echo "  **Oncelik:** [TODO Faz 0'dan ilk 1-2 madde]"
echo "  Ne yapiyoruz?"
echo ""
echo "Bu ozeti VERMEDEN kullanicinin sorusunu yanitlama."
echo "---"

exit 0
