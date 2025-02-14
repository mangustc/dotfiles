export XDG_RUNTIME_DIR="/run/user/1000"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export SSH_AUTH_SOCK="/tmp/ssh-agent.sock"
export PATH="${PATH}:${HOME}/.local/bin:${HOME}/go/bin"
export PAGER="bat"
export MY_DOTFILES_DIR="${HOME}/dotfiles"
export SVDIR="${HOME}/.local/runsvdir"
export DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/podman/podman.sock"
export XCURSOR_PATH="${XCURSOR_PATH}:/usr/share/icons"

export SESSION_ENV="/tmp/session.env"
if [ ! -f ${SESSION_ENV} ]; then
	printenv >${SESSION_ENV}
	chmod 600 ${SESSION_ENV}
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc
