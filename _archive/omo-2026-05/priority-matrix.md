# OpenDesk Priority Matrix

**Last Updated**: 2026-04-09
**Environment**: HRZ (opendesk.hrz.uni-marburg.de) + edu + sme
**Context**: Post-1.12.0 upgrade, platform modernization, alternative tooling evaluation

---

## Priority Matrix

| Task | Priority | Status | Impact | Effort | Due |
|------|----------|--------|--------|--------|-----|
| Task | Priority | Status | Impact | Effort | Due |
|------|----------|--------|--------|--------|-----|
| Fix udm-transformer LDAP config | 🔴 Critical | ✅ COMPLETE | High | Medium | Today |
| Clear pending backup jobs | 🔴 Critical | ✅ COMPLETE | Medium | Low | Today |
| Clean up terminating PVCs | 🟡 Medium | ✅ COMPLETE | Low | Low | This week |
| Deploy opendesk-compose | 🟡 Medium | ⚠️ NOT APPLICABLE | High | Medium | TBD |
| Deploy moodle-integration | 🟢 Low | Pending | Medium | Low | Next sprint |
| Verify user-import deprovision | 🟢 Low | Pending | Medium | Medium | Next sprint |
| **Evaluate Plane as OpenProject alternative** | 🟡 Medium | 🔍 Evaluate | High | Medium | Q2 2026 |
| **Platform upgrade 1.12.2 → 1.13.2** | 🔴 High | 🔄 In progress | High | High | Q2 2026 |

---

## Task Details

### 🔴 Today (Critical)

#### 1. Fix ums-provisioning-udm-transformer LDAP Configuration
- **Status**: CrashLoopBackOff (1,449 restarts)
- **Issue**: Missing LDAP configuration parameters in ConfigMap
- **Impact**: UDM transformations not functional
- **Root Cause**: ConfigMap missing required fields

**Missing Parameters:**
- `ldap_host`
- `ldap_port`
- `ldap_tls_mode`
- `ldap_base_dn`
- `ldap_bind_dn`
- `ldap_bind_pw`

**Next Steps:**
1. Check UDM REST API secret for LDAP credentials
2. Update ConfigMap with missing environment variables
3. Restart deployment
4. Verify pod comes up healthy

---

#### 2. Clear Pending Backup Jobs
- **Status**: 14+ jobs stuck in Pending state
- **Issue**: `backup-backup-live-backup-*` pods not scheduling
- **Duration**: 14h to 3d14h
- **Impact**: Backup operations not completing

**Stuck Jobs:**
- backup-backup-live-backup-8fpgj-* (3 pods, 38h stuck)
- backup-backup-live-backup-gspzp-* (3 pods, 14h stuck)
- backup-backup-live-backup-kfm8z-* (2 pods, 3d14h stuck)
- backup-backup-live-backup-xbfkq-* (3 pods, 2d14h stuck)

**Next Steps:**
1. Identify why jobs are pending (kubectl describe pod)
2. Batch delete pending backup pods
3. Verify backup schedule continues
4. Monitor for healthy backup operations

---

### 🟡 This Week (Medium Priority)

#### 3. Clean Up Terminating PVCs
- **Status**: 6 PVCs stuck in Terminating state
- **Issue**: OpenProject pods leaving temporary PVCs behind
- **Impact**: Storage not being cleaned up properly
- **Duration**: Various (4d to 44d stuck)

**Affected PVCs:**
- openproject-seeder-14-dvn6s-app-tmp (4d)
- openproject-seeder-14-dvn6s-tmp (4d)
- openproject-web-96cd98989-225f2-app-tmp (44d)
- openproject-web-96cd98989-225f2-tmp (44d)
- openproject-worker-default-69876b87-8qbnv-app-tmp (44d)
- openproject-worker-default-69876b87-8qbnv-tmp (44d)

**Next Steps:**
1. Verify no pods still using these PVCs
2. Force delete stuck PVCs
3. Implement monitoring for stale PVCs
4. Document recovery procedures

---

#### 4. Deploy opendesk-compose
- **Status**: Implementation complete, deployment pending
- **Issue**: Not yet deployed to test environment
- **Impact**: Comprehensive testing environment missing
- **Effort**: Medium (requires Docker Compose setup)

**Implementation Status**:
- ✅ docker-compose.yml validated
- ✅ All containers run as non-root users
- ✅ All Docker images use specific version tags
- ✅ Resource limits configured
- ✅ Healthchecks present

**Next Steps:**
1. Deploy: docker-compose up -d
2. Monitor service health: docker-compose ps
3. Verify HTTPS/TLS certificates
4. Test SSO login functionality
5. Test backup/restore procedures

---

### 🟢 Next Sprint (Low Priority)

#### 5. Deploy moodle-integration
- **Status**: Helm chart ready, deployment pending
- **Issue**: Production LDAP/ingress configuration needed
- **Impact**: Moodle integration missing
- **Effort**: Low (Prerequisites: Helm chart deployed)

**Implementation Status**:
- ✅ Chart structure with templates
- ✅ Values.yaml configuration
- ✅ LDAP integration setup
- ✅ Resource limits (1000m CPU, 2Gi RAM)
- ✅ Ingress configuration
- ✅ K8up backup annotations
- ✅ README documentation

**Location**: /home/weissto_local/git/opendesk_git/charts-upgrade-v1.12.0/opendesk-moodle/

**Next Steps:**
1. Deploy Helm chart to test environment
2. Verify LDAP authentication
3. Verify ingress configuration
4. Verify backup operations
5. Update documentation

---

#### 6. Verify user-import deprovision
- **Status**: Implementation complete, verification pending
- **Issue**: Requires UDM/Keycloak API access for testing
- **Impact**: Deprovisioning scripts not validated
- **Effort**: Medium (requires test environment setup)

**Implementation Status**:
- ✅ deprovision_disable.py - User disable script
- ✅ deprovision_delete.py - User deletion script
- ✅ Ucs class methods updated
- ✅ Keycloak integration functions
- ✅ README.md updated with usage examples
- ✅ Verification documentation created

**Location**: /home/weissto_local/git/opendesk_git/user_import/VERIFICATION.md

**Environment Requirements**:
- Access to UCS/Keycloak APIs
- pytest installation for automated testing
- Testing environment with test users

**Next Steps:**
1. Set up Python testing environment
2. Install pytest and dependencies
3. Run tests in staging environment
4. Validate user disable/delete workflows
5. Update documentation with test results

---

#### 7. Evaluate Plane as OpenProject Alternative (ALL VARIANTS)

- **Status**: Evaluation phase
- **Scope**: HRZ, edu, SME — all deployment variants
- **Repository**: https://github.com/makeplane/plane
- **Impact**: Potential replacement or complement for OpenProject
- **Effort**: Medium

**Plane Overview:**
- Open-source project management (issues, cycles, modules, pages, docs)
- Self-hostable, PostgreSQL backend
- REST & WebSocket APIs
- LDAP/SSO integration available
- Active development, MIT license

**Comparison vs OpenProject:**

| Feature | OpenProject | Plane |
|---------|-------------|-------|
| License | GPL-3.0 (non-enterprise) | MIT |
| Self-host | ✅ Helm available | ✅ Docker/K8s |
| LDAP/SSO | ✅ Keycloak OIDC | ✅ (check OIDC depth) |
| Work packages | ✅ Full-featured | ✅ Issues + Cycles |
| Gantt/Charts | ✅ Built-in | ⚠️ Roadmap (limited) |
| Wiki | ❌ Separate (XWiki) | ✅ Pages built-in |
| API | ✅ REST v3 | ✅ REST + WebSocket |
| UI | Enterprise-style | Modern, Jira-like |
| Resource mgmt | ✅ Advanced | ❌ Basic |
| Time tracking | ✅ Built-in | ✅ Built-in |
| Email integration | ✅ SMTP | ✅ (via config) |

**Evaluation Tasks:**
1. Deploy Plane to staging (Docker Compose or K8s)
2. Test Keycloak OIDC integration
3. Evaluate data migration from OpenProject
4. Assess LDAP group sync capabilities
5. Compare UX for academic/university use case
6. Check backup/restore story
7. Evaluate API for automation/integration
8. Test with real project data from HRZ/edu/SME

**Decision Criteria:**
- OIDC/Keycloak integration quality
- LDAP group provisioning support
- Migration path from OpenProject data
- Long-term maintenance burden
- User acceptance (academic UX expectations)

**Next Steps:**
1. Spin up Plane staging instance
2. Configure Keycloak OIDC
3. Import sample OpenProject data
4. Run 2-week evaluation with power users
5. Document findings and recommendation

---

## Dependencies

| Task | Blocks | Blocked By |
|------|--------|------------|
| Fix udm-transformer LDAP config | UDM transformations | None |
| Clear pending backup jobs | Backup operations | None |
| Clean up terminating PVCs | Storage management | Clear pending backup jobs |
| Deploy opendesk-compose | Testing environment | None |
| Deploy moodle-integration | Moodle availability | opendesk-compose |
| Verify user-import deprovision | Production deprovisioning | opendesk-compose |

---

## Progress Tracking

### Week of Feb 24 - Feb 28, 2026

### Week of Feb 24 - Feb 28, 2026

- [x] Priority matrix created
- [x] Fix udm-transformer LDAP config (CONFIGURATION COMPLETE ✅)
- [x] Clear pending backup jobs (COMPLETE ✅)
- [x] Clean up terminating PVCs (AUTO-RESOLVED ✅)
- [ ] Deploy opendesk-compose (NOT APPLICABLE - requires separate test environment)
- [x] **Analyze Tasks 5 & 6** (ANALYSIS COMPLETE ✅ - 2026-02-27)
  - Task 5: moodle-integration - ⚠️ BLOCKED (chart files missing)
  - Task 6: user-import deprovision - ⚠️ PARTIAL (code review complete)
- [ ] Deploy moodle-integration (BLOCKED - chart files missing from repo)
- [ ] Verify user-import deprovision (PARTIAL - runtime testing requires environment)

## Notes

- All PVCs in "Terminating" state should be cleaned up after clearing pending jobs
- The NATS JetStream issue was previously fixed (6 streams operational, 2 consumers created)
- Backup operations should stabilize after clearing pending jobs
- Monitor system for 24-48 hours after each fix to ensure stability
- Documentation for all procedures exists in various *.md files

---

## Related Documentation

- Current Issues: opendesk/TODO.md
- Upgrade Report: opendesk/UPGRADE_VERIFICATION_REPORT.md
- Upgrade Summary: UPGRADE_SUMMARY.md
- User Import Docs: user_import/VERIFICATION.md
- Compose Validation: opendesk-compose/VALIDATION.md