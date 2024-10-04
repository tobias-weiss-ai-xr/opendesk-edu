<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<h1>Getting started</h1>

This documentation lets you create an openDesk evaluation instance on your Kubernetes cluster.

<!-- TOC -->
* [Requirements](#requirements)
* [Customize environment](#customize-environment)
  * [DNS](#dns)
  * [Domain](#domain)
    * [Apps](#apps)
  * [Private registries](#private-registries)
  * [Cluster capabilities](#cluster-capabilities)
    * [Service](#service)
    * [Networking](#networking)
    * [Ingress](#ingress)
    * [Container runtime](#container-runtime)
    * [Volumes](#volumes)
  * [Connectivity](#connectivity)
    * [Ports](#ports)
      * [Web-based user interface](#web-based-user-interface)
      * [Mail clients](#mail-clients)
    * [Mail/SMTP configuration](#mailsmtp-configuration)
    * [TURN configuration](#turn-configuration)
    * [Certificate issuer](#certificate-issuer)
  * [Password seed](#password-seed)
  * [Install](#install)
  * [Install single app](#install-single-app)
  * [Install single release/chart](#install-single-releasechart)
* [Access deployment](#access-deployment)
  * [Using from external repository](#using-from-external-repository)
* [Uninstall](#uninstall)
<!-- TOC -->

Thanks for looking into the openDesk Getting Started guide. This document covers essential configuration steps to
deploy openDesk onto your Kubernetes infrastructure.

# Requirements

Detailed system requirements are covered on the [requirements](requirements.md) page.

# Customize environment

Before deploying openDesk, you must configure the deployment to fit your environment.
To keep your deployment up to date, we recommend customizing in `dev`, `test`, or `prod` and not in `default` environment
files.

> All configuration options and their default values can be found in files at `helmfile/environments/default/`

For the following guide, we will use `dev` as environment where variables can be set in
`helmfile/environments/dev/values.yaml.gotmpl`.

## DNS

The deployment is designed to deploy each application/service under a dedicated subdomain.
For your convenience, we recommend creating a `*.domain.tld` A-Record to your cluster ingress controller; otherwise, you must create an A-Record for each subdomain.

| Record name                   | Type | Value                                              | Additional information                                           |
|-------------------------------|------|----------------------------------------------------|------------------------------------------------------------------|
| *.domain.tld                  | A    | IPv4 address of your Ingress Controller            |                                                                  |
| *.domain.tld                  | AAAA | IPv6 address of your Ingress Controller            |                                                                  |
| mail.domain.tld               | A    | IPv4 address of your postfix NodePort/LoadBalancer | Optional mail should directly be delivered to openDesk's Postfix |
| mail.domain.tld               | AAAA | IPv6 address of your postfix NodePort/LoadBalancer | Optional mail should directly be delivered to openDesk's Postfix |
| domain.tld                    | MX   | `10 mail.domain.tld` |                                                                  |
| domain.tld                    | TXT  | `v=spf1 +a +mx +a:mail.domain.tld ~all` | Optional, use proper MTA record if present                       |
| _dmarc.domain.tld             | TXT  | `v=DMARC1; p=quarantine` | Optional                                                         |
| default._domainkey.domain.tld | TXT  | `v=DKIM1; k=rsa; h=sha256; ...` | Optional DKIM settings                                           |

## Domain

A list of all subdomains can be found in `helmfile/environments/default/global.yaml`.

All subdomains can be customized. For example, _Nextcloud_ can be changed to `files.domain.tld` in `dev` environment:

```yaml
global:
  hosts:
    nextcloud: "files"
```

The domain has to be set either via `dev` environment

```yaml
global:
  domain: "domain.tld"
```

or via environment variable

```shell
export DOMAIN=domain.tld
```

### Apps

All available apps and their default value are in `helmfile/environments/default/workplace.yaml`.

| Component            | Name                        | Default | Description                    |
| -------------------- | --------------------------- | ------- | ------------------------------ |
| Certificates         | `certificates.enabled` | `true` | TLS certificates               |
| ClamAV (Distributed) | `clamavDistributed.enabled` | `false` | Antivirus engine               |
| ClamAV (Simple)      | `clamavSimple.enabled` | `true` | Antivirus engine               |
| Collabora            | `collabora.enabled` | `true` | Weboffice                      |
| CryptPad             | `cryptpad.enabled` | `true` | Weboffice                      |
| Dovecot              | `dovecot.enabled` | `true` | Mail backend                   |
| Element              | `element.enabled` | `true` | Secure communications platform |
| Jitsi                | `jitsi.enabled` | `true` | Videoconferencing              |
| MariaDB              | `mariadb.enabled` | `true` | Database                       |
| Memcached            | `memcached.enabled` | `true` | Cache Database                 |
| MinIO                | `minio.enabled` | `true` | Object Storage                 |
| Nextcloud            | `nextcloud.enabled` | `true` | File share                     |
| Nubus                | `nubus.enabled` | `true` | Identity Management & Portal   |
| OpenProject          | `openproject.enabled` | `true` | Project management             |
| OX Appsuite          | `oxAppsuite.enabled` | `true` | Groupware                      |
| Postfix              | `postfix.enabled` | `true` | MTA                            |
| PostgreSQL           | `postgresql.enabled` | `true` | Database                       |
| Redis                | `redis.enabled` | `true` | Cache Database                 |
| XWiki                | `xwiki.enabled` | `true` | Knowledge management           |

Exemplary, Jitsi can be disabled like:

```yaml
jitsi:
  enabled: false
```

## Private registries

By default, Helm charts and container images are fetched from OCI registries. These registries can be found in most cases
in the [openDesk/component section on Open CoDE](https://gitlab.opencode.de/bmi/opendesk/components).

For untouched upstream artifacts that do not belong to a functional component's core, we use upstream registries
like Docker Hub.

Doing a test deployment will be fine with this setup. In case you want to deploy multiple times a day
and fetch from the same IP address, you might run into rate limits at Docker Hub. In that case and in cases you
prefer the use of a private image registry, you can configure such for
[your target environment](./../helmfile/environments/dev/values.yaml.gotmpl.sample) by setting
- `global.imageRegistry` for a private image registry and
- `global.helmRegistry` for a private Helm chart registry.

```yaml
global:
  imageRegistry: "my_private_registry.domain.tld"
```

alternatively, you can use an environment variable:

```shell
export PRIVATE_IMAGE_REGISTRY_URL=my_private_registry.domain.tld
```

or control repository override fine-granular per registry:

```yaml
repositories:
  image:
    dockerHub: "my_private_registry.domain.tld/docker.io/"
    registryOpencodeDe: "my_private_registry.domain.tld/registry.opencode.de/"
```

If authentication is required, you can reference `imagePullSecrets` as follows:

```yaml
global:
  imagePullSecrets:
    - "external-registry"
```

## Cluster capabilities

### Service

Some apps, like Jitsi or Dovecot, require HTTP and external TCP connections.
These apps create a Kubernetes service object.
You can configure whether `NodePort` (for on-premise), `LoadBalancer` (for cloud), or `ClusterIP` (to disable) should be
used:

```yaml
cluster:
  service:
    type: "NodePort"
```

### Networking

If your cluster has not the default `cluster.local` domain configured, you need to provide the domain via:

```yaml
cluster:
  networking:
    domain: "acme.internal"
```

If your cluster has not the default `10.0.0.0/8` CIDR configured, you need to provide the CIDR via the following:

```yaml
cluster:
  networking:
    cidr:
      - "127.0.0.0/8"
```

If your load balancer / reverse proxy IPs are not already covered by the above `cidr` you need to
explicitly configure the related IPs or IP ranges:

```yaml
cluster:
  networking:
    incomingCIDR:
      - "172.16.0.0/12"
```

### Ingress

By default, the `ingressClassName` is empty to select your default ingress controller. You may want to customize it by
setting the following attribute to the name of the currently only supported ingress controller `ingress-nginx` (see
[requirements.md](./requirements.md)) for reference) within your deployment if that is not the cluster's default ingress.

```yaml
ingress:
  ingressClassName: "name-of-my-nginx-ingress"
```

### Container runtime

Some apps require specific configurations for the container runtime. You can set your container runtime like `cri-o`,
`containerd` or `docker` by:

```yaml
cluster:
  container:
    engine: "containerd"
```

### Volumes

When your cluster has a `ReadWriteMany` volume provisioner, you can benefit from the distribution or scaling of apps. By
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

## Connectivity

### Ports

**Note:** If you use `NodePort` for service exposure, you must check your deployment for the actual ports.

#### Web-based user interface

To use the openDesk functionality with its web-based user interface, you need to expose the following ports publicly:

| Component          | Description             |  Port | Type |
| ------------------ | ----------------------- | ----: | ---: |
| openDesk           | Kubernetes Ingress      |    80 |  TCP |
| openDesk           | Kubernetes Ingress      |   443 |  TCP |
| Jitsi Video Bridge | ICE Port for video data | 10000 |  UDP |

#### Mail clients

To connect with mail clients like [Thunderbird](https://www.thunderbird.net/), the following ports need public exposure:

| Component          | Description             |  Port | Type |
| ------------------ | ----------------------- | ----: | ---: |
| Dovecot            | IMAPS                   |   993 |  TCP |
|                    | POP3S                   |   995 |  TCP |
| Postfix            | SMTP                    |    25 |  TCP |
|                    | SMTPS                   |   587 |  TCP |

### Mail/SMTP configuration

To use the full potential of the openDesk, you need to set up an SMTP relay that allows sending emails from
the whole subdomain.

```yaml
smtp:
  host: "mail.open.desk"
  username: "openDesk"
  password: "secret"
```

Enabling DKIM signing of emails helps to reduce spam and increases trust.
openDesk ships dkimpy-milter as Postfix milter for signing emails.

```yaml
dkimpy:
  enable: true
  dkim:
    key:
      value: "HzZs08QF1O7UiAkcM9T3U7rePPECtSFvWZIvyKqdg8E="
    selector: "default"
    useED25519: true # when false, RSA is used
```

### TURN configuration

Some components (Jitsi, Element) use a TURN server for direct communication. You can configure your own TURN server with
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

### Certificate issuer

As mentioned in [requirements](requirements.md#certificate-management), you can provide your own valid certificate. A TLS
secret named `opendesk-certificates-tls` must be present in the application namespace. For deployment, you can
turn off `Certificate` resource creation by:

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

## Password seed

All secrets are generated from a master password via [Master Password (algorithm)](https://en.wikipedia.org/wiki/Master_Password_(algorithm)).
To prevent others from using your openDesk instance, you must set your individual master password via:

```shell
export MASTER_PASSWORD="your_individual_master_password"
```

## Install

After setting your environment-specific values in `dev` environment, you can start deployment by:

```shell
helmfile apply -e dev -n <NAMESPACE> [-l <label>] [--suppress-diff]
```

**Arguments:**

- `-e <env>`: Environment name out of `default`, `dev`, `test`, `prod`
- `-n <namespace>`: Kubernetes namespace
- `-l <label>`: Label selector
- `--suppress-diff`: Disable diff printing

## Install single app

You can also install or upgrade only a single app like Collabora, either by label selector:

```shell
helmfile apply -e dev -n <NAMESPACE> -l component=collabora
```

or by switching into the apps' directory (faster):

```shell
cd helmfile/apps/collabora
helmfile apply -e dev -n <NAMESPACE>
```

## Install single release/chart

Instead of iteration through all services, you can also deploy a single release like `mariadb` by:

```shell
helmfile apply -e dev -n <NAMESPACE> -l name=mariadb
```

# Access deployment

When all apps are successfully deployed, and their Pod's status is `Running` or `Succeeded`, you can navigate to

```text
https://portal.domain.tld
```

If you change the subdomain of `nubus`, you must replace `portal` with the specified subdomain.

**Credentials:**

openDesk deploys with the standard user account `Administrator`, which password you get retrieved as follows:

```shell
# Replace with your namespace
NAMESPACE=your-namespace

# Get password for IAM "Administrator" account
kubectl -n ${NAMESPACE} secret ums-nubus-credentials -o jsonpath='{.data.administrator_password}' | base64 -d
```

In openDesk Community Edition, you get two more default accounts:
- `default.admin`: `kubectl -n ${NAMESPACE} secret ums-nubus-credentials -o jsonpath='{.data.admin_password}' | base64 -d`
- `default.user`: `kubectl -n ${NAMESPACE} secret ums-nubus-credentials -o jsonpath='{.data.user_password}' | base64 -d`

## Using from external repository

Referring to `./helmfile_generic.yaml` from an external
directory or repository is possible. The `helmfile.yaml` that refers to
`./helmfile_generic.yaml` may define custom environments. These custom
environments may overwrite specific configuration values. These
configuration values are:

* `global.domain`
* `global.helmRegistry`
* `global.master_password`

# Uninstall

You can uninstall the deployment by:

```shell
helmfile destroy -n <NAMESPACE>
```

> **Note**<br>
> Not all Jobs, PersistentVolumeClaims, or Certificates are deleted; you have to delete them manually

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

> **Warning**<br>
> Without specifying or empty `--namespace` flag, cluster-wide components get deleted!
