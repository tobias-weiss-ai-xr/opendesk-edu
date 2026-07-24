<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# Automated migrations

> [!important]
> This document covers the **automated** migrations, which openDesk runs on its own as part of
> every deployment and which reduce the need for manual intervention. They require specific
> openDesk versions to be installed, which effectively enforces a defined upgrade path.
>
> - For the **manual** checks and actions, and for the overview of the mandatory upgrade
>   path, see [`migrations-manual.md`](./migrations-manual.md).
> - For information about automated migrations before 1.17.0 see [`migrations-automated-archive.md`](./migrations-automated-archive.md).

> [!important]
> Depending on how you deploy openDesk (e.g. with ArgoCD), placing the two migration jobs is up to you:
> `migrations-pre` has to run before every other app, `migrations-post` after all of them.

<!-- TOC -->
* [Automated migrations](#automated-migrations)
  * [Related components and artifacts](#related-components-and-artifacts)
    * [`releaseVersion`](#releaseversion)
    * [`actions.pre` and `actions.post`](#actionspre-and-actionspost)
      * [`versions`](#versions)
      * [`tag` and `runMode`](#tag-and-runmode)
    * [`actionsSkip.pre` and `actionsSkip.post`](#actionsskippre-and-actionsskippost)
    * [`secretFiles`](#secretfiles)
    * [`objectStore`](#objectstore)
  * [Automated migrations overview](#automated-migrations-overview)
  * [Actions](#actions)
    * [`ox_functional_accounts_export`](#ox_functional_accounts_export)
    * [`workload_scale`](#workload_scale)
    * [`ldap_entryuuid_to_object_identifier`](#ldap_entryuuid_to_object_identifier)
    * [`ox_names_to_object_identifier`](#ox_names_to_object_identifier)
    * [`provisioning_drop_subscriptions`](#provisioning_drop_subscriptions)
    * [`ox_connector_restart`](#ox_connector_restart)
    * [`ox_shared_accounts_import`](#ox_shared_accounts_import)
    * [`flush_intercom_sessions`](#flush_intercom_sessions)
  * [Development](#development)
<!-- TOC -->

## Related components and artifacts

openDesk comes with two upgrade steps as part of the deployment; they can be found in the folder [/helmfile/apps](../helmfile/apps/) along with all other components:

- `migrations-pre`: Is the very first app that gets deployed.
- `migrations-post`: Is the last app that gets deployed.

Both migrations must be deployed exclusively at their first/last position and not parallel with other components.

The status of the upgrade migrations is tracked in the ConfigMap `migrations-status`, more details can be found in the [README.md of the related container image](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/README.md).

With openDesk 1.17.0 the migrations that are triggered are defined in the shared migrations values file
[`migrations.yaml.gotmpl`](../helmfile/shared/migrations.yaml.gotmpl), which is the basis for both the
`migrations-pre` and the `migrations-post`.

The file declares, below the key `migrations`:

### `releaseVersion`

The openDesk release currently being deployed, taken from `global.systemInformation.releaseVersion`.

### `actions.pre` and `actions.post`

The actions to be executed before (`migrations-pre`) respectively after (`migrations-post`) the deployment of
all other components, each in the order listed. An action is

```yaml
id: <action-id>
tag: <openDesk's half of the footprint>
runMode: <the other half of the footprint>
versions:
  minimum: <oldest supported release series>
  from: <window start series>
  to: <window end series>
config: <parameters>
```

- `id` selects the action module shipped in the migrations image.
- `config` carries its non-secret parameters.

Actions are only declared when the components they work on are actually installed, gated by the same conditions as
the corresponding releases.

#### `versions`

Every action states for itself which installed releases it applies to, so the answer is where the action is
declared rather than in one range covering the whole migration:

- `minimum` is the oldest openDesk release the action supports. When the release that was migrated successfully
last - recorded in the ConfigMap `migrations-status`, see
[Related components and artifacts](#related-components-and-artifacts) - is older than that, the migration stops
with an **error** rather than skipping quietly: an upgrade path that was never supported must not look like a
successful run. This is what enforces the
[mandatory upgrade path](./migrations-manual.md#overview-and-mandatory-upgrade-path).
- `from` and `to` are the window of last-migrated releases the action actually runs for. Outside it the action is
not this deployment's business and is skipped, which is logged.

Each of the three names a **release series**, at whatever precision it is written in: `v1` is every release of that
major, `v1.17` every release of that minor, `v1.17.2` that one release. A lower bound starts at the beginning of its
series (`from: v1.15` starts at v1.15.0), an upper bound includes all of it (`to: v1.17` still covers v1.17.3). So
`minimum: v1.15, from: v1.15, to: v1.17` is what a migration shipped with v1.18 declares, and it keeps meaning the
same thing when v1.17.3 is published afterwards. Write a patch level only when the action really is about one single
release - otherwise the declaration would depend on a patch number nobody could know when the action was written.

All three keys are **required**. All declarations of both stages are validated before the first action runs, and
any problem fails the migration without executing anything: an entry without an `id`, a missing or misspelled
`versions` key, a value that is not a version, a `from` whose series starts below `minimum`, a `to` whose series
ends before `from` begins, or a deployment whose last migrated release is older than a declared `minimum`. All
problems are reported at once.

#### `tag` and `runMode`

Both are optional, and the **`tag` decides whether an action runs only once**:

- Without a tag the action runs whenever a release declares it and its window matches - work that is meant to
happen on every migration run. A `runMode` on such an action is recorded for documentation but gates nothing,
so giving every action a run mode does not turn re-runnable ones into run-once ones.
- With a tag, the action's **footprint** - the pair of `tag` and `runMode` - is recorded in the `history` of the
ConfigMap `migrations-status`, and an action whose footprint is already recorded is skipped, on a redeployment
of the same release as well as in any later release.

The two halves of the footprint differ in who owns them:

- `tag` is openDesk's own statement of which piece of work this is, usually the release it belongs to (e.g.
`v1.17.0`). It is part of the migration definition and not configurable, and its presence is what says that this
work happens once.
- `runMode` states in which mode the work was performed, and openDesk declares `"apply"` for every action that
changes data. It is part of the migration definition as well and not configurable: the actions of a release
bring a deployment in line with that release, and the components deployed after them rely on what they wrote,
so whether an action applies is not a per-deployment decision - opting out of it entirely, through
`actionsSkip`, is. Giving a tagged action a mode it never had makes it run once more, which is how a piece of
work is repeated without editing a tag openDesk ships or the recorded history.

### `actionsSkip.pre` and `actionsSkip.post`

The actions to opt out of. In contrast to everything above, this is not part of the migration's definition but
a per-deployment setting, configurable in [`migrations.yaml.gotmpl`](../helmfile/environments/default/migrations.yaml.gotmpl).

It mirrors `actions`: An entry names the stage, the `id` and the `tag` of the action it skips, and has to match both
exactly - including the absence of a tag. The `runMode` is deliberately not part of it: it does not say *which* piece
of work this is, so requiring it would only add a value that has to be copied correctly.

What happens when an entry matches nothing depends on which of the two mistakes it is:

- It names an action **this stage declares under another tag**. That is a mistyped opt-out, and it fails the migration
before any action runs - letting it pass would run exactly the action you excluded. It is reported together with any
other problem in the declarations.
- It names an id **the stage does not declare at all**. That is what an opt-out becomes once the release it was
written for is behind you, so it is only logged as a warning.

See [Skip single actions of the automated migrations](./updates.md#skip-single-actions-of-the-automated-migrations) in `updates.md`.

### `secretFiles`

The credentials the actions need, mounted from existing Kubernetes Secrets as files, so that
no credential is passed via environment variables or duplicated into a new Secret.

### `objectStore`

The object store the two stages hand work over in. The stages are separate Jobs, so an action that has to read
something while the old release is still there and act on it once the new one is deployed is *two* actions, and the
first leaves what it worked out as an object for the second to pick up - see
[`ox_functional_accounts_export`](#ox_functional_accounts_export), which is what needed it first.

It is declared once, below `migrations`, and not per action: which object store a deployment has is a fact about
the deployment and the same answer for every action, so declaring it per action would repeat it and make it
possible to tell two actions different things about the same store. What stays with an action is *what* it puts
there, its object key.

openDesk provisions the `migrations` bucket and its identity for exactly this (`objectstores.migrations`), and the
values below are derived from it; the identity's secret key is not declared here but mounted through
[`secretFiles`](#secretfiles) as `objectstore-migrations-secret-key`. Only actions that hand work over read any of
it, and they fail naming what is missing, so a deployment running none of them needs none of it.

```yaml
objectStore:
  endpoint: "<the deployment's object store>"
  bucket: "migrations"
  username: "migration_user"
  region: "eu-west-1"
  port: 443
  useSSL: true
  pathStyle: true
  requestTimeoutSeconds: 30
  # The store is reached under the endpoint its other consumers use, which is the deployment's
  # public one. Both are configurable in `migrations.objectStore` of your environment.
  verifySSL: true
  caBundle: ""
```

Two of these are yours to set, in `migrations.objectStore`: `caBundle` is the path of a mounted CA certificate, for
a deployment whose object store certificate is issued by a CA the migrations image does not know (mount it through
the migration releases' `extraVolumes`/`extraVolumeMounts`), and `verifySSL` exists for test deployments with a
self-signed certificate - switching it off means the handover between the two stages travels over a connection
nothing authenticates.

## Automated migrations overview

The following table lists the actions the openDesk releases declare, in the order they are executed.

- *Optional context*: What the call is applied to, where the action itself is generic.
- *Declared
with*: The release whose migration definition added the call. It is also the action's `tag`.
- *Dropped with*: The release whose definition
removed it again.
- *Runs*: `Once` (an action carrying a `tag`, so its footprint is recorded and it is not executed again) or
`Always` (on every migration run, an action declared without a `tag`). Every action applies its change.
- *Upgrades covered*: The action's `versions` window, so the range of installed releases the call is executed for.

| Action                                                                        | Optional context | Stage             | Declared with | Dropped with | Runs | Upgrades covered |
| ----------------------------------------------------------------------------- | ---------------- | ----------------- | ------------- | ------------ | ---- | ---------------- |
| [`workload_scale`](#workload_scale)                                           | OX Connector     | `migrations-pre`  | v1.18.0       | -            | Once | v1.15 - v1.17    |
| [`ox_functional_accounts_export`](#ox_functional_accounts_export)             | -                | `migrations-pre`  | v1.18.0       | -            | Once | v1.15 - v1.17    |
| [`ldap_entryuuid_to_object_identifier`](#ldap_entryuuid_to_object_identifier) | -                | `migrations-pre`  | v1.18.0       | -            | Once | v1.15 - v1.17    |
| [`ox_names_to_object_identifier`](#ox_names_to_object_identifier)             | -                | `migrations-pre`  | v1.18.0       | -            | Once | v1.15 - v1.17    |
| [`provisioning_drop_subscriptions`](#provisioning_drop_subscriptions)         | -                | `migrations-pre`  | v1.18.0       | -            | Once | v1.15 - v1.17    |
| [`ox_shared_accounts_import`](#ox_shared_accounts_import)                     | -                | `migrations-post` | v1.18.0       | -            | Once | v1.15 - v1.17    |
| [`flush_intercom_sessions`](#flush_intercom_sessions)                         | -                | `migrations-post` | v1.18.0       | -            | Once | v1.15 - v1.17    |
| [`ox_connector_restart`](#ox_connector_restart)                               | -                | `migrations-post` | v1.17.0       | v1.18.0      | Once | v1.15 - v1.16    |

> [!note]
> Action are gated by their respective component prerequiste(s), e.g. the `ox_connector_restart` should only fire when:
> - Nubus and
> - OX App Suite
> are installed.

## Actions

The actions listed here are the ones shipped as modules in the
[openDesk Migrations image](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/-/tree/main/odmigs-python/odmigs_actions). They are the library the migrations `actions` section in
[shared migrations values file](../helmfile/shared/migrations.yaml.gotmpl) can draw from.

Whether an action runs once or on every deployment is not a property of the action itself but of its
declaration: An action declared with a `tag` runs once, an action declared without one runs whenever a release
declares it.

The permissions the actions need are granted in the
[`role.yaml`](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/main/charts/opendesk-migrations/templates/role.yaml)
of the migrations Helm chart, where a comment names the action each rule belongs to.

### `ox_functional_accounts_export`

**Part 1 of 2** of the migration from the IAM's Functional Accounts (`oxmail/functional_account`) to the Shared
Accounts (`oxmail/shared_account`) that replace them. It writes down what each Functional Account is, removes its
counterpart in OX App Suite through the [SOAP API](./architecture/apis.md#soap-api), deletes the object itself
through the [UDM REST API](./architecture/apis.md#udm-rest-api) and reads the OX contexts back to confirm that
nothing is left. Later, in `migrations-post`, [`ox_shared_accounts_import`](#ox_shared_accounts_import) creates the
Shared Accounts from what was written down.

It changes both sides itself and does not involve the OX Connector in either, which is why
[`workload_scale`](#workload_scale) has to be declared before it.

The two stages hand over in an object in the deployment's `migrations` bucket (`objectstores.migrations`),
`ox-functional-accounts.yaml` by default and named by `handover.objectKey` in both declarations. It holds
everything part 2 needs. It is written *before* anything is removed or deleted, and read back before the action
goes on, so a run that dies in between cannot leave accounts that are gone and described nowhere; afterwards it and
the Job's log are the only places this information still exists.

In the object store and not in a ConfigMap, because this is one record of roughly 400 bytes per Functional Account:
a ConfigMap holds 1 MiB, so a deployment with a few thousand of them could not write its handover at all - and it
would fail in `migrations-pre`, in exactly the installations where carrying the migration out by hand is least
feasible. That the store answers and holds the bucket is established while the action is still planning, so a
deployment that cannot hand over fails before anything is deleted, on a dry run as well. Both stages mount the
bucket identity's credentials as `objectstore-migrations-secret-key`.

Which object store that is is configured once for the whole migration, in `migrations.objectStore`, and not per
action - see [`objectStore`](#objectstore). What the action itself declares is only the object key it writes under,
`handover.objectKey`.

To read a handover by hand, with the credentials of the `migrations` object store identity:

```bash
mc alias set odmigs https://<endpoint> <username> <secretKey>
mc cat odmigs/migrations/ox-functional-accounts.yaml
```

It reports every account it records, every user it links and every user it cannot link (no groupware account,
`isOxUser` is not set), and per OX context which mailboxes it removes and how many user entries each of them had,
into the log of the `migrations-pre` Job. Secondary accounts a context holds that belong to none of the exported
Functional Accounts are reported as well and left alone.

Every account has to be one part 2 can name. The two modules spell names differently - see the name paragraph of
[`ox_shared_accounts_import`](#ox_shared_accounts_import) - and a Functional Account whose name leaves nothing to
build on, such as one consisting only of digits or only of punctuation, is one no Shared Account can be created
for. The action checks every account against that rule before it deletes anything, and stops naming the account if
one fails, so rename it in the IAM and run the stage again. The check runs in the planning phase and therefore on a
dry run as well.

A run that died part way through is not continued by the next one: The handover is written before anything is
changed, so finding one already there *while Functional Accounts are still in the IAM* stops the action. Sort such
a deployment out by hand - the Functional Accounts still in the IAM are the directory side, and the OX App Suite
side is read and cleaned up per context with `listsecondaryaccount` and `deletesecondaryaccount`. Do not delete the
handover while doing so: It is the only description of the accounts that are already gone. What the action does
guarantee is that it never rewrites a handover with fewer accounts than it holds, because part 2 creates the Shared
Accounts from what the handover says.

The one case it does finish is a handover with no Functional Account left in the IAM. Then the earlier run made
every change it had to make, and only the final read-back against OX App Suite may not have happened - so the
action repeats that read and ends the way it would have ended, without changing anything. A rerun after a crash at
that point therefore still reports mailboxes that are left in OX App Suite, instead of finding an empty IAM and
succeeding.

> [!warning]
> It applies, and there is no mode in which it only reports: the Functional Accounts of the release being replaced
> have no counterpart in the release that follows, so the work has to happen in the deployment that replaces it.
>
> To migrate the accounts yourself instead, opt out through `actionsSkip` - of **both** actions, so in `pre` *and*
> in `post`, as opting out of only one leaves the migration half applied.

```yaml
- id: "ox_functional_accounts_export"
  runMode: "apply"
  config:
    dryRun: false
    udm:
      url: "http://ums-udm-rest-api:9979/univention/udm/"
      username: "cn=admin"
      requestTimeoutSeconds: 30
    ldap:
      baseDn: "dc=swp-ldap,dc=internal"
    handover:
      objectKey: "ox-functional-accounts.yaml"
    oxAppSuite:
      context: 1
      soapUrl: "http://open-xchange-core-mw-admin.<namespace>.svc.<cluster domain>"
      username: "admin"
      requestTimeoutSeconds: 60
```

Its credentials are mounted through the stage's [`secretFiles`](#secretfiles). The first two belong to releases a
*fresh* installation deploys around this Job, so they are optional - a fresh installation runs no migration
actions, so the action reading them is not dispatched in the one situation where they may be absent. The third is
the identity of the `migrations` bucket the handover is written to, which belongs to the `opendesk-secrets`
release this Job already depends on:

```yaml
secretFiles:
  - name: "udm-admin-password"
    secret:
      name: "ums-ldap-server-admin"
      key: "password"
      optional: true
  - name: "ox-master-password"
    secret:
      name: "opendesk-ox-admin-password"
      key: "password"
      optional: true
  - name: "objectstore-migrations-secret-key"
    secret:
      name: "objectstore-migrations-secret-key"
      key: "secretKey"
      optional: true
```

### `workload_scale`

Scales the workload named in `workload.name` - a `StatefulSet` or a `Deployment`, as stated in `workload.kind` -
to `workload.replicas`. It performs one half of a restart
and hands the other half to whoever is responsible for it - which, declared in `migrations-pre`, is the deployment
that follows and usually contains a change for the given component to ensure the release's manifests is applied and
the declared replica count is restored.

Scaling **down** waits for the workload's pods to be gone before the action returns, and fails if they are still
there after `workload.timeoutSeconds`.

Scaling **up** is not waited for.

```yaml
- id: "workload_scale"
  config:
    workload:
      kind: "StatefulSet"
      name: "ox-connector"
      replicas: 0
      timeoutSeconds: 300
```

`kind`, `name` and `replicas` are required - a default for any of them would scale something, or scale to
something, that the declaration did not ask for. `timeoutSeconds` defaults to 300 and is a property of how long
the component takes to stop rather than of what is to be scaled. A workload that is not down by then is not slow,
it is stuck, and the action fails naming the pods that are left rather than letting the stage continue.

### `ldap_entryuuid_to_object_identifier`

Gives **every object of the directory that carries a `univentionObjectIdentifier`** its own `entryUUID` as that
identifier, so that both identifiers of an object are the same value.

The action is the one place in the migrations that writes the directory **directly**, with `ldapmodify` in the
LDAP Pod instead of through the [UDM REST API](./architecture/apis.md#udm-rest-api) every other IAM change goes
through. UDM declares `univentionObjectIdentifier` as not changeable - it can be set when an object is created and
never again - so below UDM is the only place the value can be corrected at all. The modification is a normal LDAP
write and reaches the provisioning like any other. Objects whose identifiers already match are left alone, which
is what makes a repeated run report what is left to do; afterwards the directory is read back and the action fails
when anything still carries a different identifier.

```yaml
- id: "ldap_entryuuid_to_object_identifier"
  runMode: "apply"
  config:
    dryRun: false
    ldap:
      pod: "ums-ldap-server-primary-0"
      container: "main"
      baseDn: "dc=swp-ldap,dc=internal"
```

> [!warning]
> This action and [`ox_names_to_object_identifier`](#ox_names_to_object_identifier) belong together, and applying
> only one of the two leaves a state this release cannot work with. Both apply, and neither offers a mode in which
> it only reports: the OX Connector deployed right after them addresses its objects by the identifier they write.
> Each logs per object what it changes - every object with its old and its new identifier, every OX App Suite
> account and group with its old and its new name - into the log of the `migrations-pre` Job, which is also the
> only record of the previous values once they ran.
>
> The action is bound to a single execution by its tag, and that matters beyond the usual reason: a Shared Account
> carries the `entryUUID` of the Functional Account it replaced as its identifier, which is what keeps it pointing
> at the existing mailbox. During the v1.18.0 upgrade none exists yet - they are created in `migrations-post` -
> but running this action again afterwards would give them their own `entryUUID`, and with it an empty mailbox.

### `ox_names_to_object_identifier`

Renames the user accounts and groups in OX App Suite from the name the IAM knows them by - a user's `uid`,
a group's `cn` - to the IAM's `univentionObjectIdentifier`, through the provisioning (SOAP) API.

It is the second half of the switch described above: The Connector derives the object it provisions from the IAM
object, and the v1.18.0 upgrade resubscribes it and replays every object once. It therefore looks up every account
and every group under its `univentionObjectIdentifier` and, finding none, would create a second one next to the
one in use. It runs after
[`ldap_entryuuid_to_object_identifier`](#ldap_entryuuid_to_object_identifier), because the identifier it writes
into OX App Suite is the one that action puts on the IAM objects.

All OX contexts found in the IAM are addressed. Objects keep their numeric OX id, so everything referencing them -
folder and item permissions, task participants, resource booking rights, deputy rules, Shared Account permissions -
stays valid.

The context administrator (`oxadmin`) and the standard group (`users`) belong to OX App Suite rather than to the
IAM and are never renamed. They are held out by id, asked of OX App Suite itself, so an IAM object carrying one of
those names cannot match them.

Objects whose name is neither an IAM name nor the identifier of one are reported and left alone: the IAM does not
know them, and the Connector will not recognize them either. An object already carrying the identifier of an IAM
object is done, which is what makes the action resumable - it works out what is left from the state it finds.
Every rename is verified against its context afterwards.

```yaml
- id: "ox_names_to_object_identifier"
  runMode: "apply"
  config:
    dryRun: false
    ldap:
      pod: "ums-ldap-server-primary-0"
      container: "main"
      baseDn: "dc=swp-ldap,dc=internal"
    oxAppSuite:
      soapUrl: "http://open-xchange-core-mw-admin.<namespace>.svc.cluster.local"
      username: "admin"
      requestTimeoutSeconds: 60
```

Its credential is mounted through the stage's [`secretFiles`](#secretfiles), the same
`ox-master-password` [`ox_functional_accounts_export`](#ox_functional_accounts_export) uses.

### `provisioning_drop_subscriptions`

Drops the Provisioning Service subscriptions named in `subscriptions`, so that the components register them again
with the topics the current release declares.

A component receives the directory changes its subscription lists as realm/topic pairs, registered once when it
is first deployed. That list cannot be changed: the Provisioning API can create, read and delete a subscription
and nothing else, so a release that adds a topic makes the registration job answer `409 Conflict` and fail,
leaving the component subscribed to its old topics - and silently not receiving the objects the new release is
about. The OX-Connector and the Shared Accounts are the case this exists for: without `oxmail/shared_account` in
its subscription, the Connector never learns that they exist and
[`ox_shared_accounts_import`](#ox_shared_accounts_import) has no effect in OX App Suite.

It runs in `migrations-pre` for that ordering: the components are deployed afterwards, so their registration
finds nothing and creates the subscription as the release declares it. It does not recreate the subscription
itself - that is the deployment's job, and it holds the component's own credentials.

The action knows nothing about *which* topics a consumer needs, on purpose: those stay declared once, in the
consumer's registration in [`values-nubus.yaml.gotmpl`](../helmfile/apps/nubus/values-nubus.yaml.gotmpl). Naming
a consumer here says "this release changes what it receives", nothing more. A migration holding its own copy of
the topics would, once the two drifted apart, drop a subscription on every deployment that the registration then
recreates without the topic the migration was waiting for.

A dropped subscription loses whatever is still queued for it, and the registration that recreates it asks for a
prefill, so **expect the load of a full re-provisioning for every consumer listed, once** - see
[Full re-provisioning of all objects on upgrade](./migrations-manual.md#full-re-provisioning-of-all-objects-on-upgrade).
The `tag` is what keeps it to a single deployment.

```yaml
- id: "provisioning_drop_subscriptions"
  config:
    provisioning:
      url: "http://ums-provisioning-api/v1"
      username: "admin"
      requestTimeoutSeconds: 30
    subscriptions:
      - "ox-connector"
```

> [!note]
> Its credential (`ums-provisioning-api-admin`) belongs to the Nubus release, which a *fresh* installation
> deploys after `migrations-pre`. It is therefore mounted as an optional Secret, so that the job still starts when
> it does not exist yet - a fresh installation runs no migration actions, so the action reading it is not
> dispatched in the one situation where it is absent.

### `ox_connector_restart`

> [!note]
> Declared with v1.17.0 and no longer part of the migration as of v1.18.0, which takes the Connector down in
> `migrations-pre` through [`workload_scale`](#workload_scale) instead - a restart afterwards would only
> take a Connector down that the deployment just brought up. The action is documented here because deployments
> upgraded from v1.15.0 - v1.16.1 have it recorded in their history, and it remains available in the migrations
> image.

Restarts the StatefulSet named in `statefulset.name` so that it picks up the most recent configuration, especially
required when e.g. the provisioning secrets are updated. It is restarted by scaling it down to zero and back up
to `statefulset.replicas` instead of by a rollout restart, waiting `statefulset.waitSeconds` in between. In
contrast to [`workload_scale`](#workload_scale) it brings the component back up itself, so it does not
depend on a deployment following it.

```yaml
- id: "ox_connector_restart"
  runMode: "default"
  config:
    statefulset:
      name: "ox-connector"
      replicas: 1
      waitSeconds: 30
```

### `ox_shared_accounts_import`

**Part 2 of 2** of the migration from the IAM's Functional Accounts (`oxmail/functional_account`) to the Shared
Accounts (`oxmail/shared_account`) that replace them. It creates a Shared Account in the IAM's default position
for them for every Functional Account [`ox_functional_accounts_export`](#ox_functional_accounts_export) wrote down
and deleted in `migrations-pre`, and links the account's users with the permission named in
`sharedAccounts.permission`, through the
[UDM REST API](./architecture/apis.md#udm-rest-api). The permission is addressed by its UDM `name`, not by its
display name, which is a label that may be reworded; the default is openDesk's own
`opendesk_mail_author_calendar_author` ("Mail: Full access, Calendar: Full access").

As the creation of the permissions are loaded into the IAM from the openDesk profiles by the stackdata Job, which may still be running when `migrations-post` starts, the action waits up to 15
minutes for the configured permission to appear before it reports it as missing.

The name changes where it has to. A Functional Account's name is a plain string, while a Shared Account is named
with the same syntax as a user name: Spaces and most punctuation are rejected. An account called "Team Sales" is
therefore created as `Team-Sales`, and its original name is kept as the Shared Account's `displayName`, which is
what the IAM shows. A name that leaves nothing to build on - only digits, or only punctuation - is not turned into
something invented but fails the migration; [`ox_functional_accounts_export`](#ox_functional_accounts_export)
applies the same rule in `migrations-pre`, so such an account stops the migration before anything is deleted.

```yaml
- id: "ox_shared_accounts_import"
  runMode: "apply"
  config:
    dryRun: false
    udm:
      url: "http://ums-udm-rest-api:9979/univention/udm/"
      username: "cn=admin"
      requestTimeoutSeconds: 30
    ldap:
      baseDn: "dc=swp-ldap,dc=internal"
    handover:
      objectKey: "ox-functional-accounts.yaml"
    sharedAccounts:
      permission: "opendesk_mail_author_calendar_author"
```

Its credential is mounted through the stage's [`secretFiles`](#secretfiles):

```yaml
secretFiles:
  - name: "udm-admin-password"
    secret:
      name: "ums-ldap-server-admin"
      key: "password"
```

### `flush_intercom_sessions`

Deletes the Intercom Service's sessions from the cache it keeps them in, so that no session established
against the release being replaced survives into the one being installed. The Intercom Service hands the
components their tokens, and a session from the previous release can carry claims, audiences or a user mapping
the new one no longer agrees with.

Only the keys matching `redis.keyPattern` are deleted, walked with `SCAN`. The default `sess:*` is the prefix
`express-session` stores under, which is what the Intercom Service uses. Nothing is flushed: the bundled Redis
holds OX App Suite's session store and UI middleware cache in the same database, and Nextcloud's cache, its PHP
sessions and the Notes backend in others. A pattern with no literal part - `*`, `?abc` - is rejected rather than
executed.

Host, port, database, user name and TLS are parameters, mirroring the `cache.intercomService` block the Intercom
Service itself is configured with, and the password is resolved from the same block (see below), so a deployment
using an external Redis points both at the same server and authenticates the same way. The connection and the
credential are proven before anything is deleted, and the deletion is verified afterwards.

Users are signed out of the components the Intercom Service brokers for and sign in again. There is nothing to
restore, and a repeated run finds nothing left to do.

```yaml
- id: "flush_intercom_sessions"
  config:
    redis:
      host: "redis-headless"
      port: 6379
      username: "default"
      tls: false
      database: 0
      keyPattern: "sess:*"
      requestTimeoutSeconds: 30
```

Its credential is mounted through the stage's [`secretFiles`](#secretfiles):

```yaml
secretFiles:
  - name: "redis-password"
    secret:
      name: "cache-intercom-service-password"
      key: "password"
```

## Development

When a new upgrade migration is required, ensure to address the following list:

- Update the generated release version file [`global.generated.yaml.gotmpl`](../helmfile/environments/default/global.generated.yaml.gotmpl) at least on the patch level to test the upgrade in your feature branch and trigger it in the `develop` branch after the feature branch was merged. During the release process, the value is overwritten by the release's version number.
- You have to implement the migration logic as a runner script in the [`opendesk-migrations`](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations) image. Please find more instructions in the linked repository.
- You most likely have to update the [`opendesk-migrations` Helm chart](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations) within the `rules` section of the [`role.yaml`](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/main/charts/opendesk-migrations/templates/role.yaml) to provide the permissions required for the execution of your migration's logic.
- You must set the runner's ID you want to execute in the [migrations.yaml.gotmpl](../helmfile/shared/migrations.yaml.gotmpl). See also the `migrations.*` section of [the Helm chart's README.md](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/main/charts/opendesk-migrations/README.md).
- Update the [`charts.yaml.gotmpl`](../helmfile/environments/default/charts.yaml.gotmpl) and [`images.yaml.gotmpl`](../helmfile/environments/default/images.yaml.gotmpl) to reflect the newer releases of the `opendesk-migrations` Helm chart and container image.
