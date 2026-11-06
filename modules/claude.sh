# shellcheck shell=bash
# claude: Claude Code helpers used by link, install and doctor (not a module
# you run on its own).
#
# ~/.claude/settings.json is GENERATED, not linked: repo settings deep-merged
# with the untracked ~/.claude/settings.private.json (private bits such as the
# auto-mode note about your home server). Claude Code only reads settings.json.

CLAUDE_REPO_SETTINGS="$DOTFILES_ROOT/home/.claude/settings.json"
CLAUDE_PRIVATE_SETTINGS="$HOME/.claude/settings.private.json"
CLAUDE_LIVE_SETTINGS="$HOME/.claude/settings.json"

# _claude_merged: print repo settings merged with the private file (if any).
_claude_merged() {
  if [ -f "$CLAUDE_PRIVATE_SETTINGS" ]; then
    jq -S -s '.[0] * .[1]' "$CLAUDE_REPO_SETTINGS" "$CLAUDE_PRIVATE_SETTINGS"
  else
    jq -S . "$CLAUDE_REPO_SETTINGS"
  fi
}

# claude_settings_drift: 0 if the live file equals the merge.
claude_settings_drift() {
  [ -f "$CLAUDE_LIVE_SETTINGS" ] || return 1
  [ "$(_claude_merged)" = "$(jq -S . "$CLAUDE_LIVE_SETTINGS" 2>/dev/null)" ]
}

# claude_settings_merge: write the live settings file (backing up a different one).
claude_settings_merge() {
  if claude_settings_drift; then
    echo "ok .claude/settings.json (generated)"
    return 0
  fi
  if [ "$DRY_RUN" = "1" ]; then
    echo "would: generate ~/.claude/settings.json from repo + settings.private.json"
    return 0
  fi
  # Merge into a temp file first: a broken private file must not leave Claude
  # Code with an empty settings file.
  local tmp
  tmp="$(mktemp)"
  if ! _claude_merged > "$tmp" 2>/dev/null; then
    rm -f "$tmp"
    skip "claude settings" "couldn't merge — is ~/.claude/settings.private.json valid JSON? (jq . ~/.claude/settings.private.json)"
    return 0
  fi
  if [ -e "$CLAUDE_LIVE_SETTINGS" ] || [ -L "$CLAUDE_LIVE_SETTINGS" ]; then
    local bdir
    bdir="$(backup_dir)"
    mkdir -p "$bdir/.claude"
    mv "$CLAUDE_LIVE_SETTINGS" "$bdir/.claude/settings.json"
    printf '%s\n' ".claude/settings.json" >> "$bdir/.manifest"
  fi
  mkdir -p "$(dirname "$CLAUDE_LIVE_SETTINGS")"
  mv "$tmp" "$CLAUDE_LIVE_SETTINGS"
  echo "generated .claude/settings.json"
}

# claude_skills_install: add skills from claude/skills.txt that aren't installed.
claude_skills_install() {
  local name url
  while read -r name url || [ -n "$name" ]; do
    [ -z "$name" ] && continue
    case "$name" in \#*) continue ;; esac
    [ -e "$HOME/.claude/skills/$name" ] && continue
    if ! command -v npx >/dev/null 2>&1; then
      skip "skill $name" "npx (Node) isn't available yet — run ./dotfiles install, then ./dotfiles link"
      continue
    fi
    run_cmd npx skills add "$url" --skill "$name" --global -y </dev/null \
      || skip "skill $name" "npx skills add failed"
  done < "$DOTFILES_ROOT/claude/skills.txt"
}

# claude_install: Claude Code itself (native installer), marketplaces, plugins.
claude_install() {
  if ! command -v claude >/dev/null 2>&1; then
    run_cmd /bin/bash -c 'curl -fsSL https://claude.ai/install.sh | bash' \
      || { skip "Claude Code" "installer failed"; return 0; }
    export PATH="$HOME/.local/bin:$PATH"
    command -v claude >/dev/null 2>&1 || [ "$DRY_RUN" = "1" ] || { skip "Claude Code plugins" "claude not on PATH after install"; return 0; }
  fi
  local known="$HOME/.claude/plugins/known_marketplaces.json"
  local installed="$HOME/.claude/plugins/installed_plugins.json"
  local name repo id
  while IFS=$'\t' read -r name repo; do
    [ -n "$name" ] || continue
    if [ -f "$known" ] && jq -e --arg n "$name" 'has($n)' "$known" >/dev/null 2>&1; then continue; fi
    run_cmd claude plugin marketplace add "$repo" </dev/null \
      || skip "marketplace $name" "claude plugin marketplace add failed"
  done < <(jq -r '.extraKnownMarketplaces // {} | to_entries[] | "\(.key)\t\(.value.source.repo)"' "$CLAUDE_REPO_SETTINGS")
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    if [ -f "$installed" ] && jq -e --arg i "$id" '.plugins | has($i)' "$installed" >/dev/null 2>&1; then continue; fi
    run_cmd claude plugin install "$id" </dev/null \
      || skip "plugin $id" "claude plugin install failed"
  done < <(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$CLAUDE_REPO_SETTINGS")
}
