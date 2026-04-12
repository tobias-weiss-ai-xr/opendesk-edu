# GitHub Actions Secrets Configuration

This guide explains how to configure GitHub Actions secrets for openDesk Edu workflows.

## Required Secrets

| Secret Name | Description | Required By | How to Generate |
|-------------|-------------|---------------|-----------------|
| `CODEBERG_TOKEN` | Personal Access Token for Codeberg sync | `.github/workflows/sync-to-codeberg.yml` | Create at https://codeberg.org/user/settings/applications |
| `GITHUB_TOKEN` | GitHub Personal Access Token | `.github/workflows/sync-to-codeberg.yml` | Create at https://github.com/settings/tokens (auto-provided by GitHub Actions) |
| `GITLEAKS_LICENSE` | Gitleaks license for enhanced secret scanning | `.github/workflows/security-scan.yml` | Optional - get from https://gitleaks.io/ |
| `PAGERDUTY_SERVICE_KEY` | PagerDuty integration key | `docs/monitoring-setup.md` | From PagerDuty account |

## Setting Up Secrets

### 1. Create Codeberg Personal Access Token

1. Go to https://codeberg.org/user/settings/applications
2. Click "Generate New Token"
3. Configure:
   - **Token Name**: `opendesk-edu-github-sync`
   - **Expiration**: Choose appropriate (e.g., 1 year)
   - **Scopes**: Enable:
     - `repo` (Full control of repositories)
     - `write:packages` (Upload to Codeberg packages if needed)
4. Click "Generate Token"
5. **IMPORTANT**: Copy the token immediately (you won't see it again)

### 2. Add Secret to GitHub Repository

1. Go to your GitHub repository: https://github.com/opendesk-edu/deployment/settings/secrets/actions
2. Click "New repository secret"
3. Configure:
   - **Name**: `CODEBERG_TOKEN`
   - **Value**: Paste the Codeberg token from step 1
   - **Environment**: Leave blank (all environments)
4. Click "Add secret"

### 3. Verify Secret Configuration

```bash
# Verify secret is accessible in workflow
# (Run the workflow manually to test)
```

1. Go to Actions tab in GitHub repository
2. Select "Sync to Codeberg" workflow
3. Click "Run workflow"
4. Check workflow runs for success/failure
5. View logs if needed

## Security Best Practices

### Secret Management

- **Never commit secrets to git**: This is the most critical rule
- **Use short-lived tokens**: Set expiration when creating tokens
- **Rotate secrets regularly**: Update tokens every 90-180 days
- **Limit scopes**: Only grant minimum required permissions
- **Monitor secret usage**: GitHub logs secret access in workflow runs

### Token Permissions

**CODEBERG_TOKEN** required scopes:
- `repo` - Full control of repositories (needed for push)

**PAGERDUTY_SERVICE_KEY** (if using):
- Only events: API access, read-only
- No repository access needed

### Workflow Security

All openDesk Edu GitHub Actions workflows:

1. **test.yml** - Runs helm lint, template validation, yamllint
2. **security-scan.yml** - Runs dependency scanning, SAST, secret scanning
3. **sync-to-codeberg.yml** - Syncs GitHub → Codeberg using `CODEBERG_TOKEN`
4. **deploy-docs-preview.yml** - Preview deployment for documentation

### Auditing Secret Access

GitHub maintains audit logs:

```bash
# View workflow run history
# Check for successful secret usage
```

1. Go to Actions → Workflow Runs
2. Click on a workflow run
3. Review which secrets were used (visible to you)
4. Check timestamps for suspicious activity

## Troubleshooting

### Common Issues

#### 1. Secret Not Found in Workflow

**Error**: `Resource not accessible by integration`

**Solution**:
- Verify secret name matches exactly (`CODEBERG_TOKEN` all caps)
- Check secret is in repository settings (not organization)
- Wait up to 1 minute for secret to propagate

#### 2. Codeberg Token Expired

**Error**: `Invalid credentials or have expired`

**Solution**:
1. Generate new Codeberg token
2. Update `CODEBERG_TOKEN` secret in GitHub
3. Run sync workflow again

#### 3. Token Insufficient Permissions

**Error**: `Push to create is not enabled for organizations`

**Solution**:
- Ensure Codeberg repository exists and is writable
- Verify token has `repo` scope
- Check organization permissions (opendesk-edu must allow repo creation)

#### 4. GitHub Auto-token Not Working

**Error**: `GITHUB_TOKEN` not accessible

**Solution**:
- The `GITHUB_TOKEN` is automatically provided by GitHub Actions
- No manual setup needed
- If workflow fails with authentication, check workflow file syntax

### Debug Mode

Enable debug logging in workflow:

```yaml
jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Debug environment
        run: |
          echo "GITHUB_TOKEN is set: ${{ secrets.GITHUB_TOKEN != '' }}"
          echo "CODEBERG_TOKEN is set: ${{ secrets.CODEBERG_TOKEN != '' }}"
```

## Advanced Configuration

### Environment-Specific Secrets

Different environments can use different secrets:

```yaml
jobs:
  sync:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: fork-sync/github-sync@v1
        with:
          target_token: ${{ secrets.CODEBERG_TOKEN_PRODUCTION }}
```

Add environment secrets:

1. Go to repository Settings → Environments
2. Create environment (e.g., `production`, `staging`)
3. Add environment-specific secrets
4. Update workflow to use environment

### Secret Rotation Procedure

1. **Generate new token** (before old one expires)
2. **Add new secret** to GitHub (e.g., `CODEBERG_TOKEN_NEW`)
3. **Test workflow** with new secret
4. **Delete old secret** (`CODEBERG_TOKEN`)
5. **Update workflows** to use new secret name

This ensures zero downtime during rotation.

### Multiple Codeberg Repositories

If you need to sync to multiple Codeberg repositories:

```yaml
jobs:
  sync:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        repo:
          - deployment
          - charts
          - docs
    steps:
      - uses: fork-sync/github-sync@v1
        with:
          target_token: ${{ secrets.CODEBERG_TOKEN }}
          target_repo: opendesk-edu/${{ matrix.repo }}
```

## Verification Checklist

After configuring secrets, verify:

- [ ] Codeberg token generated and copied
- [ ] `CODEBERG_TOKEN` added to GitHub repository secrets
- [ ] Sync workflow run successfully
- [ ] Changes appear in Codeberg repository
- [ ] No sensitive data in git history
- [ ] Token expiration noted in calendar
- [ ] Secret rotation scheduled

## Secret Rotation Timeline

| Secret | Created | Expires | Last Rotated | Next Rotation |
|--------|---------|---------|---------------|---------------|
| CODEBERG_TOKEN | TBD | TBD | TBD | TBD |
| PAGERDUTY_SERVICE_KEY | TBD | TBD | TBD | TBD |

## References

- [GitHub Actions Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Codeberg Settings](https://codeberg.org/user/settings)
- [Codeberg Application Tokens](https://codeberg.org/user/settings/applications)
- [fork-sync Action](https://github.com/fork-sync/github-sync)

---

**Last Updated**: 2026-04-06
**Version**: 1.0