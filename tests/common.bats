load helpers

setup_file() { :; }

load_common() { source "$REPO_ROOT/lib/common.sh"; }

@test "run_cmd prints would in dry-run and does not execute" {
  load_common
  cd "$BATS_TEST_TMPDIR"
  DRY_RUN=1 run run_cmd touch x
  [ "$status" -eq 0 ]
  [ "$output" = "would: touch x" ]
  [ ! -e x ]
}

@test "run_cmd executes when not dry-run" {
  load_common
  cd "$BATS_TEST_TMPDIR"
  DRY_RUN=0 run_cmd touch y
  [ -e y ]
}

@test "is_admin honours DOTFILES_MODE" {
  load_common
  DOTFILES_MODE=admin run is_admin
  [ "$status" -eq 0 ]
  DOTFILES_MODE=user run is_admin
  [ "$status" -eq 1 ]
}

@test "is_admin falls back to id groups" {
  load_common
  unset DOTFILES_MODE
  STUB_ID_OUT="staff everyone" run is_admin
  [ "$status" -eq 1 ]
  STUB_ID_OUT="staff admin" run is_admin
  [ "$status" -eq 0 ]
}

@test "brew_prefix user mode" {
  load_common
  DOTFILES_MODE=user run brew_prefix
  [ "$output" = "$HOME/.local/homebrew" ]
  DOTFILES_MODE=admin run brew_prefix
  [ "$output" = "/opt/homebrew" ]
}

@test "skip records and print_skips summarises" {
  load_common
  skip docker-desktop "needs admin"
  run print_skips
  [[ "$output" == *"docker-desktop"*"needs admin"* ]]
}

@test "backup_dir is stable within a run" {
  load_common
  a=$(backup_dir); b=$(backup_dir)
  [ "$a" = "$b" ]
  [[ "$a" == "$HOME/.dotfiles-backup/"* ]]
}
