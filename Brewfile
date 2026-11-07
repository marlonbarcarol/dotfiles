# Brewfile: everything Homebrew installs (run by `./dotfiles install`).
#
# Line format:  <brew|cask> "<name>"  # <Category> [needs-admin] | <what it's for>
#   - The comment is required: the README's "What gets installed" table is
#     generated from it (bash lib/tools-table.sh --write).
#   - [needs-admin] marks entries skipped on Macs without admin rights.
# No third-party taps: Homebrew 6 requires taps to be explicitly trusted.

# ---- Shell & prompt ----
brew "starship"                     # Shell | fast, minimal prompt (replaces powerlevel10k)
brew "eza"                          # Shell | modern `ls` with colours and git status (alias `l`)
brew "fzf"                          # Shell | fuzzy finder: Ctrl-R searches your command history
brew "zoxide"                       # Shell | `z <part-of-folder>` jumps to folders you've visited
brew "tlrc"                         # Shell | `tldr <command>`: short, practical examples for any command
brew "tmux"                         # Shell | terminal multiplexer: split panes, sessions that survive closing
brew "tree"                         # Shell | show a folder as a tree

# ---- Search & files ----
brew "ripgrep"                      # Search | `rg`: very fast search through code (newer grep)
brew "fd"                           # Search | fast, friendly file finder (newer find)
brew "bat"                          # Search | `cat` with syntax highlighting and line numbers
brew "yq"                           # Search | read and edit YAML from the terminal (jq ships with macOS)

# ---- Git ----
brew "gh"                           # Git | GitHub CLI: PRs, issues, auth from the terminal
brew "git-delta"                    # Git | readable `git diff` with in-line highlights (wired into .gitconfig)
brew "lazygit"                      # Git | full-screen terminal UI for git: stage, commit, rebase with keys
brew "gitleaks"                     # Git | finds secrets before they're committed (pre-commit hook)

# ---- Languages & build ----
brew "mise"                         # Languages | one manager for Node, Java, Gradle, Scala, Python tools (replaces nvm + SDKMAN)
brew "uv"                           # Languages | fast Python package and tool installer (used by mise)
brew "maven"                        # Languages | Maven build tool for Java
brew "jdtls"                        # Code intelligence | Java language server for Claude Code's jdtls-lsp plugin

# ---- Containers & cloud ----
brew "lazydocker"                   # Containers | terminal UI for Docker: containers, logs, restarts
brew "dive"                         # Containers | explore Docker image layers and wasted space
brew "awscli"                       # Cloud | AWS command line (sign in with `aws login` / SSO)

# ---- Networking & system ----
brew "curl"                         # Networking | curl with an up-to-date CA bundle (eMudhra fix)
brew "xh"                           # Networking | quick HTTP requests from the terminal (like REST Client)
brew "btop"                         # System | better Activity Monitor in the terminal

# ---- Editors ----
brew "neovim"                       # Editors | Neovim with LazyVim (`vim` is aliased to it)
brew "nano"                         # Editors | GNU nano: needed for ~/.nanorc (syntax colours). macOS's /usr/bin/nano can't use it
brew "tree-sitter-cli"              # Editors | tree-sitter command Neovim (LazyVim) uses to build syntax parsers

# ---- Quality ----
brew "shellcheck"                   # Quality | catches mistakes in shell scripts
brew "bats-core"                    # Quality | test runner for this repo's shell scripts

# ---- Apps ----
cask "iterm2"                       # Apps | iTerm2 terminal
cask "visual-studio-code"           # Apps | VS Code editor (settings via Settings Sync)
cask "jetbrains-toolbox"            # Apps | installs and updates IntelliJ and other JetBrains IDEs
cask "claude"                       # Apps | Claude desktop app

# ---- Fonts ----
cask "font-jetbrains-mono-nerd-font" # Fonts | JetBrains Mono with icons, used in iTerm, VS Code and the prompt
