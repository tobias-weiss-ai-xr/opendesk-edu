<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<h1>Requirements</h1>

This section covers the internal system requirements and external service requirements for productive use.

<!-- TOC -->
* [tl;dr](#tldr)
* [Hardware](#hardware)
* [Kubernetes](#kubernetes)
* [Ingress controller](#ingress-controller)
* [Volume provisioner](#volume-provisioner)
* [Certificate management](#certificate-management)
* [External services](#external-services)
* [Deployment](#deployment)
* [Footnotes](#footnotes)
<!-- TOC -->

# tl;dr

openDesk is a Kubernetes-only solution and requires an existing Kubernetes (K8s) cluster.

- K8s cluster >= v1.24, [CNCF Certified Kubernetes distribution](https://www.cncf.io/certification/software-conformance/)
- Domain and DNS Service
- Ingress controller (Ingress NGINX) >= [4.11.5/1.11.5](https://github.com/kubernetes/ingress-nginx/releases) - tested with v1.11.1 up to v1.11.5
  - **Important Note**: We are working on support for more recent versions, but please ensure to use at least 1.11.5 due to ["security issues"](https://www.wiz.io/blog/ingress-nginx-kubernetes-vulnerabilities) in earlier versions.
  - Ingress-NGINX introduced new security defaults in version 1.12.0, which are currently not compatible with openDesk. While we are working to adhere to these defaults, you can find additional information below on how to configure Ingress-NGINX >= 1.12.0 to be compatible with openDesk.
- [Helm](https://helm.sh/) >= v3.9.0
- [Helmfile](https://helmfile.readthedocs.io/en/latest/) >= **v1.0.0-rc8**
- [HelmDiff](https://github.com/databus23/helm-diff) >= v3.6.0
- Volume provisioner supporting RWO (read-write-once)
- Certificate handling with [cert-manager](https://cert-manager.io/)
- [OpenKruise](https://openkruise.io/)[^1] >= v1.6

# Hardware

The following minimum requirements are intended for initial evaluation deployment:

| Spec | Value                                                 |
|------|-------------------------------------------------------|
| CPU  | 12 Cores of x64 or x86 CPU (ARM is not supported yet) |
| RAM  | 32 GB, more recommended                               |
| Disk | HDD or SSD, >10 GB                                    |

# Kubernetes

Any self-hosted or managed K8s cluster >= v1.24 listed in
[CNCF Certified Kubernetes distributions](https://www.cncf.io/certification/software-conformance/) should be supported.

The deployment is tested against [kubespray](https://github.com/kubernetes-sigs/kubespray) based clusters.

> **Note**<br>
> The deployment is not tested against OpenShift.

# Ingress controller

The deployment is intended to be used only over HTTPS via a configured FQDN, therefore it is required to have a properly
configured ingress controller deployed in your cluster.

**Supported controllers:**
- [Ingress NGINX Controller](https://github.com/kubernetes/ingress-nginx)

**Compatibility with Ingress NGINX >= 1.12.0**

With the release 1.12.0 Ingress NGINX introduced new security default settings, which are incompatible with current openDesk releases. If you want to use Ingress-NGINX >= 1.12.0 the following settings have to be set
- The annotation risk level has to be set to `critical`. See the [documentation](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#annotations-risk-level) for details.
- Strict path type validation has to be disabled. See the [documentation](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#strict-validate-path-type) for details.

> **Important Note**<br>
> Ensure to install at least Ingress NGINX 1.12.1 due to ["security issues"](https://www.wiz.io/blog/ingress-nginx-kubernetes-vulnerabilities) in 1.12.0.


> **Note**<br>
> The platform development team is evaluating the use of [Gateway API](https://gateway-api.sigs.k8s.io/). If you can provide input on that topic, please get in contact with us.

# Volume provisioner

Initial evaluation deployment requires a `ReadWriteOnce` volume provisioner. For local deployment, a local- or hostPath-
provisioner is sufficient.

> **Note**<br>
> Some components require a `ReadWriteMany` volume provisioner for distributed mode or horizontal scaling.

# Certificate management

This deployment leverages [cert-manager](https://cert-manager.io/) to generate valid certificates. This is **optional**,
but a secret containing a valid TLS certificate is required.

Only `Certificate` resources will be deployed; the `cert-manager`, including its CRD must be installed before this or
openDesk certificate management is switched off.

# External services

For the development and evaluation of openDesk, we bundle some services. Be aware that for production
deployments, you need to make use of your own production-grade services; see the
[external-services.md](./external-services.md) for configuration details.

| Group    | Type                | Version | Tested against        |
|----------|---------------------|---------|-----------------------|
| Cache    | Memcached           | `1.6.x` | Memcached             |
|          | Redis               | `7.x.x` | Redis                 |
| Database | Cassandra[^1]       | `5.0.x` | Cassandra             |
|          | MariaDB             | `10.x`  | MariaDB               |
|          | PostgreSQL          | `15.x`  | PostgreSQL            |
| Mail     | Mail Transfer Agent |         | Postfix               |
|          | PKI/CI (S/MIME)     |         |                       |
| Security | AntiVirus/ICAP      |         | ClamAV                |
| Storage  | K8s ReadWriteOnce   |         | Ceph / Cloud specific |
|          | K8s ReadWriteMany   |         | Ceph / NFS            |
|          | Object Storage      |         | MinIO                 |
| Voice    | TURN                |         | Coturn                |

# Deployment

The deployment of each component is [Helm](https://helm.sh/) based. The 35+ Helm charts are configured and
templated via [Helmfile](https://helmfile.readthedocs.io/en/latest/) to provide a streamlined deployment experience.

Helmfile requires [HelmDiff](https://github.com/databus23/helm-diff) to compare the desired state against the deployed state.

# Footnotes

[^1]: Required for Dovecot Pro as part of openDesk Enterprise Edition.
