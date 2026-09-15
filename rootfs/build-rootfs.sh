#!/usr/bin/env bash
# ==============================================================================
# build-rootfs.sh: Bootstrap Arch Linux ARM64 Root Filesystem with Halium/libhybris
# Target: Huawei Nexus 6P (angler) - MSM8994
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/build"
ROOTFS_DIR="${WORK_DIR}/rootfs"
ARCH_TARBALL="ArchLinuxARM-aarch64-latest.tar.gz"
ARCH_URL="http://os.archlinuxarm.org/os/${ARCH_TARBALL}"

echo "=== [1/6] Preparing workspace ==="
mkdir -p "${WORK_DIR}"
mkdir -p "${ROOTFS_DIR}"

echo "=== [2/6] Downloading Arch Linux ARM64 rootfs ==="
if [ ! -f "${WORK_DIR}/${ARCH_TARBALL}" ]; then
    echo "Fetching ${ARCH_URL}..."
    curl -L -o "${WORK_DIR}/${ARCH_TARBALL}" "${ARCH_URL}"
else
    echo "Found existing archive at ${WORK_DIR}/${ARCH_TARBALL}."
fi

echo "=== [3/6] Extracting rootfs (requires root/fakeroot) ==="
if [ "$(id -u)" -ne 0 ]; then
    echo "Notice: Extraction requires root privileges (or sudo/proot) to preserve permissions and device nodes."
    echo "To run extraction manually:"
    echo "  sudo bsdtar -xpf ${WORK_DIR}/${ARCH_TARBALL} -C ${ROOTFS_DIR}"
    exit 0
fi

bsdtar -xpf "${WORK_DIR}/${ARCH_TARBALL}" -C "${ROOTFS_DIR}"

echo "=== [4/6] Configuring Hostname & Repositories ==="
echo "angler-plasma" > "${ROOTFS_DIR}/etc/hostname"

cat << 'EOF' > "${ROOTFS_DIR}/etc/hosts"
127.0.0.1   localhost
127.0.1.1   angler-plasma.localdomain angler-plasma
EOF

# Initialize DNS
echo "nameserver 1.1.1.1" > "${ROOTFS_DIR}/etc/resolv.conf"

echo "=== [5/6] Deploying Android Container (LXC) Mount points ==="
# Halium mounts Android system & vendor partitions here
mkdir -p "${ROOTFS_DIR}/var/lib/lxc/android/rootfs"
mkdir -p "${ROOTFS_DIR}/android/system"
mkdir -p "${ROOTFS_DIR}/android/vendor"
mkdir -p "${ROOTFS_DIR}/android/firmware"
mkdir -p "${ROOTFS_DIR}/opt/plasma-mobile"

# Copy local plasma shell into rootfs
cp -r "${SCRIPT_DIR}/../shell" "${ROOTFS_DIR}/opt/plasma-mobile/"
cp "${SCRIPT_DIR}/start-plasma-session.sh" "${ROOTFS_DIR}/usr/local/bin/"
chmod +x "${ROOTFS_DIR}/usr/local/bin/start-plasma-session.sh"

echo "=== [6/6] Injecting Halium LXC Config and Services ==="
cp "${SCRIPT_DIR}/lxc-android.conf" "${ROOTFS_DIR}/var/lib/lxc/android/config"
cp "${SCRIPT_DIR}/halium-android.service" "${ROOTFS_DIR}/etc/systemd/system/"

echo "Rootfs bootstrap configuration complete."
echo "Target location: ${ROOTFS_DIR}"
