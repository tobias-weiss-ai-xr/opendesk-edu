{ lib }:
let name = "clamav"; image = "ghcr.io/opendesk-edu/mirror/clamav/clamav"; tag = "1.5.2_base";
in lib.deployment { inherit name image tag; port = 3310; }
// lib.service { inherit name; port = 3310; }
