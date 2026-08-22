# Desk Test - Administrationshandbuch

> **Version:** 1.0  
> **Stand:** Juni 2026  
> **Status:** Pilotbetrieb  
> **Zielgruppe:** Systemadministratoren, HRZ-Mitarbeiter

## Einführung

Dieses Handbuch beschreibt die Verwaltung und Wartung der **Desk Test**-Umgebung (desk-test.uni-marburg.de). 

Desk Test ist eine Pilotinstallation eines **digitalen souveränen Arbeitsplatzes** auf Bare-Metal-Servern mit k3s (bleeding edge).

---

## Architektur-Übersicht

### Infrastruktur

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Desk Test - desk-test.uni-marburg.de               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                        Kubernetes (k3s - bleeding edge)              │    │
│  │                         Bare-Metal Cluster (HRZ)                    │    │
│  │                                                                       │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────┐  │    │
│  │  │  Ingress    │  │  Monitoring │  │     ArgoCD (GitOps)         │  │    │
│  │  │ (HAProxy)   │  │ (Grafana/   │  │                             │  │    │
│  │  │             │  │  Prometheus)│  │  ┌──────────┐                │  │    │
│  │  └──────┬──────┘  └──────┬──────┘  │  │ Git Repo │                │  │    │
│  │         │                 │         │  │ (GitLab) │                │  │    │
│  │         ▼                 ▼         │  │  + ───┴─── +              │  │    │
│  │  ┌─────────────────┐  ┌─────────────┐ │  │  Helmfile │              │  │    │
│  │  │   Tenants       │  │  Backups    │ │  │  Nix      │              │  │    │
│  │  │                 │  │ (k8up)      │ │  │  Manifeste│              │  │    │
│  │  │  ┌─────────┐   │  │             │ │  └──────────┘              │  │    │
│  │  │  │ opendesk│   │  └──────┬──────┘ └─────────────────────────────┘  │    │
│  │  │  └─────────┘   │         │                                        │    │
│  │  │                 │         │                                        │    │
│  │  │  ┌─────────┐   │         │                                        │    │
│  │  │  │staff    │   │         │                                        │    │
│  │  │  └─────────┘   │         │                                        │    │
│  │  │                 │         │                                        │    │
│  │  │  ┌─────────┐   │         │                                        │    │
│  │  │  │students │   │         │                                        │    │
│  │  │  └─────────┘   │         │                                        │    │
│  │  └─────────────────┘         │                                        │    │
│  │         ▲                     │                                        │    │
│  │         │                     │                                        │    │
│  └─────────┼─────────────────────┼────────────────────────────────────────┘    │
│            │                     │                                              │
│  ┌─────────▼─────────┐ ┌─────────▼─────────┐                                    │
│  │  Keycloak         │ │  BigBlueButton   │                                    │
│  │  (SSO)            │ │  (EXTERN)        │                                    │
│  │                   │ │  infra.run       │                                    │
│  │  - OIDC           │ │                  │                                    │
│  │  - SAML           │ │  - Meeting API   │                                    │
│  │  - LDAP Sync      │ └──────────────────┘                                    │
│  └───────────────────┘                                                                 │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────┐     │
│  │                           Services                                      │     │
│  │                                                                           │     │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │     │
│  │  │ openCloud│  │   SOGo   │  │ Element/ │  │  Etherpad│  │  Portal  │    │     │
│  │  │ (Nextcloud│  │ (Mail/   │  │  Matrix  │  │          │  │          │    │     │
│  │  │  19)     │  │ Cal/Kont)│  │          │  │          │  │          │    │     │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │     │
│  └─────────────────────────────────────────────────────────────────────────┘     │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Komponenten-Stack

| Komponente | Version | Zweck | Betreiber |
|------------|---------|-------|-----------|
| **k3s** | bleeding edge | Kubernetes Distribution | HRZ |
| **Ceph-RBD** | - | Persistenter Storage | HRZ |
| **ArgoCD** | - | GitOps Continuous Deployment | HRZ |
| **Helmfile** | - | Helm Chart Management | HRZ |
| **Nix** | - | Konfigurationsmanagement | HRZ |
| **HAProxy** | - | Ingress Controller / Load Balancer | HRZ |
| **Keycloak** | - | Identity & Access Management | HRZ |
| **openCloud** | Nextcloud 19 | Dateiablage | HRZ |
| **SOGo** | - | Groupware (Mail, Kalender, Kontakte) | HRZ |
| **Element/Matrix** | - | Dezentraler Messenger | HRZ |
| **Etherpad** | - | Kollaboratives Editieren | HRZ |
| **Portal** | - | Zentraler Zugang | HRZ |
| **Postfix/Dovecot** | - | Mail Server | HRZ |
| **MariaDB Galera** | 11.4.4 | Datenbank Cluster | HRZ |
| **BigBlueButton** | - | Videokonferenzen | **infra.run** (extern) |
| **Grafana** | - | Monitoring & Visualisierung | HRZ |
| **Prometheus** | - | Metriken-Sammlung | HRZ |
| **Alertmanager** | - | Alerting | HRZ |
| **k8up** | - | Backup Operator | HRZ |
| **SeaweedFS** | - | S3 Storage für Backups | HRZ |

---

## Deployment

### Übersicht

Desk Test verwendet ein **GitOps-basiertes Deployment** mit:
- **GitLab** als zentrale Code- und Konfigurationsquelle
- **ArgoCD** für kontinuierliche Synchronisation
- **Helmfile** für Helm Chart Management
- **Nix** für reproduzierbare Manifest-Generierung

### Repository-Struktur

```
opendesk-edu/
├── docs/                    # Dokumentation
│   ├── USER_GUIDE.md        # Dieses Dokument
│   └── ADMIN_GUIDE.md       # Nutzerhandbuch
│
├── nix/                     # Nix-Konfigurationen
│   ├── lib/                 # Bibliotheken
│   │   └── k8s.nix           # Kubernetes Helpers
│   └── images/              # Container Images
│
├── opendesk-nix/            # NixOS-basierte K8s Konfiguration
│   └── k8s/                 # Kubernetes Manifest-Templates
│       ├── cluster/         # Cluster-Konfiguration
│       └── tenant-namespaces/ #tenant-spezifisch
│
├── helmfile/                # Helmfile Konfigurationen
│   ├── charts/              # Custom Helm Charts
│   │   ├── opencloud-sidecar/
│   │   └── hessenbox-sidecar/
│   └── apps/                # Anwendungskonfigurationen
│       ├── edu/             # Bildungsspezifisch
│       │   ├── collab/      # Kollaborationsdienste
│       │   ├── mail/        # Mail-Services
│       │   └── portal-entries/ # Portal-Konfiguration
│       └── environments/    # Umgebungsspezifisch
│           ├── demo/
│           ├── hrz/
│           └── local/
│
├── k8s/                     # Kubernetes Manifests
│   ├── keycloak/            # Keycloak Konfiguration
│   │   └── clients/         # OIDC Clients
│   ├── tenant-backup/       # Backup Konfiguration
│   ├── tenant-mail/         # Mail-Services
│   └── xwiki/               # XWiki Konfiguration
│
└── helmfile.yaml.gotmpl     # Haupt-Helmfile
```

### Deployment-Prozess

1. **Änderungen commiten**: Konfigurationsänderungen im GitLab-Repository
2. **ArgoCD synchronisiert**: Automatische Erkennung und Anwendung der Änderungen
3. **Health Checks**: ArgoCD überprüft den Status der Deployment
4. **Rollback**: Bei Fehlern automatischer Rollback zur letzten funktionierenden Version

### ArgoCD Zugriff

- **URL**: https://argocd.desk-test.uni-marburg.de
- **Anmeldung**: LDAP/Uni-Account
- **Berechtigungen**: Nur für HRZ-Administratoren

### Helmfile Befehle

```bash
# Synchronisation aller Umgebungen
helmfile -f helmfile.yaml.gotmpl sync

# Synchronisation eines bestimmten Tenants
helmfile -f helmfile.yaml.gotmpl -l namespace=opendesk sync

# Diff anzeigen (was würde sich ändern?)
helmfile -f helmfile.yaml.gotmpl diff

# Status anzeigen
helmfile -f helmfile.yaml.gotmpl status
```

---

## Benutzerverwaltung

### Übersicht

Benutzer werden automatisch aus dem **zentralen LDAP** provisioniert und über **Keycloak** authentifiziert.

### LDAP-Synchronisation

Keycloak synchronisiert automatisch mit dem Uni-Marburg LDAP:

```bash
# Manuelle Synchronisation auslösen (falls nötig)
kubectl -n opendesk exec deployment/keycloak -- \
  /opt/keycloak/bin/kc.sh start-dev --import-realm --ldap-sync

# Synchronisationsstatus prüfen
kubectl -n opendesk logs deployment/keycloak | grep -i ldap
```

### Neue Benutzer hinzufügen

Benutzer werden automatisch hinzugefügt, wenn sie:
1. Im zentralen LDAP existieren
2. Zu einer der Pilotgruppen gehören

#### Manuelle Benutzerverwaltung

```bash
# Keycloak Admin Console
kubectl -n opendesk port-forward svc/keycloak 8080:8080
# Dann öffnen: http://localhost:8080/admin

# Benutzer über CLI hinzufügen
kubectl -n opendesk exec deployment/keycloak -- \
  /opt/keycloak/bin/kc.sh start-dev --user-add username --email user@uni-marburg.de
```

### Benutzergruppen

| Gruppe | Beschreibung | Zugriff auf |
|--------|--------------|-------------|
| `desk-test-users` | Alle Pilotnutzer | Alle Basis-Dienste |
| `desk-test-staff` | Mitarbeiter | Staff-Tenant + erweiterte Funktionen |
| `desk-test-students` | Studierende | Students-Tenant |
| `desk-test-admin` | Administratoren | Voller Zugriff |

### Berechtigungen

Berechtigungen werden über **Kubernetes RBAC** und **Keycloak Roles** gesteuert.

#### Keycloak Rollen

```yaml
# Beispiel: staff Role
apiVersion: keycloak.org/v1alpha1
kind: KeycloakRole
metadata:
  name: staff
  namespace: opendesk
spec:
  realmSelector:
    matchLabels:
      app: opendesk
  role:
    name: staff
    description: Staff User Role
    clientRoles:
      - clientId: realm-management
        roles:
          - manage-users
          - view-users
```

---

## Dienst-spezifische Verwaltung

### Keycloak (SSO)

**Namespace:** `opendesk`

#### Konfiguration

```bash
# Keycloak Configuration
kubectl -n opendesk get secret keycloak-config -o yaml

# Admin Passwort erhalten
kubectl -n opendesk get secret keycloak-db -o jsonpath='{.data.postgres-password}' | base64 -d

# Realm exportieren
kubectl -n opendesk exec deployment/keycloak -- \
  /opt/keycloak/bin/kc.sh start-dev --export-realm opendesk > opendesk-realm.json
```

#### OIDC Clients verwalten

Die OIDC Client-Konfigurationen finden sich in `k8s/keycloak/clients/`.

Beispiel: neuen Client hinzufügen

```yaml
# k8s/keycloak/clients/newer-service.yaml
apiVersion: keycloak.org/v1alpha1
kind: KeycloakClient
metadata:
  name: neuer-service
  namespace: opendesk
spec:
  realmSelector:
    matchLabels:
      app: opendesk
  client:
    clientId: neuer-service
    protocol: openid-connect
    standardFlowEnabled: true
    redirectUris:
      - "https://neuer-service.desk-test.uni-marburg.de/*"
    webOrigins:
      - "https://neuer-service.desk-test.uni-marburg.de"
```

#### Shibboleth/SAML Integration

```bash
# Shibboleth Identity Provider in Keycloak
kubectl -n opendesk get secret keycloak-shib-config -o yaml

# Metadaten prüfen
curl https://idp.uni-marburg.de/idp/shibboleth
```

### openCloud (Nextcloud)

**Namespace:** `opendesk`

#### Grundlegende Verwaltung

```bash
# Deployment Status
kubectl -n opendesk get pods -l app=opencloud

# Logs anzeigen
kubectl -n opendesk logs deployment/opencloud

# Konfiguration bearbeiten
kubectl -n opendesk edit configmap opencloud-config
```

#### Storage

```bash
# PVCs anzeigen
kubectl -n opendesk get pvc

# StorageClass
kubectl get storageclass
```

#### Datenbank

openCloud verwendet MariaDB Galera:

```bash
# DB Verbindungstest
kubectl -n opendesk exec deployment/opencloud -- \
  mysql -h galera.opendesk.svc.cluster.local -u nextcloud -p nextcloud
```

#### Cron Jobs

```bash
# Manuell ausführen
kubectl -n opendesk exec deployment/opencloud -- \
  su -s /bin/sh www-data -c "php /var/www/html/occ system:cron"
```

### SOGo (Groupware)

**Namespace:** `tenant-mail` (staffstudents)

#### Verwaltung

```bash
# Pod Status
kubectl -n opendesk-staff get pods -l app=sogo

# konservativen anzeigen
kubectl -n opendesk-staff logs deployment/sogo

# Konfiguration
kubectl -n opendesk-staff get configmap sogo-config -o yaml
```

#### Datenbank

```bash
# SOGo verwendet PostgreSQL
kubectl -n opendesk-staff exec deployment/sogo-db -- psql -U sogo sogo
```

### Tenant-Verwaltung

Desk Test verwendet ein **Multi-Tenant-Modell**:

| Tenant | Namespace | Zielgruppe | Speicherclass |
|--------|-----------|------------|---------------|
| `opendesk` | opendesk | Gemeinsam | ceph-rbd |
| `opendesk-staff` | opendesk-staff | Mitarbeiter | ceph-rbd-staff |
| `opendesk-students` | opendesk-students | Studierende | ceph-rbd-staff |

#### Tenant erstellen

```bash
# Namespace erstellen
kubectl create namespace opendesk-neu

# StorageClass zuweisen
kubectl label namespace opendesk-neu storageclass=ceph-rbd

# Netzwerkrichtlinien
kubectl apply -f k8s/tenant-namespaces/
```

#### Tenant-spezifische Konfiguration

Jeder Tenant hat:
- Eigene **Kubernetes Namespaces**
- Eigene **Storage Classes**
- Eigene **Backup Schedules**
- Eigene **IOC Clients**

---

## Monitoring

### Übersicht

Monitoring erfolgt über **Grafana + Prometheus + Alertmanager**.

- **Grafana**: https://grafana.desk-test.uni-marburg.de
- **Prometheus**: https://prometheus.desk-test.uni-marburg.de
- **Alertmanager**: https://alertmanager.desk-test.uni-marburg.de

### Wichtige Dashboards

| Dashboard | URL | Beschreibung |
|-----------|-----|--------------|
| Cluster Overview | /d/cluster-overview | Gesamtstatus aller Nodes |
| Pod Monitoring | /d/k8s-pods | Ressourcenverbrauch der Pods |
| Storage | /d/storage | Speichernutzung |
| Network | /d/network | Netzwerkverkehr |
| Desk Test Services | /d/desk-test | Dienst-spezifische Metriken |

### Alerts

Wichtige Alerts:

| Alert-Name | Schweregrad | Bedingung |
|-----------|------------|-----------|
| NodeDown | Critical | Node ist nicht erreichbar |
| HighCPUUsage | Warning | CPU > 80% für 15 Minuten |
| HighMemoryUsage | Warning | Memory > 85% |
| LowDiskSpace | Critical | Storage < 10% frei |
| PodCrashLoop | Critical | Pod startet nicht |
| ServiceDown | Critical | Service ist nicht verfügbar |

### Eigenes Dashboard erstellen

```json
{
  "title": "Desk Test - Custom Dashboard",
  "panels": [
    {
      "title": "CPU Usage",
      "type": "graph",
      "targets": [
        {
          "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=~\"opendesk.*\"}[5m])) by (namespace)"
        }
      ]
    }
  ]
}
```

---

## Backup und Disaster Recovery

### Übersicht

Backups werden mit **k8up** (Backup Operator) durchgeführt:
- **Ziel:** SeaweedFS S3 Storage
- **Häufigkeit:** Täglich
- **Retention:** 30 Tage

### Backup Schedules

```bash
# Alle Backup Schedules anzeigen
kubectl -n opendesk get backup schedule -A

# Beispiel: opendesk-staff Schedule
kubectl -n opendesk get scheduledbackup opendesk-staff-schedule -o yaml
```

**Aktuelle Schedules:**

| Namespace | Schedule | Zeit | Retention |
|-----------|----------|------|-----------|
| opendesk | opendesk-schedule | 00:00 UTC | 30 Tage |
| opendesk-staff | opendesk-staff-schedule | 00:12 UTC | 30 Tage |
| opendesk-students | opendesk-students-schedule | 00:24 UTC | 30 Tage |

### Manuelles Backup

```bash
# Sofortiges Backup auslösen
kubectl -n opendesk create -f - <<EOF
apiVersion: backup.appuio.ch/v1alpha1
kind: Backup
metadata:
  name: manual-backup-$(date +%Y%m%d-%H%M%S)
  namespace: opendesk
spec:
  snapshotVolumes: true
  podSelector:
    matchLabels:
      app.kubernetes.io/instance: opendesk
  backend:
    s3:
      endpoint: seaweedfs.hrz.uni-marburg.de
      bucket: desk-test-backups
EOF
```

### Backup prüfen

```bash
# Backup-Status anzeigen
kubectl -n opendesk get backup

# Details eines Backups
kubectl -n opendesk describe backup manual-backup-20260620-120000

# Backup-Logs
kubectl -n opendesk logs job/manual-backup-20260620-120000
```

###Restore aus Backup

```bash
# Restore ausführen
kubectl -n opendesk create -f - <<EOF
apiVersion: backup.appuio.ch/v1alpha1
kind: Restore
metadata:
  name: restore-from-20260620
  namespace: opendesk
spec:
  restoreMethod:
    folderRestore:
      claimName: data-opendesk-opencloud-0
      targetVolumeName: nextcloud-data
  snapshot: manual-backup-20260620-120000
  podSelector:
    matchLabels:
      app.kubernetes.io/instance: opendesk
EOF
```

### Disaster Recovery

**DR-Instanz beim BMI:**
- Automatisierte Synchronisation mit Hauptcluster
- RTO (Recovery Time Objective): <4 Stunden
- RPO (Recovery Point Objective): <1 Stunde

```bash
# DR-Test durchführen
kubectl apply -f k8s/disaster-recovery/dr-test.yaml

# Failover auslösen (nur im Notfall!)
kubectl apply -f k8s/disaster-recovery/failover.yaml
```

---

## Wartung

### Regelmäßige Wartung

| Aufgabe | Häufigkeit | Verantwortlich | Skript |
|---------|------------|----------------|--------|
| k3s Upgrade | Monatlich | HRZ Sysadmins | `nix/scripts/upgrade-k3s.sh` |
| Sicherheitsupdates | Wöchentlich | HRZ Sysadmins | `nix/scripts/security-patch.sh` |
| Zertifikatsrotation | Alle 90 Tage | HRZ Sysadmins | `k8s/certificates/rotate.sh` |
| Backup-Test | Monatlich | HRZ Sysadmins | `k8s/backup/test-restore.sh` |
| Monitoring-Check | Täglich | Grafana | Automatisch |
| Log-Rotation | Täglich | Promtail | Automatisch |

### Wartungsfenster

| Wann | Dauer | Betroffene Dienste | Vorlauf |
|------|-------|-------------------|---------|
| Patch-Tuesday (alle 4 Wochen) | 2-4 Stunden | Alle Dienste | 1 Woche |
| Lehrveranstaltungsfreie Zeit | 1 Tag | Alle Dienste | 2 Wochen |
| Notfall-Wartung | Variabel | Je nach Problem | 24 Stunden |

### Wartungsankündigung

```bash
# Wartungsankündigung an alle Nutzer senden
kubectl -n opendesk exec deployment/portal -- \
  /usr/bin/send-maintenance-notification \
    --start "2026-07-01T02:00:00Z" \
    --end "2026-07-01T06:00:00Z" \
    --message "Geplante Wartung: k3s Upgrade"
```

---

## Fehlerbehebung

### Häufige Probleme

#### k3s Cluster Probleme

| Symptom | Ursache | Lösung |
|---------|---------|--------|
| Nodes nicht erreichbar | k3s Server ausgefallen | `systemctl restart k3s` |
| Pods bleiben im Pending | Keine Ressourcen | `kubectl describe pod <pod>` |
| Netzwerkprobleme | Flannel/CNI Issue | `systemctl restart k3s` |
| Storage Probleme | Ceph nicht verfügbar | `ceph -s` |

```bash
# k3s Status
systemctl status k3s

# k3s Logs
journalctl -u k3s -f

# Node Status prüfen
kubectl get nodes -o wide

# Node Details
kubectl describe node <node-name>
```

#### Anwendungsspezifische Probleme

**openCloud:**

```bash
# Nextcloud Status
kubectl -n opendesk exec deployment/opencloud -- \
  su -s /bin/sh www-data -c "php /var/www/html/occ status"

# Datenbank prüfen
kubectl -n opendesk exec deployment/opencloud -- \
  su -s /bin/sh www-data -c "php /var/www/html/occ db:check"

# Cache leeren
kubectl -n opendesk exec deployment/opencloud -- \
  su -s /bin/sh www-data -c "php /var/www/html/occ files:cleanup"
```

**SOGo:**

```bash
# SOGo Status
kubectl -n opendesk-staff exec deployment/sogo -- sogo-tool check

# Datenbank prüfen
kubectl -n opendesk-staff exec deployment/sogo-db -- \
  psql -U sogo -c "SELECT count(*) FROM sogo_users;"
```

**Keycloak:**

```bash
# Keycloak Status
kubectl -n opendesk exec deployment/keycloak -- \
  /opt/keycloak/bin/kc.sh start-dev --version

# Realm prüfen
kubectl -n opendesk exec deployment/keycloak -- \
  /opt/keycloak/bin/kc.sh start-dev --list-realms

# Benutzer prüfen
kubectl -n opendesk exec deployment/keycloak -- \
  /opt/keycloak/bin/kc.sh start-dev --list-users realm=opendesk
```

### Logs analysieren

```bash
# Alle Pod Logs
kubectl get pods -A -o name | xargs -I {} kubectl logs {} --tail=100

# Filter für Fehler
kubectl get pods -A -o name | xargs -I {} kubectl logs {} | grep -i error

# Speichern aller Logs
mkdir -p /tmp/desk-test-logs
kubectl get pods -A -o name | xargs -I {} sh -c 'kubectl logs {} > /tmp/desk-test-logs/{}.log 2>&1'
```

### Diagnose-Tools

```bash
# Netstat in einem Pod
kubectl exec -it <pod> -- netstat -tuln

# DNS Test
kubectl exec -it <pod> -- nslookup google.com

# Verbindungstest
kubectl exec -it <pod> -- curl -v https://desk-test.uni-marburg.de

# TCP Dump
kubectl exec -it <pod> -- tcpdump -i eth0 -n port 80
```

---

## Sicherheit

### Sicherheitskonzept

Siehe zentrales Sicherheitskonzept des HRZ:
https://share.uni-marburg.de/de/hrz/hrz-intern/organisation/it-sicherheit/it-sicherheitskonzepte/

### Wichtige Sicherheitsmaßnahmen

1. **Netzwerksegmentierung**: Jeder Tenant hat eigenen Namespace
2. **TLS-Verschlüsselung**: Alle externen Zugriffe sind verschlüsselt
3. **Zertifikatsrotation**: Automatisch alle 90 Tage
4. **Firewall-Regeln**: AUF NUR NOTWENDIGe PORTS
5. **RBAC**: Feingranulare Berechtigungen
6. **Pod Security Policies**: Keine Root-Container
7. **Image Scanning**: Alle Images werden gescannt

### Sicherheitsupdates

```bash
# Alle Container Images prüfen
kubectl get pods -A -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"
"}{end}' | sort | uniq

# Für veraltete Images prüfen
kubectl get pods -A -o json | jq -r '.items[].spec.containers[].image' | tr -d ':' | sort | uniq
```

### Zertifikate verwalten

```bash
# Zertifikate prüfen
kubectl get cert -A

# Ablaufdatum prüfen
kubectl get cert -A -o json | jq -r '.items[] | .metadata.name + ": " + .status.notAfter'

# Zertifikat erneuern
kubectl apply -f k8s/certificates/renew.yaml
```

---

## Performance-Optimierung

### Ressourcen-Monitoring

```bash
# CPU Usage top 10
kubectl top pods -A --sort-by=cpu | head -10

# Memory Usage top 10
kubectl top pods -A --sort-by=memory | head -10

# Storage Usage
kubectl get pvc -A -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.spec.storage,USED:.status.capacity.storage"
```

### Skalierung

```bash
# Horizontal Pod Autoscaler
kubectl get hpa -A

# Manuell skalieren
kubectl -n opendesk scale deployment/opencloud --replicas=3

# Ressourcenlimits anpassen
kubectl -n opendesk edit deployment/opencloud
```

---

## Nutzer-Support

### Häufige Nutzer-Probleme

| Problem | Lösung |
|---------|--------|
| Anmeldung fehlgeschlagen | LDAP-Sync prüfen, Benutzer berechtigen |
| Passwort funktioniert nicht | Uni-Account Passwort ändern |
| Dateien nicht sichtbar | Berechtigungen prüfen |
| E-Mails nicht empfangbar | SOGo Pods prüfen, Logs analysieren |
| „Zugriff verweigert“ | RBAC-Rollen prüfen |
| Langsame Performance | Ressourcen prüfen, skalieren |

### Support-Workflows

1. **Ticket erstellen**: Nutzer kontaktiert Helpdesk
2. **Priorisierung**: P1-P4 nach Dringlichkeit
3. **Diagnose**: Logs und Status prüfen
4. **Lösung**: Problem beheben oder Workaround bereitstellen
5. **Dokumentation**: Lösung in Wissensdatenbank eintragen
6. **Follow-up**: Nutzer kontaktieren und Feedback einholen

---

## Dokumentation pflegen

### Handbücher aktualisieren

```bash
# USER_GUIDE.md aktualisieren
vim docs/USER_GUIDE.md

# ADMIN_GUIDE.md aktualisieren
vim docs/ADMIN_GUIDE.md

# Änderungen commiten
cd /path/to/opendesk-edu
Git commit -am "docs: Aktualisiere USER_GUIDE und ADMIN_GUIDE"
git push
```

### Changelog

Führen Sie ein Changelog für wichtige Änderungen:

```markdown
## CHANGELOG

### 1.0.0 (Juni 2026)
- Erste Version des ADMIN_GUIDE
- Grundlegende Dokumentation aller Dienste

### 1.0.1 (Juli 2026)
- Fehlende Befehle ergänzt
- Troubleshooting-Abschnitt erweitert
```

---

## Anhang

### Nützliche Links

| Link | Beschreibung |
|------|--------------|
| [Desk Test Portal](https://desk-test.uni-marburg.de) | Zentraler Zugang |
| [GitLab Repository](https://gitlab.hrz.uni-marburg.de/hrz/kubernetes/opendesk-edu) | Source Code & Config |
| [GitHub Mirror](https://github.com/opendesk-edu/opendesk-edu) | Spiegel |
| [ArgoCD](https://argocd.desk-test.uni-marburg.de) | GitOps Dashboard |
| [Grafana](https://grafana.desk-test.uni-marburg.de) | Monitoring |
| [Prometheus](https://prometheus.desk-test.uni-marburg.de) | Metriken |

### Kontakte

| Rolle | Name | E-Mail | Telefon |
|-------|------|--------|---------|
| Service Owner | Kerstin Runzheimer | kerstin.runzheimer@uni-marburg.de | - |
| Service Manager | Tobias Weiß | tobias.weiss@uni-marburg.de | - |
| HRZ Helpdesk | - | helpdesk@hrz.uni-marburg.de | +49 6421 28-28282 |
| Matrix Chat | - | #desk-test:matrix.hrz.uni-marburg.de | - |

### Glückwunsch! 🎉

Unterstützt durch openDesk Edu Community

*Dieses Handbuch wird regelmäßig aktualisiert. Letzte Änderung: Juni 2026*
