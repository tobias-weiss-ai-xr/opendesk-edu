<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->
<h1>CI/CD</h1>

This page will cover openDesk automation via Gitlab CI.

<!-- TOC -->
  * [Deployment](#deployment)
  * [Tests](#tests)
<!-- TOC -->

## Deployment

The project includes a `.gitlab-ci.yml` that allows you to execute the deployment from a Gitlab instance of your choice.


When starting the pipeline through the Gitlab UI, you will be queried for some variables plus the following ones:

- `BASE_DOMAIN`: The base domain the SWP will use. For example: `souvap.cloud`
- `NAMESPACE`: Defines into which namespace of your K8s cluster the SWP will be installed
- `MASTER_PASSWORD_WEB_VAR`: Overwrites value of `MASTER_PASSWORD`

Based on your input, the following variables will be set:
- `DOMAIN` = `NAMESPACE`.`BASE_DOMAIN`
- `ISTIO_DOMAIN` = istio.`DOMAIN`
- `MASTER_PASSWORD` = `MASTER_PASSWORD_WEB_VAR`. If `MASTER_PASSWORD_WEB_VAR`
  is not set, the default for `MASTER_PASSWORD` will be used, unless you set
  `MASTER_PASSWORD` as a masked CI/CD variable in Gitlab to supersede the default.

You might want to set credential variables in the Gitlab project at `Settings` > `CI/CD` > `Variables`.


## Tests

The gitlab-ci pipeline contains a job named `run-tests` that can trigger a test suite pipeline on another gitlab project.
The `DEPLOY_`-variables are used to determine which components should be tested.
In order for the trigger to work, the variable `TESTS_PROJECT_URL` has to be set on this gitlab project's CI variables
that can be found at `Settings` -> `CI/CD` -> `Variables`. The variable should have this format:
`<domain of gitlab>/api/v4/projects/<id>`.

If the branch of the test pipeline is not `main` this can be set with the .gitlab-ci.yml variable
`TESTS_BRANCH` while creating a new pipeline.
