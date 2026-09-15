#!/bin/bash
set -e

echo "=== Packaging Halium Boot Image for Nexus 6P (angler) ==="

KERNEL_IMG="${1:-arch/arm64/boot/Image.gz-dtb}"
RAMDISK_IMG="${2:-halium-ramdisk.img}"
OUTPUT_BOOT="${3:-boot-angler-plasma.img}"

if [ ! -f "$KERNEL_IMG" ]; then
    echo "Warning: Kernel image $KERNEL_IMG not found. Specify path as arg 1."
fi

# Nexus 6P (angler) fastboot parameters:
# Base: 0x00000000
# Pagesize: 4096
# Kernel Offset: 0x00008000
# Ramdisk Offset: 0x02000000
# Tags Offset: 0x01e00000
# Cmdline: console=ttyHSL0,115200,n8 androidboot.hardware=angler user_debug=31 msm_rtb.filter=0x37 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 boot_cpus=0-3

CMDLINE="console=ttyHSL0,115200,n8 androidboot.hardware=angler user_debug=31 msm_rtb.filter=0x37 ehci-hcd.park=3 lpm_levels.sleep_disabled=1"

echo "To flash via fastboot:"
echo "  fastboot flash boot $OUTPUT_BOOT"
echo "  fastboot reboot"
