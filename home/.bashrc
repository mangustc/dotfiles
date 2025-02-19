export XDG_RUNTIME_DIR="${HOME}/.local/runtime"
mkdir -p "${XDG_RUNTIME_DIR}"
chmod 0700 "${XDG_RUNTIME_DIR}"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.sock"
export PATH="${PATH}:${HOME}/.local/bin:${HOME}/go/bin"
export PAGER="bat -p"
export MANPAGER="bat -p"
export MY_DOTFILES_DIR="${HOME}/dotfiles"
export DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/podman/podman.sock"

if [[ $- == *i* ]]; then
	ssh-add -l 2>/dev/null >/dev/null
	if [ $? -ge 2 ]; then
		ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null
	fi
	exec fish
fi
