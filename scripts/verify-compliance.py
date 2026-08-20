#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Final compliance verification script.
Checks if all requirements marked as complete are actually implemented.
"""

import os
import re

REPO_ROOT = '/home/weissto_local/git/opendesk_git/opendesk-nix'
SERVICES_DIR = f'{REPO_ROOT}/k8s/services'

# Requirements we claim to have implemented
have_oci_labels = False
have_ingress_tls = False
have_environments = False
have_cert_manager = False
have_environment_overrides = False
have_explicit_capabilities = False

# Check 1: OCI Labels in all services
service_files = [f for f in os.listdir(SERVICES_DIR) if f.endswith('.nix')]
oci_count = 0
for f in service_files:
    filepath = f'{SERVICES_DIR}/{f}'
    with open(filepath, 'r') as file:
        content = file.read()
        if 'ociLabels = lib.mkOCILabels' in content:
            oci_count += 1

have_oci_labels = (oci_count == len(service_files))
print(f"✓ FR-IMAGE-007 (OCI Labels): {oci_count}/{len(service_files)} services = {have_oci_labels}")

# Check 2: Ingress with TLS in lib/k8s.nix
with open(f'{REPO_ROOT}/lib/k8s.nix', 'r') as f:
    k8s_lib = f.read()

have_ingress_tls = ('mkIngressWithTLS' in k8s_lib)
print(f"✓ FR-K8S-004 (Ingress with TLS): {have_ingress_tls}")

# Check 3: Environments
env_dir = f'{REPO_ROOT}/k8s/environments'
hrz_env = f'{env_dir}/hrz/default.nix'
demo_env = f'{env_dir}/demo/default.nix'
local_env = f'{env_dir}/local/default.nix'

have_environments = (
    os.path.exists(hrz_env) and 
    os.path.exists(demo_env) and 
    os.path.exists(local_env)
)
print(f"✓ FR-DEPLOY-001 (Environments): {have_environments}")

# Check 4: cert-manager in lib/k8s.nix
have_cert_manager = (
    'certificate = ' in k8s_lib and 
    'issuer = ' in k8s_lib and 
    'clusterIssuer = ' in k8s_lib
)
print(f"✓ FR-K8S-010 (cert-manager): {have_cert_manager}")

# Check 5: Environment overrides
overrides_dir = f'{REPO_ROOT}/k8s/environments/overrides'
overrides_readme = f'{overrides_dir}/README.md'
have_environment_overrides = (
    os.path.exists(overrides_dir) and 
    os.path.exists(overrides_readme)
)
print(f"✓ FR-DEPLOY-002 (Environment Overrides): {have_environment_overrides}")

# Check 6: Explicit capabilities in security profiles
with open(f'{REPO_ROOT}/lib/security.nix', 'r') as f:
    security_lib = f.read()

have_adding_capabilities = 'addCapabilities' in security_lib
have_dropping_all = 'dropCapabilities = [ "ALL" ]' in security_lib
have_explicit_capabilities = (have_adding_capabilities and have_dropping_all)
print(f"✓ FR-IMAGE-003 (Explicit Capabilities): {have_explicit_capabilities}")

# Summary
print(f"\n{'='*60}")
print("Compliance Verification Summary:")
print(f"{'='*60}")
print(f"FR-IMAGE-007 (OCI Labels):       {'✅ PASS' if have_oci_labels else '❌ FAIL'}")
print(f"FR-K8S-004 (Ingress with TLS):   {'✅ PASS' if have_ingress_tls else '❌ FAIL'}")
print(f"FR-DEPLOY-001 (Environments):    {'✅ PASS' if have_environments else '❌ FAIL'}")
print(f"FR-K8S-010 (cert-manager):       {'✅ PASS' if have_cert_manager else '❌ FAIL'}")
print(f"FR-DEPLOY-002 (Overrides):       {'✅ PASS' if have_environment_overrides else '❌ FAIL'}")
print(f"FR-IMAGE-003 (Capabilities):     {'✅ PASS' if have_explicit_capabilities else '❌ FAIL'}")
print(f"{'='*60}")

all_pass = all([
    have_oci_labels,
    have_ingress_tls,
    have_environments,
    have_cert_manager,
    have_environment_overrides,
    have_explicit_capabilities
])

print(f"\nOverall: {'✅ ALL PASSED' if all_pass else '❌ SOME FAILED'}")
