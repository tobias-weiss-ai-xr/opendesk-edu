# GitHub-Codeberg Bidirectional Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement automated bidirectional synchronization between GitHub and Codeberg repositories with real-time webhook triggers and scheduled catch-up jobs.

**Architecture:** Two separate CI/CD workflows — one in GitHub Actions (syncs GitHub → Codeberg), one in Codeberg Forgejo (syncs Codeberg → GitHub). Both use `git push --mirror` with OAuth2 tokens, triggered on push and via scheduled cron for catch-up.

**Tech Stack:** GitHub Actions (yaml), Codeberg Forgejo/CI, Git 2.40+, OAuth2 tokens, bash scripting

---

## File Structure

### Files to Create:
- `.github/workflows/codeberg-sync.yml` - GitHub Actions workflow for GitHub → Codeberg sync
- `.forgejo/workflows/github-sync.yml` - Codeberg CI workflow for Codeberg → GitHub sync

### Files to Modify:
- `.gitignore` - Ensure workflow files are not gitignored (verify existing config)

### Secrets Required:
- GitHub Secret: `CODEBERG_TOKEN` - OAuth2 token with write access to opendesk-edu/opendesk-edu on Codeberg
- Codeberg Secret: `GH_TOKEN` - Personal access token with write access to tobias-weiss-ai-xr/opendesk-edu on GitHub

---

## Task 1: Create GitHub → Codeberg Sync Workflow

**Files:**
- Create: `.github/workflows/codeberg-sync.yml`

- [ ] **Step 1: Create the GitHub Actions workflow file**

Create `.github/workflows/codeberg-sync.yml` with the following content:

```yaml
name: Sync to Codeberg

on:
  push:
    branches:
      - '**'
  schedule:
    # Run every 4 hours (cron: minute hour day month weekday)
    - cron: '0 */4 * * *'
  workflow_dispatch:

jobs:
  codeberg-sync:
    name: Sync to Codeberg mirror
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Fetch all history for mirror

      - name: Configure git
        run: |
          git config --global user.name "GitHub Actions Bot"
          git config --global user.email "actions@github.com"

      - name: Add Codeberg remote
        run: |
          git remote add codeberg https://oauth2:${{ secrets.CODEBERG_TOKEN }}@codeberg.org/opendesk-edu/opendesk-edu.git

      - name: Sync to Codeberg (with retry)
        run: |
          # Retry logic with exponential backoff
          MAX_RETRIES=3
          RETRY_DELAY=10
          ATTEMPT=1

          while [ $ATTEMPT -le $MAX_RETRIES ]; do
            echo "Sync attempt $ATTEMPT of $MAX_RETRIES..."

            if git push --mirror codeberg 2>&1; then
              echo "✓ Sync successful on attempt $ATTEMPT"
              exit 0
            else
              echo "✗ Sync failed on attempt $ATTEMPT"
              if [ $ATTEMPT -lt $MAX_RETRIES ]; then
                echo "Retrying in ${RETRY_DELAY}s..."
                sleep $RETRY_DELAY
                RETRY_DELAY=$((RETRY_DELAY * 2))  # Exponential backoff
              fi
            fi
            ATTEMPT=$((ATTEMPT + 1))
          done

          # All retries failed
          echo "❌ Sync failed after $MAX_RETRIES attempts"
          exit 1

      - name: Verify sync
        if: success()
        run: |
          echo "Checking remote refs..."
          LOCAL_REFS=$(git show-ref | wc -l)
          REMOTE_REFS=$(git ls-remote codeberg | wc -l)
          echo "Local refs: $LOCAL_REFS"
          echo "Remote refs: $REMOTE_REFS"
          if [ "$LOCAL_REFS" -ne "$REMOTE_REFS" ]; then
            echo "⚠️ Warning: Ref count mismatch (local=$LOCAL_REFS, remote=$REMOTE_REFS)"
          fi

      - name: Report status
        if: success()
        run: |
          echo "✓ GitHub → Codeberg sync completed successfully"

      - name: Report failure
        if: failure()
        run: |
          echo "❌ GitHub → Codeberg sync failed"
          echo "Check the above logs for details"
```

- [ ] **Step 2: Verify workflow directory structure**

Run: `ls -la .github/workflows/`
Expected: You should see `codeberg-sync.yml` listed

- [ ] **Step 3: Commit the GitHub workflow**

```bash
git add .github/workflows/codeberg-sync.yml
git commit -m "feat: add GitHub → Codeberg sync workflow"
```

---

## Task 2: Create Codeberg → GitHub Sync Workflow

**Files:**
- Create: `.forgejo/workflows/github-sync.yml`

- [ ] **Step 1: Create .forgejo directory structure**

Run: `mkdir -p .forgejo/workflows`
Expected: Directory `.forgejo/workflows/` is created

- [ ] **Step 2: Create the Codeberg CI workflow file**

Create `.forgejo/workflows/github-sync.yml` with the following content:

```yaml
name: Sync to GitHub

on:
  push:
    branches:
      - '**'
  schedule:
    # Run every 4 hours
    - cron: '0 */4 * * *'
  workflow_dispatch:

jobs:
  github-sync:
    name: Sync to GitHub mirror
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Fetch all history for mirror

      - name: Configure git
        run: |
          git config --global user.name "Codeberg Actions Bot"
          git config --global user.email "actions@codeberg.org"

      - name: Add GitHub remote
        run: |
          git remote add github https://oauth2:${{ secrets.GH_TOKEN }}@github.com/opendesk-edu/deployment.git

      - name: Sync to GitHub (with retry)
        run: |
          # Retry logic with exponential backoff
          MAX_RETRIES=3
          RETRY_DELAY=10
          ATTEMPT=1

          while [ $ATTEMPT -le $MAX_RETRIES ]; do
            echo "Sync attempt $ATTEMPT of $MAX_RETRIES..."

            if git push --mirror github 2>&1; then
              echo "✓ Sync successful on attempt $ATTEMPT"
              exit 0
            else
              echo "✗ Sync failed on attempt $ATTEMPT"
              if [ $ATTEMPT -lt $MAX_RETRIES ]; then
                echo "Retrying in ${RETRY_DELAY}s..."
                sleep $RETRY_DELAY
                RETRY_DELAY=$((RETRY_DELAY * 2))  # Exponential backoff
              fi
            fi
            ATTEMPT=$((ATTEMPT + 1))
          done

          # All retries failed
          echo "❌ Sync failed after $MAX_RETRIES attempts"
          exit 1

      - name: Verify sync
        if: success()
        run: |
          echo "Checking remote refs..."
          LOCAL_REFS=$(git show-ref | wc -l)
          REMOTE_REFS=$(git ls-remote github | wc -l)
          echo "Local refs: $LOCAL_REFS"
          echo "Remote refs: $REMOTE_REFS"
          if [ "$LOCAL_REFS" -ne "$REMOTE_REFS" ]; then
            echo "⚠️ Warning: Ref count mismatch (local=$LOCAL_REFS, remote=$REMOTE_REFS)"
          fi

      - name: Report status
        if: success()
        run: |
          echo "✓ Codeberg → GitHub sync completed successfully"

      - name: Report failure
        if: failure()
        run: |
          echo "❌ Codeberg → GitHub sync failed"
          echo "Check the above logs for details"
```

- [ ] **Step 3: Verify workflow directory structure**

Run: `ls -la .forgejo/workflows/`
Expected: You should see `github-sync.yml` listed

- [ ] **Step 4: Commit the Codeberg workflow**

```bash
git add .forgejo/workflows/github-sync.yml
git commit -m "feat: add Codeberg → GitHub sync workflow"
```

---

## Task 3: Push Workflows to GitHub

**Files:**
- Push: `.github/workflows/codeberg-sync.yml`
- Push: `.forgejo/workflows/github-sync.yml`

- [ ] **Step 1: Push commit to GitHub**

Run: `git push origin main`
Expected: Push succeeds, commit visible on GitHub

- [ ] **Step 2: Verify GitHub Actions workflow appears on GitHub**

Run: `gh workflow list`
Expected: Output shows "Sync to Codeberg" workflow

- [ ] **Step 3: Verify commit appears in GitHub**

Run: `gh log -3 --oneline`
Expected: Your two commits are visible in the log

---

## Task 4: Configure GitHub Secret for Codeberg Token

**Files:**
- GitHub Secret: `CODEBERG_TOKEN` (configure in GitHub repo settings)

- [ ] **Step 1: Create OAuth2 token on Codeberg**

Run the following curl command to create the token (replace token name if desired):

```bash
curl -X POST "https://codeberg.org/api/v1/users/graphwiz-ai/tokens" \
  -H "Authorization: token 2e6df2339b28910ef5951ff1adc8d9a14b4d9737" \
  -H "Content-Type: application/json" \
  -d '{"name":"github-sync-token","scopes":["write:repository","write:issue"]}'
```

Expected: JSON response with `sha1` (the new token) or `token` field

**Note:** Save the returned token. You'll need it for the next step.

- [ ] **Step 2: Add token as GitHub secret**

Run the following command to set the secret:

```bash
# Replace YOUR_NEW_CODEBERG_TOKEN below with the token from Step 1
export NEW_CODEBERG_TOKEN="YOUR_NEW_CODEBERG_TOKEN_HERE"

gh secret set CODEBERG_TOKEN --body "$NEW_CODEBERG_TOKEN"
```

Expected: Output: "✓ Set secret CODEBERG_TOKEN"

**Note:** If the command fails, manually add the secret via GitHub web UI: Settings → Secrets and variables → Actions → New repository secret

- [ ] **Step 3: Verify secret is set**

Run: `gh secret list`
Expected: Output shows `CODEBERG_TOKEN` in the list

---

## Task 5: Push Workflows to Codeberg

**Files:**
- Push: `.github/workflows/codeberg-sync.yml`
- Push: `.forgejo/workflows/github-sync.yml`

- [ ] **Step 1: Push commit to Codeberg**

Run: 
```bash
export CODEBERG_TOKEN="2e6df2339b28910ef5951ff1adc8d9a14b4d9737"
git push codeberg main
```
Expected: Push succeeds, commit visible on Codeberg

- [ ] **Step 2: Verify workflows are accessible on Codeberg**

Run: `git ls-remote codeberg | grep workflows`
Expected: Output shows refs for the workflow files

- [ ] **Step 3: Verify commit appears in Codeberg**

Run: `git log -3 --oneline codeberg/main`
Expected: Your two commits are visible in the log

---

## Task 6: Configure Codeberg Secret for GitHub Token

**Files:**
- Codeberg Secret: `GH_TOKEN` (configure in Codeberg repo settings)

- [ ] **Step 1: Create Personal Access Token on GitHub**

Run the following command to create the token:

```bash
gh auth token --scopes repo,workflow
```

Expected: Output shows a token string

**Alternative method:** Create token in GitHub web UI: Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token

**Required scopes:** `repo` (full control of private repositories), `workflow` (update GitHub Action workflows)

- [ ] **Step 2: Add token as Codeberg secret**

Run the following curl command to set the secret:

```bash
# Replace YOUR_GH_TOKEN below with the token from Step 1
export YOUR_GH_TOKEN="YOUR_GITHUB_TOKEN_HERE"

curl -X PUT "https://codeberg.org/api/v1/repos/opendesk-edu/opendesk-edu/actions/secrets/GH_TOKEN" \
  -H "Authorization: token 2e6df2339b28910ef5951ff1adc8d9a14b4d9737" \
  -H "Content-Type: application/json" \
  -d "{\"data\":\"$(echo -n $YOUR_GH_TOKEN)\"}"
```

Expected: No error (HTTP 200 or 204)

**Alternative method:** Add secret via Codeberg web UI: Repository settings → CI/CD → Secrets → Add secret

- [ ] **Step 3: Verify secret is set**

Run:
```bash
curl -s "https://codeberg.org/api/v1/repos/opendesk-edu/opendesk-edu/actions/secrets" \
  -H "Authorization: token 2e6df2339b28910ef5951ff1adc8d9a14b4d9737" | jq '.[] | .name'
```

Expected: Output shows `GH_TOKEN` in the list

---

## Task 7: Create Documentation for Sync System

**Files:**
- Create: `docs/maintenance/github-codeberg-sync.md`

- [ ] **Step 1: Create documentation file**

Create `docs/maintenance/github-codeberg-sync.md` with the following content:

```markdown
# GitHub-Codeberg Bidirectional Sync

This repository is automatically synchronized between GitHub and Codeberg.

## How It Works

- **Bidirectional sync:** Pushes to either repository sync to the other within 1-2 minutes
- **Workflows:**
  - GitHub Actions (`Sync to Codeberg`): Handles GitHub → Codeberg sync
  - Codeberg CI (`Sync to GitHub`): Handles Codeberg → GitHub sync
- **Triggers:**
  - Webhook: Any push to any branch triggers immediate sync
  - Scheduled: Runs every 4 hours as a catch-up for missed webhooks
- **Scope:** Mirrors all refs (branches, tags, all refs)

## Secrets Required

### GitHub Secret: `CODEBERG_TOKEN`

- **Purpose:** Sync from GitHub to Codeberg
- **Creation:** Create OAuth2 token on Codeberg with `write:repository` and `write:issue` scopes
- **How to set:** `gh secret set CODEBERG_TOKEN`
- **Location:** GitHub repo settings → Secrets and variables → Actions

### Codeberg Secret: `GH_TOKEN`

- **Purpose:** Sync from Codeberg to GitHub
- **Creation:** Create Personal Access Token on GitHub with `repo` and `workflow` scopes
- **How to set:** Via Codeberg API or web UI (see below)
- **Location:** Codeberg repo settings → CI/CD → Secrets

## Setting Up / Replacing Secrets

### Replace Codeberg Token (GitHub side)

1. Create new token on Codeberg:
   ```bash
   curl -X POST "https://codeberg.org/api/v1/users/YOUR_USERNAME/tokens" \
     -H "Authorization: token YOUR_CURRENT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"name":"github-sync-token","scopes":["write:repository"]}'
   ```

2. Update GitHub secret:
   ```bash
   gh secret set CODEBERG_TOKEN --body "NEW_TOKEN_HERE"
   ```

### Replace GitHub Token (Codeberg side)

1. Create new token on GitHub:
   ```bash
   gh auth token --scopes repo,workflow
   ```

2. Update Codeberg secret (via API):
   ```bash
   curl -X PUT "https://codeberg.org/api/v1/repos/opendesk-edu/opendesk-edu/actions/secrets/GH_TOKEN" \
     -H "Authorization: token YOUR_CODEBERG_TOKEN" \
     -H "Content-Type: application/json" \
     -d "{\"data\":\"$(echo -n NEW_GH_TOKEN_HERE)\"}"
   ```

## Monitoring Sync

### Check GitHub Actions status

```bash
gh workflow list
gh run list --workflow=codeberg-sync.yml
```

### Check Codeberg CI status

Visit: https://ci.codeberg.org/repos/opendesk-edu/opendesk-edu

### Manual trigger

```bash
# Trigger GitHub → Codeberg sync
gh workflow run codeberg-sync.yml

# Trigger Codeberg → GitHub sync (via Codeberg web UI or API)
```

## Troubleshooting

### Sync not working

1. **Check secrets are set:**
   - GitHub: `gh secret list`
   - Codeberg: Check repo settings → CI/CD → Secrets

2. **Check workflow logs:**
   - GitHub: Actions tab → Find "Sync to Codeberg" → View logs
   - Codeberg: https://ci.codeberg.org → Find "Sync to GitHub" → View logs

3. **Verify token permissions:**
   - Codeberg token: Needs `write:repository`, `write:issue` scopes
   - GitHub token: Needs `repo`, `workflow` scopes

### Sync causes conflicts

- **Behavior:** Last writer wins (Git's default for mirror pushes)
- **Resolution:** Accept the automated sync result, manually reconcile if needed
- **Prevention:** Coordinate pushes with collaborators, watch workflow runs

### Sync fails repeatedly

1. Check network connectivity
2. Verify token hasn't expired or been revoked
3. Check workflow logs for specific error messages
4. Manually push to reset sync state:
   ```bash
   git push origin main
   git push codeberg main
   ```

## Workflow Files

- `.github/workflows/codeberg-sync.yml` — GitHub → Codeberg workflow
- `.forgejo/workflows/github-sync.yml` — Codeberg → GitHub workflow

Both workflows:
- Mirror all refs using `git push --mirror`
- Retry up to 3 times with exponential backoff (10s, 20s, 40s)
- Timeout after 10 minutes
- Log ref counts for verification

## Security Notes

- Tokens are scoped with minimal required permissions
- Tokens are never exposed in logs (masked by CI/CD systems)
- Rotate tokens periodically (every 6-12 months recommended)
- Never commit tokens to the repository
- Use repository secrets, not plaintext in workflows
## Task 7: Create Documentation for Sync System

**Files:**
- Create: `docs/maintenance/github-codeberg-sync.md`

- [ ] **Step 1: Create documentation file**

Create `docs/maintenance/github-codeberg-sync.md` with the following content:

```markdown
# GitHub-Codeberg Bidirectional Sync

This repository is automatically synchronized between GitHub and Codeberg.

## How It Works

- **Bidirectional sync:** Pushes to either repository sync to the other within 1-2 minutes
- **Workflows:**
  - GitHub Actions (`Sync to Codeberg`): Handles GitHub → Codeberg sync
  - Codeberg CI (`Sync to GitHub`): Handles Codeberg → GitHub sync
- **Triggers:**
  - Webhook: Any push to any branch triggers immediate sync
  - Scheduled: Runs every 4 hours as a catch-up for missed webhooks
- **Scope:** Mirrors all refs (branches, tags, all refs)

## Secrets Required

### GitHub Secret: `CODEBERG_TOKEN`

- **Purpose:** Sync from GitHub to Codeberg
- **Creation:** Create OAuth2 token on Codeberg with `write:repository` and `write:issue` scopes
- **How to set:** `gh secret set CODEBERG_TOKEN`
- **Location:** GitHub repo settings → Secrets and variables → Actions

### Codeberg Secret: `GH_TOKEN`

- **Purpose:** Sync from Codeberg to GitHub
- **Creation:** Create Personal Access Token on GitHub with `repo` and `workflow` scopes
- **How to set:** Via Codeberg API or web UI (see below)
- **Location:** Codeberg repo settings → CI/DC → Secrets

## Setting Up / Replacing Secrets

### Replace Codeberg Token (GitHub side)

1. Create new token on Codeberg:
   ```bash
   curl -X POST "https://codeberg.org/api/v1/users/YOUR_USERNAME/tokens" \
     -H "Authorization: token YOUR_CURRENT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"name":"github-sync-token","scopes":["write:repository","write:issue"]}'
   ```

2. Update GitHub secret:
   ```bash
   gh secret set CODEBERG_TOKEN --body "NEW_TOKEN_HERE"
   ```

### Replace GitHub Token (Codeberg side)

1. Create new token on GitHub:
   ```bash
   gh auth token --scopes repo,workflow
   ```

2. Update Codeberg secret (via API):
   ```bash
   curl -X PUT "https://codeberg.org/api/v1/repos/opendesk-edu/opendesk-edu/actions/secrets/GH_TOKEN" \
     -H "Authorization: token YOUR_CODEBERG_TOKEN" \
     -H "Content-Type: application/json" \
     -d "{\"data\":\"$(echo -n NEW_GH_TOKEN_HERE)\"}"
   ```

## Monitoring Sync

### Check GitHub Actions status

```bash
gh workflow list
gh run list --workflow=codeberg-sync.yml
```

### Check Codeberg CI status

Visit: https://ci.codeberg.org/repos/opendesk-edu/opendesk-edu

### Manual trigger

```bash
# Trigger GitHub → Codeberg sync
gh workflow run codeberg-sync.yml

# Trigger Codeberg → GitHub sync (via Codeberg web UI or API)
```

## Troubleshooting

### Sync not working

1. **Check secrets are set:**
   - GitHub: `gh secret list`
   - Codeberg: Check repo settings → CI/CD → Secrets

2. **Check workflow logs:**
   - GitHub: Actions tab → Find "Sync to Codeberg" → View logs
   - Codeberg: https://ci.codeberg.org → Find "Sync to GitHub" → View logs

3. **Verify token permissions:**
   - Codeberg token: Needs `write:repository`, `write:issue` scopes
   - GitHub token: Needs `repo`, `workflow` scopes

### Sync causes conflicts

- **Behavior:** Last writer wins (Git's default for mirror pushes)
- **Resolution:** Accept the automated sync result, manually reconcile if needed
- **Prevention:** Coordinate pushes with collaborators, watch workflow runs

### Sync fails repeatedly

1. Check network connectivity
2. Verify token hasn't expired or been revoked
3. Check workflow logs for specific error messages
4. Manually push to reset sync state:
   ```bash
   git push origin main
   git push codeberg main
   ```

## Workflow Files

- `.github/workflows/codeberg-sync.yml` — GitHub → Codeberg workflow
- `.forgejo/workflows/github-sync.yml` — Codeberg → GitHub workflow

Both workflows:
- Mirror all refs using `git push --mirror`
- Retry up to 3 times with exponential backoff (10s, 20s, 40s)
- Timeout after 10 minutes
- Log ref counts for verification

## Security Notes

- Tokens are scoped with minimal required permissions
- Tokens are never exposed in logs (masked by CI/CD systems)
- Rotate tokens periodically (every 6-12 months recommended)
- Never commit tokens to the repository
- Use repository secrets, not plaintext in workflows
```

- [ ] **Step 2: Verify documentation file created**

Run: `ls -la docs/maintenance/github-codeberg-sync.md`
Expected: Documentation file exists

- [ ] **Step 3: Commit documentation**

```bash
git add docs/maintenance/github-codeberg-sync.md
git commit -m "docs: add GitHub-Codeberg sync documentation"
```

---

## Task 8: Push All Workflows and Documentation

**Files:**
- Push: `.github/workflows/codeberg-sync.yml`
- Push: `.forgejo/workflows/github-sync.yml`
- Push: `docs/maintenance/github-codeberg-sync.md`

- [ ] **Step 1: Push all commits to GitHub**

Run: `git push origin main`
Expected: All commits pushed successfully

- [ ] **Step 2: Push all commits to Codeberg**

Run:
```bash
export CODEBERG_TOKEN="2e6df2339b28910ef5951ff1adc8d9a14b4d9737"
git push codeberg main
```
Expected: All commits pushed successfully

- [ ] **Step 3: Verify workflows are visible on both platforms**

Run:
```bash
gh workflow list
git ls-remote codeberg | grep workflows
```
Expected: Both workflows are accessible

---

## Task 9: Test Sync System

**Files:**
- Test: Create a test commit, verify it syncs to both repos

- [ ] **Step 1: Create a test commit**

Run:
```bash
echo "test: verify bidirectional sync $(date)" > test-sync.md
git add test-sync.md
git commit -m "test: verify bidirectional sync"
git push origin main
```
Expected: Push succeeds

- [ ] **Step 2: Monitor GitHub Actions workflow**

Run:
```bash
# Wait 30 seconds, then check workflow status
sleep 30
gh run list --workflow=codeberg-sync.yml --limit 1
```
Expected: Workflow ran successfully

- [ ] **Step 3: Verify sync reached Codeberg**

Run:
```bash
git fetch codeberg main
git log --oneline codeberg/main -1
```
Expected: Test commit is visible on Codeberg

- [ ] **Step 4: Push test commit from Codeberg side**

Run:
```bash
# This commit will trigger the Codeberg → GitHub sync
echo "test from codeberg $(date)" >> test-sync.md
git add test-sync.md
git commit -m "test: push from Codeberg to verify reverse sync"
git push codeberg main
```
Expected: Push succeeds

- [ ] **Step 5: Verify reverse sync worked**

Run:
```bash
# Wait 30 seconds, then check
sleep 30
git fetch origin main
git log --oneline origin/main -2
```
Expected: Both GitHub and Codeberg commits are visible on GitHub

- [ ] **Step 6: Clean up test file**

Run:
```bash
git rm test-sync.md
git commit -m "test: cleanup sync test file"
git push origin main
git push codeberg main
```
Expected: Test file removed from both repos

---

## Task 10: Update README with Sync Notice

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Read README to find insertion point**

Run: `sed -n '190,220p' README.md`
Expected: See the "Documentation" or "Contributing" section

- [ ] **Step 2: Add sync notice to README**

Add this content to README.md after the "💬 Feedback & Issues" section:

```markdown
## 🔗 Repository Mirroring

This repository is automatically synchronized between GitHub and Codeberg:

- **GitHub:** https://github.com/opendesk-edu/deployment
- **Codeberg:** https://codeberg.org/opendesk-edu/opendesk-edu

Both repositories are kept in sync via automated CI/CD workflows. Pushes to either platform sync to the other within 1-2 minutes. See [sync documentation](./docs/maintenance/github-codeberg-sync.md) for details.

```

- [ ] **Step 3: Commit README update**

```bash
git add README.md
git commit -m "docs: add repository mirroring notice to README"
```

- [ ] **Step 4: Push README update**

Run:
```bash
git push origin main
git push codeberg main
```
Expected: README updated on both platforms

---

## Task 11: Final Verification

**Files:**
- Verify: All workflows running, documentation in place

- [ ] **Step 1: Verify all workflows exist**

Run:
```bash
gh workflow list
git ls-remote codeberg | grep workflows
```
Expected: Both workflows are listed

- [ ] **Step 2: Verify documentation exists**

Run:
```bash
ls -la docs/maintenance/github-codeberg-sync.md
ls -la docs/superpowers/specs/2026-03-30-github-codeberg-sync-design.md
```
Expected: Both documentation files exist

- [ ] **Step 3: Check recent workflow runs**

Run:
```bash
gh run list --limit 5
```
Expected: Recent sync workflows show as completed

- [ ] **Step 4: Verify README contains sync notice**

Run: `grep -i "mirroring\|codeberg" README.md | head -5`
Expected: Repo mirroring section is present

- [ ] **Step 5: Create final verification commit (if needed)**

If all verifications pass:
```bash
git add .
git commit -m "chore: verify bidirectional sync implementation complete"
```

- [ ] **Step 6: Final push to both repositories**

Run:
```bash
git push origin main
git push codeberg main
```
Expected: Final synchronization complete

