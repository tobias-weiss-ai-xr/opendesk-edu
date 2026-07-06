<!--
SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# Updates and features

While [migrations.md](./migrations.md) provides information about required actions when updating or upgrading openDesk this document provides an overview on new (non-breaking) options made available in the Helmfile deployment.

> [!note]
> We only list newly introduced plain YAML structures here. For documentation of the described features, please refer to the comments in the referenced `.yaml.gotmpl` files.

<!-- TOC -->
* [Updates and features](#updates-and-features)
  * [1.17.0](#1170)
    * [`functional.yaml.gotmpl`](#functionalyamlgotmpl)
      * [Configurable "Remember Me" SSO session timeouts](#configurable-remember-me-sso-session-timeouts)
    * [`technical.yaml.gotmpl`](#technicalyamlgotmpl)
      * [OX App Suite LDAP caching for contact picker](#ox-app-suite-ldap-caching-for-contact-picker)
  * [1.16.0](#1160)
    * [`theme.yaml.gotmpl`](#themeyamlgotmpl)
      * [OpenProject PDF export theming](#openproject-pdf-export-theming)
    * [`technical.yaml.gotmpl`](#technicalyamlgotmpl-1)
      * [Nextcloud worker and memory tuning](#nextcloud-worker-and-memory-tuning)
    * [`service.yaml.gotmpl`](#serviceyamlgotmpl)
      * [Option to set a `loadBalancerIp` for Dovecot and Postfix](#option-to-set-a-loadbalancerip-for-dovecot-and-postfix)
    * [`database.yaml.gotmpl`](#databaseyamlgotmpl)
      * [Option to enable SSL/TLS database connection for OX App Suite](#option-to-enable-ssltls-database-connection-for-ox-app-suite)
    * [`cache.yaml.gotmpl`](#cacheyamlgotmpl)
      * [Options to enable SSL/TLS Redis connection for the Intercom Service, Notes, and OX App Suite](#options-to-enable-ssltls-redis-connection-for-the-intercom-service-notes-and-ox-app-suite)
  * [1.15.0](#1150)
    * [`functional.yaml.gotmpl`](#functionalyamlgotmpl-1)
      * [Per user-quota for external sharing](#per-user-quota-for-external-sharing)
      * [Virtual alias limits](#virtual-alias-limits)
    * [`technical.yaml.gotmpl`](#technicalyamlgotmpl-2)
      * [Proxy protocol support for Postfix](#proxy-protocol-support-for-postfix)
      * [Set limitation on maximum number of objects (for tasks, contacts, attachments)](#set-limitation-on-maximum-number-of-objects-for-tasks-contacts-attachments)
<!-- TOC -->

## 1.17.0

### `functional.yaml.gotmpl`

#### Configurable "Remember Me" SSO session timeouts

Keycloak's "Remember Me" login option can now be toggled, and the idle and maximum lifespan of SSO sessions created with it can be configured:

```yaml
functional:
  authentication:
    realmSettings:
      rememberMe: true
      ssoSessionIdleTimeoutRememberMe: 28800
      ssoSessionMaxLifespanRememberMe: 1209600
```

Set `rememberMe: false` to disable the "Remember Me" option entirely. The two lifespan values only take effect while `rememberMe` is enabled. All lifespan values are defined in seconds.

### `technical.yaml.gotmpl`

#### OX App Suite LDAP caching for contact picker

The contact picker in OX App Suite by default caches the queried LDAP contents for the time (in seconds) defined in

```yaml
technical:
  oxAppSuite:
    contactPicker:
      cacheExpirySeconds: 3600
```

Setting `cacheExpirySeconds: 0` turns the cache off, resulting in the same behaviour as in openDesk 1.16.x and earlier.

## 1.16.0

### `theme.yaml.gotmpl`

#### OpenProject PDF export theming

It is possible to customize the theming for OpenProject's PDF exports now:

```yaml
theme:
  imagery:
    projects:
      pdfExportLogoPath: "./../../files/theme/logoHeader.jpg"
      pdfExportCoverPath: "./../../files/theme/login/background.jpg"
      pdfExportFooterPath: "./../../files/theme/login/favicon.png"
```

> [!warning]
> PDF theming is overwritten on every deployment. Changes made in OpenProject's admin UI are lost and must be set using the above options instead.

### `technical.yaml.gotmpl`

#### Nextcloud worker and memory tuning

The number of worker processes and the PHP memory limits of the Nextcloud components can now be tuned to size the
deployment for the expected load:

```yaml
technical:
  nextcloud:
    aio:
      php:
        memoryLimit: "768M"
        workers: 20
      nginx:
        workers: "auto"
    pushNotify:
      nginx:
        workers: 2
```

Previously, these values were hardcoded and could not be customized from the Helmfile deployment.

Pinning `nginx.workers` to a fixed number is especially relevant on nodes with many CPU cores: the `"auto"`
setting is not cgroup-aware and spawns one worker per host core regardless of the pod's CPU allocation, so setting an
explicit value bounds the number of workers.

### `service.yaml.gotmpl`

#### Option to set a `loadBalancerIp` for Dovecot and Postfix

It is now possible to configure a fixed `loadBalancerIp` for the external services exposed by Dovecot and/or Postfix when the service type is `LoadBalancer`:

```yaml
service:
  loadBalancerIp:
    dovecot: ~
    postfix: ~
```

### `database.yaml.gotmpl`

#### Option to enable SSL/TLS database connection for OX App Suite

SSL/TLS support for the database connection of OX App Suite is now available:

```yaml
databases:
  oxAppSuite:
    useSSL: false
    requireSSL: false
    verifyServerCertificate: false
    enabledTLSProtocols: "TLSv1.2,TLSv1.3"
    nullCatalogMeansCurrent: true
```

Previously no such option was provided.

### `cache.yaml.gotmpl`

#### Options to enable SSL/TLS Redis connection for the Intercom Service, Notes, and OX App Suite

SSL/TLS support for the Redis connection of the Intercom Service, Notes, and OX App Suite are now available:

```yaml
cache:
  intercomService:
    tls: true
  notes:
    tls: true
  oxAppSuite:
    tls: true
```

## 1.15.0

### `functional.yaml.gotmpl`

#### Per user-quota for external sharing

Configure the per-user quota for external share links and guest invitations (when features are enabled):

```yaml
functional:
  groupware:
    externalSharing:
      shareLinks:
        enabled: false
        quota: 100
      inviteGuests:
        enabled: false
        quota: 100
```

Previously, only toggling these features on or off was supported.

#### Virtual alias limits

Postfix applies limits to virtual alias expansion and recursion, these limits can be modified now:

```yaml
functional:
  groupware:
    mail:
      localLimits:
        expansion: 1000
        recursion: 25
```

### `technical.yaml.gotmpl`

#### Proxy protocol support for Postfix

**Target audience:** Deployments using values in `smtp.spamMilter.*` for spam protection.

**Context**

To facilitate spam detection openDesk can integrate Postfix with Rspamd via the Milter protocol using the Helmfile
settings below `smtp.spamMilter.*`.

When choosing this option, Rspamd needs the client IP address of incoming SMTP connections to perform DKIM, rDNS,
and SPF validation.

In Kubernetes environments, applications are typically not exposed directly to the internet but run behind a load
balancer or proxy, so Postfix does not receive the real client IP by default. It sees only the upstream load
balancer IP and passes that to Rspamd. As a result, Rspamd cannot distinguish actual client IPs, and spam detection
checks fail or lose reliability.

To address this, the real client IP must be preserved through the load balancer. A typical approach is to use a TCP
load balancer with proxy protocol enabled.

**Required action**

To enable the proxy protocol it must be configured for both the load balancer and Postfix.

> [!warning]
> In case of a configuration mismatch, Postfix will not function properly.

Make sure to address the following steps to enable Proxy Protocol:

1. Load balancer: To enable the proxy protocol on the load balancer, consult
   your cloud providers documentation on how to configure the load balancer. For
   example, this is the relevant section
  [in the STACKIT Kubernetes Engine documentation](https://docs.stackit.cloud/products/runtime/kubernetes-engine/basics/load-balancing/#tcp-proxy-protocol).
1. openDesk: Set the following Helmfile values and redeploy:

   ```yaml
   technical:
     postfix:
       smtpdUpstreamProxyProtocol: "haproxy"
   ```

#### Set limitation on maximum number of objects (for tasks, contacts, attachments)

Set OX context wide quota limits for tasks, contacts, and attachments:

```yaml
technical:
  oxAppSuite:
    quota:
      tasks: 250000
      contacts: 250000
      attachments: 250000
```

Previously, only the calendar quota could be configured.
