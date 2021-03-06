# DO NOT EDIT THIS FILE
#
# Please edit /boot/orangepiEnv.txt to set supported parameters
#

# default values
setenv load_addr "0x45000000"
setenv rootdev "/dev/mmcblk0p1"
setenv verbosity "1"
setenv rootfstype "ext4"
setenv console "both"
setenv docker_optimizations "off"
setenv bootlogo "false"
setenv emmc_max_frequency "50000000"

# Print boot source
itest.b *0x10028 == 0x00 && echo "U-boot loaded from SD"
itest.b *0x10028 == 0x02 && echo "U-boot loaded from eMMC or secondary SD"
itest.b *0x10028 == 0x03 && echo "U-boot loaded from SPI"

echo "Boot script loaded from ${devtype}"

if test -e ${devtype} ${devnum} ${prefix}orangepiEnv.txt; then
	load ${devtype} ${devnum} ${load_addr} ${prefix}orangepiEnv.txt
	env import -t ${load_addr} ${filesize}
fi

if test "${console}" = "display" || test "${console}" = "both"; then setenv consoleargs "console=ttyS0,115200 console=tty1"; fi
if test "${console}" = "serial"; then setenv consoleargs "console=ttyS0,115200"; fi
if test "${bootlogo}" = "true"; then setenv consoleargs "bootsplash.bootfile=bootsplash.orangepi ${consoleargs}"; fi

# get PARTUUID of first partition on SD/eMMC it was loaded from
# mmc 0 is always mapped to device u-boot (2016.09+) was loaded from
if test "${devtype}" = "mmc"; then part uuid mmc 0:1 partuuid; fi

setenv bootargs "root=${rootdev} rootwait rootfstype=${rootfstype} ${consoleargs} consoleblank=0 loglevel=${verbosity} ubootpart=${partuuid} disp_reserve=${disp_reserve} ${extraargs} ${extraboardargs}"

if test "${docker_optimizations}" = "on"; then setenv bootargs "${bootargs} cgroup_enable=memory swapaccount=1"; fi

fdt get value emmc_status /soc/sdmmc@04022000 status

load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}
fdt addr ${fdt_addr_r}
fdt resize 65536

fdt set /soc/disp@01000000 boot_fb0 ${boot_fb0}
fdt set /soc/disp@01000000 boot_disp <${boot_disp}>
fdt set /soc/disp@01000000 boot_disp1 <${boot_disp1}>
fdt set /soc/disp@01000000 boot_disp2 <${boot_disp2}>
fdt set /soc/disp@01000000 fb0_width <${fb0_width}>
fdt set /soc/disp@01000000 fb0_height <${fb0_height}>

# Orange Pi 3 without eMMC needs to turn off sdc2
fdt set /soc/sdmmc@04022000 status ${emmc_status}
fdt set /soc/sdmmc@04022000 max-frequency <${emmc_max_frequency}>

fdt addr -c ${fdt_addr_r}

load ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}uInitrd
load ${devtype} ${devnum} ${kernel_addr_r} ${prefix}uImage

bootm ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}

# Recompile with:
# mkimage -C none -A arm -T script -d /boot/boot.cmd /boot/boot.scr
