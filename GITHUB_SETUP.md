# GitHub Authentication for Cloud Build

## Quick Setup - Cloud Build GitHub App

1. **Connect GitHub to Cloud Build:**
   - Go to: https://console.cloud.google.com/cloud-build/triggers?project=onex-didcom
   - Click "Connect Repository"
   - Select "GitHub (Cloud Build GitHub App)"
   - Authenticate and select `didcom-machines/dx-one-building`
   - Click "Connect"

2. **Grant Cloud Build access:**
   - The GitHub App will need read access to your repository
   - Accept the authorization prompt

3. **Update cloudbuild/build-image.yaml to use Cloud Build connection:**
   Instead of public HTTPS, repo will use the authenticated connection automatically.

## Alternative - Use SSH Deploy Key

If you prefer SSH keys:

```bash
# Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/gcp-repo-key -N ""

# Add to GitHub as Deploy Key
cat ~/.ssh/gcp-repo-key.pub
# Go to: https://github.com/didcom-machines/dx-one-building/settings/keys
# Add as deploy key (read-only access)

# Add private key to Cloud Build Secret Manager
gcloud secrets create github-repo-key --data-file=~/.ssh/gcp-repo-key

# Update cloudbuild to use SSH
```

## Temporary Solution - Public Repository

For testing, make the repository public temporarily:
1. https://github.com/didcom-machines/dx-one-building/settings
2. Danger Zone → Change visibility → Make public

Note: Only the manifest and build configs are in this repo. Your actual BSP layer (meta-didcom-bsp) is also committed, which contains your custom configurations.
