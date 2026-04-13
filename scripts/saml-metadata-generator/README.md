<!--
SPDX-FileCopyrightText: 2025 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# SAML Metadata Generator for DFN-AAI Federation

[English](#english) | [Deutsch](#deutsch)

---

<a name="english"></a>

## English

### Description

The SAML Metadata Generator creates SAML 2.0 Service Provider (SP) metadata XML files for registering openDesk Edu with the DFN-AAI and eduGAIN identity federations. It supports multiple environments (dev, staging, production) with configurable entity IDs, ACS URLs, and certificate paths.

### Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| Python | 3.8+ | Python 3.10+ recommended |
| PyYAML | latest | Installed via `pip` |
| OpenSSL | any | For certificate handling |
| xmllint | optional | For XML validation |

### Installation

```bash
# Clone the repository (if not already done)
cd /opt/git/opendesk-edu

# Create and activate a virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install --upgrade pip
pip install -r scripts/saml-metadata-generator/requirements.txt
```

### Configuration

1. Copy the example configuration file:

   ```bash
   cp scripts/saml-metadata-generator/saml-metadata-generator-config.yaml.example \
      scripts/saml-metadata-generator/saml-metadata-generator-config.yaml
   ```

2. Edit the configuration file and adjust the following sections:

   - **`organization`**: Your institution's name, display name, URL, and primary language
   - **`contacts`**: Technical, administrative, and support contact details
   - **`requested_attributes`**: DFN-AAI/eduGAIN attributes your service requires
   - **`environments`**: Per-environment settings (dev, staging, production) including base URL, entity ID, ACS/SLO URLs, and certificate paths
   - **`dfn_aai`**: Federation-specific URLs for test, production, and eduGAIN

   See `saml-metadata-generator-config.yaml.example` for detailed comments on each field.

### Usage

#### Generate metadata for a specific environment

```bash
# Development environment
python3 scripts/saml-metadata-generator/saml-metadata-generator.py \
  -c scripts/saml-metadata-generator/saml-metadata-generator-config.yaml \
  -e dev \
  -o metadata-dev.xml

# Staging environment
python3 scripts/saml-metadata-generator/saml-metadata-generator.py \
  -c scripts/saml-metadata-generator/saml-metadata-generator-config.yaml \
  -e staging \
  -o metadata-staging.xml

# Production environment
python3 scripts/saml-metadata-generator/saml-metadata-generator.py \
  -c scripts/saml-metadata-generator/saml-metadata-generator-config.yaml \
  -e production \
  -o metadata-production.xml
```

#### Generate metadata for all environments

```bash
python3 scripts/saml-metadata-generator/saml-metadata-generator.py \
  -c scripts/saml-metadata-generator/saml-metadata-generator-config.yaml \
  --all
```

This creates `metadata-dev.xml`, `metadata-staging.xml`, and `metadata-production.xml` in the current directory.

#### Validate an existing metadata file

```bash
python3 scripts/saml-metadata-generator/saml-metadata-generator.py \
  --validate metadata-dev.xml
```

### DFN-AAI Specific Options

The generator includes DFN-AAI-specific configuration in the `dfn_aai` section of the config file:

| Federation | Metadata URL | Registration URL |
|------------|--------------|------------------|
| Test | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` | `https://test.aai.dfn.de/metadata/` |
| Production | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Basic-metadata.xml` | `https://www.aai.dfn.de/en/service/metadata/` |
| eduGAIN | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-edugain-metadata.xml` | `https://technical.edugain.org/` |

**DFN-AAI required attributes** (5 mandatory):

- `mail` — User email address
- `displayName` — User display name
- `eduPersonPrincipalName` — Persistent unique identifier
- `eduPersonAffiliation` — User role (student/faculty/staff/member)
- `eduPersonTargetedID` — Privacy-preserving persistent identifier

### Output Description

The generated XML metadata file contains:

- **EntityDescriptor** with your configured entity ID
- **SPSSODescriptor** with SAML 2.0 protocol support
- **KeyDescriptor** with your signing/encryption certificates
- **AssertionConsumerService** endpoint (HTTP-POST binding)
- **SingleLogoutService** endpoint (HTTP-Redirect binding)
- **NameIDFormat** declarations (persistent, transient, email)
- **AttributeConsumingService** with all requested attributes (bilingual German/English)
- **Organization** information (bilingual German/English)
- **ContactPerson** entries (technical, administrative, support)

### Validation Instructions

1. **XML well-formedness** — automatically checked by the generator:

   ```bash
   python3 scripts/saml-metadata-generator/saml-metadata-generator.py --validate metadata-dev.xml
   ```

2. **External validation with xmllint** (if installed):

   ```bash
   xmllint --noout metadata-dev.xml
   ```

3. **Manual review** — open the file and verify:
   - `entityID` matches your intended identifier
   - Organization name and contact details are correct
   - All endpoints use HTTPS with your actual domain
   - Certificate is properly embedded
   - All 5 required DFN-AAI attributes are listed

### Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| `Configuration file not found` | Config file path incorrect or not copied from example | Copy `saml-metadata-generator-config.yaml.example` to `saml-metadata-generator-config.yaml` and use `-c` with the correct path |
| `Certificate file not found` | Certificate path in config is wrong | Verify certificate paths in the `environments.*.certificates` section |
| `Environment 'xxx' not found` | Environment name does not match config | Use one of: `dev`, `staging`, `production` |
| `XML validation failed` | Generated metadata has structural issues | Check config for missing required fields (organization, contacts, entity_id) |
| YAML parsing error | Config file has syntax errors | Validate YAML with `python3 -c "import yaml; yaml.safe_load(open('config.yaml'))"` |

### Related Documentation

- [DFN-AAI Registration Guide](../../docs/dfn-aai-registration.md)
- [eduGAIN Attribute Mapping Reference](../../docs/edugain-attribute-mapping.md)
- [Federation Troubleshooting Guide](../../docs/federation-troubleshooting.md)

---

<a name="deutsch"></a>

## Deutsch

### Beschreibung

Der SAML-Metadaten-Generator erstellt SAML 2.0 Service Provider (SP) Metadaten-XML-Dateien für die Registrierung von openDesk Edu bei den Identitätsföderationen DFN-AAI und eduGAIN. Er unterstützt mehrere Umgebungen (Dev, Staging, Produktion) mit konfigurierbaren Entity-IDs, ACS-URLs und Zertifikatspfaden.

### Voraussetzungen

| Anforderung | Version | Hinweise |
|-------------|---------|----------|
| Python | 3.8+ | Python 3.10+ empfohlen |
| PyYAML | aktuell | Installation über `pip` |
| OpenSSL | beliebig | Für Zertifikatsverarbeitung |
| xmllint | optional | Für XML-Validierung |

### Installation

```bash
# Repository klonen (falls noch nicht geschehen)
cd /opt/git/opendesk-edu

# Virtuelle Umgebung erstellen und aktivieren
python3 -m venv venv
source venv/bin/activate  # Unter Windows: venv\Scripts\activate

# Abhängigkeiten installieren
pip install --upgrade pip
pip install -r scripts/saml-metadata-generator/requirements.txt
```

### Konfiguration

1. Kopieren Sie die Beispielkonfigurationsdatei:

   ```bash
   cp scripts/saml-metadata-generator/saml-metadata-generator-config.yaml.example \
      scripts/saml-metadata-generator/saml-metadata-generator-config.yaml
   ```

2. Bearbeiten Sie die Konfigurationsdatei und passen Sie folgende Abschnitte an:

   - **`organization`**: Name, Anzeigename, URL und Hauptsprache Ihrer Einrichtung
   - **`contacts`**: Technische, administrative und Support-Kontaktdaten
   - **`requested_attributes`**: DFN-AAI/eduGAIN-Attribute, die Ihr Dienst benötigt
   - **`environments`**: Umgebungsspezifische Einstellungen (Dev, Staging, Produktion) inkl. Basis-URL, Entity-ID, ACS/SLO-URLs und Zertifikatspfade
   - **`dfn_aai`**: Föderationsspezifische URLs für Test, Produktion und eduGAIN

   Detaillierte Kommentare zu jedem Feld finden Sie in `saml-metadata-generator-config.yaml.example`.

### Verwendung

#### Metadaten für eine bestimmte Umgebung generieren

```bash
# Entwicklungsumgebung
python3 scripts/saml-metadata-generator/saml-metadata-generator.py \
  -c scripts/saml-metadata-generator/saml-metadata-generator-config.yaml \
  -e dev \
  -o metadata-dev.xml

# Staging-Umgebung
python3 scripts/saml-metadata-generator/saml-metadata-generator.py \
  -c scripts/saml-metadata-generator/saml-metadata-generator-config.yaml \
  -e staging \
  -o metadata-staging.xml

# Produktionsumgebung
python3 scripts/saml-metadata-generator/saml-metadata-generator.py \
  -c scripts/saml-metadata-generator/saml-metadata-generator-config.yaml \
  -e production \
  -o metadata-production.xml
```

#### Metadaten für alle Umgebungen generieren

```bash
python3 scripts/saml-metadata-generator/saml-metadata-generator.py \
  -c scripts/saml-metadata-generator/saml-metadata-generator-config.yaml \
  --all
```

Dadurch werden `metadata-dev.xml`, `metadata-staging.xml` und `metadata-production.xml` im aktuellen Verzeichnis erstellt.

#### Vorhandene Metadaten-Datei validieren

```bash
python3 scripts/saml-metadata-generator/saml-metadata-generator.py \
  --validate metadata-dev.xml
```

### DFN-AAI-spezifische Optionen

Der Generator enthält DFN-AAI-spezifische Konfiguration im Abschnitt `dfn_aai` der Konfigurationsdatei:

| Föderation | Metadaten-URL | Registrierungs-URL |
|------------|---------------|-------------------|
| Test | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` | `https://test.aai.dfn.de/metadata/` |
| Produktion | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Basic-metadata.xml` | `https://www.aai.dfn.de/en/service/metadata/` |
| eduGAIN | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-edugain-metadata.xml` | `https://technical.edugain.org/` |

**DFN-AAI-Pflichtattribute** (5 erforderlich):

- `mail` — E-Mail-Adresse des Benutzers
- `displayName` — Anzeigename des Benutzers
- `eduPersonPrincipalName` — Persistente eindeutige Kennung
- `eduPersonAffiliation` — Benutzerrolle (student/faculty/staff/member)
- `eduPersonTargetedID` — Datenschutzfreundliche persistente Kennung

### Ausgabebeschreibung

Die generierte XML-Metadatendatei enthält:

- **EntityDescriptor** mit Ihrer konfigurierten Entity-ID
- **SPSSODescriptor** mit SAML 2.0-Protokollunterstützung
- **KeyDescriptor** mit Ihren Signatur-/Verschlüsselungszertifikaten
- **AssertionConsumerService**-Endpunkt (HTTP-POST-Binding)
- **SingleLogoutService**-Endpunkt (HTTP-Redirect-Binding)
- **NameIDFormat**-Deklarationen (persistent, transient, E-Mail)
- **AttributeConsumingService** mit allen angeforderten Attributen (zweisprachig Deutsch/Englisch)
- **Organisationsinformationen** (zweisprachig Deutsch/Englisch)
- **ContactPerson**-Einträge (technisch, administrativ, Support)

### Validierungsanleitung

1. **XML-Strukturprüfung** — automatisch vom Generator durchgeführt:

   ```bash
   python3 scripts/saml-metadata-generator/saml-metadata-generator.py --validate metadata-dev.xml
   ```

2. **Externe Validierung mit xmllint** (falls installiert):

   ```bash
   xmllint --noout metadata-dev.xml
   ```

3. **Manuelle Überprüfung** — Datei öffnen und prüfen:
   - `entityID` entspricht der beabsichtigten Kennung
   - Organisationsname und Kontaktdaten sind korrekt
   - Alle Endpunkte verwenden HTTPS mit Ihrer tatsächlichen Domain
   - Zertifikat ist korrekt eingebettet
   - Alle 5 erforderlichen DFN-AAI-Attribute sind aufgelistet

### Fehlerbehebung

| Problem | Ursache | Lösung |
|---------|---------|--------|
| `Configuration file not found` | Konfigurationsdateipfad falsch oder nicht aus Beispiel kopiert | `saml-metadata-generator-config.yaml.example` nach `saml-metadata-generator-config.yaml` kopieren und `-c` mit korrektem Pfad verwenden |
| `Certificate file not found` | Zertifikatspfad in der Konfiguration ist falsch | Zertifikatspfade im Abschnitt `environments.*.certificates` überprüfen |
| `Environment 'xxx' not found` | Umgebungsname stimmt nicht mit Konfiguration überein | Einen der folgenden Werte verwenden: `dev`, `staging`, `production` |
| `XML validation failed` | Generierte Metadaten haben strukturelle Probleme | Konfiguration auf fehlende Pflichtfelder prüfen (organization, contacts, entity_id) |
| YAML-Parsing-Fehler | Konfigurationsdatei hat Syntaxfehler | YAML validieren mit `python3 -c "import yaml; yaml.safe_load(open('config.yaml'))"` |

### Verwandte Dokumentation

- [DFN-AAI-Registrierungsleitfaden](../../docs/dfn-aai-registration.md)
- [eduGAIN-Attribut-Mapping-Referenz](../../docs/edugain-attribute-mapping.md)
- [Föderations-Fehlerbehebungsleitfaden](../../docs/federation-troubleshooting.md)
