set -x

#
# Extract the large overlay tar file to the rootfs directory
#
tar xfz sentry-rootfs-overlay.tar.gz --preserve-permissions --directory $ROOTFS_DIR

#
# Copy the Sentry git submodule to the default location
#
mkdir -p $ROOTFS_DIR/home/sentry/GIT/Sentry
cp -R Sentry/* $ROOTFS_DIR/home/sentry/GIT/Sentry

#
# Fixup cmdline.txt
#
CMDLINE=`cat $ROOTFS_DIR/boot/cmdline.txt`
echo "BEFORE cmdline.txt: $CMDLINE"

sed -i 's|quiet ||' $ROOTFS_DIR/boot/cmdline.txt
#sed -i 's|splash ||' $ROOTFS_DIR/boot/cmdline.txt
sed -i 's|init=/usr/lib/raspi-config/init_resize.sh ||' $ROOTFS_DIR/boot/cmdline.txt

CMDLINE=`cat $ROOTFS_DIR/boot/cmdline.txt`
echo "AFTER cmdline.txt: $CMDLINE"

#
# Remove the resize2fs_once from init.d, we don't resize the rootfs for Sentry, we resize the /data directory
# This is done in extra-rootoverlay-files/etc/Sentry/resize2fs_data.sh (run as a service at bootup)
#
rm $ROOTFS_DIR/etc/init.d/resize2fs_once

#
# Make an array of all the files in the extra rootoverlay files
#
EXTRA_FILES_DIR="Sentry/pi-gen/extra-rootoverlay-files/"
readarray -t extra_files < <(find $EXTRA_FILES_DIR -type f)

#
# Install each file
#
for file in "${extra_files[@]}"
do
    dest_dir="$(dirname `echo $file | cut -d'/' -f4-`)"
    mkdir -p $ROOTFS_DIR/$dest_dir
    echo "install -m 744 $file --target-directory=$ROOTFS_DIR/$dest_dir"
    install -m 744 $file --target-directory=$ROOTFS_DIR/$dest_dir
done

#
# Make mount points
#
mkdir -p $ROOTFS_DIR/mnt/usb
mkdir -p $ROOTFS_DIR/data


#
# Enable services to run at bootup
#
on_chroot << EOF
systemctl enable sentry-fixup.service
systemctl enable sentry-control.service
chown -R sentry:sentry /home/sentry
EOF


