#!/usr/bin/env sh
set -eu
TEMPLATE_ZIP_URL="https://japicraft.com/pack/template.zip"
show_notice() {
	echo "$1" >&2
	echo "Press Enter to continue..." >&2
	read -r _
}
prompt_choice() {
	title="$1"
	shift
	while :; do
		echo >&2
		echo "$title" >&2
		i=1
		for option in "$@"; do
			echo "  $i) $option" >&2
			i=$((i + 1))
		done
		printf "Choose an option [1-%s]: " "$#" >&2
		read -r choice
		case "$choice" in
			''|*[!0-9]*)
				echo "Please enter a number." >&2
				;;
			*)
				if [ "$choice" -ge 1 ] && [ "$choice" -le "$#" ]; then
					echo "$choice"
					return 0
				fi
				echo "Invalid choice." >&2
				;;
		esac
	done
}
resolve_script_directory() {
	if [ -f "$0" ]; then
		CDPATH= cd -- "$(dirname -- "$0")" && pwd
		return 0
	fi
	return 1
}
download_template() {
	target_zip="$1"
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL "$TEMPLATE_ZIP_URL" -o "$target_zip"
		return 0
	fi
	if command -v wget >/dev/null 2>&1; then
		wget -qO "$target_zip" "$TEMPLATE_ZIP_URL"
		return 0
	fi
	echo "Error: curl or wget is required to download the template pack." >&2
	return 1
}
find_pack_root() {
	base="$1"
	if [ -f "$base/pack.mcmeta" ]; then
		echo "$base"
		return 0
	fi
	if [ -d "$base/template" ] && [ -f "$base/template/pack.mcmeta" ]; then
		echo "$base/template"
		return 0
	fi
	for d in "$base"/*; do
		if [ -d "$d" ] && [ -f "$d/pack.mcmeta" ]; then
			echo "$d"
			return 0
		fi
	done
	return 1
}
resolve_template_pack_path() {
	script_dir=""
	if script_dir="$(resolve_script_directory 2>/dev/null)"; then
		local_template="$script_dir/template"
		if [ -f "$local_template/pack.mcmeta" ]; then
			echo "Using local template pack from: $local_template" >&2
			echo "$local_template"
			return 0
		fi
	fi
	echo "Local template pack not found. Downloading from: $TEMPLATE_ZIP_URL" >&2
	temp_root="$(mktemp -d 2>/dev/null || mktemp -d -t japicraft-pack)"
	zip_path="$temp_root/template.zip"
	extract_path="$temp_root/template-extract"
	mkdir -p "$extract_path"
	download_template "$zip_path"
	if ! command -v unzip >/dev/null 2>&1; then
		echo "Error: unzip is required to extract template.zip." >&2
		return 1
	fi
	unzip -q "$zip_path" -d "$extract_path"
	pack_root="$(find_pack_root "$extract_path" || true)"
	if [ -z "$pack_root" ]; then
		echo "Error: downloaded template archive did not contain a valid resource pack folder." >&2
		return 1
	fi
	echo "$pack_root"
}
resolve_modrinth_profiles_root() {
	for candidate in "$HOME/.config/ModrinthApp/profiles" "$HOME/.local/share/ModrinthApp/profiles" "$HOME/.config/com.modrinth.theseus/profiles"; do
		if [ -d "$candidate" ]; then
			echo "$candidate"
			return 0
		fi
	done
	return 1
}
resolve_modrinth_destination() {
	profiles_root="$(resolve_modrinth_profiles_root || true)"
	if [ -z "$profiles_root" ]; then
		show_notice "No default Modrinth profiles directory found. Returning to main menu."
		return 1
	fi
	set --
	for d in "$profiles_root"/*; do
		if [ -d "$d" ]; then
			set -- "$@" "$d"
		fi
	done
	if [ "$#" -le 0 ]; then
		show_notice "No Modrinth profiles were found in '$profiles_root'. Returning to main menu."
		return 1
	fi
	options=""
	for p in "$@"; do
		options="$options|Use profile: '$(basename "$p")'..."
	done
	options="$options|Back to main menu..."
	old_ifs="$IFS"
	IFS='|'
	# shellcheck disable=SC2086
	set -- $options
	IFS="$old_ifs"
	shift
	selection="$(prompt_choice "Choose a Modrinth profile:" "$@")"
	if [ "$selection" -eq "$#" ]; then
		return 1
	fi
	index=1
	for p in "$profiles_root"/*; do
		if [ -d "$p" ]; then
			if [ "$index" -eq "$selection" ]; then
				echo "$p/resourcepacks"
				return 0
			fi
			index=$((index + 1))
		fi
	done
	return 1
}
source_pack_path="$(resolve_template_pack_path)"
cancelled=0
destination_root=""
while :; do
	main_selection="$(prompt_choice "Template Resource Pack Installer" "Install to a Modrinth App profile..." "Install to default .minecraft folder..." "Install to a custom folder..." "Exit (Cancel)")"
	case "$main_selection" in
		1)
			destination_root="$(resolve_modrinth_destination || true)"
			if [ -z "$destination_root" ]; then
				continue
			fi
			;;
		2)
			destination_root="$HOME/.minecraft/resourcepacks"
			;;
		3)
			printf "Enter the full destination folder path (pack will be copied here): " >&2
			read -r custom_path
			if [ -z "$custom_path" ]; then
				destination_root="$(pwd)"
				show_notice "No path entered. Using current folder: $destination_root"
			else
				destination_root="$custom_path"
			fi
			;;
		4)
			cancelled=1
			break
			;;
		*)
			echo "Invalid installer selection '$main_selection'." >&2
			continue
			;;
	esac
	confirm_selection="$(prompt_choice "Confirm install destination" "Yes, install here!" "No, choose a different path..." "Cancel installation.")"
	case "$confirm_selection" in
		1)
			break
			;;
		2)
			destination_root=""
			continue
			;;
		3)
			cancelled=1
			break
			;;
		*)
			echo "Invalid confirmation selection '$confirm_selection'." >&2
			;;
	esac
done
if [ "$cancelled" -eq 1 ]; then
	echo "Installation cancelled successfully."
	exit 0
fi
mkdir -p "$destination_root"
destination_pack_path="$destination_root/$(basename "$source_pack_path")"
if [ -e "$destination_pack_path" ]; then
	rm -rf "$destination_pack_path"
fi
cp -R "$source_pack_path" "$destination_root/"
echo "Template resource pack successfully installed to: $destination_pack_path"
