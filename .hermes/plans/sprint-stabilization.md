# Sprint: Stabilization

## Goal
Harden the cluster — fix Nextcloud OOM, add backups, set resource limits, fix
NetworkPolicies, verify all pods healthy.

## Tasks

### 1. Nextcloud OOM (memory)
- Check current Nextcloud pod state and OOM kill history
- Add resource limits to the Nextcloud chart deployment
- Apply via helmfile upgrade or kubectl rollout

### 2. k8up backup schedules
- Inventory edu PVCs that need backup (bookstack, planka, limesurvey, etc.)
- Create k8up Schedule custom resources for each
- Verify backup jobs complete successfully

### 3. Resource limits audit
- kubectl top pods / describe all 34+ edu pods
- Identify which lack resource requests/limits
- Patch charts or values to set sensible defaults

### 4. NetworkPolicy audit
- Check all edu service NetworkPolicies
- Ensure each allows ingress from `ingress-controller` namespace (HAProxy)
- Add where missing

### 5. Verify all pods healthy
- Full pod status check across opendesk, opendesk-edu, opendesk-sso
- Check restart counts, crash loops, pending PVCs
- Fix any issues found
