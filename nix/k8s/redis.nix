{ lib }:
let name = "redis"; image = "ghcr.io/opendesk-edu/redis"; tag = "latest";
in [ (lib.statefulset { inherit name image tag; port = 6379; }) (lib.service { inherit name; port = 6379; }) ]
