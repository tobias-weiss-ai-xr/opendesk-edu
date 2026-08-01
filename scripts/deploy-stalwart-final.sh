#!/bin/bash
set -e

echo "=== Deploying Stalwart Mail Server v0.0.1 ==="

cd /home/weissto_local/git/opendesk_git/opendesk-edu/helmfile/charts/stalwart

# Use the original templates
git checkout templates/ 2>/dev/null || echo "No git, using existing templates"

# Install with proper values
helm install stalwart . --namespace opendesk \
  --set stalwart.image.tag="0.0.1" \
  --set stalwart.image.registry="docker.io" \
  --set stalwart.image.repository="stalwartlabs/mail-server" \
  --set stalwart.replicaCount=1 \
  --set stalwart.storage.type="rocksdb" \
  --set stalwart.storage.dataPath="/opt/stalwart/data" \
  --set stalwart.directory.type="ldap" \
  --set stalwart.directory.ldap.host="ums-ldap.opendesk.svc.cluster.local" \
  --set stalwart.directory.ldap.port=636 \
  --set stalwart.directory.ldap.baseDn="dc=uni-marburg,dc=de" \
  --set stalwart.directory.ldap.bindDn="cn=admin,dc=uni-marburg,dc=de" \
  --set stalwart.directory.ldap.bindPassword="changeme-ldap" \
  --set stalwart.directory.ldap.tls.enabled=true \
  --set stalwart.auth.oidc.enabled=true \
  --set stalwart.auth.oidc.issuerUrl="https://id.opendesk.hrz.uni-marburg.de/realms/opendesk" \
  --set stalwart.auth.oidc.clientId="stalwart" \
  --set stalwart.auth.oidc.clientSecret="changeme-oidc" \
  --set stalwart.auth.oidc.scope="openid profile email" \
  --set stalwart.auth.fallbackAdmin.username="admin" \
  --set stalwart.auth.fallbackAdmin.passwordHash="$2y$10$YFjOqBrebL9hXgCJ1p7qVOBwlJ7JQY3i3gxJQrL5Jt6T5t8v2" \
  --set stalwart.ingress.enabled=true \
  --set stalwart.ingress.className="haproxy" \
  --set stalwart.ingress.hostname="mail.opendesk.hrz.uni-marburg.de" \
  --set stalwart.ingress.tls.enabled=true \
  --set stalwart.ingress.tls.secretName="opendesk-certificates-tls" \
  --set stalwart.persistence.enabled=true \
  --set stalwart.persistence.size=20Gi \
  --set stalwart.persistence.storageClass="ceph-rbd-ssd" \
  --set stalwart.podSecurityContext.fsGroup=0 \
  --set stalwart.podSecurityContext.runAsUser=0 \
  --set stalwart.podSecurityContext.runAsGroup=0 \
  --set stalwart.containerSecurityContext.allowPrivilegeEscalation=false \
  --set stalwart.containerSecurityContext.runAsNonRoot=false \
  --set stalwart.containerSecurityContext.readOnlyRootFilesystem=false \
  --set stalwart.resources.limits.memory="4Gi" \
  --set stalwart.resources.limits.cpu="2"

echo ""
echo "✅ Stalwart deployed!"
echo ""
echo "To check status:"
echo "  kubectl get pods -n opendesk | grep stalwart"
echo ""
echo "To view logs:"
echo "  kubectl logs stalwart-stalwart-0 -n opendesk"
