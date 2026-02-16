# Repo Structure Fix - Action Items

## ✅ Fixed Issues

1. **Updated build scripts** - All repo init commands now run from workspace root
   - [cloudbuild/build-image.yaml](cloudbuild/build-image.yaml)
   - [cloudbuild.yaml](cloudbuild.yaml)
   - [build-local.sh](build-local.sh)

2. **Updated .gitignore** - Now properly tracks manifest while ignoring repo metadata
   ```gitignore
   .repo/*              # Ignore repo working directory
   !.repo/manifests/    # But keep manifests in git
   ```

3. **Added manifest to git** - `.repo/manifests/default.xml` now tracked

## 🧹 Cleanup Required

### Remove the incorrect `.repo` inside sources:
```bash
rm -rf sources/.repo
```

This was created by the old (incorrect) repo init command that ran from inside `sources/`.

## 🚀 How to Initialize Sources (Corrected)

### From workspace root:
```bash
cd /home/manuelmonge/dx-one-building

# Method 1: Using local git repository (for local development)
repo init -u file://$PWD -b main
repo sync -j8

# Method 2: Using GitHub repository (for Cloud Build)
repo init -u https://github.com/didcom-machines/dx-one-building.git -b main
repo sync -j8
```

**Note:** Repo expects a **git repository URL**, not a filesystem path. The `file://` protocol allows using a local git repo as the manifest source. The `-m default.xml` is optional since repo uses `default.xml` by default.

**This will fetch all external layers to:**
```
sources/
├── poky/                        ← Yocto core
├── meta-openembedded/           ← OE layers  
├── meta-imx/                    ← NXP i.MX BSP
├── meta-freescale/              ← FSL layers
├── meta-variscite-bsp-imx/      ← Variscite BSP
├── meta-variscite-sdk-imx/      ← Variscite SDK
├── meta-raspberrypi/            ← RPi support
├── meta-arm/                    ← ARM toolchain
├── meta-qt6/                    ← Qt framework
├── meta-browser/                ← Chromium
├── meta-security/               ← Security features
├── meta-virtualization/         ← Containers
├── ... (and more)
├── base/                        ← Variscite scripts
├── meta-dx-one/                 ← Your custom (in git)
└── meta-didcom-bsp/             ← Your BSP (in git)
```

## 📝 Git Commit Commands

```bash
# Stage all changes
git add .gitignore
git add .repo/manifests/default.xml
git add cloudbuild/build-image.yaml
git add cloudbuild.yaml
git add build-local.sh
git add BUILD_PROCESS_ANALYSIS.md
git add WORKFLOW_VERIFICATION.md

# Commit
git commit -m "fix: correct repo initialization to run from workspace root

- Fixed repo init in all build scripts to run from project root
- Updated .gitignore to track .repo/manifests/ while ignoring .repo metadata
- Added .repo/manifests/default.xml to git
- Removed incorrect 'cd sources' before repo init
- Added comprehensive build process documentation

This fixes the dual .repo directory issue where repo was incorrectly
initialized from sources/ directory, causing manifest paths to be wrong."
```

## 🔍 Verification

After cleanup and repo sync, verify the structure:

```bash
# Check that external layers were fetched
ls -d sources/*/

# Should show:
# sources/base/
# sources/meta-arm/
# sources/meta-browser/
# sources/meta-didcom-bsp/     ← Your custom
# sources/meta-dx-one/         ← Your custom
# sources/meta-freescale/
# sources/meta-freescale-3rdparty/
# sources/meta-freescale-distro/
# sources/meta-imx/
# sources/meta-openembedded/
# sources/meta-raspberrypi/
# sources/meta-variscite-bsp-common/
# sources/meta-variscite-bsp-imx/
# sources/meta-variscite-sdk-common/
# sources/meta-variscite-sdk-imx/
# sources/poky/
# ... and more

# Verify only ONE .repo directory at root
find . -name ".repo" -type d
# Should show only: ./.repo

# Verify manifest is tracked in git
git ls-files .repo/
# Should show: .repo/manifests/default.xml
```

## ✅ Summary

**Before:** Two `.repo` directories, external layers not fetched correctly
**After:** Single `.repo` at root, all layers fetched to correct locations

The build should now work correctly! 🎉
