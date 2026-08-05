# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

import random
import unicodedata
import glob
import base64
from typing import Any, Callable
import os.path
import string


class RandomUser:
    def __init__(
        self,
        callback: Callable[[dict[str, Any]], None],
        create_admin_accounts: bool = False,
        amount: int = 100,
        password_reset_mail: str = "not_provided@opendesk.internal",
        randomize_username: bool = True,
    ) -> None:
        self.usercounter = 0
        self.randomize_username = randomize_username
        self.input_dir_imgs_base = os.path.join(os.path.dirname(__file__), "..", "data", "images_")
        self.input_files_list = {
            "firstname": os.path.join(os.path.dirname(__file__), "..", "data", "firstname_gender.tsv"),
            "lastname": os.path.join(os.path.dirname(__file__), "..", "data", "lastname.txt"),
            "organisation": os.path.join(os.path.dirname(__file__), "..", "data", "organisation.txt"),
            "city": os.path.join(os.path.dirname(__file__), "..", "data", "city.txt"),
            "postcode": os.path.join(os.path.dirname(__file__), "..", "data", "postcode.txt"),
            "street": os.path.join(os.path.dirname(__file__), "..", "data", "street.txt"),
            "phone": os.path.join(os.path.dirname(__file__), "..", "data", "phone.txt"),
            "mobileTelephoneNumber": os.path.join(os.path.dirname(__file__), "..", "data", "mobile.txt"),
        }
        self.lists = {}
        for _ in list(range(amount)):
            self.usercounter += 1
            person = {}

            for category in list(self.input_files_list.keys()):
                person[category] = self.__get_random_list_entry(category)

            (person["firstname"], person["gender"]) = self.__get_firstname_and_gender()
            person["username"] = self.__get_username(person["firstname"], person["lastname"])
            person["jpegPhoto"] = self.__get_image(person["gender"])
            person["title"] = self.__get_title(person["gender"])
            person["departmentNumber"] = (
                str(random.randint(1, 50)) + "." + str(random.randint(1, 50)) + random.choice(string.ascii_lowercase)
            )
            person["roomNumber"] = (
                str(random.randint(1, 50)) + "." + str(random.randint(1, 50)) + random.choice(string.ascii_uppercase)
            )
            person["email"] = password_reset_mail
            person["is_admin"] = False
            callback(person)
            if create_admin_accounts:
                person["username"] = self.__get_username(person["firstname"], person["lastname"], admin=True)
                person["is_admin"] = True
                callback(person)

    def __get_firstname_and_gender(self) -> list[str]:
        to_split_result = self.__get_random_list_entry("firstname")
        return to_split_result.split("\t")

    def __get_random_list_entry(self, category: str) -> str:
        if category not in self.lists:
            with open(self.input_files_list[category], encoding="utf-8") as f:
                lines_with_comments = f.read().splitlines()
            self.lists[category] = [entry for entry in lines_with_comments if not entry.startswith("#")]
        return random.choice(self.lists[category])

    def __get_username(self, firstname: str, lastname: str, admin: bool = False) -> str:
        if self.randomize_username:
            username = unicodedata.normalize("NFKD", firstname + "." + lastname).encode("ascii", "ignore")
            if admin:
                return username.decode().lower() + "-admin"
            else:
                return username.decode().lower()
        else:
            if admin:
                return "admin." + str(self.usercounter)
            else:
                return "user." + str(self.usercounter)

    def __get_title(self, gender: str = "f") -> str:
        gen_title = "Frau" if gender == "f" else "Herr"
        titles = [gen_title] * 20
        titles.extend(["", "Dr.", "Prof."])
        return random.choice(titles)

    def __get_image(self, gender: str) -> str:
        if not hasattr(self, "input_filelist_img_dict"):
            self.input_filelist_img_dict = {}
        if gender not in self.input_filelist_img_dict:
            self.input_filelist_img_dict[gender] = glob.glob(self.input_dir_imgs_base + gender + "/*.jpg")

        selected_image = random.choice(self.input_filelist_img_dict[gender])
        with open(selected_image, "rb") as image_file:
            return base64.b64encode(image_file.read()).decode()
