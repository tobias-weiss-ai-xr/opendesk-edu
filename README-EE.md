<!--
SPDX-FileCopyrightText: 2024-2025 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>openDesk Enterprise Edition</h1>

<!-- TOC -->
* [Components](#components)
* [Enabling the Enterprise deployment](#enabling-the-enterprise-deployment)
* [Configuring the oD EE deployment for self-hosted installations](#configuring-the-od-ee-deployment-for-self-hosted-installations)
  * [Registry access](#registry-access)
  * [License keys](#license-keys)
<!-- TOC -->

openDesk Enterprise Edition is recommended for production use. It receives support and patches from ZenDiS and the suppliers of the components due to the included product subscriptions.

The document refers to openDesk Community Edition as "oD CE" and for the openDesk Enterprise Edition it is "oD EE".

Please contact [ZenDiS](mailto:opendesk@zendis.de) to get openDesk Enterprise, either as SaaS offering or for you on-premise installation.

# Components

The following components using the same codebase and artifacts for their Enterprise and Community offering:
- Cryptpad
- Jitsi
- Nubus
- OpenProject
- XWiki

The following components have - at least partially - Enterprise specific artifacts:

- Collabora: Collabora Online image version `<major>.<minor>.<patch>.3` will be used once available, at the same time the Collabora Development Edition image will be updated to `<major>.<minor>.<patch>.2` for oD CE.
- Element: Some artifacts providing additional functionality are only available in oD EE. For the shared artifacts we keep the ones in oD CE and oD EE in sync.
- Nextcloud: Specific enterprise image based on the NC Enterprise package is build based on the same release version as used in oD CE.
- OX AppSuite: oD CE and EE are using the same release version, in EE an enterprise-built container of the AppSuite's Core-Middleware is being integrated.
- OX Dovecot Pro 3: Dovecot Pro provides support for S3 storage and this feature is used by default.

# Enabling the Enterprise deployment

To enable the oD EE deployment you must set the environment variable `OPENDESK_ENTERPRISE` to any value that does not evaluate to boolean *false* for [Helm flow control](https://helm.sh/docs/chart_template_guide/control_structures/#ifelse), e.g. `"true"`, `"yes"` or `"1"`:

```shell
OPENDESK_ENTERPRISE=true
```

# Configuring the oD EE deployment for self-hosted installations

## Registry access

With openDesk EE you get access to the related artifact registry owned by ZenDiS.

Three steps are required to access the registry - for step #1 and #2 you can set some variables. You can to define a `<your_name_for_the_secret>` freely, like `enterprise-secret`, as long as it consistent in step #1 and #3.

```shell
NAMESPACE=<your_namespace>
NAME_FOR_THE_SECRET=<your_name_for_the_secret>
YOUR_ENTERPRISE_REGISTRY_USERNAME=<your_registry_credential_username>
YOUR_ENTERPRISE_REGISTRY_PASSWORD=<your_registry_credential_password>
```

1. Add your registry credentials as secret to the namespace you want to deploy openDesk to. Do not forget to create the namespace if it does not exist yet (`kubectl create namespace ${NAMESPACE}`).

```shell
kubectl create secret --namespace "${NAMESPACE}" \
  docker-registry "${NAME_FOR_THE_SECRET}" \
  --docker-server "registry.opencode.de" \
  --docker-username "${YOUR_ENTERPRISE_REGISTRY_USERNAME}" \
  --docker-password "${YOUR_ENTERPRISE_REGISTRY_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -
```

2. Docker login to the registry to access Helm charts for local deployments:

```shell
docker login registry.opencode.de -u ${YOUR_ENTERPRISE_REGISTRY_USERNAME} -p ${YOUR_ENTERPRISE_REGISTRY_PASSWORD}
```

3. Reference the secret from step #1 in the deployment as well as the registry itself for `images` and `helm` charts:

```yaml
global:
  imagePullSecrets:
    - "<your_name_for_the_secret>"
repositories:
  image:
    registryOpencodeDeEnterprise: "registry.opencode.de"
  helm:
    registryOpencodeDeEnterprise: "registry.opencode.de"
```

## License keys

Some applications require license information for their Enterprise features to be enabled. With the aforementioned registry credentials you will also receive a file called `enterprise.yaml` containing the relevant license keys.

Please place the file next your other `.yaml.gotmpl` file(s) that configure your deployment.

Details regarding the scope/limitation of the component's licenses:

- Nextcloud: Enterprise license to enable [Nextcloud Enterprise](https://nextcloud.com/de/enterprise/) specific features, can be used across multiple installations until the licensed number of users is reached.
- OpenProject: Domain specific enterprise license to enable [OpenProject's Enterprise feature set](https://www.openproject.org/enterprise-edition/), domain matching can use regular expressions.
- XWiki: Deployment specific enterprise license (key pair) to activate the [XWiki Pro](https://xwiki.com/en/offerings/products/xwiki-pro) apps.
