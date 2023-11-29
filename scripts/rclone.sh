#!/usr/bin/env bash
set -uo pipefail

# Remotes are created in the rclone config
# EXAMPLE: ~/.config/rclone/rclone.conf
# [warpsys-catalog-warehouse]
# type = s3
# provider = DigitalOcean
# env_auth = false
# endpoint = nyc3.digitaloceanspaces.com
# acl = public-read
# bucket_acl = private
# access_key_id = <ACCESS_KEY_ID>
# secret_access_key = <ACCESS_KEY>

REMOTE='warpsys-catalog-warehouse:'
SPACE='warpsys/mirror/'
CATALOG_DIR="${HOME}/.warphome/catalogs/warpsys/"
WAREHOUSE_DIR="$(git rev-parse --show-toplevel)/.warehouse/"
set -x
rclone -v copy "$WAREHOUSE_DIR" "${REMOTE}${SPACE}"

