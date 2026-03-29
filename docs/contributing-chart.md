<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Contributing Charts

This guide documents the canonical chart structure for openDesk Edu services. Use this template when adding new educational services to ensure consistency with existing charts.

## Chart Structure

All charts follow this canonical directory layout:

```
helmfile/charts/{chart-name}/
  Chart.yaml          # Chart metadata with artifacthub.io annotations
  values.yaml         # Default values
  ci/
    ci-values.yaml   # Minimal CI values for template rendering
  templates/
    deployment.yaml  # Main deployment (or deployment-*.yaml for multiple)
    service.yaml      # Service definition
    ingress.yaml      # Ingress (if applicable)
    pvc.yaml          # Persistent volume claims (if applicable)
    NOTES.txt         # Post-install guidance
  tests/
    deployment_test.yaml
    ingress_test.yaml
    service_test.yaml
    persistence_test.yaml
```

### Real Examples

- **ILIAS** (`helmfile/charts/ilias/`) — Learning Management System with database subcharts
- **BookStack** (`helmfile/charts/bookstack/`) — Wiki with simple deployment
- **F13** (`helmfile/charts/f13/`) — Complex multi-service AI assistant

## Chart.yaml

The chart metadata file defines the chart and includes Artifact Hub annotations for visibility.

### Example: BookStack

```yaml
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
apiVersion: v2
appVersion: 26.03.1
dependencies:
- condition: mariadb.enabled
  name: mariadb
  repository: https://charts.bitnami.com/bitnami
  version: 20.2.2
description: A Helm chart for BookStack knowledge base
name: bookstack
type: application
version: 0.1.0
annotations:
  artifacthub.io/changes: |
    - Add comprehensive helm-unittest test coverage
    - Add CI values for template rendering validation
  artifacthub.io/links: |
    - name: Source
      url: https://github.com/tobias-weiss-ai-xr/opendesk-edu
```

### Example: F13 (with keywords and maintainers)

```yaml
# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0
apiVersion: v2
name: f13
description: A Helm chart for the F13 sovereign AI assistant with chat, summarization, RAG, and transcription services
type: application
version: 0.1.0
appVersion: "1.1.0"
keywords:
  - ai
  - llm
  - chat
  - rag
  - summarization
  - transcription
maintainers:
  - name: openDesk Edu Contributors
annotations:
  artifacthub.io/changes: |
    - Add comprehensive helm-unittest test coverage
    - Add CI values for template rendering validation
  artifacthub.io/links: |
    - name: Source
      url: https://github.com/tobias-weiss-ai-xr/opendesk-edu
```

### Required Fields

- `apiVersion: v2` — Helm chart API version
- `name` — Chart name (must match directory name)
- `description` — Brief description of the service
- `type: application` — Chart type
- `version` — Chart version (semver)
- `appVersion` — Application version (from upstream)

### Annotations

Use `artifacthub.io` annotations for Artifact Hub integration:

```yaml
annotations:
  artifacthub.io/changes: |
    - Change 1
    - Change 2
  artifacthub.io/links: |
    - name: Source
      url: https://github.com/tobias-weiss-ai-xr/opendesk-edu
    - name: Documentation
      url: https://docs.example.com
```

### Dependencies

For charts that depend on other charts (like databases), declare them in the `dependencies` section:

```yaml
dependencies:
- condition: mariadb.enabled
  name: mariadb
  repository: https://charts.bitnami.com/bitnami
  version: 20.2.2
```

## CI Values Pattern

The `ci/ci-values.yaml` file provides minimal values for testing template rendering. It should:

- Exercise ALL templates
- Use NO real passwords, secrets, or API endpoints
- Set minimal resource requests (50m CPU, 64Mi memory)
- Keep storage minimal (1Gi)

### Example: ILIAS (Simple)

```yaml
# CI values for ILIAS — uses vendored mariadb subchart
mariadb:
  enabled: true
  auth:
    rootPassword: "test"

mariadbgalera:
  enabled: false
```

### Example: F13 (Complex)

```yaml
# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0
#
# CI values for f13 — exercises ALL 23 templates with minimal resources.
# NO real passwords, secrets, or API endpoints.

global:
  imageRegistry: registry.opencode.de/f13/microservices
  imagePullPolicy: IfNotPresent
  keycloakUrl: "https://keycloak.example.com"
  keycloakRealm: opendesk
  ingressClassName: nginx

services:
  chat:
    enabled: true
  summary:
    enabled: true
  parser:
    enabled: true
  rag:
    enabled: true
  transcription:
    enabled: true

authentication:
  guestMode: true
  keycloakBaseUrl: "https://keycloak.example.com"
  keycloakRealm: opendesk
  audience: f13-api

llm:
  provider: openai
  apiUrl: "https://llm.example.com/v1"
  authSecretRef: llm-api
  models:
    chat: "gpt-4o-mini"
    summary: "gpt-4o-mini"
    parser: "gpt-4o-mini"

elasticsearch:
  deploy: true
  existingHost: ""
  memory: 512Mi
  replicas: 1

transcription:
  rabbitmq:
    image: rabbitmq:3.13-management
  transcriptionDb:
    image: postgres:16-alpine
    user: f13_transcription
    name: f13_transcription
  whisperModel: "tiny"
  language: "en"

gpu:
  nodeSelector: {}
  tolerations: []
  resources:
    limits: {}

rag:
  embeddingModel: "all-MiniLM-L6-v2"

secrets:
  llmApi: "ci-test-llm-key"
  feedbackDb: "ci-test-feedback-db"
  transcriptionDb: "ci-test-transcription-db"
  rabbitmq: "ci-test-rabbitmq"
  huggingfaceToken: ""

ingress:
  enabled: true
  hostname: f13.ci.example.com
  className: ""
  annotations: {}
  tls:
    enabled: false
    secretName: ""

persistence:
  feedbackDb:
    size: 1Gi
    accessMode: ReadWriteOnce
  doclingModels:
    size: 1Gi
    accessMode: ReadWriteOnce
  transcriptionData:
    size: 1Gi
    accessMode: ReadWriteOnce
  transcriptionModels:
    size: 1Gi
    accessMode: ReadWriteOnce
  elasticsearchData:
    size: 1Gi
    accessMode: ReadWriteOnce

images:
  frontend:
    repository: frontend/main
    tag: latest
    pullPolicy: IfNotPresent
  core:
    repository: core/main
    tag: latest
    pullPolicy: IfNotPresent
  chat:
    repository: chat
    tag: v1.1.0
    pullPolicy: IfNotPresent

resources:
  core:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi
  frontend:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi

nodeSelector: {}

tolerations: []

affinity: {}

networkPolicy:
  enabled: true

pdb:
  core:
    minAvailable: 1
  frontend:
    minAvailable: 1
```

### CI Values Guidelines

1. **Enable all features** — Set `enabled: true` for all optional services
2. **Use fake credentials** — Never put real secrets in CI values
3. **Minimal resources** — Use 50m CPU, 64Mi memory requests
4. **1Gi storage** — Keep PVC sizes at 1Gi for testing
5. **Test all paths** — Ensure every template is exercised

## Test Patterns

Charts use [helm-unittest](https://github.com/quintush/helm-unittest) for testing. Each test file validates a specific template or group of templates.

### Test Structure

```yaml
suite: Deployment
templates:
  - deployment.yaml
values:
  - ../ci/ci-values.yaml
tests:
  - it: should create a Deployment with correct kind
    asserts:
      - isKind:
          of: Deployment
```

### Example: Deployment Test (ILIAS)

```yaml
suite: Deployment
templates:
  - deployment.yaml
values:
  - ../ci/ci-values.yaml
tests:
  - it: should create a Deployment with correct kind
    asserts:
      - isKind:
          of: Deployment

  - it: should use the correct container image
    asserts:
      - matchRegex:
          path: spec.template.spec.containers[0].image
          pattern: srsolutions/ilias:.+

  - it: should have standard Kubernetes labels
    asserts:
      - isNotNull:
          path: metadata.labels
      - isNotNull:
          path: metadata.labels["app.kubernetes.io/name"]
      - isNotNull:
          path: metadata.labels["app.kubernetes.io/instance"]
      - isNotNull:
          path: metadata.labels["app.kubernetes.io/managed-by"]

  - it: should set the ilias/server label
    asserts:
      - isSubset:
          path: metadata.labels
          content:
            ilias/server: "true"

  - it: should have a single replica
    asserts:
      - equal:
          path: spec.replicas
          value: 1

  - it: should configure ILIAS environment variables
    asserts:
      - contains:
          path: spec.template.spec.containers[0].env
          content:
            name: ILIAS_AUTO_SETUP
            value: "true"
      - contains:
          path: spec.template.spec.containers[0].env
          content:
            name: ILIAS_DB_HOST
            value: "RELEASE-NAME-mariadb"
      - contains:
          path: spec.template.spec.containers[0].env
          content:
            name: ILIAS_CLIENT_NAME
            value: "default"

  - it: should set resource requests and limits
    asserts:
      - isNotNull:
          path: spec.template.spec.containers[0].resources.requests
      - isNotNull:
          path: spec.template.spec.containers[0].resources.limits

  - it: should have an init container for setup
    asserts:
      - isNotNull:
          path: spec.template.spec.initContainers[0].name

  - it: should mount data volumes
    asserts:
      - contains:
          path: spec.template.spec.containers[0].volumeMounts
          content:
            name: ilias-data
            mountPath: /var/www/html/data
      - contains:
          path: spec.template.spec.containers[0].volumeMounts
          content:
            name: ilias-iliasdata
            mountPath: /var/iliasdata/ilias

  - it: should reference the ilias secrets
    asserts:
      - contains:
          path: spec.template.spec.containers[0].env
          content:
            name: ILIAS_ROOT_PASSWORD
            valueFrom:
              secretKeyRef:
                name: RELEASE-NAME-ilias-secrets
                key: ilias-root-password

  - it: should set container security context
    asserts:
      - equal:
          path: spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation
          value: false
      - contains:
          path: spec.template.spec.containers[0].securityContext.capabilities.drop
          content: ALL
      - equal:
          path: spec.template.spec.containers[0].securityContext.privileged
          value: false
```

### Example: Service Test

```yaml
suite: Service
templates:
  - service.yaml
values:
  - ../ci/ci-values.yaml
tests:
  - it: should create a Service
    asserts:
      - isKind:
          of: Service

  - it: should expose port 80
    asserts:
      - equal:
          path: spec.ports[0].port
          value: 80

  - it: should target the configured container port
    asserts:
      - equal:
          path: spec.ports[0].targetPort
          value: 80

  - it: should be of type ClusterIP
    asserts:
      - equal:
          path: spec.type
          value: ClusterIP

  - it: should have correct selector labels
    asserts:
      - isSubset:
          path: spec.selector
          content:
            ilias/server: "true"

  - it: should have standard Kubernetes labels
    asserts:
      - isNotNull:
          path: metadata.labels["app.kubernetes.io/name"]
      - isNotNull:
          path: metadata.labels["app.kubernetes.io/instance"]
```

### Example: ConfigMap Test (F13)

```yaml
suite: ConfigMap
templates:
  - configmap-general.yaml
  - configmap-llm.yaml
values:
  - ../ci/ci-values.yaml
tests:
  - it: should create all configmaps with correct kind
    asserts:
      - isKind:
          of: ConfigMap

  - it: should create general configmap with correct name and data key
    template: configmap-general.yaml
    asserts:
      - equal:
          path: metadata.name
          value: RELEASE-NAME-f13-general
      - isSubset:
          path: metadata.labels
          content:
            app.kubernetes.io/component: core
      - isNotNull:
          path: data["general.yml"]

  - it: should contain authentication config in general configmap
    template: configmap-general.yaml
    asserts:
      - matchRegex:
          path: data["general.yml"]
          pattern: "authentication:"
      - matchRegex:
          path: data["general.yml"]
          pattern: "guest_mode: true"
      - matchRegex:
          path: data["general.yml"]
          pattern: "keycloak_base_url: https://keycloak\\.example\\.com"

  - it: should NOT render configmap when service is disabled
    template: configmap-rag.yaml
    set:
      services.rag.enabled: false
    asserts:
      - hasDocuments:
          count: 0
```

### Required Test Files

Every chart should have at minimum:

- `deployment_test.yaml` — Validates deployment structure
- `service_test.yaml` — Validates service configuration
- `ingress_test.yaml` — Validates ingress (if applicable)
- `persistence_test.yaml` — Validates PVCs (if applicable)

### Test Guidelines

1. **Use descriptive test names** — Start with "should" and describe what's being tested
2. **Group related assertions** — Use sections with comments for complex templates
3. **Test conditional rendering** — Use `set` and `hasDocuments: count: 0` for disabled features
4. **Validate security contexts** — Always test `allowPrivilegeEscalation: false` and capabilities
5. **Check resource limits** — Ensure requests and limits are set
6. **Validate labels** — Check for standard Kubernetes labels
7. **Test secret references** — Verify secrets are referenced, not inline

See [docs/testing.md](testing.md) for the broader testing strategy.

## NOTES.txt

The `NOTES.txt` template provides post-install guidance to users.

### Example: ILIAS

```yaml
Thank you for installing {{ .Chart.Name }}!

Your release is named {{ .Release.Name }}.

To access the service:
  export POD_NAME=$(kubectl get pods --namespace {{ .Release.Namespace }} -l "app.kubernetes.io/instance={{ .Release.Name }}" -o jsonpath="{.items[0].metadata.name}")
  kubectl port-forward --namespace {{ .Release.Namespace }} $POD_NAME 8080:80

Next steps:
  1. Complete the ILIAS setup wizard (auto-setup enabled by default)
  2. Configure SAML/SSO integration with Keycloak
  3. Set up persistent storage for course data and uploads

Documentation: https://github.com/tobias-weiss-ai-xr/opendesk-edu
```

### Example: BookStack

```yaml
Thank you for installing {{ .Chart.Name }}!

Your release is named {{ .Release.Name }}.

To access the service:
  export POD_NAME=$(kubectl get pods --namespace {{ .Release.Namespace }} -l "app.kubernetes.io/instance={{ .Release.Name }}" -o jsonpath="{.items[0].metadata.name}")
  kubectl port-forward --namespace {{ .Release.Namespace }} $POD_NAME 8080:80

Next steps:
  1. Complete the initial BookStack setup wizard
  2. Configure SSO/SSO integration if needed
  3. Set up persistent storage for uploads

Documentation: https://github.com/tobias-weiss-ai-xr/opendesk-edu
```

### Example: F13 (Multi-component)

```yaml
Thank you for installing {{ .Chart.Name }}!

Your release is named {{ .Release.Name }}.

To access the F13 frontend:
  export POD_NAME=$(kubectl get pods --namespace {{ .Release.Namespace }} -l "app.kubernetes.io/instance={{ .Release.Name }},app.kubernetes.io/component=frontend" -o jsonpath="{.items[0].metadata.name}")
  kubectl port-forward --namespace {{ .Release.Namespace }} $POD_NAME 9999:9999

Next steps:
  1. Configure the LLM provider API key and model names
  2. Enable Keycloak authentication via global.keycloakUrl
  3. Review values.yaml to enable/disable individual AI services

Documentation: https://github.com/tobias-weiss-ai-xr/opendesk-edu
```

### NOTES.txt Guidelines

1. **Start with a thank you** — Use the template variables for chart name and release name
2. **Provide access instructions** — Show how to access the service via port-forward
3. **List next steps** — What should users do after installation
4. **Link to documentation** — Point users to the project docs
5. **Keep it concise** — 10-15 lines is sufficient
6. **Use specific selectors** — For multi-component charts, filter by component label

## Running Tests

To run tests for a specific chart:

```bash
cd helmfile/charts/{chart-name}
helm unittest .
```

To run all chart tests:

```bash
cd helmfile/charts
for chart in */; do
  echo "Testing $chart"
  cd "$chart"
  helm unittest .
  cd ..
done
```

## Common Patterns

### Database Subcharts

For services that need a database, use vendored subcharts:

```yaml
dependencies:
- condition: mariadb.enabled
  name: mariadb
  repository: https://charts.bitnami.com/bitnami
  version: 20.2.2
```

Then reference the database in deployment templates:

```yaml
env:
  - name: DB_HOST
    value: {{ include "mariadb.fullname" .Subcharts.mariadb }}
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "mariadb.fullname" .Subcharts.mariadb }}
        key: mariadb-password
```

### Secret Management

Never hardcode secrets. Use secret references:

```yaml
env:
  - name: API_KEY
    valueFrom:
      secretKeyRef:
        name: RELEASE-NAME-secrets
        key: api-key
```

### Resource Limits

Always set resource requests and limits:

```yaml
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 100m
    memory: 128Mi
```

### Security Contexts

Set secure security contexts:

```yaml
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  privileged: false
  runAsNonRoot: true
  runAsUser: 1000
  seccompProfile:
    type: RuntimeDefault
```

## Checklist

Before submitting a new chart:

- [ ] Chart.yaml has all required fields and annotations
- [ ] values.yaml defines sensible defaults
- [ ] ci/ci-values.yaml exercises all templates with minimal resources
- [ ] templates/ follows the canonical structure
- [ ] tests/ has at least deployment, service, ingress, and persistence tests
- [ ] tests pass with `helm unittest .`
- [ ] NOTES.txt provides clear post-install guidance
- [ ] No hardcoded secrets or passwords
- [ ] Resource requests and limits are set
- [ ] Security contexts are configured
- [ ] Standard Kubernetes labels are used
- [ ] Documentation is referenced in Chart.yaml and NOTES.txt

## References

- [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Helm Unittest](https://github.com/quintush/helm-unittest)
- [Artifact Hub Annotations](https://artifacthub.io/docs/topics/annotations/helm/)
- [openDesk Edu Testing](testing.md)
