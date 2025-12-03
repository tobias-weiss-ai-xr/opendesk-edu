<!--
SPDX-FileCopyrightText: 2024-2025 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Updates & Upgrades</h1>

<!-- TOC -->
* [Disclaimer](#disclaimer)
* [Deprecation warnings](#deprecation-warnings)
* [Overview and mandatory upgrade path](#overview-and-mandatory-upgrade-path)
* [Manual checks/actions](#manual-checksactions)
  * [Versions ≥ v1.11.0](#versions--v1110)
    * [Pre-upgrade to versions ≥ v1.11.0](#pre-upgrade-to-versions--v1110)
      * [Deployment cleanup: Collabora Controller](#deployment-cleanup-collabora-controller)
      * [Helmfile new option: Annotations for external services (Dovecot, Jitsi JVB, Postfix)](#helmfile-new-option-annotations-for-external-services-dovecot-jitsi-jvb-postfix)
      * [Helmfile new secret: `secrets.nextcloud.statusPassword`](#helmfile-new-secret-secretsnextcloudstatuspassword)
  * [Versions ≥ v1.10.0](#versions--v1100)
    * [Pre-upgrade to versions ≥ v1.10.0](#pre-upgrade-to-versions--v1100)
      * [Helmfile new secret: `secrets.nubus.ldapSearch.postfix`](#helmfile-new-secret-secretsnubusldapsearchpostfix)
      * [Helmfile new secret: `secrets.doveocot.sharedMailboxesMasterPassword`](#helmfile-new-secret-secretsdoveocotsharedmailboxesmasterpassword)
      * [New Helmfile default: Nubus provisioning debug container no longer deployed](#new-helmfile-default-nubus-provisioning-debug-container-no-longer-deployed)
      * [New Helmfile default: Postfix SMTP SASL security options](#new-helmfile-default-postfix-smtp-sasl-security-options)
    * [Post-upgrade to versions ≥ v1.10.0](#post-upgrade-to-versions--v1100)
      * [New application default: Dovecot full-text search index configuration](#new-application-default-dovecot-full-text-search-index-configuration)
  * [Versions ≥ v1.9.0](#versions--v190)
    * [Pre-upgrade to versions ≥ v1.9.0](#pre-upgrade-to-versions--v190)
      * [New application default: Postfix SMTP SASL security option](#new-application-default-postfix-smtp-sasl-security-option)
      * [Helmfile fix: Cassandra passwords read from `databases.*`](#helmfile-fix-cassandra-passwords-read-from-databases)
      * [Helmfile new feature: `functional.groupware.externalClients.*`](#helmfile-new-feature-functionalgroupwareexternalclients)
  * [Versions ≥ v1.8.0](#versions--v180)
    * [Pre-upgrade to versions ≥ v1.8.0](#pre-upgrade-to-versions--v180)
      * [New application default: Default group for two-factor authentication is now "2FA Users"](#new-application-default-default-group-for-two-factor-authentication-is-now-2fa-users)
      * [New database and secrets: Portal now uses OIDC](#new-database-and-secrets-portal-now-uses-oidc)
      * [New application default: XWiki blocks self-registration of user accounts](#new-application-default-xwiki-blocks-self-registration-of-user-accounts)
      * [New application default: Synapse rooms `v12`](#new-application-default-synapse-rooms-v12)
      * [New Helmfile default: Restricting characters for directory and filenames in fileshare module](#new-helmfile-default-restricting-characters-for-directory-and-filenames-in-fileshare-module)
      * [Helmfile new default: New groupware settings changing current behaviour](#helmfile-new-default-new-groupware-settings-changing-current-behaviour)
      * [New application default: Nextcloud apps "Spreed" and "Comments" no longer enabled by default](#new-application-default-nextcloud-apps-spreed-and-comments-no-longer-enabled-by-default)
      * [New application default: Gravatar is switched off for Jitsi and OpenProject](#new-application-default-gravatar-is-switched-off-for-jitsi-and-openproject)
  * [Versions ≥ v1.7.0](#versions--v170)
    * [Pre-upgrade to versions ≥ v1.7.0](#pre-upgrade-to-versions--v170)
      * [Helmfile fix: Ensure enterprise overrides apply when deploying from project root](#helmfile-fix-ensure-enterprise-overrides-apply-when-deploying-from-project-root)
      * [Replace Helm chart: New Notes Helm chart with support for self-signed deployments](#replace-helm-chart-new-notes-helm-chart-with-support-for-self-signed-deployments)
    * [Post-upgrade to versions ≥ v1.7.0](#post-upgrade-to-versions--v170)
      * [Upstream fix: Provisioning of functional mailboxes](#upstream-fix-provisioning-of-functional-mailboxes)
  * [Versions ≥ v1.6.0](#versions--v160)
    * [Pre-upgrade to versions ≥ v1.6.0](#pre-upgrade-to-versions--v160)
      * [Upstream constraint: Nubus' external secrets](#upstream-constraint-nubus-external-secrets)
      * [Helmfile new secret: `secrets.minio.openxchangeUser`](#helmfile-new-secret-secretsminioopenxchangeuser)
      * [Helmfile new object storage: `objectstores.openxchange.*`](#helmfile-new-object-storage-objectstoresopenxchange)
      * [OX App Suite fix-up: Using S3 as storage for non mail attachments (pre-upgrade)](#ox-app-suite-fix-up-using-s3-as-storage-for-non-mail-attachments-pre-upgrade)
    * [Post-upgrade to versions ≥ v1.6.0](#post-upgrade-to-versions--v160)
      * [OX App Suite fix-up: Using S3 as storage for non mail attachments (post-upgrade)](#ox-app-suite-fix-up-using-s3-as-storage-for-non-mail-attachments-post-upgrade)
  * [Versions ≥ v1.4.0](#versions--v140)
    * [Pre-upgrade to versions ≥ v1.4.0](#pre-upgrade-to-versions--v140)
      * [Helmfile cleanup: `global.additionalMailDomains` as list](#helmfile-cleanup-globaladditionalmaildomains-as-list)
  * [Versions ≥ v1.3.0](#versions--v130)
    * [Pre-upgrade to versions ≥ v1.3.0](#pre-upgrade-to-versions--v130)
      * [Helmfile new feature: `functional.authentication.ssoFederation`](#helmfile-new-feature-functionalauthenticationssofederation)
  * [Versions ≥ v1.2.0](#versions--v120)
    * [Pre-upgrade to versions ≥ v1.2.0](#pre-upgrade-to-versions--v120)
      * [Helmfile cleanup: Do not configure OX provisioning when no OX installed](#helmfile-cleanup-do-not-configure-ox-provisioning-when-no-ox-installed)
      * [Helmfile new default: PostgreSQL for XWiki and Nextcloud](#helmfile-new-default-postgresql-for-xwiki-and-nextcloud)
  * [Versions ≥ v1.1.2](#versions--v112)
    * [Pre-upgrade to versions ≥ v1.1.2](#pre-upgrade-to-versions--v112)
      * [Helmfile feature update: App settings wrapped in `apps.` element](#helmfile-feature-update-app-settings-wrapped-in-apps-element)
  * [Versions ≥ v1.1.1](#versions--v111)
    * [Pre-upgrade to versions ≥ v1.1.1](#pre-upgrade-to-versions--v111)
      * [Helmfile feature update: Component specific `storageClassName`](#helmfile-feature-update-component-specific-storageclassname)
      * [Helmfile new secret: `secrets.nubus.masterpassword`](#helmfile-new-secret-secretsnubusmasterpassword)
  * [Versions ≥ v1.1.0](#versions--v110)
    * [Pre-upgrade to versions ≥ v1.1.0](#pre-upgrade-to-versions--v110)
      * [Helmfile cleanup: Restructured `/helmfile/files/theme` folder](#helmfile-cleanup-restructured-helmfilefilestheme-folder)
      * [Helmfile cleanup: Consistent use of `*.yaml.gotmpl`](#helmfile-cleanup-consistent-use-of-yamlgotmpl)
      * [Helmfile cleanup: Prefixing certain app directories with `opendesk-`](#helmfile-cleanup-prefixing-certain-app-directories-with-opendesk-)
      * [Helmfile cleanup: Splitting external services and openDesk services](#helmfile-cleanup-splitting-external-services-and-opendesk-services)
      * [Helmfile cleanup: Streamlining `openxchange` and `oxAppSuite` attribute names](#helmfile-cleanup-streamlining-openxchange-and-oxappsuite-attribute-names)
      * [Helmfile feature update: Dicts to define `customization.release`](#helmfile-feature-update-dicts-to-define-customizationrelease)
      * [openDesk defaults (new): Enforce login](#opendesk-defaults-new-enforce-login)
      * [openDesk defaults (changed): Jitsi room history enabled](#opendesk-defaults-changed-jitsi-room-history-enabled)
      * [External requirements: Redis 7.4](#external-requirements-redis-74)
    * [Post-upgrade to versions ≥ v1.1.0](#post-upgrade-to-versions--v110)
      * [XWiki fix-ups](#xwiki-fix-ups)
  * [Versions ≥ v1.0.0](#versions--v100)
    * [Pre-upgrade to versions ≥ v1.0.0](#pre-upgrade-to-versions--v100)
      * [Configuration Cleanup: Removal of unnecessary OX-Profiles in Nubus](#configuration-cleanup-removal-of-unnecessary-ox-profiles-in-nubus)
      * [Configuration Cleanup: Updated `global.imagePullSecrets`](#configuration-cleanup-updated-globalimagepullsecrets)
      * [Changed openDesk defaults: Matrix presence status disabled](#changed-opendesk-defaults-matrix-presence-status-disabled)
      * [Changed openDesk defaults: Matrix ID](#changed-opendesk-defaults-matrix-id)
      * [Changed openDesk defaults: File-share configurability](#changed-opendesk-defaults-file-share-configurability)
      * [Changed openDesk defaults: Updated default subdomains in `global.hosts`](#changed-opendesk-defaults-updated-default-subdomains-in-globalhosts)
      * [Changed openDesk defaults: Dedicated group for access to the UDM REST API](#changed-opendesk-defaults-dedicated-group-for-access-to-the-udm-rest-api)
    * [Post-upgrade to versions ≥ v1.0.0](#post-upgrade-to-versions--v100)
      * [Configuration Improvement: Separate user permission for using Video Conference component](#configuration-improvement-separate-user-permission-for-using-video-conference-component)
      * [Optional Cleanup](#optional-cleanup)
* [Automated migrations - Details](#automated-migrations---details)
  * [Versions ≥ v1.6.0 (automated)](#versions--v160-automated)
    * [Versions ≥ v1.6.0 migrations-post](#versions--v160-migrations-post)
  * [Versions ≥ v1.2.0 (automated)](#versions--v120-automated)
    * [Versions ≥ v1.2.0 migrations-pre](#versions--v120-migrations-pre)
    * [Versions ≥ v1.2.0 migrations-post](#versions--v120-migrations-post)
  * [Versions ≥ v1.1.0 (automated)](#versions--v110-automated)
  * [Versions ≥ v1.0.0 (automated)](#versions--v100-automated)
  * [Related components and artifacts](#related-components-and-artifacts)
  * [Development](#development)
<!-- TOC -->

# Disclaimer

Starting with openDesk 1.0, we aim to offer hassle-free updates/upgrades.

Therefore, openDesk contains automated migrations between versions which reduces the need for manual interaction.

These automated migrations have limitations in the sense that they require a certain openDesk version to be installed, effectively resulting in a forced upgrade path. This is highlighted in the section [Automated migrations](#automated-migrations).

Manual checks and possible activities are also required by openDesk updates, they are described in the section [Manual update steps](#manual-update-steps).

> [!important]
> Please be sure to _thoroughly_ read / follow the requirements before you update / upgrade and assure that
> you are reading the correct version of this document (change branch / version if necessary).

> [!warning]
> We assume that the PV reclaim policy is set to `delete`, resulting in PVs getting deleted as soon as the related PVC is deleted; we will not address explicit deletion for PVs.


# Deprecation warnings

We cannot hold back all migrations as some are required e.g. due to a change in a specific component that we want/need to update, we try to bundle others only with major releases.

This section provides an overview of potential changes to be part of the next major release (openDesk 2.0).

- `functional.portal.link*` (see `functional.yaml.gotmpl` for details) are going to be moved into the `theme.*` tree, we are also going to move the icons used for the links currently found under `theme.imagery.portalEntries` in this step.
- We will explicitly set the [database schema configuration](https://www.xwiki.org/xwiki/bin/view/Documentation/AdminGuide/Configuration/#HConfigurethenamesofdatabaseschemas) for XWiki to avoid the use of the `public` schema.
- Adding support for `storageClassName` templating of various components requiring upgrading of the existing PVCs:
  - `persistence.storages.oxConnector.storageClassName`
  - `persistence.storages.nubusUdmListener.storageClassName`
  - `persistence.storages.nubusProvisioningNats.storageClassName`

# Overview and mandatory upgrade path

The following table gives an overview of the mandatory upgrade path of openDesk, required in order for the automated migrations to work as expected.

To upgrade existing deployments, you _cannot_ skip any version denoted with `yes` in the column
*Mandatory*. This ensures [automated migrations](#automated-migrations---details) have the required previous
state of openDesk. When a version number is not fully defined (e.g. `v1.1.x`), you can install any version
matching that constraint, though our links always point to the newest patch release for that minor version.

> [!warning]
> You must perform **all** manual pre and post upgrade steps for **any** major, minor and patch version up to your desired openDesk version!

> [!note]
> An exemplary update path for an upgrade from v1.3.2 to v1.7.1 would be:
> 1. You are at v1.3.2 → pre steps for v1.4.0 to v1.5.0
> 1. Upgrade to v1.5.0 → post steps for v1.4.0 to v1.5.0
> 1. You are at v1.5.0 → pre steps for v1.6.0 to 1.7.1
> 1. Upgrade to v1.7.1 → post steps for v1.6.0 to v1.7.1

<!-- IMPORTANT: Make sure to mark mandatory releases if an automatic migration requires a previous update to be installed -->
| Version                                                                                  | Mandatory | Pre-Upgrade                                                                                                                    | Post-Upgrade                             | Minimum Required Previous Version                    |
| ---------------------------------------------------------------------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------- | ---------------------------------------------------- |
| [v1.10.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.9.0) | --        | [Pre](#pre-upgrade-to-versions--v1100)                                                                                         | [Post](#post-upgrade-to-versions--v1100) | ⬇ Install ≥ v1.5.0 first                            |
| [v1.9.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.9.0)  | --        | [Pre](#pre-upgrade-to-versions--v190)                                                                                          | --                                       | ⬇ Install ≥ v1.5.0 first                            |
| [v1.8.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.8.0)  | --        | [Pre](#pre-upgrade-to-versions--v180)                                                                                          | --                                       | ⬇ Install ≥ v1.5.0 first                            |
| [v1.7.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.7.1)  | --        | [Pre](#pre-upgrade-to-versions--v170)                                                                                          | [Post](#post-upgrade-to-versions--v170)  | ⬇ Install ≥ v1.5.0 first                            |
| [v1.6.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.6.0)  | --        | [Pre](#pre-upgrade-to-versions--v160)                                                                                          | [Post](#post-upgrade-to-versions--v160)  | [⚠ Install v1.5.0 first](#versions--v160-automated) |
| [v1.5.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.5.0)  | **yes**   | --                                                                                                                             | --                                       | ⬇ Install ≥ v1.1.x first                            |
| [v1.4.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.4.1)  | --        | [Pre](#pre-upgrade-to-versions--v140)                                                                                          | --                                       | ⬇ Install ≥ v1.1.x first                            |
| [v1.3.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.3.2)  | --        | [Pre](#pre-upgrade-to-versions--v130)                                                                                          | --                                       | ⬇ Install ≥ v1.1.x first                            |
| [v1.2.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.2.1)  | --        | [Pre](#pre-upgrade-to-versions--v120)                                                                                          | --                                       | [⚠ Install v1.1.x first](#versions--v120-automated) |
| [v1.1.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.1.2)  | **yes**   | [Pre .0](#pre-upgrade-to-versions--v110) → [Pre .1](#pre-upgrade-to-versions--v111) → [Pre .2](#pre-upgrade-to-versions--v112) | [Post](#post-upgrade-to-versions--v110)  | [⚠ Install v1.0.0 first](#versions--v110-automated) |
| [v1.0.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.0.0)  | **yes**   | [Pre](#pre-upgrade-to-versions--v100)                                                                                          | [Post](#post-upgrade-to-versions--v100)  | [⚠ Install v0.9.0 first](#versions--v100-automated) |
| [v0.9.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v0.9.0)  | **yes**   | --                                                                                                                             | --                                       | --                                                   |

> [!warning]
> Be sure to check out the table in the release version you are going to install, and not the currently installed version.

If you would like more details about the automated migrations, please read section [Automated migrations - Details](#automated-migrations---details).

# Manual checks/actions

> [!note]
> We **only** use the mathematical symbol ≥ to denote for which versions manual steps must be
> applied. For example, "Versions ≥ v1.7.0" refers to all openDesk versions (major, minor and
> patch) starting from 1.7.0, e.g. 1.7.0, 1.7.1, 1.8.0, etc. Furthermore, if a version is not explicitly
> listed no extra manual steps are required when upgrading to that version, e.g. in the case of an update from
> version 1.7.0 to version 1.7.1.

## Versions ≥ v1.11.0

### Pre-upgrade to versions ≥ v1.11.0

#### Deployment cleanup: Collabora Controller

**Target group:** Existing openDesk Enterprise deployments using Collabora Controller. Actually, only long-running
deployments are affected, but following the instructions won't hurt.

As per upstream release notes for [Collabora Online Controller 1.1.7](https://www.collaboraonline.com/cool-controller-release-notes/)
you have to remove the existing leases of the Controller. You can do so by setting `<your_namespace>` and executing
the commands below.

```shell
export NAMESPACE=<your_namespace>
export COLLABORA_CONTROLLER_DEPLOYMENT_NAME=collabora-controller-cool-controller
kubectl -n ${NAMESPACE} scale deployment/${COLLABORA_CONTROLLER_DEPLOYMENT_NAME} --replicas=0
kubectl -n ${NAMESPACE} delete -n collabora leases.coordination.k8s.io collabora-online
```

> [!note]
> The Collabora Online Controller is not scaled up again, as this would happen as part of the upgrade deployment.

#### Helmfile new option: Annotations for external services (Dovecot, Jitsi JVB, Postfix)

**Target group:** Existing deployments using `service` annotations for Dovecot, Jitsi JVB or Postfix.

The three non-HTTP external services support now explicit annotations.
See [`annotations.yaml.gomtpl`](../helmfile/environments/default/annotations.yaml.gotmpl) for reference.

**Jitsi JVB**

The already existing annotation key `annotations.jitsiJVB.service` has been renamed to
`annotations.jitsiJVB.serviceExternal` be in line with the newly added ones for Postfix and Dovecot.
If you make use of the JVB service annotation please rename the attribute to the new `serviceExternal` standard.

**Dovecot**

Setting service annotation by `annotations.openxchangeDovecot.service` applied the annotations to the internal
and external service. This key now only sets annotations for the internal service. If you want to set
annotations for the external service use the newly introduced key `annotations.openxchangeDovecot.serviceExternal`.

**Postfix**

Setting service annotation by `annotations.openxchangePostfix.service` applied the annotations to the internal
and external service. This key now only sets annotations for the internal service. If you want to set
annotations for the external service use the newly introduced key `annotations.openxchangePostfix.serviceExternal`.

#### Helmfile new secret: `secrets.nextcloud.statusPassword`

**Target group:** All existing deployments that use self-defined secrets and have deployed Nextcloud.

Access to Nextcloud's `/status.php` requires now BasicAuth. The related password is set in
[`secrets.yaml.gotmpl`](../helmfile/environments/default/secrets.yaml.gotmpl) by the key
`secrets.nextcloud.statusPassword`.

If you define your own secrets, please ensure that you provide a value for this secret, otherwise it will
be derived from the `MASTER_PASSWORD`.

> [!note]
> The username for the BasicAuth is hardcoded to "status-access".

## Versions ≥ v1.10.0

### Pre-upgrade to versions ≥ v1.10.0

#### Helmfile new secret: `secrets.nubus.ldapSearch.postfix`

**Target group:** All existing deployments that use self-defined secrets.

The updated Postfix configuration supporting LDAP group based mailing list requires a new secret that is
declared in [`secrets.yaml.gotmpl`](../helmfile/environments/default/secrets.yaml.gotmpl) by the key
`secrets.nubus.ldapSearch.postfix`.

If you define your own secrets, please ensure that you provide a value for this secret, otherwise it will
be derived from the `MASTER_PASSWORD`.

#### Helmfile new secret: `secrets.doveocot.sharedMailboxesMasterPassword`

**Target group:** All existing deployments that have OX App Suite enabled and that use self-defined secrets.

The revised Dovecot configuration requires a new secret that is declared in
[`secrets.yaml.gotmpl`](../helmfile/environments/default/secrets.yaml.gotmpl) by the key
`secrets.doveocot.sharedMailboxesMasterPassword`.

If you define your own secrets, please ensure that you provide a value for this secret, otherwise it will
be derived from the `MASTER_PASSWORD`.

#### New Helmfile default: Nubus provisioning debug container no longer deployed

**Target group:** All deployments that make use of the debugging container for Nubus' provisioning stack called "nats-box",

The [nats-box](https://github.com/nats-io/nats-box), a handy tool when it comes to debugging the Nubus provisioning stack, is no longer enabled in openDesk by default.

To re-enable the nats-box for your deployment you have to set:
```yaml
technical:
  nubus:
    provisioning:
      nats:
        natsBox:
          enabled: true
```

> [!note]
> The nats-box also gets enabled when setting `debug.enabled: true`, but that should only be used in non-production scenarios and enabled debug
> accross the whole deployment.

#### New Helmfile default: Postfix SMTP SASL security options

**Target group:** All openDesk deployments using an external SMTP relay that does not support
[Postfix's default `smtpSASLSecurityOptions`](https://www.postfix.org/postconf.5.html#smtp_sasl_security_options).

Starting from openDesk v1.9.0, the SMTP SASL security options set within openDesk are aligned with the
recommended defaults. This might break currently working connections with external SMTP relays.

> [!warning]
> Please check your mail relays supported SASL security options and adjust your deployment accordingly to
> prevent the disruption of mail delivery.

To fall back to the behavior of openDesk < v1.9.0 (no security options at all) set the following in
`smtp.yaml.gotmpl`

``` yaml
smtp:
  security:
    smtpdSASLSecurityOptions: ~
    smtpSASLSecurityOptions: ~
```

To set specific options consult the official Postfix documentation for
[smtpd](https://www.postfix.org/postconf.5.html#smtpd_sasl_security_options) or
[smtp](https://www.postfix.org/postconf.5.html#smtp_sasl_security_options) and set the string options via the
yaml array notation:

``` yaml
smtp:
  security:
    smtpdSASLSecurityOptions:
      - "noanonymous"
    smtpSASLSecurityOptions:
      - "noanonymous"
      - "noplaintext"
```

### Post-upgrade to versions ≥ v1.10.0

#### New application default: Dovecot full-text search index configuration

**Target group:** All openDesk Enterprise deployments using the groupware module.

Due to a configurational change the full-text search indexes of Dovecot Pro need to be rebuilt.

Run the following command inside the Dovecot container:

```shell
set -x; for d in /var/lib/dovecot/*/*; do uuid=$(basename "$d"); [[ $uuid =~ ^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$ ]] || continue; doveadm fts rescan -u "$uuid"; doveadm index -u "$uuid" -q '*'; done
```

## Versions ≥ v1.9.0

### Pre-upgrade to versions ≥ v1.9.0

#### New application default: Postfix SMTP SASL security option

**Target group:** All openDesk deployments using an external SMTP relay that does not support
[Postfix's default `smtpSASLSecurityOptions`](https://www.postfix.org/postconf.5.html#smtp_sasl_security_options).

Starting from openDesk v1.9.0, the SMTP SASL security options set within openDesk are aligned with the
recommended defaults. This might break currently working connections with external SMTP relays. To prevent
this you have to configure the supported options for your mail relay one of the following ways:

- Recommended: Directly upgrade to v1.10.0 and set SMTP SASL options through `smtp.security.*`.
- Configure a customization for `smtpSASLSecurityOptions`.

#### Helmfile fix: Cassandra passwords read from `databases.*`

**Target group:** All of the below must apply to your deployment:
1. Enterprise Edition
2. Using external Cassandra DB
3. Defined the Cassandra passwords in `databases.*` (`database.yaml.gotmpl`) which got ignored until now
4. Defined the Cassandra passwords then in `secrets.*` (`secrets.yaml.gotmpl`)

The Cassandra passwords
- `databases.dovecotDictmap.password`
- `databases.dovecotACL.password`

are no longer ignored. So please move the passwords from
- `secrets.cassandra.dovecotDictmapUser`
- `secrets.cassandra.dovecotACLUser`

to the `databases.*` structure.

#### Helmfile new feature: `functional.groupware.externalClients.*`

**Target group:**
Deployments that allow access to groupware emails via external mail clients (e.g. Thunderbird) using IMAP and SMTP.

OX App Suite can display a dialog with configuration details for connecting external mail clients. In previous versions,
this dialog was automatically enabled when Dovecot was deployed with a service type of `NodePort` or `LoadBalancer`.

From now on, the dialog can be explicitly controlled via the setting
`functional.groupware.externalClients.enabledOnboardingInfo`, which is set to `false` by default.
If you want your users to see this dialog, set the attribute to `true`.

Additionally, it is now possible to explicitly define the hostnames shown in the client onboarding dialog using the following values:
- `functional.groupware.externalClients.fqdnImap`
- `functional.groupware.externalClients.fqdnSmtp`

If these values are not explicitly set, openDesk will use `.Values.global.domain` as in previous releases.

## Versions ≥ v1.8.0

### Pre-upgrade to versions ≥ v1.8.0

#### New application default: Default group for two-factor authentication is now "2FA Users"

**Target group:** All upgrade deployments.

In previous openDesk versions, the default group for enforcing two-factor authentication (2FA) was `2fa-users`. Accounts in this group were required to set up and use time-based one-time passwords (TOTP) for 2FA during login.

With the release v1.8.0 of openDesk, the openDesk IAM Nubus introduces a new default group named `2FA Users` serving the same purpose. Existing deployments will retain the old group, which will continue to enforce 2FA as before.

However, for consistency and easier maintenance, we recommend migrating users from the old group to the new one and removing the old group afterward.

#### New database and secrets: Portal now uses OIDC

**Target group:** All upgrade deployments.

The portal has been migrated to use OIDC for single sign-on by default. This introduces the following requirements for existing deployments:

- New database: Deployments using external databases must provide a new PostgreSQL database. See `databases.umsAuthSession` in `databases.yaml.gotmpl` for configuration details.
- New secrets: Deployments managing secrets manually must add:
  - `secrets.keycloak.clientSecret.portal`: The OIDC client secret for the portal.
  - `secrets.postgresql.umsAuthSessionUser`: For internal databases, set the secret for the database user here. If you are using an external database, you already provide these credentials in the New database step above.

> [!note]
> The SAML Client for the Nubus portal is still preserved in Keycloak and is going to be removed with openDesk 1.10.0.

#### New application default: XWiki blocks self-registration of user accounts

**Target group:** All openDesk deployments using XWiki.

The upgrade itself requires no manual intervention. However, the previous default (self-registration enabled) may be unexpected in many deployments.

XWiki supports self-registration for creating local, application-specific accounts. Before this upgrade, the feature was enabled by default. It can not be disabled at the deployment level due to limitations in the XWiki package.

With the new default, self-registration is switched off for new deployments. Existing deployments must apply the change manually:

1. Log in with an XWiki admin account.
2. Open the URL below (replace `<YOURDOMAIN>` with your domain), or navigate manually:
   - URL: `https://wiki.<YOURDOMAIN>/bin/admin/XWiki/XWikiPreferences?editor=globaladmin&section=Rights#|t=usersandgroupstable&p=1&l=10&uorg=users&wiki=local&clsname=XWiki.XWikiGlobalRights`
   - Manual navigation: Burger menu → *Administer Wiki* (repeat for each subwiki, if applicable) → *Users & Groups* → *Rights* → *Users* (table header)
3. In the first row labeled "Unregistered Users", ensure the box in the "Register" column shows a ❌ (disabled) by clicking it if necessary.

#### New application default: Synapse rooms `v12`

**Target group:** All deployments using Element/Synapse with unrestricted federation and public, federation-enabled rooms.

Following the [security bulletin from matrix.org](https://matrix.org/blog/2025/08/security-release/), openDesk now sets the default room version for new Matrix rooms to v12.

This change does not affect existing rooms. There is no immediate action required. However, if your setup allows unrestricted Matrix federation and you operate public, federation-enabled rooms, you should consider upgrading those rooms to v12 for improved security and compatibility.

For instructions on upgrading rooms, refer to the [official upstream documentation](https://docs.element.io/latest/element-server-suite-pro/administration/upgrading-local-rooms/).

OpenDesk includes several bundled widgets. When upgrading a room, a new room is created to replace the old one — widget data will not be automatically transferred to the new room.

To preserve as much data as possible, dedicated upgrade guidelines for each of these widgets are available:

- Matrix NeoBoard widget: https://github.com/nordeck/matrix-neoboard?tab=readme-ov-file#matrix-room-upgrades
- Matrix Meetings widget: https://github.com/nordeck/matrix-meetings?tab=readme-ov-file#matrix-room-upgrades
- Matrix Poll widget: https://github.com/nordeck/matrix-poll?tab=readme-ov-file#matrix-room-upgrades

> [!note]
> These instructions apply to any room upgrades, not just upgrade to `v12`.

#### New Helmfile default: Restricting characters for directory and filenames in fileshare module

**Target group:** All openDesk deployments using the fileshare module, as they may already contain files or directories with characters that are now restricted.

openDesk now enforces restrictions on the characters allowed in directory and filenames by explicitly disallowing the following set: `* " | ? ; : \ / ~ < >`

The reason is that desktop clients can not handle all characters due to restrictions in the underlying operating system and therefor syncing these directories and/or files will fail.

This change was introduced because desktop clients cannot reliably handle certain characters due to operating system limitations, causing file synchronization to fail when these characters are present.

For existing deployments, any files or directories containing restricted characters must be renamed before updates within the file or (sub)directory can succeed.

Nextcloud provides tooling for renaming affected files using an [`occ command`](https://docs.nextcloud.com/server/latest/admin_manual/occ_command.html#sanitize-filenames) that can be executed by the operator, the command also supports a dry-run mode.

You can customize the default restriction settings in `functional.yaml.gotmpl`:

```yaml
functional:
  filestore:
    naming:
      forbiddenChars:
        - '*'
        - '"'
        - '|'
        - '?'
        - ';'
        - ':'
        - '\'
        - '/'
        - '~'
        - '<'
        - '>'
```

#### Helmfile new default: New groupware settings changing current behaviour

**Target group:** All openDesk deployments using OX App Suite

The following options, newly introduced in `functional.yaml.gotmpl`, modify the previous default behavior of openDesk. Please review whether the new defaults are appropriate for your deployment:

* `functional.groupware.mail.inbound.forward.enabled: false`
  This setting prevents users from forwarding all incoming emails to external accounts.
  Instead, the new option `functional.groupware.mail.inbound.notify.enabled: true` enables notifications to user-defined email addresses when new messages arrive.
  To keep the previous behavior, set `forward` to `true` and `notify` to `false`.

* `functional.groupware.userProfile.editRealName: false`
  This setting prevents users from editing their display name in OX App Suite (e.g. the name shown when sending emails, in addition to the sender address).
  The display name is centrally managed by the openDesk IAM.
  To allow users to change it within OX App Suite, set this option to `true`.

> [!note]
> openDesk v1.8.0 adds even more options under `functional.groupware.*` while retaining the current default behaviour.

#### New application default: Nextcloud apps "Spreed" and "Comments" no longer enabled by default

**Target group:** All openDesk deployments using the fileshare module.

The following Nextcloud apps/functions are no longer enabled by default. Please check if they are required in your deployment, i.e. are used by the user:

* [Spreed](https://apps.nextcloud.com/apps/spreed): Used in openDesk to provide a chat tab to the file/directory details pane in the fileshare application.
* Comments: Core app that lets users leave comments in the activity tab of the file/directory details pane.

If required the apps can be enabled using the openDesk customization options for `opendeskNextcloudManagement`, see `customizations.yaml.gotmpl` for details, with the following settings:
```yaml
configuration:
  feature:
    comments:
      enabled: true
    apps:
      spreed:
        enabled: true
```

#### New application default: Gravatar is switched off for Jitsi and OpenProject

**Target group:** All openDesk deployments using the video conference and project module that explicitly want Gravatar support.

Gravatar support is no longer enabled by default in Jitsi and OpenProject. In case it is required openDesk's customization options can be used to enabled it, see `customizations.yaml.gotmpl` for details.

- Jitsi: `customization.release.jitsi` with
  ```yaml
  jitsi:
    web:
      extraConfig:
        disableThirdPartyRequests: false
  ```
- Open Project: `customization.release.openproject` with
  ```yaml
  environment:
    OPENPROJECT_PLUGIN__OPENPROJECT__AVATARS: '{enable_gravatars: true, enable_local_avatars: true}'
  ```

## Versions ≥ v1.7.0

### Pre-upgrade to versions ≥ v1.7.0

#### Helmfile fix: Ensure enterprise overrides apply when deploying from project root

**Target group:** All openDesk Enterprise deployments initiated from the project root using `helmfile_generic.yaml.gotmpl`

Previously, the default values referenced in `helmfile_generic.yaml.gotmpl` did not include the necessary Enterprise overrides from `helmfile/environment/default-ee-overrides/`.

As a result, when deploying openDesk Enterprise Edition from the project root, the correct Enterprise charts and images for Collabora, Nextcloud, OpenXchange, and Dovecot were not applied. This issue does not affect deployments started at the component level (e.g., `helmfile/apps/collabora`).

Please verify that your deployment uses the correct Enterprise charts and images. If not, migrate to the Enterprise versions before upgrading to openDesk EE v1.7.0.

#### Replace Helm chart: New Notes Helm chart with support for self-signed deployments

**Target group:** All deployments that set `app.notes.enabled: true` (default is `false`).

We replaced the Helm Chart used for the Notes (aka "Impress") deployment. If you have enabled Notes in your deployment, you must manually uninstall the old chart before upgrading to openDesk v1.7.0.

```shell
helm uninstall -n <your_namespace> impress
```

In case you are using `annotation.notes` they have to be moved into one of the remaining dicts, see [`annotations.yaml.gotmpl`](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/develop/helmfile/environments/default/annotations.yaml.gotmpl) for details:

```yaml
annotation:
  notesBackend: {}
  notesFrontend: {}
  notesYProvider: {}
```

### Post-upgrade to versions ≥ v1.7.0

#### Upstream fix: Provisioning of functional mailboxes

**Target group:** Deployments with OX App Suite that make use of IAM maintained functional mailboxes.

The update of OX Connector included in openDesk 1.7.0 fixes an issue with the provisioning of IAM maintained functional mailboxes. If your deployment makes use of these mailboxes it is recommended to trigger a full sync of the OX App Suite provisioning by recreating the OX Connector's provisioning subscription using calls to the provisioning API that is temporary port-forwarded in the example below:

```shell
export NAMESPACE=<your_namespace>
export SUBSCRIPTION_NAME=ox-connector
export SUBSCRIPTION_SECRET_NAME=ums-provisioning-ox-credentials
export TEMPORARY_CONSUMER_JSON=$(mktemp)
export PROVISIONING_API_POD_NAME=$(kubectl -n ${NAMESPACE} get pods --no-headers -o custom-columns=":metadata.name" | grep ums-provisioning-api | tr -d '\n')
kubectl -n ${NAMESPACE} port-forward ${PROVISIONING_API_POD_NAME} 7777:7777 &
export PROVISIONING_PORT_FORWARD_PID=$!
sleep 10
kubectl -n ${NAMESPACE} get secret ${SUBSCRIPTION_SECRET_NAME} -o json | jq '.data | map_values(@base64d)' | jq -r '."ox-connector.json"' > ${TEMPORARY_CONSUMER_JSON}.json
export PROVISIONING_ADMIN_PASSWORD=$(kubectl -n ${NAMESPACE} get secret ums-provisioning-api-admin -o jsonpath='{.data.password}' | base64 --decode)
# Delete the current subscription
curl -o - -u "admin:${PROVISIONING_ADMIN_PASSWORD}" -X DELETE http://localhost:7777/v1/subscriptions/${SUBSCRIPTION_NAME}
# Recreate the subscription
curl -u "admin:${PROVISIONING_ADMIN_PASSWORD}" -H 'Content-Type: application/json' -d @${TEMPORARY_CONSUMER_JSON}.json http://localhost:7777/v1/subscriptions
kill ${PROVISIONING_PORT_FORWARD_PID}
rm ${TEMPORARY_CONSUMER_JSON}
```

## Versions ≥ v1.6.0

### Pre-upgrade to versions ≥ v1.6.0

#### Upstream constraint: Nubus' external secrets

**Target group:** Operators that use external secrets for Nubus.

> [!note]
> External secrets are not yet a supported feature. We are working on making it available in 2025,
> though it is possible to make use of the support for external secrets within single applications using the
> openDesk [customization](../helmfile/environments/default/customization.yaml.gotmpl) options.

Please ensure you read the [Nubus 1.10.0 "Migration steps" section](https://docs.software-univention.de/nubus-kubernetes-release-notes/1.x/en/changelog.html#v1-10-0-migration-steps) with focus on the paragraph "Operators that make use of the following UDM Listener secrets variables" and act accordingly.

#### Helmfile new secret: `secrets.minio.openxchangeUser`

**Target group:** All existing deployments that have OX App Suite enabled and that use externally defined secrets in combination with openDesk provided MinIO object storage.

For OX App Suite to access the object storage a new secret has been introduced.

It is declared in [`secrets.yaml.gotmpl`](../helmfile/environments/default/secrets.yaml.gotmpl) by the key: `secrets.minio.openxchangeUser`. If you define your own secrets, please ensure that you provide a value for this secret as well, otherwise it will be derived from the `MASTER_PASSWORD`.

#### Helmfile new object storage: `objectstores.openxchange.*`

**Target group:** All deployments that use an external object storage.

For OX App Suite's newly introduced filestore you have to configure a new object storage (bucket). When you are using
an external object storage you did this already for all the entries in
[`objectstores.yaml.gotmpl`](../helmfile/environments/default/objectstores.yaml.gotmpl). Where we now introduced
`objectstores.openxchange` section that you also need to provide you external configuration for.

#### OX App Suite fix-up: Using S3 as storage for non mail attachments (pre-upgrade)

**Target group:** All existing deployments that have OX App Suite enabled.

With openDesk 1.6.0 OX App Suite persists the attachments on contact, calendar or task objects in object storage.

To enable the use of this new filestore backend existing deployments must execute the following steps.

Preparation:
- Ensure your `kubeconfig` is pointing to the cluster that is running your deployment.
- Identify/create a e.g. local temporary directory that can keep the attachments while upgrading openDesk.
- Set some environment variables to prepare running the documented commands:

```shell
export ATTACHMENT_TEMP_DIR=<your_temporary_directory_for_the_attachments>
export NAMESPACE=<your_namespace>
```

1. Copy the existing attachments from all `open-xchange-core-mw-default-*` Pods to the identified directory, example for `open-xchange-core-mw-default-0`:
```shell
kubectl cp -n ${NAMESPACE} open-xchange-core-mw-default-0:/opt/open-xchange/ox-filestore ${ATTACHMENT_TEMP_DIR}
```
2. Run the upgrade.
3. Continue with the [related post-upgrade steps](#ox-app-suite-fix-up-using-s3-as-storage-for-non-mail-attachments-post-upgrade)

### Post-upgrade to versions ≥ v1.6.0

#### OX App Suite fix-up: Using S3 as storage for non mail attachments (post-upgrade)

**Target group:** All existing deployments having OX App Suite enabled.

Continued from the [related pre-upgrade section](#ox-app-suite-fix-up-using-s3-as-storage-for-non-mail-attachments-pre-upgrade).

1. Copy the attachments back from your temporary directory into `open-xchange-core-mw-default-0`.
```shell
kubectl cp -n ${NAMESPACE} ${ATTACHMENT_TEMP_DIR}/* open-xchange-core-mw-default-0:/opt/open-xchange/ox-filestore
```
2. Ideally you verify the files have been copied as expected checking the target directory in the `open-xchange-core-mw-default-0` Pod. All the following commands are for execution within the aforementioned Pod.
3. Get the `id` of the new object storage based OX filestore, using the following command in the first line of the following block. In the shown example output the `id` for the new filestore would be `10` as the filestore can be identified by its path value `s3://ox-filestore-s3`, the `id` of the existing filestore would be `3` identified by the corresponding path `/opt/open-xchange/ox-filestore`:
```shell
/opt/open-xchange/sbin/listfilestore -A $MASTER_ADMIN_USER -P $MASTER_ADMIN_PW
id path                             size reserved used max-entities cur-entities
 3 /opt/open-xchange/ox-filestore 100000      200    5         5000            1
10 s3://ox-filestore-s3           100000        0    0         5000            0
```
4. Get the list of your OX contexts IDs (`cid` column in the output of the `listcontext` command), as the next step needs to be executed per OX context. Most installation will just have a single OX context (`1`).
```shell
/opt/open-xchange/sbin/listcontext -A $MASTER_ADMIN_USER -P $MASTER_ADMIN_PW
cid fid fname       enabled qmax qused name lmappings
  1   3 1_ctx_store true             5 1    1,context1
```
5. For each of your OX contexts IDs run the final filestore migration command and you will get output like this: `context 1 to filestore 10 scheduled as job 1`:
```shell
/opt/open-xchange/sbin/movecontextfilestore -A $MASTER_ADMIN_USER -P $MASTER_ADMIN_PW -f <your_s3_filestore_id_from_step_3> -c <your_context_id_from_step_4>
```
6. Depending on the size of your filestore, moving the contexts will take some time. You can check the status of a context's jobs with the command below. When the job status is `Done` you can also doublecheck that everything worked as expected by running the `listfilestore` command from step #3 and should see that the filestore is no longer used.
```shell
/opt/open-xchange/sbin/jobcontrol -A $MASTER_ADMIN_USER -P $MASTER_ADMIN_PW -c <your_context_id_from_step_4> -l
ID    Type of Job                              Status     Further Information
1     movefilestore                            Done       move context 1 to filestore 10
```
7. Finally you can unregister the old filestore:
```shell
/opt/open-xchange/sbin/unregisterfilestore -A $MASTER_ADMIN_USER -P $MASTER_ADMIN_PW -i <your_old_filestore_id_from_step_3>
```

## Versions ≥ v1.4.0

### Pre-upgrade to versions ≥ v1.4.0

#### Helmfile cleanup: `global.additionalMailDomains` as list

**Target group:** Installations that have set `global.additionalMailDomains`.

The `additionalMailDomains` had to be defined as a comma separated string. That now needs to change into a list of domains.

For example the following config:

```yaml
global:
  additionalMailDomains: "sub1.maildomain.de,sub2.maildomain.de"
```

Needs to change to:

```yaml
global:
  additionalMailDomains:
    - "sub1.maildomain.de"
    - "sub2.maildomain.de"
```

## Versions ≥ v1.3.0

### Pre-upgrade to versions ≥ v1.3.0

#### Helmfile new feature: `functional.authentication.ssoFederation`

**Target group:** Deployments that make use of IdP federation as described in [`idp-federation.md`](./enhanced-configuration/idp-federation.md).

Please ensure to configure your IdP federation config details as part of `functional.authentication.ssoFederation`. You can find more details in the "Example configuration" section of [`idp-federation.md`](./enhanced-configuration/idp-federation.md).

## Versions ≥ v1.2.0

### Pre-upgrade to versions ≥ v1.2.0

#### Helmfile cleanup: Do not configure OX provisioning when no OX installed

**Target group:** Installations that have no OX App Suite installed.

With openDesk 1.2.0 the OX provisioning consumer will not be registered when there is no OX installed.

We do not remove the consumer for existing installations, if you want to do that for your existing installation please perform the following steps:

```shell
export NAMESPACE=<your_namespace>
kubectl -n ${NAMESPACE} exec -it ums-provisioning-nats-0 -c nats-box -- sh -c 'nats consumer rm stream:ox-connector durable_name:ox-connector --user=admin --password=${NATS_PASSWORD} --force'
kubectl -n ${NAMESPACE} exec -it ums-provisioning-nats-0 -c nats-box -- sh -c 'nats stream rm stream:ox-connector --user=admin --password=${NATS_PASSWORD} --force'
kubectl -n ${NAMESPACE} delete secret ums-provisioning-ox-credentials-test
```

#### Helmfile new default: PostgreSQL for XWiki and Nextcloud

**Target group:** All upgrade installations that do not already use the previous optional PostgreSQL database backend for Nextcloud and XWiki.

openDesk now uses PostgreSQL as default database backend for Nextcloud and XWiki.

When upgrading existing instances you likely want to keep the current database backend (MariaDB).

**Use case A:** You use your own external database services, if not see "Use case B" further down.

You just have to add the new `type` attribute and set it to `mariadb`:

```yaml
databases:
  nextcloud:
    type: "mariadb"
  xwiki:
    type: "mariadb"
```

**Use case B:** You use the openDesk supplied database services.

Ensure you set the following attributes before upgrading, this includes the aforementioned `type` attribute.

```yaml
databases:
  nextcloud:
    type: "mariadb"
    host: "mariadb"
    port: 3306
  xwiki:
    type: "mariadb"
    host: "mariadb"
    port: 3306
    username: "root"
```

In case you are planning to migrate an existing instance from MariaDB to PostgreSQL please check the upstream documentation for details:

- Nextcloud database migration: https://docs.nextcloud.com/server/latest/admin_manual/configuration_database/db_conversion.html
- XWiki:
  - https://www.xwiki.org/xwiki/bin/view/Documentation/AdminGuide/Backup#HUsingtheXWikiExportfeature
  - https://www.xwiki.org/xwiki/bin/view/Documentation/AdminGuide/ImportExport

## Versions ≥ v1.1.2

### Pre-upgrade to versions ≥ v1.1.2

#### Helmfile feature update: App settings wrapped in `apps.` element

We now require [Helmfile v1.0.0-rc.8](https://github.com/helmfile/helmfile/releases/tag/v1.0.0-rc.8) for the deployment. This enables openDesk to lay the foundation for some significant cleanups where the information from the different apps, especially their `enabled` state, is needed.

Therefore, it was necessary to introduce the `apps` level in [`opendesk_main.yaml.gotmpl`](../helmfile/environments/default/opendesk_main.yaml.gotmpl).

If you have a deployment where you specify settings found in the aforementioned file, specifically to disable or enable components, please ensure you insert the top-level attribute `apps` as shown in the following example.

The following configuration:

```yaml
certificates:
  enabled: false
notes:
  enabled: true
```

Needs to be changed to:

```yaml
apps:
  certificates:
    enabled: false
  notes:
    enabled: true
```

## Versions ≥ v1.1.1

### Pre-upgrade to versions ≥ v1.1.1

#### Helmfile feature update: Component specific `storageClassName`

With openDesk 1.1.1 we support component specific `storageClassName` definitions beside the global ones. For this, we had to adapt the structure found in `persistence.yaml.gotmpl` to achieve this in a clean manner.

If you have set custom `persistence.size.*`-values for your deployment, please continue reading as you need to adapt your `persistence` settings to the new structure.

When comparing the [old v1.1.0 structure](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/v1.1.0/helmfile/environments/default/persistence.yaml.gotmpl) with the [new one](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/v1.1.1/helmfile/environments/default/persistence.yaml.gotmpl), you will spot these changes:

- We replaced `persistence.size` with `persistence.storages`.
- Below each component you can define now the `size` and the optional component specific `storageClassName`.
- We streamlined the structure of the components by placing them on the same level, as beforehand, Nubus had an additional level of nesting.

The following configuration:

```yaml
persistence:
  size:
    synapse: "1Gi"
```

Needs to be changed to:

```yaml
persistence:
  storages:
    synapse:
      size: "1Gi"
```

Or for the Nubus related entries, the following:

```yaml
persistence:
  size:
    nubus:
      ldapServerData: "1Gi"
```

Needs to be changed to:

```yaml
persistence:
  storages:
    nubusLdapServerData:
      size: "1Gi"
```

#### Helmfile new secret: `secrets.nubus.masterpassword`

A not yet templated secret was discovered in the Nubus deployment. It is now declared in [`secrets.yaml.gotmpl`](../helmfile/environments/default/secrets.yaml.gotmpl) and can be defined using: `secrets.nubus.masterpassword`. If you define your own secrets, please be sure this new secret is set to the same value as the `MASTER_PASSWORD` environment variable used in your deployment.

## Versions ≥ v1.1.0

### Pre-upgrade to versions ≥ v1.1.0

#### Helmfile cleanup: Restructured `/helmfile/files/theme` folder

If you make use of the [theme folder](../helmfile/files/theme/) or the [`theme.yaml.gotmpl`](../helmfile/environments/default/theme.yaml.gotmpl), e.g. to apply your own imagery, please ensure you adhere to the new structure of the folder and the yaml-file.

#### Helmfile cleanup: Consistent use of `*.yaml.gotmpl`

In v1.0.0 the files in [`/helmfile/environments/default`](../helmfile/environments/default/) had mixed file extensions.
Now we have streamlined this and consistently use the `*.yaml.gotmpl` file extension.

This change likely requires manual action in two situations:

1. You are referencing our upstream files from the aforementioned directory, e.g. in your Argo CD deployment. If so, please update your references to use the filenames with the new extension.
2. You have custom files containing configuration information that are simply named `*.yaml`. If so, please rename them to `*.yaml.gotmpl`.

#### Helmfile cleanup: Prefixing certain app directories with `opendesk-`

To make it more obvious that some elements from within the [`apps`](../helmfile/apps/) directory are solely
provided by openDesk, we have prefixed these app directories with `opendesk-`.

Affected are the following directories, here listed directly with the new prefix:

- [`./helmfile/apps/opendesk-migrations-pre`](../helmfile/apps/opendesk-migrations-pre)
- [`./helmfile/apps/opendesk-migrations-post`](../helmfile/apps/opendesk-migrations-post)
- [`./helmfile/apps/opendesk-openproject-bootstrap`](../helmfile/apps/opendesk-openproject-bootstrap)

The described changes most likely require manual action in the following situation:

- You are referencing our upstream files e.g. in your Argo CD deployment. If so, please update your references to use the new directory names.

#### Helmfile cleanup: Splitting external services and openDesk services

In v1.0.0 there was a directory `/helmfile/apps/services` that was intended to contain all the services an operator had to provide externally for production deployments.

As some services that are actually part of openDesk snuck in there, we had to split the directory into two separate ones:

- [`./helmfile/apps/opendesk-services`](../helmfile/apps/opendesk-services)
- [`./helmfile/apps/services-external`](../helmfile/apps/services-external)

The described changes most likely require manual action in the following situation:

- You are referencing our upstream files e.g. in your Argo CD deployment. If so, please update your references to use the new directory names.

#### Helmfile cleanup: Streamlining `openxchange` and `oxAppSuite` attribute names

We have updated some attribute names within the Open-Xchange / OX App Suite to be consistent within our Helmfile
deployment. This change also aligns us with the actual brand names, as well as our rule of thumb for brand based
attribute names[^1].

In case you are using any of the customizations below, the (`WAS`) values, please update to the (`NOW`) values:

```
WAS: oxAppsuite: ...
NOW: oxAppSuite: ...
```

```
WAS: cache.oxAppsuite: ...
NOW: cache.oxAppSuite: ...
```

```
WAS: charts.openXchangeAppSuite: ...
NOW: charts.oxAppSuite: ...
```

```
WAS: charts.openXchangeAppSuiteBootstrap: ...
NOW: charts.oxAppSuiteBootstrap: ...
```

```
WAS: customization.release.openXchange: ...
NOW: customization.release.openxchange: ...
```

```
WAS: customization.release.opendeskOpenXchangeBootstrap: ...
NOW: customization.release.opendeskOpenxchangeBootstrap: ...
```

```
WAS: databases.oxAppsuite: ...
NOW: databases.oxAppSuite: ...
```

```
WAS: ingress.parameters.openXchangeAppSuite: ...
NOW: ingress.parameters.oxAppSuite: ...
```

```
WAS: ingress.bodyTimeout.openXchangeAppSuite: ...
NOW: ingress.bodyTimeout.oxAppSuite: ...
```

```
WAS: migration.oxAppsuite: ...
NOW: migration.oxAppSuite: ...
```

```
WAS: secrets.oxAppsuite: ...
NOW: secrets.oxAppSuite: ...
```

#### Helmfile feature update: Dicts to define `customization.release`

If you make use of the `customization.release` option, you have to switch to a dictionary based definition of customization files, for example:

The following:

```yaml
customization:
  release:
    collaboraOnline: "./my_custom_templating.yaml.gotmpl"
```

Needs to be changed to:

```yaml
customization:
  release:
    collaboraOnline:
      file1: "./my_custom_templating.yaml.gotmpl"
```

You can freely choose the `file1` dictionary key used in the example above, but it should start with a letter.

#### openDesk defaults (new): Enforce login

Users accessing the openDesk portal are now automatically redirected to the login screen per default.

In case you want to keep the previous behavior you need to set the following `functional` flag:

```yaml
functional:
  portal:
    enforceLogin: false
```

#### openDesk defaults (changed): Jitsi room history enabled

The default to store the Jitsi room history in the local storage of a user's browser has changed.

It is now enabled and therefore stored by default.

To preserve the v1.0.0 behavior of not storing the room history you have to explicitly configure it:

```yaml
functional:
  dataProtection:
    jitsiRoomHistory:
      enabled: false
```

#### External requirements: Redis 7.4

The update from openDesk v1.0.0 contains Redis 7.4.1, like the other openDesk bundled services, the bundled Redis is not meant to be used in production.

Please ensure the Redis you are using is updated to at least version 7.4 to support the requirement of OX App Suite.

### Post-upgrade to versions ≥ v1.1.0

#### XWiki fix-ups

Unfortunately XWiki does not upgrade itself as expected. The bug has been reported and the supplier is aware. The following additional steps are required:

1. To enforce re-indexing of the now fixed full-text search, access the XWiki Pod and run the following commands to delete two search related directories:
   ```
   rm -rf /usr/local/xwiki/data/store/solr/search_9
   rm -rf /usr/local/xwiki/data/cache/solr/search_9
   ```
> The pod will need to be restarted for the changes to take effect.

2. This is necessary if the openDesk single sign-on no longer works, and you get a standard XWiki login dialogue instead:
   - Find the XWiki ConfigMap `xwiki-init-scripts` and locate in the `entrypoint` key the lines beginning with `xwiki_replace_or_add "/usr/local/xwiki/data/xwiki.cfg"`
   - Before those lines, add the following line while setting `<YOUR_TEMPORARY_SUPERADMIN_PASSWORD>` to a value you are happy with:
     ```
         xwiki_replace_or_add "/usr/local/xwiki/data/xwiki.cfg" 'xwiki.superadminpassword' '<YOUR_TEMPORARY_SUPERADMIN_PASSWORD>'
     ```
   - Restart the XWiki Pod.
   - Access XWiki's web UI and login with `superadmin` and the password you set above.
   - Once XWiki UI is fully rendered, remove the line with the temporary `superadmin` password from the aforementioned ConfigMap.
   - Restart the XWiki Pod.

You should have now a fully functional XWiki instance with single sign-on and full-text search.

## Versions ≥ v1.0.0

### Pre-upgrade to versions ≥ v1.0.0

#### Configuration Cleanup: Removal of unnecessary OX-Profiles in Nubus

> [!warning]
> The upgrade will fail if you do not address this section in your current deployment.

The update will remove unnecessary OX-Profiles in Nubus, so long as these profiles are in use.

So please ensure that only the following two supported profiles are assigned to your users:
- `opendesk_standard`: "opendesk Standard"
- `none`: "Login disabled"

You can review and update other accounts as follows:
- Login as IAM admin.
- Open the user module.
- Open the extended search by clicking the funnel (DE: "Trichter") icon next to the search input field.
- Open the "Property" (DE: "Eigenschaft") list and select "OX Access" (DE: "OX-Berechtigung").
- Enter an asterisk (*) in the input field next to the list.
- Start the search by clicking once more on the funnel icon.
- Sort the result list for the "OX Access" column.
- Edit every user that has a value different to `opendesk_standard` or `none`:
  - Open the user.
  - Go to section "OX App Suite".
  - Change the value in the dropdown "OX Access" to either:
    - "openDesk Standard" if the user should be able to use the Groupware module.
    - "Login disabled" if the user should not use the Groupware module.
  - Update the user account with the green "SAVE" button at the top of the page.

#### Configuration Cleanup: Updated `global.imagePullSecrets`

Without using a custom container image registry, you can pull all the openDesk images without authentication.
Thus defining non-existent imagePullSecrets creates unnecessary errors, so we removed them.

You can keep the current settings by setting the `external-registry` in your custom environment values:

```yaml
global:
  imagePullSecrets:
    - "external-registry"
```

#### Changed openDesk defaults: Matrix presence status disabled

Show other user's Matrix presence status is now disabled by default to comply with data protection requirements.

To enable it or keep the v0.9.0 default, please set:

```yaml
functional:
  dataProtection:
    matrixPresence:
      enabled: true
```

#### Changed openDesk defaults: Matrix ID

Until v0.9.0 openDesk used the LDAP entryUUID of a user to generate the user's Matrix ID. Due to restrictions of the
Matrix protocol, an update to a Matrix ID is not possible. Therefore, it was technically convenient to use the UUID
as they are immutable (see https://en.wikipedia.org/wiki/Universally_unique_identifier for more details on UUIDs.)

From the user experience perspective, that was a flawed approach, so from openDesk 1.0 onwards, by default, the openDesk login username is used to define the `localpart` of the Matrix ID.

For existing installations: The changed setting only affects users who log in to Element for the first time. Existing
user accounts will not be harmed. If you want existing users to get new Matrix IDs based on the new setting, you
must update their external ID in Synapse and deactivate the old user afterward. The user will get a completely new
Matrix account, losing their existing contacts, chats, and rooms.

The following Admin API calls are helpful:
- `GET /_synapse/admin/v2/users/@<entryuuid>:<matrixdomain>` get the user's existing external_id (auth_provider: "oidc")
- `PUT /_synapse/admin/v2/users/@<entryuuid>:<matrixdomain>` update user's external_id with JSON payload:
  `{ "external_ids": [ { "auth_provider": "oidc", "external_id": "<old_id>+deprecated" } ] }`
- `POST /_synapse/admin/v1/deactivate/@<entryuuid>:<matrixdomain>` deactivate old user with JSON payload:
  `{ "erase": true }`

For more details, check the Admin API documentation:
https://element-hq.github.io/synapse/latest/usage/administration/admin_api/index.html

You can enforce the old standard with the following setting:
```yaml
functional:
 chat:
   matrix:
     profile:
       useImmutableIdentifierForLocalpart: true
```

#### Changed openDesk defaults: File-share configurability

We now provide some configurability regarding the sharing capabilities of the Nextcloud component.

See the settings under `functional.filestore` in [functional.yaml](../helmfile/environments/default/functional.yaml).

For the following settings, the default in openDesk 1.0 has changed, so you might want to update
the settings for your deployment to keep its current behavior:

```yaml
functional:
 filestore:
   sharing:
     external:
       enabled: true
       expiry:
         activeByDefault: false
```

#### Changed openDesk defaults: Updated default subdomains in `global.hosts`

We have streamlined the subdomain names in openDesk to be more user-friendly and to avoid the use of specific
product names.

This results in the following changes to the default subdomain naming:

- **collabora**: `collabora` → `office`
- **cryptpad**: `cryptpad` → `pad`
- **minioApi**: `minio` → `objectstore`
- **minioConsole**: `minio-console` → `objectstore-ui`
- **nextcloud**: `fs` → `files`
- **openproject**: `project` → `projects`

Existing deployments should keep the old subdomains because URL/link changes are not supported through all components.

If you have not already defined the entire `global.hosts` dictionary in your custom environments values, please set it
to the defaults that were used before the upgrade:

```yaml
global:
  hosts:
    collabora: "collabora"
    cryptpad: "cryptpad"
    element: "chat"
    intercomService: "ics"
    jitsi: "meet"
    keycloak: "id"
    matrixNeoBoardWidget: "matrix-neoboard-widget"
    matrixNeoChoiceWidget: "matrix-neochoice-widget"
    matrixNeoDateFixBot: "matrix-neodatefix-bot"
    matrixNeoDateFixWidget: "matrix-neodatefix-widget"
    minioApi: "minio"
    minioConsole: "minio-console"
    nextcloud: "fs"
    openproject: "project"
    openxchange: "webmail"
    synapse: "matrix"
    synapseFederation: "matrix-federation"
    univentionManagementStack: "portal"
    whiteboard: "whiteboard"
    xwiki: "wiki"
```

In case you would like to update an existing deployment to use the new hostnames, you would be doing so at your own risk, so please consider the following:

- Some of your user's bookmarks and links will stop working.
- Portal links will get updated automatically.
- The update of the OpenProject <-> Nextcloud file integration needs to be updated manually as follows:
  - Use an account with functional admin permissions for both Nextcloud and OpenProject
  - In Nextcloud: *Administration* > *Files* > *External file storages* > Select `Nextcloud at [your_domain]`
    - Edit *Details* - *General Information* - *Storage provider* and update the *hostname* to `files.<your_domain>`
  - In OpenProject: *Administration* > *OpenProject* > *OpenProject server*
    - Update the *OpenProject host* to `projects.<your_domain>`

#### Changed openDesk defaults: Dedicated group for access to the UDM REST API

Prerequisite: You allow the use of the [IAM's API](https://docs.software-univention.de/developer-reference/5.0/en/udm/rest-api.html)
with the following setting:

```yaml
functional:
  externalServices:
    nubus:
      udmRestApi:
        enabled: true
```

With v0.9.0, all members of the group "Domain Admins" could successfully authenticate with the API.

With openDesk 1.0, we introduced a specific group for permission to use the API: `IAM API - Full Access`.

The IAM admin account `Administrator` is the only member of this group by default.

If you need other accounts to use the API, please assign them to the aforementioned group.

### Post-upgrade to versions ≥ v1.0.0

#### Configuration Improvement: Separate user permission for using Video Conference component

With openDesk 1.0 the user permission for authenticated access to the Chat and Video Conference components was split into two separate permissions.

Therefore, the newly added *Video Conference* permission has to be added to users that should have continued access to the component.

This can be done as IAM admin:
- Open the *user* module.
- Select all users that should get the permission for *Video Conference* using the checkbox left of the users' entry.
- In top bar of the user table click on *Edit*.
- Select the *openDesk* section from the left-hand menu.
- Check the checkbox for *Video Conference* and the directly below check box for *Overwrite*.
- Click on the green *Save* button at the top of the screen to apply the change.

> [!tip]
> If you have a lot of users and want to update (almost) all them, you can select all users by clicking the checkbox in the user's table header and then de-selecting the users you do not want to update.

#### Optional Cleanup

We do not execute possible cleanup steps as part of the migrations POST stage. So you might want to remove the unclaimed PVCs after a successful upgrade:

```shell
NAMESPACE=<your_namespace>
kubectl -n ${NAMESPACE} delete pvc shared-data-ums-ldap-server-0
kubectl -n ${NAMESPACE} delete pvc shared-run-ums-ldap-server-0
kubectl -n ${NAMESPACE} delete pvc ox-connector-ox-contexts-ox-connector-0
```

# Automated migrations - Details

## Versions ≥ v1.6.0 (automated)

> [!note]
> Details can be found in [run_5.py](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/-/blob/main/odmigs-python/odmigs_runs/run_5.py).

### Versions ≥ v1.6.0 migrations-post

- Automatically restarts the StatefulSets `ums-provisioning-nats` and `ox-connector` due to a workaround applied on the NATS secrets, see the "Notes" segment of the ["Password seed" heading in getting-started.md](./docs/getting-started.md#password-seed)

> [!note]
> This change aims to prevent authentication failures with NATS in some Pods, which can lead to errors such as: `wait-for-nats Unavailable, waiting 2 seconds. Error: nats: 'Authorization Violation'`.

## Versions ≥ v1.2.0 (automated)

> [!note]
> Details can be found in [run_4.py](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/-/blob/main/odmigs-python/odmigs_runs/run_4.py).

### Versions ≥ v1.2.0 migrations-pre

- Automatically deletes PVC `group-membership-cache-ums-portal-consumer-0`: With the upgrade the Nubus Portal Consumer no longer requires to be executed with root privileges. The PVC contains files that require root permission to access them, therefore the PVC gets deleted (and re-created) during the upgrade.
- Automatically deletes StatefulSet `ums-portal-consumer`: A bug was fixed in the templating of the Portal Consumer's PVC causing the values in `persistence.storages.nubusPortalConsumer.*` to be ignored. As these values are immutable, we had to delete the whole StatefulSet.

### Versions ≥ v1.2.0 migrations-post

- Automatically restarts the Deployment `ums-provisioning-udm-transformer` and StatefulSet `ums-provisioning-udm-listener` and deletes the Nubus Provisioning consumer `durable_name:incoming` on stream `stream:incoming`: Due to a bug in Nubus 1.7.0 the `incoming` stream was blocked after the upgrade, the aforementioned measures unblock the stream.

## Versions ≥ v1.1.0 (automated)

With openDesk v1.1.0 the IAM stack supports HA LDAP primary as well as scalable LDAP secondary pods.

openDesk's automated migrations takes care of this upgrade requirement described here for
[Nubus 1.5.1](https://docs.software-univention.de/nubus-kubernetes-release-notes/1.5.1/en/changelog.html#migrate-existing-ldap-server-to-mirror-mode-readiness),
creating the config map with the mentioned label.

> [!note]
> Details can be found in [run_3.py](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/-/blob/main/odmigs-python/odmigs_runs/run_3.py).

## Versions ≥ v1.0.0 (automated)

The `migrations-pre` and `migrations-post` jobs in the openDesk deployment address the automated migration tasks.

The permissions required to execute the migrations can be found in the migration's Helm chart [`role.yaml'](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/v1.3.5/charts/opendesk-migrations/templates/role.yaml?ref_type=tags#L29).

> [!note]
> Details can be found in [run_2.py](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/-/blob/main/odmigs-python/odmigs_runs/run_3.py).

## Related components and artifacts

openDesk comes with two upgrade steps as part of the deployment; they can be found in the folder [/helmfile/apps](../helmfile/apps/) along with all other components:

- `migrations-pre`: Is the very first app that gets deployed.
- `migrations-post`: Is the last app that gets deployed.

Both migrations must be deployed exclusively at their first/last position and not parallel with other components.

The status of the upgrade migrations is tracked in the ConfigMap `migrations-status`, more details can be found in the [README.md of the related container image](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/README.md).

## Development

When a new upgrade migration is required, ensure to address the following list:

- Update the generated release version file [`global.generated.yaml.gotmpl`](../helmfile/environments/default/global.generated.yaml.gotmpl) at least on the patch level to test the upgrade in your feature branch and trigger it in the `develop` branch after the feature branch was merged. During the release process, the value is overwritten by the release's version number.
- You have to implement the migration logic as a runner script in the [`opendesk-migrations`](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations) image. Please find more instructions in the linked repository.
- You most likely have to update the [`opendesk-migrations` Helm chart](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations) within the `rules` section of the [`role.yaml`](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/main/charts/opendesk-migrations/templates/role.yaml) to provide the permissions required for the execution of your migration's logic.
- You must set the runner's ID you want to execute in the [migrations.yaml.gotmpl](../helmfile/shared/migrations.yaml.gotmpl). See also the `migrations.*` section of [the Helm chart's README.md](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/main/charts/opendesk-migrations/README.md).
- Update the [`charts.yaml.gotmpl`](../helmfile/environments/default/charts.yaml.gotmpl) and [`images.yaml.gotmpl`](../helmfile/environments/default/images.yaml.gotmpl) to reflect the newer releases of the `opendesk-migrations` Helm chart and container image.

[^1]: We do not follow a brand name's specific spelling when it comes to upper and lower case and only use new word
uppercase when names consist of multiple, space divided words.
