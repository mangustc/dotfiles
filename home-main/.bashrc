export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"

export SSH_AUTH_SOCK="/tmp/ssh-agent.sock"
export HISTFILE="${XDG_STATE_HOME}/bash/history"
export CUDA_CACHE_PATH="${XDG_CACHE_HOME}/nv"
export CARGO_HOME="${XDG_DATA_HOME}/cargo"
export GOPATH="${XDG_DATA_HOME}/go"
export NPM_CONFIG_INIT_MODULE="${XDG_CONFIG_HOME}/npm/config/npm-init.js"
export NPM_CONFIG_CACHE="${XDG_CACHE_HOME}/npm"
export NPM_CONFIG_TMP="${XDG_RUNTIME_DIR}/npm"
export XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority

export PAGER="/usr/bin/bat -p"
export MANPAGER="/usr/bin/bat -p"
export EDITOR="/usr/bin/nvim"
export VISUAL="/usr/bin/nvim"
export MY_DOTFILES_DIR="${HOME}/dotfiles"
export MY_DOTFILES_DEVICE="main"
export WM_NAME="hyprland"
export PATH="${PATH}:${HOME}/.local/bin:${GOPATH}/bin"
export DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/podman/podman.sock"
export XCURSOR_PATH="${XCURSOR_PATH}:/usr/share/icons"

if [[ $- == *i* ]]; then
	exec fish
fi
