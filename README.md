```
 ██████╗ ██████╗  ██████╗ ██╗     ███╗   ██╗██╗ ██████╗ ██╗  ██╗████████╗
██╔════╝██╔═══██╗██╔═══██╗██║     ████╗  ██║██║██╔════╝ ██║  ██║╚══██╔══╝
██║     ██║   ██║██║   ██║██║     ██╔██╗ ██║██║██║  ███╗███████║   ██║
██║     ██║   ██║██║   ██║██║     ██║╚██╗██║██║██║   ██║██╔══██║   ██║
╚██████╗╚██████╔╝╚██████╔╝███████╗██║ ╚████║██║╚██████╔╝██║  ██║   ██║
 ╚═════╝ ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝
```

**My Mac terminal: Ghostty and a neon zsh, deep-ocean colors, a comet for a cursor. One command sets up a whole Mac, and keeps two in sync.**

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/aintyourcupoftea/coolnight/main/install.sh | bash
```

On a fresh Mac it takes 5–10 minutes, mostly for Apple's command line tools, and asks for your password once. Running it again is safe, and also updates a Mac that already has it. Anything it replaces is moved to `~/.local/state/coolnight/<date>/backup/`, never deleted, and an existing `~/.zshrc` is carried over to `~/.zshrc.local`, commented out.

## What you get

**Ghostty**
- The coolnight theme: a `#011423` background at 80% opacity with blur over a background image, a neon palette in Display P3, and FiraCode Nerd Font with ligatures
- **Comet cursor**, a custom shader: the cursor smears neon green into cyan when it jumps, and ripples when a window or split gains focus
- **Pane leader**: <kbd>cmd</kbd>+<kbd>b</kbd>, then one key to move, resize, split, zoom or close splits (Ghostty 1.3 key tables)
- Word jumps and line jumps with <kbd>alt</kbd>/<kbd>cmd</kbd>+<kbd>←</kbd><kbd>→</kbd> like any Mac app, a bell that flashes the pane instead of beeping, a notification when a long command finishes

**zsh**
- A two-line [starship](https://starship.rs) prompt: folder, git branch, status and lines changed, toolchain versions, and on the right the last exit code, duration, jobs, sudo and the time
- **Transient prompt**: once you press enter, the prompt collapses to `17:42 ❯ command`, so scrollback reads like a clean log
- Fish-style suggestions, syntax highlighting, a fuzzy Tab menu with previews ([fzf-tab](https://github.com/Aloxaf/fzf-tab)), fuzzy history, file and folder pickers in fzf's boxed style, smart `cd` ([zoxide](https://github.com/ajeetdsouza/zoxide))
- eza for `ls`, with icons, git status and clickable names; bat for `cat`, man pages and `--help`; a daily fastfetch splash with usage bars

**OmniWM**
- [OmniWM](https://omniwm.app), a Niri-style scrolling tiling window manager, with my hotkeys, 19 workspaces (1–9 plus letters), app rules, gaps, the workspace bar and the drop-down terminal. Installed and started for you; `~/.config/omniwm/README.md` lists every key
- Its `settings.toml` syncs as a **copy**, not a link, because OmniWM rewrites the file itself; changes from the other Mac are written in place, so OmniWM's live reload picks them up

**Tools, all themed coolnight**
- [delta](https://github.com/dandavison/delta) for git diffs: syntax highlighting, line numbers, clickable file names
- [lazygit](https://github.com/jesseduffield/lazygit) (`lg`), [btop](https://github.com/aristocratos/btop) with a transparent background, [yazi](https://github.com/sxyazi/yazi) (`y`) with image previews
- Installed with [zerobrew](https://github.com/zerobrewhq/zerobrew); apps with Homebrew

## Keys

Type `keys` for the full cheat sheet.

| key | does |
|---|---|
| <kbd>tab</kbd> | fuzzy completion menu with previews (<kbd><</kbd> <kbd>></kbd> switch groups) |
| <kbd>ctrl</kbd>+<kbd>r</kbd> · <kbd>ctrl</kbd>+<kbd>t</kbd> · <kbd>ctrl</kbd>+<kbd>g</kbd> | fuzzy history · pick a file · jump to a folder |
| <kbd>↑</kbd> <kbd>↓</kbd> | history matching what you've typed |
| <kbd>→</kbd> or <kbd>ctrl</kbd>+<kbd>space</kbd> | accept the grey suggestion; <kbd>alt</kbd>+<kbd>→</kbd> takes one word |
| <kbd>cmd</kbd>+<kbd>b</kbd>, then <kbd>h</kbd><kbd>j</kbd><kbd>k</kbd><kbd>l</kbd> | move between splits; <kbd>H</kbd><kbd>J</kbd><kbd>K</kbd><kbd>L</kbd> resize, <kbd>\\</kbd> <kbd>-</kbd> split, <kbd>z</kbd> zoom, <kbd>x</kbd> close |
| <kbd>cmd</kbd>+<kbd>↑</kbd> <kbd>↓</kbd> | jump between prompts |
| `y` · `lg` · `btop` | files · git · system monitor |
| `fgl` · `fgb` | browse the git log with diffs · switch branch |
| <kbd>alt</kbd>+<kbd>h</kbd><kbd>j</kbd><kbd>k</kbd><kbd>l</kbd> · <kbd>alt</kbd>+<kbd>1</kbd>…<kbd>9</kbd> | OmniWM: focus · workspaces (add <kbd>shift</kbd> to send the window there) |
| <kbd>alt</kbd>+<kbd>shift</kbd>+<kbd>o</kbd> · <kbd>alt</kbd>+<kbd>shift</kbd>+<kbd>;</kbd> | OmniWM overview · command palette |

## Keeping Macs in sync

The configs live in `~/.config/coolnight/home/` and are symlinked into place, so editing `~/.zshrc` edits the repo.

| command | does |
|---|---|
| `coolnight push` | send this Mac's changes to GitHub, merging the other Mac's first |
| `coolnight pull` | get the latest; most changes apply right away |
| `coolnight status` | what changed, here and on GitHub |
| `coolnight doctor` | check everything (apps, tools, links, configs, startup time, sync), with the fix for each problem |
| `coolnight update` | pull, then install new tools and upgrade everything |
| `coolnight add ~/.vimrc` | start syncing another file |
| `coolnight restore` | list backups; `coolnight restore latest` brings the last one back |
| `coolnight` | repair: re-link configs, reinstall what's missing |

Pushing needs `gh auth login`, once per Mac. Files an app rewrites on its own are listed in `copied-files.txt` and synced as copies; if one changes on both Macs at once, coolnight keeps this Mac's version and asks you to merge instead of overwriting either.

**Safety nets.** This repo is public, so `push` refuses anything that looks like a token, key or password, and also refuses configs that are broken (it checks them with zsh, Ghostty, starship, fastfetch and git), so a typo never reaches the other Mac. Keep secrets and machine-only settings in `~/.zshrc.local`, and your git name and email in `~/.gitconfig`; neither is ever synced. Only one coolnight runs at a time, and network steps retry instead of hanging.

## Layout

```
install.sh        the installer and the coolnight command
tests/run.sh      the test suite: two fake Macs and a fake GitHub, nothing real touched
home/             mirrors ~: each file is linked to the same path in your home
├── .zshrc
└── .config/
    ├── ghostty/
    │   ├── config                     theme, font, window, keys
    │   ├── background.jpeg
    │   └── shaders/coolnight-comet.glsl
    ├── starship.toml                  prompt
    ├── fastfetch/config.jsonc         splash
    ├── git/coolnight.gitconfig        delta and git defaults (included from ~/.gitconfig)
    ├── lazygit/config.yml
    ├── btop/btop.conf, themes/coolnight.theme
    ├── yazi/yazi.toml
    ├── omniwm/settings.toml           window manager (a synced copy) + README.md
    └── macos-tweaks-apply.sh, -undo.sh  optional macOS defaults (never run for you)
copied-files.txt  which files sync as copies instead of links
```

**Not synced, on purpose:** GitHub logins (`gh`), OmniWM's IPC secret, caches, and app leftovers like FlashSpace's old settings.

## Colors

| | | | |
|---|---|---|---|
| `#011423` background | `#033259` deep | `#214969` slate | `#3B6E8F` dim |
| `#CBE0F0` text | `#47FF9C` neon | `#44FFB1` mint | `#0FC5ED` aqua |
| `#24EAF7` teal | `#FFE073` gold | `#E52E2E` coral | `#A277FF` violet |

## Heads-up

- Ghostty asks for Accessibility once, for the <kbd>cmd</kbd>+<kbd>`</kbd> drop-down terminal. OmniWM needs Accessibility too; then turn on **Start at Login** in its Settings → General (macOS keeps that setting, so it can't sync).
- `~/.config/macos-tweaks-apply.sh` (key repeat, Finder, Dock, screenshots…) comes along but never runs on its own; run it if you want it, and `macos-tweaks-undo.sh` puts macOS back to stock.
- To get notified when long commands finish, allow notifications in System Settings → Notifications → Ghostty.
- The keys avoid <kbd>alt</kbd>+letter combos, which tiling window managers such as OmniWM take; that's why the fuzzy `cd` is on <kbd>ctrl</kbd>+<kbd>g</kbd>.
- Run `bash tests/run.sh` after changing `install.sh`.
