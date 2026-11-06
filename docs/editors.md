# `./dotfiles editors` — Neovim, VS Code, IntelliJ

```bash
./dotfiles editors --dry-run
./dotfiles editors
```

- Installs any VS Code extension listed in `vscode/extensions.txt` that you
  don't have yet.
- Installs Neovim plugins at the versions pinned in
  `home/.config/nvim/lazy-lock.json`.
- **Never writes VS Code or IntelliJ settings** — each editor's own Settings
  Sync owns those (see below).

Font everywhere: **JetBrains Mono Nerd Font**, size 15 in editors (16 in
iTerm), ligatures off.

## Neovim (LazyVim)

`vim` is an alias for `nvim`; plain Vim is still at `/usr/bin/vim`. The config
is [LazyVim](https://www.lazyvim.org) — an IDE-like setup out of the box — in
`home/.config/nvim` (linked to `~/.config/nvim`), with the Darcula colour
scheme to match IntelliJ.

First steps:

| Keys / command | Does |
|---|---|
| `<space>` | the leader key — press it and wait: a menu shows what comes next |
| `<space><space>` | find a file |
| `<space>/` | search text in the project |
| `<space>e` | file tree |
| `:Lazy` | plugin manager (update, see what's installed) |
| `:LazyExtras` | turn on language packs — e.g. `lang.java`, `lang.typescript`, `lang.docker`, `lang.json`, `lang.yaml` |
| `:Mason` | language servers/formatters installed for those packs |

Your own plugins go in `home/.config/nvim/lua/plugins/` (one file per plugin;
see `colorscheme.lua`).

## IntelliJ

- Turn on **JetBrains Settings Sync** (Settings → *Backup and Sync*) — it
  carries settings, plugins, and keymaps between machines.
- Install the **IdeaVim** plugin to practise vim keys where you spend most of
  the day; its config is `~/.ideavimrc` (from `home/.ideavimrc`).
- `jetbrains/keymaps/macOS copy.xml` is a reference copy of your custom keymap
  (10 changes on top of "Mac OS X 10.5+"). To restore it by hand: copy it into
  `~/Library/Application Support/JetBrains/<IDE version>/keymaps/` and pick it
  in Settings → Keymap.

## VS Code

- **Settings Sync** (signed in) owns settings, keybindings, extensions and the
  CoderPad profile. Sign in on a new Mac and everything comes back.
- `vscode/settings.json`, `vscode/keybindings.json` and
  `vscode/extensions.txt` are **reference copies** — readable history of your
  setup, not applied. Home paths in them were replaced with `~`.
- After moving to mise, Java runtimes live under
  `~/.local/share/mise/installs/java/…`; update `java.configuration.runtimes`
  in VS Code if you use that setting.
- Refresh the copies:

  ```bash
  U="$HOME/Library/Application Support/Code/User"
  cp "$U/settings.json" "$U/keybindings.json" vscode/
  sed -i '' "s|$HOME|~|g" vscode/settings.json
  code --list-extensions > vscode/extensions.txt
  ```
