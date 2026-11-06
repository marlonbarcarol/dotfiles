load helpers

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"; : > "$STUB_LOG"
  # git and curl are stubbed only here: install must never hit the network in tests.
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  for s in git curl; do ln -s "$REPO_ROOT/tests/stubs/_stub" "$BATS_TEST_TMPDIR/bin/$s"; done
  export PATH="$BATS_TEST_TMPDIR/bin:$REPO_ROOT/tests/stubs:$PATH"
  export DOTFILES_MODE=admin DOTFILES_ROOT="$REPO_ROOT"
  export DOTFILES_BREW=brew DOTFILES_BREWFILE="$REPO_ROOT/tests/fixtures/Brewfile.sample"
  export DOTFILES_APPDIRS="$HOME/Applications"
  export STUB_BREW_LIST_EXIT=0   # by default every cask counts as brew-installed
}

@test "user mode filters needs-admin entries" {
  source "$REPO_ROOT/lib/common.sh"; source "$REPO_ROOT/modules/install.sh"
  run brewfile_for_mode "$DOTFILES_BREWFILE" user
  [[ "$output" != *'cask "docker-desktop"'* ]] || false
  [[ "$output" == *'cask "iterm2"'* ]] || false
  run print_skips
  [[ "$output" == *"docker-desktop"* ]] || false
}

@test "admin mode keeps all entries" {
  source "$REPO_ROOT/lib/common.sh"; source "$REPO_ROOT/modules/install.sh"
  run brewfile_for_mode "$DOTFILES_BREWFILE" admin
  [[ "$output" == *'cask "docker-desktop"'* ]] || false
  [[ "$output" == *'brew "ripgrep"'* ]] || false
}

@test "install user mode uses home prefix and appdir" {
  export STUB_LOG_ENV=HOMEBREW_CASK_OPTS
  DOTFILES_MODE=user run "$REPO_ROOT/dotfiles" install
  [ "$status" -eq 0 ]
  grep -A1 '^brew bundle' "$STUB_LOG" | grep -q "env HOMEBREW_CASK_OPTS=--appdir=$HOME/Applications"
  ! grep -q '^sudo' "$STUB_LOG" || false
}

@test "install adopts manually installed app" {
  mkdir -p "$HOME/Applications/iTerm.app"
  export STUB_BREW_LIST_EXIT=1
  export STUB_BREW_INFO_OUT='{"casks":[{"artifacts":[{"app":["iTerm.app"]}]}]}'
  run "$REPO_ROOT/dotfiles" install
  [ "$status" -eq 0 ]
  adopt=$(grep -n '^brew install --cask --adopt iterm2' "$STUB_LOG" | cut -d: -f1)
  bundle=$(grep -n '^brew bundle' "$STUB_LOG" | cut -d: -f1)
  [ -n "$adopt" ] && [ -n "$bundle" ] && [ "$adopt" -lt "$bundle" ]
}

@test "install clones omz plugins when missing" {
  run "$REPO_ROOT/dotfiles" install
  [ "$status" -eq 0 ]
  grep -q "git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "$STUB_LOG"
  grep -q "git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" "$STUB_LOG"
  mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
  : > "$STUB_LOG"
  "$REPO_ROOT/dotfiles" install
  ! grep -q 'git clone' "$STUB_LOG" || false
}

@test "install runs mise install" {
  run "$REPO_ROOT/dotfiles" install
  [ "$status" -eq 0 ]
  bundle=$(grep -n '^brew bundle' "$STUB_LOG" | cut -d: -f1)
  mise=$(grep -n '^mise install' "$STUB_LOG" | cut -d: -f1)
  [ -n "$mise" ] && [ "$bundle" -lt "$mise" ]
}

@test "install continues after a failing cask" {
  mkdir -p "$HOME/Applications/iTerm.app"
  export STUB_BREW_LIST_EXIT=1 STUB_BREW_INSTALL_EXIT=1
  export STUB_BREW_INFO_OUT='{"casks":[{"artifacts":[{"app":["iTerm.app"]}]}]}'
  run "$REPO_ROOT/dotfiles" install
  [ "$status" -eq 0 ]
  [[ "$output" == *"Skipped:"*"iterm2"* ]] || false
  grep -q '^mise install' "$STUB_LOG"
}

@test "install dry-run changes nothing" {
  run "$REPO_ROOT/dotfiles" install --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would:"* ]] || false
  ! grep -qE '^(brew bundle|brew install|mise install|git clone)' "$STUB_LOG" || false
}

@test "comments mentioning needs-admin are not entries" {
  source "$REPO_ROOT/lib/common.sh"; source "$REPO_ROOT/modules/install.sh"
  brewfile_for_mode "$DOTFILES_BREWFILE" user > /dev/null 2>&1
  run print_skips
  [[ "$output" != *"Entries marked"* ]] || false
  [[ "$output" == *"docker-desktop"* ]] || false
}
