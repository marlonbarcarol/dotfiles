# shellcheck shell=bash
# install: Homebrew + Brewfile, oh-my-zsh and its plugins, mise tools.
# Works with admin rights (Homebrew in /opt/homebrew) and without
# (Homebrew in ~/.local/homebrew, apps in ~/Applications, admin-only entries skipped).

install_help() {
  cat <<'EOF'
Usage: ./dotfiles install [--dry-run] [--user|--admin]

Installs Homebrew (if missing), everything in the Brewfile, oh-my-zsh with
its two community plugins, and the language tools in mise's config.

  --user    force no-admin mode (Homebrew in ~/.local/homebrew, apps in ~/Applications)
  --admin   force admin mode
  (default: detected from your account)

Apps you installed by hand are adopted by Homebrew instead of reinstalled.
Entries marked [needs-admin] in the Brewfile are skipped without admin and
listed at the end.
Docs: docs/install.md
EOF
}

# shellcheck source=/dev/null
. "$DOTFILES_ROOT/modules/claude.sh"

OMZ_PLUGINS="zsh-autosuggestions zsh-syntax-highlighting"

# brewfile_for_mode <Brewfile> <admin|user>: print the Brewfile for this mode.
brewfile_for_mode() {
  local file="$1" mode="$2" line name
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$mode" = "user" ] && [[ "$line" =~ ^(brew|cask)\  ]] && [[ "$line" == *"[needs-admin]"* ]]; then
      name="$(printf '%s' "$line" | sed -E 's/^[a-z]+ "([^"]+)".*/\1/')"
      skip "$name" "needs admin rights (ask IT, or run with admin)"
      continue
    fi
    printf '%s\n' "$line"
  done < "$file"
}

# adopt_existing_casks <Brewfile>: let Homebrew take over apps installed by hand.
adopt_existing_casks() {
  local file="$1" token app dir
  while IFS= read -r token; do
    "$BREW" list --cask "$token" >/dev/null 2>&1 </dev/null && continue
    app="$("$BREW" info --cask --json=v2 "$token" 2>/dev/null </dev/null \
      | jq -r '.casks[0].artifacts[] | .app? // empty | .[] | strings' 2>/dev/null | head -1)"
    [ -n "$app" ] || continue
    for dir in $DOTFILES_APPDIRS; do
      if [ -d "$dir/$app" ]; then
        run_cmd "$BREW" install --cask --adopt "$token" </dev/null \
          || skip "$token" "could not adopt the existing $app"
        break
      fi
    done
  done < <(sed -nE 's/^cask "([^"]+)".*/\1/p' "$file")
}

install_homebrew() {
  command -v "$BREW" >/dev/null 2>&1 && return 0
  local prefix
  prefix="$(brew_prefix)"
  if is_admin; then
    log "installing Homebrew to $prefix (asks for your password once)"
    # shellcheck disable=SC2016  # $(curl ...) must expand in the inner shell, not here
    run_cmd /bin/bash -c '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  else
    log "installing Homebrew to $prefix (no admin rights needed)"
    run_cmd mkdir -p "$prefix"
    run_cmd git clone --depth 1 https://github.com/Homebrew/brew "$prefix"
  fi
  BREW="$prefix/bin/brew"
}

install_ohmyzsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    # KEEP_ZSHRC: our .zshrc comes from `./dotfiles link`; RUNZSH/CHSH: don't switch shells mid-install
    run_cmd /bin/sh -c 'curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | env RUNZSH=no KEEP_ZSHRC=yes CHSH=no sh -s -- --unattended' \
      || skip "oh-my-zsh" "installer failed"
  fi
  local p dir
  for p in $OMZ_PLUGINS; do
    dir="$HOME/.oh-my-zsh/custom/plugins/$p"
    [ -d "$dir" ] && continue
    run_cmd git clone --depth 1 "https://github.com/zsh-users/$p" "$dir" \
      || skip "$p" "git clone failed"
  done
}

install_mise_tools() {
  if ! command -v mise >/dev/null 2>&1; then
    skip "mise tools" "mise is not installed (did brew bundle fail?)"
    return 0
  fi
  # Use the repo's config directly: `link` (which links it into ~) may not have run yet.
  run_cmd env MISE_GLOBAL_CONFIG_FILE="$DOTFILES_ROOT/home/.config/mise/config.toml" mise install \
    || skip "mise tools" "mise install failed; run it again to see why"
}

install_main() {
  local a
  for a in "$@"; do
    case "$a" in
      --user)  DOTFILES_MODE="user" ;;
      --admin) DOTFILES_MODE="admin" ;;
      *) warn "unknown option: $a"; return 2 ;;
    esac
  done
  export DOTFILES_MODE

  local mode=admin
  is_admin || mode=user
  log "mode: $mode"

  BREW="${DOTFILES_BREW:-$(brew_prefix)/bin/brew}"
  : "${DOTFILES_APPDIRS:=/Applications $HOME/Applications}"
  if [ "$mode" = "user" ]; then
    export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
    run_cmd mkdir -p "$HOME/Applications"
  fi

  install_homebrew

  local brewfile filtered
  brewfile="${DOTFILES_BREWFILE:-$DOTFILES_ROOT/Brewfile}"
  filtered="$(mktemp -t dotfiles-brewfile)"
  brewfile_for_mode "$brewfile" "$mode" > "$filtered"

  adopt_existing_casks "$filtered"
  run_cmd "$BREW" bundle --file="$filtered" \
    || skip "brew bundle" "some entries failed; see the output above"
  rm -f "$filtered"

  install_ohmyzsh
  install_mise_tools
  claude_install
  print_skips
}
