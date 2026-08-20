# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ lib, pkgs, ... }:

let
  # Registry type names (for validation)
  registryTypeNames = [ "oci" "docker" "zot" "ghcr" "gitlab" "docker-hub" "quay" "harbor" "ecr" "acr" "gcr" "local" ];

  # Registry configuration type
  registryType = lib.types.submodule {
    options = {
      name = lib.mkOption { type = lib.types.str; };
      url = lib.mkOption { type = lib.types.str; };
      type = lib.mkOption { type = lib.types.enum registryTypeNames; };
      username = lib.mkOption { default = null; type = lib.types.nullOr lib.types.str; };
      password = lib.mkOption { default = null; type = lib.types.nullOr lib.types.str; };
      insecure = lib.mkOption { default = false; type = lib.types.bool; };
    };
  };

  # Format image name
  formatImageName = { registry, repo, tag ? "latest", digest ? null }:
    let
      base = if registry != null then "${registry}/" else "";
      tagPart = if tag != null then ":${tag}" else "";
      digestPart = if digest != null then "@${digest}" else "";
    in "${base}${repo}${tagPart}${digestPart}";

  # Predefined registries
  registries = lib.genAttrs [
    "ghcr" "gitlab" "zot" "docker-hub" "quay" "harbor" 
    "ecr" "acr" "gcr" "local" "nix-cache"
  ] (name:
    let
      cfg = {
        name = name;
        url = if name == "ghcr" then "ghcr.io"
          else if name == "gitlab" then "registry.gitlab.com"
          else if name == "zot" then "172.17.209.143:5000"
          else if name == "docker-hub" then "docker.io"
          else if name == "quay" then "quay.io"
          else if name == "harbor" then "harbor.opendesk.local"
          else if name == "ecr" then "public.ecr.aws"
          else if name == "acr" then "*.azurecr.io"
          else if name == "gcr" then "gcr.io"
          else if name == "local" then "localhost:5000"
          else if name == "nix-cache" then "cache.nixos.org"
          else "";
        type = if name == "zot" then "zot"
          else if name == "docker-hub" then "docker"
          else "oci";
        insecure = if name == "zot" then true
          else if name == "local" then true
          else false;
      };
    in cfg
  );

  # Push to registry
  pushToRegistry = { image, registryConfig, tag ? "latest" }:
    let
      imageName = formatImageName {
        registry = registryConfig.url;
        repo = image;
        tag = tag;
      };
    in pkgs.runCommand "push-${builtins.hashString "sha256" imageName}" {
      nativeBuildInputs = [ pkgs.docker ];
    } ''
      echo "Pushing ${image} to ${imageName}"
      # Implementation would use docker push or similar
      touch $out
    '';

  # Pull from registry
  pullFromRegistry = { image, registryConfig, tag ? "latest" }:
    let
      imageName = formatImageName {
        registry = registryConfig.url;
        repo = image;
        tag = tag;
      };
    in pkgs.runCommand "pull-${builtins.hashString "sha256" imageName}" {
      nativeBuildInputs = [ pkgs.docker ];
    } ''
      echo "Pulling from ${imageName}"
      # Implementation would use docker pull or similar
      touch $out
    '';

  # Containerd registry configuration
  containerdRegistryConfig = { registryConfigs }:
    pkgs.writeText "containerd-registries.toml" (builtins.concatStringsSep "\n" (
      map (cfg: ''
[plugins."io.containerd.grpc.v1.cri".registry.configs."${cfg.url}".auth]
  username = "${cfg.username or ""}"
  password = "${cfg.password or ""}"
  ${if cfg.insecure then "insecure_skip_verify = true" else ""}
      '') (builtins.attrValues registryConfigs)
    ));

  # Docker CLI authentication
  dockerAuthConfig = { registryConfigs }:
    pkgs.writeText "docker-auth.json" (builtins.toJSON {
      auths = map (cfg: {
        name = cfg.url;
        auth = if cfg.username != null && cfg.password != null then 
          builtins.toBase64 "${cfg.username}:${cfg.password}" 
        else null;
      }) (builtins.attrValues registryConfigs);
    });

in {
  inherit registryType formatImageName registries 
    pushToRegistry pullFromRegistry containerdRegistryConfig dockerAuthConfig;
  
  # Helper to get registry by name
  getRegistry = name: builtins.getAttr name registries;
  
  # All registry URLs
  allRegistryURLs = map (cfg: cfg.url) (builtins.attrValues registries);
}
