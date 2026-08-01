# Root Directory Refactor — Design

**Date:** 2026-08-01
**Repository:** openDesk HRZ Monorepo (`opendesk_git`)
**Status:** Approved

## Problem

The root of `opendesk_git/` contains 45+ loose files (docs, scripts, values,
legacy logs) that belong to the **openDesk Edu** project. The parent git repo
only tracks 13 root planning docs; `opendesk-edu` is a **separate git repo**.
Root clutter makes navigation difficult and violates repo hygiene.

## Goal

Move all loose root files into the `opendesk-edu` repository (its own git repo)
under logical folders. Root keeps only `AGENTS.md`, `README.md`, `passvault.sh`,
`passvault/`, tool config, and the nested project repos.

## Target Layout

| Destination (in `opendesk-edu`) | Files |
|---|---|
| `docs/zki/` | 24 ZKI IT-Grundschutz docs: `START_HERE.md`, `INDEX_ALL_ZKI_FILES.md`, `VISUAL_SUMMARY.md`, `DASHBOARD.md`, `QUICK_REFERENCE.md`, `COMPREHENSIVE_{GAP_ANALYSIS,GAP_ANALYSIS_PART2,ANALYSIS_SUMMARY}.md`, `ACTION_PLAN_COMPLETE.md`, `ZKI_CRITICAL_ACTIONS.md`, `ZKI_{GAPS_AND_IMPROVEMENTS,GAPS_PART2,IMPLEMENTATION_SUMMARY}.md`, `ZKI_IT_GRUNDSCHUTZ_{ANALYSIS,CHECKLIST,IMPLEMENTATION_PLAN}.md`, `{FINAL_IMPLEMENTATION_SUMMARY,IMPLEMENTATION_COMPLETE,COMPLETED_IMPLEMENTATION,SUMMARY,SESSION_SUMMARY,REPOSITORY_ORGANIZATION_PLAN,QUICK_START_ZKI_COMPLIANCE,README_ZKI_IMPLEMENTATION}.md` |
| `docs/mail/` | 11 Stalwart/OpenCloud files: `ANALYSIS_REPORT.md`, `DEPLOYMENT_COMPLETE.md`, `DEPLOY_QUICK_START.md`, `GO.md`, `IMPLEMENTATION_SUMMARY.md`, `QUICK_START_STALWART_OPENCLOUD.txt`, `STALWART_{BLOCKED,OPENCLOUD_DEPLOYMENT_SUMMARY,STATUS}.md`, `config.json`, `unmigrated.txt` |
| `scripts/` | 9 scripts: `DEPLOY_NOW.sh`, `FIX_ISSUES.sh`, `MERGE_ALL.sh`, `PUSH_CHANGES.sh`, `deploy-simple.sh`, `deploy-stalwart-final.sh`, `add-keycloak-custom-audience.sh`, `setup-seaweedfs-buckets.sh`, `update-pv-node-affinity.sh` |
| `deploy-configs/opencloud/` | `opencloud-values-{complete,final,root}.yaml`, `opencloud-values.yaml` |
| `deploy-configs/stalwart/` | `stalwart-values-{static,v001,v011}.yaml`, `deploy-stalwart-opencloud-only.yaml` |
| `docs/operations/` | `opendesk-environment-hrz.md` |
| `docs/legacy/` | `CHANGES.md`, `UPGRADE_SUMMARY.md`, `FEEDBACK-EVAL.md`, `SECRETS.md` |
| `docs/maintenance/` | `sync-public-repo.md` (from root `docs/`) |

## Stays at Root

`AGENTS.md`, `README.md`, `passvault.sh`, `passvault/`, `.github/`, `.hermes/`,
`.opencode/`, `.ralph/`, `.sisyphus/`, `.vscode/`, `renovate.json(.license)`,
`_archive/`, and all nested project repos (`opendesk/`, `k8up/`, `user_import/`,
`opendesk-compose/`, `opendesk-edu-website/`, `monitoring/`, `certificates/`,
`registry/`, `common/`, `demo-namespace/`, `erprobungskonzept/`, `charts-upgrade-*`,
`opendesk-*`, `addon-*`, `argocd-opendesk/`, `k8s-mc-mirror/`, `scripts/` removed).

## Git Handling

1. **opendesk-edu repo**: `git add` the moved files, one commit:
   `chore: migrate root deployment docs into opendesk-edu`.
2. **Parent repo**: `git rm` the 13 tracked planning docs (history stays in
   git log), commit `AGENTS.md` + `README.md`, and add a `.gitignore` listing
   the nested project dirs so `git status` stays clean.

## Reference Updates

- `AGENTS.md:527` — `opendesk-environment-hrz.md` → `opendesk-edu/docs/operations/opendesk-environment-hrz.md`
- `README.md:102,133` — same path update
- `README.md` structure section (lines ~61-63) — reflect that session logs moved
- ZKI docs: replace `opendesk-edu/security-policies/zki/` → `../../security-policies/zki/`
  and bare `security-policies/zki/` → `../../security-policies/zki/` (currently broken at root, becomes correct from `docs/zki/`).
  `REPOSITORY_ORGANIZATION_PLAN.md` links (`../../security-policies/zki/`) become correct automatically.
- ZKI↔ZKI relative links stay valid (all files move into the same folder).

## Non-Goals

- No content changes to moved files (only reference fixes).
- Do not touch other nested repos (e.g. `opendesk-knowledge/`).
- Do not merge/rename overlapping edu scripts (e.g. root `deploy-stalwart-final.sh`
  vs edu `scripts/deploy-stalwart.sh` — kept as-is, differs in content).
