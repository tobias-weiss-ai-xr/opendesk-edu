# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from functools import lru_cache
from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    api_host: str = "0.0.0.0"
    api_port: int = 8000
    api_debug: bool = False
    api_title: str = "Course Provisioning API"
    api_version: str = "1.0.0"

    ilias_api_url: Optional[str] = None
    ilias_api_user: Optional[str] = None
    ilias_api_key: Optional[str] = None

    moodle_api_url: Optional[str] = None
    moodle_api_token: Optional[str] = None

    keycloak_url: Optional[str] = None
    keycloak_realm: str = "opendesk-edu"
    keycloak_admin_user: Optional[str] = None
    keycloak_admin_password: Optional[str] = None
    keycloak_client_id: str = "admin-cli"

    hisinone_webhook_secret: Optional[str] = None
    hisinone_webhook_port: int = 8001


@lru_cache
def get_settings() -> Settings:
    return Settings()
