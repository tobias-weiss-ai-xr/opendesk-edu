# ⚠️ Stalwart Mail Server - BLOCKED (RESOLVED)

> **⚠️ THIS ISSUE IS RESOLVED — See [STALWART_STATUS.md](./STALWART_STATUS.md) for current status.**
> The config format incompatibility was resolved by using the legacy listener format
> (`[server.listener.smtp] bind = "[::]:25"`) which is fully compatible with v0.11.8.
> This file is kept for historical reference.

**Status:** ✅ RESOLVED — Stalwart is now running with legacy format config  
**Image:** stalwartlabs/mail-server:v0.11.8  
**Resolution:** The inline listener format (`[server.listener] "0.0.0.0:25" = { ... }`) is rejected by v0.11.8  
**Solution:** Use legacy section format (`[server.listener.smtp] bind = "[::]:25"`) instead

---

## 📋 ISSUE SUMMARY

Stalwart Mail Server v0.11.x container **rejects all configuration attempts** with errors:

```
ERROR: No 'bind' directive found for listener (server.listener.0.0.0.0:25)
ERROR: Missing property (storage.data, storage.blob, storage.lookup, storage.fts, storage.directory)
ERROR: Store not configured (store.not-configured)
```

**Tested Configurations:**
- ✅ Helm template generated config (v0.0.1 format) → ❌ Parse error
- ✅ Manual v0.11 format with map-style listeners → ❌ "No 'bind' directive"
- ✅ Minimal config with only required sections → ❌ "Missing property"
- ✅ Official Stalwart example configs → ❌ Same errors

---

## 🔍 ROOT CAUSE ANALYSIS

### Hypothesis 1: Image Version Mismatch
- Image tag: `v0.11.8` (latest available)
- Config format: Multiple variants tested
- **Status:** ❌ All fail

### Hypothesis 2: Container Runtime Issue
- Container runs as UID 0 (root)
- Volume mounts: `/opt/stalwart-mail/*`
- **Status:** ✅ Permissions correct (container can write to mounted volumes)

### Hypothesis 3: TOML Parsing Bug in v0.11
- Error message: "No 'bind' directive found"
- But `bind` IS in the config (as map key)
- **Status:** ⚠️ Possible bug in Stalwart v0.11 parser

### Hypothesis 4: Missing Required Configuration
- Tried with all required sections
- Tried with minimal sections only
- **Status:** ❌ Both fail

---

## 🎯 CURRENT DEPLOYMENT STATE

### ✅ What's Working
- **OpenCloud:** RUNNING (1/1 Ready)
- **Helm Chart:** Installed correctly
- **PVC:** Created (20Gi, ceph-rbd-ssd, Bound)
- **Service:** Created (ClusterIP, all ports exposed)
- **Ingress:** Created (mail.opendesk.hrz.uni-marburg.de)
- **ConfigMap:** Applied (v0.11 format)
- **StatefulSet:** Created (1 replica)

### ❌ What's Failing
- **Pod:** CrashLoopBackOff
- **Container:** Fails during startup (config parsing)
- **Error:** "No 'bind' directive found for listener"

---

## 📊 CONFIGURATION ATTEMPTS

### Attempt 1: Helm Template (v0.0.1 Format)
```toml
[server.listener.smtp]
bind = ["[::]:25"]
protocol = "smtp"
```
**Result:** ❌ Config parse error - incompatible format

### Attempt 2: v0.11 Map Format
```toml
[server.listener]
"0.0.0.0:25" = { protocol = "smtp" }
"0.0.0.0:587" = { protocol = "smtp", require-authentication = true }
```
**Result:** ❌ "No 'bind' directive found for listener"

### Attempt 3: Simple Map Format
```toml
[server.listener]
"0.0.0.0:25" = { protocol = "smtp" }
```
**Result:** ❌ "No 'bind' directive found for listener"

### Attempt 4: Minimal Config
```toml
[server]
name = "test"
[server.listener]
"0.0.0.0:8080" = { protocol = "http" }
[storage.data]
type = "rocksdb"
path = "/opt/stalwart-mail/data"
```
**Result:** ❌ "Missing property" for storage sections

---

## 🛠️ TROUBLESHOOTING CHECKLIST

- [x] Check container logs
- [x] Verify config file in container
- [x] Test with minimal configuration
- [x] Test with official example configs
- [x] Check image version compatibility
- [x] Verify volume mounts and permissions
- [x] Check UID/GID mapping
- [x] VerifyPaths exist in container
- [ ] **TEST: Run container interactively with config**
- [ ] **TEST: Try v0.11.0 instead of v0.11.8**
- [ ] **TEST: Check Stalwart GitHub issues for similar problems**
- [ ] **TEST: Contact Stalwart support**

---

## 💡 WORKAROUNDS TO TRY

### Workaround 1: Run Container Interactively
```bash
# Test config directly in container
kubectl run stalwart-test --rm -it \
  --image=docker.io/stalwartlabs/mail-server:v0.11.8 \
  --restart=Never \
  --mount type=configmap,name=stalwart-stalwart-config,items={path=config.toml} \
  -- sh

# Check config in container
cat /opt/stalwart-mail/etc/config.toml

# Try running manually
/stalwart-mail-server
```

### Workaround 2: Try Older v0.11 Tags
```bash
# Try v0.11.0
kubectl patch statefulset stalwart-stalwart -n opendesk --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "docker.io/stalwartlabs/mail-server:v0.11.0"}]'

# Try v0.11.1 through v0.11.7
```

### Workaround 3: Use v0.10.x Series
```bash
# Try v0.10.1
kubectl patch statefulset stalwart-stalwart -n opendesk --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "docker.io/stalwartlabs/mail-server:v0.10.1"}]'
```

### Workaround 4: Check Stalwart GitHub
```bash
# Search for similar issues
# https://github.com/stalwartlabs/mail-server/issues?q="No+bind+directive"
```

---

## 🎯 IMMEDIATE NEXT STEPS

### Step 1: Test Container Interactively (5 minutes)
```bash
kubectl run stalwart-test --rm -it --image=docker.io/stalwartlabs/mail-server:v0.11.8 --restart=Never -- sh
# In container: cat /opt/stalwart-mail/etc/config.default.toml
# Exit and re-enter with our config:
kubectl cp /tmp/test-config.toml stalwart-test:/opt/stalwart-mail/etc/config.toml
kubectl exec -it stalwart-test -- /stalwart-mail-server
```

### Step 2: Try Different Image Tags (15 minutes)
```bash
for tag in v0.11.0 v0.11.1 v0.11.2 v0.11.3 v0.11.4 v0.11.5 v0.11.6 v0.11.7 v0.11.8; do
  echo "Testing tag: $tag"
  kubectl patch statefulset stalwart-stalwart -n opendesk --type='json' \
    -p="[{\"op\": \"replace\", \"path\": \"/spec/template/spec/containers/0/image\", \"value\": \"docker.io/stalwartlabs/mail-server:$tag\"}]" 2>/dev/null
  kubectl delete pod stalwart-stalwart-0 -n opendesk 2>/dev/null
  sleep 30
  kubectl logs stalwart-stalwart-0 -n opendesk 2>&1 | grep -E "(Starting|ERROR)" | head -5
  sleep 10
done
```

### Step 3: Check Official Documentation (10 minutes)
```bash
# Check Stalwart docs for v0.11 config examples
# https://docs.stalwartlabs.com/mail-server/configuration
```

### Step 4: Use Dovecot + Postfix Instead (Fallback)
```bash
# Disable Stalwart
helm uninstall stalwart -n opendesk

# Enable Dovecot + Postfix from CE
# Edit opendesk/helmfile/apps/edu/mail/values.yaml.gotmpl
```

---

## 📋 ALTERNATIVE: USE DOVECOT + POSTFIX

If Stalwart cannot be deployed, consider using the traditional mail stack:

### Pros:
- ✅ Already tested and working in openDesk CE
- ✅ Mature, stable software
- ✅ Well-documented
- ✅ Full LDAP integration support
- ✅ No configuration format issues

### Cons:
- ❌ More complex (2 services instead of 1)
- ❌ No built-in web admin interface
- ❌ No advanced features (JMAP, modern protocols)

### How to Enable:
```bash
# In opendesk/helmfile/apps/edu/stalwart/values.yaml.gotmpl
# Set: enabled: false

# In opendesk/helmfile/apps/ce/mail/values.yaml.gotmpl
# Set: enabled: true

# Deploy
cd opendesk/helmfile
helmfile --environment edu sync
```

---

## 📊 DECISION MATRIX

| Option | Effort | Risk | Timeline | Recommendation |
|--------|--------|------|----------|----------------|
| **Fix Stalwart v0.11** | High | Medium | Unknown | ⚠️ If time permits |
| **Try older Stalwart** | Medium | Low | 30 min | ✅ Worth trying |
| **Use Dovecot+Postfix** | Low | Low | Immediate | ✅ Fallback option |
| **Wait for Stalwart v0.12** | None | Medium | Weeks | ❌ Not viable |

---

## 🏁 RECOMMENDATION

### Immediate (Next 30 minutes)
1. **Test with v0.11.0** (first v0.11 release)
2. **Check Stalwart GitHub issues** for similar problems
3. **If still failing:** Use Dovecot + Postfix as fallback

### If More Time Available
1. **Test with v0.10.x** series (may have different config format)
2. **Run container interactively** to debug config parsing
3. **Contact Stalwart support/community** for assistance

### Production Decision
For production readiness, **Stalwart should be disabled** and **Dovecot + Postfix enabled** until the configuration issue is resolved.

---

## 📚 REFERENCES

- **Stalwart GitHub:** https://github.com/stalwartlabs/mail-server
- **Stalwart Docs:** https://docs.stalwartlabs.com/mail-server
- **Docker Hub:** https://hub.docker.com/r/stalwartlabs/mail-server
- **openDesk CE Mail:** opendesk/helmfile/apps/ce/mail/

---

## 📞 SUPPORT

### Stalwart Support
- GitHub Issues: https://github.com/stalwartlabs/mail-server/issues
- Discord: https://discord.gg/stalwartlabs
- Email: support@stalwartlabs.com

### openDesk Support
- Repository: https://codeberg.org/openDesk/opendesk-edu
- Issues: https://codeberg.org/openDesk/opendesk-edu/issues

---

**Last Updated:** July 25, 2026, 10:55 PM CEST  
**Next Review:** Pending Stalwart config fix  
**Status:** BLOCKED - Configuration format incompatible with v0.11.x  
**Priority:** HIGH - Mail server is critical for production
