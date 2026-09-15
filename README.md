# KDE Plasma 6 Mobile on Nexus 6P (`angler`)

A native, touch-first mobile operating system setup for the **Huawei Nexus 6P (Snapdragon 810 / MSM8994)** running a KDE Plasma 6 style Wayland shell via Halium and libhybris.

---

## Architecture Overview

```
+-------------------------------------------------------------+
|    KDE Plasma 6 Mobile Shell (Qt 6 / QML + Wayland)         |
|    KWin-Wayland / QtWayland Compositor                      |
+-------------------------------------------------------------+
|    Arch Linux ARM64 Root Filesystem (glibc)                 |
|    systemd, PulseAudio / PipeWire, NetworkManager, ModemMgr |
+-------------------------------------------------------------+
|    libhybris (libEGL_hybris.so, libGLESv2_hybris.so)        |
+-------------------------------------------------------------+
|    Android 8.1 HALs & Adreno 430 Drivers (LXC Container)    |
|    (/vendor/lib64/egl, /system/lib64/hw)                    |
+-------------------------------------------------------------+
|    Downstream Kernel (msm-3.10 / lineage-15.1 + Halium)    |
+-------------------------------------------------------------+
|    Huawei Nexus 6P Hardware (MSM8994)                       |
+-------------------------------------------------------------+
```

---

## Directory Structure

* [`shell/`](shell/): Custom touch-first KDE Plasma 6 style mobile shell written in QML / Qt 6.
  * [`shell/Main.qml`](shell/Main.qml): Plasma 6 Breeze mobile interface (quick settings, status bar, app launcher, task navigation).
* [`kernel/`](kernel/): Kernel defconfig patches for container namespaces, binder IPC, and BLOD (4-core) protection.
* [`rootfs/`](rootfs/): Setup scripts for assembling the Arch ARM / Debian root filesystem, LXC container configuration, and libhybris test environment.
* [`scripts/`](scripts/): Build scripts for packing `boot.img` and flashing via fastboot.

---

## Running the Plasma 6 Shell

You can test and preview the mobile shell locally on any Linux desktop with Qt 6:

```bash
qml6 shell/Main.qml
```

---

## Hardware Notes for Nexus 6P (`angler`)

* **SoC:** Qualcomm Snapdragon 810 (MSM8994)
* **GPU:** Adreno 430
* **Display:** 5.7" WQHD (2560x1440) AMOLED
* **Thermal Tuning:** The Snapdragon 810 requires conservative CPU governor tuning or big-cluster disabling if suffering from the well-known hardware core failure (BLOD).
