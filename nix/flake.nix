{
  description = "openDesk Edu — Nix-based Kubernetes deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = import ./lib/k8s.nix { inherit pkgs; };

        services = [
          "mariadb" "postgresql" "redis" "memcached" "timescale"
          "ilias" "moodle" "bookstack" "openproject" "xwiki"
          "collabora" "element" "jitsi" "stalwart" "sogo"
          "drawio" "excalidraw" "planka" "coderd" "ollama"
          "intercom-service" "clamav" "seaweedfs"
          "self-service-password" "code-server" "rstudio" "ttyd" "slidev"
          "argocd" "bigbluebutton" "etherpad" "eudi-issuer"
          "f13" "grommunio" "jupyterhub" "kasmvnc"
          "limesurvey" "monitoring" "n8n" "opencloud"
          "open-webui" "overleaf" "portal-entries"
          "semester-provisioning" "snipr" "typo3" "zammad"
          "dask" "intercom"
        ];

        buildService = name:
          let
            data = import ./k8s/${name}.nix { inherit lib; };
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
