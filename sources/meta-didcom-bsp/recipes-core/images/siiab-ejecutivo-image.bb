# Copyright (C) 2025 DIDCOM / SIIAB
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "SIIAB Executive Branded Image. \
This image is based on automotive-infotainment with additional \
SIIAB branding, executive UI, and multimedia features."
LICENSE = "MIT"

# Inherit from automotive-infotainment-image for base packages
require recipes-core/images/automotive-infotainment-image.bb

SUMMARY = "SIIAB Ejecutivo Executive Branded Image"

# Override/add executive-specific features
IMAGE_FEATURES += " \
    splash \
    weston \
"

# Add SIIAB-specific packages on top of base image
CORE_IMAGE_EXTRA_INSTALL += " \
    weston \
    weston-init \
    weston-examples \
    chromium-ozone-wayland \
    imx-gpu-viv \
    imx-gpu-sdk \
    siiab-executive-ui \
    siiab-communication-suite \
    nfc-tools \
"

# .NET/Mono support
CORE_IMAGE_EXTRA_INSTALL += " \
    mono \
    dotnet \
"

# GPS support
CORE_IMAGE_EXTRA_INSTALL += " \
    util-linux \
    gpsd \
    gps-utils \
    libgps \
    gpsd-gpsctl \
"

# Data processing and analysis
CORE_IMAGE_EXTRA_INSTALL += " \
    dbi-simulator \
"

# Docker containerization
CORE_IMAGE_EXTRA_INSTALL += " \
    bash \
    docker \
"

# MQTT broker and clients
CORE_IMAGE_EXTRA_INSTALL += " \
    mosquitto \
    mosquitto-clients \
    libmosquitto1 \
    libmosquittopp1 \
    mosquitto-dev \
"

# Touchscreen driver
CORE_IMAGE_EXTRA_INSTALL += " \
    egtouch-driver \
"

# Mender OTA updates
CORE_IMAGE_EXTRA_INSTALL += " \
    mender-client \
"

# Enable Chromium proprietary codecs (h.264, MP3)
PACKAGECONFIG:append:pn-chromium-ozone-wayland = " proprietary-codecs"

# Configure systemd services
SYSTEMD_AUTO_ENABLE:pn-docker = "enable"
SYSTEMD_AUTO_ENABLE:pn-mosquitto = "enable"

# User groups for Docker
EXTRA_USERS_PARAMS = " \
    groupadd docker; \
    usermod -aG docker root; \
"

# Full 32GB SD card utilization
IMAGE_ROOTFS_EXTRA_SPACE = "12582912"
IMAGE_OVERHEAD_FACTOR = "1.0"
IMAGE_ROOTFS_MAXSIZE = "25165824"
BOOT_SPACE = "64"

# Only compatible with mx95 for now
COMPATIBLE_MACHINE = "dx-one-dart-mx95"