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

# Only compatible with mx95 for now
COMPATIBLE_MACHINE = "dx-one-dart-mx95"