#!/bin/bash
set -e

echo "🔧 Portal Multi-Domain OIDC Fix"
echo "================================"

EDU_DOMAIN="demo.opendesk-edu.org"
SME_DOMAIN="demo.opendesk-sme.org"

echo "Fixing portal configuration for dual-domain support..."
echo "  EDU domain: $EDU_DOMAIN"
echo "  SME domain: $SME_DOMAIN"

echo "Updating portal server configuration..."
kubectl -n opendesk-edu set env deployment/ums-portal-server \
  PORTAL_SERVER_OIDC_KEYCLOAK_URL="https://id.opendesk-edu.org/auth" \
  PORTAL_SERVER_OIDC_KEYCLOAK_URL_SME="https://id.opendesk-sme.org/auth" \
  PORTAL_SERVER_OIDC_CLIENT_ID="opendesk-portal" \
  PORTAL_SERVER_OIDC_REALM="opendesk" \
  PORTAL_SERVER_OIDC_REDIRECT_URI="https://portal.opendesk-edu.org/univention/oidc/" \
  PORTAL_SERVER_OIDC_REDIRECT_URI_SME="https://portal.opendesk-sme.org/univention/oidc/"

echo "Waiting for portal server pod to restart..."
kubectl -n opendesk-edu rollout restart deployment/ums-portal-server
kubectl -n opendesk-edu rollout status deployment/ums-portal-server --timeout=3m

echo "✅ Portal server updated"

echo "Updating portal consumer configuration..."
kubectl -n opendesk-edu set env statefulset/ums-portal-consumer \
  PORTAL_ASSETS_BASE_URL="/univention/portal" \
  PORTAL_SERVER_OIDC_ENABLED="true" \
  PORTAL_SERVER_OIDC_KEYCLOAK_URL="https://id.opendesk-edu.org/auth"

kubectl -n opendesk-edu rollout restart statefulset/ums-portal-consumer
kubectl -n opendesk-edu rollout status statefulset/ums-portal-consumer --timeout=3m

echo "✅ Portal consumer updated"

echo "Updating portal frontend nginx configuration..."
kubectl -n opendesk-edu patch configmap ums-portal-frontend-nginx --type=json -p='[
  {
    "op": "add",
    "path": "/data/nginx.conf",
    "value": "server {\n  listen 80;\n  server_name _;\n\n  location / {\n    root /var/www/html/univention/portal;\n    try_files \$uri \$uri/ /index.html;\n\n    # Inject domain-aware JS\n    sub_filter \x27</head>\x27 \x27<script src=\"/univention/portal/js/domain-aware.js\"></script></head>\x27;\n    sub_filter_once off;\n  }\n\n  location /univention/portal/js/ {\n    alias /var/www/html/domain-aware/;\n  }\n}\n"
  }
]'

kubectl -n opendesk-edu rollout restart deployment/ums-portal-frontend
kubectl -n opendesk-edu rollout status deployment/ums-portal-frontend --timeout=3m

echo "✅ Portal frontend updated"

echo ""
echo "🎉 Portal multi-domain OIDC fix complete!"
echo ""
echo "Testing instructions:"
echo "1. Test EDU domain: https://$EDU_DOMAIN/"
echo "2. Test SME domain: https://$SME_DOMAIN/"
echo "3. Verify OIDC redirects to correct Keycloak domain"
echo ""
echo "Check status: kubectl -n opendesk-edu get pods | grep portal"