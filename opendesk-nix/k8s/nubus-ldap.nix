{ lib }:
let name = "nubus-ldap"; image = "ghcr.io/opendesk-edu/supplier/univention/ldap-server"; tag = "0.48.2";
in lib.statefulset { inherit name image tag; port = 389; }
// lib.service { inherit name; port = 389; }
