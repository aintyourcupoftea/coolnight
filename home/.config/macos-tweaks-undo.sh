#!/usr/bin/env bash
# Reverts every change made by macos-tweaks-apply.sh, back to macOS stock.
set -u

for k in KeyRepeat InitialKeyRepeat ApplePressAndHoldEnabled \
         NSAutomaticCapitalizationEnabled NSAutomaticDashSubstitutionEnabled \
         NSAutomaticQuoteSubstitutionEnabled NSAutomaticPeriodSubstitutionEnabled \
         NSAutomaticSpellingCorrectionEnabled AppleShowAllExtensions \
         NSNavPanelExpandedStateForSaveMode NSNavPanelExpandedStateForSaveMode2 \
         PMPrintingExpandedStateForPrint NSWindowShouldDragOnGesture; do
    defaults delete NSGlobalDomain "$k" 2>/dev/null
done

for k in AppleShowAllFiles ShowPathbar ShowStatusBar FXPreferredViewStyle \
         _FXSortFoldersFirst FXDefaultSearchScope FXEnableExtensionChangeWarning; do
    defaults delete com.apple.finder "$k" 2>/dev/null
done

for k in autohide autohide-delay autohide-time-modifier show-recents \
         tilesize mineffect mru-spaces expose-group-apps; do
    defaults delete com.apple.dock "$k" 2>/dev/null
done

for k in location type disable-shadow; do
    defaults delete com.apple.screencapture "$k" 2>/dev/null
done

defaults delete com.apple.spaces spans-displays 2>/dev/null
defaults delete com.apple.desktopservices DSDontWriteNetworkStores 2>/dev/null
defaults delete com.apple.desktopservices DSDontWriteUSBStores 2>/dev/null

killall Finder Dock SystemUIServer 2>/dev/null

echo "Reverted to macOS defaults. Log out and back in."
