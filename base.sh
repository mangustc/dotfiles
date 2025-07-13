#!/usr/bin/env sh

export dotfiles_path="$(dirname "$(realpath $0)")"
export save_dir="$dotfiles_path/save/$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$save_dir"
chmod -R +x $dotfiles_path

errcho() {
	>&2 echo $@;
}
export -f errcho

fakerealpath() {
	fakerealpath_path="$1"
	fakerealpath_end=""

	if [ "$fakerealpath_path" = "" ]; then
		errcho "$fakerealpath_path should not be empty"
		return 1
	fi
	while true; do
		fakerealpath_path_temp="$(realpath $fakerealpath_path 2>/dev/null)"
		if [ $? -eq 0 ]; then
			fakerealpath_path="$fakerealpath_path_temp"
			break
		fi
		if [ "$fakerealpath_end" = "" ]; then
			fakerealpath_end="$(basename $fakerealpath_path)"
		else
			fakerealpath_end="$(basename $fakerealpath_path)/$fakerealpath_end"
		fi
		fakerealpath_path="$(dirname $fakerealpath_path)"
	done

	if [ "$fakerealpath_end" = "" ]; then
		echo "$fakerealpath_path"
	else
		echo "$fakerealpath_path/$fakerealpath_end"
	fi
}
export -f fakerealpath

requires_root() {
	current_dir="$1"

	while true; do
		owner="$(stat -c "%U" $current_dir 2>/dev/null)"
		if [ $? -eq 0 ]; then
			break
		fi
		current_dir="$(dirname $current_dir)"
	done
	if [ "$owner" = "$USER" ]; then
		echo "0"
	else
		echo "1"
	fi
}
export -f requires_root

remove() {
	remove_from="$(realpath $1 2>/dev/null)"
	if [ $? -eq 1 ] || [ ! -e "$remove_from" ]; then
		return 0
	fi

	if [ ! -d "$save_dir/$module_name" ]; then
		mkdir -p "$save_dir/$module_name"
	fi
	cp -rf "$remove_from" "$save_dir/$module_name"
	if [ "$(requires_root $remove_from)" = "1" ]; then
		sudo rm -rf "$remove_from"
		echo "remove ($module_name) [sudo]: $remove_from -> $save_dir/$module_name" >> "$save_dir/log"
	else
		rm -rf "$remove_from"
		echo "remove ($module_name): $remove_from -> $save_dir/$module_name" >> "$save_dir/log"
	fi

}
export -f remove

copy() {
	copy_from="$(realpath $1)"
	if [ $? -eq 1 ] || [ ! -e "$copy_from" ]; then
		echo "$copy_from doesn't exist"
		exit 1
	fi
	copy_to="$(fakerealpath $2)"
	if [ $? -eq 1 ]; then
		echo "error happend in getting path. aborting"
		exit 1
	fi

	if [ "$(requires_root $copy_to)" = "1" ]; then
		remove "$copy_to/$(basename $copy_from)"
		sudo mkdir -p "$copy_to"
		sudo cp -rf "$copy_from" "$copy_to"
		echo "copy ($module_name) [sudo]: $copy_from -> $copy_to" >> "$save_dir/log"
	else
		remove "$copy_to/$(basename $copy_from)"
		mkdir -p "$copy_to"
		cp -rf "$copy_from" "$copy_to"
		echo "copy ($module_name): $copy_from -> $copy_to" >> "$save_dir/log"
	fi
}
export -f copy

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
	chmod 755 "$newscript_tmp"
	copy "$newscript_tmp" /usr/local/bin
}
export -f newscript

rm_empty() {
	echo "$1" | awk 'NF'
}
export -f rm_empty

config() {
	export module_name="$1"
	echo -e "\ninstalling module ${module_name}:"
	cd "$dotfiles_path/modules/$module_name"
	if [ ! "$(cat ./packages)" = "" ]; then
		paru -S --needed --noconfirm - < ./packages
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
