# shellcheck shell=bash
# agentic: this repo's own plugin marketplace and its plugins (marlon-agentic:
# skills and sound hooks) in Claude Code and Codex. Installs what's missing and
# updates what's there, so running it again pulls the latest from GitHub.

AGENTIC_MANIFEST="$DOTFILES_ROOT/.claude-plugin/marketplace.json"
AGENTIC_SETTINGS="$DOTFILES_ROOT/home/.claude/settings.json"

agentic_help() {
  cat <<'EOF'
Usage: ./dotfiles agentic [--dry-run]

Installs or updates this repo's plugin marketplace (marlonbarcarol) and its
plugins (marlon-agentic: skills and sound hooks):
  - Claude Code: adds the marketplace and installs the plugins, or updates them
  - Codex: the same, if Codex is installed

Installs from GitHub, so it gets what's on main, not your local changes.
Docs: docs/agentic.md
EOF
}

# agentic_marketplace / agentic_plugins: names from this repo's manifest.
agentic_marketplace() { jq -r .name "$AGENTIC_MANIFEST"; }
agentic_plugins() { jq -r '.plugins[].name' "$AGENTIC_MANIFEST"; }

# agentic_source: where it installs from (owner/repo), from the Claude settings.
agentic_source() {
  jq -r --arg m "$(agentic_marketplace)" '.extraKnownMarketplaces[$m].source.repo' "$AGENTIC_SETTINGS"
}

agentic_claude() {
  local mp="$1" src="$2" p id
  if ! command -v claude >/dev/null 2>&1; then
    skip "Claude Code plugins" "claude isn't installed: run ./dotfiles install"
    return 0
  fi
  local known="$HOME/.claude/plugins/known_marketplaces.json"
  local installed="$HOME/.claude/plugins/installed_plugins.json"
  if [ -f "$known" ] && jq -e --arg m "$mp" 'has($m)' "$known" >/dev/null 2>&1; then
    run_cmd claude plugin marketplace update "$mp" </dev/null \
      || skip "Claude marketplace $mp" "update failed: run claude plugin marketplace update $mp"
  else
    run_cmd claude plugin marketplace add "$src" </dev/null \
      || { skip "Claude marketplace $mp" "claude plugin marketplace add $src failed"; return 0; }
  fi
  for p in $(agentic_plugins); do
    id="$p@$mp"
    if [ -f "$installed" ] && jq -e --arg i "$id" '.plugins | has($i)' "$installed" >/dev/null 2>&1; then
      run_cmd claude plugin update "$id" </dev/null \
        || skip "Claude plugin $id" "update failed: run claude plugin update $id"
    else
      run_cmd claude plugin install "$id" </dev/null \
        || skip "Claude plugin $id" "install failed: run claude plugin install $id"
    fi
  done
}

agentic_codex() {
  local mp="$1" src="$2" p id
  if ! command -v codex >/dev/null 2>&1; then
    skip "Codex plugins" "codex isn't installed: run ./dotfiles install"
    return 0
  fi
  local config="${CODEX_HOME:-$HOME/.codex}/config.toml"
  if [ -f "$config" ] && grep -qxF "[marketplaces.$mp]" "$config"; then
    run_cmd codex plugin marketplace upgrade "$mp" </dev/null \
      || skip "Codex marketplace $mp" "upgrade failed: run codex plugin marketplace upgrade $mp"
  else
    run_cmd codex plugin marketplace add "$src" </dev/null \
      || { skip "Codex marketplace $mp" "codex plugin marketplace add $src failed"; return 0; }
  fi
  # `codex plugin add` installs the marketplace's current version, new or not.
  for p in $(agentic_plugins); do
    id="$p@$mp"
    run_cmd codex plugin add "$id" </dev/null \
      || skip "Codex plugin $id" "install failed: run codex plugin add $id"
  done
}

agentic_main() {
  [ $# -eq 0 ] || { warn "unknown option: $1"; return 2; }
  local mp src
  mp="$(agentic_marketplace)"
  src="$(agentic_source)"
  agentic_claude "$mp" "$src"
  agentic_codex "$mp" "$src"
  print_skips
}
