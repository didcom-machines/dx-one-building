#!/bin/bash
# Local build script using Docker container
# Usage: ./build-local.sh [MACHINE] [DISTRO] [IMAGE]

set -e

MACHINE=${1:-dx-one-dart-mx8mp}
DISTRO=${2:-automotive-infotainment}
IMAGE=${3:-core-image-minimal}

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_NAME="build_${MACHINE}_${DISTRO}"

echo "==========================================="
echo "Yocto Build Configuration"
echo "==========================================="
echo "Machine: $MACHINE"
echo "Distro:  $DISTRO"
echo "Image:   $IMAGE"
echo "Build:   $BUILD_NAME"
echo "==========================================="

# Run build in container
docker run --rm -it \
    -v "$PROJECT_DIR:/workspace" \
    -w /workspace \
    yocto-builder:local \
    bash -c "
        set -e
        
        # Initialize sources if not already done
        if [ ! -d sources/poky ]; then
            echo 'Initializing repo...'
            mkdir -p sources
            cd sources
            repo init -u .. -m .repo/manifests/default.xml
            repo sync -j8
            cd ..
        fi
        
        # Create build directory
        mkdir -p $BUILD_NAME/conf
        
        # Copy and configure templates
        cp templates/bblayers.conf.template $BUILD_NAME/conf/bblayers.conf
        cp templates/local.conf.template $BUILD_NAME/conf/local.conf
        
        # Set machine and distro
        sed -i \"s/__MACHINE_PLACEHOLDER__/$MACHINE/\" $BUILD_NAME/conf/local.conf
        sed -i \"s/__DISTRO_PLACEHOLDER__/$DISTRO/\" $BUILD_NAME/conf/local.conf
        
        # Source environment and build
        source sources/poky/oe-init-build-env $BUILD_NAME
        
        echo '========================================='
        echo 'Starting BitBake build...'
        echo '========================================='
        
        bitbake $IMAGE
        
        echo '========================================='
        echo 'Build completed successfully!'
        echo '========================================='
        echo 'Output: tmp/deploy/images/$MACHINE/'
        ls -lh tmp/deploy/images/$MACHINE/ || true
    "

echo ""
echo "Build artifacts available in: $BUILD_NAME/tmp/deploy/images/$MACHINE/"
