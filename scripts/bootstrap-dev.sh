#!/bin/bash
# Bootstrap script for Dev environment
set -e

# Get script directory and navigate to repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "🚀 Bootstrapping Dev Environment..."

# Step 1: Install ArgoCD
echo "📦 Installing ArgoCD..."
kubectl create namespace argocd || true

# Download manifest to avoid connection issues with large files
echo "📥 Downloading ArgoCD manifest..."
TEMP_MANIFEST=$(mktemp)
trap "rm -f $TEMP_MANIFEST" EXIT

# Retry download up to 3 times
for i in {1..3}; do
  if curl -fsSL https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -o "$TEMP_MANIFEST"; then
    break
  fi
  if [ $i -eq 3 ]; then
    echo "❌ Failed to download ArgoCD manifest after 3 attempts"
    exit 1
  fi
  echo "⚠️  Download attempt $i failed, retrying..."
  sleep 2
done

# Apply with retry logic
echo "🔄 Applying ArgoCD manifest..."
MAX_RETRIES=3
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if kubectl apply -n argocd -f "$TEMP_MANIFEST"; then
    echo "✅ ArgoCD manifest applied successfully"
    break
  fi
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
    echo "⚠️  Apply attempt $RETRY_COUNT failed, retrying in 5 seconds..."
    sleep 5
  else
    echo "❌ Failed to apply ArgoCD manifest after $MAX_RETRIES attempts"
    echo "💡 Tip: Check if ArgoCD is partially installed: kubectl get all -n argocd"
    exit 1
  fi
done

# Step 2: Wait for readiness
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd \
  --timeout=300s

# Step 3: Apply AppProjects
echo "📋 Applying AppProjects..."
kubectl apply -f argocd/appproject.yml
kubectl apply -f argocd/morichal-ai-dev-appproject.yml

# Step 4: Apply App-of-Apps
echo "🔄 Applying App-of-Apps..."
kubectl apply -f argocd/environments/dev/operators-app-of-apps.yml
kubectl apply -f argocd/environments/dev/apps-app-of-apps.yml

echo "✅ Bootstrap complete!"
echo "📊 Check status: kubectl get applications -n argocd"
echo "🔑 Get admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"

