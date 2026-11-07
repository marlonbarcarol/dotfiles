# `./dotfiles link`: config files

Links the config files in this repo's `home/` folder into your home folder, so
editing either one edits both, and `git diff` shows every change you make.

```bash
./dotfiles link --dry-run   # show what would be linked or backed up
./dotfiles link             # do it
```

Safe to run any number of times. No admin rights needed.

## What gets linked

The list lives in [`links.txt`](../links.txt), one path per line, relative to
both `home/` and `~`.

| Path in `~` | What it controls |
|---|---|
| `.zshrc` | Shell: Homebrew path, oh-my-zsh + plugins, mise, aliases, Starship prompt |
| `.ideavimrc` | Vim keys inside IntelliJ (needs the IdeaVim plugin) |
| `.nanorc` | nano: syntax colours |
| `.gitmessage` | Commit message template: `git commit` (without `-m`) opens with the format |
| `.config/starship.toml` | The prompt: path, git status, ❯ on the left, duration, versions, clock on the right |
| `.config/git/ignore` | Files git ignores in every repo |
| `.config/mise/config.toml` | Global language versions and tools (Node, Java, Gradle, Codex, …) |
| `.config/nvim` | Neovim / LazyVim configuration (whole folder) |
| `.claude/statusline-command.sh` | Claude Code's status line |
| `.claude/CLAUDE.md` | Claude Code's global instructions |

### Git settings: included, not linked

`~/.gitconfig` is a small **local** file that `[include]`s
`home/.gitconfig` from the repo (pull with rebase, delta diffs, …). It isn't
a link because `git config --global …` (and tools such as `gh auth
setup-git`) write to `~/.gitconfig`. As a link, that would put your details
into the public repo. Your name and email live in `~/.gitconfig.local`.
(`git config --global <key>` only shows included values with `--includes`,
git itself always uses them.)

`~/.claude/settings.json` is generated, not linked. See
[claude-code.md](claude-code.md).

## When something is already there

| What's at the path | What happens |
|---|---|
| Already a link into this repo | Left alone (`ok`) |
| A real file, a folder, or a link elsewhere | Moved to `~/.dotfiles-backup/<run-id>/<same path>`, then linked (`backed-up+linked`) |
| Nothing | Linked (`linked`) |

Nothing is ever deleted. `<run-id>` is the date and time of the run, e.g.
`20261106-183000`.

### Undo

```bash
ls ~/.dotfiles-backup                       # find the run-id
./dotfiles link --restore 20261106-183000   # put that set back
```

Restoring removes the links that replaced those files and moves the originals
back.

## Local files (never tracked)

Created once if missing, never overwritten:

| File | For |
|---|---|
| `~/.zshrc.local` | Machine-specific or private shell settings (work proxies, tokens, …). Sourced last by `.zshrc`. |
| `~/.gitconfig.local` | Your git name and email (and e.g. signing key or a work email via `includeIf`). |

The first run asks for your git name and email, suggesting the ones from an
existing `~/.gitconfig`. Press Enter to accept a suggestion. Without a
terminal (e.g. piped), it skips this and says so. You can also pass them in:

```bash
DOTFILES_GIT_NAME="Your Name" DOTFILES_GIT_EMAIL="you@example.com" ./dotfiles link
```

## Secret scanning

`link` also sets this repo's `core.hooksPath` to `.githooks`, which turns on a
pre-commit hook that runs `gitleaks` on staged changes and blocks the commit if
it finds a secret.

## Adding a new file

1. Copy the file into `home/` at the same relative path (e.g. `home/.config/foo/config.toml`).
2. Add that path to `links.txt`.
3. Run `./dotfiles link`. Your original is backed up and replaced by the link.
