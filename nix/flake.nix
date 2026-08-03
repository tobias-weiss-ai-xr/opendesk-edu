{
  description = "openDesk Edu — Nix-based Kubernetes deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    # Reference opendesk-nix as a local path (same monorepo)
    opendesk-nix.path = "../../opendesk-nix";
  };

  outputs = { self, nixpkgs, flake-utils, opendesk-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        # Use K8s library from opendesk-nix
        k8s-lib = opendesk-nix.lib.${system}.k8s;

        services = [
          "mariadb" "postgresql" "redis" "memcached" "timescale"
          "ilias" "moodle" "bookstack" "openproject" "xwiki"
          "collabora" "element" "jitsi" "stalwart" "sogo"
          "drawio" "excalidraw" "planka" "coderd" "ollama"
          "intercom-service" "clamav" "seaweedfs"
          "self-service-password" "code-server" "rstudio" "ttyd" "slidev"
          "argocd" "bigbluebutton" "etherpad" "eudi-issuer"
          "f13" "grommunio" "jupyterhub" "kasmvnc"
          "limesurvey" "n8n" "opencloud"
          "open-webui" "overleaf" "collab-dashboard" "portal-entries"
          "semester-provisioning" "snipr" "typo3" "zammad"
          "dask" "intercom"
          # Monitoring stack
          "kube-prometheus-stack" "monitoring"
          # Centralized Logging - EFK stack
          "elasticsearch" "filebeat" "kibana"
          # Centralized Logging - Loki stack
          "loki" "promtail"
        ];

        # All services are now in opendesk-nix/k8s/services/
        buildService = name:
          let
            servicePath = "${opendesk-nix}/k8s/services/${name}.nix";
            data = import servicePath { lib = k8s-lib; };
            jsonFormat = pkgs.formats.json { };
          in
          jsonFormat.generate "${name}.yaml" data;

        allServices = pkgs.runCommand "opendesk-edu" { buildInputs = [ pkgs.yq ]; } (
          let
            copyCmds = builtins.concatStringsSep "
" (map (name: ''
              ${pkgs.yq}/bin/yq -P evalall '.' ${buildService name} > "$out/${name}.yaml"
            '') services);
          in
          ''
            mkdir -p $out
            ${copyCmds}
            echo "Done — $out has $(ls $out/*.yaml | wc -w) manifests"
          ''
        );
      in
      {
        packages = {
          inherit allServices;
        } // builtins.listToAttrs (map (name: {
          inherit name;
          value = buildService name;
        }) services);

        apps.apply = {
          type = "app";
          program = "${pkgs.writeShellScript "apply" ''
            set -euo pipefail
            echo "=== Applying openDesk Edu ==="
            kubectl apply -f ${allServices}/
            echo "=== Done ==="
          ''}";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ kubectl yq-go ];
        };
      }
    );
}
