<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->
**Content / Quick navigation**

[[_TOC_]]

# Disclaimer July 2023

The current state of the SouvAP is missing two components that are not yet generally available to the public also outside the SouvAP (Element Starter Edition and Open-Xchange App Suite 8), and contains components that will be replaced (e.g. UCS container monolith with multiple Univention Management Stack containers). We not only expect upstream updates of the functional components within their feature scope but we are going to address operational issues like monitoring and network policies.

Of course we will extend the documentation


# The Sovereign Workplace (SWP)

The SWP's runtime environment is [Kubernetes](https://kubernetes.io/), often written in it's short form "K8s".

While not all components are perfectly shaped for the execution as containers, one of the projects objectives is the make the applications more aligned with best practise when it comes to container design and operations.

This documentation gives you - hopefully - all you need to setup your own instance of the SWP. You should have at least basic knowledge Kubernetes and Devops knowledge.

To have an overview of what can be found at Open CoDE and the basic components of the SWP, please check out the [OVERVIEW.md](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/info/-/blob/main/OVERVIEW.md) in the [Info repository](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/info).

Especially check out the section ["Mitwirkung und Beteiligung"](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/info/-/blob/main/OVERVIEW.md#mitwirkung-und-beteiligung) if you are missing something or you have questions. We appreciate your feedback to improve product and documentation.
## Prerequisites

You have to take care about the following prerequisites in order to deploy the SWP:

- Vanilla K8s cluster
- Domain and DNS Service [ToDo: manual setup docu with * record...]
- Ingress controller (supported are nginx-ingress, ingress-nginx, HAProxy and Cillium)
- [Helm](https://helm.sh/), [HelmFile](https://helmfile.readthedocs.io/en/latest/) and [HelmDiff](https://github.com/databus23/helm-diff)
- Volume provisioner supporting RWO (read-write-once) and RWX (read-write-many)
- Certificate handling with [cert-manager](https://cert-manager.io/)
- [Istio](https://istio.io/) is currently required to deploy and operate OX AppSuite8, we are working with Open-Xchange to get rid of this component.

### Feature based prerequisites

- An external SMTP relay/gateway for sending mails from various components
- PKI / CI for Open-Xchange AppSuite S/MIME feature
- STUN/TURN server

#

- Domain and cert management (table with all hostnames we need to set (`<function>.<domain>`), reference to cert-manager, manual requires in DNS service)
- Parametrisierungsdoku
  - Service components
  - Environments (ingress & storage definitions)
  - Secrets (and "upstream" input secrets)

[ggf. später]
- Debugging (explain the centralized debugging values and provide additional debugging info for each component - when available. Explain that the midterm goal is to have distroless containers!)
- Functional Components
- Service Components
- CONTRIBUTE.md


## Self contained deployment

We differenciate between
- functional components (e.g. Fileshare, Groupware, IAM etc.) that are the actual focus of the SWP and
- service components (e.g. databases, storage) that are available within this deployment as well in order to make it self-contained. But in other than dev, test and demo scenarios we expect service components to be provided externally by the operator.

**DEV-REQUIREMENT**: A functional component that makes use of a service component has to support a config option that allows the use of an external service and skips the installation of the given service component within the deployment, as long as no other functional compontent still relies on that service component.

## CI based deployment

**Note: Please only deploy components you need for your developmet, as the full stack is quite resource hungry and we have limited resources. There is a nightly (namespace `nighly`) build from `main` on the `develop` cluster with all components enabled.**

**Note: Currently Gitlab sometimes does not load the configures pipeline variables as expected, so if you don't see any predefined variables on the pipelines mentioned in this document you want to reload the page in order to ensure there aren't any variables. It works on reload in 99% of the cases.**

- Please use the `develop` cluster unless you are explicitly advised to use another cluster.
- Install prerequisites and gain access to the cluster following the instructions here: https://gitlab.souvap-univention.de/groups/souvap/devops/-/wikis/deployment/K8s-cluster
- In order to deploy an instance of the SWP with selected components by running the pipeline of this project you need to request a certificate first by executing this pipeline: https://gitlab.souvap-univention.de/souvap/infrastructure/k8s-certificates/-/pipelines/new stating your desired namespace.
  - You might want to check the available certificates first: `kubectl -n istio-system get certificate`
  - We have separated the cert-management from the actual deployment to avoid getting hit my letsencrypt's rate limits.

Todos
- some info on the modules
- some info on how long a deployment takes
- rerun / update vs redeploy vs refresh complete namespace
- some info on "debugging" the deployment
- semantic release (on main)

## Local deployments

[..]

## Helmfile

### Setup

helmfile needs `helm` and the helm plugin `helm-diff` to run properly.

To install helm-diff (  helm >2.3.):
```bash
helm plugin install https://github.com/databus23/helm-diff
```

### Environment

You need to expose following variables to run the default installation with helmfile


| name                | default                      | description                                              |
|---------------------|------------------------------|----------------------------------------------------------|
| `DOMAIN`            | `souvap-univention.de`       | External reachable TLD.                                  |
| `ISTIO_DOMAIN`      | `istio.souvap-univention.de` | External reachable TLD for Istio Gateway.                |
| `MASTER_PASSWORD`   | `sovereign-workplace`        | The password where generated passwords are derived from. |
| `SMTP_PASSWORD`     |                              | Password for STMP relay gateway.                         |
| `TURN_CREDENTIALS`  |                              | Credentials for coturn server.                           |

### Configuration

In order to have a functional deployment, you need to adapt the default values to your infrastructure.

#### Deployment selection

As default, all available components are deployed.

| Component                   | Name                                | Default | Description                     |
|-----------------------------|-------------------------------------|---------|---------------------------------|
| Certificates                | `certificates.enabled`              | `true`  | TLS certificates.               |
| ClamAV                      | `clamav.enabled`                    | `true`  | Antivirus engine.               |
| Collabora                   | `collabora.enabled`                 | `true`  | Weboffice                       |
| Dovecot                     | `dovecot.enabled`                   | `true`  | Mail backend (for development). |
| Intercom Service            | `intercom.enabled`                  | `true`  | Cross service data exchange.    |
| Jitsi                       | `jitsi.enabled`                     | `true`  | Videoconferencing               |
| Keycloak                    | `keycloak.enabled`                  | `true`  | Identity Provider               |
| MariaDB                     | `mariadb.enabled`                   | `true`  | Database (for development)      |
| Nextcloud                   | `nextcloud.enabled`                 | `true`  | File share                      |
| OpenProject                 | `openproject.enabled`               | `true`  | Project management              |
| OX Appsuite                 | `oxAppsuite.enabled`                | `true`  | Groupware                       |
| OX Connector                | `oxConnector.enabled`               | `true`  | Backend provisioning            |
| Postfix                     | `postfix.enabled`                   | `true`  | MTA (for development)           |
| PostgreSQL                  | `postgresql.enabled`                | `true`  | Database (for development)      |
| Redis                       | `redis.enabled`                     | `true`  | Cache (for development)         |
| Univention Corporate Server | `univentionCorporateServer.enabled` | `true`  | LDAP                            |
| XWIKI                       | `xwiki.enabled`                     | `true`  | Knowledgebase                   |

#### TLS Certificate

The setup will create a `cert-manager.io` Certificate resource.

You can set the ClusterIssuer via `certificate.issuerRef.name`

#### Databases

| Component   | Name               | Type       | Parameter | Key                                    | Default                    |
|-------------|--------------------|------------|-----------|----------------------------------------|----------------------------|
| Keycloak    | Keycloak           | PostgreSQL |           |                                        |                            |
|             |                    |            | Name      | `databases.keycloak.name`              | `keycloak`                 |
|             |                    |            | Host      | `databases.keycloak.host`              | `postgresql`               |
|             |                    |            | Port      | `databases.keycloak.port`              | `5432`                     |
|             |                    |            | Username  | `databases.keycloak.username`          | `keycloak_user`            |
|             |                    |            | Password  | `databases.keycloak.password`          |                            |
|             | Keycloak Extension | PostgreSQL |           |                                        |                            |
|             |                    |            | Name      | `databases.keycloakExtension.name`     | `keycloak_extensions`      |
|             |                    |            | Host      | `databases.keycloakExtension.host`     | `postgresql`               |
|             |                    |            | Port      | `databases.keycloakExtension.port`     | `5432`                     |
|             |                    |            | Username  | `databases.keycloakExtension.username` | `keycloak_extensions_user` |
|             |                    |            | Password  | `databases.keycloakExtension.password` |                            |
| Nextcloud   | Nextcloud          | MariaDB    |           |                                        |                            |
|             |                    |            | Name      | `databases.nextcloud.name`             | `nextcloud`                |
|             |                    |            | Host      | `databases.nextcloud.host`             | `mariadb`                  |
|             |                    |            | Username  | `databases.nextcloud.username`         | `nextcloud_user`           |
|             |                    |            | Password  | `databases.nextcloud.password`         |                            |
| OpenProject | Keycloak           | PostgreSQL |           |                                        |                            |
|             |                    |            | Name      | `databases.openproject.name`           | `openproject`              |
|             |                    |            | Host      | `databases.openproject.host`           | `postgresql`               |
|             |                    |            | Port      | `databases.openproject.port`           | `5432`                     |
|             |                    |            | Username  | `databases.openproject.username`       | `openproject_user`         |
|             |                    |            | Password  | `databases.openproject.password`       |                            |
| OX Appsuite | OX Appsuite        | MariaDB    |           |                                        |                            |
|             |                    |            | Name      | `databases.oxAppsuite.name`            | `CONFIGDB`                 |
|             |                    |            | Host      | `databases.oxAppsuite.host`            | `mariadb`                  |
|             |                    |            | Username  | `databases.oxAppsuite.username`        | `root`                     |
|             |                    |            | Password  | `databases.oxAppsuite.password`        |                            |
| XWIKI       | XWIKI              | MariaDB    |           |                                        |                            |
|             |                    |            | Name      | `databases.xwiki.name`                 | `xwiki`                    |
|             |                    |            | Host      | `databases.xwiki.host`                 | `mariadb`                  |
|             |                    |            | Username  | `databases.xwiki.username`             | `xwiki_user`               |
|             |                    |            | Password  | `databases.xwiki.password`             |                            |

#### Scaling

Replicas for scalable components can be increased.

| Component   | Name                   | Default | Service            | Scaling            |
|-------------|------------------------|---------|--------------------|--------------------|
| ClamAV      | `replicas.clamd`       | `1`     | :white_check_mark: | :white_check_mark: |
|             | `replicas.freshclam`   | `1`     | :white_check_mark: | :x:                |
|             | `replicas.icap`        | `1`     | :white_check_mark: | :white_check_mark: |
|             | `replicas.milter`      | `1`     | :white_check_mark: | :white_check_mark: |
| Collabora   | `replicas.collabora`   | `1`     | :white_check_mark: | :white_check_mark: |
| Dovecot     | `replicas.dovecot`     | `1`     | :white_check_mark: | :x:                |
| Jitsi       | `replicas.jibri`       | `1`     | :white_check_mark: | :white_check_mark: |
|             | `replicas.jicofo`      | `1`     | :white_check_mark: | :white_check_mark: |
|             | `replicas.jitsi `      | `1`     | :white_check_mark: | :white_check_mark: |
|             | `replicas.jvb `        | `1`     | :white_check_mark: | :white_check_mark: |
| Keycloak    | `replicas.keycloak`    | `1`     | :white_check_mark: | :white_check_mark: |
| Nextcloud   | `replicas.nextcloud`   | `1`     | :white_check_mark: | :white_check_mark: |
| OpenProject | `replicas.openproject` | `1`     | :white_check_mark: | :white_check_mark: |
| Postfix     | `replicas.postfix`     | `1`     | :white_check_mark: | :x:                |
| XWIKI       | `replicas.xwiki`       | `1`     | :white_check_mark: | :white_check_mark: |
