{ lib }:
let
  master = lib.statefulset { 
    name = "seaweedfs-master"; 
    image = "ghcr.io/opendesk-edu/seaweedfs"; 
    tag = "latest"; 
    port = 9333;
    volumeClaims = [
      { name = "data"; spec = { 
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "ceph-rbd-ssd";
        resources = { requests = { storage = "10Gi"; }; };
      }; }
    ];
  };
  masterSvc = lib.service { name = "seaweedfs-master"; port = 9333; };
  volume = lib.statefulset { 
    name = "seaweedfs-volume"; 
    image = "ghcr.io/opendesk-edu/seaweedfs"; 
    tag = "latest"; 
    port = 8080;
    volumeClaims = [
      { name = "data"; spec = { 
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "ceph-rbd-ssd";
        resources = { requests = { storage = "20Gi"; }; };
      }; }
    ];
  };
  volumeSvc = lib.service { name = "seaweedfs-volume"; port = 8080; };
in [ master masterSvc volume volumeSvc ]
