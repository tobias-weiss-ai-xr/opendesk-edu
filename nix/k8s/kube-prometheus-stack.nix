{ lib, ... }:

let
  name = "kube-prometheus-stack";
  namespace = "opendesk";
  port = 9090;

in
[
  (lib.statefulset {
    name = name;
    image = "quay.io/prometheus/prometheus:v2.51.0";
    labels = { app = name; };
    selector = { app = name; };
    namespace = namespace;
    ports = [ { name = "http"; containerPort = port; } ];
    volumeClaims = [ { name = "data"; spec = { accessModes = [ "ReadWriteOnce" ]; resources = { requests = { storage = "10Gi" }; }; }; } ];
    resources = { limits = { cpu = "1"; memory = "2Gi"; }; };
  }