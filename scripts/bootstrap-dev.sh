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
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

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

