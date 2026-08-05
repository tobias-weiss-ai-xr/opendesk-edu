# Sprint: Fix Issues

**Goal:** Fix remaining deployment issues in opendesk-edu

## Tasks

1. **snipr removal**
   - No upstream image exists (ghcr.io/tobias-weiss-ai-xr/snipr not found)
   - Remove chart templates or clearly mark as scaffold
   - Delete stuck helm release

2. **SOGo ingress — no LB address**
   - sogo.opendesk.hrz.uni-marburg.de has no ADDRESS
   - Compare with working ingresses (bookstack, drawio)
   - Check haproxy backend config / ingress annotations

3. **ILIAS ingress — wrong class**
   - Uses `<none>` instead of `haproxy`
   - Patch ingressClassName

4. **Planka — 6 restarts in 14h**
   - Investigate logs / events
   - Likely OOM or probe failure
   - Fix and stabilize
