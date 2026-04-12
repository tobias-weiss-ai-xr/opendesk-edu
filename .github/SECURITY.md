<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Security Policy / Sicherheitsrichtlinie

<!--
English: How to responsibly report security vulnerabilities in openDesk Edu.
Deutsch: Wie man Sicherheitslücken in openDesk Edu verantwortungsvoll meldet.
-->

## 🔐 Reporting a Vulnerability / Melden einer Sicherheitslücke

**⚠️ Do NOT open a public issue for security vulnerabilities! ⚠️**
**⚠️ Eröffnen Sie KEIN öffentliches Issue für Sicherheitslücken! ⚠️**

### How to Report / Wie man meldet

| Method / Methode | Details |
|------------------|---------|
| **GitHub Security Advisory** (preferred) | [Create private advisory](https://github.com/opendesk-edu/deployment/security/advisories/new) |
| **Email** | security@opendesk-edu.org |

### What to Include / Was Sie einschließen sollten

When reporting a security vulnerability, please provide:

1. **Description** — A clear description of the vulnerability
2. **Affected versions** — Which versions of openDesk Edu are affected
3. **Steps to reproduce** — How to reproduce the issue
4. **Proof of concept** — Code or screenshots demonstrating the vulnerability
5. **Potential impact** — What could an attacker achieve
6. **Suggested fix** — If you have ideas for remediation

---

## 📋 Response Timeline / Reaktionszeitplan

| Milestone / Meilenstein | Target / Ziel |
|-------------------------|---------------|
| **Acknowledgment / Bestätigung** | 48 hours / 48 Stunden |
| **Initial assessment / Erste Bewertung** | 7 days / 7 Tage |
| **Status update / Status-Update** | Every 7 days / Alle 7 Tage |
| **Fix coordination / Koordinierung des Fixes** | As needed / Nach Bedarf |
| **Disclosure / Veröffentlichung** | After fix released / Nach Veröffentlichung des Fixes |

---

## 🛡️ Supported Versions / Unterstützte Versionen

| Version | Supported / Unterstützt |
|---------|------------------------|
| Latest release (main branch) | ✅ Yes / Ja |
| Previous major release | ⚠️ Critical fixes only / Nur kritische Fixes |
| Older versions | ❌ No / Nein |

**Recommendation / Empfehlung:** Always upgrade to the latest release for security updates.
**Empfehlung:** Aktualisieren Sie immer auf die neueste Version für Sicherheitsupdates.

---

## 🎯 Scope / Geltungsbereich

### In Scope / Im Geltungsbereich

Security reports for **openDesk Edu-specific code** are welcome:

| Category / Kategorie | Examples / Beispiele |
|----------------------|---------------------|
| **Helm Charts** | Custom charts, values templates, helpers |
| **Integration Code** | SSO handlers, backchannel logout, session management |
| **Custom Images** | Dockerfiles, entrypoint scripts |
| **Configuration** | Default credentials, insecure defaults, exposed secrets |
| **Documentation** | Sensitive information leakage in docs |

### Out of Scope / Außerhalb des Geltungsbereichs

| Category / Kategorie | Action / Aktion |
|----------------------|-----------------|
| **Upstream components** | Report to respective project |
| **Third-party CVEs** | Update via normal channels |
| **DoS attacks** | Not a vulnerability type we handle |
| **Social engineering** | User awareness issue |

---

## 🔗 Upstream Security Contacts / Upstream-Sicherheitskontakte

For vulnerabilities in upstream components, report directly to the respective projects:

| Component / Komponente | Security Contact / Sicherheitskontakt |
|------------------------|--------------------------------------|
| **openDesk CE** | [Bundesdruckerei/openDesk Security](https://github.com/Bundesdruckerei/opendesk/security) |
| **ILIAS** | [ILIAS Security](https://docu.ilias.de/goto_docu_wiki_wpage_3207.html) |
| **Moodle** | [Moodle Security](https://moodle.org/security/) |
| **BigBlueButton** | [BBB Security](https://github.com/bigbluebutton/bigbluebutton/security) |
| **OpenCloud** | [OpenCloud Security](https://github.com/opencloudeu/opencloud/security) |
| **Keycloak** | [Keycloak Security](https://www.keycloak.org/security) |
| **Element** | [Element Security](https://element.io/security) |
| **Nextcloud** | [Nextcloud Security](https://hackerone.com/nextcloud) |
| **XWiki** | [XWiki Security](https://www.xwiki.org/xwiki/bin/view/XWiki/SecurityAlerts) |
| **OpenProject** | [OpenProject Security](https://www.openproject.org/docs/security/) |

---

## 🔒 Security Best Practices / Sicherheitsbest Practices

### For Deployment / Für die Bereitstellung

When deploying openDesk Edu, ensure:

- [ ] **No default credentials** — Change all default passwords
- [ ] **TLS enabled** — Use valid certificates for all services
- [ ] **Network policies** — Restrict pod-to-pod communication
- [ ] **Secrets management** — Use external secrets (Vault, SOPS, etc.)
- [ ] **Regular updates** — Keep components up to date
- [ ] **Audit logging** — Enable audit logs for critical services
- [ ] **Backup encryption** — Encrypt backup storage

### For Development / Für die Entwicklung

When contributing code:

- [ ] **No secrets in code** — Never commit passwords, tokens, or keys
- [ ] **Input validation** — Validate all external inputs
- [ ] **Secure defaults** — Use secure default configurations
- [ ] **Dependency scanning** — Check dependencies for CVEs
- [ ] **Container security** — Run as non-root, read-only filesystem

---

## 📜 Safe Harbor / Sichere Grundlage

We consider security research conducted under this policy to be:
Wir betrachten Sicherheitsforschung, die unter dieser Richtlinie durchgeführt wird, als:

- **Authorized** — Conducted in accordance with this policy
- **In good faith** — Not intended to cause harm

We will not pursue legal action against researchers who:
Wir werden keine rechtlichen Schritte gegen Forscher einleiten, die:

- Follow this policy
- Act in good faith
- Do not access data beyond what is necessary
- Report vulnerabilities promptly

---

## 📞 Contact / Kontakt

| Purpose / Zweck | Contact / Kontakt |
|-----------------|-------------------|
| **Security issues** | security@opendesk-edu.org |
| **General questions** | [GitHub Discussions](https://github.com/opendesk-edu/deployment/discussions) |
| **Bug reports** | [GitHub Issues](https://github.com/opendesk-edu/deployment/issues) |

---

_This security policy is based on industry best practices and aligned with [GitHub's security features](https://docs.github.com/en/code-security)._

_Diese Sicherheitsrichtlinie basiert auf bewährten Branchenpraktiken und ist auf die [Sicherheitsfunktionen von GitHub](https://docs.github.com/en/code-security) abgestimmt._
