# `./dotfiles macos`: Mac settings

Applies your macOS preferences with `defaults write`. Each group can run on
its own. Nothing here needs admin rights.

```bash
./dotfiles macos --dry-run          # list every setting it would write
./dotfiles macos                    # all groups
./dotfiles macos dock hot-corners   # only these groups
```

Groups: `dock`, `hot-corners`, `keyboard`, `trackpad`, `finder`, `system`.
The Dock, Finder and menu bar restart once at the end so changes show up.
Keyboard repeat settings take effect after you log out and back in. If a
setting can't be written (some need your terminal to have Accessibility or
Full Disk Access permission), it's skipped and listed at the end.

## Every setting

| Group | Where in System Settings | Value | Undo |
|---|---|---|---|
| dock | Desktop & Dock → Automatically hide and show the Dock | `true` | `defaults delete com.apple.dock autohide` |
| dock | Desktop & Dock → Size | `47` | `defaults delete com.apple.dock tilesize` |
| dock | Desktop & Dock → Show suggested and recent apps in Dock (off) | `false` | `defaults delete com.apple.dock show-recents` |
| dock | Desktop & Dock → Automatically rearrange Spaces (off) | `false` | `defaults delete com.apple.dock mru-spaces` |
| hot-corners | Desktop & Dock → Hot Corners → top right: Put Display to Sleep | `10` | `defaults delete com.apple.dock wvous-tr-corner` |
| hot-corners | Desktop & Dock → Hot Corners → top right: no modifier key | `0` | `defaults delete com.apple.dock wvous-tr-modifier` |
| hot-corners | Desktop & Dock → Hot Corners → bottom right: none (no Quick Note) | `1` | `defaults delete com.apple.dock wvous-br-corner` |
| hot-corners | Desktop & Dock → Hot Corners → bottom right: ⌘ | `1048576` | `defaults delete com.apple.dock wvous-br-modifier` |
| keyboard | Keyboard → Key repeat rate (fastest) | `2` | `defaults delete NSGlobalDomain KeyRepeat` |
| keyboard | Keyboard → Delay until repeat (shortest) | `15` | `defaults delete NSGlobalDomain InitialKeyRepeat` |
| keyboard | Keyboard → Use F1, F2, etc. keys as standard function keys | `true` | `defaults delete NSGlobalDomain com.apple.keyboard.fnState` |
| keyboard | Keyboard → Text Input → Capitalise words automatically (off) | `false` | `defaults delete NSGlobalDomain NSAutomaticCapitalizationEnabled` |
| keyboard | Keyboard → Text Input → Add full stop with double-space (off) | `false` | `defaults delete NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled` |
| keyboard | (no UI) Hold a key to repeat it instead of showing accents | `false` | `defaults delete NSGlobalDomain ApplePressAndHoldEnabled` |
| trackpad | Trackpad → Tap to click | `true` | `defaults delete com.apple.AppleMultitouchTrackpad Clicking` |
| trackpad | Trackpad → Tap to click (Magic Trackpad) | `true` | `defaults delete com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking` |
| trackpad | Trackpad → Tap to click (login screen) | `1` | `defaults -currentHost delete NSGlobalDomain com.apple.mouse.tapBehavior` |
| trackpad | Trackpad → Tracking speed (fastest) | `3` | `defaults delete NSGlobalDomain com.apple.trackpad.scaling` |
| finder | Finder → View → as List (default view) | `Nlsv` | `defaults delete com.apple.finder FXPreferredViewStyle` |
| finder | Finder → View → Show Path Bar | `true` | `defaults delete com.apple.finder ShowPathbar` |
| finder | Finder → View → Show Status Bar | `true` | `defaults delete com.apple.finder ShowStatusBar` |
| finder | Finder → Settings → When performing a search: current folder | `SCcf` | `defaults delete com.apple.finder FXDefaultSearchScope` |
| finder | Finder → Settings → New Finder windows show: home folder | `PfHm` | `defaults delete com.apple.finder NewWindowTarget` |
| finder | Finder → Settings → New Finder windows show (path) | `file://~/` | `defaults delete com.apple.finder NewWindowTargetPath` |
| finder | Finder → Settings → Remove items from the Bin after 30 days | `true` | `defaults delete com.apple.finder FXRemoveOldTrashItems` |
| finder | Finder → Settings → Keep folders on top in windows | `true` | `defaults delete com.apple.finder _FXSortFoldersFirst` |
| finder | Finder → Settings → Show all filename extensions | `true` | `defaults delete NSGlobalDomain AppleShowAllExtensions` |
| finder | (no UI) Don't create .DS_Store files on network drives | `true` | `defaults delete com.apple.desktopservices DSDontWriteNetworkStores` |
| finder | (no UI) Don't create .DS_Store files on USB drives | `true` | `defaults delete com.apple.desktopservices DSDontWriteUSBStores` |
| system | Appearance → Dark | `Dark` | `defaults delete NSGlobalDomain AppleInterfaceStyle` |
| system | Accessibility → Display → Reduce motion | `true` | `defaults delete com.apple.universalaccess reduceMotion` |
| system | Desktop & Dock → Stage Manager (off) | `false` | `defaults delete com.apple.WindowManager GloballyEnabled` |
| system | Desktop & Dock → Tiled windows have margins (off) | `false` | `defaults delete com.apple.WindowManager EnableTiledWindowMargins` |
| system | Screenshot app → Options → Save to: Documents/Screenshots | `~/Documents/Screenshots` | `defaults delete com.apple.screencapture location` |
| system | Control Centre → Clock Options → Show the day of the week | `true` | `defaults delete com.apple.menuextra.clock ShowDayOfWeek` |

"(no UI)" means there's no switch for it in System Settings.

## Undoing a setting

Each row's **Undo** command removes the value, so macOS goes back to its
default. Then restart the affected app (`killall Dock`, `killall Finder`) or
log out.

## Not automated

- **Display scaling**: the 4K external monitor is set to "looks like
  1920 × 1080" at 144 Hz in System Settings → Displays. Per-display scaling
  can't be set reliably from a script, so set it by hand.
- **Changing a setting here**: edit the `dw` line in `modules/macos.sh`
  (domain, key, type, value, and the System Settings label), then update this
  table. To find a setting's key: `defaults read > before.txt`, change it in
  System Settings, `defaults read > after.txt`, `diff before.txt after.txt`.
