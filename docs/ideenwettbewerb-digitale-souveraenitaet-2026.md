# Bewerbung: HFD Ideenwettbewerb Digitale Souveränität 2026

**Projekt:** openDesk Edu — Digitale Souveränität als skalierbare Hochschulplattform
**Einreichungsfrist:** 31. August 2026
**Jury-Auswahl:** September 2026
**Bekanntgabe Siegerteam:** 05. Oktober 2026

---

## 1. Kurzbeschreibung (Formular, max. 500 Zeichen)

> openDesk Edu ist eine vollständig quelloffene, Kubernetes-basierte Plattform für den souveränen digitalen Arbeitsplatz an Hochschulen. 78 quelloffene Dienste (LMS, Dateiaustausch, Groupware, Videokonferenz) werden als NixOS-Container deterministisch gebaut, signiert und per SBOM dokumentiert (0 CVEs). Deployment per GitOps auf eigener Infrastruktur, SCS-kompatibler Cloud oder im Verbund — mit SSO-Föderation über Keycloak und DFN-AAI/eduGAIN. Skalierbar und herstellerunabhängig.

*(482 von 500 Zeichen)*

---

## 2. Vollständige Einreichung

### 2.1 Projektprofil

**openDesk Edu** ist eine vollständig quelloffene, Kubernetes-native Plattform für den digitalen Arbeitsplatz sowie die Forschungs- und Lehrinfrastruktur von Hochschulen. Die Plattform bündelt bewährte quelloffene Kernkomponenten für Dateiaustausch, Groupware, Videokonferenz, Lernmanagement, Messaging und wissenschaftliches Rechnen in einer einzigen, deterministisch aufgebauten und reproduzierbar bereitgestellten Umgebung — als Alternative zu proprietären Cloud-Diensten.

Kernmerkmale:

- **100 % Open Source** auf allen Ebenen: Anwendungen, Container, Build- und Deployment-Pipeline.
- **Deterministische, reproduzierbare Builds:** Container werden aus NixOS definiert und sind in identischer Qualität auf jeder Infrastruktur reproduzierbar.
- **Kubernetes-nativ:** GitOps (ArgoCD) und Helm/Helmfile als standardisierte Deployment-Wege.
- **Integrierte Identität und Föderation:** SSO über Keycloak, Anbindung an Hochschul-IdPs sowie SAML-Föderation über DFN-AAI/eduGAIN.
- **Supply-Chain-Sicherheit:** SBOM (SPDX 2.3) für jeden Container, Cosign-Signierung, Schwachstellenprüfung (0 CVEs).

### 2.2 Bezug zum Thema Digitale Souveränität

Viele Hochschulen betreiben ihren digitalen Arbeitsplatz über proprietäre Cloud-Dienste mit anbietergebundener Infrastruktur, steigenden Lizenzkosten und Datenverarbeitung außerhalb eigener Kontrolle. openDesk Edu adressiert diese Abhängigkeit mit einer leistungsfähigen quelloffenen Alternative:

- **Datenhoheit** bleibt bei der Einrichtung; Speicherung und Verarbeitung erfolgen auf selbst kontrollierter Infrastruktur.
- **Herstellerunabhängigkeit:** keine Lock-in-Bindung an einzelne Anbieter; jede Komponente ist austauschbar.
- **Plan- und beschaffungsfähig:** vollständig quelloffen, nachvollziehbar, für öffentliche Vergabe geeignet.

Die Plattform trägt zu mehreren ausgeschriebenen Themenfeldern bei: **Open Source**, **souveräne Cloud**, **digitale Identitäten**, **Data Governance** (transparente Datenhaltung, Compliance-Nachweise) sowie **KI-Infrastruktur** (ausbaufähige quelloffene KI-/ML-Dienste).

### 2.3 Skalierbarkeit auf andere Hochschulen

Der Wettbewerb verlangt skalierbare, auf weitere Hochschulen übertragbare Vorhaben. openDesk Edu ist von Grund auf auf Übertragbarkeit ausgelegt:

- **Offene Artefakte:** Alle Container-Definitionen, Kubernetes-Manifeste und Build-Skripte liegen in öffentlichen Repositories.
- **Standardisierte Basis:** Das Deployment läuft auf jeder konformen Kubernetes-Umgebung, auf souveräner Cloud (SCS-kompatibel) sowie auf eigener Hardware (z. B. K3s).
- **Keine Hochschultyp-Bindung:** Funktionsfähig von kleinen Einrichtungen bis zu großen Verbünden; Betrieb durch ein kleines IT-Team ist vorgesehen.
- **Dokumentierte Übertragung:** Deployment-Leitfaden sowie Muster für SSO, Monitoring, Backup und Betrieb.
- **Verbundstauglichkeit:** Die Architektur erlaubt einem Hochschulverbund, die Plattform zentral oder föderiert zu betreiben und Betriebslast zu teilen.

Genau diese Verbund-Skalierung ist das, was der Ideenwettbewerb ermöglichen kann: die Erprobung an einer Transferhochschule oder in einem Verbund als zusätzlicher Real-Betrieb.

### 2.4 Reifegrad

Das Projekt befindet sich in der **produktionsnahen Phase** — nicht als Ideenskizze, sondern als lauffähige Lösung: Die Container-Build-Pipeline (deterministisch, signiert, SBOM-dokumentiert), das Kubernetes-Deployment und die GitOps-Werkzeuge sind umgesetzt und dokumentiert. Die Bausteine eignen sich unmittelbar zur Skalierung an einer weiteren Hochschule oder in einem Verbund.

### 2.5 Team und Nachhaltigkeit

Getragen von der openDesk-Edu-Community. Die Arbeit ist vollständig offen; Beiträge sind ausdrücklich erwünscht. Langfristig stehen Wartung, Updates, Dokumentation und Betrieb im Vordergrund — durch den deterministischen Build und die herstellerunabhängige Toolchain dauerhaft wirtschaftlich und nachvollziehbar gestaltbar.

### 2.6 Mehrwert des Wettbewerbspreises

Die Förderung ist bewusst ideell und personell ausgerichtet — für dieses Projekt die passende Form: Benötigt werden Reichweite, Vernetzung und ein konkreter Transfer-Ort:

- **Realer Transfer:** Skalierung bei einer Transferhochschule oder in einem Verbund als Pilot.
- **Fachliche Begleitung** durch das HFD-Team zur Adaption auf weitere Einrichtungen.
- **Netzwerk und Sichtbarkeit** über die HFD-Kanäle und -Formate (Konferenzen, Workshops).
- **Reproduzierbarkeit als Vorbild:** Weitere Hochschulen können den Weg anhand der offenen Artefakte nachvollziehen.

---

## 3. Kontakt

- **Projekt:** openDesk Edu (openDesk-Edu-Community)
- **E-Mail:** info@opendesk-edu.org
- **Quellcode:** github.com/tobias-weiss-ai-xr/opendesk-nix

---

*Eingereicht im Rahmen des HFD-Ideenwettbewerbs Digitale Souveränität 2026.*
