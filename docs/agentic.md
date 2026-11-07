# `./dotfiles agentic`: your own plugins in Claude Code and Codex

```bash
./dotfiles agentic --dry-run
./dotfiles agentic
```

Installs this repo's plugin marketplace, `marlonbarcarol`, and its plugin,
`marlon-agentic` (your general skills, such as
`marlon-agentic:state-machine-audit`, plus the sound hooks), in both Claude
Code and Codex. What's in the plugin:
[Your own plugin](claude-code.md#your-own-plugin-marlon-agentic).

| | Not installed yet | Already installed |
|---|---|---|
| Claude Code | `claude plugin marketplace add marlonbarcarol/dotfiles`, then `claude plugin install marlon-agentic@marlonbarcarol` | `claude plugin marketplace update marlonbarcarol`, then `claude plugin update marlon-agentic@marlonbarcarol` |
| Codex | `codex plugin marketplace add marlonbarcarol/dotfiles`, then `codex plugin add marlon-agentic@marlonbarcarol` | `codex plugin marketplace upgrade marlonbarcarol`, then `codex plugin add …` again (it installs the current version) |

So running it again is how you pick up a new version. Restart Claude Code
or Codex afterwards so they load it.

- **It installs from GitHub**, so you get what's on `main`, not your local
  edits. To try a change before pushing it, run
  `claude --plugin-dir plugins/marlon-agentic`.
- **A missing tool is skipped**, not an error: without Codex it still does the
  Claude Code part, and the end of the run lists what was skipped.
- `./dotfiles all` runs it after `editors`. `./dotfiles install` leaves this
  marketplace alone and installs only the others in `home/.claude/settings.json`.
- `./dotfiles doctor` warns when the plugin isn't installed in Claude Code.

No admin rights needed.

## Undo

```bash
claude plugin uninstall marlon-agentic@marlonbarcarol
claude plugin marketplace remove marlonbarcarol
codex plugin remove marlon-agentic@marlonbarcarol
codex plugin marketplace remove marlonbarcarol
```

Claude Code will offer it again while `home/.claude/settings.json` lists it
under `enabledPlugins` and `extraKnownMarketplaces`. Remove it there too, then
run `./dotfiles link`.
