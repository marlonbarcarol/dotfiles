# shellcheck shell=bash
# link: symlink the config files in home/ into $HOME (list: links.txt).
# Anything already in the way is moved to ~/.dotfiles-backup/<run-id>/, never
# deleted. Also creates the untracked local files and the git identity.

link_help() {
  cat <<'EOF'
Usage: ./dotfiles link [--dry-run] [--restore <run-id>]

Links every path listed in links.txt from the repo's home/ folder into your
home folder. Existing files are moved to ~/.dotfiles-backup/<run-id>/ first.

  --dry-run           show what would be linked or backed up
  --restore <run-id>  put a backup set back (run-ids: ls ~/.dotfiles-backup)

Also: creates ~/.zshrc.local and ~/.gitconfig.local if missing (asks for your
git name and email; or set DOTFILES_GIT_NAME / DOTFILES_GIT_EMAIL), and turns
on the repo's secret-scanning git hook.
Docs: docs/link.md
EOF
}

# shellcheck source=/dev/null
. "$DOTFILES_ROOT/modules/claude.sh"

# link_one <relpath>: link $HOME/<relpath> to the repo copy; prints the state.
link_one() {
  local rel="$1"
  local src="$DOTFILES_ROOT/home/$rel"
  local dst="$HOME/$rel"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "ok $rel"
    return 0
  fi
  local state="linked"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local bdir
    bdir="$(backup_dir)"
    run_cmd mkdir -p "$(dirname "$bdir/$rel")"
    run_cmd mv "$dst" "$bdir/$rel"
    if [ "$DRY_RUN" != "1" ]; then
      printf '%s\n' "$rel" >> "$bdir/.manifest"
    fi
    state="backed-up+linked"
  fi
  run_cmd mkdir -p "$(dirname "$dst")"
  run_cmd ln -s "$src" "$dst"
  echo "$state $rel"
}

# gitconfig_stub: the exact contents of ~/.gitconfig. It's a real local file
# (not a link) so `git config --global ...` writes here, never into the
# public repo; shared settings come in through the include.
gitconfig_stub() {
  printf '# Local git config (not tracked). Shared settings come from the dotfiles repo;\n'
  # shellcheck disable=SC2016  # backticks are literal text in the file
  printf '# `git config --global ...` writes here, never into the repo.\n'
  printf '[include]\n\tpath = %s\n' "$DOTFILES_ROOT/home/.gitconfig"
}

# ensure_gitconfig: write ~/.gitconfig as the stub, backing up anything else.
ensure_gitconfig() {
  local dst="$HOME/.gitconfig"
  if [ -f "$dst" ] && [ ! -L "$dst" ] && [ "$(cat "$dst")" = "$(gitconfig_stub)" ]; then
    echo "ok .gitconfig (includes repo settings)"
    return 0
  fi
  if [ "$DRY_RUN" = "1" ]; then
    echo "would: write ~/.gitconfig that includes $DOTFILES_ROOT/home/.gitconfig"
    return 0
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local bdir
    bdir="$(backup_dir)"
    mkdir -p "$bdir"
    mv "$dst" "$bdir/.gitconfig"
    printf '%s\n' ".gitconfig" >> "$bdir/.manifest"
  fi
  gitconfig_stub > "$dst"
  echo "wrote .gitconfig (includes repo settings)"
}

# ensure_local_files: untracked per-machine files, created once, never touched again.
ensure_local_files() {
  if [ ! -e "$HOME/.zshrc.local" ]; then
    if [ "$DRY_RUN" = "1" ]; then
      echo "would: create ~/.zshrc.local"
    else
      printf '# Machine-specific or private shell settings (not tracked by dotfiles).\n' > "$HOME/.zshrc.local"
    fi
  fi
}

# ensure_git_identity <default-name> <default-email>
# Order: env vars -> interactive prompt (with defaults) -> skip.
ensure_git_identity() {
  local file="$HOME/.gitconfig.local"
  [ -e "$file" ] && return 0
  local name="${DOTFILES_GIT_NAME:-}" email="${DOTFILES_GIT_EMAIL:-}"
  if [ -z "$name" ] || [ -z "$email" ]; then
    if [ "$DRY_RUN" = "1" ]; then
      echo "would: ask for git name and email, write ~/.gitconfig.local"
      return 0
    fi
    if [ ! -t 0 ]; then
      skip "git identity" "no terminal to ask; set DOTFILES_GIT_NAME and DOTFILES_GIT_EMAIL or re-run ./dotfiles link"
      return 0
    fi
    local answer
    read -r -p "Git name [$1]: " answer || answer=""
    name="${answer:-$1}"
    read -r -p "Git email [$2]: " answer || answer=""
    email="${answer:-$2}"
  fi
  if [ -z "$name" ] || [ -z "$email" ]; then
    skip "git identity" "name or email left empty"
    return 0
  fi
  run_cmd git config -f "$file" user.name "$name"
  run_cmd git config -f "$file" user.email "$email"
}

# ensure_hooks: enable the gitleaks pre-commit hook for this repo.
ensure_hooks() {
  if ! git -C "$DOTFILES_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    return 0
  fi
  if [ "$(git -C "$DOTFILES_ROOT" config core.hooksPath || true)" != ".githooks" ]; then
    run_cmd git -C "$DOTFILES_ROOT" config core.hooksPath .githooks
  fi
}

# link_restore <run-id>: move each backed-up path back over its symlink.
link_restore() {
  local bdir="$HOME/.dotfiles-backup/$1"
  if [ ! -f "$bdir/.manifest" ]; then
    warn "no backup set at $bdir"
    return 2
  fi
  local rel
  while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    if [ -L "$HOME/$rel" ]; then
      run_cmd rm "$HOME/$rel"
    fi
    run_cmd mkdir -p "$(dirname "$HOME/$rel")"
    run_cmd mv "$bdir/$rel" "$HOME/$rel"
    echo "restored $rel"
  done < "$bdir/.manifest"
}

link_main() {
  if [ "${1:-}" = "--restore" ]; then
    [ -n "${2:-}" ] || { warn "--restore needs a run-id"; return 2; }
    link_restore "$2"
    return
  fi
  # Read identity defaults before ~/.gitconfig gets moved into a backup.
  local def_name def_email
  def_name="$(git config -f "$HOME/.gitconfig" user.name 2>/dev/null || true)"
  def_email="$(git config -f "$HOME/.gitconfig" user.email 2>/dev/null || true)"

  local links="${DOTFILES_LINKS:-$DOTFILES_ROOT/links.txt}" rel
  while IFS= read -r rel || [ -n "$rel" ]; do
    [ -z "$rel" ] && continue
    case "$rel" in \#*) continue ;; esac
    link_one "$rel"
  done < "$links"

  ensure_gitconfig
  ensure_local_files
  ensure_git_identity "$def_name" "$def_email"
  ensure_hooks
  claude_settings_merge
  claude_skills_install
  print_skips
}
