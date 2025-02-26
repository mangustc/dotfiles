termux-notification-list | jq -r '.[] | select(.id == 1337).content' | grep -qF 'wake lock held' || termux-wake-lock

export XDG_RUNTIME_DIR="${TMPDIR}/xdg-runtime"
mkdir -p "${XDG_RUNTIME_DIR}"
chmod 0700 "${XDG_RUNTIME_DIR}"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export SSH_AUTH_SOCK="${TMPDIR}/ssh-agent.sock"
export PAGER="bat -p"
export MANPAGER="bat -p"
export MY_DOTFILES_DIR="${HOME}/dotfiles"
export DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/podman/podman.sock"
export CARGO_HOME="${XDG_DATA_HOME}/cargo"
export GOPATH="${XDG_DATA_HOME}/go"
export PATH="${PATH}:${HOME}/.local/bin:${GOPATH}/bin"

ssh-add -l 2>/dev/null >/dev/null
if [ $? -ge 2 ]; then
	ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null
fi
if [ -n "$PS1" ]; then
	exec fish
fi
