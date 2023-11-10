<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->
<h1>Requirements</h1>

This section covers the internal system requirements as well as external service requirements for productive use.

<!-- TOC -->
  * [TL;DR;](#tldr)
  * [Hardware](#hardware)
  * [Kubernetes](#kubernetes)
  * [Ingress controller](#ingress-controller)
  * [Volume provisioner](#volume-provisioner)
  * [Certificate management](#certificate-management)
  * [External services](#external-services)
  * [Deployment](#deployment)
<!-- TOC -->

## TL;DR;
openDesk is a Kubernetes only solution and requires an existing Kubernetes (K8s) cluster.

- K8s cluster >= 1.24, [CNCF Certified Kubernetes Distro](https://www.cncf.io/certification/software-conformance/)
- Domain and DNS Service
- Ingress controller (supported are nginx-ingress, HAProxy)
- [Helm](https://helm.sh/) >= v3.9.0
- [Helmfile](https://helmfile.readthedocs.io/en/latest/) >= **v0.157.0**
- [HelmDiff](https://github.com/databus23/helm-diff) >= 3.6.0
- Volume provisioner supporting RWO (read-write-once)
- Certificate handling with [cert-manager](https://cert-manager.io/)
- [Istio](https://istio.io/) is currently required to deploy and operate OX AppSuite8

## Hardware

The following minimal requirements are thought for initial evaluation deployment:

| Spec | Value                                                |
|------|------------------------------------------------------|
| CPU  | 8 Cores of x64 or x86 CPU (ARM is not supported yet) |
| RAM  | 16 GB, recommended 32 GB                             |
| Disk | HDD or SSD, >10 GB                                   |

## Kubernetes

Any self-hosted or managed K8s cluster >= 1.24 listed in
[CNCF Certified Kubernetes Distros](https://www.cncf.io/certification/software-conformance/) should be supported.

The deployment is tested against [kubespray](https://github.com/kubernetes-sigs/kubespray) based clusters.

> **Note:** The deployment is not tested against OpenShift.

## Ingress controller

The deployment is intended to use only over HTTPS via a configured FQDN, therefor it is required to have a proper
configured ingress controller deployed.

**Maintained controllers:**
- [NGINX Ingress Controller](https://github.com/nginxinc/kubernetes-ingress)
- [HAProxy Kubernetes Ingress Controller](https://github.com/haproxytech/kubernetes-ingress)

**Community Supported:**
- [Ingress NGINX Controller](https://github.com/kubernetes/ingress-nginx)

When you want to use Open-Xchange Appsuite 8, you need to deploy and configure additionally [Istio](https://istio.io/)

## Volume provisioner

Initial evaluation deployment requires a `ReadWriteOnce` volume provisioner. For local deployment a local- or hostPath-
provisioner is sufficient.

> **Note:** Some components requiring a `ReadWriteMany` volume provisioner for distributed mode or scaling.

## Certificate management

This deployment leverages [cert-manager](https://cert-manager.io/) to generate valid certificates. This is **optional**,
but a secret containing a valid TLS certificate is required.

Only `Certificate` resources will be deployed, the `cert-manager` including its CRD must be installed prior to this or
openDesk certificate management disabled.

## External services

Evaluation the openDesk deployment does not require any external service to start, but features may be limited.


| Group    | Type                | Version | Tested against        | 
|----------|---------------------|---------|-----------------------| 
| Cache    | Memached            | `1.6.x` | Memached              | 
|          | Redis               | `7.x.x` | Redis                 | 
| Database | MariaDB             | `10.x`  | MariaDB               | 
|          | PostgreSQL          | `15.x`  | PostgreSQL            |
| Mail     | Mail Transfer Agent |         | Postfix               |
|          | PKI/CI (SMIME)      |         |                       |
| Security | AntiVirus/ICAP      |         | ClamAV                |
| Storage  | K8s ReadWriteOnce   |         | Ceph / Cloud specific |
|          | K8s ReadWriteMany   |         | Ceph / NFS            |
|          | Object Storage      |         | MinIO                 |
| Voice    | TURN                |         | Coturn                |

## Deployment

The deployment of each individual component is [Helm](https://helm.sh/) based. The 35+ Helm charts are configured and
templated via [Helmfile](https://helmfile.readthedocs.io/en/latest/) to provide a streamlined deployment experience.

Helmfile requires [HelmDiff](https://github.com/databus23/helm-diff) to compare desired against deployed state.
