# Upstream: intercom-service Helm Chart

This chart is a fork of the **Univention** intercom-service Helm chart.

| Attribute | Value |
|---|---|
| **Upstream** | Univention GmbH |
| **Repository** | `oci://artifacts.software-univention.de/nubus/charts` |
| **Chart name** | `intercom-service` |
| **Forked version** | `2.23.11` |
| **Original license** | AGPL-3.0-or-later |

## Local changes

- Chart made self-contained: external OCI dependency (`nubus-common`) removed,
  vendored copy in `charts/` used instead
- Image registry changed to self-hosted (`codeberg.org/opendesk-edu/intercom-service`)
- YAML indentation fix for `image` key in `values.yaml` (nested subkeys)
- Various edu configuration adjustments in values and templates

## How to sync with upstream

```bash
helm repo add univention oci://artifacts.software-univention.de/nubus/charts
helm pull univention/intercom-service --version <new-version> --untar
# Manually re-apply edu patches listed above
```
