# Yocto CI/CD Project Setup Summary

## Project Overview

This is a clean Yocto Project setup for automated CI/CD builds on Google Cloud Build, supporting multiple machines, custom distributions, and automated image generation.

## Hardware Platforms (Machines)

Three machines are defined:

1. **dx-one-dart-mx95** - i.MX95 based board (Variscite DART-MX95)
   - Compatible distros: `automotive-didcom`, `siiab-ejecutivo`
   - Custom device trees, kernel, and U-Boot fork

2. **dx-one-dart-mx8mp** - i.MX8M Plus based board (Variscite DART-MX8M-PLUS)
   - Compatible distros: `automotive-didcom` only
   - Custom device trees, kernel, and U-Boot fork

3. **myproject-rpi-zero2w** - Raspberry Pi Zero 2W
   - Compatible distros: `poky`
   - Development/testing platform

## Custom Distributions

### automotive-didcom
- Based on: `fsl-imx-xwayland`
- Compatible with: dx-one-dart-mx95, dx-one-dart-mx8mp
- Features: Automotive middleware, CAN bus, real-time kernel, systemd
- Image: `automotive-didcom-image.bb`

### siiab-ejecutivo
- Based on: `fsl-imx-xwayland`
- Compatible with: dx-one-dart-mx95 ONLY
- Features: High-performance multimedia, Wayland/Vulkan, executive UI, systemd
- Image: `siiab-ejecutivo-image.bb`

## Repository Structure

```
your-clean-project/
├── .gitignore                          # Excludes external layers
├── .repo/manifests/
│   └── default.xml                     # Defines external layer sources (COMMIT)
│
├── Dockerfile.cloudbuild               # Build environment container (COMMIT)
├── cloudbuild.yaml                     # Main CI/CD trigger (COMMIT)
├── cloudbuild-image.yaml               # Container build (COMMIT)
│
├── conf/                               # Build configurations (COMMIT ALL)
│   ├── machines.yaml                   # Machine inventory
│   ├── distros.yaml                    # Distribution definitions
│   └── images.yaml                     # Build matrix (what to build)
│
├── templates/                          # Config templates (COMMIT ALL)
│   ├── bblayers.conf.template          # Layer configuration template
│   └── local.conf.template             # Build settings template
│
├── cloudbuild/                         # CI/CD workflows (COMMIT ALL)
│   ├── build-image.yaml                # Single image build
│   └── build-all.yaml                  # Multi-image build
│
└── sources/
    ├── meta-dx-one/                 # YOUR CUSTOM LAYER (COMMIT ALL)
    │   ├── conf/
    │   │   ├── layer.conf
    │   │   ├── distro/
    │   │   │   ├── automotive-didcom.conf
    │   │   │   └── siiab-ejecutivo.conf
    │   │   └── machine/
    │   │       ├── dx-one-dart-mx95.conf
    │   │       ├── dx-one-dart-mx8mp.conf
    │   │       └── myproject-rpi-zero2w.conf
    │   ├── recipes-bsp/u-boot/
    │   │   ├── u-boot-myproject_2024.10.bb
    │   │   └── files/
    │   ├── recipes-kernel/linux/
    │   │   ├── linux-myproject_6.6.bb
    │   │   └── files/
    │   │       ├── imx95-dx-one-dart-v1.dts
    │   │       └── imx8mp-dx-one-dart.dts
    │   └── recipes-core/images/
    │       ├── automotive-didcom-image.bb
    │       └── siiab-ejecutivo-image.bb
    │
    ├── poky/                           # NOT IN GIT (fetched by repo)
    ├── meta-openembedded/              # NOT IN GIT
    ├── meta-variscite-bsp-imx/         # NOT IN GIT
    ├── meta-raspberrypi/               # NOT IN GIT
    └── [other external layers...]      # NOT IN GIT
```

## What Goes in Git vs What Gets Fetched

### COMMIT to Git:
- ✅ `Dockerfile.cloudbuild`
- ✅ `cloudbuild.yaml`, `cloudbuild-image.yaml`
- ✅ `cloudbuild/` directory
- ✅ `conf/` directory (machines.yaml, distros.yaml, images.yaml)
- ✅ `templates/` directory (*.template files)
- ✅ `.repo/manifests/default.xml` (your custom manifest)
- ✅ `sources/meta-dx-one/` (your custom layer)
- ✅ `.gitignore`
- ✅ Documentation files

### DO NOT COMMIT (fetched by repo):
- ❌ `sources/poky/`
- ❌ `sources/meta-openembedded/`
- ❌ `sources/meta-variscite-*/`
- ❌ `sources/meta-imx/`
- ❌ `sources/meta-freescale*/`
- ❌ `sources/meta-raspberrypi/`
- ❌ All other external layers
- ❌ `build*/` directories
- ❌ `downloads/`, `sstate-cache/`

## Key Configuration Files

### 1. Manifest (.repo/manifests/default.xml)
- Defines external layer sources and versions
- Based on Variscite Scarthgap (5.0) manifest
- Added `meta-raspberrypi` for RPi support
- Uses repo tool to fetch dependencies

### 2. Machine Configs (sources/meta-dx-one/conf/machine/*.conf)
- Inherit from Variscite base machines (`require conf/machine/imx95-var-dart.conf`)
- Override device trees, kernel, and U-Boot providers
- Point to your forked repositories

### 3. Distro Configs (sources/meta-dx-one/conf/distro/*.conf)
- Based on `fsl-imx-xwayland`
- Define DISTRO_FEATURES, package selections
- Specify compatible machines via COMPATIBLE_MACHINE in images

### 4. Image Recipes (sources/meta-dx-one/recipes-core/images/*.bb)
- Inherit from `core-image`
- Define IMAGE_INSTALL packages
- Set COMPATIBLE_MACHINE restrictions

### 5. Templates (templates/*.template)
- `local.conf.template`: Uses `__MACHINE_PLACEHOLDER__` and `__DISTRO_PLACEHOLDER__`
- `bblayers.conf.template`: Lists all layers including `meta-dx-one`
- Cloud Build replaces placeholders with actual values during build

## CI/CD Workflow

### On Commit to Main (Validation Build):
```
git push → Cloud Build triggered
    ↓
1. Build/pull yocto-builder container
2. repo sync (fetch external layers)
3. Generate config from templates
4. Build: dx-one-dart-mx8mp + automotive-didcom + core-image-minimal
5. Fast validation (~10-30 min)
```

### On Tag (Production Build):
```
git tag v1.0.0 → Cloud Build triggered
    ↓
1. Build/pull yocto-builder container
2. repo sync (fetch external layers)
3. Read build matrix from conf/images.yaml
4. Trigger parallel builds:
   - dx-one-dart-mx95 + automotive-didcom + automotive-didcom-image
   - dx-one-dart-mx95 + siiab-ejecutivo + siiab-ejecutivo-image
   - dx-one-dart-mx8mp + automotive-didcom + automotive-didcom-image
   - dx-one-rpi-zero2w + poky + core-image-minimal
5. Upload artifacts to gs://PROJECT-yocto-artifacts/production/v1.0.0/
6. Generate release manifest
```

## Build Matrix (conf/images.yaml)

```yaml
build_matrix:
  validation:  # Fast builds on every commit
    - machine: dx-one-dart-mx8mp
      distro: automotive-didcom
      image: core-image-minimal
  
  production:  # Full builds on release tags
    - machine: dx-one-dart-mx95
      distro: automotive-didcom
      image: automotive-didcom-image
    - machine: dx-one-dart-mx95
      distro: siiab-ejecutivo
      image: siiab-ejecutivo-image
    - machine: dx-one-dart-mx8mp
      distro: automotive-didcom
      image: automotive-didcom-image
    - machine: dx-one-rpi-zero2w
      distro: poky
      image: core-image-minimal
```

## Local Development Workflow

```bash
# 1. Clone your repo
git clone https://github.com/youruser/your-project.git
cd your-project

# 2. Fetch external layers
mkdir -p sources
cd sources
repo init -u .. -m .repo/manifests/default.xml
repo sync

# 3. Now you can inspect external layers
cd meta-variscite-bsp-imx/recipes-kernel/linux/
vim linux-variscite_*.bb

# 5. Create bbappends or recipes in meta-dx-one/
cd ../../meta-dx-one/recipes-kernel/linux/
vim linux-dx-one_6.6.bb

# 5. Test locally (optional)
cd /path/to/your-project
docker build -t yocto-builder:local -f Dockerfile.cloudbuild .
# Or use Variscite container if available

# 6. Commit only your changes
git add sources/meta-dx-one/
git commit -m "Add custom kernel configuration"
git push
```

## Cloud Storage Structure

```
gs://PROJECT-yocto-cache/
├── sstate-cache/      # Shared state cache (speeds up builds 80%+)
└── downloads/         # Downloaded sources (tarballs, git repos)

gs://PROJECT-yocto-artifacts/
├── validation/
│   └── commit-sha/
│       └── dx-one-dart-mx8mp_automotive-didcom/
└── production/
    └── v1.0.0/
        ├── dx-one-dart-mx95_automotive-didcom/
        ├── dx-one-dart-mx95_siiab-ejecutivo/
        ├── dx-one-dart-mx8mp_automotive-didcom/
        └── release-manifest.json
```

## Custom Kernel and U-Boot

Both kernel and U-Boot are maintained in your own forks:

```bash
# Kernel recipe points to your fork
SRC_URI = "git://github.com/yourcompany/linux-dx-one.git;branch=6.6.y"

# U-Boot recipe points to your fork
SRC_URI = "git://github.com/yourcompany/u-boot-dx-one.git;branch=imx95"

# Device trees are in meta-dx-one/recipes-kernel/linux/files/
```

## Key Design Decisions

1. **Repo Tool vs Submodules**: Using repo tool (Yocto standard)
   - Easier to manage 15+ external layers
   - One manifest file vs many submodule commands

2. **Template-based Configs**: Templates with placeholders
   - Supports multiple machine/distro combinations
   - Single source of truth for configurations

3. **Layer Separation**: Clear boundary between external and custom code
   - External layers fetched by manifest (not in git)
   - Your code in `meta-dx-one` (tracked in git)
   - Use bbappends to modify external recipes

4. **Machine Inheritance**: Custom machines inherit from Variscite
   - `require conf/machine/imx95-var-dart.conf`
   - Get updates from Variscite by updating manifest
   - Override only what you need

5. **Distro Compatibility**: Explicit machine-distro relationships
   - Documented in machines.yaml and distros.yaml
   - Enforced in build matrix
   - Prevents invalid combinations

## Getting Started Checklist

- [ ] Copy all files from reference workspace to clean project
- [ ] Update `.repo/manifests/default.xml` with your layer sources
- [ ] Create `sources/meta-dx-one/` with your custom layer
- [ ] Define machines in `sources/meta-dx-one/conf/machine/`
- [ ] Define distros in `sources/meta-dx-one/conf/distro/`
- [ ] Create image recipes in `sources/meta-dx-one/recipes-core/images/`
- [ ] Update `conf/machines.yaml`, `conf/distros.yaml`, `conf/images.yaml`
- [ ] Update `templates/bblayers.conf.template` to include meta-dx-one
- [ ] Create `.gitignore` to exclude external layers
- [ ] Set up GCP: Create buckets, build container
- [ ] Configure GitHub build triggers
- [ ] Test validation build
- [ ] Tag and test production build

## Essential Commands

```bash
# Local repo sync
cd sources && repo sync

# Build container
gcloud builds submit --config=cloudbuild-image.yaml

# Manual build
gcloud builds submit --config=cloudbuild/build-image.yaml \
  --substitutions=_MACHINE=dx-one-dart-mx95,_DISTRO=automotive-didcom,_IMAGE=automotive-didcom-image

# Tag for release
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0
```

## Important Notes

- Yocto version: **Scarthgap (5.0)** via manifest
- Container runs as root (no user mapping needed)
- Templates use placeholders: `__MACHINE_PLACEHOLDER__`, `__DISTRO_PLACEHOLDER__`
- External layers = dependencies (like node_modules)
- Only commit `sources/meta-dx-one/`, not other sources/
- Build times: validation ~15min, production ~2-4 hours per image
- Cache in Cloud Storage reduces rebuild time by 80%+

## Next Steps for New Agent

1. Review this summary to understand the architecture
2. Check `QUICKSTART_CLEAN_PROJECT.md` for step-by-step setup
3. Examine `CI_CD_SETUP.md` for Cloud Build configuration
3. Review example files in `sources/meta-dx-one/`
5. Understand the build matrix in `conf/images.yaml`
6. Test locally with `repo sync` before pushing to Cloud Build
