#!/bin/bash

err=0

while IFS= read -r file
do
    while IFS= read -r line
    do
        printf "[-] ERROR: absolute export path found in %s:%d\n" \
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

