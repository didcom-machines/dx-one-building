# Cloud Build Verification Guide

## ✅ Repo Initialization - Cloud Build Ready

All Cloud Build configuration files have been updated to use the correct repo initialization method.

### Configuration Summary

| File | Repo Init Command | Status |
|------|-------------------|--------|
| `cloudbuild.yaml` | `repo init -u https://github.com/didcom-machines/dx-one-building.git -b main` | ✅ Ready |
| `cloudbuild/build-image.yaml` | `repo init -u https://github.com/didcom-machines/dx-one-building.git -b main` | ✅ Ready |
| `build-local.sh` | `repo init -u file://$PWD -b main` | ✅ Ready |

### Key Differences: Local vs Cloud Build

**Local Development:**
```bash
# Uses file:// protocol to access local git repo
repo init -u file://$PWD -b main
```

**Cloud Build:**
```bash
# Uses GitHub URL as manifest source
repo init -u https://github.com/didcom-machines/dx-one-building.git -b main
```

### Why This Works

1. **Cloud Build Context:**
   - Cloud Build clones your repo from GitHub
   - The workspace is a fresh checkout
   - Using the GitHub URL ensures repo can always access the manifest

2. **Local Development:**
   - You have a local git repository
   - Using `file://$PWD` avoids network calls
   - Faster initialization during development

### Testing Cloud Build

#### 1. Build the Docker Container
```bash
gcloud config set project onex-didcom
gcloud builds submit --config=cloudbuild-image.yaml
```

**Expected Result:** Container `gcr.io/onex-didcom/yocto-builder:latest` is built and pushed.

#### 2. Test Single Image Build
```bash
gcloud builds submit \
  --config=cloudbuild/build-image.yaml \
  --substitutions=_MACHINE=dx-one-dart-mx95,_DISTRO=automotive-infotainment,_IMAGE=core-image-minimal,_BUILD_VERSION=test,_BUILD_TYPE=validation
```

**Expected Steps:**
1. ✅ Pull yocto-builder container
2. ✅ Run `repo init` using GitHub URL
3. ✅ Run `repo sync` to fetch all layers to `sources/`
4. ✅ Setup build configuration
5. ✅ Run BitBake

**Watch for:**
- Repo initialization should show: "repo has been initialized in /workspace"
- Repo sync should fetch ~22 external layers
- Build directory should be created: `build_dx-one-dart-mx95_automotive-infotainment/`

#### 3. Test Full CI/CD Pipeline
```bash
# Trigger validation build (commits to main)
git commit --allow-empty -m "test: trigger Cloud Build validation"
git push origin main

# Trigger production build (tags)
git tag -a v0.1.0-test -m "Test production build"
git push origin v0.1.0-test
```

### Architecture Note: cloudbuild.yaml Design

⚠️ **Current Issue:** `cloudbuild.yaml` has a redundant initialization step.

**Current Flow:**
```
cloudbuild.yaml:
  Step 1: Determine build type
  Step 2: Prepare container
  Step 3: Initialize sources ← This workspace is discarded
  Step 4: gcloud builds submit cloudbuild/build-image.yaml ← NEW workspace, needs its own init
```

**Problem:** Step 4 starts a NEW Cloud Build with a fresh workspace. The sources initialized in Step 3 are not transferred.

**Solution:** The initialization in `cloudbuild/build-image.yaml` handles this correctly. Step 3 in `cloudbuild.yaml` is currently redundant but harmless.

**Recommendation:** Consider removing Step 3 from `cloudbuild.yaml` or restructuring to use a single build without nested `gcloud builds submit`.

### Verification Checklist

Before pushing to trigger Cloud Build:

- [x] Committed `.repo/manifests/default.xml` to git
- [x] Updated `.gitignore` to track manifests
- [x] All cloudbuild YAML files use GitHub URL for repo init
- [x] `build-local.sh` uses `file://$PWD` for local development
- [ ] Docker container built: `gcr.io/onex-didcom/yocto-builder:latest`
- [ ] GCS buckets created: `onex-didcom-yocto-cache`, `onex-didcom-yocto-artifacts`
- [ ] Tested manual build with `gcloud builds submit`

### Common Issues

**Issue:** "fatal: manifest ... not available"
- **Cause:** Using `-u .` or wrong path format
- **Fix:** Use `repo init -u https://github.com/didcom-machines/dx-one-building.git -b main`

**Issue:** "Could not read from remote repository"
- **Cause:** Repository is private, Cloud Build needs access
- **Fix:** Ensure Cloud Build service account has read access to GitHub repo

**Issue:** "No such file or directory: .repo/manifest.xml"
- **Cause:** Repo symlink not created properly
- **Fix:** Run `repo init` again, ensure you're using a git URL (not `.`)

### Next Steps

1. **Commit and push changes:**
   ```bash
   git add cloudbuild/ cloudbuild.yaml .gitignore .repo/manifests/
   git commit -m "fix: use GitHub URL for repo init in Cloud Build"
   git push origin main
   ```

2. **Build container:**
   ```bash
   ./setup-gcp.sh  # Create GCS buckets
   gcloud builds submit --config=cloudbuild-image.yaml
   ```

3. **Test build:**
   ```bash
   gcloud builds submit --config=cloudbuild/build-image.yaml \
     --substitutions=_MACHINE=dx-one-dart-mx95,_DISTRO=automotive-infotainment,_IMAGE=core-image-minimal,_BUILD_VERSION=dev,_BUILD_TYPE=validation
   ```

4. **Set up triggers** in GCP Console for automatic builds on push/tag.

## 🎯 Summary

✅ All Cloud Build files now use the correct repo initialization method
✅ GitHub URL as manifest source for Cloud Build
✅ Local builds use `file://` protocol
✅ Ready to test in Cloud Build environment
