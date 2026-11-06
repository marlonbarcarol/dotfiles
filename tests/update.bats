load helpers

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"; : > "$STUB_LOG"
  export PATH="$REPO_ROOT/tests/stubs:$PATH"
  export DOTFILES_MODE=admin DOTFILES_BREW=brew
  # fake oh-my-zsh updater that just logs
  export ZSH="$HOME/.oh-my-zsh"
  mkdir -p "$ZSH/tools"
  printf '#!/bin/bash\necho "omz-upgrade" >> "$STUB_LOG"\n' > "$ZSH/tools/upgrade.sh"
  chmod +x "$ZSH/tools/upgrade.sh"
}

order() { grep -oE '^(brew update|mise upgrade|omz-upgrade|nvim|tldr)' "$STUB_LOG" | uniq | tr '\n' ',' ; }

@test "update brew only runs brew" {
  run "$REPO_ROOT/dotfiles" update brew
  [ "$status" -eq 0 ]
  grep -q '^brew update$' "$STUB_LOG"
  grep -q '^brew upgrade$' "$STUB_LOG"
  grep -q '^brew cleanup$' "$STUB_LOG"
  ! grep -qE '^(mise|nvim|tldr|omz)' "$STUB_LOG" || false
}

@test "update all runs five parts in order" {
  run "$REPO_ROOT/dotfiles" update
  [ "$status" -eq 0 ]
  [ "$(order)" = "brew update,mise upgrade,omz-upgrade,nvim,tldr," ]
  grep -q '^tldr --update$' "$STUB_LOG"
}

@test "unknown part exits 2" {
  run "$REPO_ROOT/dotfiles" update nope
  [ "$status" -eq 2 ]
  [ ! -s "$STUB_LOG" ]
}

@test "failing part does not stop the rest" {
  STUB_BREW_EXIT=1 run "$REPO_ROOT/dotfiles" update
  [ "$status" -eq 0 ]
  grep -q '^mise upgrade' "$STUB_LOG"
  [[ "$output" == *"Skipped:"*"brew"* ]] || false
}

@test "update dry-run runs nothing" {
  run "$REPO_ROOT/dotfiles" update --dry-run
  [ "$status" -eq 0 ]
  [ ! -s "$STUB_LOG" ]
  [[ "$output" == *"would: brew update"* ]] || false
}
