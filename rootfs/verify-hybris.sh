#!/usr/bin/env bash
# ==============================================================================
# verify-hybris.sh: Diagnostic and verification script for libhybris hardware
# Run this inside the booted Arch Linux ARM64 rootfs on Nexus 6P (angler)
# ==============================================================================
set -euo pipefail

echo "========================================================"
echo "    libhybris Diagnostic Suite for Nexus 6P (angler)    "
echo "========================================================"

echo ""
echo "[1/5] Checking Android binder & GPU nodes..."
for node in /dev/binder /dev/hwbinder /dev/vndbinder /dev/ion /dev/kgsl-3d0; do
    if [ -e "$node" ]; then
        echo "  [OK] Found $node ($(ls -l "$node" | awk '{print $1, $3, $4}'))"
    else
        echo "  [FAIL] Missing device node: $node"
    fi
done

echo ""
echo "[2/5] Checking Android LXC container state..."
if command -v lxc-info >/dev/null 2>&1; then
    lxc-info -n android || echo "  [WARN] Container 'android' is not running."
else
    echo "  [WARN] lxc-info command not found. Verify lxc package is installed."
fi

echo ""
echo "[3/5] Testing libhybris link to Bionic linker..."
if [ -f "/system/bin/linker64" ] || [ -f "/android/system/bin/linker64" ]; then
    echo "  [OK] 64-bit Bionic linker located."
else
    echo "  [FAIL] Bionic linker64 not found in /system/bin or /android/system/bin."
fi

echo ""
echo "[4/5] Checking Adreno 430 GPU blobs..."
for blob in /vendor/lib64/egl/libEGL_adreno.so /vendor/lib64/egl/libGLESv2_adreno.so; do
    if [ -f "$blob" ]; then
        echo "  [OK] Found Adreno blob: $blob"
    else
        echo "  [WARN] Missing vendor blob at $blob. Check vendor mount."
    fi
done

echo ""
echo "[5/5] Testing Hardware Composer & EGL (libhybris binaries)..."
for test_bin in test_egl test_glesv2 test_hwcomposer; do
    if command -v "$test_bin" >/dev/null 2>&1; then
        echo "  Found $test_bin: ready to execute rendering test."
    else
        echo "  $test_bin not installed in PATH."
    fi
done

echo "Diagnostic scan complete."
