# `./dotfiles install` — tools and apps

Installs, in this order:

1. **Homebrew** if it's missing.
2. Everything in the [`Brewfile`](../Brewfile): command-line tools, apps, fonts.
   Apps you installed by hand (dragged into `/Applications`) are **adopted** by
   Homebrew instead of reinstalled, so `brew upgrade` can update them later.
3. **oh-my-zsh** (if missing) plus its two community plugins,
   `zsh-autosuggestions` and `zsh-syntax-highlighting`.
4. The language tools in [`home/.config/mise/config.toml`](../home/.config/mise/config.toml)
   via `mise install`: Node, Java, Gradle, Scala, Ansible, Poetry, Codex,
   TypeScript language server.

```bash
./dotfiles install --dry-run   # list what it would install/adopt
./dotfiles install
```

Safe to re-run: anything already installed is left as it is. If one item
fails, the rest still run and the failures are listed at the end under
**Skipped**.

## With or without admin rights

`install` checks whether your account is an administrator and picks a mode.
Force one with `--admin` or `--user`.

| | Admin mode | No-admin mode (`--user`) |
|---|---|---|
| Homebrew location | `/opt/homebrew` (standard) | `~/.local/homebrew` |
| Homebrew install | official installer, asks for your password once | `git clone`, no password |
| Packages | prebuilt ("bottles"), fast | some get compiled on your Mac — slower, and occasionally fails |
| Apps (casks) | `/Applications` | `~/Applications` |
| `[needs-admin]` entries | installed | skipped and listed — **ask IT** for these |

Entries marked `[needs-admin]` today: Docker Desktop (installs a system
helper), Microsoft Teams and Zoom (both use `.pkg` installers).

`~/.zshrc` finds Homebrew in either location, so nothing else changes.

## Adding or removing a tool

Every Brewfile line has the same shape:

```ruby
brew "ripgrep"          # Search | fast search through code (newer grep)
cask "docker-desktop"   # Apps [needs-admin] | Docker Desktop: containers and Compose
```

- `brew` = command-line tool, `cask` = app or font.
- The comment is required: `Category | what it's for`. The README's
  **What gets installed** table is generated from it.
- Add `[needs-admin]` after the category if the app needs admin rights.

Then:

```bash
./dotfiles install                  # installs the new entry
bash lib/tools-table.sh --write     # refreshes the README table
```

Removing a line doesn't uninstall anything. `./dotfiles doctor` lists
installed packages that aren't in the Brewfile; remove them with
`brew uninstall <name>`.

Language tools go in `home/.config/mise/config.toml` instead, with the same
comment format:

```toml
node = "24"   # Languages | Node.js runtime
```

Java is BellSoft **Liberica 25** (`liberica-25`), the same vendor you used with
SDKMAN.

Projects that pin versions the old way keep working: mise reads `.nvmrc`,
`.node-version`, `.java-version` and `.sdkmanrc` files
(`idiomatic_version_file_enable_tools` in the mise config). Older Java
versions you had in SDKMAN (11, 20, 21) install on demand: `mise install
java@liberica-21`, or just `cd` into the project.

## Per-project versions and tasks (mise)

A `mise.toml` in a project pins that project's versions — they switch
automatically when you `cd` in — and can define tasks, like a Makefile:

```toml
[tools]
java = "21"
node = "24"

[tasks.dev]
run = "docker compose up -d && ./gradlew bootRun"
```

```bash
mise run dev      # run the task
mise use java@21  # pin a version in the current project (writes mise.toml)
```

## AWS

The AWS CLI comes from Homebrew (`awscli`), so it also works without admin
rights. Sign in with `aws login` or SSO — never store access keys. Your default
region is `us-east-1` (`aws configure set region us-east-1`).
Nothing from `~/.aws` is in this repo: it holds your login sessions.
