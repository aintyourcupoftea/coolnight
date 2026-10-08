#!/usr/bin/env bash
# macOS defaults tuning — review before running.
# Every change here is reverted by macos-tweaks-undo.sh in this same folder.
set -u

echo "→ Keyboard: fast repeat, hold-to-repeat instead of accent picker"
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

echo "→ Text: stop macOS rewriting what you type (matters when coding)"
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

echo "→ Finder: extensions, hidden files, path bar, list view, folders first"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

echo "→ Save/print panels open expanded"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

echo "→ Screenshots: ~/Pictures/Screenshots, PNG, no drop shadow"
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

echo "→ Dock: autohide with no delay, no recents"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 44
defaults write com.apple.dock mineffect -string "scale"

echo "→ Spaces: OmniWM requires 'Displays have separate Spaces' ON (macOS default)"
# OmniWM refuses to tile while this is OFF. (AeroSpace wanted it OFF instead.)
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.spaces spans-displays -bool false

echo "→ Mission Control: group windows by app (required, see note)"
# OmniWM (like AeroSpace) fakes workspaces by moving inactive windows off-screen.
# Without this, Mission Control zooms out to cover them and every thumbnail is tiny.
defaults write com.apple.dock expose-group-apps -bool true

echo "→ Misc: ctrl+cmd drag to move any window from anywhere"
defaults write NSGlobalDomain NSWindowShouldDragOnGesture -bool true

killall Finder Dock SystemUIServer 2>/dev/null

echo
echo "Applied. Log out and back in for the Spaces and key-repeat changes to take fully."
