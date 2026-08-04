# Namespace Consolidation: opendesk-sme → opendesk-edu

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate opendesk-sme namespace into opendesk-edu, serving both demo.opendesk-sme.org and demo.opendesk-edu.org from a single namespace.

**Architecture:** Update opendesk-edu Helmfile configuration to support multiple domains (demo.opendesk-sme.org + demo.opendesk-edu.org) via custom ingress hosts, then redeploy opendesk-edu and delete opendesk-sme namespace. Keycloak configuration will be updated to accept authentication from both domains.

**Tech Stack:** Helmfile, Kubernetes Ingress (HAProxy), Keycloak Identity Provider

---

## Pre-requisites & Verification

**Files to inspect first:**
- `/home/weiss/git/opendesk-edu/helmfile/environments/prod/values.yaml.gotmpl` - Current configuration
- `/home/weiss/git/opendesk-edu/helmfile/apps/*/values.yaml.gotmpl` - Individual app ingress configs

**Current State:**
- opendesk-edu namespace: 66 pods, serves demo.opendesk-edu.org domain
- opendesk-sme namespace: 46 pods, serves demo.opendesk-sme.org domain (core services only)
- Both namespaces on single node: 12000m total CPU
- Current CPU allocation: 9771m (81%), 2219m headroom

---

### Task 1: Analyze opendesk-edu configuration

**Files:**
- Read: `/home/weiss/git/opendesk-edu/helmfile/environments/prod/values.yaml.gotmpl`

- [ ] **Step 1: Read current opendesk-edu configuration**

```bash
cat /home/weiss/git/opendesk-edu/helmfile/environments/prod/values.yaml.gotmpl
```

- [ ] **Step 2: Identify domain variable location**
   - Find `global.domain` setting (likely `demo.opendesk-edu.org`)
   - Note how ingress hosts are configured
   - Document apps with custom ingress rules

- [ ] **Step 3: Check ingress patterns across apps**

```bash
find /home/weiss/git/opendesk-edu/helmfile/apps -name "values.yaml.gotmpl" -exec grep -l "ingress" {} \;
```

Expected: Find 10-15 apps with ingress configurations

---

### Task 2: Configure multi-domain support in opendesk-edu

**Files:**
- Modify: `/home/weiss/git/opendesk-edu/helmfile/environments/prod/values.yaml.gotmpl`

- [ ] **Step 1: Add secondary domain configuration**

Add to `values.yaml.gotmpl`:

```yaml
global:
  domain: "demo.opendesk-edu.org"
  domains:
    - "demo.opendesk-edu.org"
    - "demo.opendesk-sme.org"
  primaryDomain: "demo.opendesk-edu.org"
```

- [ ] **Step 2: Add ingress annotations for multi-domain support**

```yaml
# Add under global:
ingress:
  # Enable multi-host ingress rules
  multiHost: true
  # Create separate ingress rules for each domain-app combination
  createRules:
    - domain: "demo.opendesk-edu.org"
      apps: ["portal", "id", "wiki", "meet", "files", "chat", "office", "pad", ...]
    - domain: "demo.opendesk-sme.org"
      apps: ["portal", "id"]
```

Note: This will require careful manual mapping of which apps should serve which domains.

- [ ] **Step 3: Configure Keycloak for both domains**

Add to Keycloak configuration section:

```yaml
ums-keycloak:
  auth:
    admin:
      existingSecret: ""  # Keep existing auth
  hostnameStrictHttps: true
  hostnameStrict: false
  proxy: edge
  hostname:
    - "id.demo.opendesk-edu.org"
    - "id.demo.opendesk-sme.org"
  additionalHostnames: ["id.demo.opendesk-sme.org"]
```

- [ ] **Step 4: Configure Portal for both domains**

Add or update Portal configuration:

```yaml
ums-portal:
  enabled: true
  hostnames:
    - "demo.opendesk-edu.org"
    - "demo.opendesk-sme.org"
  primaryDomain: "demo.opendesk-edu.org"
```

- [ ] **Step 5: Update app-specific ingress rules for SME domain**

For portal and Keycloak specifically (apps that need to serve both domains):

```yaml
# Add under apps.ums-portal:
ums-portal-server:
  ingress:
    hosts:
      - host: "portal.demo.opendesk-edu.org"
        paths:
          - path: /
            pathType: Prefix
      - host: "portal.demo.opendesk-sme.org"
        paths:
          - path: /
            pathType: Prefix

# Add under apps.ums-keycloak:
ums-keycloak:
  ingress:
    hosts:
      - host: "id.demo.opendesk-edu.org"
        paths:
          - path: /
            pathType: Prefix
      - host: "id.demo.opendesk-sme.org"
        paths:
          - path: /
            pathType: Prefix
```

- [ ] **Step 6: Commit configuration**

```bash
cd /home/weiss/git/opendesk-edu
git add helmfile/environments/prod/values.yaml.gotmpl
git commit -m "feat: Add multi-domain support for opendesk-sme.org"
```

---

### Task 3: Configure static file serving for SME domain

**Problem:** opendesk-sme has `opendesk-static-*` services serving static files (Keycloak, Portal themes). These need to be configured for both domains.

**Files:**
- Modify: `/home/weiss/git/opendesk-edu/helmfile/environments/prod/values.yaml.gotmpl`

- [ ] **Step 1: Add static file ingress rules for SME domain**

```yaml
# Under apps.opendesk-static-files:
opendesk-static-files-keycloak:
  ingress:
    hosts:
      - host: "id.demo.opendesk-edu.org"
        paths:
          - path: /
            pathType: Prefix
      - host: "id.demo.opendesk-sme.org"
        paths:
          - path: /
            pathType: Prefix

opendesk-static-files-portal:
  ingress:
    hosts:
      - host: "portal.demo.opendesk-edu.org"
        paths:
          - path: /
            pathType: Prefix
      - host: "portal.demo.opendesk-sme.org"
        paths:
          - path: /
            pathType: Prefix
```

- [ ] **Step 2: Commit**

```bash
git add helmfile/environments/prod/values.yaml.gotmpl
git commit -m "feat: Configure static file ingress for both domains"
```

---

### Task 4: Back up opendesk-sme data and configurations

**Files:**
- Create: `/tmp/opendesk-sme-backup-<timestamp>/`

- [ ] **Step 1: Export Secrets**

```bash
mkdir -p /tmp/opendesk-sme-backup-$(date +%Y%m%d-%H%M%S)
cd /tmp/opendesk-sme-backup-$(date +%Y%m%d-%H%M%S)
kubectl get secrets -n opendesk-sme -o yaml > secrets-backup.yaml
```

- [ ] **Step 2: Export ConfigMaps**

```bash
kubectl get configmaps -n opendesk-sme -o yaml > configmaps-backup.yaml
```

- [ ] **Step 3: Export LDAP users (UDM REST API)**

```bash
# Note: User import tool already created users. Document their existence.
cat <<'EOF' > users-documentation.md
# opendesk-sme User Migration Notes

## Demo Users Created:
- nadine.goldberg
- ingeborg.helm
- osman.buchel
- marko.essig
- susan.griebel

## Credentials:
See /home/weiss/git/opendesk-sme/DEMO-CREDENTIALS.md

## Keycloak Sync Issue:
Users exist in LDAP but not syncing to Keycloak 'opendesk' realm.
This issue should be monitored after migration.
EOF
```

- [ ] **Step 4: Document DNS records**

```bash
cat <<'EOF' >> dns-records.md
# DNS Records for demo.opendesk-sme.org

## Current Records (pointing to opendesk-sme):
- id.demo.opendesk-sme.org → [loadBalancerIP]
- portal.demo.opendesk-sme.org → [loadBalancerIP]
- ics.demo.opendesk-sme.org → [loadBalancerIP]

## Required Action:
Update DNS to point all *.demo.opendesk-sme.org records to same IP as *.demo.opendesk-edu.org
EOF
```

---

### Task 5: Deploy updated opendesk-edu with multi-domain support

**Files:**
- Execute: `/home/weiss/git/opendesk-edu/helmfile.yaml.gotmpl`

- [ ] **Step 1: Dry-run deployment**

```bash
cd /home/weiss/git/opendesk-edu
helmfile apply -e prod -n opendesk-edu --diff
```

Check review carefully for:
- New ingress resources created
- Static file hosts configured
- Keycloak and Portal updated

- [ ] **Step 2: Apply deployment**

```bash
helmfile apply -e prod -n opendesk-edu
```

Expected output:
- Existing releases: Updated (Keycloak, Portal, static files)
- No new releases created
- Ingress resources: Updated with additional hosts

- [ ] **Step 3: Verify ingress resources**

```bash
kubectl get ingress -n opendesk-edu
kubectl describe ingress -n opendesk-edu | grep -A 5 "Host:"
```

Expected: See both `demo.opendesk-edu.org` and `demo.opendesk-sme.org` hosts for portal and Keycloak

- [ ] **Step 4: Verify pod status**

```bash
kubectl get pods -n opendesk-edu
```

Expected: All 66 pods running, no new pods created

---

### Task 6: Verify SME domain access through opendesk-edu

**Prerequisite:** DNS records for demo.opendesk-sme.org must point to opendesk-edu ingress

**Files:**
- Test: Browser/curl commands

- [ ] **Step 1: Test portal access**

```bash
# Check if portal.elb responds to SME domain
curl -I https://portal.demo.opendesk-sme.org
```

Expected: HTTP 200 or 301/302 redirect to Keycloak

- [ ] **Step 2: Test Keycloak access**

```bash
curl -I https://id.demo.opendesk-sme.org
```

Expected: HTTP 200 (Keycloak login page)

- [ ] **Step 3: Test browser login**

1. Open: https://portal.demo.opendesk-sme.org
2. Should redirect to: https://id.demo.opendesk-sme.org
3. Login with: administrator / [password from demo-credentials.txt]
4. Verify: Portal loads with apps available

- [ ] **Step 4: Test EDU domain still works**

```bash
curl -I https://portal.demo.opendesk-edu.org
```

Expected: HTTP 200, same behavior

---

### Task 7: Update DNS records

**Note:** This is a manual step outside the cluster. Document the required changes.

**Files:**
- Create: `/tmp/opendesk-sme-backup-<timestamp>/dns-updates-required.md`

- [ ] **Step 1: Document DNS changes**

```bash
cat <<'EOF' > dns-updates-required.md
# DNS Updates Required

## Demo Domain: demo.opendesk-sme.org

### Records to Update:
All `*.demo.opendesk-sme.org` records must point to the same IP as `*.demo.opendesk-edu.org`

### Current IP (opendesk-edu):
Run: `kubectl get svc -n opendesk-ingress haproxy-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`

### Records to Change:
- id.demo.opendesk-sme.org → [opendesk-edu loadBalancerIP]
- portal.demo.opendesk-sme.org → [opendesk-edu loadBalancerIP]
- ics.demo.opendesk-sme.org → [opendesk-edu loadBalancerIP]
- files.demo.opendesk-sme.org → [opendesk-edu loadBalancerIP]
- wiki.demo.opendesk-sme.org → [opendesk-edu loadBalancerIP]
- meet.demo.opendesk-sme.org → [opendesk-edu loadBalancerIP]
- notes.demo.opendesk-sme.org → [opendesk-edu loadBalancerIP]

### Timing:
After DNS propagation (5-30 minutes), test:
```bash
curl -I https://portal.demo.opendesk-sme.org
```
EOF
```

---

### Task 8: Delete opendesk-sme namespace

**Files:**
- Execute: Kubernetes namespace deletion

**BEFORE DELETING:**
- ✅ opendesk-edu serves both domains correctly
- ✅ DNS records updated and propagated
- ✅ Users can login via portal.demo.opendesk-sme.org
- ✅ All apps accessible via SME domain

- [ ] **Step 1: Final verification**

```bash
# Assert both portals work
curl -s -o /dev/null -w "EDU portal: %{http_code}\n" https://portal.demo.opendesk-edu.org
curl -s -o /dev/null -w "SME portal: %{http_code}\n" https://portal.demo.opendesk-sme.org

# Expected output:
# EDU portal: 200
# SME portal: 200
```

- [ ] **Step 2: Delete namespace**

```bash
kubectl delete namespace opendesk-sme
```

Expected: Namespace deleted, all resources in namespace terminated

- [ ] **Step 3: Verify deletion**

```bash
kubectl get namespace opendesk-sme
```

Expected: "Error from server (NotFound): namespaces "opendesk-sme" not found"

- [ ] **Step 4: Verify cluster cleanup**

```bash
kubectl get pods -A | grep opendesk-sme
```

Expected: No results (no remaining opendesk-sme resources)

- [ ] **Step 5: Delete opendesk-sme git repository files (optional)**

```bash
cd /home/weiss/git
rm -rf opendesk-sme
echo "opendesk-sme repository removed"
```

**WARNING:** Only run this if completely sure no further references needed

- [ ] **Step 6: Commit final deployment**

```bash
cd /home/weiss/git/opendesk-edu
git commit -m "feat: Consolidated opendesk-sme into multi-domain opendesk-edu

- Added demo.opendesk-sme.org as secondary domain
- Configured Portal and Keycloak for both domains
- DNS updates required for *.demo.opendesk-sme.org
- opendesk-sme namespace deleted"
```

---

### Task 9: Post-migration verification

**Files:**
- Test: End-to-end verification

- [ ] **Step 1: Verify user login via SME domain**

```bash
# Use demo credentials from DEMO-CREDENTIALS.md
curl -X POST https://id.demo.opendesk-sme.org/realms/opendesk/protocol/openid-connect/token \
  -d "client_id=portal" \
  -d "grant_type=password" \
  -d "username=nadine.goldberg" \
  -d "password=[user_password]"
```

Expected: JSON response with access_token

- [ ] **Step 2: Verify Portal app list via SME domain**

1. Login at: https://portal.demo.opendesk-sme.org
2. Check: Which apps are visible?
3. Expected: Apps configured in opendesk-edu should appear

- [ ] **Step 3: Verify Keycloak sync issue status**

```bash
# Check if users now sync to Keycloak
kubectl logs -n opendesk-edu deployment/ums-selfservice-listener | tail -50
```

Expected: User sync messages processed (may still have issues - monitor)

- [ ] **Step 4: Document final state**

```bash
cat <<'EOF' > /tmp/opendesk-sme-backup-$(date +%Y%m%d-%H%M%S)/migration-complete.md
# Namespace Migration Complete

## Date: $(date)

## Changes Made:
1. ✅ Configured opendesk-edu to serve both domains
2. ✅ Added multi-domain ingress for Keycloak and Portal
3. ✅ Updated static file serving for both domains
4. ✅ Deleted opendesk-sme namespace
5. ✅ Updated DNS (if completed)

## Current State:
- Single namespace: opendesk-edu
- Domains served: demo.opendesk-edu.org + demo.opendesk-sme.org
- Apps running: All 20+ opendesk-edu apps available on both domains
- Users: Demo users in LDAP (Keycloak sync monitoring required)

## Remaining Tasks:
1. DNS updates for *.demo.opendesk-sme.org (manual)
2. Monitor Keycloak user sync progress
3. Verify all apps function correctly via SME domain

## Backup Location:
/tmp/opendesk-sme-backup-<timestamp>/
EOF
```

- [ ] **Step 5: Create final summary**

```bash
cat <<'EOF'
=== Migration Complete ===

Namespace opendesk-sme has been consolidated into opendesk-edu.

Access URLs:
- EDU: https://portal.demo.opendesk-edu.org
- SME: https://portal.demo.opendesk-sme.org

Both domains now serve from the same namespace with full app availability.

Next Steps:
1. Update DNS for *.demo.opendesk-sme.org
2. Monitor Keycloak user sync
3. Verify all apps via SME domain
EOF
```

---

## Rollback Plan (if needed)

**If issues arise**: Restore opendesk-sme namespace from backup archive using:
1. Create namespace: `kubectl create namespace opendesk-sme`
2. Apply configs: `kubectl apply -f /tmp/opendesk-sme-backup-<timestamp>/configmaps-backup.yaml`
3. Apply secrets: `kubectl apply -f /tmp/opendesk-sme-backup-<timestamp>/secrets-backup.yaml`
4. Deploy: `cd /home/weiss/git/opendesk-sme && helmfile apply -e opendesk-sme -n opendesk-sme`
5. Update DNS back to original configuration

**Note:** LDAP user data persists outside the namespace (Univention server)