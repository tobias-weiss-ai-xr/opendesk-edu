#!/bin/bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Complete SOGo deployment with Apache proxy fix verification

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Complete SOGo Deployment with Fixes ===${NC}"
echo "Deploying SOGo with Apache DefaultRuntimeDir fix and all infrastructure"
echo ""

# Create namespace
echo -e "${YELLOW}Step 1: Creating opendesk namespace...${NC}"
kubectl create namespace opendesk --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace ready${NC}"
sleep 2

# Deploy PostgreSQL (dependency)
echo -e "${YELLOW}Step 2: Deploying PostgreSQL...${NC}"
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresql
  namespace: opendesk
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      containers:
      - name: postgresql
        image: postgres:15-alpine
        env:
        - name: POSTGRES_USER
          value: postgres
        - name: POSTGRES_PASSWORD
          value: postgres
        - name: POSTGRES_DB
          value: sogo
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-data
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: postgresql
  namespace: opendesk
spec:
  ports:
  - port: 5432
    targetPort: 5432
  selector:
    app: postgresql
EOF

echo -e "${GREEN}✓ PostgreSQL deployed${NC}"

# Deploy OpenLDAP (dependency)
echo -e "${YELLOW}Step 3: Deploying OpenLDAP...${NC}"
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openldap
  namespace: opendesk
spec:
  replicas: 1
  selector:
    matchLabels:
      app: openldap
  template:
    metadata:
      labels:
        app: openldap
    spec:
      containers:
      - name: openldap
        image: osixia/openldap:1.5.0
        env:
        - name: LDAP_DOMAIN
          value: opendesk.edu
        - name: LDAP_ORGANISATION
          value: "openDesk Edu"
        - name: LDAP_BASE_DN
          value: "dc=opendesk,dc=edu"
        - name: LDAP_ADMIN_PASSWORD
          value: admin
        ports:
        - containerPort: 389
---
apiVersion: v1
kind: Service
metadata:
  name: openldap
  namespace: opendesk
spec:
  ports:
  - port: 389
    targetPort: 389
  selector:
    app: openldap
EOF

echo -e "${GREEN}✓ OpenLDAP deployed${NC}"

# Wait for dependencies
echo -e "${YELLOW}Step 4: Waiting for dependencies to be ready...${NC}"
kubectl wait --for=condition=ready pod -n opendesk -l app=postgresql --timeout=120s
kubectl wait --for=condition=ready pod -n opendesk -l app=openldap --timeout=120s
echo -e "${GREEN}✓ Dependencies ready${NC}"

# Initialize SOGo database
echo -e "${YELLOW}Step 5: Initializing SOGo database...${NC}"
kubectl run -n opendesk db-init --rm -i --restart=Never --image=postgres:15-alpine -- \
  psql -h postgresql -U postgres -d sogo -c "
CREATE USER sogo WITH PASSWORD 'sogopassword';
GRANT ALL PRIVILEGES ON DATABASE sogo TO sogo;
"
echo -e "${GREEN}✓ Database initialized${NC}"

# Deploy SOGo with Apache fix
echo -e "${YELLOW}Step 6: Deploying SOGo with Apache DefaultRuntimeDir fix...${NC}"
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: sogo-entrypoint
  namespace: opendesk
data:
  supervisord.conf: |
    [unix_http_server]
    file=/var/run/supervisor.sock
    chmod=0700

    [supervisord]
    nodaemon=true
    logfile=/var/log/supervisord.log
    pidfile=/var/run/supervisord.pid
    childlogdir=/var/log/supervisor

    [rpcinterface:supervisor]
    supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

    [supervisorctl]
    serverurl=unix:///var/run/supervisor.sock

    [program:sogo]
    user=root
    command=/usr/local/sbin/sogod -WOWorkersCount 5 -WONoDetach YES
    autostart=true
    autorestart=true
    stopasgroup=true
    killasgroup=true
    stopwaitsecs=90
    directory=/var/lib/sogo
    stdout_logfile=/dev/stdout
    stdout_logfile_maxbytes=0
    stderr_logfile=/dev/stderr
    stderr_logfile_maxbytes=0
    environment=HOME="/var/lib/sogo"

    [program:apache]
    user=root
    command=/usr/sbin/apache2 -c "ErrorLog /dev/stdout" -c "DefaultRuntimeDir /var/run/apache2" -D FOREGROUND
    autostart=true
    autorestart=true
    stopasgroup=true
    killasgroup=true
    stopwaitsecs=90
    stdout_logfile=/dev/stdout
    stdout_logfile_maxbytes=0
    stderr_logfile=/dev/stderr
    stderr_logfile_maxbytes=0

  entrypoint.sh: |
    #!/bin/bash
    echo "Starting SOGo with supervisord (Apache proxy enabled)..."

    for dir in lib log run spool; do
      mkdir -p /var/$dir/sogo
      chmod 755 /var/$dir/sogo
    done

    mkdir -p /var/run/apache2
    chmod 755 /var/run/apache2
    
    if ! id www-data >/dev/null 2>&1; then
      groupadd -g 33 www-data
      useradd -M -u 33 -g www-data -s /usr/sbin/nologin www-data
    fi

    chmod +x /usr/local/sbin/sogod
    chmod +x /usr/local/sbin/sogo-manage

    export APACHE_RUN_USER="www-data"
    export APACHE_RUN_GROUP="www-data"
    export APACHE_RUN_DIR="/var/run/apache2"
    export APACHE_PID_FILE="/var/run/apache2/apache2.pid"
    export APACHE_LOCK_DIR="/var/lock/apache2"
    export APACHE_LOG_DIR="/var/log/apache2"

    echo "Starting supervisord..."
    exec /usr/bin/supervisord -c /opt/custom-entrypoint/supervisord.conf

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: sogo-config
  namespace: opendesk
data:
  general.yaml: |
    sogo:
      url: "http://sogo.opendesk-edu.org"
      imap:
        server: "dovecot.opendesk-edu.org:993"
        port: 993
        ssl: true
      sieve:
        server: "sieve.opendesk-edu.org:4190"
        port: 4190
        ssl: true
      smtp:
        server: "smtp.opendesk-edu.org:587"
        port: 587
      postgresql:
        host: postgresql
        port: 5432
        database: sogo
        user: sogo
        password: sogopassword
      ldap:
        host: openldap
        port: 389
        baseDN: "dc=opendesk,dc=edu"
        bindDN: "cn=admin,dc=opendesk,dc=edu"
        bindPassword: admin
---
apiVersion: v1
kind: Secret
metadata:
  name: sogo
  namespace: opendesk
type: Opaque
stringData:
  LDAP_PASSWORD: admin
  POSTGRESQL_PASSWORD: sogopassword
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sogo
  namespace: opendesk
  labels:
    app: sogo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sogo
  template:
    metadata:
      labels:
        app: sogo
    spec:
      securityContext:
        fsGroup: 1000
      containers:
      - name: sogo
        image: alinto/sogo:5.11.0
        securityContext:
          runAsUser: 0
          runAsGroup: 0
        ports:
        - containerPort: 80
        env:
        - name: SOGO_DEFAULT_ENCODING
          value: "UTF-8"
        command:
        - /bin/bash
        - /opt/custom-entrypoint/entrypoint.sh
        volumeMounts:
        - name: entrypoint
          mountPath: /opt/custom-entrypoint
        - name: sogo-data
          mountPath: /var/lib/sogo
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 20
      volumes:
      - name: entrypoint
        configMap:
          name: sogo-entrypoint
          defaultMode: 0755
      - name: sogo-data
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: sogo
  namespace: opendesk
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: sogo
EOF

echo -e "${GREEN}✓ SOGo deployment configured${NC}"

# Wait for SOGo to start
echo -e "${YELLOW}Step 7: Waiting for SOGo pod to be ready...${NC}"
sleep 10
kubectl wait --for=condition=ready pod -n opendesk -l app=sogo --timeout=300s
echo -e "${GREEN}✓ SOGo is ready${NC}"

echo ""
echo -e "${GREEN}=== Running Verification ===${NC}"

SOGO_POD=$(kubectl get pods -n opendesk -l app=sogo -o name | head -1)

echo -e "${YELLOW}Checking Apache status...${NC}"
kubectl exec -n opendesk $SOGO_POD -- supervisorctl status apache || echo "Apache status check failed"

echo ""
echo -e "${YELLOW}Checking SOGo status...${NC}"
kubectl exec -n opendesk $SOGO_POD -- supervisorctl status sogo || echo "SOGo status check failed"

echo ""
echo -e "${YELLOW}Checking port 80 bindings...${NC}"
kubectl exec -n opendesk $SOGO_POD -- netstat -tlnp | grep :80 || echo "Port 80 check failed"

echo ""
echo -e "${YELLOW}Testing HTTP access...${NC}"
kubectl exec -n opendesk $SOGO_POD -- wget -qO- http://localhost:80/ | head -20 || echo "HTTP access test failed"

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo "SOGo deployed successfully with Apache DefaultRuntimeDir fix"
echo ""
echo "Access SOGo at: kubectl port-forward -n opendesk $SOGO_POD 8080:80"