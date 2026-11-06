# ~/.zshrc — interactive zsh setup (linked from the dotfiles repo).
#
# Sections, in order:
#   1. Homebrew   — find Homebrew (standard prefix with admin, ~/.local/homebrew without)
#   2. oh-my-zsh  — framework + plugins (git aliases like gst, fzf, zoxide, ...)
#   3. PATH       — curl fix, user bin, mise (Node, Java, Gradle, Python tools)
#   4. Editor     — Neovim everywhere
#   5. Aliases
#   6. Prompt     — Starship (config: ~/.config/starship.toml)
#   7. Local      — ~/.zshrc.local for machine-specific or private settings
#
# There is deliberately no ~/.zprofile: macOS reorders PATH between .zprofile
# and .zshrc, so everything PATH-related lives here.

# ---- 1. Homebrew --------------------------------------------------------------
for _prefix in /opt/homebrew "$HOME/.local/homebrew"; do
  if [[ -x "$_prefix/bin/brew" ]]; then
    export HOMEBREW_PREFIX="$_prefix"
    export PATH="$_prefix/bin:$_prefix/sbin:$PATH"
    break
  fi
done
unset _prefix

# ---- 2. oh-my-zsh ---------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""   # prompt is handled by Starship (section 6)

# git: gst, gco, gp... | fzf: Ctrl-R history search | zoxide: `z <folder>`
# zsh-syntax-highlighting must stay last
plugins=(git fzf zoxide zsh-autosuggestions zsh-syntax-highlighting)

[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# ---- 3. PATH ----------------------------------------------------------------------
# eMudhra CA fix (2026-10-21): prefer Homebrew curl, whose CA bundle drops the
# compromised roots, over /usr/bin/curl
[[ -n "$HOMEBREW_PREFIX" ]] && export PATH="$HOMEBREW_PREFIX/opt/curl/bin:$PATH"
# Claude Code's native installer and other user-level tools
export PATH="$HOME/.local/bin:$PATH"
# mise: language runtimes and their global tools (see ~/.config/mise/config.toml)
command -v mise >/dev/null && eval "$(mise activate zsh)"

# ---- 4. Editor ----------------------------------------------------------------------
export EDITOR=nvim VISUAL=nvim
alias vim=nvim

# ---- 5. Aliases -----------------------------------------------------------------------
alias l="eza"
alias claude='caffeinate -dis claude'          # keep the Mac awake while Claude works
alias codepad='code --profile "CoderPad"'      # VS Code with the CoderPad profile
alias myip="curl --write-out '\n' ifconfig.me/ip"

# ---- 6. Prompt -------------------------------------------------------------------------
command -v starship >/dev/null && eval "$(starship init zsh)"

# ---- 7. Local overrides (untracked) ------------------------------------------------------
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
