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
<!-- TOC -->

# tl;dr

openDesk is a Kubernetes-only solution and requires an existing Kubernetes (K8s) cluster.

- K8s cluster >= 1.24, [CNCF Certified Kubernetes distribution](https://www.cncf.io/certification/software-conformance/)
- Domain and DNS Service
- Ingress controller (Ingress NGINX)
- [Helm](https://helm.sh/) >= v3.9.0
- [Helmfile](https://helmfile.readthedocs.io/en/latest/) >= **v1.0.0-rc5**
- [HelmDiff](https://github.com/databus23/helm-diff) >= 3.6.0
- Volume provisioner supporting RWO (read-write-once)
- Certificate handling with [cert-manager](https://cert-manager.io/)

# Hardware

The following minimal requirements are thought for initial evaluation deployment:

| Spec | Value                                                 |
| ---- | ----------------------------------------------------- |
| CPU  | 12 Cores of x64 or x86 CPU (ARM is not supported yet) |
| RAM  | 32 GB, more recommended                               |
| Disk | HDD or SSD, >10 GB                                    |

# Kubernetes

Any self-hosted or managed K8s cluster >= 1.24 listed in
[CNCF Certified Kubernetes distributions](https://www.cncf.io/certification/software-conformance/) should be supported.

The deployment is tested against [kubespray](https://github.com/kubernetes-sigs/kubespray) based clusters.

> **Note:** The deployment is not tested against OpenShift.

# Ingress controller

The deployment is intended to be used only over HTTPS via a configured FQDN, therefore it is required to have a proper
configured ingress controller deployed.

**Supported controllers:**
- [Ingress NGINX Controller](https://github.com/kubernetes/ingress-nginx)

> **Note**<br>
> The platform development team is evaluating the use of [Gateway API](https://gateway-api.sigs.k8s.io/). If you have feedback on that topic, please share it with us.

# Volume provisioner

Initial evaluation deployment requires a `ReadWriteOnce` volume provisioner. For local deployment, a local- or hostPath-
provisioner is sufficient.

> **Note**<br>
> Some components require a `ReadWriteMany` volume provisioner for distributed mode or scaling.

# Certificate management

This deployment leverages [cert-manager](https://cert-manager.io/) to generate valid certificates. This is **optional**,
but a secret containing a valid TLS certificate is required.

Only `Certificate` resources will be deployed; the `cert-manager`, including its CRD must be installed before this or
openDesk certificate management switched off.

# External services

For the development and evaluation of openDesk, we bundle some services. Be aware that for production
deployments, you need to make use of your own production-grade services; see the
[external-services.md](./external-services.md) for configuration details.

| Group    | Type                | Version | Tested against        |
| -------- | ------------------- | ------- | --------------------- |
| Cache    | Memcached           | `1.6.x` | Memcached             |
|          | Redis               | `7.x.x` | Redis                 |
| Database | MariaDB             | `10.x` | MariaDB               |
|          | PostgreSQL          | `15.x` | PostgreSQL            |
| Mail     | Mail Transfer Agent |         | Postfix               |
|          | PKI/CI (S/MIME)     |         |                       |
| Security | AntiVirus/ICAP      |         | ClamAV                |
| Storage  | K8s ReadWriteOnce   |         | Ceph / Cloud specific |
|          | K8s ReadWriteMany   |         | Ceph / NFS            |
|          | Object Storage      |         | MinIO                 |
| Voice    | TURN                |         | Coturn                |

# Deployment

The deployment of each component is [Helm](https://helm.sh/) based. The 35+ Helm charts are configured and
templated via [Helmfile](https://helmfile.readthedocs.io/en/latest/) to provide a streamlined deployment experience.

Helmfile requires [HelmDiff](https://github.com/databus23/helm-diff) to compare the desired against the deployed state.
