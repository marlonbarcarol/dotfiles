# `./dotfiles doctor`: health check

Checks how this Mac compares with the repo. It **never changes anything**, so
run it whenever you like.

```bash
./dotfiles doctor
```

Each line is `ok`, `warn` (worth a look) or `fail` (something the repo expects
is missing). The exit code is 1 if anything failed, so `./dotfiles all` ends
by telling you whether the setup is complete.

| Check | `fail` / `warn` means | Fix |
|---|---|---|
| `mode` | fail: no Homebrew where this mode expects it (`/opt/homebrew` with admin, `~/.local/homebrew` without) | `./dotfiles install` |
| `link <path>` | fail: that file isn't linked to this repo (missing, or your own copy is in the way) | `./dotfiles link` (backs up your copy) |
| `brew bundle` | fail: something in the Brewfile isn't installed | `./dotfiles install` |
| `brew extras` | warn: things you installed yourself that aren't in the Brewfile (dependencies are ignored) | add them to the Brewfile, or `brew uninstall <name>` |
| `mise` | fail: a tool in `~/.config/mise/config.toml` isn't installed | `mise install` |
| `PATH curl` | warn: Homebrew's curl isn't ahead of `/usr/bin/curl` (the eMudhra CA fix isn't active) | open a new terminal tab |
| `PATH java` | warn: `java` isn't coming from mise | open a new tab, or run `mise install` |
| `README tools table` | fail: the Brewfile or mise config changed without refreshing the README | `bash lib/tools-table.sh --write` |
| `secret scanning` | warn: the gitleaks pre-commit hook is off for this repo | `./dotfiles link` |
| `git identity` | warn: no email in `~/.gitconfig.local` | `./dotfiles link` (asks for it) |
| `claude settings` | warn: `~/.claude/settings.json` differs from repo + private settings (you changed something via `/config` or `/plugin`) | copy the change into `home/.claude/settings.json`, then `./dotfiles link` |

PATH checks look at the shell you ran doctor from, so run it from a normal
terminal tab.
