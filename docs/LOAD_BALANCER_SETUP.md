# Load Balancer Setup for DigitalOcean

## Problem

DigitalOcean's Cloud Controller Manager (CCM) has a limitation where it creates LoadBalancer services with incorrect forwarding rules:
- It creates `80 → 80` and `443 → 443` forwarding
- Should create `80 → 30080` and `443 → 30443` (NodePorts)
- This causes connection timeouts because port 80/443 aren't listening on the nodes

## Solution

We pre-create the load balancers with the correct configuration and use fixed NodePorts.

### Fixed NodePorts

All environments use the same NodePorts for consistency:
- **HTTP**: 30080
- **HTTPS**: 30443

### Configuration

All ingress-nginx deployments are configured with:
```yaml
controller:
  kind: DaemonSet                    # One pod per node
  service:
    type: LoadBalancer
    externalTrafficPolicy: Local     # Route only to nodes with pods
    nodePorts:
      http: 30080                    # Fixed HTTP NodePort
      https: 30443                   # Fixed HTTPS NodePort
    annotations:
      service.beta.kubernetes.io/do-loadbalancer-name: "lb-morichal-{env}"
      service.beta.kubernetes.io/do-loadbalancer-type: "REGIONAL_NETWORK"
```

## Setup Instructions

### For New Environments (Staging/Prod)

**1. Pre-create the load balancer:**
```bash
./scripts/create-loadbalancers.sh staging
# or
./scripts/create-loadbalancers.sh prod
```

This script will:
- Create firewall rules to allow NodePorts 30080 and 30443
- Create the load balancer with correct forwarding rules (80→30080, 443→30443)
- Set up TCP health checks on port 30080
- Tag the LB to automatically include all cluster nodes

**2. Deploy ingress-nginx:**

The load balancer is already created, so when you deploy ingress-nginx via ArgoCD, it will automatically use the existing LB.

```bash
# Staging
kubectl apply -f argocd/environments/staging/operators-app-of-apps.yml

# Prod
kubectl apply -f argocd/environments/prod/operators-app-of-apps.yml
```

**3. Verify:**
```bash
# Check service got the correct LB
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Check LB configuration
doctl compute load-balancer list
```

### For Existing Environments (Dev)

If the load balancer was already created incorrectly:

**Option 1: Fix existing LB**
```bash
./scripts/fix-loadbalancer.sh dev
```

**Option 2: Recreate from scratch**
```bash
# Delete the service (LB will be deleted)
kubectl delete svc -n ingress-nginx ingress-nginx-controller

# Pre-create the LB
./scripts/create-loadbalancers.sh dev

# ArgoCD will recreate the service and use the existing LB
```

## Verification

Test connectivity:
```bash
# HTTP (should redirect to HTTPS)
curl -v http://argocd.dev.morichalcorp.com

# HTTPS
curl -v https://argocd.dev.morichalcorp.com -k
```

Check load balancer health:
```bash
doctl compute load-balancer get <lb-id> --format ForwardingRules,HealthCheck
```

Expected output:
```
Forwarding Rules: 
  entry_protocol:tcp,entry_port:80,target_protocol:tcp,target_port:30080
  entry_protocol:tcp,entry_port:443,target_protocol:tcp,target_port:30443

Health Check:
  protocol:tcp,port:30080
```

## Cluster IDs Reference

- **Dev**: `31dc6bf1-0eda-48b2-9c3c-14b776b53a3d`
- **Staging**: `b8dded20-335c-4b42-9e75-8a592147b88e`
- **Prod**: `8616d258-fb5a-4480-9102-9223fe1f54ce`

## Troubleshooting

### Connection Timeouts

1. **Check NodePort firewall rules:**
   ```bash
   doctl compute firewall get <firewall-id> --format InboundRules
   ```
   Should include ports 30080 and 30443 from 0.0.0.0/0

2. **Check LB forwarding rules:**
   ```bash
   doctl compute load-balancer get <lb-id> --format ForwardingRules
   ```
   Should be 80→30080 and 443→30443, NOT 80→80 and 443→443

3. **Check LB firewall (allow-list):**
   ```bash
   doctl compute load-balancer get <lb-id> --format FirewallRules
   ```
   Should show `allow:[cidr:0.0.0.0/0]`

4. **Test direct NodePort access:**
   ```bash
   curl -v http://<node-ip>:30080 -H "Host: <your-domain>"
   ```

### Service Not Getting External IP

If the service shows `<pending>` for EXTERNAL-IP:
1. Check if LB name matches the annotation
2. Check LB logs: `doctl compute load-balancer list`
3. Check cluster tag: `k8s:<cluster-id>`

## Why This Approach?

1. **DaemonSet**: Ensures one ingress-nginx pod per node for high availability
2. **externalTrafficPolicy: Local**: LB only routes to healthy nodes with pods
3. **Fixed NodePorts**: Prevents port conflicts and allows pre-creating LBs
4. **Pre-created LBs**: Avoids the DO CCM bug with incorrect forwarding rules

