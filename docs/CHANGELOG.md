# openDesk Edu Changelog

All notable changes to the openDesk Edu deployment repository.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v1.17.0-migration] - 2026-07-23

### Architecture
- **Major refactoring**: Migrated from fork-based to Git submodule architecture for CE integration
  - CE submodule at `helmfile/ce/` pinned to v1.17.0 (f9c2fc97)
  - Clean separation between CE core and edu-specific configurations
  - Zero merge conflicts on upstream updates

### Integration
- **Upstream merge**: Integrated opendesk v1.16.0 → v1.17.0 (35fafbb8)
  - Resolved 40 merge conflicts
  - Preserved edu-specific configurations using submodule approach
- **Keycloak**: Restored SAML clients (ILIAS, Moodle, BBB) via CE's `functional.authentication.oidc.clients`
- **Paths**: Fixed chart paths for all 32 edu apps (`../../charts/` → `../../../charts/`)

### Deployment
- **Orchestration**: Created `helmfile/edu-helmfile.yaml.gotmpl` with glob pattern for automatic app detection
- **Scripting**: Added `deploy.sh` with --diff, --verbose, multi-env support
- **Images**: Populated `helmfile/environments/edu/images.yaml` (typo3:13.4.0)
- **Secrets**: Verified `helmfile/environments/edu/secrets.yaml` placeholder structure

### Cleanup
- Removed duplicate GPG keys
- Deleted stale CE CI artifacts (`.gitlab/`, `.ralph/`)
- Removed dead keycloak template files and portal entries for CE services
- Ported deploy/hrz etherpad refactoring (removed Bitnami PostgreSQL subchart)
- Deleted 8 stale local branches
- Removed 3,716 tracked `node_modules/` files (85MB) from collab-dashboard
- Deleted 19 stale root-level CE-era ALL_CAPS markdown files
- Removed 16 stale CE-era scripts from `scripts/`
- Deleted 7 stale CE-era documentation files

### Documentation
- Added `docs/deployment.md` - deployment guide
- Created `scripts/update-ce.sh` - CE submodule update helper
- Updated `.gitignore` with Node.js, Python, npm patterns

---

## Legacy

For CE upstream changes prior to v1.17.0, refer to:
- [openDesk CE Changelog](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/CHANGELOG.md)
