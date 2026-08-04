# openDesk Edu — Historical Deployment Notes

This file consolidates useful architectural knowledge from the April 2026
edu deployment cycle. The actual deployment target has moved to the HRZ cluster
(`*.opendesk.hrz.uni-marburg.de`). This is kept for reference only.

---

## SOGo Architecture

- **WOHttpAdaptor** runs on `127.0.0.1:20000` (internal watchdog ONLY)
- **External access** requires Apache reverse proxy on port 80
- Config parameters `SOGoDaemonAddresses` and `SOGoListenPort` are for Apache config, not SOGo itself
- SOGo 5.12.7 with ActiveSync support

```
External Request → Port 80 (Apache) → 127.0.0.1:20000 (SOGo) → Workers
```

## Portal Architecture

- **Data Initialization**: `stack-data-ums` job processes 24 YAML files via data-loader
- **Entry Creation**: `41-selfservice-portal.yaml` creates self-service portal structure
- **Authentication**: Reads from `ums-portal-consumer-object-storage` secret (MinIO)
- **Provisioning**: Registers via provisioning-api

## Git History (feature/sogo-fix branch)

```
932149d docs: Update AGENTS.md with WSL bash requirement
e382a8f fix(sogo): Add DefaultRuntimeDir and remove sogo-manage
c3594d8 fix(sogo): enable Apache proxy for port 80 access
4b7efa3 chore(sogo): Create deployment script
098f9c5 docs(sogo): Add quickstart guide
6e3231d docs(sogo): Update work plan completion status
450043b docs: update work plan status - tasks 8-10 blocked
cf61abb docs: Add UMS-SOGO-DEPLOYMENT-STATUS.md
```

## Key Fixes (recorded, not deployed — target moved to HRZ cluster)

### Portal MinIO Credentials
- **Problem**: Invalid MinIO credentials in `ums-portal-consumer-object-storage` secret
- **Fix**: Copy valid credentials from `ums-portal-server-object-storage` secret
- **Verification**: Pod status Running, portal returns HTTP 200

### SOGo Apache Proxy
- **Problem**: Apache FATAL with DefaultRuntimeDir AH00111 error (stale ConfigMap)
- **Fix**: Delete ConfigMap `sogo-sogo-entrypoint` and redeploy
- **Apache config**: `apache2 -c "DefaultRuntimeDir /var/run/apache2" -D FOREGROUND`
- **Verification**: Port 80 listening, curl localhost:80 returns 200
