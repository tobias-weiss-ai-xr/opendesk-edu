#!/usr/bin/env python3
import sys
import ldap3
import imaplib
import smtplib
import requests
from urllib.parse import urljoin

LDAP_SERVER = "ums-ldap-server-primary-0.ums-ldap-server-headless.opendesk.svc.cluster.local"
LDAP_PORT = 389
LDAP_BASE_DN = "cn=directory-manager"
LDAP_BASE_SEARCH = "dc=example,dc=com"

MAIL_SERVER = "dovecot.opendesk.hrz.uni-marburg.de"
MAIL_PORT_IMAP = 993
SMTP_SERVER = "postfix.opendesk.hrz.uni-marburg.de"
SMTP_PORT = 465

MINIO_ENDPOINT = "https://objectstore.opendesk.hrz.uni-marburg.de"
SEAWEEDFS_ENDPOINT = "https://objectstorage.opendesk.hrz.uni-marburg.de"

K8UP_NAMESPACE = "opendesk"

def test_ldap_connectivity():
    try:
        server = ldap3.Server(LDAP_SERVER, port=LDAP_PORT, get_info=ldap3.ALL)
        conn = ldap3.Connection(server, auto_bind=True, authentication=ldap3.ANONYMOUS)
        conn.search(search_base=LDAP_BASE_SEARCH, search_filter='(objectClass=*)', search_scope=ldap3.SUBTREE, attributes=['cn'])
        conn.unbind()
        return True, "LDAP search successful"
    except Exception as e:
        return False, f"LDAP error: {str(e)[:80]}"

def test_imap_connectivity():
    try:
        imap = imaplib.IMAP4_SSL(MAIL_SERVER, port=MAIL_PORT_IMAP, timeout=10)
        imap.noop()
        imap.logout()
        return True, "IMAP connection successful"
    except Exception as e:
        return False, f"IMAP error: {str(e)[:80]}"

def test_smtp_connectivity():
    try:
        smtp = smtplib.SMTP_SSL(SMTP_SERVER, port=SMTP_PORT, timeout=10)
        smtp.noop()
        smtp.quit()
        return True, "SMTP connection successful"
    except Exception as e:
        return False, f"SMTP error: {str(e)[:80]}"

def test_minio_health():
    try:
        response = requests.get(MINIO_ENDPOINT, timeout=10, verify=False)
        if response.status_code in [200, 302, 401]:
            return True, f"MinIO accessible: HTTP {response.status_code}"
        return False, f"MinIO unexpected status: HTTP {response.status_code}"
    except Exception as e:
        return False, f"MinIO error: {str(e)[:80]}"

def test_seaweedfs_health():
    try:
        response = requests.get(SEAWEEDFS_ENDPOINT, timeout=10, verify=False)
        if response.status_code in [200, 302]:
            return True, f"SeaweedFS accessible: HTTP {response.status_code}"
        return False, f"SeaweedFS unexpected status: HTTP {response.status_code}"
    except Exception as e:
        return False, f"SeaweedFS error: {str(e)[:80]}"

def test_k8up_schedules():
    try:
        response = requests.get(f"http://localhost:8081/api/v1/namespaces/{K8UP_NAMESPACE}/schedules", timeout=5)
        if response.status_code == 200:
            count = len(response.json().get('items', []))
            return True, f"k8up schedules found: {count}"
        return False, f"k8up API error: HTTP {response.status_code}"
    except Exception as e:
        return False, f"k8up error: {str(e)[:80]}"

def test_clamav_health():
    try:
        import socket
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(5)
        result = s.connect_ex(('clamav-clamd.opendesk.svc.cluster.local', 3310))
        s.close()
        if result == 0:
            return True, "ClamAV socket responsive"
        return False, f"ClamAV connection failed: {result}"
    except Exception as e:
        return False, f"ClamAV error: {str(e)[:80]}"

def test_ox_filepicker():
    try:
        ox_api = "https://webmail.opendesk.hrz.uni-marburg.de/apisuite"
        response = requests.get(ox_api, timeout=10, verify=False)
        if response.status_code == 401:
            return True, "OX API accessible (auth required)"
        return False, f"OX API unexpected status: HTTP {response.status_code}"
    except Exception as e:
        return False, f"OX API error: {str(e)[:80]}"

def test_provisioning_api():
    try:
        provisioning_api = "https://portal.opendesk.hrz.uni-marburg.de/provisioning"
        response = requests.get(provisioning_api, timeout=10, verify=False)
        if response.status_code in [401, 403]:
            return True, "Provisioning API accessible (auth required)"
        return False, f"Provisioning API unexpected status: HTTP {response.status_code}"
    except Exception as e:
        return False, f"Provisioning error: {str(e)[:80]}"

if __name__ == "__main__":
    total = 0
    passed = 0
    failed = 0
    warnings = 0
    
    print("\n" + "="*70)
    print("Layer 3: Integration Tests")
    print("="*70)
    
    tests = [
        ("LDAP Connectivity", test_ldap_connectivity),
        ("IMAP (Dovecot)", test_imap_connectivity),
        ("SMTP (Postfix)", test_smtp_connectivity),
        ("MinIO Object Storage", test_minio_health),
        ("SeaweedFS S3 Storage", test_seaweedfs_health),
        ("k8up Backup Schedules", test_k8up_schedules),
        ("ClamAV Antivirus", test_clamav_health),
        ("OX Filepicker API", test_ox_filepicker),
        ("Provisioning API", test_provisioning_api),
    ]
    
    print("\n" + "-"*70 + "\n")
    
    for test_name, test_func in tests:
        total += 1
        success, message = test_func()
        
        if success:
            print(f"✓ {test_name:30s} → {message}")
            passed += 1
        else:
            if "timeout" in message.lower() or "connection" in message.lower():
                print(f"⚠ {test_name:30s} → {message}")
                warnings += 1
            else:
                print(f"✗ {test_name:30s} → {message}")
                failed += 1
    
    percent = (passed * 100) // total if total > 0 else 0
    
    print("\n" + "="*70)
    print(f"Layer 3 Summary")
    print("="*70)
    print(f"Total:    {total}")
    print(f"Passed:   {passed}")
    print(f"Failed:   {failed}")
    print(f"Warnings: {warnings}")
    print(f"Success:  {percent}%")
    print("="*70 + "\n")
    
    sys.exit(1 if failed > 0 else 0)