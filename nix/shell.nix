{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = with pkgs; [ kubectl yq-go just ];
  shellHook = ''
    echo "🔧 Nix deployment development shell"
    echo "  nix build .#<service>  — build a service"
    echo "  cat result | kubectl apply -f -  — deploy"
    echo "  yq -P evalall . result  — convert JSON to YAML"
  '';
}
