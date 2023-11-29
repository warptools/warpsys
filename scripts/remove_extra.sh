#!/usr/bin/env bash
set -euo pipefail
CONFIG='./.s3cfg'
BUCKET='s3://warpsys/mirror'
BUCKET_LS_FILE='bucket_ls'
WARE_ID_FILE='ware_ids'
# uncomment to refresh bucket data
# s3cmd -c "$CONFIG" ls --recursive "$BUCKET" > $BUCKET_LS_FILE

BUCKET_HASH=$(column < "${BUCKET_LS_FILE}" --table-columns=date,time,size,object -J | jq -r .table[].object | cut -d/ -f6 | sort) 
>&2 echo "BUCKET_HASH"
>&2 echo "$BUCKET_HASH"

WARE_HASH=$(cut < "${WARE_ID_FILE}" -d\: -f2)
>&2 echo 'WARE_HASH'
>&2 echo "$WARE_HASH"
set -x
EXTRA_HASH=$(diff <(echo "$WARE_HASH") <(echo "$BUCKET_HASH") | grep '>' | cut -d\  -f3)
>&2 echo "EXTRA_HASH"
>&2 echo "$EXTRA_HASH"
if [[ -z "$EXTRA_HASH" ]]; then 
    >&2 echo 'no extras to remove'
     exit 0
fi

REMOVE_OBJ=$(grep -F -f <(echo "$EXTRA_HASH") "$BUCKET_LS_FILE" | column -t -o$'\t' | cut -d$'\t' -f4)
>&2 echo "REMOVE_OBJ"
>&2 echo "$REMOVE_OBJ"

>&2 echo 'result'
for line in $REMOVE_OBJ; do
    echo "s3cmd -c ${CONFIG} del ${line}"
done
