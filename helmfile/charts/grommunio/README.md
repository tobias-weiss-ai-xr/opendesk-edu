# Grommunio

A Helm chart for deploying [Grommunio](https://grommunio.com/) (v2025.01) groupware solution with email, calendar, contacts, and native ActiveSync/EWS/MAPI support for Outlook and mobile integration.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- MariaDB database (Grommunio does **not** support PostgreSQL)
- Redis for caching
- LDAP server for user provisioning
- IMAP/SMTP mail servers

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/grommunio \
  --set grommunio.db.password="<db-password>" \
  --set grommunio.cache.password="<redis-password>" \
  --set grommunio.ldap.bindPassword="<ldap-password>"
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `grommunio.image.repository` | Container image | `grommunio/grommunio` |
| `grommunio.image.tag` | Image tag | `2025.01.1` |
| `grommunio.replicaCount` | Number of replicas | `1` |
| `grommunio.db.host` | MariaDB host | `mariadb-headless` |
| `grommunio.db.user` | Database username | `grommunio` |
| `grommunio.cache.host` | Redis host | `redis-headless` |
| `grommunio.auth.method` | Authentication method (`oidc` or `saml`) | `oidc` |
| `grommunio.auth.oidc.enabled` | Enable OIDC/Keycloak | `true` |
| `grommunio.ldap.enabled` | Enable LDAP user provisioning | `true` |
| `grommunio.ldap.baseDN` | LDAP base DN | `ou=users,dc=opendesk,dc=edu` |
| `grommunio.mail.domain` | Mail domain | `opendesk.example.com` |
| `grommunio.features.activesync` | Enable ActiveSync (mobile) | `true` |
| `grommunio.features.ews` | Enable Exchange Web Services | `true` |
| `grommunio.features.mapi` | Enable MAPI/HTTP (Outlook) | `true` |
| `grommunio.persistence.enabled` | Enable persistent storage | `true` |
| `grommunio.persistence.size` | Storage size | `50Gi` |
| `grommunio.resources.requests.cpu/memory` | Pod resource requests | `1 / 4Gi` |
| `grommunio.monitoring.enabled` | Enable Prometheus metrics | `true` |
| `grommunio.hpa.enabled` | Enable horizontal pod autoscaling | `false` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.hostname` | Ingress hostname | `grommunio.opendesk.example.com` |

### Dev/Test with Bundled MariaDB and Redis

```bash
helm install my-release opendesk-edu/grommunio \
  --set mariadb.enabled=true \
  --set redis.enabled=true
```

### Migration from OX App Suite

```bash
helm install my-release opendesk-edu/grommunio \
  --set grommunio.migration.enabled=true \
  --set grommunio.migration.from="ox"
```
