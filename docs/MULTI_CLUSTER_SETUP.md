# Multi-Cluster Setup Guide

This guide explains how to deploy the same infrastructure stack across multiple Kubernetes clusters using branch-based GitOps.

## Architecture Overview

- **Same Resource Files**: All environments use identical resource files from `operators/` and `apps/` directories
- **Branch-Based Targeting**: Different git branches target different environments
  - `dev` branch → Dev cluster
  - `staging` branch → Staging cluster  
  - `main` branch → Production cluster
- **Environment-Specific App-of-Apps**: Each cluster has its own app-of-apps that targets the appropriate branch

## Directory Structure

```
k8s-infra/
├── operators/                          # Shared operator definitions (no env-specific naming)
│   ├── loki-app.yml
│   ├── prometheus-operator-app.yml
│   └── ...
├── apps/                               # Shared application definitions (no env-specific naming)
│   ├── morichal-ai-backend-app.yml
│   └── morichal-ai-frontend-app.yml
├── k8s-infra-operators-app-of-apps-dev.yml      # Dev cluster entry point
├── k8s-infra-operators-app-of-apps-staging.yml # Staging cluster entry point
├── k8s-infra-operators-app-of-apps-prod.yml    # Prod cluster entry point
├── k8s-infra-apps-app-of-apps-dev.yml          # Dev cluster entry point
├── k8s-infra-apps-app-of-apps-staging.yml      # Staging cluster entry point
└── k8s-infra-apps-app-of-apps-prod.yml         # Prod cluster entry point
```

## Setup Steps

### 1. Create Git Branches

```bash
# Create and push branches
git checkout -b dev
git push -u origin dev

git checkout -b staging
git push -u origin staging

# Main branch is already your production branch
```

### 2. Set Up Staging Cluster on DigitalOcean

1. Create a new Kubernetes cluster in DigitalOcean
2. Get the kubeconfig:
   ```bash
   doctl kubernetes cluster kubeconfig save <cluster-name>
   ```

### 3. Install ArgoCD on Staging Cluster

```bash
# Switch to staging cluster context
kubectl config use-context <staging-cluster-context>

# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### 4. Architecture: Separate ArgoCD Instances

**Each cluster has its own ArgoCD instance managing itself:**

- **Dev cluster**: ArgoCD manages dev cluster (current setup)
- **Staging cluster**: ArgoCD manages staging cluster
- **Prod cluster**: ArgoCD manages prod cluster

This is the default and recommended setup. Each app-of-apps uses `server: https://kubernetes.default.svc` which means "this cluster" - ArgoCD manages the cluster it's running on.

**Benefits:**
- ✅ Complete isolation between environments
- ✅ No single point of failure
- ✅ Simpler setup (no cluster registration needed)
- ✅ Each environment is self-contained

### 5. Bootstrap Each Environment

#### Dev Environment (Current)
```bash
kubectl config use-context <dev-cluster-context>
kubectl apply -f argocd/appproject.yml
kubectl apply -f argocd/environments/dev/operators-app-of-apps.yml
kubectl apply -f argocd/environments/dev/apps-app-of-apps.yml
```

#### Staging Environment
```bash
kubectl config use-context <staging-cluster-context>
kubectl apply -f argocd/appproject.yml
kubectl apply -f argocd/environments/staging/operators-app-of-apps.yml
kubectl apply -f argocd/environments/staging/apps-app-of-apps.yml
```

#### Production Environment
```bash
kubectl config use-context <prod-cluster-context>
kubectl apply -f argocd/appproject.yml
kubectl apply -f argocd/environments/prod/operators-app-of-apps.yml
kubectl apply -f argocd/environments/prod/apps-app-of-apps.yml
```

## Workflow

### Making Changes

1. **For Dev**: Make changes and commit to `dev` branch
   ```bash
   git checkout dev
   # Make changes
   git commit -m "Update Loki config"
   git push origin dev
   ```
   ArgoCD on dev cluster automatically syncs

2. **For Staging**: Merge dev → staging
   ```bash
   git checkout staging
   git merge dev
   git push origin staging
   ```
   ArgoCD on staging cluster automatically syncs

3. **For Production**: Merge staging → main
   ```bash
   git checkout main
   git merge staging
   git push origin main
   ```
   ArgoCD on prod cluster automatically syncs

### Environment-Specific Configuration

If you need environment-specific values (e.g., different resource limits, different storage sizes), you can:

1. **Use Helm values overrides** in the Application manifests
2. **Use Kustomize overlays** (create `kustomization.yaml` files)
3. **Use ArgoCD Application parameters** for environment-specific values

Example with Helm values:
```yaml
# operators/loki-app.yml
spec:
  helm:
    values: |
      singleBinary:
        replicas: 1
        persistence:
          size: 50Gi  # Can be overridden per environment
```

Then create environment-specific overrides:
```yaml
# operators/loki-app-staging-override.yml (if needed)
# Or use ArgoCD Application parameters
```

## Benefits of This Approach

✅ **Same Resources**: No duplication, same files across all environments  
✅ **No Environment Names in Resources**: Resources are generic, environment is determined by branch/cluster  
✅ **Git-Based Promotion**: Natural promotion path: dev → staging → prod  
✅ **Isolation**: Each environment is completely isolated  
✅ **Easy Rollback**: Just revert the git branch  

## Troubleshooting

### ArgoCD Not Syncing
- Check if the branch exists and has the latest changes
- Verify the app-of-apps is pointing to the correct branch
- Check ArgoCD logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server`

### Cluster Connection Issues
- Verify you're using the correct kubeconfig context
- Check cluster access: `kubectl get nodes`
- Ensure ArgoCD is installed on the target cluster

### Resource Conflicts
- Ensure resource names don't conflict (they shouldn't since each cluster is separate)
- Check namespaces are created correctly

## Next Steps

1. Create `dev` and `staging` branches
2. Set up staging cluster on DigitalOcean
3. Install ArgoCD on staging cluster
4. Apply the staging app-of-apps files
5. Test the workflow by making a change to dev branch

