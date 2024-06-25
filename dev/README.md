<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Tools for local development</h1>

* [charts-local.py](#charts-localpy)
  * [Commandline parameter](#commandline-parameter)
    * [`--branch`](#--branch)
    * [`--revert`](#--revert)

# charts-local.py

This script helps you on cloning the platform development Helm charts and referencing them directly in the openDesk
Helmfile deployment for comfortable local test and development. The charts will be cloned into a directory
parallel created next to the `opendesk` repo containing this documentation and the `charts-local.py` script.
The name of the chart directory is derived from the branch name you are working with in this `opendesk` repo.

The script will create `.bak` copies of the helmfiles that have been touched.

Run the script with `-h` to get information about the script's parameter on commandline.

## Commandline parameter

### `--branch`

Optional parameter: Defines a branch for the `opendesk` repo to work with. The script will create the branch if it
does not exist yet. Otherwise it will switch to defined branch.

If parameter is omitted the current branch of the `opendesk` repo will be used.

### `--revert`

Reverts the changes in the helmfiles pointing to the local Helm charts by copying the backup files created by the
scripts itself back to their original location.
