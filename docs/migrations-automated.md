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

<!-- TOC -->
* [Automated migrations](#automated-migrations)
  * [Related components and artifacts](#related-components-and-artifacts)
    * [`releaseVersion`](#releaseversion)
    * [`upgradeFrom.min` and `upgradeFrom.max`](#upgradefrommin-and-upgradefrommax)
    * [`actions.pre` and `actions.post`](#actionspre-and-actionspost)
    * [`actionsSkip.pre` and `actionsSkip.post`](#actionsskippre-and-actionsskippost)
    * [`secretFiles`](#secretfiles)
  * [Automated migrations overview](#automated-migrations-overview)
  * [Actions](#actions)
    * [`ox_connector_restart`](#ox_connector_restart)
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

### `upgradeFrom.min` and `upgradeFrom.max`

The range of openDesk releases the declared migrations support upgrading from.
They only run when the release that was migrated successfully last - recorded in the
ConfigMap `migrations-status`, see [Related components and artifacts](#related-components-and-artifacts) -
lies within this range. This version gating is what enforces the
[mandatory upgrade path](./migrations-manual.md#overview-and-mandatory-upgrade-path).

### `actions.pre` and `actions.post`

The actions to be executed before (`migrations-pre`) respectively after (`migrations-post`) the deployment of
all other components, each in the order listed. An action is

```yaml
id: <action-id>
tag: <run-once-key>
config: <parameters>
```

- `id` selects the action module shipped in the migrations image.
- `config` carries its non-secret parameters.
- `tag` (**optional**) makes an action run *once*: The pair (`id`, `tag`) is recorded in the `history` of the
ConfigMap `migrations-status`, and an action whose pair is already recorded is skipped - on a redeployment of
the same release as well as in any later release. It is used for work that must not be repeated, like a data
migration or a one-time restart of a component, and is omitted for actions that are meant to run on every
deployment that declares them. A later release that needs the same work again declares the action under a new
tag, so tagging with the release the work belongs to (e.g. `v1.17.0`) keeps the pairs distinct.

Actions are only declared when the components they work on are actually installed, gated by the same conditions as
the corresponding releases.

### `actionsSkip.pre` and `actionsSkip.post`

The actions to opt out of. In contrast to everything above, this is not part of the migration's definition but
a per-deployment setting, configurable in [`migrations.yaml.gotmpl`](../helmfile/environments/default/migrations.yaml.gotmpl).

It mirrors `actions`: An entry names the stage, the `id` and the `tag` of the action it skips - the same footprint, just without
its `config` - and has to match the declared action exactly. See [Skip single actions of the automated migrations](./updates.md#skip-single-actions-of-the-automated-migrations) in `updates.md`.

### `secretFiles`

The credentials the actions need, mounted from existing Kubernetes Secrets as files, so that
no credential is passed via environment variables or duplicated into a new Secret.

## Automated migrations overview

The following table lists the actions the openDesk releases declare. *Declared with* is the release whose
migration definition added the call, *Upgrades covered* is the `upgradeFrom` range of that definition, so the
range of installed releases the call is executed for.

| Action                                          | Stage             | Declared with | Runs                    | Upgrades covered  |
| ----------------------------------------------- | ----------------- | ------------- | ----------------------- | ----------------- |
| [`ox_connector_restart`](#ox_connector_restart) | `migrations-post` | v1.17.0       | Once (`tag`: `v1.17.0`) | v1.15.0 - v1.16.1 |

> [!note]
> An action is only declared when the components it works on are actually installed. The call of
> `ox_connector_restart` above is therefore only part of the migration when OX App Suite is enabled.

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

### `ox_connector_restart`

Restarts the StatefulSet named in `statefulset.name` so that it picks up the most recent configuration, especially
required when e.g. the provisioning secrets are updated. It is restarted by scaling it down to zero and back up
to `statefulset.replicas` instead of by a rollout restart, waiting `statefulset.waitSeconds` in between.

```yaml
migrations:
  actions:
    post:
      - id: "ox_connector_restart"
        config:
          statefulset:
            name: "ox-connector"
            replicas: 1
            waitSeconds: 30
```

## Development

When a new upgrade migration is required, ensure to address the following list:

- Update the generated release version file [`global.generated.yaml.gotmpl`](../helmfile/environments/default/global.generated.yaml.gotmpl) at least on the patch level to test the upgrade in your feature branch and trigger it in the `develop` branch after the feature branch was merged. During the release process, the value is overwritten by the release's version number.
- You have to implement the migration logic as a runner script in the [`opendesk-migrations`](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations) image. Please find more instructions in the linked repository.
- You most likely have to update the [`opendesk-migrations` Helm chart](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations) within the `rules` section of the [`role.yaml`](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/main/charts/opendesk-migrations/templates/role.yaml) to provide the permissions required for the execution of your migration's logic.
- You must set the runner's ID you want to execute in the [migrations.yaml.gotmpl](../helmfile/shared/migrations.yaml.gotmpl). See also the `migrations.*` section of [the Helm chart's README.md](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/main/charts/opendesk-migrations/README.md).
- Update the [`charts.yaml.gotmpl`](../helmfile/environments/default/charts.yaml.gotmpl) and [`images.yaml.gotmpl`](../helmfile/environments/default/images.yaml.gotmpl) to reflect the newer releases of the `opendesk-migrations` Helm chart and container image.
