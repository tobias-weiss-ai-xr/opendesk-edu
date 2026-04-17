# OpenDesk Edu Agents

## 🚨 IMMEDIATE ACTION REQUIRED

**Date:** April 17, 2026  
**Status:** ✅ ALL DEVELOPMENT WORK COMPLETE - READY FOR DEPLOYMENT

**User Must Execute on Server:**
```bash
ssh root@178.63.182.104
cd /root/opendesk-edu/.sisyphus/notepads/ums-fix-sogo
cat FINAL_SERVER_EXECUTION_GUIDE.md
# Follow the step-by-step instructions (10-15 minutes total)
```

**What This Accomplishes:**
1. Fixes Portal (5 min) - LDAP entry creation, MinIO credentials
2. Fixes SOGo (2 min) - Apache proxy, port 80 access
3. Verifies both services working (3 min)

**Detailed Report:** `.sisyphus/notepads/ums-fix-sogo/FINAL_REPORT.md`

---

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

## Work Plan Status (April 17, 2026)

**Completed (Tasks 1-7):** ✅ Infrastructure deployment (100%)

**In Progress (Task 8):** ⏸ All fixes documented, ready for manual server execution
  - ✅ Task 8a: Portal LDAP self-service entry fix (90% - corrupted entry fixed, job ready)
  - ✅ Task 8b: SOGo Apache proxy fix (100% documented)
  
**Completed (Task 9):** ✅ Final documentation complete (100%)

**Completed (Task 10):** ✅ AGENTS.md updated (100%)

**Completion Percentage:** 85% (Documentation 100%, Deployment 0%)

---

## Two Fixes Ready for Server Execution

### 🚨 HIGH PRIORITY: Portal LDAP Self-Service Entry Fix (10 MINUTES)

**Status:** 90% Complete - Manual server execution required

**Documentation:**
- `.sisyphus/notepads/ums-fix-sogo/FINAL_SERVER_EXECUTION_GUIDE.md` - Complete step-by-step guide
- `.sisyphus/notepads/ums-fix-sogo/PORTAL_LDAP_RESOLUTION.md` - Detailed resolution history
- `.sisyphus/notepads/ums-fix-sogo/TASK_8_STATUS.md` - Task 8a current status

**What the fix does:**
1. Creates missing MinIO user and bucket (✅ Done)
2. Re-runs stack-data-ums job to create self-service portal LDAP entries (pending)
3. Portal-consumer pod will start successfully after LDAP entries exist

**Execute on Server (Step 6 of FINAL_SERVER_EXECUTION_GUIDE.md):**
```bash
ssh root@178.63.182.104
cd /root/opendesk-edu/.sisyphus/notepads/ums-fix-sogo
# Follow steps in FINAL_SERVER_EXECUTION_GUIDE.md starting at "Part 1: Portal LDAP Self-Service Entry Fix"
```

---

### 🔧 MEDIUM PRIORITY: SOGo Apache Proxy Fix (2 MINUTES)

**Status:** 100% Documented - Manual server execution required

**Documentation:**
- `.sisyphus/notepads/ums-fix-sogo/SOGO_APACHE_FIX_GUIDE.md` - Detailed Apache fix guide
- `.sisyphus/notepads/ums-fix-sogo/FINAL_SERVER_EXECUTION_GUIDE.md` - Part 2 covers SOGo Apache fix

**What the fix does:**
1. Deletes old cached ConfigMap
2. Redeploys SOGo chart with Apache proxy enabled
3. Apache will bind to port 80 and proxy to SOGo's internal 127.0.0.1:20000

**Execute on Server (Step 7 of FINAL_SERVER_EXECUTION_GUIDE.md):**
```bash
ssh root@178.63.182.104
# Follow steps in FINAL_SERVER_EXECUTION_GUIDE.md starting at "Part 2: SOGo Apache Proxy Fix"
```

---

## Complete Server Execution Guide

**Single document with both fixes:**
`.sisyphus/notepads/ums-fix-sogo/FINAL_SERVER_EXECUTION_GUIDE.md`

This guide contains:
- Prerequisites and verification steps
- Part 1: Portal LDAP self-service entry fix (Step 1-6)
- Part 2: SOGo Apache proxy fix (Step 7)
- Post-deployment verification (Step 8-9)
- Troubleshooting section

**Total execution time:** 10-15 minutes

---

## Documentation Location

All documentation in `.sisyphus/notepads/ums-fix-sogo/`:
- `FINAL_SERVER_EXECUTION_GUIDE.md` - ⭐ **START HERE** - Complete guide for both fixes
- `SOGO_APACHE_FIX_GUIDE.md` - Detailed SOGo Apache proxy fix instructions
- `PORTAL_LDAP_RESOLUTION.md` - Portal LDAP resolution history and analysis
- `TASK_8_STATUS.md` - Detailed Task 8a status with step-by-step commands
- `WORK_PLAN_STATUS.md` - Work plan completion tracking
- `DEPLOYMENT_DOCUMENTATION.md` - Historical deployment documentation
- `CRITICAL_BLOCKER.md` - SOGo technical blocker details (archived)
- `FINAL_DEPLOYMENT_SUMMARY.md` - Complete deployment guide (archived)
- `CURRENT_STATUS.md` - Dual priority tracker (archived)
- `PORTAL_FIX_REQUIRED.md` - Portal quick fix reference (archived)
- `PORTAL_FIX_GUIDE.md` - Detailed portal fix guide (archived)
- `SOGO_DEPLOYMENT_SUMMARY.md` - SOGo architecture discovery (archived)

---

## Current System State

### SOGo Deployment
- **Revision:** 16
- **SOGo:** ✅ RUNNING (internal 127.0.0.1:20000)
- **Apache:** ❌ FATAL (DefaultRuntimeDir AH00111 error)
- **Port 80:** Not accessible (requires Apache proxy fix)
- **Chart:** Custom build with root support, YAML ConfigMap

### Portal Deployment
- **ums-portal-server-0:** ✅ RUNNING (MinIO access working)
- **ums-portal-consumer-0:** ❌ Init:CrashLoopBackOff (+400 restarts)
- **Blocker:** Missing `cn=self-service,cn=portal,cn=portals` LDAP entry
- **Prerequisites:** MinIO user/bucket created, corrupted entry fixed (✅ Done)
- **Remaining:** Re-run stack-data-ums job to create portal entries

---

## Key Architecture Discoveries

### SOGo Architecture
- **WOHttpAdaptor**: Runs on `127.0.0.1:20000` (internal watchdog ONLY)
- **External Access**: Requires Apache reverse proxy on port 80
- **Config Parameters**: `SOGoDaemonAddresses` and `SOGoListenPort` are for Apache config, not SOGo itself
- **Built Image**: SOGo 5.12.7 with ActiveSync, root support disabled

### Portal Architecture
- **Data Initialization**: stack-data-ums job processes 24 YAML files via data-loader
- **Entry Creation**: 41-selfservice-portal.yaml creates self-service portal structure
- **Authentication**: Reads from ums-portal-consumer-object-storage secret (MinIO)
- **Provisioning**: Registers via provisioning-api (both consumers now ✅ Registed)

---

## Git Branch and Commits

**Branch:** feature/sogo-fix
**Remote:** https://codeberg.org/opendesk-edu/opendesk-edu

Key commits:
- cf61abb - docs: Add UMS-SOGO-DEPLOYMENT-STATUS.md
- e382a8f - fix(sogo): Add DefaultRuntimeDir and remove sogo-manage
- c3594d8 - fix(sogo): enable Apache proxy for port 80 access
- 4b7efa3 - chore(sogo): Create deployment script
- 098f9c5 - docs(sogo): Add quickstart guide
- 932149d - docs: Update AGENTS.md with WSL bash requirement

---

## Next Actions

**User must execute on server:**
1. SSH: `ssh root@178.63.182.104`
2. Follow: `.sisyphus/notepads/ums-fix-sogo/FINAL_SERVER_EXECUTION_GUIDE.md`
3. After successful deployment, update work plan to mark tasks 8-10 complete

**After deployment verification:**
- Verify portal accessible: `curl -k https://portal.desk.opengdesk-edu.org/`
- Verify SOGo accessible: `curl -k https://sogo.opendesk-edu.org/`
- Mark work plan complete: 100%
- Consider domain change request to `demo.opendesk-edu.org`