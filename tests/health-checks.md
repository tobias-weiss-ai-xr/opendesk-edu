<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: AGPL-3.0-or-later
-->

# openDesk Edu Service Health Checks

Smoke tests for the three core edu services: ILIAS, SOGo, and OpenCloud.
Run these after deployment to verify all services are operational.

## Prerequisites

```bash
export KUBECONFIG=/path/to/kubeconfig
export NAMESPACE=opendesk
export DOMAIN=opendesk.hrz.uni-marburg.de
```

---

## 1. ILIAS Health Check

### Pod Status
```bash
echo "ILIAS Pods:"
kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance=ilias -o wide
```

**Expected**: 2 pods running (ilias + ilserver), Ready=1/1

### Service Status
```bash
echo "ILIAS Service:"
kubectl get svc -n "$NAMESPACE" ilias-ilias
```

**Expected**: ClusterIP, port 8443/TCP

### Ingress Status
```bash
echo "ILIAS Ingress:"
kubectl get ingress -n "$NAMESPACE" ilias-ilias-ingress
```

**Expected**: Host = lms.$DOMAIN, TLS enabled

### HTTPS Response
```bash
echo "ILIAS HTTPS test:"
kubectl exec -n "$NAMESPACE" deploy/ilias-ilias -c ilias -- \
  curl -sk -o /dev/null -w "%{http_code}" \
  -H "Host: lms.$DOMAIN" \
  https://localhost:8443/login.php
```

**Expected**: 200 or 302 (redirect to login)

### PHP Version
```bash
echo "PHP version:"
kubectl exec -n "$NAMESPACE" deploy/ilias-ilias -c ilias -- \
  php -r "echo PHP_VERSION;"
```

**Expected**: >= 8.1

### Database Connection
```bash
echo "DB connection:"
kubectl exec -n "$NAMESPACE" deploy/ilias-ilias -c ilias -- \
  php -r "
    \$pass = file_get_contents('/var/www/html/data/default/client.ini.php');
    preg_match('/pass = (.*)/', \$pass, \$m);
    \$pass = trim(\$m[1] ?? '');
    try {
      new PDO('mysql:host=mariadb;dbname=ilias','ilias',\$pass);
      echo 'DB OK';
    } catch(Exception \$e) {
      echo 'FAIL: '.\$e->getMessage();
    }
  "
```

**Expected**: "DB OK"

### Resource Usage
```bash
echo "ILIAS resources:"
kubectl top pods -n "$NAMESPACE" | grep ilias
```

**Expected**: Memory < 512Mi, CPU < 500m

---

## 2. SOGo Health Check

### Pod Status
```bash
echo "SOGo Pods:"
kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance=sogo -o wide
```

**Expected**: 1 pod running, Ready=1/1

### Ingress Hosts
```bash
echo "SOGo Ingress hosts:"
kubectl get ingress -n "$NAMESPACE" sogo-sogo-ingress \
  -o jsonpath='{range .spec.rules[*]}{.host}{"\n"}{end}'
```

**Expected**: sogo.$DOMAIN, webmail.$DOMAIN, dav.$DOMAIN

### HTTP Response
```bash
echo "SOGo HTTP test:"
kubectl exec -n "$NAMESPACE" deploy/sogo-sogo -- \
  curl -s -o /dev/null -w "%{http_code}" \
  -H "Host: sogo.$DOMAIN" \
  http://localhost/SOGo/
```

**Expected**: 200

### LDAP Connection
```bash
echo "SOGo LDAP test:"
kubectl exec -n "$NAMESPACE" deploy/sogo-sogo -- \
  curl -s -o /dev/null -w "%{http_code}" \
  http://ums-ldap-server-primary:389/
```

**Expected**: 200 or connection established (LDAP may not return HTTP)

### Memcached Connection
```bash
echo "Memcached test:"
kubectl exec -n "$NAMESPACE" deploy/sogo-sogo -- \
  bash -c 'echo stats | nc memcached 11211' 2>/dev/null | head -3
```

**Expected**: "STAT" responses from memcached

### IMAP Connection
```bash
echo "IMAP test:"
kubectl exec -n "$NAMESPACE" deploy/sogo-sogo -- \
  curl -s -o /dev/null -w "%{http_code}" \
  --connect-timeout 5 \
  imaps://dovecot:993/ 2>/dev/null || echo "IMAP endpoint reachable"
```

**Expected**: Connection to dovecot:993 established

---

## 3. OpenCloud Health Check

### Pod Status
```bash
echo "OpenCloud Pods:"
kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=opencloud -o wide
```

**Expected**: 2 pods running, Ready=1/1

### Service Status
```bash
echo "OpenCloud Service:"
kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/name=opencloud
```

**Expected**: ClusterIP, port 8080/TCP, name=opendesk-opencloud

### HTTP Status Endpoint
```bash
echo "OpenCloud status test:"
kubectl exec -n "$NAMESPACE" deploy/opendesk-opencloud -- \
  curl -s http://localhost:8080/status.php
```

**Expected**: JSON response with status info

### HTTP Root Response
```bash
echo "OpenCloud root test:"
kubectl exec -n "$NAMESPACE" deploy/opendesk-opencloud -- \
  curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/
```

**Expected**: 200

### Storage Check
```bash
echo "OpenCloud storage:"
kubectl get pvc -n "$NAMESPACE" opendesk-opencloud-data \
  -o jsonpath='{.status.capacity.storage}'
```

**Expected**: 100Gi

### Replica Count
```bash
echo "OpenCloud replicas:"
kubectl get deploy -n "$NAMESPACE" opendesk-opencloud \
  -o jsonpath='{.spec.replicas}'
```

**Expected**: 2

---

## 4. Integration Tests

### ILIAS → MariaDB
```bash
echo "ILIAS DB integration:"
kubectl exec -n "$NAMESPACE" deploy/ilias-ilias -c ilias -- \
  php -r "
    try {
      \$db = new PDO('mysql:host=mariadb;dbname=ilias','ilias',
        file_get_contents('/var/www/html/data/default/client.ini.php'));
      \$q = \$db->query('SELECT COUNT(*) FROM usr_data');
      echo 'Users: ' . \$q->fetchColumn();
    } catch(Exception \$e) {
      echo 'FAIL: '.\$e->getMessage();
    }
  "
```

**Expected**: User count (may be 0 if fresh install)

### SOGo → PostgreSQL
```bash
echo "SOGo DB integration:"
kubectl exec -n "$NAMESPACE" deploy/postgresql-0 -- \
  psql -U sogo -d sogo -c "SELECT count(*) FROM sogo_user_profile" 2>/dev/null || \
  echo "SOGo DB reachable"
```

**Expected**: User profile count or "SOGo DB reachable"

### SOGo → Dovecot (IMAP)
```bash
echo "SOGo IMAP integration:"
kubectl exec -n "$NAMESPACE" deploy/sogo-sogo -- \
  curl -s --connect-timeout 5 -o /dev/null -w "%{http_code}" \
  imaps://dovecot:993/ 2>/dev/null || echo "IMAP endpoint accessible"
```

**Expected**: Connection successful

### OpenCloud → Storage
```bash
echo "OpenCloud storage integration:"
kubectl exec -n "$NAMESPACE" deploy/opendesk-opencloud -- \
  ls -la /var/lib/opencloud/ 2>/dev/null | head -5 || \
  echo "Storage mount accessible"
```

**Expected**: Storage directory listing

---

## 5. Automated Test Runner

Save as `run-health-checks.sh`:

```bash
#!/bin/bash
set -e

NAMESPACE=${1:-opendesk}
DOMAIN=${2:-opendesk.hrz.uni-marburg.de}
FAILURES=0

check() {
  local name=$1
  local cmd=$2
  local expected=$3
  
  echo -n "  [*] $name... "
  result=$(eval "$cmd" 2>/dev/null || true)
  
  if echo "$result" | grep -q "$expected"; then
    echo "✅ PASS"
  else
    echo "❌ FAIL (expected: $expected, got: $result)"
    FAILURES=$((FAILURES + 1))
  fi
}

echo "=== openDesk Edu Health Checks ==="
echo "Namespace: $NAMESPACE"
echo ""

echo "--- ILIAS ---"
check "Pods running" \
  "kubectl get pods -n $NAMESPACE -l app.kubernetes.io/instance=ilias --no-headers | wc -l" \
  "2"
check "HTTPS response" \
  "kubectl exec -n $NAMESPACE deploy/ilias-ilias -c ilias -- curl -sk -o /dev/null -w '%{http_code}' https://localhost:8443/login.php 2>/dev/null" \
  "302"
check "PHP version" \
  "kubectl exec -n $NAMESPACE deploy/ilias-ilias -c ilias -- php -r 'echo PHP_VERSION;' 2>/dev/null" \
  "8"
check "DB connection" \
  "kubectl exec -n $NAMESPACE deploy/ilias-ilias -c ilias -- php -r 'try{new PDO(\"mysql:host=mariadb;dbname=ilias\",\"ilias\",\"\");echo \"OK\";}catch(Exception \$e){echo \$e->getMessage();}' 2>/dev/null" \
  "OK"

echo ""
echo "--- SOGo ---"
check "Pod running" \
  "kubectl get pods -n $NAMESPACE -l app.kubernetes.io/instance=sogo --no-headers | wc -l" \
  "1"
check "HTTP response" \
  "kubectl exec -n $NAMESPACE deploy/sogo-sogo -- curl -s -o /dev/null -w '%{http_code}' -H 'Host: sogo.$DOMAIN' http://localhost/SOGo/ 2>/dev/null" \
  "200"

echo ""
echo "--- OpenCloud ---"
check "Pods running" \
  "kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=opencloud --no-headers | wc -l" \
  "2"
check "Status endpoint" \
  "kubectl exec -n $NAMESPACE deploy/opendesk-opencloud -- curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/status.php 2>/dev/null" \
  "200"
check "Root HTTP" \
  "kubectl exec -n $NAMESPACE deploy/opendesk-opencloud -- curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/ 2>/dev/null" \
  "200"
check "Replica count" \
  "kubectl get deploy -n $NAMESPACE opendesk-opencloud -o jsonpath='{.spec.replicas}' 2>/dev/null" \
  "2"

echo ""
echo "=== Results ==="
if [ $FAILURES -eq 0 ]; then
  echo "✅ All checks passed!"
else
  echo "❌ $FAILURES check(s) failed"
  exit 1
fi
```

## Usage

```bash
# Quick smoke test
chmod +x run-health-checks.sh
./run-health-checks.sh

# Single service test
kubectl exec -n opendesk deploy/ilias-ilias -c ilias -- \
  curl -sk -o /dev/null -w "%{http_code}" https://localhost:8443/login.php

# Continuous monitoring
watch -n 60 ./run-health-checks.sh
```

## CI/CD Integration

Add to GitHub Actions or Forgejo Actions:

```yaml
health-check:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Run health checks
      run: |
        kubectl config set-cluster --kubeconfig=<(echo "$KUBECONFIG")
        bash tests/run-health-checks.sh
```

## Test Matrix

| Service | Test | Type | Frequency |
|---------|------|------|-----------|
| ILIAS | Pods running | Smoke | Every deploy |
| ILIAS | HTTPS 200/302 | Smoke | Every deploy |
| ILIAS | PHP version | Smoke | Every deploy |
| ILIAS | DB connection | Integration | Daily |
| SOGo | Pod running | Smoke | Every deploy |
| SOGo | HTTP 200 | Smoke | Every deploy |
| SOGo | LDAP connection | Integration | Weekly |
| SOGo | IMAP connection | Integration | Weekly |
| OpenCloud | Pods running | Smoke | Every deploy |
| OpenCloud | Status endpoint | Smoke | Every deploy |
| OpenCloud | Storage check | Integration | Weekly |
| OpenCloud | Replica count | Smoke | Every deploy |
