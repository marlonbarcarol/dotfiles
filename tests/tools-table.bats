load helpers

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  source "$REPO_ROOT/lib/tools-table.sh"
}

rows() { grep -c '^| `' <<< "$1"; }

@test "table has a row per Brewfile entry" {
  run tools_table "$REPO_ROOT/tests/fixtures/Brewfile.sample" /dev/null
  [ "$status" -eq 0 ]
  [ "$(rows "$output")" -eq 3 ]
  [[ "$output" == *'| Tool | Category | What it'* ]] || false
}

@test "mise tools are listed after Brewfile entries" {
  run tools_table "$REPO_ROOT/tests/fixtures/Brewfile.sample" "$REPO_ROOT/tests/fixtures/mise.sample.toml"
  [ "$(rows "$output")" -eq 5 ]
  last=$(grep '^| `' <<< "$output" | tail -1)
  [[ "$last" == *'`npm:typescript`'*'Code intelligence'*'TypeScript compiler'* ]] || false
  [[ "$output" != *"pipx.uvx"* ]] || false
}

@test "needs-admin marker shown as (admin) in category" {
  run tools_table "$REPO_ROOT/tests/fixtures/Brewfile.sample" /dev/null
  [[ "$output" == *'| `docker-desktop` | Containers (admin) | Docker Desktop |'* ]] || false
}

@test "entry without comment fails with its name" {
  printf 'brew "ripgrep"\n' > "$BATS_TEST_TMPDIR/Brewfile"
  run tools_table "$BATS_TEST_TMPDIR/Brewfile" /dev/null
  [ "$status" -ne 0 ]
  [[ "$output" == *"ripgrep"* ]] || false
}

@test "README in repo is up to date" {
  run readme_tools_up_to_date "$REPO_ROOT/README.md"
  [ "$status" -eq 0 ]
}

@test "write refreshes the README section" {
  printf '# T\n\n<!-- tools:start -->\nold\n<!-- tools:end -->\n\nafter\n' > "$BATS_TEST_TMPDIR/README.md"
  DOTFILES_README="$BATS_TEST_TMPDIR/README.md" run bash "$REPO_ROOT/lib/tools-table.sh" --write
  [ "$status" -eq 0 ]
  run readme_tools_up_to_date "$BATS_TEST_TMPDIR/README.md"
  [ "$status" -eq 0 ]
  grep -q '^after$' "$BATS_TEST_TMPDIR/README.md"
  ! grep -q '^old$' "$BATS_TEST_TMPDIR/README.md" || false
}
