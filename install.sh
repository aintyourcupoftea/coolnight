#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  coolnight · Ghostty + neon zsh for macOS, one command to set up     ║
# ╚══════════════════════════════════════════════════════════════════════╝
#
#   curl -fsSL https://raw.githubusercontent.com/aintyourcupoftea/coolnight/main/install.sh | bash
#
#   coolnight               set up this Mac, or repair it (safe to re-run)
#   coolnight push          send this Mac's config changes to GitHub
#   coolnight pull          get the latest configs from GitHub
#   coolnight status        what changed here and on GitHub
#   coolnight doctor        check that everything is healthy, with fixes
#   coolnight update        pull, then upgrade the apps, tools and plugins
#   coolnight add <file>    start syncing another file, e.g. ~/.vimrc
#   coolnight restore       list backups; `restore <date>` brings one back
#
#   --configs-only  skip installing apps and tools
#   --no-open       don't launch Ghostty at the end
#   --force         push or add even when something looks off
#
# The configs live in ~/.config/coolnight/home and are symlinked into place,
# so editing ~/.zshrc edits the repo. Whatever they replace is moved to
# ~/.local/state/coolnight/<date>/backup/ first, never deleted.
#
# Written for macOS's stock bash 3.2, and safe to pipe into bash.

REPO_URL=${COOLNIGHT_REPO:-https://github.com/aintyourcupoftea/coolnight}
REPO_DIR=$HOME/.config/coolnight
STATE_ROOT=$HOME/.local/state/coolnight
TOOLS="starship eza bat fd ripgrep fzf zoxide fastfetch gh git-delta lazygit btop yazi zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search"
BINARIES="starship eza bat fd rg fzf zoxide fastfetch gh delta lazygit btop yazi"
PLUGINS="zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search"
FZF_TAB_REPO=https://github.com/Aloxaf/fzf-tab
GIT_INCLUDE='~/.config/git/coolnight.gitconfig'
# lines that look like credentials, which must never reach the public repo
SECRET_RE="(api[_-]?key|secret|token|passw(or)?d)[a-z0-9_]*[[:space:]]*[=:][[:space:]]*[\"']?[^[:space:]\"'\$]{8,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-|-----BEGIN [A-Z ]*PRIVATE KEY"

# git must fail fast instead of waiting for a password nobody can type,
# and give up on a stalled connection instead of hanging forever
export GIT_TERMINAL_PROMPT=0 GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=30
CURL="curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 15"

# ─── Look ───────────────────────────────────────────────────────────────
# 256-color codes so it also looks right in Terminal.app
if [[ -t 1 ]]; then
  ESC=$'\033'
  GRN="${ESC}[38;5;85m" CYN="${ESC}[38;5;45m" PRP="${ESC}[38;5;141m" YLW="${ESC}[38;5;222m"
  RED="${ESC}[38;5;203m" DIM="${ESC}[38;5;67m" BLD="${ESC}[1m" RST="${ESC}[0m"
  GRADIENT="85 86 50 51 45 39"
fi
FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

ok()   { printf '  %s✔%s %s\n' "$GRN" "$RST" "$*"; }
have() { printf '  %s✔%s %s %s· %s%s\n' "$GRN" "$RST" "$1" "$DIM" "$2" "$RST"; }
note() { printf '    %s%s%s\n' "$DIM" "$*" "$RST"; }
warn() { printf '  %s!%s %s\n' "$YLW" "$RST" "$*"; WARNINGS=$((WARNINGS + 1)); }
die()  { printf '\n  %s✘ %s%s\n\n' "$RED" "$*" "$RST" >&2; exit 1; }
section() { printf '\n  %s%s%s\n' "$DIM" "$*" "$RST"; }
count() { echo $#; }
tildify() { case $1 in "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;; *) printf '%s' "$1" ;; esac; }
computer_name() { scutil --get ComputerName 2>/dev/null || hostname -s; }
join_lines() { paste -sd , - | sed 's/,/, /g'; }   # lines → "a, b, c"

banner() {
  local line color i=0
  printf '\n'
  if [[ $(tput cols 2>/dev/null || echo 80) -ge 76 ]]; then
    set -- $GRADIENT
    while IFS= read -r line; do
      eval "color=\${$((i % 6 + 1)):-}"
      [[ -n $color ]] && printf '  %s' "${ESC}[38;5;${color}m" || printf '  '
      printf '%s%s\n' "$line" "$RST"
      i=$((i + 1))
    done <<'ART'
 ██████╗ ██████╗  ██████╗ ██╗     ███╗   ██╗██╗ ██████╗ ██╗  ██╗████████╗
██╔════╝██╔═══██╗██╔═══██╗██║     ████╗  ██║██║██╔════╝ ██║  ██║╚══██╔══╝
██║     ██║   ██║██║   ██║██║     ██╔██╗ ██║██║██║  ███╗███████║   ██║
██║     ██║   ██║██║   ██║██║     ██║╚██╗██║██║██║   ██║██╔══██║   ██║
╚██████╗╚██████╔╝╚██████╔╝███████╗██║ ╚████║██║╚██████╔╝██║  ██║   ██║
 ╚═════╝ ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝
ART
  else
    printf '  %s%scoolnight%s\n' "$GRN" "$BLD" "$RST"
  fi
  printf '  %sghostty · neon zsh · comet cursor · one-shot Mac terminal setup%s\n\n' "$DIM" "$RST"
}

sysline() {
  printf '  %s●%s macOS %s · %s · %s%s\n\n' "$CYN" "$RST" "$(sw_vers -productVersion)" \
    "$([[ $(uname -m) == arm64 ]] && echo 'Apple silicon' || echo Intel)" "$(id -un)" \
    "$([[ -d ${REPO:-$REPO_DIR}/.git ]] && printf ' · coolnight %s' "$(git -C "${REPO:-$REPO_DIR}" log -1 --format=%h 2>/dev/null)")"
}

# step "label" command [args…]: runs quietly behind a spinner, output → $LOG
step() {
  local label=$1 rc i=0 t0=$SECONDS line
  shift
  printf '\n━━ %s · %s\n$ %s\n' "$(date +%T)" "$label" "$*" >>"$LOG"
  "$@" >>"$LOG" 2>&1 </dev/null &
  CUR_PID=$!
  if [[ -t 1 ]]; then
    printf '%s' "${ESC}[?25l"
    while kill -0 "$CUR_PID" 2>/dev/null; do
      printf '\r  %s%s%s %s %s%ss%s ' "$CYN" "${FRAMES[i++ % 10]}" "$RST" "$label" "$DIM" $((SECONDS - t0)) "$RST"
      sleep 0.1
    done
    printf '\r%s[K%s[?25h' "$ESC" "$ESC"
  fi
  wait "$CUR_PID"; rc=$?
  CUR_PID=
  if ((rc == 0)); then
    ok "$label"
  else
    printf '  %s✘%s %s\n' "$RED" "$RST" "$label"
    tail -n 6 "$LOG" | while IFS= read -r line; do note "│ $line"; done
  fi
  return $rc
}

# retry <tries> command [args…]: for flaky networks, waits 2s, 4s, … between tries
retry() {
  local tries=$1 i=1
  shift
  until "$@"; do
    ((i >= tries)) && return 1
    echo "(attempt $i failed, retrying)"
    sleep $((i * 2))
    i=$((i + 1))
  done
}

# init_state install|sync: where this run's log and backups go
init_state() {
  local n=0
  STATE=$STATE_ROOT/$(date +%Y-%m-%d_%H%M%S)
  while [[ -e $STATE ]]; do STATE=$STATE_ROOT/$(date +%Y-%m-%d_%H%M%S)-$((n += 1)); done
  BACKUP=$STATE/backup
  if [[ $1 == install ]]; then LOG=$STATE/install.log; else LOG=$STATE_ROOT/last-sync.log; fi
  mkdir -p "${LOG%/*}" && : >"$LOG" || die "couldn't write $(tildify "$LOG")"
  trap cleanup EXIT
  trap 'exit 130' INT TERM
}

# one coolnight at a time: two runs linking or pushing at once would collide
acquire_lock() {
  local pid
  LOCK=$STATE_ROOT/lock
  mkdir -p "$STATE_ROOT"
  if ! mkdir "$LOCK" 2>/dev/null; then
    pid=$(cat "$LOCK/pid" 2>/dev/null)
    if [[ -n $pid ]] && kill -0 "$pid" 2>/dev/null; then
      die "another coolnight is already running (pid $pid); wait for it to finish"
    fi
    rm -rf "$LOCK"   # left behind by a run that crashed
    mkdir "$LOCK" 2>/dev/null || die "couldn't take the lock at $(tildify "$LOCK")"
  fi
  echo $$ >"$LOCK/pid"
  LOCKED=1
}

cleanup() {
  [[ -n $CUR_PID ]] && kill "$CUR_PID" 2>/dev/null
  [[ -n $SUDO_PID ]] && kill "$SUDO_PID" 2>/dev/null
  [[ -n $LOCKED ]] && rm -rf "$LOCK"
  [[ -t 1 ]] && printf '%s' "${ESC}[?25h"
  # a run that changed nothing leaves nothing behind
  [[ -n $LOG && -f $LOG && ! -s $LOG ]] && rm -f "$LOG"
  [[ -n $STATE ]] && rmdir "$BACKUP" "$STATE" 2>/dev/null
  return 0
}

# ─── Detection ──────────────────────────────────────────────────────────
find_brew() {
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x $b ]] && { BREW=$b; return 0; }
  done
  return 1
}

find_zb() {
  local z
  for z in /opt/homebrew/bin/zb /usr/local/bin/zb "$HOME/.zerobrew/bin/zb" "$(command -v zb 2>/dev/null)"; do
    [[ -n $z && -x $z ]] && { ZB=$z; return 0; }
  done
  return 1
}

# where the tools live, so checks work even from a bare `bash install.sh`
tool_path() {
  PATH=/opt/zerobrew/bin:/opt/homebrew/bin:/usr/local/bin:$PATH
  export PATH
}

ghostty_bin() {
  local app
  for app in /Applications/Ghostty.app "$HOME/Applications/Ghostty.app"; do
    [[ -x $app/Contents/MacOS/ghostty ]] && { echo "$app/Contents/MacOS/ghostty"; return 0; }
  done
  return 1
}
have_ghostty() { ghostty_bin >/dev/null; }
have_font() {
  local f
  for f in "$HOME"/Library/Fonts/FiraCodeNerdFontMono-Regular.* /Library/Fonts/FiraCodeNerdFontMono-Regular.*; do
    [[ -e $f ]] && return 0
  done
  return 1
}
ghostty_running() { ps -axo comm= | grep -q '/Ghostty.app/Contents/MacOS/ghostty$'; }
macos_major() { sw_vers -productVersion | cut -d. -f1; }

# /usr/bin/git is only a stub that pops up an installer until Apple's
# command line tools exist, so check for those before touching it
git_ok() {
  local g
  g=$(command -v git) || return 1
  [[ $g != /usr/bin/git ]] || xcode-select -p >/dev/null 2>&1
}

missing_tools() {  # prints the formula name of every tool that isn't installed
  local b p found
  for b in $BINARIES; do
    command -v "$b" >/dev/null 2>&1 && continue
    case $b in rg) echo ripgrep ;; delta) echo git-delta ;; *) echo "$b" ;; esac
  done
  for p in $PLUGINS; do
    found=
    for b in /opt/zerobrew /opt/homebrew /usr/local; do [[ -d $b/share/$p ]] && found=1; done
    [[ -n $found ]] || echo "$p"
  done
}

# ─── Apps and tools ─────────────────────────────────────────────────────
get_sudo() {  # one password prompt up front, kept fresh while we run
  if ! sudo -n true 2>/dev/null; then
    note "your Mac password is needed once, to create /opt/homebrew and /opt/zerobrew"
    sudo -v || return 1
  fi
  ( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 30; done ) &
  SUDO_PID=$!
}

install_homebrew() {
  NONINTERACTIVE=1 /bin/bash -c "$($CURL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_fzf_tab() {
  local dir=$HOME/.local/share/zsh/plugins/fzf-tab
  if [[ -d $dir/.git ]] && git_ok; then
    retry 3 git -C "$dir" pull --ff-only --quiet
  elif [[ -r $dir/fzf-tab.plugin.zsh ]]; then
    :   # a copy from an earlier run without git; still works
  elif git_ok; then
    rmdir "$dir" 2>/dev/null
    mkdir -p "${dir%/*}" && retry 3 git clone --depth 1 --quiet "$FZF_TAB_REPO" "$dir"
  else
    mkdir -p "$dir" && $CURL "$FZF_TAB_REPO/archive/refs/heads/master.tar.gz" | tar -xzf - -C "$dir" --strip-components 1
  fi
}

# the command-line tools: zerobrew first, Homebrew if zerobrew can't
install_tools() {
  local n
  n=$(count $TOOLS)
  note "starship eza bat fd ripgrep fzf zoxide fastfetch gh delta lazygit btop yazi + 4 zsh plugins"
  if [[ -n $ZB ]] && step "$n command-line tools" retry 2 "$ZB" install $TOOLS; then
    :
  else
    [[ -n $ZB ]] && note "zerobrew had trouble, so Homebrew installs them instead"
    step "$n command-line tools (Homebrew)" retry 2 "$BREW" install $TOOLS || true
  fi
  hash -r
  MISSING=$(missing_tools | join_lines)
  [[ -z $MISSING ]] || warn "still missing: $MISSING; the log is at $(tildify "$LOG")"
}

install_packages() {
  local need_sudo
  find_brew || need_sudo=1
  [[ -d /opt/zerobrew ]] || need_sudo=1
  if [[ -n $need_sudo ]]; then
    get_sudo || die "the first-time setup needs an admin account (sudo)"
  fi

  # Homebrew: the apps (Ghostty, the font) and zerobrew itself
  if find_brew; then
    have "Homebrew" "already installed"
  else
    note "the first Homebrew install also fetches Apple's command line tools, so it takes a few minutes"
    step "Homebrew" install_homebrew && find_brew || die "Homebrew didn't install; the log is at $(tildify "$LOG")"
  fi
  eval "$("$BREW" shellenv)"
  export HOMEBREW_NO_ENV_HINTS=1

  if have_ghostty; then
    have "Ghostty" "already installed"
  elif (($(macos_major) < 13)); then
    warn "Ghostty needs macOS 13 or newer; everything else still gets set up"
  else
    step "Ghostty" retry 2 "$BREW" install --cask ghostty || warn "Ghostty didn't install; try: brew install --cask ghostty"
  fi
  if have_font; then
    have "FiraCode Nerd Font" "already installed"
  elif step "FiraCode Nerd Font" retry 2 "$BREW" install --cask font-fira-code-nerd-font; then
    FONT_NEW=1
  else
    warn "the font didn't install, so icons show as boxes; try: brew install --cask font-fira-code-nerd-font"
  fi

  # zerobrew: the fast installer for the command-line tools. Its own shell
  # setup is already in the synced ~/.zshrc, so it must not append another
  if find_zb; then
    have "zerobrew" "already installed"
  else
    step "zerobrew" retry 2 "$BREW" install zerobrewhq/zerobrew/zerobrew && find_zb
  fi
  if [[ -n $ZB && ! -d /opt/zerobrew ]]; then
    step "zerobrew setup" "$ZB" init --no-modify-path --auto-init || ZB=
  fi
  if [[ -n $ZB ]]; then
    export ZEROBREW_ROOT=/opt/zerobrew ZEROBREW_PREFIX=/opt/zerobrew
    PATH=/opt/zerobrew/bin:$PATH
  fi

  install_tools
  step "fzf-tab (fuzzy tab menu)" install_fzf_tab || warn "fzf-tab is missing; Tab falls back to the normal menu"
}

# ─── The repo and the links into it ─────────────────────────────────────
# running from a checkout (bash ~/.config/coolnight/install.sh)?
locate_repo() {
  local self=${BASH_SOURCE[0]:-} dir
  [[ -f $self ]] || return 0
  dir=$(cd "$(dirname "$self")" && pwd) || return 0
  [[ -d $dir/home ]] && REPO=$dir
  return 0
}

require_repo() {
  [[ -d $REPO/.git ]] || die "there's no coolnight repo at $(tildify "$REPO"); set this Mac up first with: coolnight"
}

clone_repo() {
  mkdir -p "${REPO_DIR%/*}" || return 1
  if git_ok; then
    retry 3 git clone --quiet "$REPO_URL" "$REPO_DIR"
  else  # no git yet (--configs-only on a bare Mac): a plain copy still works
    mkdir -p "$REPO_DIR" && $CURL "$REPO_URL/archive/refs/heads/main.tar.gz" | tar -xzf - -C "$REPO_DIR" --strip-components 1
  fi
}

ensure_repo() {
  REPO=$REPO_DIR
  if [[ -d $REPO/.git ]]; then
    # running the one-liner again also updates, unless there's unpushed work
    if [[ -n $(git -C "$REPO" status --porcelain 2>/dev/null) ]]; then
      have "coolnight repo" "has local changes, so not updating (coolnight push first)"
    else
      step "coolnight repo · up to date" retry 3 git -C "$REPO" pull --ff-only --quiet ||
        warn "couldn't update the repo, so this uses the copy already on this Mac"
    fi
    return 0
  fi
  if [[ -d $REPO/home ]] && ! git_ok; then
    have "coolnight repo" "$(tildify "$REPO")"
    return 0
  fi
  # a plain copy from an earlier run, or an older non-git coolnight folder
  if [[ -e $REPO ]]; then stash ".config/coolnight" || die "couldn't move the old $(tildify "$REPO") aside"; fi
  step "coolnight repo → $(tildify "$REPO")" clone_repo || die "couldn't download $REPO_URL; the log is at $(tildify "$LOG")"
}

tracked_files() {  # every file under home/, relative to it
  (cd "$REPO/home" && find . \( -type f -o -type l \) ! -name .DS_Store | sed 's|^\./||' | sort)
}

stash() {  # move ~/$1 into this run's backup folder
  mkdir -p "$BACKUP/$(dirname "$1")" && mv "$HOME/$1" "$BACKUP/$1" && STASHED=$((STASHED + 1))
}

# a ~/.zshrc from before coolnight goes to ~/.zshrc.local, commented out,
# so things like nvm or work PATHs are one uncomment away
keep_old_zshrc() {
  [[ -s $HOME/.zshrc && ! -e $HOME/.zshrc.local ]] || return 0
  grep -q coolnight "$HOME/.zshrc" && return 0
  {
    printf '%s\n' "# ~/.zshrc.local · loaded at the end of ~/.zshrc, on this Mac only (never synced)." \
      "# Below is your old ~/.zshrc, commented out. Uncomment what you still need" \
      "# (PATH tweaks, nvm/pyenv/conda, exports, aliases), but skip old prompt or" \
      "# plugin setup (oh-my-zsh, p10k…): coolnight replaces those." ""
    sed 's/^/# /' "$HOME/.zshrc"
  } >"$HOME/.zshrc.local"
  OLD_ZSHRC=1
}

# ~/.gitconfig stays a plain local file (name, email, anything private) and
# pulls the shared coolnight defaults in with an [include] at the top, so
# `git config --global` never writes into the public repo
ensure_git_include() {
  local f=$HOME/.gitconfig tmp
  [[ -e $REPO/home/.config/git/coolnight.gitconfig ]] || return 0
  if git config --file "$f" --get-all include.path 2>/dev/null | grep -q 'coolnight\.gitconfig$'; then
    return 0
  fi
  if [[ -L $f ]]; then
    warn "~/.gitconfig is a link, so add this yourself: [include] path = $GIT_INCLUDE"
    return 0
  fi
  if [[ -e $f ]]; then
    mkdir -p "$BACKUP" && cp -p "$f" "$BACKUP/.gitconfig" && STASHED=$((STASHED + 1))
  fi
  tmp=$(mktemp "${TMPDIR:-/tmp}/gitconfig.XXXXXX") || return 1
  {
    printf '%s\n' "# ~/.gitconfig · this Mac only, never synced: your name, email and" \
      "# anything private go here. The shared defaults (delta diffs and friends)" \
      "# come from the coolnight include; settings below it win." \
      "[include]" "	path = $GIT_INCLUDE" ""
    if [[ -e $f ]]; then cat "$f"; fi
  } >"$tmp" && mv "$tmp" "$f" && note "git now uses the coolnight defaults (delta diffs) through ~/.gitconfig"
}

# link_configs [quiet]: point ~/<file> at the repo's home/<file>
link_configs() {
  local quiet=$1 rel src dst linked=0 same=0 extra=
  # Ghostty also reads these files, and one with real settings in it would
  # override ours (the empty template Ghostty creates is fine)
  for rel in ".config/ghostty/config.ghostty" \
             "Library/Application Support/com.mitchellh.ghostty/config" \
             "Library/Application Support/com.mitchellh.ghostty/config.ghostty"; do
    if [[ -f $HOME/$rel && ! -L $HOME/$rel ]] && grep -qvE '^[[:space:]]*(#|$)' "$HOME/$rel"; then
      stash "$rel" && note "moved aside ~/$rel, which would override the coolnight Ghostty config"
    fi
  done

  while IFS= read -r rel; do
    src=$REPO/home/$rel dst=$HOME/$rel
    if [[ -L $dst && $(readlink "$dst") == "$src" ]]; then
      same=$((same + 1))
      continue
    fi
    [[ $rel == .zshrc ]] && keep_old_zshrc
    if [[ -e $dst || -L $dst ]]; then stash "$rel" || die "couldn't back up ~/$rel"; fi
    mkdir -p "$(dirname "$dst")" && ln -s "$src" "$dst" || die "couldn't link ~/$rel"
    linked=$((linked + 1))
  done < <(tracked_files)

  if ((linked > 0)); then
    ok "configs linked from $(tildify "$REPO")"
    ((STASHED)) && extra=", $STASHED old ones backed up"
    note "$linked linked, $same already in place$extra"
  elif [[ -z $quiet ]]; then
    have "configs" "already linked"
  fi
  [[ -n $OLD_ZSHRC ]] && note "your old .zshrc is in ~/.zshrc.local, commented out: uncomment what you still need"
  ensure_git_include
  return 0
}

# compinit refuses group-writable folders and nags on every new shell;
# Homebrew's share/ often is one
insecure_completion_dirs() {
  zsh -f 2>/dev/null <<'ZSH'
fpath=({/opt/zerobrew,/opt/homebrew,/usr/local}/share/{zsh-completions,zsh/site-functions}(N-/) $fpath)
autoload -Uz compaudit
compaudit
ZSH
}

fix_completion_perms() {
  local d
  insecure_completion_dirs | while IFS= read -r d; do [[ -O $d ]] && chmod g-w,o-w "$d"; done
  rm -f "$HOME"/.cache/zsh/zcompdump*   # rebuilt on the next shell
}

ensure_zsh_login() {
  local shell
  shell=$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null)
  [[ $shell == *zsh ]] && return 0
  note "switching your login shell to zsh (macOS asks for your password)"
  chsh -s /bin/zsh || warn "couldn't switch the login shell; run: chsh -s /bin/zsh"
}

# ─── Validation: a broken config never leaves this Mac ──────────────────
# validate_configs <home dir>: prints "file: problem" for each broken config
validate_configs() {
  local h=$1 g err
  [[ -f $h/.zshrc ]] && { err=$(zsh -n "$h/.zshrc" 2>&1) || echo ".zshrc: ${err##*: }"; }
  if [[ -f $h/.config/ghostty/config ]] && g=$(ghostty_bin); then
    err=$("$g" +validate-config --config-file="$h/.config/ghostty/config" 2>&1) ||
      echo ".config/ghostty/config: $(echo "$err" | head -1 | sed 's|^.*/config:||')"
  fi
  if [[ -f $h/.config/starship.toml ]] && command -v starship >/dev/null 2>&1; then
    err=$(STARSHIP_CONFIG="$h/.config/starship.toml" starship print-config 2>&1 >/dev/null)
    [[ -z $err ]] || echo ".config/starship.toml: $(echo "$err" | sed $'s/\033\\[[0-9;]*m//g' | head -1 | sed 's/^.*config): //')"
  fi
  if [[ -f $h/.config/fastfetch/config.jsonc ]] && command -v fastfetch >/dev/null 2>&1; then
    fastfetch -c "$h/.config/fastfetch/config.jsonc" --pipe true >/dev/null 2>&1 ||
      echo ".config/fastfetch/config.jsonc: not valid JSON"
  fi
  if [[ -f $h/.config/git/coolnight.gitconfig ]]; then
    git config --file "$h/.config/git/coolnight.gitconfig" --list >/dev/null 2>&1 ||
      echo ".config/git/coolnight.gitconfig: git can't parse it"
  fi
  if [[ -f $h/../install.sh ]]; then
    err=$(/bin/bash -n "$h/../install.sh" 2>&1) || echo "install.sh: ${err##*: }"
  fi
  return 0
}

# ─── Sync ───────────────────────────────────────────────────────────────
looks_secret() { grep -E '^\+' | grep -vE '^\+\+\+ ' | grep -iE "$SECRET_RE"; }

require_gh() {
  command -v gh >/dev/null 2>&1 || die "pushing needs GitHub's gh tool: zb install gh, then gh auth login"
  gh auth status >/dev/null 2>&1 || die "log in to GitHub first (once per Mac): gh auth login"
}

# commit as your GitHub account (private noreply address) unless git
# already has an identity, and push with gh's login, for this repo only
setup_git_for_push() {
  local login id name gh_bin
  if [[ -z $(git -C "$REPO" config user.email) ]]; then
    read -r login id name < <(gh api user --jq '"\(.login) \(.id) \(.name // .login)"' 2>/dev/null)
    [[ -n $id ]] || die "couldn't read your GitHub profile; try: gh auth login"
    git -C "$REPO" config user.name "$name"
    git -C "$REPO" config user.email "$id+$login@users.noreply.github.com"
  fi
  gh_bin=$(command -v gh)
  git -C "$REPO" config --replace-all credential.https://github.com.helper ''
  git -C "$REPO" config --add credential.https://github.com.helper "!$gh_bin auth git-credential"
}

reload_hints() {  # for the files in $INCOMING
  local zsh='' ghostty=''
  case $'\n'$INCOMING$'\n' in *$'\n'.zshrc$'\n'*) zsh=1 ;; esac
  case $'\n'$INCOMING in *$'\n'.config/ghostty/*) ghostty=1 ;; esac
  [[ -n $zsh ]] && note "open a new tab (or run exec zsh) to load the new shell config"
  [[ -n $ghostty ]] && note "press cmd+shift+, in Ghostty to reload its config"
  return 0
}

# fetch, then rebase this Mac's commits on top of GitHub's; sets INCOMING
sync_with_github() {
  local f
  step "checking GitHub" retry 3 git -C "$REPO" fetch --quiet origin || die "couldn't reach GitHub; the log is at $(tildify "$LOG")"
  INCOMING=$(git -C "$REPO" diff --name-only 'HEAD...@{u}' -- home | sed 's|^home/||')
  if ! git -C "$REPO" rebase --quiet '@{u}' >>"$LOG" 2>&1; then
    git -C "$REPO" rebase --abort >/dev/null 2>&1
    die "both Macs changed the same lines. This Mac's version is untouched; merge by hand in $(tildify "$REPO") (git pull --rebase), then coolnight push"
  fi
  # files the other Mac stopped syncing: drop the now-dangling links
  while IFS= read -r f; do
    [[ -n $f && ! -e $REPO/home/$f && -L $HOME/$f ]] || continue
    if [[ $(readlink "$HOME/$f") == "$REPO/home/$f" ]]; then
      rm -f "$HOME/$f" && note "~/$f is no longer synced, so its link was removed"
    fi
  done <<<"$INCOMING"
  return 0
}

tools_hint() {  # after new configs arrive, they may need tools this Mac lacks
  local missing
  missing=$(missing_tools | join_lines)
  [[ -z $missing ]] || note "new tools in this setup aren't installed here yet ($missing): run coolnight update"
}

cmd_push() {
  local hits files n msg l problems
  init_state sync
  acquire_lock
  require_gh
  setup_git_for_push
  problems=$(validate_configs "$REPO/home")
  if [[ -n $problems && -z $FORCE ]]; then
    printf '  %s✘%s nothing pushed: these configs are broken, and would break the other Mac too\n' "$RED" "$RST"
    printf '%s\n' "$problems" | while IFS= read -r l; do note "│ $l"; done
    note "fix them (coolnight doctor shows the details), or push anyway with --force"
    exit 1
  fi
  git -C "$REPO" add -A
  if ! git -C "$REPO" diff --cached --quiet; then
    hits=$(git -C "$REPO" diff --cached -U0 -- home | looks_secret)
    if [[ -n $hits && -z $FORCE ]]; then
      git -C "$REPO" reset --quiet
      printf '  %s✘%s nothing pushed: these lines look like secrets, and the repo is public\n' "$RED" "$RST"
      printf '%s\n' "$hits" | cut -c2-100 | while IFS= read -r l; do note "│ $l"; done
      note "keep secrets in ~/.zshrc.local (it never leaves this Mac), or push anyway with --force"
      exit 1
    fi
    files=$(git -C "$REPO" diff --cached --name-only | sed 's|^home/||')
    n=$(printf '%s\n' "$files" | grep -c .)
    if ((n <= 3)); then msg="Update $(printf '%s\n' "$files" | join_lines)"; else msg="Update $n files"; fi
    git -C "$REPO" commit --quiet -m "$msg (from $(computer_name))" || die "git commit failed"
    ok "saved · $msg"
  fi
  sync_with_github
  if [[ $(git -C "$REPO" rev-list --count '@{u}..HEAD') -eq 0 ]]; then
    have "GitHub" "already up to date"
  else
    step "push to GitHub" retry 3 git -C "$REPO" push --quiet origin HEAD || die "the push failed; the log is at $(tildify "$LOG")"
  fi
  if [[ -n $INCOMING ]]; then
    ok "also got the other Mac's changes · $(printf '%s\n' "$INCOMING" | join_lines)"
    link_configs quiet
    reload_hints
    tools_hint
  fi
}

cmd_pull() {
  local problems l
  init_state sync
  acquire_lock
  if [[ -n $(git -C "$REPO" status --porcelain) ]]; then
    die "this Mac has changes that aren't on GitHub yet; run coolnight push, which merges both sides"
  fi
  sync_with_github
  if [[ -z $INCOMING ]]; then
    have "configs" "already up to date"
  else
    ok "updated · $(printf '%s\n' "$INCOMING" | join_lines)"
  fi
  link_configs quiet
  reload_hints
  tools_hint
  problems=$(validate_configs "$REPO/home")
  if [[ -n $problems ]]; then
    warn "some configs from GitHub look broken:"
    printf '%s\n' "$problems" | while IFS= read -r l; do note "│ $l"; done
  fi
}

cmd_status() {
  local changes behind ahead l p rel unlinked='' online=1
  printf '\n  %s%scoolnight%s %s%s ↔ %s%s\n\n' "$GRN" "$BLD" "$RST" "$DIM" "$(tildify "$REPO")" "${REPO_URL#https://}" "$RST"
  if ! git -C "$REPO" fetch --quiet origin 2>/dev/null || ! git -C "$REPO" rev-parse '@{u}' >/dev/null 2>&1; then
    warn "couldn't reach GitHub, so this only shows this Mac"
    online=
  fi
  behind=$(git -C "$REPO" rev-list --count 'HEAD..@{u}' 2>/dev/null) || behind=0
  ahead=$(git -C "$REPO" rev-list --count '@{u}..HEAD' 2>/dev/null) || ahead=0
  changes=$(git -C "$REPO" status --porcelain)
  if [[ -z $changes ]] && ((ahead == 0 && behind == 0)); then
    if [[ -n $online ]]; then ok "in sync with GitHub"; else ok "nothing changed on this Mac"; fi
  fi
  if [[ -n $changes ]] || ((ahead > 0)); then
    printf '  %s●%s changed on this Mac %s→ coolnight push%s\n' "$CYN" "$RST" "$DIM" "$RST"
    while IFS= read -r l; do
      [[ -n $l ]] || continue
      p=${l:3}
      note "${l:0:2} ${p#home/}"
    done <<<"$changes"
    ((ahead > 0)) && note "+ $ahead saved change(s) not pushed yet"
  fi
  if ((behind > 0)); then
    printf '  %s●%s new on GitHub %s→ coolnight pull%s\n' "$CYN" "$RST" "$DIM" "$RST"
    git -C "$REPO" diff --name-only 'HEAD...@{u}' -- home | sed 's|^home/||' | while IFS= read -r l; do note "$l"; done
  fi
  # a tool that saved over a link with a plain file silently stops syncing
  while IFS= read -r rel; do
    if [[ ! -L $HOME/$rel || $(readlink "$HOME/$rel") != "$REPO/home/$rel" ]]; then
      warn "~/$rel isn't linked to the repo anymore"
      unlinked=1
    fi
  done < <(tracked_files)
  if [[ -n $unlinked ]]; then
    note "keep this Mac's version: coolnight add <file> · keep the repo's: coolnight"
  fi
  printf '\n'
}

cmd_add() {
  local f abs rel home
  (($# > 0)) || die "which file? e.g. coolnight add ~/.vimrc"
  init_state sync
  acquire_lock
  home=$(cd "$HOME" && pwd -P)
  for f in "$@"; do
    [[ -e $f || -L $f ]] || die "no such file: $f"
    abs=$(cd "$(dirname "$f")" && pwd -P)/$(basename "$f")
    [[ $abs == "$home"/* ]] || die "only files in your home folder can be synced: $f"
    rel=${abs#"$home"/}
    abs=$HOME/$rel
    [[ $rel != .config/coolnight/* ]] || die "$f is inside the repo already"
    if [[ -L $abs && $(readlink "$abs") == "$REPO/home/$rel" ]]; then
      have "~/$rel" "already synced"
      continue
    fi
    [[ -f $abs ]] || die "only single files can be synced, not folders: $f"
    if [[ -z $FORCE ]]; then
      case /$rel in
        */.ssh/* | */.aws/* | */.gnupg/* | */.netrc | *.pem | *.key | */.env | */.env.* | /.gitconfig)
          die "~/$rel holds secrets or personal details and the repo is public; add --force if you're sure" ;;
      esac
      if [[ $(file -b --mime-encoding "$abs") != binary ]] && sed 's/^/+/' "$abs" | looks_secret >/dev/null; then
        die "~/$rel seems to contain a token, key or password, and the repo is public; add --force if you're sure"
      fi
    fi
    mkdir -p "$REPO/home/$(dirname "$rel")" && cp "$abs" "$REPO/home/$rel" || die "couldn't copy ~/$rel into the repo"
    stash "$rel" && ln -s "$REPO/home/$rel" "$abs" || die "couldn't link ~/$rel"
    ok "now syncing ~/$rel"
  done
  note "run coolnight push to upload it"
}

# ─── Doctor ─────────────────────────────────────────────────────────────
check_ok()   { printf '  %s✔%s %s\n' "$GRN" "$RST" "$1"; }
check_warn() { printf '  %s!%s %s\n' "$YLW" "$RST" "$1"; [[ -n $2 ]] && note "→ $2"; WARNINGS=$((WARNINGS + 1)); }
check_fail() { printf '  %s✘%s %s\n' "$RED" "$RST" "$1"; [[ -n $2 ]] && note "→ $2"; FAILURES=$((FAILURES + 1)); }

cmd_doctor() {
  local g v missing shell rel unlinked=0 linked=0 problems l err ms ahead behind changes insecure
  tool_path
  printf '\n  %s%scoolnight doctor%s\n' "$GRN" "$BLD" "$RST"

  section "system"
  check_ok "macOS $(sw_vers -productVersion) · $([[ $(uname -m) == arm64 ]] && echo 'Apple silicon' || echo Intel)"
  shell=$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null)
  if [[ $shell == *zsh ]]; then check_ok "login shell is zsh"; else check_fail "login shell is ${shell#UserShell: }" "chsh -s /bin/zsh"; fi

  section "apps"
  if g=$(ghostty_bin); then
    v=$("$g" --version 2>/dev/null | head -1)
    check_ok "${v:-Ghostty}"
  else
    check_fail "Ghostty isn't installed" "coolnight"
  fi
  if have_font; then check_ok "FiraCode Nerd Font"; else check_fail "FiraCode Nerd Font is missing, so icons show as boxes" "coolnight"; fi
  if find_brew; then check_ok "Homebrew $("$BREW" --version 2>/dev/null | head -1 | awk '{print $2}')"; else check_fail "Homebrew isn't installed" "coolnight"; fi
  if find_zb; then check_ok "zerobrew $("$ZB" --version 2>/dev/null | awk '{print $2}')"; else check_warn "zerobrew isn't installed, so Homebrew handles the tools" "coolnight"; fi

  section "tools"
  missing=$(missing_tools | join_lines)
  if [[ -z $missing ]]; then
    check_ok "all $(( $(count $BINARIES) + $(count $PLUGINS) )) tools and zsh plugins"
  else
    check_fail "missing: $missing" "coolnight update"
  fi
  if [[ -r $HOME/.local/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh ]]; then check_ok "fzf-tab"; else check_fail "fzf-tab is missing" "coolnight"; fi

  section "configs"
  if [[ ! -d $REPO/home ]]; then
    check_fail "no coolnight repo at $(tildify "$REPO")" "run the install one-liner again"
  else
    while IFS= read -r rel; do
      if [[ -L $HOME/$rel && $(readlink "$HOME/$rel") == "$REPO/home/$rel" ]]; then
        linked=$((linked + 1))
      else
        unlinked=$((unlinked + 1))
        check_fail "~/$rel isn't linked to the repo" "coolnight (or coolnight add ~/$rel to keep this Mac's version)"
      fi
    done < <(tracked_files)
    ((unlinked == 0)) && check_ok "all $linked configs linked from $(tildify "$REPO")"
    problems=$(validate_configs "$REPO/home")
    if [[ -z $problems ]]; then
      check_ok "configs valid (zsh, Ghostty, starship, fastfetch, git)"
    else
      while IFS= read -r l; do check_fail "broken: $l" "fix it, then coolnight push"; done <<<"$problems"
    fi
    if [[ -e $REPO/home/.config/git/coolnight.gitconfig ]]; then
      if git config --file "$HOME/.gitconfig" --get-all include.path 2>/dev/null | grep -q 'coolnight\.gitconfig$'; then
        check_ok "git uses the coolnight defaults (delta diffs)"
      else
        check_warn "~/.gitconfig doesn't include the coolnight git defaults" "coolnight"
      fi
    fi
    for rel in ".config/ghostty/config.ghostty" \
               "Library/Application Support/com.mitchellh.ghostty/config" \
               "Library/Application Support/com.mitchellh.ghostty/config.ghostty"; do
      if [[ -f $HOME/$rel && ! -L $HOME/$rel ]] && grep -qvE '^[[:space:]]*(#|$)' "$HOME/$rel"; then
        check_warn "~/$rel overrides the coolnight Ghostty config" "coolnight (moves it aside)"
      fi
    done
  fi
  if [[ -n $(git config --get user.email 2>/dev/null) ]]; then
    check_ok "git knows who you are ($(git config --get user.email))"
  else
    check_warn "git has no name or email for your own commits" "git config --global user.name 'Your Name'; git config --global user.email you@example.com"
  fi

  section "shell"
  mkdir -p "$STATE_ROOT"
  ms=$(zsh -fc '
    zmodload zsh/datetime
    run() { script -q "$1" env -u CLAUDECODE COOLNIGHT_NO_SPLASH=1 TERM=xterm-256color zsh -i -c exit >/dev/null 2>&1 </dev/null }
    run /dev/null                 # warm up: the first start builds caches
    s=$EPOCHREALTIME
    run "$1"
    printf "%.0f\n" $(( (EPOCHREALTIME - s) * 1000 ))' zsh "$STATE_ROOT/doctor-zsh.err" 2>/dev/null)
  err=$(tr -d '\r' <"$STATE_ROOT/doctor-zsh.err" 2>/dev/null | grep -a -i -E 'error|not found|no such|command not|can.t|warn' | head -3)
  rm -f "$STATE_ROOT/doctor-zsh.err"
  if [[ -n $err ]]; then
    check_fail "zsh prints errors when it starts:" ""
    printf '%s\n' "$err" | while IFS= read -r l; do note "│ $l"; done
  elif [[ -n $ms ]] && ((ms > 400)); then
    check_warn "zsh takes ${ms} ms to start (usually under 150)" "something in ~/.zshrc.local may be slow"
  else
    check_ok "zsh starts in ${ms:-?} ms with no errors"
  fi
  insecure=$(insecure_completion_dirs | join_lines)
  if [[ -z $insecure ]]; then check_ok "completion folders are secure"; else check_fail "insecure completion folders: $insecure" "coolnight"; fi

  section "sync"
  if [[ -d $REPO/.git ]]; then
    if git -C "$REPO" fetch --quiet origin 2>/dev/null; then
      behind=$(git -C "$REPO" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)
      ahead=$(git -C "$REPO" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
      changes=$(git -C "$REPO" status --porcelain | grep -c .)
      if ((behind + ahead + changes == 0)); then check_ok "in sync with GitHub"; fi
      ((changes + ahead > 0)) && check_warn "$changes changed file(s) on this Mac aren't on GitHub" "coolnight push"
      ((behind > 0)) && check_warn "$behind update(s) on GitHub aren't on this Mac" "coolnight pull"
    else
      check_warn "couldn't reach GitHub" "check the internet connection"
    fi
  fi
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    check_ok "GitHub login works, so coolnight push can upload"
  else
    check_warn "not logged in to GitHub here, so push won't work (pull does)" "gh auth login"
  fi

  printf '\n'
  if ((FAILURES > 0)); then
    printf '  %s%d problem(s)%s, %d warning(s); the fixes are under each one\n\n' "$RED" "$FAILURES" "$RST" "${WARNINGS:-0}"
    return 1
  elif ((WARNINGS > 0)); then
    printf '  %shealthy%s, with %d thing(s) worth a look\n\n' "$GRN" "$RST" "$WARNINGS"
  else
    printf '  %s%sall healthy ✨%s\n\n' "$GRN" "$BLD" "$RST"
  fi
  return 0
}

# ─── Update ─────────────────────────────────────────────────────────────
cmd_update() {
  local secs
  init_state install
  acquire_lock
  tool_path
  printf '\n  %s%scoolnight update%s\n\n' "$GRN" "$BLD" "$RST"
  curl -fsSI --max-time 10 https://github.com >/dev/null 2>&1 || die "no internet connection (couldn't reach github.com)"

  # configs first, so new tools they mention get installed below
  if [[ -n $(git -C "$REPO" status --porcelain) ]]; then
    warn "configs not updated: this Mac has unpushed changes (coolnight push first)"
  else
    sync_with_github
    if [[ -z $INCOMING ]]; then have "configs" "already up to date"; else ok "configs updated · $(printf '%s\n' "$INCOMING" | join_lines)"; fi
  fi
  link_configs quiet

  find_brew && eval "$("$BREW" shellenv)"
  export HOMEBREW_NO_ENV_HINTS=1
  if find_zb; then
    install_tools
    step "upgrade zerobrew tools" "$ZB" upgrade || warn "some zerobrew upgrades failed; the log is at $(tildify "$LOG")"
  elif [[ -n $BREW ]]; then
    install_tools
    step "upgrade Homebrew tools" "$BREW" upgrade $TOOLS || warn "some upgrades failed; the log is at $(tildify "$LOG")"
  else
    warn "neither zerobrew nor Homebrew is installed; run coolnight first"
  fi
  if [[ -n $BREW ]] && "$BREW" list --cask font-fira-code-nerd-font >/dev/null 2>&1; then
    step "FiraCode Nerd Font" "$BREW" upgrade --cask font-fira-code-nerd-font || true
  fi
  step "fzf-tab" install_fzf_tab || warn "couldn't update fzf-tab"
  fix_completion_perms
  have "Ghostty" "updates itself (Ghostty menu → Check for Updates)"

  secs=$((SECONDS - T0))
  printf '\n  %s%s✨ up to date%s %s· %dm%02ds%s\n' "$GRN" "$BLD" "$RST" "$DIM" $((secs / 60)) $((secs % 60)) "$RST"
  reload_hints
  printf '\n'
}

# ─── Restore ────────────────────────────────────────────────────────────
backup_sets() { ls -1d "$STATE_ROOT"/*/backup 2>/dev/null | sort; }

restorable_files() {  # files in a backup set that belong in ~ (not the repo itself)
  (cd "$1" && find . \( -type f -o -type l \) ! -name .DS_Store | sed 's|^\./||' | grep -v '^\.config/coolnight/' | sort)
}

cmd_restore() {
  local bk sets name files n=0 rel shown
  sets=$(backup_sets)
  [[ -n $sets ]] || { ok "no backups yet: nothing has been replaced on this Mac"; return 0; }
  if [[ -z $1 ]]; then
    printf '\n  %s%sbackups%s %s(newest last)%s\n\n' "$GRN" "$BLD" "$RST" "$DIM" "$RST"
    while IFS= read -r bk; do
      name=$(basename "$(dirname "$bk")")
      files=$(restorable_files "$bk")
      [[ -n $files ]] || continue
      shown=$(printf '%s\n' "$files" | head -4 | join_lines)
      n=$(printf '%s\n' "$files" | grep -c .)
      printf '  %s%s%s  %d file(s): %s%s\n' "$CYN" "$name" "$RST" "$n" "$shown" "$( ((n > 4)) && echo ', …')"
    done <<<"$sets"
    printf '\n'
    note "bring one back: coolnight restore <date>   (or: coolnight restore latest)"
    note "what's there now gets backed up first, so a restore can be undone too"
    printf '\n'
    return 0
  fi
  if [[ $1 == latest ]]; then bk=$(printf '%s\n' "$sets" | tail -1); else bk=$STATE_ROOT/$1/backup; fi
  [[ -d $bk ]] || die "no backup called $1; run coolnight restore to list them"
  init_state sync
  acquire_lock
  while IFS= read -r rel; do
    if [[ -e $HOME/$rel || -L $HOME/$rel ]]; then stash "$rel" || die "couldn't back up ~/$rel"; fi
    mkdir -p "$HOME/$(dirname "$rel")" && cp -pP "$bk/$rel" "$HOME/$rel" || die "couldn't restore ~/$rel"
    n=$((n + 1))
  done < <(restorable_files "$bk")
  ok "restored $n file(s) from $(basename "$(dirname "$bk")")"
  [[ -d $BACKUP ]] && note "what was there before is in $(tildify "$BACKUP")"
  note "back to coolnight any time: coolnight"
}

# ─── Install ────────────────────────────────────────────────────────────
do_install() {
  local secs
  init_state install
  acquire_lock
  banner
  sysline

  if [[ -z $CONFIGS_ONLY ]]; then
    curl -fsSI --max-time 10 https://github.com >/dev/null 2>&1 || die "no internet connection (couldn't reach github.com)"
    install_packages
  else
    tool_path
  fi
  [[ -n $REPO ]] || ensure_repo
  link_configs
  fix_completion_perms
  ensure_zsh_login

  secs=$((SECONDS - T0))
  printf '\n  %s%s✨ coolnight is on%s %s· %dm%02ds%s\n\n' "$GRN" "$BLD" "$RST" "$DIM" $((secs / 60)) $((secs % 60)) "$RST"
  [[ -d $BACKUP ]] && printf '  %sbackups%s  %s\n' "$PRP" "$RST" "$(tildify "$BACKUP")"
  [[ -s $LOG ]] && printf '  %slog%s      %s\n' "$PRP" "$RST" "$(tildify "$LOG")"
  printf '  %snext%s     open a new Ghostty window, then type %skeys%s for the cheat sheet\n' "$PRP" "$RST" "$CYN" "$RST"
  printf '  %ssync%s     %scoolnight push%s after you change a config, %scoolnight pull%s on the other Mac\n' "$PRP" "$RST" "$CYN" "$RST" "$CYN" "$RST"
  printf '  %scheck%s    %scoolnight doctor%s any time something feels off\n' "$PRP" "$RST" "$CYN" "$RST"
  printf '  %sheads-up%s Ghostty asks for Accessibility once (for the cmd+` drop-down);\n' "$PRP" "$RST"
  printf '           allow notifications in System Settings → Notifications → Ghostty\n'
  if [[ $TERM_PROGRAM != ghostty ]]; then
    printf '           use Ghostty from now on: other terminals lack the Nerd Font, so icons show as boxes\n'
  fi
  ((WARNINGS)) && printf '  %s%d warning(s) above%s; the details are in the log\n' "$YLW" "$WARNINGS" "$RST"
  printf '\n'

  if [[ -z $NO_OPEN ]] && have_ghostty; then
    if ghostty_running; then
      note "Ghostty is running: press cmd+shift+, in it to reload, then open a new tab"
      [[ -n $FONT_NEW ]] && note "quit it once (cmd+q) and reopen so it picks up the new font"
    else
      open -a Ghostty && note "opening Ghostty…"
    fi
    printf '\n'
  fi
  return 0
}

usage() {
  cat <<'USAGE'
coolnight · Ghostty + neon zsh for macOS

  coolnight               set up this Mac, or repair it (safe to re-run)
  coolnight push          send this Mac's config changes to GitHub
  coolnight pull          get the latest configs from GitHub
  coolnight status        what changed here and on GitHub
  coolnight doctor        check that everything is healthy, with fixes
  coolnight update        pull, then upgrade the apps, tools and plugins
  coolnight add <file>    start syncing another file, e.g. ~/.vimrc
  coolnight restore       list backups; restore <date> or restore latest

  --configs-only  skip installing apps and tools
  --no-open       don't launch Ghostty at the end
  --force         push or add even when something looks off
  --version       which commit of coolnight this is
USAGE
}

main() {
  local cmd= arg
  local -a args
  T0=$SECONDS
  for arg in "$@"; do
    case $arg in
      --configs-only) CONFIGS_ONLY=1 ;;
      --no-open) NO_OPEN=1 ;;
      --force) FORCE=1 ;;
      -h | --help | help) usage; return 0 ;;
      --version) cmd=version ;;
      -*) printf 'coolnight: unknown option %s\n\n' "$arg" >&2; usage >&2; return 2 ;;
      *)
        if [[ -z $cmd ]]; then
          case $arg in
            install | push | pull | status | add | doctor | update | restore) cmd=$arg ;;
            *) printf 'coolnight: unknown command %s\n\n' "$arg" >&2; usage >&2; return 2 ;;
          esac
        elif [[ $cmd == add || $cmd == restore ]]; then
          args+=("$arg")
        else
          printf 'coolnight: %s takes no arguments\n' "$cmd" >&2; return 2
        fi
        ;;
    esac
  done
  [[ $(uname -s) == Darwin ]] || die "coolnight is for macOS"
  [[ $EUID -ne 0 ]] || die "run it as yourself, without sudo"
  [[ -n $HOME && -d $HOME ]] || die "HOME isn't set"
  # piped in (curl … | bash): take the keyboard back for password prompts
  if [[ ! -t 0 ]] && { : </dev/tty; } 2>/dev/null; then exec </dev/tty; fi

  locate_repo
  case ${cmd:-install} in
    install) do_install ;;
    version)
      REPO=${REPO:-$REPO_DIR}
      if [[ -d $REPO/.git ]]; then echo "coolnight $(git -C "$REPO" log -1 --format='%h · %cs · %s')"; else echo "coolnight (not installed yet)"; fi
      ;;
    restore) "cmd_restore" "${args[@]}" ;;
    doctor) REPO=${REPO:-$REPO_DIR}; cmd_doctor ;;
    *)
      REPO=${REPO:-$REPO_DIR}
      require_repo
      "cmd_$cmd" "${args[@]}"
      ;;
  esac
}

main "$@"; exit $?
