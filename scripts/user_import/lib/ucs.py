# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

import requests
import json
import sys
from datetime import datetime
from typing import Optional
import urllib.parse
import logging
import pandas as pd

from requests.auth import HTTPBasicAuth


class Ucs:
    def __init__(
        self,
        adm_username,
        adm_password,
        base_url,
        maildomain,
        options_object,
        ldap_base="dc=swp-ldap,dc=internal",
    ):
        self.user = None
        self.user_updated = False
        self.adm_username = adm_username
        self.adm_password = adm_password
        self.options_object = options_object
        self.maildomain = maildomain

        if self.options_object.enforce_ipv4:
            requests.packages.urllib3.util.connection.HAS_IPV6 = False

        if self.options_object.localhost_port:
            self.base_url = base_url
            self.request_url = "http://localhost:" + str(
                self.options_object.localhost_port
            )
            self.verify_certificate = False
            self.path_prefix = ""
            self.options_object.trigger_invitation_mail = False
        else:
            self.base_url = base_url
            self.request_url = "https://portal." + self.base_url
            self.verify_certificate = self.options_object.verify_certificate
            self.path_prefix = "/univention"

        self.user_base = "cn=users," + ldap_base
        self.group_base = "cn=groups," + ldap_base
        self.maildomain_base = "cn=domain,cn=mail," + ldap_base
        self.timestamp = datetime.now().strftime("%Y-%m-%dT%Hh%Mm%SZ")
        self.create_count = {"users": 0, "maildomains": 0, "groups": 0, "oxcontexts": 0}
        self.credentials_created = []

        if options_object.output_accounts_filename:
            self.account_output_filename = options_object.output_accounts_filename
        else:
            self.account_output_filename = (
                "users-" + self.base_url + "-" + self.timestamp + ".txt"
            )

        self.groups_available = []
        self.existing_maildomains = []
        self.existing_oxcontexts = []
        if self.options_object.create_maildomains:
            for maildomain_object in self.__get_object_list("mail", "domain"):
                self.existing_maildomains.append(maildomain_object["id"])
            logging.debug(
                f"Pre-existing maildomains: {', '.join(self.existing_maildomains)}"
            )
        if self.options_object.create_oxcontexts:
            for oxcontext_object in self.__get_object_list("oxmail", "oxcontext"):
                self.existing_oxcontexts.append(oxcontext_object["id"])
            logging.debug(
                f"Pre-existing OX contexts: {', '.join(self.existing_oxcontexts)}"
            )
        self.__get_user_schema()

    def __get_user_schema(self):
        response = self.__http_request(
            method="options",
            url_path=self.path_prefix + "/udm/users/user/",
            data=None,
            allowed_responses=[200],
        )
        self.user_schema = response.json()["components"]["schemas"][
            "users-user.request-patch"
        ]["properties"]["properties"]["properties"]

    def __get_object_list(self, basetype, type):
        response = self.__http_request(
            method="get",
            url_path=self.path_prefix
            + "/udm/"
            + basetype
            + "/"
            + type
            + "/?query[name]=*",
            data=None,
            allowed_responses=[200],
        )
        return response.json()["_embedded"]["udm:object"]

    def __get_object_json(self, type, dn):
        response = self.__http_request(
            method="get",
            url_path=self.path_prefix
            + "/udm/"
            + type
            + "s/"
            + type
            + "/"
            + urllib.parse.quote(dn),
            data=None,
            allowed_responses=[200, 404],
        )
        if response.status_code == 200:
            json = response.json()
            json["etag"] = response.headers["etag"]
            return json
        elif response.status_code == 404:
            return None
        else:
            logging.error(
                "Stopping due to response's http status " + str(response.status_code)
            )
            sys.exit(response.text)

    def __add_property(self, obj_json, person, key, list=False):
        if key in person and not pd.isna(person[key]):
            if list:
                obj_json["properties"][key] = [person[key]]
            else:
                obj_json["properties"][key] = person[key]

    def __get_checked_groups(self, groups):
        user_groups = []
        if not isinstance(groups, str):
            logging.info("No groups defined.")
        else:
            group_names = [tmp.strip() for tmp in groups.split(";")]
            for group_name in group_names:
                group_dn = "cn=" + group_name + "," + self.group_base
                if group_dn not in self.groups_available:
                    if not self.__get_object_json("group", group_dn):
                        logging.info(f"Creating group {group_name} / {group_dn}")
                        self.__create_group(group_name)
                    self.groups_available.append(group_dn)
                user_groups.append(group_dn)
        return user_groups

    def __http_request(
        self,
        method,
        url_path,
        data,
        query_param=None,
        allowed_responses=[200],
        http_header_additional={},
        exit_on_bad_response=True,
    ):
        http_headers = {
            "Accept": "application/json",
            "Content-Type": "application/json;charset=UTF-8",
        }
        http_headers.update(http_header_additional)
        logging.debug(f"Headers: {http_headers}")
        http_call = getattr(requests, method)
        url = self.request_url + url_path
        response = http_call(
            url,
            data=data,
            params=query_param,
            headers=http_headers,
            auth=HTTPBasicAuth(self.adm_username, self.adm_password),
            verify=self.verify_certificate,
        )
        if response.status_code not in allowed_responses:
            logging.error(f"1/2: Unexpected response: HTTP/{str(response.status_code)}")
            logging.error(f"2/2: Request body: {data}")
            if exit_on_bad_response:
                sys.exit(response.text)
        return response

    def __create_group(self, group_name):
        group_json = {
            "properties": {
                "name": group_name,
                "description": f"Created by openDesk User Import at {self.timestamp}",
                "opendeskFileshareEnabled": self.options_object.group_component_enable_fileshare,
                "opendeskProjectmanagementEnabled": self.options_object.group_component_enable_projectmanagement,
                "opendeskKnowledgemanagementEnabled": self.options_object.group_component_enable_knowledgemanagement,
            },
            "position": self.group_base,
        }
        allowed_responses = [
            201,
            422,
        ]
        response = self.__http_request(
            method="post",
            url_path=self.path_prefix + "/udm/groups/group/",
            data=json.dumps(group_json),
            allowed_responses=allowed_responses,
            exit_on_bad_response=False,
        )
        if response.status_code not in allowed_responses:
            logging.error(
                f"Response code not in {allowed_responses}: HTTP/{str(response.status_code)}"
            )
            sys.exit(response.text)
        elif response.status_code == 422:
            if "Object exists" in response.text:
                logging.warning(
                    f"Tried to create an already existing group f{group_name} - probably race condition with parallel running script."
                )
            else:
                logging.error("Response code 422 with unexpected body.")
                sys.exit(response.text)
        else:
            self.create_count["groups"] += 1
        logging.debug(f"{group_name}: {response}")

    def update_user(self, current_json, person):
        if "groups" in person:
            groups = self.__get_checked_groups(person["groups"])
        else:
            groups = []
        user_json = {
            "properties": {
                "groups": groups,
            },
            "position": self.user_base,
        }
        self.__http_request(
            method="patch",
            url_path=self.path_prefix + "/udm/users/user/" + current_json["dn"],
            data=json.dumps(user_json),
            allowed_responses=[204],
        )
        logging.debug(f"{person['username']}: has been updated.")

    def create_user(self, person):
        if "groups" in person:
            groups = self.__get_checked_groups(person["groups"])
        else:
            groups = []
        user_json = {
            "properties": {
                "isOxUser": (
                    not person["is_admin"]
                    and not self.options_object.component_disable_groupware
                ),
                "opendeskFileshareEnabled": (
                    not person["is_admin"]
                    and not self.options_object.component_disable_fileshare
                ),
                "opendeskProjectmanagementEnabled": (
                    not person["is_admin"]
                    and not self.options_object.component_disable_projectmanagement
                ),
                "opendeskKnowledgemanagementEnabled": (
                    not person["is_admin"]
                    and not self.options_object.component_disable_knowledgemanagement
                ),
                "opendeskLivecollaborationEnabled": (
                    not person["is_admin"]
                    and not self.options_object.component_disable_livecollaboration
                ),
                "opendeskVideoconferenceEnabled": (
                    not person["is_admin"]
                    and not self.options_object.component_disable_videoconference
                ),
                "opendeskNotesEnabled": (
                    not person["is_admin"]
                    and not self.options_object.component_disable_notes
                ),
                "opendeskFileshareAdmin": self.options_object.admin_enable_fileshare,
                "opendeskProjectmanagementAdmin": self.options_object.admin_enable_projectmanagement,
                "opendeskKnowledgemanagementAdmin": self.options_object.admin_enable_knowledgemanagement,
                "mailPrimaryAddress": person["username"] + "@" + self.maildomain
                if "mailPrimaryAddress" not in person
                or not isinstance(person["mailPrimaryAddress"], str)
                else person["mailPrimaryAddress"],
                "PasswordRecoveryEmail": person["email"],
                "oxContext": int(
                    person["oxContext"]
                    if "oxContext" in person and not pd.isna(person["oxContext"])
                    else self.options_object.default_oxcontext
                ),
                "oxAccess": "opendesk_standard",
                "disabled": False,
                "lastname": str(person["lastname"]),
                "password": str(person["password"]),
                "groups": groups,
                "username": str(person["username"]),
                "description": f"Created by openDesk User Import at {self.timestamp}",
                "firstname": str(person["firstname"]),
            },
            "position": self.user_base,
        }

        keys = list(user_json["properties"].keys())
        for key in keys:
            if key not in self.user_schema:
                logging.debug(f"attribute {key} not supported, skipping.")
                del user_json["properties"][key]

        if self.options_object.create_maildomains:
            users_maildomain = user_json["properties"]["mailPrimaryAddress"].split("@")[
                -1
            ]
            if users_maildomain not in self.existing_maildomains:
                logging.info(f"Creating maildomain: {users_maildomain}")
                self.__http_request(
                    method="post",
                    url_path=self.path_prefix + "/udm/mail/domain/",
                    data=json.dumps(
                        {
                            "properties": {"name": users_maildomain},
                            "position": self.maildomain_base,
                        }
                    ),
                    allowed_responses=[201],
                )
                self.create_count["maildomains"] += 1
                self.existing_maildomains.append(users_maildomain)

        if self.options_object.create_oxcontexts:
            oxcontext = user_json["properties"]["oxContext"]
            if str(oxcontext) not in self.existing_oxcontexts:
                logging.info(f"Creating OX context: {oxcontext}")
                self.__http_request(
                    method="post",
                    url_path=self.path_prefix + "/udm/oxmail/oxcontext/",
                    data=json.dumps(
                        {
                            "properties": {
                                "name": f"{oxcontext}",
                                "contextid": int(oxcontext),
                                "oxQuota": None,
                            }
                        }
                    ),
                    allowed_responses=[201],
                )
                self.create_count["oxcontexts"] += 1
                self.existing_oxcontexts.append(str(oxcontext))

        if "is_admin" in person and person["is_admin"] is True:
            user_json["properties"]["primaryGroup"] = (
                "cn=Domain Admins,cn=groups,dc=swp-ldap,dc=internal"
            )
        else:
            user_json["properties"]["primaryGroup"] = (
                "cn=Domain Users,cn=groups,dc=swp-ldap,dc=internal"
            )

        self.__add_property(user_json, person, "title")
        self.__add_property(user_json, person, "jpegPhoto")
        self.__add_property(user_json, person, "organisation")
        self.__add_property(user_json, person, "street")
        self.__add_property(user_json, person, "postcode")
        self.__add_property(user_json, person, "city")
        self.__add_property(user_json, person, "departmentNumber", True)
        self.__add_property(user_json, person, "phone", True)
        self.__add_property(user_json, person, "roomNumber", True)
        self.__add_property(user_json, person, "mobileTelephoneNumber", True)

        response = self.__http_request(
            method="post",
            url_path=self.path_prefix + "/udm/users/user/",
            data=json.dumps(user_json),
            allowed_responses=[201],
        )
        response_json = json.loads(response.text)
        logging.debug(
            f"{person['username']}: {person['password']} - {response} - {response_json['uuid']}"
        )
        self.create_count["users"] += 1
        self.__write_account_credentials(person["username"] + "\t" + person["password"])

    def delete_user(self, username):
        dn = f"uid={username},{self.user_base}"
        current_json = self.__get_object_json("user", dn)

        if not current_json:
            logging.info(f"User {dn} does not exist. Skipping deletion.")
            return True

        try:
            response = self.__http_request(
                method="delete",
                url_path=f"{self.path_prefix}/udm/users/user/{urllib.parse.quote(dn)}",
                data=None,
                allowed_responses=[204, 404],
                exit_on_bad_response=False,
            )

            if response.status_code == 204:
                logging.info(f"User {username} deleted successfully.")
                return True
            elif response.status_code == 404:
                logging.warning(
                    f"User {username} was already deleted (race condition)."
                )
                return True
            else:
                logging.error(
                    f"Failed to delete user {username}. HTTP {response.status_code}"
                )
                return False

        except Exception as e:
            logging.exception(f"Exception during deletion of user {username}: {str(e)}")
            return False

    def get_user_dn(self, username: str) -> str:
        return f"uid={username},{self.user_base}"

    def get_user_groups(self, username: str) -> list:
        dn = self.get_user_dn(username)
        user_json = self.__get_object_json("user", dn)

        if (
            user_json
            and "properties" in user_json
            and "groups" in user_json["properties"]
        ):
            return user_json["properties"]["groups"]
        return []

    def disable_user(
        self, username: str, deprovision_timestamp: Optional[str] = None
    ) -> bool:
        dn = self.get_user_dn(username)
        current_json = self.__get_object_json("user", dn)

        if not current_json:
            logging.warning(f"User {username} not found, cannot disable")
            return False

        current_description = current_json["properties"].get("description", "")
        if deprovision_timestamp and "Deprovisioned on" in current_description:
            logging.info(f"User {username} already deprovisioned, skipping")
            return True

        new_description = current_description
        if deprovision_timestamp:
            if current_description:
                new_description = (
                    f"{current_description} | Deprovisioned on {deprovision_timestamp}"
                )
            else:
                new_description = f"Deprovisioned on {deprovision_timestamp}"

        user_json = {"properties": {"disabled": True, "description": new_description}}

        try:
            self.__http_request(
                method="patch",
                url_path=f"{self.path_prefix}/udm/users/user/{dn}",
                data=json.dumps(user_json),
                allowed_responses=[204],
            )
            logging.info(f"User {username} disabled successfully")
            return True
        except Exception as e:
            logging.error(f"Failed to disable user {username}: {e}")
            return False

    def update_user_description(self, username: str, description: str) -> bool:
        dn = self.get_user_dn(username)

        user_json = {"properties": {"description": description}}

        try:
            self.__http_request(
                method="patch",
                url_path=f"{self.path_prefix}/udm/users/user/{dn}",
                data=json.dumps(user_json),
                allowed_responses=[204],
            )
            logging.debug(f"User {username} description updated")
            return True
        except Exception as e:
            logging.error(f"Failed to update description for {username}: {e}")
            return False

    def remove_groups_except(self, username: str, keep_groups: list) -> bool:
        dn = self.get_user_dn(username)
        current_json = self.__get_object_json("user", dn)

        if not current_json:
            logging.warning(f"User {username} not found")
            return False

        current_groups = current_json["properties"].get("groups", [])
        new_groups = [g for g in current_groups if g in keep_groups]

        user_json = {"properties": {"groups": new_groups}}

        try:
            self.__http_request(
                method="patch",
                url_path=f"{self.path_prefix}/udm/users/user/{dn}",
                data=json.dumps(user_json),
                allowed_responses=[204],
            )
            logging.info(
                f"User {username} groups updated (removed {len(current_groups) - len(new_groups)} groups)"
            )
            return True
        except Exception as e:
            logging.error(f"Failed to update groups for {username}: {e}")
            return False

    def set_user(self, person):
        self.user = None
        self.user_updated = False
        username = person["username"]
        dn = "uid=" + username + "," + self.user_base
        current_json = self.__get_object_json("user", dn)
        if current_json:
            if self.options_object.reconcile_groups:
                logging.debug(f"Reconcile {username} groups to: {person['groups']}")
                self.update_user(current_json, person)
            else:
                logging.info(f"User {dn} already exists.")
        else:
            logging.info(f"Creating user {username}")
            self.create_user(person)
            if self.options_object.trigger_invitation_mail:
                psw_reset_trigger_payload = {
                    "options": {"username": username, "method": "email"}
                }
                self.__http_request(
                    method="post",
                    url_path=self.path_prefix + "/command/passwordreset/send_token",
                    data=json.dumps(psw_reset_trigger_payload),
                    allowed_responses=[200],
                )

    def __write_account_credentials(self, string):
        file = open(self.account_output_filename, "a", encoding="utf-8")
        file.write("%s\n" % string)
        self.credentials_created.append(string)
        file.close()

    def summary(self):
        logging.info("Done processing. Create stats:")
        logging.info(f"- Accounts   :\t{self.create_count['users']}")
        logging.info(f"- Groups     :\t{self.create_count['groups']}")
        logging.info(f"- Maildomains:\t{self.create_count['maildomains']}")
        logging.info(f"- OX Contexts:\t{self.create_count['oxcontexts']}")

    def get_imported_credentials_list(self):
        return "\n".join(self.credentials_created)
