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
        ];

        buildService = name:
          pkgs.writeText "${name}.yaml" (
            builtins.toJSON (import ./k8s/${name}.nix { inherit lib; })
          );

        allServices = pkgs.symlinkJoin {
          name = "opendesk-edu";
          paths = map buildService services;
        };
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
