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
export XAUTHORITY="${XDG_RUNTIME_DIR}/Xauthority"

export PAGER="/usr/bin/nvimpager -p"
export MANPAGER="/usr/bin/nvimpager -p"
export EDITOR="/usr/bin/nvim"
export VISUAL="/usr/bin/nvim"
export MY_DOTFILES_DIR="${HOME}/dotfiles"
export MY_DOTFILES_DEVICE="gaming"
export VIRT_BASE_DOMAIN="win-passthrough"
export VIRT_USB_DEVICES="${HOME}/virt/usb.json"
export WM_NAME="kde"
export WM_ARGS="wayland"
export PATH="${PATH}:${HOME}/.local/bin:${HOME}/go/bin"
export LIBVIRT_DEFAULT_URI="qemu:///system"

if [[ $- == *i* ]]; then
	exec fish
fi
