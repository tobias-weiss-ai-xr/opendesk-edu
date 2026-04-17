# OpenDesk Edu Agents

## Shell Environment Requirements

### CRITICAL: Always Use WSL Bash

**PowerShell is BROKEN for this project**

Issues:
- Environment variable corruption when mixing `$env:` commands with SSH
- Quote handling conflicts with WSL paths
- Syntax errors on innocent commands like "unexpected token ')'"

**Mandatory shell command pattern:**
```bash
# WRONG (PowerShell) - THIS WILL FAIL
$env:CI='true'; ssh user@host "command"

# CORRECT (WSL Bash)
wsl bash -lc "ssh -i ~/.ssh/id_ed25519 user@host 'command'"
```

**Best practices:**
1. Always use `wsl bash -lc` for any SSH command to the server
2. Use single quotes inside double quotes for SSH commands
3. Avoid PowerShell environment variables except for git operations that are known to work
4. Keep WSL path format: `/mnt/c/Users/...`

**Working command examples:**
```bash
# Deploy helm chart
wsl bash -lc "ssh -i ~/.ssh/id_ed25519 root@178.63.182.104 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && helm upgrade --install sogo /root/opendesk-edu/helmfile/charts/sogo --namespace opendesk-edu --values /root/opendesk-edu/sogo-direct-values.yaml'"

# Check pod status
wsl bash -lc "ssh -i ~/.ssh/id_ed25519 root@178.63.182.104 'kubectl -n opendesk-edu get pods -l app.kubernetes.io/instance=sogo'"

# Copy files
wsl bash -lc "cd /mnt/c/Users/Tobias/git/opendesk-edu && scp -i ~/.ssh/id_ed25519 file root@178.63.182.104:/path/"

# Git operations
git add file && git commit -m "message"  # OK in PowerShell
```

## Server Deployment Instructions

### CRITICAL: Two Fixes Ready for Deployment

**Stuck Because:** PowerShell environment corruption preventing remote SSH command execution

**Password:**
Both fixes documented and ready for manual execution on server (root@178.63.182.104)

---

## 🚨 HIGH PRIO<span style="color:purple">紧急优先级RITY: Portal Fix (5 MINUTES)

**Issue:** Portal unavailable at https://portal.desk.opengdesk-edu.org

**Root Cause:** Invalid MinIO credentials in ums-portal-consumer-object-storage secret

**Solution:** Copy valid credentials from working ums-portal-server-object-storage secret

**Execute on Server:**
```bash
cd /root/opendesk-edu/.sisyphus/notepads/ums-fix-sogo
bash fix-portal-object-storage.sh
```

**Or Manually:**
```bash
# Get valid credentials from portal-secret
ACCESS_KEY=$(kubectl -n opendesk-edu get secret ums-portal-server-object-storage -o jsonpath='{.data.AWS_ACCESS_KEY_ID}' | base64 -d)
SECRET_KEY=$(kubectl -n opendesk-edu get secret ums-portal-server-object-storage -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}' | base64 -d)

# Create new secret with valid credentials
kubectl -n opendesk-edu create secret generic ums-portal-consumer-object-storage \
  --from-literal=AWS_ACCESS_KEY_ID="$ACCESS_KEY" \
  --from-literal=AWS_SECRET_ACCESS_KEY="$SECRET_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

# Delete and recreate consumer pod
kubectl -n opendesk-edu delete pod ums-portal-consumer-0
```

**Verification:**
```bash
# Wait for pod to restart (2-3 minutes)
kubectl -n opendesk-edu get pods -l app.kubernetes.io/name=portal-consumer -w

# Check logs
kubectl -n opendesk-edu logs -f ums-portal-consumer-0

# Verify portal accessible
curl -k https://portal.desk.opengdesk-edu.org/
# Should return HTML content
```

---

## 🔧 MEDIUM PRIORITY: SOGo Apache Proxy Fix (2 MINUTES)

**Issue:** Apache failing with DefaultRuntimeDir error

**Solution:** Delete ConfigMap and redeploy to force regeneration

**Execute on Server:**
```bash
# Delete old ConfigMap (cached version)
kubectl -n opendesk-edu delete configmap sogo-sogo-entrypoint

# Redeploy SOGo
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm upgrade --install sogo /root/opendesk-edu/helmfile/charts/sogo \
  --namespace opendesk-edu \
  --values /root/opendesk-edu/sogo-direct-values.yaml

# Wait for pod to restart (~30 seconds)
sleep 30

# Verify Apache running
kubectl -n opendesk-edu get pods -l app.kubernetes.io/name=sogo
NEW_POD=$(kubectl -n opendesk-edu get pods -l app.kubernetes.io/name=sogo -o name | head -1)
kubectl -n opendesk-edu exec -it $NEW_POD -- supervisorctl status apache
# Should show: apache   RUNNING   pid xx, uptime x:xx:xx

# Verify Port 80 listening
kubectl -n opendesk-edu exec -it $NEW_POD -- netstat -tlnp | grep :80
# Should show: 0.0.0.0:80 (Apache)

# Verify SOGo accessible
curl -k https://sogo.opendesk-edu.org/
# Should return HTML (SOGo login page)
```

---

## Current System State

### SOGo Deployment
- **Revision:** 16
- **SOGo:** ✅ RUNNING (2:19 uptime, 5 workers READY)
- **Apache:** ❌ FATAL (DefaultRuntimeDir AH00111 error)
- **Port 80:** Not accessible

### Portal Deployment
- **ums-portal-server-0:** ✅ RUNNING (MinIO access working)
- **ums-portal-consumer-0:** ❌ Init:CrashLoopBackOff (342 restarts)
- **Status:** U

---

## SOGo Architecture Summary

**CRITICAL DISCOVERY:**
- SOGo's WOHttpAdaptor runs on `127.0.0.1:20000` (internal watchdog ONLY)
- SOGo DOES NOT bind to external port 80
- **Apache reverse proxy is REQUIRED** for external HTTP access on port 80
- Configuration parameters `SOGoDaemonAddresses` and `SOGoListenPort` are for Apache's use, not SOGo

**Architecture:**
```
External Request → Port 80 (Apache) → 127.0.0.1:20000 (SOGo internal)
```

---

## Work Plan Status

**Completed (Tasks 1-7):** ✅ Infrastructure deployment (100%)

**In Progress (Task 8):** ⏸ Verification waiting for deployment completion

**Pending (Tasks 9-10):** ⏸ Final documentation and closure

**Completion Percentage:** 70% (Infra 100%, Verification 0%)

---

## Documentation Location

All documentation in `.sisyphus/notepads/ums-fix-sogo/`:
- `FINAL_DEPLOYMENT_SUMMARY.md` - Complete deployment guide
- `CURRENT_STATUS.md` - Dual priority tracker (Portal/SOGo)
- `PORTAL_FIX_REQUIRED.md` - Portal quick fix reference
- `PORTAL_FIX_GUIDE.md` - Detailed portal fix guide
- `CRITICAL_BLOCKER.md` - SOGo technical blocker details
- `SOGO_DEPLOYMENT_SUMMARY.md` - SOGo architecture discovery
- `WORK_PLAN_STATUS.md` - Work plan completion status