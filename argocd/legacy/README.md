# Legacy App-of-Apps Files

This directory contains the original single-cluster app-of-apps files that were used before the multi-cluster setup.

## Files

- `k8s-infra-operators-app-of-apps.yml` - Original operators app-of-apps (targets `main` branch)
- `k8s-infra-apps-app-of-apps.yml` - Original apps app-of-apps (targets `main` branch)

## Migration

These files have been replaced by the environment-specific files in `argocd/environments/prod/`:
- `argocd/environments/prod/operators-app-of-apps.yml`
- `argocd/environments/prod/apps-app-of-apps.yml`

The new prod files are functionally identical but include the `environment: prod` label for better organization.

## Usage

These files are kept for reference only. For new deployments, use the files in `argocd/environments/prod/`.

