#!/bin/bash
# Google Cloud Platform Setup Script
# Sets up GCP resources for Yocto CI/CD builds

set -e

echo "==========================================="
echo "GCP Setup for Yocto CI/CD"
echo "==========================================="
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "ERROR: gcloud CLI is not installed"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Get or set project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    # Use default project
    PROJECT_ID="onex-didcom"
    echo "Using default project: $PROJECT_ID"
    gcloud config set project "$PROJECT_ID"
fi

echo "Using GCP Project: $PROJECT_ID"
echo ""

# Enable required APIs
echo "Step 1: Enabling required GCP APIs..."
gcloud services enable \
    cloudbuild.googleapis.com \
    containerregistry.googleapis.com \
    storage-api.googleapis.com \
    storage-component.googleapis.com \
    artifactregistry.googleapis.com

echo "✓ APIs enabled"
echo ""

# Create GCS buckets
echo "Step 2: Creating Cloud Storage buckets..."

# Cache bucket (for sstate-cache and downloads)
CACHE_BUCKET="${PROJECT_ID}-yocto-cache"
if ! gsutil ls -b "gs://${CACHE_BUCKET}" &>/dev/null; then
    gsutil mb -l us-central1 "gs://${CACHE_BUCKET}"
    echo "✓ Created cache bucket: gs://${CACHE_BUCKET}"
else
    echo "✓ Cache bucket already exists: gs://${CACHE_BUCKET}"
fi

# Create subdirectories
gsutil -q stat "gs://${CACHE_BUCKET}/sstate-cache/" 2>/dev/null || \
    echo "Placeholder for sstate-cache" | gsutil cp - "gs://${CACHE_BUCKET}/sstate-cache/.placeholder"
gsutil -q stat "gs://${CACHE_BUCKET}/downloads/" 2>/dev/null || \
    echo "Placeholder for downloads" | gsutil cp - "gs://${CACHE_BUCKET}/downloads/.placeholder"

# Artifacts bucket (for build outputs)
ARTIFACTS_BUCKET="${PROJECT_ID}-yocto-artifacts"
if ! gsutil ls -b "gs://${ARTIFACTS_BUCKET}" &>/dev/null; then
    gsutil mb -l us-central1 "gs://${ARTIFACTS_BUCKET}"
    echo "✓ Created artifacts bucket: gs://${ARTIFACTS_BUCKET}"
else
    echo "✓ Artifacts bucket already exists: gs://${ARTIFACTS_BUCKET}"
fi

# Create subdirectories
gsutil -q stat "gs://${ARTIFACTS_BUCKET}/validation/" 2>/dev/null || \
    echo "Placeholder for validation builds" | gsutil cp - "gs://${ARTIFACTS_BUCKET}/validation/.placeholder"
gsutil -q stat "gs://${ARTIFACTS_BUCKET}/production/" 2>/dev/null || \
    echo "Placeholder for production builds" | gsutil cp - "gs://${ARTIFACTS_BUCKET}/production/.placeholder"

echo ""

# Build and push container
echo "Step 3: Building and pushing Yocto builder container..."
gcloud builds submit --config=cloudbuild-image.yaml --timeout=30m

echo "✓ Container built and pushed: gcr.io/${PROJECT_ID}/yocto-builder:latest"
echo ""

# Set up Cloud Build triggers (manual step)
echo "==========================================="
echo "Setup Complete!"
echo "==========================================="
echo ""
echo "GCS Buckets:"
echo "  - Cache:     gs://${CACHE_BUCKET}"
echo "  - Artifacts: gs://${ARTIFACTS_BUCKET}"
echo ""
echo "Container:"
echo "  - gcr.io/${PROJECT_ID}/yocto-builder:latest"
echo ""
echo "Next Steps:"
echo "1. Update cloudbuild.yaml repo URL (line 52):"
echo "   repo init -u https://github.com/YOUR_ORG/YOUR_REPO.git ..."
echo ""
echo "2. Set up Cloud Build triggers:"
echo "   - Go to: https://console.cloud.google.com/cloud-build/triggers"
echo "   - Connect your GitHub repository"
echo "   - Create trigger for 'main' branch → cloudbuild.yaml"
echo "   - Create trigger for tags (v*) → cloudbuild.yaml"
echo ""
echo "3. Test with manual build:"
echo "   gcloud builds submit --config=cloudbuild/build-image.yaml \\"
echo "     --substitutions=_MACHINE=dx-one-dart-mx8mp,_DISTRO=automotive-infotainment,_IMAGE=core-image-minimal"
echo ""
