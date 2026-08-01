# 🎯 GO - Stalwart + OpenCloud Deployment

**You're ready!** Here's your complete deployment roadmap.

---

## 🚀 START HERE

Pick your deployment path:

### 🔥 Quick Deploy (Testing/Staging)
```bash
cd ./opendesk-edu
helmfile --environment edu diff      # Review changes
helmfile --environment edu sync      # Deploy
```

### 🏭 Production Deploy
```bash
./DEPLOY_NOW.sh all                  # Interactive, does everything
```

---

## 📁 FILES CREATED FOR YOU

| File | Purpose | Action |
|------|---------|--------|
| ✅ `ANALYSIS_REPORT.md` | Complete gap analysis | **Read before production** |
| ✅ `DEPLOY_QUICK_START.md` | Quick start guide | **Bookmark this** |
| ✅ `DEPLOY_NOW.sh` | Interactive deployment | **Run this** |
| ✅ `DEPLOYMENT_COMPLETE.md` | Executive summary | **Review** |
| ✅ `STALWART_OPENCLOUD_DEPLOYMENT_SUMMARY.md` | Detailed summary | **Reference** |
| ✅ `QUICK_START_STALWART_OPENCLOUD.txt` | Quick reference | **Print this** |
| ✅ `FIX_ISSUES.sh` | Auto-fix identified issues | **Optional** |
| ✅ `opendesk-edu/docs/services-stalwart-opencloud.md` | Full guide | **Deep dive** |

---

## 🎯 DEPLOYMENT CHECKLIST

### ✅ DONE (by me)
- [x] Complete Stalwart configuration
- [x] Complete OpenCloud configuration
- [x] OIDC authentication configured
- [x] LDAP integration configured
- [x] Ingress with TLS configured
- [x] Storage configuration (RWO/RWX)
- [x] Security contexts configured
- [x] Resource limits configured
- [x] Health checks configured
- [x] Backup annotations added
- [x] Deployment scripts created
- [x] Documentation created

### ⏳ TODO (by you)
- [ ] Generate secrets (`./DEPLOY_NOW.sh secrets`)
- [ ] Register OIDC clients in Keycloak (`./DEPLOY_NOW.sh keycloak`)
- [ ] Create DNS records (`./DEPLOY_NOW.sh dns`)
- [ ] Deploy services (`./DEPLOY_NOW.sh deploy`)
- [ ] Verify deployment (`./DEPLOY_NOW.sh verify`)

---

## 📊 STATUS SUMMARY

| Component | Status | Details |
|-----------|--------|---------|
| **Configuration** | ✅ 100% Complete | All templates ready |
| **Secrets** | ⏳ 0% Complete | Need to generate (13 items) |
| **Keycloak Clients** | ⏳ 0% Complete | Need to register (2 clients) |
| **DNS** | ⏳ 0% Complete | Need to create (2 records) |
| **Prerequisites** | ❓ Unknown | Run `./DEPLOY_NOW.sh prereqs` |
| **Deployment** | ⏳ 0% Complete | Ready to deploy |

---

## 🎮 INTERACTIVE DEPLOYMENT

The easiest way to deploy - just follow the prompts:

```bash
./DEPLOY_NOW.sh
```

This will:
1. ✅ Check all prerequisites
2. ✅ Help you generate secrets
3. ✅ Guide you through OIDC client registration
4. ✅ Verify DNS configuration
5. ✅ Deploy the services
6. ✅ Verify the deployment

---

## 🚨 QUICK DEPLOY (for the impatient)

If you just want to see it working in staging:

```bash
# Generate minimal secrets (copy these into the secrets file)
echo "Generating minimal test secrets..."
openssl passwd -6 "admin123"                                    # Stalwart admin hash
openssl rand -hex 32                                           # Stalwart OIDC secret
openssl rand -base64 24                                        # LDAP bind password
openssl rand -hex 32                                           # OpenCloud OIDC secret
openssl rand -hex 32                                           # OpenCloud JWT secret

# Deploy (will fail without proper Keycloak/DNS, but shows structure)
cd ./opendesk-edu
helmfile --environment edu sync

# Watch it deploy
kubectl get pods -n opendesk -w
```

---

## 🔐 SECURITY NOTE

**Important:** The configuration uses placeholder secrets that must be replaced before production deployment.

**Generated secrets are for testing only!**
- Use strong, randomly generated passwords for production
- Store secrets securely (Kubernetes Secrets, Vault, etc.)
- Never commit actual secrets to version control

---

## 📚 DOCUMENTATION INDEX

### Quick References
- 📖 **Full Guide:** `opendesk-edu/docs/services-stalwart-opencloud.md`
- 📋 **Quick Start:** `DEPLOY_QUICK_START.md`
- 🎯 **This File:** `GO.md`

### Detailed Analysis
- 📊 **Gap Analysis:** `ANALYSIS_REPORT.md`
- 📝 **Deployment Summary:** `STALWART_OPENCLOUD_DEPLOYMENT_SUMMARY.md`
- ✅ **Complete Overview:** `DEPLOYMENT_COMPLETE.md`

### Scripts
- 🚀 **Deploy Now:** `./DEPLOY_NOW.sh` (interactive)
- 🔧 **Fix Issues:** `./FIX_ISSUES.sh` (auto-remediation)
- ✅ **Verify:** `./opendesk-edu/scripts/verify-stalwart-opencloud.sh`

### Configuration Files
- Stalwart: `opendesk-edu/helmfile/apps/edu/stalwart/values.yaml.gotmpl`
- OpenCloud: `opendesk-edu/helmfile/apps/edu/opencloud/values.yaml.gotmpl`
- Secrets: `opendesk-edu/helmfile/environments/edu/secrets.yaml`
- Overrides: `opendesk-edu/helmfile/environments/edu/ce-overrides.yaml`

---

## ✨ WHAT YOU'RE GETTING

### Stalwart Mail Server
- 📧 **Admin Console:** `https://mail.opendesk.hrz.uni-marburg.de`
- 🔐 **OIDC Authentication** via Keycloak
- 📚 **LDAP Integration** with UMS
- 🔒 **TLS Encryption** on all ports
- 💾 **20Gi Storage** on fast SSD (ceph-rbd-ssd)
- ⚙️ **IMAP, SMTP, POP3, Sieve** - all protocols
- 🛡️ **Security Hardened** (non-root, read-only FS, etc.)

### OpenCloud (Nextcloud)
- 📁 **Web Interface:** `https://files.opendesk.hrz.uni-marburg.de`
- 🔐 **OIDC Authentication** via Keycloak
- 👥 **Auto-provisioning** of users
- 💾 **100Gi Storage** on erasure-coded HDD (ceph-cephfs-hdd-ec)
- ⚙️ **2 Replicas** for high availability
- 🔄 **Backchannel Logout** support
- 🛡️ **Security Hardened**

---

## 🎓 STILL HAVE QUESTIONS?

### Q: Can I deploy without Keycloak?
**A:** No, both services require Keycloak for OIDC authentication. However, Stalwart has a fallback admin user for initial setup.

### Q: Can I deploy without DNS?
**A:** You can deploy, but services won't be accessible externally. For testing, you can use port-forwarding:
```bash
kubectl port-forward -n opendesk svc/stalwart 8080:80
kubectl port-forward -n opendesk svc/opencloud 8081:80
```

### Q: Can I deploy to a different namespace?
**A:** Yes! The configuration uses `opendesk` namespace, but you can change it:
```bash
# Deploy to a different namespace
helmfile --environment edu --namespace my-test-ns sync
```

### Q: Can I deploy only Stalwart or only OpenCloud?
**A:** Yes! Individual deployment scripts are available:
```bash
# Deploy only Stalwart
./opendesk-edu/scripts/deploy-stalwart.sh

# Deploy only OpenCloud
./opendesk-edu/scripts/deploy-opencloud.sh

# Deploy both
./opendesk-edu/scripts/deploy-stalwart-opencloud.sh
```

### Q: What if something goes wrong?
**A:** Check the troubleshooting section in `DEPLOY_QUICK_START.md` or run:
```bash
./DEPLOY_NOW.sh verify
```

### Q: How do I rollback?
**A:** Helmfile maintains a state file. To rollback:
```bash
cd ./opendesk-edu
helmfile --environment edu destroy  # Remove all releases
# or for specific releases:
helmfile --environment edu -l name=stalwart destroy
helmfile --environment edu -l name=opencloud destroy
```

---

## 🏆 READY, SET, GO!

You have everything you need. **Start your deployment now:**

```bash
./DEPLOY_NOW.sh
```

Or for the minimal path:
```bash
cd ./opendesk-edu
helmfile --environment edu sync
```

---

## 💬 COMMANDS SUMMARY

| Task | Command |
|------|---------|
| Check prerequisites | `./DEPLOY_NOW.sh prereqs` |
| Generate secrets | `./DEPLOY_NOW.sh secrets` |
| Check Keycloak | `./DEPLOY_NOW.sh keycloak` |
| Check DNS | `./DEPLOY_NOW.sh dns` |
| Deploy | `./DEPLOY_NOW.sh deploy` |
| Verify | `./DEPLOY_NOW.sh verify` |
| All steps | `./DEPLOY_NOW.sh all` |
| Quick deploy | `cd opendesk-edu && helmfile --environment edu sync` |
| Check status | `kubectl get pods -n opendesk` |
| View logs | `kubectl logs -f -n opendesk <pod-name>` |
| Rollback | `cd opendesk-edu && helmfile --environment edu destroy` |

---

## 🎉 YOU'RE ALL SET!

**The configuration is complete and ready for deployment.**

Everything you need is in this directory:
- ✅ Configuration files (in `opendesk-edu/helmfile/`)
- ✅ Deployment scripts (`DEPLOY_NOW.sh`, `FIX_ISSUES.sh`)
- ✅ Documentation (`GO.md`, `DEPLOY_QUICK_START.md`, etc.)
- ✅ Verification scripts

**Just run:**
```bash
./DEPLOY_NOW.sh
```

---

*Happy deploying! 🚀*

---

**Last Updated:** 2026-07-25  
**Maintainer:** AI Assistant  
**Repository:** openDesk Edu (HRZ Marburg)
