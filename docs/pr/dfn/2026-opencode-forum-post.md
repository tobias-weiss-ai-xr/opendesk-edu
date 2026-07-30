---
SPDX-License-Identifier: AGPL-3.0
---

# 🎓 openDesk Edu: Offene Plattform für Hochschulen – Jetzt mitmachen!

**Erstellt von:** @weissto (Tobias Weiß, HRZ Marburg)  
**Datum:** Juli 2026  
**Tags:** #opendesk #bildung #kubernetes #open-source #hochschulen #dfn

---

## 👋 Hallo Community!

Wir von der **Philipps-Universität Marburg** (HRZ) haben in den letzten Monaten **openDesk Edu** zu einer stabilen Plattform für den Betrieb von Bildungsdiensten an Hochschulen weiterentwickelt – und suchen jetzt **Mitmachende für Testing, Feedback und Mitentwicklung**!

---

## 🚀 Was ist openDesk Edu?

openDesk Edu ist eine **Kubernetes-native Plattform**, die **28 Bildungsdienste** unter einer gemeinsamen Architektur vereint:

| **Kategorie** | **Dienste** | **Status** |
|--------------|------------|------------|
| **Lernmanagement** | Moodle, ILIAS | ✅ Produktiv |
| **Zusammenarbeit** | Nextcloud, Etherpad, Draw.io, Excalidraw | ✅ Produktiv |
| **Groupware** | SOGo, OpenXchange | ✅ Produktiv |
| **Wiki** | BookStack | ✅ Produktiv |
| **Projektmanagement** | Planka (Kanban), JupyterHub | ✅ Produktiv |
| **Infrastruktur** | Keycloak (SSO), MinIO, Ceph CSI, PostgreSQL, Redis | ✅ Produktiv |

**Technische Basis:**
- **Kubernetes (K3s)** auf 9 Nodes (Debian 12)
- **Helm/Helmfile** für Deployments
- **Ceph CSI** für skalierbaren Speicher (RBD für DBs, CephFS für Dateien)
- **k8up + Restic** für automatisierte Backups
- **DFN-AAI-Integration** für Single Sign-On

---

## 🎯 Warum gibt es openDesk Edu?

An vielen Hochschulen sieht die Realität so aus:
- **Jede Einrichtung betreibt Moodle, Nextcloud oder ILIAS einzeln** → Doppelte Arbeit, Inkompatibilitäten
- **Kein standardisierter Betrieb** → Hohe Wartungskosten, Sicherheitslücken
- **Keine gemeinsame Basis** → Jeder erfindet das Rad neu

**Unsere Lösung:**
✅ **Vorgefertigte Helm-Charts** (Bitnami-frei!) für alle Dienste
✅ **Einheitliches SSO** (Keycloak mit SAML 2.0 + OIDC + DFN-AAI)
✅ **Automatisierte Backups** (k8up + Restic auf Ceph/S3)
✅ **Dokumentation & Best Practices** aus dem echten Betrieb

---

## 📊 Aktueller Stand (Juli 2026)

| **Metrik** | **Wert** |
|------------|---------|
| **Produktiv-Installationen** | 3 (u. a. HRZ Marburg) |
| **Hochschulen im Testbetrieb** | 12 |
| **Aktive Nutzer** | 5.000+ |
| **Deployed Dienste** | 28 |
| **Cluster-Knoten** | 9 (K3s) |
| **Backup-Größe** | ~2 TB |
| **Sicherheits-Assessment** | ✅ Bestanden (2026) |

**DFN-Referenzimplementierung:** Start **Q4 2026** 🎉

---

## 🤝 Wie kannst du mitmachen?

### 🧪 **1. Testen & Feedback geben**
- **Demo-Umgebung anfordern**: Schreibe an [tobias.weiss@uni-marburg.de](mailto:tobias.weiss@uni-marburg.de)
- **Testzugang erhalten**: Innerhalb von 24 Stunden
- **Pilotphase starten**: 3 Monate kostenlos

**Was du testen kannst:**
- [x] Moodle/ILIAS mit SSO
- [x] Nextcloud-Integration
- [x] Etherpad & Draw.io
- [x] Monitoring (Grafana)
- [x] Backup & Restore

### 🛠️ **2. Code beitragen**
- **Repository**: [https://gitlab.com/opendesk-edu/opendesk-edu](https://gitlab.com/opendesk-edu/opendesk-edu)
- **Merge Requests**: Immer willkommen!
- **Issues**: [GitLab Issues](https://gitlab.com/opendesk-edu/opendesk-edu/issues)

**Aktuelle Themen:**
- [ ] Integration von **Mahara** (Portfolio-System)
- [ ] **OpenOlat** hinzufügen
- [ ] **Matrix/Element**-Chat integrieren
- [ ] **Gehostete Variante** (für Hochschulen ohne K8s)

### 💬 **3. Community**
- **Matrix-Chat**: `#opendesk-edu:matrix.org`
- **Monatlicher Community-Call**: [Termine hier](https://opendesk-edu.org/community)
- **DFN-Tagung 2026**: Workshop & Vortrag (September 2026)

---

## 📦 Schnellstart (für Techniker)

### Option 1: Docker Compose (für Einsteiger)
```bash
# Repository klonen
git clone https://gitlab.com/opendesk-edu/opendesk-edu.git
cd opendesk-edu/opendesk-compose

# Starten
docker-compose up -d

# Status prüfen
docker-compose ps
```

### Option 2: Kubernetes (Helmfile)
```bash
# Repository klonen
git clone https://gitlab.com/opendesk-edu/opendesk-edu.git
cd opendesk-edu/helmfile

# Deployen
helmfile sync

# Status prüfen
kubectl get pods -n opendesk
```

**Dokumentation:** [https://docs.opendesk-edu.org](https://docs.opendesk-edu.org)

---

## 🔍 Screenshots

### Architektur
![Architektur](https://gitlab.com/opendesk-edu/opendesk-edu/-/raw/main/docs/dfn/images/architecture-diagram.svg)
*Modulare Architektur mit Kubernetes, Ceph CSI und 28 integrierten Diensten*

### Portal
![Portal](https://gitlab.com/opendesk-edu/opendesk-edu/-/raw/main/docs/dfn/images/opendesk-portal2.png)
*Ein Login – Zugang zu allen Diensten*

### Moodle
![Moodle](https://gitlab.com/opendesk-edu/opendesk-edu/-/raw/main/docs/dfn/images/moodle.png)
*Vollständig integriert mit SSO*

---

## 💡 Warum sollte deine Hochschule mitmachen?

1. **Zeit sparen**: Keine individuelle Konfiguration mehr nötig
2. **Kosten senken**: Gemeinsame Wartung statt Insellösungen
3. **Sicherheit erhöhen**: Von Anfang an mit Security-Hardening
4. **Flexibilität behalten**: Anpassbar an eigene Anforderungen
5. **Community nutzen**: Erfahrung von 12+ Hochschulen teilen

---

## 📢 Stimmen aus der Community

> *„Früher haben wir Moodle, Nextcloud und Etherpad separat betrieben – mit eigenem SSO, eigenen Backups und eigener Wartung. Mit openDesk Edu sparen wir nicht nur Zeit, sondern haben auch eine **einheitliche Basis**, auf der wir aufbauen können.“*
> **— Tobias Weiß, HRZ Marburg**

> *„Die Integration von ILIAS mit Shibboleth war für uns ein kritischer Punkt. openDesk Edu hat dies aus der Box heraus funktioniert.“*
> **— [Name einfügen], [Hochschule einfügen]** *(Hast du eine Erkenntnis? Teile sie!)*

---

## 🗺️ Roadmap

| **Zeitraum** | **Meilenstein** | **Status** |
|--------------|------------------|------------|
| **Q3 2026** | 15 Hochschulen im Testbetrieb | 🟡 In Arbeit |
| **Q4 2026** | DFN-Referenzimplementierung starten | 🟡 Geplant |
| **Q1 2027** | Gehostete Variante (Beta) | 🟢 In Planung |
| **Q2 2027** | Vollständige DFN-AAI-Integration | 🟢 In Planung |

---

## 📞 Kontakt

**Ansprechpartner:**
> **Tobias Weiß**  
> Abteilung Zentrale Systeme  
> Hochschulrechenzentrum (HRZ)  
> Philipps-Universität Marburg  
> Hans-Meerwein-Str. 6, 35032 Marburg  
> Büro: Gebäude H|04, Raum 05A12  
> 📧 [tobias.weiss@uni-marburg.de](mailto:tobias.weiss@uni-marburg.de)  
> 💬 [@weissto:matrix.uni-marburg.de](https://matrix.to/#/@weissto:matrix.uni-marburg.de)  
> 🌐 [https://www.uni-marburg.de/de/hrz](https://www.uni-marburg.de/de/hrz)

**Projekt-Links:**
- 🌐 [Website](https://opendesk-edu.org)
- 🐙 [GitLab](https://gitlab.com/opendesk-edu)
- 📖 [Dokumentation](https://docs.opendesk-edu.org)

---

## ❓ Fragen?

Antworte einfach auf diesen Post oder schreibe mir direkt!  
Ich freue mich auf den Austausch. **Gemeinsam können wir den Betrieb von Bildungsdiensten an Hochschulen vereinfachen!**

---

*openDesk Edu – Gemeinsam. Offen. Für die Bildung.*  
*#OpenSource #Hochschulen #Kubernetes #DFN #Zusammenarbeit*
