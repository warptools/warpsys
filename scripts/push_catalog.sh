#!/bin/bash
set -euo pipefail

# This is a rather basic script for pushing the catalog site and wares to S3
# buckets.
# It requires a few things to work:
#   - The AWS CLI tool to perform `aws s3 sync`
#   - Configured AWS credentials
#
# The script uses the AWS profile "warpsys-site" to push the site and
# "warpsys-wares" to push the wares. These need to be configured in
# `~/.aws/config` and `~/.aws/credentials`.
#
# This script must be run from within the warpsys folder, to ensure warpsys'
# root workspace is used.

# get the location of the warpsys workspace, using this script's location
workspace_dir=$(dirname $0)/../.warpforge

# generate html
warpforge catalog generate-html --url-prefix=/ \
	  --download-url=https://warpsys-wares.s3.fr-par.scw.cloud

# push html, deleting any files that no longer exist
html_dir=$workspace_dir/catalogs/default/_html
aws --profile=warpsys-site s3 sync --delete $html_dir s3://catalog.warpsys.org

# push wares
warehouse_dir=$workspace_dir/warehouse
aws --profile=warpsys-wares s3 sync $warehouse_dir s3://warpsys-wares
