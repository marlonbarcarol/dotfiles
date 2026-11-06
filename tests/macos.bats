load helpers

@test "dock group writes exactly its keys" {
  run "$REPO_ROOT/dotfiles" macos dock
  [ "$status" -eq 0 ]
  [ "$(grep -c '^defaults write com.apple.dock' "$STUB_LOG")" -eq 4 ]
  grep -q '^defaults write com.apple.dock autohide -bool true$' "$STUB_LOG"
  grep -q '^defaults write com.apple.dock tilesize -int 47$' "$STUB_LOG"
  grep -q '^defaults write com.apple.dock show-recents -bool false$' "$STUB_LOG"
  grep -q '^defaults write com.apple.dock mru-spaces -bool false$' "$STUB_LOG"
  [ "$(grep -c '^killall Dock' "$STUB_LOG")" -eq 1 ]
}

@test "single group does not touch others" {
  run "$REPO_ROOT/dotfiles" macos dock
  ! grep -q 'com.apple.finder' "$STUB_LOG" || false
  ! grep -q '^killall Finder' "$STUB_LOG" || false
}

@test "dock and hot-corners restart the Dock once" {
  run "$REPO_ROOT/dotfiles" macos dock hot-corners
  [ "$status" -eq 0 ]
  grep -q '^defaults write com.apple.dock wvous-br-modifier -int 1048576$' "$STUB_LOG"
  [ "$(grep -c '^killall Dock' "$STUB_LOG")" -eq 1 ]
}

@test "finder group uses home path and restarts Finder" {
  run "$REPO_ROOT/dotfiles" macos finder
  grep -q "^defaults write com.apple.finder NewWindowTargetPath -string file://$HOME/\$" "$STUB_LOG"
  grep -q '^defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true$' "$STUB_LOG"
  grep -q '^killall Finder' "$STUB_LOG"
}

@test "system group creates screenshot folder" {
  run "$REPO_ROOT/dotfiles" macos system
  [ -d "$HOME/Documents/Screenshots" ]
  grep -q "^defaults write com.apple.screencapture location -string $HOME/Documents/Screenshots\$" "$STUB_LOG"
}

@test "trackpad tap-to-click uses currentHost" {
  run "$REPO_ROOT/dotfiles" macos trackpad
  grep -q '^defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1$' "$STUB_LOG"
  grep -q '^defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3$' "$STUB_LOG"
}

@test "unknown group exits 2" {
  run "$REPO_ROOT/dotfiles" macos nope
  [ "$status" -eq 2 ]
}

@test "failed write is skipped not fatal" {
  STUB_DEFAULTS_EXIT=1 run "$REPO_ROOT/dotfiles" macos system
  [ "$status" -eq 0 ]
  [[ "$output" == *"Skipped:"*"reduceMotion"* ]] || false
}

@test "dry-run writes nothing" {
  run "$REPO_ROOT/dotfiles" macos --dry-run
  [ "$status" -eq 0 ]
  [ ! -s "$STUB_LOG" ]
  [[ "$output" == *"would: defaults write"* ]] || false
}
