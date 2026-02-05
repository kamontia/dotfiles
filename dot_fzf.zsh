# Setup fzf
# ---------
if [[ ! "$PATH" == */Users/kamo/.fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/Users/kamo/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/Users/kamo/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/Users/kamo/.fzf/shell/key-bindings.zsh"
