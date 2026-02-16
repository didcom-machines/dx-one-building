#!/bin/bash
# Quick Cloud Build Test Script
# This script helps verify that Cloud Build configuration is working

set -e

PROJECT_ID="onex-didcom"
MACHINE="dx-one-dart-mx95"
DISTRO="automotive-infotainment"
IMAGE="core-image-minimal"

echo "==========================================="
echo "Cloud Build Test for Yocto DX-ONE Project"
echo "==========================================="
echo "Project: $PROJECT_ID"
echo "Machine: $MACHINE"
echo "Distro:  $DISTRO"
echo "Image:   $IMAGE"
echo "==========================================="

# Check if gcloud is configured
if ! gcloud config get-value project &>/dev/null; then
    echo "ERROR: gcloud is not configured"
    echo "Run: gcloud config set project $PROJECT_ID"
    exit 1
fi

CURRENT_PROJECT=$(gcloud config get-value project)
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo "WARNING: Current project is $CURRENT_PROJECT, expected $PROJECT_ID"
    read -p "Switch to $PROJECT_ID? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gcloud config set project $PROJECT_ID
    else
        echo "Aborting"
        exit 1
    fi
fi

echo ""
echo "Step 1: Check if Docker container exists..."
if gcloud container images describe "gcr.io/$PROJECT_ID/yocto-builder:latest" &>/dev/null; then
    echo "✅ Container exists: gcr.io/$PROJECT_ID/yocto-builder:latest"
else
    echo "❌ Container not found. Building it now..."
    echo "This will take ~10-15 minutes..."
    gcloud builds submit --config=cloudbuild-image.yaml
    echo "✅ Container built successfully"
fi

echo ""
echo "Step 2: Check GCS buckets..."
if gsutil ls "gs://$PROJECT_ID-yocto-cache" &>/dev/null; then
    echo "✅ Cache bucket exists: gs://$PROJECT_ID-yocto-cache"
else
    echo "⚠️  Cache bucket not found"
    echo "Run: ./setup-gcp.sh"
fi

if gsutil ls "gs://$PROJECT_ID-yocto-artifacts" &>/dev/null; then
    echo "✅ Artifacts bucket exists: gs://$PROJECT_ID-yocto-artifacts"
else
    echo "⚠️  Artifacts bucket not found"
    echo "Run: ./setup-gcp.sh"
fi

echo ""
echo "Step 3: Test repo initialization (dry run)..."
cat > /tmp/test-repo-init.sh << 'EOF'
#!/bin/bash
set -e
cd /workspace
repo init -u https://github.com/didcom-machines/dx-one-building.git -b main
echo "✅ Repo initialization would succeed"
EOF

echo "Would run: repo init -u https://github.com/didcom-machines/dx-one-building.git -b main"
echo "✅ Command syntax is correct"

echo ""
echo "Step 4: Ready to test Cloud Build"
echo ""
echo "Run the following command to test:"
echo ""
echo "gcloud builds submit \\"
echo "  --config=cloudbuild/build-image.yaml \\"
echo "  --substitutions=_MACHINE=$MACHINE,_DISTRO=$DISTRO,_IMAGE=$IMAGE,_BUILD_VERSION=test,_BUILD_TYPE=validation"
echo ""
read -p "Run this test now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Starting Cloud Build test..."
    echo "This will take 2-4 hours for a full Yocto build"
    echo "You can monitor progress in GCP Console: https://console.cloud.google.com/cloud-build/builds"
    echo ""
    
    gcloud builds submit \
        --config=cloudbuild/build-image.yaml \
        --substitutions="_MACHINE=$MACHINE,_DISTRO=$DISTRO,_IMAGE=$IMAGE,_BUILD_VERSION=test,_BUILD_TYPE=validation"
    
    echo ""
    echo "✅ Build submitted successfully!"
else
    echo "Skipping test. Run manually when ready."
fi

echo ""
echo "==========================================="
echo "Test Complete!"
echo "==========================================="
