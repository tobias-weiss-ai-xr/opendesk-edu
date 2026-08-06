# Open Source Wettbewerb 2026 – Bewerbungstexte openDesk Edu

**Einreichung:** Universität Marburg | Kategorie: Interne Verwaltungsanwendungen + Künstliche Intelligenz
**Ansprechpartner:** Tobias Weiß, DevOps Engineer // Lead Digital Sovereignty

---

## 1. Projektbeschreibung

**openDesk Edu – Die Open-Source-Digitalplattform für Hochschulen**

openDesk Edu ist eine Erweiterung der openDesk Community Edition des Bundes (ZenDiS) um spezifisch für Hochschulen benötigte Dienste. Während openDesk primär auf Verwaltungsmitarbeitende ausgerichtet ist, adressiert openDesk Edu die gesamte Hochschule: Studierende, Lehrende, Forschende und Verwaltung auf einer einzigen, einheitlich authentifizierten Plattform.

**Problemstellung**

Hochschulen in Deutschland stehen vor einem strategischen Dilemma: Entweder sie setzen auf proprietäre All-in-One-Lösungen wie Microsoft 365 Education – mit hohen Lizenzkosten, Vendor-Lock-in und Datenabfluss in US-Rechenzentren – oder sie betreiben eine heterogene Landschaft aus Einzellösungen (Moodle, ILIAS, Nextcloud, Jitsi etc.) ohne gemeinsame Benutzerverwaltung, ohne einheitlichen Zugang und ohne integrierte Arbeitsabläufe. Beide Wege sind unbefriedigend: Ersterer widerspricht der digitalen Souveränität, letzterer erzeugt hohen Administrationsaufwand und eine schlechte User Experience.

**Lösung**

openDesk Edu vereint über 25 quelloffene Dienste auf einer gemeinsamen Kubernetes-Plattform mit zentralem Keycloak-Single-Sign-On. Ein einziger Login genügt, um auf alle Dienste zuzugreifen – von E-Mail und Groupware über Lernmanagementsysteme bis hin zu wissenschaftlichen Rechenwerkzeugen und KI-Assistenten.

**Lernmanagementsysteme**: ILIAS und Moodle in vollständig integrierter Form mit SAML-Authentifizierung über Keycloak und DFN-AAI-Anbindung. Beide Systeme teilen sich die Benutzerbasis und ermöglichen nahtlose Übergänge zwischen Kursen, Prüfungen und Kollaboration.

**Kollaboration und Produktivität**: Nextcloud oder OpenCloud für Dateispeicher und -austausch, Etherpad für Echtzeit-Zusammenarbeit, BookStack als Wissensdatenbank, Planka für Projektmanagement und Zammad als Service-Desk. Für E-Mail und Groupware stehen OX App Suite, SOGo und Grommunio zur Auswahl – je nach Anforderung an ActiveSync-Unterstützung und Skalierbarkeit.

**Wissenschaftliches Rechnen (Collab Services)**: Eine neuartige Integration von JupyterHub, Overleaf, RStudio Server, code-server (VS Code im Browser), KasmVNC (Linux-Desktop im Browser), Dask Gateway (verteiltes Rechnen), ttyd (Web-Terminal), Slidev und Excalidraw – alles über eine zentrale Dashboard-Oberfläche erreichbar. Dies senkt die Einstiegshürde für digitale Lehre und Forschung erheblich, da Studierende und Forschende keine lokale Installation mehr benötigen.

**Künstliche Intelligenz (zweite Kategorie)**: Open WebUI bietet eine ChatGPT-ähnliche Oberfläche, die über Ollama mit lokalen Large Language Models (LLaMA, Mistral u.a.) verbunden ist. Sämtliche KI-Verarbeitung erfolgt auf der eigenen Infrastruktur – keine Daten verlassen die Hochschule. Dies ist für den Forschungs- und Lehrbetrieb, insbesondere unter datenschutzrechtlichen Aspekten, von zentraler Bedeutung.

**Technische Architektur**

Die Plattform basiert auf Kubernetes (K8s 1.28+) mit Helm und helmfile als Deployment-Werkzeugen. Jeder Dienst ist in einem eigenen Helm-Chart gekapselt und über helmfile-Gruppen organisierbar. Die gesamte Konfiguration erfolgt über zentrale YAML-Templates, die Umgebungsvariablen, Domains und Zertifikate steuern.

- **Authentifizierung**: Keycloak als zentraler Identity Provider (SAML 2.0 + OIDC)
- **Hochschulföderation**: Vollständige DFN-AAI / eduGAIN-Integration über Shibboleth Service Provider
- **Verschlüsselung**: Automatisierte TLS-Zertifikate über die openDesk-Certificates-Komponente
- **Backup**: k8up (restic-basiert) für alle persistenten Daten
- **Monitoring**: Prometheus-Stack (im openDesk-Upstream enthalten)
- **Storage**: RWO/RWX-StorageClasses aus der openDesk-Konfiguration

Ein besonderes architektonisches Merkmal ist die modulare Austauschbarkeit: Für jede Funktion existieren mehrere Optionen (z.B. Nextcloud ODER OpenCloud für Dateien, OX App Suite ODER SOGo ODER Grommunio für E-Mail). Hochschulen wählen die Komponente, die ihren Anforderungen am besten entspricht – ohne die Plattform wechseln zu müssen.

**Umsetzungsstand**

Das Projekt ist aktiv in Entwicklung und wird an der Universität Marburg betrieben. Alle Kernkomponenten sind deployt und getestet. Phase A (Foundation mit 11 wissenschaftlichen Rechenwerkzeugen) ist abgeschlossen, Phasen B und C (Produktionshärtung und Feinschliff) sind in Arbeit. Die Plattform wurde auf der Chemnitzer Linux-Tage 2026 sowie auf dem LinuxTag 2026 in 30 Sprachen präsentiert und stieß auf großes Interesse im gesamten DACH-Raum.

---

## 2. Technischer Innovationsgrad und Beitrag zur Verwaltungsmodernisierung

openDesk Edu stellt in mehrfacher Hinsicht eine technische Neuerung dar:

**1. Erste vollständige Integration von openDesk mit hochschulspezifischen Diensten.** Während openDesk als Verwaltungsplattform konzipiert ist, erweitert openDesk Edu den Ansatz auf den gesamten Hochschulkontext. Die Integration von ILIAS, Moodle, JupyterHub und Overleaf in die bestehende Keycloak-SSO-Infrastruktur ist technisch anspruchsvoll: Jeder Dienst erfordert individuelle SAML/OIDC-Konfiguration, Attribut-Mapping und Session-Handling. Die Lösung dieser Integrationsprobleme – dokumentiert in wiederverwendbaren Helm-Charts und Konfigurationsvorlagen – ist ein konkreter Beitrag zur Verwaltungsmodernisierung, da andere Hochschulen diese Arbeit nicht wiederholen müssen.

**2. Collab Services – wissenschaftliche Werkzeuge als Plattform.** Die Bündelung von JupyterHub, Overleaf, RStudio, code-server, Dask und Open WebUI in einer einheitlichen Helmfile-Gruppe mit zentralem Dashboard ist neuartig. Existierende Lösungen (z.B. CoCalc) sind proprietär oder erfordern eigene Infrastruktur. openDesk Edu bietet eine quelloffene Alternative, die tief in die vorhandene Hochschul-IT integriert ist – inklusive DFN-AAI-Authentifizierung und gemeinsamer Storage-Anbindung über OpenCloud-WebDAV.

**3. Lokale KI als Plattformdienst.** Open WebUI + Ollama sind als vollständig lokale KI-Infrastruktur integriert, ohne Cloud-Abhängigkeit. Dies ist technisch innovativ, weil es GPU-Scheduling, Modell-Management und Benutzerauthentifizierung in einem Kubernetes-Cluster vereint – eine Kombination, die in dieser Form an keiner anderen deutschen Hochschule produktiv eingesetzt wird.

**4. Modulare Helmfile-Architektur.** openDesk Edu führt das Konzept der alternativen Komponenten (z.B. Nextcloud ↔ OpenCloud, Jitsi ↔ BigBlueButton) ein. Dies wird durch ein ausgeklügeltes helmfile-Labeling und konditionale Releases ermöglicht – ein Architekturmuster, das über das Projekt hinaus als Best Practice für modulare Kubernetes-Plattformen dienen kann.

**Beitrag zur Verwaltungsmodernisierung**: openDesk Edu zeigt, dass eine moderne, cloud-native Hochschul-IT vollständig auf Open-Source-Basis realisiert werden kann. Die Plattform reduziert die Fragmentierung der IT-Landschaft, senkt den Administrationsaufwand durch zentrale Authentifizierung und einheitliches Deployment und macht Hochschulen unabhängig von proprietären Anbietern.

---

## 3. Ökonomischer Nutzen

openDesk Edu adressiert die wirtschaftliche Ineffizienz der aktuellen Hochschul-IT-Landschaft:

**1. Wegfall von Lizenzkosten.** Eine deutsche Universität mittlerer Größe (20.000 Studierende) gibt jährlich zwischen 500.000 € und 2 Mio. € für proprietäre Softwarelizenzen aus – Microsoft Campus Agreement, Adobe, MATLAB, SPSS und weitere. openDesk Edu ersetzt diese durch quelloffene Äquivalente: Nextcloud/OpenCloud statt SharePoint/OneDrive, Collabora statt Microsoft 365, JupyterHub statt MATLAB Online, Open WebUI statt ChatGPT Enterprise, RStudio statt SPSS. Die Lizenzkosten sinken auf null.

**2. Konsolidierung der IT-Infrastruktur.** Aktuell betreiben viele Hochschulen parallele Infrastrukturen: Ein Team betreut das Lernmanagementsystem, ein anderes die Kollaborationsplattform, ein drittes die E-Mail-Infrastruktur, ein viertes die Rechencluster – oft mit unterschiedlichen Authentifizierungssystemen und ohne Integration. openDesk Edu konsolidiert dies auf einer Kubernetes-Plattform mit einem Identity Provider. Die Einsparungen bei Betrieb, Wartung und Personal sind erheblich: Statt 5–6 Teilinfrastrukturen wird nur eine betrieben.

**3. Geringere Einarbeitungs- und Supportkosten.** Durch das einheitliche Benutzererlebnis (ein Login, ein Portal, konsistente Bedienung) sinken Support-Anfragen signifikant. Studierende und Mitarbeitende müssen sich nicht in sechs verschiedene Systeme mit sechs verschiedenen Passwörtern und Bedienlogiken einarbeiten.

**4. Shared-Development-Effekt.** openDesk Edu ist als Gemeinschaftsprojekt konzipiert. Wenn eine Hochschule eine Integration vornimmt, profitiert die gesamte Community. Dies vermeidet Doppelarbeit: Aktuell implementieren 80 deutsche Hochschulen unabhängig voneinander die Integration von ILIAS mit Keycloak – jede mit eigenem Aufwand und eigenen Fehlern. openDesk Edu bietet eine geteilte, getestete Referenzimplementierung.

**5. Vermiedene Wechselkosten.** Die modulare Architektur ermöglicht den Austausch von Komponenten ohne Plattformwechsel. Eine Hochschule, die heute Nextcloud nutzt, kann später auf OpenCloud wechseln – ohne die Benutzerverwaltung, das Portal oder die Backup-Infrastruktur ändern zu müssen. Dies reduziert das wirtschaftliche Risiko von Technologieentscheidungen erheblich.

Die Gesamtkostenersparnis über einen Fünf-Jahres-Zeitraum wird für eine mittlere Universität auf 2–4 Mio. € geschätzt – bei gleichzeitiger Steigerung der digitalen Souveränität.

---

## 4. Nachhaltigkeit der Lösung

openDesk Edu ist auf technische, organisatorische und ökologische Nachhaltigkeit ausgelegt:

**Technische Nachhaltigkeit**

- **Open-Source-Lizenzierung**: Sämtliche Komponenten stehen unter Open-Source-Lizenzen (Apache 2.0, AGPL-3.0, GPL, MIT). Es gibt keine versteckten proprietären Abhängigkeiten. Das Projekt kann auch bei Wegfall der ursprünglichen Entwickler von jeder Hochschule oder jedem Dienstleister weitergeführt werden.
- **Standards statt proprietärer Schnittstellen**: SAML 2.0, OIDC, LDAP, CalDAV/CardDAV, WebDAV, SCIM – alle Integrationen basieren auf offenen Standards. Komponenten können gegen jede standardskonforme Alternative ausgetauscht werden.
- **Modulare Architektur**: Jeder Dienst ist ein eigener, austauschbarer Baustein. Veraltete Komponenten können durch aktuelle Alternativen ersetzt werden, ohne die Gesamtplattform zu gefährden. Dies verhindert technologische Altlasten.
- **Upstream-Following**: openDesk Edu folgt den Upstream-Versionen aller integrierten Projekte. Sicherheitsupdates und neue Versionen werden zeitnah eingespielt.

**Organisatorische Nachhaltigkeit**

- **Community-getrieben**: Das Projekt ist als Kollaboration mehrerer Hochschulen und Einrichtungen angelegt. Die Entwicklung findet öffentlich auf GitHub und Codeberg statt, Beiträge sind explizit erwünscht.
- **Dokumentation und Wissenstransfer**: Umfangreiche Dokumentation (Architektur, Deployment, Konfiguration, Migration) und mehrsprachige Präsentationsmaterialien (30 Sprachen) senken die Einstiegshürde für neue Hochschulen.
- **Keine Vendor-Lock-in**: Es gibt keine Abhängigkeit von einem bestimmten Dienstleister. Betrieb, Wartung und Weiterentwicklung können von jedem qualifizierten IT-Dienstleister oder hochschuleigenem Personal übernommen werden.

**Ökologische Nachhaltigkeit**

- **Ressourceneffizienz durch Konsolidierung**: Statt mehrerer paralleler Infrastrukturen (ein Cluster pro Anwendung) betreibt openDesk Edu eine gemeinsame Kubernetes-Plattform. Dies reduziert den Gesamtenergieverbrauch durch besser ausgelastete Hardware und geringeren Overhead.
- **Lokale KI**: Anders als Cloud-KI-Dienste (ChatGPT, Claude, Gemini) erfordert die lokale Ollama-Integration keine energieintensiven Rechenzentrumsverbindungen und keine Datenübertragung über weite Strecken.

---

## 5. Beitrag zur Stärkung der Digitalen Souveränität

openDesk Edu leistet einen zentralen Beitrag zur digitalen Souveränität deutscher Hochschulen:

**1. Vollständige Datenhoheit.** Sämtliche Daten – von E-Mails über Kursmaterialien bis hin zu KI-Interaktionen – verbleiben auf der Infrastruktur der Hochschule. Es findet keine Datenübertragung an Drittanbieter statt, insbesondere nicht in US-amerikanische Rechenzentren (kein Microsoft 365, keine Google Workspace, kein ChatGPT). Dies ist für Hochschulen nicht nur eine Frage der Souveränität, sondern auch der datenschutzrechtlichen Compliance (DSGVO, insbesondere Art. 44–49 zur Drittlandübermittlung).

**2. Unabhängigkeit von proprietären Ökosystemen.** openDesk Edu bricht die Abhängigkeit von den Ökosystemen der großen US-Technologiekonzerne. Statt Microsoft 365 Education (geschätzte Marktdurchdringung an deutschen Hochschulen: >60 %) setzt die Plattform auf vollständig quelloffene Alternativen. Dies bedeutet: Keine erzwungenen Updates, keine Lizenzänderungen, keine einseitigen Konditionsanpassungen, keine Kündigung von Lizenzen aufgrund politischer Entscheidungen.

**3. Basierend auf openDesk – der Souveränitätsplattform des Bundes.** openDesk wurde im Auftrag des Bundesministeriums des Innern und für Heimat entwickelt, um die öffentliche Verwaltung von proprietären Abhängigkeiten zu lösen. openDesk Edu überführt dieses Konzept in den Hochschulkontext und stellt sicher, dass die digitale Souveränität von der Verwaltungsebene nahtlos in die akademische Lehre und Forschung fortgesetzt wird.

**4. DFN-AAI-Integration als Souveränitätsbaustein.** Die Integration der DFN-AAI-Föderation (Shibboleth/eduGAIN) stellt sicher, dass Hochschulen ihre bestehende Authentifizierungsinfrastruktur weiter nutzen können. Dies vermeidet Insellösungen und stärkt die föderierte Identitätsverwaltung im deutschen Wissenschaftsnetz.

**5. Lokale KI statt Cloud-KI.** Die Integration von Open WebUI mit Ollama ermöglicht KI-Nutzung ohne Cloud-Anbindung. Ein Hochschulgesetz oder eine Datenschutzverordnung kann nicht dazu führen, dass der KI-Assistent abgeschaltet werden muss – weil keine Daten Dritte erreichen. Dies ist ein entscheidender Unterschied zu ChatGPT Enterprise, Microsoft Copilot oder Google Gemini, die alle eine Datenverarbeitung auf Servern in den USA erfordern.

**6. Nachvollziehbare und prüfbare Software.** Da sämtlicher Quellcode offen liegt, können Hochschulen Sicherheitsaudits durchführen, Schwachstellen eigenständig schließen und die Software an eigene Bedürfnisse anpassen – ohne auf den Goodwill eines Herstellers angewiesen zu sein.

---

*Stand: Juni 2026 | Einreichung zum Open Source Wettbewerb 2026*
*Kategorien: Interne Verwaltungsanwendungen, Künstliche Intelligenz*
