<!--
SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# Updates & features

<!-- TOC -->
* [Migration requirements](#migration-requirements)
<!-- TOC -->

## Disclaimer

While [migrations.md](./migrations.md) provides information about required actions when updating or upgrading openDesk this document provides you with new (non-breaking) options made available in the Helmfile deployment.

# 1.15.0

## `functional.yaml.gotmpl`: Per user-quota for external sharing

It is now possible to configure the per-user quota for external share links and guest invitations. Previously, only toggling these features on or off was supported.

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


## `technical.yaml.gotmpl`: Set limitation on maximum number of objects (for tasks, contacts, attachments)

It is now possible to configure OX context wide quota limits for tasks, contacts, and attachments. Previously, only the calendar quota could be configured.

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
