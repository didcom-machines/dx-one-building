# Copyright (C) 2025 DIDCOM
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "DIDCOM Automotive Infotainment Image. \
This image contains packages for automotive infotainment systems including \
CAN bus support, multimedia, and connectivity features."
LICENSE = "MIT"

inherit core-image

### WARNING: This image is intended for development and testing purposes.

# Debug features for development
DEBUG_TWEAKS = " \
    allow-empty-password \
    allow-root-login \
    empty-root-password \
    post-install-logging \
"

IMAGE_FEATURES += " \
    splash \
    ssh-server-openssh \
    hwcodecs \
    ${DEBUG_TWEAKS} \
    package-management \
    tools-debug \
    ${@bb.utils.contains('DISTRO_FEATURES', 'wayland', 'weston', \
       bb.utils.contains('DISTRO_FEATURES',     'x11', 'x11-base', \
                                                       '', d), d)} \
"

CORE_IMAGE_EXTRA_INSTALL += " \
    packagegroup-core-full-cmdline \
    packagegroup-fsl-gstreamer1.0 \
    packagegroup-fsl-gstreamer1.0-full \
    ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd-analyze', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'wayland', 'weston-init', '', d)} \
"

# Automotive-specific packages
CORE_IMAGE_EXTRA_INSTALL += " \
    can-utils \
    iproute2 \
    ethtool \
"

# Connectivity packages
CORE_IMAGE_EXTRA_INSTALL += " \
    networkmanager \
    bluez5 \
    wpa-supplicant \
"

# Platform-specific packages
CORE_IMAGE_EXTRA_INSTALL:append:mx8-nxp-bsp = " \
    packagegroup-fsl-tools-gpu \
"

CORE_IMAGE_EXTRA_INSTALL:append:mx95-nxp-bsp = " \
    packagegroup-fsl-tools-gpu \
"

# Disable virtual terminals if configured
systemd_disable_vt () {
    rm ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/getty.target.wants/getty@tty*.service
}

IMAGE_PREPROCESS_COMMAND:append = " ${@ 'systemd_disable_vt;' if bb.utils.contains('DISTRO_FEATURES', 'systemd', True, False, d) and bb.utils.contains('USE_VT', '0', True, False, d) else ''} "

# Compatible with both mx95 and mx8mp
COMPATIBLE_MACHINE = "(dx-one-dart-mx95|dx-one-dart-mx8mp)"