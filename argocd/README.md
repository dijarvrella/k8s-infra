# ArgoCD Bootstrap Configuration

This directory contains the ArgoCD bootstrap configuration files that are applied manually to each cluster to set up GitOps.

## Structure

```
argocd/
├── appproject.yml                    # ArgoCD AppProject definition (shared across all environments)
└── environments/
    ├── dev/
    │   ├── operators-app-of-apps.yml # Bootstrap operators for dev cluster
    │   └── apps-app-of-apps.yml     # Bootstrap apps for dev cluster
    ├── staging/
    │   ├── operators-app-of-apps.yml # Bootstrap operators for staging cluster
    │   └── apps-app-of-apps.yml     # Bootstrap apps for staging cluster
    └── prod/
        ├── operators-app-of-apps.yml # Bootstrap operators for prod cluster
        └── apps-app-of-apps.yml     # Bootstrap apps for prod cluster
```

## Bootstrap Process

### For Each Environment

1. **Install ArgoCD** (if not already installed):
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

2. **Wait for ArgoCD to be ready**:
   ```bash
   kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
   ```

3. **Apply the AppProject** (shared across all environments):
   ```bash
   kubectl apply -f argocd/appproject.yml
   ```

4. **Apply the App-of-Apps for your environment**:
   
   **Dev:**
   ```bash
   kubectl apply -f argocd/environments/dev/operators-app-of-apps.yml
   kubectl apply -f argocd/environments/dev/apps-app-of-apps.yml
   ```
   
   **Staging:**
   ```bash
   kubectl apply -f argocd/environments/staging/operators-app-of-apps.yml
   kubectl apply -f argocd/environments/staging/apps-app-of-apps.yml
   ```
   
   **Prod:**
   ```bash
   kubectl apply -f argocd/environments/prod/operators-app-of-apps.yml
   kubectl apply -f argocd/environments/prod/apps-app-of-apps.yml
   ```

## File Details

### `appproject.yml`
- Defines the `k8s-infra` AppProject
- Shared across all environments
- Defines RBAC policies and resource permissions

### `environments/{env}/operators-app-of-apps.yml`
- Creates the `k8s-infra-operators` Application
- Targets the appropriate git branch:
  - `dev` → dev branch
  - `staging` → staging branch
  - `prod` → main branch
- Discovers and syncs all operator Applications from `operators/` directory

### `environments/{env}/apps-app-of-apps.yml`
- Creates the `k8s-infra-apps` Application
- Targets the appropriate git branch
- Discovers and syncs all application Applications from `apps/` directory

## Important Notes

- These files are **manually applied** to bootstrap ArgoCD on each cluster
- Once applied, ArgoCD manages itself and all other resources via GitOps
- Each environment uses the same Application names but in separate clusters
- The `environment` label distinguishes them when needed

