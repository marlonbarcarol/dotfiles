# `./dotfiles iterm` — terminal

Installs iTerm2 profiles as **Dynamic Profiles**: small JSON files that iTerm
loads from `~/Library/Application Support/iTerm2/DynamicProfiles/` and reloads
whenever they change. They're readable and safe to publish, unlike iTerm's full
settings file (which also holds machine-specific state and AI settings).

```bash
./dotfiles iterm             # Main + Hotkey Window profiles
./dotfiles iterm --themes    # also the theme preview profiles
./dotfiles iterm --dry-run
```

## Profiles

All profiles are based on your **Default** profile and only change what's
listed.

| Profile | What it changes |
|---|---|
| **Main** | JetBrains Mono Nerd Font 16 · **right ⌥ acts as Meta** (see below) · no blue arrow marks next to prompts · mouse reporting on, so scrolling and clicking work inside Claude Code and Neovim — **hold ⌥ while dragging to select text** there |
| **Hotkey Window** | Same as Main, plus: **double-tap ⌥** from any app slides a full-width terminal down from the top; double-tap again (or click away) to hide it |
| **Theme: …** (`--themes`) | Catppuccin Mocha, Dracula, Tokyo Night, Gruvbox Dark, Darcula colour schemes to preview |

## One-time manual steps

1. **Make Main your default** — iTerm → Settings → Profiles → select **Main** →
   *Other Actions…* → **Set as Default**. New tabs then use it.
2. **Allow the hotkey** — the first time, macOS asks to let iTerm monitor input
   ("Device control and data access" / Input Monitoring). iTerm needs it to
   notice a double-tap of ⌥ while another app is in front. Allow it, then quit
   and reopen iTerm. If you'd rather not grant it, change the Hotkey Window
   profile to a normal shortcut such as ⌥Space (no permission needed).
3. **Reopen windows after quitting** — `./dotfiles iterm` sets this, but only
   while iTerm isn't running (iTerm overwrites its settings when it quits). Run
   it once from **Terminal.app** with iTerm closed.

## Keys worth knowing

**Right ⌥ as Meta.** By default ⌥ types special characters (⌥F → `ƒ`). In
**Main** the **right** ⌥ sends Meta instead, which shells and Neovim expect;
the left ⌥ still types `ƒ`, `©`, etc.

| Keys | Does |
|---|---|
| right⌥ B / right⌥ F | jump back / forward one word |
| right⌥ ⌫ | delete the previous word |
| right⌥ . | insert the last argument of the previous command (`mkdir foo/bar` → `cd ` + right⌥ . → `cd foo/bar`) |

**Jumping through output** (shell integration marks):

| Keys | Does |
|---|---|
| ⌘⇧↑ / ⌘⇧↓ | jump to the previous / next command in the scrollback |
| ⌘⇧A | select everything the last command printed (then ⌘C to copy) |

**Tabs:**

| Keys | Does |
|---|---|
| ⌃Tab / ⌃⇧Tab | next / previous tab (same as Chrome) |
| ⌘⇧] / ⌘⇧[ | next / previous tab |
| ⌘1 … ⌘9 | go to tab 1–9 |
| ⌘T / ⌘W | new tab / close tab |
| ⌘Z | reopen a tab you closed a few seconds ago |

## Choosing a theme

1. `./dotfiles iterm --themes`
2. iTerm menu bar → **Profiles** → open a tab with each **Theme: …** profile.
3. To keep one: copy that theme's colour keys (`"Ansi 0 Color"` … `"Selection
   Color"`, `"Background Color"`, `"Foreground Color"`, …) from
   `iterm/DynamicProfiles/themes.json` into the **Main** profile in
   `iterm/DynamicProfiles/dotfiles.json`, then run `./dotfiles iterm`.
   More schemes: <https://iterm2colorschemes.com>.

## Hotkey settings reference

In a profile, `"HotKey Modifier Activation"` picks the key you double-tap:

| Value | Key |
|---|---|
| 0 | ⌃ Control |
| 1 | ⇧ Shift |
| 2 | ⌥ Option |
| 3 | ⌘ Command |

(Source: `ITAddressBookMgr.h` in the iTerm2 source.)

## Window restoration setting

`./dotfiles iterm` writes, for iTerm only:

```bash
defaults write com.googlecode.iterm2 NSQuitAlwaysKeepsWindows -bool true
defaults write com.googlecode.iterm2 OpenNoWindowsAtStartup -bool false
defaults write com.googlecode.iterm2 AlternateMouseScroll -bool false
```

`AlternateMouseScroll` off (Settings → Advanced → Mouse, *Scroll wheel sends
arrow keys when in alternate screen mode* = No) lets the wheel scroll Claude
Code's conversation instead of paging through your prompt history.

With iTerm's default startup policy, whether windows come back follows
`NSQuitAlwaysKeepsWindows` (macOS's "Close windows when quitting an
application", set here for iTerm only). In the GUI: iTerm → Settings →
General → Startup → *Window restoration policy*.
