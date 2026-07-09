<!--
SPDX-FileCopyrightText: 2023-2025 Univention GmbH
SPDX-License-Identifier: AGPL-3.0-only
-->
{{ template "chart.header" . }}
{{ template "chart.description" . }}

## Installing the Chart

To install the chart with the release name `my-release`, you have two options:

### Install via Repository
```console
helm repo add ${CI_PROJECT_NAME} ${CI_SERVER_PROTOCOL}://${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/helm/stable
helm install my-release --version ${RELEASE_VERSION} ${CI_PROJECT_NAME}/{{ template "chart.name" . }}
```

### Install via OCI Registry
```console
helm repo add ${CI_PROJECT_NAME} oci://${CI_REGISTRY_IMAGE}
helm install my-release --version ${RELEASE_VERSION} ${CI_PROJECT_NAME}/{{ template "chart.name" . }}
```

{{ template "chart.requirementsSection" . }}

{{ template "chart.valuesSection" . }}

## Uninstalling the Chart

To install the release with name `my-release`:

```bash
helm uninstall my-release
```

## Signing

### Chart

Helm charts are signed with helm native signing method. You can verify the charts against this GPG key:

```
${GPG_SOUVAP_UNIVENTION_PUB}
```

### Images

Container images are signed via [cosign](https://github.com/sigstore/cosign) and can be verified with:

```
${COSIGN_PUBLIC_KEY}
```

```
cosign verify --key cosign.pub --insecure-ignore-tlog <image>
```

## License
This project uses the following license: AGPL-3.0-only


## Copyright
Copyright (C) 2023-2025 Univention GmbH
