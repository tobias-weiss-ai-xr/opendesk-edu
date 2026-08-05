# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in openDesk Edu, please report it privately.

**Do not** create a public GitHub issue for security vulnerabilities.

Instead, send a description of the issue to the maintainers via one of the following:

- **GitHub Security Advisory**: https://github.com/opendesk-edu/opendesk-edu/security/advisories
- **Email**: info@opendesk.edu

We will acknowledge receipt within 48 hours and provide an estimated timeline for a fix.

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| main    | ✅ Active development |

## Disclosure Policy

- We will investigate and fix verified vulnerabilities promptly.
- A security advisory will be published after the fix is released.
- We follow a 90-day disclosure timeline for publicly reported issues.

## Security-Related Configuration

- **SOPS**: All secrets must be encrypted using SOPS with Age key (`age13zw40j4...`).
  See `docs/developer/sops-argocd-integration.md` for setup instructions.
- **MASTER_PASSWORD**: Required environment variable for deployment.
  Used by CE's `derivePassword` function to generate deterministic secrets.
- **Keycloak**: SAML client secrets must be pre-configured in
  `helmfile/environments/edu/secrets.yaml` before first deployment.
- **Network policies**: Default-deny + allow-dns are enabled by default.
  Service-specific allow rules must be added for new components.
