#!/usr/bin/env sh

export dotfiles_path="$(dirname "$(realpath $0)")"
export save_dir="$dotfiles_path/save/$(date +%Y-%m-%d_%H-%M-%S)"
export MODULE_PACKAGES=""
mkdir -p "$save_dir"
chmod -R +x $dotfiles_path

errcho() {
	>&2 echo $@;
}
export -f errcho

cmd() {
	# cmd_command="$*"

	# $cmd_command
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

_trim_pkgs() {
	echo "$1" | sed '/^#/d' | awk 'NF'
}
trim_pkgs() {
	_trim_pkgs "$(cat "$1")"
}
export -f trim_pkgs

print_orphan_packages() {
	echo "Current orphan packages (not in modules, not in packages-$DOTFILES_HOST):"
	grep -v -F -x -f <(echo -e "$(cat ./packages-$DOTFILES_HOST)\n$MODULE_PACKAGES") <<< "$(paru -Qe | cut -d ' ' -f 1)"
}
export -f print_orphan_packages

config() {
	export module_name="$1"
	echo -e "\ninstalling module ${module_name}:"
	cd "$dotfiles_path/modules/$module_name"
	pkgs="$(trim_pkgs ./packages)"
	if [ ! "$pkgs" = "" ]; then
		paru -S --needed --noconfirm $pkgs
		export MODULE_PACKAGES="$(_trim_pkgs "$MODULE_PACKAGES$(echo -e "\n$pkgs")")"
	fi
	chmod +x ./install
	./install "${@:2}"
	if [ $? -eq 1 ]; then
		echo -e "FAILED TO INSTALL MODULE ${module_name}"
	else
		echo -e "successfully installed module ${module_name}"
	fi
	cd "$dotfiles_path"
}
