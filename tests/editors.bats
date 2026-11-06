load helpers

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"; : > "$STUB_LOG"
  export PATH="$REPO_ROOT/tests/stubs:$PATH"
  export DOTFILES_MODE=admin
  export DOTFILES_VSCODE_EXTENSIONS="$REPO_ROOT/tests/fixtures/extensions.txt"
}

@test "installs only missing extensions" {
  STUB_CODE_OUT="eamodio.gitlens" run "$REPO_ROOT/dotfiles" editors
  [ "$status" -eq 0 ]
  [ "$(grep -c '^code --install-extension' "$STUB_LOG")" -eq 1 ]
  grep -q '^code --install-extension redhat.java$' "$STUB_LOG"
}

@test "runs lazyvim headless" {
  run "$REPO_ROOT/dotfiles" editors
  grep -q "^nvim --headless" "$STUB_LOG"
}

@test "missing code is skipped" {
  mkdir -p "$BATS_TEST_TMPDIR/bin"; ln -s "$REPO_ROOT/tests/stubs/_stub" "$BATS_TEST_TMPDIR/bin/nvim"
  PATH="$BATS_TEST_TMPDIR/bin:/usr/bin:/bin" run "$REPO_ROOT/dotfiles" editors
  [ "$status" -eq 0 ]
  [[ "$output" == *"Skipped:"*"VS Code"* ]] || false
  grep -q '^nvim' "$STUB_LOG"
}

@test "never writes vscode settings" {
  run "$REPO_ROOT/dotfiles" editors
  [ ! -e "$HOME/Library/Application Support/Code" ]
}

@test "editors dry-run installs nothing" {
  run "$REPO_ROOT/dotfiles" editors --dry-run
  [ "$status" -eq 0 ]
  ! grep -qE '^(code --install|nvim)' "$STUB_LOG" || false
  [[ "$output" == *"would: code --install-extension"* ]] || false
}

@test "editors installs pinned plugin versions" {
  run "$REPO_ROOT/dotfiles" editors
  grep -q '^nvim --headless +Lazy! restore +qa$' "$STUB_LOG"
  ! grep -q 'Lazy! sync' "$STUB_LOG" || false
}
