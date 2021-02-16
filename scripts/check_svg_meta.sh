#!/bin/bash

err=0
arg_fix=0

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

while IFS= read -r file
do
    if [ "$arg_fix" == "1" ]
    then
        sed -i -r '/export-filename="([A-Z]:|\/)/d' "$file"
        continue
    fi
    while IFS= read -r line
    do
        printf "[-] ERROR: absolute export path found in %s:%d\\n" \
            "$file" \
            "$(echo "$line" | cut -d':' -f1)"
        err="$((err+1))"
    done < <(grep -nE 'export-filename="([A-Z]:\\|/)' "$file")
done < <(find . -type f -name "*.svg")

if [ "$err" -ne "0" ]
then
    echo "[-] failed ($err errors)"
    exit 1
fi

echo "[+] done"

