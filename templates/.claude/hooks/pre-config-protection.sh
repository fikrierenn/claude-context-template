#!/usr/bin/env bash
# PreToolUse(Edit|Write) hook — linter/formatter config korumasi.
# Kaynak fikir: ECC (github.com/affaan-m/ECC) config-protection.js — bash'e uyarlandi.
#
# Amac: Agent'lar lint/format hatasini duzeltmek yerine config'i gevsetme
# egilimindedir. Bu hook MEVCUT config dosyasinin degistirilmesini bloklar,
# agent'i kaynak kodu duzeltmeye yonlendirir.
#
# - Yeni config olusturma serbest (proje bootstrap'i mesru senaryo).
# - pyproject.toml bilerek listede YOK (bagimlilik degisiklikleri mesru).
#
# Cikis kodlari: 0 -> izin ver | 2 -> BLOKLA.
# Bypass (kullanici onayindan sonra): CLAUDE_CONFIGGUARD_SKIP=1

set -e

[ "${CLAUDE_CONFIGGUARD_SKIP:-0}" = "1" ] && exit 0

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')
else
  file_path=$(echo "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi

[ -z "$file_path" ] && exit 0

base=$(basename "$file_path")

protected="
.eslintrc .eslintrc.js .eslintrc.cjs .eslintrc.json .eslintrc.yml .eslintrc.yaml
eslint.config.js eslint.config.mjs eslint.config.cjs eslint.config.ts
.prettierrc .prettierrc.js .prettierrc.cjs .prettierrc.json .prettierrc.yml .prettierrc.yaml
prettier.config.js prettier.config.cjs prettier.config.mjs
biome.json biome.jsonc
.ruff.toml ruff.toml
.editorconfig
.shellcheckrc
.stylelintrc .stylelintrc.json .stylelintrc.yml
.markdownlint.json .markdownlint.yaml .markdownlintrc
"

is_protected=0
for p in $protected; do
  if [ "$base" = "$p" ]; then is_protected=1; break; fi
done

[ "$is_protected" = "0" ] && exit 0

# Yeni dosya olusturma serbest — gevsetilecek mevcut config yok
[ ! -e "$file_path" ] && exit 0

echo "=== CONFIG GUARD: BLOKLANDI ===" >&2
echo "  X $base degistirilemez." >&2
echo "" >&2
echo "Lint/format kuralini gecmek icin config gevsetme — KAYNAK KODU duzelt." >&2
echo "Mesru bir config degisikligiyse kullanicidan onay al; onay sonrasi:" >&2
echo "  CLAUDE_CONFIGGUARD_SKIP=1 ile gecici bypass" >&2
exit 2
