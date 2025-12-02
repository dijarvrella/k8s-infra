# ArgoCD Configuration

This directory contains ArgoCD configurations for managing ArgoCD installation, ingress, and OAuth setup.

## Installation

ArgoCD is installed using Helm via the bootstrap scripts. See the main repository README for bootstrap instructions.

### Helm Values Files

- `values-dev.yaml` - ArgoCD configuration for Dev environment
- `values-staging.yaml` - ArgoCD configuration for Staging environment  
- `values-prod.yaml` - ArgoCD configuration for Production environment

Each values file includes:
- Ingress configuration
- GitHub OAuth configuration (requires setup - see GITHUB_OAUTH_SETUP.md)
- Resource sizing (replicas, etc.)

## GitHub OAuth Setup

ArgoCD is configured with GitHub OAuth for authentication. **You must configure OAuth before deploying.**

See [GITHUB_OAUTH_SETUP.md](./GITHUB_OAUTH_SETUP.md) for detailed instructions on:
- Creating a GitHub OAuth App
- Configuring the values files
- Setting up RBAC policies
- Troubleshooting

**Quick Start:**
1. Create a GitHub OAuth App (see GITHUB_OAUTH_SETUP.md)
2. Update the appropriate values file (`values-<env>.yaml`) with your Client ID and Secret
3. Run the bootstrap script for your environment

## Applications

### ArgoCD Application (Optional)

The `argocd-app-<env>.yml` files can be used to manage ArgoCD via GitOps after initial bootstrap.
These are optional and primarily useful for ongoing configuration management.

**Note**: The bootstrap scripts handle the initial installation. The Application files are for future GitOps management.

### Ingress Applications

- `argocd-ingress-dev.yaml` - Ingress for Dev environment
- `argocd-ingress-staging.yaml` - Ingress for Staging environment
- `argocd-ingress-prod.yaml` - Ingress for Production environment

These are managed via the operators directory structure and provide external access to ArgoCD with TLS.

