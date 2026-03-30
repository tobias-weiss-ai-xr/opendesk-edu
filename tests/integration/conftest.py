# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0

import os
import sys

# Add semester-provisioning and subdirectories to Python path
# Fügt semester-provisioning und Unterverzeichnisse zum Python-Pfad hinzu
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SEM_PROV_PATH = os.path.join(ROOT_DIR, "scripts", "semester-provisioning")

paths_to_add = [
    SEM_PROV_PATH,
    os.path.join(SEM_PROV_PATH, "sync"),
    os.path.join(SEM_PROV_PATH, "archival"),
    os.path.join(SEM_PROV_PATH, "config"),
]

for path in paths_to_add:
    if os.path.isdir(path) and path not in sys.path:
        sys.path.insert(0, path)
