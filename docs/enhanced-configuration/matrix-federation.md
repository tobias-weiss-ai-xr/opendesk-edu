<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Matrix federation</h1>

* [Use case](#use-case)
* [Example configuration](#example-configuration)
  * [DNS setup](#dns-setup)

# Use case

By default you only can chat with users that also have an account within your openDesk installation. The Element chat application and its server component Synapse are based on the Matrix protocol that supports federation with other Matrix servers to communicate with the users with accounts on these servers.

# Example configuration

The following values are used in this example documentation. Please ensure when you come across such a value even if it is part of a URL hostname or path that you adapt it where needed to your setup:

- `opendesk.domain.tld`: the mandatory `DOMAIN` setting for your deployment resulting in `https://chat.opendesk.domain.tld` to access the Element chat.
- `my_organization.tld`: an optional alternative domain used for mail and/or Matrix. If not used it is also set to `opendesk.domain.tld`.

## DNS setup

If you want to federate with other Matrix instances, you need to have both SRV records:

| Record name                         | Type | Value                                  | Additional Information                                                             |
| ----------------------------------- | ---- | -------------------------------------- | ---------------------------------------------------------------------------------- |
| _matrix._tcp.my_organization.tld    | SRV  | `1 10 PORT matrix.opendesk.domain.tld` | `PORT` is your NodePort/LoadBalancer port of `opendesk-synapse-federation` service |
| matrix-fed._tcp.my_organization.tld | SRV  | `1 10 PORT matrix.opendesk.domain.tld` | `PORT` is your NodePort/LoadBalancer port of `opendesk-synapse-federation` service |

*Note:* `matrix.opendesk.domain.tld` in the "Value" column can also be the IP address where synapse TLS port is listening to.
