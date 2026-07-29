{ lib }:
let name = "memcached"; image = "ghcr.io/opendesk-edu/mirror/memcached"; tag = "1.6.38";
in lib.deployment { inherit name image tag; port = 11211; }
// lib.service { inherit name; port = 11211; }
