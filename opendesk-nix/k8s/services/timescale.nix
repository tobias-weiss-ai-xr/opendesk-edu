{ lib }:
let name = "timescale"; image = "ghcr.io/opendesk-edu/timescale"; tag = "latest";
in [
  (lib.statefulset { 
    inherit name image tag;
    port = 5432;
    volumeClaims = [
      { name = "data"; spec = { 
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "ceph-rbd-ssd";
        resources = { requests = { storage = "10Gi"; }; };
      }; }
    ];
  })
  (lib.service { inherit name; port = 5432; })
]
