# ╔══════════════════════════════════════════════════════════════════════╗
# ║  zsh · coolnight neon                                                ║
# ║  starship prompt · fish-style suggestions · syntax colors · fzf      ║
# ║  everything · fuzzy tab menu · zoxide · eza icons · bat              ║
# ║  cheat sheet: run `keys`                                             ║
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

# bat everywhere: themed by Ghostty's palette, colored man pages
export BAT_THEME=ansi
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# ─── Colors for ls, eza, completion ────────────────────────────────────
export CLICOLOR=1
export LSCOLORS="ExGxFxdxCxDxDxhbadacad"
export LS_COLORS="di=1;34:ln=1;36:so=1;35:pi=33:ex=1;32:bd=1;33:cd=1;33:su=37;41:sg=30;43:tw=30;42:ow=30;43"
# eza details: permissions, sizes, dates, git column in coolnight hex
export EZA_COLORS="ur=38;2;255;224;115:uw=38;2;229;46;46:ux=38;2;71;255;156:ue=38;2;71;255;156:gr=38;2;59;110;143:gw=38;2;59;110;143:gx=38;2;59;110;143:tr=38;2;59;110;143:tw=38;2;59;110;143:tx=38;2;59;110;143:sn=38;2;36;234;247:sb=38;2;59;110;143:da=38;2;91;216;245:uu=38;2;68;255;177:un=38;2;162;119;255:gm=38;2;255;224;115:ga=38;2;71;255;156:gd=38;2;229;46;46:gn=38;2;36;234;247:xx=38;2;33;73;105"

# ─── Options ───────────────────────────────────────────────────────────
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT   # `..`, `dirs -v`, `cd -2`
setopt EXTENDED_GLOB GLOB_DOTS INTERACTIVE_COMMENTS NO_BEEP
setopt COMPLETE_IN_WORD ALWAYS_TO_END

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
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="\
--height=60% --layout=reverse --border=rounded --info=inline-right \
--prompt='❯ ' --pointer='▌' --marker='┃' --separator='─' --scrollbar='│' \
--color=bg+:#033259,bg:-1,gutter:-1,fg:#CBE0F0,fg+:#E8F4FF,hl:#0FC5ED,hl+:#24EAF7 \
--color=border:#214969,label:#0FC5ED,header:#3B6E8F,info:#A277FF,query:#E8F4FF \
--color=prompt:#47FF9C,pointer:#47FF9C,marker:#FFE073,spinner:#47FF9C \
--bind='ctrl-/:toggle-preview,ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {} 2>/dev/null || eza --tree --level=2 --icons=always --color=always {}'"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons=always --color=always {}'"
export FZF_CTRL_R_OPTS="--preview 'echo {2..}' --preview-window=down:3:wrap:hidden --header='ctrl-/ preview · ctrl-y copy' --bind='ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'"

# ─── Plugins (order matters) ───────────────────────────────────────────
(( $+commands[fzf] )) && source <(fzf --zsh)   # ctrl-r history · ctrl-t files · alt-c dirs

# fuzzy tab-completion menu with previews; after compinit and after fzf
# (so it owns Tab), before the widget-wrapping plugins below
_plugin=~/.local/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
[[ -r $_plugin ]] && source $_plugin
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-flags --height=50%
zstyle ':fzf-tab:complete:(cd|z|zi|eza|ls|cat|bat|vim|open):*' fzf-preview \
  '[[ -d $realpath ]] && eza --tree --level=2 --icons=always --color=always $realpath || bat --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps -p $word -o pid,user,%cpu,%mem,command'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ${(P)word}'
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff --color=always $word'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --oneline --graph --color=always -20 $word'
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

# ─── Keys (emacs mode; Ghostty already maps cmd/alt+arrows) ────────────
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
bindkey ' ' magic-space                    # expand !! / !$ as you type
autoload -Uz edit-command-line && zle -N edit-command-line
bindkey '^X^E' edit-command-line           # ctrl+x ctrl+e: edit command in vim

# ─── Aliases ───────────────────────────────────────────────────────────
if (( ! _agent_shell )); then
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza -lh --icons=auto --group-directories-first --git --time-style=relative'
  alias la='ll -a'
  alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
  alias tree='eza --tree --icons=auto --group-directories-first'
  alias cat='bat --paging=never'
fi
alias grep='grep --color=auto'
alias ..='cd ..' ...='cd ../..' ....='cd ../../..'
alias md='mkdir -p'
alias reload='exec zsh'
alias path='print -rl -- $path'
alias ff='fastfetch'
alias please='sudo $(fc -ln -1)'
alias myip='curl -s https://ifconfig.me; echo'

# git
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gp='git push'
alias gpl='git pull --rebase'
alias gco='git checkout'
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
  f=$(fzf --query="$*" --preview 'bat --color=always --style=numbers --line-range=:300 {}') && ${EDITOR:-vim} "$f"
}

# live ripgrep → pick a match → open at that line
rgf() {
  local hit
  hit=$(rg --color=always --line-number --no-heading --smart-case "${*:-}" |
    fzf --ansi --delimiter : --preview 'bat --color=always --highlight-line {2} {1}' \
        --preview-window '+{2}/2') || return
  ${EDITOR:-vim} "+${${hit#*:}%%:*}" "${hit%%:*}"
}

# fuzzy-pick processes to kill
fkill() {
  local pids
  pids=$(ps -axo pid,user,%cpu,%mem,comm | sed 1d | fzf -m --header='tab: select several' | awk '{print $1}')
  [[ -n $pids ]] && echo $pids | xargs kill -${1:-15}
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
_coolnight() { _arguments '1:command:(push pull status add)' '*:file:_files' }
compdef _coolnight coolnight

# cheat sheet for everything in this file
keys() {
  print -P "%F{#47FF9C}%B coolnight zsh%b%f"
  print -P "  %F{#0FC5ED}ctrl+r%f  fuzzy history       %F{#0FC5ED}ctrl+t%f  fuzzy file → command line"
  print -P "  %F{#0FC5ED}ctrl+g%f  fuzzy cd            %F{#0FC5ED}tab%f     fuzzy completion menu (< > switch group)"
  print -P "  %F{#0FC5ED}↑ / ↓%f   history matching what you've typed"
  print -P "  %F{#0FC5ED}→%f / %F{#0FC5ED}ctrl+space%f  accept grey suggestion   %F{#0FC5ED}alt+→%f  accept one word"
  print -P "  %F{#0FC5ED}ctrl+x ctrl+e%f  edit command in vim   %F{#0FC5ED}ctrl+/%f  toggle preview inside fzf"
  print -P "  %F{#A277FF}cd foo%f  jump to best match (zoxide)   %F{#A277FF}cdi%f  pick from visited dirs"
  print -P "  %F{#A277FF}ll la lt%f  eza with icons/git   %F{#A277FF}fe rgf fkill mkcd extract%f   %F{#A277FF}gl gs%f"
  print -P "  %F{#A277FF}cmd G pat%f  pipe to rg   %F{#A277FF}cmd C%f  to clipboard   %F{#A277FF}ff%f  system splash"
  print -P "  %F{#A277FF}coolnight push%f · %F{#A277FF}pull%f · %F{#A277FF}status%f  sync this setup with your other Mac"
}

# ─── Smart cd & prompt ─────────────────────────────────────────────────
if (( $+commands[zoxide] )); then
  if (( ! _agent_shell )); then
    eval "$(zoxide init zsh --cmd cd)"   # `cd proj` jumps to the best match; real paths work as usual
  else
    eval "$(zoxide init zsh)"
  fi
fi
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
else                                     # plain fallback until starship is installed
  PROMPT='%F{#0FC5ED}%~%f %(?.%F{#47FF9C}.%F{#E52E2E})❯%f '
fi

# ─── This Mac only ─────────────────────────────────────────────────────
# machine-specific extras (work PATHs, tokens, nvm…) go in ~/.zshrc.local:
# this file is synced to a public repo, that one never leaves this Mac
[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local

# ─── Daily splash ──────────────────────────────────────────────────────
# fastfetch once per day, in the first interactive Ghostty shell
if [[ -o interactive && ! $_agent_shell -eq 1 && $TERM_PROGRAM == ghostty ]]; then
  zmodload zsh/datetime
  _splash=~/.cache/zsh/splash-$(strftime %F $EPOCHSECONDS)
  if [[ ! -e $_splash ]]; then
    rm -f ~/.cache/zsh/splash-*(N)
    : > $_splash
    fastfetch
  fi
  unset _splash
fi
unset _agent_shell _pkg _plugin
