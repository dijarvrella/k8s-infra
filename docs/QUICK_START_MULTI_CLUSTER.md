# Quick Start: Multi-Cluster Setup

## Prerequisites

- Dev cluster already set up (current setup)
- DigitalOcean account with access to create Kubernetes clusters
- `doctl` CLI installed and authenticated
- `kubectl` configured
- `argocd` CLI installed

## Step-by-Step Setup

### 1. Create Git Branches

```bash
cd /path/to/k8s-infra

# Create dev branch (if not exists)
git checkout -b dev
git push -u origin dev

# Create staging branch
git checkout -b staging
git push -u origin staging

# Return to main
git checkout main
```

### 2. Create Staging Cluster on DigitalOcean

```bash
# Create cluster (adjust size/region as needed)
doctl kubernetes cluster create staging-cluster \
  --region nyc1 \
  --node-pool "name=worker-pool;size=s-2vcpu-4gb;count=3" \
  --wait

# Save kubeconfig
doctl kubernetes cluster kubeconfig save staging-cluster
```

### 3. Install ArgoCD on Staging Cluster

```bash
# Switch to staging context
kubectl config use-context do-nyc1-staging-cluster

# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for readiness
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### 4. Bootstrap Staging Environment

```bash
# Ensure you're on staging cluster context
kubectl config current-context  # Should show staging cluster

# Apply AppProject
kubectl apply -f argocd/appproject.yml

# Apply app-of-apps for staging
kubectl apply -f argocd/environments/staging/operators-app-of-apps.yml
kubectl apply -f argocd/environments/staging/apps-app-of-apps.yml
```

### 5. Verify Setup

```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Access ArgoCD UI (port-forward)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Workflow Examples

### Deploy to Dev

```bash
git checkout dev
# Make your changes
git add .
git commit -m "Update configuration"
git push origin dev
# ArgoCD on dev cluster automatically syncs
```

### Promote to Staging

```bash
git checkout staging
git merge dev
git push origin staging
# ArgoCD on staging cluster automatically syncs
```

### Promote to Production

```bash
git checkout main
git merge staging
git push origin main
# ArgoCD on prod cluster automatically syncs
```

## Important Notes

1. **Same Resources**: All environments use the same files from `operators/` and `apps/` - no duplication needed
2. **Branch Targeting**: Each app-of-apps targets a specific branch:
   - Dev app-of-apps → `dev` branch
   - Staging app-of-apps → `staging` branch
   - Prod app-of-apps → `main` branch
3. **Separate ArgoCD Instances**: Each cluster has its own ArgoCD instance managing itself
   - Dev cluster: ArgoCD on dev cluster manages dev cluster
   - Staging cluster: ArgoCD on staging cluster manages staging cluster
   - Prod cluster: ArgoCD on prod cluster manages prod cluster
4. **No Environment Names**: Resources don't contain "dev", "staging", or "prod" in their names
5. **Self-Contained**: Each environment is completely isolated and independent

## Troubleshooting

### ArgoCD Not Syncing
```bash
# Check repo-server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server --tail=50

# Force refresh
argocd app get <app-name> --refresh --grpc-web
```

### Wrong Branch Deployed
- Verify the app-of-apps `targetRevision` matches the intended branch
- Check git branch exists: `git branch -a`

### Cluster Connection Issues
- Verify kubeconfig: `kubectl config get-contexts`
- Test cluster access: `kubectl get nodes`

