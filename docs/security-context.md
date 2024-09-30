<!--
SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->
<h1>Kubernetes Security Context</h1>

* [Container Security Context](#container-security-context)
  * [allowPrivilegeEscalation](#allowprivilegeescalation)
  * [capabilities](#capabilities)
  * [privileged](#privileged)
  * [runAsUser](#runasuser)
  * [runAsGroup](#runasgroup)
  * [seccompProfile](#seccompprofile)
  * [readOnlyRootFilesystem](#readonlyrootfilesystem)
  * [runAsNonRoot](#runasnonroot)
* [Status quo](#status-quo)

# Container Security Context


The containerSecurityContext is the most important security-related section because it has the highest precedence and restricts the container to its minimal privileges.

## allowPrivilegeEscalation


Privilege escalation (such as via set-user-ID or set-group-ID file mode) should not be allowed (Linux only) at any time.

```yaml
containerSecurityContext:
  allowPrivilegeEscalation: false
```

## capabilities


Containers must drop ALL capabilities, and are only permitted to add back the `NET_BIND_SERVICE` capability (Linux only).


**Optimal:**

```yaml
containerSecurityContext:
  capabilities:
    drop:
      - "ALL"
```


**Allowed:**

```yaml
containerSecurityContext:
  capabilities:
    drop:
      - "ALL"
    add:
      - "NET_BIND_SERVICE"
```

## privileged


Privileged Pods disable most security mechanisms and must be disallowed.

```yaml
containerSecurityContext:
  privileged: false
```

## runAsUser


Containers should set a user id >= 1000 and never use 0 (root) as user.

```yaml
containerSecurityContext:
  runAsUser: 1000
```

## runAsGroup


Containers should set a group id >= 1000 and never use 0 (root) as user.

```yaml
containerSecurityContext:
  runAsGroup: 1000
```

## seccompProfile


Seccomp profile must be explicitly set to one of the allowed values. An unconfined profile and the complete absence of the profile are prohibited.

```yaml
containerSecurityContext:
  seccompProfile:
    type: "RuntimeDefault"
```


or

```yaml
containerSecurityContext:
  seccompProfile:
    type: "Localhost"
```

## readOnlyRootFilesystem


Containers should have an immutable file systems, so that attackers could not modify application code or download malicious code.

```yaml
containerSecurityContext:
  readOnlyRootFilesystem: true
```

## runAsNonRoot


Containers must be required to run as non-root users.

```yaml
containerSecurityContext:
  runAsNonRoot: true
```

# Status quo


openDesk aims to achieve that all security relevant settings are explicitly templated and comply with security recommendations.


The rendered manifests are also validated against Kyverno [policies](/.kyverno/policies) in CI to ensure that the provided values inside openDesk are also properly templated by the given Helm charts.


This list gives you an overview of templated security settings and if they comply with security standards:


 - **yes**: Value is set to `true`
 - **no**: Value is set to `false`
 - **n/a**: No explicitly templated in openDesk and default is used.

| process | status | allowPrivilegeEscalation | privileged | readOnlyRootFilesystem | runAsNonRoot | runAsUser | runAsGroup | seccompProfile | capabilities |
| ------- | ------ | ------------------------ | ---------- | ---------------------- | ------------ | --------- | ---------- | -------------- | ------------ |
| **collabora**/collabora-online | :x: | yes | no | no | yes | 100 | 101 | yes | no ["CHOWN","DAC_OVERRIDE","FOWNER","FSETID","KILL","SETGID","SETUID","SETPCAP","NET_BIND_SERVICE","NET_RAW","SYS_CHROOT","MKNOD"] |
| **cryptpad**/cryptpad | :x: | no | no | no | yes | 4001 | 4001 | yes | yes |
| **element**/matrix-neoboard-widget | :white_check_mark: | no | no | yes | yes | 101 | 101 | yes | yes |
| **element**/matrix-neochoice-widget | :white_check_mark: | no | no | yes | yes | 101 | 101 | yes | yes |
| **element**/matrix-neodatefix-bot | :white_check_mark: | no | no | yes | yes | 101 | 101 | yes | yes |
| **element**/matrix-neodatefix-bot-bootstrap | :white_check_mark: | no | no | yes | yes | 101 | 101 | yes | yes |
| **element**/matrix-neodatefix-widget | :white_check_mark: | no | no | yes | yes | 101 | 101 | yes | yes |
| **element**/opendesk-element | :white_check_mark: | no | no | yes | yes | 101 | 101 | yes | yes |
| **element**/opendesk-matrix-user-verification-service | :x: | no | no | no | no | 0 | 0 | yes | yes |
| **element**/opendesk-matrix-user-verification-service-bootstrap | :white_check_mark: | no | no | yes | yes | 101 | 101 | yes | yes |
| **element**/opendesk-synapse | :white_check_mark: | no | no | yes | yes | 10991 | 10991 | yes | yes |
| **element**/opendesk-synapse-web | :white_check_mark: | no | no | yes | yes | 101 | 101 | yes | yes |
| **element**/opendesk-well-known | :white_check_mark: | no | no | yes | yes | 101 | 101 | yes | yes |
| **jitsi**/jitsi | :white_check_mark: | no | no | yes | yes | 1993 | 1993 | yes | yes |
| **jitsi**/jitsi/jitsi/jibri | :x: | n/a | n/a | n/a | n/a | n/a | n/a | n/a | no ["SYS_ADMIN"] |
| **jitsi**/jitsi/jitsi/jicofo | :x: | no | no | no | no | 0 | 0 | yes | no |
| **jitsi**/jitsi/jitsi/jvb | :x: | no | no | no | no | 0 | 0 | yes | no |
| **jitsi**/jitsi/jitsi/prosody | :x: | no | no | no | no | 0 | 0 | yes | no |
| **jitsi**/jitsi/jitsi/web | :x: | no | no | no | no | 0 | 0 | yes | no |
| **jitsi**/jitsi/patchJVB | :white_check_mark: | no | no | yes | yes | 1001 | 1001 | yes | yes |
| **nextcloud**/opendesk-nextcloud-management | :x: | no | no | no | yes | 65532 | 65532 | yes | yes |
| **nextcloud**/opendesk-nextcloud/apache2 | :white_check_mark: | no | no | yes | yes | 65532 | 65532 | yes | yes |
| **nextcloud**/opendesk-nextcloud/exporter | :white_check_mark: | no | no | yes | yes | 65532 | 65532 | yes | yes |
| **nextcloud**/opendesk-nextcloud/php | :white_check_mark: | no | no | yes | yes | 65532 | 65532 | yes | yes |
| **open-xchange**/dovecot | :x: | no | n/a | yes | n/a | n/a | n/a | yes | no ["CHOWN","DAC_OVERRIDE","KILL","NET_BIND_SERVICE","SETGID","SETUID","SYS_CHROOT"] |
| **open-xchange**/open-xchange/appsuite/core-documentconverter | :x: | no | no | no | yes | 987 | 1000 | yes | yes |
| **open-xchange**/open-xchange/appsuite/core-guidedtours | :white_check_mark: | no | no | yes | yes | 1000 | 1000 | yes | yes |
| **open-xchange**/open-xchange/appsuite/core-imageconverter | :x: | no | no | no | yes | 987 | 1000 | yes | yes |
| **open-xchange**/open-xchange/appsuite/core-mw/gotenberg | :white_check_mark: | no | no | yes | yes | 1001 | 1001 | yes | yes |
| **open-xchange**/open-xchange/appsuite/core-ui | :white_check_mark: | no | no | yes | yes | 1000 | 1000 | yes | yes |
| **open-xchange**/open-xchange/appsuite/core-ui-middleware | :white_check_mark: | no | no | yes | yes | 1000 | 1000 | yes | yes |
| **open-xchange**/open-xchange/appsuite/core-user-guide | :white_check_mark: | no | no | yes | yes | 1000 | 1000 | yes | yes |
| **open-xchange**/open-xchange/appsuite/guard-ui | :white_check_mark: | no | no | yes | yes | 1000 | 1000 | yes | yes |
| **open-xchange**/open-xchange/nextcloud-integration-ui | :x: | no | no | no | yes | 1000 | 1000 | yes | yes |
| **open-xchange**/open-xchange/public-sector-ui | :white_check_mark: | no | no | yes | yes | 1000 | 1000 | yes | yes |
| **openproject**/openproject | :white_check_mark: | no | no | yes | yes | 1000 | 1000 | yes | yes |
| **openproject-bootstrap**/opendesk-openproject-bootstrap | :white_check_mark: | no | no | yes | yes | 1000 | 1000 | yes | yes |
| **open-xchange**/ox-connector | :x: | no | no | no | no | 0 | 0 | yes | no ["CHOWN","DAC_OVERRIDE","FOWNER","FSETID","KILL","SETGID","SETUID","SETPCAP","NET_BIND_SERVICE","NET_RAW","SYS_CHROOT"] |
| **services**/clamav | :x: | no | no | yes | no | 0 | 0 | yes | no |
| **services**/clamav-simple | :white_check_mark: | no | no | yes | yes | 100 | 101 | yes | yes |
| **services**/clamav/clamd | :white_check_mark: | no | no | yes | yes | 100 | 101 | yes | yes |
| **services**/clamav/freshclam | :white_check_mark: | no | no | yes | yes | 100 | 101 | yes | yes |
| **services**/clamav/icap | :white_check_mark: | no | no | yes | yes | 100 | 101 | yes | yes |
| **services**/clamav/milter | :white_check_mark: | no | no | yes | yes | 100 | 101 | yes | yes |
| **services**/mariadb | :white_check_mark: | no | no | yes | yes | 1001 | 1001 | yes | yes |
| **services**/memcached | :white_check_mark: | no | no | yes | yes | 1001 | 1001 | yes | yes |
| **services**/minio | :x: | no | no | no | yes | 1000 | 0 | yes | yes |
| **services**/postfix | :x: | yes | yes | no | no | 0 | 0 | yes | no |
| **services**/postgresql | :white_check_mark: | no | no | yes | yes | 1001 | 1001 | yes | yes |
| **services**/redis/master | :white_check_mark: | no | no | yes | yes | 1001 | 1001 | yes | yes |
| **univention-management-stack**/intercom-service | :white_check_mark: | no | no | yes | yes | 1000 | 1000 | yes | yes |
| **univention-management-stack**/opendesk-keycloak-bootstrap | :white_check_mark: | no | no | yes | yes | 1000 | 1000 | yes | yes |
| **univention-management-stack**/ums/keycloak | :x: | no | no | no | yes | 1000 | 1000 | yes | yes |
| **univention-management-stack**/ums/keycloak-bootstrap | :x: | no | no | no | yes | 1000 | 1000 | yes | yes |
| **univention-management-stack**/ums/keycloak-extensions/handler | :white_check_mark: | no | no | yes | yes | 1000 | 1000 | yes | yes |
| **univention-management-stack**/ums/keycloak-extensions/proxy | :white_check_mark: | no | no | yes | yes | 1000 | 1000 | yes | yes |
| **univention-management-stack**/ums/ldap-notifier | :x: | n/a | n/a | n/a | n/a | n/a | n/a | yes | no |
| **univention-management-stack**/ums/portal-listener | :x: | no | no | no | no | 0 | 0 | yes | no ["CHOWN","DAC_OVERRIDE","FOWNER","FSETID","KILL","SETGID","SETUID","SETPCAP","NET_BIND_SERVICE","NET_RAW","SYS_CHROOT"] |
| **univention-management-stack**/ums/selfservice-listener | :x: | no | no | no | no | 0 | 0 | yes | no ["CHOWN","DAC_OVERRIDE","FOWNER","FSETID","KILL","SETGID","SETUID","SETPCAP","NET_BIND_SERVICE","NET_RAW","SYS_CHROOT"] |
| **univention-management-stack**/ums/stack-data-swp | :x: | no | no | no | no | 0 | 0 | yes | yes |
| **univention-management-stack**/ums/stack-gateway | :x: | no | no | no | yes | 1001 | 0 | yes | yes |
| **univention-management-stack**/ums/umc-gateway | :x: | no | no | no | no | 0 | 0 | yes | no ["CHOWN","DAC_OVERRIDE","FOWNER","FSETID","KILL","SETGID","SETUID","SETPCAP","NET_BIND_SERVICE","NET_RAW","SYS_CHROOT"] |
| **univention-management-stack**/ums/umc-server | :x: | no | no | no | no | 0 | 0 | yes | no ["CHOWN","DAC_OVERRIDE","FOWNER","FSETID","KILL","SETGID","SETUID","SETPCAP","NET_BIND_SERVICE","NET_RAW","SYS_CHROOT"] |
| **xwiki**/xwiki | :x: | no | no | no | yes | 100 | 101 | yes | yes |


This file is auto-generated by [openDesk CI CLI](https://gitlab.opencode.de/bmi/opendesk/tooling/opendesk-ci-cli)
