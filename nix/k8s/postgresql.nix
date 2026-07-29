{ lib }:
let name = "postgresql"; image = "ghcr.io/opendesk-edu/postgresql"; tag = "latest";
in [ (lib.statefulset { inherit name image tag; port = 5432; }) (lib.service { inherit name; port = 5432; }) ]
