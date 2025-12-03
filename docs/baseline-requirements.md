<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Baseline Requirements</h1>

* [Preamble / Scope](#preamble--scope)
* [License compliance](#license-compliance)
* [Release Management](#release-management)
* [Container architectural basics](#container-architectural-basics)
* [Authentication \& Authorization](#authentication--authorization)
  * [Authentication](#authentication)
  * [User lifecycle](#user-lifecycle)
    * [Pull: LDAP](#pull-ldap)
    * [Push: Provisioning](#push-provisioning)
* [Logging \& Monitoring](#logging--monitoring)
* [Features](#features)
  * [Non-overlapping functionality](#non-overlapping-functionality)
  * [Functional administration](#functional-administration)
  * [Theming](#theming)
  * [Central user profile](#central-user-profile)
* [UI/UX](#uiux)
  * [Top bar](#top-bar)
    * [Look and feel](#look-and-feel)
    * [Central navigation](#central-navigation)
* [Security](#security)
  * [Software bill of materials (SBOMs)](#software-bill-of-materials-sboms)
    * [Artifact SBOMs](#artifact-sboms)
    * [Source code SBOMs](#source-code-sboms)
  * [Software supply chain security](#software-supply-chain-security)
  * [Pod Security Standards (PSS)](#pod-security-standards-pss)
  * [Deutsche Verwaltungscloud Strategie (DVS)](#deutsche-verwaltungscloud-strategie-dvs)
  * [IT-Grundschutz](#it-grundschutz)
* [Accessibility](#accessibility)
* [Data protection](#data-protection)
* [Footnotes](#footnotes)

# Preamble / Scope

This document lays out the requirements for each openDesk component referred as "component" in the following.

This document MAY be used to assess the status for a component and possible gaps, which might itself be the basis for a decision if the component should be integrated into openDesk by working on closing the identified gaps.

> [!note]
> Even an already integrated component might not adhere to all aspects of the documented requirements yet.
> Closing the gaps for existing components therefore is an openDesk priority.

> [!note]
> The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
>      NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
>      "OPTIONAL" in this document are to be interpreted as described in
>      [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).
> - MUST (NOT): These requirements are hard requirements and must be fulfilled. If technically possible they can be considered hard-blocking qualitygates that could prevent a new components artifact/container from being deployed.
> - SHOULD (NOT): These requirements don't need to be fulfilled, but might be in the future. Any given MUST requirement was a SHOULD requirement for at minimum 90 days.

# License compliance

All parts of openDesk Community Edition MUST be [open source](https://opensource.org/osd). Source code MUST be published on openCode or MUST BE publicly available to be published as a copy on openCode.

openCode provides some boundaries when it comes to open source license compliance openDesk has to adhere to:

- The components MUST be published under a license listed in the [openCode license allow list](https://opencode.de/en/knowledge/general-conditions/standardised-open-source-licenses).
- Delivered artifacts (container images) MUST contain only components licensed under the aforementioned allow list. A container MUST NOT contain any artifact using a license from the [openCode license block list](https://opencode.de/en/knowledge/general-conditions/standardised-open-source-licenses#3.-Negative-list-of-all-non-released-licenses).

Deviations from the above requirements must be documented in the openDesk license deviation report.

**Reference:** https://gitlab.opencode.de/bmi/opendesk/deployment/SBOM/-/blob/main/sboms/openDesk%20Deviation%20Report-0.5.74.md

openDesk MUST ensure open source license compliance.
Therefore, suppliers MUST apply the [OpenChain ISO/IEC 5230](https://openchainproject.org/license-compliance) license compliance program. Suppliers MAY use the [ISO/IEC 5230 Self-Certification
](https://openchainproject.org/checklist-iso-5230-2020) to state conformance.

# Release Management

Components MUST provide [Semantic Versioning (SemVer) 2.0.0](https://semver.org/) compliant releases of the container image. Patch level-maintained releases MUST exist for all component minor versions currently used in supported openDesk releases.

Caveats:
- If a component uses non SemVer compliant versioning, it may get relabeled. This may break documentation and encourage a revision of versioning upstream.

# Container architectural basics

> [!note]
> openDesk is operated as a Kubernetes (K8s) workload.

Components SHOULD adhere to best practices for K8s application/container design. While there are dozens of documents about these best practices please use them as references:
- https://cloud.google.com/architecture/best-practices-for-building-containers
- https://cloud.google.com/architecture/best-practices-for-operating-containers

As some applications were initially created years before K8s was introduced, they naturally might take different approaches.

You will find below some of the most common best practice requirements, some of which are auto-tested as part of the openDesk deployment automation:

- Containers come with readiness and liveness probes.
- Containers are stateless and immutable (read-only root file system), state should be placed into a database (or similar).
- Allow horizontal scaling (auto-scaling is of course nice to have).
- Provide resource requests and limits (we do not want to limit CPU though).
- Provide application-specific monitoring endpoints and expose the health of the application.
- Write your logs to STDOUT/STDERR and ideally provide JSON-based logs.
- Use one service per container (microservice pattern).
- Minimize the footprint of your container e.g. removing unnecessary tools, ideally providing a distroless container.
- Allow restrictive setting of the security contexts (see [security-context.md](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/security-context.md) for reference).
- Support for external secrets.
- Support for externally provided/self-signed certificates.

**Reference:** Some of these requirements are tested and/or documented within the deployment automation:
- CI executed Kyverno tests: https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/tree/main/.kyverno/policies
- Generated documentation regarding security contexts: https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/security-context.md

# Authentication & Authorization

## Authentication

The central IdP ensures the single sign-on and logout workflows. openDesk consistently uses [Open ID Connect](https://openid.net/). It can be configured to provide additional user information from the IAM if required by a component.

Components MUST support OIDC. The following configuration is REQUIRED regarding the OIDC support in a component, besides the actual login flow:

- Back-channel logout: [OIDC Back-Channel Logout](https://openid.net/specs/openid-connect-backchannel-1_0.html) must be supported by the components unless there is a significant reason why it technically cannot be supported, in that case [OIDC Front-Channel Logout](https://openid.net/specs/openid-connect-frontchannel-1_0.html) is the alternative.
- IdP Session Refresh: Ensure that your application regularly checks the IdP session for its validity and invalidates the local session when there is no longer an IdP session.

**Reference:** Most components are directly connected to the IdP and are using OIDC: https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/architecture.md#identity-data-flows

## User lifecycle

With a central Identity- and Access Management (IAM) also the user lifecycle (ULC) that addresses account create-update-delete actions with support for "inactive" accounts must be harmonized within the platform.

The objective is to have all components using the IAM managed account details including the account's state, profile picture and - where required - group memberships. While this can be done by pushing the data through OIDC claims when a user logs in to a component, it is preferred that the information in synchronized into the components independently from user interaction. Therefore, two ways of managing an account are applicable and described in the following sections.

> [!note]
> Allowing ad hoc updates of account data through OIDC claims during login is still encouraged.

### Pull: LDAP

Components can access the IAM's LDAP to access all data necessary for managing their part of the ULC.

**Reference:** Most components use LDAP access as per https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/docs/components.md?ref_type=heads#identity-data-flows

> [!note]
> The direct access to LDAP is going to be deprecated for most use cases. openDesk plans to introduce active
> provisioning of the user/group data into the applications using [SCIM](https://scim.cloud/).

### Push: Provisioning

Some components require active provisioning of the centrally maintained IAM data. As the actual provisioning is part of the openDesk provisioning framework, it is necessary to define the ULC flow regarding its different states to get a matching provisioning connector implemented. This is done collaboratively between the supplier and openDesk product management.

**Reference:** New components will make use of the [provisioning framework](https://gitlab.opencode.de/bmi/opendesk/component-code/crossfunctional/univention/ums-provisioning-api). At the moment to only active (push) provisioned component is OX AppSuite fed by the [OX-connector](https://github.com/univention/ox-connector/tree/ucs5.0).

# Logging & Monitoring

Components MUST provide a [Prometheus](https://prometheus.io/) monitoring endpoint following the [OpenMetrics 1.0](https://prometheus.io/docs/specs/om/open_metrics_spec/) specification.

Grafana dashboard(s) MUST be provided for each component, visualizing the most relevant component-specific metrics.

Components MUST log only to stderr/stdout or MUST provide documentation which additional log locations need to be monitored by an operator.

Components MUST NOT log to a local file system inside a container.

# Features

## Non-overlapping functionality

openDesk aims to provide components that are excellent in *their main domain*. To avoid offering the same functionality multiple times in openDesk, components MUST support to disable certain functionality. There needs to be an assessment for each new component if it has overlapping functionality and how to deal with that.

**Reference:** Nextcloud’s internal contact management and Nextcloud Talk features are deactivated, as contact management is handled through OX App Suite, and chat, audio, and video conferencing are provided by Element and Jitsi.

## Functional administration

While components usually support technical and functional administration, the technical part SHOULD be in the responsibility of the operator and is usually done at (re)deployment time. Therefore, the administrative tasks within a component should be limited to functional administration.

Example for "technical administration":
- Configuring the SMTP relay for an application to send out emails.

Example of "functional administration":
- Creating and maintaining users and groups.

**Reference:** OpenProject took the approach that all settings pre-defined in the deployment are still rendered in the admin section of OpenProject, but can not be changed.

## Theming

Theming MUST be controlled with the deployment and affect all components that support branding options.

**Reference:** https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/develop/helmfile/environments/default/theme.yaml.gotmpl

## Central user profile

The user profile is maintained centrally, therefore the components SHOULD make use of that central data and not allow local editing of the data within the application, except for data that is required by the component and that cannot be provided by the central IAM.

The data can still be rendered but MUST NOT be tampered with in any way within components outside of the IAM, as it would either cause inconsistent data within openDesk or the changed data being overwritten, which is at least unexpected behaviour from the user's perspective.

The user's preferred language and theme (light/dark) are also selected in the IAM's portal and the setting SHOULD be respected in all components.

**Reference:** No reference yet.

# UI/UX

## Top bar

Components MUST provide a top bar for navigation. The top bar SHOULD provide a common UI and UX.

### Look and feel

Components MUST provide a top bar that can be customized (or adheres to a given openDesk standard) in various settings:

- Size (height) of the bar.
- Foreground and -background colors, including hover/active.
- Size and color of the bar's bottom line.
- Logo position, size, and link including the link's target.
- Icon position and size of the central navigation.
- Ideally have the user's menu on the right-hand side of the top bar using the user's profile picture.
- Have the search option/bar as the leftmost option in the right content section of the top bar or even allow the search bar to be rendered in the center of the top bar.

**Reference:** This is available in current deployments, see e.g. Nextcloud, Open-Xchange, and XWiki.

### Central navigation

Within the top bar, users MUST be able to access the central navigation: A menu that gets its content from the portal component, rendering the available applications to the logged-in user for direct access.

When implementing the central navigation into a component, there are two options to access the user's data from the portal:

- Frontend-based: Issuing an IFrame-based silent login against the intercom service (ICS) to get a session with the ICS, followed by a request for the JSON containing the user's central navigation contents through the ICS.
- Backend-based: Requesting the JSON using a backend call to the portal providing the user's name and a shared secret.

**Reference:** This is available in current deployments in all applications except for Jitsi, Collabora, and CryptPad.

# Security

## Software bill of materials (SBOMs)

openDesk provides in-depth SBOM for container images. Those SBOMs are scoped on a per-container basis. SBOMs SHOULD contain all software components present in the final image, even when obfuscated through static linking. False positives are expected.

Components MUST provide artifact and source code SBOMs in a standardized manner.

The SBOMs SHOULD use a current version - 1.7 at the time of writing - of the [CycloneDX](https://cyclonedx.org/tool-center/) format. CycloneDX is explicitly supported by openCode's [DevGuard](https://devguard.opencode.de/) toolchain.

### Artifact SBOMs

There are various free tools like [syft](https://github.com/anchore/syft) available to generate SBOMs for container images. Components MUST provide cryptographically signed artifact SBOMs for all container images delivered to be integrated into openDesk.

**Reference:** As part of [openDesk's standard CI](https://gitlab.opencode.de/bmi/opendesk/tooling/gitlab-config) a container image SBOM is derived from the container's content and gets signed. Both artifacts (SBOM and signature) are placed next to the image in the related registry ([example](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/semantic-release/container_registry/827)).

### Source code SBOMs

Today's software development platforms like GitLab or GitHub provide dependency list/graph features that are the basis for your source code SBOMs. These features are usually based on analysis of language-specific package manager dependency definition files. As part of a component supplier's software development process, source code SBOMs SHOULD at least be created on the level of the already defined software dependencies within the source code tree of the component.

**Reference:** Currently we do not have source code SBOMs in place.

## Software supply chain security

openDesk is going to implement [SLSA v1.2](https://slsa.dev/spec/v1.2/).

All component artifacts (i.e. container images, Helm charts, SBOM and VeX) MUST be signed and their signature MUST be verifiable based on the ZenDiS-provided secure key store.

**Reference:** The [openDesk standard CI](https://gitlab.opencode.de/bmi/opendesk/tooling/gitlab-config) ensures that each container image being built and each Helm chart being released is signed. In the case of container images, the related SBOMs are signed as well.

## Pod Security Standards (PSS)

[Pod Security Standards (PSS)](https://kubernetes.io/docs/concepts/security/pod-security-standards) MUST be supported. openDesk MUST support the operation of pods even when using Policy Level ["Restricted"](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted) & [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/).

## Deutsche Verwaltungscloud Strategie (DVS)

openDesk SHOULD be compliant with the "Deutsche Verwaltungscloud Strategie" (DVS) (German public authority cloud strategy). While this is a moving target it references some already established standards like the BSI's [IT-Grundschutz](https://www.bsi.bund.de/DE/Themen/Unternehmen-und-Organisationen/Standards-und-Zertifizierung/IT-Grundschutz/IT-Grundschutz-Kompendium/it-grundschutz-kompendium_node.html) and [C5](https://www.bsi.bund.de/DE/Themen/Unternehmen-und-Organisationen/Informationen-und-Empfehlungen/Empfehlungen-nach-Angriffszielen/Cloud-Computing/Kriterienkatalog-C5/C5_AktuelleVersion/C5_AktuelleVersion_node.html). These standards address hundreds of requirements which are published at the given links. So here's just a summary to understand the approach of the broadest requirements from IT-Grundschutz.

**Reference:** [DVS Rahmenwerk 3.0](https://www.cio.bund.de/SharedDocs/downloads/Webs/CIO/DE/cio-bund/steuerung-it-bund/beschluesse_cio-board/2025_01_CIO_Board_Anlagen.html)

## IT-Grundschutz

openDesk MUST be operatable conforming to the BSI IT-Grundschutz (IT baseline protection).

The IT-Grundschutz catalog knows a lot of modules ("Bausteine"), but not all of them apply to all components, as there are some related to hardware or some just relevant for the operator, while openDesk is "just" the software platform. The first step for an IT-Grundschutz evaluation of a component (or the platform as a whole) requires defining which modules are applicable. Other modules apply to all components e.g. [APP.4.4 Kubernetes](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Grundschutz/IT-GS-Kompendium_Einzel_PDFs_2023/06_APP_Anwendungen/APP_4_4_Kubernetes_Edition_2023.pdf), [SYS.1.6 Containerisierung](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Grundschutz/IT-GS-Kompendium_Einzel_PDFs_2023/07_SYS_IT_Systeme/SYS_1_6_Containerisierung_Edition_2023.pdf) and [CON.2 Datenschutz](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Grundschutz/IT-GS-Kompendium_Einzel_PDFs_2023/03_CON_Konzepte_und_Vorgehensweisen/CON_2_Datenschutz_Edition_2023.pdf).

Within each module are multiple requirements ("Anforderungen") that are usually composed of multiple partial requirements ("Teilanforderungen"). Each requirement has a given category:
- B for basic ("Basis") - the requirement must be fulfilled.
- S for standard ("Standard") - the requirement should also be fulfilled, if not there must be a good reason why it is not the case that does not tamper the security of the overall system. There is only a defined amount of deviations allowed for standard requirements.
- H for high ("Hoch") - in certain scenarios you have extended security requirements, in that case, the high requirements must be fulfilled. openDesk is working towards making that possible.

Different requirements address different roles in IT-Grundschutz.

- Supplier: processes & product (component -> e.g. Open-Xchange, OpenProject)
- Provider: processes & product (platform -> openDesk)
- Operator: processes & product (service)
- Customer: processes.

As a supplier of an openDesk component, you will focus on the "Supplier" requirements, while the outcome (your product) must enable the Provider to fulfill the requirements that lay with its responsibility for the openDesk platform. Operators use openDesk to provide a service, therefore the openDesk platform must enable an Operator to fulfill the related requirements. Finally, the service must enable the customer to align with the scope of the IT-Grundschutz catalog. So it will happen that a requirement from e.g. the customer level needs a specific capability by the product (Supplier's responsibility), a defined core configuration from the platform (Provider's responsibility), or a certain service setup from the Operator.

We are aware that IT-Grundschutz is a complex topic and are working towards a streamlined process to reduce overhead as much as possible and ensure to maximize the use of synergies.

**Reference:** https://gitlab.opencode.de/bmi/opendesk/documentation/it-grundschutz

# Accessibility

Accessibility is a key requirement for software that is being used in the public sector. Therefore the products of the suppliers MUST adhere to the relevant standards.

Please find more context about the topic on the [bund.de website](https://www.barrierefreiheit-dienstekonsolidierung.bund.de/Webs/PB/DE/gesetze-und-richtlinien/wcag/wcag_2_2/wcag-2-2-node.html) followed by a more detailed look at the actual accessibility standard [WCAG 2.2](https://www.w3.org/TR/WCAG22/).

Each vendor MUST provide a certificate that their component - or the parts of the component relevant for openDesk - complies with at least WCAG 2.1 AA or [BITV 2.0](https://www.bundesfachstelle-barrierefreiheit.de/DE/Fachwissen/Informationstechnik/EU-Webseitenrichtlinie/BGG-und-BITV-2-0/Die-neue-BITV-2-0/die-neue-bitv-2-0_node.html). As the certification and related accessibility improvements are time-consuming the focus of openDesk is that a supplier provides a plan and certification partner (contract) that shows the supplier is working towards the certification. While the aforementioned standard states the priority is the "A" level requirements, the "AA" level must be met at the end of the process.

> [!note]
> Please keep in mind that [WCAG 3.0 is work in progress](https://www.w3.org/TR/wcag-3.0/).
> If you already work on accessibility improvements you might want to take these standards
> already into consideration.

**Reference:** In the past the [accessibility evaluations](https://gitlab.opencode.de/bmi/opendesk/info/-/tree/main/24.03/Barrierefreiheit) have been executed by Dataport. But they do not do certifications.

# Data protection

Each component MUST be able to operate according to the [EU's General Data Protection Regulation (GDPR)](https://gdpr.eu/). This requires some key messages to be answered when it comes to personal data[^1]:

- Who are the affected data subjects?
- What personal data (attributes) from the subjects is being processed?
- Who is the controller and processor of the subject's data?
- Which processing activities involve which data attributes?
- How can the data be deleted?
- Are personal data-related activities traceable?
- How can data be provided uniformly to affected people?
- What does a data privacy-friendly configuration look like?

While this can be answered by each component that will be in the spotlight for the suppliers, we also need an aligned overall picture for openDesk that at least has the platform-specific user lifecycle and cross-application interfaces in focus.

Note: The topics of availability, integrity, and confidentiality of personal data are also being addressed by the IT-Grundschutz module "CON.2". It has to be ensured that it is not in contradiction to what is being done in the general area of data protection.

**Reference:** https://gitlab.opencode.de/bmi/opendesk/documentation/datenschutz

# Footnotes

^1: For definitions see [GDPR Article 4](https://gdpr.eu/article-4-definitions/).
