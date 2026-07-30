---
marp: true
theme: default
paginate: true
---

## Backup B1: Sicherheit

- **Pod-Sicherheit:** Kyverno-Richtlinien 🔒
- **Netzwerk-Isolierung:** Kubernetes Network Policies 🌐
- **Container-Sicherheit:** Image-Scanning 🔍
- **Secrets-Management:**
  - sealed-secrets oder Vault 🔑
  - Niemals Secrets ins Git committen

---

## Backup B2: Hochverfügbarkeit

- **Multi-Zonen-Deployment:** Redundante Rechenzentren 🖥️
- **Datenbank-Replikation:** PostgreSQL Streaming 💾
- **Ceph-Erasure-Coding:** Fehlertoleranter Speicher 💽
- **Load Balancing:** HAProxy / MetalLB ⚖️

---

## Backup B3: Migrationsstrategien

- **E-Mail-Migration:** Mailcow → openDesk ✉️
- **Datei-Migration:** Google Drive → Nextcloud ☁️
- **Team-Chat:** M365 Teams → Element 💬
- **Werkzeuge:** rsync, rclone, IMAPSync 🔧

---

## Backup B4: SSO im Detail

- **Shibboleth-Föderations-Attribute** 🏛️
  - eduPersonPrincipalName (ePPN)
  - eduPersonAffiliation, eduPersonEntitlement
- **Gruppenbasierte Autorisierung** 👥
- **Service Provider Metadata** 📄
- **Metadata-Signierung** 🔒

---

## Backup B5: Datenbankschema

- **Keycloak-Tabellen:**
  - user_entity, credential, user_attribute, user_group_membership
- **Nextcloud-Tabellen:**
  - oc_users, oc_files, oc_calendar
- **Synapse-Tabellen:**
  - event_json_stream, state_events, users

---

## Backup B6: Fehlerbehebung häufiger Probleme

- **Dienst startet nicht:**
  - Logs prüfen: `docker logs <container>`
  - Ressourcen-Limits verifizieren
- **Authentifizierung fehlgeschlagen:**
  - Shibboleth-SP-Metadaten verifizieren
  - Attribut-Mapping in Keycloak prüfen
- **Speicherlimit erreicht:**
  - Ceph-Pool-Größe erweitern

---

## Backup B7: Performance-Tuning

- **PostgreSQL:** Connection Pooling (PgBouncer) 💾
- **Caching:** Redis für häufig abgerufene Daten 🧠
- **Webserver:** HAProxy-Worker-Prozesse optimieren 🖥️
- **Synapse:** Media-Repository-Optimierung 📦

---

## Backup B8: Entwicklung und Test

- **Lokale Entwicklung:** kind oder minikube 💻
- **CI/CD-Pipeline:** GitLab CI 🦊
- **Automatisierte Tests:** Helm Chart Linting ✅
- **Integrationstests:** Staging-Umgebung 🧪

---

## Backup B9: K8s-Deployment — Kubespray vs k3s-ansible

| **Merkmal**       | **Kubespray**              | **k3s-ansible**        |
|-------------------|----------------------------|------------------------|
| Stars / Forks     | 18,3k / 6,9k               | 3k / 1,2k              |
| Kubernetes        | Standard (kubeadm)         | K3s (leichtgewichtig)  |
| Projektart        | CNCF Offiziell (SIG)       | Community (TechnoTim)  |
| Komplexität       | Hoch (Enterprise)          | Niedrig (einfacher)    |
| Netzwerk-Plugins  | Calico, Cilium, Flannel... | Flannel (integriert)   |
| Cloud-Provider    | AWS, GCE, Azure, ...       | On-Premise Fokus       |
| Ressourcenbedarf  | Höher                      | Niedriger (ein Binary) |
| Optimal für       | Groß / Enterprise          | KMU / Edge / HomeLab   |

- **Universitätskontext:** k3s-ansible gewählt für Einfachheit & geringeren Overhead
- **Enterprise-Scale:** Kubespray für Multi-Cloud, komplexe Anforderungen

---

## Backup B10: Account Linking Extension

**Workflow für Account Verknüpfung:**

- **IAM API** liefert aktive Accounts

  ```
  GET /iam-api/v1.0/openDesk_account_depro
  ```

- **Keycloak User Lookup

  ```
  GET /admin/realms/opendesk/users?username={uid}
  ```

- **Federated Identity Link**

  ```
  POST /users/{user_id}/federated-identity/{provider}
  Provider: saml-umr (SAML Identity Provider)
  ```

- **Resultat:** Automatisches SAML SSO für verknüpfte Accounts

---

## Backup B11: Grafana Installation

```bash
# Helm Repository hinzufuegen
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts 2>/dev/null; helm repo update

# Prometheus Stack installieren
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n opendesk --create-namespace

# K8up Dashboard Configmap
kubectl create configmap opendesk-dashboards-k8up \
  --from-file=k8up-backup-overview.json=/path/to/dashboard.json \
  -n opendesk --dry-run=client -o yaml | kubectl apply -f -
```

---

## Backup B12: HRZ-Upgrade: Gelöste Probleme

- **ClamAV Image** 🦠
  - Bild temporär nicht verfügbar → Upgrade auf v1.5.2
  - Upstream-MR #1222
- **CI Pipeline Variable** 🔧
  - `PROJECT_PATH_GITLAB_CONFIG_TOOLING` leer
  - Lösung: Default-Wert in `.gitlab-ci.yml`
- **Backup-System** 🗄️
  - 7 verwaiste Backup-Ressourcen gelöscht
  - Pods blockieren: PVCs existieren nicht mehr

---
