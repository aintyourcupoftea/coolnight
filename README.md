```
 ██████╗ ██████╗  ██████╗ ██╗     ███╗   ██╗██╗ ██████╗ ██╗  ██╗████████╗
██╔════╝██╔═══██╗██╔═══██╗██║     ████╗  ██║██║██╔════╝ ██║  ██║╚══██╔══╝
██║     ██║   ██║██║   ██║██║     ██╔██╗ ██║██║██║  ███╗███████║   ██║
██║     ██║   ██║██║   ██║██║     ██║╚██╗██║██║██║   ██║██╔══██║   ██║
╚██████╗╚██████╔╝╚██████╔╝███████╗██║ ╚████║██║╚██████╔╝██║  ██║   ██║
 ╚═════╝ ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝
```

**My Mac terminal: Ghostty and a neon zsh. One command sets up a whole Mac.**

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/aintyourcupoftea/coolnight/main/install.sh | bash
```

On a fresh Mac it takes 5–10 minutes, mostly for Apple's command line tools, and asks for your password once. It's safe to re-run: anything it replaces is moved to `~/.local/state/coolnight/<date>/backup/`, never deleted. An existing `~/.zshrc` is carried over to `~/.zshrc.local`, commented out.

## What you get

- **Ghostty** in the coolnight theme: a `#011423` background at 80% opacity with blur over a background image, a neon palette in Display P3, and FiraCode Nerd Font with ligatures
- **Comet cursor**, a custom shader: the cursor smears neon green into cyan when it jumps, and ripples when a window or split gains focus
- **zsh** with a two-line [starship](https://starship.rs) prompt, fish-style autosuggestions, syntax highlighting, a fuzzy Tab menu with previews ([fzf-tab](https://github.com/Aloxaf/fzf-tab)), fuzzy history, smart `cd` ([zoxide](https://github.com/ajeetdsouza/zoxide)), eza and bat in place of ls and cat, colored man pages, and a daily fastfetch splash
- **Tools** installed with [zerobrew](https://github.com/zerobrewhq/zerobrew), and apps with Homebrew: starship, eza, bat, fd, ripgrep, fzf, zoxide, fastfetch, gh, plus four zsh plugins

## Keys

| key | does |
|---|---|
| <kbd>tab</kbd> | fuzzy completion menu with previews (<kbd><</kbd> <kbd>></kbd> switch groups) |
| <kbd>ctrl</kbd>+<kbd>r</kbd> | fuzzy history |
| <kbd>ctrl</kbd>+<kbd>t</kbd> | fuzzy file picker |
| <kbd>ctrl</kbd>+<kbd>g</kbd> | fuzzy `cd` |
| <kbd>↑</kbd> <kbd>↓</kbd> | history matching what you've typed |
| <kbd>→</kbd> or <kbd>ctrl</kbd>+<kbd>space</kbd> | accept the grey suggestion |
| `cd foo` | jump to the folder you use most that matches `foo` |
| `keys` | the full cheat sheet |

## Keeping Macs in sync

The configs live in `~/.config/coolnight/home/` and are symlinked into place, so editing `~/.zshrc` edits the repo.

| command | does |
|---|---|
| `coolnight push` | send this Mac's changes to GitHub, merging the other Mac's first |
| `coolnight pull` | get the latest; most changes apply right away |
| `coolnight status` | what changed, here and on GitHub |
| `coolnight add ~/.gitconfig` | start syncing another file |
| `coolnight` | repair: re-link configs, reinstall missing tools |

Pushing needs `gh auth login`, once per Mac. This repo is public, so `push` refuses anything that looks like a token, key or password. Keep secrets and machine-only settings in `~/.zshrc.local`, which is never synced.

## Layout

```
install.sh        the installer, and the coolnight command
home/             mirrors ~: each file is linked to the same path in your home
├── .zshrc
└── .config/
    ├── ghostty/
    │   ├── config                     theme, font, window, keys
    │   ├── background.jpeg
    │   └── shaders/coolnight-comet.glsl
    ├── starship.toml                  prompt
    └── fastfetch/config.jsonc         splash
```

## Heads-up

- Ghostty asks for Accessibility once, for the <kbd>cmd</kbd>+<kbd>`</kbd> drop-down terminal.
- To get notified when long commands finish, allow notifications in System Settings → Notifications → Ghostty.
- The keys avoid <kbd>alt</kbd>+letter combos, which tiling window managers such as OmniWM take; that's why the fuzzy `cd` is on <kbd>ctrl</kbd>+<kbd>g</kbd>.
