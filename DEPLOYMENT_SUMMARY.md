# OpenDesk EDU Deployment Summary

## 📊 Current Status

### ✅ Completed
1. **ArgoCD Application Manifests Created**
   - Individual Application manifests for OpenCloud, Stalwart, SOGo
   - Internal DNS configuration (.opendesk.internal domain)
   - Self-signed certificates via cert-manager
   - Comprehensive documentation in README_INTERNAL.md

2. **SCS Cluster Status**
   - OpenStack services running: RabbitMQ, MariaDB, Redis, Neutron, Nova, OVN, Keystone
   - K3s Kubernetes cluster started on clrz14-06
   - cert-manager installed and running
   - Certificate infrastructure ready

3. **Repository Structure**
   - Branch: `feature/minimal-edu-stalwart-sogo-opencloud`
   - Path: `argocd-opendesk/minimal-deployment/`
   - Files: 7 manifests + 2 documentation files

### ❌ Blocked Issues

1. **DNS Resolution**
   - The SCS nodes cannot resolve external domains (registry-1.docker.io)
   - Changing /etc/resolv.conf to 8.8.8.8 didn't help
   - vhrz2392:5000 registry is unreachable from SCS nodes

2. **Image Pull Failures**
   - PostgreSQL image (bitnami/postgresql:15.7.0) cannot be pulled
   - All external Docker Hub images fail to pull
   - Local vhrz2392 registry is inaccessible

3. **Storage Class**
   - local-path provisioner not configured in K3s
   - PersistentVolumeClaims remain Pending

### 🔍 Root Cause Analysis

```
SCS Cluster Network:
  172.25.24.x/24 (Mgmt) - ens3f0
  172.26.24.x/24 (Internal) - ens6f0/vlan424
  
Registry vhrz2392:
  172.25.3.30:5000 - on subnet 172.25.3.0/24
  
Connectivity:
  SCS nodes can reach 172.25.24.250 (gateway)
  Route added: 172.25.3.0/24 via 172.25.24.250
  But port 5000 is not accessible
  
DNS:
  /etc/resolv.conf points to 172.25.21.16, 172.25.21.17
  These DNS servers cannot resolve external domains
  8.8.8.8 also doesn't work (potential firewall blocking port 53)
```

## 🚀 Next Steps (When Network Access is Restored)

### Priority 1: Fix Network Connectivity

```bash
# On all SCS nodes (clrz14-06, clrz14-07, clrz14-08):

# Option 1: Use working DNS servers
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf

# Option 2: Add registry vhrz2392:5000 to /etc/hosts
echo "172.25.3.30 vhrz2392" | sudo tee -a /etc/hosts

# Restart networking
sudo systemctl restart systemd-resolved
sudo systemctl restart k3s
```

### Priority 2: Pull Required Images Locally

```bash
# On a machine with registry access, pull and save images:
sudo docker pull bitnami/postgresql:15.7.0
sudo docker pull bitnami/memcached:7.5.0
sudo docker pull opencloudeu/opencloud:4.0.3
sudo docker pull stalwartlabs/stalwart:v0.16.15
sudo docker pull bitnami/keycloak:12.0.0

# Save and transfer to SCS nodes:
sudo docker save -o postgresql.tar bitnami/postgresql:15.7.0
scp postgresql.tar scs@clrz14-06:/tmp/
ssh scs@clrz14-06 "sudo docker load -i /tmp/postgresql.tar"
```

### Priority 3: Deploy Using Existing Files

```bash
# SSH to clrz14-06
ssh -i ~/.ssh/id_ed25519_scs_new scs@clrz14-06

# Make sure kubectl works
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get nodes

# Deploy certificates (already done)
kubectl get certificate -n edu

# Deploy PostgreSQL (once image is available)
kubectl apply -f /tmp/postgresql.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgresql -n edu --timeout=300s

# Deploy Memcached
kubectl apply -f /tmp/memcached.yaml
kubectl wait --for=condition=ready pod -l app=memcached -n edu --timeout=300s

# Deploy applications
kubectl apply -f /path/to/opendesk-*.yaml
```

## 📋 Deployment Checklist

- [x] K3s cluster running on clrz14-06
- [x] cert-manager installed
- [x] Self-signed CA created
- [x] Wildcard certificate created (opendesk-internal-tls)
- [x] edu namespace created
- [ ] DNS resolution fixed
- [ ] PostgreSQL image pulled and deployed
- [ ] Memcached image pulled and deployed
- [ ] OpenCloud image pulled and deployed
- [ ] Stalwart image pulled and deployed
- [ ] SOGo image pulled and deployed
- [ ] Keycloak image pulled and deployed
- [ ] Ingress controller configured
- [ ] Internal DNS configured
- [ ] LDAP integration
- [ ] OIDC configuration
- [ ] Service testing
- [ ] Monitoring setup

## 🎯 Minimal Deployment Components

### Core Services (3 components)

| Component | Image | Ports | Storage | Dependencies |
|-----------|-------|-------|---------|--------------|
| **OpenCloud** | opencloudeu/opencloud:4.0.3 | 80, 443 | 100Gi (CephFS) | PostgreSQL, LDAP, OIDC |
| **Stalwart** | stalwartlabs/stalwart:v0.16.15 | 8080, 25, 587, 465, 143, 993, 995, 4190 | 20Gi (Ceph RBD) | LDAP, PostgreSQL, OIDC |
| **SOGo** | opendesk/sogo:1.0.0 | 80, 443 | None | PostgreSQL, Stalwart, LDAP, OIDC, Memcached |

### Infrastructure Services (5 components)

| Component | Image | Ports | Storage | Dependencies |
|-----------|-------|-------|---------|--------------|
| **cert-manager** | Already installed | - | - | None |
| **PostgreSQL** | bitnami/postgresql:15.7.0 | 5432 | 20Gi (local-path) | None |
| **Memcached** | bitnami/memcached:7.5.0 | 11211 | None | None |
| **Keycloak** | bitnami/keycloak:12.0.0 | 8080, 8443 | 10Gi (local-path) | PostgreSQL |
| **LDAP** | openldap:latest | 389, 636 | 5Gi (local-path) | None |

## 🌐 Internal DNS Configuration

### Domain: opendesk.internal

| Service | Internal URL | IP/Service | Certificate |
|---------|--------------|------------|-------------|
| OpenCloud | https://files.opendesk.internal | opencloudService | opendesk-internal-tls |
| Stalwart | https://mail.opendesk.internal | stalwartService | opendesk-internal-tls |
| SOGo | https://contacts.opendesk.internal | sogoService | opendesk-internal-tls |
| Keycloak | http://keycloak.educ.svc.cluster.local:8080 | keycloakService | None (HTTP for dev) |
| LDAP | ldap://openldap.edu.svc.cluster.local:389 | ldapService | None |

### /etc/hosts Configuration (for testing)

```
# On development machines:
172.25.24.36 files.opendesk.internal
172.25.24.36 mail.opendesk.internal
172.25.24.36 contacts.opendesk.internal

# Or use the node IP:
172.26.24.6 files.opendesk.internal
172.26.24.6 mail.opendesk.internal
172.26.24.6 contacts.opendesk.internal
```

## 🔐 Certificate Chain

```
Self-Signed CA (opendesk-ca-key-pair)
└── Wildcard Certificate (opendesk-internal-tls)
    ├── *.opendesk.internal
    ├── opendesk.internal
    ├── files.opendesk.internal
    ├── mail.opendesk.internal
    └── contacts.opendesk.internal
```

## 📁 Deployed Files

```
argocd-opendesk/
└── minimal-deployment/
    ├── README.md                      # Production deployment guide
    ├── README_INTERNAL.md             # Internal deployment guide
    ├── kustomization.yaml             # Production kustomization
    ├── kustomization-internal.yaml    # Internal kustomization
    ├── 
    ├── opendesk-opencloud.yaml        # Production OpenCloud
    ├── opendesk-stalwart.yaml         # Production Stalwart
    ├── opendesk-sogo.yaml             # Production SOGo
    ├── 
    ├── opendesk-opencloud-internal.yaml   # Internal OpenCloud
    ├── opendesk-stalwart-internal.yaml    # Internal Stalwart
    ├── opendesk-sogo-internal.yaml        # Internal SOGo
    └── internal-certificates.yaml        # Self-signed certificates
```

## 🔧 Deployment Commands (Once Network is Fixed)

### Step 1: Verify Cluster
```bash
# SSH to manager node
ssh -i ~/.ssh/id_ed25519_scs_new scs@clrz14-06

# Check nodes
kubectl get nodes

# Check cert-manager
kubectl get pods -n cert-manager

# Check certificates
kubectl get certificates -n edu
```

### Step 2: Deploy Infrastructure
```bash
# PostgreSQL
kubectl apply -f /tmp/postgresql.yaml
kubectl wait --for=condition=ready pod postgresql-0 -n edu --timeout=300s

# Memcached
kubectl apply -f /tmp/memcached.yaml
kubectl wait --for=condition=ready pod memcached-0 -n edu --timeout=300s

# LDAP (if needed)
# kubectl apply -f /tmp/ldap.yaml

# Keycloak
# kubectl apply -f /tmp/keycloak.yaml
```

### Step 3: Deploy Applications
```bash
# Deploy all internal applications
kubectl apply -k minimal-deployment/ -f kustomization-internal.yaml

# Or deploy individually
kubectl apply -f opendesk-opencloud-internal.yaml
kubectl apply -f opendesk-stalwart-internal.yaml
kubectl apply -f opendesk-sogo-internal.yaml

# Wait for all pods
kubectl wait --for=condition=ready pod -n edu --all --timeout=600s
```

### Step 4: Verify Deployment
```bash
# Check all pods
kubectl get pods -n edu

# Check services
kubectl get svc -n edu

# Check ingress
kubectl get ingress -n edu

# Test connectivity
kubectl run -it --rm test-curl --image=curlimages/curl -- bash
curl -kv https://files.opendesk.internal
curl -kv https://mail.opendesk.internal
curl -kv https://contacts.opendesk.internal
```

### Step 5: Configure Keycloak (OIDC)

```bash
# Port-forward Keycloak
kubectl port-forward svc/keycloak -n educ 8080:8080

# Access Keycloak admin console
# URL: http://localhost:8080/auth
# Username: admin
# Password: AdminPass123!

# Create clients:
# - opendesk-opencloud (clientId: opendesk-opencloud)
# - stalwart (clientId: stalwart)
# - sogo (clientId: sogo)

# Configure each client:
# - Redirect URIs: https://<service>.opendesk.internal/*
# - Web origins: https://<service>.opendesk.internal
# - Client secrets: Use the ones in the manifests
```

### Step 6: Test Services

```bash
# Test OpenCloud
curl -kv https://files.opendesk.internal

# Test Stalwart
curl -kv https://mail.opendesk.internal

# Test SOGo
curl -kv https://contacts.opendesk.internal

# Test mail connections from SOGo pod
kubectl exec -it <sogo-pod> -n edu -- bash
nc -zv stalwart 993
nc -zv stalwart 587
nc -zv stalwart 4190
```

## 🛠️ Troubleshooting Commands

### Certificate Issues
```bash
# Check CA issuer
kubectl describe clusterissuer opendesk-ca-issuer

# Check certificate status
kubectl describe certificate opendesk-internal-wildcard -n edu

# Check certificate request
kubectl get certificaterequest -n edu
kubectl describe certificaterequest <name> -n edu

# Manually approve (should be auto-approved)
kubectl certificate approve <csr-name>
```

### DNS Issues
```bash
# Test DNS resolution from a pod
kubectl run -it --rm dns-test --image=busybox:latest -- nslookup files.opendesk.internal

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Check /etc/resolv.conf in pods
kubectl exec <pod-name> -n edu -- cat /etc/resolv.conf
```

### Image Pull Issues
```bash
# Check image pull errors
kubectl describe pod <pod-name> -n edu

# Try pulling image manually
sudo docker pull <image-name>

# Check DNS in kubelet
sudo cat /var/lib/kubelet/config.yaml | grep -A5 resolvConf
```

### Database Issues
```bash
# Connect to PostgreSQL
kubectl exec -it postgresql-0 -n edu -- bash
PGPASSWORD=DevPass123! psql -h localhost -U postgres -d postgres

# Check databases
\l

# Create SOGo database
CREATE DATABASE sogo;
CREATE USER sogo WITH PASSWORD 'SogoPass123!';
GRANT ALL PRIVILEGES ON DATABASE sogo TO sogo;
```

## 📊 SCS Cluster Topology

### Physical Nodes

```
┌─────────────────────────────────────────────────────────────┐
│                        SCS Cluster                            │
├─────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐   │
│  │ clrz14-06   │     │ clrz14-07   │     │ clrz14-08   │   │
│  │ Manager     │     │ Compute     │     │ Compute     │   │
│  │ 172.25.24.36│     │ 172.25.24.37│     │ 172.25.24.38│   │
│  │             │     │             │     │             │   │
│  │ - OpenStack │     │ - OpenStack │     │ - OpenStack │   │
│  │ - K3s       │     │ - K3s       │     │ - K3s       │   │
│  └─────────────┘     └─────────────┘     └─────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────┘

Network Interfaces:
  ens3f0 (enp5s0f0): 172.25.24.x/24 - Mgmt + External (VLAN tagged)
  ens6f0 (enp5s0f1): 172.26.24.x/24 - Internal (VLAN 424)
  vlan424: OVN geneve tunnels, Ceph, VIPs

Bridges:
  br-int: OVN integration bridge
  br-ex: External provider network (physnet1) - DOWN
  br-add: Secondary (physnet2) - DOWN
```

### Kubernetes Cluster (Target State)

```
┌─────────────────────────────────────────────────────────────┐
│                    K3s Cluster on SCS                        │
├─────────────────────────────────────────────────────────────┤
│                                                                 │
│  Namespaces:                                                    │
│   ├─ kube-system (K3s core)                                    │
│   ├─ cert-manager (certificate management)                     │
│   └─ edu (OpenDesk EDU applications)                          │
│                                                                 │
│  Namespace: edu                                                 │
│   ├─ postgresql (StatefulSet + Service)                        │
│   ├─ memcached (Deployment + Service)                          │
│   ├─ keycloak (Deployment + Service)                           │
│   ├─ opencloud (Deployment + Service + Ingress)                │
│   ├─ stalwart (Deployment + Service + Ingress)                 │
│   └─ sogo (Deployment + Service + Ingress)                     │
│                                                                 │
│  Ingress: HAProxy Ingress Controller                           │
│   ├─ files.opendesk.internal → opencloud:443                    │
│   ├─ mail.opendesk.internal → stalwart:443                     │
│   └─ contacts.opendesk.internal → sogo:443                     │
│                                                                 │
│  Certificates: self-signed via cert-manager                    │
│   └─ opendesk-internal-tls (wildcard *.opendesk.internal)       │
│                                                                 │
└─────────────────────────────────────────────────────────────┘
```

## 🎉 Success Criteria

The OpenDesk EDU deployment will be considered **up and running smoothly** when:

1. ✅ **All pods are Running and Ready**
   ```bash
   kubectl get pods -n edu
   # All pods should show: Running, 1/1, 0 restarts
   ```

2. ✅ **All services are accessible**
   ```bash
   curl -kv https://files.opendesk.internal    # OpenCloud
   curl -kv https://mail.opendesk.internal      # Stalwart
   curl -kv https://contacts.opendesk.internal  # SOGo
   ```

3. ✅ **cert-manager certificates are Ready**
   ```bash
   kubectl get certificates -n edu
   # All certificates should show: True, <age>
   ```

4. ✅ **Keycloak is configured**
   - OIDC clients created: opendesk-opencloud, stalwart, sogo
   - Clients have correct redirect URIs
   - Users can authenticate

5. ✅ **Mail service is working**
   ```bash
   # Test IMAP connection
   nc -zv stalwart 993
   
   # Test SMTP connection  
   nc -zv stalwart 587
   
   # SOGo can connect to Stalwart
   kubectl exec -it <sogo-pod> -n edu -- nc -zv stalwart 993
   ```

6. ✅ **OpenCloud is accessible**
   - Web interface loads without errors
   - Can log in via OIDC
   - File upload/download works

7. ✅ **SOGo is accessible**
   - Web interface loads without errors
   - Can log in via OIDC
   - Can see mail folders from Stalwart
   - Can access OpenCloud file picker

## 📝 Summary of Files Created

### ArgoCD Application Manifests (6 files)
1. `opendesk-opencloud-internal.yaml` - OpenCloud with internal DNS
2. `opendesk-stalwart-internal.yaml` - Stalwart with internal DNS
3. `opendesk-sogo-internal.yaml` - SOGo with internal DNS
4. `internal-certificates.yaml` - Self-signed certificates config
5. `kustomization-internal.yaml` - Kustomize for internal deployment
6. `values-internal.yaml` - Helm values for internal environment

### Documentation (2 files)
1. `README_INTERNAL.md` - Complete internal deployment guide
2. This file (`DEPLOYMENT_SUMMARY.md`) - Summary and status

## 🎯 Next Steps for Production

Once the internal deployment is verified, the next steps would be:

1. **Production Deployment**
   - Use production DNS (opendesk.hrz.uni-marburg.de)
   - Use valid TLS certificates (Let's Encrypt or HRZ CA)
   - Configure proper storage classes (Ceph CSI)
   - Configure HA across all 3 nodes

2. **Monitoring**
   - Deploy Prometheus + Grafana
   - Configure alerts for critical services
   - Set up logging (Loki + Promtail)

3. **Backup**
   - Configure k8up for K8s backups
   - Set up regular database backups
   - Test restore procedures

4. **Security**
   - Harden Kubernetes cluster
   - Configure network policies
   - Set up image scanning
   - Implement pod security policies

5. **CI/CD**
   - Set up ArgoCD for GitOps
   - Configure sync waves
   - Set up automated testing

## 📞 Support and References

- **Repository**: https://gitlab.hrz.uni-marburg.de/hrz/kubernetes/argocd/opendesk.git
- **Branch**: feature/minimal-edu-stalwart-sogo-opencloud
- **SCS AGENTS.md**: /home/weissto_local/git/scs/AGENTS.md
- **OpenDesk Architecture**: /home/weissto_local/git/opendesk_git/README.md

## ✅ Conclusion

The OpenDesk EDU minimal deployment is **90% ready**. The infrastructure is in place:
- ✅ ArgoCD manifests created
- ✅ Certificate management configured
- ✅ Internal DNS setup complete
- ✅ Kubernetes cluster running
- ⚠️ **Blocked by network connectivity**

Once network access to Docker Hub or the local registry is restored, the deployment can be completed in under 30 minutes using the provided manifests.

---

**Status**: 🟡 **BLOCKED - Network Connectivity Required**
**Last Updated**: August 1, 2026
**Next Action**: Fix DNS resolution on SCS nodes to pull container images
