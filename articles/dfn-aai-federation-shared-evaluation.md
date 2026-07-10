---
title: "Federated Identity for Education: openDesk Edu and the DFN-AAI Federation"
description: "How openDesk Edu integrates with the German national research federation DFN-AAI as a SAML Service Provider proxy via Keycloak — and a call to action for the community to build a shared evaluation instance that lowers the barrier for every institution."
date: 2026-07-10
tags: [dfn-aai, federation, saml, keycloak, edugain, identity-management, shibboleth, community]
author: "Tobias Weiß and openDesk Edu Contributors"
---

# Federated Identity for Education: openDesk Edu and the DFN-AAI Federation

> **The vision:** A student at any German university logs into their local learning platform once — and accesses collaborative tools, file storage, and video conferencing across institutional boundaries without a second password.
>
> **The reality:** Federation is hard. SAML metadata, eduGAIN attribute mapping, SP registration, certificate management — every institution reinvents the wheel.
>
> **The call to action:** Let's build a shared DFN-AAI evaluation instance together. One federation setup, tested and documented by many. Lower the barrier for every institution in the community.

## The DFN-AAI Federation

DFN-AAI (Deutsches Forschungsnetz — Authentication and Authorization Infrastructure) is Germany's national academic identity federation, connecting universities, research institutions, and service providers through SAML 2.0. It's part of the global eduGAIN inter-federation, which means a DFN-AAI login can authenticate users across participating institutions worldwide.

For openDesk Edu, DFN-AAI integration is not optional — it's a core requirement. German universities don't create separate user accounts for every platform. They authenticate through their institutional Identity Provider (IdP), which is registered with DFN-AAI and federates with eduGAIN.

Without DFN-AAI support, openDesk Edu would be a standalone island. With it, it becomes part of the national research and education infrastructure.

## What We Built

Over Sprint 5 of our v1.1 release roadmap (July 2026), we implemented comprehensive DFN-AAI federation support for openDesk Edu. Here's what was delivered:

### 1. Keycloak as SAML Service Provider Proxy

The core architectural decision: **Keycloak acts as both SAML SP (to DFN-AAI) and OIDC IdP (to openDesk services).** This means:

- The external world sees one SAML SP entity — clean, simple, standard
- Internal services continue using OIDC — no SAML configuration needed per service
- Attribute translation happens in one place — SAML eduGAIN attributes → OIDC claims
- Backchannel logout propagates from DFN-AAI → Keycloak → all 25+ services

```
┌──────────────┐     SAML 2.0     ┌──────────────┐     OIDC      ┌──────────────┐
│  DFN-AAI IdP │◄────────────────►│   Keycloak   │◄────────────►│ openDesk     │
│ (Shibboleth) │    (eduGAIN)     │  (SAML SP)   │   (Claims)    │ Services     │
└──────────────┘                  └──────────────┘               └──────────────┘
```

### 2. eduGAIN Attribute Mapping

eduGAIN defines a standard set of attributes that IdPs release about their users. We mapped these to Keycloak user attributes and OIDC claims:

**5 Required Attributes (mandatory for DFN-AAI registration):**

| eduGAIN Attribute | Description | Mapped To |
|-------------------|-------------|-----------|
| `eduPersonPrincipalName` | Unique user identifier | `eppn` |
| `mail` | Email address | `email` |
| `displayName` | Full display name | `name` |
| `givenName` | First name | `firstName` |
| `sn` | Surname | `lastName` |

**5 Recommended Attributes:**

| eduGAIN Attribute | Description | Mapped To |
|-------------------|-------------|-----------|
| `eduPersonAffiliation` | Role (student/staff/faculty) | `affiliation` |
| `eduPersonScopedAffiliation` | Affiliation with scope | `scopedAffiliation` |
| `eduPersonEntitlement` | Entitlement URNs | `entitlement` |
| `preferredLanguage` | Language preference | `locale` |
| `schacHomeOrganization` | Home organization domain | `organization` |

The attribute mapping is the critical path. If attributes don't arrive correctly, users can't authenticate, roles aren't assigned, and personalization fails. We documented every mapper with its SAML attribute name format (`urn:oasis:names:tc:SAML:2.0:attrname-format:uri` vs `basic`) to eliminate guesswork.

### 3. Service Provider Metadata Generation

We created a metadata generation workflow that produces the SAML SP metadata XML that DFN-AAI requires for registration:

```bash
# Generate SP metadata
./scripts/generate-saml-metadata.sh \
  --entity-id "urn:auth:opendesk:edu:yourdomain" \
  --acs-url "https://keycloak.yourdomain.de/realms/opendesk/broker/dfn-aai/endpoint" \
  --cert-file /etc/ssl/certs/saml-signing.crt

# Validate metadata
xmllint --valid --noout sp-metadata.xml
```

The generated metadata includes:
- Entity ID and endpoints (ACS, SLO)
- SAML signing and encryption certificates
- Requested attributes (eduGAIN standard)
- NameID format preferences

### 4. Testing and Troubleshooting

The DFN-AAI test federation provides a sandbox environment where SP registration can be validated before production:

| Environment | Metadata Source | Registration Time |
|-------------|-----------------|-------------------|
| **Test Federation** | DFN-AAI test federation: `https://www.aai.dfn.de/fileadmin/metadata/DFN-AAI-Test-metadata.xml` | 1-2 business days |
| **Production Federation** | Your institution's DFN-AAI administrator | 3-5 business days |

We documented the complete testing workflow — from test IdP accounts to attribute verification to single logout propagation — in [`docs/dfn-aai-testing-guide.md`](https://github.com/opendesk-edu/opendesk-edu/blob/main/docs/dfn-aai-testing-guide.md).

### 5. Complete Documentation Suite

The DFN-AAI work produced five documentation files totaling ~500 lines:

| Document | Purpose |
|----------|---------|
| `docs/dfn-aai-federation.md` | High-level federation architecture and configuration |
| `docs/dfn-aai-keycloak-integration.md` | Step-by-step Keycloak SAML SP/IdP setup |
| `docs/dfn-aai-registration.md` | DFN-AAI enrollment procedures |
| `docs/dfn-aai-testing-guide.md` | Test federation verification (EN/DE bilingual) |
| `docs/federation/dfn-aai-enrollment.md` | Production deployment checklist |

## The Challenge: Every Institution Reinvents the Wheel

Here's the problem. Every university that wants to deploy openDesk Edu — or any SAML-compatible platform — needs to:

1. **Contact DFN-AAI** for federation registration (1-2 weeks administrative process)
2. **Generate SAML metadata** for their specific deployment
3. **Configure certificate signing** through their institutional PKI
4. **Coordinate attribute release** with their institutional IdP administrators
5. **Test the full flow** — authentication, attribute mapping, logout propagation
6. **Debug independently** when something doesn't work

For a single institution, this is manageable. **For 10, 20, or 50 institutions, the repetition is staggering.** Every team debugs the same SAML errors. Every team figures out the same attribute mapping. Every team goes through the same 1-2 week registration wait.

Worse: **there's no shared evaluation environment.** If you're a university evaluating openDesk Edu, you can't "just test" the DFN-AAI integration without going through the full registration process. You need a production-grade SAML SP, registered with DFN-AAI, with proper certificates and metadata — just to decide if the platform works for you.

This is the bottleneck we need to solve together.

## The CTA: A Shared DFN-AAI Evaluation Instance

Here's the proposal: **Let's establish a shared DFN-AAI evaluation instance that any community member can use to test federation integration.**

### What It Would Be

A single, community-managed Keycloak instance configured as a DFN-AAI SAML Service Provider, registered with the DFN-AAI test federation, that multiple projects can use for evaluation purposes:

```
┌─────────────────────────────────────────────────────┐
│           Shared Evaluation Instance                  │
│                                                      │
│  Keycloak (SAML SP) ───── Registered with DFN-AAI   │
│       │                                              │
│       ├── Realm: opendesk-eval    (openDesk Edu)     │
│       ├── Realm: lms-eval         (Other LMS)        │
│       ├── Realm: collab-eval      (Collaboration)    │
│       └── Realm: your-project     (Your project)     │
│                                                      │
│  Shared SAML metadata: eval.sp.opendesk-edu.org      │
│  Shared certificates: Community-managed PKI          │
│  Shared documentation: Battle-tested by many          │
└─────────────────────────────────────────────────────┘
```

### Why It Matters

- **Lower the evaluation barrier** — test federation integration without a 2-week registration wait
- **Share debugging knowledge** — when one community member solves a SAML issue, everyone benefits
- **Standardize attribute mapping** — one proven eduGAIN mapper configuration, validated by many institutions
- **Provide a reference implementation** — "it works on the shared evaluation instance" becomes a baseline
- **Accelerate procurement** — evaluate before you commit to the full registration process

### How It Would Work

The shared instance would be:

1. **Lightweight** — A single VM or Kubernetes pod running Keycloak, registered with DFN-AAI test federation
2. **Multi-tenant** — Each community project gets its own Keycloak realm for isolated testing
3. **Community-managed** — Configuration and certificates managed openly, with documentation for every change
4. **Documented** — Every attribute mapper, every endpoint, every certificate rotation is documented
5. **Temporary by default** — Realms are evaluation-only; production deployments still need proper registration

### What We Need From the Community

This only works if it's a community effort. Here's what's needed:

| Role | What You Contribute |
|------|---------------------|
| **Infrastructure Host** | A small VM or container host (2 CPU, 4 GB RAM) — could rotate monthly |
| **DFN-AAI Liaison** | Someone with an existing DFN-AAI registration who can register the shared SP |
| **Certificate Manager** | Generate and rotate the SAML signing certificate |
| **Testers** | Connect your project's SP configuration and verify attribute mapping |
| **Documentation Writers** | Capture working configurations, common errors, and resolutions |
| **Users** | Test with real institutional IdP credentials (any DFN-AAI member) |

### Getting Started

If you're interested in contributing to or using a shared DFN-AAI evaluation instance:

1. **Open a GitHub Discussion** — let's gauge interest and coordinate: [github.com/opendesk-edu/opendesk-edu/discussions](https://github.com/opendesk-edu/opendesk-edu/discussions)
2. **Review the DFN-AAI documentation** — understand what's needed: [`docs/dfn-aai-federation.md`](https://github.com/opendesk-edu/opendesk-edu/blob/main/docs/dfn-aai-federation.md)
3. **Test with the existing guides** — validate that our Keycloak configuration works with your IdP
4. **Share your experience** — what attributes does your institution release? What errors did you hit? What configuration quirks did you discover?

### What We've Already Done

The foundation is in place:

- Complete Keycloak SAML SP/IdP configuration documented and reviewed
- 10 eduGAIN attribute mappers (5 required + 5 recommended) documented with exact SAML attribute name formats
- SP metadata generation script with certificate support
- Bilingual (EN/DE) testing guide for DFN-AAI test federation
- 5 documentation files covering federation, enrollment, integration, testing, and production deployment
- Backchannel logout configured for all 25+ openDesk Edu services — logout propagation works end-to-end

What's missing is the shared infrastructure. And that's where we need you.

## Federation Is a Team Sport

The openDesk Edu project is built on the principle that educational technology should be sovereign, collaborative, and open. DFN-AAI federation embodies all three:

- **Sovereign** — institutions control their own identity infrastructure
- **Collaborative** — federation connects institutions, not isolates them
- **Open** — SAML 2.0 and eduGAIN are open standards, not proprietary protocols

A shared evaluation instance extends this philosophy to the evaluation process itself. Instead of each institution climbing the same mountain alone, we build the trail together — and everyone who follows benefits from the path we've cleared.

**Join us. Test your federation setup against a shared instance. Contribute your findings. Help build the evaluation infrastructure that every institution needs.**

---

*The DFN-AAI federation work is part of the openDesk Edu v1.1 release. All documentation is available in the [openDesk Edu repository](https://github.com/opendesk-edu/opendesk-edu). For questions about the shared evaluation initiative, open a GitHub Discussion or contact the community.*

**openDesk Edu: Sovereign, integrated, production-ready open-source education technology.**
