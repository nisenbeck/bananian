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
\033[32;40mThis script will upgrade your installation to Bananian 14.11 r01\033[0m
---------------------------------------------------------------------------------

The following files will be modified:
-------------------------------------
boot partition:
uImage
script.bin

root filesystem:
/lib/modules/*
/usr/local/bin/bananian-config
/usr/local/bin/soctemp
/usr/local/bin/pmutemp
/etc/motd

Important changes:
--------------------
- 0000061: [Hardware] Banana Pi will not power on after upgrade / clean flash to 14.09
- 0000033: [Kernel] Update Linux kernel to 3.4.104
- 0000042: [Kernel] Excessive VLAN logging
- 0000051: [Kernel] WiFi - setting regulatory domain
- 0000053: [Kernel] Add CONFIG_FHANDLE=y to standard BPI sun7i_defconfig
- 0000050: [Hardware] [RfE] Enable hardware watchdog
- 0000056: [Userland] soctemp/pmutemp to read out thermal sensors inside the A20 SoC and the AXP209 PMU
- 0000049: [General] [RfE] Push people aggressivly to the FAQ

For a list of all changes see our changelog:
https://dev.bananian.org/changelog_page.php?version_id=6

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
umount $TMPDIR/mnt

echo -e "---------------------------------------------------------------------------------"
echo -e "replacing files in /lib/modules... \n"
tar -xzf kernel-modules.tar.gz -C /lib/

echo -e "---------------------------------------------------------------------------------"
echo -e "upgrading software... \n"
aptitude update
aptitude upgrade
echo -e ""

echo -e "---------------------------------------------------------------------------------"
echo -e "upgrading bananian-config... \n"
mv bananian-config /usr/local/bin/bananian-config && chmod 700 /usr/local/bin/bananian-config

echo -e "---------------------------------------------------------------------------------"
echo -e "installing soctemp/pmutemp... \n"
mv soctemp /usr/local/bin/soctemp && chmod 700 /usr/local/bin/soctemp
mv pmutemp /usr/local/bin/pmutemp && chmod 700 /usr/local/bin/pmutemp

echo -e "---------------------------------------------------------------------------------"
echo -e "replacing motd... \n"
mv motd /etc/motd

echo -e "---------------------------------------------------------------------------------"
echo -e "setting new version number... \n"
echo 141101 > /etc/bananian_version

echo -e "---------------------------------------------------------------------------------"
echo -e "\033[32;40mdone! please reboot your system now! (shutdown -r now)\033[0m \n"
