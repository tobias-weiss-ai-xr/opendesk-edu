<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->
<h1>CI/CD</h1>

This page covers openDesk deployment automation via Gitlab CI.

<!-- TOC -->
* [Deployment](#deployment)
* [Tests](#tests)
<!-- TOC -->

# Deployment

The project includes a `.gitlab-ci.yml` that allows you to execute the deployment from a GitLab instance of your choice.

When starting the pipeline through the GitLab UI, you will be queried for some variables plus the following ones:

- `DOMAIN`: Primary domain for your deployment making the openDesk services available e.g. as `https://portal.DOMAIN`.
- `MAIL_DOMAIN`: (optional) Domain for the users mail addresses, defaults to `DOMAIN`.
- `MATRIX_DOMAIN`: (optional) Domain for the users Matrix IDs, defaults to `DOMAIN`.
- `NAMESPACE`: Namespace of your K8s cluster openDesk will be installed to.
- `MASTER_PASSWORD_WEB_VAR`: Overwrites value of `MASTER_PASSWORD`.

Based on your input, the following variables will be set:
- `MASTER_PASSWORD:`: `MASTER_PASSWORD_WEB_VAR`. If `MASTER_PASSWORD_WEB_VAR`
  is not set, the default for `MASTER_PASSWORD` will be used, unless you set
  `MASTER_PASSWORD` as a masked CI/CD variable in GitLab to supersede the default.

You might want to set credential variables in the GitLab project at `Settings` > `CI/CD` > `Variables`.

# Tests

The GitLab CI pipeline contains a job named `run-tests` that can trigger a test suite pipeline on another GitLab project.
The `DEPLOY_`-variables are used to determine which components should be tested.
In order for the trigger to work, the variable `TESTS_PROJECT_URL` has to be set on this GitLab project's CI variables
that can be found at `Settings` -> `CI/CD` -> `Variables`. The variable should have this format:
`<domain of gitlab>/api/v4/projects/<id>`.

If the branch of the test pipeline is not `main` this can be set with the `.gitlab-ci.yml` variable
`TESTS_BRANCH` while creating a new pipeline.
