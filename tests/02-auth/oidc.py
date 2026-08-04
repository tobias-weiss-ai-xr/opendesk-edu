#!/usr/bin/env python3
import sys
import requests
from urllib.parse import urlparse

KEYCLOAK_IDP = "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/openid-connect/auth"
KEYCLOAK_REALM = "opendesk"
ACCEPTABLE_RESPONSES = [200, 302, 401]

services_oidc = {
    "Nextcloud": "https://files.opendesk.hrz.uni-marburg.de",
    "OpenCloud": "https://opencloud.opendesk.hrz.uni-marburg.de",
    "OX App Suite": "https://webmail.opendesk.hrz.uni-marburg.de",
    "OpenProject": "https://projects.opendesk.hrz.uni-marburg.de",
    "Moodle": "https://moodle.opendesk.hrz.uni-marburg.de",
}

services_saml = {
    "ILIAS": "https://lms.opendesk.hrz.uni-marburg.de/Shibboleth.sso/Metadata",
    "XWiki": "https://wiki.opendesk.hrz.uni-marburg.de/xwiki/bin/loginsaml/saml/request",
}

def check_oidc_redirect(service_name, service_url):
    try:
        response = requests.get(service_url, allow_redirects=False, timeout=10)
        
        if response.status_code in ACCEPTABLE_RESPONSES:
            if response.status_code == 302:
                location = response.headers.get('Location', '')
                if "opendesk.hrz.uni-marburg.de" in location or "opendesk-edu.org" in location:
                    return True, 302, f"Redirects to: {location[:60]}..."
                return False, response.status_code, f"Unexpected redirect: {location[:60]}"
            else:
                return True, response.status_code, "Response OK"
        return False, response.status_code, f"Unexpected status: {response.status_code}"
    except Exception as e:
        return False, 0, f"Request failed: {str(e)[:60]}"

def check_saml_metadata(service_name, service_url):
    try:
        response = requests.get(service_url, timeout=10)
        
        if response.status_code == 200:
            if "EntityDescriptor" in response.text and "entityID=" in response.text:
                return True, 200, "Valid SAML metadata"
            return False, 200, "Invalid SAML metadata response"
        return False, response.status_code, f"HTTP {response.status_code}"
    except Exception as e:
        return False, 0, f"Request failed: {str(e)[:60]}"

def check_keycloak_reachable():
    try:
        response = requests.get(
            f"https://id.opendesk.hrz.uni-marburg.de/realms/{KEYCLOAK_REALM}/.well-known/openid-configuration",
            timeout=10
        )
        if response.status_code == 200 and "authorization_endpoint" in response.text:
            return True
        return False
    except Exception:
        return False

if __name__ == "__main__":
    total = 0
    passed = 0
    failed = 0
    warnings = 0
    
    print("\n" + "="*70)
    print("Layer 2: Authentication Flow Validation")
    print("="*70)
    
    if not check_keycloak_reachable():
        print("\n❌ CRITICAL: Keycloak realm not reachable - aborting auth tests")
        sys.exit(1)
    
    print("\n✓ Keycloak realm reachable")
    
    print("\n" + "-"*70)
    print("OIDC Redirect Tests")
    print("-"*70 + "\n")
    
    for service_name, service_url in services_oidc.items():
        total += 1
        success, status, message = check_oidc_redirect(service_name, service_url)
        
        if success:
            print(f"✓ {service_name:20s} → {message}")
            passed += 1
        else:
            if status == 401 or status == 403:
                print(f"⚠ {service_name:20s} → {message}")
                warnings += 1
            else:
                print(f"✗ {service_name:20s} → {message}")
                failed += 1
    
    print("\n" + "-"*70)
    print("SAML Metadata Tests")
    print("-"*70 + "\n")
    
    for service_name, service_url in services_saml.items():
        total += 1
        success, status, message = check_saml_metadata(service_name, service_url)
        
        if success:
            print(f"✓ {service_name:20s} → {message}")
            passed += 1
        else:
            print(f"✗ {service_name:20s} → {message}")
            failed += 1
    
    percent = (passed * 100) // total if total > 0 else 0
    
    print("\n" + "="*70)
    print(f"Layer 2 Summary")
    print("="*70)
    print(f"Total:    {total}")
    print(f"Passed:   {passed}")
    print(f"Failed:   {failed}")
    print(f"Warnings: {warnings}")
    print(f"Success:  {percent}%")
    print("="*70 + "\n")
    
    sys.exit(1 if failed > 0 else 0)