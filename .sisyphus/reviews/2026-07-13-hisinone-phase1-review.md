# HISinOne Phase 1 — Self-Review Checklist

> Reviewed: 2026-07-13 | Branch: feat/hisinone-phase1-ldap

## 1. Keycloak Client (`sync/keycloak_client.py`)

- [ ] OAuth2 client credentials grant works with valid tokens
- [ ] Falls back to password grant when no client_secret configured
- [ ] Token caching with early refresh (10s buffer)
- [ ] API error responses raise `KeycloakClientError`
- [ ] User CRUD: get, create, update, enable/disable
- [ ] Group operations: list, assign, remove, sync (diff-based)
- [ ] `sync_user_groups` correctly adds missing groups
- [ ] `sync_user_groups` correctly removes extra groups
- [ ] All methods accept optional `dry_run` parameter pattern
- [ ] Tests use httpx_mock, no real Keycloak dependency
- [ ] Tests cover: found, not-found, create, disable, sync, error

## 2. HISinOne Webhook (`sync/hisinone_webhook.py`)

- [ ] HMAC signature verification unchanged (backward compat)
- [ ] Existing event handlers (enrollment, course, instructor) intact
- [ ] `person.created` → creates Keycloak user or re-enables existing
- [ ] `immatriculation` → re-enables user, assigns semester groups
- [ ] `exmatriculation` → removes semester groups, disables user
- [ ] `leave_of_absence` → marks user as suspended via attributes
- [ ] `role_change` → syncs groups to match new role
- [ ] Helper function `_get_base_groups_for_type` correct mapping
- [ ] Helper function `_get_semester_groups` generates correct names
- [ ] Unknown person types default to empty group list (no-op safe)
- [ ] Missing users in Keycloak logged as warning, not error
- [ ] Lifecycle event handler tests exist and pass

## 3. Semester Check CronJob (`sync/semester_check.py`)

- [ ] `get_enrolled_usernames_from_ldap()` queries university LDAP
- [ ] Falls back to empty set if LDAP password not configured
- [ ] `process_semester_check()` compares LDAP vs Keycloak state
- [ ] Students not enrolled get `reRegistrationStatus=pending` with deadline
- [ ] Re-registered students get re-enabled with `status=confirmed`
- [ ] `dry_run` mode skips all mutation
- [ ] Handles `semester` attribute being absent gracefully
- [ ] Calculates grace period from `HISINONE_RE_REGISTRATION_GRACE`
- [ ] Reports summary with disabled/re-enabled/skipped/errors counts
- [ ] Exits with code 1 on errors, 0 on success
- [ ] Test mocks LDAP and Keycloak, verifies dry_run

## 4. Guest Cleanup CronJob (`sync/guest_cleanup.py`)

- [ ] Queries Keycloak for `guestLecturer=true` users
- [ ] Parses `accountExpiry` attribute as ISO datetime
- [ ] Expired accounts: removes all groups, disables user
- [ ] Expiring within 14 days: logs warning, includes in report
- [ ] Invalid expiry dates: logged as warning, skipped
- [ ] No expiry attribute: silently skipped
- [ ] `dry_run` mode logs intent but doesn't mutate
- [ ] Reports summary with expired/expiring-soon/errors counts
- [ ] Tests cover: expired (disabled + groups removed), active (skipped)

## 5. Helm Chart (`helmfile/charts/hisinone-lifecycle/`)

- [ ] `Chart.yaml` has correct metadata (name, version, sources)
- [ ] `deployment.yaml` has correct env vars from ConfigMap + Secrets
- [ ] `service.yaml` exposes port 8000
- [ ] `configmap.yaml` has all required env vars
- [ ] `cronjob-semester.yaml`: schedule, command, backoffLimit correct
- [ ] `cronjob-guest.yaml`: schedule, command, backoffLimit correct
- [ ] All templates use `{{- if .Values.hisinone.accountLifecycle.enabled }}` guard
- [ ] Secrets referenced via `valueFrom.secretKeyRef`

## 6. General

- [ ] All files committed to `feat/hisinone-phase1-ldap`
- [ ] Branch pushed to all remotes (origin, github, codeberg)
- [ ] No type suppressions (`as any`, `@ts-ignore`) — N/A (Python)
- [ ] No bare `except:` — all catches are specific or `Exception`
- [ ] Logging with proper logger names (not `print()`)
- [ ] All new files have SPDX headers where applicable
- [ ] No secrets or credentials committed
- [ ] `__pycache__/` and `.venv/` not tracked by git
