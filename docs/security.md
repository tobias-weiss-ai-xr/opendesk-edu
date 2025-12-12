<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<h1>Security</h1>

This document covers the current status of security measures.

<!-- TOC -->
* [Helm chart trust chain](#helm-chart-trust-chain)
* [Kubernetes security enforcements](#kubernetes-security-enforcements)
* [Network policies](#network-policies)
<!-- TOC -->

# Helm chart trust chain

Helm charts are signed and validated against GPG keys in `helmfile/files/gpg-pubkeys`.

For more details on Chart validation, please visit: https://helm.sh/docs/topics/provenance/

All charts except the ones mentioned below are verified by Helmfile.

| Repository                | Verifiable |
| ------------------------- | :--------: |
| collabora-controller-repo |     no     |
| open-xchange-repo         | cosign[^1] |

# Kubernetes security enforcements

This list gives you an overview of default security settings and whether they comply with security standards:

⟶ Visit our generated detailed [Security Context](./docs/security-context.md) overview.

# Network policies

Kubernetes network policies are an essential measure to secure your Kubernetes apps and clusters.
When applied, they restrict traffic to your services.
`NetworkPolicy` resources protect other deployments in your cluster or other services in your deployment from getting compromised when another
component is compromised.

We ship a default set of Otterize `ClientIntents` via
[Otterize intents operator](https://github.com/otterize/intents-operator) which translates intent-based access control
(IBAC) into Kubernetes native network policies.

This requires the Otterize intents operator to be installed.

```yaml
security:
  otterizeIntents:
    enabled: true
```

[^1]: Helmfile does not support cosign chart verification yet, though the chart can be [externally verified](https://docs.sigstore.dev/cosign/verifying/verify/) using the key(s) in `helmfile/files/cosign-pubkeys`
