# dotfiles

My macOS setup for coding work — shell, tools, apps, editor and terminal
configuration, and Mac settings — in one repo, so a new Mac is ready with one
command and every change is tracked.

## What gets installed

Generated from the comments in the [`Brewfile`](Brewfile) and
[`home/.config/mise/config.toml`](home/.config/mise/config.toml) — refresh with
`bash lib/tools-table.sh --write`. "(admin)" means it's skipped on Macs without
admin rights.

<!-- tools:start -->
| Tool | Category | What it's for |
|---|---|---|
| `starship` | Shell | fast, minimal prompt (replaces powerlevel10k) |
| `eza` | Shell | modern `ls` with colours and git status (alias `l`) |
| `fzf` | Shell | fuzzy finder: Ctrl-R searches your command history |
| `zoxide` | Shell | `z <part-of-folder>` jumps to folders you've visited |
| `tlrc` | Shell | `tldr <command>`: short, practical examples for any command |
| `tmux` | Shell | terminal multiplexer: split panes, sessions that survive closing |
| `tree` | Shell | show a folder as a tree |
| `ripgrep` | Search | `rg`: very fast search through code (newer grep) |
| `fd` | Search | fast, friendly file finder (newer find) |
| `bat` | Search | `cat` with syntax highlighting and line numbers |
| `yq` | Search | read and edit YAML from the terminal (jq ships with macOS) |
| `gh` | Git | GitHub CLI: PRs, issues, auth from the terminal |
| `git-delta` | Git | readable `git diff` with in-line highlights (wired into .gitconfig) |
| `lazygit` | Git | full-screen terminal UI for git: stage, commit, rebase with keys |
| `gitleaks` | Git | finds secrets before they're committed (pre-commit hook) |
| `mise` | Languages | one manager for Node, Java, Gradle, Scala, Python tools (replaces nvm + SDKMAN) |
| `uv` | Languages | fast Python package and tool installer (used by mise) |
| `maven` | Languages | Maven build tool for Java |
| `jdtls` | Code intelligence | Java language server for Claude Code's jdtls-lsp plugin |
| `lazydocker` | Containers | terminal UI for Docker: containers, logs, restarts |
| `dive` | Containers | explore Docker image layers and wasted space |
| `awscli` | Cloud | AWS command line (sign in with `aws login` / SSO) |
| `curl` | Networking | curl with an up-to-date CA bundle (eMudhra fix) |
| `xh` | Networking | quick HTTP requests from the terminal (like REST Client) |
| `btop` | System | better Activity Monitor in the terminal |
| `neovim` | Editors | Neovim with LazyVim (`vim` is aliased to it) |
| `nano` | Editors | simple terminal editor, newer than macOS's |
| `shellcheck` | Quality | catches mistakes in shell scripts |
| `bats-core` | Quality | test runner for this repo's shell scripts |
| `iterm2` | Apps | iTerm2 terminal |
| `visual-studio-code` | Apps | VS Code editor (settings via Settings Sync) |
| `jetbrains-toolbox` | Apps | installs and updates IntelliJ and other JetBrains IDEs |
| `docker-desktop` | Apps (admin) | Docker Desktop: containers and Compose |
| `google-chrome` | Apps | Chrome browser |
| `1password` | Apps | password manager |
| `obsidian` | Apps | notes |
| `claude` | Apps | Claude desktop app |
| `microsoft-teams` | Apps (admin) | Microsoft Teams |
| `zoom` | Apps (admin) | Zoom meetings |
| `font-jetbrains-mono-nerd-font` | Fonts | JetBrains Mono with icons, used in iTerm, VS Code and the prompt |
| `node` | Languages | Node.js runtime (replaces nvm) |
| `java` | Languages | Java JDK, BellSoft Liberica (replaces SDKMAN) |
| `gradle` | Languages | Gradle build tool for Java/Kotlin |
| `scala` | Languages | Scala compiler and REPL |
| `pipx:ansible` | Python tools | Ansible automation (was pip --user) |
| `pipx:poetry` | Python tools | Poetry dependency/packaging manager |
| `npm:@openai/codex` | AI | OpenAI Codex CLI |
| `npm:typescript-language-server` | Code intelligence | TypeScript LSP for Claude Code's typescript-lsp plugin |
| `npm:typescript` | Code intelligence | TypeScript compiler (tsc), used by the TypeScript LSP |
<!-- tools:end -->
