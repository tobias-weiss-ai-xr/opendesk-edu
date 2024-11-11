<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>openDesk APIs</h1>

This chapter presents APIs available in openDesk grouped by applications.

* [IAM - Nubus](#iam---nubus)
  * [UMC Python API](#umc-python-api)
  * [UMC store API](#umc-store-api)
  * [IntercomService (ICS) API](#intercomservice-ics-api)
  * [High-level Listener modules API](#high-level-listener-modules-api)
  * [UDM Simple API](#udm-simple-api)
  * [UDM REST API](#udm-rest-api)
  * [UCR Python API](#ucr-python-api)
  * [LDAP](#ldap)
  * [Nubus Provisioning Service (**TBD**)](#nubus-provisioning-service-tbd)
  * [Nubus Authorization Service (**TBD**)](#nubus-authorization-service-tbd)
* [Groupware - OX AppSuite / OX Dovecot](#groupware---ox-appsuite--ox-dovecot)
  * [Usage of APIs within openDesk](#usage-of-apis-within-opendesk)
  * [HTTP API](#http-api)
  * [SOAP API](#soap-api)
  * [REST API](#rest-api)
  * [CardDAV](#carddav)
  * [CalDAV](#caldav)
  * [IMAP](#imap)
  * [POP3](#pop3)
* [Files - Nextcloud](#files---nextcloud)
  * [Usage of APIs within openDesk](#usage-of-apis-within-opendesk-1)
  * [OCS API](#ocs-api)
  * [Notifications API](#notifications-api)
  * [Activity API](#activity-api)
  * [Remote wipe API](#remote-wipe-api)
  * [WebDAV](#webdav)
  * [CalDAV / CardDAV](#caldav--carddav)
* [Weboffice - Collabora](#weboffice---collabora)
  * [PostMessage API](#postmessage-api)
  * [Conversion API](#conversion-api)
* [Project management - OpenProject](#project-management---openproject)
  * [HATEOAS API](#hateoas-api)
  * [BCF API](#bcf-api)
* [Video Conferencing - Jitsi](#video-conferencing---jitsi)
  * [IFrame API](#iframe-api)
  * [Lib-jitsi-meet API](#lib-jitsi-meet-api)
  * [Jitsi Meet React SDK](#jitsi-meet-react-sdk)
* [Chat - Element](#chat---element)
  * [Matrix Application Service API](#matrix-application-service-api)
  * [Matrix Client-Server API](#matrix-client-server-api)
  * [Matrix Server-Server API](#matrix-server-server-api)
  * [Matrix Push Gateway API](#matrix-push-gateway-api)
  * [Matrix Identity Service API](#matrix-identity-service-api)
* [Knowledge management - XWiki](#knowledge-management---xwiki)
  * [REST API](#rest-api-1)
  * [Scripting API](#scripting-api)
  * [Java API](#java-api)
  * [JavaScript API](#javascript-api)

# IAM - Nubus

![High-level architecture of Univention part withAPIs/interfaces highlighted](./apis_images/IAM-overview.png)

## UMC Python API

![Composition of UMC component with APIs highlighted](./apis_images/IAM-umc-architecture.png)

| Name                           | UMC Python API                                                                                                                                                                                                                                 |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        |                                                                                                                                                                                                                                                |
| Versioning                     |                                                                                                                                                                                                                                                |
| Authentication                 |                                                                                                                                                                                                                                                |
| In openDesk provided by        | Nubus UMC                                                                                                                                                                                                                                      |
| Transport protocol             |                                                                                                                                                                                                                                                |
| Usage within component         |                                                                                                                                                                                                                                                |
| Usage within openDesk          |                                                                                                                                                                                                                                                |
| Usage for external integration |                                                                                                                                                                                                                                                |
| Parallel access                | Allowed                                                                                                                                                                                                                                        |
| Message protocol               | [Univention Management Console Protocol (UMCP)](https://docs.software-univention.de/ucs-python-api/univention.management.console.protocol.html). Format consisting of a single header line, one empty line and the body. The body can be JSON. |
| Supported standards            |                                                                                                                                                                                                                                                |
| Documentation                  | https://docs.software-univention.de/ucs-python-api/modules.html                                                                                                                                                                                |

## UMC store API

| Name                           | UMC store API (also named UMC JavaScript API or Dojo/UMC JavaScript API)                                  |
| ------------------------------ | --------------------------------------------------------------------------------------------------------- |
| Purpose                        | Encapsulate and ease the access to module data from JavaScript                                            |
| Versioning                     |                                                                                                           |
| Authentication                 |                                                                                                           |
| In openDesk provided by        | Nubus UMC                                                                                                 |
| Transport protocol             |                                                                                                           |
| Usage within component         |                                                                                                           |
| Usage within openDesk          |                                                                                                           |
| Usage for external integration |                                                                                                           |
| Parallel access                | Allowed                                                                                                   |
| Message protocol               |                                                                                                           |
| Supported standards            |                                                                                                           |
| Documentation                  | https://docs.software-univention.de/developer-reference/5.0/en/umc/local-system-module.html#umc-store-api |

## IntercomService (ICS) API

| Name                           | IntercomService API                                                                                                                                                                                                                 |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Encapsulate and ease the access to module data from JavaScript                                                                                                                                                                      |
| Versioning                     |                                                                                                                                                                                                                                     |
| Authentication                 | IdP based SSO                                                                                                                                                                                                                       |
| In openDesk provided by        | Nubus UMC                                                                                                                                                                                                                           |
| Transport protocol             | HTTP(S)                                                                                                                                                                                                                             |
| Usage within component         |                                                                                                                                                                                                                                     |
| Usage within openDesk          | The ICS implements the BFF pattern for various openDesk inter-component integrations, see also [components.md](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/develop/docs/components.md#component-integration) |
| Usage for external integration |                                                                                                                                                                                                                                     |
| Parallel access                | Allowed                                                                                                                                                                                                                             |
| Message protocol               | Depends on the integration use case.                                                                                                                                                                                                |
| Supported standards            |                                                                                                                                                                                                                                     |
| Documentation                  | https://docs.software-univention.de/intercom-service/latest/architecture.html                                                                                                                                                       |

## High-level Listener modules API

| Name                           | High-level Listener modules API                                                                                                                                                                                                     |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Dispatching of LDAP events.                                                                                                                                                                                                         |
| Versioning                     |                                                                                                                                                                                                                                     |
| Authentication                 |                                                                                                                                                                                                                                     |
| In openDesk provided by        | Univention Event Processing                                                                                                                                                                                                         |
| Transport protocol             |                                                                                                                                                                                                                                     |
| Usage within component         | The listener mechanism is used to dispatch events from the LDAP to the Nubus provisioning service. It should be replaced by another approach in the future.                                                                          |
| Usage within openDesk          | The ICS implements the BFF pattern for various openDesk inter-component integrations, see also [components.md](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/develop/docs/components.md#component-integration) |
| Usage for external integration |                                                                                                                                                                                                                                     |
| Parallel access                | Allowed                                                                                                                                                                                                                             |
| Message protocol               | Depends on the integration use case.                                                                                                                                                                                                |
| Supported standards            |                                                                                                                                                                                                                                     |
| Documentation                  | https://docs.software-univention.de/developer-reference/5.0/en/listener/api.html                                                                                                                                                    |

More details on the Nubus provisioning service can be found here: https://docs.software-univention.de/nubus-kubernetes-architecture/0.5/en/components/provisioning-service.html

## UDM Simple API

![Composition of UMC component with APIs highlighted](./apis_images/IAM-udm.png)

| Name                           | UDM Simple API                                                    |
| ------------------------------ | ----------------------------------------------------------------- |
| Purpose                        | Allows to use capability and objects directly in Python programs. |
| Versioning                     |                                                                   |
| Authentication                 |                                                                   |
| In openDesk provided by        | Univention Directory Manager                                      |
| Transport protocol             |                                                                   |
| Usage within component         |                                                                   |
| Usage within openDesk          |                                                                   |
| Usage for external integration |                                                                   |
| Parallel access                | Allowed                                                           |
| Message protocol               | Depends on the integration use case.                              |
| Supported standards            |                                                                   |
| Documentation                  |                                                                   |

## UDM REST API

| Name                           | UDM REST API                                                                                                                               |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Purpose                        | Inspect, modify, create and delete objects through HTTP requests.                                                                          |
| Versioning                     |                                                                                                                                            |
| Authentication                 | Basic Auth                                                                                                                                 |
| In openDesk provided by        | Univention Directory Manager                                                                                                               |
| Transport protocol             | HTTP(S)                                                                                                                                    |
| Usage within component         | The Nubus bootstrapping makes use of the API.                                                                                               |
| Usage within openDesk          |                                                                                                                                            |
| Usage for external integration | The [openDesk User Importer](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import) utilizes the API. |
| Parallel access                | Allowed                                                                                                                                    |
| Message protocol               | Depends on the integration use case.                                                                                                       |
| Supported standards            |                                                                                                                                            |
| Documentation                  | https://docs.software-univention.de/developer-reference/5.0/en/udm/rest-api.html                                                           |

## UCR Python API

![Composition of UCR component with APIs/interfaces highlighted](./apis_images/IAM-ucr.png)

| Name                           | UCR Python API                                                                                      |
| ------------------------------ | --------------------------------------------------------------------------------------------------- |
| Purpose                        | Offers a programming interface for components and other Python programs.                            |
| Versioning                     |                                                                                                     |
| Authentication                 |                                                                                                     |
| In openDesk provided by        | Nubus                                                                                               |
| Transport protocol             |                                                                                                     |
| Usage within component         | The Nubus bootstrapping makes use of the API.                                                       |
| Usage within openDesk          |                                                                                                     |
| Usage for external integration |                                                                                                     |
| Parallel access                | Allowed                                                                                             |
| Message protocol               |                                                                                                     |
| Supported standards            |                                                                                                     |
| Documentation                  | https://docs.software-univention.de/developer-reference/5.0/en/ucr/usage.html#using-ucr-from-python |

## LDAP

| Name                           | LDAP                                                                                                                   |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Read access to Nubus LDAP                                                                                              |
| Versioning                     | n/a                                                                                                                    |
| Authentication                 | LDAP user auth                                                                                                         |
| In openDesk provided by        | Nubus openLDAP                                                                                                         |
| Transport protocol             | LDAP                                                                                                                   |
| Usage within component         | Data backend for Nubus                                                                                                 |
| Usage within openDesk          | Used by multiple application to access user/group data, e.g. Nextcloud Server, OpenProject, OX AppSuite backend, XWiki |
| Usage for external integration | No recommended                                                                                                         |
| Parallel access                | Allowed                                                                                                                |
| Message protocol               | LDAP                                                                                                                   |
| Supported standards            | LDAP                                                                                                                   |
| Documentation                  | https://docs.software-univention.de/manual/5.0/en/domain-ldap/ldap-directory.html                                      |

## Nubus Provisioning Service (**TBD**)

To be delivered.

## Nubus Authorization Service (**TBD**)

To be delivered.

# Groupware - OX AppSuite / OX Dovecot

![OX AppSuite APIs overview](./apis_images/Groupware-apis.png)

![Use of OX AppSuite APIs by other components](./apis_images/Groupware-api-usage.png)

## Usage of APIs within openDesk

Following are APIs used by the Groupware application:

| Used by                        | Accessed component | Service            | Purpose                                                     | Message format                   |
| ------------------------------ | ------------------ | ------------------ | ----------------------------------------------------------- | -------------------------------- |
| AppSuite Middleware            | Keycloak           | Authentication     | Single sign-on / sign-out                                   | OIDC                             |
| Dovecot                        | Keycloak           | Authentication     | Authenticate user                                           | OIDC                             |
| AppSuite Frontend (in Browser) | Intercom Service   | Silent Login       | Stablish Intercom Service session                           |                                  |
| AppSuite Frontend (in Browser) | Intercom Service   | Central Navigation | Retrieve content for openDesk Navigation drop-down          | JSON                             |
| AppSuite Frontend (in Browser) | Intercom Service   | Element Bot        | Manage (CUD) meetings in Element                            | Custom JSON (based on iCalender) |
| AppSuite Frontend (in Browser) | Intercom Service   | Filepicker         | Read/write contents from/to Nextcloud or create share links | WebDAV & Nextcloud API           |
| AppSuite Middleware            | Nextcloud          | Filepicker         | Read/write files from/to Nextcloud                          | WebDAV & Nextcloud API           |
| AppSuite Middleware            | Element Bot        | Element Bot        | Update/delete meetings in Element                            | Custom JSON (based on iCalender) |
| AppSuite Middleware            | LDAP               | Address book       | Search for global contacts and retrieve contact details     | LDAP                             |
| Dovecot                        | LDAP               | Data retrieval     | Retrieve necessary user details to handle mailboxes         | LDAP                             |

## HTTP API

![Use of HTTP API in openDesk](./apis_images/Groupware-api-http-usage.png)

| Name                           | HTTP API                                                                                                                                                                                                     |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Login, accessing email, contacts, calendar, tasks, configs, email filtering, task automation, workflow automation, etc – most of the AppSuite's functionality that is available to the user through the Web-UI. |
| Versioning                     | No API-specific versioning. The version can be considered identical with OX App Suite version, which is contained in URL of online documentation of API.                                                        |
| Authentication                 |                                                                                                                                                                                                                 |
| In openDesk provided by        | OX AppSuite Middleware                                                                                                                                                                                          |
| Transport protocol             | HTTP(S)                                                                                                                                                                                                         |
| Usage within component         | Used by OX Web-UI (Frontend)                                                                                                                                                                                    |
| Usage within openDesk          | - Nextcloud used the SearchAPI to synchronize contacts<br>- Nordeck Meeting bot synchronizes OX meeting changes applied in Element.                                                                             |
| Usage for external integration | Not used at the moment, but recommended way to integrate with OX AppSuite.                                                                                                                                      |
| Parallel access                | Allowed                                                                                                                                                                                                         |
| Message protocol               | JSON based, AppSuite specific format                                                                                                                                                                            |
| Supported standards            | iCal, defined by RFC, fully implemented                                                                                                                                                                         |
| Documentation                  | https://documentation.open-xchange.com/components/middleware/http/8/index.html                                                                                                                                  |

## SOAP API

| Name                           | SOAP API                                                                                  |
| ------------------------------ | -------------------------------------------------------------------------------------------- |
| Purpose                        | Management of users, groups, contexts, resources.                                            |
| Versioning                     | n/a                                                                                          |
| Authentication                 | Basic Auth                                                                                   |
| In openDesk provided by        | OX AppSuite Middleware                                                                       |
| Transport protocol             | HTTP(S)                                                                                      |
| Usage within component         | none                                                                                         |
| Usage within openDesk          | OX-Connector synchronizes the state of the objects (users, groups etc.) managed in the LDAP. |
| Usage for external integration | none                                                                                         |
| Parallel access                | Allowed                                                                                      |
| Message protocol               | XML based, exactly following the format of Java RMI.                                         |
| Supported standards            | SOAP                                                                                         |
| Documentation                  | https://software.open-xchange.com/products/appsuite/doc/SOAP/admin/OX-Admin-SOAP.html        |

> **Note**:
> You will find a catalogue of the available services including links to the respective URLs at `/webservices/` within the AppSuite host of your openDesk installation, e.g. https://webmail.myopendesk.tld/webservices/

## REST API

| Name                           | REST API                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Delivers services in following functional groups:<br>- *Admin*: Interface for provisioning and other administrative operations<br>- *Advertisement*: The advertisement module<br>- *Health*: The health-check module<br>- *InternetFreeBusy*: Servlet for requesting free busy data<br>- *Metrics*: The metrics module<br>- *Preliminary*: This module contains preliminary endpoints which can change in the future<br>- *Push*: The push module<br>- *Userfeedback*: The user feedback module |
| Versioning                     | No API-specific versioning. The version can be considered identical with OX App Suite version, which is contained in URL of online documentation of API.                                                                                                                                                                                                                                                                                                                                        |
| Authentication                 | Basic Auth                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| In openDesk provided by        | OX AppSuite Middleware                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| Transport protocol             | HTTP(S)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| Usage within component         | Push module is used by OX Frontend.                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| Usage within openDesk          | none                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Usage for external integration | none                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Parallel access                | Allowed                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| Message protocol               | - Email Body RFC 822 is used by Push<br>- Prometheus format is used by Metrics API<br>- API iCal format is used by InternetFreeBusy                                                                                                                                                                                                                                                                                                                                                             |
| Supported standards            | SOAP                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Documentation                  | https://documentation.open-xchange.com/components/middleware/rest/8/index.html                                                                                                                                                                                                                                                                                                                                                                                                                  |
## CardDAV

| Name                           | CardDAV                                                                                                                                                                 |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Designed for rich clients. Synchronization of contact entries in both directions (i.e. as a server and as a client); vCard import and export are available via OX HTTP API |
| Versioning                     | Yes, API version is specific to the version of underlying protocol                                                                                                         |
| Authentication                 |                                                                                                                                                                            |
| In openDesk provided by        | OX AppSuite Middleware                                                                                                                                                     |
| Transport protocol             | HTTP(S)                                                                                                                                                                    |
| Usage within component         | none                                                                                                                                                                       |
| Usage within openDesk          | none                                                                                                                                                                       |
| Usage for external integration | none                                                                                                                                                                       |
| Parallel access                | Allowed                                                                                                                                                                    |
| Message protocol               | vCard, defined by RFC, fully implemented                                                                                                                                   |
| Supported standards            |                                                                                                                                                                            |
| Documentation                  | https://documentation.open-xchange.com/8/middleware/miscellaneous/caldav_carddav.html                                                                                      |

## CalDAV

| Name                           | CalDAV                                                                                                                                                                  |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Designed for rich clients. Synchronization of contact entries in both directions (i.e. as a server and as a client); vCard import and export are available via OX HTTP API |
| Versioning                     | Yes, API version is specific to the version of underlying protocol                                                                                                         |
| Authentication                 |                                                                                                                                                                            |
| In openDesk provided by        | OX AppSuite Middleware                                                                                                                                                     |
| Transport protocol             | HTTP(S)                                                                                                                                                                    |
| Usage within component         | none                                                                                                                                                                       |
| Usage within openDesk          | none                                                                                                                                                                       |
| Usage for external integration | none                                                                                                                                                                       |
| Parallel access                | Allowed                                                                                                                                                                    |
| Message protocol               | iCal, defined by RFC, fully implemented                                                                                                                                    |
| Supported standards            | iTIP, iMIP                                                                                                                                                                 |
| Documentation                  | https://documentation.open-xchange.com/8/middleware/miscellaneous/caldav_carddav.html                                                                                      |

## IMAP

| Name                           | IMAP                                                               |
| ------------------------------ | ------------------------------------------------------------------ |
| Purpose                        | Used for retrieval of emails, designed for rich clients            |
| Versioning                     | Yes, API version is specific to the version of underlying protocol |
| Authentication                 |                                                                    |
| In openDesk provided by        | OX Dovecot                                                         |
| Transport protocol             | TCP                                                                |
| Usage within component         | Used by OX AppSuite middleware to read/write mail and folders      |
| Usage within openDesk          | none                                                               |
| Usage for external integration | Can be used by local IMAP clients (e.g. Thunderbird)               |
| Parallel access                | Allowed                                                            |
| Message protocol               | RFC 9051                                                           |
| Supported standards            | IMAP                                                               |
| Documentation                  | https://www.rfc-editor.org/rfc/rfc9051                             |

## POP3

| Name                           | POP3                                                               |
| ------------------------------ | ------------------------------------------------------------------ |
| Purpose                        | Used for retrieval of emails, designed for rich clients            |
| Versioning                     | Yes, API version is specific to the version of underlying protocol |
| Authentication                 |                                                                    |
| In openDesk provided by        | OX Dovecot                                                         |
| Transport protocol             | TCP                                                                |
| Usage within component         | none                                                               |
| Usage within openDesk          | none                                                               |
| Usage for external integration | Can be used by local POP3 clients (e.g. Thunderbird)               |
| Parallel access                | Allowed                                                            |
| Message protocol               | RFC 1939                                                           |
| Supported standards            | IMAP                                                               |
| Documentation                  | https://www.rfc-editor.org/rfc/rfc1939                             |

# Files - Nextcloud

![Nextcloud APIs](./apis_images/Files-api.png)

## Usage of APIs within openDesk

Following are APIs used by the Files application:

| Used by          | Accessed component     | Service                | Purpose                                            | Message format |
| ---------------- | ---------------------- | ---------------------- | -------------------------------------------------- | -------------- |
| Nextcloud Server | Keycloak               | Authentication         | Single sign-on / sign-out                          | OIDC           |
| Nextcloud Server | Nubus Portal           | Central Navigation     | Retrieve content for openDesk Navigation drop-down | JSON           |
| Nextcloud Server | OX AppSuite Middleware | OX HTTP API (Contacts) | Reading/writing personal contacts                  | JSON           |
| Nextcloud Server | Nubus                  | LDAP                   | Read users and groups data                         | LDAP           |

## OCS API

| Name                           | OCS API                                                                                                                                                                                                                                |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Obtain and/or manage user status, user preferences, shares, sharees, recommendations. API is likely to be extended to other use cases in the future. Nextcloud apps can extend the functionality of OCS API by providing new endpoints |
| Versioning                     | Identical with component release version                                                                                                                                                                                               |
| Authentication                 | Basic Auth or by passing a set of valid session cookies                                                                                                                                                                                |
| In openDesk provided by        | Nextcloud Server                                                                                                                                                                                                                       |
| Transport protocol             | HTTP(S)                                                                                                                                                                                                                                |
| Usage within component         | none                                                                                                                                                                                                                                   |
| Usage within openDesk          | Filepicker is using the API to create share links.                                                                                                                                                                                     |
| Usage for external integration | none                                                                                                                                                                                                                                   |
| Parallel access                | Allowed                                                                                                                                                                                                                                |
| Message protocol               | Requests in JSON, responses in JSON or XML                                                                                                                                                                                             |
| Supported standards            |                                                                                                                                                                                                                                        |
| Documentation                  | https://docs.nextcloud.com/server/latest/developer_manual/client_apis/OCS/index.html                                                                                                                                                   |

## Notifications API

| Name                           | Notifications API                                                                                                           |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Fetch notifications                                                                                                         |
| Versioning                     | See linked documentation (which also names the version), address via URL path, e.g. `/ocs/v2.php/apps/notifications/api/v2` |
| Authentication                 |                                                                                                                             |
| In openDesk provided by        | Nextcloud Server                                                                                                            |
| Transport protocol             | HTTP(S)                                                                                                                     |
| Usage within component         | none                                                                                                                        |
| Usage within openDesk          | none                                                                                                                        |
| Usage for external integration | none                                                                                                                        |
| Parallel access                | Allowed                                                                                                                     |
| Message protocol               | Requests in JSON, responses in JSON or XML                                                                                  |
| Supported standards            |                                                                                                                             |
| Documentation                  | https://github.com/nextcloud/notifications/blob/master/docs/ocs-endpoint-v2.md                                              |
|                                |                                                                                                                             |

## Activity API

| Name                           | Activity API                                                                                                                                           |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Purpose                        | Allows to obtain the list of actions initiated or involving a specific user (files created, shared, deleted etc and other activities reported by apps) |
| Versioning                     | Identical with component release version                                                                                                               |
| Authentication                 | See linked documentation (which also names the version), address via URL path, e.g. `/ocs/v2.php/apps/activity/api/v2`                                 |
| In openDesk provided by        | Nextcloud Server                                                                                                                                       |
| Transport protocol             | HTTP(S)                                                                                                                                                |
| Usage within component         | none                                                                                                                                                   |
| Usage within openDesk          | none                                                                                                                                                   |
| Usage for external integration | none                                                                                                                                                   |
| Parallel access                | Allowed                                                                                                                                                |
| Message protocol               | Requests in JSON, responses in JSON or XML                                                                                                             |
| Supported standards            |                                                                                                                                                        |
| Documentation                  | https://github.com/nextcloud/activity/blob/master/docs/endpoint-v2.md                                                                                  |

## Remote wipe API

| Name                           | Remote wipe API                                                                             |
| ------------------------------ | ------------------------------------------------------------------------------------------- |
| Purpose                        | Used to wipe storage remotely (e.g. on a lost device)                                       |
| Versioning                     | Identical with component release version                                                    |
| Authentication                 | Login flow token                                                                            |
| In openDesk provided by        | Nextcloud Server                                                                            |
| Transport protocol             | HTTP(S)                                                                                     |
| Usage within component         | none                                                                                        |
| Usage within openDesk          | none                                                                                        |
| Usage for external integration | none                                                                                        |
| Parallel access                | Allowed                                                                                     |
| Message protocol               | JSON                                                                                        |
| Supported standards            |                                                                                             |
| Documentation                  | https://docs.nextcloud.com/server/latest/developer_manual/client_apis/RemoteWipe/index.html |

## WebDAV

| Name                           | WebDAV                                                                                  |
| ------------------------------ | --------------------------------------------------------------------------------------- |
| Purpose                        | Accessing files and folders, conducting search                                          |
| Versioning                     | Identical with component release version                                                |
| Authentication                 | Basic Auth or by passing a set of valid session cookies                                 |
| In openDesk provided by        | Nextcloud Server                                                                        |
| Transport protocol             | HTTP(S)                                                                                 |
| Usage within component         | none                                                                                    |
| Usage within openDesk          | Used by OX AppSuite to put/retrieve files (attachments)                                 |
| Usage for external integration | none                                                                                    |
| Parallel access                | Allowed                                                                                 |
| Message protocol               | Requests in JSON, responses in JSON or XML                                              |
| Supported standards            | RFC4918                                                                                 |
| Documentation                  | https://docs.nextcloud.com/server/latest/developer_manual/client_apis/WebDAV/index.html |

## CalDAV / CardDAV

CalDAV and CardDAV APIs are available in Nextcloud, but as openDesk uses OX AppSuite for Calendar and Contacts these Nextcloud APIs do not provide relevant data in openDesk.

# Weboffice - Collabora

Following are APIs used by the Weboffice application:

| Used by   | Accessed component | Service           | Purpose                                     | Message format |
| --------- | ------------------ | ----------------- | ------------------------------------------- | -------------- |
| Collabora | Nextcloud          | Document handling | Retrieve, store and manage office documents | WOPI           |

Collabora is integrated with Nextcloud to read/write Office documents from/to Nextcloud. The integration uses the Web
Application Open Interface ([WOPI](https://learn.microsoft.com/en-us/openspecs/office_protocols/ms-wopi/6a8bb410-68ad-47e4-9dc3-6cf29c6b046b)) protocol.

Nextcloud acts as the WOPI server whereas Collabora Online is the WOPI client.

```mermaid
sequenceDiagram
    autonumber
    Browser->>Nextcloud: Open document "digital-strategy.odt"<br>(which is fileid=123456)
    Nextcloud-->>Browser: "Use COOL server to open document online<br>URL is https://office.domain.tld/?open"
    Browser->>Collabora: GET "https://office.domain.tld/?open&file=https://files.domain.tld/index.php/apps/richdocuments/wopi/files/123456"
    Collabora-->>Nextcloud: GET https://files.domain.tld/index.php/apps/richdocuments/wopi/files
    Nextcloud-->>Browser: Edit document "digital-strategy.odt" (fileid=123456)
```


## PostMessage API

| Name                           | PostMessage API                                                                                                                                 |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Interact with parent frame when Collabora browser part is enclosed in one, mostly based on WOPI specification with few extensions/modifications |
| Versioning                     | N/A                                                                                                                                             |
| Authentication                 | CSP rules protect unauthorized communication. In practice editor is embedded in an iframe and can communicate only with the iframe's parent.    |
| In openDesk provided by        | Collabora                                                                                                                                       |
| Transport protocol             | HTTP                                                                                                                                            |
| Usage within component         | N/A                                                                                                                                             |
| Usage within openDesk          | Query number of users in a document, query supported export formats, manage sessions, manage actions like save, insert image, print etc.        |
| Usage for external integration | In openDesk Collabora Online is integrated with Nextcloud but other integrations exist and are possible, see the documentation.                 |
| Parallel access                | Allowed                                                                                                                                         |
| Message protocol               | JSON                                                                                                                                            |
| Supported standards            | [WOPI](https://learn.microsoft.com/en-us/openspecs/office_protocols/ms-wopi/6a8bb410-68ad-47e4-9dc3-6cf29c6b046b)                               |
| Documentation                  | https://sdk.collaboraonline.com/docs/postmessage_api.html                                                                                       |

## Conversion API

| Name                           | Conversion API                                                                                          |
| ------------------------------ | ------------------------------------------------------------------------------------------------------- |
| Purpose                        | Convert files between various file formats (e.g. to pdf, png, txt, or between OOXML and ODF etc.)       |
| Versioning                     | N/A                                                                                                     |
| Authentication                 | The `convert-to` endpoint is restricted to allowed host addresses that can be set in the configuration. |
| In openDesk provided by        | Collabora                                                                                               |
| Transport protocol             | HTTP (REST API)                                                                                         |
| Usage within component         | N/A                                                                                                     |
| Usage within openDesk          | To generate thumbnails in Nextcloud for supported document types.                                       |
| Usage for external integration | It is possible to set up Collabora Online as a general document converter service.                      |
| Parallel access                | Allowed                                                                                                 |
| Message protocol               | text based, see the documentation                                                                                                        |
| Supported standards            | N/A                                                                                                     |
| Documentation                  | https://sdk.collaboraonline.com/docs/conversion_api.html                                                |

# Project management - OpenProject

Following are APIs used by the Project management application:

| Used by         | Accessed component | Service            | Purpose                                            | Message format |
| --------------- | ------------------ | ------------------ | -------------------------------------------------- | -------------- |
| OpenProject-web | Keycloak           | Authentication     | Single sign-on / sign-out                          | OIDC           |
| OpenProject-web | Nubus Portal       | Central Navigation | Retrieve content for openDesk Navigation drop-down | JSON           |
| OpenProject-web | Nextcloud          | Various            | Integration of Nextcloud as OpenProject filestore  | JSON           |
| OpenProject-web | Nubus              | LDAP               | Read users and groups data                         | LDAP           |

## HATEOAS API

| Name                           | HATEOAS (Hyperimages as the Engine of Application State) API                                                                                                                                                                                                                                                                                      |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Provides access for the frontend client of OpenProject and for third party use, i.e.:<br>- CRUD work packages, projects, time logging, users, queries (work package filters), and all related objects<br>- READ notifications, activities per work package<br>- READ capabilities (allowed actions of users throughout projects) does not address |
| Versioning                     | URL based versioning scheme, e.g. `/api/v3/spec.json`                                                                                                                                                                                                                                                                                             |
| Authentication                 | OAuth2, session based authentication, and basic auth                                                                                                                                                                                                                                                                                              |
| In openDesk provided by        | OpenProject                                                                                                                                                                                                                                                                                                                                       |
| Transport protocol             | HTTP(S)                                                                                                                                                                                                                                                                                                                                           |
| Usage within component         | OpenProject Web-UI                                                                                                                                                                                                                                                                                                                                |
| Usage within openDesk          | none                                                                                                                                                                                                                                                                                                                                              |
| Usage for external integration | none                                                                                                                                                                                                                                                                                                                                              |
| Parallel access                | Allowed                                                                                                                                                                                                                                                                                                                                           |
| Message protocol               | [HAL](https://en.wikipedia.org/wiki/Hypertext_Application_Language) + JSON                                                                                                                                                                                                                                                                        |
| Supported standards            | REST, [HATEOAS](https://en.wikipedia.org/wiki/HATEOAS)                                                                                                                                                                                                                                                                                            |
| Documentation                  | https://www.openproject.org/docs/api/introduction/                                                                                                                                                                                                                                                                                                |

**Additional Information:**

*What does it not do that developers should know about?*
- CRUD custom fields, time reports, wikis and wiki pages
- Aggregated filterable activities/changes

*What are the typical use cases?*
- It powers all angular frontend components in OpenProject, mainly the work package table/view, boards, team planner etc., and supports all common use cases

*How does it work? (What do users need to know about architecture an internal components?)*
- HAL is a standard to define resources with embedding and links between them
- HAL contains action links depending on the user’s permissions, allows to derive allowed actions from object keys in json

*What knowledge prerequisites for the developer before using the API?*
- Knowledge of REST
- (Optional) Knowledge of HAL standard

*Any extensions or APIs in development or in planning users should know about?*
- Signaling to receive only selected attributes/nested resources from the API for performance improvements

## BCF API

| Name                           | BCF API                                                                                                                                                                            |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Implementation of subset of [BCF](https://en.wikipedia.org/wiki/BIM_Collaboration_Format) standard for [BIM](https://en.wikipedia.org/wiki/Building_information_modeling) projects |
| Versioning                     | URL based versioning scheme, e.g. `/api/bcf/2.1`                                                                                                                                   |
| Authentication                 | OAuth2                                                                                                                                                                             |
| In openDesk provided by        | OpenProject                                                                                                                                                                        |
| Transport protocol             | HTTP(S)                                                                                                                                                                            |
| Usage within component         | none                                                                                                                                                                               |
| Usage within openDesk          | none                                                                                                                                                                               |
| Usage for external integration | none                                                                                                                                                                               |
| Parallel access                | Allowed                                                                                                                                                                            |
| Message protocol               | JSON                                                                                                                                                                               |
| Supported standards            | [BCF 2.1](https://github.com/buildingSMART/BCF-API/blob/release_2_1/README.md)                                                                                                     |
| Documentation                  | https://www.openproject.org/docs/api/bcf-rest-api/                                                                                                                                 |

# Video Conferencing - Jitsi

## IFrame API

| Name                           | IFrame API                                                             |
| ------------------------------ | ---------------------------------------------------------------------- |
| Purpose                        | Embed Jitsi video conferencing features into existing application/site |
| Versioning                     | Identical to the Jitsi release version                                 |
| Authentication                 | Optional (JWT-based authentication in openDesk context)                |
| In openDesk provided by        | Jitsi-Web                                                              |
| Transport protocol             | HTTP(S)                                                                |
| Usage within component         | none                                                                   |
| Usage within openDesk          | Used by Element (Chat Web-UI)                                          |
| Usage for external integration | none                                                                   |
| Parallel access                | Allowed                                                                |
| Message protocol               |                                                                        |
| Supported standards            |                                                                        |
| Documentation                  | https://jitsi.github.io/handbook/docs/dev-guide/dev-guide-iframe/      |

## lib-jitsi-meet API

| Name                           | lib-jitsi-meet API                                                     |
| ------------------------------ | ---------------------------------------------------------------------- |
| Purpose                        | Create Jitsi video conferences with a custom GUI                       |
| Versioning                     | Identical to the Jitsi release                                         |
| Authentication                 | not required                                                           |
| In openDesk provided by        | Jitsi-Web                                                              |
| Transport protocol             | none (it works as a library)                                           |
| Usage within component         | Used by Jitsi itself                                                   |
| Usage within openDesk          | Used by Jitsi itself                                                   |
| Usage for external integration | none                                                                   |
| Parallel access                | Allowed                                                                |
| Message protocol               |                                                                        |
| Supported standards            |                                                                        |
| Documentation                  | https://jitsi.github.io/handbook/docs/dev-guide/dev-guide-ljm-api/     |

## Jitsi Meet React SDK

> **Note**<br>
> Additional SDKs can be found at https://jitsi.github.io/handbook/docs/category/sdks/

| Name                           | Meet React SDK                                                      |
| ------------------------------ | ------------------------------------------------------------------- |
| Purpose                        | Embed Jitsi video conferencing into apps using React                |
| Versioning                     | https://github.com/jitsi/jitsi-meet-react-sdk/releases              |
| Authentication                 | not required                                                        |
| In openDesk provided by        | Jitsi                                                               |
| Transport protocol             | none (it works as a module)                                         |
| Usage within component         | none                                                                |
| Usage within openDesk          | none                                                                |
| Usage for external integration | none                                                                |
| Parallel access                | Allowed                                                             |
| Message protocol               |                                                                     |
| Supported standards            |                                                                     |
| Documentation                  | https://jitsi.github.io/handbook/docs/dev-guide/dev-guide-react-sdk |

# Chat - Element

While Jitsi is available as standalone videoconferencing in openDesk, it is also used in [Element as videoconferencing backend](https://github.com/element-hq/element-web/blob/develop/docs/jitsi.md).

![APIs of Element and Jitsi providing Communication Service](./apis_images/ChatVC-overview.png)

Following are APIs used by the Chat application:

| Used by         | Accessed component | Service            | Purpose                                            | Message format |
| --------------- | ------------------ | ------------------ | -------------------------------------------------- | -------------- |
| Element/Synapse | Keycloak           | Authentication     | Single sign-on / sign-out                          | OIDC           |
| OpenProject-web | Intercom Service   | Central Navigation | Retrieve content for openDesk Navigation drop-down | JSON           |

## Matrix Application Service API

| Name                           | Matrix Application Service API                                                                                                               |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Implementation of custom server-side behavior in Matrix (e.g. gateways, filters, extensible hooks)                                           |
| Versioning                     | URL based with version bumps on breaking changes (e.g. `/_matrix/app/v1`)                                                                    |
| Authentication                 | HTTP-Authorization header with Bearer token                                                                                                  |
| In openDesk provided by        | Synapse                                                                                                                                      |
| Transport protocol             | HTTP(S)                                                                                                                                      |
| Usage within component         | none                                                                                                                                         |
| Usage within openDesk          | Nordeck Widgets                                                                                                                              |
| Usage for external integration | none                                                                                                                                         |
| Parallel access                | Allowed                                                                                                                                      |
| Message protocol               | JSON                                                                                                                                         |
| Supported standards            | [Matrix](https://spec.matrix.org/latest/application-service-api/)                                                                            |
| Documentation                  | [Synapse](https://element-hq.github.io/synapse/latest/) is the reference implementation of the Matrix protocol, see standard for API details |

## Matrix Client-Server API

| Name                           | Matrix Client-Server API                                                                                                                     |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Send messages, control rooms and synchronize conversation history, JSON objects over HTTP                                                    |
| Versioning                     | URL based with version bumps on breaking changes (e.g. `/_matrix/client/v3`)                                                                 |
| Authentication                 | HTTP-Authorization header with Bearer token                                                                                                  |
| In openDesk provided by        | Synapse                                                                                                                                      |
| Transport protocol             | HTTP(S)                                                                                                                                      |
| Usage within component         | none                                                                                                                                         |
| Usage within openDesk          | Used by Element (Chat Web-UI)                                                                                                                |
| Usage for external integration | none                                                                                                                                         |
| Parallel access                | Allowed                                                                                                                                      |
| Message protocol               | JSON                                                                                                                                         |
| Supported standards            | [Matrix](https://spec.matrix.org/latest/client-server-api/)                                                                                  |
| Documentation                  | [Synapse](https://element-hq.github.io/synapse/latest/) is the reference implementation of the Matrix protocol, see standard for API details |

## Matrix Server-Server API

| Name                           | Matrix Server-Server API                                                                                                                     |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Communication between Matrix server (also known as FederationAPIs)                                                                           |
| Versioning                     | URL based with version bumps on breaking changes (e.g. `/_matrix/federation/v2`)                                                             |
| Authentication                 | HTTP-Authorization header with Bearer token                                                                                                  |
| In openDesk provided by        | Synapse                                                                                                                                      |
| Transport protocol             | HTTP(S)                                                                                                                                      |
| Usage within component         | none                                                                                                                                         |
| Usage within openDesk          | none                                                                                                                                         |
| Usage for external integration | Used when federation with other Matrix instances is enabled                                                                                  |
| Parallel access                | Allowed                                                                                                                                      |
| Message protocol               | JSON                                                                                                                                         |
| Supported standards            | [Matrix](https://spec.matrix.org/latest/client-server-api/)                                                                                  |
| Documentation                  | [Synapse](https://element-hq.github.io/synapse/latest/) is the reference implementation of the Matrix protocol, see standard for API details |

## Matrix Push Gateway API

| Name                           | Matrix Push Gateway API                                                                                                                      |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Distribute notifications from the homeserver to clients (push)                                                                               |
| Versioning                     | URL based with version bumps on breaking changes (e.g. `/_matrix/push/v2`)                                                                   |
| Authentication                 |                                                                                                                                              |
| In openDesk provided by        | Synapse                                                                                                                                      |
| Transport protocol             | HTTP(S)                                                                                                                                      |
| Usage within component         | none                                                                                                                                         |
| Usage within openDesk          | Used by Element (Chat Web-UI)                                                                                                                |
| Usage for external integration | none                                                                                                                                         |
| Parallel access                | Allowed                                                                                                                                      |
| Message protocol               | JSON                                                                                                                                         |
| Supported standards            | [Matrix](https://spec.matrix.org/latest/push-gateway-api/)                                                                                   |
| Documentation                  | [Synapse](https://element-hq.github.io/synapse/latest/) is the reference implementation of the Matrix protocol, see standard for API details |

## Matrix Identity Service API

| Name                           | Matrix Identity Service API                                                                                                                  |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Validate, store, and answer questions about the identities of users                                                                          |
| Versioning                     | URL based with version bumps on breaking changes (e.g. `/_matrix/identity/v2`)                                                               |
| Authentication                 | HTTP-Authorization header with Bearer token                                                                                                  |
| In openDesk provided by        | Synapse                                                                                                                                      |
| Transport protocol             | HTTP(S)                                                                                                                                      |
| Usage within component         | none                                                                                                                                         |
| Usage within openDesk          |                                                                                                                                              |
| Usage for external integration | none                                                                                                                                         |
| Parallel access                | Allowed                                                                                                                                      |
| Message protocol               | JSON                                                                                                                                         |
| Supported standards            | [Matrix](https://spec.matrix.org/latest/identity-service-api/)                                                                               |
| Documentation                  | [Synapse](https://element-hq.github.io/synapse/latest/) is the reference implementation of the Matrix protocol, see standard for API details |

# Knowledge management - XWiki

Following are APIs used by the Knowledge management application:

| Used by | Accessed component | Service            | Purpose                                            | Message format |
| ------- | ------------------ | ------------------ | -------------------------------------------------- | -------------- |
| Xwiki   | Keycloak           | Authentication     | Single sign-on / sign-out                          | OIDC           |
| Xwiki   | Nubus Portal       | Central Navigation | Retrieve content for openDesk Navigation drop-down | JSON           |
| Xwiki   | Nubus              | LDAP               | Read users and groups data                         | LDAP           |

## REST API

| Name                           | REST API                                                                                                                                                                                                                                                   |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Perform low level action, e.g. interact with XWiki stored data                                                                                                                                                                                             |
| Versioning                     |                                                                                                                                                                                                                                                            |
| Authentication                 | Anonymous or username/password on each request (stateless)                                                                                                                                                                                                 |
| In openDesk provided by        | XWiki                                                                                                                                                                                                                                                      |
| Transport protocol             | HTTP(S)                                                                                                                                                                                                                                                    |
| Usage within component         |                                                                                                                                                                                                                                                            |
| Usage within openDesk          | none                                                                                                                                                                                                                                                       |
| Usage for external integration | none                                                                                                                                                                                                                                                       |
| Parallel access                | Allowed                                                                                                                                                                                                                                                    |
| Message protocol               | JSON/XML                                                                                                                                                                                                                                                   |
| Supported standards            |                                                                                                                                                                                                                                                            |
| Documentation                  | - https://www.xwiki.org/xwiki/bin/view/Documentation/UserGuide/Features/XWikiRESTfulAPI<br>- https://github.com/xwiki/xwiki-platform/blob/master/xwiki-platform-core/xwiki-platform-rest/xwiki-platform-rest-model/src/main/resources/xwiki.rest.model.xsd |

## Scripting API

| Name                           | Scripting API                                                                                                                                                                 |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Feature-rich API to access any module, use any functionality, modify existing functionality; allows definition of new REST API endpoints - API scope is identical to Java API |
| Versioning                     |                                                                                                                                                                               |
| Authentication                 | Executed in context of (authenticated) user or anonymous - permissions (scripting rights, programming rights) of that context apply                                           |
| In openDesk provided by        | XWiki                                                                                                                                                                         |
| Transport protocol             |                                                                                                                                                                               |
| Usage within component         |                                                                                                                                                                               |
| Usage within openDesk          | none                                                                                                                                                                          |
| Usage for external integration | Not supported                                                                                                                                                                 |
| Parallel access                | Allowed                                                                                                                                                                       |
| Message protocol               |                                                                                                                                                                               |
| Supported standards            |                                                                                                                                                                               |
| Documentation                  | https://extensions.xwiki.org/xwiki/bin/view/Extension/Scripting%20Documentation%20Application                                                                                 |

## Java API

| Name                           | Java API                                                                                                                                                                           |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                        | Feature-rich API to access any module, use any functionality, modify existing functionality; allows definition of new REST API endpoints - API scope is identical to Scripting API |
| Versioning                     |                                                                                                                                                                                    |
| Authentication                 | Executed in context of (authenticated) user or anonymous - but without the permission check (in opposite to the Scripting API)                                                     |
| In openDesk provided by        | XWiki                                                                                                                                                                              |
| Transport protocol             |                                                                                                                                                                                    |
| Usage within component         |                                                                                                                                                                                    |
| Usage within openDesk          | none                                                                                                                                                                               |
| Usage for external integration | none                                                                                                                                                                               |
| Parallel access                | Allowed                                                                                                                                                                            |
| Message protocol               |                                                                                                                                                                                    |
| Supported standards            |                                                                                                                                                                                    |
| Documentation                  | https://www.xwiki.org/xwiki/bin/view/Documentation/DevGuide/API/                                                                                                                   |

## JavaScript API

| Name                           | Javascript API                                                                               |
| ------------------------------ | -------------------------------------------------------------------------------------------- |
| Purpose                        | Include dynamic components in XWiki/web pages                                                |
| Versioning                     |                                                                                              |
| Authentication                 | Executed in context of (authenticated) user or anonymous                                     |
| In openDesk provided by        | Jitsi                                                                                        |
| Transport protocol             |                                                                                              |
| Usage within component         |                                                                                              |
| Usage within openDesk          | none                                                                                         |
| Usage for external integration | none                                                                                         |
| Parallel access                | Allowed                                                                                      |
| Message protocol               |                                                                                              |
| Supported standards            |                                                                                              |
| Documentation                  | https://www.xwiki.org/xwiki/bin/view/Documentation/DevGuide/FrontendResources/JavaScriptAPI/ |
