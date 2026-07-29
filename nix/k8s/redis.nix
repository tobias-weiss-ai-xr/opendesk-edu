{ lib }:
let name = "redis"; image = "ghcr.io/opendesk-edu/mirror/redis"; tag = "7.4.3";
in lib.deployment { inherit name image tag; port = 6379; }
// lib.service { inherit name; port = 6379; }
