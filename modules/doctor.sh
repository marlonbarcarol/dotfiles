# shellcheck shell=bash
# doctor: read-only health check. One line per check: ok | warn | fail.
# Exits 1 if anything failed. Never changes anything (--dry-run is the same).

# shellcheck source=/dev/null
. "$DOTFILES_ROOT/modules/install.sh"     # for brewfile_for_mode
# shellcheck source=/dev/null
. "$DOTFILES_ROOT/lib/tools-table.sh"     # for readme_tools_up_to_date

doctor_help() {
  cat <<'EOF'
Usage: ./dotfiles doctor

Checks, without changing anything:
  - admin/no-admin mode and where Homebrew is
  - every file in links.txt is linked to this repo
  - everything in the Brewfile is installed; lists installed extras
  - every mise tool is installed
  - PATH order (Homebrew curl first, Java from mise)
  - the README tools table matches the Brewfile and mise config
  - secret-scanning hook on, git identity set

Exit code 1 if any check fails. Docs (what each failure means): docs/doctor.md
EOF
}

_DOCTOR_FAILED=0
_ok()   { printf 'ok %s: %s\n' "$1" "$2"; }
_warn() { printf 'warn %s: %s\n' "$1" "$2"; }
_fail() { printf 'fail %s: %s\n' "$1" "$2"; _DOCTOR_FAILED=1; }

doctor_gitconfig() {
  if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ] \
     && git config -f "$HOME/.gitconfig" --get-all include.path 2>/dev/null | grep -qx "$DOTFILES_ROOT/home/.gitconfig"; then
    _ok "gitconfig" "includes the repo settings"
  else
    _fail "gitconfig" "your .gitconfig doesn't include the repo settings — run ./dotfiles link"
  fi
}

doctor_mode() {
  local mode=admin brew
  is_admin || mode=user
  brew="${DOTFILES_BREW:-$(brew_prefix)/bin/brew}"
  if command -v "$brew" >/dev/null 2>&1; then
    _ok mode "$mode, Homebrew at $(brew_prefix)"
  else
    _fail mode "$mode, but no Homebrew at $(brew_prefix) — run ./dotfiles install"
  fi
}

doctor_links() {
  local rel src dst
  while IFS= read -r rel || [ -n "$rel" ]; do
    [ -z "$rel" ] && continue
    case "$rel" in \#*) continue ;; esac
    src="$DOTFILES_ROOT/home/$rel"; dst="$HOME/$rel"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
      _ok "link $rel" "linked"
    else
      _fail "link $rel" "not linked to this repo — run ./dotfiles link"
    fi
  done < "${DOTFILES_LINKS:-$DOTFILES_ROOT/links.txt}"
}

doctor_brew() {
  local brew mode=admin filtered extras
  brew="${DOTFILES_BREW:-$(brew_prefix)/bin/brew}"
  command -v "$brew" >/dev/null 2>&1 || return 0
  is_admin || mode=user
  filtered="$(mktemp -t dotfiles-brewfile)"
  brewfile_for_mode "${DOTFILES_BREWFILE:-$DOTFILES_ROOT/Brewfile}" "$mode" > "$filtered" 2>/dev/null
  if "$brew" bundle check --file="$filtered" >/dev/null 2>&1 </dev/null; then
    _ok "brew bundle" "everything in the Brewfile is installed"
  else
    _fail "brew bundle" "some Brewfile entries are missing — run ./dotfiles install"
  fi
  # Extras = what you installed on purpose (leaves + casks) that the Brewfile lacks.
  # (`brew bundle cleanup` would also list dependencies, which is noise.)
  local wanted
  wanted="$(sed -nE 's/^(brew|cask) "([^"]+)".*/\2/p' "$filtered")"
  extras="$( { "$brew" leaves --installed-on-request 2>/dev/null </dev/null; "$brew" list --cask 2>/dev/null </dev/null; } \
    | while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        printf '%s\n' "$wanted" | grep -qx "${pkg##*/}" || printf '%s ' "$pkg"
      done | sed 's/ $//' || true)"
  rm -f "$filtered"
  if [ -n "$extras" ]; then
    _warn "brew extras" "$extras (installed but not in the Brewfile: add them, or brew uninstall)"
  else
    _ok "brew extras" "none"
  fi
}

doctor_mise() {
  command -v mise >/dev/null 2>&1 || { _fail mise "not installed — run ./dotfiles install"; return; }
  local missing
  missing="$(mise ls --missing 2>/dev/null </dev/null | awk '{print $1}' | tr '\n' ' ' | sed 's/ $//')"
  if [ -n "$missing" ]; then
    _fail mise "missing: $missing — run mise install"
  else
    _ok mise "all tools installed"
  fi
}

doctor_path() {
  local curl_dir="" java
  [ -x /opt/homebrew/bin/brew ] && curl_dir=/opt/homebrew/opt/curl/bin
  [ -x "$HOME/.local/homebrew/bin/brew" ] && curl_dir="$HOME/.local/homebrew/opt/curl/bin"
  if [ -n "$curl_dir" ]; then
    case ":$PATH:" in
      *":$curl_dir:"*":/usr/bin:"*) _ok "PATH curl" "Homebrew curl comes before /usr/bin" ;;
      *) _warn "PATH curl" "Homebrew curl isn't ahead of /usr/bin (eMudhra fix) — open a new shell" ;;
    esac
  fi
  java="$(command -v java || true)"
  if [ -z "$java" ] || [ "$java" = /usr/bin/java ]; then
    _warn "PATH java" "java isn't coming from mise — open a new shell, or run mise install"
  else
    _ok "PATH java" "$java"
  fi
}

doctor_readme() {
  if readme_tools_up_to_date "$DOTFILES_ROOT/README.md" 2>/dev/null; then
    _ok "README tools table" "up to date"
  else
    _fail "README tools table" "out of date — run bash lib/tools-table.sh --write"
  fi
}

doctor_git() {
  if git -C "$DOTFILES_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    if [ "$(git -C "$DOTFILES_ROOT" config core.hooksPath || true)" = ".githooks" ]; then
      _ok "secret scanning" "pre-commit hook on"
    else
      _warn "secret scanning" "pre-commit hook off — run ./dotfiles link"
    fi
  fi
  if git config -f "$HOME/.gitconfig.local" user.email >/dev/null 2>&1; then
    _ok "git identity" "$(git config -f "$HOME/.gitconfig.local" user.email)"
  else
    _warn "git identity" "no email in ~/.gitconfig.local — run ./dotfiles link"
  fi
}

doctor_claude() {
  [ -f "$CLAUDE_REPO_SETTINGS" ] || return 0
  if claude_settings_drift; then
    _ok "claude settings" "matches repo + private settings"
  else
    _warn "claude settings" "the live settings.json differs from the repo (changed via /config or /plugin?) — copy the change into home/.claude/settings.json, then ./dotfiles link"
  fi
}

doctor_main() {
  [ $# -eq 0 ] || { warn "doctor takes no options"; return 2; }
  doctor_mode
  doctor_links
  doctor_gitconfig
  doctor_brew
  doctor_mise
  doctor_path
  doctor_readme
  doctor_git
  doctor_claude
  [ "$_DOCTOR_FAILED" = 0 ]
}
