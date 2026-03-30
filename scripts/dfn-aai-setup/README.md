# SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# DFN-AAI Federation Setup Scripts

[English](#english) | [Deutsch](#deutsch)

<a name="english"></a>
## English

### Overview

This directory contains setup scripts for configuring Keycloak as a SAML Service Provider within the DFN-AAI / eduGAIN federation. These scripts enable federated login for 200+ German universities and 80+ international institutions via eduGAIN.

### Scripts

| Script | Description |
|--------|-------------|
| `setup-keycloak-idp.sh` | Configure Keycloak SAML Identity Provider for DFN-AAI/eduGAIN |
| `setup-attribute-mappers.sh` | Create SAML attribute mappers for eduGAIN attributes |
| `setup-role-mapper.sh` | Create role assignment mapper based on eduPersonAffiliation |
| `validate-metadata.sh` | Validate SAML metadata for DFN-AAI compliance |

### Quick Start

```bash
# 1. Configure Keycloak IdP for test federation (always test first!)
./setup-keycloak-idp.sh \
    -e test \
    -u https://id.example.edu \
    --admin-password secret

# 2. Create attribute mappers
./setup-attribute-mappers.sh \
    -p dfn-aai-test \
    -u https://id.example.edu \
    --include-optional \
    --admin-password secret

# 3. Create role mapper
./setup-role-mapper.sh \
    -p dfn-aai-test \
    -u https://id.example.edu \
    --create-roles \
    --admin-password secret

# 4. Validate generated metadata
./validate-metadata.sh --all /path/to/metadata.xml
```

### Prerequisites

- **Keycloak 22+** with SAML 2.0 identity broker support
- **kcadm.sh** in PATH (Keycloak Admin CLI)
- **Network access** to DFN-AAI metadata URLs
- **DFN-AAI membership** (contact support@aai.dfn.de)

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `KC_ADMIN_PASSWORD` | Keycloak admin password | `admin` |
| `KEYCLOAK_URL` | Keycloak base URL | `http://localhost:8080` |

### DFN-AAI Metadata URLs

| Environment | URL |
|-------------|-----|
| Test Federation | `https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-test-metadata.xml` |
| Production | `https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-basic-metadata.xml` |
| eduGAIN | `https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-edugain-metadata.xml` |

### Attribute Mapping

| eduGAIN Attribute | Keycloak Attribute | Required |
|-------------------|-------------------|----------|
| `mail` | `email` | Yes |
| `eduPersonPrincipalName` | `username` | Yes |
| `displayName` | `displayName` | Yes |
| `eduPersonAffiliation` | `affiliation` | Yes |
| `eduPersonTargetedID` | `persistentId` | Yes |
| `givenName` | `firstName` | No |
| `sn` | `lastName` | No |

### Role Mapping

| eduPersonAffiliation | Keycloak Role |
|---------------------|---------------|
| `faculty`, `teacher` | `instructor` |
| `staff`, `employee` | `staff` |
| `student` | `student` |
| `member` | `member` |
| `affiliate` | `affiliate` |
| `alum` | `alumni` |

### Testing

1. **Test Federation First**: Always start with DFN-AAI test federation
2. **Use SAML Tracer**: Browser extension to inspect SAML assertions
3. **Test Users**: Available at `test.aai.dfn.de`
4. **Verify Attributes**: Check all required attributes are received

### Troubleshooting

#### IdP Configuration Fails

```bash
# Check network connectivity
curl -I https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-test-metadata.xml

# Verify Keycloak is running
curl -s https://id.example.edu/realms/opendesk/.well-known/openid-configuration
```

#### Attributes Not Received

1. Contact IdP admin about attribute release policy
2. Use SAML Tracer to inspect assertion
3. Verify mapper configuration: `./setup-attribute-mappers.sh --list`

#### Role Assignment Not Working

1. Check required roles exist: `./setup-role-mapper.sh --create-roles`
2. Verify role mapper script: `./setup-role-mapper.sh --show-script`
3. Check Keycloak logs for role assignment messages

---

<a name="deutsch"></a>
## Deutsch

### Übersicht

Dieses Verzeichnis enthält Einrichtungsskripte für die Konfiguration von Keycloak als SAML Service Provider innerhalb der DFN-AAI / eduGAIN Föderation. Diese Skripte ermöglichen föderiertes Anmelden für über 200 deutsche Universitäten und 80+ internationale Einrichtungen über eduGAIN.

### Skripte

| Skript | Beschreibung |
|--------|---------------|
| `setup-keycloak-idp.sh` | Keycloak SAML Identity Provider für DFN-AAI/eduGAIN konfigurieren |
| `setup-attribute-mappers.sh` | SAML-Attribut-Mapper für eduGAIN-Attribute erstellen |
| `setup-role-mapper.sh` | Rollenzuweisungs-Mapper basierend auf eduPersonAffiliation erstellen |
| `validate-metadata.sh` | SAML-Metadaten auf DFN-AAI-Konformität validieren |

### Schnellstart

```bash
# 1. Keycloak IdP für Testföderation konfigurieren (immer zuerst testen!)
./setup-keycloak-idp.sh \
    -e test \
    -u https://id.beispiel-universitaet.de \
    --admin-password geheim

# 2. Attribut-Mapper erstellen
./setup-attribute-mappers.sh \
    -p dfn-aai-test \
    -u https://id.beispiel-universitaet.de \
    --include-optional \
    --admin-password geheim

# 3. Rollen-Mapper erstellen
./setup-role-mapper.sh \
    -p dfn-aai-test \
    -u https://id.beispiel-universitaet.de \
    --create-roles \
    --admin-password geheim

# 4. Generierte Metadaten validieren
./validate-metadata.sh --all /pfad/zu/metadaten.xml
```

### Voraussetzungen

- **Keycloak 22+** mit SAML 2.0 Identity-Broker-Unterstützung
- **kcadm.sh** im PATH (Keycloak Admin CLI)
- **Netzwerkzugriff** auf DFN-AAI-Metadaten-URLs
- **DFN-AAI-Mitgliedschaft** (Kontakt: support@aai.dfn.de)

### Attribut-Mapping

| eduGAIN-Attribut | Keycloak-Attribut | Erforderlich |
|------------------|-------------------|--------------|
| `mail` | `email` | Ja |
| `eduPersonPrincipalName` | `username` | Ja |
| `displayName` | `displayName` | Ja |
| `eduPersonAffiliation` | `affiliation` | Ja |
| `eduPersonTargetedID` | `persistentId` | Ja |
| `givenName` | `firstName` | Nein |
| `sn` | `lastName` | Nein |

### Rollen-Mapping

| eduPersonAffiliation | Keycloak-Rolle |
|---------------------|----------------|
| `faculty`, `teacher` | `instructor` |
| `staff`, `employee` | `staff` |
| `student` | `student` |
| `member` | `member` |
| `affiliate` | `affiliate` |
| `alum` | `alumni` |

### Testen

1. **Zuerst Testföderation**: Immer mit DFN-AAI-Testföderation beginnen
2. **SAML Tracer verwenden**: Browser-Erweiterung zur Inspektion von SAML-Assertions
3. **Testbenutzer**: Verfügbar unter `test.aai.dfn.de`
4. **Attribute verifizieren**: Prüfen, dass alle erforderlichen Attribute empfangen werden

### Fehlerbehebung

#### IdP-Konfiguration schlägt fehl

```bash
# Netzwerkkonnektivität prüfen
curl -I https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-test-metadata.xml

# Prüfen, ob Keycloak läuft
curl -s https://id.beispiel-universitaet.de/realms/opendesk/.well-known/openid-configuration
```

#### Attribute nicht empfangen

1. IdP-Admin bezüglich Attributfreigaberichtlinie kontaktieren
2. SAML Tracer verwenden, um Assertion zu inspizieren
3. Mapper-Konfiguration verifizieren: `./setup-attribute-mappers.sh --list`

#### Rollenzuweisung funktioniert nicht

1. Prüfen, ob erforderliche Rollen existieren: `./setup-role-mapper.sh --create-roles`
2. Rollen-Mapper-Skript verifizieren: `./setup-role-mapper.sh --show-script`
3. Keycloak-Logs auf Rollenzuweisungsnachrichten prüfen

---

## Related Documentation

- [DFN-AAI Registration Guide](../../docs/dfn-aai-registration.md)
- [eduGAIN Attribute Mapping](../../docs/edugain-attribute-mapping.md)
- [Shibboleth IdP Integration](../../docs/shibboleth-idp-integration.md)

## License

SPDX-License-Identifier: Apache-2.0
