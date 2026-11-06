# `./dotfiles update` — keeping things current

Upgrades what's installed on this Mac. It only runs when you run it — there
are no background upgrades — so a Java or Node project never breaks in the
middle of your work. Once a week is a good rhythm.

```bash
./dotfiles update --dry-run     # show the commands
./dotfiles update               # everything
./dotfiles update brew mise     # just these parts
```

| Part | Runs | Updates |
|---|---|---|
| `brew` | `brew update`, `brew upgrade`, `brew cleanup` | command-line tools, apps, fonts (and mise itself) |
| `mise` | `mise upgrade` | Node, Java, Gradle, Scala, Ansible, Poetry, Codex, TypeScript LSP — within the versions pinned in `~/.config/mise/config.toml` (e.g. `node = "24"` stays on 24.x) |
| `omz` | oh-my-zsh's own updater | oh-my-zsh |
| `nvim` | `nvim --headless "+Lazy! sync" +qa` | Neovim plugins; rewrites `lazy-lock.json` in the repo — commit it if all's well |
| `tldr` | `tldr --update` | the tldr pages cache |

If one part fails, the others still run, and the failure is listed at the end.

Claude Code updates itself, and VS Code / IntelliJ update through their own
updaters (JetBrains Toolbox for IntelliJ).

## Updating one tool

```bash
brew upgrade gh                 # one Homebrew package
brew upgrade --cask iterm2      # one app
mise upgrade node               # one mise tool (within its pinned version)
mise use --global node@26       # move the global default to a new major version
mise use node@22                # pin a version for the current project (writes mise.toml)
mise outdated                   # what has newer versions
brew outdated                   # same for Homebrew
```

## Machine vs repo

`./dotfiles update` upgrades **this Mac**. Keeping the **repo's** pinned
versions current (the Brewfile, mise pins, `lazy-lock.json`, skills) is the
job of the `dependency-updater` skill — see the README.
