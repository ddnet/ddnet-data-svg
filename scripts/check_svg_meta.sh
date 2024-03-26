#!/bin/bash

num_errors=0
num_warnings=0
arg_fix=0

error() {
	printf '[-] ERROR: %s\n' "$1" 1>&2
	num_errors="$((num_errors+1))"
}

warning() {
	printf '[-] WARNING: %s\n' "$1" 1>&2
	num_warnings="$((num_warnings+1))"
}

for arg in "$@"
do
	if [ "$arg" == "--help" ] || [ "$arg" == "-h" ] || [ "$arg" == "help" ]
	then
		echo "usage: $(tput bold)$(basename "$0") [OPTION]$(tput sgr0)"
		echo "options:"
		echo "  --help|-h       show this help"
		echo "  --fix|-f        automatically fix files"
		exit 0
	elif [ "$arg" == "--fix" ] || [ "$arg" == "-f" ]
	then
		arg_fix=1
	else
		echo "unkown option $arg try --help"
		exit 1
	fi
done

# prefix your keys with dot
# this is a wrapper around jq
xml_get_key() {
	local key="$1"
	local file="$2"
	if yq --version | grep -qF 'https://github.com/mikefarah/yq'
	then
		yq -r -p xml -o json "$key" "$file"
	else
		local potential_keys
		[[ "$key" =~ ^\.svg\[[\"\']\+@(.*)[\"\']\]$ ]] && key="${BASH_REMATCH[1]}"
		potential_keys="$(grep -F "$key=" "$file")"
		local num_matches
		num_matches="$(printf '%s' "$potential_keys" | wc -l)"
		if [ "$num_matches" -lt 2 ] && [ "$potential_keys" != "" ]
		then
			printf '%s' "$potential_keys" | cut -d'"' -f2
			return
		fi

		local grep_safe_key
		grep_safe_key="$(printf '%s' "$key" | grep -o '[a-ZA-Z0-9]')"
		potential_keys="$(printf '%s' "$potential_keys" | grep "^[[:space:]]*$grep_safe_key")"
		num_matches="$(printf '%s' "$potential_keys" | wc -l)"
		if [ "$num_matches" = 0 ]
		then
			printf null
			return
		fi
		printf '%s' "$potential_keys" | head -n1 | cut -d'"' -f2
	fi
}

check_meta_filename_match() {
	local file="$1"
	local expected_filename
	expected_filename="$(basename "$file")"
	local actual_filename
	if ! actual_filename="$(xml_get_key '.svg["+@sodipodi:docname"]' "$file")"
	then
		error "failed to get meta filename of $file"
		exit 1
	fi
	[ "$actual_filename" = null ] && return

	if [ "$actual_filename" != "$expected_filename" ]
	then
		warning "svg docname does not match filename in $file"
		printf '\n    expected: "%s"' "$expected_filename" 1>&2
		printf '\n         got: "%s"\n\n' "$actual_filename" 1>&2
	fi
}

check_absolute_path() {
	local file="$1"
	if [ "$arg_fix" == "1" ]
	then
		sed -i -r '/export-filename="([A-Z]:|\/)/d' "$file"
		return
	fi
	while IFS= read -r line
	do
		error "absolute export path found in $file:$(echo "$line" | cut -d':' -f1)"
	done < <(grep -nE 'export-filename="([A-Z]:\\|/)' "$file")
}

check_width_height() {
	local file="$1"
	width_found=$(grep -Eiwzo "<svg[^>]*>" "$file" | tr '\0' '\n' | grep -Eo "width=\"([0-9.]|px)*\"")
	height_found=$(grep -Eiwzo "<svg[^>]*>" "$file" | tr '\0' '\n' | grep -Eo "height=\"([0-9.]|px)*\"")

	if [[ "$width_found" == "" || "$height_found" == "" ]]
	then
		error "no width or height parameter found in $file"
	fi
	if grep -qF 'xlink:href="data:image/png;base64,' "$file"
	then
		error "embedded image found $file"
	fi
}

while IFS= read -r file
do
	check_absolute_path "$file"
	check_meta_filename_match "$file"
	check_width_height "$file"
done < <(find . -type f -name "*.svg")

if [ "$num_errors" -ne "0" ]
then
	echo "[-] failed ($num_errors errors)"
	exit 1
fi
if [ "$num_warnings" -ne "0" ]
then
	echo "[!] finished ($num_warnings warnings)"
	exit 0
fi

echo "[+] done"

