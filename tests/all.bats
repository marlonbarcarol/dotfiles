load helpers

# Fake modules: each logs its name, doctor fails and one module records a skip.
setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"; : > "$STUB_LOG"
  export DOTFILES_MODULES_DIR="$BATS_TEST_TMPDIR/modules"; mkdir -p "$DOTFILES_MODULES_DIR"
  for m in install link macos iterm editors agentic doctor; do
    printf '%s_help() { :; }\n%s_main() { echo "%s $*" >> "$STUB_LOG"; echo "PATH=$PATH" >> "$STUB_LOG"; }\n' "$m" "$m" "$m" > "$DOTFILES_MODULES_DIR/$m.sh"
  done
  printf 'link_help() { :; }\nlink_main() { echo "link $*" >> "$STUB_LOG"; skip "thing" "because"; }\n' > "$DOTFILES_MODULES_DIR/link.sh"
  printf 'doctor_help() { :; }\ndoctor_main() { echo "doctor" >> "$STUB_LOG"; return 1; }\n' > "$DOTFILES_MODULES_DIR/doctor.sh"
}

@test "all skips macos unless --with-macos" {
  run "$REPO_ROOT/dotfiles" all
  ! grep -q '^macos' "$STUB_LOG" || false
  run "$REPO_ROOT/dotfiles" all --with-macos
  grep -q '^macos' "$STUB_LOG"
  ! grep -q -- '--with-macos' "$STUB_LOG" || false
}

@test "all prints the summary and fails when doctor fails" {
  run "$REPO_ROOT/dotfiles" all
  [ "$status" -eq 1 ]
  [[ "$output" == *"Skipped:"*"thing: because"* ]] || false
}

@test "modules see Homebrew and mise shims on PATH when present" {
  mkdir -p "$HOME/.local/homebrew/bin" "$HOME/.local/share/mise/shims"
  DOTFILES_NO_PATH_SETUP=0 DOTFILES_MODE=user run "$REPO_ROOT/dotfiles" all
  grep -q "PATH=.*$HOME/.local/homebrew/bin" "$STUB_LOG"
  grep -q "PATH=.*$HOME/.local/share/mise/shims" "$STUB_LOG"
}

@test "all passes --user to install only" {
  run "$REPO_ROOT/dotfiles" all --user
  grep -q '^install --user' "$STUB_LOG"
  ! grep -qE '^(link|iterm|editors) .*--user' "$STUB_LOG" || false
}

@test "a failing module doesn't stop the others" {
  printf 'link_help() { :; }\nlink_main() { skip "x" "y"; false; }\n' > "$DOTFILES_MODULES_DIR/link.sh"
  run "$REPO_ROOT/dotfiles" all
  [ "$status" -eq 1 ]
  grep -q '^iterm' "$STUB_LOG"
  grep -q '^doctor' "$STUB_LOG"
  [[ "$output" == *"Skipped:"*"x: y"* ]] || false
}

@test "all runs agentic after editors" {
  run "$REPO_ROOT/dotfiles" all
  [ "$(grep -oE '^(editors|agentic|doctor)' "$STUB_LOG" | tr '\n' ,)" = "editors,agentic,doctor," ]
}
