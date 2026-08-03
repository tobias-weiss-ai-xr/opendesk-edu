# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ lib, pkgs, ... }:

let
  mkCosignKeyPair = { name ? "cosign" }:
    pkgs.runCommand "${name}-keypair" {
      inherit (pkgs) cosign;
    } ''
      mkdir -p $out
      cosign generate-key-pair --output-key $out/${name}.key --output-pubkey $out/${name}.pub
      chmod 600 $out/${name}.key
    '';

  signWithCosign = { image, keyPath, outputPath ? "/tmp/signature" }:
    pkgs.runCommand "cosign-sign-${builtins.hashString "sha256" image}" {
      inherit (pkgs) cosign;
      nativeBuildInputs = [ pkgs.curl ];
    } ''
      cosign sign --key ${keyPath} ${image} > ${outputPath}
      echo "Signed: ${image}"
    '';

  verifyWithCosign = { image, keyPath, outputPath ? "/tmp/verification" }:
    pkgs.runCommand "cosign-verify-${builtins.hashString "sha256" image}" {
      inherit (pkgs) cosign;
    } ''
      cosign verify --key ${keyPath} ${image} > ${outputPath} 2>&1
      echo "Verification result saved to ${outputPath}"
    '';

in {
  inherit mkCosignKeyPair signWithCosign verifyWithCosign;
}
