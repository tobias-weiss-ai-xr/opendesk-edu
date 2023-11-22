<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<h1>Security</h1>

This document should cover the current status of security measurements.

<!-- TOC -->
  * [Helm Chart Trust Chain](#helm-chart-trust-chain)
  * [Kubernetes Security Enforcements](#kubernetes-security-enforcements)
<!-- TOC -->

## Helm Chart Trust Chain

Helm Charts which are released via openDesk CI/CD process are always signed. The public GPG keys are present in
`pubkey.gpg` file and are validated during helmfile installation.

| Repository                           | OCI |     Verifiable     |
|--------------------------------------|:---:|:------------------:|
| bitnami-repo (openDesk build)        | yes | :white_check_mark: |
| clamav-repo                          | yes | :white_check_mark: |
| collabora-online-repo                | no  |        :x:         |
| cryptpad-online-repo                 | no  |        :x:         |
| intercom-service-repo                | yes | :white_check_mark: |
| istio-resources-repo                 | yes | :white_check_mark: |
| jitsi-repo                           | yes | :white_check_mark: |
| keycloak-extensions-repo             | no  |        :x:         |
| keycloak-theme-repo                  | yes | :white_check_mark: |
| mariadb-repo                         | yes | :white_check_mark: |
| nextcloud-repo                       | no  |        :x:         |
| opendesk-certificates-repo           | yes | :white_check_mark: |
| opendesk-dovecot-repo                | yes | :white_check_mark: |
| opendesk-element-repo                | yes | :white_check_mark: |
| opendesk-keycloak-bootstrap-repo     | yes | :white_check_mark: |
| opendesk-nextcloud-bootstrap-repo    | yes | :white_check_mark: |
| opendesk-open-xchange-bootstrap-repo | yes | :white_check_mark: |
| openproject-repo                     | no  |        :x:         |
| openxchange-repo                     | yes |        :x:         |
| ox-connector-repo                    | no  |        :x:         |
| postfix-repo                         | yes | :white_check_mark: |
| postgresql-repo                      | yes | :white_check_mark: |
| univention-corporate-container-repo  | yes | :white_check_mark: |
| ums-repo                             | no  |        :x:         |
| xwiki-repo                           | no  |        :x:         |

## Kubernetes Security Enforcements

This list gives you an overview of default security settings and if they comply with security standards:


| Component    | Process                    |         =          | allowPrivilegeEscalation (`false`) |                                                           capabilities (`drop: ALL`)                                                           | seccompProfile (`RuntimeDefault`) | readOnlyRootFilesystem (`true`) | runAsNonRoot (`true`) | runAsUser | runAsGroup | fsGroup |
|--------------|----------------------------|:------------------:|:----------------------------------:|:----------------------------------------------------------------------------------------------------------------------------------------------:|:---------------------------------:|:-------------------------------:|:---------------------:|:---------:|:----------:|:-------:|
| ClamAV       | clamd                      | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |    100    |    101     |   101   |
|              | freshclam                  | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |    100    |    101     |   101   |
|              | icap                       | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |    100    |    101     |   101   |
|              | milter                     | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |    100    |    101     |   101   |
| Collabora    | collabora                  |        :x:         |                :x:                 | :x: (`CHOWN`, `DAC_OVERRIDE`, `FOWNER`, `FSETID`, `KILL`, `SETGID`, `SETUID`, `SETPCAP`, `NET_BIND_SERVICE`, `NET_RAW`, `SYS_CHROOT`, `MKNOD`) |        :white_check_mark:         |               :x:               |  :white_check_mark:   |    100    |    101     |   100   |
| CryptPad     | npm                        |        :x:         |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |               :x:               |  :white_check_mark:   |   4001    |   4001     |  4001   |
| Dovecot      | dovecot                    |        :x:         |         :white_check_mark:         |                              :x: (`CHOWN`, `DAC_OVERRIDE`, `NET_BIND_SERVICE`, `SETGID`, `SETUID`, `SYS_CHROOT`)                               |        :white_check_mark:         |       :white_check_mark:        |          :x:          |      -    |      -     |  1000   |
| Element      | element                    | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |    101    |    101     |   101   |
|              | synapse                    | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   10991   |     -      |  10991  |
|              | synapseWeb                 | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |    101    |    101     |   101   |
|              | wellKnown                  | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |    101    |    101     |   101   |
| Jitsi        | jibri                      |        :x:         |                :x:                 |                                                               :x: (`SYS_ADMIN`)                                                                |        :white_check_mark:         |               :x:               |          :x:          |     -     |     -      |    -    |
|              | jicofo                     |        :x:         |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |               :x:               |          :x:          |     -     |     -      |    -    |
|              | jitsiKeycloakAdapter       | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1993    |    1993    |    -    |
|              | jvb                        |        :x:         |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |               :x:               |          :x:          |     -     |     -      |    -    |
|              | prosody                    |        :x:         |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |               :x:               |          :x:          |     -     |     -      |    -    |
|              | web                        |        :x:         |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |               :x:               |          :x:          |     -     |     -      |    -    |
| Keycloak     | keycloak                   |        :x:         |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |               :x:               |  :white_check_mark:   |   1001    |    1001    |  1001   |
|              | keycloakConfigCli          | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1001    |    1001    |  1001   |
|              | keycloakExtensionHandler   | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1000    |    1000    |    -    |
|              | keycloakExtensionProxy     | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1000    |    1000    |    -    |
| MariaDB      | mariadb                    | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1001    |    1001    |  1001   |
| Memcached    | memcached                  | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1001    |     -      |  1001   |
| Postfix      | postfix                    |        :x:         |                :x:                 |                                                                      :x:                                                                       |        :white_check_mark:         |               :x:               |          :x:          |     -     |     -      |   101   |
| Open-Xchange | core-documentconverter     |        :x:         |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |               :x:               |  :white_check_mark:   |    987    |    1000    |    -    |
|              | core-guidedtours           | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1000    |    1000    |    -    |
|              | core-imageconverter        |        :x:         |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |              :x:                |  :white_check_mark:   |    987    |    1000    |    -    |
|              | core-mw-default            |        :x:         |                :x:                 |                                                                      :x:                                                                       |               :x:                 |              :x:                |         :x:           |      -    |       -    |    -    |
|              | core-ui                    | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1000    |    1000    |    -    |
|              | core-ui-middleware         | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1000    |    1000    |    -    |
|              | core-ui-middleware-updater | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1000    |    1000    |    -    |
|              | core-user-guide            | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1000    |    1000    |    -    |
|              | gotenberg                  | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1000    |    1000    |    -    |
|              | guard-ui                   | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1000    |    1000    |    -    |
|              | nextlcoud-integration-ui   | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1000    |    1000    |    -    |
|              | public-sector-ui           | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1000    |    1000    |    -    |
| OpenProject  | openproject                |        :x:         |         :white_check_mark:         |                                                                      :x:                                                                       |        :white_check_mark:         |               :x:               |          :x:          |     -     |     -      |    -    |
| PostgreSQL   | postgresql                 | :white_check_mark: |         :white_check_mark:         |                                                               :white_check_mark:                                                               |        :white_check_mark:         |       :white_check_mark:        |  :white_check_mark:   |   1001    |    1001    |  1001   |
