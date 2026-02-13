# DX-ONE Building - Yocto CI/CD

Automated Yocto Project build system for DX-ONE automotive platforms using Google Cloud Build.

## Hardware Platforms

- **dx-one-dart-mx95** - i.MX95 based board (Variscite DART-MX95)
- **dx-one-dart-mx8mp** - i.MX8M Plus based board (Variscite DART-MX8M-PLUS)
- **dx-one-rpi-zero2w** - Raspberry Pi Zero 2W (development/testing)

## Distribution & Images

**Distribution:** `automotive-infotainment`
- Based on NXP i.MX with Wayland support
- Automotive features, CAN bus, multimedia
- Compatible with both production machines

**Images:**
- `automotive-infotainment-image` - Standard automotive infotainment system
- `siiab-ejecutivo-image` - SIIAB branded executive variant
- `core-image-minimal` - Minimal image for validation

## Quick Start

### Local Development

```bash
# Build container locally
docker build -t yocto-builder:local -f Dockerfile.cloudbuild .

# Run a test build
./build-local.sh dx-one-dart-mx8mp automotive-infotainment core-image-minimal
```

### Google Cloud Build Setup

```bash
# Configure GCP project
gcloud config set project onex-didcom

# Set up buckets and container
./setup-gcp.sh

# Trigger manual build
gcloud builds submit --config=cloudbuild/build-image.yaml \
  --substitutions=_MACHINE=dx-one-dart-mx8mp,_DISTRO=automotive-infotainment,_IMAGE=core-image-minimal
```

## Project Structure

```
dx-one-building/
├── .repo/manifests/       # Repo manifest for external layers
├── sources/
│   └── meta-didcom-bsp/   # Custom DIDCOM BSP layer (committed to git)
├── conf/                  # Build matrix configuration
├── templates/             # BitBake configuration templates
├── cloudbuild/            # Cloud Build workflow definitions
└── Dockerfile.cloudbuild  # Yocto build container
```

## Cloud Build Workflow

- **On commit to main:** Validation build (quick minimal image)
- **On tag (v*):** Production builds (all images per build matrix)

## GCP Resources

- **Project:** onex-didcom
- **Cache:** gs://onex-didcom-yocto-cache
- **Artifacts:** gs://onex-didcom-yocto-artifacts
- **Container:** gcr.io/onex-didcom/yocto-builder:latest

## Documentation

See [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) for detailed architecture and setup information.

## License

Proprietary - DIDCOM
