#!/bin/bash --posix

error_code=0

if ! command -v inkscape &> /dev/null
then
    echo "inkscape could not be found, please install it to continue"
    exit 1
fi

if [[ -z ${1+x} || $1 -lt 1920 ]]; then
	error_code=$((1 | error_code))
fi

if [[ -z ${2+x} || $2 -lt 1080 ]]; then
	error_code=$((2 | error_code))
fi

if [[ -z ${3+x} ]]; then
	error_code=$((4 | error_code))
fi

if [[ $error_code != 0 ]]; then
	if [[ $((error_code&1)) -ne 0 ]]; then
		echo "target resolution width not found or less than 1920"
	fi
	if [[ $((error_code&2)) -ne 0 ]]; then
		echo "target resolution height not found or less than 1080"
	fi
	echo "usage: build.sh <target_resolution_width> <target_resolution_height> <svg_source_dir>"
	exit 1
fi

res_width=$1
res_height=$2
source_dir=$3

bash_script_dir=$(dirname "$0")
cur_dir=$PWD

num_cores() {
	if [ -x "$(command -v nproc)" ]
	then
		nproc
	elif [ -x "$(command -v sysctl)" ]
	then
		sysctl -n hw.logicalcpu
	else
		echo 1
	fi
}

cd "$source_dir" || { echo "Error: invalid directory '$source_dir'"; exit 1; }

while IFS= read -r -d '' svg; do
	mkdir -p "$cur_dir/$(dirname "$svg")"
done < <(find . -name '*.svg' -type f -print0)

find . -name "*.svg" -type f -print0 | \
sed -z "p;s#\(.*\)\.svg#$cur_dir/\1\.png#" | \
xargs -0 -n 2 -P "$(num_cores)" "$cur_dir/$bash_script_dir/build_single.sh" "$res_width" "$res_height"
echo "done"
