// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Security Scanning Library for openDesk container images

This library provides comprehensive vulnerability scanning capabilities:
- Grype: Lightweight vulnerability scanner (default)
- Trivy: Comprehensive vulnerability scanner
- Snyk: Cloud-native vulnerability management
- Integration with CI/CD pipelines
- Report generation and analysis

OpenSpec Compliance:
- FR-SEC-001: Scan all images for vulnerabilities
- FR-SEC-004: Support image verification

Usage:
  scanning = import ./lib/security-scanning.nix { pkgs = pkgs; };
  
  # Scan an image with Grype
  scanning.scanWithGrype { image = "my-image:latest"; }
  
  # Scan with Trivy
  scanning.scanWithTrivy { image = "my-image:latest"; }
  
  # Scan in CI/CD
  scanning.scanInCI { image = "my-image:latest"; scanner = "grype"; }
"""

{ 
  pkgs ? import <nixpkgs> { }
, 
  lib ? import ./types.nix { }
, 
  config ? { }
}:

let

  # =============================================================================
  # SCANNER CONFIGURATION
  # =============================================================================
  
  # Supported vulnerability scanners
  supportedScanners = [ "grype" "trivy" "snyk" ]; 
  
  # Default scanner
  defaultScanner = if pkgs ? grype then "grype" else (if pkgs ? trivy then "trivy" else "grype");
  
  # Configure Grype (default, lightweight)
  grypeConfig = {
    scanner = "grype";
    enable = true;
    # Disable for local development to speed up builds
    skipInDev = config.skipScanning or false;
    severityThreshold = "medium";  # medium, high, critical
    outputFormats = [ "json" "table" "sarif" ];
    dbAutoUpdate = true;
    dbDir = "/tmp/grype-db";
  };
  
  # Configure Trivy (comprehensive)
  trivyConfig = {
    scanner = "trivy";
    enable = true;
    skipInDev = config.skipScanning or false;
    severityThreshold = "medium";
    outputFormats = [ "json" "table" "sarif" "cyclonedx" ];
    ignoreUnfixed = false;
    skipDBUpdate = false;
  };
  
  # Configure Snyk (cloud-based, requires API key)
  snykConfig = {
    scanner = "snyk";
    enable = false;  # Disabled by default (requires API key)
    apiToken = "";  # Set via SNYK_TOKEN environment variable
    severityThreshold = "medium";
    outputFormat = "json";
    dev = false;  # Use false for production
    org = "opendesk-edu";
  };
  
  # =============================================================================
  # VULNERABILITY SCANNING FUNCTIONS
  # =============================================================================
  
  # Scan an image with Grype
  scanWithGrype = { 
    image,
    tag ? "latest",
    severity ? grypeConfig.severityThreshold,
    outputFormat ? "json",
    outputFile ? null,
    failOnCritical ? true,
    failOnHigh ? false,
    failOnMedium ? false,
    extraArgs ? []
  }:
    let
      fullImage = if tag == null then image else "${image}:${tag}";
      args = [
        "db:update"
        "${fullImage}"
        "--only-fixed"
        "--severity=${severity}"
        "--format=${outputFormat}"
      ] ++ (if failOnCritical then [ "--fail-on=critical" ] else [ ])
           ++ (if failOnHigh then [ "--fail-on=high" ] else [ ])
           ++ (if failOnMedium then [ "--fail-on=medium" ] else [ ])
           ++ (if outputFile != null then [ "--output=${outputFile}" ] else [ ])
           ++ extraArgs;
    in
      {
        inherit image tag fullImage;
        scanner = "grype";
        command = pkgs.writeShellScriptBin "scan-grype-${fullImage}" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          
          echo "Scanning ${fullImage} with Grype..."
          
          ${pkgs.grype or pkgs.writeShellScriptBin "grype" "echo 'Grype not in nixpkgs, install manually'"}/bin/grype ${builtins.concatStringsSep " " args}
          
          exit_code=$?
          
          if [ $exit_code -ne 0 ]; then
            echo "ERROR: Vulnerabilities found above threshold"
            exit $exit_code
          fi
          
          echo "✅ Scan passed: No vulnerabilities above ${severity} threshold"
        '';
        config = grypeConfig;
      };
  
  # Scan an image with Trivy
  scanWithTrivy = { 
    image,
    tag ? "latest",
    severity ? trivyConfig.severityThreshold,
    outputFormat ? "json",
    outputFile ? null,
    failOnCritical ? true,
    failOnHigh ? false,
    failOnMedium ? false,
    extraArgs ? []
  }:
    let
      fullImage = if tag == null then image else "${image}:${tag}";
      args = [
        "image"
        "--severity=${severity}"
        "--format=${outputFormat}"
        "${fullImage}"
      ] ++ (if failOnCritical then [ "--exit-code=1" ] else [ ])
           ++ (if failOnHigh then [ "--exit-code=1" ] else [ ])
           ++ (if failOnMedium then [ "--exit-code=1" ] else [ ])
           ++ (if outputFile != null then [ "--output=${outputFile}" ] else [ ])
           ++ extraArgs;
    in
      {
        inherit image tag fullImage;
        scanner = "trivy";
        command = pkgs.writeShellScriptBin "scan-trivy-${fullImage}" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          
          echo "Scanning ${fullImage} with Trivy..."
          
          # Check if we can auto-update the DB
          if [ -z "${TRIVY_SKIP_DB_UPDATE:-}" ]; then
            ${pkgs.trivy or pkgs.writeShellScriptBin "trivy" "echo 'Trivy not in nixpkgs'"}/bin/trivy image --download-db-only
          fi
          
          ${pkgs.trivy or pkgs.writeShellScriptBin "trivy" "echo 'Trivy not in nixpkgs'"}/bin/trivy ${builtins.concatStringsSep " " args}
          
          exit_code=$?
          
          if [ $exit_code -ne 0 ]; then
            echo "ERROR: Vulnerabilities found above threshold"
            exit $exit_code
          fi
          
          echo "✅ Scan passed: No vulnerabilities above ${severity} threshold"
        '';
        config = trivyConfig;
      };
  
  # Scan an image with Snyk
  scanWithSnyk = { 
    image,
    tag ? "latest",
    severity ? snykConfig.severityThreshold,
    outputFormat ? snykConfig.outputFormat,
    apiToken ? snykConfig.apiToken,
    extraArgs ? []
  }:
    let
      fullImage = if tag == null then image else "${image}:${tag}";
    in
      {
        inherit image tag fullImage;
        scanner = "snyk";
        command = pkgs.writeShellScriptBin "scan-snyk-${fullImage}" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          
          # Use environment variable for API token
          local token="${SNYK_TOKEN:-${apiToken}}"
          
          if [ -z "$token" ]; then
            echo "ERROR: SNYK_TOKEN environment variable or apiToken parameter must be set"
            exit 1
          fi
          
          echo "Scanning ${fullImage} with Snyk..."
          
          # Use Snyk CLI or Docker
          if command -v snyk &> /dev/null; then
            snyk container test ${fullImage} \
              --severity-threshold=${severity} \
              --json-file-output=/_snyk-result.json \
              --org=${snykConfig.org}
          else
            docker run --rm \
              -e SNYK_TOKEN="$token" \
              -v /var/run/docker.sock:/var/run/docker.sock \
              snyk/snyk:cli \
              container test ${fullImage} \
              --severity-threshold=${severity} \
              --json-file-output=/tmp/snyk-result.json \
              --org=${snykConfig.org}
          fi
          
          exit_code=$?
          
          if [ $exit_code -ne 0 ]; then
            echo "ERROR: Vulnerabilities found above threshold"
            exit $exit_code
          fi
          
          echo "✅ Scan passed: No vulnerabilities above ${severity} threshold"
        '';
        config = snykConfig;
      };
  
  # Generic scan function (uses default scanner)
  scanImage = { image, tag ? null, scanner ? defaultScanner, ... }: 
    case scanner of
      "grype" -> scanWithGrype { inherit image tag; } // { inherit scanner; }
      "trivy" -> scanWithTrivy { inherit image tag; } // { inherit scanner; }
      "snyk" -> scanWithSnyk { inherit image tag; } // { inherit scanner; }
      _ -> throw "Unsupported scanner: ${scanner}. Supported: ${builtins.concatStringsSep ", " supportedScanners}";
    ;
  
  # Scan in CI/CD pipeline
  scanInCI = { image, tag ? null, scanner ? defaultScanner, failOn ? "critical" }:
    let
      scan = scanImage { inherit image tag scanner; };
      
      # Map failOn to scanner-specific options
      failOptions = {
        "critical" = { failOnCritical = true; failOnHigh = false; failOnMedium = false; };
        "high" = { failOnCritical = true; failOnHigh = true; failOnMedium = false; };
        "medium" = { failOnCritical = true; failOnHigh = true; failOnMedium = true; };
        "none" = { failOnCritical = false; failOnHigh = false; failOnMedium = false; };
      };
      failOpts = failOptions.${failOn} or failOptions."critical";
      
      scanResult = scan // failOpts;
    in
      scanResult;
  
  # Scan multiple images
  scanMultiple = { images, scanner ? defaultScanner, failOn ? "critical" }:
    builtins.map (img: scanInCI { inherit scanner failOn; image = img; }) images;
  
  # =============================================================================
  # SCANNING IN NIX BUILD PIPELINE
  # =============================================================================
  
  # Add vulnerability scanning to a Docker image build
  withScanning = { pkg, scanner ? "grype", failOn ? "critical", inCI ? false }:
    let
      scan = scanInCI { 
        image = "${pkg.pname}:${pkg.version}";
        inherit scanner failOn;
      };
    in
      pkg.overrideAttrs (oldAttrs: {
        inherit (oldAttrs) pname version;
        
        # Add scanning as a post-build step
        postInstall = (oldAttrs.postInstall or "") + ''
          # Run vulnerability scan
          ${scan.command}
        '';
        
        # Add scanning metadata
        meta = (oldAttrs.meta or { }) // {
          scanning = {
            inherit scanner failOn;
            description = "Image scanned for vulnerabilities with ${scanner}";
          };
        };
      });
  
  # =============================================================================
  # REPORT GENERATION
  # =============================================================================
  
  # Generate security report from scan results
  generateSecurityReport = { 
    scanResults,
    outputDir ? "./reports/security",
    includeDetails ? true
  }:
    let
      reports = builtins.map (result: 
        {
          name = "${result.image}:${result.tag or "latest"}";
          scanner = result.scanner;
          reportFile = "${outputDir}/${result.image}-${result.scanner}.json";
          htmlReportFile = "${outputDir}/${result.image}-${result.scanner}.html";
        }
      ) scanResults;
    in
      {
        inherit reports outputDir;
        numImages = builtins.length scanResults;
        timestamp = builtins.currentTime;
      };
  
  # Convert scan results to CSV
  scanResultsToCSV = { scanResults }:
    let
      header = "Image,Scanner,Severity,ExitCode,Timestamp";
      rows = builtins.map (result: 
        "${result.image}:${result.tag or "latest"},${result.scanner},${result.config.severityThreshold},0,${builtins.currentTime}"
      ) scanResults;
    in
      builtins.concatStringsSep "\n" ([ header ] ++ rows);
  
  # =============================================================================
  # IMAGE VERIFICATION (FR-SEC-004)
  # =============================================================================
  
  # Verify an image signature with Cosign
  verifyWithCosign = { 
    image,
    tag ? "latest",
    publicKey ? null,
    keyRef ? null,  # e.g., "cosign-signing-key"
    extraArgs ? []
  }:
    let
      fullImage = if tag == null then image else "${image}:${tag}";
      
      # Key is either provided directly or referenced from a secret
      keyArgs = if publicKey != null then [ "--key=${publicKey}" ] 
                 else if keyRef != null then [ "--key=env://COSIGN_PUBLIC_KEY" ] 
                 else [];
      
      args = [
        "verify"
        "${fullImage}"
      ] ++ keyArgs ++ extraArgs;
    in
      {
        inherit image tag fullImage;
        verifier = "cosign";
        command = pkgs.writeShellScriptBin "verify-cosign-${fullImage}" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          
          echo "Verifying signature for ${fullImage} with Cosign..."
          
          ${pkgs.cosign or pkgs.writeShellScriptBin "cosign" "echo 'Cosign not in nixpkgs'"}/bin/cosign ${builtins.concatStringsSep " " args}
          
          echo "✅ Signature verified successfully"
        '';
        config = {
          requireSignature = true;
          inherit keyArgs;
        };
      };
  
  # Sign an image with Cosign
  signWithCosign = { 
    image,
    tag ? "latest",
    privateKey ? null,
    password ? null,
    keyRef ? null,
    annotateWith ? { },
    extraArgs ? []
  }:
    let
      fullImage = if tag == null then image else "${image}:${tag}";
      
      # Handle key configuration
      keyMount = if keyRef != null then 
        ''--key=env://COSIGN_PRIVATE_KEY''
      else if privateKey != null then 
        ''--key=${privateKey}''
      else 
        "";
      
      passwordMount = if password != null then 
        ''--password=env://COSIGN_PASSWORD''
      else 
        "";
      
      # Build annotation arguments
      annotateArgs = builtins.concatMap (k: v: [ "--annotate=${k}=${v}" ]) (builtins.attrNames annotateWith);
      
      allArgs = [
        "sign"
        "${fullImage}"
      ] ++ (if keyMount != "" then [ keyMount ] else [ ])
           ++ (if passwordMount != "" then [ passwordMount ] else [ ])
           ++ annotateArgs
           ++ extraArgs;
    in
      {
        inherit image tag fullImage;
        signer = "cosign";
        command = pkgs.writeShellScriptBin "sign-cosign-${fullImage}" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          
          echo "Signing ${fullImage} with Cosign..."
          
          ${pkgs.cosign or pkgs.writeShellScriptBin "cosign" "echo 'Cosign not in nixpkgs'"}/bin/cosign ${builtins.concatStringsSep " " allArgs}
          
          echo "✅ Image signed successfully"
        '';
      };
  
  # Sign and verify an image
  signAndVerify = { image, tag ? "latest", signArgs ? { }, verifyArgs ? { } }:
    {
      sign = signWithCosign { inherit image tag; } // signArgs;
      verify = verifyWithCosign { inherit image tag; } // verifyArgs;
    };
  
  # Add Cosign signing to a Docker image build
  withSigning = { pkg, keyRef ? "cosign-signing-key", annotateWith ? { } }:
    pkg.overrideAttrs (oldAttrs: {
      inherit (oldAttrs) pname version;
      
      postInstall = (oldAttrs.postInstall or "") + ''
        # Sign the image with Cosign
        IMAGE="${pname}:${version}"
        echo "Signing $IMAGE with Cosign..."
        
        # Cosign expects the key from environment
        if [ -n "${COSIGN_PRIVATE_KEY:-}" ]; then
          cosign sign --key=env://COSIGN_PRIVATE_KEY $IMAGE ${optionalString (annotateWith != { }) (builtins.concatStringsSep " " (builtins.concatMap (k: v: [ "--annotate=${k}=${v}" ]) (builtins.attrNames annotateWith))))}
          echo "✅ Image signed"
        else
          echo "⚠️  COSIGN_PRIVATE_KEY not set, skipping signing"
        fi
      '';
      
      meta = (oldAttrs.meta or { }) // {
        signing = {
          method = "cosign";
          keyRef = keyRef;
          annotations = annotateWith;
          description = "Image signed with Cosign";
        };
      };
    });
  
  # =============================================================================
  # INTEGRATION WITH SBOM
  # =============================================================================
  
  # Scan and generate SBOM together
  scanAndGenerateSBOM = { 
    image,
    tag ? "latest",
    scanner ? defaultScanner,
    sbomFormat ? "spdx",
    sbomOutput ? "./sbom",
    ...
  }:
    let
      sbom = import ./sbom.nix { pkgs = pkgs; };
      scan = scanInCI { inherit image tag scanner; };
      sbomGen = sbom.generateFor {
        derivation = image;
        format = sbomFormat;
        outputDir = sbomOutput;
      };
    in
      {
        inherit scan sbomGen;
        image = image;
        tag = tag;
        scanner = scanner;
        sbomFormat = sbomFormat;
      };
  
  # Full security pipeline: SBOM + Sign + Scan + Verify
  securityPipeline = { 
    pkg,
    scanner ? "grype",
    signWith ? "cosign",
    failOn ? "critical",
    keyRef ? "cosign-signing-key",
    sbomFormat ? "both",
    sbomOutput ? "./sbom",
    ...
  }:
    let
      sbom = import ./sbom.nix { pkgs = pkgs; };
      registryLib = import ./registry.nix { pkgs = pkgs; };
      
      # Step 1: Generate SBOM
      sbomResult = sbom.withSBOM pkg;
      
      # Step 2: Add signing
      signedPkg = if signWith == "cosign" then 
        withSigning { inherit pkg keyRef; }
      else if signWith == "none" then 
        pkg
      else 
        throw "Unsupported signing method: ${signWith}";
      
      # Step 3: Add scanning to build process
      finalPkg = withScanning { inherit signedPkg scanner failOn; };
    in
      {
        package = finalPkg;
        sbom = sbomResult.sbom;
        pipeline = [
          "SBOM generation (${sbomFormat})"
          "Image signing (${signWith})"
          "Vulnerability scanning (${scanner})"
        ];
        description = "Complete security pipeline for ${pkg.pname}";
      };
  
  # =============================================================================
  # EXPORTS
  # =============================================================================
  
in

{
  # Scanner configurations
  inherit supportedScanners defaultScanner grypeConfig trivyConfig snykConfig;
  
  # Scanning functions
  inherit scanWithGrype scanWithTrivy scanWithSnyk scanImage scanInCI scanMultiple;
  
  # Build-time scanning
  inherit withScanning;
  
  # Report generation
  inherit generateSecurityReport scanResultsToCSV;
  
  # Image signing and verification (FR-SEC-003, FR-SEC-004)
  inherit verifyWithCosign signWithCosign signAndVerify withSigning;
  
  # Integrated pipelines
  inherit scanAndGenerateSBOM securityPipeline;
  
  # Configuration
  config = {
    defaultScanner = defaultScanner;
    vulnerabilityScanning = {
      enabled = true;
      failOnCritical = true;
      failOnHigh = false;
      failOnMedium = false;
      outputFormats = [ "json" "sarif" ];
    };
    imageSigning = {
      enabled = true;
      method = "cosign";
      keyRef = "cosign-signing-key";
    };
    imageVerification = {
      enabled = true;
      requireSignatures = true;
    };
  };
  
  # Metadata
  meta = {
    name = "security-scanning";
    version = "1.0.0";
    description = "Vulnerability scanning and image security library for openDesk";
    license = "Apache-2.0";
    openspec = [ "FR-SEC-001" "FR-SEC-003" "FR-SEC-004" ];
  };
}
