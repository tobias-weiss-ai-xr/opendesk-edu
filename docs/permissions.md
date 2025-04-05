<!--
SPDX-FileCopyrightText: 2025 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Roles & Permissions</h1>

openDesk uses role-based access control (RBAC) to manage permissions. This system ensures that users have access only to the resources necessary for their role.

<!-- TOC -->
* [Identity and Access Management (IAM)](#identity-and-access-management-iam)
  * [Permissions](#permissions)
  * [Roles](#roles)
    * [Application usage](#application-usage)
    * [Application administration](#application-administration)
  * [Groups](#groups)
    * [Global groups](#global-groups)
    * [Application groups](#application-groups)
      * [Standard access to applications](#standard-access-to-applications)
      * [Administrative access to applications](#administrative-access-to-applications)
    * [Custom groups](#custom-groups)
  * [Assigning roles/groups and permissions](#assigning-rolesgroups-and-permissions)
  * [Predefined roles / user templates](#predefined-roles--user-templates)
    * [*openDesk User*](#opendesk-user)
    * [*openDesk Administrator*](#opendesk-administrator)
  * [Managing permissions](#managing-permissions)
  * [Hierarchies and delegation](#hierarchies-and-delegation)
  * [Audit/Logging](#auditlogging)
  * [Reporting](#reporting)
  * [Delegation](#delegation)
  * [Regular review](#regular-review)
* [Applications](#applications)
  * [Roles/groups](#rolesgroups)
<!-- TOC -->

# Identity and Access Management (IAM)

Within openDesk's Identity and Access Management component Nubus the openDesk user accounts are managed, as well as some core roles and permissions.

## Permissions

A permission represents a specific authorization that defines an action a user is allowed to perform on a resource.

As openDesk consists of multiple applications, each application may have different needs regarding its fine-grained internal permissions, usually these permissions are manged within each component.

The overall permissions to access the application as well as group membership of users is managed in the IAM.

## Roles

Roles are defined sets of permissions that can be assigned to users. Each role corresponds to a specific set of tasks and responsibilities within the system. In openDesk's IAM, two roles are defined by default:

- **openDesk Administrator**: Manages openDesk-global settings, such as users and groups.
- **openDesk User**: Can login to openDesk to make use of defined openDesk applications.

> **Note**<br>
> It is strongly recommended that a user account is not granted both roles at the same time to address the segregation of duties, though it is not enforced by openDesk.

### Application usage

To access and use applications in openDesk and to address [the principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege), a user needs to have the necessary permissions set. openDesk defines the following permissions to access applications:

- **Groupware**: Use email, calendar and address book applications.
- **Chat**: Use the chat application.
- **Knowledge Management**: Use the wiki application.
- **Project Management**: Use the project management application.
- **File Sharing**: Use the file sharing application.
- **Video Conference**: Use the video conferencing application.

### Application administration

For applications that provide application-specific administrative settings, openDesk defines the following permissions:

- **Knowledge Management Admin**: Manage the wiki application.
- **Project Management Admin**: Manage the project management application settings.
- **File Sharing Admin**: Manage the file sharing administrative settings.

## Groups

Groups help in clustering users with similar responsibilities and enable easier assignment of roles or permissions. It is often the case that a group maps directly to a role.

openDesk predefines the following groups.

### Global groups

- **Domain Users**: Members of this group are *openDesk Users*.
- **Domain Admins**: Members of this group are *openDesk IAM Administrators*. By default this group is also enable for two-factor authentication (2FA).
- **2fa-users**: Members of this group that are forced to use two-factor authentication (2FA).
- **IAM API - Full Access**: Members of this group have full (read and write) access to the IAM's REST API.

### Application groups

When editing a user in the IAM you can select if a user can access or get elevated admin permission for a specific application within the "openDesk" tab. The selection is stored as an attribute on the user object, but for other applications it is helpful to also expose the information as a group membership. Therefore openDesk comes with the following [groups](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-nubus/-/blob/main/udm/udm-data-loader/63-groups.yaml).

To easily identify these groups all of them are prefixed with `managed-by-Attribute-`.

> **Note**<br>
> The membership of these groups is automatically managed, based on the user's attributes from the "openDesk" tab. So any changes directly to the groups will be overwritten, please always use the "openDesk" of the respective user. The IAM supports to edit user attributes in multiple accounts at once.

#### Standard access to applications

Unless a user is member of a group the respective application is not shown in the portal.

> **Note**<br>
> In openDesk's identity provider the required OIDC claims to access an application are only granted when the respective group membership is available. So even if a user who is not a member of an application group, knows the link to the application and calls it directly, the single sign-on will not be successful.

- **managed-by-Attribute-Groupware**: Members of this group have access to the groupware applications.
- **managed-by-Attribute-Fileshare**: Members of this group have access to the file sharing application.
- **managed-by-Attribute-Projectmanagement**: Members of this group have access to the project management application.
- **managed-by-Attribute-Knowledgemanagement**: Members of this group have access to the wiki application.
- **managed-by-Attribute-Livecollaboration**: Members of this group have access to the chat application.
- **managed-by-Attribute-Videoconference**: Members of this group have access to the video conferencing application.

#### Administrative access to applications

Within some applications it is possible to grant users elevated permissions, these are also primarily managed by attributes from the "openDesk" tab when editing a user, but are also automatically mapped to the following groups:

- **managed-by-Attribute-FileshareAdmin**: Members of this group can administrate the file sharing application.
- **managed-by-Attribute-ProjectmanagementAdmin**: Members of this group can administrate the project management application.
- **managed-by-Attribute-KnowledgemanagementAdmin**: Members of this group can administrate the wiki application.

### Custom groups

While openDesk ships with predefined groups, additional groups can be [created](https://docs.opendesk.eu/administration/gruppen/) by an *IAM Administrator*.

## Assigning roles/groups and permissions

Users get roles assigned based on their responsibilities and the tasks they need to perform. This assignment can be done by an admin through the [administration portal](https://docs.opendesk.eu/administration/).

## Predefined roles / user templates

openDesk defines [templates](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-nubus/-/blob/main/udm/udm-data-loader/65-usertemplate.yaml) for the *User* and *Administrator* roles. The templates can be used to create users with these roles by an *openDesk Administrator* using the [administration portal](https://docs.opendesk.eu/administration/).

> **Note**<br>
> Additional/custom templates can be created using the UDM REST API.

### *openDesk User*

The *openDesk User* template sets the primary group to *Domain Users* and initially sets the following permissions:

- **Groupware**: Enabled
- **Chat**: Enabled
- **Knowledge Management**: Enabled
- **Project Management**: Enabled
- **File Sharing**: Enabled
- **Video Conference**: Enabled
- **Knowledge Management Admin**: Disabled
- **Project Management Admin**: Disabled
- **File Sharing Admin**: Disabled

### *openDesk Administrator*

The *openDesk Administrator* template sets the primary group to *Domain Admins* and initially sets the following permissions:

- **Groupware**: Disabled
- **Chat**: Disabled
- **Knowledge Management**: Disabled
- **Project Management**: Disabled
- **File Sharing**: Disabled
- **Video Conference**: Disabled
- **Knowledge Management Admin**: Disabled
- **Project Management Admin**: Disabled
- **File Sharing Admin**: Disabled

## Managing permissions

*Administrators* can manage permissions of *Users* using the [administration portal](https://docs.opendesk.eu/administration/).

By using roles and permissions, openDesk ensures that users have the appropriate level of access, enhancing both security and efficiency.

## Hierarchies and delegation

The IAM allows the nesting of groups, in that case a group has no or not only users as members but other groups.

## Audit/Logging

Univention is about to provide an audit logging which brings the idea of the [UCS based directory logger](https://docs.software-univention.de/manual/5.0/en/domain-ldap/ldap-directory.html#audit-proof-logging-of-ldap-changes) to Nubus. openDesk will offer this feature as soon as it is made available in Nubus.

## Reporting

The IAM webinterface supports the export of reports for users and groups, which are the essential objects when it comes to permissions. These data exports can be subject to custom data analysis.

## Delegation

Currently the temporary assignment of roles is not supported. Role membership must be managed at the time of granting / revoking the membership.

## Regular review

While the overall role and permission setup must be checked by the customer including the respective custom roles, the openDesk team is challenging and improving the role and permission management on a regular basis, e.g. to address the need for a distinct "support" role.

# Applications

As managing all the application permissions within the IAM would require a superset of permissions to be available in the IAM causing a high level of administrative complexity, the permissions are usually managed within an application itself and mapped to roles/groups that are managed in the IAM.

## Roles/groups

For each IAM group it can be configured for which openDesk application the group should be visible. Like with users this is done in the "openDesk" tab of the [group administration](https://docs.opendesk.eu/administration/gruppen/).

> **Note**<br>
> Currently the openDesk applications do not support nested groups. As a result only direct group memberships of users are processed in the application.<br>
> The plan is to enable the openDesk applications to either support nested groups or to actively provision users into an application while resolving the nested group memberships for the application.

Within an application each available group can get a set of application specific permissions assigned.
