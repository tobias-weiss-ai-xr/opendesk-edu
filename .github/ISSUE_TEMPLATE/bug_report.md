---
name: Bug report
about: Report a bug in openDesk Edu
title: "[Bug] "
labels: bug
assignees: ''
---

## Bug description

A clear and concise description of what the bug is.

## Steps to reproduce

1. Deploy openDesk Edu with the following configuration:
2. Navigate to...
3. Click on...
4. See error

## Expected behavior

A clear and concise description of what you expected to happen.

## Actual behavior

What actually happened. Include relevant error messages, logs, or screenshots.

## Environment

- **openDesk Edu version**:
- **Kubernetes distribution and version**: (e.g., RKE2 1.28, K3s 1.29)
- **Ingress controller**: (e.g., HAProxy, NGINX)
- **Storage class**: (e.g., Ceph RBD, local-path)
- **Component affected**: (e.g., ILIAS, Moodle, BigBlueButton, OpenCloud, Keycloak, Open-Xchange)

## Helmfile configuration

Share the relevant sections of your environment configuration (redact secrets):

```yaml
# helmfile/environments/<env>/values.yaml.gotmpl
```

## Logs

```
# kubectl logs -n <namespace> <pod> --tail=100
```

## Additional context

Any other context that might help diagnose the issue (e.g., recent upgrade, SSO configuration).
