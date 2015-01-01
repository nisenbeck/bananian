#!/bin/bash
# This script is used to compile 'swconfig' for the BPI-R1 based on the OpenWrt sources.
# Big thanks to mattrix and x4711 from the LeMaker forum who discovered this procedure.

apt-get update
apt-get install -y liblua5.1-0-dev cmake lua5.1 git
git clone https://github.com/Bananian/openwrt.git

cp openwrt/target/linux/generic/files/include/uapi/linux/switch.h /usr/include/linux/switch.h
chmod 644 /usr/include/linux/switch.h

ln -s openwrt/package/network/config/swconfig/src swconfig
ln -s openwrt/package/libs/libnl-tiny libnl-tiny
SRCDIR=`pwd`

cd $SRCDIR/libnl-tiny/src
make
rm libnl-tiny.so
ar rcs libnl-tiny.a nl.o handlers.o msg.o attr.o cache.o cache_mngt.o object.o socket.o error.o genl.o genl_family.o genl_ctrl.o genl_mngt.o unl.o

cd $SRCDIR/swconfig
CFLAGS="-I $SRCDIR/libnl-tiny/src/include -D_GNU_SOURCE" LDFLAGS="-L $SRCDIR/libnl-tiny/src" make
cc -L $SRCDIR/libnl-tiny/src -o swconfig cli.o swlib.o -lnl-tiny -ldl
