#--------------------------------------------------------------------------------------------------------------------------------
# Boot loader script to boot with different boot methods for old and new kernel
# Credits: https://github.com/igorpecovnik - Thank you for this great script!
#--------------------------------------------------------------------------------------------------------------------------------
if load mmc 0:1 0x00000000 uImage-next
then
# mainline kernel >= 4.x
#--------------------------------------------------------------------------------------------------------------------------------
setenv bootargs console=ttyS0,115200 console=tty0 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait
load mmc 0:1 0x49000000 dtb/${fdtfile}
load mmc 0:1 0x46000000 uImage-next
bootm 0x46000000 - 0x49000000
#--------------------------------------------------------------------------------------------------------------------------------
else
# sunxi 3.4.x
#--------------------------------------------------------------------------------------------------------------------------------
setenv bootargs console=ttyS0,115200 console=tty0 console=tty1 sunxi_g2d_mem_reserve=0 sunxi_ve_mem_reserve=0 hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1680x1050p60 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait
setenv bootm_boot_mode sec
load mmc 0:1 0x43000000 script.bin
load mmc 0:1 0x48000000 uImage
bootm 0x48000000
#--------------------------------------------------------------------------------------------------------------------------------
fi
