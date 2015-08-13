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

DEBIAN_VERSION=$(cut -d"." -f1 /etc/debian_version)

if [ "$DEBIAN_VERSION" = "7" ]; then {
echo -e "

---------------------------------------------------------------------------------
\033[40;37mYou are using Bananian $READABLE_VERSION on Debian Wheezy\033[0m
---------------------------------------------------------------------------------

\033[40;33mBananian 15.04 was the last release based on Debian 7/Wheezy.\033[0m

Now you have two options:
-------------------------
1.) Upgrade to Debian 8/Jessie
2.) Stay at Debian 7/Wheezy

Bananian 15.08 (and later versions) will only be available for Debian 8/Jessie.
Debian 7/Wheezy is still supported and will receive kernel and security updates.

Upgrade instructions:
---------------------
1.) sed -i 's/wheezy/jessie/g' /etc/apt/sources.list
2.) apt-get update
3.) apt-get upgrade
4.) apt-get dist-upgrade
5.) shutdown -r now

More detailed instructions on debian.org:
https://www.debian.org/releases/jessie/armhf/release-notes/ch-upgrading.en.html

"

} elif [ "$DEBIAN_VERSION" = "8" ]; then {

echo -e -n "

---------------------------------------------------------------------------------
\033[40;37mYou are using Bananian $READABLE_VERSION\033[0m
\033[32;40mThis script will upgrade your installation to Bananian 15.08 r01\033[0m
---------------------------------------------------------------------------------

The following files will be modified:
-------------------------------------
boot partition:
/uImage
/boot.cmd
/boot.scr
/uEnv.* (del)

root filesystem:
/lib/modules/*
/lib/firmware/*
/usr/local/bin/bananian-config
/usr/local/bin/raspi-config
/usr/local/bin/soctemp
/usr/sbin/swconfig (del)
/usr/local/bin/swconfig (del)
/sbin/swconfig
/etc/apt/preferences.d/systemd
/etc/apt/sources.list.d/bananian.list
/etc/kernel/postinst.d/install-bananian-kernel (del)
/etc/kernel/postinst.d/bananian-kernel-postinst
/etc/kernel/postinst.d/
/etc/ssh/sshd_config
/etc/rc.local
/etc/skel/.zshrc
/root/.zshrc

Packages to be installed:
-------------------------
swconfig

Important changes:
--------------------
- 0000149: [Kernel] prepare for mainline Kernel 4.x
- 0000135: [Userland] add 15.08 release to bananian-update
- 0000146: [General] Keep SysVinit instead of systemd
- 0000134: [Userland] update Debian packages and clean up before release
- 0000127: [General] RFE: rebase Bananian to Debian 8
- 0000106: [Kernel] Request to patch Realtek driver for 8192cu / 8188cu devices
- 0000118: [Userland] package swconfig as a .deb file
- 0000145: [Network] When SSH host key generation gets interrupted SSH is broken
- 0000138: [General] create repository for jessie
- 0000144: [Security] Adjust the SSH (sshd_config) configuration for Debian Jessie
- 0000143: [General] expanding the filesystem does not work on Debian 8/Jessie
- 0000133: [Kernel] enable CONFIG_BLK_DEV_THROTTLING in the kernel
- 0000141: [Userland] Lost colors and command prompt in zsh shell after update
- 0000142: [Kernel] Update Linux Kernel to 3.4.108
- 0000136: [Userland] error handling in soctemp

For a list of all changes see our changelog:
https://dev.bananian.org/changelog_page.php?version_id=15

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
echo -e "adding/updating Bananian repository... \n"
gpg --armor --export 24BFF712 | apt-key add -
echo "deb http://dl.bananian.org/packages/ jessie main" > /etc/apt/sources.list.d/bananian.list

echo -e "---------------------------------------------------------------------------------"
echo -e "installing kernel postinst hook script... \n"
mkdir -p /etc/kernel/postinst.d
[ -f /etc/kernel/postinst.d/install-bananian-kernel ] && rm /etc/kernel/postinst.d/install-bananian-kernel
mv bananian-kernel-postinst /etc/kernel/postinst.d/bananian-kernel-postinst && chmod 755 /etc/kernel/postinst.d/bananian-kernel-postinst

echo -e "---------------------------------------------------------------------------------"
echo -e "installing kernel and modules... \n"
dpkg -i linux-image*.deb
echo -e ""

echo -e "---------------------------------------------------------------------------------"
echo -e "installing firmware... \n"
dpkg -i linux-firmware-image*.deb
echo -e ""

echo -e "---------------------------------------------------------------------------------"
echo -e "installing U-Boot... \n"
dd if=u-boot-sunxi-with-spl.bin of=/dev/mmcblk0 bs=1024 seek=8

echo -e "---------------------------------------------------------------------------------"
echo -e "updating boot configuration... \n"
mkdir ${TMPDIR}/mnt
mount /dev/mmcblk0p1 ${TMPDIR}/mnt
mv boot.cmd ${TMPDIR}/mnt
mv boot.scr ${TMPDIR}/mnt
rm -f ${TMPDIR}/mnt/uEnv.*
umount ${TMPDIR}/mnt

echo -e "---------------------------------------------------------------------------------"
echo -e "upgrading software... (Get a coffee, this might take some time.) \n"
aptitude update && aptitude upgrade
echo -e ""

echo -e "---------------------------------------------------------------------------------"
echo -e "upgrading bananian-config... \n"
mv bananian-config /usr/local/bin/bananian-config && chmod 700 /usr/local/bin/bananian-config

echo -e "---------------------------------------------------------------------------------"
echo -e "upgrading raspi-config... \n"
mv raspi-config /usr/local/bin/raspi-config && chmod 700 /usr/local/bin/raspi-config

echo -e "---------------------------------------------------------------------------------"
echo -e "Set the root filesystem label... \n"
e2label /dev/mmcblk0p2 root

echo -e "---------------------------------------------------------------------------------"
echo -e "upgrading soctemp... \n"
mv soctemp /usr/local/bin/soctemp && chmod 700 /usr/local/bin/soctemp

echo -e "---------------------------------------------------------------------------------"
echo -e "installing swconfig... \n"
rm -f /usr/sbin/swconfig
rm -f /usr/local/bin/swconfig
dpkg -i swconfig*.deb
echo -e ""

echo -e "---------------------------------------------------------------------------------"
echo -e "Updating SSH configuration... \n"
sed -i "/^HostKey \/etc\/ssh\/ssh_host_ed25519_key$/d" /etc/ssh/sshd_config
sed -i "/^HostKey \/etc\/ssh\/ssh_host_rsa_key$/a HostKey \/etc\/ssh\/ssh_host_ed25519_key" /etc/ssh/sshd_config
sed -i "s/\# https:\/\/bettercrypto.org\/ 20140809/\# https:\/\/bettercrypto.org\/ 20150712/g" /etc/ssh/sshd_config
sed -i "s/^Ciphers.*/Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes128-ctr/g" /etc/ssh/sshd_config
sed -i "s/^MACs.*/MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,hmac-ripemd160/g" /etc/ssh/sshd_config
sed -i "s/^KexAlgorithms.*/KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1/g" /etc/ssh/sshd_config

echo -e "---------------------------------------------------------------------------------"
echo -e "Generate ED25519 host key... \n"
if [ ! -s /etc/ssh/ssh_host_rsa_key ] || [ ! -s /etc/ssh/ssh_host_rsa_key.pub ] || [ ! -s /etc/ssh/ssh_host_ed25519_key ] || [ ! -s /etc/ssh/ssh_host_ed25519_key.pub ]; then
        # check for missing RSA host keys
        if [ ! -s /etc/ssh/ssh_host_rsa_key ] || [ ! -s /etc/ssh/ssh_host_rsa_key.pub ]; then
                rm -f /etc/ssh/ssh_host_rsa_key*
        fi
        # check for missing ED25519 host keys
        if [ ! -s /etc/ssh/ssh_host_ed25519_key ] || [ ! -s /etc/ssh/ssh_host_ed25519_key.pub ]; then
                rm -f /etc/ssh/ssh_host_ed25519_key*
        fi
        # (re)generate all missing keys
        dpkg-reconfigure openssh-server
fi
echo -e "---------------------------------------------------------------------------------"
echo -e "Restart SSH daemon... \n"
/etc/init.d/ssh restart

echo -e "---------------------------------------------------------------------------------"
echo -e "Adding ED25519 host key generation to /etc/rc.local... \n"
if grep -q ssh_host_ed25519_key /etc/rc.local ; then {
	echo -e "\033[40;33mOops. It seems like ED25519 host key generation is already in /etc/rc.local, skipping...\033[0m \n"
} else {
# remove old ssh host key generation code
perl -i -0pe 's/if \[ \! -(s|f) \/etc\/ssh\/ssh_host_rsa_key(.|\n)*?\nfi\n//' /etc/rc.local
# insert new ssh host key generation code
sed -i '/^\# generate new ssh host key$/a \
if [ ! -s /etc/ssh/ssh_host_rsa_key ] || [ ! -s /etc/ssh/ssh_host_rsa_key.pub ] || [ ! -s /etc/ssh/ssh_host_ed25519_key ] || [ ! -s /etc/ssh/ssh_host_ed25519_key.pub ]; then \
        # check for missing RSA host keys \
        if [ ! -s /etc/ssh/ssh_host_rsa_key ] || [ ! -s /etc/ssh/ssh_host_rsa_key.pub ]; then \
                rm -f /etc/ssh/ssh_host_rsa_key* \
        fi \
        # check for missing ED25519 host keys \
        if [ ! -s /etc/ssh/ssh_host_ed25519_key ] || [ ! -s /etc/ssh/ssh_host_ed25519_key.pub ]; then \
                rm -f /etc/ssh/ssh_host_ed25519_key* \
        fi \
        # (re)generate all missing keys \
        dpkg-reconfigure openssh-server \
fi \

' /etc/rc.local
} fi

echo -e "---------------------------------------------------------------------------------"
echo -n "Do you want to replace systemd with SysVinit (Bananian default)? (Y/n) "
read DELSYSTEMD
if [ "$DELSYSTEMD" != "n" ]; then {
	apt-get install -y sysvinit-core sysvinit sysvinit-utils && mv removesystemd_once /etc/init.d/removesystemd_once && chmod 700 /etc/init.d/removesystemd_once && update-rc.d removesystemd_once defaults && echo -e 'Package: systemd\nPin: origin ""\nPin-Priority: -1' > /etc/apt/preferences.d/systemd && echo -e '\n\nPackage: *systemd*\nPin: origin ""\nPin-Priority: -1' >> /etc/apt/preferences.d/systemd
	echo -e ""
	echo -e "systemd will be removed on next reboot... \n"
} fi

echo -e "---------------------------------------------------------------------------------"
echo -e "configuring z-shell (zsh)... \n"
cp zshrc /etc/skel/.zshrc
mv zshrc /root/.zshrc

echo -e "---------------------------------------------------------------------------------"
echo -e "setting new version number... \n"
echo 150801 > /etc/bananian_version

echo -e "---------------------------------------------------------------------------------"
echo -e "\033[32;40mdone! please reboot your system now! (shutdown -r now)\033[0m \n"

} else {

echo -e "
---------------------------------------------------------------------------------
\033[40;37mYou are using Bananian $READABLE_VERSION \033[0m
---------------------------------------------------------------------------------

Your Debian version is unknown/not supported.
Please make sure /etc/debian_version contains the correct version number.
"
} fi
