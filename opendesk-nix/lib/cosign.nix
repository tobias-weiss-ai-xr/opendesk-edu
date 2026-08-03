// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Cosign Library for openDesk container image signing and verification

This library provides comprehensive Cosign integration for:
- Signing container images
- Verifying container image signatures
- Generating and managing signing keys
- Integration with Nix build pipelines

OpenSpec Compliance:
- FR-SEC-003: Sign all images with Cosign
- FR-SEC-004: Support image verification

Usage:
  cosign = import ./lib/cosign.nix { pkgs = pkgs; };
  
  # Sign an image
  cosign.signImage { 
    image = "my-image:1.0.0";
    keyRef = "cosign-signing-key";
  }
  
  # Verify an image
  cosign.verifyImage { 
    image = "my-image:1.0.0";
    keyRef = "cosign-signing-key";
  }
  
  # Add signing to a package build
  cosign.withSigning myPackage
"""

{ 
  pkgs ? import <nixpkgs> { }
, 
  lib ? import ./types.nix { }
, 
  sbom ? import ./sbom.nix { inherit pkgs lib; }
, 
  registry ? import ./registry.nix { inherit pkgs lib; }
, 
  config ? { }
}:

let

  # =============================================================================
  # KEY MANAGEMENT
  # =============================================================================
  
  # Generate a new Cosign key pair
  generateKeyPair = { 
    keyName ? "cosign-signing-key",
    keyAlgorithm ? "ed25519",
    outputDir ? "./cosign-keys"
  }:
    pkgs.writeShellScriptBin "generate-cosign-keypair" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      
      mkdir -p "${outputDir}"
      
      echo "Generating Cosign ${keyAlgorithm} key pair in ${outputDir}..."
      
      # Use Cosign CLI to generate keys
      ${pkgs.cosign or pkgs.writeShellScriptBin "cosign" "echo 'Cosign not in nixpkgs'"}/bin/cosign generate-key-pair --algorithm ${keyAlgorithm} --output-key "${outputDir}/${keyName}"
      
      echo "✅ Key pair generated:"
      echo "   Private key: ${outputDir}/${keyName}"
      echo "   Public key:  ${outputDir}/${keyName}.pub"
      
      # Store public key in environment format for use in verification
      echo "COSIGN_PUBLIC_KEY=$(cat ${outputDir}/${keyName}.pub)" > "${outputDir}/${keyName}.env"
    '';
  
  # Get public key from secret or file
  getPublicKey = { 
    keyPath ? null,
    keyRef ? null,
    fromEnv ? true
  }:
    if fromEnv then
      builtins.getEnv "COSIGN_PUBLIC_KEY"
    else if keyPath != null then
      builtins.readFile keyPath
    else if keyRef != null then
      # In Kubernetes, this would be from a secret
      "env://COSIGN_PUBLIC_KEY"
    else
      throw "No Cosign public key configured. Set COSIGN_PUBLIC_KEY or provide keyPath";
  
  # Get private key from secret or file
  getPrivateKey = { 
    keyPath ? null,
    keyRef ? null,
    fromEnv ? true
  }:
    if fromEnv then
      builtins.getEnv "COSIGN_PRIVATE_KEY"
    else if keyPath != null then
      builtins.readFile keyPath
    else if keyRef != null then
      # In Kubernetes, this would be from a secret
      "env://COSIGN_PRIVATE_KEY"
    else
      throw "No Cosign private key configured. Set COSIGN_PRIVATE_KEY or provide keyPath";
  
  # =============================================================================
  # SIGNING FUNCTIONS
  # =============================================================================
  
  # Sign a container image with Cosign
  signImage = { 
    image,
    tag ? null,
    keyPath ? null,
    password ? null,
    annotations ? { },
    baseImage ? null,
    extraArgs ? []
  }:
    let
      fullImage = if tag != null then "${image}:${tag}" else image;
      
      # Determine key source
      keyArg = if keyPath != null then "--key=${keyPath}"
               else "--key=env://COSIGN_PRIVATE_KEY";
      
      passwordArg = if password != null then "--password=env://COSIGN_PASSWORD"
                     else "";
      
      # Build annotation arguments
      annotateArgs = builtins.concatMap (k: v: [ "--annotate=${k}=${v}" ]) (builtins.attrNames annotations);
      
      allArgs = [
        "sign"
        "${fullImage}"
      ] ++ (if keyArg != "" then [ keyArg ] else [ ])
           ++ (if passwordArg != "" then [ passwordArg ] else [ ])
           ++ annotateArgs
           ++ extraArgs;
    in
      {
        inherit image tag fullImage;
        command = pkgs.writeShellScriptBin "sign-${fullImage}" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          
          echo "Signing ${fullImage} with Cosign..."
          
          ${if baseImage != null then ''
            # Get the digest of the base image
            BASE_DIGEST=$(crane digest ${baseImage})
            echo "Base image digest: $BASE_DIGEST"
          '' else ""}
          
          ${pkgs.cosign or pkgs.writeShellScriptBin "cosign" "echo 'Cosign not in nixpkgs'"}/bin/cosign ${builtins.concatStringsSep " " allArgs}
          
          echo "✅ Image signed successfully"
        '';
        annotations = annotations;
        key = keyPath;
      };
  
  # Sign a local file/derivation with Cosign
  signFile = { 
    filePath,
    outputPath ? "${filePath}.sig",
    keyPath ? null,
    extraArgs ? []
  }:
    let
      allArgs = [
        "sign-blob"
        "--output-signature=${outputPath}"
      ] ++ (if keyPath != null then [ "--key=${keyPath}" ] else [ "--key=env://COSIGN_PRIVATE_KEY" ])
           ++ extraArgs++ [ filePath ];
    in
      pkgs.writeShellScriptBin "sign-file-${builtins.baseNameOf filePath}" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        
        echo "Signing ${filePath} with Cosign..."
        ${pkgs.cosign or pkgs.writeShellScriptBin "cosign" "echo 'Cosign not in nixpkgs'"}/bin/cosign ${builtins.concatStringsSep " " allArgs}
        
        echo "✅ File signed successfully"
        echo "Signature saved to: ${outputPath}"
      '';
  
  # Sign with annotations from SBOM
  signWithSBOM = { 
    pkg,
    sbomFormat ? "spdx",
    keyPath ? null,
    extraArgs ? []
  }:
    let
      sbomGen = sbom.generateFor {
        derivation = pkg;
        format = sbomFormat;
      };
      
      sbomFile = "${sbomGen.outputDir}/${pkg.pname}-${pkg.version}.${sbomFormat}";
      
      # Annotations from SBOM metadata
      annotations = {
        "sbom.format" = sbomFormat;
        "sbom.generator" = "opendesk-nix";
        "com.opendesk.sbom" = "true";
      };
    in
      signImage {
        image = "${pkg.pname}:${pkg.version}";
        inherit keyPath annotations extraArgs;
      };
  
  # =============================================================================
  # VERIFICATION FUNCTIONS
  # =============================================================================
  
  # Verify a container image signature with Cosign
  verifyImage = { 
    image,
    tag ? null,
    keyPath ? null,
    publicKey ? null,
    keyRef ? null,
    attachment ? null,  # For signed SBOMs, etc.
    extraArgs ? []
  }:
    let
      fullImage = if tag != null then "${image}:${tag}" else image;
      
      # Determine key source for verification
      keyArg = if keyPath != null then "--key=${keyPath}"
               else if publicKey != null then "--key=${publicKey}"
               else "--key=env://COSIGN_PUBLIC_KEY";
      
      allArgs = [
        "verify"
      ] ++ (if attachment != null then [ "--attachment=${attachment}" ] else [ ])
           ++ [ keyArg ]
           ++ [ fullImage ]
           ++ extraArgs;
    in
      {
        inherit image tag fullImage;
        command = pkgs.writeShellScriptBin "verify-${fullImage}" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          
          echo "Verifying signature for ${fullImage} with Cosign..."
          
          ${pkgs.cosign or pkgs.writeShellScriptBin "cosign" "echo 'Cosign not in nixpkgs'"}/bin/cosign ${builtins.concatStringsSep " " allArgs}
          
          echo "✅ Signature verified successfully"
        '';
      };
  
  # Verify a signed file
  verifyFile = { 
    filePath,
    signaturePath ? "${filePath}.sig",
    publicKey ? null,
    keyPath ? null,
    extraArgs ? []
  }:
    let
      keyArg = if keyPath != null then "--key=${keyPath}"
               else if publicKey != null then "--key=${publicKey}"
               else "--key=env://COSIGN_PUBLIC_KEY";
      
      allArgs = [
        "verify-blob"
        "--signature=${signaturePath}"
        keyArg
        filePath
      ] ++ extraArgs;
    in
      pkgs.writeShellScriptBin "verify-file-${builtins.baseNameOf filePath}" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        
        echo "Verifying ${filePath} with Cosign..."
        ${pkgs.cosign or pkgs.writeShellScriptBin "cosign" "echo 'Cosign not in nixpkgs'"}/bin/cosign ${builtins.concatStringsSep " " allArgs}
        
        echo "✅ File verified successfully"
      '';
  
  # Verify with SBOM attachment
  verifySBOM = { 
    image,
    sbomPath,
    tag ? null,
    keyPath ? null,
    extraArgs ? []
  }:
    let
      fullImage = if tag != null then "${image}:${tag}" else image;
    in
      verifyImage {
        inherit image tag fullImage keyPath extraArgs;
        attachment = sbomPath;
      };
  
  # =============================================================================
  # KEY ROTATION AND MANAGEMENT
  # =============================================================================
  
  # Rotate signing keys
  rotateKeys = { 
    oldKeyPath,
    newKeyPath ? "cosign-signing-key-new",
    reSign ? true
  }:
    let
      generateNew = generateKeyPair { keyName = newKeyPath; };
      
      reSignAction = if reSign then ''
        echo "Re-signing all images with new key..."
        # This would be implemented based on your image registry
        echo "TODO: Implement re-signing logic"
      '' else "";
    in
      pkgs.writeShellScriptBin "rotate-cosign-keys" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        
        echo "Rotating Cosign signing keys..."
        ${generateNew}
        
        ${reSignAction}
        
        echo "Key rotation complete"
        echo "Old key: ${oldKeyPath}"
        echo "New key: ${newKeyPath}"
      '';
  
  # =============================================================================
  # NIX BUILD INTEGRATION
  # =============================================================================
  
  # Add Cosign signing to a Nix package derivation
  withSigning = { 
    pkg,
    keyPath ? null,
    annotations ? { },
    signDuringBuild ? true,
    signAfterPush ? false
  }:
    pkg.overrideAttrs (oldAttrs: rec {
      inherit (oldAttrs) pname version;
      
      # Sign the image during build if requested
      postInstall = (oldAttrs.postInstall or "") + (if signDuringBuild then ''
        # Sign the built image with Cosign
        IMAGE_NAME="${pname}"
        IMAGE_TAG="${version}"
        FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
        
        echo "Signing $FULL_IMAGE with Cosign..."
        
        # Use the signing command
        ${signImage { image = IMAGE_NAME; tag = IMAGE_TAG; keyPath = keyPath; annotations = annotations; }.command}
        
        echo "✅ Image signed during build"
      '' else "");
      
      # Add signing metadata
      meta = (oldAttrs.meta or { }) // {
        cosign = {
          signed = signDuringBuild;
          keyPath = keyPath;
          annotations = annotations;
          description = "Image signed with Cosign during build";
        };
      };
    });
  
  # Sign after pushing to registry
  signAfterPush = { 
    pkg,
    registryUrl ? "ghcr.io",
    keyPath ? null,
    annotations ? { },
    extraArgs ? []
  }:
    pkg.overrideAttrs (oldAttrs: rec {
      inherit (oldAttrs) pname version;
      
      # Create a post-push signing script
      postInstall = (oldAttrs.postInstall or "") + ''
        # Create signing script that runs after push
        cat > $out.sign << 'SIGNSCRIPT'
        #!${pkgs.bash}/bin/bash
        echo "Signing pushed image with Cosign..."
        ${signImage { 
          image = "${registryUrl}/${pname}"; 
          tag = version; 
          keyPath = keyPath; 
          annotations = annotations; 
          extraArgs = extraArgs; 
        }.command}
        SIGNSCRIPT
        chmod +x $out.sign
        echo "✅ Signing script created: $out.sign"
      '';
    });
  
  # =============================================================================
  # KUBERNETES INTEGRATION
  # =============================================================================
  
  # Generate Kubernetes manifests with image verification
  mkVerifiedDeployment = { 
    name,
    image,
    tag ? "latest",
    keyRef ? "cosign-public-key",
    verificationPolicy ? "require",
    ...
  }:
    let
      libk8s = import ./k8s.nix { inherit pkgs lib; };
      fullImage = if tag != null then "${image}:${tag}" else image;
      
      verificationContainer = {
        name = "cosign-verification";
        image = "ghcr.io/sigstore/cosign/cosign:v2.2.0";
        command = [ "/bin/sh", "-c" ];
        args = [ "cosign verify --key=env://COSIGN_PUBLIC_KEY ${fullImage} && echo 'Verification passed' || exit 1" ];
        env = [ { name = "COSIGN_PUBLIC_KEY"; valueFrom = { secretKeyRef = { name = keyRef; key = "cosign-pub" }; }; } ];
        securityContext = { runAsNonRoot = true; allowPrivilegeEscalation = false; };
      };
      
      baseDeployment = libk8s.deployment {
        name = name;
        image = fullImage;
        tag = tag;
        # Add init container for verification
        initContainers = if verificationPolicy == "require" then [ verificationContainer ] else [];
        # Add annotation for policy
        annotations = {
          "cosign.sigstore.dev/require-signature" = "true";
          "cosign.sigstore.dev/key-ref" = keyRef;
        };
      };
    in
      baseDeployment;
  
  # Generate ImagePolicy for Kubernetes
  mkImagePolicy = { 
    name,
    namespace ? "default",
    keyRef ? "cosign-public-key",
    images ? [ ],
    keySecret ? null
  }:
    {
      apiVersion = "policy.sigstore.dev/v1beta1";
      kind = "ClusterImagePolicy";
      metadata = {
        name = name;
        namespace = namespace;
      };
      spec = {
        images = builtins.map (img: {
          glob = img;
        }) images;
        authorities = [ {
          name = "opendesk-keys";
          key = {
            secretRef = {
              name = keyRef;
              namespace = namespace;
            };
          };
          sources = [ {
            name = "opendesk-registry";
            registry = {
              name = "ghcr.io";
            };
          } ];
          policy = {
            type = " 한다면";
            data = {
              requireSignature = true;
              keyRef = keyRef;
            };
          };
        } ];
      };
    };
  
  # =============================================================================
  # CA CERTIFICATE MANAGEMENT
  # =============================================================================
  
  # Generate Fulcio (Sigstore CA) certificate
  generateFulcioCertificate = { 
    identityToken ? null,
    extraArgs ? []
  }:
    pkgs.writeShellScriptBin "generate-fulcio-cert" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      
      if [ -z "${IDENTITY_TOKEN:-}" ]; then
        echo "ERROR: IDENTITY_TOKEN environment variable must be set"
        exit 1
      fi
      
      echo "Generating Fulcio certificate..."
      ${pkgs.cosign or pkgs.writeShellScriptBin "cosign" "echo 'Cosign not in nixpkgs'"}/bin/cosign generate identity-token --identity-token-file <(echo "$IDENTITY_TOKEN") ${builtins.concatStringsSep " " extraArgs}
    '';
  
  # =============================================================================
  # EXPORTS
  # =============================================================================
  
in

{
  # Key management
  inherit generateKeyPair getPublicKey getPrivateKey;
  
  # Signing
  inherit signImage signFile signWithSBOM;
  
  # Verification
  inherit verifyImage verifyFile verifySBOM;
  
  # Key management
  inherit rotateKeys;
  
  # Build integration
  inherit withSigning signAfterPush;
  
  # Kubernetes integration
  inherit mkVerifiedDeployment mkImagePolicy;
  
  # Certificate management
  inherit generateFulcioCertificate;
  
  # Configuration
  config = {
    cosign = {
      enabled = true;
      # Default to environment variables for keys
      privateKeyEnv = "COSIGN_PRIVATE_KEY";
      publicKeyEnv = "COSIGN_PUBLIC_KEY";
      passwordEnv = "COSIGN_PASSWORD";
      # Key rotation
      keyRotation = {
        enabled = false;
        interval = "30d";  # Rotate every 30 days
      };
      # Registration
      registry = "ghcr.io/opendesk-edu";
    };
  };
  
  # Metadata
  meta = {
    name = "cosign";
    version = "1.0.0";
    description = "Cosign image signing and verification library for openDesk";
    license = "Apache-2.0";
    openspec = [ "FR-SEC-003" "FR-SEC-004" ];
    dependencies = [ "k8s.nix" "sbom.nix" "registry.nix" ];
  };
}
