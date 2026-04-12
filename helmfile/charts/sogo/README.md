# SOGo Groupware

A Helm chart for deploying [SOGo](https://www.sogo.nu/) (v5.11) groupware server providing email, calendar, and contacts with optional Keycloak OIDC/SSO support.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- PostgreSQL database server
- LDAP server for user directory
- IMAP/SMTP mail servers (e.g., Dovecot + Postfix)

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/sogo \
  --set sogo.db.host="postgresql" \
  --set sogo.db.password="<db-password>" \
  --set sogo.ldap.bindPassword="<ldap-bind-password>"
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sogo.image.repository` | Container image | `sonroyaalmerol/docker-sogo` |
| `sogo.image.tag` | Image tag | `5.11.0` |
| `sogo.replicaCount` | Number of replicas | `1` |
| `sogo.timezone` | Server timezone | `Europe/Berlin` |
| `sogo.db.host` | PostgreSQL host | `postgresql` |
| `sogo.db.user` | Database username | `sogo` |
| `sogo.ldap.host` | LDAP server hostname | `openldap` |
| `sogo.ldap.baseDN` | LDAP base DN | `ou=users,dc=opendesk,dc=edu` |
| `sogo.imap.server` | IMAP server URL | `imaps://dovecot:993` |
| `sogo.smtp.server` | SMTP server URL | `smtp://postfix:587` |
| `sogo.mailDomain` | Default mail domain | `opendesk.example.com` |
| `sogo.oidc.enabled` | Enable Keycloak OIDC/SSO | `false` |
| `sogo.persistence.size` | Persistent storage size | `1Gi` |
| `sogo.resources.requests.cpu/memory` | Pod resource requests | `250m / 512Mi` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.hosts[0].host` | Ingress hostname | `sogo.opendesk.example.com` |
