<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Contributing to openDesk Edu

<!-- 
Welcome! / Willkommen!

English: This guide will help you contribute to openDesk Edu effectively.
Deutsch: Dieser Leitfaden hilft Ihnen, effektiv zu openDesk Edu beizutragen.
-->

**Thank you for your interest in contributing to openDesk Edu!** 🎓

openDesk Edu is an open-source digital workspace platform designed specifically for educational institutions. By contributing, you're helping universities, schools, and public sector organizations build sovereign, secure, and collaborative digital learning environments.

---

## Table of Contents

- [Welcome & Project Overview](#welcome--project-overview)
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Development Environment Setup](#development-environment-setup)
  - [Fork and Clone](#fork-and-clone)
- [Contribution Workflow](#contribution-workflow)
  - [Branching Strategy](#branching-strategy)
  - [Making Changes](#making-changes)
  - [Submitting a Pull Request](#submitting-a-pull-request)
- [Coding Standards](#coding-standards)
  - [Helm Charts](#helm-charts)
  - [YAML Configuration](#yaml-configuration)
  - [PHP Development](#php-development)
  - [Ruby Development](#ruby-development)
  - [TypeScript/JavaScript](#typescriptjavascript)
  - [General Guidelines](#general-guidelines)
- [Testing Requirements](#testing-requirements)
  - [Running Tests](#running-tests)
  - [Writing Tests](#writing-tests)
- [Commit Message Conventions](#commit-message-conventions)
- [Pull Request Guidelines](#pull-request-guidelines)
  - [PR Checklist](#pr-checklist)
  - [PR Template](#pr-template)
- [Code Review Process](#code-review-process)
- [Issue Reporting](#issue-reporting)
- [Security Vulnerabilities](#security-vulnerabilities)
- [Documentation Contributions](#documentation-contributions)
- [License and Copyright](#license-and-copyright)
- [Getting Help](#getting-help)

---

## Welcome & Project Overview

### What is openDesk Edu?

openDesk Edu extends the [openDesk Community Edition](https://www.opencode.de/en/opendesk) with educational services tailored for universities and schools:

| Category | Services |
|----------|----------|
| **Learning Management** | ILIAS, Moodle |
| **Video Conferencing** | BigBlueButton (alternative to Jitsi) |
| **File Sync & Share** | OpenCloud (alternative to Nextcloud) |
| **Collaboration** | Etherpad, BookStack, Planka |
| **Support** | Zammad, LimeSurvey |
| **Utilities** | Draw.io, Excalidraw, Self-Service Password |

All services integrate with openDesk's Keycloak-based Single Sign-On (SSO) and unified portal.

### Target Contributors

We welcome contributions from:
- 🏛️ **University IT administrators** with development skills
- 🌍 **Open source developers** interested in educational software
- 🇩🇪 **German public sector IT teams** (Öffentliche Verwaltung)
- 🎓 **International educational institutions**
- 👨‍🎓 **Students and researchers** in EdTech

### Why Contribute?

- **Digital Sovereignty**: Help build alternatives to proprietary platforms
- **Educational Impact**: Improve tools used by thousands of students
- **Open Source Community**: Join a growing ecosystem of contributors
- **Professional Development**: Gain experience with Kubernetes, Helm, SSO, and more

---

## Code of Conduct

### Verhaltenskodex / Code of Conduct

**English:**

This project follows the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). By participating, you agree to uphold this code. Please report unacceptable behavior to the maintainers.

**Deutsch:**

Dieses Projekt folgt dem [Contributor Covenant Verhaltenskodex](https://www.contributor-covenant.org/version/2/1/code_of_conduct/de/). Durch Ihre Teilnahme stimmen Sie zu, diesen Kodex einzuhalten. Bitte melden Sie inakzeptables Verhalten an die Maintainer.

---

## Getting Started

### Prerequisites

Before contributing, ensure you have the following installed:

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| **Kubernetes** | 1.28+ | Container orchestration | [k8s.io](https://kubernetes.io/docs/setup/) |
| **Helm** | 3.x | Package manager | [helm.sh](https://helm.sh/docs/intro/install/) |
| **helmfile** | 0.x | Declarative Helm deployment | [helmfile.readthedocs.io](https://helmfile.readthedocs.io/) |
| **kubectl** | 1.28+ | Kubernetes CLI | [k8s.io](https://kubernetes.io/docs/tasks/tools/) |
| **Git** | 2.x | Version control | [git-scm.com](https://git-scm.com/) |
| **Docker** | 24+ | Container runtime | [docker.com](https://docs.docker.com/get-docker/) |
| **Go** | 1.21+ | For Helm plugins | [go.dev](https://go.dev/doc/install) |

**Optional but recommended:**

| Tool | Purpose |
|------|---------|
| **pre-commit** | Git hooks for linting |
| **yamllint** | YAML linting |
| **helm-docs** | Auto-generate chart documentation |
| **chart-testing** | Helm chart testing |

### Development Environment Setup

#### 1. Install pre-commit hooks

```bash
# Install pre-commit
pip install pre-commit

# Install the hooks
cd opendesk-edu
pre-commit install
```

#### 2. Configure your environment

```bash
# Set your domain (for local development)
export DOMAIN=opendesk.local

# Set master password for secrets generation
export MASTER_PASSWORD="your-secure-password"

# Set namespace for deployments
export NAMESPACE=opendesk-dev
```

#### 3. Verify your setup

```bash
# Check Kubernetes connectivity
kubectl cluster-info

# Verify Helm installation
helm version

# Verify helmfile installation
helmfile --version

# Run a dry-run deployment
helmfile -e dev template
```

### Fork and Clone

```bash
# 1. Fork the repository on GitHub
#    Go to https://github.com/opendesk-edu/deployment and click "Fork"

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/opendesk-edu.git
cd opendesk-edu

# 3. Add upstream remote
git remote add upstream https://github.com/opendesk-edu/deployment.git

# 4. Keep your fork updated
git fetch upstream
git checkout main
git merge upstream/main
```

---

## Contribution Workflow

### Branching Strategy

openDesk Edu uses a simplified **main-branch workflow**:

```
main (stable) ──────────────────────────────────────►
     │
     ├── feature/backchannel-logout ─── PR ───► merged
     │
     ├── fix/moodle-session-handling ─── PR ───► merged
     │
     └── docs/contributing-guide ─── PR ───► merged
```

#### Branch Naming Convention

Use descriptive branch names with prefixes:

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feature/` | New functionality | `feature/saml-backchannel-logout` |
| `fix/` | Bug fixes | `fix/moodle-session-timeout` |
| `docs/` | Documentation | `docs/api-reference-update` |
| `refactor/` | Code improvements | `refactor/helm-values-structure` |
| `test/` | Test additions | `test/e2e-backchannel-logout` |
| `chore/` | Maintenance | `chore/dependency-updates` |

### Making Changes

#### Step 1: Create a feature branch

```bash
# Ensure you're on main and up-to-date
git checkout main
git pull upstream main

# Create your branch
git checkout -b feature/your-feature-name
```

#### Step 2: Make your changes

Follow the [Coding Standards](#coding-standards) for your file type.

#### Step 3: Test your changes

```bash
# Lint Helm charts
helm lint helmfile/charts/your-chart/

# Run helm-unittest (if applicable)
helm unittest helmfile/charts/your-chart/

# Template the deployment
helmfile -e dev template

# Dry-run apply
helmfile -e dev apply --dry-run
```

#### Step 4: Commit your changes

Follow [Commit Message Conventions](#commit-message-conventions).

### Submitting a Pull Request

#### Step 1: Push your branch

```bash
git push origin feature/your-feature-name
```

#### Step 2: Open a Pull Request

1. Go to your fork on GitHub
2. Click "Compare & pull request"
3. Fill in the PR template (see below)
4. Submit the PR against `main`

#### Step 3: Address review feedback

Maintainers will review your PR. Be responsive to feedback:

```bash
# Make changes based on feedback
git add .
git commit -m "fix: address review comments"
git push origin feature/your-feature-name
```

---

## Coding Standards

### Helm Charts

#### Directory Structure

```
helmfile/charts/<service>/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values
├── values.schema.json      # Values JSON schema (optional)
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── ingress.yaml
│   ├── _helpers.tpl        # Template helpers
│   └── NOTES.txt           # Post-install notes
├── charts/                 # Dependencies
├── ci/
│   └── ci-values.yaml      # CI test values
└── tests/
    └── deployment_test.yaml # helm-unittest files
```

#### Chart.yaml Template

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
apiVersion: v2
name: my-service
description: A Helm chart for deploying My Service to openDesk Edu
type: application
version: 1.0.0
appVersion: "1.0.0"
maintainers:
  - name: openDesk Edu Team
    email: maintainers@opendesk-edu.org
sources:
  - https://github.com/opendesk-edu/deployment/tree/main/helmfile/charts/my-service
keywords:
  - opendesk
  - education
  - learning
home: https://opendesk-edu.org
```

#### values.yaml Best Practices

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0

# Always include SPDX headers

# Group related values logically
global:
  imageRegistry: ""
  imagePullSecrets: []

# Use clear descriptions
replicaCount: 1

image:
  repository: registry.opencode.de/opendesk/components/services/my-service
  pullPolicy: IfNotPresent
  tag: "1.0.0"

# Security contexts are required
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false

# Resource limits are required
resources:
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

# Ingress configuration
ingress:
  enabled: true
  className: "haproxy"
  hosts:
    - host: my-service.{domain}
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: my-service-tls
      hosts:
        - my-service.{domain}
```

#### Template Helpers (_helpers.tpl)

```yaml
{{/*
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "my-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "my-service.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "my-service.labels" -}}
helm.sh/chart: {{ include "my-service.chart" . }}
{{ include "my-service.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
```

### YAML Configuration

#### Environment Values Files

Files in `helmfile/environments/default/` must follow this structure:

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
---
## Section Title
##
## Description of what this section configures.

component:
  ## Enable this component
  enabled: {{ env "COMPONENT_ENABLED" | default "true" | quote }}

  ## Configuration option with description
  ##
  option: {{ env "COMPONENT_OPTION" | default "default-value" | quote }}
```

#### Key Principles

1. **SPDX Headers**: All files must include SPDX copyright and license headers
2. **Comments**: Use `##` for documentation comments, `#` for annotations
3. **Environment Variables**: Use `{{ env "VAR_NAME" | default "value" | quote }}` for overrides
4. **Alphabetical Order**: Keep lists alphabetically sorted (enforced by CI linting)
5. **Logical Order**: Within component blocks: registry → repository → tag

Example from `backchannel-logout.yaml.gotmpl`:

```yaml
backchannelLogout:
  enabled: {{ env "BACKCHANNEL_LOGOUT_ENABLED" | default "true" | quote }}

  saml:
    moodle:
      enabled: {{ env "BACKCHANNEL_LOGOUT_MOODLE_ENABLED" | default "true" | quote }}
      backchannelLogoutUrl: {{ env "BACKCHANNEL_LOGOUT_MOODLE_URL" | default (printf "https://moodle.%s/Shibboleth.sso/Logout" .Values.global.domain) | quote }}
      bindings:
        httpRedirect: {{ env "BACKCHANNEL_LOGOUT_MOODLE_REDIRECT_BINDING" | default "true" | quote }}
        httpPost: {{ env "BACKCHANNEL_LOGOUT_MOODLE_POST_BINDING" | default "true" | quote }}
        soap: {{ env "BACKCHANNEL_LOGOUT_MOODLE_SOAP_BINDING" | default "true" | quote }}
```

### PHP Development

PHP is used for Moodle integrations and custom handlers.

#### PHP File Template

```php
<?php
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
// SPDX-License-Identifier: Apache-2.0
/**
 * Brief description of the file
 *
 * Detailed description of what this file does and how it fits
 * into the larger system.
 *
 * @package    openDesk_Edu
 * @subpackage Component
 * @author     Your Name <your.email@example.com>
 * @copyright  2026 openDesk Edu Contributors
 * @license    Apache-2.0
 */

declare(strict_types=1);

// Constants at the top
const LOG_FILE = '/var/log/service/app.log';
const SESSION_TIMEOUT = 30;

/**
 * Log a structured message
 *
 * @param string $level Log level (debug, info, warn, error)
 * @param string $message Log message
 * @param array $context Additional context data
 */
function log_message(string $level, string $message, array $context = []): void
{
    $entry = [
        'timestamp' => date('c'),
        'level' => $level,
        'message' => $message,
        'context' => $context
    ];
    
    file_put_contents(LOG_FILE, json_encode($entry) . "\n", FILE_APPEND);
}

/**
 * Main handler function
 */
function handle_request(): void
{
    try {
        // Implementation
    } catch (Exception $e) {
        log_message('error', 'Request failed', [
            'error' => $e->getMessage()
        ]);
    }
}
```

#### PHP Best Practices

1. **Type Declarations**: Always use `declare(strict_types=1)` and type hints
2. **Error Handling**: Use try-catch with structured logging
3. **Security**: 
   - Validate all inputs
   - Use prepared statements for database queries
   - Never expose stack traces in production
4. **Documentation**: Add PHPDoc comments for all public functions

#### Example: SAML Backchannel Handler (Moodle)

From `helmfile/apps/moodle/files/backchannel-handler.php`:

```php
<?php
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
// SPDX-License-Identifier: Apache-2.0
/**
 * SAML Backchannel Logout Handler for Moodle
 *
 * Receives SAML 2.0 LogoutRequest messages from Keycloak
 * and terminates the corresponding Moodle session.
 */

declare(strict_types=1);

// Prevent direct GET access (only allow server-to-server POST)
if (php_sapi_name() !== 'cli' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    http_response_code(405);
    header('Allow: POST');
    exit;
}

/**
 * Parse SAML LogoutRequest XML
 */
function parse_logout_request(string $xml): array
{
    libxml_use_internal_errors(true);
    $doc = new DOMDocument();
    
    if (!$doc->loadXML($xml)) {
        throw new InvalidArgumentException('Invalid XML');
    }
    
    $xpath = new DOMXPath($doc);
    $xpath->registerNamespace('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');
    $xpath->registerNamespace('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');
    
    return [
        'id' => $xpath->query('//samlp:LogoutRequest/@ID')[0]?->nodeValue,
        'issuer' => $xpath->query('//saml:Issuer')[0]?->nodeValue,
        'nameId' => $xpath->query('//saml:NameID')[0]?->nodeValue,
        'sessionIndex' => $xpath->query('//samlp:SessionIndex')[0]?->nodeValue
    ];
}
```

### Ruby Development

Ruby is used for BigBlueButton integrations and controllers.

#### Ruby File Template

```ruby
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

# Brief description of the class/module
#
# Detailed description of functionality
#
# @see https://example.com/docs
#
class MyController < ApplicationController
  # Skip CSRF for server-to-server communication
  skip_before_action :verify_authenticity_token, only: [:endpoint]
  
  # Constants
  TIMEOUT = ENV.fetch('TIMEOUT', 30).to_i
  VERBOSE = ENV.fetch('VERBOSE', 'false') == 'true'

  ##
  # Handle incoming request
  #
  # @return [String] Response content
  #
  def endpoint
    log_event(:info, 'request_started', { ip: request.remote_ip })
    
    begin
      result = process_request
      render json: result, status: :ok
    rescue StandardError => e
      log_event(:error, 'request_failed', { error: e.message })
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  private

  ##
  # Structured logging
  #
  # @param level [Symbol] Log level
  # @param event [String] Event type
  # @param data [Hash] Event data
  #
  def log_event(level, event, data = {})
    Rails.logger.send(level) do
      {
        timestamp: Time.current.utc.iso8601,
        level: level.to_s.upcase,
        event: event,
        **data
      }.to_json
    end
  end
end
```

#### Ruby Best Practices

1. **Frozen String Literal**: Always include `# frozen_string_literal: true`
2. **Environment Variables**: Use `ENV.fetch('VAR', default)` for configuration
3. **Structured Logging**: Use JSON-formatted logs for observability
4. **Error Handling**: Catch `StandardError` and log with context
5. **Documentation**: Use YARD-style documentation (`##` for methods)

#### Example: SAML Backchannel Controller (BigBlueButton)

From `helmfile/apps/bigbluebutton/controllers/saml_backchannel_controller.rb`:

```ruby
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

# SAML Backchannel Logout Controller for BigBlueButton
#
# Handles SAML 2.0 Single Logout (SLO) backchannel requests from Keycloak.
#
# @see https://docs.bigbluebutton.org/development/api
class SamlBackchannelController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:logout]
  skip_before_action :authenticate_user!, only: [:logout]

  SAML_PROTOCOL_NS = 'urn:oasis:names:tc:SAML:2.0:protocol'.freeze
  SESSION_TIMEOUT = ENV.fetch('BACKCHANNEL_LOGOUT_BBB_TIMEOUT', 30).to_i

  ##
  # Handle SAML backchannel logout request
  #
  # POST /saml/logout
  #
  def logout
    log_event(:info, 'saml_backchannel_logout_started', {
      remote_ip: request.remote_ip
    })

    begin
      saml_request = read_saml_request
      logout_request = parse_saml_request(saml_request)
      
      unless verify_signature(logout_request)
        return render_error_response(403, 'Signature verification failed')
      end

      process_logout(extract_user_id(logout_request))
      render_successful_response(logout_request['ID'])

    rescue StandardError => e
      log_event(:error, 'saml_logout_error', { error: e.message })
      render_error_response(500, "Internal error: #{e.message}")
    end
  end

  private

  def log_event(level, event, data = {})
    return unless logging_enabled?

    Rails.logger.send(level) do
      {
        timestamp: Time.current.utc.iso8601(3),
        level: level.to_s.upcase,
        event: event,
        service: 'bigbluebutton-saml-backchannel',
        **data
      }.to_json
    end
  end
end
```

### TypeScript/JavaScript

Used for portal customizations and E2E testing.

#### TypeScript/JavaScript File Template

```typescript
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
// SPDX-License-Identifier: Apache-2.0

/**
 * Brief description
 *
 * Detailed description of the module
 */

// Imports at the top
import { something } from './module';

// Type definitions
interface Config {
  enabled: boolean;
  timeout: number;
}

// Constants
const DEFAULT_TIMEOUT = 30000;

/**
 * Function description
 *
 * @param param - Parameter description
 * @returns Return value description
 */
export async function doSomething(param: string): Promise<void> {
  try {
    // Implementation
  } catch (error) {
    console.error('Operation failed', { error, param });
    throw error;
  }
}
```

#### Best Practices

1. **ES Modules**: Use `import`/`export` syntax
2. **TypeScript**: Prefer TypeScript for new code
3. **Error Handling**: Always use try-catch with logging
4. **Async/Await**: Prefer over raw Promises
5. **Linting**: Run ESLint before committing

### General Guidelines

#### SPDX Headers

All files must include SPDX headers:

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
```

For files with multiple copyright holders:

```yaml
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
```

#### Security Best Practices

1. **No Secrets in Code**: Never commit secrets, passwords, or tokens
2. **Read-Only Filesystems**: Containers should use `readOnlyRootFilesystem: true`
3. **Non-Root Users**: Always run as non-root (`runAsNonRoot: true`)
4. **Network Policies**: Restrict pod-to-pod communication
5. **Input Validation**: Validate all external inputs

---

## Testing Requirements

### Running Tests

#### Helm Chart Tests

```bash
# Lint a specific chart
helm lint helmfile/charts/my-service/

# Lint all charts
for chart in helmfile/charts/*/; do
  helm lint "$chart"
done

# Run helm-unittest
helm unittest helmfile/charts/my-service/

# Run with coverage
helm unittest -f 'tests/*_test.yaml' helmfile/charts/my-service/
```

#### Template Validation

```bash
# Template without applying
helmfile -e dev template

# Template a specific release
helmfile -e dev -l name=my-service template

# Validate rendered manifests
helmfile -e dev template | kubeval -
```

#### E2E Tests (Playwright)

```bash
# Install Playwright
npm install -g playwright

# Run all E2E tests
npx playwright test tests/

# Run specific test
npx playwright test tests/backchannel-e2e.spec.js

# Run with headed browser
npx playwright test --headed
```

### Writing Tests

#### Helm Unit Tests

Create `tests/deployment_test.yaml`:

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
suite: Test deployment
templates:
  - deployment.yaml
tests:
  - it: should render deployment with default values
    asserts:
      - isKind:
          of: Deployment
      - equal:
          path: spec.replicas
          value: 1
      - isSubset:
          path: spec.template.spec.securityContext
          content:
            runAsNonRoot: true

  - it: should set custom replicas
    set:
      replicaCount: 3
    asserts:
      - equal:
          path: spec.replicas
          value: 3

  - it: should include resource limits
    asserts:
      - isSubset:
          path: spec.template.spec.containers[0].resources
          content:
            limits:
              cpu: 500m
              memory: 256Mi
```

#### E2E Test Example

```javascript
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
// SPDX-License-Identifier: Apache-2.0
// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('Backchannel Logout', () => {
  test('should terminate all sessions on portal logout', async ({ page, context }) => {
    // Login to portal
    await page.goto('https://portal.opendesk.local');
    await page.fill('[name="username"]', 'testuser');
    await page.fill('[name="password"]', 'password');
    await page.click('button[type="submit"]');
    
    // Open service in new tab
    const moodlePage = await context.newPage();
    await moodlePage.goto('https://moodle.opendesk.local');
    
    // Verify logged in
    await expect(moodlePage.locator('.user-profile')).toBeVisible();
    
    // Logout from portal
    await page.click('[data-testid="logout-button"]');
    
    // Wait for logout propagation
    await page.waitForTimeout(5000);
    
    // Verify session terminated in Moodle
    await moodlePage.reload();
    await expect(moodlePage.locator('[name="username"]')).toBeVisible();
  });
});
```

### CI Testing

All PRs must pass CI checks:

1. **Helm Lint**: `helm lint` on all charts
2. **Template Validation**: `helmfile template` succeeds
3. **Unit Tests**: `helm-unittest` passes
4. **YAML Lint**: `yamllint` on all YAML files
5. **Chart Testing**: `ct lint` for chart changes

---

## Commit Message Conventions

We follow [Conventional Commits](https://www.conventionalcommits.org/):

### Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

### Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(moodle): add SAML backchannel logout` |
| `fix` | Bug fix | `fix(moodle): correct session timeout handling` |
| `docs` | Documentation | `docs: update contributing guide` |
| `style` | Code style (no logic change) | `style: fix indentation in values.yaml` |
| `refactor` | Code refactoring | `refactor(helm): extract common helpers` |
| `test` | Adding tests | `test: add E2E test for backchannel logout` |
| `chore` | Maintenance | `chore: update CI workflow` |
| `perf` | Performance improvement | `perf: optimize template rendering` |

### Scopes

Use the component name:

- `moodle` - Moodle-related changes
- `bigbluebutton` or `bbb` - BigBlueButton changes
- `ilias` - ILIAS changes
- `helmfile` - Core deployment changes
- `docs` - Documentation changes
- `ci` - CI/CD changes

### Examples

```bash
# Feature
git commit -m "feat(backchannel): add OIDC logout support for OpenCloud"

# Bug fix with breaking change note
git commit -m "fix(moodle): correct SAML signature verification

The signature verification was incorrectly checking the wrong element.
This fixes CVE-2026-XXXX.

BREAKING CHANGE: Requires new KEYCLOAK_SIGNING_CERTIFICATE env var"

# Multiple paragraphs
git commit -m "feat(moodle): implement backchannel logout handler

- Parse SAML LogoutRequest XML
- Verify XML signature with IdP certificate
- Terminate Moodle session by SessionIndex or NameID

Refs: #123"

# Skip CI (use sparingly)
git commit -m "docs: fix typo in README [ci skip]"
```

### German Language (Optional)

For German-speaking contributors, you may write commit messages in German:

```bash
git commit -m "feat(moodle): SAML Backchannel Logout implementieren

- SAML LogoutRequest XML parsen
- XML-Signatur mit IdP-Zertifikat verifizieren
- Moodle-Session beenden

Bezieht sich auf: #123"
```

---

## Pull Request Guidelines

### PR Checklist

Before submitting a PR, ensure:

- [ ] Code follows [coding standards](#coding-standards)
- [ ] All files have SPDX copyright headers
- [ ] Commit messages follow [conventions](#commit-message-conventions)
- [ ] Tests pass locally (`helm lint`, `helm unittest`)
- [ ] Documentation updated if needed
- [ ] No secrets or credentials included
- [ ] Changes are backwards-compatible (or marked as breaking)

### PR Template

Use the template in `.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## Summary

Brief description of what this PR changes and why.

## Type of change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Helm chart update
- [ ] Configuration change

## Component affected

- [ ] ILIAS
- [ ] Moodle
- [ ] BigBlueButton
- [ ] OpenCloud
- [ ] Keycloak / SSO
- [ ] Helmfile (core)
- [ ] Documentation
- [ ] Other: __________

## Related issues

Fixes # (issue number)
Related to # (issue number)

## Testing

Describe how you tested this change:

- [ ] Deployed to a test cluster
- [ ] Verified SSO login flow
- [ ] Checked portal tile rendering
- [ ] Ran `helmfile template` without errors
- [ ] Other: __________

## Checklist

- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my changes
- [ ] I have commented my code where necessary
- [ ] I have updated the relevant documentation
- [ ] No secrets or credentials are included
- [ ] Changes to Helm charts are backwards-compatible
```

### PR Size Guidelines

| Size | Lines Changed | Description |
|------|---------------|-------------|
| **XS** | 1-10 | Typo fix, small config change |
| **S** | 11-50 | Minor feature, bug fix |
| **M** | 51-250 | Standard feature, refactoring |
| **L** | 251-1000 | Major feature, significant changes |
| **XL** | 1000+ | Requires design review |

For XL PRs, consider splitting into smaller PRs.

---

## Code Review Process

### Review Timeline

| PR Type | Initial Review | Follow-up Reviews |
|---------|---------------|-------------------|
| Bug fix | 2 business days | 1 business day |
| Feature | 3 business days | 1-2 business days |
| Breaking change | 5 business days | 2 business days |
| Documentation | 2 business days | 1 business day |

### Review Criteria

Reviewers will check:

1. **Correctness**: Does the code work as intended?
2. **Security**: Are there any security vulnerabilities?
3. **Performance**: Are there performance concerns?
4. **Maintainability**: Is the code readable and well-documented?
5. **Compatibility**: Is it backwards-compatible?
6. **Testing**: Are there adequate tests?
7. **Standards**: Does it follow coding standards?

### Review Labels

| Label | Meaning |
|-------|---------|
| `needs-review` | Ready for maintainer review |
| `changes-requested` | Changes needed before merge |
| `approved` | Approved by maintainer |
| `blocked` | Blocked by external dependency |
| `wip` | Work in progress, not ready |

### Responding to Reviews

```markdown
<!-- Good response -->
@reviewer Thanks for the feedback! I've addressed your comments:
- Fixed the typo in `values.yaml`
- Added the missing security context
- Updated the documentation

Please take another look when you have a chance.

<!-- Avoid -->
@reviewer I don't think this needs to change.
```

---

## Issue Reporting

### Bug Reports

Use the [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md):

```markdown
## Bug Description
A clear description of what the bug is.

## Steps to Reproduce
1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Environment
- openDesk Edu version: [e.g., 1.0.0]
- Kubernetes version: [e.g., 1.28.0]
- Helm version: [e.g., 3.13.0]
- Browser: [e.g., Chrome 120]

## Logs
```
Paste relevant logs here
```

## Additional Context
Any other context about the problem.
```

### Feature Requests

Use the [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.md):

```markdown
## Problem Statement
A clear description of what problem this feature would solve.

## Proposed Solution
A clear description of what you want to happen.

## Alternatives Considered
A description of any alternative solutions you've considered.

## Use Case
Who would use this feature and how?

## Additional Context
Any other context, screenshots, or mockups.
```

### Issue Labels

| Label | Description |
|-------|-------------|
| `bug` | Something isn't working |
| `enhancement` | New feature or request |
| `documentation` | Improvements to documentation |
| `good first issue` | Good for newcomers |
| `help wanted` | Extra attention needed |
| `priority/high` | Urgent issue |
| `priority/medium` | Standard priority |
| `priority/low` | Nice to have |

---

## Security Vulnerabilities

### Reporting Security Issues

**⚠️ Do NOT open a public issue for security vulnerabilities!**

Instead:

1. **Open a private security advisory**: [GitHub Security Advisories](https://github.com/opendesk-edu/deployment/security/advisories/new)
2. **Or email**: security@opendesk-edu.org

### What to Include

1. **Description** of the vulnerability
2. **Steps to reproduce** the issue
3. **Affected versions** of openDesk Edu
4. **Potential impact** if exploited
5. **Suggested fix** (if available)

### Response Timeline

| Milestone | Target |
|-----------|--------|
| Acknowledgment | 48 hours |
| Initial assessment | 7 days |
| Fix coordination | As needed |
| Disclosure | After fix released |

### Supported Versions

Only the **latest release** of openDesk Edu receives security updates.

### Scope

| In Scope | Out of Scope |
|----------|--------------|
| openDesk Edu Helm charts | Upstream component vulnerabilities |
| SSO integration code | Third-party library CVEs |
| Custom images | Default credentials |
| Configuration vulnerabilities | DoS attacks |

For upstream vulnerabilities, report to the respective projects:

| Component | Security Contact |
|-----------|-----------------|
| openDesk CE | [Bundesdruckerei/openDesk](https://github.com/Bundesdruckerei/opendesk/security) |
| ILIAS | [ILIAS Security](https://docu.ilias.de/goto_docu_wiki_wpage_3207.html) |
| Moodle | [Moodle Security](https://moodle.org/security/) |
| BigBlueButton | [BBB Security](https://github.com/bigbluebutton/bigbluebutton/security) |
| Keycloak | [Keycloak Security](https://www.keycloak.org/security) |

---

## Documentation Contributions

### Documentation Structure

```
docs/
├── getting-started.md      # Initial setup guide
├── requirements.md         # System requirements
├── architecture.md         # System architecture
├── developer/
│   ├── development.md      # Development workflow
│   └── ci.md               # CI/CD documentation
├── external-services/      # Service-specific docs
└── presentations/          # Presentation materials
```

### Writing Guidelines

1. **Clear and Concise**: Use simple language
2. **Code Examples**: Include working examples
3. **Screenshots**: Add images where helpful
4. **Bilingual**: German (DE) and English (EN) sections where appropriate
5. **SPDX Headers**: Include copyright headers in all docs

### Example Documentation

```markdown
<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Feature Name

## Overview / Übersicht

<!-- English -->
Brief description of the feature.

<!-- Deutsch -->
Kurze Beschreibung des Features.

## Configuration

### Basic Setup

```yaml
feature:
  enabled: true
  option: "value"
```

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Error X | Do Y |
```

---

## License and Copyright

### License

openDesk Edu is licensed under the **Apache License 2.0**.

```
Copyright 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
Copyright 2025-2026 openDesk Edu Contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

### Adding Copyright

When contributing new files, add:

```yaml
# SPDX-FileCopyrightText: 2026 Your Name <your.email@example.com>
# SPDX-License-Identifier: Apache-2.0
```

When modifying existing files, add your copyright line:

```yaml
# SPDX-FileCopyrightText: 2024 ZenDiS GmbH
# SPDX-FileCopyrightText: 2026 Your Name <your.email@example.com>
# SPDX-License-Identifier: Apache-2.0
```

### Contributor License Agreement

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

---

## Getting Help

### Community Channels

| Channel | Purpose |
|---------|---------|
| [GitHub Issues](https://github.com/opendesk-edu/deployment/issues) | Bug reports, feature requests |
| [GitHub Discussions](https://github.com/opendesk-edu/deployment/discussions) | Questions, ideas |
| [Matrix/Element](https://matrix.to/#/#opendesk-edu:matrix.org) | Real-time chat |

### Documentation

- [Getting Started](docs/getting-started.md)
- [Architecture](docs/architecture.md)
- [External Services](docs/external-services.md)
- [Backchannel Logout](docs/backchannel-logout.md)
- [Security](docs/security.md)

### Asking Questions

When asking for help, include:

1. **What you're trying to do**
2. **What you've tried**
3. **Error messages** (with logs)
4. **Environment details** (versions, platform)
5. **Steps to reproduce**

```markdown
## What I'm trying to do
Deploy Moodle with backchannel logout enabled.

## What I've tried
1. Set `backchannelLogout.saml.moodle.enabled: true`
2. Ran `helmfile -e dev apply`

## Error message
```
Error: INSTALLATION FAILED: cannot re-use a name that is still in use
```

## Environment
- openDesk Edu: main branch (commit abc123)
- Kubernetes: 1.28.0
- Helm: 3.13.0

## Logs
```
[paste relevant logs]
```
```

---

## Recognition

Contributors are recognized in:

- **CHANGELOG.md**: Contributions listed in release notes
- **README.md**: Top contributors acknowledged
- **Release Notes**: Major contributions highlighted

Thank you for contributing to openDesk Edu! 🎉

---

## Appendix: Quick Reference

### Essential Commands

```bash
# Clone and setup
git clone https://github.com/opendesk-edu/deployment.git
cd opendesk-edu
pre-commit install

# Development
helmfile -e dev template          # Template without applying
helmfile -e dev apply --dry-run   # Dry-run deployment
helm lint helmfile/charts/my-app/ # Lint a chart

# Testing
helm unittest helmfile/charts/my-app/
npx playwright test tests/

# Committing
git commit -m "feat(scope): description"

# Updating fork
git fetch upstream
git checkout main
git merge upstream/main
```

### Useful Links

| Resource | Link |
|----------|------|
| Helm Docs | https://helm.sh/docs/ |
| helmfile Docs | https://helmfile.readthedocs.io/ |
| Kubernetes Docs | https://kubernetes.io/docs/ |
| Keycloak Docs | https://www.keycloak.org/documentation |
| SAML 2.0 Spec | https://docs.oasis-open.org/security/saml/ |
| Conventional Commits | https://www.conventionalcommits.org/ |

---

*Last updated: March 2026*
