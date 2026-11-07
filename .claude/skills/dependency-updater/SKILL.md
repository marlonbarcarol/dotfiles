---
name: dependency-updater
description: Use when asked to update, bump or refresh the dependencies, pins or versions recorded in this dotfiles repo, or to check whether they are outdated.
---

# Dependency updater

## Overview

Keeps what the **repo records** current. This is not `./dotfiles update`
(which upgrades the Mac). Change pin files, verify, report, and ask before risky
bumps.

## What is pinned where

| Dependency | Pinned in | Find outdated | Bump |
|---|---|---|---|
| mise runtimes/tools | `home/.config/mise/config.toml` | `MISE_GLOBAL_CONFIG_FILE=home/.config/mise/config.toml mise outdated --bump` | edit the version in the file |
| Neovim plugins | `home/.config/nvim/lazy-lock.json` | `nvim --headless "+Lazy! check" +qa` | `nvim --headless "+Lazy! update" +qa` (rewrites the lock) |
| Claude skills | `claude/skills.txt` (+ `~/.agents/.skill-lock.json`) | no check command: `npx skills list`, then compare with the source repo's latest commit | `npx skills update`, then `git diff`-style review of `~/.agents/skills/<name>` |
| Claude plugins | `home/.claude/settings.json` (`enabledPlugins`) | `claude plugin list` | `claude plugin update <name>` |
| oh-my-zsh + `zsh-autosuggestions`, `zsh-syntax-highlighting` | not pinned (git clones in `~/.oh-my-zsh/custom/plugins/`) | `git -C <dir> fetch && git -C <dir> rev-list --count HEAD..@{u}` (fetch only touches the clone's remote refs) | `./dotfiles update omz` |
| Homebrew | `Brewfile` has **no versions** | `brew outdated` | nothing to bump in the repo: machine upgrade only |

Entries set to `"latest"` in mise float: there's nothing to bump, but a new
**major** version arrives silently. Baseline = the installed version
(`mise ls`). Compare it with `mise outdated --bump` and report any major jump.
A tool shown as missing isn't installed. Say so, and don't install it to compare.
`nvim "+Lazy! update"` is a change, not a check: run it only in step 2.

## Process

1. Run the verification commands (step 5) **before** changing anything, and
   note any failures as pre-existing. Then check everything above (read-only)
   and build the table.
2. **Patch/minor** bumps: apply. **Major** bumps (Node, Java, Gradle, Scala,
   anything `latest` that jumped a major), new/changed community plugins or
   skills: list them with changelog links and ask first.
3. For each applied bump: read release notes (`gh release view -R <repo>`, the
   project's CHANGELOG). Community plugins/skills are code that runs with your
   permissions, so diff before accepting.
4. If tool names or descriptions changed: `bash lib/tools-table.sh --write`.
5. Verify, in order:
   ```bash
   bats tests/
   shellcheck dotfiles lib/*.sh modules/*.sh
   ./dotfiles doctor
   zsh -i -c 'node -v; java -version 2>&1 | head -1; codex --version'
   git diff --stat        # only pin files should have changed
   ```

Rollback: `git checkout -- <pin file>` undoes a bump in the repo. For a
runtime, `mise use --global <tool>@<old version>`. For plugins,
`git checkout -- home/.config/nvim/lazy-lock.json` then
`nvim --headless "+Lazy! restore" +qa`.

## Report

| Dependency | Old | New | Kind (patch/minor/major) | Applied or waiting | Notes / changelog |
|---|---|---|---|---|---|

Then failures and anything skipped. Don't commit unless asked.

## Common mistakes

- Running `brew upgrade` and calling the repo "updated": the Brewfile has no versions.
- Forgetting `lazy-lock.json` must be committed after a Lazy update.
- Bumping several majors at once, so a failure has no single cause.
