# University Apps: Extending OpenDesk for Higher Education

> **Note**: This document describes the original 4 university services (ILIAS, Moodle, BigBlueButton, OpenCloud). openDesk Edu now includes **13 education services**. For the complete list, see [README.md](../README.md).

**Philipps-Universität Marburg**

## Introduction

OpenDesk is an open-source, Kubernetes-based digital workplace suite originally designed for German public administration. At the University of Marburg (Philipps-Universität Marburg), we are extending OpenDesk beyond its government origins to serve as a **unified digital workplace for higher education**. This initiative integrates university-specific applications—such as learning management systems (LMS), video conferencing, and file sharing—alongside the standard OpenDesk suite, providing a seamless, single sign-on (SSO) experience for students, faculty, and staff.

This document explores the vision, architecture, technical decisions, and challenges of integrating university applications into OpenDesk. It is intended for a technical audience, particularly those attending LinuxTag, and demonstrates the power of open-source composability in adapting a government-focused platform for education.

---

## The Vision: One Portal, All Applications

Universities traditionally rely on a fragmented digital ecosystem: separate platforms for email, file sharing, collaboration, learning management, and video conferencing. This fragmentation creates friction for users, who must remember multiple URLs, credentials, and workflows. OpenDesk addresses this challenge by providing a **single portal** that unifies all these services under one roof.

At the University of Marburg, we leverage OpenDesk’s **Nubus portal** as the central entry point. The portal federates access to all integrated applications via SSO, ensuring users can navigate seamlessly between services without repeated logins. This approach not only improves user experience but also reduces administrative overhead and enhances security.

---

## Integrated University Applications

The following university-specific applications have been integrated into OpenDesk, each tailored to the needs of higher education:

| Application          | Purpose                          | Category         | Integration Method | Status       |
|----------------------|----------------------------------|------------------|--------------------|--------------|
| **ILIAS**            | Learning Management System (LMS) | Learning         | SAML 2.0 (Shibboleth SP) | ✅ Deployed  |
| **Moodle**           | Alternative LMS                  | Learning         | SAML 2.0 (Shibboleth SP) | ✅ Deployed  |
| **BigBlueButton**    | Video Conferencing               | Video            | SAML 2.0 (Shibboleth SP) | ✅ Deployed  |
| **OpenCloud**        | File Sync & Share (Nextcloud alternative) | Applications | OIDC (Keycloak)    | 🔧 In Progress |

### ILIAS LMS

**ILIAS** is a widely used learning management system at the University of Marburg. It provides course management, assessments, and collaborative learning tools.

- **Integration**: SAML 2.0 via Shibboleth Service Provider (SP) → Keycloak Identity Provider (IdP)
- **Portal Tile**: Located in the "Lernen" (Learning) category
- **URL**: `lms.opendesk.example.com`
- **Commits**: ~25 commits for SSO, portal integration, and end-to-end testing
- **Status**: Fully deployed and operational

### Moodle LMS

**Moodle** serves as an alternative to ILIAS, offering flexibility for courses that require different pedagogical tools.

- **Integration**: SAML 2.0 via Shibboleth SP → Keycloak IdP
- **Portal Tile**: Located in the "Lernen" (Learning) category
- **Custom Docker Image**: `ghcr.io/<your-org>/moodle:4.4-apache-shibboleth` (pre-installed with Shibboleth SP)
- **Backend**: PostgreSQL database, Ceph RBD storage for course data (100Gi)
- **Admin Interface**: Whitelisted with LDAP authentication
- **Status**: Fully deployed and operational

### BigBlueButton

**BigBlueButton** is a video conferencing platform designed for online lectures, seminars, and virtual classrooms.

- **Integration**: SAML 2.0 via Shibboleth SP → Keycloak IdP
- **Custom Docker Image**: `ghcr.io/<your-org>/bbb:2.7-shibboleth`
- **Storage**: CephFS for recordings (500Gi, RWX for multi-node access)
- **Portal Tile**: Located in the "Video" category
- **Status**: Fully deployed and operational

### OpenCloud

**OpenCloud** is an open-source file sync and share platform (a fork of ownCloud) that serves as a lightweight alternative to Nextcloud.

- **Integration**: OIDC via Keycloak (OpenCloud is OIDC-native)
- **Portal Tile**: Located in the "Anwendungen" (Applications) category
- **URL**: `opencloud.opendesk.example.com`
- **Custom Docker Image**: `ghcr.io/<your-org>/opencloud:v1.0.0`
- **OpenXchange Integration**: Enabled via `filestorage_owncloud_oauth` capability
- **Status**: Deployment in progress (fixes ongoing)

---

## Architecture Overview

The University Apps integration extends OpenDesk’s existing architecture, which is built on Kubernetes (OpenStack + Ceph) and designed for scalability, resilience, and data sovereignty. Below is a high-level overview of the architecture:

```
┌─────────────────────────────────────────────────────────┐
│                    Nubus Portal                          │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────────┐      │
│  │ Mail │ │Files │ │ Chat │ │Wiki  │ │ Learning │      │
│  │ (OX) │ │(NC)  │ │(Elem)│ │(XWiki│ │(ILIAS,   │      │
│  │      │ │(OC)  │ │      │ │      │ │ Moodle)  │      │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────────┘      │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────────┐      │
│  │Proj. │ │Video │ │Office│ │White-│ │(BBB)     │      │
│  │(OP)  │ │(Jitsi│ │(Colla│ │board │ │          │      │
│  │      │ │ BBB) │ │bora) │ │      │ │          │      │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────────┘      │
└────────────────────┬────────────────────────────────────┘
                     │ SSO (SAML 2.0 / OIDC)
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Keycloak Identity Provider                  │
│  ┌──────────────┐  ┌──────────────┐                     │
│  │ LDAP/AD User │  │  SAML Clients│  OIDC Clients      │
│  │ Directory    │  │ (ILIAS,      │  (OpenCloud,        │
│  │ (Univention  │  │  Moodle, BBB)│   Nextcloud)        │
│  │  UCS/DS)     │  │              │                     │
│  └──────────────┘  └──────────────┘                     │
└─────────────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Kubernetes (OpenStack + Ceph)                │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │Ceph RBD  │  │CephFS   │  │HAProxy  │  │Let's    │   │
│  │(SSD, RWO)│  │(HDD, RWX│  │Ingress  │  │Encrypt  │   │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Key Components

1. **Nubus Portal**: The central entry point for users, providing a customizable dashboard with access to all integrated applications.

2. **Keycloak Identity Provider**: The SSO backbone, federating authentication across all applications. It supports:
   - **SAML 2.0** for ILIAS, Moodle, and BigBlueButton
   - **OIDC** for OpenCloud, Nextcloud, and OpenProject
   - **LDAP/AD integration** for user directory synchronization via Univention Corporate Server (UCS)

3. **Kubernetes Cluster**: Hosted on OpenStack with Ceph storage for scalability and resilience:
   - **Ceph RBD (SSD, RWO)**: Used for database and stateful workloads (e.g., PostgreSQL for Moodle)
   - **CephFS (HDD, RWX)**: Used for shared file storage (e.g., BigBlueButton recordings)
   - **HAProxy Ingress**: Routes traffic to the appropriate services
   - **Let’s Encrypt**: Provides TLS encryption for all external endpoints

---

## SSO Architecture

Single sign-on is the cornerstone of the University Apps integration. Keycloak serves as the central Identity Provider (IdP), federating authentication across all applications using two primary protocols:

### SAML 2.0 Integration

**SAML 2.0** is used for applications that lack native OIDC support, such as ILIAS, Moodle, and BigBlueButton. The integration involves:

1. **Shibboleth Service Provider (SP)**: Deployed as an Apache module, the Shibboleth SP translates SAML assertions from Keycloak into HTTP headers (e.g., `REMOTE_USER`). This allows the application to authenticate users without modifying its codebase.
2. **Custom Docker Images**: Each SAML-integrated application (ILIAS, Moodle, BigBlueButton) uses a custom Docker image with Shibboleth SP pre-installed and configured.
3. **Keycloak as IdP**: Keycloak acts as the SAML 2.0 IdP, issuing assertions to the Shibboleth SP upon successful authentication.

### OIDC Integration

**OIDC** is used for modern, cloud-native applications like OpenCloud and Nextcloud. The integration is simpler and more direct:

1. **Keycloak as OIDC Provider**: Keycloak issues OIDC tokens to clients.
2. **Native OIDC Support**: Applications like OpenCloud and Nextcloud natively support OIDC, allowing seamless integration without additional middleware.

### Group-Based Access Control

Access to portal tiles and applications is controlled via **group memberships** in Keycloak. Groups are mapped to Univention Directory Manager (UDM) attributes, ensuring fine-grained control over who can access which applications. For example:

- `managed-by-attribute-students`: Grants access to learning management systems
- `managed-by-attribute-faculty`: Grants access to video conferencing and project management tools

### Backchannel Logout

Backchannel logout ensures that user sessions are terminated across all applications when a user logs out of the portal. This is critical for maintaining security and session hygiene.

---

## Key Technical Decisions

Integrating university applications into OpenDesk required several technical decisions to ensure scalability, maintainability, and security. Below are the most impactful choices:

### 1. Shibboleth SP for Legacy Applications

**Problem**: Many university applications, such as ILIAS and Moodle, lack native OIDC support and rely on SAML 2.0 for federated authentication.

**Solution**: Deploy **Shibboleth Service Provider (SP)** as an Apache module alongside each application. The Shibboleth SP translates SAML assertions from Keycloak into HTTP headers, allowing the application to authenticate users without code changes.

**Implementation**:

- Custom Docker images for ILIAS, Moodle, and BigBlueButton with Shibboleth SP pre-installed (`ghcr.io/<your-org>/ilias:7.28-shibboleth`, `ghcr.io/<your-org>/moodle:4.4-apache-shibboleth`, `ghcr.io/<your-org>/bbb:2.7-shibboleth`)
- Configuration files (`shibboleth2.xml`) tailored to each application’s requirements

### 2. Ceph Dual Storage Strategy

**Problem**: University applications have diverse storage requirements. Some, like Moodle, require fast, block-level storage (RWO), while others, like BigBlueButton, need shared file storage (RWX) for multi-node access.

**Solution**: Leverage **Ceph** for both block and file storage:

- **Ceph RBD (SSD-backed)**: Provides **ReadWriteOnce (RWO)** access for databases (e.g., PostgreSQL for Moodle) and stateful workloads
- **CephFS (HDD-backed)**: Provides **ReadWriteMany (RWX)** access for shared file storage (e.g., BigBlueButton recordings)

**Implementation**:

- Moodle: Ceph RBD for database storage (100Gi)
- BigBlueButton: CephFS for recordings (500Gi)

### 3. OpenCloud as a Nextcloud Alternative

**Problem**: While Nextcloud is a robust file sync and share platform, its PHP-based architecture and resource requirements make it less ideal for some university use cases.

**Solution**: Adopt **OpenCloud**, a Go-based fork of ownCloud, as a lightweight alternative. OpenCloud offers:

- Native OIDC integration via Keycloak
- Lower resource consumption
- Direct integration with OpenXchange via the `filestorage_owncloud_oauth` capability

**Implementation**:

- Custom Docker image (`ghcr.io/<your-org>/opencloud:v1.0.0`)
- OIDC integration with Keycloak
- Portal tile in the "Anwendungen" (Applications) category

### 4. Helmfile-Based Deployment

**Problem**: Managing deployments for multiple applications with interdependent configurations (e.g., hostnames, secrets, resources) can quickly become complex.

**Solution**: Follow OpenDesk’s **helmfile-based deployment** pattern. Each application is defined as a helmfile "app" with **gotmpl** templates that reference global configuration values (e.g., domains, secrets, resource limits).

**Implementation**:

- Helmfiles for ILIAS, Moodle, BigBlueButton, and OpenCloud
- Global values (`values.yaml`) for shared configurations
- Overrides for app-specific settings

### 5. Value Coalescing and Conflict Resolution

**Problem**: Conflicts arise when chart default values (e.g., manifests as `map` types) clash with app-level overrides (e.g., secrets as `string` types).

**Solution**: Implement a **strict value coalescing strategy** to ensure consistency:

- Use `tpl` functions in Helm templates to render values dynamically
- Define clear precedence rules: app-level overrides > chart defaults > global defaults
- Validate configurations during CI/CD pipelines

---

## Challenges and Lessons Learned

Integrating university applications into OpenDesk presented several technical and operational challenges. Below are the key lessons learned:

### 1. Helm Template Whitespace Trimming

**Challenge**: Go template directives like `{{- if` and `-}}` can inadvertently merge YAML document separators (`---`) with comments, causing parse failures.

**Solution**:

- Use explicit whitespace control: `{{` and `}}` to avoid merging lines
- Test Helm templates locally with `helm template --debug` before deployment
- Document template formatting guidelines for future contributors

### 2. Ceph RBD Access Modes

**Challenge**: The `ReadWriteOncePod` access mode, which ensures a volume is mounted to only one pod, is not supported by the Ceph RBD CSI driver.

**Solution**:

- Use standard `ReadWriteOnce` (RWO) for all RBD-backed PVCs
- Implement pod anti-affinity rules to ensure workloads are scheduled on the same node

### 3. PVC Immutability

**Challenge**: Kubernetes PersistentVolumeClaims (PVCs) are immutable with respect to access modes and volume modes. Changing these properties on an existing PVC requires deleting and recreating it.

**Solution**:

- Plan PVC configurations carefully before deployment
- Use Helm hooks to manage PVC lifecycle during upgrades
- Document rollback procedures for PVC-related changes

### 4. UDM Portal Entry API Limitations

**Challenge**: The Univention Directory Manager (UDM) portal entry API has limited property support:

- `icon_url` is not supported (must use theme registry instead)
- DN (Distinguished Name) case sensitivity issues with `allowedGroups`

**Solution**:

- Use theme registry for icons instead of direct URLs
- Normalize group DNs to lowercase before referencing them in portal entries

### 5. Value Coalescing Conflicts

**Challenge**: Conflicts between chart default values (e.g., `map` types) and app-level overrides (e.g., `string` types) can break deployments.

**Solution**:

- Use `tpl` functions in Helm templates to render values dynamically
- Define strict type coercion rules in `values.yaml`
- Validate configurations during CI/CD pipelines

---

## Why This Matters for LinuxTag

The University Apps integration demonstrates the **power of open-source composability**. OpenDesk, originally designed for government digital workplaces, has been successfully adapted for higher education with minimal friction. This project is relevant to LinuxTag for several reasons:

### 1. Open-Source as a Foundation for Innovation

OpenDesk is built on open-source components—Kubernetes, Ceph, Keycloak, and more—which provide the flexibility to customize and extend the platform for new use cases. This project shows how open-source software can **transcend its original scope** and serve entirely new domains, such as education.

### 2. Breaking Down Silos

Universities often struggle with fragmented digital ecosystems. By integrating disparate applications—LMS, video conferencing, file sharing, and collaboration tools—into a **single portal with SSO**, OpenDesk eliminates silos and reduces friction for users. This approach improves user experience, enhances security, and reduces administrative overhead.

### 3. Data Sovereignty and On-Premise Control

Unlike proprietary cloud solutions, OpenDesk is **on-premise**, ensuring full control over data and infrastructure. This is particularly important for universities, where data privacy and compliance are critical. By leveraging Kubernetes and Ceph, OpenDesk provides a **scalable, resilient, and vendor-neutral** platform.

### 4. Community-Driven Development

The University Apps integration is a collaborative effort, involving contributions from developers, administrators, and end-users. This project exemplifies the **strength of the open-source community** in solving real-world problems through shared effort and innovation.

### 5. A Blueprint for Other Institutions

The patterns and tools used in this project—helmfile deployments, Keycloak SSO, Ceph storage—can serve as a **blueprint for other universities and institutions** looking to unify their digital workplaces. The modular architecture of OpenDesk makes it adaptable to a wide range of use cases beyond education.

---

## Future Directions

The University Apps integration is just the beginning. Several exciting directions are on the horizon:

### 1. Deepening OpenXchange ↔ OpenCloud Integration

- Enable **file storage backend** sharing between OpenXchange and OpenCloud
- Support **calendar and contact synchronization** between the two platforms
- Explore **real-time collaboration** features (e.g., shared documents)

### 2. Exam Management Integration

- Integrate **exam management systems** (e.g., EvaExam, ONYX) into the OpenDesk portal
- Support **secure exam environments** with lockdown browsers and proctoring tools
- Enable **automated grading and feedback** workflows

### 3. Library System Integration

- Integrate **OPAC (Online Public Access Catalog)** systems for library access
- Support **digital lending** and resource management
- Enable **research data management** for faculty and students

### 4. Student Information System (HIS/LSF) Integration

- Integrate **campus management systems** (e.g., HISinOne, LSF) for course enrollment and scheduling
- Support **automated course provisioning** in ILIAS and Moodle
- Enable **student lifecycle management** (enrollment, grading, graduation)

### 5. Automated Course Provisioning

- Develop **automated workflows** to provision courses in ILIAS and Moodle based on campus management system data
- Support **role-based access control** (e.g., instructors, students, TAs)
- Enable **template-based course creation** for consistency

---

## Conclusion

The University Apps integration into OpenDesk at the University of Marburg demonstrates how open-source platforms can be extended beyond their original scope to serve new domains. By unifying learning management, video conferencing, file sharing, and collaboration tools under a single portal with SSO, OpenDesk provides a **seamless, user-friendly digital workplace** for higher education.

This project is a testament to the **power of open-source composability**, showing how government-focused tools can be adapted for education with minimal friction. The lessons learned—from SSO architecture to storage strategies—can serve as a blueprint for other institutions looking to modernize their digital ecosystems.

At LinuxTag, this presentation aims to inspire others to explore open-source solutions for their own challenges, whether in education, government, or beyond. The future of digital workplaces lies in **unity, sovereignty, and openness**—and OpenDesk is paving the way.

---

**Philipps-Universität Marburg**
**OpenDesk University Apps Team**
