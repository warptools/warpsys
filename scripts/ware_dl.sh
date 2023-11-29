#!/usr/bin/env bash
# mirrors wares from a catalog locally with rio
# checks for wares in mirrors files and in releases
#
# example
# ./scripts/ware_dl_by_ware.sh 'ca+file://.warehouse'
#
# ignores git wares because those aren't going to be mirrored with the s3 object store
set -uo pipefail

readonly DEFAULT_WAREHOUSE='ca+file://.warehouse'
readonly WAREHOUSE="${1:-$DEFAULT_WAREHOUSE}"
readonly CATALOG_DIR="${HOME}/.warphome/catalogs/warpsys/"
readonly DEFAULT_REMOTE='ca+https://warpsys-wares.s3.fr-par.scw.cloud'

readonly MIRROR_RAW_JSON=$(find "$CATALOG_DIR" -wholename '*/_mirrors.json' | xargs jq '.[].byWare?')
readonly MIRROR_JOINED_JSON=$(jq <<< "$MIRROR_RAW_JSON" -s '[map(select(. != null)) | .[] | to_entries[]] | group_by(.key) | map({key: .[0].key, value: [.[].value] | add}) | from_entries')

ware_ids_by_ware() {
  local -r WARES=$(jq <<< "$MIRROR_JOINED_JSON" -r 'keys[]')
  echo "$WARES"
}

remote_by_ware() {
  local -r WAREID=${1}
  # Currently only get the first available remote and try that. Most of these will only have one mirror anyway.
  local -r REMOTE=$(jq <<< "$MIRROR_JOINED_JSON" -r --arg key "$WAREID" '.[$key][0] | select( startswith("git") | not )' )
  echo "$REMOTE"
}

ware_ids_releases() {
  local -r WARES=$(find "$CATALOG_DIR" -wholename '*/_releases/*.json' | xargs jq -r '.items[] | select( startswith("git") | not )' )
  echo "$WARES"
}

download() {
  local -r WARES=${1}
  local WAREID
  local REMOTE
  for WAREID in $WARES; do
    REMOTE=$(remote_by_ware $WAREID)
    if [[ $REMOTE == "null" ]] || [[ -z $REMOTE ]]; then
      # We check remote by ware but ignore module remotes
      # Currently we just use one remote for all modules so a default remote covers all other cases.
      REMOTE=$DEFAULT_REMOTE
    fi
    >&2 echo rio mirror --source="$REMOTE" --target="$WAREHOUSE" "$WAREID"
  done
}

# !!! UNCOMMENT LINES TO CHANGE BEHAVIOR
 
# >&2 echo releases
# ware_ids_releases

# >&2 echo mirrors by ware
# ware_ids_by_ware

download "$(ware_ids_by_ware)"
download "$(ware_ids_releases)"

