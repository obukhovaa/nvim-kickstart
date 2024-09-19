# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set default edtor to nvim
export ZVM_VI_EDITOR="nvim"
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export KUBE_EDITOR="nvim"
export EDITOR="nvim"

export ZVM_VI_HIGHLIGHT_FOREGROUND="white"
export ZVM_VI_HIGHLIGHT_BACKGROUND="blue"
export ZVM_VI_HIGHLIGHT_EXTRASTYLE="bold"

# zsh-vi-mode will auto execute this zvm_after_init function
# required to fix fzf key binds
# function zvm_after_init() {
#   [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# }

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="clean"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	git
	aws
	zsh-vi-mode
	zsh-syntax-highlighting
	zsh-autosuggestions
	fzf
	z
	zsh-interactive-cd
	kubectl
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

function kdig {
	local is_minimal=true
	if [ ! -z "$3" ]; then
		if [ "$3" -eq "-d" -o "$3" -eq "--deep" ]; then 
			is_minimal=false
		fi
	fi

	local target_pods="$(kubectl -n $1 get pods | grep "$2")"
	local pod_name="$(awk '{ print $1;exit;}' <<< $target_pods)"
	echo "uploading tools to $pod_name ..."
	kubectl cp ~/.config/nvim/install.sh "$1"/"$pod_name":/tmp/install.sh
	echo "connecting to $pod_name"
	if [ "$is_minimal" = true ]; then
		kubectl -n "$1" exec -ti $pod_name -- sh -c 'export IS_MINIMAL=true && cd /tmp && chmod +x install.sh && ./install.sh'
	else
		kubectl -n "$1" exec -ti $pod_name -- sh /tmp/install.sh
	fi
}

function kexec { 
	local target_pods="$(kubectl -n $1 get pods | grep "$2")"
	local pod_name="$(awk '{ print $1;exit;}' <<< $target_pods)"
	echo "connecting to $pod_name"
	kubectl -n "$1" exec -ti $pod_name -- sh
}

function kpods { 
	while true; do
		local pods="$(kubectl -n $1 get pods | grep "$2")"
		echo "$(date +"%H:%M")\n$pods\n..."
		sleep 10
	done
}

function ksvc { 
	while true; do
		local svcs="$(kubectl -n $1 get svc | grep "$2")"
		echo "$(date +"%H:%M")\n$svcs\n..."
		sleep 10
	done
}

function klog {
	if [ -z "$2" ]
	then
		echo "deployment is not provided"
		return 1
	fi
	
	kubectl -n "$1" logs -f "$(kubectl -n $1 get pods | grep $2 | awk '{print $1; exit;}')"
}

function encrypt_pwd() {
	openssl enc -in "$1" -aes-256-cbc -p -pass stdin -out "$1.sec"
}

function decrypt_pwd() {
	local in="$1"
	openssl enc -in "$in" -aes-256-cbc -d -pass stdin -out ${in%$'.sec'}
}


bindkey "\e\eOD" backward-word 
bindkey "\e\eOC" forward-word
bindkey "^[^[[D" backward-word
bindkey "^[^[[C" forward-word
