#!/bin/bash
# tools-table: build the README's "What gets installed" table from the
# Brewfile and mise config comments ("# Category [needs-admin] | what it's for").
#
#   bash lib/tools-table.sh           print the table
#   bash lib/tools-table.sh --write   refresh README.md between the tools markers
#   source lib/tools-table.sh         use tools_table / readme_tools_up_to_date

_TT_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TOOLS_START='<!-- tools:start -->'
TOOLS_END='<!-- tools:end -->'

# _tt_row <name> <comment>: one markdown row; fails if the comment is malformed.
_tt_row() {
  local name="$1" comment="$2" category desc
  if [[ "$comment" != *"|"* ]]; then
    echo "tools-table: '$name' needs a comment like '# Category | what it's for'" >&2
    return 1
  fi
  category="${comment%%|*}"; desc="${comment#*|}"
  category="$(printf '%s' "$category" | sed -E 's/^ +//; s/ +$//; s/\[needs-admin\]/(admin)/; s/  +/ /g')"
  desc="$(printf '%s' "$desc" | sed -E 's/^ +//; s/ +$//')"
  # shellcheck disable=SC2016  # backticks are markdown, not command substitution
  printf '| `%s` | %s | %s |\n' "$name" "$category" "$desc"
}

# tools_table <Brewfile> <mise-config>: print the full markdown table.
tools_table() {
  local brewfile="$1" misefile="$2" line name comment in_tools=0
  printf '| Tool | Category | What it'"'"'s for |\n|---|---|---|\n'
  while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^(brew|cask)\ \"([^\"]+)\" ]] || continue
    name="${BASH_REMATCH[2]}"
    comment=""
    [[ "$line" == *"#"* ]] && comment="${line#*#}"
    _tt_row "$name" "$comment" || return 1
  done < "$brewfile"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "[tools]") in_tools=1; continue ;;
      "["*) in_tools=0; continue ;;
    esac
    [ "$in_tools" = 1 ] || continue
    [[ "$line" =~ ^\"?([^\"=\ ]+)\"?\ *= ]] || continue
    name="${BASH_REMATCH[1]}"
    comment=""
    [[ "$line" == *"#"* ]] && comment="${line#*#}"
    _tt_row "$name" "$comment" || return 1
  done < "$misefile"
}

_tt_current() {
  tools_table "$_TT_ROOT/Brewfile" "$_TT_ROOT/home/.config/mise/config.toml"
}

# readme_tools_up_to_date <README>: 0 if the marked section matches the table.
readme_tools_up_to_date() {
  local readme="$1" expected actual
  expected="$(_tt_current)" || return 1
  actual="$(sed -n "/^$TOOLS_START\$/,/^$TOOLS_END\$/p" "$readme" | sed '1d;$d')"
  [ "$expected" = "$actual" ]
}

# _tt_write <README>: replace the marked section with the current table.
_tt_write() {
  local readme="$1" table tmp
  grep -qx "$TOOLS_START" "$readme" || { echo "tools-table: no $TOOLS_START marker in $readme" >&2; return 1; }
  table="$(mktemp)"; tmp="$(mktemp)"
  _tt_current > "$table" || { rm -f "$table" "$tmp"; return 1; }
  # macOS awk can't take multi-line -v values, so the table comes from a file.
  awk -v start="$TOOLS_START" -v end="$TOOLS_END" -v tablefile="$table" '
    $0 == start { print; while ((getline l < tablefile) > 0) print l; skipping = 1; next }
    $0 == end   { skipping = 0 }
    !skipping   { print }
  ' "$readme" > "$tmp" && mv "$tmp" "$readme"
  rm -f "$table"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
  case "${1:-}" in
    --write) _tt_write "${DOTFILES_README:-$_TT_ROOT/README.md}" ;;
    "") _tt_current ;;
    *) echo "usage: bash lib/tools-table.sh [--write]" >&2; exit 2 ;;
  esac
fi
