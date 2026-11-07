# dotfiles

My macOS setup for coding work — shell, tools, apps, editor and terminal
configuration, and Mac settings — in one repo, so a new Mac is ready with one
command and every change is tracked. Apple Silicon Macs, with or without admin
rights.

## Quick start on a fresh Mac

```bash
xcode-select --install                     # Apple's command-line tools (git, etc.)
git clone https://github.com/<owner>/dotfiles ~/project/dotfiles
cd ~/project/dotfiles
./dotfiles all --dry-run                   # see everything it would do
./dotfiles all                             # do it (add --with-macos to apply Mac settings too)
```

While the repo is private, sign in first so `git clone` works:
`brew install gh && gh auth login` (or clone over SSH).

Then do the [manual steps](#manual-steps) and open a new terminal tab.

## Modules

Every module can run on its own, is safe to re-run, and supports `--help` and
`--dry-run` (shows what would change, changes nothing).

| Command | What it does | Admin needed? |
|---|---|---|
| `./dotfiles install` | Homebrew + [Brewfile](Brewfile), mise language tools, oh-my-zsh + plugins, Claude Code + plugins | Optional — see below |
| `./dotfiles link` | links config files into `~` (backs up what it replaces), asks for your git name/email, generates Claude Code settings, adds skills | No |
| `./dotfiles macos [group…]` | Mac settings: `dock`, `hot-corners`, `keyboard`, `trackpad`, `finder`, `system` | No |
| `./dotfiles iterm [--themes]` | iTerm2 profiles (Main, Hotkey Window, theme previews) and window restoration | No |
| `./dotfiles editors` | VS Code extensions, Neovim plugins | No |
| `./dotfiles update [part…]` | upgrades everything, or `brew` / `mise` / `omz` / `nvim` / `tldr` | No |
| `./dotfiles doctor` | checks what's set up and what's missing — changes nothing | No |
| `./dotfiles all` | `install`, `link`, `iterm`, `editors`, then `doctor`; add `--with-macos` to include `macos`, `--user`/`--admin` to pick the install mode | — |

Details, and how to undo each one:
[install](docs/install.md) ·
[link](docs/link.md) ·
[macos](docs/macos.md) ·
[iterm](docs/iterm.md) ·
[editors](docs/editors.md) ·
[update](docs/update.md) ·
[doctor](docs/doctor.md) ·
[Claude Code & Codex](docs/claude-code.md)

## Admin vs no-admin

`install` detects whether your account is an administrator (force it with
`--admin` / `--user`):

- **With admin:** Homebrew in `/opt/homebrew`, apps in `/Applications`.
- **Without admin:** Homebrew in `~/.local/homebrew`, apps in `~/Applications`.
  Some packages compile on your Mac (slower). Entries marked `(admin)` in the
  table below — Docker Desktop, Microsoft Teams, Zoom — are skipped and listed
  at the end so you can ask IT.

One failed item never stops the rest; everything skipped is listed at the end
with the reason.

## Manual steps

Things a script can't (or shouldn't) do:

1. **iTerm:** Settings → Profiles → **Main** → *Other Actions…* → **Set as
   Default**. Allow the input-monitoring prompt so double-tapping ⌥ opens the
   hotkey window. Run `./dotfiles iterm` once from Terminal.app with iTerm
   closed so it reopens your tabs after quitting. ([details](docs/iterm.md))
2. **Settings Sync:** sign in to **VS Code** Settings Sync and **JetBrains**
   Settings Sync — they bring back editor settings, keymaps and extensions.
3. **IntelliJ:** install the **IdeaVim** plugin (its config, `~/.ideavimrc`, is
   already linked).
4. **Display:** System Settings → Displays → external 4K monitor → "looks like
   1920 × 1080", 144 Hz.
5. **AWS:** `aws login` (or SSO). Default region `us-east-1`.
6. **Claude Code:** `claude` → sign in. Put private settings (like trusted
   hosts) in `~/.claude/settings.private.json`. ([details](docs/claude-code.md))

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
| `nano` | Editors | GNU nano: needed for ~/.nanorc (syntax colours); macOS's /usr/bin/nano can't use it |
| `tree-sitter-cli` | Editors | tree-sitter command Neovim (LazyVim) uses to build syntax parsers |
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
| `pipx:ansible` | Python tools | Ansible automation (ansible-core commands; Python 3.13 until it supports 3.15) |
| `pipx:poetry` | Python tools | Poetry dependency/packaging manager |
| `npm:@openai/codex` | AI | OpenAI Codex CLI |
| `npm:typescript-language-server` | Code intelligence | TypeScript LSP for Claude Code's typescript-lsp plugin |
| `npm:typescript` | Code intelligence | TypeScript compiler (tsc), used by the TypeScript LSP |
<!-- tools:end -->

## Day to day

| I want to… | Do this |
|---|---|
| add a CLI tool or app | add a line to the `Brewfile` (`brew "name"  # Category \| what it's for`), run `./dotfiles install`, then `bash lib/tools-table.sh --write` |
| add a language tool | add it to `home/.config/mise/config.toml` (same comment format), `mise install`, refresh the table |
| pin versions for one project | `mise use java@21` in the project — writes its own `mise.toml` ([example](docs/install.md#per-project-versions-and-tasks-mise)) |
| change a Mac setting | edit its `dw` line in `modules/macos.sh`, run `./dotfiles macos <group>` ([how to find a key](docs/macos.md#not-automated)) |
| track a new config file | copy it into `home/` at the same path, add the path to `links.txt`, run `./dotfiles link` |
| update everything | `./dotfiles update` (when you choose — nothing updates by itself) |
| see what's missing or drifted | `./dotfiles doctor` |
| undo a link run | `./dotfiles link --restore <run-id>` (`ls ~/.dotfiles-backup`) |

## Repo skills (Claude Code)

This repo ships two Claude Code skills in `.claude/skills/`, available when
you run Claude Code here:

- **`tool-scout`** — reviews every tool the repo installs: is it abandoned,
  deprecated, or has security news? Is there a better-established
  alternative? It checks your shell history before suggesting a removal, scans
  this Mac for tools, apps, configs and settings the repo doesn't capture yet,
  and gives a keep / replace / add / remove table with sources. Ask: *"scout my
  tools"* or *"is there anything I should add to my dotfiles?"*
- **`dependency-updater`** — keeps the versions the **repo** records current
  (mise pins, Neovim's `lazy-lock.json`, skills, Claude plugins), reads
  changelogs, asks before major upgrades, runs the tests and `doctor`, and
  reports old → new. Ask: *"update the repo's dependencies"*. (`./dotfiles
  update` is different: it upgrades this Mac.)

## Safety

This repo is meant to be public, so:

- **Never tracked:** `~/.ssh`, `~/.aws`, `~/.kube`, `~/.npmrc`, `~/.docker`,
  `~/.claude.json`, Codex `auth.json`, iTerm's full settings file, and any
  `*.local` file.
- **`~/.gitconfig` is a local file**, not a link: it `[include]`s the repo's
  settings, so `git config --global …` (or tools that edit it) can never
  write your details into the repo.
- **Private bits live in local files:** `~/.gitconfig.local` (name, email),
  `~/.zshrc.local` (machine or secret shell settings),
  `~/.claude/settings.private.json`. They're created once and never
  overwritten.
- **Secret scanning:** `./dotfiles link` turns on a pre-commit hook that runs
  [gitleaks](https://github.com/gitleaks/gitleaks) on every commit.
- **Nothing is deleted:** anything replaced goes to
  `~/.dotfiles-backup/<run-id>/`.

## Development

```bash
bats tests/                                        # all tests (sandboxed $HOME, stubbed system commands)
shellcheck dotfiles lib/*.sh modules/*.sh          # lint
gitleaks dir . --no-banner                         # secrets scan
```

Scripts target macOS's built-in `/bin/bash` 3.2. In tests, end a `[[ … ]]` or
`! cmd` check with `|| false` — bash 3.2 otherwise ignores a failure in the
middle of a test.
