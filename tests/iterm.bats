load helpers

DP() { echo "$HOME/Library/Application Support/iTerm2/DynamicProfiles"; }

@test "profiles copied into path with spaces" {
  STUB_PGREP_EXIT=1 run "$REPO_ROOT/dotfiles" iterm
  [ "$status" -eq 0 ]
  cmp -s "$REPO_ROOT/iterm/DynamicProfiles/dotfiles.json" "$(DP)/dotfiles.json"
}

@test "themes only with --themes" {
  STUB_PGREP_EXIT=1 run "$REPO_ROOT/dotfiles" iterm
  [ ! -e "$(DP)/themes.json" ]
  STUB_PGREP_EXIT=1 run "$REPO_ROOT/dotfiles" iterm --themes
  [ -f "$(DP)/themes.json" ]
}

@test "differing existing profile is backed up" {
  mkdir -p "$(DP)"; echo '{"Profiles":[]}' > "$(DP)/dotfiles.json"
  STUB_PGREP_EXIT=1 run "$REPO_ROOT/dotfiles" iterm
  [ "$status" -eq 0 ]
  grep -q '"Profiles":\[\]' "$HOME"/.dotfiles-backup/*/"Library/Application Support/iTerm2/DynamicProfiles/dotfiles.json"
}

@test "globals skipped while iTerm runs" {
  STUB_PGREP_EXIT=0 run "$REPO_ROOT/dotfiles" iterm
  [ "$status" -eq 0 ]
  ! grep -q '^defaults write com.googlecode.iterm2' "$STUB_LOG" || false
  [[ "$output" == *"Skipped:"*"Terminal.app"* ]] || false
}

@test "globals written when iTerm not running" {
  STUB_PGREP_EXIT=1 run "$REPO_ROOT/dotfiles" iterm
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
  STUB_PGREP_EXIT=1 run "$REPO_ROOT/dotfiles" iterm --dry-run
  [ "$status" -eq 0 ]
  [ ! -e "$(DP)" ]
  ! grep -q '^defaults write' "$STUB_LOG" || false
}
