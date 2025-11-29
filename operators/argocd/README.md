# ArgoCD Self-Management

This directory contains ArgoCD configurations for managing ArgoCD itself and its ingress.

## Applications

### argocd-self-managed-app.yml

Manages ArgoCD itself using the official ArgoCD manifests from the stable branch.

**Important Notes:**
- This Application uses `ignoreDifferences` to prevent ArgoCD from managing certain secrets that contain runtime-generated data
- The `ServerSideApply=true` option helps with managing existing resources
- This should be applied **after** ArgoCD is initially installed

**Bootstrap Process:**
1. Install ArgoCD manually first:
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

2. Once ArgoCD is running, apply this Application:
   ```bash
   kubectl apply -f operators/argocd/argocd-self-managed-app.yml
   ```

3. ArgoCD will then manage itself going forward.

### argocd-ingress-app.yml

Manages the ArgoCD server ingress resource.

- **Manifest**: `argocd-ingress.yaml`
- **Namespace**: `argocd`
- Provides external access to ArgoCD server with TLS

