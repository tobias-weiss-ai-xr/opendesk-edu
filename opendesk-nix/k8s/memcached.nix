{ lib }:
let name = "memcached"; image = "memcached"; tag = "1.6.38-alpine";
in lib.deployment { inherit name image tag; port = 11211; }
// lib.service { inherit name; port = 11211; }
