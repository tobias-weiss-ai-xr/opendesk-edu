#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""
Role Synchronization Engine for Semester Lifecycle Management
Engine to sync user roles between Keycloak and LMS platforms.

- EN: Maps Keycloak realm roles to LMS roles according to a defined mapping.
- ES: Mapea roles de Keycloak a roles en LMS según un mapeo definido.
"""

from __future__ import annotations

from typing import Any, Dict, Optional
from pydantic import BaseModel


class KCUser(BaseModel):
    """Keycloak user representation used for syncing.

    EN: Minimal representation containing user id and the roles from Keycloak.
    ES: Representación mínima que contiene el id de usuario y los roles de Keycloak.
    """

    id: str
    realm_roles: list[str]


class LMSUser(BaseModel):
    """LMS user representation after mapping.

    EN: Contains user id and the mapped LMS roles.
    ES: Contiene el id de usuario y los roles mapeados para el LMS.
    """

    id: str
    roles: list[str]


class RoleSyncEngine:
    """Engine to synchronize roles from Keycloak to LMS.

    EN: Keeps user roles in LMS aligned with Keycloak realm roles using a defined mapping.
    ES: Mantiene los roles de los usuarios en el LMS alineados con los roles del reino de Keycloak usando un mapeo definido.
    """

    def __init__(
        self,
        lms_client: Any,
        kc_client: Optional[object] = None,
        mapping: Optional[Dict[str, str]] = None,
    ) -> None:
        self.lms_client = lms_client
        self.kc_client = kc_client
        self.role_map: Dict[str, str] = mapping or {
            "student": "student",
            "tutor": "tutor",
            "lecturer": "instructor",
        }

    def _map_roles(self, kc_roles: list[str]) -> list[str]:
        """Map Keycloak roles to LMS roles according to self.role_map, deduplicated and ordered.

        EN: Returns the mapped roles with duplicates removed while preserving order.
        ES: Devuelve los roles mapeados quitando duplicados y preservando el orden.
        """
        mapped: list[str] = []
        for r in kc_roles:
            if r in self.role_map:
                mapped.append(self.role_map[r])
        # Deduplicate while preserving order
        seen = set()
        result: list[str] = []
        for r in mapped:
            if r not in seen:
                seen.add(r)
                result.append(r)
        return result

    def sync(self, users: list[KCUser]) -> list[LMSUser]:
        """Synchronize a list of Keycloak users to LMS, returning LMSUser records.

        EN: For each KCUser, compute mapped LMS roles and push to LMS via lms_client.
        ES: Para cada KCUser, calcular los roles LMS mapeados y enviarlos al LMS mediante lms_client.
        """
        results: list[LMSUser] = []
        for u in users:
            mapped = self._map_roles(u.realm_roles)
            if self.lms_client:
                self.lms_client.set_user_roles(u.id, mapped)
            results.append(LMSUser(id=u.id, roles=mapped))
        return results
