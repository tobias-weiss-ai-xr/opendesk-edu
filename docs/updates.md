<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

# Updates and features

While [migrations.md](./migrations.md) provides information about required actions when updating or upgrading openDesk this document provides an overview on new (non-breaking) options made available in the Helmfile deployment.

<!-- TOC -->
* [Updates and features](#updates-and-features)
  * [1.15.0](#1150)
    * [`functional.yaml.gotmpl`](#functionalyamlgotmpl)
      * [Per user-quota for external sharing](#per-user-quota-for-external-sharing)
      * [Virtual alias limits](#virtual-alias-limits)
    * [`technical.yaml.gotmpl`](#technicalyamlgotmpl)
      * [Set limitation on maximum number of objects (for tasks, contacts, attachments)](#set-limitation-on-maximum-number-of-objects-for-tasks-contacts-attachments)
<!-- TOC -->

## 1.15.0

### `functional.yaml.gotmpl`

#### Per user-quota for external sharing

Configure the per-user quota for external share links and guest invitations:

```yaml
functional:
  groupware:
    externalSharing:
      shareLinks:
        enabled: false
        # Limit the number of share links a single user can create.
        # Ref.: https://documentation.open-xchange.com/components/middleware/config/8/#mode=search&term=com.openexchange.quota.share_links
        quota: 100
      inviteGuests:
        enabled: false
        # Limit the number of guests a single user can create.
        # Ref.: https://documentation.open-xchange.com/components/middleware/config/8/#mode=search&term=com.openexchange.quota.invite_guests
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
        # Maximum number of recipients a single address may expand to (e.g. members of a mailing list).
        # Ref: https://www.postfix.org/postconf.5.html#virtual_alias_expansion_limit
        expansion: 1000
        # Maximum nesting depth of alias-of-alias resolution chains.
        # Ref: https://www.postfix.org/postconf.5.html#virtual_alias_recursion_limit
        recursion: 25
```

### `technical.yaml.gotmpl`

#### Set limitation on maximum number of objects (for tasks, contacts, attachments)

Set OX context wide quota limits for tasks, contacts, and attachments:

```yaml
technical:
  oxAppSuite:
    quota:
      # Maximum number of tasks within a single OX Context. Might need to be increased in larger deployments to avoid hitting the quota limit.
      # Ref.: https://documentation.open-xchange.com/components/middleware/config/8/#mode=search&term=com.openexchange.quota.tasks
      tasks: 250000
      # Maximum number of contacts within a single OX Context. Might need to be increased in larger deployments to avoid hitting the quota limit.
      # Ref.: https://documentation.open-xchange.com/components/middleware/config/8/#mode=search&term=com.openexchange.quota.contacts
      contacts: 250000
      # Maximum number of attachments within a single OX Context. Might need to be increased in larger deployments to avoid hitting the quota limit.
      # Ref.: https://documentation.open-xchange.com/components/middleware/config/8/#mode=search&term=com.openexchange.quota.attachments
      attachments: 250000
```

Previously, only the calendar quota could be configured.