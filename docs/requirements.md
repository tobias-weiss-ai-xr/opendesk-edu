<!--
SPDX-FileCopyrightText: 2024-2025 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

# Requirements

This section covers the internal system requirements and external service requirements for productive use.

<!-- TOC -->
* [Requirements](#requirements)
  * [tl;dr](#tldr)
  * [Hardware](#hardware)
  * [Kubernetes](#kubernetes)
  * [Ingress controller](#ingress-controller)
    * [Supported controllers](#supported-controllers)
      * [haproxy-ingress.github.io](#haproxy-ingressgithubio)
      * [Ingress nginx](#ingress-nginx)
    * [Minimal configuration](#minimal-configuration)
  * [Volume provisioner](#volume-provisioner)
  * [Certificate management](#certificate-management)
  * [External services](#external-services)
  * [Deployment](#deployment)
  * [Footnotes](#footnotes)
<!-- TOC -->

## tl;dr

openDesk is a Kubernetes-only solution and requires an existing Kubernetes (K8s) cluster.

- K8s cluster >= v1.24, [CNCF Certified Kubernetes distribution](https://www.cncf.io/certification/software-conformance/)
- Domain and DNS Service
- Ingress controller
  - [haproxy-ingress.github.io](https://haproxy-ingress.github.io)
  - [Ingress nginx](https://github.com/kubernetes/ingress-nginx/) >= [4.11.5/1.11.5](https://github.com/kubernetes/ingress-nginx/releases) - [now deprecated](https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/)
  - See section [Ingress controller](#ingress-controller) for more details.
- [Helm](https://helm.sh/) >= v3.17.3 but not
  - v3.18.0[^1]
  - v4.x[^2]
- [Helmfile](https://helmfile.readthedocs.io/en/latest/) >= v1.0.0
- [HelmDiff](https://github.com/databus23/helm-diff) >= v3.11.0
- Volume provisioner supporting RWO (read-write-once)
- Certificate handling with [cert-manager](https://cert-manager.io/)

**Additional openDesk Enterprise requirements**
- [OpenKruise](https://openkruise.io/)[^3] >= v1.6

## Hardware

The following minimum requirements are intended for initial evaluation deployment:

| Spec | Value                                                 |
|------|-------------------------------------------------------|
| CPU  | 12 Cores of x64 or x86 CPU (ARM is not supported yet) |
| RAM  | 32 GB, more recommended                               |
| Disk | HDD or SSD, >10 GB                                    |

## Kubernetes

Any self-hosted or managed K8s cluster >= v1.24 listed in
[CNCF Certified Kubernetes distributions](https://www.cncf.io/certification/software-conformance/) should be supported.

The deployment is tested against [kubespray](https://github.com/kubernetes-sigs/kubespray) based clusters.

> [!note]
> The deployment is not tested against OpenShift.

## Ingress controller

The deployment is intended to be used only over HTTPS via a configured FQDN, therefore it is required to have a properly
configured ingress controller deployed in your cluster.

### Supported controllers

- [haproxy-ingress.github.io](https://haproxy-ingress.github.io) - since openDesk 1.13
- [Ingress nginx Controller](https://github.com/kubernetes/ingress-nginx) - [now deprecated](https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/)

> [!note]
> We plan to move to [Gateway API](https://gateway-api.sigs.k8s.io/) ideally by end of 2026. The objective is to achive
> an implementation that is as controller agnostic as possible to give you the choice when it comes to selecting the
> actual implementation for your infrastructure.

#### haproxy-ingress.github.io

Some openDesk components, e.g. the optional UDM REST API (see functional.externalServices.nubus.udmRestApi), can hit some default global limits of the controller. Tweaking the controller deployment as shown below is best practise to avoid running into issues.

```yaml
controller:
  config:
    config-global: |
      tune.bufsize 65536
      tune.http.maxhdr 256
```

#### Ingress nginx

> [!warning]
> [Ingress nginx is no longer maintained](https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/) by
> upstream and its use is therefore

With the release 1.12.0 Ingress nginx introduced new security default settings, which are incompatible with current openDesk releases. If you want to use Ingress-nginx >= 1.12.0 the following settings have to be set:

```
controller.config.annotations-risk-level=Critical
controller.config.strict-validate-path-type=false
```

See the [`annotations-risk-level` documentation](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#annotations-risk-level) and [`strict-validate-path-type` documentation](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#strict-validate-path-type) for details.

> [!warning]
> Ensure to install at least Ingress nginx 1.11.5 or 1.12.1 due to [security
> issues](https://www.wiz.io/blog/ingress-nginx-kubernetes-vulnerabilities) in earlier versions.

### Minimal configuration

Several components in openDesk make use of snippet annotations, which are disabled by default. Please enable them using the following configuration:
```
controller.allowSnippetAnnotations=true
controller.admissionWebhooks.allowSnippetAnnotations=true
```
See the [`allowSnippetAnnotations` documentation](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#allow-snippet-annotations) for context.

## Volume provisioner

Initial evaluation deployments requires a `ReadWriteOnce` volume provisioner.

Some components require a `ReadWriteMany` volume provisioner for distributed mode or horizontal scaling.

> [!warning]
> Due to [restrictions on Kubernetes `emptyDir`](https://github.com/kubernetes/kubernetes/pull/130277) you need a volume provisioner that has sticky bit support, otherwise the OpenProject seeder job will fail. The `local-path-provisioner` does not have sticky bit support.

## Certificate management

This deployment leverages [cert-manager](https://cert-manager.io/) to generate valid certificates. This is **optional**,
but a secret containing a valid TLS certificate is required.

Only `Certificate` resources will be deployed; the `cert-manager`, including its CRD must be installed before this or
openDesk certificate management is switched off.

## External services

For the development and evaluation of openDesk, we bundle some services. Be aware that for production
deployments, you need to make use of your own production-grade services; see the
[external-services.md](./external-services.md) for configuration details.

| Group    | Type                | Version | Tested against        |
|----------|---------------------|---------|-----------------------|
| Cache    | Memcached           | `1.6.x` | Memcached             |
|          | Redis               | `7.x.x` | Redis                 |
| Database | Cassandra[^3]       | `5.0.x` | Cassandra             |
|          | MariaDB             | `10.x`  | MariaDB               |
|          | PostgreSQL          | `15.x`  | PostgreSQL            |
| Mail     | Mail Transfer Agent |         | Postfix               |
|          | PKI/CI (S/MIME)     |         |                       |
| Security | AntiVirus/ICAP      |         | ClamAV                |
| Storage  | K8s ReadWriteOnce   |         | Ceph / Cloud specific |
|          | K8s ReadWriteMany   |         | Ceph / NFS            |
|          | Object Storage      |         | MinIO                 |
| Voice    | TURN                |         | Coturn                |

## Deployment

The deployment of each component is [Helm](https://helm.sh/) based. The 35+ Helm charts are configured and
templated via [Helmfile](https://helmfile.readthedocs.io/en/latest/) to provide a streamlined deployment experience.

Helmfile requires [HelmDiff](https://github.com/databus23/helm-diff) to compare the desired state against the deployed state.

## Footnotes

[^1]: Due to a [Helm bug](https://github.com/helm/helm/issues/30890) Helm v3.18.0 is not supported.

[^2]: Helm v4 introduced stricter flag grouping that is not yet supported by the helmdiff plugin.

[^3]: Required for Dovecot Pro as part of openDesk Enterprise Edition.
