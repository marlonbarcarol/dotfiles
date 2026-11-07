# shellcheck shell=bash
# editors: VS Code extensions and Neovim plugins. Editor *settings* are synced
# by each editor's own Settings Sync. This repo keeps reference copies only.

editors_help() {
  cat <<'EOF'
Usage: ./dotfiles editors [--dry-run]

  - Installs any VS Code extension in vscode/extensions.txt you don't have yet.
  - Installs/updates Neovim (LazyVim) plugins to the versions in lazy-lock.json.

It never writes VS Code or IntelliJ settings: their Settings Sync owns those.
Docs: docs/editors.md
EOF
}

editors_vscode() {
  if ! command -v code >/dev/null 2>&1; then
    skip "VS Code extensions" "the 'code' command isn't installed (VS Code → Command Palette → Shell Command: Install 'code' command)"
    return 0
  fi
  local list="${DOTFILES_VSCODE_EXTENSIONS:-$DOTFILES_ROOT/vscode/extensions.txt}" have ext
  have="$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"
  while IFS= read -r ext || [ -n "$ext" ]; do
    [ -z "$ext" ] && continue
    if printf '%s\n' "$have" | grep -qx "$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"; then
      continue
    fi
    run_cmd code --install-extension "$ext" </dev/null \
      || skip "$ext" "VS Code extension install failed"
  done < "$list"
}

editors_neovim() {
  if ! command -v nvim >/dev/null 2>&1; then
    skip "Neovim plugins" "nvim isn't installed (run ./dotfiles install)"
    return 0
  fi
  # restore = install exactly the versions in lazy-lock.json (sync would update them)
  run_cmd nvim --headless "+Lazy! restore" +qa </dev/null \
    || skip "Neovim plugins" "Lazy sync failed: open nvim and run :Lazy"
}

editors_main() {
  [ $# -eq 0 ] || { warn "unknown option: $1"; return 2; }
  editors_vscode
  editors_neovim
  print_skips
}
