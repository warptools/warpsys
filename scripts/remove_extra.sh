#!/usr/bin/env bash
set -euo pipefail
CONFIG='./.s3cfg'
BUCKET='s3://warpsys/warehouse'
BUCKET_LS_FILE='bucket_ls'
WARE_ID_FILE='ware_ids'
# uncomment to refresh bucket data
# s3cmd -c "$CONFIG" ls --recursive "$BUCKET" > $BUCKET_LS_FILE

OBJ_PATHS=$(column -t -o$'\t' < "${BUCKET_LS_FILE}" | cut -d$'\t' -f4 | sort)
OBJ_HASH=$(echo "$OBJ_PATHS" | xargs -I_ basename _ | sort)
>&2 printf 'OBJECTS: %d\n' $(echo "$OBJ_HASH" | grep -v '^$' | wc -l)


WARE_HASH=$(cut < "${WARE_ID_FILE}" -d\: -f2)
>&2 printf 'WARES: %d\n' $(echo "$WARE_HASH" | grep -v '^$' | wc -l)

EXTRA_HASH=$(comm -13 <(echo "$WARE_HASH") <(echo "$OBJ_HASH"))
>&2 printf 'EXTRA OBJECTS: %d\n' $(echo "$EXTRA_HASH" | grep -v '^$' | wc -l)
if [[ -z "$EXTRA_HASH" ]]; then 
    >&2 echo 'no extras to remove'
     exit 0
fi

REMOVE_OBJ=$(grep -F -f <(echo "$EXTRA_HASH") <(echo "$") | column -t -o$'\t' | cut -d$'\t' -f4)
>&2 echo "REMOVE_OBJ"
>&2 echo "$REMOVE_OBJ"

>&2 echo 'result'
for line in $REMOVE_OBJ; do
    echo "s3cmd -c ${CONFIG} del ${line}"
done
