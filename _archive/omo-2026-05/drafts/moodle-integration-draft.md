# Draft: Moodle LMS Integration into OpenDesk

## Requirements (confirmed)
- **Authentication**: LDAP only (connect to OpenLDAP)
- **User sync**: LDAP polling (periodic fetch from OpenLDAP)
- **Database**: Bundled MariaDB subchart (self-contained deployment)
- **Scale**: 100-500 users (medium deployment)
- **Course management**: Manual only (no sync from OpenDesk)
- **Completion data**: No sync back to OpenDesk

## Technical Decisions
- Use Bitnami Moodle Helm chart as base, customized for OpenDesk patterns
- Follow opendesk-nextcloud integration pattern (LDAP auth + no provisioning)
- Bundle MariaDB subchart for database
- Resource sizing: 1000m CPU, 2Gi RAM, 50Gi storage
- No moodle-connector service (no active provisioning)
- No course sync from OpenDesk
- No completion data sync back

## Research Findings

### OpenDesk Architecture
- Helm chart-based deployment with Helmfile orchestration
- Nubus IAM: OpenLDAP (user store) + Keycloak (OIDC provider)
- Provisioning API + NATS messaging for user/group provisioning
- Most apps use LDAP polling (Nextcloud, OpenProject, XWiki)
- Only OX AppSuite uses active provisioning via ox-connector
- Otterize for service mesh policies
- K8up for backups
- Quality gates: REUSE headers, yamllint, kube-linter, Kyverno policies, E2E tests

### Moodle Technical Details
- Bitnami Docker image: `bitnami/moodle:5.0.2-debian-12-r1`
- REST API for user/course/enrollment management
- Authentication: LDAP, OAuth2, SAML2 plugins
- Requires MySQL/MariaDB database
- Two PVs: `/bitnami/moodle` (app code), `/bitnami/moodledata` (user content)
- Resources: 500m CPU / 1Gi RAM minimum

## Open Questions
- Authentication method preference: LDAP only vs. LDAP + Keycloak OIDC?
- Provisioning approach: LDAP sync (simple) vs. active provisioning (complex)?
- Database: Use bundled MariaDB subchart or external database service?
- User scale: Expected number of concurrent users for resource sizing?
- Course sync: Any requirements to sync courses from OpenDesk to Moodle?
- Completion tracking: Need Moodle completion data pushed back to OpenDesk?

## Scope Boundaries
### IN scope:
- Deploy Moodle LMS via Helm chart
- LDAP authentication integration with OpenLDAP
- Resource configuration for 100-500 users
- Persistent storage for Moodle data
- Ingress configuration for external access
- OTTERIZE ClientIntents for service mesh policies
- K8up backup integration
- REUSE headers, yamllint, kube-linter checks
- README documentation

### OUT scope:
- Active provisioning via moodle-connector service
- Keycloak OIDC integration
- Course sync from OpenDesk
- Completion data sync to OpenDesk
- Moodle REST API integration (external callers)
- External database service
- SAML2 authentication
- Course enrollment automation
- Moodle plugin/custom development