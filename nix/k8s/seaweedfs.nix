{ lib }:
let
  master = lib.statefulset { name = "seaweedfs-master"; image = "ghcr.io/opendesk-edu/seaweedfs"; tag = "latest"; port = 9333; };
  masterSvc = lib.service { name = "seaweedfs-master"; port = 9333; };
  volume = lib.statefulset { name = "seaweedfs-volume"; image = "ghcr.io/opendesk-edu/seaweedfs"; tag = "latest"; port = 8080; };
  volumeSvc = lib.service { name = "seaweedfs-volume"; port = 8080; };
in [ master masterSvc volume volumeSvc ]
