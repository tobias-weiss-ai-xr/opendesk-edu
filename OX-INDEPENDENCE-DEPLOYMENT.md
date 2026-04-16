# OX-Independence Deployment Guide

## Overview

This guide documents how to make the openDesk Edu deployment independent of Open-Xchange (OX) by replacing the OX-specific LDAP category `cn=od.applications` with an OX-independent `cn=applications` category.

## Problem Statement

The original deployment depended on `cn=od.applications,cn=category,cn=portals,cn=univention` in LDAP. This entry was created by the Open-Xchange bootstrap, which we disabled. Without it, the `ums-stack-data-ums` job failed with a 404 error, cascading to all UMS services.

## Solution

1. **Create OX-independent LDAP category**: `cn=applications` (without the `od.` prefix)
2. **Update nubus configuration**: Replace all references to `cn=od.applications` with `cn=applications`
3. **Enable SOGo**: Replace OX with SOGo as the groupware solution

## Files Modified

### LDAP

#### File: `helmfile/apps/nubus/files/applications-ox-independent.ldif`
- Creates the `cn=applications` portal category
- OX-independent (no `od.` prefix)
- Used by `apply-ox-independent-ldap-category.sh` script

#### Script: `helmfile/apps/nubus/apply-ox-independent-ldap-category.sh`
- Automates LDAP category creation
- Verifies existing entries before creating
- Can be run manually or integrated into bootstrap

### Configuration

#### File: `helmfile/apps/nubus/values-nubus.yaml.gotmpl`
- **Commit**: `7aec106`
- **Changes**: Replaced 14 instances of `cn=od.applications` with `cn=applications`
- **Affected portals**: ILIAS, Moodle, Nextcloud, etc.

#### File: `helmfile/helmfile_generic.yaml.gotmpl`
- **Commit**: `db354fc`
- **Changes**: Enabled SOGo (uncommented line 63-64)
- Replaces Open-Xchange as the groupware solution

## Deployment Procedure

### Prerequisites

1. LDAP server running (`ums-ldap-server-primary-0`)
2. kubectl configured
3. Access to the cluster

### Step 1: Apply LDAP Category (Manual)

```bash
cd helmfile/apps/nubus
./apply-ox-independent-ldap-category.sh
```

Or manually:
```bash
# Get LDAP credentials
LDAPPW=$(kubectl get secret -n opendesk-edu ums-ldap-server-credentials -o jsonpath='{.data.ldapSecret}' | base64 -d)

# Apply LDIF
kubectl cp files/applications-ox-independent.ldif opendesk-edu/ums-ldap-server-primary-0:/tmp/applications.ldif -c main

kubectl exec -n opendesk-edu ums-ldap-server-primary-0 -c main -- ldapadd -x \
  -D "cn=admin,dc=swp-ldap,dc=internal" -w "$LDAPPW" \
  -f /tmp/applications.ldif
```

### Step 2: Deploy with Helmfile

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
cd /path/to/opendesk-edu
DOMAIN=desk.opendesk-edu.org MAIL_DOMAIN=opendesk-edu.org MATRIX_DOMAIN=desk.opendesk-edu.org \
  helmfile -e prod -n opendesk-edu apply --skip-diff-on-install
```

**Note**: As of this writing, helmfile apply is blocked by a recursion error. See `helmfile-blocker-analysis.md` for details.

### Step 3: Verify Deployment

```bash
# Check stack-data-ums job
kubectl get jobs -n opendesk-edu | grep stack-data-ums

# Check pods status
kubectl get pods -n opendesk-edu

# Verify portal
curl -I https://portal.desk.opendesk-edu.org

# Verify SOGo (once deployed)
curl -I https://sogo.desk.opendesk-edu.org
```

## Rollback Procedure

If you need to revert to OX-specific configuration:

1. **Restore nubus values**:
   ```bash
   git revert 7aec106
   ```

2. **Restore helmfile**:
   ```bash
   git revert db354fc
   ```

3. **Optionally restore OX-specific LDAP category**:
   ```bash
   # Create cn=od.applications instead of cn=applications
   ldapadd -x -H ldap://localhost -D "cn=admin,dc=swp-ldap,dc=internal" -W -f od-applications.ldif
   ```

## Troubleshooting

### Issue: LDAP category already exists

If the script reports "already exists", verify it's the correct one:
```bash
kubectl exec -n opendesk-edu ums-ldap-server-primary-0 -c main -- ldapsearch -x -LLL \
  -D "cn=admin,dc=swp-ldap,dc=internal" -w "$LDAPPW" \
  -b "cn=applications,cn=category,cn=portals,cn=univention,dc=swp-ldap,dc=internal" dn
```

Expected output:
```
dn: cn=applications,cn=category,cn=portals,cn=univention,dc=swp-ldap,dc=internal
```

### Issue: stack-data-ums still fails

Check the job logs:
```bash
kubectl logs -n opendesk-edu job/ums-stack-data-ums-<job-number>
```

Look for "404" errors mentioning LDAP entries. You may need to add additional categories.

### Issue: Helmfile recursion error

See `helmfile-blocker-analysis.md` for detailed investigation. Current status:
- Helmfile v1.1.2: Recursion at helmfiles[13]
- Helmfile v1.4.4: YAML template parsing error
- Requires 4-7 hours human investigation

## Verification Criteria

### OX-Independence Achieved ✓

- [x] LDAP uses neutral `cn=applications` category
- [x] Nubus configuration updated (committed)
- [x] SOGo enabled (replaces OX)
- [x] Changes committed and pushed to Codeberg

### Deployment Verification (Pending Due to Helmfile Blocker)

- [ ] Helmfile apply completes successfully
- [ ] stack-data-ums job completes without error
- [ ] ums-portal-consumer pod is Running
- [ ] ums-selfservice-listener pod is Running
- [ ] SOGo pod is Running
- [ ] Portal accessible at https://portal.desk.opendesk-edu.org
- [ ] SOGo accessible at https://sogo.desk.opendesk-edu.org

## Related Documentation

- `helmfile-blocker-analysis.md` - Helmfile recursion error investigation
- `work-summary.md` - Complete work summary
- `../.sisyphus/notepads/ums-fix-sogo/` - Additional investigation notes

## Commits Reference

- `7aec106` - fix(nubus): replace OX-specific cn=od.applications with OX-independent cn=applications
- `db354fc` - chore(helmfile): add helmfile_generic.yaml.gotmpl with SOGo enabled

## Support

For issues or questions regarding this OX-independent deployment:
1. Check this documentation first
2. Review the blocker analysis if helmfile fails
3. Verify LDAP configuration
4. Check pod and job logs