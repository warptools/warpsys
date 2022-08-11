set -euxo pipefail

# temp directory to store rootfs while building
TMPDIR=/tmp/rootfs

# debian/ubuntu mirror to use
# for debian mirrors on ubuntu, install keys with: `apt-get install debian-keyring debian-archive-keyring`
MIRROR='https://mirrors.wikimedia.org/debian'

# suite (or release) to use
SUITE=bullseye

# packages to install
PKGS='bash binutils binutils-dev bison build-essential bzip2 coreutils diffutils findutils gawk gcc g++ grep gzip m4 make patch perl python3 python3-dev sed tar texinfo xz-utils'

# this value is used as the timestamp for building the rootfs
# for a given value, this will create a repeatable build
# this needs to be exported for mmdebstrap
export SOURCE_DATE_EPOCH=1646092800

# create the warehouse in case it doesn't exist
mkdir -p ../../.warpforge/warehouse

# delete the existing rootfs, in case it exists
rm -rf $TMPDIR

# mmbootstrap the rootfs
./mmdebstrap/mmdebstrap --variant=minbase --include="$PKGS" $SUITE $TMPDIR "$MIRROR"

# chown all rootfs files to the current user so we can `rio pack` it
sudo chown -R $USER $TMPDIR

# delete all __pycache__ dirs, because they are non-deterministic
find $TMPDIR -type d -name __pycache__ -exec rm -rf {} +

# pack the rootfs into the warpsys root workspace's warehouse
mkdir -p ../../.warpforge/warehouse
rio pack --target=ca+file://../../.warpforge/warehouse --filters=uid=0,gid=0,setid=ignore,mtime=@$SOURCE_DATE_EPOCH tar $TMPDIR

# delete the temp dir
rm -rf $TMPDIR
