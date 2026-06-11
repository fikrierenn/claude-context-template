#!/usr/bin/env bash
# PreToolUse(Bash) hook — git guard: hook bypass + tehlikeli git komutlarini blokla.
# Kaynak fikir: ECC (github.com/affaan-m/ECC) block-no-verify.js — bash'e uyarlandi.
#
# Tetikleyici: settings.json PreToolUse, matcher = "Bash".
# stdin'den JSON okur: { tool_input: { command } }.
#
# Bloklananlar:
#   - git commit/push/merge/rebase/cherry-pick ... --no-verify  (hook bypass)
#   - git commit -n                                             (--no-verify kisaltmasi)
#   - git -c core.hooksPath=...                                 (hook path override)
#   - git push --force / -f                                     (--force-with-lease serbest)
#   - git reset --hard                                          (uncommitted is ucar)
#   - git clean -fd / -df                                       (untracked siler)
#   - git checkout . / git restore .                            (tum degisiklikleri at)
#
# Cikis kodlari: 0 -> izin ver | 2 -> BLOKLA (stderr mesaji Claude'a gider).
# Bypass (kullanici onayindan sonra): CLAUDE_GITGUARD_SKIP=1

set -e

[ "${CLAUDE_GITGUARD_SKIP:-0}" = "1" ] && exit 0

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  cmd=$(echo "$input" | jq -r '.tool_input.command // ""')
else
  cmd=$(echo "$input" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi

[ -z "$cmd" ] && exit 0

# git komutu degilse cik
echo "$cmd" | grep -qE '(^|[[:space:]&;|(])git([[:space:]]|$)' || exit 0

# Quoted string icerigini maskele (commit mesajindaki "--no-verify" yanlis pozitif olmasin)
masked=$(echo "$cmd" | sed -E "s/'[^']*'/''/g; s/\"[^\"]*\"/\"\"/g")

block() {
  echo "=== GIT GUARD: BLOKLANDI ===" >&2
  echo "  X $1" >&2
  echo "" >&2
  echo "Bu komut commit-discipline kuralina aykiri. Gercekten gerekliyse" >&2
  echo "kullanicidan ACIK ONAY al; onay sonrasi bypass:" >&2
  echo "  CLAUDE_GITGUARD_SKIP=1 <komut>" >&2
  exit 2
}

# 1. Hook bypass
if echo "$masked" | grep -qE '(^|[[:space:]])--no-verify([[:space:]]|$)'; then
  block "--no-verify: git hook'lari bypass edilemez"
fi
if echo "$masked" | grep -qE 'git[[:space:]]+commit[^;|&]*([[:space:]])-n([[:space:]]|$)'; then
  block "git commit -n (--no-verify kisaltmasi): hook bypass edilemez"
fi
if echo "$masked" | grep -qiE -- '-c[[:space:]]*core\.hookspath='; then
  block "core.hooksPath override: hook bypass edilemez"
fi

# 2. Tehlikeli git komutlari (commit-discipline.md listesi)
if echo "$masked" | grep -qE 'git[[:space:]]+push[^;|&]*([[:space:]])(--force|-f)([[:space:]]|$)' \
   && ! echo "$masked" | grep -q -- '--force-with-lease'; then
  block "git push --force: history yeniden yazar (--force-with-lease degerlendir)"
fi
if echo "$masked" | grep -qE 'git[[:space:]]+reset[^;|&]*--hard'; then
  block "git reset --hard: uncommitted is kaybolur"
fi
if echo "$masked" | grep -qE 'git[[:space:]]+clean[^;|&]*-[a-zA-Z]*f'; then
  block "git clean -f: untracked dosyalar silinir"
fi
if echo "$masked" | grep -qE 'git[[:space:]]+(checkout|restore)[[:space:]]+\.([[:space:]]|$)'; then
  block "git checkout/restore . : tum degisiklikler atilir"
fi

exit 0
