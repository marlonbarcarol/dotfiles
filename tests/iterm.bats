load helpers

# `ps` is stubbed here only: STUB_PS_OUT lists running processes.
setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"; : > "$STUB_LOG"
  mkdir -p "$BATS_TEST_TMPDIR/bin"; ln -s "$REPO_ROOT/tests/stubs/_stub" "$BATS_TEST_TMPDIR/bin/ps"
  export PATH="$BATS_TEST_TMPDIR/bin:$REPO_ROOT/tests/stubs:$PATH"
  export DOTFILES_MODE=admin
  # pgrep can't see GUI apps from some shells, so it must not decide anything
  export STUB_PGREP_EXIT=1
}
ITERM_PROC=/Applications/iTerm.app/Contents/MacOS/iTerm2

DP() { echo "$HOME/Library/Application Support/iTerm2/DynamicProfiles"; }

@test "profiles copied into path with spaces" {
  STUB_PS_OUT="/usr/sbin/cfprefsd" run "$REPO_ROOT/dotfiles" iterm
  [ "$status" -eq 0 ]
  cmp -s "$REPO_ROOT/iterm/DynamicProfiles/dotfiles.json" "$(DP)/dotfiles.json"
}

@test "themes only with --themes" {
  STUB_PS_OUT="/usr/sbin/cfprefsd" run "$REPO_ROOT/dotfiles" iterm
  [ ! -e "$(DP)/themes.json" ]
  STUB_PS_OUT="/usr/sbin/cfprefsd" run "$REPO_ROOT/dotfiles" iterm --themes
  [ -f "$(DP)/themes.json" ]
}

@test "differing existing profile is backed up" {
  mkdir -p "$(DP)"; echo '{"Profiles":[]}' > "$(DP)/dotfiles.json"
  STUB_PS_OUT="/usr/sbin/cfprefsd" run "$REPO_ROOT/dotfiles" iterm
  [ "$status" -eq 0 ]
  grep -q '"Profiles":\[\]' "$HOME"/.dotfiles-backup/*/"Library/Application Support/iTerm2/DynamicProfiles/dotfiles.json"
}

@test "globals skipped while iTerm runs" {
  STUB_PS_OUT="$ITERM_PROC" run "$REPO_ROOT/dotfiles" iterm
  [ "$status" -eq 0 ]
  ! grep -q '^defaults write com.googlecode.iterm2' "$STUB_LOG" || false
  [[ "$output" == *"Skipped:"*"Terminal.app"* ]] || false
}

@test "globals written when iTerm not running" {
  STUB_PS_OUT="/usr/sbin/cfprefsd" run "$REPO_ROOT/dotfiles" iterm
  grep -q '^defaults write com.googlecode.iterm2 NSQuitAlwaysKeepsWindows -bool true$' "$STUB_LOG"
  grep -q '^defaults write com.googlecode.iterm2 OpenNoWindowsAtStartup -bool false$' "$STUB_LOG"
}

@test "hotkey profile uses option double-tap" {
  run jq '.Profiles[] | select(.Name=="Hotkey Window") | ."HotKey Modifier Activation"' "$REPO_ROOT/iterm/DynamicProfiles/dotfiles.json"
  [ "$output" = "2" ]
}

@test "profiles json valid" {
  for f in "$REPO_ROOT"/iterm/DynamicProfiles/*.json; do
    jq empty "$f" || { echo "invalid: $f"; return 1; }
  done
}

@test "iterm dry-run changes nothing" {
  STUB_PS_OUT="/usr/sbin/cfprefsd" run "$REPO_ROOT/dotfiles" iterm --dry-run
  [ "$status" -eq 0 ]
  [ ! -e "$(DP)" ]
  ! grep -q '^defaults write' "$STUB_LOG" || false
}
