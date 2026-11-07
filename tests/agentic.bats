load helpers

# ./dotfiles agentic: this repo's own plugin marketplace, in Claude Code and Codex.

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME/.claude/plugins" "$HOME/.codex"
  export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"; : > "$STUB_LOG"
  export PATH="$REPO_ROOT/tests/stubs:$PATH"
  export DOTFILES_MODE=admin
}

already_installed() {
  echo '{"marlonbarcarol":{"source":{"source":"github","repo":"marlonbarcarol/dotfiles"}}}' \
    > "$HOME/.claude/plugins/known_marketplaces.json"
  echo '{"version":2,"plugins":{"marlon-agentic@marlonbarcarol":[{"scope":"user"}]}}' \
    > "$HOME/.claude/plugins/installed_plugins.json"
  printf '[marketplaces.marlonbarcarol]\nsource_type = "git"\n' > "$HOME/.codex/config.toml"
}

@test "agentic adds the marketplace and installs the plugin in Claude Code and Codex" {
  run "$REPO_ROOT/dotfiles" agentic
  [ "$status" -eq 0 ]
  grep -qx 'claude plugin marketplace add marlonbarcarol/dotfiles' "$STUB_LOG"
  grep -qx 'claude plugin install marlon-agentic@marlonbarcarol' "$STUB_LOG"
  grep -qx 'codex plugin marketplace add marlonbarcarol/dotfiles' "$STUB_LOG"
  grep -qx 'codex plugin add marlon-agentic@marlonbarcarol' "$STUB_LOG"
}

@test "agentic updates to the latest version when already installed" {
  already_installed
  run "$REPO_ROOT/dotfiles" agentic
  [ "$status" -eq 0 ]
  grep -qx 'claude plugin marketplace update marlonbarcarol' "$STUB_LOG"
  grep -qx 'claude plugin update marlon-agentic@marlonbarcarol' "$STUB_LOG"
  grep -qx 'codex plugin marketplace upgrade marlonbarcarol' "$STUB_LOG"
  grep -qx 'codex plugin add marlon-agentic@marlonbarcarol' "$STUB_LOG"
  ! grep -q 'marketplace add' "$STUB_LOG" || false
  ! grep -q 'claude plugin install' "$STUB_LOG" || false
}

@test "agentic dry-run changes nothing" {
  run "$REPO_ROOT/dotfiles" agentic --dry-run
  [ "$status" -eq 0 ]
  [ ! -s "$STUB_LOG" ]
  [[ "$output" == *"would: claude plugin install marlon-agentic@marlonbarcarol"* ]] || false
  [[ "$output" == *"would: codex plugin add marlon-agentic@marlonbarcarol"* ]] || false
}

@test "agentic skips a tool that isn't installed" {
  mkdir -p "$BATS_TEST_TMPDIR/bin"; ln -s "$REPO_ROOT/tests/stubs/_stub" "$BATS_TEST_TMPDIR/bin/claude"
  PATH="$BATS_TEST_TMPDIR/bin:/usr/bin:/bin" run "$REPO_ROOT/dotfiles" agentic
  [ "$status" -eq 0 ]
  grep -q '^claude plugin install' "$STUB_LOG"
  [[ "$output" == *"Skipped:"*"Codex"* ]] || false
}

@test "agentic carries on when one step fails" {
  STUB_CLAUDE_EXIT=1 run "$REPO_ROOT/dotfiles" agentic
  [ "$status" -eq 0 ]
  grep -q '^codex plugin add' "$STUB_LOG"
  [[ "$output" == *"Skipped:"* ]] || false
}

@test "agentic rejects unknown options" {
  run "$REPO_ROOT/dotfiles" agentic --nope
  [ "$status" -eq 2 ]
  [ ! -s "$STUB_LOG" ]
}

@test "install leaves this repo's marketplace to agentic" {
  # shellcheck source=/dev/null
  DOTFILES_ROOT="$REPO_ROOT"; . "$REPO_ROOT/lib/common.sh"; . "$REPO_ROOT/modules/claude.sh"
  claude_install
  grep -q '^claude plugin marketplace add openai/codex-plugin-cc' "$STUB_LOG"
  ! grep -q 'marlonbarcarol' "$STUB_LOG" || false
}
