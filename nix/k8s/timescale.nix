{ lib }:
let name = "timescale"; image = "ghcr.io/opendesk-edu/timescale"; tag = "latest";
in [ (lib.statefulset { inherit name image tag; port = 5432; }) (lib.service { inherit name; port = 5432; }) ]
