#!/usr/bin/env python3
"""
Create a dedicated ICS integration test user in LDAP.

The user ('ics-testuser') needs to exist in LDAP (not just Keycloak) so that
the OIDC password grant works through Keycloak's LDAP federation.

Usage (via kubectl exec on ums-udm-rest-api pod):
    kubectl exec -n opendesk deploy/ums-udm-rest-api -- \\
        python3 -c "\$(cat tests/create-ics-testuser.py)" --from-cluster

Alternative (via UDM CLI on portal pod):
    kubectl exec -n opendesk deploy/ums-umc-server -- bash -c "
      udm users/user create \\
        --position=\"cn=users,dc=swp-ldap,dc=internal\" \\
        --set username=ics-testuser \\
        --set firstname=ICS \\
        --set lastname=Testuser \\
        --set password=ics-testuser-2026 \\
        --set primaryGroup=\"cn=Domain Users,cn=groups,dc=swp-ldap,dc=internal\" \\
        --set opendeskFileshareEnabled=1 \\
        --set opendeskFileshareCloudEnabled=1 \\
        --set opendeskLearnmanagementEnabled=1 \\
        --set disabled=0
    "
"""

import os
import sys
import json
import hashlib
import logging
import argparse
import urllib.request
import urllib.error
import base64

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
log = logging.getLogger("create-ics-testuser")


def create_via_udm_rest(username, password, ldap_secret, ldap_base):
    """Create user via UDM REST API on localhost (run from ums-udm-rest-api pod)."""
    url = f"http://localhost/udm/users/user/"
    creds = base64.b64encode(f"cn=admin:{ldap_secret}".encode()).decode()

    user_data = json.dumps({
        "properties": {
            "username": username,
            "firstname": "ICS",
            "lastname": "Testuser",
            "password": password,
            "disabled": False,
            "description": "ICS integration test user",
            "primaryGroup": f"cn=Domain Users,cn=groups,{ldap_base}",
            "opendeskFileshareEnabled": True,
            "opendeskFileshareCloudEnabled": True,
            "opendeskLearnmanagementEnabled": True,
            "opendeskLivecollaborationEnabled": True,
            "opendeskVideoconferenceEnabled": True,
        },
        "position": f"cn=users,{ldap_base}",
    }).encode()

    req = urllib.request.Request(url, data=user_data, method="POST")
    req.add_header("Authorization", f"Basic {creds}")
    req.add_header("Content-Type", "application/json")

    try:
        resp = urllib.request.urlopen(req)
        log.info(f"User '{username}' created: HTTP {resp.status}")
        return True
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        if "Object exists" in body:
            log.info(f"User '{username}' already exists")
            return True
        log.error(f"Failed: HTTP {e.code} - {body[:300]}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Create ICS integration test user in LDAP"
    )
    parser.add_argument("--from-cluster", action="store_true",
                        help="Run from ums-udm-rest-api pod (reads /etc/ldap.secret)")
    parser.add_argument("--username", default="ics-testuser")
    parser.add_argument("--password", default="ics-testuser-2026")
    args = parser.parse_args()

    if args.from_cluster:
        # Running from inside the ums-udm-rest-api pod
        try:
            with open("/etc/ldap.secret") as f:
                ldap_secret = f.read().strip()
        except FileNotFoundError:
            log.error("Not on ums-udm-rest-api pod (no /etc/ldap.secret)")
            sys.exit(1)

        # Try to determine LDAP base
        ldap_base = os.environ.get("LDAP_BASE", "dc=swp-ldap,dc=internal")

        success = create_via_udm_rest(args.username, args.password,
                                       ldap_secret, ldap_base)
        if success:
            print()
            print("=" * 60)
            print("ICS Test User Created / Already Exists")
            print("=" * 60)
            print(f"  Username:   {args.username}")
            print(f"  Password:   {args.password}")
            print(f"  LDAP base:  {ldap_base}")
            print()
            print("  To use with spec runner:")
            print(f"  PORTAL_USERNAME={args.username} PORTAL_PASSWORD={args.password} \\")
            print(f"  OIDC_CLIENT_ID=opendesk-intercom \\")
            print(f"  OIDC_CLIENT_SECRET=\$(kubectl get secret -n opendesk \\")
            print(f"    intercom-service-oidc -o jsonpath='{{.data.clientSecret}}' \\")
            print(f"    | base64 -d) \\")
            print(f"  python tests/run-specs.py")
            print()
            print("  Required Keycloak config (done once):")
            print("  - opendesk-intercom client needs directAccessGrantsEnabled=true")
            print("  - Realm needs bruteForceProtected=false")
            print("=" * 60)
        else:
            sys.exit(1)
    else:
        print("""
This script must be run from inside the ums-udm-rest-api pod on the cluster.

  kubectl exec -n opendesk deploy/ums-udm-rest-api -- \\
      python3 -c "$(cat tests/create-ics-testuser.py)" --from-cluster

Alternatively, use the UDM CLI on the UMC server:
  kubectl exec -n opendesk deploy/ums-umc-server -- bash -c '
    udm users/user create \\
      --position="cn=users,dc=swp-ldap,dc=internal" \\
      --set username=ics-testuser \\
      --set firstname=ICS \\
      --set lastname=Testuser \\
      --set password=ics-testuser-2026
  '
""")


if __name__ == "__main__":
    main()
