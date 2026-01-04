export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export KUBE_EDITOR="vim"
export EDITOR="vim"
export USE_COMPLETE_NVIM_SETUP="false"

export JAVA_8_HOME=$(/usr/libexec/java_home -v1.8)
export JAVA_11_HOME=$(/usr/libexec/java_home -v11)
export JAVA_17_HOME=$(/usr/libexec/java_home -v17)
export JAVA_21_HOME=$(/usr/libexec/java_home -v21)

alias java8='export JAVA_HOME=$JAVA_8_HOME'
alias java11='export JAVA_HOME=$JAVA_11_HOME'
alias java17='export JAVA_HOME=$JAVA_17_HOME'
alias java21='export JAVA_HOME=$JAVA_21_HOME'

# default to Java 21
# java21

source ~/.zshrc
eval "$(/opt/homebrew/bin/brew shellenv)"

# Added by Toolbox App
export PATH="$PATH:/usr/local/bin"

# For gitlab scripts
source ~/.gitlab/.env

# For teamcity scripts
source ~/.teamcity/.c2

# For open ai scripts
source ~/.openai/.env

# For Atlassian scripts
source ~/.atlassian/.env

# For Figma scripts
source ~/.figma/.env

# For Figma scripts
source ~/.metabase/.env

# GO tools
export PATH="$PATH:$HOME/go/bin"

# RUST tools
export PATH="$PATH:$HOME/.cargo/env"
