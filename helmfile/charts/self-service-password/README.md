# LTB Self Service Password

A Helm chart for deploying [LTB Self Service Password](https://github.com/ltb-project/self-service-password) (v1.7) for LDAP-based password self-reset.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- An LDAP server (e.g., OpenLDAP)

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/self-service-password \
  --set selfServicePassword.ldap.host="openldap" \
  --set selfServicePassword.ldap.baseDn="ou=users,dc=opendesk,dc=edu" \
  --set selfServicePassword.ldap.bindDn="cn=admin,dc=opendesk,dc=edu"
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `selfServicePassword.image` | Container image | `ltbproject/self-service-password` |
| `selfServicePassword.tag` | Image tag | `latest` |
| `selfServicePassword.port` | Container port | `80` |
| `selfServicePassword.ldap.host` | LDAP server hostname (required) | `""` |
| `selfServicePassword.ldap.port` | LDAP server port | `389` |
| `selfServicePassword.ldap.baseDn` | LDAP base DN (required) | `""` |
| `selfServicePassword.ldap.bindDn` | LDAP bind DN (required) | `""` |
| `selfServicePassword.ldap.startTls` | Enable StartTLS | `false` |
| `selfServicePassword.resources.requests.cpu/memory` | Pod resource requests | `50m / 64Mi` |
| `ingress.enabled` | Enable ingress | `false` |

> **Note:** LDAP connection parameters (`host`, `baseDn`, `bindDn`) are required for the chart to function.
