<!--
SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# Updates and features

While [migrations-manual.md](./migrations-manual.md) provides information about required actions when updating or upgrading openDesk this document provides an overview on new (non-breaking) options made available in the Helmfile deployment.

> [!note]
> We only list newly introduced plain YAML structures here. For documentation of the described features, please refer to the comments in the referenced `.yaml.gotmpl` files.

<!-- TOC -->
* [Updates and features](#updates-and-features)
  * [1.17.0](#1170)
    * [`functional.yaml.gotmpl`](#functionalyamlgotmpl)
      * [Enable the "Send later" (scheduled mail) feature for OX App Suite](#enable-the-send-later-scheduled-mail-feature-for-ox-app-suite)
      * [Configurable "Remember Me" SSO session timeouts](#configurable-remember-me-sso-session-timeouts)
    * [`helmfile-defaults.yaml.gotmpl`](#helmfile-defaultsyamlgotmpl)
      * [Allow override of single application helmfiles](#allow-override-of-single-application-helmfiles)
    * [`migrations.yaml.gotmpl`](#migrationsyamlgotmpl)
      * [Skip single actions of the automated migrations](#skip-single-actions-of-the-automated-migrations)
    * [`secrets.yaml.gotmpl`, `objectstores.yaml.gotmpl`, `database.yaml.gotmpl`](#secretsyamlgotmpl-objectstoresyamlgotmpl-databaseyamlgotmpl)
      * [Provide selected secrets as pre-created Kubernetes Secrets](#provide-selected-secrets-as-pre-created-kubernetes-secrets)
    * [`smtp.yaml.gotmpl`](#smtpyamlgotmpl)
      * [Postfix HELO names](#postfix-helo-names)
    * [`technical.yaml.gotmpl`](#technicalyamlgotmpl)
      * [OX App Suite LDAP caching for contact picker](#ox-app-suite-ldap-caching-for-contact-picker)
      * [Postfix](#postfix)
        * [SPF validation for incoming mail](#spf-validation-for-incoming-mail)
        * [User namespaces for the Postfix pod](#user-namespaces-for-the-postfix-pod)
        * [Client, HELO, sender restrictions and rate limits](#client-helo-sender-restrictions-and-rate-limits)
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

#### Enable the "Send later" (scheduled mail) feature for OX App Suite

The OX App Suite "Send later" feature for scheduling outgoing emails is now enabled by default.

```yaml
functional:
  groupware:
    mail:
      outbound:
        sendLater:
          enabled: true
```

Setting `enabled: false` turns the feature off, resulting in the same behaviour as in openDesk 1.16.x and earlier.

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

### `helmfile-defaults.yaml.gotmpl`

#### Allow override of single application helmfiles

It is now possible to override the helmfile definition with default values for
a single openDesk application from an external repository by referencing
the `helmfile-defaults.yaml.gotmpl` in the application directories.

Example `helmfile.yaml.gotmpl`:

```yaml
---
environments:
  ext-env:
    values:
      ...
---
helmfiles:
  - path: "git::https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk.git@helmfile/apps/collabora/helmfile-defaults.yaml.gotmpl?ref=main"
    values:
      - {{ toYaml .Values | nindent 6 }}
...
```

### `migrations.yaml.gotmpl`

#### Skip single actions of the automated migrations

The automated migrations are now described by a list of actions per stage, see
[Automated migrations overview](./migrations-automated.md#automated-migrations-overview) in
`migrations-automated.md`.

The new file `migrations.yaml.gotmpl` allows to opt out of single actions of these migrations via
`migrations.actionsSkip`, e.g. when a migration is considered too complex or too risky for your
environment.

`actionsSkip` mirrors the `actions` structure of the migration definition: An entry names the stage
(the list it is in), the `id` and the `tag` of the action it skips - the same footprint, just
without its `config`. It has to match the declared action exactly, including its `tag` (or the
absence of one), so that an opt-out can never silently suppress a later, different piece of work
that reuses the same action under another tag. An entry that matches no declared action is logged
as a warning.

A skipped action is logged as a warning and is not recorded as executed, so an action that is
declared to run once stays eligible should you un-skip it later.

Example `migrations.yaml.gotmpl` for skipping the OX Connector restart post deployment:

```yaml
migrations:
  actionsSkip:
    pre: []
    post:
      - id: "ox_connector_restart"
        tag: "v1.17.0"
```

> [!warning]
> The automated migrations bring your deployment in line with the openDesk release you are
> deploying. Skipping an action means the migration it implements is not applied and the affected
> component may stay on the old state, so you take over the responsibility for its outcome - for
> example because you already performed the step manually or because you need to perform it in a
> maintenance window of your own. Only use this option if openDesk support asked you to do so or if
> you are certain about the consequences.

### `secrets.yaml.gotmpl`, `objectstores.yaml.gotmpl`, `database.yaml.gotmpl`

#### Provide selected secrets as pre-created Kubernetes Secrets

Secret-bearing entries now carry a `create`/`name`/`key` structure alongside their `value`, and openDesk
delivers them as real Kubernetes Secrets by default instead of inlining the value into the chart. This applies
across all three files:
- `secrets.*` in `secrets.yaml.gotmpl`
- `objectstores.<store>.secretKey` in `objectstores.yaml.gotmpl`
- `databases.<db>.password` in `database.yaml.gotmpl`

Example:

```yaml
secrets:
  cassandra:
    rootPassword:
      value: {{ ... }}
      create: true
      name: "cassandra-root-password"
      key: "cassandra-password"
```

- `create: true` (default): openDesk provisions that Secret from `value`. The `opendesk-secrets` release is
  deployed automatically whenever at least one secret is `create: true`.
- To bring your own: set `create: false` and pre-create the Secret named `name` with key `key` in the
  namespace beforehand, e.g. `kubectl -n <NAMESPACE> create secret generic cassandra-root-password
  --from-literal=cassandra-password='<your-password>'`.

Per-entry caveats are documented inline, e.g. some secrets need an extra key (MinIO also needs `root-user`,
Collabora `username`), some cannot yet use `create: false` (other components still read the literal value).

### `smtp.yaml.gotmpl`

#### Postfix HELO names

The HELO name announced by the OX App Suite facing Postfix (`postfix-ox`) and by the internal Postfix can now be
overridden. Both default to `~`, which keeps the previous behaviour of letting Postfix derive the name from its
hostname:

```yaml
smtp:
  heloName: ~
  internalHeloName: ~
```

### `technical.yaml.gotmpl`

#### OX App Suite LDAP caching for contact picker

The contact picker in OX App Suite can cache LDAP lookups. The cache lifetime is controlled by an expiry time in seconds:

```yaml
technical:
  oxAppSuite:
    contactPicker:
      cacheExpirySeconds: 0
```

A value of `0` disables caching and is the default. Any positive value keeps LDAP results cached for that many seconds before they are refreshed.

#### Postfix

##### SPF validation for incoming mail

Postfix can now validate the SPF record of incoming mail and reject mail that fails the check:

```yaml
technical:
  postfix:
    checkSpf: false
```

The check is disabled by default, which keeps the previous behaviour. Only enable it if Postfix actually sees the IP
of the originating mail server. If a load balancer or proxy in front of Postfix terminates the connection without
preserving the client IP, every incoming mail is evaluated against the proxy's IP and legitimate mail is rejected. In
such a setup, either configure `technical.postfix.smtpdUpstreamProxyProtocol` so that Postfix learns the real client
IP, or leave `checkSpf` disabled.

##### User namespaces for the Postfix pod

The Postfix pods (`postfix` and `postfix-ox`) can now run in their own user namespace, so that UID 0 inside the
container maps to an unprivileged UID on the host:

```yaml
technical:
  postfix:
    userNamespaces: false
```

The default `false` preserves the current behaviour. Set it to `true` if your cluster supports user namespaces
(Kubernetes >= v1.36 with the feature enabled on the nodes); see the
[Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/). Enabling it on a
cluster without support prevents the Postfix pods from starting.

This complements the hardened container security contexts shipped with this release: the Postfix containers no longer
run privileged, no longer allow privilege escalation, and drop all capabilities except those Postfix requires
(`CHOWN`, `DAC_OVERRIDE`, `FOWNER`, `SETGID`, `SETUID`, `KILL`).

##### Client, HELO, sender restrictions and rate limits

A set of Postfix restrictions can now be toggled to harden the configuration. These only affect `postfix-ox`.
Boolean options default to Postfix's previous behaviour (`false`, i.e. not rejecting), except
`reject_non_fqdn_sender`, `reject_unknown_sender_domain`, `reject_unlisted_sender` which was mistakenly not set
but defaults now to `true`; the list options default to empty:

```yaml
technical:
  postfix:
    restrictions:
      unknownReverseClientHostname: false
      unknownClientHostname: false
      rblClient: []
      rhsblReverseClient: []
      invalidHeloHostname: false
      nonFQDNHeloHostname: false
      rhsblHelo: []
      unknownHeloHostname: false
      nonFQDNSender: true
      rhsblSender: []
      unknownSenderDomain: true
      unlistedSender: true
      nonFQDNRecipient: true
      unlistedRecipient: true
      unknownRecipientDomain: true
      unauthDestination: true
```

Additionally, several client connection limits can now be set for smtp (Port 25) and submission (Port 465/587):

```yaml
technical:
  postfix:
    anvilRateTimeUnit: 60
    smtpdUpstreamProxyProtocol: ~
    smtpLimits:
      clientConnectionCount: 15
      clientConnectionRate: 0
      clientMessageRate: 0
      clientRecipientRate: 0
      clientNewTLSSessionRate: 0
      clientAuthRate: 0
    submissionLimits:
      clientConnectionCount: 15
      clientConnectionRate: 0
      clientMessageRate: 0
      clientRecipientRate: 0
      clientNewTLSSessionRate: 0
      clientAuthRate: 0
```

All `*Rate` limits are counted per time interval, and `anvilRateTimeUnit` defines the length of that interval in
seconds. The default of `60` means the rate limits apply per minute; setting it to `3600`, for example, turns them
into hourly limits. It applies to both `smtpLimits` and `submissionLimits` and has no effect on
`clientConnectionCount`, which limits simultaneous connections rather than a rate.

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
