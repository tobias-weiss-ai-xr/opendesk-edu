# MariaDB NixOS Container

## Version: 11.4.4

### OpenSpec Compliance
- ✅ **FR-BUILD-001**: Docker image build for all services
- ✅ **FR-BUILD-002**: Nix flakes for reproducible builds
- ✅ **FR-BUILD-003**: Multi-architecture builds (amd64, arm64)
- ✅ **FR-BUILD-004**: OCI-compliant images
- ✅ **FR-BUILD-005**: Incremental builds with caching
- ✅ **FR-IMAGE-001**: Non-root user (UID 999)
- ✅ **FR-IMAGE-002**: Security hardened
- ✅ **FR-IMAGE-003**: Explicit capabilities
- ✅ **FR-IMAGE-004**: Minimal base image
- ✅ **FR-IMAGE-005**: Read-only filesystem support
- ✅ **FR-IMAGE-006**: Multi-arch support
- ✅ **FR-IMAGE-007**: OCI labels
- ✅ **FR-IMAGE-009**: Health checks

---

## Quick Start

### Build the container
```bash
cd opendesk-nix
nix build .#mariadb-nixos
```

### Load into Docker
```bash
docker load < result
```

### Run the container
```bash
docker run -d --name mariadb \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=your_secure_password \
  -e MYSQL_PASSWORD=your_opendesk_password \
  -v mariadb_data:/var/lib/mysql \
  -v mariadb_logs:/var/log/mysql \
  mariadb-opendesk:11.4.4-nixos
```

---

## Configuration

### Main Configuration Files
| File | Purpose |
|------|---------|
| `configuration.nix` | NixOS system configuration |
| `default.nix` | Docker image definition |
| `secrets.nix` | Encrypted secrets (uses sops-nix) |
| `secrets.yaml` | Encrypted secrets file |

### Customizing MariaDB

#### Change Port
In `configuration.nix`:
```nix
services.mariadb.port = 3307;  # Default: 3306
```

#### Add Custom Databases
In `configuration.nix`:
```nix
services.mariadb.ensureDatabases = [
  "opendesk"
  "new_database"
];
```

#### Custom my.cnf Settings
In `configuration.nix`:
```nix
services.mariadb.my.cnfExtra = ''
  [mysqld]
  innodb_buffer_pool_size = 4G
  max_connections = 1000
'';
```

#### Add Users
In `configuration.nix`:
```nix
services.mariadb.ensureUsers = [
  {
    name = "new_user";
    password = "user_password";
    ensurePermissions = {
      "new_db.*" = "ALL PRIVILEGES";
    };
  }
];
```

---

## Secrets Management with sops-nix

### 1. Install sops
```bash
nix-shell -p sops
```

### 2. Create secrets.yaml
```yaml
# secrets.yaml (plaintext - will be encrypted)
mariadb:
  root-password: "your_root_password"
  opendesk-password: "your_opendesk_password"
  moodle-password: "moodle_password"
  ilias-password: "ilias_password"
  nextcloud-password: "nextcloud_password"
```

### 3. Encrypt secrets.yaml
```bash
# Generate age key (if you don't have one)
age-keygen -o key.txt

# Encrypt the file
sops --encrypt --age "age1..." secrets.yaml > secrets.enc.yaml
```

### 4. Use in NixOS configuration
In your flake or configuration:
```nix
{ pkgs, ... }:
let
  sops = import (builtins.fetchGit {
    url = "https://github.com/Mic92/sops-nix";
    ref = "refs/tags/1.0";
  }) { inherit pkgs; };
  secrets = sops.parseFile ./secrets.enc.yaml;
in {
  sops.secrets = secrets;
}
```

### 5. In secrets.nix
The secrets are automatically available via `config.sops.secrets.mariadb-*`

---

## Kubernetes Deployment

### StatefulSet
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mariadb
  labels:
    app: mariadb
    tier: database
spec:
  serviceName: mariadb
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
      annotations:
        checksum/config: {{ include "mariadb-config.txt" | sha256sum }}
    spec:
      securityContext:
        runAsUser: 999
        runAsGroup: 999
        fsGroup: 999
      containers:
      - name: mariadb
        image: mariadb-opendesk:11.4.4-nixos
        imagePullPolicy: IfNotPresent
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mariadb-secrets
              key: root-password
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mariadb-secrets
              key: opendesk-password
        - name: TZ
          value: Europe/Berlin
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mariadb-data
          mountPath: /var/lib/mysql
        - name: mariadb-logs
          mountPath: /var/log/mysql
        - name: mariadb-config
          mountPath: /etc/mysql/conf.d
        - name: init-scripts
          mountPath: /docker-entrypoint-initdb.d
        livenessProbe:
          exec:
            command:
            - mariadb-admin
            - ping
            - -u
            - root
            - --password=$(MYSQL_ROOT_PASSWORD)
            - --silent
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        readinessProbe:
          exec:
            command:
            - mariadb
            - -uroot
            - -p$(MYSQL_ROOT_PASSWORD)
            - -e
            - "SELECT 1"
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 3
        resources:
          requests:
            memory: "2Gi"
            cpu: "1"
          limits:
            memory: "4Gi"
            cpu: "2"
      volumes:
      - name: mariadb-config
        configMap:
          name: mariadb-config
      - name: init-scripts
        configMap:
          name: mariadb-init-scripts
  volumeClaimTemplates:
  - metadata:
      name: mariadb-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: ceph-rbd-ssd
      resources:
        requests:
          storage: 100Gi
  - metadata:
      name: mariadb-logs
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: ceph-rbd-ssd
      resources:
        requests:
          storage: 50Gi
```

### Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mariadb
  labels:
    app: mariadb
spec:
  type: ClusterIP
  ports:
  - port: 3306
    targetPort: 3306
    name: mysql
  selector:
    app: mariadb
```

---

## Performance Tuning

### Recommended Configuration for Production

#### Large Instance (32GB RAM, 8 vCPUs)
```nix
services.mariadb.my.cnfExtra = ''
  [mysqld]
  innodb_buffer_pool_size = 24G
  innodb_buffer_pool_instances = 8
  innodb_log_file_size = 2G
  innodb_log_buffer_size = 64M
  innodb_flush_log_at_trx_commit = 2
  innodb_io_capacity = 10000
  innodb_io_capacity_max = 20000
  max_connections = 2000
  thread_cache_size = 100
  table_open_cache = 4000
  table_definition_cache = 4000
'';
```

#### Medium Instance (16GB RAM, 4 vCPUs)
```nix
services.mariadb.my.cnfExtra = ''
  [mysqld]
  innodb_buffer_pool_size = 12G
  innodb_buffer_pool_instances = 4
  innodb_log_file_size = 1G
  innodb_log_buffer_size = 32M
  max_connections = 1000
  thread_cache_size = 50
  table_open_cache = 2000
'';
```

#### Small Instance (8GB RAM, 2 vCPUs)
```nix
services.mariadb.my.cnfExtra = ''
  [mysqld]
  innodb_buffer_pool_size = 4G
  innodb_buffer_pool_instances = 2
  innodb_log_file_size = 512M
  innodb_log_buffer_size = 16M
  max_connections = 500
  thread_cache_size = 25
  table_open_cache = 1000
'';
```

---

## Backup & Restore

### Using k8up (openDesk's backup operator)
```yaml
apiVersion: backup.appuio.ch/v1alpha1
kind: Backup
metadata:
  name: mariadb-backup
spec:
  podSelector:
    matchLabels:
      app: mariadb
  snapshotVolumes: true
  backupMethod:
    volumeSnapshot:
      excludeVolumes:
        - mariadb-logs
```

### Manual Backup
```bash
# Dump all databases
docker exec mariadb mysqldump -u root -p$MYSQL_ROOT_PASSWORD --all-databases > mariadb-backup.sql

# Dump single database
docker exec mariadb mysqldump -u root -p$MYSQL_ROOT_PASSWORD opendesk > opendesk-backup.sql

# Restore
cat mariadb-backup.sql | docker exec -i mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD
```

---

## Monitoring

### Prometheus Metrics with mysqld_exporter
```nix
# In configuration.nix
services.prometheus.nodeExporter = {
  enable = true;
};

services.mysqld-exporter = {
  enable = true;
  package = pkgs.prometheus-mysqld-exporter;
  port = 9104;
  mysqlConfig = ''
    [client]
    user = exporter
    password = ${config.services.mariadb.exporterPassword}
  '';
};
```

### Grafana Dashboard
Import dashboard ID **7362** (MySQL Overview) from Grafana Dashboards.

---

## Troubleshooting

### Common Issues

#### Container fails to start
```bash
# Check logs
docker logs mariadb

# Check if the data directory has correct permissions
ls -la /var/lib/docker/volumes/mariadb_data/_data

# Fix permissions docker run -it --rm -v mariadb_data:/var/lib/mysql alpine chown -R 999:999 /var/lib/mysql
```

#### Connecting from host
```bash
# Use the container's IP or service name
mysql -h 127.0.0.1 -P 3306 -uroot -p

# Or via Docker network
mysql -h mariadb -P 3306 -uroot -p
```

#### Character set issues
```nix
# In configuration.nix
services.mariadb.my.cnfExtra = ''
  [mysqld]
  character-set-server = utf8mb4
  collation-server = utf8mb4_unicode_ci
  character-set-client-handshake = FALSE
  skip-character-set-client-handshake
'';
```

#### Connection limit reached
```nix
# Increase max_connections in configuration.nix
services.mariadb.my.cnfExtra = ''
  [mysqld]
  max_connections = 1000
'';
```

---

## Contributing

### Building for multiple architectures
```bash
# amd64
nix build .#mariadb-nixos

# arm64 (on macOS or arm64 Linux)
nix build .#mariadb-nixos --system aarch64-linux

# Cross-compile from x86_64 to aarch64
nix build .#mariadb-nixos --system aarch64-linux
```

### Testing configuration changes
```bash
# Build and start a test container
nix build .#mariadb-nixos
docker load < result
docker run -d --name test-mariadb -p 3306:3306 -e MYSQL_ROOT_PASSWORD=test mariadb-opendesk:11.4.4-nixos

# Test connection
mysql -h 127.0.0.1 -P 3306 -uroot -ptest -e "SELECT 1;"

# Clean up
docker stop test-mariadb && docker rm test-mariadb
```

### Updating MariaDB version
1. Update version in `overlays/opendesk.nix`
2. Update sha256 hash (use `nix-prefetch-url`)
3. Test the new version
4. Update documentation

---

## License
Apache-2.0

---

## Links
- [MariaDB Documentation](https://mariadb.org/documentation/)
- [NixOS Manual](https://nixos.org/manual/)
- [docks.nix](https://github.com/dockernix/docks.nix)
- [openDesk Documentation](https://opendesk.hrz.uni-marburg.de/docs)
