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
\033[32;40mThis script will upgrade your installation to Bananian 14.09 r01\033[0m
---------------------------------------------------------------------------------

The following files will be modified:
-------------------------------------
boot partition:
uImage
script.bin
uEnv.txt

root filesystem:
/lib/modules/*
/lib/firmware/*
/etc/inittab
/etc/asound.conf
/etc/rc.local
/usr/local/bin/bananian-config
/usr/local/bin/raspi-config

Packages to be installed:
-------------------------
console-data console-setup keyboard-configuration curl cpufrequtils libnss-myhostname (+ dependencies)

Incompatible changes:
--------------------
- USB OTG port enabled. Make sure you use the 'DC in' port for power supply!
- Video acceleration engine disabled. Enable it in 'bananian-config' if needed
- ALSA default output is now HDMI (see /etc/asound.conf)

For a list of all changes see our changelog:
https://dev.bananian.org/changelog_page.php?version_id=2

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
echo -e "installing necessary software... \n"
aptitude install -y console-data console-setup keyboard-configuration curl cpufrequtils libnss-myhostname firmware-atheros firmware-brcm80211 firmware-libertas firmware-ralink firmware-realtek

echo -e "---------------------------------------------------------------------------------"
echo -e "upgrading bananian-config... \n"
mv bananian-config /usr/local/bin/bananian-config && chmod 700 /usr/local/bin/bananian-config

echo -e "---------------------------------------------------------------------------------"
echo -e "upgrading raspi-config... \n"
mv raspi-config /usr/local/bin/raspi-config && chmod 700 /usr/local/bin/raspi-config

echo -e "---------------------------------------------------------------------------------"
echo -e "enable serial console... \n"
sed -i '/enable serial console/d' /etc/inittab
sed -i '/T0:23:respawn:\/sbin\/getty -L ttyS0 115200 vt100/d' /etc/inittab
cat <<EOF >> /etc/inittab

# enable serial console
T0:23:respawn:/sbin/getty -L ttyS0 115200 vt100
EOF

echo -e "---------------------------------------------------------------------------------"
echo -e "creating alsa config (/etc/asound.conf) for HDMI sound... \n"
if [ -f /etc/asound.conf ]; then {
echo -e "\033[40;33m/etc/asound.conf exists, skipping...\033[0m \n"
} else {
cat <<EOF > /etc/asound.conf
pcm.!default {
	type hw
	card 1 # for headphone, turn 1 to 0
	device 0
}
ctl.!default {
	type hw
	card 1 # for headphone, turn 1 to 0
}
EOF
} fi

echo -e "---------------------------------------------------------------------------------"
echo -e "configuring cpufreq... \n"
sed -i '/cpu frequency/d' /etc/rc.local
sed -i '/\/sys\/devices\/system\/cpu/d' /etc/rc.local
sed -i '/^exit 0$/i \
# cpu frequency \
echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor \
echo 600000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq \
echo 1008000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq \
echo 25 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold \
echo 10 > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor \
echo 1 > /sys/devices/system/cpu/cpufreq/ondemand/io_is_busy \

' /etc/rc.local

echo -e "---------------------------------------------------------------------------------"
echo -e "setting new version number... \n"
echo 140901 > /etc/bananian_version

echo -e "---------------------------------------------------------------------------------"
echo -e "\033[32;40mdone! please reboot your system now! (shutdown -r now)\033[0m \n"
