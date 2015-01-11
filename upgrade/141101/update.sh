#/bin/bash

# The MIT License (MIT)
#
# Copyright (c) 2014 Nico Isenbeck <contact@bananian.org>
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
\033[32;40mThis script will upgrade your installation to Bananian 15.01 r01\033[0m
---------------------------------------------------------------------------------

The following files will be deleted:
-------------------------------------
/script.bin.otg-off
/script.bin.otg-on

The following files will be modified:
-------------------------------------
boot partition:
/uImage
/fex/*

root filesystem:
/lib/modules/*
/lib/firmware/*
/usr/local/bin/bananian-config
/usr/local/bin/bananian-hardware
/usr/local/bin/fexc
/usr/local/bin/bin2fex
/usr/local/bin/fex2bin
/usr/local/bin/swconfig
/etc/modules
/etc/network/if-pre-up.d/swconfig

Packages to be installed:
-------------------------
wireless-tools wpasupplicant iw usbutils (+ dependencies)

Important changes:
--------------------
- 0000047: [Network] some packages for WLAN missing
- 0000044: [Userland] install usbutils by default
- 0000091: [Userland] update Debian packages and clean up before release
- 0000090: [Userland] add 15.01 release to bananian-update
- 0000082: [Network] Wlan Support for Banana Pro
- 0000083: [Hardware] support BPI-R1 hardware
- 0000084: [General] add hardware configuration to bananian-config
- 0000060: [General] Include bin2fex and fex2bin

For a list of all changes see our changelog:
https://dev.bananian.org/changelog_page.php?version_id=11

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
[ -f $TMPDIR/mnt/script.bin.otg-off ] && rm $TMPDIR/mnt/script.bin.otg-off
[ -f $TMPDIR/mnt/script.bin.otg-on ] && rm $TMPDIR/mnt/script.bin.otg-on
tar -xzf mmcblk0p1.tar.gz -C $TMPDIR/mnt
umount $TMPDIR/mnt

echo -e "---------------------------------------------------------------------------------"
echo -e "replacing files in /lib/modules... \n"
tar -xzf kernel-modules.tar.gz -C /lib/

echo -e "---------------------------------------------------------------------------------"
echo -e "replacing files in /lib/firmware... \n"
tar -xzf kernel-firmware.tar.gz -C /lib/

echo -e "---------------------------------------------------------------------------------"
echo -e "upgrading software... (Get a coffee, this might take some time.) \n"
aptitude update
aptitude upgrade
echo -e ""

echo -e "---------------------------------------------------------------------------------"
echo -e "installing necessary software... \n"
aptitude install -y wireless-tools wpasupplicant iw usbutils

echo -e "---------------------------------------------------------------------------------"
echo -e "upgrading bananian-config... \n"
mv bananian-config /usr/local/bin/bananian-config && chmod 700 /usr/local/bin/bananian-config

echo -e "---------------------------------------------------------------------------------"
echo -e "installing bananian-hardware... \n"
mv bananian-hardware /usr/local/bin/bananian-hardware && chmod 700 /usr/local/bin/bananian-hardware

echo -e "---------------------------------------------------------------------------------"
echo -e "installing fexc (bin2fex/fex2bin)... \n"
mv fexc /usr/local/bin/fexc && chmod 755 /usr/local/bin/fexc
[ ! -f /usr/local/bin/bin2fex ] && ln -s /usr/local/bin/fexc /usr/local/bin/bin2fex
[ ! -f /usr/local/bin/fex2bin ] && ln -s /usr/local/bin/fexc /usr/local/bin/fex2bin

echo -e "---------------------------------------------------------------------------------"
echo -e "installing swconfig... \n"
mv swconfig /usr/local/bin/swconfig && chmod 700 /usr/local/bin/swconfig
[ -f /usr/sbin/swconfig ] && rm /usr/sbin/swconfig
ln -s /usr/local/bin/swconfig /usr/sbin/swconfig
[ ! -f /etc/network/if-pre-up.d/swconfig ] && mv pre-up-swconfig /etc/network/if-pre-up.d/swconfig
chmod 755 /etc/network/if-pre-up.d/swconfig

echo -e "---------------------------------------------------------------------------------"
echo -e "enabling VLAN (8021q) module... \n"
sed -i '/VLAN support for BPI-R1/d' /etc/modules
sed -i '/8021q/d' /etc/modules
cat <<EOF >> /etc/modules

# VLAN support for BPI-R1
8021q
EOF

echo -e "---------------------------------------------------------------------------------"
echo -e "setting new version number... \n"
echo 150101 > /etc/bananian_version

echo -e "---------------------------------------------------------------------------------"
echo -e "\033[32;40mdone! please reboot your system now! (shutdown -r now)\033[0m \n"
