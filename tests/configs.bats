load helpers

@test "zshrc parses" {
  run zsh -n "$REPO_ROOT/home/.zshrc"
  [ "$status" -eq 0 ]
}

@test "zshrc has no hard-coded /opt/homebrew outside prefix detection" {
  count=$(grep -c '/opt/homebrew' "$REPO_ROOT/home/.zshrc")
  [ "$count" -eq 1 ]
}

@test "gitconfig includes local identity and has no user section" {
  run git config -f "$REPO_ROOT/home/.gitconfig" include.path
  [ "$output" = "~/.gitconfig.local" ]
  run git config -f "$REPO_ROOT/home/.gitconfig" user.email
  [ "$status" -ne 0 ]
}

@test "gitconfig does not prune on fetch" {
  [ -f "$REPO_ROOT/home/.gitconfig" ]
  run git config -f "$REPO_ROOT/home/.gitconfig" fetch.prune
  [ "$status" -ne 0 ]
}

@test "starship config is valid" {
  [ -f "$REPO_ROOT/home/.config/starship.toml" ]
  STARSHIP_CONFIG="$REPO_ROOT/home/.config/starship.toml" run starship print-config
  [ "$status" -eq 0 ]
  [[ "$output" != *"WARN"* ]] || false
}

@test "every links.txt entry exists under home/" {
  [ -s "$REPO_ROOT/links.txt" ]
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    [ -e "$REPO_ROOT/home/$entry" ] || { echo "missing home/$entry"; return 1; }
  done < "$REPO_ROOT/links.txt"
}

@test "no secrets in repo" {
  run gitleaks dir "$REPO_ROOT" --no-banner
  [ "$status" -eq 0 ]
}

@test "no zsh completion caches are tracked" {
  run git -C "$REPO_ROOT" ls-files '*zcompdump*'
  [ -z "$output" ]
}

@test "mise honours .nvmrc and .java-version files" {
  grep -qE '^idiomatic_version_file_enable_tools = \[.*"node".*"java".*\]' "$REPO_ROOT/home/.config/mise/config.toml"
}

@test "docs carry no local username" {
  # any real /Users/<name> path (placeholders like /Users/<you> are fine)
  ! git -C "$REPO_ROOT" grep -nE '/Users/[A-Za-z0-9._-]+' -- . ':!tests' || false
}
