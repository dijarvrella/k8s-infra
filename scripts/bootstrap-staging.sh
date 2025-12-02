#!/bin/bash
# Bootstrap script for Staging environment
set -e

# Get script directory and navigate to repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "🚀 Bootstrapping Staging Environment..."

# Step 1: Add ArgoCD Helm repository
echo "📦 Adding ArgoCD Helm repository..."
if ! helm repo list | grep -q argo; then
  helm repo add argo https://argoproj.github.io/argo-helm
  helm repo update
else
  echo "✅ ArgoCD Helm repository already added"
  helm repo update argo
fi

# Step 2: Install ArgoCD using Helm
echo "📦 Installing ArgoCD using Helm..."
kubectl create namespace argocd || true

# Check if values file exists and has OAuth configured
VALUES_FILE="$REPO_ROOT/operators/argocd/values-staging.yaml"
if [ ! -f "$VALUES_FILE" ]; then
  echo "❌ Values file not found: $VALUES_FILE"
  exit 1
fi

# Check if OAuth credentials are configured
if grep -q "<YOUR_CLIENT_ID>" "$VALUES_FILE" || grep -q "<YOUR_CLIENT_SECRET>" "$VALUES_FILE"; then
  echo "⚠️  WARNING: OAuth credentials not configured in values file!"
  echo "   Please update $VALUES_FILE with your GitHub OAuth Client ID and Secret"
  echo "   See operators/argocd/README.md for instructions"
  read -p "Continue with installation anyway? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Install ArgoCD with Helm
MAX_RETRIES=3
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if helm upgrade --install argocd argo/argo-cd \
    --namespace argocd \
    --values "$VALUES_FILE" \
    --wait \
    --timeout 10m; then
    echo "✅ ArgoCD installed successfully"
    break
  fi
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
    echo "⚠️  Install attempt $RETRY_COUNT failed, retrying in 10 seconds..."
    sleep 10
  else
    echo "❌ Failed to install ArgoCD after $MAX_RETRIES attempts"
    echo "💡 Tip: Check ArgoCD pods: kubectl get pods -n argocd"
    exit 1
  fi
done

# Step 3: Wait for readiness (additional check)
echo "⏳ Verifying ArgoCD is ready..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd \
  --timeout=300s || echo "⚠️  ArgoCD server may still be starting..."

# Step 3: Apply AppProjects
echo "📋 Applying AppProjects..."
kubectl apply -f argocd/appproject.yml
kubectl apply -f argocd/environments/staging/morichal-ai-staging-appproject.yml

# Step 4: Apply App-of-Apps
echo "🔄 Applying App-of-Apps..."
kubectl apply -f argocd/environments/staging/operators-app-of-apps.yml
kubectl apply -f argocd/environments/staging/apps-app-of-apps.yml

echo "✅ Bootstrap complete!"
echo "📊 Check status: kubectl get applications -n argocd"
echo "🔑 Get admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "🔐 GitHub OAuth Configuration:"
echo "   - Make sure you've configured your GitHub OAuth App and updated values-staging.yaml"
echo "   - OAuth callback URL should be: https://argocd.staging.morichalcorp.com/api/auth/callback"
echo "   - See operators/argocd/README.md for detailed setup instructions"


