# Build Process Analysis - Repo Structure Issue

## 🔴 Problem: Two `.repo` Directories

### Current Structure
```
dx-one-building/
├── .repo/
│   └── manifests/
│       └── default.xml          ← Manifest committed to git
├── sources/
│   ├── .repo/                   ← WRONG! Created by repo init from sources/
│   ├── meta-dx-one/             ← Custom layer (in git)
│   └── meta-didcom-bsp/         ← Custom layer (in git)
```

### What Should Happen ✅

**Single `.repo` at root:**
```
dx-one-building/
├── .repo/                       ← Single repo tool directory
│   ├── manifests/
│   ├── manifests.git/
│   ├── repo/
│   └── ... (repo tool metadata)
└── sources/
    ├── meta-dx-one/             ← Custom (in git)
    ├── meta-didcom-bsp/         ← Custom (in git)
    ├── poky/                    ← Fetched by repo
    ├── meta-openembedded/       ← Fetched by repo
    ├── meta-freescale/          ← Fetched by repo
    └── ... (15+ external layers)
```

## 🐛 Root Cause

### Manifest Path Declaration
The manifest at `.repo/manifests/default.xml` declares paths **relative to the workspace root**:

```xml
<project name="poky" path="sources/poky" .../>
<project name="meta-openembedded" path="sources/meta-openembedded" .../>
<project name="meta-variscite-bsp-imx" path="sources/meta-variscite-bsp-imx" .../>
```

### Broken Build Script Behavior

**Current (BROKEN) in `cloudbuild/build-image.yaml`:**
```yaml
- |
  cd /workspace
  mkdir -p sources
  cd sources                                         # ← WRONG: Changed to sources/
  repo init -u /workspace -m .repo/manifests/default.xml
  repo sync -j8
```

**What this does:**
1. Changes directory to `sources/`
2. Runs `repo init` from inside `sources/`
3. Creates `sources/.repo/` (second .repo directory)
4. Tries to fetch projects relative to `sources/`
5. Manifest says `path="sources/poky"` 
6. Result: Tries to create `sources/sources/poky` ❌

**Same issue in `build-local.sh`:**
```bash
cd sources
repo init -u .. -m .repo/manifests/default.xml
repo sync -j8
```

## ✅ Correct Approach

### Proper Initialization

**Run from workspace root:**
```bash
cd /workspace                    # Stay at root
repo init -u . -m .repo/manifests/default.xml
repo sync -j8
```

**What this does:**
1. Stays in workspace root
2. Uses existing `.repo/manifests/default.xml`
3. Creates a single `.repo/` at root (already exists)
4. Fetches projects to correct paths: `sources/poky`, `sources/meta-openembedded`, etc.
5. Everything goes to the right place ✅

## 📋 Step-by-Step Build Process (Corrected)

### Step 0: Repo Initialization
```bash
# Location: /workspace (root)

# For Cloud Build (using GitHub):
repo init -u https://github.com/didcom-machines/dx-one-building.git -b main
repo sync -j8

# For local builds (using local git repo):
repo init -u file://$PWD -b main
repo sync -j8
```

**Important:** Repo expects a **git repository URL** as the manifest source. It will:
1. Clone that repo into `.repo/manifests.git/`
2. Checkout to `.repo/manifests/`
3. Read the manifest file (`default.xml`) from there
4. Create symlink `.repo/manifest.xml` → `.repo/manifests/default.xml`

**Result:**
```
sources/
├── base/                        # Variscite base scripts
├── poky/                        # Yocto core
├── meta-openembedded/           # OE layers
├── meta-imx/                    # NXP i.MX BSP
├── meta-freescale/              # Freescale layers
├── meta-variscite-bsp-imx/      # Variscite BSP
├── meta-variscite-sdk-imx/      # Variscite SDK
├── meta-raspberrypi/            # Raspberry Pi
├── meta-arm/                    # ARM support
├── meta-qt6/                    # Qt6
├── meta-browser/                # Chromium
├── ... (all external layers)
├── meta-dx-one/                 # Your custom layer (already in git)
└── meta-didcom-bsp/             # Your BSP layer (already in git)
```

### Step 1: Setup Build Configuration
```bash
# Location: /workspace
BUILD_NAME="build_dx-one-dart-mx95_automotive-infotainment"
mkdir -p "$BUILD_NAME/conf"
cp templates/bblayers.conf.template "$BUILD_NAME/conf/bblayers.conf"
cp templates/local.conf.template "$BUILD_NAME/conf/local.conf"
```

### Step 2: Initialize BitBake Environment
```bash
# Location: /workspace
source sources/poky/oe-init-build-env "$BUILD_NAME"
```

**What this does:**
- Sources BitBake environment from `sources/poky/`
- Changes directory to `$BUILD_NAME/`
- Sets up BitBake paths
- Reads `conf/bblayers.conf` to discover layers

### Step 3: BitBake Layer Resolution
```bash
# Now in: /workspace/build_dx-one-dart-mx95_automotive-infotainment/

# BitBake reads bblayers.conf:
BBLAYERS = "
  ${BSPDIR}/sources/poky/meta
  ${BSPDIR}/sources/meta-openembedded/meta-oe
  ${BSPDIR}/sources/meta-imx/meta-imx-bsp
  ${BSPDIR}/sources/meta-variscite-bsp-imx
  ${BSPDIR}/sources/meta-didcom-bsp     ← Your layers
  ${BSPDIR}/sources/meta-dx-one
"
```

### Step 4: BitBake Discovers Configurations
```bash
# BitBake scans all layers for:

# 1. Machine config
MACHINE = "dx-one-dart-mx95"
  → searches: */conf/machine/dx-one-dart-mx95.conf
  → finds: sources/meta-didcom-bsp/conf/machine/dx-one-dart-mx95.conf

# 2. Distro config
DISTRO = "automotive-infotainment"
  → searches: */conf/distro/automotive-infotainment.conf
  → finds: sources/meta-didcom-bsp/conf/distro/automotive-infotainment.conf

# 3. Image recipe
IMAGE = "automotive-infotainment-image"
  → searches: */recipes-*/images/automotive-infotainment-image.bb
  → finds: sources/meta-didcom-bsp/recipes-core/images/automotive-infotainment-image.bb
```

### Step 5: BitBake Build
```bash
bitbake automotive-infotainment-image
```

**Build process:**
1. Parse all layers and recipes
2. Resolve dependencies
3. Download sources to `downloads/`
4. Build packages using `sstate-cache/`
5. Generate rootfs
6. Create final image
7. Output: `tmp/deploy/images/dx-one-dart-mx95/*.wic`

## 🔧 Required Fixes

### 1. Fix `cloudbuild/build-image.yaml`
```yaml
# BEFORE (broken):
repo init -u . -m .repo/manifests/default.xml

# AFTER (correct):
repo init -u file://$PWD -b main
```

### 2. Fix `build-local.sh`
```bash
# BEFORE (broken):
repo init -u . -m .repo/manifests/default.xml

# AFTER (correct):
repo init -u file://$PWD -b main
```

### 3. Fix `cloudbuild.yaml`
```yaml
# For Cloud Build using GitHub:
repo init -u https://github.com/didcom-machines/dx-one-building.git -b main
```

### 3. Clean Up Existing State
```bash
# Remove the incorrect .repo inside sources/
rm -rf sources/.repo

# Keep only the top-level .repo
# This contains your manifest and should be in git
```

## 📊 Comparison: Before vs After

### Before (Broken)
```
Workspace: /workspace
  ├── .repo/manifests/default.xml ← Manifest here
  └── sources/
      ├── .repo/               ← WRONG! Duplicate
      ├── meta-dx-one/
      └── meta-didcom-bsp/
      
No external layers fetched! ❌
```

### After (Fixed)
```
Workspace: /workspace
  ├── .repo/                   ← Single repo directory
  │   ├── manifests/
  │   ├── manifests.git/
  │   └── repo/
  └── sources/
      ├── poky/                ✅ Fetched
      ├── meta-openembedded/   ✅ Fetched
      ├── meta-variscite-*/    ✅ Fetched
      ├── meta-imx/            ✅ Fetched
      ├── ... (15+ layers)     ✅ Fetched
      ├── meta-dx-one/         ✅ Your custom
      └── meta-didcom-bsp/     ✅ Your custom

All layers ready to build! ✅
```

## 🎯 Summary

**The Issue:**
- Two `.repo` directories confuse the repository tool
- Running `repo init` from inside `sources/` creates incorrect paths
- External layers never get fetched to the right location

**The Fix:**
- Run `repo init` and `repo sync` from workspace root
- Keep single `.repo/` directory at root
- Manifest paths (`sources/poky`) work correctly relative to root

**The Result:**
- All external Yocto layers fetched to `sources/`
- BitBake can find all layers through `bblayers.conf`
- Clean, predictable build structure
