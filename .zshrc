# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...



if type "nvim" >/dev/null 2>&1; then
    alias vim='nvim' 
fi

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
export PATH="$HOME/.anyenv/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export PATH="$HOME/.anyenv/bin:$PATH"
export GOPATH="${HOME}/repo"
export PATH="$PATH:$GOPATH/bin"

eval "$(anyenv init - zsh)"
eval "$(pyenv virtualenv-init - zsh)"
eval "$(nodenv init - zsh)"
export GOENV_DISABLE_GOPATH=1
eval "$(goenv init - zsh)"

### Alias
alias g='cd $(ghq root)/$(ghq list | fzf)'

if [ "$(uname)" = "Darwin" ]; then
  alias ls='ls -G'
  alias ll='ls -G -l'
  alias la='ls -G -la'
else
  alias ls='ls --color'
  alias ll='ls --color -l'
  alias la='ls --color -la'
fi
export PATH="$HOME/.anyenv/bin:$PATH"
