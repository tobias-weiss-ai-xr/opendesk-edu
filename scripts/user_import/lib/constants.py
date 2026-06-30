# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: AGPL-3.0-or-later

DEFAULT_REALM = "opendesk"
DEFAULT_KEYCLOAK_MASTER_REALM = "master"
DEFAULT_IDENTITY_PROVIDER = "saml-umr"

NON_RECONCILE_GROUPS = [
    "cn=Domain Admins,cn=groups,dc=swp-ldap,dc=internal",
    "cn=Domain Users,cn=groups,dc=swp-ldap,dc=internal",
    "cn=IAM API - Full Access,cn=groups,dc=swp-ldap,dc=internal",
    "cn=managed-by-attribute-Fileshare,cn=groups,dc=swp-ldap,dc=internal",
    "cn=managed-by-attribute-FileshareAdmin,cn=groups,dc=swp-ldap,dc=internal",
    "cn=managed-by-attribute-Groupware,cn=groups,dc=swp-ldap,dc=internal",
    "cn=managed-by-attribute-Knowledgemanagement,cn=groups,dc=swp-ldap,dc=internal",
    "cn=managed-by-attribute-KnowledgemanagementAdmin,cn=groups,dc=swp-ldap,dc=internal",
    "cn=managed-by-attribute-Livecollaboration,cn=groups,dc=swp-ldap,dc=internal",
    "cn=managed-by-attribute-Projectmanagement,cn=groups,dc=swp-ldap,dc=internal",
]
