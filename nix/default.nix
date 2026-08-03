{ pkgs ? import <nixpkgs> {}, libPath ? ./lib/k8s.nix }:

# DEPRECATION NOTICE: This module is being migrated to opendesk-nix/
# See: ../../opendesk-edu-spec/changes/nix-integration-proposal/
# For new projects, use opendesk-nix/ directly

let
  lib = import libPath { inherit pkgs; };
  
  # All service modules
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

  # Import a single service
  getService = name:
    if builtins.elemAt allServices (builtins.find name allServices) != null then
      import ./k8s/${name}.nix { inherit lib; }
    else
      throw "Service '${name}' not found in allServices list";

  # Import all services or a subset
  getServices = names:
    if names == null then
      map getService allServices
    else
      map getService names;

in
{
  inherit lib getService getServices allServices;
}
