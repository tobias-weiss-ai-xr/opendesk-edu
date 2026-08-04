<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# DFN-AAI Federation Testing Guide

This guide provides comprehensive testing procedures for validating your openDesk Edu deployment integration with the DFN-AAI identity federation. It covers test scenarios, validation checklists, expected results, and troubleshooting for common issues.

<!-- TOC -->
* [DFN-AAI Federation Testing Guide](#dfn-aai-federation-testing-guide)
  * [Overview](#overview)
  * [Prerequisites](#prerequisites)
    * [Completed Enrollment](#completed-enrollment)
    * [Keycloak Configuration](#keycloak-configuration)
    * [Test Credentials](#test-credentials)
    * [Test Tools](#test-tools)
  * [Test 1: Discovery Service Access](#test-1-discovery-service-access)
    * [Purpose](#purpose-1)
    * [Procedure](#procedure-1)
    * [Expected Results](#expected-results-1)
    * [Validation Checklist](#validation-checklist-1)
    * [Troubleshooting](#troubleshooting-1)
  * [Test 2: Direct IdP Authentication](#test-2-direct-idp-authentication)
    * [Purpose](#purpose-2)
    * [Procedure](#procedure-2)
    * [Expected Results](#expected-results-2)
    * [Validation Checklist](#validation-checklist-2)
    * [Troubleshooting](#troubleshooting-2)
  * [Test 3: Attribute Mapping Validation](#test-3-attribute-mapping-validation)
    * [Purpose](#purpose-3)
    * [Procedure](#procedure-3)
    * [Expected Results](#expected-results-3)
    * [Validation Checklist](#validation-checklist-3)
    * [Troubleshooting](#troubleshooting-3)
  * [Test 4: Application-Level SSO](#test-4-application-level-sso)
    * [Purpose](#purpose-4)
    * [Procedure](#procedure-4)
    * [Expected Results](#expected-results-4)
    * [Validation Checklist](#validation-checklist-4)
    * [Troubleshooting](#troubleshooting-4)
  * [Test 5: Single Logout](#test-5-single-logout)
    * [Purpose](#purpose-5)
    * [Procedure](#procedure-5)
    * [Expected Results](#expected-results-5)
    * [Validation Checklist](#validation-checklist-5)
    * [Troubleshooting](#troubleshooting-5)
  * [Test 6: Error Handling](#test-6-error-handling)
    * [Purpose](#purpose-6)
    * [Procedure](#procedure-6)
    * [Expected Results](#expected-results-6)
    * [Validation Checklist](#validation-checklist-6)
    * [Troubleshooting](#troubleshooting-6)
  * [Test Environment Configuration](#test-environment-configuration)
    * [DFN-AAI Test Federation Attributes](#dfn-aai-test-federation-attributes)
    * [Test Identity Providers](#test-identity-providers)
    * [Test Account Examples](#test-account-examples)
  * [Production Testing Checklist](#production-testing-checklist)
  * [Common Test Failures](#common-test-failures)
    * [SAML Response Errors](#saml-response-errors)
    * [Attribute Release Issues](#attribute-release-issues)
    * [Certificate Errors](#certificate-errors)
    * [Network Connectivity Issues](#network-connectivity-issues)
  * [Performance Testing](#performance-testing)
    * [Load Testing](#load-testing)
    * [Response Time Validation](#response-time-validation)
    * [Resource Monitoring](#resource-monitoring)
  * [Security Testing](#security-testing)
    * [Signature Validation](#signature-validation)
    * [Attribute Encryption](#attribute-encryption)
    * [Replay Attack Prevention](#replay-attack-prevention)
  * [Test Result Documentation](#test-result-documentation)
  * [Integration Testing](#integration-testing)
    * [Shibboleth SP Testing](#shibboleth-sp-testing)
    * [ILIAS Federation Testing](#ilias-federation-testing)
    * [Moodle Federation Testing](#moodle-federation-testing)
  * [Automated Testing](#automated-testing)
    * [SAML Testing Tools](#saml-testing-tools)
    * [Keycloak API Testing](#keycloak-api-testing)
    * [E2E Test Automation](#e2e-test-automation)
<!-- TOC -->

## Overview

This testing guide validates that your openDesk Edu deployment can successfully authenticate users through the DFN-AAI identity federation. The tests verify:

* SAML protocol compliance between Keycloak and DFN-AAI
* Attribute mapping from federation to Keycloak user profiles
* Application-level single sign-on with educational services
* Logout and session management
* Error handling and recovery

**Prerequisite Reading:** Complete the [DFN-AAI Federation Enrollment Guide](./dfn-aai-enrollment.md) before performing these tests.

> [!important]
> Always test with the DFN-AAI test federation before testing with production endpoints. The test federation provides predictable attribute values and test credentials.

## Prerequisites

Before running federation tests, ensure the following prerequisites are met.

### Completed Enrollment

* [ ] DFN-AAI registration approved (test federation) - **[DFN-AAI Enrollment Guide](./dfn-aai-enrollment.md)**
* [ ] SAML metadata submitted and accepted
* [ ] Keycloak configured as SAML service provider
* [ ] DFN-AAI configured as identity provider in Keycloak
* [ ] Attribute mappers created for required attributes
* [ ] DNS configured for federation endpoints

### Keycloak Configuration

* [ ] Realm: `opendesk` (or your custom realm)
* [ ] Identity Provider: `dfn-aai-test` (test) or `dfn-aai` (production)
* [ ] SAML endpoints accessible via HTTPS
* [ ] First login flow configured (typically `first broker login`)
* [ ] Attribute mappers: `affiliation`, `email`, `firstName`, `username`

### Test Credentials

For the DFN-AAI test federation, use the official test identity providers:

**DFN-AAI Test IdP:**

* Entity ID: `https://idp.test.aai.dfn.de/idp/shibboleth`
* Test accounts available via the discovery service
* Attribute values are predictable and documented below

**Institutional Test IdPs:**

* Select any test institution from the discovery service
* Each test IdP provides predefined attributes
* Some test IdPs may require self-registration

### Test Tools

Recommended tools for federation testing:

* **Browser:** Chrome/Firefox with SAML trace add-on
* **Network Tools:** `curl` for endpoint validation
* **Keycloak Admin Console:** User and session inspection
* **SAML Tracer:** Browser extension for SAML message inspection (optional)

## Test 1: Discovery Service Access

### Purpose

Verify that the DFN-AAI discovery service can redirect users to your Keycloak SAML endpoint and that test institutions are available for selection.

### Procedure

#### 1.1 Access Discovery Service

Open the DFN-AAI discovery service in your browser:

```url
https://discovery.aai.dfn.de/
```

#### 1.2 Configure Return URL

In the discovery service form:

1. **Return to (ACS URL):** Enter your Keycloak SAML endpoint

   ```
   https://idp.education.example.org/realms/opendesk/protocol/saml
   ```

2. **Entity ID (optional):** Verify it matches your registered entity ID

   ```
   https://idp.education.example.org/realms/opendesk
   ```

#### 1.3 Select Test Institution

1. Click **Choose your institution**
2. Search for or select a test institution:
   * **Test IdP: "DFN-AAI Test IdP"** (recommended)
   * Any institution with (Test) in the name
3. Click **Continue** or the institution name

#### 1.4 Observe Redirect

Watch the browser address bar to confirm:

1. Discovery service redirects to Keycloak SSO endpoint
2. URL contains ACS URL and SAML request parameters
3. Redirect is to your Keycloak domain (`https://idp.education.example.org`)

### Expected Results

* Discovery service loads without errors
* Return URL field accepts your Keycloak SAML endpoint
* Test institutions list is visible and accessible
* Browser redirects to Keycloak `/protocol/saml` endpoint
* No certificate errors or mixed content warnings
* Redirect contains SAML request (`SAMLRequest` parameter)

### Validation Checklist

* [ ] Discovery service accessible via HTTPS
* [ ] Return URL field accepts your Keycloak endpoint
* [ ] Test institutions appear in the dropdown list
* [ ] Redirect to Keycloak SAML endpoint succeeds
* [ ] No browser console errors
* [ ] SAML request parameter present in URL

### Troubleshooting

#### Discovery Service Not Loading

**Symptom:** Discovery service page shows connection error or timeout

**Solutions:**

1. **Check Network Connectivity**

   ```bash
   curl -I https://discovery.aai.dfn.de/
   # Should return HTTP 200
   ```

2. **Verify DNS Resolution**

   ```bash
   nslookup discovery.aai.dfn.de
   ```

3. **Check Proxy Settings**
   * Ensure outbound HTTPS access is allowed
   * Verify no corporate proxy blocks DFN-AAI domains

#### Return URL Rejected

**Symptom:** Discovery service rejects your Keycloak endpoint

**Solutions:**

1. **Verify Endpoint Format**
   * Must be HTTPS (no HTTP)
   * Must include `/protocol/saml` path
   * Must match registered entity ID domain

2. **Check DFN-AAI Registration**
   * Verify your metadata is approved in DFN-AAI portal
   * Confirm entity ID matches registration exactly

3. **Test with Official Example**

   ```
   https://idp.test.aai.dfn.edu/idp/shibboleth
   ```

#### No Test Institutions Visible

**Symptom:** Discovery service shows empty or limited institution list

**Solutions:**

1. **Verify Test Federation Access**
   * Ensure using test federation (`https://discovery.aai.dfn.de/`)
   * Confirm SP is registered with test federation (not production)

2. **Check Discovery Service Configuration**
   * Some test IdPs require registration
   * DFN-AAI Test IdP should always be available

3. **Browser Selection**
   * Try different browser or incognito mode
   * Check if session cookies are blocked

## Test 2: Direct IdP Authentication

### Purpose

Validate that Keycloak can receive authentication assertions directly from a DFN-AAI identity provider without using the discovery service.

### Procedure

#### 2.1 Initiate SAML Login

Navigate directly to the Keycloak SSO endpoint to initiate federation login:

```url
https://idp.education.example.org/realms/opendesk/protocol/saml
```

Or use the Keycloak login URL with IdP hint:

```url
https://idp.education.example.org/realms/opendesk/protocol/openid-connect/auth?client_id=account-console&redirect_uri=https://idp.education.example.org/realms/opendesk/account&response_type=code&scope=openid&kc_idp_hint=dfn-aai-test
```

#### 2.2 Select Identity Provider

If prompted:

1. Click on **DFN-AAI (Test)** from the login page
2. Or use the identity provider dropdown

#### 2.3 Login with Test Credentials

When redirected to the test identity provider:

1. **DFN-AAI Test IdP:**
   * Username: `testuser1` (or `test1`, `testuser`)
   * Password: Check test IdP documentation or use provided test credentials

2. **Institutional Test IdP:**
   * Use credentials provided by the test institution
   * Some test IdPs allow self-registration

#### 2.4 Confirm SAML Flow

Observe the authentication flow in the browser:

1. Keycloak redirects to test IdP with SAML request
2. Test IdP authenticates the user
3. Test IdP redirects back to Keycloak with SAML assertion
4. Keycloak processes the assertion and redirects to application

### Expected Results

* User successfully authenticates with test credentials
* Browser redirects through SAML protocol (3-4 redirects)
* Keycloak creates or updates federated user account
* User is logged into Keycloak (`/realms/opendesk/account`)
* No SAML validation errors or signature failures
* User session established in Keycloak

### Validation Checklist

* [ ] SAML request generated by Keycloak
* [ ] Test IdP login page loads
* [ ] Authentication with test credentials succeeds
* [ ] SAML assertion returned to Keycloak
* [ ] Keycloak accepts assertion without errors
* [ ] User logged into Keycloak with federated identity
* [ ] Session created in Keycloak sessions list

### Troubleshooting

#### "Invalid Signature" Error

**Symptom:** Keycloak rejects SAML assertion with signature validation failure

**Solutions:**

1. **Check IdP Certificate**
   * Verify DFN-AAI test IdP certificate imported in Keycloak
   * Navigate to **Identity Providers** > **DFN-AAI** > **Import Metadata**
   * Re-import test metadata if certificate changed

2. **Time Synchronization**

   ```bash
   # Ensure system time is synchronized
   timedatectl status
   # Keycloak SAML has strict timestamp validation (5-minute window)
   ```

3. **Attribute Mapper Configuration**
   * Verify required attribute mappers are configured
   * Check SAML attribute names match federation format

#### "No Endpoint Available" Error

**Symptom:** Redirect fails with endpoint not found

**Solutions:**

1. **Verify Endpoint Configuration**
   * Check IdP SSO endpoint in Keycloak configuration
   * Test federation: `https://idp.test.aai.dfn.de/idp/profile/SAML2/Redirect/SSO`
   * Production federation: `https://idp.aai.dfn.de/idp/profile/SAML2/Redirect/SSO`

2. **Test Endpoint Accessibility**

   ```bash
   curl -I https://idp.test.aai.dfn.de/idp/profile/SAML2/Redirect/SSO
   # Should return HTTP 200
   ```

3. **Check Metadata Import**
   * Verify DFN-AAI metadata imported successfully
   * Confirm ACS URL matches Keycloak endpoint

#### User Not Created in Keycloak

**Symptom:** Authentication succeeds but no user account created

**Solutions:**

1. **Check First Login Flow**
   * Navigate to **Identity Providers** > **DFN-AAI**
   * Verify **First Login Flow** is set to `first broker login`
   * Confirm flow creates users (not just links accounts)

2. **Review Keycloak Logs**

   ```bash
   kubectl -n opendesk logs deployment/ums-keycloak --tail=100 | grep -i federation
   ```

3. **Attribute Mapping Issues**
   * Verify `username` mapper is configured (required for user creation)
   * Check `username` attribute is provided by test IdP

## Test 3: Attribute Mapping Validation

### Purpose

Verify that all required DFN-AAI attributes are correctly mapped from the SAML assertion to Keycloak user attributes.

### Procedure

#### 3.1 Enable SAML Tracing

1. Install SAML tracer add-on (Chrome/Firefox)
2. Clear browser cache and cookies
3. Enable tracing before initiating federation login

#### 3.2 Authenticate and Capture

1. Initiate federation login through discovery service or direct IdP
2. Complete authentication with test credentials
3. Keep SAML tracer open to capture the assertion

#### 3.3 Inspect SAML Assertion

In the SAML tracer:

1. Click on the last SAML response (`SAMLResponse`)
2. Expand the assertion XML
3. Locate the `<AttributeStatement>` section
4. Verify attributes are present:

   ```xml
   <saml:Attribute Name="urn:mace:dir:attribute-def:mail">
     <saml:AttributeValue>testuser1@test-idp.dfn.de</saml:AttributeValue>
   </saml:Attribute>
   <saml:Attribute Name="urn:mace:dir:attribute-def:displayName">
     <saml:AttributeValue>Test User One</saml:AttributeValue>
   </saml:Attribute>
   ```

#### 3.4 Verify Keycloak User Attributes

1. Navigate to **Users** in Keycloak admin console
2. Search for the federated user
3. Click on the user
4. Select the **Attributes** tab
5. Verify mapped attributes:

   | Keycloak Attribute | Expected Value | Source Federation Attribute |
   |--------------------|----------------|----------------------------|
   | `firstName` | Display name from IdP | `displayName` |
   | `email` | Email address from IdP | `mail` |
   | `username` | Persistent ID | `eduPersonPrincipalName` |
   | `affiliation` | User affiliation | `eduPersonAffiliation` |

#### 3.5 Verify Identity Provider Link

1. In user details, click **Federated Identities**
2. Confirm DFN-AAI identity is linked
3. Verify identity provider federation ID matches expected persistent ID

### Expected Results

* SAML assertion includes all required attributes
* Attribute names match DFN-AAI/eduGAIN specification (URN format)
* Attribute values match test IdP expectations
* Keycloak user account created with correct attribute mappings
* Federated identity linked to user
* No attribute processing errors in Keycloak logs

### Validation Checklist

* [ ] SAML assertion contains `mail` attribute
* [ ] SAML assertion contains `displayName` attribute
* [ ] SAML assertion contains `eduPersonAffiliation` attribute
* [ ] SAML assertion contains `eduPersonPrincipalName` attribute
* [ ] Keycloak `firstName` attribute populated correctly
* [ ] Keycloak `email` attribute populated correctly
* [ ] Keycloak `username` attribute populated correctly
* [ ] Keycloak `affiliation` attribute populated correctly
* [ ] Federated identity linked to user account
* [ ] No attribute mapping errors in logs

### Troubleshooting

#### Attributes Missing in SAML Assertion

**Symptom:** SAML assertion doesn't include required attributes

**Solutions:**

1. **Check IdP Attribute Release**
   * Contact test IdP administrator
   * Verify SP is authorized to receive attributes
   * Confirm attribute filtering is not blocking release

2. **Verify Attribute Request**
   * Check Keycloak attribute consumers service is requesting attributes
   * Review `<AttributeConsumingService>` in Keycloak SP metadata
   * Ensure required attributes are marked as `isRequired="true"`

3. **Test with Different Test IdP**
   * Some test IdPs release different attributes
   * Switch to DFN-AAI Test IdP for complete attribute set

#### Attributes Not Mapped in Keycloak

**Symptom:** Attributes present in SAML assertion but not in Keycloak user profile

**Solutions:**

1. **Verify Attribute Mapper Configuration**
   * Navigate to **Identity Providers** > **DFN-AAI** > **Mappers**
   * Confirm all required mappers exist
   * Check mapper SAML attribute names match assertion exactly

2. **Check Attribute Name Formats**
   * Federation attributes: `urn:mace:dir:attribute-def:<attribute>`
   * Friendly names: `mail`, `displayName`, etc.
   * Mapper must match one format or the other

3. **Review Mapper Target Attributes**
   * **User Attribute** must match Keycloak user schema
   * Common targets: `firstName`, `email`, `username`, `affiliation`
   * Verify spelling matches exactly (case-sensitive)

#### Incorrect Attribute Values

**Symptom:** Attributes present but with unexpected values

**Solutions:**

1. **Validate Attribute Formats**
   * `eduPersonAffiliation`: Should be one of `faculty`, `student`, `staff`, `member`
   * `mail`: Should be valid email address format
   * `eduPersonPrincipalName`: Should be scoped identifier (`user@domain`)

2. **Check IdP Configuration**
   * Review test IdP attribute generation logic
   * Compare with DFN-AAI attribute specification
   * Some test IdPs use predictable patterns for testing

3. **Use Script Mapper for Transformation**
   * If attributes need transformation, use **Script Mapper**
   * Example: Extract primary value from multi-valued attributes
   * Normalize attribute formats before mapping to Keycloak

## Test 4: Application-Level SSO

### Purpose

Validate that users can log into openDesk Edu applications (ILIAS, Moodle, etc.) using DFN-AAI federation through Keycloak.

### Procedure

#### 4.1 Access Application

1. Open an openDesk Edu application in the browser
   * ILIAS: `https://ilias.education.example.org`
   * Moodle: `https://moodle.education.example.org`

2. Click **Login** or sign into the application

#### 4.2 Select Federation Login

On the login page:

1. Look for SSO or federation login option
2. Click **Login with Keycloak** or **SSO login**
3. Option: Use discovery service directly from application

#### 4.3 Choose IdP

When prompted for identity provider:

1. Select **DFN-AAI** from the list
2. Or redirect through DFN-AAI discovery service
3. Select test institution

#### 4.4 Complete Authentication

1. Login with test credentials
2. Observe SAML flow through Keycloak
3. Verify application receives user session

#### 4.5 Verify User Session

1. Check if user is logged into the application
2. Verify user profile shows correct federation attributes
3. Confirm application functionality is available

### Expected Results

* Application login page loads
* Federation login option is available
* User selects DFN-AAI or uses discovery service
* Authentication completes through Keycloak
* Application accepts Keycloak session
* User logged into application with correct identity
* User profile populated with federation attributes

### Validation Checklist

* [ ] Application accessible via HTTPS
* [ ] Federation login option visible
* [ ] User can select DFN-AAI identity provider
* [ ] Discovery service option available
* [ ] SAML authentication completes
* [ ] Application receives session from Keycloak
* [ ] User logged into application
* [ ] User profile shows correct attributes
* [ ] Application functionality works

### Troubleshooting

#### Application Doesn't Recognize Federation Login

**Symptom:** Application requires local login instead of accepting Keycloak SSO

**Solutions:**

1. **Verify Application SAML Configuration**
   * Check application SP metadata points to Keycloak
   * Confirm ACS URL matches Keycloak endpoint
   * Review SAML atlas integration for specific application

2. **Check Keycloak Client Scope**
   * Navigate to **Clients** > [Application Client] > **Client Scopes**
   * Verify `email`, `profile`, `roles` scopes are assigned
   * Check protocol mappers export required attributes

3. **Test with Direct Keycloak Login**
   * Login directly to Keycloak account console
   * Then access application using "Already logged in" flow
   * Isolates issue to federation vs application integration

#### User Attributes Not Visible in Application

**Symptom:** User logged in but attributes not transferred to application

**Solutions:**

1. **Check Application Attribute Request**
   * Verify application requests attributes from Keycloak
   * Review SAML assertion sent from Keycloak to application
   * Application may need updated SAML SP configuration

2. **Verify Client Protocol Mappers**
   * Navigate to **Clients** > [Application Client] > **Client Scopes** > **Dedicated scopes**
   * Configure protocol mappers to export federation attributes
   * Example: Export `affiliation` as custom claim or SAML attribute

3. **Test Attribute Flow Separately**
   * Check Keycloak user attributes are populated (Test 3)
   * Verify Keycloak sends attributes in SAML response to application
   * Use SAML tracer to inspect assertion from Keycloak to application

#### Session Not Maintained Across Applications

**Symptom:** User logged into one application but not others

**Solutions:**

1. **Verify Single Sign-On Configuration**
   * Check Keycloak session is active across realm
   * Applications should share Keycloak session cookies
   * Verify SSO cookie domain includes all application subdomains

2. **Check Application Session Management**
   * Review application session cookies and expiry
   * Some applications may have separate session logic
   * Verify application trusts Keycloak session token

3. **Test with Fresh Browser Session**
   * Clear all cookies and cache
   * Login to one application
   * Access second application without re-authenticating
   * Confirms SSO is working correctly

## Test 5: Single Logout

### Purpose

Verify that logout from one application or Keycloak properly terminates sessions across the federation and all applications.

### Procedure

#### 5.1 Establish Federation Session

1. Login to Keycloak via DFN-AAI federation (Test 2)
2. Login to multiple applications (ILIAS, Moodle)
3. Confirm active sessions in Keycloak **Sessions** tab

#### 5.2 Log Out from Keycloak

1. Navigate to Keycloak account console
2. Click **Sign Out**
3. Observe logout redirect chain

#### 5.3 Verify Session Termination

1. Try accessing Keycloak - should redirect to login
2. Try accessing applications - should redirect to login
3. Check Keycloak sessions list - user session should be absent

#### 5.4 Test Application-Led Logout

1. Re-authenticate via federation
2. Log out from within an application (ILIAS/Moodle)
3. Verify Keycloak session is terminated
4. Verify other applications are logged out

#### 5.5 Test Federation Logout

If supported:

1. Re-authenticate via federation
2. Initiate logout from test IdP (if available)
3. Verify Keycloak and application sessions terminated

### Expected Results

* Logout from Keycloak terminates all sessions
* Applications redirect to login on access attempt
* Logout from application terminates Keycloak session
* Federation logout (if supported) terminates all sessions
* No orphaned sessions remain

### Validation Checklist

* [ ] Logout from Keycloak succeeds
* [ ] Keycloak redirects to login page after logout
* [ ] Applications redirect to login after Keycloak logout
* [ ] Application logout terminates Keycloak session
* [ ] No orphaned sessions in Keycloak
* [ ] SAML logout requests processed correctly
* [ ] Federation logout (if tested) terminates all sessions

### Troubleshooting

#### Applications Not Logging Out

**Symptom:** Logging out from Keycloak doesn't log out applications

**Solutions:**

1. **Verify Application Logout Configuration**
   * Check application SP metadata includes logout endpoint
   * Review SAML logout request/response configuration
   * Some applications may not implement SAML logout

2. **Check Keycloak Logout Settings**
   * Navigate to **Realm Settings** > **SSO**
   * Verify **Frontchannel Logout** is enabled
   * Check post logout redirect URLs are configured

3. **Test Independently**
   * Log out from application directly
   * Verify Keycloak session is terminated
   * Isolates issue to Keycloak-to-application logout propagation

#### Logout Redirect Fails

**Symptom:** Logout redirect chain breaks or shows errors

**Solutions:**

1. **Check Logout Endpoint Configuration**
   * Verify SLO endpoints are configured in SP metadata
   * Confirm logout endpoints are accessible via HTTPS
   * Test logout endpoint directly:

     ```bash
     curl -I https://ilias.education.example.org/logout.php?return_to=...
     ```

2. **Review Browser Network Activity**
   * Use browser developer tools to monitor logout redirects
   * Identify which request fails
   * Check for CORS or cross-site request issues

3. **Verify Logout Binding Configuration**
   * Check logout binding matches what applications support
   * Some apps only support HTTP-POST logout, not HTTP-Redirect
   * Configure Keycloak logout mechanism accordingly

## Test 6: Error Handling

### Purpose

Validate that the federation integration handles errors gracefully and provides clear feedback to users and administrators.

### Procedure

#### 6.1 Test Invalid Credentials

1. Access discovery service or direct IdP login
2. Enter invalid test credentials
3. Verify appropriate error message displayed

#### 6.2 Test Attribute Release Denial

1. If available, configure test IdP to deny attribute release
2. Attempt federation login
3. Verify Keycloak handles missing attributes correctly

#### 6.3 Test Expired Certificate

1. Temporarily rotate Keycloak SP certificate to expired
2. Attempt federation login
3. Verify appropriate certificate validation error

#### 6.4 Test Network Timeout

1. Block outbound traffic to DFN-AAI endpoints (firewall)
2. Attempt federation login
3. Verify clear timeout or connection error message

#### 6.5 Test IdP Unavailable

1. Simulate IdP downtime (if possible with test environment)
2. Attempt federation login
3. Verify error handling and user feedback

### Expected Results

* Invalid credentials: clear authentication error
* Attribute denial: user informed or login fails gracefully
* Expired certificate: clear certificate error or validation message
* Network timeout: timeout or connection error message
* IdP unavailable: service unavailable or federation error message
* No confusing technical errors shown to end users
* Admin logs contain detailed error information

### Validation Checklist

* [ ] Invalid credentials produce clear errors
* [ ] Attribute denial handled gracefully
* [ ] Certificate errors show helpful information
* [ ] Network errors provide clear feedback
* [ ] IdP unavailable displays appropriate message
* [ ] Admin logs contain relevant error details
* [ ] No exception stacks or technical errors to users

### Troubleshooting

#### Generic Error Messages Only

**Symptom:** All errors show same generic message

**Solutions:**

1. **Check Keycloak Error Handling**
   * Review Keycloak event log for detailed error types
   * Configure keycloak themes to display specific errors
   * Update login flow error handling if needed

2. **Enable Detailed Logging**

   ```bash
   # Set Keycloak debug logging for federation
   kubectl -n opendesk exec -it ums-keycloak-0 -- bash
   export KEYCLOAK_LOGLEVEL=DEBUG
   # Restart Keycloak or adjust logging config
   ```

3. **Review Error Mappers**
   * Check if any custom error mappers are masking errors
   * Verify error message localization is working
   * Update error message templates for clarity

#### Admin Logs Missing Error Details

**Symptom:** User sees error but admin logs don't show details

**Solutions:**

1. **Verify Logging Configuration**
   * Check Keycloak logging settings (console or config)
   * Ensure DEBUG logging enabled for SAML and federation
   * Review Keycloak server log file location

2. **Check Application Logs**
   * Some errors may only appear in application logs
   * Review ILIAS/Moodle error logs for SAML-related errors
   * Check Kubernetes pod logs for all relevant services

3. **Enable Federation-Specific Logging**
   * Configure Keycloak to log SAML protocol events
   * Enable audit logging for authentication events
   * Review Keycloak events tab for federation authentication events

## Test Environment Configuration

### DFN-AAI Test Federation Attributes

The DFN-AAI test federation provides predictable attribute values for testing. Use these values for validation.

**Test Attribute Patterns:**

| Test User | `mail` | `displayName` | `eduPersonAffiliation` | `eduPersonPrincipalName` |
|-----------|--------|---------------|------------------------|-------------------------|
| `testuser1` | `testuser1@test-idp.dfn.de` | `Test User One` | `student` | `testuser1@test-idp.dfn.de` |
| `testuser2` | `testuser2@test-idp.dfn.de` | `Test User Two` | `faculty` | `testuser2@test-idp.dfn.de` |
| `testuser3` | `testuser3@test-idp.dfn.de` | `Test User Three` | `staff` | `testuser3@test-idp.dfn.de` |

**Note:** Actual values may vary by test IdP. Always verify attributes in SAML tracer for your specific test environment.

### Test Identity Providers

**DFN-AAI Test IdP (Recommended):**

* Entity ID: `https://idp.test.aai.dfn.de/idp/shibboleth`
* Provides all required attributes
* No registration required
* Predictable attribute values

**Institutional Test IdPs:**

* Various universities provide test IdPs via discovery service
* May require registration with the institution
* Attribute patterns vary by institution
* Useful for testing eduGAIN federation

### Test Account Examples

**DFN-AAI Test IdP Credentials:**

* Username: `testuser1`, `testuser2`, `testuser3`
* Password: Check test IdP documentation (often same as username or provided)
* Alternative: `test1`, `test2`, `test3`

**Institutional Test IdP:**

* Follow registration process at the test institution
* Credentials provided after registration
* May require VPN or network access from specific IP ranges

## Production Testing Checklist

After successful testing with the test federation, complete these steps before moving to production:

* [ ] All tests (1-6) pass with test federation
* [ ] Attribute mapping validated with test credentials
* [ ] Application-level SSO working for all services
* [ ] Logout functionality verified
* [ ] Error handling and user feedback acceptable
* [ ] CA-signed certificates obtained from institution PKI
* [ ] SP metadata regenerated with production certificates
* [ ] DFN-AAI production registration approved
* [ ] Keycloak IdP configuration updated to production endpoints
* [ ] Attribute mappers verified with production expectations
* [ ] Test with a small pilot group of users
* [ ] Monitor authentication logs for errors
* [ ] Verify session behavior under load
* [ ] Document any production-specific issues
* [ ] Create user support documentation
* [ ] Train helpdesk staff on federation authentication

> [!important]

* Test federation allows self-signed certificates
* Production federation requires CA-signed certificates
* Separate registrations required for test and production
* Production endpoints: `https://idp.aai.dfn.de/idp/profile/SAML2/Redirect/SSO`

## Common Test Failures

### SAML Response Errors

| Error Message | Cause | Solution |
|---------------|-------|----------|
| "Invalid signature" | IdP certificate mismatch | Re-import DFN-AAI metadata in Keycloak |
| "Assertion expired" | Time synchronization issue | Sync system time (NTP) |
| "No user creation" | First login flow misconfigured | Check First Login Flow in IdP config |
| "Attribute missing" | Attribute release denied | Verify SP authorization at IdP |
| "Invalid NameID" | NameID format mismatch | Check NameID format in Keycloak IdP config |

### Attribute Release Issues

| Symptom | Cause | Solution |
|---------|-------|----------|
| email attribute missing | IdP doesn't release email to SP | Contact IdP administrator |
| Multiple affiliation values | User has multiple roles | Use script mapper to extract primary |
| Empty displayName | IdP doesn't provide display name | Configure fallback in Keycloak |
| eduPersonPrincipalName not unique | IdP generates non-unique IDs | Contact IdP administrator |

### Certificate Errors

| Error Message | Cause | Solution |
|---------------|-------|----------|
| "Certificate expired" | SP certificate expired | Rotate certificate, update metadata |
| "Certificate not trusted" | Self-signed cert in production | Use CA-signed certificate |
| "Signature validation failed" | Certificate mismatch between SP and IdP | Verify certificate in Keycloak matches registration |
| "Key size insufficient" | Certificate uses small RSA key | Generate certificate with 2048+ bit key |

### Network Connectivity Issues

| Symptom | Cause | Solution |
|---------|-------|----------|
| Timeout connecting to IdP | Firewall blocks outbound HTTPS | Open firewall rules to DFN-AAI endpoints |
| DNS resolution fails | DNS server can't resolve DFN-AAI domains | Configure DNS or use public DNS |
| Connection refused on SSO endpoint | TLS/SSL negotiation issue | Verify TLS certificate validity |
| Proxy errors | Corporate proxy blocking SAML requests | Configure proxy exceptions for federation domains |

## Performance Testing

### Load Testing

**Objective:** Validate that Keycloak can handle federation authentication under expected user load.

**Procedure:**

1. Determine peak concurrent users (e.g., 500 students at semester start)
2. Use load testing tool (e.g., JMeter, Locust, k6)
3. Configure script to simulate federation login flow
4. Ramp up load gradually (50, 100, 200, 500 concurrent users)
5. Monitor Keycloak response times and error rates

**Key Metrics:**

* Average login time: < 5 seconds
* Error rate: < 1%
* Keycloak CPU/memory utilization within limits
* No database connection pool exhaustion

### Response Time Validation

**Expected Response Times:**

| Operation | Baseline | Acceptable |
|-----------|----------|------------|
| Discovery service load | < 2s | < 3s |
| Redirect to IdP | < 1s | < 2s |
| IdP authentication | < 5s | < 8s |
| SAML assertion processing | < 2s | < 3s |
| Total login time | < 10s | < 15s |

**Measurement:**

1. Use browser developer tools (Network tab)
2. Observe timeline for each redirect
3. Measure time from initial request to final application access
4. Identify slow components (network, IdP, Keycloak, applications)

### Resource Monitoring

**Monitor During Load Test:**

1. **Keycloak Resources:**
   * CPU utilization
   * Memory usage
   * Database connection pool usage
   * Active session count

2. **Application Resources:**
   * ILIAS/Moodle HTTP response times
   * Database query performance
   * Application server load

3. **Network Metrics:**
   * Bandwidth usage
   * Request rate to DFN-AAI endpoints
   * Latency to external IdPs

**Commands:**

```bash
# Check Keycloak pod resource usage
kubectl top pod -n opendesk -l app=ums-keycloak

# Check Keycloak logs for errors during load
kubectl -n opendesk logs deployment/ums-keycloak --tail=500 | grep -i error

# Monitor database connections
kubectl -n opendesk exec -it ums-keycloak-0 -- bash
/opt/keycloak/bin/kcadm.sh get events --server http://localhost:8080/auth --realm opendesk
```

## Security Testing

### Signature Validation

**Objective:** Ensure SAML assertions are properly signed and validated.

**Procedure:**

1. Intercept SAML response from IdP
2. Verify assertion contains `<ds:Signature>` element
3. Check signature algorithm (should be RSA-SHA256 or better)
4. Confirm Keycloak validates signature (no verification bypass)

**Validation:**

* Use SAML tracer to inspect signature
* Verify signature covers Assertion element
* Check Keycloak logs for signature validation errors
* Test with unsigned assertion (should fail)

### Attribute Encryption

**Objective:** Validate that sensitive attributes are encrypted when required.

**Procedure:**

1. Check SAML assertion for `<xenc:EncryptedData>` elements
2. Verify encryption algorithm (AES-256 or better)
3. Confirm Keycloak can decrypt encrypted attributes
4. Review encryption key management

**Note:** Encryption is optional in DFN-AAI but may be required for specific attributes or institutions.

### Replay Attack Prevention

**Objective:** Ensure SAML assertions cannot be replayed.

**Procedure:**

1. Capture a SAML assertion完成successful login
2. Re-submit the same assertion to Keycloak (manually or with tool)
3. Verify login fails (assertion rejected)
4. Check Keycloak logs for replay detection

**Validation:**

* SAML assertions include `IssueInstant` timestamp
* Keycloak validates timestamp within valid window
* Assertion ID tracked and reused assertions rejected
* No session fixation vulnerabilities

## Test Result Documentation

**Test Report Template:**

```markdown
# DFN-AAI Federation Test Results
Date: YYYY-MM-DD
Tester: Name
Environment: Test/Production

## Test Summary
- Tests Passed: X/6
- Overall Status: PASS/FAIL

## Detailed Results
### Test 1: Discovery Service Access
Status: PASS/FAIL
Notes: ...

### Test 2: Direct IdP Authentication
Status: PASS/FAIL
Notes: ...

...

## Issues Found
1. Issue description
   - Severity: Critical/High/Medium/Low
   - Affected tests:
   - Resolution:

## Recommendations
- Production ready: Yes/No
- Outstanding items:
```

**Test Artifacts:**

* SAML tracer exports (captured assertions)
* Keycloak event logs snippets
* Browser network traces
* Load test results
* Error screenshot files
* Configuration snapshots

## Integration Testing

### Shibboleth SP Testing

For services using Shibboleth SP configuration (ILIAS, Moodle):

**Procedure:**

1. Test Shibboleth SP -> Keycloak flow
2. Verify attribute consumption from Keycloak
3. Check session management with Kerberos/NTLM
4. Validate attribute map file consumption

**Validation:**

* Shibboleth SP accepts SAML assertions from Keycloak
* Attributes correctly mapped in `attribute-map.xml`
* Apache/Shibd service restarts without errors
* Application recognizes federated user identity

### ILIAS Federation Testing

**Procedure:**

1. Login to ILIAS with federation
2. Verify user profile completed from Keycloak
3. Test course access with federated user
4. Validate ILIAS recognizes federation role mapping

**Validation:**

* ILIAS login page shows SSO option
* User profile populated with Keycloak attributes
* Course enrollment works with federated user
* ILIAS local role assignment matches federation affiliation

### Moodle Federation Testing

**Procedure:**

1. Login to Moodle with federation
2. Verify user creation in Moodle database
3. Test course enrollment with federated user
4. Validate moodle recognizes federation affiliation

**Validation:**

* Moodle login page shows SSO option
* User created in `mdl_user` table with correct fields
* Course assignment works with federated user
* Moodle role assignment matches federation affiliation

## Automated Testing

### SAML Testing Tools

**Recommended Tools:**

1. **SAML-tracer (Browser Extension)**
   * Captures SAML requests and responses
   * Visual inspection of assertion content
   * Export for documentation and debugging

2. **saml2-js (Node.js)**
   * Programmatic SAML request/response generation
   * Validation of SAML signatures
   * Test automation scripts

3. **PySAML2 (Python)**
   * SAML client and server implementation
   * Assertion generation and validation
   * Test harness development

**Example Automation:**

```bash
# Automate Test 2 (Direct IdP Authentication) with curl
curl -v -X GET \
  "https://idp.education.example.org/realms/opendesk/protocol/saml" \
  --data-urlencode "client_id=account-console" \
  --data-urlencode "redirect_uri=https://idp.education.example.org/realms/opendesk/account" \
  --data-urlencode "response_type=code" \
  --data-urlencode "scope=openid" \
  --data-urlencode "kc_idp_hint=dfn-aai-test"
```

### Keycloak API Testing

**Objective:** Automate user and federation testing via Keycloak admin API.

**Procedure:**

1. Obtain Keycloak admin access token
2. Create test script to:
   * List federated identities
   * Query user attributes
   * Validate identity provider configuration
   * Check authentication events

**Example:**

```bash
# Get Keycloak admin token
ACCESS_TOKEN=$(curl -X POST \
  "https://idp.education.example.org/realms/master/protocol/openid-connect/token" \
  -d "client_id=admin-cli" \
  -d "username=kcadmin" \
  -d "password=...password..." \
  -d "grant_type=password" | jq -r '.access_token')

# List federated identities
curl -X GET \
  "https://idp.education.example.org/admin/realms/opendesk/identity-provider-instances" \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# Get user federation details
curl -X GET \
  "https://idp.education.example.org/admin/realms/opendesk/users/<user-id>/federated-identity" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

### E2E Test Automation

**Objective:** Create end-to-end test automation for federation authentication.

**Tools:**

* **Playwright/Cypress:** Browser-based E2E testing
* **TestCafe:** Cross-browser testing framework
* **Selenium:** WebDriver automation

**Test Scenarios:**

1. Discovery service login flow
2. Direct IdP authentication
3. Attribute mapping validation
4. Application-level SSO
5. Logout functionality
6. Error handling

**Example (Playwright):**

```typescript
// Test federation login with discovery service
test('federation login with discovery service', async ({ page }) => {
  await page.goto('https://discovery.aai.dfn.de/');

  // Fill return URL
  await page.fill('#return_to', 'https://idp.education.example.org/realms/opendesk/protocol/saml');

  // Select test institution
  await page.click('.institution-select');
  await page.click('text=DFN-AAI Test IdP');

  // Login
  await page.fill('#username', 'testuser1');
  await page.fill('#password', 'password');
  await page.click('#login-button');

  // Verify redirect to Keycloak and successful login
  await expect(page).toHaveURL(/opendesk\/account/);
  await expect(page.locator('.user-profile')).toContainText('Test User One');
});
```

---

## Additional Resources

* **DFN-AAI Documentation:** <https://www.aai.dfn.de/en/documentation/>
* **eduGAIN Technical Profile:** <https://technical.edugain.org/>
* **Keycloak SAML Documentation:** <https://www.keycloak.org/docs/latest/server_admin/#identity-broker-saml>
* **DFN-AAI Support:** [support@aai.dfn.de](mailto:support@aai.dfn.de)
* **Shibboleth Documentation:** <https://wiki.shibboleth.net/confluence/display/CONCEPT/Home>
* **OpenDesk Edu GitHub:** <https://github.com/opendesk-edu/opendesk-edu/issues>

---

**Related Documentation:**

* [DFN-AAI Enrollment Guide](./dfn-aai-enrollment.md)
* [Federation Metadata Generation Script](../../scripts/federation/README.md)
* [Keycloak Configuration Guide](../../docs/enhanced-configuration/idp-federation.md)
