#/bin/bash

# The MIT License (MIT)
#
# Copyright (c) 2015 Nico Isenbeck <contact@bananian.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

echo -e -n "

---------------------------------------------------------------------------------
\033[40;37mYou are using Bananian $READABLE_VERSION\033[0m
\033[32;40mThis script will upgrade your installation to Bananian 15.04 r01\033[0m
---------------------------------------------------------------------------------

The following files will be modified:
-------------------------------------
boot partition:
/uImage
/script.bin
/fex/*

root filesystem:
/lib/modules/*
/lib/firmware/*
/usr/local/bin/bananian-config
/usr/local/bin/bananian-update
/etc/rsyslog.conf
/etc/apt/sources.list.d/bananian.list
/etc/kernel/postinst.d/install-bananian-kernel
/etc/zsh/zshrc
/etc/skel/.zshrc

Packages to be installed:
-------------------------
fake-hwclock

Important changes:
--------------------
- 0000122: [Userland] zsh configuration
- 0000121: [Userland] set BANANIAN_PLATFORM variable in bananian-update
- 0000103: [Kernel] Missing headers for 3.4.x kernel
- 0000119: [Hardware] support Banana Pi M1+
- 0000100: [General] ttyS4 und usbc0 overlapping in fex
- 0000038: [General] Attempt to change keyboard layout through bananian-config on an headless installation fails silently
- 0000045: [General] rsyslog: do not sync to the disk immediately
- 0000114: [Userland] add the Bananian repository to sources.list
- 0000097: [General] Bananian-update throws ssl-error (wrong date/time)
- 0000113: [Hardware] add support for Orange Pi
- 0000098: [Hardware] BPi-R1: Power on SATA not sufficient for HDD
- 0000111: [Kernel] ft5x_ts: Touchscreen does not work reliable (i2c)
- 0000112: [Kernel] merge LeMaker kernel sources

For a list of all changes see our changelog:
https://dev.bananian.org/changelog_page.php?version_id=7

\033[0;31mDo you want to continue (yes/no)?\033[0m "
read start_upgrade

echo -e ""
if [ "$start_upgrade" != "yes" ]; then {
	echo -e "---------------------------------------------------------------------------------"
	echo -e "\033[40;31mupgrade canceled by user...\033[0m \n"
        rm -rf $TMPDIR
	exit
} fi

echo -e "---------------------------------------------------------------------------------"
echo -e "replacing files on mmcblk0p1... \n"
mkdir $TMPDIR/mnt
mount /dev/mmcblk0p1 $TMPDIR/mnt
tar -xzf mmcblk0p1.tar.gz -C $TMPDIR/mnt
[ -f $TMPDIR/mnt/fex/BananaPi/script.bin.otg-off ]  && rm $TMPDIR/mnt/fex/BananaPi/script.bin.otg-off
[ -f $TMPDIR/mnt/fex/BananaPi/script.bin.otg-on ]   && rm $TMPDIR/mnt/fex/BananaPi/script.bin.otg-on
[ -f $TMPDIR/mnt/fex/BananaPro/script.bin.otg-off ] && rm $TMPDIR/mnt/fex/BananaPro/script.bin.otg-off
[ -f $TMPDIR/mnt/fex/BananaPro/script.bin.otg-on ]  && rm $TMPDIR/mnt/fex/BananaPro/script.bin.otg-on
## workaround for 0000121: set BANANIAN_PLATFORM variable in bananian-update
[ -f /etc/bananian_platform ] && BANANIAN_PLATFORM=$(cat /etc/bananian_platform) || BANANIAN_PLATFORM="BananaPi"
##
[ -f $TMPDIR/mnt/fex/$BANANIAN_PLATFORM/script.bin ] && cp $TMPDIR/mnt/fex/$BANANIAN_PLATFORM/script.bin $TMPDIR/mnt/script.bin || echo -e "\033[40;33munknown hardware configuration. Skipping script.bin...\033[0m \n"
umount $TMPDIR/mnt

echo -e "---------------------------------------------------------------------------------"
echo -e "installing kernel postinst hook script... \n"
mkdir -p /etc/kernel/postinst.d
mv bananian-kernel-postinst /etc/kernel/postinst.d/install-bananian-kernel && chmod 755 /etc/kernel/postinst.d/install-bananian-kernel

echo -e "---------------------------------------------------------------------------------"
echo -e "installing kernel and modules... \n"
dpkg -i linux-image*.deb
echo -e ""

echo -e "---------------------------------------------------------------------------------"
echo -e "installing firmware... \n"
dpkg -i linux-firmware-image*.deb
echo -e ""

echo -e "---------------------------------------------------------------------------------"
echo -e "upgrading software... (Get a coffee, this might take some time.) \n"
aptitude update && aptitude upgrade
echo -e ""

echo -e "---------------------------------------------------------------------------------"
echo -e "installing necessary software... \n"
aptitude install -y fake-hwclock

echo -e "---------------------------------------------------------------------------------"
echo -e "upgrading bananian-config... \n"
mv bananian-config /usr/local/bin/bananian-config && chmod 700 /usr/local/bin/bananian-config

echo -e "---------------------------------------------------------------------------------"
echo -e "upgrading bananian-update... \n"
mv bananian-update /usr/local/bin/bananian-update && chmod 700 /usr/local/bin/bananian-update

echo -e "---------------------------------------------------------------------------------"
echo -e "replacing /etc/rsyslog.conf... \n"
RSYSLOGCONF=$(sha256sum /etc/rsyslog.conf | awk -F ' ' '{print $1}')
if [ "$RSYSLOGCONF" = "b470dff47ec015510e737432b41fbbc138f7171378cf42458036229bc101c119" ]; then {
	mv rsyslog.conf /etc/rsyslog.conf
} else {
	echo -e "\033[40;33munknown rsyslog.conf. Skipping...\033[0m \n"
} fi

echo -e "---------------------------------------------------------------------------------"
echo -e "adding Bananian repository... \n"
gpg --armor --export 24BFF712 | apt-key add -
echo "deb http://dl.bananian.org/packages/ wheezy main" > /etc/apt/sources.list.d/bananian.list

echo -e "---------------------------------------------------------------------------------"
echo -e "configuring z-shell (zsh)... \n"
touch /etc/skel/.zshrc
mv zshrc /etc/zsh/zshrc
echo "The file /root/.zshrc is no longer required and can be cleared."
echo -n "Do you want to continue? (Y/n) "
read DELZSHCONFIG
if [ "$DELZSHCONFIG" != "n" ]; then {
	echo > /root/.zshrc
} fi

echo -e "---------------------------------------------------------------------------------"
echo -e "setting new version number... \n"
echo 150401 > /etc/bananian_version

echo -e "---------------------------------------------------------------------------------"
echo -e "\033[32;40mdone! please reboot your system now! (shutdown -r now)\033[0m \n"
