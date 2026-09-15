#!/usr/bin/env bash
# ==============================================================================
# build-kernel.sh: Cross-compilation pipeline for Nexus 6P (angler) Halium Kernel
# Target Architecture: aarch64 (Snapdragon 810 / MSM8994)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_ROOT="${SCRIPT_DIR}/../kernel"
SRC_DIR="${KERNEL_ROOT}/source"
OUT_DIR="${KERNEL_ROOT}/out"
DEFCONFIG_FRAGMENT="${KERNEL_ROOT}/halium_angler_defconfig_fragment"

# Default toolchain config (adjust if using custom cross compiler)
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"

# Number of parallel compilation jobs
THREADS="$(nproc)"

echo "========================================================="
echo "   Building Nexus 6P (angler) Kernel for Plasma Mobile   "
echo "========================================================="
echo "ARCH:          ${ARCH}"
echo "CROSS_COMPILE: ${CROSS_COMPILE}"
echo "Jobs:          ${THREADS}"

# 1. Clone kernel source if not already present
if [ ! -d "${SRC_DIR}" ]; then
    echo "Cloning LineageOS 15.1 angler kernel source..."
    git clone --depth 1 -b lineage-15.1 https://github.com/LineageOS/android_kernel_huawei_angler "${SRC_DIR}"
fi

mkdir -p "${OUT_DIR}"

cd "${SRC_DIR}"

# 2. Generate baseline angler defconfig
echo "Generating base angler_defconfig..."
make O="${OUT_DIR}" angler_defconfig

# 3. Merge Halium container & libhybris configuration fragment
if [ -f "${DEFCONFIG_FRAGMENT}" ]; then
    echo "Merging Halium defconfig fragment..."
    if [ -f "${SRC_DIR}/scripts/kconfig/merge_config.sh" ]; then
        ARCH="${ARCH}" "${SRC_DIR}/scripts/kconfig/merge_config.sh" -m -O "${OUT_DIR}" "${OUT_DIR}/.config" "${DEFCONFIG_FRAGMENT}"
        make O="${OUT_DIR}" olddefconfig
    else
        cat "${DEFCONFIG_FRAGMENT}" >> "${OUT_DIR}/.config"
        make O="${OUT_DIR}" olddefconfig
    fi
fi

# 4. Compile the kernel and dtb
echo "Compiling kernel (Image.gz-dtb)..."
make -j"${THREADS}" O="${OUT_DIR}" Image.gz-dtb

echo ""
echo "=== Kernel Build Succeeded ==="
echo "Output image: ${OUT_DIR}/arch/arm64/boot/Image.gz-dtb"
