{ lib }:
let name = "minio"; image = "quay.io/minio/minio"; tag = "latest";
in lib.statefulset { inherit name image tag; port = 9000; resources.limits = { cpu = "2"; memory = "4Gi"; }; }
// lib.service { inherit name; port = 9000; }
