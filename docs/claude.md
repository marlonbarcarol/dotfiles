# Claude Code and Codex

Claude Code's setup is handled inside other modules, not by a module of its
own:

| Module | Does |
|---|---|
| `./dotfiles install` | installs Claude Code (official native installer, only if `claude` is missing — no admin rights, updates itself), adds the plugin marketplaces, installs every enabled plugin that's missing |
| `./dotfiles link` | links `~/.claude/CLAUDE.md` and `~/.claude/statusline-command.sh`, **generates** `~/.claude/settings.json`, adds missing skills |
| `./dotfiles doctor` | warns when the live settings drift from the repo |

## What's tracked, and what never is

| Tracked in the repo | Never tracked |
|---|---|
| `home/.claude/settings.json` — permissions mode, hooks, status line, plugins, marketplaces | `~/.claude.json` (account, sign-in, project history) |
| `home/.claude/statusline-command.sh` — your status line script | `~/.claude/settings.private.json` (see below) |
| `home/.claude/CLAUDE.md` — global instructions (two lines) | `history.jsonl`, `projects/`, `sessions/`, caches, `plugins/` state |
| `claude/skills.txt` — skills to install | `~/.agents/` (the Skills CLI's install folder and lock file) |
| `codex/config.toml` — Codex preferences (reference copy) | `~/.codex/auth.json`, `~/.codex/rules/`, Codex sessions/sqlite |

### The generated settings file

Claude Code reads only `~/.claude/settings.json`, but part of yours is private
— the auto-mode note naming your home server (user and IP address). So:

- `home/.claude/settings.json` (public) has everything else.
- `~/.claude/settings.private.json` (untracked, on your Mac only) has the
  private part.
- `./dotfiles link` deep-merges the two into `~/.claude/settings.json`
  (backing up whatever was there).

When you change settings inside Claude Code (`/config`, `/plugin`), the live
file changes and `./dotfiles doctor` warns `claude settings`. Copy the change
into `home/.claude/settings.json` (or into the private file if it's private),
then run `./dotfiles link`.

## Hooks

| Hook | When | What you notice |
|---|---|---|
| Notification → `afplay … Hero.aiff` (5% volume) | Claude is **waiting for you**: needs a permission, idle, or asking a question | a soft "Hero" chime |
| Stop → `afplay … Blow.aiff` (5% volume) | Claude **finished** its reply | a soft "Blow" sound |
| every event → `$HOME/.config/iterm2/cc-status` | all the time | silent: updates the Claude status shown on the iTerm tab (working / waiting). The script is iTerm's own (installed by its Claude Code integration). |

## Plugins

Enabled (from `home/.claude/settings.json`): claude-code-setup,
claude-md-management, code-review, code-simplifier, coderabbit, codex,
commit-commands, github, hookify, image-view, jdtls-lsp, mattpocock-skills,
playwright, remember, savvy-progress, security-guidance, superpowers,
typescript-lsp. (context7 is intentionally not included.)

Marketplaces: Anthropic's official ones, `openai/codex-plugin-cc`, and two
**community-run** ones — `jarrodwatts/claude-image-view` (image-view) and
`johnnyvizz/claude-kit` (savvy-progress). Community plugins run code on your
Mac with your permissions; review updates to them.

The two LSP plugins need their language servers on your PATH: `jdtls` (Brewfile)
and `typescript-language-server` + `typescript` (mise).

## Skills

Third-party skills are installed globally with the Skills CLI, which puts them
in `~/.agents/skills/` and links them into `~/.claude/skills/`:

| Skill | From | What for |
|---|---|---|
| `security-audit` | cloudflare/security-audit-skill | full, multi-agent security audits of a codebase |
| `find-skills` | vercel-labs/skills | finding more skills |

Add one:

```bash
npx skills add https://github.com/<owner>/<repo> --skill <name> --global
echo "<name> https://github.com/<owner>/<repo>" >> claude/skills.txt
```

`./dotfiles link` re-adds any listed skill that's missing on a new Mac.

### `/security-review` or the security-audit skill?

- **`/security-review`** (built in) — reviews your current changes. Quick and
  cheap: use it before a PR.
- **security-audit skill** — a full audit in phases (reconnaissance, many
  hunting agents, independent verifiers, a report). Slow and uses a lot of
  tokens. Use it deliberately — "security audit this codebase" — for a real
  audit; otherwise it only gives guidance.

## Codex

Codex itself comes from mise (`npm:@openai/codex`). Its settings file is
owned by the Codex app, which keeps rewriting it with machine-specific entries,
so `codex/config.toml` here is a **reference copy** of your preferences (model
reasoning effort, approval policy, sandbox mode, status line, the mattpocock
skills marketplace). Copy what you want into `~/.codex/config.toml` on a new
Mac.
