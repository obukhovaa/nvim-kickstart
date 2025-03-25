export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export KUBE_EDITOR="nvim"
export EDITOR="nvim"
export USE_COMPLETE_NVIM_SETUP="true"

export PATH="/opt/homebrew/opt/php@7.4/bin:$PATH"
export PATH="/opt/homebrew/opt/php@7.4/sbin:$PATH"
export PATH="/usr/local/opt/python/libexec/bin:$PATH"
export PATH="/usr/local/opt/go/libexec/bin:$PATH"

export JAVA_8_HOME=$(/usr/libexec/java_home -v1.8)
export JAVA_11_HOME=$(/usr/libexec/java_home -v11)
export JAVA_17_HOME=$(/usr/libexec/java_home -v17)
export JAVA_21_HOME=$(/usr/libexec/java_home -v21)

alias java8='export JAVA_HOME=$JAVA_8_HOME'
alias java11='export JAVA_HOME=$JAVA_11_HOME'
alias java17='export JAVA_HOME=$JAVA_17_HOME'
alias java21='export JAVA_HOME=$JAVA_21_HOME'

# default to Java 21
java21

# Piano
source /Users/nouwa/piano-bash-env/load.sh
source /Users/nouwa/Development/piano-aws-sso/scripts/login.sh

# Zsh toolkit
source ~/.zshrc
eval "$(/opt/homebrew/bin/brew shellenv)"

# Added by Toolbox App
export PATH="$PATH:/usr/local/bin"

# For gitlab scripts
source ~/.gitlab/.env

# For openai scripts
source ~/.openai/.env

# GO tools
export PATH="$PATH:$HOME/go/bin"

# RUST tools
export PATH="$PATH:$HOME/.cargo/env"

# Python to use
alias python=/opt/homebrew/bin/python3
alias pip=/opt/homebrew/bin/pip3

# Aider and python tooling
export PATH="$PATH:/Users/nouwa/.local/bin"

# NVIM tooling
export PATH="$PATH:/Users/nouwa/.local/share/nvim/mason/bin"
