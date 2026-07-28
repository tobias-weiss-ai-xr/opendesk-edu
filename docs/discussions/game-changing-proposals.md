# Game-Changing Proposals for openDesk CE

## 1. 🔥 Systematic Bitnami Migration

**Problem:** Bitnami removed versioned images from Docker Hub (e.g., `bitnami/mariadb:11.4.4-debian-12-r3` is gone). CE still depends on Bitnami for mariadb, postgresql, redis, elasticsearch, and more. This is a ticking time bomb — next `helmfile sync` could fail.

**Proposal:** Replace all Bitnami subchart dependencies with direct StatefulSet templates using official base images — same pattern we implemented for Edu's ILIAS and Bookstack.

**Impact:** Deployment resilience, no external registry dependency, full control over DB configs.
**Effort:** Medium (systematic, repetitive work)

---

## 2. 🏗️ Unified Chart Repository

**Problem:** CE, Edu, SME, Sec each maintain fork-based chart trees. Fixes in one don't propagate. Bitnami migration has to be done 4×.

**Proposal:** Extract all charts into a single `opendesk/charts` repository with semantic versioning. Variants pin specific chart versions and only maintain overlay values. ArgoCD App of Apps pattern with shared Helmfile.

**Impact:** One fix → all variants benefit. Reduces maintenance from 4× to 1×.
**Effort:** Large (restructuring), but pays for itself within months.

---

## 3. 🔐 Verifiable Credential Identity Layer

**Problem:** Every service call to check a user's group/role hits LDAP or Keycloak. Cross-service authorization is fragile (NetworkPolicies + OIDC claims).

**Proposal:** Issue Verifiable Credentials (VCs) for user attributes (role, group, student ID) signed by the identity provider. Services verify VCs offline using the issuer's public key. BundID/EUDI Wallet integration is the on-ramp.

**Impact:** Offline authorization, reduced LDAP load, portable identity across clusters. eIDAS 2.0 compliance.
**Effort:** Large (new service), but Phase 1 (bundID SAML) is already deployed at HRZ.

---

## 4. 📊 Built-in Cost Transparency

**Problem:** openDesk hosting providers (HRZ, DFN, etc.) need to show per-service resource costs to their customers. Currently no visibility.

**Proposal:** Add a `opendesk-cost-exporter` that reads K8s resource metrics + PVC sizes + ingress bandwidth and exposes Prometheus metrics with labels per service (app.kubernetes.io/instance). Bundle with a pre-built Grafana dashboard.

```promql
sum by (app) (container_memory_working_set_bytes * on(node) kube_node_price_per_hour)
```

**Impact:** Enables hosting business models. Each service shows its exact cost.
**Effort:** Medium (exporter service + dashboards).

---

## 5. 📦 Declarative Semester/Term Provisioning (GitOps)

**Problem:** Edu deployments run imperative scripts for semester provisioning (HISinOne → LDAP → Keycloak → Services). No audit trail, hard to rollback.

**Proposal:** A Kubernetes operator that watches a `Semester` CRD. User/group state is declared in YAML. The operator reconciles:
- LDAP entries via UDM REST API
- Keycloak group assignments
- Service-specific provisioning (ILIAS course creation, Moodle cohort sync)

```yaml
apiVersion: opendesk.org/v1
kind: Semester
metadata:
  name: ws2026
spec:
  courses:
    - id: "CS101"
      students: ["group:cs-students-ws2026"]
      teachers: ["group:cs-lecturers"]
      services:
        ilias: true
        moodle: true
```

**Impact:** Full GitOps traceability. Rollback is `git revert`. No more SSH-into-pod scripts.
**Effort:** Large (operator development), but solves the #1 operational pain point for edu.

---

## 6. 🔄 Deprecation Path for Nubus/UMS

**Problem:** Nubus (Univention) is the largest third-party dependency in openDesk. Complex licensing, heavy resource footprint, single vendor. Community deployments without Nubus need a lighter alternative.

**Proposal:** Define a **Nubus-free deployment profile** that replaces UDM with:
- Keycloak (already exists) + LDAP (already exists)
- A lightweight provisioning service (~100 lines of Python/Go)
- UMC functionality replaced by ArgoCD + standard K8s tooling

**Impact:** Reduces resource footprint by ~60%. Eliminates vendor lock-in. Enables truly open-source openDesk.
**Effort:** Very Large (multiple services), but incremental — start with one service at a time.

---

## 7. 🔌 Pluggable Event Bus for Service-to-Service Integration

**Problem:** Inter-service communication is ad-hoc (direct REST calls, hardcoded URLs, shared secrets). Adding a new service requires modifying existing services.

**Proposal:** Deploy a lightweight event bus (NATS — already in use for provisioning) as the backbone for all service-to-service events. Define standard event types:
- `user.created`, `user.deleted`, `user.group_changed`
- `course.created`, `course.enrollment_changed`
- `password.changed`, `email.verified`

Services subscribe to relevant events instead of polling LDAP or making REST calls.

**Impact:** Loose coupling. New services integrate by subscribing to events, not by modifying existing code.
**Effort:** Medium (event schema design + adapter for existing services).

---

## 8. 🔬 Observability as Code

**Problem:** Monitoring is bolted on. Dashboards are created manually. Alerts are not versioned.

**Proposal:** Every Helm chart ships with:
- A `servicemonitor.yaml` (Prometheus operator)
- A `grafanadashboard.yaml` (Grafana operator) with dashboard JSON baked in
- A `prometheusrule.yaml` with SLO-based alerts
- Structured JSON logging (not ad-hoc log formats)

**Impact:** `helmfile sync` deploys the service AND its monitoring. Dashboards are versioned alongside the chart.
**Effort:** Medium (adding dashboards to existing charts).

---

## Discussion Questions for the Community

1. Which of these resonates most with current CE roadmap priorities?
2. Are there overlapping initiatives already in progress?
3. Which proposal would you like to see a concrete implementation plan for?
4. Is there appetite for a regular "Architecture Sync" meeting to coordinate cross-variant development?

---

*Prepared by openDesk Edu (HRZ Marburg) — July 2026*
*Based on operational experience with 25+ services across Edu, CE, and SME deployments.*
