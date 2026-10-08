# ╔══════════════════════════════════════════════════════════════════════╗
# ║  zsh · coolnight neon · v2                                           ║
# ║  starship + transient prompt · fish-style suggestions · syntax       ║
# ║  colors · fzf everything · fuzzy tab menu · zoxide · eza · bat ·     ║
# ║  delta · lazygit · yazi · btop                                       ║
# ║  cheat sheet: keys          health check: coolnight doctor           ║
# ╚══════════════════════════════════════════════════════════════════════╝

# Claude Code (and other tools) run commands through this file; keep
# their shells predictable and only dress up shells meant for humans.
[[ -n $CLAUDECODE ]] && _agent_shell=1

# ─── Path & environment ────────────────────────────────────────────────
typeset -U path fpath
path=(/opt/homebrew/bin /opt/homebrew/sbin ~/.local/bin $path)

# zerobrew (Homebrew replacement) — must come before anything that runs
# starship/fzf/zoxide/eza, so it lives up here, not at the end of the file
# >>> zerobrew >>>
# zerobrew
export ZEROBREW_DIR="$HOME/.zerobrew"
export ZEROBREW_BIN="$HOME/.zerobrew/bin"
export ZEROBREW_ROOT='/opt/zerobrew'
export ZEROBREW_PREFIX='/opt/zerobrew'
export PKG_CONFIG_PATH="$ZEROBREW_PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

# SSL/TLS certificates (only if ca-certificates is installed)
if [ -z "${CURL_CA_BUNDLE:-}" ] || [ -z "${SSL_CERT_FILE:-}" ]; then
  if [ -f "$ZEROBREW_PREFIX/opt/ca-certificates/share/ca-certificates/cacert.pem" ]; then
    [ -z "${CURL_CA_BUNDLE:-}" ] && export CURL_CA_BUNDLE="$ZEROBREW_PREFIX/opt/ca-certificates/share/ca-certificates/cacert.pem"
    [ -z "${SSL_CERT_FILE:-}" ] && export SSL_CERT_FILE="$ZEROBREW_PREFIX/opt/ca-certificates/share/ca-certificates/cacert.pem"
  elif [ -f "$ZEROBREW_PREFIX/etc/ca-certificates/cacert.pem" ]; then
    [ -z "${CURL_CA_BUNDLE:-}" ] && export CURL_CA_BUNDLE="$ZEROBREW_PREFIX/etc/ca-certificates/cacert.pem"
    [ -z "${SSL_CERT_FILE:-}" ] && export SSL_CERT_FILE="$ZEROBREW_PREFIX/etc/ca-certificates/cacert.pem"
  elif [ -f "$ZEROBREW_PREFIX/etc/openssl/cert.pem" ]; then
    [ -z "${CURL_CA_BUNDLE:-}" ] && export CURL_CA_BUNDLE="$ZEROBREW_PREFIX/etc/openssl/cert.pem"
    [ -z "${SSL_CERT_FILE:-}" ] && export SSL_CERT_FILE="$ZEROBREW_PREFIX/etc/openssl/cert.pem"
  elif [ -f "$ZEROBREW_PREFIX/share/ca-certificates/cacert.pem" ]; then
    [ -z "${CURL_CA_BUNDLE:-}" ] && export CURL_CA_BUNDLE="$ZEROBREW_PREFIX/share/ca-certificates/cacert.pem"
    [ -z "${SSL_CERT_FILE:-}" ] && export SSL_CERT_FILE="$ZEROBREW_PREFIX/share/ca-certificates/cacert.pem"
  fi
fi

if [ -z "${SSL_CERT_DIR:-}" ]; then
  if [ -d "$ZEROBREW_PREFIX/etc/ca-certificates" ]; then
    export SSL_CERT_DIR="$ZEROBREW_PREFIX/etc/ca-certificates"
  elif [ -d "$ZEROBREW_PREFIX/etc/openssl/certs" ]; then
    export SSL_CERT_DIR="$ZEROBREW_PREFIX/etc/openssl/certs"
  elif [ -d "$ZEROBREW_PREFIX/share/ca-certificates" ]; then
    export SSL_CERT_DIR="$ZEROBREW_PREFIX/share/ca-certificates"
  fi
fi

# Helper function to safely append to PATH
_zb_path_append() {
    local argpath="$1"
    case ":${PATH}:" in
        *:"$argpath":*) ;;
        *) export PATH="$argpath:$PATH" ;;
    esac;
}

_zb_path_append "$ZEROBREW_BIN"
_zb_path_append "$ZEROBREW_PREFIX/sbin"
_zb_path_append "$ZEROBREW_PREFIX/bin"

# <<< zerobrew <<<

# zsh plugins come from zerobrew, or from Homebrew on a Mac without it
for _pkg in $ZEROBREW_PREFIX /opt/homebrew /usr/local; do
  [[ -d $_pkg/share/zsh-autosuggestions ]] && break
done

export HOMEBREW_NO_ENV_HINTS=1
export EDITOR=vim VISUAL=vim
export LANG=${LANG:-en_US.UTF-8}
export STARSHIP_LOG=error                 # no "[WARN] scan timed out" over the prompt in big folders
export LG_CONFIG_FILE=~/.config/lazygit/config.yml   # lazygit looks in ~/Library otherwise

# bat everywhere: themed by Ghostty's palette, colored man pages
export BAT_THEME=ansi
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# ─── Colors for ls, eza, fd and completion ─────────────────────────────
export CLICOLOR=1
export LSCOLORS="ExGxFxdxCxDxDxhbadacad"   # macOS ls
# everyone else: file types, then files grouped by kind, all in coolnight hex
() {
  local -A kind=(
    archive '38;2;255;224;115'   # gold
    image   '38;2;162;119;255'   # violet
    media   '38;2;190;158;255'   # lavender
    doc     '38;2;99;241;250'    # ice
    data    '38;2;36;234;247'    # teal
    code    '38;2;107;255;196'   # mint
    junk    '38;2;59;110;143'    # dim
  )
  local -A ext=(
    archive 'zip tar gz tgz bz2 xz zst 7z rar dmg pkg iso'
    image   'png jpg jpeg gif webp svg heic ico bmp tiff'
    media   'mp4 mov mkv webm avi mp3 m4a wav flac ogg'
    doc     'md txt pdf rst org tex epub'
    data    'json jsonc yaml yml toml ini conf plist csv xml'
    code    'sh zsh bash fish py js ts tsx jsx go rs c h cpp swift rb lua java kt sql html css glsl'
    junk    'lock log tmp bak swp old orig DS_Store'
  )
  local k e out="di=1;38;2;15;197;237:ln=38;2;36;234;247:so=38;2;190;158;255:pi=38;2;255;224;115"
  out+=":ex=1;38;2;71;255;156:bd=38;2;255;224;115:cd=38;2;255;224;115:or=38;2;229;46;46:mi=38;2;229;46;46"
  out+=":su=38;2;1;20;35;48;2;229;46;46:sg=38;2;1;20;35;48;2;255;224;115:tw=38;2;1;20;35;48;2;71;255;156:ow=38;2;1;20;35;48;2;36;234;247"
  for k in ${(k)ext}; do
    for e in ${=ext[$k]}; do out+=":*.$e=${kind[$k]}"; done
  done
  export LS_COLORS=$out
}
# eza details: permissions, sizes, dates, git column in coolnight hex
export EZA_COLORS="ur=38;2;255;224;115:uw=38;2;229;46;46:ux=38;2;71;255;156:ue=38;2;71;255;156:gr=38;2;59;110;143:gw=38;2;59;110;143:gx=38;2;59;110;143:tr=38;2;59;110;143:tw=38;2;59;110;143:tx=38;2;59;110;143:sn=38;2;36;234;247:sb=38;2;59;110;143:da=38;2;91;216;245:uu=38;2;68;255;177:un=38;2;162;119;255:gm=38;2;255;224;115:ga=38;2;71;255;156:gd=38;2;229;46;46:gn=38;2;36;234;247:xx=38;2;33;73;105"

# ─── Options ───────────────────────────────────────────────────────────
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT   # `..`, `dirs -v`, `cd -2`
setopt EXTENDED_GLOB GLOB_DOTS INTERACTIVE_COMMENTS NO_BEEP
setopt COMPLETE_IN_WORD ALWAYS_TO_END
setopt NO_FLOW_CONTROL                    # ctrl+s no longer freezes the terminal
WORDCHARS='*?_[]~&;!#$%^(){}<>'           # alt+backspace stops at / . - =

# ─── History: big, shared between tabs, no duplicates ──────────────────
HISTFILE=~/.zsh_history
HISTSIZE=200000
SAVEHIST=200000
setopt SHARE_HISTORY EXTENDED_HISTORY HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_VERIFY   # leading space = don't record

# ─── Completion ────────────────────────────────────────────────────────
fpath=({$ZEROBREW_PREFIX,/opt/homebrew,/usr/local}/share/{zsh-completions,zsh/site-functions}(N-/) $fpath)
mkdir -p ~/.cache/zsh
autoload -Uz compinit
# full security check once a day, cached load otherwise (fast startup)
if [[ -n ~/.cache/zsh/zcompdump(#qN.mh+24) || ! -e ~/.cache/zsh/zcompdump ]]; then
  compinit -d ~/.cache/zsh/zcompdump
else
  compinit -C -d ~/.cache/zsh/zcompdump
fi
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'  # case-insensitive, fuzzy-ish
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' menu no                      # fzf-tab draws the menu
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh/compcache
zstyle ':completion:*:git-checkout:*' sort false

# ─── fzf: coolnight look, fd for files, previews ───────────────────────
# fzf 0.58+ "full" style: separate rounded boxes for input, list and preview
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="\
--style=full --layout=reverse --height=60% --info=inline-right \
--prompt='❯ ' --pointer='▌' --marker='┃' --separator='─' --scrollbar='│' --ghost='type to filter' \
--color=bg+:#033259,bg:-1,gutter:-1,fg:#CBE0F0,fg+:#E8F4FF,hl:#0FC5ED,hl+:#24EAF7 \
--color=border:#214969,list-border:#214969,input-border:#0FC5ED,preview-border:#214969 \
--color=label:#0FC5ED,input-label:#47FF9C,list-label:#3B6E8F,preview-label:#A277FF \
--color=header:#3B6E8F,info:#A277FF,query:#E8F4FF,ghost:#3B6E8F \
--color=prompt:#47FF9C,pointer:#47FF9C,marker:#FFE073,spinner:#47FF9C \
--bind='ctrl-/:toggle-preview,ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--input-label=' files ' --preview-label=' preview ' --preview 'bat --color=always --style=numbers --line-range=:300 {} 2>/dev/null || eza --tree --level=2 --icons=always --color=always {}'"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="--input-label=' jump to folder ' --preview-label=' inside ' --preview 'eza --tree --level=2 --icons=always --color=always {}'"
export FZF_CTRL_R_OPTS="--input-label=' history ' --preview 'echo {2..}' --preview-window=down:3:wrap:hidden --header='ctrl-/ preview · ctrl-y copy' --bind='ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'"

# ─── Plugins (order matters) ───────────────────────────────────────────
# ctrl-r history · ctrl-t files · alt-c dirs (needs fzf 0.48+ for --zsh); only
# with a real terminal: editors run `zsh -i -c env` without one to read PATH
if (( $+commands[fzf] )) && [[ -t 0 ]] && _init=$(fzf --zsh 2>/dev/null); then
  eval "$_init"
fi

# fuzzy tab-completion menu with previews; after compinit and after fzf
# (so it owns Tab), before the widget-wrapping plugins below
_plugin=~/.local/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
[[ -r $_plugin ]] && source $_plugin
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-flags --height=50% --input-label=' complete ' --ghost=''
zstyle ':fzf-tab:complete:(cd|z|zi|eza|ls|cat|bat|vim|open|y|yazi):*' fzf-preview \
  '[[ -d $realpath ]] && eza --tree --level=2 --icons=always --color=always $realpath || bat --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps -p $word -o pid,user,%cpu,%mem,command'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ${(P)word}'
if (( $+commands[delta] )); then
  zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta --width=$FZF_PREVIEW_COLUMNS'
else
  zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff --color=always $word'
fi
zstyle ':fzf-tab:complete:git-(checkout|switch):*' fzf-preview 'git log --oneline --graph --color=always -20 $word'
zstyle ':fzf-tab:complete:brew-(install|uninstall|info):*' fzf-preview 'brew info $word'

# fish-style ghost suggestions from history, then from completions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#3B6E8F'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40
ZSH_AUTOSUGGEST_USE_ASYNC=1
_plugin=$_pkg/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r $_plugin ]] && source $_plugin

# command-line syntax colors (must come before history-substring-search)
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#47FF9C,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#44FFB1,bold'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#44FFB1,underline'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#A277FF,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#6BFFC4,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#24EAF7,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#A277FF,italic'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#A277FF'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#E52E2E,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=#CBE0F0,underline'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#CBE0F0'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#FFE073,bold'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#5BD8F5'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#5BD8F5'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#FFE073'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#FFE073'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#FFE073'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#A277FF'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#24EAF7'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#0FC5ED'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#0FC5ED,bold'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#BE9EFF'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#3B6E8F,italic'
ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=#0FC5ED,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=#A277FF,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=#47FF9C,bold'
ZSH_HIGHLIGHT_STYLES[bracket-error]='fg=#E52E2E,bold'
_plugin=$_pkg/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -r $_plugin ]] && source $_plugin

# type part of a command, then ↑/↓ to cycle only through matching history
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=#033259,fg=#47FF9C,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=#E52E2E,fg=#011423,bold'
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
_plugin=$_pkg/share/zsh-history-substring-search/zsh-history-substring-search.zsh
[[ -r $_plugin ]] && source $_plugin

# ─── Keys (emacs mode) ─────────────────────────────────────────────────
bindkey -e
bindkey '^[[A' history-substring-search-up
bindkey '^[OA' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[OB' history-substring-search-down
bindkey '^ ' autosuggest-accept            # ctrl+space takes the whole suggestion
bindkey '^G' fzf-cd-widget                 # alt+c belongs to OmniWM, so: ctrl+g
bindkey '^[[3~' delete-char
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
# word jumps; Ghostty sends esc+b/f for alt+←/→, other terminals send these
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey ' ' magic-space                    # expand !! / !$ as you type
autoload -Uz edit-command-line && zle -N edit-command-line
bindkey '^X^E' edit-command-line           # ctrl+x ctrl+e: edit command in vim

# ─── Aliases ───────────────────────────────────────────────────────────
if (( ! _agent_shell )); then
  if (( $+commands[eza] )); then
    alias ls='eza --icons=auto --group-directories-first --hyperlink=auto'
    alias ll='eza -lh --icons=auto --group-directories-first --git --time-style=relative --smart-group --hyperlink=auto'
    alias la='ll -a'
    alias lt='eza --tree --level=2 --icons=auto --group-directories-first --hyperlink=auto'
    alias tree='eza --tree --icons=auto --group-directories-first'
  fi
  (( $+commands[bat] )) && alias cat='bat --paging=never'
fi
alias grep='grep --color=auto'
alias ..='cd ..' ...='cd ../..' ....='cd ../../..'
alias md='mkdir -p'
alias reload='exec zsh'
alias path='print -rl -- $path'
alias ff='fastfetch'
alias please='sudo $(fc -ln -1)'
alias myip='curl -s https://ifconfig.me; echo'
(( $+commands[lazygit] )) && alias lg='lazygit'

# git
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gds='git diff --staged'
alias gp='git push'
alias gpl='git pull --rebase'
alias gco='git checkout'
alias gsw='git switch'
alias gl="git log --graph --date=relative --pretty='%C(#47FF9C)%h%C(reset) %C(#0FC5ED)%ad%C(reset) %s %C(#A277FF)%an%C(reset)%C(#FFE073)%d%C(reset)'"

# global aliases: `cmd G pattern`, `cmd L`, `cmd C`
alias -g G='| rg'
alias -g L='| bat --paging=always'
alias -g C='| pbcopy'
alias -g NE='2>/dev/null'

# type a file name to open it: `notes.md` ⏎
alias -s {md,txt,json,yaml,yml,toml,log,csv}='bat'

# ─── Functions ─────────────────────────────────────────────────────────
mkcd() { mkdir -p -- "$1" && cd -- "$1" }

# fuzzy-find a file (with preview) and open it in $EDITOR
fe() {
  local f
  f=$(fzf --query="$*" --input-label=' edit ' --preview 'bat --color=always --style=numbers --line-range=:300 {}') && ${EDITOR:-vim} "$f"
}

# live ripgrep → pick a match → open at that line
rgf() {
  local hit
  hit=$(rg --color=always --line-number --no-heading --smart-case "${*:-}" |
    fzf --ansi --delimiter : --input-label=' grep ' --preview 'bat --color=always --highlight-line {2} {1}' \
        --preview-window '+{2}/2') || return
  ${EDITOR:-vim} "+${${hit#*:}%%:*}" "${hit%%:*}"
}

# fuzzy-pick processes to kill
fkill() {
  local pids
  pids=$(ps -axo pid,user,%cpu,%mem,comm | sed 1d | fzf -m --input-label=' kill ' --header='tab: select several' | awk '{print $1}')
  [[ -n $pids ]] && echo $pids | xargs kill -${1:-15}
}

# browse the git log with diffs; enter opens the whole commit
fgl() {
  git rev-parse --git-dir >/dev/null 2>&1 || { print -u2 "fgl: not inside a git repo"; return 1 }
  git log --color=always --format='%C(#47FF9C)%h%C(reset) %C(#0FC5ED)%<(12,trunc)%ar%C(reset) %s %C(#A277FF)%an%C(reset)%C(#FFE073)%d%C(reset)' "$@" |
    fzf --ansi --no-sort --input-label=' git log ' --preview-label=' commit ' \
        --preview 'git show --color=always {1} | { delta --width=$FZF_PREVIEW_COLUMNS 2>/dev/null || cat; }' \
        --bind 'enter:execute(git show {1})'
}

# switch branches fuzzily (local or remote), previewing each one's log
fgb() {
  local b
  git rev-parse --git-dir >/dev/null 2>&1 || { print -u2 "fgb: not inside a git repo"; return 1 }
  b=$(git branch --all --sort=-committerdate --format='%(refname:short)' | grep -v -e HEAD -e '^origin$' |
      fzf --input-label=' switch branch ' --preview 'git log --oneline --graph --color=always -30 {}') || return
  git switch "${b#origin/}"
}

# yazi file manager; quitting it leaves you in the folder you were browsing
if (( $+commands[yazi] )); then
  y() {
    local tmp cwd
    tmp=$(mktemp -t yazi-cwd) || return
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd <"$tmp"
    [[ -n $cwd && $cwd != $PWD ]] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
  }
fi

# colorized --help: `help git`, `help rg`
help() {
  if (( $+commands[bat] )); then "$@" --help 2>&1 | bat --plain --language=help
  else "$@" --help; fi
}

# unpack anything
extract() {
  case $1 in
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.xz|*.txz)   tar xJf "$1" ;;
    *.tar)            tar xf "$1" ;;
    *.zip)            unzip "$1" ;;
    *.gz)             gunzip "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.7z)             7z x "$1" ;;
    *) echo "extract: don't know how to unpack '$1'" >&2; return 1 ;;
  esac
}

# this whole setup, synced between Macs through GitHub
coolnight() { bash ~/.config/coolnight/install.sh "$@" }
_coolnight() {
  local -a cmds=(
    'push:send this Mac'\''s changes to GitHub'
    'pull:get the latest configs from GitHub'
    'status:what changed, here and on GitHub'
    'doctor:check that everything is healthy'
    'update:upgrade apps, tools and plugins'
    'add:start syncing another file'
    'restore:bring back files from a backup'
  )
  if (( CURRENT == 2 )); then _describe 'coolnight command' cmds
  else _files; fi
}
compdef _coolnight coolnight

# cheat sheet for everything in this file
keys() {
  setopt localoptions nopromptsubst   # starship turns it on; here ` and \ are just characters
  print -P "%F{#47FF9C}%B coolnight%b%f %F{#3B6E8F}· keys and commands%f"
  print -P "%F{#3B6E8F} shell%f"
  print -P "  %F{#0FC5ED}tab%f        fuzzy completion menu (%F{#0FC5ED}<%f %F{#0FC5ED}>%f switch group)   %F{#0FC5ED}ctrl+r%f  fuzzy history"
  print -P "  %F{#0FC5ED}ctrl+t%f     pick a file → command line          %F{#0FC5ED}ctrl+g%f  fuzzy cd"
  print -P "  %F{#0FC5ED}↑ ↓%f        history matching what you typed     %F{#0FC5ED}→%f / %F{#0FC5ED}ctrl+space%f  take suggestion"
  print -P "  %F{#0FC5ED}alt+← →%f    jump words (%F{#0FC5ED}alt+→%f takes one word)   %F{#0FC5ED}cmd+← →%f  start / end of line"
  print -P "  %F{#0FC5ED}ctrl+x ctrl+e%f  edit the command in vim         %F{#0FC5ED}ctrl+/%f  toggle preview inside fzf"
  print -P "%F{#3B6E8F} find & files%f"
  print -P "  %F{#A277FF}cd foo%f  best match (zoxide) · %F{#A277FF}cdi%f pick one    %F{#A277FF}y%f  yazi file manager (cd's on quit)"
  print -P "  %F{#A277FF}ll la lt%f  eza with icons, git, clickable names   %F{#A277FF}fe%f edit · %F{#A277FF}rgf%f grep · %F{#A277FF}fkill%f · %F{#A277FF}extract%f · %F{#A277FF}mkcd%f"
  print -P "  %F{#A277FF}cmd G pat%f  pipe to rg · %F{#A277FF}cmd C%f  to clipboard     %F{#A277FF}help cmd%f  colorful --help"
  print -P "%F{#3B6E8F} git%f"
  print -P "  %F{#A277FF}lg%f  lazygit · %F{#A277FF}fgl%f  browse log with diffs · %F{#A277FF}fgb%f  switch branch   %F{#A277FF}gl gs gd gds%f"
  print -P "%F{#3B6E8F} ghostty%f"
  print -P "  %F{#0FC5ED}cmd+b%f then %F{#0FC5ED}h j k l%f move · %F{#0FC5ED}H J K L%f resize · %F{#0FC5ED}\\\\%f %F{#0FC5ED}-%f split · %F{#0FC5ED}z%f zoom · %F{#0FC5ED}=%f even · %F{#0FC5ED}x%f close"
  print -P "  %F{#0FC5ED}cmd+↑ ↓%f  jump between prompts   %F{#0FC5ED}cmd+\`%f  drop-down terminal   %F{#0FC5ED}cmd+shift+p%f  command palette"
  print -P "%F{#3B6E8F} system%f"
  print -P "  %F{#A277FF}btop%f  activity monitor · %F{#A277FF}ff%f  system splash · %F{#A277FF}coolnight doctor%f · %F{#A277FF}push%f · %F{#A277FF}pull%f · %F{#A277FF}update%f"
}

# ─── Smart cd & prompt ─────────────────────────────────────────────────
if (( $+commands[zoxide] )); then
  if (( ! _agent_shell )); then
    _init=$(zoxide init zsh --cmd cd)   # `cd proj` jumps to the best match; real paths work as usual
  else
    _init=$(zoxide init zsh)
  fi
  [[ -n $_init ]] && eval "$_init"
fi
if (( $+commands[starship] )) && _init=$(starship init zsh 2>/dev/null); then
  eval "$_init"
else                                     # plain fallback until starship is installed
  PROMPT='%F{#0FC5ED}%~%f %(?.%F{#47FF9C}.%F{#E52E2E})❯%f '
fi

# ─── This Mac only ─────────────────────────────────────────────────────
# machine-specific extras (work PATHs, tokens, nvm…) go in ~/.zshrc.local:
# this file is synced to a public repo, that one never leaves this Mac
[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local

# ─── Transient prompt ──────────────────────────────────────────────────
# when you press enter, the two-line prompt collapses to "17:42 ❯ command",
# so scrollback reads like a log of what you ran. Ghostty's prompt marks
# (cmd+↑/↓) still work. Opt out with COOLNIGHT_TRANSIENT=0 in ~/.zshrc.local
if [[ -o interactive && $_agent_shell != 1 && $COOLNIGHT_TRANSIENT != 0 ]]; then
  _cn_prompt=$PROMPT _cn_rprompt=$RPROMPT
  _cn_collapse_prompt() {
    [[ $CONTEXT == start ]] || return 0
    local arrow='#47FF9C'
    (( ${STARSHIP_CMD_STATUS:-0} )) && arrow='#E52E2E'
    PROMPT="%F{#3B6E8F}%D{%H:%M}%f %F{$arrow}❯%f " RPROMPT=''
    zle .reset-prompt
  }
  _cn_restore_prompt() { PROMPT=$_cn_prompt RPROMPT=$_cn_rprompt }
  autoload -Uz add-zle-hook-widget add-zsh-hook
  add-zle-hook-widget line-finish _cn_collapse_prompt
  add-zsh-hook precmd _cn_restore_prompt
fi

# ─── Daily splash ──────────────────────────────────────────────────────
# fastfetch once per day, in the first interactive Ghostty shell
# (COOLNIGHT_NO_SPLASH=1 skips it)
if [[ -o interactive && $_agent_shell != 1 && $TERM_PROGRAM == ghostty && -z $COOLNIGHT_NO_SPLASH ]] && (( $+commands[fastfetch] )); then
  zmodload zsh/datetime
  _splash=~/.cache/zsh/splash-$(strftime %F $EPOCHSECONDS)
  if [[ ! -e $_splash ]]; then
    rm -f ~/.cache/zsh/splash-*(N)
    : > $_splash
    fastfetch
  fi
  unset _splash
fi
unset _agent_shell _pkg _plugin _init
