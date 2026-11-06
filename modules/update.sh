# shellcheck shell=bash
# update: upgrade everything on this Mac, or one part. Never runs on its own —
# you decide when, so nothing changes under you in the middle of work.

UPDATE_PARTS="brew mise omz nvim tldr"

update_help() {
  cat <<'EOF'
Usage: ./dotfiles update [--dry-run] [part...]

Parts (none = all, in this order):
  brew   brew update, brew upgrade, brew cleanup  (CLI tools, apps, fonts)
  mise   mise upgrade                             (Node, Java, Gradle, Codex, ...)
  omz    oh-my-zsh's own updater
  nvim   Neovim plugins (Lazy sync; updates lazy-lock.json in the repo)
  tldr   refresh the tldr pages cache

Examples: ./dotfiles update            ./dotfiles update brew mise
Docs: docs/update.md
EOF
}

# _update_brew_bin: Homebrew for this mode (same lookup as install), else PATH.
_update_brew_bin() {
  if [ -n "${DOTFILES_BREW:-}" ]; then echo "$DOTFILES_BREW"; return; fi
  if [ -x "$(brew_prefix)/bin/brew" ]; then brew_prefix | sed 's|$|/bin/brew|'; else echo brew; fi
}

update_brew() {
  local brew
  brew="$(_update_brew_bin)"
  run_cmd "$brew" update && run_cmd "$brew" upgrade && run_cmd "$brew" cleanup
}

# mise comes from Homebrew, so `brew upgrade` updates mise itself; this updates its tools.
update_mise() { run_cmd mise upgrade; }

update_omz() {
  local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
  [ -x "$zsh_dir/tools/upgrade.sh" ] || { skip "omz" "oh-my-zsh isn't installed"; return 0; }
  run_cmd "$zsh_dir/tools/upgrade.sh"
}

update_nvim() { run_cmd nvim --headless "+Lazy! sync" +qa; }

update_tldr() { run_cmd tldr --update; }

# update_available <part>: is the tool behind this part installed?
update_available() {
  case "$1" in
    brew) command -v "$(_update_brew_bin)" >/dev/null 2>&1 ;;
    omz)  return 0 ;;   # update_omz reports a missing oh-my-zsh itself
    *)    command -v "$1" >/dev/null 2>&1 ;;
  esac
}

update_main() {
  local parts=("$@") p
  [ ${#parts[@]} -eq 0 ] && read -r -a parts <<< "$UPDATE_PARTS"
  for p in "${parts[@]}"; do
    case " $UPDATE_PARTS " in
      *" $p "*) ;;
      *) warn "unknown part: $p (parts: $UPDATE_PARTS)"; return 2 ;;
    esac
  done
  for p in "${parts[@]}"; do
    log "update: $p"
    if ! update_available "$p"; then
      skip "$p" "not installed"
      continue
    fi
    "update_$p" </dev/null || skip "$p" "update failed; run ./dotfiles update $p to see why"
  done
  print_skips
}
