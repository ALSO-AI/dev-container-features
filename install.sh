#!/bin/bash
set -e

# The install.sh script is the installation entrypoint for any dev container 'features' in this repository. 
#
# The tooling will parse the devcontainer-features.json + user devcontainer, and write 
# any build-time arguments into a feature-set scoped "devcontainer-features.env"
# The author is free to source that file and use it however they would like.
set -a
. ./devcontainer-features.env
set +a

USERNAME=${2:-"automatic"}

# If in automatic mode, determine if a user already exists, if not use vscode
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in ${POSSIBLE_USERS[@]}; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=vscode
    fi
elif [ "${USERNAME}" = "none" ]; then
    USERNAME=root
    USER_UID=0
    USER_GID=0
fi

# ** Shell customization section **
if [ "${USERNAME}" = "root" ]; then 
    user_rc_path="/root"
else
    user_rc_path="/home/${USERNAME}"
fi

oh_my_plugins_dir="${user_rc_path}/.oh-my-zsh/custom/plugins"
user_rc_file="${user_rc_path}/.zshrc"

plugin() { sed -i -E "s/^(plugins=\(.+)\)$/\1 $1)/" "${user_rc_file}"; }

plug() {
    git clone "https://github.com/$1/$2.git" "${oh_my_plugins_dir}/$2" 2>&1
    plugin $2
}

if [ ! -z ${_BUILD_ARG_OMZPLUGINS} ]; then
    echo "Activating feature 'omzplugins'"
    plugin dotnet
    plug zdharma-continuum fast-syntax-highlighting
    plug zsh-users zsh-autosuggestions
fi
