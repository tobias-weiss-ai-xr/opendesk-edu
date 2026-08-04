# Pre-Commit Hooks

This repo uses pre-commit hooks to ensure code quality before pushing.

## Installation

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install
```

## Available Hooks

### YAML Linting

Checks YAML syntax and style.

```yaml
- repo: https://github.com/adrienverge/yamllint
  rev: v1.35.1
  hooks:
    - id: yamllint
      args: [--config-file=.yamllint]
```

### Markdown Linting

Checks Markdown formatting and link validity.

```yaml
- repo: https://github.com/igorshubovych/markdownlint-cli
  rev: v0.39.0
  hooks:
    - id: markdownlint
      args: [--fix]
```

### Helm Linting

Validates Helm charts.

```yaml
- repo: local
  hooks:
    - id: helm-lint
      name: Helm Lint
      entry: make lint
      language: system
      files: helmfile/charts/*/Chart.yaml
```

### Spell Check

Checks for common spelling errors.

```yaml
- repo: https://github.com/codespell-project/codespell
  rev: v2.2.6
  hooks:
    - id: codespell
      args: [--config=cspell.json]
```

## Running Hooks Manually

```bash
# Run all hooks on all files
pre-commit run --all-files

# Run specific hook
pre-commit run yamllint --all-files

# Run on staged files only
pre-commit run
```

## Skipping Hooks

To skip hooks for a single commit:

```bash
git commit --no-verify -m "your message"
```

To skip hooks permanently:

```bash
pre-commit uninstall
```

## Updating Hooks

```bash
# Update to latest versions
pre-commit autoupdate

# Reinstall with updated versions
pre-commit install --overwrite
```
