export SSH_AUTH_SOCK="/tmp/ssh-agent.sock"
export PATH="${PATH}:${HOME}/.local/bin:${HOME}/go/bin"
export PAGER="bat"
export MY_DOTFILES_DIR="${HOME}/dotfiles"

# export SESSION_ENV="/tmp/session.env"
# if [ ! -f ${SESSION_ENV} ]; then
# 	printenv >${SESSION_ENV}
# 	chmod 600 ${SESSION_ENV}
# fi

[[ -f ~/.bashrc ]] && . ~/.bashrc
