{ lib }:
let
  name = "mariadb";
  instance = "ilias";
  storageSize = "10Gi";
  storageClass = "ceph-rbd-ssd";
  fullName = "${instance}-${name}";
in [
  (lib.statefulset { 
    name = fullName;
    inherit instance;
    image = "ghcr.io/opendesk-edu/mariadb"; 
    tag = "11.4.4"; 
    port = 3306;
    volumeClaims = [
      { name = "data"; spec = { 
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = storageClass;
        resources = { requests = { storage = storageSize; }; };
      }; }
    ];
  })
  (lib.service { name = fullName; inherit instance; port = 3306; })
]
