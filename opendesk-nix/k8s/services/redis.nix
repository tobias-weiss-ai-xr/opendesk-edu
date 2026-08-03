{ lib }:
let name = "redis"; image = "ghcr.io/opendesk-edu/redis"; tag = "latest";
in [
  (lib.statefulset { 
    inherit name image tag;
    port = 6379;
    volumeClaims = [
      { name = "data"; spec = { 
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "ceph-rbd-ssd";
        resources = { requests = { storage = "10Gi"; }; };
      }; }
    ];
  })
  (lib.service { inherit name; port = 6379; })
]
