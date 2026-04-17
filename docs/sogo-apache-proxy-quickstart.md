# SOGo Apache Proxy Deployment - Quick Start

## Status

✅ **Technical Solution Complete** - Ready for deployment

## One-Line Deployment

Execute on server `root@178.63.182.104`:

```bash
cd /root/opendesk-edu && bash scripts/deploy-sogo-apache-proxy.sh
```

## What This Does

1. Fetches `feature/sogo-fix` branch from Codeberg
2. Deploys SOGo Helm chart with Apache proxy enabled
3. Verifies Apache is running and port 80 is listening
4. Tests SOGo web interface accessibility

## Expected Results

**After deployment:**
- SOGo pod: READY 1/1
- Apache: RUNNING (supervisorctl shows apache process)
- Port 80: LISTENING (netstat shows apache bound to 0.0.0.0:80)
- SOGo interface: Accessible via http://pod-ip:80/

## Architecture

```
External Request → Port 80 (Apache) → 127.0.0.1:20000 (SOGo) → Application
```

**Why Apache is required:**
SOGo's WOHttpAdaptor runs on `127.0.0.1:20000` (internal watchdog only).
External HTTP access requires Apache reverse proxy to bind to port 80.

## Verification Steps

```bash
# Get pod name
POD=$(kubectl -n opendesk-edu get pods -l app.kubernetes.io/instance=sogo -o name | head -1)

# Check Apache status
kubectl -n opendesk-edu exec $POD -- supervisorctl status apache
# Expected: apache  RUNNING  pid XXX, uptime 0:00:XX

# Check port 80
kubectl -n opendesk-edu exec $POD -- netstat -tlnp | grep :80
# Expected: tcp  0  0 0.0.0.0:80  0 0.0.0.0:*  LISTEN  XXX/apache2

# Test web interface
kubectl -n opendesk-edu exec $POD -- curl -v http://localhost:80/
# Expected: HTTP 200 or 302 redirect
```

## Troubleshooting

### Pod not ready?
```bash
kubectl -n opendesk-edu get pods -l app.kubernetes.io/instance=sogo
kubectl -n opendesk-edu logs $POD
```

### Apache not running?
```bash
kubectl -n opendesk-edu exec $POD -- supervisorctl status
kubectl -n opendesk-edu exec $POD -- cat /opt/custom-entrypoint/supervisord.conf | grep -A5 "^\[program:apache\]"
```

### Port 80 not listening?
```bash
kubectl -n opendesk-edu exec $POD -- netstat -tlnp
kubectl -n opendesk-edu logs $POD | tail -50
```

## Work Plan Status

**Completed (Tasks 1-7):**
✅ LDAP neutrality (cn=od.applications → cn=applications)
✅ Core infrastructure deployed
✅ SOGo image built (5.12.7 with ActiveSync)
✅ PostgreSQL database and user created
✅ ConfigMap YAML format fixed
✅ SSL mode configured
✅ Apache proxy configured

**Pending (Tasks 8-10):**
⏳ Verify SOGo web interface accessible (after deployment)
⏳ Verify SOGo authentication works (after deployment)
⏳ Complete documentation (after deployment verified)

## Technical Details

### Commits on feature/sogo-fix

1. **c3594d8** - `fix(sogo): enable Apache proxy for port 80 access`
   - Enabled Apache in supervisord configuration
   - Apache command: `/usr/sbin/apache2 -c "ErrorLog /dev/stdout" -D FOREGROUND`
   - Simplified entrypoint script
   - Removed deprecated sogo-tool-plus-wrapper

2. **4b7efa3** - `feat(sogo): add Apache proxy deployment script`
   - Created `scripts/deploy-sogo-apache-proxy.sh`
   - Automated deployment workflow
   - Built-in verification steps

### Files Modified

- `helmfile/charts/sogo/templates/entrypoint-configmap.yaml`
  - Added Apache program block in supervisord.conf
  - Modified entrypoint.sh to start supervisord
- `scripts/deploy-sogo-apache-proxy.sh`
  - New automated deployment script

### Key Configuration

**Apache supervisord program:**
```ini
[program:apache]
user=root
command=/usr/sbin/apache2 -c "ErrorLog /dev/stdout" -D FOREGROUND
autostart=true
autorestart=true
```

**SOGo supervisord program:**
```ini
[program:sogo]
user=root
command=/usr/local/sbin/sogod -WOWorkersCount 5
autostart=true
autorestart=true
```

## Access SOGo

After successful deployment, access via:
- HTTP: `http://sogo.opendesk-edu.org/`
- HTTPS: `https://sogo.opendesk-edu.org/` (if TLS configured)

Authentication via Keycloak OIDC will be automatic.

## Next Steps

After deployment verification:

1. Login to SOGo via web interface
2. Verify email functionality (IMAP/SMTP)
3. Test calendar synchronization
4. Test contacts management
5. Verify key部件: user LDAP synchronization
6. Complete work plan tasks 8-10

## Reproducibility

All changes versioned in `feature/sogo-fix` branch:

```bash
git clone https://codeberg.org/opendesk-edu/opendesk-edu.git
cd opendesk-edu
git checkout feature/sogo-fix
bash scripts/deploy-sogo-apache-proxy.sh
```

---

**Deployment ready. Execute the script on the server to complete SOGo setup.**