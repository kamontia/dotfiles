# # Environment
# export GOPATH=$HOME/repo
# export PATH=$PATH:$GOPATH/bin:/usr/local/go/bin
# export PATH=/usr/local/opt/coreutils/libexec/gnubin:$PATH
# 
# # Two regular plugins loaded without tracking.
# zplugin light zsh-users/zsh-autosuggestions
# zplugin light zdharma/fast-syntax-highlighting
# 
# # Plugin history-search-multi-word loaded with tracking.
# ice wait'!0' zplugin load zdharma/history-search-multi-word
# 
# # Load the pure theme, with zsh-async library that's bundled with it.
# zplugin ice pick"async.zsh" src"pure.zsh"
# zplugin light sindresorhus/pure
# 
# zplugin ice wait"!0" atinit"zpcompinit; zpcdreplay -q"
# 

## 実行したプロセスの消費時間が3秒以上かかったら
## 自動的に消費時間の統計情報を表示する。
REPORTTIME=3

# ls に色をつける
zstyle ':completion:*' list-colors "${LS_COLORS}" # 補完候補のカラー表示
PROMPT="%F{009}%n@%m: %f%k"
autoload -U compinit
compinit

export LSCOLORS=exfxcxdxbxegedabagacad
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'

alias ls="ls --color"
alias ll="ls -alh --color"

zstyle ':completion:*' list-colors 'di=34' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'

# funciton
function select-history() {
    local tac
    if which tac > /dev/null; then
        tac="tac"
    else
        tac="tail -r"
    fi
    BUFFER=$(fc -l -n 1 | eval $tac | peco --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle -R -c
}
zle -N select-history
bindkey '^r' select-history


# alias
alias gf="git show-branch | grep '*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -1 | awk -F'[]~^[]' '{print $2}'"
alias g='cd $(ghq root)/$(ghq list | peco)'
alias pvim='vim $(find . -type f | peco)'
alias pcat='bat $(find . -type f | peco)'
alias pcd='cd $(find . -type f | peco | xargs dirname )'
alias b='hub browse'
alias gitroot='cd-gitroot'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# move git root
function git-root() {
  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    cd `pwd`/`git rev-parse --show-cdup`
  fi
}

# anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"
eval "$(nodenv init -)"

# thefuck
eval $(thefuck --alias)

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing DHARMA Initiative Plugin Manager (zdharma/zinit)…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f" || \
        print -P "%F{160}▓▒░ The clone has failed.%f"
fi
source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit installer's chunk

# Environment
export GOPATH=$HOME/repo
export PATH=$PATH:$GOPATH/bin:/usr/local/go/bin
export PATH=/usr/local/opt/coreutils/libexec/gnubin:$PATH

# Two regular plugins loaded without tracking.
zplugin light zsh-users/zsh-autosuggestions
zplugin light zdharma/fast-syntax-highlighting
zplugin load momo-lab/zsh-abbrev-alias

# Plugin history-search-multi-word loaded with tracking.
zplugin ice wait'!0' zplugin load zdharma/history-search-multi-word

# Load the pure theme, with zsh-async library that's bundled with it.
zplugin ice pick"async.zsh" src"pure.zsh"
zplugin light sindresorhus/pure

zplugin ice wait"!0" atinit"zpcompinit; zpcdreplay -q"

