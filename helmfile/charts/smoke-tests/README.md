# Smoke Tests

This chart deploys a CronJob that runs E2E tests against all OpenDesk Edu services every 5 minutes.

## Test Suites

| Suite | Description |
|-------|-------------|
| 1/7 DNS Resolution | All service hostnames resolve to the HAProxy ingress IP |
| 2/7 HTTP Health & Content | All services return valid HTTP status codes (200/302) |
| 3/7 SSL/TLS Certificates | Certificate validity check (if openssl available) |
| 4/7 OIDC Redirect Chain | Services authenticate via Keycloak with correct client IDs |
| 5/7 Portal Data Integrity | Expected portal entries exist in portal.json |
| 6/7 Keycloak OIDC Configuration | OIDC endpoints (auth, token, userinfo, jwks) are functional |
| 7/7 OpenCloud Configuration | OIDC authority matches Keycloak, default app is files |

## Alerting

Three PrometheusRules are deployed:
- `SmokeTestFailed` - Warning when any test run fails
- `SmokeTestRepeatedFailures` - Critical when >2 failures in 1h
- `SmokeTestNoRecentRun` - Warning when no run in 15 minutes

Alerts appear in Grafana under `opendesk-edu` namespace. The dashboard "OpenDesk Edu Service Health" provides visualization.

## Grafana Dashboard

Dashboard is auto-provisioned via ConfigMap sidecar. View it in Grafana:
1. Access Grafana (ClusterIP: opendesk/kube-prometheus-stack-grafana:80)
2. Browse → Dashboards → OpenDesk Edu Service Health
