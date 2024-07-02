<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Self-signed certificate and custom Certificate Authority (CA)</h1>

<!-- TOC -->
* [Use case](#use-case)
* [Configuration](#configuration)
  * [Option 1: Bring Your Own Certificate](#option-1-bring-your-own-certificate)
  * [Option 2: Use cert-manager.io](#option-2-use-cert-managerio)
<!-- TOC -->

# Use case

Deploying openDesk into an environment with custom public key infrastructure (PKI) that is usually not part of
public certificate authority chains or deploying openDesk into a local cluster without ACME challenge.

# Configuration

There are two options to address the use case.

## Option 1: Bring Your Own Certificate

This option is useful, when you have your own PKI in your environment which is trusted by all clients that should
access openDesk.

1. Disable cert-manager.io certificate resource creation:

    ```yaml
    certificates:
      enabled: false
    ```

1. Enable mount of self-signed certificates:

    ```yaml
    certificate:
      selfSigned: true
    ```

1. Create a Kubernetes secret named `opendesk-certificates-tls` of type `kubernetes.io/tls` containing either a valid
wildcard certificate or a certificate with [all required subdomains](../../helmfile/environments/default/global.yaml)
set as SANs (Subject Alternative Name).

1. Create a Kubernetes secret with name `opendesk-certificates-ca-tls` of type `kubernetes.io/tls` containing the custom
CA certificate as X.509 encoded (`ca.crt`) and as jks trust store (`truststore.jks`).

1. Create a Kubernetes secret with name `opendesk-certificates-keystore-jks` with key `password` and as value the jks
trust store password.

## Option 2: Use cert-manager.io

This option is useful, when you do not have a trusted certificate available and can't fetch a certificate from
Let’s Encrypt.

1. Create self-signed cert-manager.io Cluster Issuer:
    ```yaml
    apiVersion: "cert-manager.io/v1"
    kind: "ClusterIssuer"
    metadata:
      name: "selfsigned-issuer"
    spec:
      selfSigned: {}
    ```

1. Enable mount and creation of self-signed certificates:
    ```yaml
    certificate:
      issuerRef:
        name: "selfsigned-issuer"
      selfSigned: true
    ```
