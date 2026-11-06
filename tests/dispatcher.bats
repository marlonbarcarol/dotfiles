load helpers

@test "help lists all seven modules" {
  run "$REPO_ROOT/dotfiles" --help
  [ "$status" -eq 0 ]
  for m in install link macos iterm editors update doctor; do
    [[ "$output" == *"$m"* ]] || { echo "missing $m"; return 1; }
  done
}

@test "unknown module exits 2" {
  run "$REPO_ROOT/dotfiles" nope
  [ "$status" -eq 2 ]
  [[ "$output" == *"nope"* ]] || false
}

@test "dry-run is passed to module" {
  DOTFILES_MODULES_DIR="$REPO_ROOT/tests/fixtures/modules" run "$REPO_ROOT/dotfiles" echo --dry-run
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}
