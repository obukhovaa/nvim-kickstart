#!/bin/sh

use_complete_setup="${USE_COMPLETE_NVIM_SETUP:-false}"
export USE_COMPLETE_NVIM_SETUP="$use_complete_setup"

has_apk=false
has_apt=false
pkg_manager=""
add_cmd=""

if command -v apk &>/dev/null; then
    echo "YES"
    has_apk=true
fi

if command -v apt &>/dev/null; then
    echo "NO"
    has_apt=true
fi

if [ "$has_apk" = false -a "$has_apt" = false ]; then
    echo "apk or apt has to be installed on the host"
    exit 1
elif [ "$has_apk" = true ]; then
    pkg_manager="apk"
    add_cmd="add"
    # add gcc, usually it is missing on alpine
    apk add build-base
else
    pkg_manager="apt"
    add_cmd="install"
fi
$pkg_manager update

if ! command -v git &>/dev/null; then
    echo "git could not be found, installing"
    $pkg_manager $add_cmd git
fi

if ! command -v nvim &>/dev/null; then
    echo "nvim could not be found, installing"
    $pkg_manager $add_cmd neovim
fi

if [ ! -d "$HOME/.config/nvim" ]; then
    echo "$HOME/.config/nvim doesn't exist, creating and cloning..."
    mkdir -p "$HOME/.config"
    cd "$HOME/.config"
    git clone https://github.com/obukhovaa/nvim-kickstart.git nvim
fi

echo "done; use nvim to start"
