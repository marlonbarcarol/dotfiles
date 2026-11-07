---
name: tool-scout
description: Use when asked to review, audit or modernise the tools in this dotfiles repo, find better alternatives, check whether a tool is abandoned or deprecated, or find things on this Mac that the dotfiles don't capture yet.
---

# Tool scout

## Overview

Two jobs, one report: (1) is each tool the repo installs still the right
choice, and (2) what on this Mac is missing from the repo. Read-only until the
owner picks what to apply.

## Inputs

| Source | Holds |
|---|---|
| `Brewfile` | CLI tools, apps, fonts |
| `home/.config/mise/config.toml` | runtimes and language tools |
| `home/.zshrc` | oh-my-zsh plugins, aliases |
| `home/.config/starship.toml`, `home/.config/nvim/`, `iterm/DynamicProfiles/` | prompt, editor, terminal |
| `home/.claude/settings.json`, `claude/skills.txt` | Claude plugins, marketplaces, skills |
| `vscode/extensions.txt`, `modules/macos.sh` | VS Code extensions, macOS settings |

## Part 1: Is each tool still right?

For every tool, check with web search (cite each source):
- **Maintenance:** last release, archived/"life support" notices (e.g. powerlevel10k), deprecation in favour of a fork (e.g. exa → eza).
- **Security / supply chain:** advisories, compromised taps or packages, Homebrew policy changes (e.g. tap trust in Homebrew 6).
- **Better-established alternative:** only if it's clearly mainstream now (e.g. Starship, mise, tlrc), not merely new.

Before recommending a **removal or replacement**, check usage:

```bash
export LC_ALL=C   # for the whole pipeline, sort included
# counts for specific commands (and their aliases):
awk -F';' '{print $2}' ~/.zsh_history | awk '{print $1}' | sort | uniq -c | grep -wE 'git|gst|vim|nvim'
# which alias maps to which command:
zsh -i -c 'alias' | grep -E "='?git "     # e.g. gst='git status'
```

`LC_ALL=C` is required for every command in the pipe: the history file has non-UTF-8 bytes, so `awk` silently misses lines and `sort` fails with "Illegal byte sequence". Count the tool **and its aliases** (`gst` is oh-my-zsh's git plugin). Counts only see the first word of each line (not `cd x && tool`, pipes or `sudo tool`), so a low count is a lower bound: say "rarely used", and also check scripts and configs (`grep -rn <tool> ~/project`) before calling it unused.

## Part 2: What on this Mac isn't in the repo?

| Look at | Command | Compare with |
|---|---|---|
| Homebrew installs | `brew leaves --installed-on-request`, `brew list --cask` | `Brewfile` |
| Hand-installed apps | `ls /Applications`, then `brew search --cask <name>` | `Brewfile` casks |
| App Store apps | `mas list` | usually personal: ignore unless a work tool |
| Global tools | `mise ls`, `npm -g ls --depth 0`, `ls ~/.local/bin` | mise config |
| Config files | `ls -A ~ ~/.config` | `links.txt` |
| Claude | `jq .enabledPlugins ~/.claude/settings.json`, `ls ~/.claude/skills` | `home/.claude/settings.json`, `claude/skills.txt` |
| VS Code | `code --list-extensions` | `vscode/extensions.txt` |
| macOS | `defaults read <domain> <key>` for keys you suspect | `modules/macos.sh` |

`./dotfiles doctor` already lists Homebrew extras: start there.

Classify every finding: **add** (work/coding tool), **ignore (personal)** (media, games, music: the repo is coding-focused), or **ignore (stale)** (unused per history, old runtime versions). Never read secrets (`~/.ssh`, `~/.aws`, `~/.npmrc`, `.env`, `auth.json`).

## Report

One table, most important first:

| Tool | Verdict (keep / replace / add / remove / ignore) | Why (evidence) | Effort | Source |
|---|---|---|---|---|

Then: "Not verified" (anything you couldn't check). Then ask which rows to apply.

## Applying (after the owner chooses)

- Add a tool: Brewfile/mise line with the `# Category | what it's for` comment, then `bash lib/tools-table.sh --write`.
- Replace: update configs and docs that mention the old tool (`grep -rn <old>`).
- Then `bats tests/` and `./dotfiles doctor`. Never uninstall from the Mac yourself. Tell the owner the command.

## Common mistakes

- Calling a tool unused without the history check.
- Recommending something new and shiny over an established tool.
- Suggesting personal apps for a work repo.
- Answers without sources.
