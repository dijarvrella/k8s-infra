# k8s-infra

This repository contains Kubernetes infrastructure configurations managed by ArgoCD.

## Structure

```
k8s-infra/
├── operators/                          # Infrastructure operators organized by environment
│   ├── argocd/                         # ArgoCD configuration (values, ingress)
│   ├── cert-manager/                   # cert-manager cluster issuers
│   ├── dev/                            # Dev environment operators
│   │   ├── argocd-ingress-app-dev.yml
│   │   ├── cert-manager-app.yml
│   │   ├── ingress-nginx-app-dev.yml
│   │   ├── loki-app.yml
│   │   ├── prometheus-operator-app.yml
│   │   └── promtail-app.yml
│   ├── staging/                        # Staging environment operators
│   │   └── ...
│   └── prod/                           # Production environment operators
│       └── ...
├── apps/                               # Application deployments organized by environment
│   ├── dev/                            # Dev environment applications
│   │   ├── morichal-ai-frontend-app.yml
│   │   └── morichal-ai-backend-app.yml
│   ├── staging/                        # Staging environment applications
│   │   └── ...
│   └── prod/                           # Production environment applications
│       └── ...
├── argocd/                             # ArgoCD bootstrap configuration
│   ├── appproject.yml                  # Shared AppProject definition
│   └── environments/
│       ├── dev/
│       │   ├── morichal-ai-dev-appproject.yml
│       │   ├── operators-app-of-apps.yml
│       │   └── apps-app-of-apps.yml
│       ├── staging/
│       │   ├── morichal-ai-staging-appproject.yml
│       │   ├── operators-app-of-apps.yml
│       │   └── apps-app-of-apps.yml
│       └── prod/
│           ├── morichal-ai-prod-appproject.yml
│           ├── operators-app-of-apps.yml
│           └── apps-app-of-apps.yml
├── scripts/
│   ├── bootstrap-dev.sh
│   ├── bootstrap-staging.sh
│   └── bootstrap-prod.sh
└── docs/
    └── MULTI_CLUSTER_SETUP.md
```

## Bootstrap Process

**Quick Start:** Use the bootstrap scripts for your environment:
```bash
# Dev
./scripts/bootstrap-dev.sh

# Staging
./scripts/bootstrap-staging.sh

# Production
./scripts/bootstrap-prod.sh
```

### Quick Reference:

1. **Install ArgoCD** (handled by bootstrap scripts):
   ```bash
   kubectl create namespace argocd
   helm repo add argo https://argoproj.github.io/argo-helm
   helm repo update
   helm upgrade --install argocd argo/argo-cd \
     --namespace argocd \
     --values operators/argocd/values-<env>.yaml \
     --wait
   ```

2. **Apply AppProjects**:
   ```bash
   # Shared AppProject
   kubectl apply -f argocd/appproject.yml
   
   # Environment-specific AppProject
   # Dev
   kubectl apply -f argocd/environments/dev/morichal-ai-dev-appproject.yml
   
   # Staging
   kubectl apply -f argocd/environments/staging/morichal-ai-staging-appproject.yml
   
   # Prod
   kubectl apply -f argocd/environments/prod/morichal-ai-prod-appproject.yml
   ```

3. **Apply App-of-Apps** (choose environment):
   ```bash
   # Dev
   kubectl apply -f argocd/environments/dev/operators-app-of-apps.yml
   kubectl apply -f argocd/environments/dev/apps-app-of-apps.yml
   
   # Staging
   kubectl apply -f argocd/environments/staging/operators-app-of-apps.yml
   kubectl apply -f argocd/environments/staging/apps-app-of-apps.yml
   
   # Prod
   kubectl apply -f argocd/environments/prod/operators-app-of-apps.yml
   kubectl apply -f argocd/environments/prod/apps-app-of-apps.yml
   ```

## App of Apps Pattern

This repository uses the App of Apps pattern with environment-specific entry points:

1. **`operators-app-of-apps.yml`** - Manages infrastructure operators for each environment
2. **`apps-app-of-apps.yml`** - Manages application deployments for each environment

ArgoCD will automatically discover and sync all Application manifests in the respective directories:
- Operators: `operators/<env>/`
- Applications: `apps/<env>/`

## Operators

Infrastructure operators that provide cluster-wide capabilities.

### Ingress NGINX Controller

- **Application**: `operators/ingress-nginx-app.yml`
- **Source**: Helm chart from `https://kubernetes.github.io/ingress-nginx`
- **Namespace**: `ingress-nginx`
- **Project**: `k8s-infra`
- Manages the NGINX Ingress Controller for the cluster

### cert-manager

- **Application**: `operators/cert-manager-app.yml`
- **Source**: Helm chart from `https://charts.jetstack.io`
- **Namespace**: `cert-manager`
- **Project**: `k8s-infra`
- Manages TLS certificates using Let's Encrypt

### ArgoCD

- **Ingress Application**: `operators/argocd-ingress-app.yml`
- Manages the ArgoCD server ingress for external access

### Prometheus Operator

- **Application**: `operators/prometheus-operator-app.yml`
- **Source**: Helm chart from `https://prometheus-community.github.io/helm-charts`
- **Namespace**: `monitoring`
- **Project**: `k8s-infra`
- Includes Prometheus, Grafana, and Alertmanager
- Provides cluster-wide metrics collection and monitoring

### Loki

- **Application**: `operators/loki-app.yml`
- **Source**: Helm chart from `https://grafana.github.io/helm-charts`
- **Namespace**: `monitoring`
- **Project**: `k8s-infra`
- Provides log aggregation and storage
- Includes Promtail for log collection

## Applications

Application deployments managed by ArgoCD.

### morichal-ai-frontend

- **Application**: `apps/morichal-ai-frontend-app.yml`
- **Namespace**: `morichal-ai-frontend`
- **Project**: `morichal-ai-dev`

### morichal-ai-backend

- **Application**: `apps/morichal-ai-backend-app.yml`
- **Namespace**: `morichal-ai-backend`
- **Project**: `morichal-ai-dev`

## Multi-Cluster Deployment

This repository supports deploying the same infrastructure stack across multiple Kubernetes clusters using branch-based GitOps:

- **`dev` branch** → Dev cluster
- **`staging` branch** → Staging cluster (DigitalOcean)
- **`main` branch** → Production cluster

**Key Benefits:**
- ✅ Same resource files across all environments (no duplication)
- ✅ No environment-specific naming in resources
- ✅ Natural promotion path: dev → staging → prod
- ✅ Complete isolation between environments

See [docs/MULTI_CLUSTER_SETUP.md](docs/MULTI_CLUSTER_SETUP.md) for detailed setup instructions.

## Git Repository

- **Repository**: `git@github.com:Deploy-Staff/morichal-k8s-infra.git`
- **Branches**:
  - `main` - Production environment
  - `staging` - Staging environment
  - `dev` - Development environment

## Usage

### Adding a new operator:

1. Create a directory in `operators/your-operator/`
2. Create the Application manifest: `operators/your-operator/your-operator-app.yml`
3. Add operator manifests to the directory
4. Commit and push to the repository
5. ArgoCD will automatically discover and sync it

### Adding a new application:

1. Create the Application manifest in `apps/<env>/your-app-app.yml` (where `<env>` is `dev`, `staging`, or `prod`)
2. Commit and push to the repository
3. ArgoCD will automatically discover and sync it

### Updating resources:

1. Modify the Application manifest or the resource manifests
2. Commit and push to the repository
3. ArgoCD will automatically sync the changes
