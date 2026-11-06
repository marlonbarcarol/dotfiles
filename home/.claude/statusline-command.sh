#!/bin/bash
# Powerlevel10k-style status line: directory, git branch (+ dirty marker), model, context used.
input=$(cat)

# Fields joined by the unit separator, not tabs: read collapses runs of tabs, so an empty field would shift the rest.
IFS=$'\x1f' read -r cwd model used five five_reset week < <(echo "$input" | jq -r '[.workspace.current_dir // .cwd // "", .model.display_name // "", (.context_window.used_percentage // ""), (.rate_limits.five_hour.used_percentage // ""), (.rate_limits.five_hour.resets_at // ""), (.rate_limits.seven_day.used_percentage // "")] | map(tostring) | join("\u001f")')

# Usage limit in green, yellow from 50%, red from 80%.
limit() {
  local colour=32
  if [ "${1%.*}" -ge 80 ]; then colour=31; elif [ "${1%.*}" -ge 50 ]; then colour=33; fi
  printf '\033[%sm%s %.0f%%\033[0m' "$colour" "$2" "$1"
}

# Shorten $HOME to ~
dir="${cwd/#$HOME/~}"

out=$(printf '\033[34m%s\033[0m' "$dir")

# One git call: branch from the "## " header line, dirty if any further lines exist.
if [ -n "$cwd" ] && status=$(git -C "$cwd" --no-optional-locks status --porcelain=v1 -b 2>/dev/null); then
  header=${status%%$'\n'*}
  branch=${header#\#\# }
  branch=${branch%%...*}
  branch=${branch#No commits yet on }
  case "$branch" in "HEAD (no branch)") branch="detached" ;; esac
  out="$out $(printf '\033[32mon %s\033[0m' "$branch")"
  [[ "$status" == *$'\n'* ]] && out="$out $(printf '\033[33m*\033[0m')"
fi

[ -n "$model" ] && out="$out $(printf '\033[36m%s\033[0m' "$model")"

if [ -n "$used" ]; then
  out="$out $(printf '\033[35mctx %.0f%%\033[0m' "$used")"
fi

# Usage limits: only on claude.ai Pro/Max, and only after the session's first response.
if [ -n "$five" ]; then
  out="$out $(limit "$five" 5h)"
  [ -n "$five_reset" ] && out="$out$(printf '\033[2m (resets %s)\033[0m' "$(date -r "${five_reset%.*}" +%H:%M)")"
fi
[ -n "$week" ] && out="$out $(limit "$week" 7d)"

printf '%s\n' "$out"
