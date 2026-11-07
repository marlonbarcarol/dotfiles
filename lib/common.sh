# shellcheck shell=bash
# Shared helpers for every module. Sourced by ./dotfiles, never run directly.
# Compatible with macOS /bin/bash 3.2.

: "${DOTFILES_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export DOTFILES_ROOT
: "${DOTFILES_RUN_ID:=$(date +%Y%m%d-%H%M%S)}"
export DOTFILES_RUN_ID
: "${DOTFILES_SKIPS:=$(mktemp -t dotfiles-skips)}"
export DOTFILES_SKIPS
: "${DRY_RUN:=0}"

# log/warn: progress and problems go to stderr so stdout stays clean.
log()  { printf '==> %s\n' "$*" >&2; }
warn() { printf '!! %s\n' "$*" >&2; }

# run_cmd: every side effect goes through here so --dry-run is uniform.
run_cmd() {
  if [ "$DRY_RUN" = "1" ]; then
    printf 'would: %s\n' "$*"
    return 0
  fi
  "$@"
}

# is_admin: DOTFILES_MODE=admin|user forces the answer, otherwise ask macOS.
is_admin() {
  case "${DOTFILES_MODE:-}" in
    admin) return 0 ;;
    user)  return 1 ;;
  esac
  id -Gn | tr ' ' '\n' | grep -qx admin
}

# brew_prefix: standard location with admin rights, per-user one without.
# (~/.homebrew is avoided on purpose: Homebrew 6 keeps tap-trust state there.)
brew_prefix() {
  if is_admin; then
    echo /opt/homebrew
  else
    echo "$HOME/.local/homebrew"
  fi
}

# backup_dir: one timestamped folder per run for everything we replace.
backup_dir() {
  echo "$HOME/.dotfiles-backup/$DOTFILES_RUN_ID"
}

# skip/print_skips: collect items we chose not to do and say why at the end.
skip() {
  printf '%s\t%s\n' "$1" "$2" >> "$DOTFILES_SKIPS"
  warn "skipped $1: $2"
}

print_skips() {
  [ -s "$DOTFILES_SKIPS" ] || return 0
  echo "Skipped:"
  while IFS="$(printf '\t')" read -r item reason; do
    printf '  - %s: %s\n' "$item" "$reason"
  done < "$DOTFILES_SKIPS"
}
