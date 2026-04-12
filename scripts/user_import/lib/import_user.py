# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

import base64
import glob
import random
import re
import sys
import logging
from typing import Any, Callable
import os.path
import pandas as pd

import requests

from lib.keycloak import link_saml_identity_with_credentials
from lib.constants import DEFAULT_IDENTITY_PROVIDER


class ImportUser:
    def __init__(
        self,
        callback: Callable[[dict[str, Any]], None],
        import_filename: str | None = None,
        iam_api_url: str | None = None,
        create_admin_accounts: bool = False,
        use_images: bool = False,
        password_recovery_email: str | None = None,
        keycloak_url: str | None = None,
        keycloak_username: str | None = None,
        keycloak_password: str | None = None,
        identity_provider: str = DEFAULT_IDENTITY_PROVIDER,
    ) -> None:
        self.input_dir_imgs_base = os.path.join(os.path.dirname(__file__), "..", "data", "images_")
        self.input_file = import_filename
        self.iam_api_url = iam_api_url
        self.keycloak_url = keycloak_url
        self.keycloak_username = keycloak_username
        self.keycloak_password = keycloak_password
        self.identity_provider = identity_provider
        self.password_recovery_email = password_recovery_email
        self.callback = callback
        self.create_admin_accounts = create_admin_accounts
        self.use_images = use_images

        self.columnnames_map = {
            "Username": "username",
            "Externe E-Mail": "email",
            "Vorname": "firstname",
            "Nachname": "lastname",
            "Anrede": "title",
            "Passwort": "password",
            "LDAP-Gruppen": "groups",
            "Organisationseinheit": "organisation",
            "Primäre Mailadresse": "mailPrimaryAddress",
            "OX Context": "oxContext",
        }

        persons = self._load_users()

        if persons is None or len(persons.index) == 0:
            logging.error("No user data loaded, aborting.")
            sys.exit(1)

        persons.rename(columns=self.columnnames_map, inplace=True)

        logging.info("Cleaning up list")

        error_count = 0
        for index, person in persons.iterrows():
            if person["email"] == 0:
                persons.drop(index, inplace=True)
                continue
            if not isinstance(person["username"], str):
                logging.error(f"Missing username in '{person}'")
                error_count += 1
                continue
            if person["username"].strip() != person["username"]:
                logging.warning(f"Leading or trailing blank(s) found in username email: '{person['username']}'")
                persons.at[index, "username"] = person["username"].strip()
            if person["email"].strip() != person["email"]:
                logging.warning(f"Leading or trailing blank(s) found in external email: '{person['email']}'")
                persons.at[index, "email"] = person["email"].strip()
            if "mailPrimaryAddress" in person and isinstance(person["mailPrimaryAddress"], str):
                if person["mailPrimaryAddress"].strip() != person["mailPrimaryAddress"]:
                    logging.warning(
                        f"Leading or trailing blank(s) found in internal email: '{person['mailPrimaryAddress']}'"
                    )
                    persons.at[index, "mailPrimaryAddress"] = person["mailPrimaryAddress"].strip()

        logging.info(f"Processing list with {len(persons.index)} lines.")
        logging.debug(f"Going to process the following list:\n{persons.to_string()}")

        for index, person in persons.iterrows():
            if not bool(re.match(r"^[\w\d\.-]+$", person["username"], flags=re.IGNORECASE)):
                logging.error(f"Found invalid characters in username: '{person['username']}'")
                error_count += 1
            if not bool(re.match(r"^[\w\d\.\-_]+@[\w\d\.\-_]+$", person["email"], flags=re.IGNORECASE)):
                logging.error(f"Found invalid external email: '{person['email']}'")
                error_count += 1
            if "mailPrimaryAddress" in person and isinstance(person["mailPrimaryAddress"], str):
                if not bool(
                    re.match(
                        r"^[\w\d\.\-_]+@[\w\d\.\-_]+$",
                        person["mailPrimaryAddress"],
                        flags=re.IGNORECASE,
                    )
                ):
                    logging.error(f"Found invalid primary email: '{person['mailPrimaryAddress']}'")
                    error_count += 1
            if "oxContext" in person and not pd.isna(persons.at[index, "oxContext"]):
                if not isinstance(person["oxContext"], (int, float)):
                    logging.error(
                        f"Invalid oxContext value for user '{person['username']}': {person['oxContext']}. Must be an integer."
                    )
                    error_count += 1

        if error_count > 0:
            sys.exit("! Found errors, please fix and rerun the script")

        for _, person in persons.iterrows():
            if self.password_recovery_email:
                person["email"] = self.password_recovery_email
            if "organisation" not in person or pd.isna(person["organisation"]):
                person["organisation"] = person["email"].rpartition("@")[-1]
            person["is_admin"] = False
            if use_images:
                person["jpegPhoto"] = self.__get_image()
            callback(person)
            if create_admin_accounts:
                person["username"] = person["username"] + "-admin"
                person["is_admin"] = True
                callback(person)

            if self.keycloak_url and self.keycloak_username and self.keycloak_password:
                link_saml_identity_with_credentials(
                    keycloak_url=self.keycloak_url,
                    username=person["username"],
                    admin_username=self.keycloak_username,
                    admin_password=self.keycloak_password,
                    identity_provider=self.identity_provider,
                )

    def _load_users(self) -> list[dict[str, Any]]:
        if self.iam_api_url:
            logging.info(f"Loading users from IAM API: {self.iam_api_url}")
            try:
                r = requests.get(self.iam_api_url, timeout=30)
                r.raise_for_status()
                provisioning_info = r.json()
                persons = pd.json_normalize(provisioning_info["accounts"])
                return persons
            except requests.RequestException as e:
                logging.error(f"Failed to fetch users from IAM API: {e}")
                sys.exit(1)

        if self.input_file and os.path.isfile(self.input_file):
            logging.info(f"Loading users from file: {self.input_file}")
            ext = os.path.splitext(self.input_file)[1].lower()
            if ext in (".ods",):
                persons = pd.read_excel(self.input_file, engine="odf", skiprows=self.skip_rows)
            elif ext in (".xlsx",):
                persons = pd.read_excel(self.input_file, engine="openpyxl")
            elif ext in (".csv",):
                persons = pd.read_csv(self.input_file, skiprows=self.skip_rows)
            else:
                logging.error(f"Unsupported file format: {ext}")
                sys.exit(1)
            return persons

        logging.error("No IAM API URL or import file specified, cannot load users.")
        return None

    def __get_image(self) -> str | None:
        if not hasattr(self, "input_filelist_img_list"):
            self.input_filelist_img_list = []
        if len(self.input_filelist_img_list) == 0:
            for gender in ("m", "f"):
                self.input_filelist_img_list.extend(glob.glob(self.input_dir_imgs_base + gender + "/*.jpg"))

        selected_image = random.choice(self.input_filelist_img_list)
        with open(selected_image, "rb") as image_file:
            return base64.b64encode(image_file.read()).decode()
