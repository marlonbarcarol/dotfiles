load helpers

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"; : > "$STUB_LOG"
  export PATH="$REPO_ROOT/tests/stubs:$PATH"
  export DOTFILES_MODE=admin DOTFILES_BREW=brew
  REPO="$BATS_TEST_TMPDIR/repo"; mkdir -p "$REPO"
  (cd "$REPO_ROOT" && tar --exclude ./.git --exclude ./.superpowers -cf - .) | (cd "$REPO" && tar -xf -)
  export DOTFILES_GIT_NAME=T DOTFILES_GIT_EMAIL=t@x
}

@test "doctor fails on unlinked entry" {
  run "$REPO/dotfiles" doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"fail link .zshrc"* ]] || false
}

@test "doctor ok when all linked" {
  "$REPO/dotfiles" link > /dev/null 2>&1
  : > "$STUB_LOG"
  run "$REPO/dotfiles" doctor
  while IFS= read -r e; do
    [[ "$output" == *"ok link $e"* ]] || { echo "not ok: $e"; return 1; }
  done < "$REPO/links.txt"
  [[ "$output" == *"ok git identity"* ]] || false
}

@test "doctor warns on brew extras" {
  # leaves = what you installed on purpose; ripgrep is in the Brewfile, cmatrix isn't
  export STUB_BREW_LEAVES_OUT=$'cmatrix\nripgrep'
  run "$REPO/dotfiles" doctor
  [[ "$output" == *"warn brew extras: cmatrix (installed"* ]] || false
}

@test "doctor extras ignore dependencies" {
  export STUB_BREW_LEAVES_OUT="ripgrep"
  export STUB_BREW_BUNDLE_OUT=$'Would uninstall formulae:\nlibvmaf'
  run "$REPO/dotfiles" doctor
  [[ "$output" == *"ok brew extras"* ]] || false
  [[ "$output" != *"libvmaf"* ]] || false
}

@test "doctor fails when brew bundle has missing entries" {
  STUB_BREW_EXIT=1 run "$REPO/dotfiles" doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"fail brew bundle"* ]] || false
}

@test "doctor fails when README table stale" {
  echo 'brew "cowsay"  # Fun | moo' >> "$REPO/Brewfile"
  run "$REPO/dotfiles" doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"fail README tools table"* ]] || false
}

@test "doctor fails on missing mise tools" {
  STUB_MISE_OUT="node 24.22.2 (missing)" run "$REPO/dotfiles" doctor
  [[ "$output" == *"fail mise"*"node"* ]] || false
}

@test "doctor makes no changes" {
  before=$(cd "$HOME" && find . | sort)
  run "$REPO/dotfiles" doctor
  after=$(cd "$HOME" && find . | sort)
  [ "$before" = "$after" ]
  ! grep -vE '^(brew bundle check|brew leaves|brew list --cask$|brew tap$|mise ls|  env )' "$STUB_LOG" || false
  ! grep -q -- '--force' "$STUB_LOG" || false
}
