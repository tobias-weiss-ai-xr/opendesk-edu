---
SPDX-License-Identifier: AGPL-3.0
---

# 🎓 openDesk Edu: Offenes Ökosystem für Hochschulen – Mitmachen und mitgestalten!

**Erstellt von:** Tobias Weiß, HRZ Marburg
**Datum:** Juli 2026
**Tags:** #opendesk #bildung #kubernetes #open-source #hochschulen #vendor-lock-in #ökosystem

---

## 👋 Warum openDesk Edu?

An vielen Hochschulen sieht die Realität aktuell so aus:
- **Abhängigkeit von einzelnen Anbietern**: Ob Microsoft 365, Nextcloud, Univention oder Nordeck – der Wechsel zwischen Lösungen ist **schmerzhaft und teuer**.
- **Vendor Lock-in**: Sobald man sich für eine Plattform entscheidet, ist der **Wechsel zu Alternativen kaum noch möglich** – sei es wegen proprietärer Formate, fehlender Schnittstellen oder komplexer Migration.
- **Insellösungen**: Jede Hochschule betreibt Moodle, Nextcloud oder ILIAS **individuell** – mit eigenem SSO, eigenen Backups und eigener Wartung. Die Folge: **Doppelte Arbeit, hohe Kosten und Sicherheitslücken**.

**Unsere Vision**:
🔹 **Ein Ökosystem, kein Monolith** – Alle Module müssen **einfach austauschbar** sein.
🔹 **Kein Vendor Lock-in** – Wir wechseln von einer Abhängigkeit (z. B. Microsoft 365) nicht in die nächste (z. B. Nextcloud als einziger Anbieter).
🔹 **Wahlfreiheit** – Ob SOGo oder Grommunio, Moodle oder ILIAS: **Die Hochschule entscheidet**, nicht der Anbieter.

---

## 🚀 Was ist openDesk Edu?

openDesk Edu ist ein **modulares, Kubernetes-natives Ökosystem**, das **Bildungsdienste als austauschbare Komponenten** bereitstellt. Jeder Dienst kann **einfach ersetzt oder ergänzt** werden – ohne die gesamte Plattform zu ändern.

### 🔧 Technische Basis
| **Schicht** | **Komponenten** | **Zweck** |
|--------------|----------------|------------|
| **Infrastruktur** | K3s, Ceph CSI, Helmfile | Skalierbare Basis für alle Dienste |
| **Authentifizierung** | Keycloak (SAML 2.0 + OIDC + DFN-AAI) | Einheitliches SSO für alle Anwendungen |
| **Storage** | Ceph (RBD für DBs, CephFS für Dateien) | Flexibler, skalierbarer Speicher |
| **Backups** | k8up + Restic | Automatisierte, inkrementelle Backups |

### 🔄 Warum ein Ökosystem? Kein Vendor Lock-in!
openDesk Edu ist **kein Monolith**, sondern ein **modulares System**, in dem **jeder Dienst austauschbar** ist.
Wir wollen **nicht von einer Abhängigkeit (z. B. Microsoft 365) in die nächste (z. B. Nextcloud als einziger Anbieter) wechseln**.

#### Beispiele für Austauschbarkeit:
| **Kategorie**       | **Optionen** | **Vorteil** |
|----------------------|-------------|-------------|
| **Groupware**        | SOGo, Grommunio, OpenXchange | Freiheit der Wahl |
| **Dateiablage**      | Nextcloud, OpenCloud | Kein Lock-in |
| **Lernmanagement**   | Moodle, ILIAS | Anpassbar an Lehransätze |
| **Mail**             | Stalwart, Dovecot | Skalierbar und sicher |

**Das bedeutet**:
✅ **Kein Zwang zu einer bestimmten Lösung** – Sie können zu jedem Zeitpunkt den Anbieter wechseln.
✅ **Keine Abhängigkeit von einzelnen Herstellern** – Alle Komponenten basieren auf **offenen Standards**.
✅ **Zukunftssicherheit** – Neue Dienste können **einfach hinzugefügt** werden, ohne das System zu brechen.

---

## 📜 Ausgangspunkt: Der Offene Brief
Die Entwicklung von openDesk Edu geht auf den **[Offenen Brief an den Herrn Bundesminister für Digitales und Staatsmodernisierung (BMDs)](https://pak-digs.gi.de/mitteilung/offener-brief-an-den-herrn-bundesminister-fuer-digitales-und-staatsmodernisierung-bmds-digitale-souveraenitaet-an-hochschulen-dringender-handlungsbedarf-fuer-eine-faire-marktsituation-opendesk-vs-microsoft)** der **Gesellschaft für Informatik e.V.** zurück. 
In diesem Brief fordert der **Präsidiumsarbeitskreis „Digitale Souveränität“** gemeinsam mit den Arbeitskreisen **„Open Source Software“** und **„Datenschutz und IT-Sicherheit“** sowie dem **ZKI e.V.** mehr **digitale Souveränität an Hochschulen** und sieht **dringenden Handlungsbedarf für eine faire Marktsituation** im Vergleich **openDesk vs. Microsoft**.

> *"Wir wollen nicht von Microsoft zu Nextcloud wechseln, nur um dann wieder in einer neuen Abhängigkeit gefangen zu sein. 
> Es muss ein **Ökosystem** geben, in dem wir **frei wählen können** – heute und in Zukunft."*

---

## 🌍 Aktuelle Einsatzgebiete von openDesk
openDesk **CE** (Community Edition) wird bereits produktiv eingesetzt:

| **Bundesland / Organisation** | **Projekt** | **Verantwortlich** | **Link** |
|-------------------------------|-------------|--------------------|----------|
| **Baden-Württemberg** | Digitaler Arbeitsplatz für Lehrkräfte | LMZ BW | [Pressemitteilung](https://www.baden-wuerttemberg.de/de/service/presse/pressemitteilung/pid/digitaler-arbeitsplatz-fuer-lehrkraefte-wird-nun-mit-opendesk-umgesetzt-1) |
| **Schleswig-Holstein** | Linux+1 | Land Schleswig-Holstein | [Pressemitteilung](https://www.schleswig-holstein.de/DE/landesregierung/themen/digitalisierung/linux-plus1) |

**openDesk Edu** (die hochschulspezifische Variante) befindet sich aktuell in der **Testphase am HRZ Marburg**
und ist die **logische Weiterentwicklung** des CE-Ansatzes für den Hochschulbereich. Die Projektwebsite ist unter 
**[https://opendesk-edu.org](https://opendesk-edu.org/en)** zu finden.

---

## 🤝 Wie kannst du mitmachen?

### 🧪 **1. Testen & Feedback geben**
- **Demo-Umgebung anfordern**: Schreibe an [tobias.weiss@uni-marburg.de](mailto:tobias.weiss@uni-marburg.de)
- Fragen, Feedback und Bug-Meldungen sind jederzeit willkommen

**Verfügbare Dienste in der Demo-Umgebung:**
- Moodle & ILIAS mit SSO
- Nextcloud-Integration
- Etherpad & Draw.io
- Monitoring (Grafana)
- Backup & Restore

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
- **Community of Practice Calls**: Quartalsweise (Termine im [opendesk-edu-cop](https://gitlab.com/opendesk-edu/opendesk-edu-cop) Repo)
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

**Dokumentation:** [https://docs.opendesk.eu](https://docs.opendesk.eu)

---

## 💡 Warum sollte eure Hochschule mitmachen?

1. **Vendor Lock-in vermeiden** – Keine Abhängigkeit von einzelnen Anbietern.
2. **Kontrolle behalten** – Die Hochschule entscheidet, welche Dienste sie nutzt.
3. **Kosten sparen** – Gemeinsame Wartung statt Insellösungen.
4. **Zukunft sichern** – Offene Standards garantieren **Langzeitkompatibilität**.
5. **Von der Community profitieren** – Erfahrungen mit anderen Hochschulen teilen.

---

## 📢 Stimmen aus der Community

> *"Früher haben wir Moodle, Nextcloud und Etherpad separat betrieben – mit eigenem SSO, eigenen Backups und eigener Wartung. Mit openDesk Edu sparen wir nicht nur Zeit, sondern haben auch eine **einheitliche Basis**, auf der wir aufbauen können."*
> **— Tobias Weiß, HRZ Marburg**

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
> 💬 [Matrix](https://matrix.to/#/@weissto:matrix.uni-marburg.de)  
> 🌐 [https://www.uni-marburg.de/de/hrz](https://www.uni-marburg.de/de/hrz)

**Projekt-Links:**
- 🌐 [Website](https://opendesk-edu.org/en)
- 🗺️ [Landscape – Ökosystem-Übersicht](https://landscape.opendesk-edu.org/)
- 🐙 [GitLab](https://gitlab.com/opendesk-edu)
- 📖 [Dokumentation](https://docs.opendesk.eu)

---

## ❓ Fragen?

Antworte einfach auf diesen Post oder schreibe mir direkt!  
Ich freue mich auf den Austausch. **Gemeinsam können wir den Betrieb von Bildungsdiensten an Hochschulen vereinfachen – ohne neue Abhängigkeiten zu schaffen!**
