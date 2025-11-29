# Architecture: Multi-Cluster GitOps

## Overview

This repository implements a **branch-based, multi-cluster GitOps** architecture where each Kubernetes cluster has its own ArgoCD instance managing itself.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Git Repository                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │   dev    │  │ staging  │  │   main    │                 │
│  │  branch  │  │  branch  │  │  branch  │                 │
│  └──────────┘  └──────────┘  └──────────┘                 │
│       │              │              │                        │
└───────┼──────────────┼──────────────┼────────────────────────┘
        │              │              │
        ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Dev Cluster │ │Staging Cluster│ │ Prod Cluster │
│              │ │              │ │              │
│  ┌────────┐  │ │  ┌────────┐  │ │  ┌────────┐  │
│  │ ArgoCD │  │ │  │ ArgoCD │  │ │  │ ArgoCD │  │
│  └───┬────┘  │ │  └───┬────┘  │ │  └───┬────┘  │
│      │       │ │      │       │ │      │       │
│      └───────┼─┘      └───────┼─┘      └───────┼─┘
│              │                 │                 │
│  Manages     │  Manages        │  Manages       │
│  Dev Cluster │  Staging Cluster│  Prod Cluster  │
└──────────────┘ └──────────────┘ └──────────────┘
```

## Key Principles

### 1. Separate ArgoCD Instances
- Each cluster runs its own ArgoCD instance
- Each ArgoCD manages only the cluster it's running on
- No cross-cluster dependencies
- Complete isolation between environments

### 2. Same Resource Files
- All environments use identical resource files from:
  - `operators/` - Infrastructure operators
  - `apps/` - Application deployments
- No environment-specific file duplication
- No environment names in resource names

### 3. Branch-Based Targeting
- **dev branch** → Dev cluster
- **staging branch** → Staging cluster
- **main branch** → Production cluster
- Each app-of-apps targets a specific branch

### 4. Self-Contained Environments
- Each environment is completely independent
- No shared infrastructure between environments
- Each cluster can be managed separately

## Component Details

### App-of-Apps Pattern

Each environment has two app-of-apps entry points, organized under `argocd/environments/{env}/`:

1. **Operators App-of-Apps**
   - `argocd/environments/{env}/operators-app-of-apps.yml`
   - Manages infrastructure operators (Loki, Prometheus, etc.)
   - Targets `operators/` directory

2. **Applications App-of-Apps**
   - `argocd/environments/{env}/apps-app-of-apps.yml`
   - Manages application deployments
   - Targets `apps/` directory

### Cluster Configuration

Each app-of-apps uses:
```yaml
destination:
  server: https://kubernetes.default.svc  # "This cluster"
  namespace: argocd
```

The `https://kubernetes.default.svc` means ArgoCD manages the cluster it's running on.

### Resource Structure

```
operators/                    # Shared across all environments
├── loki-app.yml             # Same file for dev/staging/prod
├── prometheus-operator-app.yml
└── ...

apps/                        # Shared across all environments
├── morichal-ai-backend-app.yml
└── morichal-ai-frontend-app.yml
```

## Deployment Flow

### Development
1. Developer makes changes
2. Commits to `dev` branch
3. Pushes to GitHub
4. ArgoCD on dev cluster detects change
5. ArgoCD syncs dev cluster

### Staging Promotion
1. Merge `dev` → `staging` branch
2. Push to GitHub
3. ArgoCD on staging cluster detects change
4. ArgoCD syncs staging cluster

### Production Promotion
1. Merge `staging` → `main` branch
2. Push to GitHub
3. ArgoCD on prod cluster detects change
4. ArgoCD syncs prod cluster

## Benefits

✅ **Isolation**: Complete separation between environments  
✅ **No Duplication**: Same files, different branches  
✅ **Self-Contained**: Each cluster is independent  
✅ **Simple Promotion**: Natural git workflow  
✅ **No Single Point of Failure**: Each environment has its own ArgoCD  
✅ **Easy Rollback**: Revert git branch  

## Comparison with Hub Model

| Aspect | Separate ArgoCD (Current) | Hub Model |
|--------|-------------------------|-----------|
| Setup Complexity | Simple | More complex |
| Cluster Registration | Not needed | Required |
| Single Point of Failure | No | Yes (hub cluster) |
| Network Requirements | None | Hub must reach all clusters |
| Isolation | Complete | Shared ArgoCD instance |
| Recommended | ✅ Yes | ❌ Not recommended |

## Security Considerations

- Each ArgoCD instance only has access to its own cluster
- No cross-cluster credentials needed
- RBAC can be configured per environment
- Network isolation between environments

