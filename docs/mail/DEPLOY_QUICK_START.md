# 🚀 DEPLOY QUICK START

**Stalwart Mail Server + OpenCloud Deployment**  
**Last Updated:** 2026-07-25  
**Status:** Ready for Deployment

---

## ⏱️ TL;DR - GET STARTED IN 5 MINUTES

If you just want to **deploy now** and figure things out later:

```bash
# Step 0: Navigate to repository
cd /home/weissto_local/git/opendesk_git

# Step 1: Run the interactive deployment assistant
./DEPLOY_NOW.sh

# Follow the prompts to:
#   1. Check prerequisites
#   2. Generate secrets (or skip and use placeholders for testing)
#   3. Deploy with helmfile
#   4. Verify installation
```

---

## 🎯 DEPLOYMENT OPTIONS

| Option | Command | What It Does | Best For |
|--------|---------|--------------|----------|
| **Interactive** | `./DEPLOY_NOW.sh` | Step-by-step guide | First-time users |
| **Prerequisites** | `./DEPLOY_NOW.sh prereqs` | Check tools & cluster | Quick validation |
| **Secrets** | `./DEPLOY_NOW.sh secrets` | Generate secrets | Configuration |
| **Keycloak** | `./DEPLOY_NOW.sh keycloak` | Check OIDC clients | Setup |
| **DNS** | `./DEPLOY_NOW.sh dns` | Verify DNS records | Production |
| **Deploy** | `./DEPLOY_NOW.sh deploy` | Deploy services | Actual deployment |
| **Verify** | `./DEPLOY_NOW.sh verify` | Check deployment | Post-deployment |
| **All** | `./DEPLOY_NOW.sh all` | Do everything | One-shot deployment |

---

## 📋 STAGING DEPLOYMENT (FASTEST - for testing)

For **quick testing** with minimal configuration:

```bash
# 1. Navigate to opendesk-edu
cd ./opendesk-edu

# 2. Review the configuration
helmfile --environment edu diff

# 3. Deploy (with placeholder secrets - will use defaults)
#    Note: This may fail if Keycloak is not running
#    For true testing, you need at least minimal secrets
helmfile --environment edu sync
```

---

## 🏭 PRODUCTION DEPLOYMENT

For **production** deployment, follow these steps:

### Step 1: Generate Secrets

#### Option A: Use the script (recommended)
```bash
./DEPLOY_NOW.sh secrets
# Follow the prompts and copy the generated values
```

#### Option B: Manual generation
```bash
# Stalwart
openssl passwd -6 "your-admin-password"  # Admin password hash
openssl rand -hex 32                     # OIDC client secret
openssl rand -base64 24                  # LDAP bind password

# OpenCloud (7 secrets)
for i in {1..7}; do openssl rand -hex 32; done

# Keycloak
openssl rand -base64 20                  # Admin password
```

#### Step 2: Update the secrets file
```bash
nano ./opendesk-edu/helmfile/environments/edu/secrets.yaml

# Replace all "changeme-replace-with-actual-secret" with actual values
# Save the file
```

### Step 3: Register OIDC Clients in Keycloak

#### Prerequisite: Keycloak must be running
```bash
# Check if Keycloak is ready
kubectl get pods -n opendesk | grep keycloak
kubectl wait --for=condition=Ready pod -n opendesk -l app.kubernetes.io/name=keycloak --timeout=300s
```

#### Using kcadm.sh (CLI)
```bash
# Get admin credentials
KEYCLOAK_POD=$(kubectl get pods -n opendesk -l app.kubernetes.io/name=keycloak -o jsonpath='{.items[0].metadata.name}')

# Register Stalwart client
kubectl exec -it -n opendesk $KEYCLOAK_POD -- kcadm.sh create clients/opendesk/stalwart \
  -s clientId=stalwart \
  -s enabled=true \
  -s 'redirectUris=["https://mail.opendesk.hrz.uni-marburg.de/*"]' \
  -s 'webOrigins=["https://mail.opendesk.hrz.uni-marburg.de"]' \
  -s standardFlowEnabled=true \
  -s implicitFlowEnabled=false \
  -s directAccessGrantsEnabled=true \
  -s serviceAccountsEnabled=false

# Get Stalwart client secret
kubectl exec -it -n opendesk $KEYCLOAK_POD -- kcadm.sh get clients/opendesk/stalwart -o json | jq -r '.secret'

# Register OpenCloud client
kubectl exec -it -n opendesk $KEYCLOAK_POD -- kcadm.sh create clients/opendesk/opendesk-opencloud \
  -s clientId=opendesk-opencloud \
  -s enabled=true \
  -s 'redirectUris=["https://files.opendesk.hrz.uni-marburg.de/*"]' \
  -s 'webOrigins=["https://files.opendesk.hrz.uni-marburg.de"]' \
  -s 'backchannelLogoutUrl=https://files.opendesk.hrz.uni-marburg.de/oidc/logout' \
  -s standardFlowEnabled=true \
  -s implicitFlowEnabled=false \
  -s directAccessGrantsEnabled=true \
  -s serviceAccountsEnabled=false

# Get OpenCloud client secret
kubectl exec -it -n opendesk $KEYCLOAK_POD -- kcadm.sh get clients/opendesk/opendesk-opencloud -o json | jq -r '.secret'

# Update the secrets.yaml file with the actual client secrets
nano ./opendesk-edu/helmfile/environments/edu/secrets.yaml
```

#### Using Keycloak Admin Console
1. Access: `https://portal.opendesk.hrz.uni-marburg.de/auth/admin`
2. Login with admin credentials
3. Navigate to: Realm `opendesk` → Clients → Create
4. Create two clients with above configurations
5. Note the client secrets
6. Update `secrets.yaml`

### Step 4: Configure DNS

```bash
# Find your ingress IP
INGRESS_IP=$(kubectl get svc -n traefik traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
# or
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Ingress IP: $INGRESS_IP"

# Create DNS records (run on your DNS server or ask HRZ)
# mail.opendesk.hrz.uni-marburg.de.    IN  A     $INGRESS_IP
# files.opendesk.hrz.uni-marburg.de.   IN  A     $INGRESS_IP

# For email (if enabling SMTP externally):
# @.opendesk.hrz.uni-marburg.de.       IN  MX    10 mail.opendesk.hrz.uni-marburg.de.
```

### Step 5: Deploy

```bash
cd ./opendesk-edu

# Dry-run (review changes)
helmfile --environment edu diff

# Deploy
helmfile --environment edu sync

# Watch progress
kubectl get pods -n opendesk -w
```

### Step 6: Verify

```bash
# Check all pods
kubectl get pods -n opendesk

# Check Stalwart specifically
kubectl get pods,svc,ingress -n opendesk -l app.kubernetes.io/name=stalwart

# Check OpenCloud specifically
kubectl get pods,svc,ingress -n opendesk -l app.kubernetes.io/name=opencloud

# Check logs
kubectl logs -f -n opendesk <stalwart-pod-name>
kubectl logs -f -n opendesk <opencloud-pod-name>

# Test health endpoints (once DNS is configured)
curl -k https://mail.opendesk.hrz.uni-marburg.de/api/health
curl -k https://files.opendesk.hrz.uni-marburg.de/status.php
```

---

## ✅ DEPLOYMENT CHECKLIST

### Pre-Deployment
- [ ] Required tools installed (kubectl, helm, helmfile)
- [ ] Access to Kubernetes cluster (HRZ K3s)
- [ ] Secrets generated and configured
- [ ] OIDC clients registered in Keycloak
- [ ] DNS records created

### During Deployment
- [ ] helmfile diff reviewed
- [ ] helmfile sync executed
- [ ] Pods started successfully

### Post-Deployment
- [ ] Services accessible via ingress
- [ ] Health checks passing
- [ ] OIDC authentication working
- [ ] LDAP integration working (if applicable)
- [ ] Backups configured (k8up)

---

## 🚨 COMMON ISSUES & SOLUTIONS

### Issue 1: "Secret not found" errors
```
Error: secret "stalwart-secrets" not found
```

**Solution:** The secrets file needs to be applied to the cluster:
```bash
cd ./opendesk-edu
kubectl apply -f helmfile/environments/edu/secrets.yaml
# Then re-run helmfile sync
helmfile --environment edu sync
```

### Issue 2: "Connection refused" to Keycloak
```
Error: dial tcp: lookup keycloak on ...: no such host
```

**Solution:** Keycloak may not be running or DNS not configured:
```bash
# Check if Keycloak is running
kubectl get pods -n opendesk | grep keycloak

# Check Keycloak service
kubectl get svc -n opendesk keycloak

# The Stalwart/OpenCloud config uses: https://portal.opendesk.hrz.uni-marburg.de
# Make sure this resolves to your ingress IP
```

### Issue 3: "DNS resolution failed"
```
Error: dial tcp: lookup mail.opendesk.hrz.uni-marburg.de on ...: no such host
```

**Solution:** DNS records not configured:
```bash
# Check if DNS is configured
dig mail.opendesk.hrz.uni-marburg.de

# If not, create the DNS records (see Step 4 above)
```

### Issue 4: "Creating PVC failed"
```
Error: PersistentVolumeClaim "stalwart-data" is waiting for a volume to be created
```

**Solution:** Storage class may not be available:
```bash
# Check available storage classes
kubectl get storageclass

# Check if ceph-rbd-ssd exists
kubectl get storageclass ceph-rbd-ssd

# If not, you may need to use a different storage class
# Edit: opendesk-edu/helmfile/apps/edu/stalwart/values.yaml.gotmpl
# Change: storageClass: ceph-rbd-ssd
# To:     storageClass: <available-class>
```

### Issue 5: "Image pull failed"
```
Error: Error pulling image docker.io/stalwartlabs/mail-server:latest
```

**Solution:** Image may not exist or network issue:
```bash
# Check if image exists
docker pull docker.io/stalwartlabs/mail-server:latest

# If using private registry, configure credentials
kubectl create secret docker-registry regcred \
  --docker-server=docker.io \
  --docker-username=your-username \
  --docker-password=your-password \
  --docker-email=your-email

# Then add to values:
imagePullSecrets:
  - name: regcred
```

### Issue 6: "OIDC client not found"
```
Error: OIDC client 'stalwart' not found in realm 'opendesk'
```

**Solution:** OIDC client not registered in Keycloak:
```bash
# Register the client (see Step 3 above)
# Then restart Stalwart/OpenCloud pods
kubectl delete pods -n opendesk -l app.kubernetes.io/name=stalwart
kubectl delete pods -n opendesk -l app.kubernetes.io/name=opencloud
```

---

## 📚 USEFUL COMMANDS

### View Configuration
```bash
# View values for Stalwart
helmfile --environment edu -l name=stalwart* values

# View values for OpenCloud
helmfile --environment edu -l name=opencloud* values
```

### Debug Pods
```bash
# Get shell in a pod
kubectl exec -it -n opendesk <pod-name> -- /bin/bash

# View pod description
kubectl describe pod -n opendesk <pod-name>

# View pod events
kubectl get events -n opendesk --sort-by='.metadata.creationTimestamp'
```

### Scale Services
```bash
# Scale OpenCloud (stateless)
kubectl scale deployment -n opendesk opencloud --replicas=3

# Note: Stalwart is StatefulSet - cannot scale without storage changes
```

### Upgrade Services
```bash
# Update image version
# Edit: opendesk-edu/helmfile/environments/edu/images.yaml
# Then: helmfile --environment edu sync
```

---

## 📖 DOCUMENTATION

| File | Purpose |
|------|---------|
| `ANALYSIS_REPORT.md` | Complete gap analysis and recommendations |
| `DEPLOYMENT_COMPLETE.md` | Executive summary of deployment |
| `STALWART_OPENCLOUD_DEPLOYMENT_SUMMARY.md` | Detailed deployment summary |
| `QUICK_START_STALWART_OPENCLOUD.txt` | Quick reference card |
| `opendesk-edu/docs/services-stalwart-opencloud.md` | Full deployment guide |
| `FIX_ISSUES.sh` | Automated remediation for identified issues |
| `DEPLOY_NOW.sh` | Interactive deployment assistant |

---

## 🆘 NEED HELP?

### Issues with Deployment
1. Check the troubleshooting section above
2. Review the pods logs
3. Run: `./DEPLOY_NOW.sh verify`

### Configuration Questions
1. Review the configuration files in `opendesk-edu/helmfile/`
2. Check the documentation files listed above

### Cluster Issues
1. Verify cluster connection: `kubectl cluster-info`
2. Check node status: `kubectl get nodes`
3. Check storage: `kubectl get pvc -n opendesk`

---

## ✨ TIPS FOR SUCCESS

1. **Start with staging** - Deploy to a test namespace first
2. **Use the interactive guide** - `./DEPLOY_NOW.sh` walks you through everything
3. **Check prerequisites** - Run `./DEPLOY_NOW.sh prereqs` before deployment
4. **Review the diff** - Always check `helmfile --environment edu diff` before sync
5. **Monitor after deployment** - Watch pods and check logs
6. **Fix one issue at a time** - Use the verification script to identify problems
7. **Document your changes** - Keep track of what you modify

---

## 🎉 YOU'RE READY!

The configuration is complete and ready for deployment. All the hard work is done!

**To deploy now:**
```bash
./DEPLOY_NOW.sh
```

**For production:** Follow the "Production Deployment" steps above

**For testing:** Follow the "Staging Deployment" steps above

---

**Good luck with your deployment!** 🚀

*Need more help? Review the documentation files or run `./DEPLOY_NOW.sh`*
