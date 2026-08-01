{ lib }:
let name = "dovecot"; image = "ghcr.io/opendesk-edu/supplier/dovecot"; tag = "2.3";
in lib.statefulset { inherit name image tag; port = 143; storageSize = "50Gi"; }
// lib.service { inherit name; port = 143; }
