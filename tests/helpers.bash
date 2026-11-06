# Shared bats setup: sandbox $HOME, stubbed system commands, admin mode.
# Modules must only see stubs and the test's own PATH, never this Mac's tools.
export DOTFILES_NO_PATH_SETUP=1

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"
  : > "$STUB_LOG"
  export PATH="$REPO_ROOT/tests/stubs:$PATH"
  export DOTFILES_MODE=admin
  export DOTFILES_ROOT="$REPO_ROOT"
}
