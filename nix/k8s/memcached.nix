{ lib }:
let name = "memcached"; image = "ghcr.io/opendesk-edu/memcached"; tag = "latest";
in [ (lib.deployment { inherit name image tag; port = 11211; }) (lib.service { inherit name; port = 11211; }) ]
