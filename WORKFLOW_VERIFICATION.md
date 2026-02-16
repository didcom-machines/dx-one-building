# Workflow Verification - Configuration Connections

This document verifies that all configurations are properly connected after moving from `conf/` to the meta layer structure.

## ✅ Configuration Structure

### Sources Location (meta-didcom-bsp)
```
sources/meta-didcom-bsp/
├── conf/
│   ├── layer.conf                           # Layer definition
│   ├── distro/
│   │   └── automotive-infotainment.conf     # Single distro for all platforms
│   └── machine/
│       ├── dx-one-dart-mx95.conf            # i.MX95 primary
│       ├── dx-one-dart-mx8mp.conf           # i.MX8M Plus secondary
│       └── dx-one-rpi-zero2w.conf           # RPi development
└── recipes-core/
    └── images/
        ├── automotive-infotainment-image.bb # Base image (all machines)
        └── siiab-ejecutivo-image.bb         # SIIAB branded (mx95 only)
```

## ✅ Build Workflow Connections

### 1. Build Matrix Definition
**File:** `build-matrix.yaml` (project root)

Defines what to build in production releases:
- `dx-one-dart-mx95` + `automotive-infotainment` + `automotive-infotainment-image`
- `dx-one-dart-mx95` + `automotive-infotainment` + `siiab-ejecutivo-image`
- `dx-one-dart-mx8mp` + `automotive-infotainment` + `automotive-infotainment-image`

### 2. Layer Registration
**File:** `templates/bblayers.conf.template`

Includes both custom layers:
```bash
BBLAYERS += " \
  ${BSPDIR}/sources/meta-dx-one \
  ${BSPDIR}/sources/meta-didcom-bsp \
  "
```

### 3. Cloud Build Workflow

#### Production Build (`cloudbuild/build-all.yaml`)
1. Reads `build-matrix.yaml` from project root
2. Parses production builds using `yq`
3. Triggers parallel builds for each configuration
4. Generates release manifest

**Updated references:**
```yaml
# OLD (removed):
conf/images.yaml

# NEW (current):
build-matrix.yaml
```

#### Single Build (`cloudbuild/build-image.yaml`)
- Takes substitution variables: `_MACHINE`, `_DISTRO`, `_IMAGE`
- Copies templates to build directory
- BitBake resolves machine/distro from meta layers
- No direct conf/ references needed

### 4. BitBake Resolution Path

When BitBake builds an image, it uses this resolution chain:

```
1. bblayers.conf → meta-didcom-bsp is included
   ├─→ 2. layer.conf → BitBake knows meta-didcom-bsp exists
       ├─→ 3. MACHINE variable → finds conf/machine/${MACHINE}.conf
       ├─→ 4. DISTRO variable → finds conf/distro/${DISTRO}.conf
       └─→ 5. IMAGE variable → finds recipes-core/images/${IMAGE}.bb
```

**Example for `dx-one-dart-mx95 + automotive-infotainment + siiab-ejecutivo-image`:**

```bash
MACHINE="dx-one-dart-mx95"
  ↓
sources/meta-didcom-bsp/conf/machine/dx-one-dart-mx95.conf
  ↓ (requires Variscite BSP configs)
sources/meta-variscite-bsp-imx/conf/machine/include/imx95-var-dart.conf

DISTRO="automotive-infotainment"
  ↓
sources/meta-didcom-bsp/conf/distro/automotive-infotainment.conf
  ↓ (requires base distro)
sources/poky/meta/conf/distro/poky.conf

IMAGE="siiab-ejecutivo-image"
  ↓
sources/meta-didcom-bsp/recipes-core/images/siiab-ejecutivo-image.bb
  ↓ (requires base image)
sources/meta-didcom-bsp/recipes-core/images/automotive-infotainment-image.bb
```

## ✅ Configuration Files Content

### Distro: automotive-infotainment
**Location:** `sources/meta-didcom-bsp/conf/distro/automotive-infotainment.conf`

**Key Settings:**
- Base: `require conf/distro/poky.conf`
- Init: systemd
- Graphics: Wayland (no X11)
- Features: automotive, multimedia, virtualization

**Compatible Machines:** All (mx95, mx8mp, rpi-zero2w)

### Machines

**dx-one-dart-mx95** (`sources/meta-didcom-bsp/conf/machine/dx-one-dart-mx95.conf`)
- SOC: i.MX95 Cortex-A55
- BSP: Variscite DART board
- Features: NXP IW612 WiFi/BT, TPM

**dx-one-dart-mx8mp** (`sources/meta-didcom-bsp/conf/machine/dx-one-dart-mx8mp.conf`)
- SOC: i.MX8M Plus Cortex-A53
- BSP: Variscite DART board
- Features: BCM43xx WiFi/BT, NXP IW612

**dx-one-rpi-zero2w** (`sources/meta-didcom-bsp/conf/machine/dx-one-rpi-zero2w.conf`)
- SOC: BCM2837 (RPi Zero 2W)
- Purpose: Development/testing
- Inherits: raspberrypi0-2w-64.conf

### Images

**automotive-infotainment-image** (`sources/meta-didcom-bsp/recipes-core/images/automotive-infotainment-image.bb`)
- Base: core-image
- Packages: GStreamer, CAN utils, NetworkManager, Weston
- Compatible: All machines
- Purpose: Base image for automotive platforms

**siiab-ejecutivo-image** (`sources/meta-didcom-bsp/recipes-core/images/siiab-ejecutivo-image.bb`)
- Base: `require automotive-infotainment-image.bb`
- Extra: Chromium, NFC tools, SIIAB branded UI
- Compatible: dx-one-dart-mx95 only
- Purpose: SIIAB executive branded image

## ✅ Cloud Build Commands

### Manual Single Build
```bash
gcloud builds submit \
  --config=cloudbuild/build-image.yaml \
  --substitutions=_MACHINE=dx-one-dart-mx95,_DISTRO=automotive-infotainment,_IMAGE=automotive-infotainment-image,_BUILD_VERSION=dev,_BUILD_TYPE=validation
```

### Production Batch Build
```bash
gcloud builds submit \
  --config=cloudbuild/build-all.yaml \
  --substitutions=_BUILD_VERSION=v1.0.0
```

## ✅ Verification Checklist

- [x] Removed old `conf/` directory (machines.yaml, distros.yaml, images.yaml)
- [x] Created `build-matrix.yaml` in project root
- [x] Updated `cloudbuild/build-all.yaml` to reference `build-matrix.yaml`
- [x] Verified `sources/meta-didcom-bsp/conf/layer.conf` exists
- [x] Added `meta-didcom-bsp` to `templates/bblayers.conf.template`
- [x] Verified distro config: `sources/meta-didcom-bsp/conf/distro/automotive-infotainment.conf`
- [x] Verified machine configs in `sources/meta-didcom-bsp/conf/machine/`
- [x] Verified image recipes in `sources/meta-didcom-bsp/recipes-core/images/`
- [x] Verified `.repo/manifests/default.xml` includes all external layers
- [x] Templates reference correct structure (`bblayers.conf.template`, `local.conf.template`)

## 🔗 Configuration Dependencies

```
build-matrix.yaml (defines what to build)
    ↓
cloudbuild/build-all.yaml (orchestrates builds)
    ↓
cloudbuild/build-image.yaml (executes single build)
    ↓
templates/bblayers.conf.template (defines layers)
    ↓
sources/meta-didcom-bsp/conf/layer.conf (BSP layer definition)
    ↓
sources/meta-didcom-bsp/conf/
    ├─ distro/automotive-infotainment.conf (policy)
    ├─ machine/*.conf (hardware configs)
    └─ ../recipes-core/images/*.bb (image definitions)
```

## ✅ Everything is Connected!

All configurations are now properly located in the meta layer structure and correctly connected through the Cloud Build workflow. The build system can:

1. ✅ Discover available machines from `meta-didcom-bsp/conf/machine/`
2. ✅ Discover available distros from `meta-didcom-bsp/conf/distro/`
3. ✅ Discover available images from `meta-didcom-bsp/recipes-core/images/`
4. ✅ Read production build matrix from `build-matrix.yaml`
5. ✅ Execute builds with proper BitBake layer resolution

Ready to build! 🚀
