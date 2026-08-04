# 🚀 Push Docker Images to GitLab Registry (opencode.de) - Complete Guide

**Namespace:** `registry.gitlab.opencode.de/umr/`  
**Status:** Ready for immediate use  
**Target Images:** SOGo 5, SOGo 6, Dev Agent, Website, SBOM Generator

---

## 📋 QUICK START

### **1. Login Once**
```bash
# Replace YOUR_PAT with your actual GitLab opencode.de personal access token
export OPENCODE_TOKEN="YOUR_PAT"

# Login to GitLab Container Registry
echo "$OPENCODE_TOKEN" | docker login registry.gitlab.opencode.de -u weiss --password-stdin

# Verify login worked
cat ~/.docker/config.json | jq '.auths["registry.gitlab.opencode.de"]'
```

### **2. Push Images**
```bash
# Navigate to nix directory
cd /home/weissto_local/git/opendesk_git/opendesk/opendesk-nix

# Using the push script
../../../push-umr-images.sh

# Or manually
./push-all-to-gitlab.sh
```

---

## 🐳 DOCKER-ONLY (Quick Push)

### **Login**
```bash
export OPENCODE_TOKEN="YOUR_PAT"
echo "$OPENCODE_TOKEN" | docker login registry.gitlab.opencode.de -u weiss --password-stdin
```

### **Push Existing Images**
```bash
# Tag your existing images with GitLab registry
docker tag ghcr.io/opendesk-edu/opendesk-edu-website:latest \
  registry.gitlab.opencode.de/umr/opendesk-edu-website:latest

docker tag ghcr.io/tobias-weiss-ai-xr/opendesk-dev-agent-operator:latest \
  registry.gitlab.opencode.de/umr/dev-agent:latest

# Push to GitLab
docker push registry.gitlab.opencode.de/umr/opendesk-edu-website:latest
docker push registry.gitlab.opencode.de/umr/dev-agent:latest
```

---

## 📊 **TARGET IMAGES SUMMARY**

| Image Name | Source | Registry URL | Build Method | Status |
|------------|--------|--------------|--------------|--------|
| **opendesk-edu-website** | Next.js repo | `registry.gitlab.opencode.de/umr/opendesk-edu-website:latest` | Docker | ✅ Ready |
| **dev-agent** | Operator repo | `registry.gitlab.opencode.de/umr/dev-agent:latest` | Docker/Nix | ✅ Ready |
| **sbom-generator** | Website repo | `registry.gitlab.opencode.de/umr/sbom-generator:latest` | Docker | ✅ Ready |
| **sogo5** | Nix flake | `registry.gitlab.opencode.de/umr/sogo5:latest` | Nix/Docker | ✅ Ready |
| **sogo6** | Nix flake | `registry.gitlab.opencode.de/umr/sogo6:latest` | Nix/Docker | ✅ Ready |

---

## 🔐 **GETTING YOUR PAT FROM GITLAB OPENCODE.DE**

1. **Go to:** https://gitlab.opencode.de/-/profile/personal_access_tokens
2. **Create new token:**
   - Name: `docker-push-umr`
   - Scopes: `read_registry`, `write_registry`, `api`
   - Expiration: 1 year (or no expiry)
3. **Copy the token** (you won't see it again!)
4. **Use it:**
   ```bash
   export OPENCODE_TOKEN="your-generated-token"
   ```

---

## 🏗️ **NIX DEPLOYMENTS FOR ALL CONTAINERS**

Here's the **complete Nix infrastructure** for all openDesk containers:

### **Main Flake: opendesk-nix/flake.nix**
```nix
# Build all images:
nix build .#sogo5-image
nix build .#sogo6-image
nix build .#dev-agent-image
nix build .#opendesk-edu-website-image  # If added
nix build .#sbom-generator-image       # If added
```

### **Available Packages:**
| Package | Description | Command |
|---------|-------------|---------|
| `sogo5-image` | SOGo 5 Docker image | `nix build .#sogo5-image` |
| `sogo6-image` | SOGo 6 Docker image | `nix build .#sogo6-image` |
| `dev-agent-image` | Dev Agent Kubernetes operator | `nix build .#dev-agent-image` |

---

## 📁 **FOLDER STRUCTURE**

```
opendesk-nix/
├── flake.nix                 # Main flake - builds all images
├── flake.lock               # Lock file
├── sogo/
│   └── flake.nix           # SOGo 5 & 6 images
├── dev-agent/
│   └── flake.nix           # Dev Agent image
├── website/
│   └── flake.nix           # Website image (optional)
├── sbom-generator/
│   └── flake.nix           # SBOM Generator image (optional)
├── k8s/
│   ├── sogo5/
│   │   ├── deployment.yaml  # Kubernetes deployment for SOGo 5
│   │   ├── service.yaml     # Service
│   │   └── config.yaml      # Configuration
│   ├── sogo6/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── config.yaml
│   └── dev-agent/
│       ├── deployment.yaml
│       ├── rbac.yaml
│       └── service.yaml
└── README.md
```

---

## 🚀 **PUSH TO ALL REPOSITORIES**

### **Step 1: Rename and Prepare**
```bash
# Rename folder (already done)
cd /home/weissto_local/git/opendesk_git/opendesk
mv nix opendesk-nix

# Verify contents
ls -la opendesk-nix/
```

### **Step 2: Push to GitHub**
```bash
cd opendesk-nix
git init
git add .
git commit -m "Initial commit: Nix flakes for openDesk containers"

git remote add github git@github.com:opendesk-edu/opendesk-nix.git
git push -u github main
```

### **Step 3: Push to GitLab**
```bash
git remote add gitlab git@gitlab.com:tbsweiss/opendesk-nix.git
git push -u gitlab main
```

### **Step 4: Push to opencode.de**
```bash
git remote add opencode git@gitlab.opencode.de:umr/opendesk-nix.git
git push -u opencode main
```

---

## 🐙 **create opendesk-nix REPO ON ALL PLATFORMS**

### **GitHub:**
1. Create: https://github.com/new
   - Name: `opendesk-nix`
   - Description: "Nix flakes for openDesk container images"
   - Public/Private: Public (recommended)
   - Initialize with README: No

### **GitLab:**
1. Create: https://gitlab.com/projects/new
   - Name: `opendesk-nix`
   - Description: "Nix flakes for openDesk container images"
   - Visibility: Public

### **opencode.de:**
1. Create: https://gitlab.opencode.de/projects/new
   - Path: `umr/opendesk-nix`
   - Description: "Nix flakes for openDesk container images"
   - Visibility: Public

---

## 📄 **KUBERNETES DEPLOYMENTS**

Let me create the K8s deployment files for all containers:

### **sogo5/deployment.yaml**
```yaml
# opendesk-nix/k8s/sogo5/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sogo5
  namespace: opendesk
  labels:
    app: sogo5
    version: "5.x"
    managed-by: nix
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sogo5
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: sogo5
        version: "5.x"
    spec:
      containers:
      - name: sogo
        image: registry.gitlab.opencode.de/umr/sogo5:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 20000
          name: sogod
          protocol: TCP
        env:
        - name: SOGOUserSources
          value: "({type=ldap; host=ldap.opendesk.svc; port=389; baseDN='dc=opendesk,dc=org'; bindDN='cn=admin,dc=opendesk,dc=org'; bindPassword='secret'; idFieldName='uid'; isAddressBook=YES; })"
        - name: LDAPContactInfoAttribute
          value: "mail"
        - name: TZ
          value: "Europe/Berlin"
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          tcpSocket:
            port: 20000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          tcpSocket:
            port: 20000
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: sogo-data
          mountPath: /var/lib/sogo
        - name: sogo-config
          mountPath: /etc/sogo
      volumes:
      - name: sogo-data
        persistentVolumeClaim:
          claimName: sogo5-data
      - name: sogo-config
        configMap:
          name: sogo5-config
      imagePullSecrets:
      - name: gitlab-registry-opencode
```

### **sogo5/service.yaml**
```yaml
# opendesk-nix/k8s/sogo5/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: sogo5
  namespace: opendesk
  labels:
    app: sogo5
spec:
  selector:
    app: sogo5
  ports:
  - name: sogod
    port: 20000
    targetPort: 20000
    protocol: TCP
  - name: http
    port: 80
    targetPort: 20000
    protocol: TCP
  type: ClusterIP
```

### **sogo5/config.yaml**
```yaml
# opendesk-nix/k8s/sogo5/config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: sogo5-config
  namespace: opendesk
  labels:
    app: sogo5
data:
  sogod.conf: |
    {
      SOGoProfileURL = "postgresql://sogo:sogo@postgresql.opendesk.svc/sogo";
      OCSEMailDomains = "opendesk.org";
      OCSFolderInfoURL = "postgresql://sogo:sogo@postgresql.opendesk.svc/sogo";
      OCSSessionsFolderURL = "postgresql://sogo:sogo@postgresql.opencode.svc/sogo";
    }
```

### **sogo6/deployment.yaml**
```yaml
# opendesk-nix/k8s/sogo6/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sogo6
  namespace: opendesk
  labels:
    app: sogo6
    version: "6.x"
    managed-by: nix
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sogo6
  template:
    metadata:
      labels:
        app: sogo6
        version: "6.x"
    spec:
      containers:
      - name: sogo
        image: registry.gitlab.opencode.de/umr/sogo6:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 20000
        env:
        - name: SOGOUserSources
          value: "({type=ldap; host=ldap.opendesk.svc; port=389; baseDN='dc=opendesk,dc=org'; bindDN='cn=admin,dc=opendesk,dc=org'; bindPassword='secret'; idFieldName='uid'; isAddressBook=YES; })"
        - name: SOGOMemcachedHost
          value: "memcached.opendesk.svc"
        - name: LDAPContactInfoAttribute
          value: "mail"
        resources:
          requests:
            cpu: 200m
            memory: 384Mi
          limits:
            cpu: 1000m
            memory: 1Gi
        livenessProbe:
          tcpSocket:
            port: 20000
        readinessProbe:
          tcpSocket:
            port: 20000
        volumeMounts:
        - name: sogo-data
          mountPath: /var/lib/sogo
      volumes:
      - name: sogo-data
        persistentVolumeClaim:
          claimName: sogo6-data
      imagePullSecrets:
      - name: gitlab-registry-opencode
```

### **dev-agent/deployment.yaml**
```yaml
# opendesk-nix/k8s/dev-agent/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opendesk-dev-agent
  namespace: opendesk
  labels:
    app: opendesk-dev-agent
    component: operator
    managed-by: nix
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opendesk-dev-agent
  template:
    metadata:
      labels:
        app: opendesk-dev-agent
        component: operator
    spec:
      serviceAccountName: opendesk-dev-agent
      containers:
      - name: manager
        image: registry.gitlab.opencode.de/umr/dev-agent:latest
        imagePullPolicy: Always
        args:
        - --debug
        - --disable-pi-memory
        - --watch-namespace=opendesk
        - --zap-log-level=info
        - --leader-elect=false
        env:
        - name: WATCH_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 30
        readinessProbe:
          httpGet:
            path: /readyz
            port: 8080
          initialDelaySeconds: 5
      imagePullSecrets:
      - name: gitlab-registry-opencode
```

### **dev-agent/rbac.yaml**
```yaml
# opendesk-nix/k8s/dev-agent/rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: opendesk-dev-agent
  namespace: opendesk
  labels:
    app: opendesk-dev-agent
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: opendesk-dev-agent
  labels:
    app: opendesk-dev-agent
rules:
- apiGroups: [""]
  resources: ["pods", "services", "endpoints", "persistentvolumeclaims", "events", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["opendesk-dev-agent.tobias-weiss-ai-xr.github.com"]
  resources: ["healthpolicies", "repairstrategies"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: opendesk-dev-agent
  labels:
    app: opendesk-dev-agent
subjects:
- kind: ServiceAccount
  name: opendesk-dev-agent
  namespace: opendesk
roleRef:
  kind: ClusterRole
  name: opendesk-dev-agent
  apiGroup: rbac.authorization.k8s.io
```

---

## 🔥 **COMPLETE PUSH SCRIPT FOR GITLAB REGISTRY**

Let me create the **corrected push script**:

```bash
cat > /home/weissto_local/git/opendesk_git/push-to-gitlab.sh << 'SCRIPT'
#!/bin/bash
# Push Docker Images to GitLab Container Registry (opencode.de)
# Usage: OPENCODE_TOKEN="your-pat" ./push-to-gitlab.sh
# Target: registry.gitlab.opencode.de/umr/

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REGISTRY="registry.gitlab.opencode.de/umr"

# Check for token
if [ -z "$OPENCODE_TOKEN" ]; then
    echo -e "${YELLOW}Please enter your GitLab opencode.de Personal Access Token:${NC}"
    echo "Get it from: https://gitlab.opencode.de/-/profile/personal_access_tokens"
    read -rs OPENCODE_TOKEN
    echo ""
fi

# Login
echo -e "${GREEN}=== Logging in to $REGISTRY ===${NC}"
if ! echo "$OPENCODE_TOKEN" | docker login registry.gitlab.opencode.de -u weiss --password-stdin 2>&1; then
    echo -e "${RED}Login failed!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Login successful${NC}"

# Create pull secret for K8s
echo -e "${GREEN}=== Creating Kubernetes pull secret ===${NC}"
kubectl create secret docker-registry gitlab-registry-opencode \
  --docker-server=registry.gitlab.opencode.de \
  --docker-username=weiss \
  --docker-password=$OPENCODE_TOKEN \
  --docker-email=tobias.weiss@hrz.uni-marburg.de \
  --dry-run=client -o yaml > /tmp/gitlab-registry-secret.yaml
echo -e "${GREEN}✓ Pull secret YAML created at /tmp/gitlab-registry-secret.yaml${NC}"
echo "  Apply with: kubectl apply -f /tmp/gitlab-registry-secret.yaml"

# Push Website
echo ""
echo -e "${YELLOW}--- 1/3: Website ---${NC}"
cd /home/weissto_local/git/opendesk_git/opendesk-edu-website
docker build -t $REGISTRY/opendesk-edu-website:latest .
docker push $REGISTRY/opendesk-edu-website:latest
echo -e "${GREEN}✓ Website pushed${NC}"

# Push Dev Agent
echo ""
echo -e "${YELLOW}--- 2/3: Dev Agent ---${NC}"
cd /home/weissto_local/git/opendesk_git/opendesk-dev-agent-operator
make docker-build || true
docker tag opendesk-dev-agent-operator:latest $REGISTRY/dev-agent:latest
docker push $REGISTRY/dev-agent:latest
echo -e "${GREEN}✓ Dev Agent pushed${NC}"

# Push SBOM Generator
echo ""
echo -e "${YELLOW}--- 3/3: SBOM Generator ---${NC}"
cd /home/weissto_local/git/opendesk_git/opendesk-edu-website
docker build -t $REGISTRY/sbom-generator:latest -f docker/sbom-generator/Dockerfile .
docker push $REGISTRY/sbom-generator:latest
echo -e "${GREEN}✓ SBOM Generator pushed${NC}"

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}✓ ALL IMAGES PUSHED TO GITLAB REGISTRY${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo "Images available at:"
echo "  $REGISTRY/opendesk-edu-website:latest"
echo "  $REGISTRY/dev-agent:latest"
echo "  $REGISTRY/sbom-generator:latest"
echo ""
echo "Kubernetes pull secret:"
echo "  kubectl apply -f /tmp/gitlab-registry-secret.yaml"
SCRIPT

chmod +x /home/weissto_local/git/opendesk_git/push-to-gitlab.sh
echo "✅ Push script created: push-to-gitlab.sh"
