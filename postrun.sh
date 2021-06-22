echo "postrun.sh start"
echo "Making swupdate images..."

DEPLOY_NAME=$DEPLOY_DIR/$IMG_FILENAME
DEPLOY_IMG=$DEPLOY_NAME.img

echo
echo "DEPLOY_IMG=$DEPLOY_IMG"
echo

#
# Get partition info from deploy image
#
FDISK_LINE=$(sudo fdisk -lu $DEPLOY_IMG | grep ".img2")
echo "FDISK_LINE=$FDISK_LINE"

read -a fdisk_array <<< "$FDISK_LINE"

OFFSET=${fdisk_array[1]}
SIZE=${fdisk_array[3]}

echo "OFFSET=$OFFSET"
echo "SIZE=$SIZE"

ROOTFS_IMG=$DEPLOY_NAME-rootfs.ext4

sudo dd if=$DEPLOY_IMG of=swupdate-rootfs.img skip=$OFFSET count=$SIZE status=progress

PRODUCT_NAME="sentry"
FILES="sw-description swupdate-rootfs.img"

for filename in $FILES;do
    echo $filename;done | cpio -ov -H crc >  $DEPLOY_DIR/${PRODUCT_NAME}.swu

echo "postrun.sh done"
