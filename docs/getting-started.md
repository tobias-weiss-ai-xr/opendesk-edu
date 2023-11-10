<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<h1>Getting stated</h1>

This documentation should enable you to create your own evaluation instance of openDesk on your Kubernetes cluster.

<!-- TOC -->
  * [Requirements](#requirements)
  * [Customize environment](#customize-environment)
    * [Domain](#domain)
    * [Apps](#apps)
    * [Private OCI registry](#private-oci-registry)
    * [Private Helm registry](#private-helm-registry)
    * [Cluster capabilities](#cluster-capabilities)
      * [Service](#service)
      * [Networking](#networking)
      * [Ingress](#ingress)
      * [Container runtime](#container-runtime)
      * [Volumes](#volumes)
    * [Connectivity](#connectivity)
      * [Mail/SMTP configuration](#mailsmtp-configuration)
      * [TURN configuration](#turn-configuration)
      * [Certificate issuer](#certificate-issuer)
    * [Password seed](#password-seed)
  * [Install](#install)
    * [Install single app](#install-single-app)
    * [Install single release/chart](#install-single-releasechart)
  * [Access deployment](#access-deployment)
  * [Uninstall](#uninstall)
<!-- TOC -->

Thanks for looking into the openDesk Getting started guide. This documents covers essentials configuration steps to
deploy openDesk onto your kubernetes infrastructure.

## Requirements

Detailed system requirements are covered on [requirements](requirements.md) page.

## Customize environment

Before deploying openDesk, you have to configure the deployment to suit your environment.
To keep your deployment up to date, we recommend customizing in `dev`, `test` or `prod` and not in `default` environment
files.

> All configuration options and their default values can be found in files at `helmfile/environments/default/`

For the following guide, we will use `dev` as environment, where variables can be set in
`helmfile/environments/dev/values.yaml`.

### Domain

The deployment is designed to deploy each app under a subdomains. For your convenience, we recommend to create a 
`*.domain.tld` A-Record to your cluster ingress controller, otherwise you need to create an A-Record for each subdomain.

A list of all subdomains can be found in `helmfile/environments/default/global.yaml`.

All subdomains can be customized. For example, _Nextcloud_ can be changed to `files.domain.tld` in `dev` environment:

```yaml
global:
  hosts:
    nextcloud: "files"
```

The domain have to be set either via `dev` environment

```yaml
global:
  domain: "my.open.desk"
istio:
  domain: "istio.my.open.desk"
```

or via environment variable

```shell
export DOMAIN=my.open.desk
export ISTIO_DOMAIN=istio.my.open.desk
```

When you configure each subdomain individually, you can set `global.domain` and `istio.domain` to the same value.

Istio is only used for Open-Xchange Appsuite 8, when you don't want to install it, you can disable Istio:

```yaml
istio:
  enabled: false
oxAppsuite:
  enabled: false
```

### Apps

All available apps and their default value can be found in `helmfile/environments/default/workplace.yaml`.

| Component                   | Name                                | Default | Description                    |
|-----------------------------|-------------------------------------|---------|--------------------------------|
| Certificates                | `certificates.enabled`              | `true`  | TLS certificates               |
| ClamAV (Distributed)        | `clamavDistributed.enabled`         | `false` | Antivirus engine               |
| ClamAV (Simple)             | `clamavSimple.enabled`              | `true`  | Antivirus engine               |
| Collabora                   | `collabora.enabled`                 | `true`  | Weboffice                      |
| CryptPad                    | `cryptpad.enabled`                  | `true`  | Weboffice                      |
| Dovecot                     | `dovecot.enabled`                   | `true`  | Mail backend                   |
| Element                     | `element.enabled`                   | `true`  | Secure communications platform |
| Intercom Service            | `intercom.enabled`                  | `true`  | Cross service data exchange    |
| Jitsi                       | `jitsi.enabled`                     | `true`  | Videoconferencing              |
| Keycloak                    | `keycloak.enabled`                  | `true`  | Identity Provider              |
| MariaDB                     | `mariadb.enabled`                   | `true`  | Database                       |
| Memcached                   | `memcached.enabled`                 | `true`  | Cache Database                 |
| MinIO                       | `minio.enabled`                     | `true`  | Object Storage                 |
| Nextcloud                   | `nextcloud.enabled`                 | `true`  | File share                     |
| OpenProject                 | `openproject.enabled`               | `true`  | Project management             |
| OX Appsuite                 | `oxAppsuite.enabled`                | `true`  | Groupware                      |
| Provisioning                | `oxConnector.enabled`               | `true`  | Backend provisioning           |
| Postfix                     | `postfix.enabled`                   | `true`  | MTA                            |
| PostgreSQL                  | `postgresql.enabled`                | `true`  | Database                       |
| Redis                       | `redis.enabled`                     | `true`  | Cache Database                 |
| Univention Corporate Server | `univentionCorporateServer.enabled` | `true`  | Identity Management & Portal   |
| Univention Management Stack | `univentionManagementStack.enabled` | `false` | Identity Management & Portal   |
| XWiki                       | `xwiki.enabled`                     | `true`  | Knowledgebase                  |

Exemplary, Jitsi can be disabled like:

```yaml
jitsi:
  enabled: false
```

### Private OCI registry

By default, all OCI artifacts are proxied via the project's container registry, which should get replaced soon by the
OCI registries provided by Open CoDE.

You also can set your own registry by:

```yaml
global:
  imageRegistry: "external-registry.souvap-univention.de/sovereign-workplace"
```

or via environments variable:

```shell
export PRIVATE_IMAGE_REGISTRY_URL=external-registry.souvap-univention.de/sovereign-workplace
```

If authentication is required, you can reference imagePullSecrets as following:
```yaml
global:
  imagePullSecrets:
    - "external-registry"
```

### Private Helm registry

Some apps use Chart Museum style helm registries. You can use your own registry by setting this environment variable:

```shell
export PRIVATE_CHART_REPOSITORY_URL=charts.open.desk
```

### Cluster capabilities

#### Service

Some apps, like Jitsi or Dovecot, require HTTP and external TCP connections.
These apps create a Kubernetes service object.
You can configure, whether `NodePort` (for on-premise), `LoadBalancer` (for cloud) or `ClusterIP` (to disable) should be
used:

```yaml
cluster:
  service:
    type: "NodePort"
```

#### Networking

If your cluster has not the default `cluster.local` domain configured, you need to provide the domain via:

```yaml
cluster:
  networking:
    domain: "acme.internal"
```

If your cluster has not the default `10.0.0.0/8` CIDR configured, you need to provide the CIDR via:

```yaml
cluster:
  networking:
    cidr: "127.0.0.0/8"
```

#### Ingress

By default, the `ingressClassName` is empty to choose your default ingress controller, you may want to customize it by
setting:

```yaml
ingress:
  ingressClassName: "cilium"
```

#### Container runtime

Some apps require specific configuration for container runtimes. You can set your container runtime like `cri-o`,
`containerd` or `docker` by:

```yaml
cluster:
  container:
    engine: "containerd"
```

#### Volumes

When your cluster has a `ReadWriteMany` volume provisioner, you can benefit from distributed or scaling of apps. By
default, only `ReadWriteOnce` is enabled. To enable `ReadWriteMany` you can set:

```yaml
cluster:
  persistence:
    readWriteMany: true
```

The **StorageClass** can be set by:

```yaml
persistence:
  storageClassNames:
    RWX: "my-read-write-many-class"
    RWO: "my-read-write-once-class"
```

### Connectivity

#### Mail/SMTP configuration

To use the full potential of the openDesk, you need to set up an SMTP Smarthost/Relay which allows to send emails from
the whole subdomain.

```yaml
smtp:
  host: "mail.open.desk"
  username: "openDesk"
  password: "secret"
```

#### TURN configuration

Some components (Jitsi, Element) use for direct communication a TURN server. You can configure your own TURN server with
these options:

```yaml
turn:
  transport: "udp" # or tcp
  credentials: "secret"
  server:
    host: "turn.open.desk"
    port: "3478"
  tls:
    host: "turns.open.desk"
    port: "5349"
```

#### Certificate issuer

As mentioned in [requirements](requirements.md#certificate-management) you can provide your own valid certificate. A TLS
secret with name `opendesk-certificates-tls` needs to be present in application namespace. For deployment, you can
disable `Certificate` resource creation by:

```yaml
certificates:
  enabled: false
```

If you want to leverage the `cert-manager.io` to handle certificates, like `Let's encrypt`, you need to provide the
configured cluster issuer:

```yaml
certificate:
  issuerRef:
    name: "letsencrypt-prod"
```

Additionally, it is possible to request wildcard certificates by:

```yaml
certificate:
  wildcard: true
```

### Password seed

All secrets are generated from a single master password via Master Password (algorithm). 
To prevent others from using your openDesk instance, we highly recommend setting an individual master password via:

```shell
export MASTER_PASSWORD="openDesk"
```

## Install

After setting your environment specific values in `dev` environment, you can start deployment by:

```shell
helmfile apply -e dev -n <NAMESPACE> [-l <label>] [--suppress-diff]
```

**Arguments:**

- `-e <env>`: Environment name out of `default`, `dev`, `test`, `prod`
- `-n <namespace>`: Kubernetes namespace
- `-l <label>`: Label selector
- `--suppress-diff`: Disable diff printing

### Install single app

You can also install or upgrade only a single app like Collabora, either by label selector:

```shell
helmfile apply -e dev -n <NAMESPACE> -l component=collabora
```

or by switching into the apps' directory (faster):

```shell
cd helmfile/apps/collabora
helmfile apply -e dev -n <NAMESPACE>
```

### Install single release/chart

Instead of iteration through all services, you can also deploy a single release like mariadb by:

```shell
helmfile apply -e dev -n <NAMESPACE> -l name=mariadb
```

## Access deployment

When all apps are successfully deployed and pod status' went to `Running` or `Succeeded`, you can navigate to

```text
https://portal.domain.tld
```

If you change the subdomain of `univentionCorporateServer` or `univentionManagementStack`, you need to replace `portal`
by your specified subdomain.

**Credentials:**

```shell
# Replace with your namespace
NAMESPACE=your-namespace

# Get UCS container, which contains passwords as env var.
CONTAINER=$(kubectl -n ${NAMESPACE} get po -l app.kubernetes.io/name=univention-corporate-container -o jsonpath='{.items[0].metadata.name}')
# $ kubectl -n ${NAMESPACE} get po -l app.kubernetes.io/name=univention-corporate-container
#
# NAME                                              READY   STATUS    RESTARTS   AGE
# univention-corporate-container-8665c6f8b7-nlhc6   1/1     Running   0          10m


# Password of `default.user`
kubectl -n ${NAMESPACE} get po ${CONTAINER} -o=jsonpath='{.spec.containers[0].env[?(@.name=="DEFAULT_ACCOUNT_USER_PASSWORD")].value}'
# 40615..............................e9e2f

# Password of `default.admin`
kubectl -n ${NAMESPACE} get po ${CONTAINER} -o=jsonpath='{.spec.containers[0].env[?(@.name=="DEFAULT_ACCOUNT_ADMIN_PASSWORD")].value}'
# bdbbb..............................04db6
```

Now you can log in with obtained credentials:

| Username        | Password                                   | Description      |
|-----------------|--------------------------------------------|------------------|
| `default.user`  | `40615..............................e9e2f` | Application user |
| `default.admin` | `bdbbb..............................04db6` | Administrator    |

## Uninstall

You can uninstall the deployment by:

```shell
helmfile destroy -n <NAMESPACE>
```

> **Note**
> Not all Jobs, PersistentVolumeClaims or Certificates are deleted; you have to delete them manually

**'Sledgehammer destroy'** - for fast development turn-around times (at your own risk):

```shell
NAMESPACE=your-namespace

# Uninstall all Helm charts
for OPENDESK_RELEASE in $(helm ls -n ${NAMESPACE} -aq); do
  helm uninstall -n ${NAMESPACE} ${OPENDESK_RELEASE};
done

# Delete leftover resources
kubectl delete pvc --all --namespace ${NAMESPACE};
kubectl delete jobs --all --namespace ${NAMESPACE};
```

> **Warning**
> Without specifying or empty `--namespace` flag, cluster-wide components get deleted!
