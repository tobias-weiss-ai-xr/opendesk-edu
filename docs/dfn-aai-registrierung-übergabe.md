<!--
SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# DFN-AAI Registrierung: Übergabe für IDM-Kolleginnen und Kollegen

Dieses Dokument beschreibt die Schritte zur Registrierung von openDesk Edu als Service Provider (SP) in der DFN-AAI Föderation. Es ist als Übergabe gedacht, nicht als vollständiges Handbuch.

## Kurzübersicht

DFN-AAI ist die deutsche akademische Identitätsföderation. Über 200 Hochschulen in Deutschland nutzen sie für Single Sign-On. Durch die Registrierung von openDesk Edu als SP können sich Studierende und Lehrende mit ihren bestehenden Hochschul-Zugangsdaten anmelden, ohne dass lokalen Accounts nötig sind. Die Registrierung erfolgt über das DFN-AAI Metadata Portal.

## Benötigte Informationen

Vor der Registrierung müssen folgende Daten vorliegen. Tragen Sie Ihre Werte in die rechte Spalte ein.

### Service Provider

| Feld | Beispiel | Ihr Wert |
|------|----------|----------|
| Entity ID | `https://idp.education.example.org/realms/opendesk` | |
| Dienstname | `openDesk Edu - Musteruniversität` | |
| Dienstbeschreibung | `Digitale Arbeitsplatzplattform für Bildung` | |
| Dienst-URL | `https://portal.education.example.org` | |

### Organisation

| Feld | Beispiel | Ihr Wert |
|------|----------|----------|
| Organisationsname | `Musteruniversität` | |
| Anzeigename | `Musteruniversität Bildungsplattform` | |
| Organisations-URL | `https://www.musteruniversitaet.de` | |
| Technische Kontakt-E-Mail | `idm-tech@musteruniversitaet.de` | |
| Administrative Kontakt-E-Mail | `idm-admin@musteruniversitaet.de` | |

## Technische Endpunkte

Ersetzen Sie `<domain>` durch die Domain Ihrer openDesk Edu Installation.

| Endpunkt | URL |
|----------|-----|
| Assertion Consumer Service (POST) | `https://idp.<domain>/realms/opendesk/protocol/saml` |
| Single Logout Service | `https://idp.<domain>/realms/opendesk/protocol/saml` |
| Metadaten-Deskriptor | `https://idp.<domain>/realms/opendesk/protocol/saml/descriptor` |

## Pflichtattribute

DFN-AAI verlangt, dass Ihr SP diese fünf Attribute anfordert:

| Attribut | SAML-Name | Zweck |
|----------|-----------|-------|
| `mail` | `urn:mace:dir:attribute-def:mail` | E-Mail-Adresse |
| `displayName` | `urn:mace:dir:attribute-def:displayName` | Anzeigename |
| `eduPersonPrincipalName` | `urn:mace:dir:attribute-def:eduPersonPrincipalName` | Persistente eindeutige Kennung |
| `eduPersonAffiliation` | `urn:mace:dir:attribute-def:eduPersonAffiliation` | Rolle (student/faculty/staff/member) |
| `eduPersonTargetedID` | `urn:mace:dir:attribute-def:eduPersonTargetedID` | Datenschutzfreundliche persistente Kennung |

## Schritte zur Registrierung

1. **Metadaten generieren**: Nutzen Sie `scripts/saml-metadata-generator/saml-metadata-generator.py`. Kopieren Sie die Beispielkonfiguration, tragen Sie Ihre Daten ein und generieren Sie die XML-Datei.
2. **Metadaten validieren**: Prüfen Sie mit `--validate` oder `xmllint`. Vergewissern Sie sich, dass Entity ID, Endpunkte, Zertifikat und alle fünf Pflichtattribute korrekt sind.
3. **Bei DFN-AAI einreichen**: Melden Sie sich im Metadata Portal an (URL siehe unten), laden Sie die XML-Datei hoch und füllen Sie das Formular aus. Wählen Sie zuerst die Testföderation.
4. **Keycloak konfigurieren**: Nach der Genehmigung konfigurieren Sie Keycloak mit den Skripten aus `scripts/dfn-aai-setup/`. Stimmen Sie sich dazu mit dem openDesk Edu Team ab.

## Verfügbare Skripte

| Verzeichnis | Zweck |
|-------------|-------|
| `scripts/saml-metadata-generator/` | Python-Skript zur Generierung und Validierung der SAML SP-Metadaten-XML |
| `scripts/dfn-aai-setup/` | Bash-Skripte für Keycloak: IdP einrichten, Attribut-Mapper erstellen, Rollen-Mapper konfigurieren |

## Wichtige URLs

| Zweck | URL |
|-------|-----|
| Testföderation Metadaten | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` |
| Produktion Metadaten | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Basic-metadata.xml` |
| Metadata Portal (Registrierung) | `https://www.aai.dfn.de/en/service/metadata/` |
| Testföderation Registrierung | `https://test.aai.dfn.de/metadata/` |
| Discovery Service | `https://discovery.aai.dfn.de/` |
| DFN-AAI Dokumentation | `https://www.aai.dfn.de/dokumentation/` |

## Support und Weiterführendes

- **DFN-AAI Support**: support@aai.dfn.de
- **Interne Dokumentation**: `docs/dfn-aai-registration.md` (vollständiger Leitfaden), `docs/dfn-aai-testing-guide.md` (Testanleitung)

**Hinweis**: Die Keycloak-Konfiguration sollte in Absprache mit dem openDesk Edu Team erfolgen. Das Team kennt die genaue Realm-Struktur und die erforderlichen Mapper-Einstellungen.
