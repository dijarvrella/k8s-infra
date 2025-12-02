# GitHub OAuth Setup for ArgoCD

This guide explains how to configure GitHub OAuth authentication for ArgoCD in your Kubernetes clusters.

## Prerequisites

- A GitHub account with organization access (if using organization-based authentication)
- Access to your Kubernetes cluster
- Helm 3.x installed
- kubectl configured to access your cluster

## Step 1: Create a GitHub OAuth Application

1. Navigate to your GitHub account settings:
   - Go to **Settings** → **Developer settings** → **OAuth Apps**
   - Or for organization: **Organization Settings** → **Developer settings** → **OAuth Apps**

2. Click **New OAuth App**

3. Fill in the application details:
   - **Application name**: `ArgoCD - <Environment>` (e.g., `ArgoCD - Dev`)
   - **Homepage URL**: Your ArgoCD URL
     - Dev: `https://argocd.dev.morichalcorp.com`
     - Staging: `https://argocd.staging.morichalcorp.com`
     - Prod: `https://argocd.app.morichalcorp.com`
   - **Authorization callback URL**: 
     - Dev: `https://argocd.dev.morichalcorp.com/api/auth/callback`
     - Staging: `https://argocd.staging.morichalcorp.com/api/auth/callback`
     - Prod: `https://argocd.app.morichalcorp.com/api/auth/callback`

4. Click **Register application**

5. **Important**: Copy the **Client ID** and generate a **Client Secret** (click "Generate a new client secret")
   - Save these values securely - you'll need them in the next step

## Step 2: Update Helm Values Files

For each environment, update the corresponding values file with your GitHub OAuth credentials:

### Dev Environment

Edit `operators/argocd/values-dev.yaml`:

```yaml
server:
  config:
    oidc.config: |
      name: GitHub
      issuer: https://github.com
      clientID: YOUR_CLIENT_ID_HERE
      clientSecret: YOUR_CLIENT_SECRET_HERE
      requestedScopes: ["openid", "profile", "email", "read:org"]
```

### Staging Environment

Edit `operators/argocd/values-staging.yaml` and replace the placeholder values.

### Production Environment

Edit `operators/argocd/values-prod.yaml` and replace the placeholder values.

**Security Note**: For production, consider using:
- A separate values file that's gitignored (e.g., `values-prod-secrets.yaml`)
- Sealed Secrets or External Secrets Operator
- Helm secrets plugin with encrypted values

## Step 3: Install/Upgrade ArgoCD

Run the bootstrap script for your environment:

```bash
# For Dev
./scripts/bootstrap-dev.sh

# For Staging
./scripts/bootstrap-staging.sh

# For Prod
./scripts/bootstrap-prod.sh
```

The bootstrap script will:
1. Add the ArgoCD Helm repository
2. Install/upgrade ArgoCD using Helm with your values file
3. Configure OAuth automatically

## Step 4: Configure RBAC (Optional)

To map GitHub teams/organizations to ArgoCD roles, you can configure RBAC policies.

### Option 1: Using ConfigMap (Recommended)

Create or update the `argocd-rbac-cm` ConfigMap:

```bash
kubectl edit configmap argocd-rbac-cm -n argocd
```

Add policies like:

```yaml
policy.default: role:readonly
policy.csv: |
  # Map GitHub organization teams to ArgoCD roles
  g, github-org:admins, role:admin
  g, github-org:developers, role:readonly
  g, github-org:ops, role:admin
```

### Option 2: Using Helm Values

You can also add RBAC configuration to your values file:

```yaml
server:
  config:
    policy.default: role:readonly
    policy.csv: |
      g, github-org:admins, role:admin
      g, github-org:developers, role:readonly
```

## Step 5: Verify OAuth Configuration

1. Access your ArgoCD UI:
   - Dev: https://argocd.dev.morichalcorp.com
   - Staging: https://argocd.staging.morichalcorp.com
   - Prod: https://argocd.app.morichalcorp.com

2. You should see a **Login via GitHub** button instead of the default login form

3. Click the button and authorize the application

4. You should be redirected back to ArgoCD and logged in

## Troubleshooting

### OAuth Login Not Appearing

1. Check that the values file has been updated with correct Client ID and Secret
2. Verify the ArgoCD server pod has restarted after the configuration change:
   ```bash
   kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
   ```

### "Invalid redirect URI" Error

- Verify the callback URL in your GitHub OAuth App matches exactly:
  - Must be: `https://<your-argocd-domain>/api/auth/callback`
  - Check for trailing slashes or typos

### "Client authentication failed" Error

- Verify the Client ID and Client Secret are correct
- Check that the secret hasn't expired (GitHub secrets can expire)
- Regenerate the client secret if needed

### Users Can't Access ArgoCD

- Check RBAC policies in `argocd-rbac-cm` ConfigMap
- Verify GitHub organization/team names match exactly
- Default policy might be too restrictive - adjust `policy.default` if needed

### View OAuth Configuration

Check the current OAuth configuration:

```bash
kubectl get configmap argocd-cm -n argocd -o yaml | grep -A 20 oidc.config
```

## Updating OAuth Configuration

To update OAuth settings:

1. Edit the values file for your environment
2. Upgrade ArgoCD:
   ```bash
   helm upgrade argocd argo/argo-cd \
     --namespace argocd \
     --values operators/argocd/values-<env>.yaml
   ```
3. Restart the ArgoCD server if needed:
   ```bash
   kubectl rollout restart deployment argocd-server -n argocd
   ```

## Security Best Practices

1. **Never commit secrets to Git**: Use gitignored files or secret management tools
2. **Use different OAuth apps per environment**: Separate Client IDs/Secrets for dev, staging, and prod
3. **Rotate secrets regularly**: Regenerate GitHub OAuth secrets periodically
4. **Limit OAuth app scope**: Only request necessary scopes (`read:org` is needed for team-based RBAC)
5. **Use RBAC policies**: Restrict access based on GitHub teams/organizations
6. **Monitor access logs**: Regularly review who has access to ArgoCD

## Additional Resources

- [ArgoCD OIDC Configuration](https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/#existing-oidc-provider)
- [GitHub OAuth Apps Documentation](https://docs.github.com/en/developers/apps/building-oauth-apps/creating-an-oauth-app)
- [ArgoCD RBAC Documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/)

