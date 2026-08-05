# GitHub ↔ Codeberg Sync

Bidirectional mirror sync between GitHub and Codeberg. Every push to either platform triggers a full mirror to the other, with a scheduled fallback every 4 hours.

## How It Works

Two CI workflows keep the repositories in sync:

| Direction | Trigger file | Target |
|-----------|-------------|--------|
| GitHub → Codeberg | `.github/workflows/codeberg-sync.yml` | `opendesk-edu/opendesk-edu` on Codeberg |
| Codeberg → GitHub | `.forgejo/workflows/github-sync.yml` | `tobias-weiss-ai-xr/opendesk-edu` on GitHub |

Both workflows share the same logic:

1. Checkout the full repository history (`fetch-depth: 0`)
2. Add the remote platform as a git remote using an OAuth2 token
3. Run `git push --mirror` to push all refs (branches, tags, notes)
4. Compare local and remote ref counts as a sanity check

### Triggers

Each workflow runs on three triggers:

- **Push** — any branch push fires an immediate sync
- **Schedule** — cron at `0 */4 * * *` (every 4 hours) as a safety net for missed pushes
- **Manual** — `workflow_dispatch` for on-demand sync via the UI or CLI

### Mirror Scope

`git push --mirror` pushes everything: all branches, all tags, all refs. This means deleting a branch on one side will delete it on the other after the next sync.

## Secrets Required

### On GitHub (repository settings → Secrets and variables → Actions)

| Secret | Description | Required scopes |
|--------|-------------|-----------------|
| `CODEBERG_TOKEN` | Personal access token from Codeberg | `repo`, `write:packages` |

### On Codeberg (repository settings → Actions → Secrets)

| Secret | Description | Required scopes |
|--------|-------------|-----------------|
| `GH_TOKEN` | Personal access token (classic) from GitHub | `repo`, `workflow` |

## Setting Up / Replacing Secrets

### Create a Codeberg token (for use on GitHub)

```bash
curl -X POST 'https://codeberg.org/api/v1/users/-/tokens' \
  -H "Authorization: Basic $(echo -n 'YOUR_CODEBERG_USERNAME:YOUR_PASSWORD' | base64)" \
  -H 'Content-Type: application/json' \
  -d '{"name": "github-sync","scopes": ["repo","write:packages"]}'
```

Save the `sha1` field from the response. This is your `CODEBERG_TOKEN`.

### Create a GitHub token (for use on Codeberg)

Go to **GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)** and generate a token with `repo` and `workflow` scopes. Alternatively via the API:

```bash
curl -X POST 'https://api.github.com/authorizations' \
  -H "Authorization: token YOUR_EXISTING_GITHUB_TOKEN" \
  -H 'Accept: application/vnd.github+json' \
  -d '{"scopes":["repo","workflow"],"note":"codeberg-sync"}'
```

Save the `token` field from the response. This is your `GH_TOKEN`.

### Set secrets via API

**On GitHub:**

```bash
gh secret set CODEBERG_TOKEN --repo tobias-weiss-ai-xr/opendesk-edu --body 'YOUR_CODEBERG_TOKEN'
```

**On Codeberg:**

```bash
curl -X POST 'https://codeberg.org/api/v1/repos/opendesk-edu/opendesk-edu/actions/secrets' \
  -H "Authorization: token YOUR_CODEBERG_ADMIN_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name":"GH_TOKEN","data":"YOUR_GITHUB_TOKEN"}'
```

### Replacing a compromised token

1. Revoke the old token (GitHub: Settings → Developer settings; Codeberg: Settings → Applications → Manage Access Tokens)
2. Create a new token with the same scopes
3. Update the secret on the opposite platform using the commands above
4. Trigger a manual sync to verify the new token works

## Monitoring Sync

### GitHub side

```bash
# List workflows and their last status
gh workflow list --repo tobias-weiss-ai-xr/opendesk-edu

# View recent runs
gh run list --workflow=codeberg-sync.yml --repo tobias-weiss-ai-xr/opendesk-edu --limit 5

# Watch a specific run
gh run view --repo tobias-weiss-ai-xr/opendesk-edu --log

# Trigger manually
gh workflow run codeberg-sync.yml --repo tobias-weiss-ai-xr/opendesk-edu
```

### Codeberg side

- **CI dashboard**: <https://ci.codeberg.org/opendesk-edu/opendesk-edu>
- **Actions tab**: <https://codeberg.org/opendesk-edu/opendesk-edu/actions>

### Manual sync from the UI

Both platforms support a "Run workflow" button on the Actions page. On GitHub, go to Actions → Sync to Codeberg → Run workflow. On Codeberg, go to Actions → Sync to GitHub → Run workflow.

## Troubleshooting

### Sync not running after a push

- Check that the workflow file exists on the branch that was pushed
- Verify the secret is set (a missing secret causes the step to fail, not skip)
- On GitHub, check if Actions are enabled: Settings → Actions → General → "Allow all actions"
- On Codeberg, check that the repository has Actions enabled in its settings

### Repeated failures

1. Check the token hasn't expired or been revoked
2. Verify the token has the correct scopes
3. Check that the remote repository URL is correct (typos in org/repo names)
4. Look for rate limiting errors in the workflow logs
5. Try triggering a manual sync to get fresh logs

### Ref count mismatch warning

The verify step compares local and remote ref counts after a successful push. A mismatch is a warning, not an error. Common causes:

- The mirror just created a new branch that the checkout didn't fetch
- Stale refs on the remote that don't exist locally
- A race condition where both syncs ran simultaneously

If the counts consistently diverge, check whether someone is pushing directly to the remote without going through the sync workflow.

### Conflicting pushes (both sides at once)

If a push lands on GitHub and Codeberg within seconds of each other, the `--mirror` flag on the second sync will overwrite the first. This is expected behavior for a mirror setup. The scheduled 4-hour cron acts as a reconciliation layer, so any divergence self-heals within 4 hours at most.

### Workflow timeout

Both workflows have a 10-minute timeout. A full mirror of a large repository with deep history can be slow. If you hit this limit:

1. Check for unusually large objects (`git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | sort -k3 -n -r | head -20`)
2. Consider running `git gc` on the repository
3. If the repository has grown significantly, the timeout can be increased in both workflow files (look for `timeout-minutes: 10`)

## Workflow Files

| File | Platform | Purpose |
|------|----------|---------|
| `.github/workflows/codeberg-sync.yml` | GitHub Actions | Pushes mirror to Codeberg |
| `.forgejo/workflows/github-sync.yml` | Codeberg CI (Forgejo) | Pushes mirror to GitHub |

### Retry logic

Both workflows use identical retry logic:

- 3 attempts maximum
- Exponential backoff: 10s, 20s, 40s
- Each attempt runs `git push --mirror`
- On success, the workflow exits immediately
- After 3 failures, the workflow fails with a non-zero exit code

### Timeout

Each workflow has `timeout-minutes: 10`. If the job doesn't complete within 10 minutes, GitHub/Codeberg kills it.

### Ref verification

After a successful push, both workflows count local refs (`git show-ref`) and remote refs (`git ls-remote`) and compare them. A mismatch prints a warning but does not fail the workflow.

## Security Notes

### Token scoping

Both tokens are scoped to the minimum permissions needed. The `repo` scope allows reading and writing repository contents. The `write:packages` scope (Codeberg) and `workflow` scope (GitHub) are needed for the CI integration.

Neither token has admin, delete_repo, or organization-wide permissions.

### Log exposure

Tokens are passed via `${{ secrets.CODEBERG_TOKEN }}` and `${{ secrets.GH_TOKEN }}`. Both GitHub Actions and Forgejo automatically mask secrets in logs. The token appears in the git remote URL, but the runner scrubs it before logging.

### Token rotation

Rotate tokens periodically:

1. Create a new token with the same scopes
2. Update the secret on the opposite platform
3. Revoke the old token
4. Trigger a manual sync to confirm the new token works

GitHub classic tokens don't expire by default. Set an explicit expiration date when creating them. Codeberg tokens also don't expire automatically, so track rotation in a calendar or secrets manager.

### Access

Only repository admins should be able to create and manage sync tokens. On GitHub, restrict Actions permissions under Settings → Actions → General → "Workflow permissions" to limit who can trigger workflows.
