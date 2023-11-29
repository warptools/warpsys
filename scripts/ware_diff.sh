#!/bin/bash
if [ "$#" -ne 2 ]; then
    >&2 echo "Usage: $0 file_with_paths file_with_expected_filenames"
    >&2 echo ''
    >&2 echo 'Returns ware hashes not in list of paths.'
    >&2 echo 'Used to find wares missing from a warehouse.'
    >&2 echo 'Example:'
    >&2 echo 'cut -d: -f2 < ./ware_ids > ./ware_hashes'
    >&2 echo 'find .warehouse -type f > ./ware_paths'
    >&2 echo "$0 ./ware_paths ./ware_hashes"
    exit 1
fi

readonly file_with_paths="$1"
readonly file_with_expected_filenames="$2"

if [ ! -f "$file_with_paths" ] || [ ! -f "$file_with_expected_filenames" ]; then
    >&2 echo "Error: Both files must exist."
    exit 1
fi

readonly FILES=$(cat "${file_with_paths}" | xargs -I_ basename _ | sort | uniq)
diff <(cat "${file_with_expected_filenames}" | sort | uniq) <(echo "$FILES") | grep '^[<>]'
