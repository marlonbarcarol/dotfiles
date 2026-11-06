# shellcheck shell=bash
# macos: apply macOS settings with `defaults write`, grouped so each group can
# run alone. Every setting is labelled with its name in System Settings.

MACOS_GROUPS="dock hot-corners keyboard trackpad finder system"

macos_help() {
  cat <<'EOF'
Usage: ./dotfiles macos [--dry-run] [group...]

Groups: dock hot-corners keyboard trackpad finder system  (none = all)

  ./dotfiles macos                 apply everything
  ./dotfiles macos dock finder     apply just those groups
  ./dotfiles macos --dry-run       show every setting it would write

No admin rights needed. Some keyboard settings take effect after you log out
and back in. Docs (every setting, and how to undo it): docs/macos.md
EOF
}

# dw [-currentHost] <domain> <key> <type> <value> <label>
# Writes one setting; a failure is recorded as skipped, never fatal.
dw() {
  local host=()
  if [ "$1" = "-currentHost" ]; then host=(-currentHost); shift; fi
  local domain="$1" key="$2" type="$3" value="$4" label="$5"
  printf '  %-55s %s\n' "$label" "$value"
  run_cmd defaults ${host[@]+"${host[@]}"} write "$domain" "$key" "-$type" "$value" \
    || skip "$domain $key" "defaults write failed (may need Full Disk Access or Accessibility permission for your terminal)"
}

macos_dock() {
  dw com.apple.dock autohide bool true          "Desktop & Dock › Automatically hide and show the Dock"
  dw com.apple.dock tilesize int 47             "Desktop & Dock › Size"
  dw com.apple.dock show-recents bool false     "Desktop & Dock › Show suggested and recent apps in Dock (off)"
  dw com.apple.dock mru-spaces bool false       "Desktop & Dock › Automatically rearrange Spaces (off)"
  _MACOS_RESTART_DOCK=1
}

macos_hot_corners() {
  # Corner actions: 1 = none, 10 = put display to sleep. Modifier 1048576 = ⌘.
  dw com.apple.dock wvous-tr-corner int 10          "Desktop & Dock › Hot Corners › top right: Put Display to Sleep"
  dw com.apple.dock wvous-tr-modifier int 0         "Desktop & Dock › Hot Corners › top right: no modifier key"
  dw com.apple.dock wvous-br-corner int 1           "Desktop & Dock › Hot Corners › bottom right: none (no Quick Note)"
  dw com.apple.dock wvous-br-modifier int 1048576   "Desktop & Dock › Hot Corners › bottom right: ⌘"
  _MACOS_RESTART_DOCK=1
}

macos_keyboard() {
  dw NSGlobalDomain KeyRepeat int 2                                  "Keyboard › Key repeat rate (fastest)"
  dw NSGlobalDomain InitialKeyRepeat int 15                          "Keyboard › Delay until repeat (shortest)"
  dw NSGlobalDomain com.apple.keyboard.fnState bool true             "Keyboard › Use F1, F2, etc. keys as standard function keys"
  dw NSGlobalDomain NSAutomaticCapitalizationEnabled bool false      "Keyboard › Text Input › Capitalise words automatically (off)"
  dw NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled bool false  "Keyboard › Text Input › Add full stop with double-space (off)"
  dw NSGlobalDomain ApplePressAndHoldEnabled bool false              "(no UI) Hold a key to repeat it instead of showing accents"
}

macos_trackpad() {
  dw com.apple.AppleMultitouchTrackpad Clicking bool true                    "Trackpad › Tap to click"
  dw com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking bool true   "Trackpad › Tap to click (Magic Trackpad)"
  dw -currentHost NSGlobalDomain com.apple.mouse.tapBehavior int 1           "Trackpad › Tap to click (login screen)"
  dw NSGlobalDomain com.apple.trackpad.scaling float 3                       "Trackpad › Tracking speed (fastest)"
}

macos_finder() {
  dw com.apple.finder FXPreferredViewStyle string Nlsv                "Finder › View › as List (default view)"
  dw com.apple.finder ShowPathbar bool true                           "Finder › View › Show Path Bar"
  dw com.apple.finder ShowStatusBar bool true                         "Finder › View › Show Status Bar"
  dw com.apple.finder FXDefaultSearchScope string SCcf                "Finder › Settings › When performing a search: current folder"
  dw com.apple.finder NewWindowTarget string PfHm                     "Finder › Settings › New Finder windows show: home folder"
  dw com.apple.finder NewWindowTargetPath string "file://$HOME/"      "Finder › Settings › New Finder windows show (path)"
  dw com.apple.finder FXRemoveOldTrashItems bool true                 "Finder › Settings › Remove items from the Bin after 30 days"
  dw com.apple.finder _FXSortFoldersFirst bool true                   "Finder › Settings › Keep folders on top in windows"
  dw NSGlobalDomain AppleShowAllExtensions bool true                  "Finder › Settings › Show all filename extensions"
  dw com.apple.desktopservices DSDontWriteNetworkStores bool true     "(no UI) Don't create .DS_Store files on network drives"
  dw com.apple.desktopservices DSDontWriteUSBStores bool true         "(no UI) Don't create .DS_Store files on USB drives"
  _MACOS_RESTART_FINDER=1
}

macos_system() {
  dw NSGlobalDomain AppleInterfaceStyle string Dark                   "Appearance › Dark"
  dw com.apple.universalaccess reduceMotion bool true                 "Accessibility › Display › Reduce motion"
  dw com.apple.WindowManager GloballyEnabled bool false               "Desktop & Dock › Stage Manager (off)"
  dw com.apple.WindowManager EnableTiledWindowMargins bool false      "Desktop & Dock › Tiled windows have margins (off)"
  run_cmd mkdir -p "$HOME/Documents/Screenshots"
  dw com.apple.screencapture location string "$HOME/Documents/Screenshots" "Screenshot app › Options › Save to: Documents/Screenshots"
  dw com.apple.menuextra.clock ShowDayOfWeek bool true                "Control Centre › Clock Options › Show the day of the week"
  _MACOS_RESTART_UI=1
}

macos_main() {
  local groups=("$@") g
  [ ${#groups[@]} -eq 0 ] && read -r -a groups <<< "$MACOS_GROUPS"
  for g in "${groups[@]}"; do
    case " $MACOS_GROUPS " in
      *" $g "*) ;;
      *) warn "unknown group: $g (groups: $MACOS_GROUPS)"; return 2 ;;
    esac
  done

  _MACOS_RESTART_DOCK=0 _MACOS_RESTART_FINDER=0 _MACOS_RESTART_UI=0
  for g in "${groups[@]}"; do
    log "macos: $g"
    "macos_${g//-/_}"
  done

  # Restart each affected app once so the new settings show up.
  [ "$_MACOS_RESTART_DOCK" = 1 ]   && { run_cmd killall Dock || true; }
  [ "$_MACOS_RESTART_FINDER" = 1 ] && { run_cmd killall Finder || true; }
  [ "$_MACOS_RESTART_UI" = 1 ]     && { run_cmd killall SystemUIServer || true; }
  print_skips
}
