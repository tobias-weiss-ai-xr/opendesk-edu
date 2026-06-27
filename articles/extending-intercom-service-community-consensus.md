---
title: "Extending the Intercom-Service: A Call for Community-ZenDiS Consensus on Common Development Patterns"
date: "2026-06-27"
description: "How we extended the openDesk intercom-service to support OpenCloud, SOGo, and ILIAS, and why we urge ZenDiS and the community to establish a formal consensus on common development patterns."
categories: ["Engineering", "Community", "Open Source"]
tags: ["intercom-service", "zendis", "opendesk", "extension", "community", "governance"]
author: "Tobias Weiß and openDesk Edu Contributors"
---

# Extending the Intercom-Service: A Call for Community-ZenDiS Consensus on Common Development Patterns

## Introduction

The **intercom-service** (ICS) is a small but critical piece of infrastructure in the openDesk ecosystem. It acts as an intermediary that enables browser-based cross-application communication—file pickers, video conference integration, single sign-on between apps, and portal navigation.

When we set out to build **openDesk Edu**, we discovered that the upstream intercom-service (maintained by Univention and deployed by ZenDiS) was designed primarily for **openDesk CE** (Community Edition), focusing on **Nextcloud, OX App Suite, and Matrix** as the primary integrations.

For **openDesk Edu**, we needed additional integrations for **OpenCloud, SOGo, and ILIAS**. This is our story of extending the intercom-service—and our urgent call for a **formal consensus between ZenDiS and the community** on common development patterns.

## The Intercom-Service: What It Does

The intercom-service is a lightweight proxy/broker that runs in your browser context. It enables apps to:

- **File-picker**: Open a file from Nextcloud/OpenCloud in another app
- **Silent login**: Pass OIDC tokens between apps without user interaction
- **Portal navigation**: Fetch the central navigation menu from the Univention Portal
- **Video conference integration**: Create BBB/Jitsi rooms from other apps
- **Backchannel logout**: Coordinate OIDC session termination

These features require the ICS to be **embedded as an iframe** in each app, which then uses **postMessage** to communicate with the parent application. The ICS acts as a trusted intermediary that holds the user's OIDC tokens and can act on behalf of the user.

## What We Extended

In our openDesk Edu fork, we added the following:

### 1. **OpenCloud Support** (`/oc/` route)

Upstream only supports Nextcloud (`/fs/` route). We added a parallel `/oc/` route for OpenCloud, which is our primary file service in openDesk Edu.

```typescript
// New: opencloud route handler
router.get('/oc/*', handleOpenCloudProxy);

// Existing: nextcloud route (kept for compatibility)
router.get('/fs/*', handleNextCloudProxy);
```

### 2. **SOGo Groupware Support** (`/sogo/` route)

Upstream doesn't support SOGo. We added a `/sogo/` route that proxies CalDAV and CardDAV requests to the SOGo backend, enabling calendar and contact integration across apps.

### 3. **ILIAS LMS Support** (`/ilias/` route)

Upstream doesn't support ILIAS. We added an `/ilias/` route that proxies REST API calls and file uploads to the ILIAS backend, enabling deep LMS integration.

### 4. **Standard Node.js Base Image**

Upstream requires the **Univention UCS base image**, which is a 2GB+ image with many Univention-specific dependencies. We replaced this with a **standard Node.js Alpine base image**, reducing the image size to ~150MB and making the ICS deployable on any Kubernetes cluster without Univention dependencies.

### 5. **`opendesk_username` as Default Claim**

Upstream uses `username` as the default claim. We changed this to `opendesk_username` to match the openDesk Edu claim naming convention.

### 6. **Health Endpoint** (`/health`)

A simple `/health` endpoint returning `{"status": "ok"}` for Kubernetes liveness/readiness probes.

## The Problem: Diverging Codebases

Here's the uncomfortable truth: **our fork is diverging from upstream**.

Every time ZenDiS updates the upstream intercom-service (e.g., security patches, new features for openDesk CE), we face a choice:

1. **Merge upstream and lose our changes** → We'd lose OpenCloud, SOGo, and ILIAS support
2. **Stay on our fork and miss upstream improvements** → We'd accumulate technical debt
3. **Manually rebase and resolve conflicts** → This takes days every time and is error-prone

**None of these options are sustainable.** We need a better way.

## The Root Cause: No Common Development Pattern

The fundamental problem is that there is **no formal agreement** between:

- **ZenDiS** (the primary maintainer of the openDesk platform)
- **The openDesk Edu community** (and potentially other openDesk variants)

...on **how extensions like ours should be developed, contributed, and merged**.

Today, the situation is:

- ZenDiS develops for **openDesk CE** (public sector focus)
- We develop for **openDesk Edu** (education sector focus)
- Both projects use the **same upstream intercom-service** but with different needs
- There is **no official channel** for contributing our changes back
- There is **no governance model** for managing divergent forks

## What We Urge: A Formal ZenDiS-Community Consensus

We believe it's time to establish a **formal consensus** between ZenDiS and the community on common development patterns. Here is our proposal:

### 1. **Contributor License Agreement (CLA)**

ZenDiS should provide a lightweight CLA that allows external contributors to submit changes without complex legal overhead. This is standard practice in many open-source projects (e.g., CNCF, Apache Foundation).

### 2. **Generic, Pluggable Architecture**

The intercom-service should be refactored to be **service-agnostic** with a **plugin architecture**. Instead of hardcoded handlers for Nextcloud, SOGo, OpenCloud, etc., there should be a common interface that any service can implement.

```typescript
// Proposed: Pluggable architecture
interface BackendService {
  name: string;
  baseUrl: string;
  healthCheck(): Promise<boolean>;
  proxyRequest(req: Request): Promise<Response>;
}

// Register any service
registry.register('opencloud', new OpenCloudService());
registry.register('sogo', new SOGoService());
registry.register('ilias', new ILIASService());
```

This would allow openDesk Edu to add OpenCloud, SOGo, and ILIAS support as **plugins** that don't require upstream changes.

### 3. **Common Configuration Schema**

All openDesk variants should use a **common configuration schema** for the intercom-service. This makes it easy to:

- Deploy the same image across all variants
- Share Helm charts and Kubernetes manifests
- Test integrations consistently

```yaml
# Proposed: Common config schema
intercom:
  backends:
    - name: nextcloud
      type: ocis  # or "nextcloud", "opencloud", etc.
      url: https://nextcloud.example.com
    - name: sogo
      type: caldav
      url: https://sogo.example.com
```

### 4. **CI/CD for Multi-Variant Testing**

ZenDiS's CI/CD should test the intercom-service against **all major openDesk variants** (CE, Edu, SME, etc.), not just CE. This ensures that changes don't break other variants.

### 5. **Regular Community Calls**

Monthly or bi-monthly community calls between ZenDiS maintainers and community contributors to:

- Discuss upcoming changes
- Coordinate releases
- Resolve conflicts early
- Share roadmaps

### 6. **Public Roadmap**

ZenDiS should publish a **public roadmap** for the intercom-service (and other shared components) so the community can plan around changes.

### 7. **Clear Contribution Path**

There should be a **clear, documented path** for community contributions:

- How to submit a PR
- What review criteria are used
- How merges are decided
- Who has merge rights
- How conflicts are resolved

## Why This Matters for Digital Sovereignty

This isn't just about code quality or developer convenience. It has **real implications for digital sovereignty in European public administration**.

The openDesk platform is a **strategic initiative** by the German federal government to provide a sovereign alternative to Microsoft 365 and Google Workspace. If the platform fragments into incompatible forks, it undermines the core value proposition:

- **Interoperability**: Different government agencies using different openDesk variants should be able to collaborate
- **Maintainability**: Forks that diverge too much become impossible to maintain
- **Adoption**: Public administrators are reluctant to adopt fragmented platforms
- **Cost**: Each fork requires its own maintenance team, increasing total cost

**A formal consensus on common development patterns is essential for the long-term success of openDesk as a sovereign platform.**

## What We're Doing in the Meantime

While we wait for an official consensus, we're doing our best to be good community citizens:

1. **Open-source our fork** on GitHub: https://github.com/opendesk-edu/opendesk/tree/main/helmfile/charts/intercom-service
2. **Submit PRs upstream** for any changes that might be useful to all
3. **Document our changes clearly** in the README (see the "What's different from upstream" section)
4. **Maintain compatibility** by keeping all upstream routes intact
5. **Contribute back** improvements like the standard Node.js base image

We're not trying to fork the project permanently. **We want to merge back**. But we need a process to make that possible.

## A Concrete Proposal for ZenDiS

To ZenDiS, we propose the following **first steps**:

1. **Open a GitHub issue** titled "RFC: Multi-variant intercom-service development" on the univention/intercom-service repository
2. **Invite openDesk Edu, SME, and other variant maintainers** to a kickoff call
3. **Establish a working group** to draft a contribution guide
4. **Publish a CLA template** for community contributions
5. **Refactor the intercom-service** to be more modular (even a simple first step helps)

We're ready to contribute our time, code, and resources to make this happen. **The ball is in ZenDiS's court.**

## Conclusion: The Path Forward

The openDesk platform is a remarkable achievement—25+ integrated open-source services, German data protection compliance, and a real alternative to US-based SaaS giants. But its long-term success depends on **collaboration, not fragmentation**.

We urge ZenDiS to work with the community to establish **common development patterns** for shared components like the intercom-service. This isn't just about making our lives easier—it's about ensuring that openDesk remains a **viable, sovereign platform** for the long term.

**Let's build this together.**

---

## Call to Action

If you agree with this vision, here's how you can help:

1. **Share this article** with the openDesk community
2. **Engage with ZenDiS** on social media and at conferences
3. **Contribute** to the intercom-service or other shared components
4. **Comment** on the GitHub issue (once it exists) with your use case
5. **Document** your own openDesk variant's needs

Together, we can build a truly sovereign digital infrastructure for European public administration and education.

---

**About the Authors**: This article was written by the openDesk Edu community. openDesk Edu is a production deployment of 25 integrated open-source services for German educational institutions, based at HRZ Marburg. See [opendesk-edu.org](https://opendesk-edu.org) for more information.

**License**: This article is licensed under Apache-2.0.
