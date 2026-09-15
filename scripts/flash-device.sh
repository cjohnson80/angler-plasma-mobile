#!/usr/bin/env bash
# ==============================================================================
# flash-device.sh: Automated fastboot flashing script for Nexus 6P (angler)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOT_IMG="${1:-${SCRIPT_DIR}/../boot-angler-plasma.img}"

echo "========================================================="
echo "   Fastboot Flashing Pipeline for Nexus 6P (angler)     "
echo "========================================================="

# 1. Verify fastboot binary
if ! command -v fastboot >/dev/null 2>&1; then
    echo "Error: 'fastboot' command not found in PATH."
    echo "Install android-tools (pacman -S android-tools / apt install android-tools-fastboot)."
    exit 1
fi

# 2. Check for device in fastboot mode
echo "Checking connected fastboot devices..."
DEVICE="$(fastboot devices | head -n 1 | awk '{print $1}')"

if [ -z "$DEVICE" ]; then
    echo "No device detected in fastboot mode."
    echo "Please boot the Nexus 6P into fastboot mode (Hold Volume Down + Power) and connect USB."
    exit 1
fi

echo "Connected device: ${DEVICE}"

# 3. Flash boot image
if [ -f "$BOOT_IMG" ]; then
    echo "Flashing boot partition with ${BOOT_IMG}..."
    fastboot flash boot "${BOOT_IMG}"
else
    echo "Warning: Boot image ${BOOT_IMG} not found. Skipping boot flash."
fi

echo "Flashing finished."
echo "To boot into system run: fastboot reboot"
