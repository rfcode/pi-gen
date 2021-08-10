set -x

#
# Create a tarball of the extra-rootoverlay-files to be installed alongsize the 
# tarballs created by mkinstalltar.sh
#
pushd Sentry/pi-gen/
tar cfz extra-rootoverlay-files.tgz --preserve-permissions -C extra-rootoverlay-files .
popd

#
# Extract the large overlay tar file to the rootfs directory
#
#tar xfz sentry-rootfs-overlay.tar.gz --preserve-permissions --directory $ROOTFS_DIR
for tarfile in $(find Sentry/pi-gen -name "*.tgz")
do
    tar xfz $tarfile --preserve-permissions --directory $ROOTFS_DIR
done


#
# Copy the Sentry git submodule to the default location
#
mkdir -p $ROOTFS_DIR/home/sentry/GIT/Sentry
cp -R Sentry/* $ROOTFS_DIR/home/sentry/GIT/Sentry

#
# Clear some superfluous stuff (leave pyarmor-regcode-1746.txt)
#
pushd $ROOTFS_DIR/home/sentry/GIT/Sentry/pi-gen

# Delete files made by mkinstalltar.sh
rm -rf *.tgz

# Delete all dirs
find . -maxdepth 1 -type d | xargs rm -rf

popd

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
# Fix monitrc
#
chmod 600 $ROOTFS_DIR/etc/monit/monitrc

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

#
# We don't enable sentry-control until after we've put the necessary files in /data for the sentry to run
#
systemctl enable sentry-control.service

#
# Disable some services we don't need
#

# Printer service
systemctl disable cups

# Bluetooth over UART
systemctl disable hciuart

# Light dm - Desktop manager
systemctl disable lightdm

chown -R sentry:sentry /home/sentry
EOF


