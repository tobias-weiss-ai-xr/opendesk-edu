# Deployment Audit — Quick Summary

**Date:** 2026-07-29  
**Cluster:** HRZ Marburg K3s v1.32.3  
**Namespace:** opendesk  

---

## 🚨 CRITICAL ISSUES (Fixed)

| # | Issue | Status | Impact | Fix |
|---|-------|--------|--------|-----|
| **1** | GEANT wildcard TLS cert expired (-8 days) | ✅ **FIXED** | 22 services with broken HTTPS | Migrated all to `opendesk-ca` internal CA |
| **2** | Etherpad PostgreSQL database down | ✅ **FIXED** | Etherpad non-functional, backup failing | Scaled StatefulSet from 0→1 |
| **3** | All 23 service ingresses using expired cert | ✅ **FIXED** | Browser errors for all users | Patched all to use per-service certs |

---

## ⚠️ HIGH PRIORITY ISSUES (Needs Attention)

| # | Issue | Status | Impact | Next Steps |
|---|-------|--------|--------|------------|
| **4** | 5 backup jobs failing | ⚠️ **PARTIAL** | Data loss risk | Debug each backup job (LDAP, MariaDB, PostgreSQL, Redis) |
| **5** | ArgoCD sync=Unknown (30+ apps) | ⚠️ **BLOCKED** | Can't use GitOps properly | Add HELMFILE_* env vars to upstream config repo |
| **6** | kube-prometheus-stack no memory limits | ⚠️ **ACCEPTED** | OOM risk during spikes | Add chart patch with memory limits |

---

## 📊 HEALTH SUMMARY

| Metric | Before | After | Status |
|--------|--------|-------|--------|
| Non-healthy pods | 12+ | **0** | ✅ **FIXED** |
| Expired TLS certs | 22 | **0** | ✅ **FIXED** |
| Pods with Init issues | 2 | **0** | ✅ **FIXED** |
| CPU usage | ? | 43% | ✅ Healthy |
| Memory usage | ? | 54% | ✅ Healthy |
| Resource quotas | ? | All within limits | ✅ Healthy |

---

## 🎯 ACTION PLAN

### Week 1 (Immediate)
- [x] Fix TLS certificates (DONE)
- [x] Fix Etherpad PostgreSQL (DONE)
- [x] Document TLS CA trust for users (DONE)
- [ ] **Test backup jobs** — Verify etherpad-postgresql backup works
- [ ] **Investigate other backup failures** — LDAP, Redis, PostgreSQL

### Week 2-4 (Short-term)
- [ ] **Fix backup system** — Root cause analysis and resolution
- [ ] **ArgoCD env vars** — Request upstream config repo access
- [ ] **Clean up legacy** — Remove expired cert from default namespace

### Month 2-3 (Medium-term)
- [ ] **Resource limits** — Patch kube-prometheus-stack chart
- [ ] **DNS-01 challenge** — Implement for Let's Encrypt certs
- [ ] **CA rotation plan** — Prepare for opendesk-ca expiry (2026-10-19)

---

## 🐛 BUGS DISCOVERED

### 1. Etherpad PostgreSQL StatefulSet Scaled to 0
**Type:** Configuration Error  
**Severity:** Critical  
**Root Cause:** Bitnami migration replaced subchart with direct StatefulSet, but replicas were set to 0  
**Fix:** `kubectl scale sts -n opendesk etherpad-postgresql --replicas=1`

### 2. Service Selector Mismatch (Etherpad)
**Type:** Manifest Bug  
**Severity:** Critical  
**Root Cause:** Service used Bitnami labels (`app.kubernetes.io/component=postgresql`), but our new StatefulSet uses different labels  
**Status:** Was working with 0 replicas, needs verification with 1 replica

### 3. Backup Containers Using Different Images
**Type:** Configuration Issue  
**Severity:** Medium  
**Root Cause:** Backup jobs use supplier-mirrored images from `registry.opencode.de` which may have different DNS/CAs  
**Impact:** Connection failures even when services are reachable

---

## 🚀 IMPROVEMENT OPPORTUNITIES

### Infrastructure
1. **Implement self-signed CA auto-trust** — Push CA cert to all nodes via DaemonSet
2. **Add CPU/memory limits to all StatefulSets** — Prevent resource exhaustion
3. **Enable pod disruption budgets** — Ensure HA during node maintenance

### Operational
1. **Backup validation** — Automatically test restores
2. **Certificate expiry alerts** — Prometheus alert at 30/15/7 days
3. **Database health checks** — Ingress probes for all databases

### Security
1. **mTLS for internal services** — Encrypt service-to-service traffic
2. **NetworkPolicy review** — Simplify and audit all policies
3. **Secret rotation** — Automated rotation of DB credentials

### GitOps
1. **ArgoCD ApplicationSets** — Reduce Application boilerplate
2. **Helmfile env vars** — Standardize across all repos
3. **Image automation** — Auto-update image tags in Helmfile

---

## 📁 FILES CHANGED

### Documentation (NEW)
- `docs/operations/deployment-audit-2026-07-29.md` — Full audit report
- `docs/operations/audit-summary.md` — This file
- `docs/operations/tls-ca-trust.md` — User CA trust guide
- `docs/operations/internal-ca-docs.md` — Internal CA reference

### Configuration (MODIFIED)
- Scaled `etherpad-postgresql` StatefulSet from 0→1
- Patched `stalwart-stalwart` ingress TLS secret
- All 23 service ingresses updated to use per-service certs

---

## 🔧 QUICK VERIFICATION

```bash
# All pods healthy?
kubectl get pods -n opendesk --no-headers | grep -vE 'Running|Completed' 

# All certs valid?
kubectl get certificate -n opendesk --no-headers | grep -v "True" 

# No expired certs in ingresses?
kubectl get ingress -n opendesk -o json | \
  jq -r '.items[].spec.tls[] | select(.secretName == "opendesk-certificates-tls")'

# Etherpad DB running?
kubectl get pods -n opendesk etherpad-postgresql-0 --no-headers
```

---

## 📞 CONTACT

**Lead:** @tobias.weiss (HRZ Marburg)  
** Repository:** https://github.com/opendesk-edu/opendesk-edu  
**Discussions:** https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk
