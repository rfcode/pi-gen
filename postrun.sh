#!/bin/bash -e
set -x

echo "postrun.sh ENTER"
RFC_VERSION=0.9

source stage7/EXPORT_IMAGE
IMG_UTC_SECONDS=$(date --utc +%s)
IMG_UTC_STR=$(date --date @$IMG_UTC_SECONDS +"%Y%02m%02dT%H%M%SZ")
IMG_DEPLOY=$DEPLOY_DIR/${IMG_FILENAME}${IMG_SUFFIX}.img

POST_DEPLOY_DIR=${DEPLOY_DIR}/${IMG_UTC_STR}
IMG_SDCARD=$POST_DEPLOY_DIR/$RFC_VERSION.$IMG_UTC_STR-${IMG_FILENAME}${IMG_SUFFIX}.img
IMG_ROOTFS_FILE=$RFC_VERSION.$IMG_UTC_STR-${IMG_FILENAME}-rootfs.img
TGZ_UPGRADE_FILE=$RFC_VERSION.$IMG_UTC_STR-${IMG_FILENAME}-upgrade.tgz
TARBALL_DIR=$POST_DEPLOY_DIR/tarball
export IMG_ROOTFS_DEPLOY=$TARBALL_DIR/$IMG_ROOTFS_FILE


echo "Image: $IMG_DEPLOY"
echo "Image UTC: $IMG_UTC_STR - $IMG_UTC_SECONDS"


#
# Move the built img file to a subdir with the build date on it
#
mkdir -p $TARBALL_DIR

# Delete older images 
#pushd $DEPLOY_DIR
#find . -maxdepth 1 -type d ! -name "${IMG_UTC_STR}" | xargs rm -rf
#popd

mv $IMG_DEPLOY $IMG_SDCARD

#
# Write manifest.json
#

MANIFEST_JSON=$(jq --null-input \
    --arg rootfs "$IMG_ROOTFS_FILE" \
    --arg build_time_utc_seconds "$IMG_UTC_SECONDS" \
    --arg build_time_utc "$IMG_UTC_STR" \
    '{ "rootfs": $rootfs, "build_time_utc_seconds": $build_time_utc_seconds, "build_time_utc" : "$build_time_utc" }' \
)


echo "$MANIFEST_JSON" > $TARBALL_DIR/manifest.json

#
# Read the fdisk info line for .img2 into ROOTFS_INFO_ARR
#
ROOTFS_INFO=$(fdisk -lu $IMG_SDCARD | grep ".img2")
read -a ROOTFS_INFO_ARR <<< "$ROOTFS_INFO"

ROOTFS_START="${ROOTFS_INFO_ARR[1]}"
ROOTFS_SIZE="${ROOTFS_INFO_ARR[3]}"

echo "Start: $ROOTFS_START"
echo "Size: $ROOTFS_SIZE"

#
# Use dd to extract the rootfs partition
#
dd if=$IMG_SDCARD of=$IMG_ROOTFS_DEPLOY skip=$ROOTFS_START count=$ROOTFS_SIZE status=progress

#
# The partition size of the rootfs image generated by the build continues to increase as new files are added.
# This can cause the firmware upgrade to fail if the size of the rootfs pushes past the alignment boundary
# as compared to the first time the sdcard was flashed.  Here we limit the partition size to the current size
# generated as of 8/4/2021 (just before alpha release).
#
# Sectors are 512 bytes
#
#ALPHA_RELEASE_ROOTFS_SIZE_SECTORS=10003721
#ALPHA_RELEASE_ROOTFS_SIZE_SECTORS=9798921
ALPHA_RELEASE_ROOTFS_SIZE_SECTORS=9561456

#
# Have to run this to clean up the fs first
#
e2fsck -p $IMG_ROOTFS_DEPLOY

#
# Force the resize2fs since it makes an overly cautious calculation about what the minimum size needs to be
#
resize2fs -f $IMG_ROOTFS_DEPLOY ${ALPHA_RELEASE_ROOTFS_SIZE_SECTORS}s

NEW_ROOTFS_END=$((ROOTFS_START+$ALPHA_RELEASE_ROOTFS_SIZE_SECTORS))

#
# Re-create partition 2 of the sdcard img file to be the new length
#
printf "unit s\n"   > parted.cmd
printf "print\n"    >> parted.cmd
printf "rm 2\n"     >> parted.cmd
printf "print\n"    >> parted.cmd
printf "mkpart primary ext4 $ROOTFS_START $NEW_ROOTFS_END\n"     >> parted.cmd
printf "print\n"    >> parted.cmd
 
parted $IMG_SDCARD < parted.cmd

#
# Now dd the resized rootfs img file to the sdcard img
#
dd if=$IMG_ROOTFS_DEPLOY of=$IMG_SDCARD seek=$ROOTFS_START status=progress

# 
# Change dir to TARBALL_DIR and create the tar gzipped rootfs upgrade file
#
tar cfz $POST_DEPLOY_DIR/$TGZ_UPGRADE_FILE -C $TARBALL_DIR .

#
# Erase the extra tarball dir and leave just the sdcard image and compress tarball
#
rm -rf $TARBALL_DIR

echo "postrun.sh EXIT"
