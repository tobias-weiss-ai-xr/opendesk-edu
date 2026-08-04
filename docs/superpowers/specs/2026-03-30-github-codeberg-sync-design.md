# GitHub-Codeberg Sync Design Spec

> **Created:** 2026-03-30
> **Status:** Draft

## Purpose

Automate two-way synchronization between GitHub and Codeberg repositories for openDesk-edu, combining real-time webhook-based syncing with scheduled catch-up to ensure consistency.

## Architecture

### Sync Pattern

**Bidirectional sync with dual triggers:**

```
┌─────────────┐                ┌─────────────┐
│   GitHub    │◄──────────────►│   Codeberg  │
│             │    (sync)      │             │
└─────────────┘                └─────────────┘
       │                             │
       │ webhook push                │ webhook push
       │                             │
  ┌────▼────┐                    ┌────▼────┐
  │ GitHub  │                    │Codeberg│
  │Actions │                    │ CI/CD   │
  │ workflow│                    │pipeline│
  └─────────┘                    └─────────┘
       │                             │
       │                             │
       ▼                             ▼
  GitHub → Codeberg            Codeberg → GitHub
  (via token)                  (via SSH key or token)
       │                             │
       │ scheduled catch-up          │ scheduled catch-up
       │ (cron)                      │ (cron)
       │                             │
       └───────────────┬─────────────┘
                       │
                Full mirror sync
       (all branches, tags, refs)
```

### Components

1. **GitHub Actions Workflow** (`.github/workflows/codeberg-sync.yml`)
   - Triggered on `push` to any branch
   - Syncs all refs from GitHub → Codeberg using OAuth2 token
   - Runs scheduled catch-up every 4 hours

2. **Codeberg CI/CD Pipeline** (`.forgejo/workflows/github-sync.yml`)
   - Triggered on push to any branch
   - Syncs all refs from Codeberg → GitHub via SSH key or token
   - Runs scheduled catch-up every 4 hours

3. **Sync Behavior**

   - **Real-time sync:** Executes within 1-2 minutes of any push
   - **Scheduled catch-up:** Runs every 4 hours to catch any missed webhook events
   - **Full mirror:** Uses `git push --mirror` to sync all refs
     - All branches
     - All tags
     - All refs (including PR refs, origin refs)

## Requirements

### Functional Requirements

1. **Bidirectional Sync**
   - Pushes to GitHub must sync to Codeberg
   - Pushes to Codeberg must sync to GitHub
   - Both syncs must happen automatically without manual intervention

2. **Sync Coverage**
   - All branches (including temporary branches)
   - All tags
   - All refs (including dependabot refs, origin refs)
   - No refs are excluded

3. **Sync Timing**
   - Webhook-triggered sync starts within 1-2 minutes of push
   - Scheduled catch-up runs every 4 hours
   - Conflicts resolve by last writer wins (fast-forward preferred)

4. **Error Handling**
   - Failed syncs should be logged
   - Retry logic with exponential backoff (max 3 retries)
   - Notifications in repository issues for persistent failures

### Non-Functional Requirements

1. **Authentication**
   - GitHub → Codeberg: OAuth2 token stored in GitHub secrets
   - Codeberg → GitHub: OAuth2 token stored in Codeberg secrets

2. **Security**
   - Tokens scoped with minimal permissions (write-only to target repo)
   - No token exposure in logs
   - Secrets rotation guidance in documentation

3. **Reliability**
   - Dual trigger system (webhook + scheduled) ensures no missed syncs
   - Duration monitoring (timeout if sync takes >10 minutes)
   - Status reporting in commit checks

4. **Compatibility**
   - Works for both repositories without modification
   - No special configuration for users
   - Standard git operations only

## Open Questions

1. **Conflict Resolution:** If both repos diverge simultaneously, should we:
   - Accept last writer wins (Git's default for mirror pushes)
   - Require manual intervention and open an issue?

2. **Excluded Branches:** Should certain branches be excluded from sync (e.g., local-only branches, temporary build branches)?

3. **Sync Validation:** Should we add checksum verification after sync to ensure mirror integrity?

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Token compromise | Unauthorized repo access | Use write-only tokens, audit token usage, enable secret scanning |
| Broken sync (permanent divergence) | Repositories become inconsistent | Offline detection with scheduled checks, manual intervention process documented |
| Performance issues (large repo) | Sync timeout, failed jobs | Incremental sync support, timeout configuration, partial sync fallback |

## Dependencies

- GitHub Actions runner (free tier)
- Codeberg CI/CD (Woodpecker, free)
- OAuth2 tokens for both platforms
- Git 2.40+ (for improved `--mirror` behavior)
