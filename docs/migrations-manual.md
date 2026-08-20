<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# Migration requirements

> [!note]
> openDesk's latest migration documentation is split across two documents:
>
> - This document covers the **manual checks and actions** for at least the last two openDesk releases on [the mandatory upgrade path](#overview-and-mandatory-upgrade-path).
> - [`migrations-automated.md`](./migrations-automated.md) covers the **automated migrations**, which openDesk runs on
>   its own as part of every deployment, and the catalogue of the available actions.
>
> New options made available with a release that do not require manual interaction are documented in [`updates.md`](./updates.md)
>
> Manual checks and actions for older openDesk release can be found in [`migrations-manual-archive.md`](./migrations-manual-archive.md).

> [!important]
> Please read and follow these requirements thoroughly before starting an update or upgrade. Always run your backup procedure before beginning an upgrade, as rollbacks may require restoring from backup due to non-reversible database changes within the applications.

> [!warning]
> Depending on your PV reclaim policy, you may need to clean up PVs manually once the related PVCs are no longer in use.

<!-- TOC -->
* [Migration requirements](#migration-requirements)
  * [Deprecation warnings](#deprecation-warnings)
  * [Overview and mandatory upgrade path](#overview-and-mandatory-upgrade-path)
  * [Manual checks/actions](#manual-checksactions)
    * [Versions ≥ v1.18.0](#versions--v1180)
      * [Pre-upgrade to versions ≥ v1.18.0](#pre-upgrade-to-versions--v1180)
        * [New persistence requirement: OX Connector requires its own PostgreSQL database](#new-persistence-requirement-ox-connector-requires-its-own-postgresql-database)
        * [Full re-provisioning of all objects on upgrade](#full-re-provisioning-of-all-objects-on-upgrade)
        * [Nubus fix: Availability of `univentionObjectIdentifier` on all objects](#nubus-fix-availability-of-univentionobjectidentifier-on-all-objects)
        * [OX App Suite: Switch to `univentionObjectIdentifier` and Shared Accounts](#ox-app-suite-switch-to-univentionobjectidentifier-and-shared-accounts)
        * [New Helmfile secrets: Dovecot's password grant client and the OX App Suite REST API](#new-helmfile-secrets-dovecots-password-grant-client-and-the-ox-app-suite-rest-api)
        * [IAM: An externally maintained `univentionObjectIdentifier` has to move](#iam-an-externally-maintained-univentionobjectidentifier-has-to-move)
        * [Changed Helmfile structure: `userNamespaces` setting moved to `technical.userNamespaces`](#changed-helmfile-structure-usernamespaces-setting-moved-to-technicalusernamespaces)
        * [Changed Helmfile structure: Streamlined naming of the theming attributes](#changed-helmfile-structure-streamlined-naming-of-the-theming-attributes)
        * [Changed Helmfile structure: Redis secret moved to `cache.redis.password`](#changed-helmfile-structure-redis-secret-moved-to-cacheredispassword)
        * [Changed Helmfile default: Matrix federation is no longer enabled by default](#changed-helmfile-default-matrix-federation-is-no-longer-enabled-by-default)
        * [Fixed Helmfile templating: S3 region for Dovecot](#fixed-helmfile-templating-s3-region-for-dovecot)
    * [Versions ≥ v1.17.0](#versions--v1170)
      * [Pre-upgrade to versions ≥ v1.17.0](#pre-upgrade-to-versions--v1170)
        * [Fixed Helmfile templating: `loadBalancerIP` for Dovecot and Postfix services](#fixed-helmfile-templating-loadbalancerip-for-dovecot-and-postfix-services)
        * [Postfix: Changed network settings to list](#postfix-changed-network-settings-to-list)
        * [Changed Helmfile structure: Allow overriding app helmfiles and consolidate helmfile environment definitions](#changed-helmfile-structure-allow-overriding-app-helmfiles-and-consolidate-helmfile-environment-definitions)
        * [Changed Helmfile structure: Limited support for existing secrets](#changed-helmfile-structure-limited-support-for-existing-secrets)
          * [Structure of secret definitions](#structure-of-secret-definitions)
          * [Secrets consolidated into their domain files and a consistent `value` structure](#secrets-consolidated-into-their-domain-files-and-a-consistent-value-structure)
      * [Post-upgrade to versions ≥ v1.17.0](#post-upgrade-to-versions--v1170)
        * [Backup of the migration status](#backup-of-the-migration-status)
    * [Versions ≥ v1.16.0](#versions--v1160)
      * [Pre-upgrade to versions ≥ v1.16.0](#pre-upgrade-to-versions--v1160)
        * [Nubus bug fix: LDAP storage class settings](#nubus-bug-fix-ldap-storage-class-settings)
    * [Versions ≥ v1.15.0](#versions--v1150)
      * [Pre-upgrade to versions ≥ v1.15.0](#pre-upgrade-to-versions--v1150)
        * [New Helmfile default: External mail services are no longer enabled by default](#new-helmfile-default-external-mail-services-are-no-longer-enabled-by-default)
        * [New Helmfile default: Support for SeaweedFS as S3 backend](#new-helmfile-default-support-for-seaweedfs-as-s3-backend)
      * [Post-upgrade to versions ≥ v1.15.0](#post-upgrade-to-versions--v1150)
        * [XWiki bug fix: LDAP group synchronization incomplete](#xwiki-bug-fix-ldap-group-synchronization-incomplete)
        * [XWiki bug fix: User account merge for uppercase usernames (Part 2)](#xwiki-bug-fix-user-account-merge-for-uppercase-usernames-part-2)
    * [Versions ≥ v1.14.0](#versions--v1140)
      * [Pre-upgrade to versions ≥ v1.14.0](#pre-upgrade-to-versions--v1140)
        * [Updated Helmfile behaviour: Remove default MASTER\_PASSWORD](#updated-helmfile-behaviour-remove-default-master_password)
        * [Changed Helmfile structure: Custom OIDC clients and client scopes](#changed-helmfile-structure-custom-oidc-clients-and-client-scopes)
        * [Changed Helmfile structure: Single-sign on federation with upstream IdPs](#changed-helmfile-structure-single-sign-on-federation-with-upstream-idps)
      * [Post-upgrade to versions ≥ v1.14.0](#post-upgrade-to-versions--v1140)
        * [Potential restart: OX Connector may get into crash loop](#potential-restart-ox-connector-may-get-into-crash-loop)
    * [Versions ≥ v1.13.0](#versions--v1130)
      * [Pre-upgrade to versions ≥ v1.13.0](#pre-upgrade-to-versions--v1130)
        * [New Helmfile default: Support for Ingress controller `haproxy-ingress.github.io`](#new-helmfile-default-support-for-ingress-controller-haproxy-ingressgithubio)
        * [Updated Helmfile options: New ingress additional annotations](#updated-helmfile-options-new-ingress-additional-annotations)
    * [Versions ≥ v1.12.0](#versions--v1120)
      * [Pre-upgrade to versions ≥ v1.12.0](#pre-upgrade-to-versions--v1120)
        * [New application default: Keycloak imports users to its own database](#new-application-default-keycloak-imports-users-to-its-own-database)
        * [Replace Helm chart: Upgrade to upstream Jitsi 2.x Helm chart](#replace-helm-chart-upgrade-to-upstream-jitsi-2x-helm-chart)
        * [Fixed Helmfile templating: StorageClassNames for Nubus, OpenProject and OX-Connector](#fixed-helmfile-templating-storageclassnames-for-nubus-openproject-and-ox-connector)
        * [New Helmfile default: Postfix SMTP(D) SASL TLS security options](#new-helmfile-default-postfix-smtpd-sasl-tls-security-options)
      * [Post-upgrade to versions ≥ v1.12.0](#post-upgrade-to-versions--v1120)
        * [Wiki bug fix: User account merge for uppercase usernames](#wiki-bug-fix-user-account-merge-for-uppercase-usernames)
        * [IAM new feature: External routing for mail domains](#iam-new-feature-external-routing-for-mail-domains)
<!-- TOC -->

## Deprecation warnings

We cannot hold back all migrations as some are required e.g. due to a change in a specific component that we want/need to update, we try to bundle others only with major releases.

This section provides an overview of potential changes to be part of the next major release (openDesk 2.0).

- `functional.portal.link*` (see `functional.yaml.gotmpl` for details) are going to be moved into the `theme.*` tree, we are also going to move the icons used for the links currently found under `theme.imagery.portalEntries` in this step.
- We will explicitly set the [database schema configuration](https://www.xwiki.org/xwiki/bin/view/Documentation/AdminGuide/Configuration/#HConfigurethenamesofdatabaseschemas) for XWiki to avoid the use of the `public` schema.
- Removal of the `OPENDESK_1_12_0_SKIP_PVC_MIGRATION` option that was [introduced with openDesk 1.12.0](#fixed-helmfile-templating-storageclassnames-for-nubus-openproject-and-ox-connector).
- Focussing on PostgreSQL all components except OX App Suite components:
  - Removal of the XWiki MariaDB support.
  - Removal of the Nextcloud MariaDB support.
- The option `technical.nubus.keycloak.ldapFederation.importUsers` described in the [≥ 1.12.0 migrations](#new-application-default-keycloak-imports-users-to-its-own-database) is likely to be removed by enforcing the documented change of the user import setting.
- Removal of MinIO as S3 storage backend for non-production installations (see [≥ 1.15.0 migrations](#new-helmfile-default-support-for-seaweedfs-as-s3-backend)).
- Removal of the file `helmfile_generic.yaml.gotmpl`, use `helmfile-defaults.yaml.gotmpl` instead.

## Overview and mandatory upgrade path

The following table gives an overview of the mandatory upgrade path of openDesk, required in order for the automated migrations to work as expected.

To upgrade existing deployments, you _cannot_ skip any version denoted with `yes` in the column
*Mandatory*. This ensures [automated migrations](./migrations-automated.md) have the required previous
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
| Version                                                                                   | Mandatory | Pre-Upgrade                                                          | Post-Upgrade                                                           | Minimum Required Previous Version                                                     |
| ----------------------------------------------------------------------------------------- | --------- | -------------------------------------------------------------------- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| [v1.18.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.18.0) | **yes**   | [Pre](#pre-upgrade-to-versions--v1180)                               | [Post](#post-upgrade-to-versions--v1180)                               | ⬇ Install v1.15.x first                                                              |
| [v1.17.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.17.0) | --        | [Pre](#pre-upgrade-to-versions--v1170)                               | [Post](#post-upgrade-to-versions--v1170)                               | ⬇ Install v1.15.x first                                                              |
| [v1.16.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.16.1) | --        | [Pre](#pre-upgrade-to-versions--v1160)                               | --                                                                     | [⚠ Install v1.15.x first](#pre-upgrade-to-versions--v1160)                           |
| [v1.15.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.15.1) | **yes**   | [Pre](#pre-upgrade-to-versions--v1150)                               | [Post](#post-upgrade-to-versions--v1150)                               | ⬇ Install ≥ v1.12.x first                                                            |
| [v1.14.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.14.2) | --        | [Pre](#pre-upgrade-to-versions--v1140)                               | [Post](#post-upgrade-to-versions--v1140)                               | ⬇ Install ≥ v1.12.x first                                                            |
| [v1.13.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.13.2) | --        | [Pre](#pre-upgrade-to-versions--v1130)                               | --                                                                     | [⚠ Install v1.12.x first](#versions--v1120-automated)                                |
| [v1.12.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.12.2) | **yes**   | [Pre](#pre-upgrade-to-versions--v1120)                               | [Post](#post-upgrade-to-versions--v1120)                               | ⬇ Install ≥ v1.8.0 first                                                             |
| [v1.11.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.11.4) | --        | [Pre](./migrations-manual-archive.md#pre-upgrade-to-versions--v1110) | --                                                                     | ⬇ Install ≥ v1.8.0 first                                                             |
| [v1.10.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.10.0) | --        | [Pre](./migrations-manual-archive.md#pre-upgrade-to-versions--v1100) | [Post](./migrations-manual-archive.md#post-upgrade-to-versions--v1100) | ⬇ Install ≥ v1.8.0 first                                                             |
| [v1.9.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.9.0)   | --        | [Pre](./migrations-manual-archive.md#pre-upgrade-to-versions--v190)  | --                                                                     | [⚠ Install v1.8.0 first](./migrations-automated-archive.md#versions--v180-automated) |
| [v1.8.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.8.0)   | **yes**   | [Pre](./migrations-manual-archive.md#pre-upgrade-to-versions--v180)  | --                                                                     | ⬇ Install ≥ v1.5.0 first                                                             |
| [v1.7.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.7.1)   | --        | [Pre](./migrations-manual-archive.md#pre-upgrade-to-versions--v170)  | [Post](./migrations-manual-archive.md#post-upgrade-to-versions--v170)  | ⬇ Install ≥ v1.5.0 first                                                             |
| [v1.6.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.6.0)   | --        | [Pre](./migrations-manual-archive.md#pre-upgrade-to-versions--v160)  | [Post](./migrations-manual-archive.md#post-upgrade-to-versions--v160)  | [⚠ Install v1.5.0 first](./migrations-automated-archive.md#versions--v160-automated) |
| [v1.5.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.5.0)   | **yes**   | --                                                                   | --                                                                     | ⬇ Install ≥ v1.1.x first                                                             |
| [v1.4.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.4.1)   | --        | [Pre](./migrations-manual-archive.md#pre-upgrade-to-versions--v140)  | --                                                                     | ⬇ Install ≥ v1.1.x first                                                             |
| [v1.3.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.3.2)   | --        | [Pre](./migrations-manual-archive.md#pre-upgrade-to-versions--v130)  | --                                                                     | ⬇ Install ≥ v1.1.x first                                                             |
| [v1.2.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.2.1)   | --        | [Pre](./migrations-manual-archive.md#pre-upgrade-to-versions--v120)  | --                                                                     | [⚠ Install v1.1.x first](./migrations-automated-archive.md#versions--v120-automated) |
| [v1.1.x](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.1.2)   | **yes**   | [Pre](./migrations-manual-archive.md#pre-upgrade-to-versions--v110)  | [Post](./migrations-manual-archive.md#post-upgrade-to-versions--v110)  | [⚠ Install v1.0.0 first](./migrations-automated-archive.md#versions--v110-automated) |
| [v1.0.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.0.0)   | **yes**   | [Pre](./migrations-manual-archive.md#pre-upgrade-to-versions--v100)  | [Post](./migrations-manual-archive.md#post-upgrade-to-versions--v100)  | [⚠ Install v0.9.0 first](./migrations-automated-archive.md#versions--v100-automated) |
| [v0.9.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v0.9.0)   | **yes**   | --                                                                   | --                                                                     | --                                                                                    |

## Manual checks/actions

> [!note]
> We **only** use the mathematical symbol ≥ to denote for which versions manual steps must be
> applied. For example, "Versions ≥ v1.7.0" refers to all openDesk versions (major, minor and
> patch) starting from 1.7.0, e.g. 1.7.0, 1.7.1, 1.8.0, etc. Furthermore, if a version is not explicitly
> listed no extra manual steps are required when upgrading to that version, e.g. in the case of an update from
> version 1.7.0 to version 1.7.1.

### Versions ≥ v1.18.0

#### Pre-upgrade to versions ≥ v1.18.0

##### New persistence requirement: OX Connector requires its own PostgreSQL database

**Target group:** All deployments using OX App Suite and an external PostgreSQL service.

**Context**

With OX Connector 0.41.0 the connector no longer keeps its object cache on its volume alone, it
requires a dedicated PostgreSQL database.

openDesk declares the database as `databases.oxConnector` in
[`database.yaml.gotmpl`](../helmfile/environments/default/database.yaml.gotmpl):

```yaml
databases:
  oxConnector:
    type: "postgresql"
    name: "oxconnector"
    host: "postgresql"
    port: 5432
    username: "oxconnector_user"
```

On first start the connector's `init-db` container detects the empty tables, recreates its
subscription to the Provisioning Service and requests a full replay of all UDM objects to rebuild
its cache. The first start therefore takes considerably longer than usual.

**Required action: Provide an empty database and user**

If you run an external PostgreSQL service, required for production-grade deployments, create the
database and its user yourself before the upgrade and grant the user full privileges on it:

```sql
CREATE USER oxconnector_user WITH PASSWORD '<databases.oxConnector.password.value>';
CREATE DATABASE oxconnector OWNER oxconnector_user;
GRANT ALL PRIVILEGES ON DATABASE oxconnector TO oxconnector_user;
```

> [!note]
> The connector receives the connection as a single SQLAlchemy URL via
> `openXchange.oxDbConnectionString`, which openDesk composes from the `databases.oxConnector`
> values. The chart provides no `existingSecret` for it, so the password is part of that URL.
> Username and password are percent-encoded by the Helmfile.

##### Full re-provisioning of all objects on upgrade

**Target group:** Large scale deployments using OX App Suite and no dedicated provisioning Pod.

**Context**

As described above, the OX Connector rebuilds its object cache on the first start after the upgrade.
It re-subscribes to the Provisioning Service and replays all relevant objects (users, groups, resources,
shared mailboxes), so all these objects get updated in OX App Suite again.

Depending on the number of users and groups, the replay can take a long time and generates
considerable load on the Core Middleware and on the OX database. End-user requests served by the
same Core Middleware Pods can slow down noticeably while it runs. Plan the upgrade accordingly,
e.g. outside of business hours.

> [!note]
> The replay is not visible in the Pod status. Follow the respective NATS queue to track its progress.
> Only once the replay is completed newly created or updated objects will be available in OX App Suite.

**Recommended action: Use a dedicated provisioning Pod for larger deployments**

For deployments with a large number of users and groups we recommend running provisioning on its own
Core Middleware Pod, so that the replay does not compete with the Pods serving end-user sessions:

```yaml
technical:
  oxAppSuite:
    provisioning:
      dedicatedCoreMwPod: true
```

##### Nubus fix: Availability of `univentionObjectIdentifier` on all objects

**Target group:**

Installations that initially deployed an openDesk version <1.6 and always used LDAP secondaries without LDAP proxies
and run into the problem that the `opendesk-migrations-pre` job fails with an error like:

`The user uid=default.user,cn=users,dc=swp-ldap,dc=internal has no univentionObjectIdentifier, so its OX App Suite user cannot be renamed to one.`

**Context:**

The job that initializes the `univentionObjectIdentifier` - part of openDesk since 1.6.0 until it was phased out with 1.18.0 - ended with status
"Succeeded" even when the required updates could not be executed. This happened in setups where LDAP secondaries are deployed without the LDAP
proxy that takes care of routing write requests to the appropriate (primary) backend: The job's writes against a secondary which is read-only
do not succeed, and objects created while such a setup was in place may still be missing their `univentionObjectIdentifier`.

**Required action:**

Run the job `ums-udm-rest-api-XX-update-univention-object-identifier` again, but with a changed value.

Before:

```yaml
            - name: LDAP_URI
              value: ldap://ums-ldap-server
```

After:

```yaml
            - name: LDAP_URI
              value: ldap://ums-ldap-server-primary
```

An example Job manifest with this change applied can be found in [`1.18.0-initialize-univentionObjectIdentifier.yaml`](./migrations-helper/1.18.0-initialize-univentionObjectIdentifier.yaml).

Once done you can simply re-start the deployment of openDesk 1.18+ and the migrations-pre Job should succeed.

##### OX App Suite: Switch to `univentionObjectIdentifier` and Shared Accounts

**Target group:** All deployments using OX App Suite.

> [!warning]
> Between `migrations-pre` and `migrations-post` the Functional Account mailboxes do not exist: Action 2 (see below)
> deletes them in OX App Suite and their objects in the IAM, and only action 5 recreates them as Shared Accounts.
> For that window  their addresses are unknown recipients, so mail to them - especially from the internet -
> is **rejected permanently and bounces back to the sender**; it is not queued and not delivered later.
> If external mail is expected during the upgrade, point the MX records of the affected mail domains at a host that
> answers with a temporary failure (`4xx`) for the duration, so sending servers keep the messages in their queue and
> retry once the migration has finished. Personal mailboxes are not affected, but they share the same MX.

**Context:**

openDesk 1.18.0 changes two things in the OX provisioning at once, and the automated actions that migrate them depend on each other:

- Up to 1.17.x the OX Connector addressed users, groups and shared accounts in OX App Suite by their name. From 1.18.0 on it addresses them by their `univentionObjectIdentifier`, so that renaming a user or a group in the IAM no longer makes the Connector lose the account it provisioned and create a second one beside it.
- The IAM's Functional Accounts (`oxmail/functional_account`) are replaced by Shared Accounts (`oxmail/shared_account`). The two objects are not the same thing: A Functional Account listed its users, a Shared Account links each of its users together with a permission (`oxmail/shared_account_permission`), which is what allows to grant each user a different level of access - calendar only, or the mailbox with or without the calendar - instead of one blanket access for everyone linked to it.

Five automated actions do this, and they are applied with the upgrade - the Connector deployed right after them addresses its objects by what they write:

1. [`workload_scale`](./migrations-automated.md#workload_scale) scales the OX Connector to 0 as the first step of `migrations-pre`. The actions that follow change the objects it provisions, on both sides, so it must not write them at the same time. The deployment brings it back up with the configuration of this release.
2. [`ox_functional_accounts_export`](./migrations-automated.md#ox_functional_accounts_export) records the Functional Accounts in `migrations-pre`, removes their counterparts in OX App Suite, deletes the IAM objects and reads every OX context back to confirm that none of the mailboxes is left.
3. [`ldap_entryuuid_to_object_identifier`](./migrations-automated.md#ldap_entryuuid_to_object_identifier) copies the value of `entryUUID`  to `univentionObjectIdentifier` for each object of the LDAP.
4. [`ox_names_to_object_identifier`](./migrations-automated.md#ox_names_to_object_identifier) renames the user accounts and the groups in OX App Suite to that identifier, in every OX context the IAM hold.
5. [`ox_shared_accounts_import`](./migrations-automated.md#ox_shared_accounts_import) creates the Shared Accounts from the export in `migrations-post`, where the IAM knows the module they need.

Every action logs per object what it changes, in the log of the `migrations-pre` respectively the `migrations-post` Job. That log is the only record of the previous values.

> [!note]
> Actions 2 and 5 are two halves of one migration running in two jobs, so the first hands its export to the second
> as an object in the `migrations` bucket - one record per Functional Account. That bucket has been declared as `objectstores.migrations` in
> [`objectstores.yaml.gotmpl`](../helmfile/environments/default/objectstores.yaml.gotmpl) all along, but **1.18.0 is
> the first release in which anything writes to it**. The bundled MinIO and SeaweedFS provision it from that
> declaration. If you run an externally managed S3 storage backend, make sure the bucket and its identity exist and
> are reachable before you upgrade. The migration proves both before it changes anything, so a deployment that
> cannot reach the bucket fails in `migrations-pre` with the Functional Accounts still untouched.

**Required action:**

1. Choose the permission every linked user of a Shared Account is to receive via `migrations.actionOptions.oxFunctionalToSharedAccounts.permission` in [`migrations.yaml.gotmpl`](../helmfile/environments/default/migrations.yaml.gotmpl), given as the `name` of the `oxmail/shared_account_permission` object. It defaults to openDesk's `opendesk_mail_author_calendar_author` ("Mail: Full access, Calendar: Full access"), the permission that comes closest to what a Functional Account granted its users:
   - `opendesk_mail_none_calendar_viewer`: "Mail: No access, Calendar: Read"
   - `opendesk_mail_author_calendar_none`: "Mail: Full access, Calendar: No access". If you do not want to make use of the calendar functionality available with Shared Accounts, provide a permission for mail only.
   - `opendesk_mail_author_calendar_viewer`: "Mail: Full access, Calendar: Read"
   - `opendesk_mail_author_calendar_editor`: "Mail: Full access, Calendar: Edit"
   - `opendesk_mail_author_calendar_author`: "Mail: Full access, Calendar: Full access" - the default setting
   - `opendesk_mail_admin_calendar_none`: "Mail: Administration, Calendar: No access"
   - `opendesk_mail_admin_calendar_viewer`: "Mail: Administration, Calendar: Read"
   - `opendesk_mail_admin_calendar_editor`: "Mail: Administration, Calendar: Edit"
   - `opendesk_mail_admin_calendar_author`: "Mail: Administration, Calendar: Full access"
2. Upgrade, then review the logs of both Jobs. The identifier actions verify their own result and fail the deployment rather than leaving the Connector unable to find the accounts.
3. Review the resulting Shared Accounts in the IAM and adjust the per user permissions where the single permission granted by the migration is not what that user should have. Accounts whose name contained spaces or punctuation are renamed, because a Shared Account is named with the same syntax as a user name - "Team Sales" becomes `Team-Sales`, with the original kept as the account's display name. The `migrations-post` Job lists every such rename.

The four actions cannot be previewed, and they are not meant to be run one by one: the OX Connector of 1.18.0 addresses its objects by the identifier they write, so a deployment that applied only some of them is a state this release cannot work with. Either the migration runs as a whole, or you perform it yourself.

If you perform one of the migrations yourself, opt out through `migrations.actionsSkip` - of **all** actions belonging to it, for the Shared Accounts so in `pre` *and* in `post`, as opting out of only one leaves that migration half applied. See [Skip single actions of the automated migrations](./updates.md#skip-single-actions-of-the-automated-migrations).

##### New Helmfile secrets: Dovecot's password grant client and the OX App Suite REST API

**Target group:** Deployments using OX App Suite that supply their own secret values instead of deriving them from `MASTER_PASSWORD`.

**Context:**

The Shared Accounts introduced with [OX App Suite: Switch to `univentionObjectIdentifier` and Shared Accounts](#ox-app-suite-switch-to-univentionobjectidentifier-and-shared-accounts) grant each linked user an individual permission on the account, and Dovecot has to establish on every login who is connecting and what that user is allowed to do. Two new entries in [`secrets.yaml.gotmpl`](../helmfile/environments/default/secrets.yaml.gotmpl) cover the two halves of that question:

- `secrets.keycloak.clientSecret.dovecotGrant`: The client secret of a second Keycloak client for Dovecot, `opendesk-dovecot-grant`, delivered as the Secret `keycloak-grant-client-secret-dovecot` and registered by the Keycloak bootstrap. Opening a Shared Account from an external mail client is a `user@account` login with the user's own password, not a token login, so Dovecot verifies that password itself: It exchanges it at Keycloak's token endpoint through a Direct Access Grant and takes the `opendesk_objectid` of the authenticated user from the returned token. That capability gets its own client rather than being added to the existing `opendesk-dovecot`, which is only allowed to introspect tokens: The grant client has the standard and the implicit flow switched off and a scope that carries nothing but `opendesk_objectid` and `sub`, so its secret cannot be used to obtain tokens with the full `opendesk-dovecot-scope`.
- `secrets.oxAppSuite.restApiPassword`: The password of the OX App Suite REST user `rest-api` (`com.openexchange.rest.services.basic-auth.login`/`.password`). With the identity established, Dovecot asks OX which permission that user holds on the requested Shared Account and translates the answer into the mailbox ACL it applies for the session. OX Guard reads the same credential (`com.openexchange.guard.restApiUsername`/`Password`). The REST routes themselves are not new, but this is the first release that configures a login for them.

**Required action**

None if your secrets are derived from `MASTER_PASSWORD` - both are generated along with all the others.

If you override secret values, add the two entries in the structure described in [Structure of secret definitions](#structure-of-secret-definitions):

```yaml
secrets:
  oxAppSuite:
    restApiPassword:
      value: "your_custom_password"
  keycloak:
    clientSecret:
      dovecotGrant:
        value: "your_custom_secret"
        create: false
        name: "your-own-secret"
        key: "secret"
```

> [!note]
> `secrets.oxAppSuite.adminPassword` gained `create`/`name`/`key` in the same release and is now additionally
> rendered as the Secret `opendesk-ox-admin-password`. The OX App Suite charts keep receiving the plain value; the
> Secret exists because the automated migrations read the master administrator's credentials from a mount only. If
> you bring your own, set `create: false` and point `name`/`key` at your Secret.

##### IAM: An externally maintained `univentionObjectIdentifier` has to move

**Target group:** Deployments that provision users and groups from an external IAM and store that IAM's identifier in the `univentionObjectIdentifier` of the objects they create.

**Context:**

As described in [OX App Suite: Switch to `univentionObjectIdentifier` and Shared Accounts](#ox-app-suite-switch-to-univentionobjectidentifier-and-shared-accounts), openDesk takes the `univentionObjectIdentifier` into its own use with this release: [`ldap_entryuuid_to_object_identifier`](./migrations-automated.md#ldap_entryuuid_to_object_identifier) gives every object that carries one its own `entryUUID` as identifier, and the components deployed after it - the OX Connector above all - address their objects by that value. An identifier your synchronization wrote there is therefore overwritten with the upgrade, and it cannot be written back afterwards.

For this case openDesk reserves the LDAP attribute `univentionFreeAttribute2` and ships it from 1.18.0 on as the UDM extended attribute `reservedLegacyExternalIamIdentifier` ("Identifier from external IAM"). openDesk neither reads nor writes it; it exists so that the identifier of an external IAM has a place that stays yours.

**Required action:**

Move your identifiers there **before** you upgrade:

1. Stop the synchronization from your external IAM.
2. Create the extended attribute `reservedLegacyExternalIamIdentifier` through the UDM REST API, with the definition openDesk ships.
3. Copy the `univentionObjectIdentifier` of all users and groups into that attribute.
4. Reconfigure the synchronization to write and match on the new attribute.
5. Upgrade openDesk.
6. Restart the synchronization, about 30 minutes after the upgrade, so that the LDAP index for `univentionFreeAttribute2` added with this release has been created.

Each step with its API calls and a helper script for the copy: see [Preserve an externally maintained object identifier](./migrations-instructions/1.18.0-preserve-external-iam-identifier.md).

##### Changed Helmfile structure: `userNamespaces` setting moved to `technical.userNamespaces`

**Target group:** Deployments that set `technical.postfix.userNamespaces` introduced with 1.17.0 to (non-default) `true`.

**Context**

The setting to run a Pod in its own Kubernetes user namespace was previously specific to Postfix, under
`technical.postfix.userNamespaces`. It has been generalized into a single, shared toggle at
`technical.userNamespaces`, since Dovecot now supports running in its own user namespace as well.

**Required action**

If you set this option, move it out of `technical.postfix` to the new top-level location under `technical`:

Before:

```yaml
technical:
  postfix:
    userNamespaces: true
```

After:

```yaml
technical:
  userNamespaces: true
```

##### Changed Helmfile structure: Streamlined naming of the theming attributes

**Target group:** Deployments that customize the header logos, i.e. that set `theme.imagery.logoHeaderSvgB64`
and/or `theme.imagery.logoHeaderInvertedSvgB64`.

**Context**

Practically all attributes below `theme.imagery` carry Base64-encoded assets, but only the two header
logo attributes stated this in their name with a `B64` suffix. The naming has been streamlined to the
`<asset><Format>` scheme used by all other attributes, and the redundant `B64` suffix has been dropped:

| Before                                   | After                                 |
|------------------------------------------|---------------------------------------|
| `theme.imagery.logoHeaderSvgB64`         | `theme.imagery.logoHeaderSvg`         |
| `theme.imagery.logoHeaderInvertedSvgB64` | `theme.imagery.logoHeaderInvertedSvg` |

This is a pure rename: the expected value is unchanged, the attributes still take the Base64-encoded
content of an SVG file.

**Required action**

If you set one or both of these attributes, rename them in your customization.

Before:

```yaml
theme:
  imagery:
    logoHeaderSvgB64: {{ readFile "./files/theme/myLogoHeader.svg" | b64enc | quote }}
    logoHeaderInvertedSvgB64: {{ readFile "./files/theme/myLogoHeaderInverted.svg" | b64enc | quote }}
```

After:

```yaml
theme:
  imagery:
    logoHeaderSvg: {{ readFile "./files/theme/myLogoHeader.svg" | b64enc | quote }}
    logoHeaderInvertedSvg: {{ readFile "./files/theme/myLogoHeaderInverted.svg" | b64enc | quote }}
```

The old attribute names are not evaluated any longer. If they are not renamed, the deployment silently
falls back to openDesk's default logos instead of failing, so please verify your branding after the
upgrade.

> [!note]
> Along with the rename, the assets that are shared by several modules have been moved into the new
> directory `helmfile/files/theme/_common/`, matching the per-module directories that already existed:
>
> - `helmfile/files/theme/logoHeader.svg` → `helmfile/files/theme/_common/logoHeader.svg`
> - `helmfile/files/theme/logoHeaderInverted.svg` → `helmfile/files/theme/_common/logoHeaderInverted.svg`
> - `helmfile/files/theme/logoHeader.jpg` → `helmfile/files/theme/_common/logoHeader.jpg`
> - `helmfile/files/theme/robots.txt` → `helmfile/files/theme/_common/robots.txt`
>
> This only affects you if your customization references these openDesk-shipped files by path, e.g. via
> `readFile` or in `theme.imagery.projects.pdfExport*Path`. Adjust such references accordingly.

##### Changed Helmfile structure: Redis secret moved to `cache.redis.password`

**Target group:** Deployments that override `secrets.redis.password` or point a component at an external cache
with `cache.<component>.password`.

**Context**

The Redis credential lived in two places: The server's password as `secrets.redis.password`, and a per-component
override as `cache.<component>.password.value` that carried a value only and was empty by default, with every
consumer falling back to the former.

Continuing the consolidation started in 1.17.0 (see
[Secrets consolidated into their domain files](#secrets-consolidated-into-their-domain-files-and-a-consistent-value-structure)),
[`cache.yaml.gotmpl`](../helmfile/environments/default/cache.yaml.gotmpl) is now the single place a cache and its
credential are configured. The fallback itself is unchanged - an empty `cache.<component>.password.value` still
means "the bundled server's password" - only its target moved along with the server password, from
`secrets.redis.password` to `cache.redis.password`.

**Required action**

If you set the Redis password yourself, move it:

Before:

```yaml
secrets:
  redis:
    password:
      value: "..."
```

After:

```yaml
cache:
  redis:
    password:
      value: "..."
```

Setting only `cache.redis.password` still changes the password for the server and for all components using the
bundled Redis, exactly as setting `secrets.redis.password` did before. If a component uses an external cache,
override that component's own `password.value` as before - a non-empty component entry wins over the fallback.

##### Changed Helmfile default: Matrix federation is no longer enabled by default

**Target group:** Deployments using the chat module to exchange messages with users of other homeservers.

**Context**

openDesk's Synapse homeserver can federate with other Matrix homeservers. Previously federation was
enabled by default, which meant every new deployment exposed the federation endpoint and accepted
federation traffic from any homeserver on the internet ("open federation") unless the operator
actively turned it off. To harden the default deployment, `functional.externalServices.matrix.federation.enabled`
is now `false`, so federation is an explicit opt-in decision.

Open federation noticeably increases the attack surface of a homeserver: The federation API is
reachable by arbitrary remote servers, and a large share of the vulnerabilities reported against
Synapse can only be triggered over that path. A recent example is the Synapse 1.157.2 security
release shipped with openDesk 1.17.1 and 1.16.2, whose CVE fixes were, per the
[upstream release notes](https://github.com/element-hq/synapse/releases/tag/v1.157.2), especially
relevant for setups configured with open federation. Deployments without federation, or with
federation limited to a known set of trusted partner domains, were largely unaffected.
Switching off or restricted federation therefore reduces both the exposure to such issues and the
urgency of reacting to them.

**Required action**

If your deployment federates with other homeservers, re-enable federation explicitly:

```yaml
functional:
  externalServices:
    matrix:
      federation:
        enabled: true
```

Additionally, you can restrict federation to a defined set of homeserver domains instead of
federating openly. When `domainAllowList` is non-empty, Synapse only federates with the listed
domains:

```yaml
functional:
  externalServices:
    matrix:
      federation:
        enabled: true
        domainAllowList:
          - "partner-one.example"
          - "partner-two.example"
```

An empty list (`domainAllowList: []`, the default) means no restriction, i.e. open federation with
all reachable homeservers. We recommend maintaining an allow list wherever the set of federation
partners is known in advance.

> [!note]
> Changing the setting does not remove already federated rooms or their history; it only stops
> further federation traffic. Existing rooms shared with users on other homeservers will no longer
> receive or send updates once federation is disabled or the remote domain is not part of the
> allow list.

##### Fixed Helmfile templating: S3 region for Dovecot

**Target group:** Deployments using an external S3 service for Dovecot with `objectstores.dovecot.region` set to a value other than `"eu-west-1"`.

**Context:**

Until now, `objectstores.dovecot.region` was not rendered into the Dovecot values, so Dovecot always used the chart
default `eu-west-1`. The setting is now passed through and takes effect.

**Required action**

None. Since the region had no effect before, this note is purely informational.

### Versions ≥ v1.17.0

#### Pre-upgrade to versions ≥ v1.17.0

##### Fixed Helmfile templating: `loadBalancerIP` for Dovecot and Postfix services

**Target group:** Deployments that set `service.loadBalancerIp.dovecot` or `service.loadBalancerIp.postfix`.

**Context:**

Until now, the setting `service.loadBalancerIp` was rendered into the Dovecot and Postfix service manifests with an
incorrect field name (`loadBalancerIp` instead of `loadBalancerIP`), so it was silently ignored by Kubernetes and
never had any effect. The templating has been fixed and the setting has been renamed accordingly.

**Required action**

If you configured this setting, rename the key to use an uppercase "P":

```yaml
service:
  loadBalancerIP:
    dovecot: "1.2.3.4"
    postfix: "2.3.4.5"
```

> [!note]
> The assigned load balancer IP of an existing service may change once the setting takes effect for the
> first time.

##### Postfix: Changed network settings to list

**Target group:** Deployments with customized relay net or other networking related settings.

**Context**

All network related settings are using lists now instead of strings.

**Required action: Update all network related settings to lists, including `127.0.0.1/32` and `[::1]/128` if necessary**

Example: Change the customization from a space-separated string:
```yaml
postfix:
  relayNets: "127.0.0.0/8 ::1/128 1.2.3.4/24 2001:d35c:123:4::/64"
```

to a list:
```yaml
postfix:
  relayNets:
    - "127.0.0.0/8"
    - "::1/128"
    - "1.2.3.4/24"
    - "2001:d35c:123:4::/64"
```

##### Changed Helmfile structure: Allow overriding app helmfiles and consolidate helmfile environment definitions

**Target group:** All deployments that deploy single applications or override the helmfiles from another repository

**Context:**

While the helmfile structure already allowed some advanced use cases like referencing the `helmfile_generic.yaml.gotmpl`
file in the root directory of this repository to define your own environments from an external repository, there
were also still some limitations:

- It was not easily possible to reference the `helmfile.yaml.gotmpl` in an application directory, e.g.
  `helmfile/apps/collabora`, to override a single application's default values.

- The helmfile structure forced the maintenance of two files that define helmfile environments, the `helmfile.yaml.gotmpl` in
  the root directory and `environments.yaml.gotmpl` in `helmfile/bases/`.

To solve these problems the helmfile structure was changed by introducing three types of helmfiles:

- `helmfile.yaml.gotmpl`: Entrypoint for helmfile that includes the environments defined in `helmfile/bases/environments.yaml.gotmpl`.

  There is a `helmfile.yaml.gotmpl` in the root directory of this repository and in the directory of each application,
  e.g. `helmfile/apps/collabora/helmfile.yaml.gotmpl`. All `helmfile` calls have to be made from the root directory
  (see the required actions below).

- `helmfile-defaults.yaml.gotmpl`: Entrypoint for external helmfile's. This helmfile does not include environments
  but includes all default values for the applications. This file can be referenced from an external repository
  to define environments that override the default values.

  There is a `helmfile-defaults.yaml.gotmpl` in the root directory of this repository and in the directory for each application,
  e.g. `helmfile/apps/collabora/helmfile-defaults.yaml.gotmpl`.

- `helmfile-child.yaml.gotmpl`: Defines the deployment logic for an application. This file contains the definition of
  which helm charts to deploy for each openDesk application without any value defined and is thus not meant to be used directly.

  `helmfile-child.yaml.gotmpl` files are only present in the directory for each application, e.g. `helmfile/apps/collabora/helmfile-child.yaml.gotmpl`.

A diagram showing the helmfile references might help to make this more descriptive:

```mermaid
flowchart TD
    subgraph deployment_opendesk[deployment/opendesk]
        helmfile_root[helmfile - root] --> helmfile_environments[helmfile - environments]
        helmfile_environments --> values_prod((values - prod))
        helmfile_root --> helmfile_defaults_root[helmfile-defaults - root]
        helmfile_defaults_root --> helmfile_defaults_app[helmfile-defaults - app]
        helmfile_defaults_app --> values_defaults((values - defaults))
        helmfile_defaults_app --> helmfile_child_app[helmfile-child - app]
        helmfile_app[helmfile - app] --> helmfile_environments
        helmfile_app --> helmfile_defaults_app
    end

    subgraph external_opendesk_env[external/opendesk-environment-definitions]
        helmfile_root_external[helmfile - root] --> helmfile_defaults_root
        helmfile_root_external --> helmfile_environments_external[helmfile - environments]
        helmfile_app_external[helmfile - app] --> helmfile_defaults_app
        helmfile_app_external --> helmfile_environments_external
        helmfile_environments_external --> values_external((values - external))
    end
```

**Required action: Use the correct helmfile for your use-case**

- Use-case: Deploying all openDesk applications from this repository:
  - Nothing changes, run `helmfile` from the root directory.

- Use-case: Deploying a single application from this repository:
  - `helmfile` needs to be executed from the root directory instead of the application directory:

    ```bash
    # Instead of previously
    cd helmfile/apps/collabora
    helmfile apply

    # Do this (from the root directory)
    helmfile apply --file helmfile/apps/collabora/helmfile.yaml.gotmpl
    ```

- Use-case: Overriding all openDesk applications from an external repository
  - Instead of `helmfile_generic.yaml.gotmpl` reference `helmfile-defaults.yaml.gotmpl` from the root directory.
  - `helmfile_generic.yaml.gotmpl` is kept for backwards compatibility reasons but will be removed with version 2.0.

- Use-case: Overriding a single openDesk application from an external repository
  - Reference `helmfile-defaults.yaml.gotmpl` from the application directory,
    e.g. `helmfile/apps/collabora/helmfile-defaults.yaml.gotmpl`.
  - This was not easily possible before this release.
  - For an example, see [updates.md](./updates.md#helmfile-defaultsyamlgotmpl).

##### Changed Helmfile structure: Limited support for existing secrets

###### Structure of secret definitions

**Target group**

All deployments that override one or more `secrets.*` entries with custom values.
Deployments that rely entirely on the values derived from `MASTER_PASSWORD` do not need to change
any values, but should still be aware of the new structure.

**Context**

Every entry under `secrets:` in `secrets.yaml.gotmpl` changed from a bare scalar to a mapping. The actual
secret value now lives under a `value:` key, and secrets whose chart can consume a Kubernetes Secret
additionally carry `create`, `name` and `key` fields.

The same structural change applies to the secret-bearing entries in all of the following
environment files (see the [Secrets consolidated into their domain files](#secrets-consolidated-into-their-domain-files-and-a-consistent-value-structure)
subsection below for more details):

- `helmfile/environments/default/secrets.yaml.gotmpl`: All `secrets.*` entries.
- `helmfile/environments/default/objectstores.yaml.gotmpl`: The S3 secret key of every store
(`objectstores.<store>.secretKey`).
- `helmfile/environments/default/database.yaml.gotmpl`: The per-app database password
(`databases.<db>.password`) - for Nextcloud on MariaDB (default before openDesk 1.2.0) make sure
you check the section below.

By default, openDesk now provisions those secrets as real Kubernetes Secrets instead of inlining the
plaintext into each component's values: a new release `opendesk-secrets` creates
one Secret per `create: true` entry, and the consuming charts read the credential from it via their
`existingSecret` option. The values are still derived from `MASTER_PASSWORD`, so this is transparent for
standard deployments.

> [!note]
> Be aware that a new release and new Secret objects will appear (relevant for GitOps/ArgoCD diffs).

**Required action: Move custom secret values under `value:`**

If you override any secret, nest your value under `.value`. A bare scalar now replaces the whole mapping and
breaks the components that read `<secret>.value`.

Before:

```yaml
secrets:
  oxAppSuite:
    migrationsMasterPassword: "your_custom_password"
  keycloak:
    clientSecret:
      portal: "your_custom_secret"
```

After:

```yaml
secrets:
  oxAppSuite:
    migrationsMasterPassword:
      value: "your_custom_password"
  keycloak:
    clientSecret:
      portal:
        value: "your_custom_secret"
```

This applies to every overridden entry, at every nesting depth, e.g.
- `secrets.postgresql.nextcloudUser.value` or
- `secrets.nubus.ldapSearch.dovecot.value`.

It is the only change required to keep a manually-managed secrets configuration working.

See [updates.md](./updates.md) for how to bring your secrets.

> [!note]
> During applying the change above we found the following secret being obsolete now:
> `secrets.nubus.systemAccounts.sysIdpUserPassword`
> It was removed from the `secrets` structure.

###### Secrets consolidated into their domain files and a consistent `value` structure

**Target group**

Deployments that
- override any object-store S3 secret key (`objectstores.<store>.secretKey`) or any
database password (`databases.<db>.password`) with a custom value,
- override any of the remaining credentials listed below (cache, AI, SMTP) or
- use MariaDB for Nextcloud with the out-of-the-box generated password, which
was the default before [openDesk 1.2.0](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases/v1.2.0).

**Context**

The object-store S3 secret keys and the per-app database passwords are no longer defined in
`secrets.yaml.gotmpl`. They now live co-located with their configuration in
`objectstores.yaml.gotmpl` and `database.yaml.gotmpl`, using the same externalized-secret shape
(`{value, create, name, key}`) as the other managed secrets.

The database *server* credentials stay where they were: `secrets.mariadb.rootPassword` and
`secrets.postgresql.postgresUser` remain defined in `secrets.yaml.gotmpl`. Only the per-app
database user passwords moved.

In addition, the credentials that still held their secret as a bare scalar now use the same nested
`value:` structure, so that every credential in the Helmfile environment definition is written the
same way:

- `cache.yaml.gotmpl`: The cache password of every component (`cache.<component>.password`) -
  `intercomService`, `nextcloud`, `notes` and `oxAppSuite`.
- `ai.yaml.gotmpl`: The API key of the external AI endpoint (`ai.apiKey`).
- `smtp.yaml.gotmpl`: The password of the external SMTP relay (`smtp.password`).
- `database.yaml.gotmpl`: The optional read-replica password of OX App Suite
  (`databases.oxAppSuite.readPassword`).

These entries stay value-only: They do not take the `create`/`name`/`key` fields, because they are
operator-supplied overrides that are empty by default (there is nothing to provision from an empty
value) and the consuming components still read the literal value. Adopting `value` now means they can
gain `create`/`name`/`key` later without another change to the structure.

**Required action: Move custom overrides under `value:`**

If you override any of these, nest your value under the `value:` key - and, for the object-store and
database secrets, at their new location. A bare scalar now replaces the whole mapping and breaks the
components that read `<credential>.value`.

Before:

```yaml
objectstores:
  nextcloud:
    secretKey: "your_custom_key"
databases:
  keycloak:
    password: "your_custom_password"
smtp:
  password: "your_password"
cache:
  nextcloud:
    password: "your_cache_password"
ai:
  apiKey: "your_api_key"
```

After:

```yaml
objectstores:
  nextcloud:
    secretKey:
      value: "your_custom_key"
databases:
  keycloak:
    password:
      value: "your_custom_password"
smtp:
  password:
    value: "your_password"
cache:
  nextcloud:
    password:
      value: "your_cache_password"
ai:
  apiKey:
    value: "your_api_key"
```

Special cases:

- **OX App Suite / external MariaDB**: `databases.oxAppSuite.password` also moved to the new shape.
  It is not a managed Secret (OX connects as the MariaDB `root` user and the value defaults to
  `secrets.mariadb.rootPassword`), but if you override it - typically when using an external
  MariaDB - the override now goes under `databases.oxAppSuite.password.value`.

- **Nextcloud on MariaDB**: Nextcloud can run on either engine, but `databases.nextcloud.password`
  is a single managed Secret shared by both, seeded from the PostgreSQL-salted default. If you still
  run Nextcloud on MariaDB, you must set `databases.nextcloud.password.value` explicitly to the
  password your MariaDB user actually has, which is likely the default that was used before:
  ```
  nextcloudUser: {{ derivePassword 1 "long" $masterPassword "mariadb" "nextcloud_user" | sha1sum | quote }}
  ```

  > [!warning]
  > MariaDB support for Nextcloud and XWiki is deprecated in openDesk and will be removed in openDesk 2.0.

#### Post-upgrade to versions ≥ v1.17.0

##### Backup of the migration status

**Target group:** All deployments

**Context:**

The status of the automated migrations is tracked in the ConfigMap `migrations-status`, see [Related components and artifacts](./migrations-automated.md#related-components-and-artifacts). It is part of your deployment's state: It records which migration actions have already been applied and which release was migrated successfully last, and it cannot be reconstructed from the applications' data. So it must be in scope of your backup and restore process, otherwise the automated migrations of your next upgrade run against a state that does not match the restored data, which may re-apply one-shot migrations or skip required ones.

**Required action:**

The ConfigMap `migrations-status` must be added to your backup and restore procedure.

### Versions ≥ v1.16.0

#### Pre-upgrade to versions ≥ v1.16.0

##### Nubus bug fix: LDAP storage class settings

**Target group:** Deployments that set explicit storage settings for `nubusLdapServerRun` which differ from those for `nubusLdapServerData`.

**Context**

Until now, the settings under `persistence.storages.nubusLdapServerRun` were ignored, and the settings from `persistence.storages.nubusLdapServerData` were applied instead.

Because PVC settings cannot be changed after a PVC has been created, the deployment settings and the actual PVC settings must be kept consistent.

There are two ways to achieve this:

1. Adjust the templated storage settings to match the existing PVCs.
2. Migrate the PVCs to match the templated storage settings.

**Required action: Align storage settings with existing PVCs**

Set the `size` and `storageClassName` under `nubusLdapServerRun` to the same values as those under `nubusLdapServerData`:

```yaml
persistence:
  storages:
    nubusLdapServerData:
      size: "1Gi"
      storageClassName: "myStorageClassName"
    nubusLdapServerRun:
      size: "1Gi"
      storageClassName: "myStorageClassName"
```

**Required action: Migrate PVCs to match storage settings**

> [!warning]
> Every primary and secondary LDAP Pod has its own affected PVC, so this action must be performed for each of them.

Migrate[^1] the `nubusLdapServerRun` PVC(s) to the currently defined storage settings, for example:

```yaml
persistence:
  storages:
    nubusLdapServerRun:
      size: "0.2Gi"
      storageClassName: "specialStorageClass"
```

### Versions ≥ v1.15.0

#### Pre-upgrade to versions ≥ v1.15.0

##### New Helmfile default: External mail services are no longer enabled by default

**Target group:** Deployments using the groupware module with support for external mail clients.

**Context:**

openDesk can expose several mail-related services (IMAPS and SMTP submission) for external clients. Previously
these were created by default; especially with service type "LoadBalancer" this meant they were exposed
automatically. They are now disabled by default and must be enabled explicitly.

**Required action**

If your deployment supports external mail clients, enable the services you need:

```yaml
functional:
  groupware:
    externalClients:
      exposeImaps: true
      exposeSubmission: true
      exposeSubmissions: true
```

##### New Helmfile default: Support for SeaweedFS as S3 backend

**Target group:** Deployments using the bundled service MinIO

**Context**

Since the maintenance for MinIO - the former only S3 storage backend supported
by openDesk - [has been discontinued](https://github.com/minio/minio),
openDesk now also supports and enables [SeaweedFS](https://seaweedfs.com/) for
its non-production installations per default (for production scenarios use an
externally managed S3 storage backend).

Starting from version v2.0.0 openDesk will not include MinIO in the Helmfile
deployment anymore. If you have been a user of the included MinIO S3 backend,
we encourage you to move to the new SeaweedFS S3 backend before the 2.0.0
release.

The enabled apps in `opendesk_main.yaml.gotmpl` before was:

```yaml
apps:
  minio:
    enabled: true
```

And now is:

```yaml
apps:
  minio:
    enabled: false
  seaweedfs:
    enabled: true
```

Furthermore, SeaweedFS's uses `objectstorage` as default hostname in oposition
to MinIO which is using `objectstore`:

```yaml
global:
  hosts:
    minioApi: "objectstore"
    minioConsole: "objectstore-ui"
    seaweedfs: "objectstorage"
    seaweedfsAdmin: "objectstorage-ui"
```

**Required action: Keeping MinIO as S3 storage backend**

If you want to keep MinIO, you need to set:

```yaml
apps:
  minio:
    enabled: true
  seaweedfs:
    enabled: false
```

**Optional action: Migrating to SeaweedFS as S3 storage backend**

See [Migrate from MinTO to SeaweedFS](./migrations-instructions/1.15.0-migrate-from-minio-to-seaweedfs.md)

#### Post-upgrade to versions ≥ v1.15.0

##### XWiki bug fix: LDAP group synchronization incomplete

**Target audience:** Deployments using XWiki with LDAP groups where some group memberships are not synchronized as expected.

**Required action**

To repair groups whose memberships are no longer properly synchronized to XWiki, run the following script:
[`./migrations-helper/1.15.0-xwiki-groupsync.java`](./migrations-helper/1.15.0-xwiki-groupsync.java)

*Prerequisites*

- Ensure your account has XWiki administrator permissions:
  - Permissions can be granted via IAM administration in the user's "openDesk" tab.
  - Note that permissions are synchronized to XWiki nightly, so changes may take up to 24 hours to take effect.
  - To verify that the permissions are active, open the waffle menu in XWiki and confirm that the "Wiki administration" option is available.
- Enable script execution for your account:
  - In XWiki, click your avatar to open your user profile.
  - Navigate to "Settings".
  - Set "User type" to "Advanced" (required to execute scripts).
  - Save the change.

*Running the script*

- Create a new XWiki page (it can be deleted once the cleanup is complete).
- Open the "Edit" dropdown and switch to the "Wiki" editor (not the default WYSIWYG editor).
- Paste the script into the editor and save the page.
- On the newly created page, click "Recreate the LDAP Groups Mapping" to start the analysis.
- A list of all recreated mappings will be displayed once the process completes.

##### XWiki bug fix: User account merge for uppercase usernames (Part 2)

**Target audience:** Deployments where usernames (login names) contain uppercase characters, XWiki is enabled, and users logged into XWiki before their accounts were pre-created by the nightly LDAP synchronization.

**Context**

XWiki receives user and account identity information through two mechanisms:
- **OIDC** – during a user's SSO-based login to XWiki
- **LDAP** – during nightly synchronization jobs

In earlier releases, when a username was provided via OIDC before the corresponding account had been pre-created by the nightly LDAP synchronization, duplicate accounts were created - one with mixed-case letters and one with all lowercase letters.

**Required action**

To identify and merge duplicate user accounts, run the following script:
[`./migrations-helper/1.15.0-Xwiki-usermerge.java`](./migrations-helper/1.15.0-Xwiki-usermerge.java)

*Prerequisites*

The same prerequisites as for the XWiki fix in the section above.

*Running the script*

- Create a new XWiki page (it can be deleted once the cleanup is complete).
- Open the "Edit" dropdown and switch to the "Wiki" editor (not the default WYSIWYG editor).
- Paste the script into the editor and save the page.
- On the newly created page, click "Show duplicate user accounts" to start the analysis.
- A list of "Duplicate user accounts" will be displayed.
- If duplicates are found, click "Replace and disable duplicate accounts" to merge them.
- For each merged account, the script outputs a message similar to: `Duplicate user account [XWiki.uppercase1] has been replaced by account [XWiki.UpperCase1] and disabled.`

### Versions ≥ v1.14.0

#### Pre-upgrade to versions ≥ v1.14.0

##### Updated Helmfile behaviour: Remove default MASTER_PASSWORD

**Target group:** All deployments that do not have set a `MASTER_PASSWORD` yet

**Context**

Default passwords are a common cause of security issues (see OWASP Top 10
[A07:2017](https://owasp.org/Top10/2021/A07_2021-Identification_and_Authentication_Failures/)
and [A02:2025](https://owasp.org/Top10/2025/A02_2025-Security_Misconfiguration/)).
For this reason the default master password has been removed from the openDesk
helmfile deployment. Setting the environment variable `MASTER_PASSWORD` is now
required and the deployment will fail if it has an empty value.

**Required action**

If you have been relying on the default master password, set a master password.
Note that due to limitations of helm, the `MASTER_PASSWORD` environment
variable has to be an non-empty value, even if all secrets have been replaced
by custom values.

##### Changed Helmfile structure: Custom OIDC clients and client scopes

**Target group:** Existing openDesk deployments OIDC client and/or client scope configurations in (at least) one of the following sections:
- `functional.authentication.oidc.clients`
- `functional.authentication.oidc.clientScopes`

The configuration is now using dicts instead of lists requiring to set an unique key for each entry, while the key itself can be freely chosen, it is best practise to have the key in line with the attribute values for `name` and `clientId` like in the following example:

The previous version:
```yaml
functional:
  authentication:
    oidc:
      clients:
        - name: "my-custom-oidc-client"
          clientId: "my-custom-oidc-client"
          protocol: "openid-connect"
          [..]
```

```yaml
functional:
  authentication:
    oidc:
      clients:
        opendesk-intercom:
          name: "my-custom-oidc-client"
          clientId: "my-custom-oidc-client"
          protocol: "openid-connect"
          [..]
```

##### Changed Helmfile structure: Single-sign on federation with upstream IdPs

**Target group:** Existing openDesk deployments with configured IdP federation under `functional.authentication.ssoFederation`.

**Context**

In response to customer demand for configuring more than one upstream IdP for SSO federation, the configuration under `functional.authentication.ssoFederation` has been restructured to support multiple IdP definitions.

**Required action**

Overview:

1. IdP configurations must now be defined as entries in the dict under `functional.authentication.ssoFederation.idps`.
2. Enforcing login via an upstream IdP is no longer a boolean toggle — you must explicitly reference the dict key of the IdP to enforce login with.

To minimize the impact of this change on existing deployments, use `legacy-single-idp-config` as the dict key for your existing IdP. This preserves the IdP's internal identifier, keeping the OIDC URLs configured in the upstream IdP stable.

If you currently enforce login via the upstream IdP (so that the openDesk login dialog is skipped and users are redirected directly to the federated IdP), also set `enforceFederatedLogin` to `legacy-single-idp-config`.

The previous version:
```yaml
functional:
  authentication:
    ssoFederation:
      enabled: true
      enforceFederatedLogin: false
      name: "My upstream IdP"
      idpDetails:
        providerId: "oidc"
        [..]
```

Becomes:

```yaml
functional:
  authentication:
    ssoFederation:
      enabled: true
      # When you enforce you SSO federation, otherwise keep it empty to `~`
      enforceFederatedLogin: "legacy-single-idp-config"
      idps:
        # The dict key identifying the IdP, set it to `legacy-single-idp-config` to avoid changes of OIDC URLs
        legacy-single-idp-config:
          name: "My upstream IdP"
          idpDetails:
            providerId: "oidc"
            [..]
```

#### Post-upgrade to versions ≥ v1.14.0

##### Potential restart: OX Connector may get into crash loop

**Target group:** All deployments using OX App Suite

**Context:** After upgrade deployments, the OX Connector Pod may enter a CrashLoopBackOff state.

**Required action**

- Monitor the OX Connector Pod once the upgrade deployment has completed.
- If the pod is stuck in CrashLoopBackOff, delete it manually to trigger a fresh restart.

### Versions ≥ v1.13.0

#### Pre-upgrade to versions ≥ v1.13.0

##### New Helmfile default: Support for Ingress controller `haproxy-ingress.github.io`

**Target group:** All deployments

**Context**

Due to the widely recognized [discontinuation of `ingress-nginx`](https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/) - the former only Ingress controller supported by openDesk - openDesk now also supports [`haproxy-ingress.github.io`](https://haproxy-ingress.github.io/).

While you can decide which of these two Ingress controllers you want to operate openDesk with, we encourage the move to the new HA-Proxy controller, therefore we changed some defaults.

The `ingress.yaml.gotmpl` before was:

```yaml
ingress:
  ingressClassName: "nginx"
```

and now its

```yaml
ingress:
  ingressClassName: "haproxy"
  controller: "haproxy"
```

**Required action**

1. Remove legacy Ingress object:

```shell
kubectl -n <NAMESPACE> delete ingress opendesk-static-files
```

2. When you stay with nginx you need to set

```yaml
ingress:
  ingressClassName: "nginx" # or an alternative value you already have set here for you existing deployment
  controller: "nginx"
```

When going with `haproxy-ingress.github.io` and the `ingressClassName` within your deployment is not `haproxy` please ensure you modify the setting accordingly. Use `kubectl get ingressclass` to check the names of your Ingress controller(s).

##### Updated Helmfile options: New ingress additional annotations

**Target group:** Deployments using additional annotations for Nubus or OX App Suite Ingress resources.

**Required action**

**For Nubus**, the following Ingress annotations options have been removed:

```yaml
annotations:
  nubusPortalFrontend:
    ingressIngress: ~
    ingressRewrites: ~
    ingressRedirects: ~
```

They have been replaced with a single annotation option:

```yaml
annotations:
  nubusPortalFrontend:
    ingress: ~
```

**For OX App Suite**, a new Ingress resource is now available that supports additional annotations:

```yaml
annotations:
  openxchangeAppsuiteIngress:
    coreUiApiRoute: ~
```

### Versions ≥ v1.12.0

#### Pre-upgrade to versions ≥ v1.12.0

##### New application default: Keycloak imports users to its own database

**Target group:** All deployments that were initially installed with a release **earlier than openDesk 1.8.0**.

**Context**

Starting with openDesk 1.8.0, the IAM's handling of users in the identity provider component Keycloak was changed to the suppliers upstream default for new installations.

Now the users are imported from the LDAP into the Keycloak database (and kept in sync) instead of just creating shadow user accounts in Keycloak. This is especially important when IdP federation is configured, and it is expected that backchannel logout from the upstream IdP to be propagated correctly into openDesk.

With openDesk 1.12.0, this import behavior became the default also for existing installations. However, enabling user import on systems that were initially installed before 1.8.0 will lead to the following side effects:

- 2FA reset required: All users with two-factor authentication enabled must reconfigure their second factor.
- OIDC user duplication risk: Externally integrated OIDC clients may detect duplicate users if they rely on Keycloak’s default internal user identifiers.
To avoid this issue, clients should use the `opendesk_useruuid` OIDC claim as the stable user identifier.

This behavior has been corrected in openDesk 1.12.1 by introducing the following configuration option in `technical.yaml.gotmpl` which keeps the existing default instead of enforcing the import to be enabled.

Please refer to the YAML file for detailed documentation of this setting:

```yaml
technical:
  nubus:
    keycloak:
      ldapFederation:
        importUsers: ~
```

**Required action**

To avoid the aforementioned issues, directly upgrade to openDesk v1.12.1.

If you are not affected by those issues or know how to handle them, you should set the `importUsers` option to `true` to align with the openDesk standard configuration that is based from the Supplier supported standard for Nubus.

```yaml
technical:
  nubus:
    keycloak:
      ldapFederation:
        importUsers: true
```

##### Replace Helm chart: Upgrade to upstream Jitsi 2.x Helm chart

**Target group:** All deployments that have Jitsi installed.

The new upstream Jitsi Helm chart requires manual uninstall before upgrading to openDesk v1.12.x.

```shell
helm uninstall -n <your_namespace> jitsi
```

##### Fixed Helmfile templating: StorageClassNames for Nubus, OpenProject and OX-Connector

**Target group:** All openDesk deployments.

**Context**

The for following Persistant Volumes Claims the storage class attributes were not templated causing the related PVCs to fall back to the Helm Chart's default for size and to the cluster's default for the name:

| Component    | PVC name                                  | storageClassName | size | With 1.12.0 set in                             | Migration required    |
| ------------ | ----------------------------------------- | ---------------- | ---- | ---------------------------------------------- | --------------------- |
| Nubus        | `data-ums-provisioning-udm-listener-0`    | yes              | -    | `persistence.storages.nubusUdmListener.*`      | yes                   |
|              | `nats-data-ums-provisioning-nats-0`       | yes              | -    | `persistence.storages.nubusProvisioningNats.*` | yes                   |
|              | `shared-run-ums-ldap-server-primary-0`    | -                | yes  | `persistence.storages.nubusLdapServerRun.*`    | no (with 1Gi default) |
| OX-Connector | `ox-connector-appcenter-ox-connector-0`   | yes              |      | `persistence.storages.oxConnector.*`           | yes                   |
|              | `ox-connector-ox-contexts-ox-connector-0` | yes              |      | same values as above                           | yes                   |
| OpenProject  | `openproject-*-tmp`                       | yes              | yes  | `persistence.storages.openprojectTmp.*`        | no (ephemeral)        |

While the OpenProject ones are ephemeral temporary volumes, only used because [K8s does not support the sticky-bit option on emptyDirs](https://github.com/kubernetes/kubernetes/issues/110835) yet, the other PVCs will not accept patching of the newly templated attributes and require migration.

**Required action**

As an operator you will know how to run an update migration for existing PVCs to change e.g. its storageClassName
or size[^1]. As this still might not come handy during an upgrade and to allow independend scheduling of the task,
there is an alternative at least until openDesk 2.0:
Setting the environment variable `OPENDESK_1_12_0_SKIP_PVC_MIGRATION` to any non empty value
will trigger Helm post renderer scripts that remove the newly added attributes again.

##### New Helmfile default: Postfix SMTP(D) SASL TLS security options

**Target group:** All openDesk deployments using an external SMTP relay that does not support
[Postfix's default `smtp_sasl_tls_security_options`](https://www.postfix.org/postconf.5.html#smtp_sasl_tls_security_options)
or deployments using external mail clients in case the offered security options should be limited.

Before 1.12.0, the SMTP(D) SASL TLS security options were defaulting to the non TLS options (Postfix's default behavior).
In some cases, users need a more fine grained approach, e.g. allowing plaintext authentication over a TLS connection.

> [!warning]
> Please check the supported SASL security options of your mail relay and adjust your deployment accordingly to
> prevent the disruption of mail delivery.

To fall back to the behavior of openDesk < v1.12.0 (non TLS option are used), set the following in
`smtp.yaml.gotmpl`

``` yaml
smtp:
  security:
    smtpdSASLTLSSecurityOptions:
      - "$smtpd_sasl_security_options"
    smtpSASLTLSSecurityOptions:
      - "$smtp_sasl_security_options"
```

To set specific options consult the official Postfix documentation for
[smtpd](https://www.postfix.org/postconf.5.html#smtpd_sasl_tls_security_options) or
[smtp](https://www.postfix.org/postconf.5.html#smtp_sasl_tls_security_options)
and set the string options via the yaml array notation like this:

``` yaml
smtp:
  security:
    smtpdSASLTLSSecurityOptions:
      - "noanonymous"
    smtpSASLTLSSecurityOptions:
      - "noanonymous"
```

#### Post-upgrade to versions ≥ v1.12.0

##### Wiki bug fix: User account merge for uppercase usernames

**Target audience:** Deployments where user accounts contain uppercase characters in usernames (login names) and XWiki is enabled.

**Context**

XWiki receives user and account identity information via two mechanisms:
- **OIDC** – during a user's SSO-based login to XWiki
- **LDAP** – during nightly synchronization jobs

In earlier releases, usernames provided via OIDC were automatically normalized to lowercase, while usernames synchronized from LDAP were not. This mismatch could result in duplicate user accounts in XWiki that differ only by letter case.

**Required action**

To identify and merge duplicate user accounts, run the following script:
[`./migrations-helper/1.12.0-Xwiki-usermerge.java`](./migrations-helper/1.12.0-Xwiki-usermerge.java)

*Prerequisites*

- You need a user account with XWiki administrator permissions.
- These permissions can be granted via IAM administration in the user's "openDesk" tab.
- Note that permissions are currently synchronized to XWiki nightly.
- Verify that the permissions are active by opening the waffle menu in XWiki and checking for the "Wiki administration" option.
- In XWiki, click your avatar to open your user profile:
  - Navigate to "Settings"
  - Set "User type" to "Advanced" (required to execute scripts)
  - Save the change

*Running the script*

- Create a new XWiki page (it can be deleted after the cleanup is complete).
- Use the "Edit" dropdown and switch to the "Wiki" editor (not the default WYSIWYG editor).
- Paste the script into the editor and save the page.
- On the newly created page, click "Show duplicate user accounts" to start the analysis.
- A list of "Duplicate user accounts" will be displayed.
- If duplicates are found, click "Replace and disable duplicate accounts" to merge them.
- For each merged account, the script outputs a message similar to: `Duplicate user account [XWiki.uppercase1] has been replaced by account [XWiki.UpperCase1] and disabled.`

##### IAM new feature: External routing for mail domains

**Target group:** Deployments with groupware enabled that also manage user accounts in openDesk with primary mail addresses set that should not be delivered locally (aka "guest users").

**Context**

All domains used in a user's primary email address must be configured in the IAM. This can be done at deployment level, for example:

```yaml
global:
  ## Define host
  domain: {{ env "DOMAIN" | default "opendesk.internal" | quote }}
  ## Define mail host
  ## If this is unset the "domain" value above should be used in all references
  mailDomain: {{ env "MAIL_DOMAIN" | quote }}
  ## Optional list of additional mail domains
  additionalMailDomains: []
```

Mail domains can also be created via the UDM REST API. This API is used by the [openDesk User Importer](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import), which automatically creates mail domain objects when required, for example, when a user's primary email address references a domain that has not yet been configured.

When creating accounts for external or guest users in the IAM, email addressed to their domains must not be routed internally if openDesk groupware is enabled. To support this, mail domains now provide the option `opendeskMailDomainRelayExternal`. When enabled, email for these domains is relayed externally instead of being delivered to the openDesk groupware.

The user importer has been extended accordingly and now supports the option `--create_maildomains_external True`.

**Required action**

If you have configured mail domains in the openDesk IAM that should be routed or relayed externally while openDesk groupware is enabled, ensure that `opendeskMailDomainRelayExternal` is set to `true` for all affected domains.

> [!note]
> The manual checks and actions for the openDesk releases before v1.12.0 have moved to
> [`migrations-manual-archive.md`](./migrations-manual-archive.md).

[^1]: For PVC migrations in development we use the the [`migrate_pvc.py`](./migrations-helper/migrate_pvc.py) script. It comes without any warranty.
