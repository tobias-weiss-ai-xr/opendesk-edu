<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

## Summary / Zusammenfassung

<!--
English: Brief description of what this PR changes and why.
Deutsch: Kurze Beschreibung, was dieser PR ändert und warum.
-->
_What does this PR do? Why is it needed?_

## Type of Change / Art der Änderung

- [ ] 🐛 **Bug fix** — Non-breaking change that fixes an issue
- [ ] ✨ **New feature** — Non-breaking change that adds functionality
- [ ] 💥 **Breaking change** — Fix or feature that would cause existing functionality to not work as expected
- [ ] 📚 **Documentation** — Documentation update only
- [ ] 🔧 **Configuration** — Helm values, environment config, or secrets changes
- [ ] 📦 **Refactor** — Code restructuring without functional changes
- [ ] 🧪 **Tests** — Adding or updating tests
- [ ] 🔖 **Chore** — Dependencies, CI/CD, or maintenance

## Component(s) Affected / Betroffene Komponente(n)

_Check all that apply: / Alle zutreffenden markieren:_

- [ ] ILIAS
- [ ] Moodle
- [ ] BigBlueButton
- [ ] OpenCloud
- [ ] Etherpad
- [ ] BookStack
- [ ] Planka
- [ ] Zammad
- [ ] LimeSurvey
- [ ] LTB Self-Service Password
- [ ] Draw.io
- [ ] Excalidraw
- [ ] Keycloak / SSO
- [ ] Portal / Nubus
- [ ] Helmfile (core deployment)
- [ ] CI/CD pipelines
- [ ] Documentation

## Related Issues / Verwandte Issues

<!--
Link to any related issues. Use "Fixes #123" to auto-close on merge.
Verknüpfen Sie verwandte Issues. Verwenden Sie "Fixes #123" zum automatischen Schließen beim Mergen.
-->

- Fixes #
- Related to #

## Testing / Tests

<!--
Describe how you tested this change.
Beschreiben Sie, wie Sie diese Änderung getestet haben.
-->

### Testing Method / Testmethode

- [ ] Deployed to local/test cluster
- [ ] Ran `helmfile -e dev template` without errors
- [ ] Ran `helm lint` on affected charts
- [ ] Ran `helm unittest` for chart tests
- [ ] Verified SSO login flow
- [ ] Tested backchannel logout (if applicable)
- [ ] Manual UI testing
- [ ] E2E tests (Playwright)
- [ ] Other: _______________

### Test Configuration / Testkonfiguration

<!--
If applicable, share relevant test environment details.
Falls zutreffend, teilen Sie relevante Details zur Testumgebung.
-->

- Kubernetes version:
- Helm version:
- Platform (RKE2, K3s, kubeadm, etc.):

## Screenshots / Screenshots

<!--
If applicable, add screenshots to help explain your changes.
Falls zutreffend, fügen Sie Screenshots hinzu, um Ihre Änderungen zu erklären.
-->

| Before / Vorher | After / Nachher |
|-----------------|-----------------|
| _screenshot_    | _screenshot_    |

## Checklist / Checkliste

<!--
Before submitting, ensure you've completed all applicable items.
Vor dem Einreichen stellen Sie sicher, dass Sie alle zutreffenden Punkte erfüllt haben.
-->

### Code Quality / Codequalität

- [ ] My code follows the [coding standards](../CONTRIBUTING.md#coding-standards)
- [ ] I have performed a self-review of my changes
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have added/updated SPDX copyright headers in all modified files

### Testing / Tests

- [ ] New and existing tests pass locally
- [ ] I have added tests that prove my fix/feature works
- [ ] Helm charts lint successfully (`helm lint`)

### Documentation / Dokumentation

- [ ] I have updated relevant documentation
- [ ] I have added inline documentation where needed
- [ ] README updates included (if applicable)

### Security / Sicherheit

- [ ] No secrets, passwords, or credentials are included in this PR
- [ ] Container security contexts are properly configured (if applicable)
- [ ] No new security vulnerabilities introduced

### Compatibility / Kompatibilität

- [ ] Changes are backwards-compatible
- [ ] Breaking changes are documented in commit message
- [ ] Migration steps documented (if applicable)

## Additional Notes / Zusätzliche Anmerkungen

<!--
Any additional information, context, or concerns.
Irgendwelche zusätzlichen Informationen, Kontexte oder Bedenken.
-->

---

_Thank you for contributing to openDesk Edu! 🎓_

_Vielen Dank für Ihren Beitrag zu openDesk Edu! 🎓_
