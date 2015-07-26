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

} else {

echo -e "---------------------------------------------------------------------------------"
echo -e "
\033[32;40m You are already using Bananian $READABLE_VERSION \033[0m

No upgrades available...
"

} fi
