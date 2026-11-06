# shellcheck shell=bash
# iterm: install the iTerm2 Dynamic Profiles (Main, Hotkey Window, optional
# themes) and the global "reopen windows at launch" setting.

iterm_help() {
  cat <<'EOF'
Usage: ./dotfiles iterm [--dry-run] [--themes]

Copies the profiles in iterm/DynamicProfiles/ into iTerm2's DynamicProfiles
folder (iTerm picks them up while running):
  Main            everyday profile (font, right ⌥ as Meta, no prompt arrows)
  Hotkey Window   double-tap ⌥ from any app to drop down a terminal
  --themes        also add "Theme: …" profiles to preview colour schemes

Also makes iTerm reopen your windows and tabs after you quit it. iTerm
overwrites its own settings when it quits, so that part only runs when iTerm
isn't running — run it once from Terminal.app.
Docs (manual steps, shortcuts): docs/iterm.md
EOF
}

ITERM_DP_DIR="Library/Application Support/iTerm2/DynamicProfiles"

# iterm_copy <file>: copy one profile file, backing up a different existing one.
iterm_copy() {
  local name="$1" src dst rel
  src="$DOTFILES_ROOT/iterm/DynamicProfiles/$name"
  rel="$ITERM_DP_DIR/$name"
  dst="$HOME/$rel"
  if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    echo "ok $name"
    return 0
  fi
  if [ -e "$dst" ]; then
    local bdir
    bdir="$(backup_dir)"
    run_cmd mkdir -p "$(dirname "$bdir/$rel")"
    run_cmd cp "$dst" "$bdir/$rel"
  fi
  run_cmd mkdir -p "$(dirname "$dst")"
  run_cmd cp "$src" "$dst"
  echo "installed $name"
}

# iterm_running: `pgrep` can't see GUI apps from some shells; `ps` can.
iterm_running() {
  # shellcheck disable=SC2009  # pgrep is exactly what misses iTerm here
  ps -axo comm 2>/dev/null | grep -q '/iTerm\.app/Contents/MacOS/iTerm2$'
}

iterm_globals() {
  if iterm_running; then
    skip "iTerm global settings" "iTerm is running and would overwrite them — quit iTerm and run ./dotfiles iterm from Terminal.app"
    return 0
  fi
  # Reopen windows/tabs after quitting (iTerm only; other apps keep the macOS setting)
  run_cmd defaults write com.googlecode.iterm2 NSQuitAlwaysKeepsWindows -bool true \
    || skip "iTerm NSQuitAlwaysKeepsWindows" "defaults write failed"
  run_cmd defaults write com.googlecode.iterm2 OpenNoWindowsAtStartup -bool false \
    || skip "iTerm OpenNoWindowsAtStartup" "defaults write failed"
}

iterm_main() {
  local themes=0 a
  for a in "$@"; do
    case "$a" in
      --themes) themes=1 ;;
      *) warn "unknown option: $a"; return 2 ;;
    esac
  done
  iterm_copy dotfiles.json
  [ "$themes" = 1 ] && iterm_copy themes.json
  iterm_globals
  print_skips
}
