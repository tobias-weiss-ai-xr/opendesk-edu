# SAML Metadata Generator for DFN-AAI Federation

- German (Deutsch) ist primäre Sprache; English (Englisch) ist zweitrangig.
- This README is bilingual. German is the primary language; English provides translations.

## Zweck

- Generiert SAML 2.0 SP-Metadaten XML-Dateien für DFN-AAI/eduGAIN-Föderationsregistrierung.
- Generates SAML 2.0 SP metadata XML files for DFN-AAI/eduGAIN federation registration.

## Voraussetzungen

- Python 3.x installiert
- Abhängigkeiten are in requirements.txt aufgeführt
- Zugriff auf Zertifikate (signing/encryption) per konfiguriertem Pfad

## Installation (Installation / Installation)

```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

## Konfiguration (Configuration)

- Kopieren Sie die Template-Konfigurationsdatei in den Arbeitskontext und passen Sie sie an:
  - scripts/saml-metadata-generator/saml-metadata-generator-config.yaml.example -> saml-metadata-generator-config.yaml
- In der Konfiguration definieren Sie:
  - organization: Name, URL, Sprache (lang)
  - contacts: technische, administrative, support Kontakte
  - requested_attributes: DFN-AAI/eduGAIN Attribute-Übergaben
  - environments: dev, staging, production mit base_url, entity_id, acs_url, slo_url, certificate paths
- Beispiel-Referenz: saml-metadata-generator-config.yaml.example

Beachten Sie: Sie dürfen die config.yaml nicht direkt verändern, nutzen Sie die Vorlage zum Kopieren.

## Verwendung (Usage)

- Erzeuge Metadata für eine spezifische Umgebung:

```bash
python3 saml-metadata-generator.py -c saml-metadata-generator-config.yaml -e dev -o metadata-dev.xml
```

- Erzeuge Metadata für alle konfigurierten Umgebungen:

```bash
python3 saml-metadata-generator.py -c saml-metadata-generator-config.yaml -a
```

- Validieren Sie eine vorhandene Metadata-Datei:

```bash
python3 saml-metadata-generator.py -c saml-metadata-generator-config.yaml --validate metadata.xml
```

Hinweis: Das Script unterstützt die Umgebungen dev, staging und production. Die Dateinamen können Sie frei wählen.

## DFN-AAI Registrierungsworkflow (Registration Workflow)

- DFN-AAI verlangt eine formale Registrierung; der Prozess umfasst Vorabkontakt, Prüfung/Prüfzeit, und Freigabe.
- Im config.yaml finden Sie Verweise auf Registrierungs-URLs, Support-Emails und Beschreibungen.
- Typischer Ablauf:
  1) Metadata erzeugen (Dev/Test-Umgebung) und einreichen an DFN-AAI Test Federation.
  2) Vorabkontakt mit der DFN-AAI (pre_contact_email) und Einholen von Feedback.
  3) Nach Zustimmung Erstellung der Produktion-Metadaten und Einreichung bei Production Federation.
  4) Beantragung des EduGAIN-Auftritts nach Freigabe.
  5) Verifizierung via DFN-AAI-Disovery-Dienste.

The DFN-AAI workflow mirrors the steps in the configuration:

- Test/Muster-Registrierung: Registrierung/Metadata-URL, Registration URL, Discovery URL, Support-Email.
- Produktion: Produktion-Metadata-URL, Produktionsregistrierung, Discovery, Support.
- eduGAIN: Inter-Föderation – Metadata, Registration, Discovery.

## Fehlersuche (Troubleshooting)

- Fehlermeldung: Config-Datei nicht gefunden
  - Lösung: Kopieren Sie die Vorlage und legen Sie den richtigen Pfad fest.
- Zertifikatsfehler oder Lesefehler der Zertifikate
  - Lösung: Stellen Sie sicher, dass Zertifikatpfade korrekt sind und die Dateien lesbar sind.
- YAML-Parsing-Fehler
  - Lösung: Prüfen Sie die YAML-Syntax in der Konfig.

## Optionen der Konfiguration (Configuration Options)

- base_url, realm, entity_id, acs_url, slo_url
- certificates: signing, encryption
- organization, contacts, requested_attributes
- environments: dev, staging, production
- dfn_aai: test, production, edugain
- registration: pre_contact_email, approval_times, requirements
- validation: schema_validation, use_xmllint, cert_expiry_warn_days

## English (English) translation notes

- Primary language is German for DFN-AAI compliance; English is provided for readability.
- The structure mirrors the German section and helps international operators use the tool.

## Abkürzungen / Abbreviations

- DFN-AAI: German Research and Education Network – Authentication and Authorization Infrastructure
- eduGAIN: Interfederation for academic identities

## Lizenz

- Abhängigkeiten und Code bleiben unverändert; dieses Dokument ergänzt die vorhandene Konfiguration.

## Hinweis zur Wartung

- Append-only documentation: Änderungen sollten in der README und in den Notizen festgehalten werden.

---

## SAML Metadata Generator for DFN-AAI Federation

- English (as a secondary language) for international users.
- This bilingual README mirrors the German primary language.
