export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.sock"
export XDG_CACHE_HOME="$HOME/.cache";
export XDG_CONFIG_HOME="$HOME/.config";
export XDG_DATA_HOME="$HOME/.local/share";
export XDG_STATE_HOME="$HOME/.local/state";
export PATH="$PATH:$HOME/.local/bin"
export HISTFILE="$XDG_STATE_HOME/bash/history";
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv";
export CARGO_HOME="$XDG_DATA_HOME/cargo";
export GOPATH="$XDG_DATA_HOME/go";
export NPM_CONFIG_INIT_MODULE="$XDG_CONFIG_HOME/npm/config/npm-init.js";
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm";
export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR/npm";
export EDITOR="nvim"

[[ $- != *i* ]] && return

if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && -z ${BASH_EXECUTION_STRING} && ${SHLVL} == 1 ]]
then
	shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''
	exec fish $LOGIN_OPTION
fi

