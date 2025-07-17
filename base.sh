#!/usr/bin/env sh

# dotfiles dir:
# - modules/
#   - some_module/
#     - install (any executable, mainly shell scripts)
#     - packages (paru compatible package list)
#   - ...
# - base.sh
# - configuration-HOST.sh (where bash.sh should be sourced as below)
# - packages-HOST (paru compatible package list)
# - save/.../* (all logs and files from configuration update run, *created automatically*)

# Start of each configuration
# DOTFILES_HOST="your-host-name"
# DOTFILES_DIR="your-dotfiles-dir"
# cd "$(DOTFILES_DIR)"
# source ./base.sh

export save_dir="$DOTFILES_DIR/save/$(date +%Y-%m-%d_%H-%M-%S)"
export MODULE_PACKAGES=""
mkdir -p "$save_dir"
chmod -R +x $DOTFILES_DIR

errcho() {
	>&2 echo $@;
}
export -f errcho

cmd() {
	"$@"

	echo "cmd ($module_name): $@" >> "$save_dir/log"
}
export -f cmd

newscript() {
	newscript_name="$1"
	newscript_content="$2"

	newscript_tmp="/tmp/$newscript_name"
	echo "$newscript_content" > "$newscript_tmp"
	cmd sudo install -D -m 755 "$newscript_tmp" "/usr/local/bin/$newscript_name"
}
export -f newscript

writetext() {
	writetext_content="$1"

	writetext_tmp="$(mktemp "/tmp/writetext.XXXXXXX")"
	echo "$writetext_content" > "$writetext_tmp"
	echo "$writetext_tmp"
}
export -f writetext

rm_empty() {
	echo "$1" | awk 'NF'
}
export -f rm_empty

trim_pkgs_str() {
	echo "$1" | sed '/^#/d' | awk 'NF' | uniq | sort
}
trim_pkgs_file() {
	trim_pkgs_str "$(cat "$1")"
}
export -f trim_pkgs_str
export -f trim_pkgs_file

print_orphan_packages() {
	echo "Current orphan packages (not in modules, not in packages-$DOTFILES_HOST):"
	grep -v -F -x -f <(echo -e "$(cat ./packages-$DOTFILES_HOST)\n$MODULE_PACKAGES") <<< "$(paru -Qe | cut -d ' ' -f 1)"
	echo "Current overlapping packages (between packages-$DOTFILES_HOST and modules):"
	comm -12 <(echo "$(trim_pkgs_str "$MODULE_PACKAGES")") <(trim_pkgs_file ./packages-$DOTFILES_HOST)
}
export -f print_orphan_packages

install_pkgs() {
	install_pkgs_paru=""
	install_pkgs_list="$(trim_pkgs_str "$1" | grep -v -F -x -f <(echo "$(paru -Q | cut -d ' ' -f 1)"))"
	echo "$install_pkgs_list"
	if [ ! "$install_pkgs_list" = "" ]; then
		paru -S --needed --noconfirm $install_pkgs_list
	fi
}
export -f install_pkgs

config() {
	export module_name="$1"
	echo -e "\ninstalling module ${module_name}:"
	cd "$DOTFILES_DIR/modules/$module_name"
	pkgs="$(trim_pkgs_file ./packages)"
	install_pkgs "$pkgs"
	export MODULE_PACKAGES="$(trim_pkgs_str "$MODULE_PACKAGES$(echo -e "\n$pkgs")")"
	chmod +x ./install
	./install "${@:2}"
	if [ $? -eq 1 ]; then
		echo -e "FAILED TO INSTALL MODULE ${module_name}"
	else
		echo -e "successfully installed module ${module_name}"
	fi
	cd "$DOTFILES_DIR"
}
