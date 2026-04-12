# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

from typing import Any
from configargparse import ArgumentTypeError


def opt2bool(opt: Any) -> bool:
    if isinstance(opt, bool):
        return opt
    elif opt.lower() in ["true", "yes", "ok", "1"]:
        return True
    elif opt.lower() in ["false", "no", "nok", "0"]:
        return False
    else:
        raise ArgumentTypeError(f"Cannot convert {opt} into a boolean value.")
