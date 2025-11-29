# k8s-infra

This repository contains Kubernetes infrastructure configurations managed by ArgoCD.

## Structure

```
k8s-infra/
├── operators/                          # Shared infrastructure operators (no env-specific naming)
│   ├── ingress-nginx-app.yml
│   ├── cert-manager-app.yml
│   ├── loki-app.yml
│   ├── prometheus-operator-app.yml
│   └── ...
├── apps/                               # Shared application deployments (no env-specific naming)
│   ├── morichal-ai-frontend-app.yml
│   └── morichal-ai-backend-app.yml
├── argocd/                                     # ArgoCD bootstrap configuration
│   ├── appproject.yml                         # AppProject definition (shared)
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── operators-app-of-apps.yml      # Dev cluster operators bootstrap
│   │   │   └── apps-app-of-apps.yml           # Dev cluster apps bootstrap
│   │   ├── staging/
│   │   │   ├── operators-app-of-apps.yml      # Staging cluster operators bootstrap
│   │   │   └── apps-app-of-apps.yml           # Staging cluster apps bootstrap
│   │   └── prod/
│   │       ├── operators-app-of-apps.yml      # Prod cluster operators bootstrap
│   │       └── apps-app-of-apps.yml           # Prod cluster apps bootstrap
│   └── legacy/                                 # Legacy single-cluster files (reference only)
│       ├── k8s-infra-operators-app-of-apps.yml
│       └── k8s-infra-apps-app-of-apps.yml
├── scripts/
│   └── register-cluster.sh                    # Helper script for cluster registration
└── docs/
    └── MULTI_CLUSTER_SETUP.md                  # Multi-cluster setup guide
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

**Manual Bootstrap:** See [argocd/BOOTSTRAP.md](argocd/BOOTSTRAP.md) for detailed step-by-step instructions.

### Quick Reference:

1. **Install ArgoCD**:
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
   ```

2. **Apply AppProject**:
   ```bash
   kubectl apply -f argocd/appproject.yml
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

This repository uses the App of Apps pattern with two separate entry points:

1. **`k8s-infra-operators-app-of-apps.yml`** - Manages infrastructure operators
2. **`k8s-infra-apps-app-of-apps.yml`** - Manages application deployments

ArgoCD will automatically discover and sync all Application manifests in the respective directories.

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

- **Repository**: `git@github.com:dijarvrella/k8s-infra.git`
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

1. Create the Application manifest in `apps/your-app-app.yml`
2. Commit and push to the repository
3. ArgoCD will automatically discover and sync it

### Updating resources:

1. Modify the Application manifest or the resource manifests
2. Commit and push to the repository
3. ArgoCD will automatically sync the changes
