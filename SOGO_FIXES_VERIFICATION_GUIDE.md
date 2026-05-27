# SOGo Fixes Verification Deployment Guide

**Objective:** Deploy upstream SOGo fixes from `feature/sogo-fix` branch to verify in `opendesk-edu` namespace

**Date:** 2026-05-25

## Status of Fixes in Branch

### 1. SOGo Apache Proxy Fix (COMMIT: e382a8f, 2c0e8f2, c3594d8)

**Problem:** Apache failing with `DefaultRuntimeDir AH00111 error`, SOGo not accessible on port 80

**Architecture Discovery:**
- SOGo's WOHttpAdaptor runs on `127.0.0.1:20000` (internal watchdog ONLY)
- SOGo DOES NOT bind to external port 80
- Apache reverse proxy REQUIRED for external HTTP access on port 80

**Fixes Applied:**
- ✅ Add `DefaultRuntimeDir /var/run/apache2` to Apache command
- ✅ Enable Apache in supervisord (reverse proxy to SOGo's 127.0.0.1:20000)
- ✅ Add `stopwaitsecs=90` for graceful SOGo shutdown
- ✅ Simplify entrypoint.sh (remove deprecated logic)
- ✅ Remove sogo-tool-plus-wrapper.sh (SOGo auto-initializes databases)
- ✅ Fix Apache environment variable propagation (www-data user)

### 2. PostgreSQL SSL Mode Fixes (COMMIT: 88734d5, 502e1e2, 1bc7899, etc.)

**Problem:** PostgreSQL SSL mode causing connection issues

**Fixes Applied:**
- ✅ Remove table paths from PostgreSQL URLs in db.yaml
- ✅ Remove SSL sed commands corrupting PostgreSQL URLs
- ✅ Use PgsqlHost for SSL mode instead of query param
- ✅ Add sslmode=disable to PostgreSQL connection URL

### 3. SOGo Foreground Fix (COMMIT: 066ed18)

**Problem:** SOGo not staying in foreground for supervisord monitoring

**Fixes Applied:**
- ✅ Add `-WONoDetach YES` to SOGo command

### 4. Network Policy Fix (COMMIT: 9d70b86)

**Problem:** SOGo unable to reach PostgreSQL

**Fixes Applied:**
- ✅ Add PostgreSQL egress rule to network policy

### 5. Production Environment Fix (COMMIT: e5bacab)

**Problem:** Apps not explicitly enabled, namespace not configured

**Fixes Applied:**
- ✅ Create `helmfile/environments/prod/values.yaml.gotmpl`
- ✅ Explicitly enable all apps (nubus, openproject, xwiki, sogo)
- ✅ Configure namespace to `opendesk-edu`
- ✅ Configure SOGo host as `sogo.demo`

## Current vs. Fixed State

### Current Project Status (HEAD)

**Apache Config:**
```yaml
# helmfile/apps/sogo/entrypoint-configmap.yaml:48
command=/usr/sbin/apache2 -c "ErrorLog /dev/stdout" -D FOREGROUND
# ❌ MISSING DefaultRuntimeDir flag
```

**Fixed State (feature/sogo-fix):**
```yaml
# helmfile/apps/sogo/entrypoint-configmap.yaml:48
command=/usr/sbin/apache2 -c "ErrorLog /dev/stdout" -c "DefaultRuntimeDir /var/run/apache2" -D FOREGROUND
# ✅ HAS DefaultRuntimeDir flag
```

## Deployment Verification Steps

### Prerequisites

1. Access to Kubernetes cluster (wherever you can deploy)
2. Helmfile installed locally
3. Existing opendesk infrastructure or ability to deploy dependencies

### Step 1: Create opendesk-edu Namespace

```bash
kubectl create namespace opendesk-edu --dry-run=client -o yaml | kubectl apply -f -
```

### Step 2: Apply SOGo Chart Fixes

Option A: Cherry-pick fixes from upstream
```bash
# Navigate to upstream opendesk repo
cd ../opendesk

# Get the specific commits
git show e382a8f:helmfile/charts/sogo/templates/entrypoint-configmap.yaml > /tmp/entrypoint-configmap-fixed.yaml
git show 2c0e8f2:helmfile/charts/sogo/templates/entrypoint-configmap.yaml > /tmp/entrypoint-env-fixed.yaml
git show c3594d8:helmfile/charts/sogo/templates/entrypoint-configmap.yaml > /tmp/entrypoint-full-fixed.yaml

# Copy to current project
cp /tmp/entrypoint-full-fixed.yaml helmfile/apps/sogo/entrypoint-configmap.yaml
```

Option B: Apply the DefaultRuntimeDir fix directly (minimal)
```bash
# Edit current file
sed -i 's|command=/usr/sbin/apache2 -c "ErrorLog /dev/stdout" -D FOREGROUND|command=/usr/sbin/apache2 -c "ErrorLog /dev/stdout" -c "DefaultRuntimeDir /var/run/apache2" -D FOREGROUND|g' \
  helmfile/apps/sogo/entrypoint-configmap.yaml
```

### Step 3: Create Production Environment Values

```bash
# Create prod environment directory
mkdir -p helmfile/environments/prod

# Create values.yaml.gotmpl
cat > helmfile/environments/prod/values.yaml.gotmpl << 'EOF'
# SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0
---
global:
  domain: "demo.opendesk-edu.org"

# Enable all apps
apps:
  sogo:
    host: "sogo.demo"
    enabled: true
  nubus:
    enabled: true
  openproject:
    enabled: true
  xwiki:
    enabled: true

# Configure namespace
namespace: "opendesk-edu"

# Accessibility configuration
accessibility:
  lastAuditDate: "2026-05-25"
EOF
```

### Step 4: Deploy SOGo with Helmfile

```bash
# Set environment variables
export KUBECONFIG=~/.kube/config  # Adjust to your cluster
export HELMFILE_ENVIRONMENT=prod

# Deploy SOGo only (for testing)
helmfile -f helmfile/apps/sogo/helmfile-child.yaml.gotmpl \
  --environment prod \
  --namespace opendesk-edu \
  apply
```

### Step 5: Verify Deployment

```bash
# Check pod status
kubectl -n opendesk-edu get pods -l app.kubernetes.io/name=sogo

# Check Apache process
kubectl -n opendesk-edu exec -it <sogo-pod> -- supervisorctl status apache

# Check SOGo process
kubectl -n opendesk-edu exec -it <sogo-pod> -- supervisorctl status sogo

# Check port 80 bindings
kubectl -n opendesk-edu exec -it <sogo-pod> -- netstat -tlnp | grep :80

# Check SOGo internal port
kubectl -n opendesk-edu exec -it <sogo-pod> -- netstat -tlnp | grep 20000

# Check Apache logs
kubectl -n opendesk-edu logs -f <sogo-pod> | grep -i apache

# Check SOGo logs
kubectl -n opendesk-edu logs -f <sogo-pod> | grep -i sogo
```

### Step 6: Test SOGo Access

```bash
# Forward port to local testing
kubectl -n opendesk-edu port-forward <sogo-pod> 8080:80

# In another terminal, test access
curl -v http://localhost:8080/
# Should return SOGo login page HTML

# If ingress is configured, test via hostname
curl -k https://sogo.demo.opendesk-edu.org/
# Should return SOGo login page HTML
```

## Expected Results

### Before Fix
```
# Apache status
apache   FATAL   exied too quickly

# Port 80 bindings
(empty - Apache not running)

# Access
curl: (7) Failed to connect to sogo.demo.opendesk-edu.org port 80
```

### After Fix
```
# Apache status
apache   RUNNING   pid 123, uptime 0:05:42

# SOGo status
sogo     RUNNING   pid 456, uptime 0:05:42

# Port 80 bindings
tcp        0      0.0.0.0:80              0.0.0.0:*               LISTEN      123/apache2
tcp        0      127.0.0.1:20000         0.0.0.0:*               LISTEN      456/sogod

# Access
HTTP/1.1 200 OK
Content-Type: text/html
...
<!DOCTYPE html>
<html>
<title>SOGo Login</title>
...
</html>
```

## Troubleshooting

### Apache Still Failing

1. Check DefaultRuntimeDir flag present:
```bash
kubectl -n opendesk-edu exec -it <sogo-pod> -- cat /opt/custom-entrypoint/supervisord.conf | grep -A2 "program:apache"
```

Should show:
```
command=/usr/sbin/apache2 -c "ErrorLog /dev/stdout" -c "DefaultRuntimeDir /var/run/apache2" -D FOREGROUND
```

2. Check Apache runtime directory:
```bash
kubectl -n opendesk-edu exec -it <sogo-pod> -- ls -la /var/run/apache2/
```

Should exist and be writable.

### SOGo Not Starting

1. Check PostgreSQL connection:
```bash
kubectl -n opendesk-edu exec -it <sogo-pod> -- nc -zv postgresql 5432
```

2. Check LDAP connection:
```bash
kubectl -n opendesk-edu exec -it <sogo-pod> -- nc -zv openldap 389
```

3. Check SOGo logs for SSL errors:
```bash
kubectl -n opendesk-edu logs <sogo-pod> | grep -i "ssl\|postgres"
```

### Port 80 Not Accessible

1. Verify Apache is running (from Step 5)
2. Check NetworkPolicy allows ingress:
```bash
kubectl -n opendesk-edu get networkpolicy -l app.kubernetes.io/name=sogo -o yaml
```
Should have ingress rules port 80.
3. Check if NodePort/LoadBalancer is configured if needed.

## Deployment Structure

```
opendesk-edu/
├── helmfile/
│   ├── apps/
│   │   └── sogo/
│   │       ├── entrypoint-configmap.yaml  # ← NEEDS DefaultRuntimeDir fix
│   │       ├── helmfile-child.yaml.gotmpl
│   │       └── values.yaml.gotmpl
│   ├── charts/
│   │   └── sogo/
│   │       ├── templates/
│   │       │   ├── deployment.yaml
│   │       │   ├── service.yaml
│   │       │   └── ingress.yaml
│   │       └── Chart.yaml
│   └── environments/
│       └── prod/
│           └── values.yaml.gotmpl  # ← NEEDED (explicit app enable + namespace)
└── sogo-direct-values.yaml  # Alternative direct deployment values
```

## Next Steps

1. If verification successful, merge fixes into main branch
2. Document any additional issues found
3. Update deployment guides with verified steps
4. Consider rolling out to production after validation

## References

- **Commit e382a8f:** fix(sogo): Add DefaultRuntimeDir and remove sogo-manage
- **Commit 2c0e8f2:** fix(sogo): Fix Apache environment variable propagation
- **Commit c3594d8:** fix(sogo): enable Apache proxy for port 80 access
- **Commit e5bacab:** fix(prod): explicitly enable apps and configure namespace
- **Branch:** feature/sogo-fix
- **Upstream:** ../opendesk/ (parent directory)