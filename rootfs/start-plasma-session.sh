#!/bin/bash
# Environment setup for running Qt 6 Plasma Mobile shell over Halium / libhybris

export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export EGL_PLATFORM=hwcomposer
export HYBRIS_EGLPLATFORM=hwcomposer
export XDG_CURRENT_DESKTOP=KDE
export KDE_FULL_SESSION=true

echo "Starting KDE Plasma 6 Mobile Shell..."
exec qml6 /opt/plasma-mobile/shell/Main.qml
