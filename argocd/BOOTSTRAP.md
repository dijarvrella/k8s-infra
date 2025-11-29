# ArgoCD Bootstrap Guide

Complete step-by-step guide to bootstrap ArgoCD and GitOps on a new cluster.

## Prerequisites

- `kubectl` configured with access to your cluster
- Cluster context set correctly: `kubectl config current-context`

## Bootstrap Sequence

### Step 1: Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Step 2: Wait for ArgoCD to be Ready

```bash
# Wait for ArgoCD server to be ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd \
  --timeout=300s

# Verify all pods are running
kubectl get pods -n argocd
```

**Expected output:** All pods should be in `Running` state.

### Step 3: Apply AppProject

```bash
# Apply the shared AppProject
kubectl apply -f argocd/appproject.yml
```

### Step 4: Apply Environment-Specific App-of-Apps

Choose the appropriate environment:

#### For Dev Environment
```bash
kubectl apply -f argocd/environments/dev/operators-app-of-apps.yml
kubectl apply -f argocd/environments/dev/apps-app-of-apps.yml
```

#### For Staging Environment
```bash
kubectl apply -f argocd/environments/staging/operators-app-of-apps.yml
kubectl apply -f argocd/environments/staging/apps-app-of-apps.yml
```

#### For Production Environment
```bash
kubectl apply -f argocd/environments/prod/operators-app-of-apps.yml
kubectl apply -f argocd/environments/prod/apps-app-of-apps.yml
```

### Step 5: Verify Bootstrap

```bash
# Check ArgoCD Applications
kubectl get applications -n argocd

# Check AppProject
kubectl get appproject -n argocd

# Get ArgoCD admin password (for UI access)
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

## Complete Bootstrap Script

Here's a complete script for each environment:

### Dev Environment Bootstrap

```bash
#!/bin/bash
set -e

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

# Step 3: Apply AppProject
echo "📋 Applying AppProject..."
kubectl apply -f argocd/appproject.yml

# Step 4: Apply App-of-Apps
echo "🔄 Applying App-of-Apps..."
kubectl apply -f argocd/environments/dev/operators-app-of-apps.yml
kubectl apply -f argocd/environments/dev/apps-app-of-apps.yml

echo "✅ Bootstrap complete!"
echo "📊 Check status: kubectl get applications -n argocd"
```

### Staging Environment Bootstrap

```bash
#!/bin/bash
set -e

echo "🚀 Bootstrapping Staging Environment..."

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

# Step 3: Apply AppProject
echo "📋 Applying AppProject..."
kubectl apply -f argocd/appproject.yml

# Step 4: Apply App-of-Apps
echo "🔄 Applying App-of-Apps..."
kubectl apply -f argocd/environments/staging/operators-app-of-apps.yml
kubectl apply -f argocd/environments/staging/apps-app-of-apps.yml

echo "✅ Bootstrap complete!"
echo "📊 Check status: kubectl get applications -n argocd"
```

### Production Environment Bootstrap

```bash
#!/bin/bash
set -e

echo "🚀 Bootstrapping Production Environment..."

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

# Step 3: Apply AppProject
echo "📋 Applying AppProject..."
kubectl apply -f argocd/appproject.yml

# Step 4: Apply App-of-Apps
echo "🔄 Applying App-of-Apps..."
kubectl apply -f argocd/environments/prod/operators-app-of-apps.yml
kubectl apply -f argocd/environments/prod/apps-app-of-apps.yml

echo "✅ Bootstrap complete!"
echo "📊 Check status: kubectl get applications -n argocd"
```

## Quick Reference

### One-Liner Commands

**Dev:**
```bash
kubectl create namespace argocd && \
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml && \
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s && \
kubectl apply -f argocd/appproject.yml && \
kubectl apply -f argocd/environments/dev/operators-app-of-apps.yml && \
kubectl apply -f argocd/environments/dev/apps-app-of-apps.yml
```

**Staging:**
```bash
kubectl create namespace argocd && \
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml && \
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s && \
kubectl apply -f argocd/appproject.yml && \
kubectl apply -f argocd/environments/staging/operators-app-of-apps.yml && \
kubectl apply -f argocd/environments/staging/apps-app-of-apps.yml
```

**Prod:**
```bash
kubectl create namespace argocd && \
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml && \
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s && \
kubectl apply -f argocd/appproject.yml && \
kubectl apply -f argocd/environments/prod/operators-app-of-apps.yml && \
kubectl apply -f argocd/environments/prod/apps-app-of-apps.yml
```

## Post-Bootstrap

### Access ArgoCD UI

```bash
# Port-forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Login via CLI
argocd login localhost:8080 --username admin --insecure --grpc-web
```

### Monitor Applications

```bash
# Watch all applications
kubectl get applications -n argocd -w

# Check specific application
kubectl get application k8s-infra-operators -n argocd

# Get application details
argocd app get k8s-infra-operators --grpc-web
```

## Troubleshooting

### ArgoCD Pods Not Ready

```bash
# Check pod status
kubectl get pods -n argocd

# Check pod logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Check events
kubectl get events -n argocd --sort-by='.lastTimestamp'
```

### Applications Not Syncing

```bash
# Check application status
kubectl get applications -n argocd

# Check application conditions
kubectl describe application k8s-infra-operators -n argocd

# Check repo-server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server --tail=50
```

