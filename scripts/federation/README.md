# Federation Metadata Generation

Generate SAML 2.0 Service Provider metadata for Keycloak integration with DFN-AAI / eduGAIN federation.

## Overview

This script generates SAML 2.0 metadata XML files required for registering openDesk Edu as a Service Provider in the DFN-AAI federation (German National Research and Education Network's identity federation). The metadata includes:

- SAML SP endpoints (SSO, SLO, ACS)
- X.509 signing/encryption certificates
- Organization and contact information
- Required eduGAIN attributes (eduPersonAffiliation, mail, displayName, persistentId)

## Prerequisites

- Bash shell support
- OpenSSL (for generating self-signed certificates or validating existing ones)
- X.509 certificate in PEM format (or use `--generate-cert` for testing)

## Quick Start

### Generate Metadata with Self-Signed Certificate (Testing)

```bash
./scripts/federation/generate-metadata.sh \
    -d opendesk.example.com \
    --generate-cert
```

This creates:
- `sp-cert.pem`: Self-signed certificate (365 days valid)
- `sp-key.pem`: Private key
- `sp-metadata.xml`: SAML 2.0 metadata

### Generate Metadata with Existing Certificates (Production)

```bash
./scripts/federation/generate-metadata.sh \
    -d your-university.edu \
    -c /path/to/your-sp-cert.pem \
    -k /path/to/your-sp-key.pem \
    -o /output/metadata.xml
```

## Options

| Option | Required | Description | Default |
|--------|----------|-------------|---------|
| `-d, --domain DOMAIN` | Yes | Base domain (e.g., opendesk.example.com) | - |
| `-e, --entity-id ENTITY_ID` | No | SAML entityID | `https://id.<domain>/realms/opendesk` |
| `-c, --cert-path PATH` | No | Path to SP X.509 certificate (PEM) | `./sp-cert.pem` |
| `-k, --key-path PATH` | No | Path to SP private key (PEM) | `./sp-key.pem` |
| `-o, --output-file FILE` | No | Output metadata file | `sp-metadata.xml` |
| `--org-name NAME` | No | Organization name | `openDesk Edu` |
| `--org-display DISPLAY` | No | Organization display name | `University openDesk Education Platform` |
| `--org-url URL` | No | Organization URL | `https://<domain>` |
| `--tech-email EMAIL` | No | Technical support email | `support@<domain>` |
| `--generate-cert` | No | Generate self-signed certificate | false |
| `--cert-days DAYS` | No | Certificate validity days (with --generate-cert) | 365 |
| `--help` | No | Show usage information | - |

## Examples

### Example 1: University Deployment with CA-Signed Certificates

```bash
./scripts/federation/generate-metadata.sh \
    -d university.edu \
    -e "https://idp.university.edu/realms/education" \
    -c /etc/ssl/certs/sp-cert.pem \
    -k /etc/ssl/private/sp-key.pem \
    --org-name "University IT Services" \
    --org-display "University Education Platform" \
    --tech-email idp-admin@university.edu \
    -o /tmp/university-metadata.xml
```

### Example 2: Development Environment with Custom Domain

```bash
./scripts/federation/generate-metadata.sh \
    -d dev.example.com \
    --org-name "Dev Environment" \
    --generate-cert
```

### Example 3: Production Multi-Service Deployment

```bash
./scripts/federation/generate-metadata.sh \
    -d education.example.org \
    -c /etc/pki/tls/certs/keycloak-sp.crt \
    -k /etc/pki/tls/private/keycloak-sp.key \
    --org-name "Education Services" \
    --org-display "Institutional Education Platform" \
    --tech-email security@example.org \
    --org-url "https://education.example.org"
```

## Generated Attributes

The metadata requests the following DFN-AAI/eduGAIN attributes:

| Attribute | Friendly Name | Required | Description |
|-----------|--------------|----------|-------------|
| `eduPersonAffiliation` | affiliation | Yes | User's affiliation (student, faculty, staff, member, etc.) |
| `mail` | mail | Yes | User's primary email address |
| `displayName` | displayName | Yes | User's preferred display name |
| `eduPersonPrincipalName` | persistentID | Yes | Persistent, opaque identifier |
| `eduPersonEntitlement` | entitlement | No | Service-based entitlements |
| `eduPersonScopedAffiliation` | scopedAffiliation | No | Affiliation with scope (e.g., `student@university.edu`) |

## SAML Endpoints

The generated metadata includes these Keycloak SAML 2.0 endpoints:

| Endpoint Type | Binding | Location |
|---------------|---------|----------|
| Single Sign-On Service | HTTP-POST | `https://id.<domain>/realms/opendesk/protocol/saml` |
| Single Sign-On Service | HTTP-Redirect | `https://id.<domain>/realms/opendesk/protocol/saml` |
| Single Sign-On Service | SOAP | `https://id.<domain>/realms/opendesk/protocol/saml` |
| Single Logout Service | HTTP-Redirect | `https://id.<domain>/realms/opendesk/protocol/saml` |
| Single Logout Service | HTTP-POST | `https://id.<domain>/realms/opendesk/protocol/saml` |
| Single Logout Service | SOAP | `https://id.<domain>/realms/opendesk/protocol/saml` |
| Assertion Consumer Service | HTTP-POST | `https://id.<domain>/realms/opendesk/protocol/saml` |
| Assertion Consumer Service | HTTP-Artifact | `https://id.<domain>/realms/opendesk/protocol/saml` |

## DFN-AAI Registration Steps

After generating metadata, follow these steps to register with DFN-AAI:

### 1. Review the Generated Metadata

```bash
cat sp-metadata.xml
```

Verify:
- Correct `entityID`
- Valid certificate chain
- Complete endpoint URLs
- Organization information accuracy

### 2. Submit to DFN-AAI Portal

- Access the [DFN-AAI registration portal](https://www.aai.dfn.de/en/service/metadata/)
- Upload the `sp-metadata.xml` file
- Complete the registration form with technical details
- Provide contact information for federation administrators

### 3. Configure Keycloak Federation

Wait for DFN-AAI approval, then configure Keycloak:

1. Add DFN-AAI as Identity Provider in Keycloak Admin Console
   - Navigate to: Realm → Identity Providers → Add provider → SAML 2.0 IdP
   - Import DFN-AAI metadata from: `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` (test) or `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Basic-metadata.xml` (production)

2. Configure attribute mapping in Keycloak:
   ```json
   {
     "urn:mace:dir:attribute-def:eduPersonAffiliation": "user.attributes.affiliation",
     "urn:mace:dir:attribute-def:mail": "email",
     "urn:mace:dir:attribute-def:displayName": "firstName",
     "urn:mace:dir:attribute-def:eduPersonPrincipalName": "username"
   }
   ```

3. Enable SAML 2.0 identity provider in Keycloak SSO settings

### 4. Keycloak Service Provider Configuration

In the realm SSO settings (Keycloak 26+), import the generated metadata:

1. Navigate to: Realm → Realm Settings → SSO → Identity Provider Settings
2. Add SAML 2.0 Identity Provider Settings
3. Import `sp-metadata.xml`
4. Configure:
   - Enable SAML Identity Provider
   - Set to Accept/Sign mode
   - Configure name ID format: `urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified`

5. Download updated metadata from Keycloak (includes logout endpoints):
   - Endpoint: `https://id.<domain>/realms/opendesk/protocol/saml/descriptor`
   - Update the metadata file and re-submit to DFN-AAI

### 5. Test Federation Access

1. Access Keycloak via Discovery Service:
   ```
   https://discovery.aai.dfn.de/
   ```

2. Select your institution (test federation)
3. Login with institutional credentials
4. Verify that attributes are correctly mapped

## Troubleshooting

### Certificate Issues

**Error**: `Certificate file not found`
- **Solution**: Ensure certificate path is correct, or use `--generate-cert` for testing

**Error**: `Invalid certificate format`
- **Solution**: Certificate must be in PEM format with `BEGIN CERTIFICATE` header

### DFN-AAI Registration Fails

**Issue**: Metadata validation error
- **Solution**:
  - Validate XML syntax: `xmllint --noout sp-metadata.xml`
  - Check certificate validity: `openssl x509 -in sp-cert.pem -noout -dates`
  - Verify all required attributes are present

**Issue**: Domain mismatch
- **Solution**: Ensure `entityID` matches your actual domain and is registered in DNS

### Attribute Mapping Issues

**Issue**: User attributes not populated
- **Solution**: Check Keycloak mappers for the SAML identity provider:
  - Navigate to: Identity Providers → DFN-AAI → Mappers
  - Ensure all required attributes have mappers configured
  - Verify mapper targets match Keycloak user attributes

## Security Considerations

### Certificate Management

- **Production**: Use CA-signed certificates from your university PKI
- **Testing**: Self-signed certificates (`--generate-cert`) are acceptable for test federation
- **Rotation**: Replace certificates before expiration (DFN-AAI typically requires 1-year validity)

### Private Key Protection

- Store private keys securely (file permissions: `chmod 600`)
- Never commit private keys to version control
- Use separate signing/encryption certificates for production

### HTTPS Requirements

- All SAML endpoints must use HTTPS
- TLS certificates must be valid and not expired
- DFN-AAI test federation allows self-signed TLS certificates
- Production federation requires CA-signed TLS certificates

## Related Documentation

- [DFN-AAI Service Description](https://www.aai.dfn.de/en/service/)
- [DFN-AAI Metadata Registration](https://www.aai.dfn.de/en/service/metadata/)
- [eduGAIN Technical Profile](https://technical.edugain.org/)
- [Keycloak SAML documentation](https://www.keycloak.org/docs/latest/server_admin/#identity-broker-saml)

## Example Output

```xml
<?xml version="1.0" encoding="UTF-8"?>
<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                     entityID="https://id.opendesk.example.com/realms/opendesk">
  <md:SPSSODescriptor AuthnRequestsSigned="true"
                      WantAssertionsSigned="true"
                      protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <!-- Endpoints, certificates, organization info, attributes -->
  </md:SPSSODescriptor>
</md:EntityDescriptor>
```

## Help and Support

- Script help: `./scripts/federation/generate-metadata.sh --help`
- Issue tracking: [opendesk-edu GitHub Issues](https://github.com/opendesk-edu/deployment/issues)
- DFN-AAI support: [support@aai.dfn.de](mailto:support@aai.dfn.de)

## License

SPDX-License-Identifier: Apache-2.0