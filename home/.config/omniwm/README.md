# OmniWM setup (ported from AeroSpace)

`settings.toml` is a port of `~/Downloads/aerospace.toml` for **OmniWM 0.7.5**,
checked against OmniWM's own schema code. This file is the durable reference:
OmniWM strips comments from `settings.toml` whenever it rewrites it.

## One-time steps

1. **Log out and back in.** OmniWM only tiles when *Displays have separate
   Spaces* is **ON**. AeroSpace needed it OFF, so your tweaks script had turned
   it off. The setting is now back on; it applies after you log in again.
2. If macOS asks for permissions after you log back in, approve them.
   Accessibility is required.
3. Turn on **Start at Login** in OmniWM's Settings → General. macOS manages
   that setting, so it isn't stored in `settings.toml`.

## Keybindings

The modifier scheme is the same as before: **alt** goes somewhere, **alt-shift** sends the window there.

### Navigate

| Keys | Action | Was in AeroSpace |
|---|---|---|
| `alt-h/j/k/l` | Focus left/down/up/right. At the screen edge, focus continues onto the next display. | same |
| `alt-shift-h/j/k/l` | Move the window. In Niri this also merges it into, or splits it out of, the neighbouring column. | `move`, plus `join-with` |
| ``alt-` `` | Focus the previous window | `focus-back-and-forth` |
| `alt-1…9`, `alt-b c e m n p t v w z` | Switch to that workspace | same |
| `alt-shift-` + the same keys | Send the focused window to that workspace | same |
| `alt-tab` | Go back to the previous workspace | same |
| `alt-[` / `alt-]` | Previous / next workspace. Empty workspaces are skipped and the list wraps around. | same |
| `alt-shift-[` / `alt-shift-]` | Move the whole workspace to the display on the left / right | `alt-shift-tab` |
| `ctrl-cmd-tab` / ``ctrl-cmd-` `` | Focus the next display / the last-used display | — |

### Layout and size

| Keys | Action | Was in AeroSpace |
|---|---|---|
| `alt-/` | Switch this workspace between **Niri** (scrolling) and **Dwindle** (BSP tiling) | `layout tiles` |
| `alt-shift-/` | Dwindle only: flip the split direction | the h/v flip of `alt-/` |
| `alt-,` | Show the column's windows as tabs | `accordion` |
| `alt-f` | Fullscreen (gaps kept) | `fullscreen` |
| `alt-shift-f` | Toggle floating / tiled | `layout floating tiling` |
| `alt-r` | Cycle the column width: ⅓ → ½ → ⅔ | resize mode |
| `ctrl-alt-h` / `l` | Make the column narrower / wider | resize mode `h` / `l` |
| `ctrl-alt-j` / `k` | Make the window taller / shorter within its column | resize mode `j` / `k` |
| `ctrl-alt-r` | Reset the window's height | — |
| `ctrl-alt-f` | Toggle the column to full width | — |
| `ctrl-alt-e` | Expand the column into the free space | — |
| `ctrl-alt-c` | Center the column | — |
| `ctrl-alt-b` | Balance sizes | resize/service `b` |
| `ctrl-alt-1…9`, `alt-home/end` | Jump to column N / the first or last column | — |
| `ctrl-alt-shift-←/→`, `ctrl-alt-home/end` | Move the column left/right, or to the first/last position | — |

### Tools

| Keys | Action |
|---|---|
| `alt-shift-;` | **Command palette**. It replaces service mode. `⌘4` = Commands, which runs *any* action, including ones without a shortcut. Also `⌘1` windows, `⌘2` app menus, `⌘5` apps, `⌘6` files. |
| `alt-shift-o` | Overview: every workspace zoomed out. Click or drag windows. |
| `ctrl-alt-m` | Open the front app's menu at the cursor |
| `alt-s` / `alt-shift-s` | Show/hide scratchpad 1 / put the window in it (again: take it back out) |
| ``alt-shift-` `` | OmniWM's drop-down terminal. It uses your Ghostty config. |
| `alt-shift-r` | Bring all floating windows to the front |
| `ctrl-cmd` + drag | Drop a tiled window onto another to swap them. Add `shift` to insert it instead (Niri). |
| `ctrl-cmd` + right-drag | Resize a tiled window |
| `alt-shift` + scroll wheel, or a 4-finger swipe | Scroll through columns |

These keys are deliberately left free:
- `alt-return` stays free for JetBrains' Alt+Enter.
- `alt-arrows` stay free for word-by-word cursor movement.
- `alt-minus/equal` stay free so you can type – — ≠ ±.

## How it differs from AeroSpace

- **Workspace names must be numbers.** The letter workspaces are 10–19 with
  the letter as a display name, so the bar shows `B`, not `10`:
  B=10 C=11 E=12 M=13 N=14 P=15 T=16 V=17 W=18 Z=19. App rules use the number:
  `assignToWorkspace = "16"`.
- **Pressing the current workspace's key does nothing.** There's no
  `--auto-back-and-forth`; use `alt-tab` to go back.
- **App rules only route an app's first window, when it launches.** Later
  windows open on the workspace you're on. AeroSpace moved every new window.
- **There are no modes.** Resizing moved to `ctrl-alt-hjkl` and service mode
  to the command palette. You never need `reload-config`: saving the file
  applies it.
- **No equivalent for** `flatten-workspace-tree`, `close-all-windows-but-current`,
  or wrap-around focus at the outermost screen edge.
- **Each workspace has a home display.** All of them live on the main display,
  except **T**, which moves to a second display when one is connected. That
  was your commented-out AeroSpace plan. With one display, everything shares it.
- **Only one rule applies per window**: the most specific match wins. Keep one
  `[[appRules]]` entry per app, with the workspace and minimum size together.

## Why OmniWM is better (in short)

- **Niri scrolling layout.** Windows sit in columns on an endless horizontal
  strip. Opening a window never squeezes the others; the strip scrolls
  instead. Dwindle (Hyprland-style BSP) is one keypress away, per workspace.
- **Built in**:
  - a workspace bar with app icons, hover previews and unread counts (no SketchyBar)
  - focus borders (no JankyBorders)
  - Overview
  - a command palette with window, menu, app and file search, plus clipboard
    history (off until you enable it)
  - Menu Anywhere
  - a Quake-style drop-down terminal built on Ghostty's engine
  - 10 scratchpads
  - trackpad gestures
  - a menu-bar icon hider ("Hidden Bar", needs macOS 27+)
- **A Settings window and an App Rules window**, with live reload.
- **`omniwmctl`** for scripting: queries, commands, rules and event
  subscriptions (IPC is turned on).

One correction: OmniWM isn't an AeroSpace fork. It's an independent project
modelled on Niri and Hyprland. Its tests do reuse AeroSpace's
window-classification data.

## Choices I made for you (each is one value to change)

| Setting | What I chose and why |
|---|---|
| `general.defaultLayoutType = "niri"` | Set it to `"dwindle"` to get AeroSpace-style tiling on every workspace (they all follow this default). |
| `borders.enabled = true` | Uses your JankyBorders blue at 6pt. **Borders were OFF in the file OmniWM generated this morning.** If you turned them off on purpose, set this to `false`. |
| `gaps` + `[[monitorGapOverrides]]` | 12pt gaps, and 8pt on the MacBook screen. `outer.top` counts from the top of the screen, so it includes the 30pt menu bar (42 = 30 + 12). |
| `niri.edgeGaps = false` | Otherwise screen edges get the outer and inner gap added together (24pt). |
| `workspaceBar` | Shown in the menu bar. Hides empty workspaces, collapses repeated app icons into one, shows unread counts (`notificationBadges = "text"`). |
| `gestures.fingerCount = 4` | 3-finger drag is on in macOS, so 3 fingers would also scroll columns. 4-finger swipes also switch macOS Spaces; turn that off under System Settings → Trackpad → More Gestures. |
| `gestures.mouseMoveModifierKey = "controlCommand"` | OmniWM's default is Option. Option-drag would also grab the window during Option-drag duplicate/copy in Photoshop and Finder. Ctrl-cmd matches your existing window-drag gesture (`NSWindowShouldDragOnGesture`). macOS may also move the real window while OmniWM shows its preview; the swap still happens when you release. Plain title-bar drags just snap back into place. |
| `gestures.mouseResizeModifierKey = "controlCommand"` | Same reasoning. It also keeps Finder's Option+right-click menu working. |
| `general.animationSpeed = 1.5` | A bit snappier for someone used to instant AeroSpace. Set it to `1.0` for the default speed. To turn animations off, set `animationsEnabled = false`. |
| `appearance.mode = "automatic"` | Follows your Mac's automatic light/dark switching. |
| Extra app rules | Edge, Dia and Firefox → B. Zed → C. Spotify → M. ZapFast → W. Commander One → E. `com.adobe.Photoshop` → Z, next to your `com.PS.PSD`. Passwords floats. |
| Ghostty quick-terminal rule | Your global ``cmd-` `` Ghostty dropdown floats instead of being sent to T. |

**Ghostty dropdown vs OmniWM's.** OmniWM tracks Ghostty's quick terminal as a
normal floating window that belongs to one workspace. Summoning it from a
different workspace may jump you to that workspace. OmniWM's own terminal
(``alt-shift-` ``) appears on whatever workspace you're on and reads the same
Ghostty config. To switch over:

1. Delete `keybind = global:cmd+grave_accent=toggle_quick_terminal` from
   `~/.config/ghostty/config`.
2. Set `toggleQuakeTerminal` to `"Command+Grave"` in `settings.toml`.

## Files and troubleshooting

- `settings.toml` is live. Saving it applies immediately.
- The schema is strict. A missing key, a bad value, or a missing or duplicated
  hotkey id rejects the whole file. OmniWM then keeps the last good config and
  lists the problem under Diagnostics in its menu-bar icon.
- `settings.toml.omniwm-default.bak` is the untouched file OmniWM generated.
- To see what OmniWM loaded: `omniwmctl query workspaces`, `omniwmctl query rules`,
  `omniwmctl query displays`.
- `../macos-tweaks-apply.sh` now keeps *separate Spaces* ON. Re-running the old
  version would have stopped OmniWM from tiling.
