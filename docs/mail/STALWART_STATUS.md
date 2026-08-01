# ✅ Stalwart Mail Server — Operational

**Status:** ✅ Running — All 9 listeners active  
**Image:** `stalwartlabs/mail-server:v0.11.8`  
**Config Format:** Legacy compatible (`[server.listener.<name>]` with `bind` directive)  
**Ingress:** `mail.opendesk.hrz.uni-marburg.de` (HAProxy, TLS)  
**Storage:** 20Gi RWO (ceph-rbd-ssd)  
**Auth:** OIDC via Keycloak (`id.opendesk.hrz.uni-marburg.de/realms/opendesk`)  

---

## Overview

Stalwart is deployed and functional. All network listeners started successfully:

| Listener | Port | Protocol | TLS |
|----------|------|----------|-----|
| SMTP | 25 | smtp | ❌ |
| Submission | 587 | smtp | ❌ |
| Submissions | 465 | smtp | ✅ implicit |
| IMAP | 143 | imap | ❌ |
| IMAPS | 993 | imap | ✅ implicit |
| POP3 | 110 | pop3 | ❌ |
| POP3S | 995 | pop3 | ✅ implicit |
| ManageSieve | 4190 | managesieve | ❌ |
| HTTP (Admin API) | 8080 | http | ❌ |

## Notable Issues (Non-Blocking)

| Issue | Impact | Workaround |
|-------|--------|------------|
| Webadmin UI bundle cannot download from GitHub | Admin UI unavailable | Use API/admin CLI instead. Blocked by cluster network restrictions. |
| DNS record `mail.opendesk.hrz.uni-marburg.de` may not resolve externally | External access fails | Add CNAME/A record pointing to ingress IP `192.168.3.201` |

## Configuration

The config uses the **legacy listener format** (`[server.listener.smtp] bind = "[::]:25"`) which is fully compatible with v0.11.8. The Helm chart template at `helmfile/charts/stalwart/templates/configmap.yaml` generates this format — do not switch to the inline format (`"0.0.0.0:25" = { protocol = "smtp" }`) as v0.11.8 rejects it with `"No 'bind' directive found for listener"`.

## Quick Verification

```bash
# Check pod
kubectl get pods -n opendesk -l app.kubernetes.io/name=stalwart

# Check listeners
kubectl exec stalwart-stalwart-0 -n opendesk -- \
  cat /opt/stalwart-mail/logs/stalwart.log* | grep "listener started"

# Check OIDC config
kubectl exec stalwart-stalwart-0 -n opendesk -- \
  cat /opt/stalwart-mail/etc/config.toml | grep -A5 "auth.oauth2"

# Port-forward for SMTP test
kubectl port-forward -n opendesk svc/stalwart-stalwart 2525:25
# Then: telnet localhost 2525 → should see Stalwart banner
```

## Related Files

| File | Purpose |
|------|---------|
| `helmfile/charts/stalwart/` | Helm chart (templates, values) |
| `helmfile/apps/edu/stalwart/values.yaml.gotmpl` | Edu-specific values |
| `helmfile/environments/edu/secrets.yaml` | OIDC secrets |
| `helmfile/environments/edu/ce-overrides.yaml` | Resource overrides |

## History

- **2026-07-25**: Original deployment attempt — config format incompatibility
- **2026-07-27**: Config fixed using legacy format → Running stable
