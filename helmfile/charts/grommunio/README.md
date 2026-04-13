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
| `grommunio.pageTitle` | Browser tab title | `openDesk Mail` |
| `grommunio.db.host` | MariaDB host | `mariadb-headless` |
| `grommunio.db.user` | Database username | `grommunio` |
| `grommunio.cache.host` | Redis host | `redis-headless` |
| `grommunio.auth.method` | Authentication method (`oidc` or `saml`) | `oidc` |
| `grommunio.auth.oidc.enabled` | Enable OIDC/Keycloak | `true` |
| `grommunio.ldap.enabled` | Enable LDAP user provisioning | `true` |
| `grommunio.ldap.baseDN` | LDAP base DN | `ou=users,dc=opendesk,dc=edu` |
| `grommunio.mail.domain` | Mail domain | `opendesk.example.com` |
| `grommunio.mail.lmtp.port` | LMTP port for mail delivery | `24` |
| `grommunio.features.activesync` | Enable ActiveSync (mobile) | `true` |
| `grommunio.features.ews` | Enable Exchange Web Services | `true` |
| `grommunio.features.mapi` | Enable MAPI/HTTP (Outlook) | `true` |
| `grommunio.persistence.enabled` | Enable persistent storage | `true` |
| `grommunio.persistence.size` | Storage size | `50Gi` |
| `grommunio.resources.requests.cpu/memory` | Pod resource requests | `1 / 4Gi` |
| `grommunio.monitoring.enabled` | Enable Prometheus metrics | `true` |
| `grommunio.service.annotations` | Service annotations | `{}` |
| `grommunio.pdb.enabled` | Enable Pod Disruption Budget | `true` |
| `grommunio.pdb.minAvailable` | Minimum available pods during disruption | `1` |
| `grommunio.hpa.enabled` | Enable horizontal pod autoscaling | `false` |
| `grommunio.ingress.enabled` | Enable ingress | `true` |
| `grommunio.ingress.hostname` | Ingress hostname | `grommunio.opendesk.example.com` |

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

---

<!-- German -->

# Grommunio

Ein Helm-Chart zur Bereitstellung der [Grommunio](https://grommunio.com/) (v2025.01) Groupware-Lösung mit E-Mail, Kalender, Kontakten und nativer ActiveSync/EWS/MAPI-Unterstützung für Outlook und mobile Geräte.

## Voraussetzungen

- Kubernetes 1.29+
- Helm 3
- MariaDB-Datenbank (Grommunio unterstützt **kein** PostgreSQL)
- Redis als Cache
- LDAP-Server zur Benutzerbereitstellung
- IMAP/SMTP-Mailserver

## Installation des Charts

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/grommunio \
  --set grommunio.db.password="<db-passwort>" \
  --set grommunio.cache.password="<redis-passwort>" \
  --set grommunio.ldap.bindPassword="<ldap-passwort>"
```

## Deinstallation des Charts

```bash
helm uninstall my-release
```

## Konfiguration

| Parameter | Beschreibung | Standardwert |
|-----------|-------------|--------------|
| `grommunio.image.repository` | Container-Image | `grommunio/grommunio` |
| `grommunio.image.tag` | Image-Tag | `2025.01.1` |
| `grommunio.replicaCount` | Anzahl der Replikas | `1` |
| `grommunio.pageTitle` | Titel im Browser-Tab | `openDesk Mail` |
| `grommunio.db.host` | MariaDB-Host | `mariadb-headless` |
| `grommunio.db.user` | Datenbank-Benutzername | `grommunio` |
| `grommunio.cache.host` | Redis-Host | `redis-headless` |
| `grommunio.auth.method` | Authentifizierungsmethode (`oidc` oder `saml`) | `oidc` |
| `grommunio.auth.oidc.enabled` | OIDC/Keycloak aktivieren | `true` |
| `grommunio.ldap.enabled` | LDAP-Benutzerbereitstellung aktivieren | `true` |
| `grommunio.ldap.baseDN` | LDAP-Basis-DN | `ou=users,dc=opendesk,dc=edu` |
| `grommunio.mail.domain` | Mail-Domäne | `opendesk.example.com` |
| `grommunio.mail.lmtp.port` | LMTP-Port für E-Mail-Zustellung | `24` |
| `grommunio.features.activesync` | ActiveSync aktivieren (mobil) | `true` |
| `grommunio.features.ews` | Exchange Web Services aktivieren | `true` |
| `grommunio.features.mapi` | MAPI/HTTP aktivieren (Outlook) | `true` |
| `grommunio.persistence.enabled` | Persistenten Speicher aktivieren | `true` |
| `grommunio.persistence.size` | Speichergröße | `50Gi` |
| `grommunio.resources.requests.cpu/memory` | Pod-Ressourcenanforderungen | `1 / 4Gi` |
| `grommunio.monitoring.enabled` | Prometheus-Metriken aktivieren | `true` |
| `grommunio.service.annotations` | Service-Annotationen | `{}` |
| `grommunio.pdb.enabled` | Pod Disruption Budget aktivieren | `true` |
| `grommunio.pdb.minAvailable` | Mindestens verfügbare Pods bei Störungen | `1` |
| `grommunio.hpa.enabled` | Horizontale Pod-Autoskalierung aktivieren | `false` |
| `grommunio.ingress.enabled` | Ingress aktivieren | `true` |
| `grommunio.ingress.hostname` | Ingress-Hostname | `grommunio.opendesk.example.com` |

### Entwicklung/Test mit integriertem MariaDB und Redis

```bash
helm install my-release opendesk-edu/grommunio \
  --set mariadb.enabled=true \
  --set redis.enabled=true
```

### Migration von OX App Suite

```bash
helm install my-release opendesk-edu/grommunio \
  --set grommunio.migration.enabled=true \
  --set grommunio.migration.from="ox"
```
