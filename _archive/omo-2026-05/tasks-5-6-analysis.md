# Analysis: Tasks 5 & 6 from Priority Matrix

**Generated**: 2026-02-27
**Context**: Remaining low-priority tasks after completing critical fixes

---

## Task 5: Deploy moodle-integration

### Current Status Analysis

**Legend from completion-status.md:**
- ✅ Helm chart created (28 tasks completed)
- ✅ All quality gates passed (helm lint, yamllint, REUSE headers)
- ✅ README documentation written
- ✅ Helmfile integration completed
- 📍 Chart location: `charts-merge_1112_upstream/opendesk-moodle/` (from documentation)

**Problem Discovered:**
```bash
$ find . -type d -name "*moodle*" | grep -v ".git"
./.sisyphus/notepads/moodle-integration
```
**The Helm chart directory does NOT exist in the current repository.**

**What Happened:**
- A plan was created (`.sisyphus/plans/moodle-integration.md` - 892 lines)
- Implementation was marked complete in `completion-status.md`
- But the actual chart files were never committed to the repository
- This appears to be a planning/documentation artifact only

### Research Findings

**Existing Moodle References:**
1. `opendesk/CHANGELOG.md`: Mentions Moodle integration added (portal tiles, OIDC client configured)
2. `.sisyphus/plans/moodle-integration.md`: Comprehensive 892-line plan exists
3. `.sisyphus/notepads/moodle-integration/completion-status.md`: Claims completion but no files found

**Current Cluster Status:**
- ✅ Kubernetes context: `default` (access available)
- ✅ Helm installed: v3.19.0
- ✅ opendesk namespace exists (Active, 193 days)
- ✅ Multiple services deployed (cert-manager, Nextcloud, OpenProject, etc.)
- ❌ No Moodle Helm release found in opendesk namespace

**Dependencies Identified:**
- LDAP authentication: Use `ums-ldap-server-proxy` service pattern
- MariaDB: Bundled subchart (self-contained)
- Resource limits: 1000m CPU, 2Gi RAM (from plan)
- Storage: 50Gi total (30Gi moodle-data + 20Gi moodledata-data)

### Requirements for Deployment

**Missing Pieces:**
1. **Helm Chart Does Not Exist** - Must be created from scratch or located
2. **Ingress Configuration** - Needs actual hostname (placeholder in plan)
3. **LDAP Secret** - Current LDAP bind credentials needed
4. **Helmfile Integration** - Not found in `opendesk/helmfile/apps/`
5. **Portal Tiles** - Static assets for portal display (mentioned in CHANGELOG)

**Options:**
1. **Re-implement from plan** - Use existing 892-line plan as spec, recreate all files
2. **Check staging/other branches** - Chart might exist in other Git branches
3. **Request chart from team** - Contact development team for missing files
4. **Skip Moodle deployment** - Requires significant effort, low priority accessibility feature

---

## Task 6: Verify user-import deprovision

### Current Status Analysis

**Implementation Status:**
- ✅ Scripts implemented and documented
- ✅ README.md updated with usage examples (lines 113-211)
- ✅ VERIFICATION.md created (131 lines, 25 verification items)
- ✅ All required methods present in lib files

**Implementation Verification:**

| Component | Method/Function | Status | Location |
|-----------|----------------|--------|----------|
| Ucs class | `disable_user()` | ✅ Line 469 | `user_import/lib/ucs.py` |
| Ucs class | `update_user_description()` | ✅ Line 520 | `user_import/lib/ucs.py` |
| Ucs class | `remove_groups_except()` | ✅ Line 548 | `user_import/lib/ucs.py` |
| Keycloak | `remove_saml_identity()` | ✅ Line 81 | `user_import/lib/keycloak.py` |
| Keycloak | `remove_saml_identity_with_credentials()` | ✅ Line 130 | `user_import/lib/keycloak.py` |
| Script | `deprovision_disable.py` | ✅ 415 lines | `user_import/deprovision_disable.py` |
| Script | `deprovision_delete.py` | ✅ Confirmed exists | `user_import/deprovision_delete.py` |

**Documentation Status:**
- ✅ README.md has comprehensive deprovisioning section (lines 113-211)
- ✅ Usage examples documented for both phases
- ✅ VERIFICATION.md lists 25 verification procedures
- ✅ Environment requirements documented

### Current Environment Status

**Python Environment:**
```bash
$ ls -la user_import/.venv/bin/python*
lrwxrwxrwx 1 weissto_local python -> python3
lrwxrwxrwx 1 weissto_local python3 -> /usr/bin/python3
lrwxrwxrwx 1 weissto_local python3.11 -> /usr/bin/python3  # Broken venv
```
**Problem:** venv exists but is broken (ensurepip not available, venv package missing)

**Dependencies:**
```python
# user_import/requirements.txt
requests
pandas
configargparse
pytest
odfpy
```
**Problem:** Dependencies not installed in venv

**Test Infrastructure:**
- ✅ Test directory exists: `user_import/tests/`
- ✅ Test files present: `test_keycloak.py`, `test_ucs.py`, `conftest.py`
- ❌ pytest not installed
- ❌ python3-venv package missing from system

### Verification Scenarios Possible

**Without Full API Access:**

1. **Syntax/Import Validation** ✅
   ```bash
   # Able to verify Python syntax is correct
   python3 -m py_compile user_import/deprovision_disable.py
   python3 -m py_compile user_import/deprovision_delete.py
   ```

2. **Function Signatures** ✅
   ```bash
   # Able to verify required methods exist
   grep -n "def disable_user\|def update_user_description" user_import/lib/ucs.py
   ```

3. **Help Documentation** ❌ (missing dependencies)
   ```bash
   # Currently fails: `ModuleNotFoundError: configargparse`
   ./deprovision_disable.py --help
   ```

4. **Dry Run Tests** ❌ (needs API access)

**With Full API Access:**
- Test Phase 1: User disable workflow end-to-end
- Test Phase 2: User delete workflow end-to-end
- Test grace period enforcement
- Test idempotency
- Verify SAML identity removal
- Verify output file generation

### Requirements for Full Verification

**System Dependencies:**
```bash
# Missing required packages
sudo apt install python3-pip python3-venv
```

**Python Dependencies:**
```bash
# Recreate venv and install
cd user_import
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

**API Access:**
- UCS/UDM REST API credentials (username/password)
- Keycloak admin credentials
- Test environment with test users
- Network access to endpoints

---

## Recommendations

### For Task 5 (moodle-integration):

**Option A: Investigate Missing Chart** (Recommended)
1. Check other Git branches for chart files
2. Check staging environment
3. Contact development team
4. If found, deploy directly

**Option B: Re-implement from Plan** (High Effort)
1. Use existing 892-line plan as specification
2. Recreate all chart files (10 YAML files)
3. Create Helmfile integration (3 files)
4. Deploy and test
5. **Estimated effort**: 4-6 hours

**Option C: Skip and Document** (Lowest Effort)
1. Document that chart needs to be created/relocated
2. Mark task as "Requires chart file recovery"
3. Continue with higher-priority work

### For Task 6 (user-import deprovision):

**Option A: Lightweight Verification** (Recommended - No API Access)
1. Install system dependencies (python3-pip, python3-venv)
2. Recreate venv and install Python dependencies
3. Verify scripts can import all modules
4. Test --help functionality
5. Verify code structure matches plan
6. Document what requires full API access

**Option B: Full Verification** (Requires API Access)
1. Same as Option A +
2. Set up test environment with UDM/Keycloak
3. Create test users
4. Run Phase 1 (disable) in dry-run mode
5. Run Phase 1 in production mode
6. Run Phase 2 (delete) test
7. Document all test results

**Option C: Skip** (If verification can wait)
1. Document that code review is complete
2. Note that full verification requires test environment
3. Schedule for future sprint

---

## Summary Table

| Task | Status | Blocking Issue | Recommended Action | Effort |
|------|--------|----------------|-------------------|--------|
| Task 5: moodle-integration | Chart missing | Helm chart files not found in repo | Investigate/recover chart or re-implement | High (4-6h) or Unknown |
| Task 6: user-import deprovision | Implementation complete | venv broken, dependencies missing | Lightweight verification (no API access) | Medium (1-2h) |

---

## Next Steps

1. **Immediate** (can do now):
   - Contact team about missing Moodle chart
   - Install python3-pip and python3-venv for Task 6
   - Perform lightweight verification of user-import scripts

2. **Short-term** (requires coordination):
   - Recover or re-implement Moodle Helm chart
   - Set up test environment for full deprovision verification

3. **Document** regardless of outcome:
   - Update priority matrix with current state
   - Create evidence files for what was verified
   - Note what requires future work