{ lib }:
let name = "redis"; image = "redis"; tag = "7.2-alpine";
in lib.statefulset { inherit name image tag; port = 6379; }
// lib.service { inherit name; port = 6379; }
