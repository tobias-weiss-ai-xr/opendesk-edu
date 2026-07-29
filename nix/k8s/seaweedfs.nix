{ lib }:
let
  master = lib.statefulset { name = "seaweedfs-master"; image = "ghcr.io/opendesk-edu/mirror/seaweedfs"; tag = "4.17"; port = 9333; };
  volume = lib.statefulset { name = "seaweedfs-volume"; image = "ghcr.io/opendesk-edu/mirror/seaweedfs"; tag = "4.17"; port = 8080; };
  filer = lib.deployment { name = "seaweedfs-filer"; image = "ghcr.io/opendesk-edu/mirror/seaweedfs"; tag = "4.17"; port = 8888; };
in [ master volume filer ]
