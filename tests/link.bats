load helpers

# Each test works on a copy of the repo so nothing touches the real one.
setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"; : > "$STUB_LOG"
  export PATH="$REPO_ROOT/tests/stubs:$PATH"
  export DOTFILES_MODE=admin
  REPO="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$REPO"
  (cd "$REPO_ROOT" && tar --exclude ./.git --exclude ./.superpowers -cf - .) | (cd "$REPO" && tar -xf -)
  export DOTFILES_GIT_NAME="Test User" DOTFILES_GIT_EMAIL="test@example.com"
}

entries() { grep -v '^$' "$REPO/links.txt"; }

@test "link creates symlinks for every entry" {
  run "$REPO/dotfiles" link
  [ "$status" -eq 0 ]
  while IFS= read -r e; do
    [ -L "$HOME/$e" ] || { echo "not a link: $e"; return 1; }
    [ "$(readlink "$HOME/$e")" = "$REPO/home/$e" ]
  done < <(entries)
}

@test "link is idempotent" {
  "$REPO/dotfiles" link
  run "$REPO/dotfiles" link
  [ "$status" -eq 0 ]
  [ ! -d "$HOME/.dotfiles-backup" ]
  while IFS= read -r e; do
    [[ "$output" == *"ok $e"* ]] || { echo "no ok for $e"; return 1; }
  done < <(entries)
}

@test "link backs up existing file" {
  echo old > "$HOME/.zshrc"
  run "$REPO/dotfiles" link
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME"/.dotfiles-backup/*/.zshrc)" = "old" ]
  [ -L "$HOME/.zshrc" ]
}

@test "link backs up existing directory" {
  mkdir -p "$HOME/.config/nvim"; echo mine > "$HOME/.config/nvim/init.lua"
  run "$REPO/dotfiles" link
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME"/.dotfiles-backup/*/.config/nvim/init.lua)" = "mine" ]
  [ -L "$HOME/.config/nvim" ]
}

@test "link handles path with spaces" {
  mkdir -p "$REPO/home/Library/Application Support"
  echo x > "$REPO/home/Library/Application Support/x.txt"
  printf 'Library/Application Support/x.txt\n' > "$BATS_TEST_TMPDIR/links"
  DOTFILES_LINKS="$BATS_TEST_TMPDIR/links" run "$REPO/dotfiles" link
  [ "$status" -eq 0 ]
  [ -L "$HOME/Library/Application Support/x.txt" ]
  [ "$(cat "$HOME/Library/Application Support/x.txt")" = "x" ]
}

@test "link dry-run changes nothing" {
  echo old > "$HOME/.zshrc"
  before=$(cd "$HOME" && find . | sort)
  run "$REPO/dotfiles" link --dry-run
  [ "$status" -eq 0 ]
  after=$(cd "$HOME" && find . | sort)
  [ "$before" = "$after" ]
  [[ "$output" == *"would:"* ]] || false
}

@test "link restore puts backup back" {
  echo old > "$HOME/.zshrc"
  DOTFILES_RUN_ID=run1 "$REPO/dotfiles" link
  run "$REPO/dotfiles" link --restore run1
  [ "$status" -eq 0 ]
  [ ! -L "$HOME/.zshrc" ]
  [ "$(cat "$HOME/.zshrc")" = "old" ]
}

@test "link writes gitconfig.local from env" {
  DOTFILES_GIT_NAME=A DOTFILES_GIT_EMAIL=a@b run "$REPO/dotfiles" link
  [ "$status" -eq 0 ]
  [ "$(git config -f "$HOME/.gitconfig.local" user.email)" = "a@b" ]
  [ "$(git config -f "$HOME/.gitconfig.local" user.name)" = "A" ]
}

@test "link never overwrites gitconfig.local" {
  printf '[user]\n\temail = keep@me\n' > "$HOME/.gitconfig.local"
  run "$REPO/dotfiles" link
  [ "$status" -eq 0 ]
  [ "$(git config -f "$HOME/.gitconfig.local" user.email)" = "keep@me" ]
}

@test "link prefills identity from existing gitconfig" {
  unset DOTFILES_GIT_NAME DOTFILES_GIT_EMAIL
  printf '[user]\n\tname = Old\n\temail = old@x\n' > "$HOME/.gitconfig"
  printf '\n\n' | script -q /dev/null "$REPO/dotfiles" link > "$BATS_TEST_TMPDIR/out" 2>&1
  [ "$(git config -f "$HOME/.gitconfig.local" user.name)" = "Old" ]
  [ "$(git config -f "$HOME/.gitconfig.local" user.email)" = "old@x" ]
}

@test "link skips identity prompt without tty" {
  unset DOTFILES_GIT_NAME DOTFILES_GIT_EMAIL
  run "$REPO/dotfiles" link < /dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipped git identity"* ]] || false
  [ ! -e "$HOME/.gitconfig.local" ]
}

@test "link creates empty zshrc.local once" {
  run "$REPO/dotfiles" link
  [ -f "$HOME/.zshrc.local" ]
  echo "export MINE=1" >> "$HOME/.zshrc.local"
  "$REPO/dotfiles" link
  grep -q 'MINE=1' "$HOME/.zshrc.local"
}

@test "link sets repo hooksPath" {
  git -C "$REPO" init -q
  run "$REPO/dotfiles" link
  [ "$status" -eq 0 ]
  [ "$(git -C "$REPO" config core.hooksPath)" = ".githooks" ]
}

@test "gitconfig is a local file that includes the repo settings" {
  run "$REPO/dotfiles" link
  [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]
  [ "$(git config -f "$HOME/.gitconfig" --get-all include.path | head -1)" = "$REPO/home/.gitconfig" ]
  [ "$(git config --includes --global pull.rebase)" = "true" ]
}

@test "git config --global never writes into the repo" {
  "$REPO/dotfiles" link > /dev/null 2>&1
  git config --global user.email leak@example.com
  ! grep -q 'leak@example.com' "$REPO/home/.gitconfig" || false
}
