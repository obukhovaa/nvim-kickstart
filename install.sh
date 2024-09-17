#!/bin/sh

use_complete_setup="${USE_COMPLETE_NVIM_SETUP:-false}"
export USE_COMPLETE_NVIM_SETUP="$use_complete_setup"

has_apk=false
has_apt=false
pkg_manager=""
add_cmd=""
make_pkg="build-base"

if command -v apk; then
    has_apk=true
fi

if command -v apt; then
    has_apt=true
fi

if [ "$has_apk" = false -a "$has_apt" = false ]; then
    echo "apk or apt has to be installed on the host"
    exit 1
elif [ "$has_apk" = true ]; then
    pkg_manager="apk"
    add_cmd="add"
else
    pkg_manager="apt"
    add_cmd="install -y"
    make_pkg="build-essential"
fi
$pkg_manager update

# skip heavy binaries, mainly required to build telescope-fzf-native
if use_complete_setup = true; then
    if ! command -v make; then
        echo "make could not be found, installing"
        $pkg_manager $add_cmd $make_pkg
    fi
fi

if ! command -v tmux; then
    echo "tmux could not be found, installing"
    $pkg_manager $add_cmd tmux
fi

if ! command -v git; then
    echo "git could not be found, installing"
    $pkg_manager $add_cmd git
fi

if ! command -v curl; then
    echo "curl could not be found, installing"
    $pkg_manager $add_cmd curl
fi

if ! command -v nvim; then
    echo "nvim could not be found, installing"
    $pkg_manager $add_cmd neovim
fi

if ! command -v rg; then
    echo "ripgrep could not be found, installing"
    $pkg_manager $add_cmd ripgrep
fi

if ! command -v fzf; then
    echo "fzf could not be found, installing"
    $pkg_manager $add_cmd fzf
fi

if [ ! -d "$HOME/.config/nvim" ]; then
    echo "$HOME/.config/nvim doesn't exist, creating and cloning..."
    mkdir -p "$HOME/.config"
    cd "$HOME/.config"
    git clone https://github.com/obukhovaa/nvim-kickstart.git nvim
fi

cd "$HOME/.config"
cp nvim/tmux/.tmux.conf "$HOME/.tmux.conf"
cp nvim/tmux/.tmux.conf.local "$HOME/.tmux.conf.local"
cp nvim/zsh/.zshrc "$HOME/.zshrc"

if ! command -v zsh; then
    echo "zsh could not be found, installing"
    $pkg_manager $add_cmd zsh
    chsh -s $(which zsh)
    KEEP_ZSHRC=yes RUNZSH=no sh -c '$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)'
    git clone https://github.com/jeffreytse/zsh-vi-mode ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-vi-mode
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

tmux new -s remote 'zsh'
nvim .