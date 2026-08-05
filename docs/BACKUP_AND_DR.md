# Backup and Disaster Recovery

## Data That Needs Backup

### Tier 1: Critical (restore within 1h)

| Data | Location | Backup Method | Frequency |
|------|----------|---------------|-----------|
| Portal data (entries, icons, JSON) | MinIO `ums/portal-data/` | MinIO `mc mirror` to backup MinIO | Every 6h |
| LDAP entries | `ums-ldap-server-primary` | `ldapsearch -LLL` dump | Daily |
| Keycloak realm config | `id.opendesk.hrz.uni-marburg.de` | Keycloak export via admin API | Weekly |
| Helm release state | k3s cluster | `helm get values` for each release | After changes |

### Tier 2: Important (restore within 24h)

| Data | Location | Backup Method | Frequency |
|------|----------|---------------|-----------|
| MinIO user data (files) | MinIO `ums/user-data/` | MinIO bucket replication | Daily |
| PVCs (OpenCloud, JupyterHub, etc.) | k3s PVs | Velero or `kasten k10` | Daily |

## Backup Scripts

### 1. Portal Data Backup

```bash
# From any pod with MinIO access (e.g., ums-portal-server)
kubectl exec -n opendesk ums-portal-server-0 -- python3 << 'EOF'
import boto3, os

s3 = boto3.client('s3',
    endpoint_url='https://objectstore.opendesk.hrz.uni-marburg.de',
    aws_access_key_id=os.environ['OBJECT_STORAGE_ACCESS_KEY_ID'],
    aws_secret_access_key=os.environ['OBJECT_STORAGE_SECRET_ACCESS_KEY'],
    config=botocore.config.Config(signature_version='s3v4'),
    verify=False)

# Sync portal data to backup MinIO
BACKUP_ENDPOINT = 'https://minio-backup.opendesk.svc.cluster.local:9000'
BACKUP_ACCESS = ''
BACKUP_SECRET = ''

backup = boto3.client('s3',
    endpoint_url=BACKUP_ENDPOINT,
    aws_access_key_id=BACKUP_ACCESS,
    aws_secret_access_key=BACKUP_SECRET,
    verify=False)

# List objects and copy
objects = s3.list_objects(Bucket='ums', Prefix='portal-data/')
for obj in objects.get('Contents', []):
    # Copy to backup
    copy_source = {'Bucket': 'ums', 'Key': obj['Key']}
    backup.copy_object(Bucket='ums-backup', Key=obj['Key'], CopySource=copy_source)
    print(f'Backed up {obj["Key"]}')
EOF
```

### 2. LDAP Backup

```bash
# Dump all portal entries
LDAP_PASS=$(kubectl get secret -n opendesk ums-ldap-server-admin -o jsonpath='{.data.password}' | base64 -d)
POD="ums-ldap-server-primary-0"

kubectl exec -n opendesk $POD -c main -- ldapsearch -x -LLL \
  -H ldap://localhost:389 \
  -D "cn=admin,dc=swp-ldap,dc=internal" -w "$LDAP_PASS" \
  -b "dc=swp-ldap,dc=internal" > /tmp/ldap-backup-$(date +%Y%m%d-%H%M%S).ldif
```

### 3. Keycloak Export

```bash
# Export realm via Keycloak admin API
KCADMIN_PASS=$(kubectl get secret -n opendesk opendesk-keycloak-bootstrap-admin-creds -o jsonpath='{.data.admin\.yaml}' | base64 -d | grep password | awk '{print $2}')
TOKEN=$(curl -sk -X POST "https://id.opendesk.hrz.uni-marburg.de/realms/master/protocol/openid-connect/token" \
  -d "client_id=admin-cli" -d "username=kcadmin" -d "password=$KCADMIN_PASS" -d "grant_type=password" | \
  python3 -c "import json,sys; print(json.load(sys.stdin)['access_token'])")

curl -sk "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk" \
  -H "Authorization: Bearer $TOKEN" > /tmp/keycloak-realm-opendesk.json
```

## Disaster Recovery Procedures

### A. Portal Unavailable (502/503)

**Symptoms:**
- Portal returns 502, 503, or 504
- Portal OIDC (`/univention/oidc/`) returns 502

**Steps:**
1. Check portal pods: `kubectl get pods -n opendesk -l app.kubernetes.io/name=portal-server`
2. Check Keycloak reachability from portal pod:
   ```
   kubectl exec -n opendesk ums-portal-server-0 -- python3 -c "
   import urllib.request; 
   r = urllib.request.urlopen('https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/.well-known/openid-configuration', timeout=5);
   print(f'Keycloak: HTTP {r.status}')"
   ```
3. Check objectstore reachability:
   ```
   kubectl exec -n opendesk ums-portal-server-0 -- python3 -c "
   import urllib.request;
   r = urllib.request.urlopen('https://objectstore.opendesk.hrz.uni-marburg.de/minio/health/live', timeout=5);
   print(f'MinIO: HTTP {r.status}')"
   ```
4. Restart portal consumer if data is stale:
   `kubectl delete pod -n opendesk ums-portal-consumer-0`
5. Restart portal server as last resort:
   `kubectl rollout restart -n opendesk deployment/ums-portal-server`

### B. DNS Resolution Fails for `*.opendesk.hrz.uni-marburg.de`

**Symptoms:**
- `nslookup ai.opendesk.hrz.uni-marburg.de` returns NXDOMAIN or SERVFAIL
- Services unreachable from browser

**Steps:**
1. Check CoreDNS is running: `kubectl get pods -n kube-system -l k8s-app=kube-dns`
2. Check custom configmap: `kubectl get configmap -n kube-system coredns-custom`
3. Verify dev-dns .server block is loaded:
   ```
   kubectl logs -n kube-system -l k8s-app=kube-dns | grep "opendesk.hrz"
   ```
   Should show: `opendesk.hrz.uni-marburg.de.:53`
4. Test resolution from inside cluster:
   `kubectl run test --image=busybox --rm -it -- nslookup r.opendesk.hrz.uni-marburg.de 172.17.128.10`
5. If CoreDNS is broken, restart it:
   `kubectl rollout restart -n kube-system deployment/coredns`

### C. Portal Icons Missing

**Symptoms:**
- Portal tiles show generic placeholder icons
- SVG files are 20 bytes instead of 300-700 bytes

**Steps:**
1. This is caused by `::` (double colon) in LDAP base64 attribute
2. Fix: update LDAP entry with single colon (`:`) format:
   ```
   echo "dn: cn=rstudio,cn=entry,cn=portals,cn=univention,dc=swp-ldap,dc=internal
   changetype: modify
   replace: univentionNewPortalEntryIcon
   univentionNewPortalEntryIcon: $(echo '<svg>...</svg>' | base64 -w0)" | \
   kubectl exec -i -n opendesk ums-ldap-server-primary-0 -c main -- ldapmodify -x \
     -H ldap://localhost:389 -D "cn=admin,dc=swp-ldap,dc=internal" -w "$LDAP_PASS"
   ```
3. Restart portal consumer:
   `kubectl delete pod -n opendesk ums-portal-consumer-0`
4. Restart portal frontend:
   `kubectl rollout restart -n opendesk deployment/ums-portal-frontend`

### D. Full Cluster Recovery

**Scenario:** Complete k3s cluster failure or data loss

**Prerequisites:**
- Helm chart files in `/root/opendesk-edu/helmfile/charts/`
- LDAP backup (`ldap-backup-*.ldif`)
- Keycloak realm export (`keycloak-realm-opendesk.json`)
- MinIO portal data backup

**Steps:**
1. Install k3s: `curl -sfL https://get.k3s.io | sh -`
2. Restore Helm charts:
   ```
   cd /root/opendesk-edu/helmfile/charts
   for chart in *; do
     helm upgrade --install $chart ./$chart -n opendesk
   done
   ```
3. Restore LDAP from backup:
   `kubectl exec -i -n opendesk ums-ldap-server-primary-0 -c main -- ldapadd -x -H ldap://localhost:389 -D "cn=admin,dc=swp-ldap,dc=internal" -w "$PASS" -f /tmp/ldap-backup-*.ldif`
4. Restore Keycloak realm via admin API
5. Re-run E2E tests to verify:
   `kubectl create job -n opendesk-edu --from=cronjob/smoke-tests smoke-test-manual`
6. Check dashboard in Grafana

### E. E2E Test Failures

**Symptoms:**
- SmokeTestFailed alert fires
- Grafana dashboard shows red

**Steps:**
1. Check logs: `kubectl logs -n opendesk-edu -l job-name=smoke-test-$(date +%H%M)`
2. Identify which service(s) failed from the output
3. For HTTP failures: check the service pod and ingress
4. For DNS failures: check CoreDNS config
5. For OIDC failures: check Keycloak client config
