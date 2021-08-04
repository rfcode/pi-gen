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
TGZ_ROOTFS_FILE=$RFC_VERSION.$IMG_UTC_STR-${IMG_FILENAME}-rootfs.tgz
TARBALL_DIR=$POST_DEPLOY_DIR/tarball
export IMG_ROOTFS_DEPLOY=$TARBALL_DIR/$IMG_ROOTFS_FILE


echo "Image: $IMG_DEPLOY"
echo "Image UTC: $IMG_UTC_STR - $IMG_UTC_SECONDS"

#
# Move the built img file to a subdir with the build date on it
#
mkdir -p $TARBALL_DIR
mv $IMG_DEPLOY $IMG_SDCARD

#
# Write manifest.json
#
echo -e "{\n  'rootfs' : '$IMG_ROOTFS_FILE',\n  'build_time_utc_seconds' : $IMG_UTC_SECONDS,\n  'build_time_utc' : '$IMG_UTC_STR'\n}" > $TARBALL_DIR/manifest.json

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
# Change dir to TARBALL_DIR and create the tar gzipped rootfs upgrade file
#
tar cfz $POST_DEPLOY_DIR/$TGZ_ROOTFS_FILE -C $TARBALL_DIR .

echo "postrun.sh EXIT"
