{ pkgs ? import <nixpkgs> {}, libPath ? ./lib/k8s.nix }:

let
  lib = import libPath { inherit pkgs; };
  allServices = [
    "argocd" "bigbluebutton" "bookstack" "clamav" "coderd"
    "code-server" "collab-dashboard" "collabora" "dask" "drawio"
    "element" "etherpad" "eudi-issuer" "excalidraw" "f13"
    "grommunio" "ilias" "ilias-full" "intercom" "intercom-service"
    "jitsi" "jupyterhub" "kasmvnc" "limesurvey" "mariadb"
    "memcached" "monitoring" "moodle" "n8n" "ollama"
    "opencloud" "open-webui" "openproject" "overleaf" "planka"
    "portal-entries" "postgresql" "redis" "rstudio" "seaweedfs"
    "self-service-password" "semester-provisioning" "slidev" "snipr"
    "sogo" "stalwart" "timescale" "ttyd" "typo3" "xwiki" "zammad"
  ];

  # Validate all services can be imported and evaluated
  validateService = name:
    try (
      let data = import ./k8s/${name}.nix { inherit lib; };
      in {
        inherit name;
        status = "OK";
        resources = builtins.length data;
      }
    ) catch e: {
      inherit name;
      status = "ERROR";
      error = builtins.toString e;
    };

  # Check for specific features
  validateFeatures = name:
    try (
      let data = import ./k8s/${name}.nix { inherit lib; };
      in {
        inherit name;
        hasDeployment = builtins.any (r: r.apiVersion == "apps/v1" && r.kind == "Deployment") data;
        hasStatefulSet = builtins.any (r: r.apiVersion == "apps/v1" && r.kind == "StatefulSet") data;
        hasService = builtins.any (r: r.kind == "Service") data;
        hasIngress = builtins.any (r: r.kind == "Ingress") data;
        hasCertificate = builtins.any (r: r.kind == "Certificate") data;
        hasPVC = builtins.any (r: r.kind == "PersistentVolumeClaim") data;
        totalResources = builtins.length data;
      }
    ) catch e: {
      inherit name;
      error = "Failed to import: " + builtins.toString e;
      hasDeployment = false;
      hasStatefulSet = false;
      hasService = false;
      hasIngress = false;
      hasCertificate = false;
      hasPVC = false;
      totalResources = 0;
    };

in
{
  inherit lib allServices;
  validateService = name: validateService name;
  validateAllServices = map validateService allServices;
  validateFeatures = name: validateFeatures name;
  validateAllFeatures = map validateFeatures allServices;
  
  # Summary
  summary = let
    results = map validateService allServices;
    okCount = builtins.length (builtins.filter (r: r.status == "OK") results);
    errorCount = builtins.length (builtins.filter (r: r.status == "ERROR") results);
    totalResources = builtins.sumAttrs (builtins.filterAttrs (n: v: v.status == "OK") (builtins.listToAttrs results)) "resources";
  in {
    totalServices = builtins.length allServices;
    inherit okCount errorCount totalResources;
  };
}
