<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# DFN-AAI Federation Enrollment Guide

This guide explains how to register your openDesk Edu deployment with the DFN-AAI (German National Research and Education Network) identity federation, enabling SAML-based single sign-on from institutional identity providers across Germany and the eduGAIN federation.

<!-- TOC -->
* [DFN-AAI Federation Enrollment Guide](#dfn-aai-federation-enrollment-guide)
  * [Overview](#overview)
  * [Prerequisites](#prerequisites)
    * [Required Accounts and Access](#required-accounts-and-access)
    * [Certificates](#certificates)
    * [Network Requirements](#network-requirements)
  * [Step-by-Step Enrollment](#step-by-step-enrollment)
    * [Step 1: Generate SAML Metadata](#step-1-generate-saml-metadata)
    * [Step 2: Validate Generated Metadata](#step-2-validate-generated-metadata)
    * [Step 3: Register with DFN-AAI](#step-3-register-with-dfn-aai)
    * [Step 4: Configure Keycloak as Identity Provider](#step-4-configure-keycloak-as-identity-provider)
    * [Step 5: Configure Keycloak as Service Provider](#step-5-configure-keycloak-as-service-provider)
    * [Step 6: Test Federation Access](#step-6-test-federation-access)
  * [Required Certificates and Endpoints](#required-certificates-and-endpoints)
    * [SAML Signing/Encryption Certificates](#saml-signingencryption-certificates)
    * [SAML Endpoints](#saml-endpoints)
    * [DFN-AAI Federation Endpoints](#dfn-aai-federation-endpoints)
  * [Attribute Mapping](#attribute-mapping)
  * [Troubleshooting](#troubleshooting)
    * [Registration Issues](#registration-issues)
    * [Attribute Mapping Problems](#attribute-mapping-problems)
    * [Login Failures](#login-failures)
    * [Certificate Problems](#certificate-problems)
  * [Test vs Production Federation](#test-vs-production-federation)
<!-- TOC -->

## Overview

DFN-AAI enables single sign-on access to research and education services across Germany. By registering openDesk Edu as a Service Provider (SP), users can log in using institutional credentials from any DFN-AAI or eduGAIN participating organization.

This guide covers:

* Generating SAML service provider metadata
* Registering with DFN-AAI test and production federations
* Configuring Keycloak for SAML federation
* Testing federation access with institutional identities

> [!important]
> This guide assumes you have access to a DFN-AAI registration account. Contact your institution's IT department or DFN-AAI support at [support@aai.dfn.de](mailto:support@aai.dfn.de) if you need federation enrollment.

## Prerequisites

Before starting the enrollment process, ensure you have the following prerequisites in place.

### Required Accounts and Access

| Item | Description | How to Obtain |
|------|-------------|---------------|
| DFN-AAI Registration Account | Access to DFN-AAI metadata registration portal | Contact DFN-AAI support at [support@aai.dfn.de](mailto:support@aai.dfn.de) |
| DFN-AAI Test Federation Access | Access to test federation for initial testing | Automatic with registration account |
| Keycloak Admin Access | Administrative access to Keycloak console | Deployed with openDesk Edu |
| DNS Control | Ability to configure DNS records for your domain | Your institution's DNS management |

### Certificates

You need an X.509 certificate for signing SAML requests and encrypting assertions.

**For Testing:**

* Self-signed certificates are acceptable for DFN-AAI test federation
* Use the `--generate-cert` option with the metadata generation script

**For Production:**

* CA-signed certificates from your institution's PKI are required
* Certificate validity should be at least 1 year
* Private keys must be stored securely

### Network Requirements

* All SAML endpoints must be accessible via HTTPS
* TLS certificates must be valid and not expired
* Firewall rules must allow inbound HTTPS traffic to Keycloak endpoints
* Outbound HTTPS access to DFN-AAI services is required

## Step-by-Step Enrollment

### Step 1: Generate SAML Metadata

Use the provided metadata generation script to create SAML service provider metadata for your openDesk Edu deployment.

#### Generate with Self-Signed Certificate (Test Federation)

```bash
cd /opt/git/opendesk-edu

./scripts/federation/generate-metadata.sh \
    -d education.example.org \
    -e "https://idp.education.example.org/realms/opendesk" \
    --generate-cert \
    --org-name "Example University" \
    --org-display "Example University Education Platform" \
    --tech-email edu-support@example.org \
    -o /tmp/dfn-aai-metadata.xml
```

This generates:

* `sp-cert.pem`: Self-signed certificate (default 365 days valid)
* `sp-key.pem`: Private key
* `/tmp/dfn-aai-metadata.xml`: SAML 2.0 metadata for DFN-AAI registration

#### Generate with CA-Signed Certificates (Production)

```bash
cd /opt/git/opendesk-edu

./scripts/federation/generate-metadata.sh \
    -d education.example.org \
    -e "https://idp.education.example.org/realms/opendesk" \
    -c /etc/pki/tls/certs/keycloak-sp.crt \
    -k /etc/pki/tls/private/keycloak-sp.key \
    --org-name "Example University" \
    --org-display "Example University Education Platform" \
    --tech-email edu-support@example.org \
    -o /tmp/dfn-aai-metadata.xml
```

> [!note]
> Replace `education.example.org` with your actual domain and adjust organization details to match your institution's information.

### Step 2: Validate Generated Metadata

Before submitting metadata to DFN-AAI, validate the generated file.

#### Check XML Syntax

```bash
xmllint --noout /tmp/dfn-aai-metadata.xml && echo "✓ XML is valid"
```

#### Verify Certificate Validity

```bash
openssl x509 -in sp-cert.pem -noout -dates
# Verify the certificate is not expired and has sufficient validity
```

#### Review Metadata Contents

```bash
cat /tmp/dfn-aai-metadata.xml
```

Verify the following:

* `entityID` matches your intended SAML entity identifier
* Organization name and contact information are correct
* All endpoints reference your domain with HTTPS
* Certificate is properly embedded in the metadata
* Required attributes are listed in `AttributeConsumingService`

### Step 3: Register with DFN-AAI

Submit your metadata to DFN-AAI through their registration portal.

#### Access Registration Portal

Navigate to the [DFN-AAI metadata registration portal](https://www.aai.dfn.de/en/service/metadata/).

#### Complete Registration Form

1. **Service Information**
   * EntityID (from your metadata)
   * Service name (Organization display name)
   * Service description (Brief description of your education platform)

2. **Technical Details**
   * Upload the `dfn-aai-metadata.xml` file
   * Provide contact information for federation administrators
   * Specify whether registering for test or production federation

3. **Attribute Requirements**
   * Confirm required attributes are included:
     * `eduPersonAffiliation`
     * `mail`
     * `displayName`
     * `eduPersonPrincipalName`

4. **Support Contact**
   * Technical contact email
   * Administrative contact email

#### Submit for Approval

After completing the form, submit your registration request. DFN-AAI will:

* Validate your metadata format
* Verify endpoint accessibility
* Review certificate validity
* Approve or request corrections

Approval typically takes 1-3 business days. You will receive an email notification when your registration is approved.

> [!important]

* Start with the test federation to validate your configuration
* Move to production federation only after successful testing

### Step 4: Configure Keycloak as Identity Provider

After DFN-AAI approval, configure Keycloak to recognize DFN-AAI as an external identity provider.

#### Access Keycloak Admin Console

```bash
# Login to Keycloak pod (adjust namespace as needed)
kubectl -n opendesk exec -it ums-keycloak-0 -- bash

# Use kcadm.sh CLI or access via web console:
# https://idp.example.org/admin/master/console/
```

Default admin credentials:

* Username: `kcadmin`
* Password: Check `KEYCLOAK_ADMIN_PASSWORD` environment variable in the Keycloak pod

#### Import DFN-AAI Metadata

1. Navigate to **Realm Settings** > **Identity Providers** > **Add provider** > **SAML v2.0 IdP**

2. Configure:

   | Field | Test Federation | Production Federation |
   |-------|----------------|----------------------|
   | Alias | `dfn-aai-test` | `dfn-aai` |
   | Display Name | DFN-AAI (Test) | DFN-AAI |
   | Entity ID | `https://www.aai.dfn.de/idp/shibboleth` | `https://www.aai.dfn.de/idp/shibboleth` |
   | Single Sign-On Service URL | `https://idp.test.aai.dfn.de/idp/profile/SAML2/Redirect/SSO` | `https://idp.aai.dfn.de/idp/profile/SAML2/Redirect/SSO` |
   | Single Logout Service URL | `https://idp.test.aai.dfn.de/idp/profile/SAML2/Redirect/SLO` | `https://idp.aai.dfn.de/idp/profile/SAML2/Redirect/SLO` |

3. **Import Metadata**:

   For test federation:

   ```url
   https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml
   ```

   For production federation:

   ```url
   https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Basic-metadata.xml
   ```

4. Click **Import** to load federation metadata

#### Configure Attribute Mapping

Create attribute mappers to translate DFN-AAI attributes to Keycloak user attributes.

Navigate to **Identity Providers** > **DFN-AAI** > **Add mapper** > **User Attribute**:

| DFN-AAI Attribute | Friendly Name | Keycloak User Attribute |
|-------------------|---------------|------------------------|
| `urn:mace:dir:attribute-def:eduPersonAffiliation` | affiliation | `affiliation` |
| `urn:mace:dir:attribute-def:mail` | mail | `email` |
| `urn:mace:dir:attribute-def:displayName` | displayName | `firstName` |
| `urn:mace:dir:attribute-def:eduPersonPrincipalName` | persistentID | `username` |

#### Enable Identity Provider

* Set **First Login Flow** to `first broker login` (or custom flow)
* Check **Enabled** to activate the identity provider
* Click **Save**

### Step 5: Configure Keycloak as Service Provider

Configure Keycloak realm SAML settings to act as a service provider for DFN-AAI.

#### Navigate to Realm SAML Settings

1. Go to **Realm Settings** > **SSO** > **Identity Provider Settings**
2. Add SAML 2.0 Identity Provider Settings

#### Import Your SP Metadata

Import the metadata file generated in Step 1:

1. Click **Import** and select `dfn-aai-metadata.xml`
2. Review the imported configuration

#### Configure SAML Settings

| Setting | Value |
|---------|-------|
| Name ID Format | `urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified` |
| Validate Signature | `On` |
| Sign Documents | `On` |
| Want Assertions Signed | `On` |
| Want Assertions Encrypted | `Off` (optional, requires encryption cert exchange) |

#### Download Updated Metadata

After importing into Keycloak SAML settings, the metadata may have been updated with logout endpoints:

```url
https://idp.education.example.org/realms/opendesk/protocol/saml/descriptor
```

If the metadata differs significantly from your initial version:

1. Download the updated metadata from Keycloak
2. Re-submit the updated metadata to DFN-AAI portal

### Step 6: Test Federation Access

Validate that users can authenticate through the DFN-AAI federation.

#### Access via Discovery Service

1. Navigate to the DFN-AAI discovery service:

   ```
   https://discovery.aai.dfn.de/
   ```

2. In the **Return to** field, enter your Keycloak SAML endpoint:

   ```
   https://idp.education.example.org/realms/opendesk/protocol/saml
   ```

3. Select your institution from the list (test federation shows test institutions)

4. Login with institutional credentials

#### Verify Attribute Mapping

After successful login, verify that attributes are correctly mapped:

1. Navigate to **Users** in Keycloak admin console
2. Locate the federated user
3. View user attributes
4. Confirm:
   * `firstName` contains display name value
   * `email` contains mail attribute
   * `username` contains persistent ID
   * `affiliation` contains affiliation value

#### Test Application Access

1. Access an openDesk Edu application (ILIAS, Moodle, etc.)
2. Choose DFN-AAI or institutional login
3. Verify successful authentication and attribute mapping

> [!tip]

* Use browser developer tools to inspect SAML responses if troubleshooting
* Check Keycloak logs for federation authentication events
* Verify attribute mapper configuration if attributes are missing

## Required Certificates and Endpoints

### SAML Signing/Encryption Certificates

| Certificate | Purpose | Required For |
|------------|---------|--------------|
| SP Signing Certificate | Signs SAML authentication requests | DFN-AAI registration, IdP trust |
| SP Encryption Certificate | Encrypts SAML assertions from IdP | Secure attribute transfer (optional) |

**Certificate Requirements:**

* X.509 format in PEM encoding
* RSA key size: 2048 bits or greater
* Validity period: At least 365 days for production
* Subject Alternative Name: Not required for SAML SP certificates
* Key usage: Digital signature, non-repudiation

**Key Management:**

* Store private keys with restricted access (`chmod 600`)
* Never commit private keys to version control
* Rotate certificates before expiration (DFN-AAI requires 30-day notice)

### SAML Endpoints

The generated metadata includes these Keycloak SAML 2.0 endpoints:

| Endpoint Type | Binding | Location |
|---------------|---------|----------|
| Single Sign-On Service | HTTP-POST | `https://idp.<domain>/realms/opendesk/protocol/saml` |
| Single Sign-On Service | HTTP-Redirect | `https://idp.<domain>/realms/opendesk/protocol/saml` |
| Single Sign-On Service | SOAP | `https://idp.<domain>/realms/opendesk/protocol/saml` |
| Single Logout Service | HTTP-Redirect | `https://idp.<domain>/realms/opendesk/protocol/saml` |
| Single Logout Service | HTTP-POST | `https://idp.<domain>/realms/opendesk/protocol/saml` |
| Single Logout Service | SOAP | `https://idp.<domain>/realms/opendesk/protocol/saml` |
| Assertion Consumer Service | HTTP-POST | `https://idp.<domain>/realms/opendesk/protocol/saml` |
| Assertion Consumer Service | HTTP-Artifact | `https://idp.<domain>/realms/opendesk/protocol/saml` |
| Metadata Descriptor | N/A | `https://idp.<domain>/realms/opendesk/protocol/saml/descriptor` |

### DFN-AAI Federation Endpoints

| Environment | Metadata URL | Discovery Service |
|------------|--------------|-------------------|
| Test Federation | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` | `https://discovery.aai.dfn.de/` |
| Production Federation | `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Basic-metadata.xml` | `https://discovery.aai.dfn.de/` |

## Attribute Mapping

DFN-AAI and eduGAIN use standardized attribute names based on the eduPerson schema.

### Required Attributes

| Attribute Name | SAML Attribute Name | Friendly Name | Description | Example Value |
|----------------|---------------------|--------------|-------------|---------------|
| Email Address | `urn:mace:dir:attribute-def:mail` | `mail` | Primary email address | `student@university.edu` |
| Display Name | `urn:mace:dir:attribute-def:displayName` | `displayName` | User's preferred display name | `Dr. Jane Smith` |
| Affiliation | `urn:mace:dir:attribute-def:eduPersonAffiliation` | `affiliation` | User's role at institution | `faculty`, `student`, `staff`, `member` |
| Persistent ID | `urn:mace:dir:attribute-def:eduPersonPrincipalName` | `persistentID` | Unique, persistent identifier | `student@university.edu` |

### Optional Attributes

| Attribute Name | SAML Attribute Name | Friendly Name | Description | Example Value |
|----------------|---------------------|--------------|-------------|---------------|
| Scoped Affiliation | `urn:mace:dir:attribute-def:eduPersonScopedAffiliation` | `scopedAffiliation` | Affiliation with institution scope | `student@university.edu` |
| Entitlement | `urn:mace:dir:attribute-def:eduPersonEntitlement` | `entitlement` | Service-based entitlements | `urn:mace:example.edu:entitlements:library` |

### Keycloak Mapper Configuration

Configure attribute mappers in Keycloak to translate federation attributes to user attributes:

1. Navigate to **Identity Providers** > **DFN-AAI** > **Mappers**
2. Click **Add mapper** > **User Attribute**
3. Configure:
   * **Name**: Descriptive mapper name (e.g., "Email Mapper")
   * **User Attribute**: Target Keycloak attribute (e.g., `email`)
   * **SAML Attribute Name**: Source federation attribute (e.g., `urn:mace:dir:attribute-def:mail`)
   * **Friendly Name**: Human-readable name (e.g., `mail`)
   * **SAML Attribute NameFormat**: `urn:oasis:names:tc:SAML:2.0:attrname-format:uri`
4. Click **Save**

## Troubleshooting

### Registration Issues

#### Metadata Validation Fails

**Symptom:** DFN-AAI portal rejects metadata with validation errors

**Solutions:**

1. **Check XML Syntax**

   ```bash
   xmllint --noout /tmp/dfn-aai-metadata.xml
   ```

2. **Verify Certificate Format**

   ```bash
   openssl x509 -in sp-cert.pem -noout -text
   # Verify certificate is valid and not expired
   ```

3. **Check EntityID Format**
   * Must be a valid HTTPS URL
   * Must use your actual domain
   * DNS must resolve to your institution's IP

4. **Verify All Required Attributes**
   * Ensure all four required attributes are present
   * Check attribute names use correct URI format
   * Confirm friendly names match DFN-AAI specifications

#### Registration Pending Approval

**Symptom:** Registration submitted but awaiting approval for extended period

**Checklist:**

* [ ] Verify email contact information is correct
* [ ] Check spam folder for DFN-AAI communications
* [ ] Confirm metadata file was successfully uploaded
* [ ] Double-check institution has valid DFN-AAI subscription
* [ ] Contact DFN-AAI support: [support@aai.dfn.de](mailto:support@aai.dfn.de)

### Attribute Mapping Problems

#### User Attributes Not Populated

**Symptom:** User logs in successfully but attributes are missing or incorrect

**Solutions:**

1. **Verify Attribute Release at IdP**
   * Contact institutional IdP administrator
   * Confirm required attributes are released to this SP
   * Check IdP logs for attribute release denials

2. **Check Keycloak Mapper Configuration**
   * Navigate to **Identity Providers** > **DFN-AAI** > **Mappers**
   * Verify all required attributes have mappers
   * Check mapper target attributes match Keycloak user profile

3. **Inspect SAML Response**
   * Use browser developer tools (Network tab)
   * Examine SAML assertion from DFN-AAI IdP
   * Confirm attributes are present in the assertion

4. **Review Keycloak Logs**

   ```bash
   # Check Keycloak authentication logs
   kubectl -n opendesk logs deployment/ums-keycloak --tail=100
   ```

#### Incorrect Affiliation Values

**Symptom:** Affiliation attribute contains unexpected values

**Diagnosis:**

1. Review DFN-AAI attribute specifications:
   * Valid values: `faculty`, `student`, `staff`, `member`, `alum`, `affiliate`, `library-walk-in`

2. Check institutional IdP configuration:
   * IdP may return multiple affiliation values
   * First value is typically the primary affiliation
   * Contact IdP administrator for attribute mapping explanation

3. Configure Keycloak mapper logic:
   * Use **Script Mapper** for custom attribute processing
   * Extract specific affiliation from multi-valued attributes

### Login Failures

#### "Invalid Signature" Error

**Symptom:** Authentication fails with signature validation error

**Solutions:**

1. **Verify Certificate Synchronization**
   * Ensure SP signing certificate matches what DFN-AAI has on record
   * Re-submit updated metadata if certificate was rotated

2. **Check Keycloak Signature Validation**
   * Navigate to **Identity Providers** > **DFN-AAI**
   * Verify signature validation is enabled
   * Check if DFN-AAI IdP certificate was imported correctly

3. **Validate Time Synchronization**

   ```bash
   # Ensure Keycloak system clock is synchronized
   timedatectl status
   ```

#### "No Endpoint Available" Error

**Symptom:** Redirect fails with endpoint not found error

**Solutions:**

1. **Verify Endpoint Accessibility**

   ```bash
   curl -I https://idp.education.example.org/realms/opendesk/protocol/saml
   ```

2. **Check Federation Metadata**
   * Confirm ACS URL in metadata matches expected endpoint
   * Verify binding type is supported by Keycloak

3. **Review Ingress Configuration**
   * Ensure Kubernetes ingress routes traffic to Keycloak
   * Check TLS certificate is valid for the endpoint

### Certificate Problems

#### Certificate Expired

**Symptom:** Federation login fails due to expired certificate

**Recovery Process:**

1. **Generate New Certificate**

   ```bash
   ./scripts/federation/generate-metadata.sh \
       -d education.example.org \
       --generate-cert \
       --cert-days 730
   ```

2. **Update Keycloak Configuration**
   * Import new certificate in Keycloak SAML settings
   * Download updated metadata from Keycloak

3. **Re-submit to DFN-AAI**
   * Update metadata in DFN-AAI registration portal
   * Provide 30-day notice for certificate changes

4. **Notify Users**
   * Communicate certificate rotation to federation partners
   * Monitor for login failures during transition

#### Self-Signed Certificate Rejected

**Symptom:** DFN-AAI rejects self-signed certificate for production federation

**Solution:**

* Use CA-signed certificates from your institution's PKI
* Contact your IT security team for certificate issuance
* Export certificate in PEM format for metadata generation

## Test vs Production Federation

### Test Federation

**Purpose:** Validate configuration without risk of production disruption

**Characteristics:**

* Contains test institutional identity providers
* Lower security requirements (self-signed TLS allowed)
* Faster approval process
* Suitable for development and testing

**When to Use:**

* Initial configuration testing
* Attribute mapping validation
* Integration development
* Training and demonstrations

**Migration Path:**

* Configurations from test federation can be adapted for production
* Re-register SP metadata with production federation URL
* Update Keycloak IdP configuration to production endpoints

### Production Federation

**Purpose:** Provide production SSO access for real users

**Characteristics:**

* Contains institutional identity providers from DFN-AAI and eduGAIN
* Strict security requirements (CA-signed TLS required)
* Formal approval process
* Supports production workloads

**When to Use:**

* Production deployments
* Federation with institutional IdPs
* User-facing authentication
* Academic term start (semester onboarding)

**Migration Checklist:**

* [ ] Complete successful testing with test federation
* [ ] Obtain CA-signed certificates from institution PKI
* [ ] Re-generate metadata with production certificates
* [ ] Register with production DFN-AAI federation
* [ ] Update Keycloak IdP configuration to production endpoints
* [ ] Update attribute mappers if required
* [ ] Perform end-to-end testing with production credentials
* [ ] Communicate availability to users and support teams

> [!important]
DFN-AAI requires separate registrations for test and production federations. Configure your deployment to support both environments by maintaining separate Keycloak realms or identity provider configurations.

---

## Additional Resources

* **DFN-AAI Documentation:** <https://www.aai.dfn.de/en/documentation/>
* **eduGAIN Technical Profile:** <https://technical.edugain.org/>
* **Keycloak SAML Documentation:** <https://www.keycloak.org/docs/latest/server_admin/#identity-broker-saml>
* **DFN-AAI Support:** [support@aai.dfn.de](mailto:support@aai.dfn.de)
* **OpenDesk Edu GitHub:** <https://github.com/opendesk-edu/opendesk-edu/issues>
