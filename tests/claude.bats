load helpers

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME/.claude"
  export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"; : > "$STUB_LOG"
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  for s in git curl; do ln -s "$REPO_ROOT/tests/stubs/_stub" "$BATS_TEST_TMPDIR/bin/$s"; done
  export PATH="$REPO_ROOT/tests/stubs:$PATH"
  export DOTFILES_MODE=admin DOTFILES_BREW=brew STUB_BREW_LIST_EXIT=0
  export DOTFILES_GIT_NAME=T DOTFILES_GIT_EMAIL=t@x
  REPO="$BATS_TEST_TMPDIR/repo"; mkdir -p "$REPO"
  (cd "$REPO_ROOT" && tar --exclude ./.git --exclude ./.superpowers -cf - .) | (cd "$REPO" && tar -xf -)
}

@test "settings merge includes private keys" {
  echo '{"autoMode":{"environment":["x"]}}' > "$HOME/.claude/settings.private.json"
  run "$REPO/dotfiles" link
  [ "$status" -eq 0 ]
  [ "$(jq -r '.autoMode.environment[0]' "$HOME/.claude/settings.json")" = "x" ]
  [ "$(jq -r '.statusLine.type' "$HOME/.claude/settings.json")" = "command" ]
  [ ! -L "$HOME/.claude/settings.json" ]
}

@test "settings merge works without private file" {
  run "$REPO/dotfiles" link
  [ "$status" -eq 0 ]
  jq -e '.enabledPlugins' "$HOME/.claude/settings.json" > /dev/null
  [ "$(jq -r '.autoMode' "$HOME/.claude/settings.json")" = "null" ]
}

@test "existing live settings are backed up before merge" {
  echo '{"mine":true}' > "$HOME/.claude/settings.json"
  run "$REPO/dotfiles" link
  [ "$(jq -r .mine "$HOME"/.dotfiles-backup/*/.claude/settings.json)" = "true" ]
}

@test "repo settings contain no private IPs or home paths" {
  ! grep -qE '192\.168\.|/Users/' "$REPO_ROOT/home/.claude/settings.json" || false
}

@test "context7 not enabled" {
  [ "$(jq -r '.enabledPlugins["context7@claude-plugins-official"]' "$REPO_ROOT/home/.claude/settings.json")" = "null" ]
}

@test "drift detected after live edit" {
  "$REPO/dotfiles" link > /dev/null 2>&1
  jq '.tui = "default"' "$HOME/.claude/settings.json" > "$BATS_TEST_TMPDIR/s" && mv "$BATS_TEST_TMPDIR/s" "$HOME/.claude/settings.json"
  run "$REPO/dotfiles" doctor
  [[ "$output" == *"warn claude settings"* ]] || false
}

@test "no drift right after link" {
  "$REPO/dotfiles" link > /dev/null 2>&1
  run "$REPO/dotfiles" doctor
  [[ "$output" == *"ok claude settings"* ]] || false
}

@test "claude installer skipped when claude exists" {
  PATH="$BATS_TEST_TMPDIR/bin:$PATH" DOTFILES_BREWFILE="$REPO_ROOT/tests/fixtures/Brewfile.sample" run "$REPO/dotfiles" install
  [ "$status" -eq 0 ]
  ! grep -q 'claude.ai/install.sh' "$STUB_LOG" || false
  grep -q '^claude plugin install superpowers@claude-plugins-official$' "$STUB_LOG"
  grep -q '^claude plugin marketplace add openai/codex-plugin-cc$' "$STUB_LOG"
}

@test "already installed plugins are not reinstalled" {
  mkdir -p "$HOME/.claude/plugins"
  echo '{"version":2,"plugins":{"superpowers@claude-plugins-official":[]}}' > "$HOME/.claude/plugins/installed_plugins.json"
  PATH="$BATS_TEST_TMPDIR/bin:$PATH" DOTFILES_BREWFILE="$REPO_ROOT/tests/fixtures/Brewfile.sample" run "$REPO/dotfiles" install
  ! grep -q '^claude plugin install superpowers@' "$STUB_LOG" || false
}

@test "missing skill is added via skills CLI" {
  run "$REPO/dotfiles" link
  grep -q '^npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global -y$' "$STUB_LOG"
}

@test "present skill is not re-added" {
  mkdir -p "$HOME/.claude/skills/security-audit"
  run "$REPO/dotfiles" link
  ! grep -q 'skill security-audit' "$STUB_LOG" || false
  grep -q 'skill find-skills' "$STUB_LOG"
}

@test "global CLAUDE.md is exactly two lines" {
  [ "$(wc -l < "$REPO_ROOT/home/.claude/CLAUDE.md" | tr -d ' ')" -eq 2 ]
  grep -qx -- '- British English.' "$REPO_ROOT/home/.claude/CLAUDE.md"
}

@test "broken private settings keep the live file intact" {
  echo '{"mine":true}' > "$HOME/.claude/settings.json"
  echo '{ not json' > "$HOME/.claude/settings.private.json"
  run "$REPO/dotfiles" link
  [ "$status" -eq 0 ]
  [ "$(jq -r .mine "$HOME/.claude/settings.json")" = "true" ]
  [[ "$output" == *"Skipped:"*"settings"* ]] || false
}
