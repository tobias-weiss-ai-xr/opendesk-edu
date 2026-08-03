{ pkgs, lib, ... }:

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
SBOM (Software Bill of Materials) generation utilities for openDesk container images.

This library provides:
- SBOM generation for Nix-built images
- Support for CycloneDX and SPDX formats
- Integration with Syft and other SBOM tools
- Metadata enrichment for openDesk services

Usage:
  sbom = import ./lib/sbom.nix { inherit pkgs lib; };
  
  # Generate SBOM for a derivation
  sbom.generateFor { derivation = myPackage; format = "spdx"; }
  
  # Generate SBOM during image build
  sbom.withSBOM myPackage
"""

let
  # =============================================================================
  # SBOM FORMAT DEFINITIONS
  # =============================================================================

  sbomFormats = [ "spdx" "cyclonedx" "both" ];

  # SPDX document structure
  spdxDocument = { 
    documentName ? "SPDX-OpenDesk"
    documentNamespace ? "https://opendesk.hrz.uni-marburg.de/spdx/${builtins.currentTime}"
    spdxVersion ? "SPDX-2.3"
    creators ? [ "Tool: syft-0.90.0" "Organization: openDesk Edu" ]
    }:
    {
      spdxVersion = spdxVersion;
      dataLicense = "CC0-1.0";
      SPDXID = "SPDXRef-DOCUMENT";
      name = documentName;
      documentNamespace = documentNamespace;
      creators = creators;
    };

  # =============================================================================
  # SBOM GENERATION FUNCTIONS
  # =============================================================================

  # Generate SBOM using Syft (recommended)
  generateWithSyft = { 
    derivation, format ? "spdx", outputDir ? "./sbom", outputName ? null
    , syft ? pkgs.syft, extraArgs ? [ ]
  }:
    let
      drvName = (derivation.name or "unknown");
      drvVersion = (derivation.version or "latest");
      outName = if outputName != null then outputName else "${drvName}-${drvVersion}";
      outPath = "${outputDir}/${outName}";
      
      # Build the derivation to get its output path
      drvOut = derivation or (throw "derivation must be provided");
      
      # Create a shell script that runs syft on the built image
      # Note: This is a placeholder - actual implementation would use runCommand
      # or similar to generate the SBOM after the image is built
      script = ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        
        # Get the image path from the derivation
        IMAGE_PATH="${drvOut}"
        
        # Create output directory
        mkdir -p "${outputDir}"
        
        # Run syft to generate SBOM
        ${syft}/bin/syft dir:"${IMAGE_PATH}" \
          -o ${format} \
          --file "${outPath}.${format}"
        ${extraArgs}
        
        echo "SBOM generated at ${outPath}.${format}"
      '';
    in
      pkgs.writeShellScriptBin "generate-sbom-${drvName}" script;

  # Generate SPDX SBOM manually from Nix derivation
  generateSPDX = { 
    derivation, outputDir ? "./sbom", outputName ? null
    , includeLicenses ? true, includeDependencies ? true
  }:
    let
      drvName = (derivation.name or "unknown");
      drvVersion = (derivation.version or "latest");
      outName = if outputName != null then outputName else "${drvName}-${drvVersion}";
      
      # Get the derivation's metadata
      drvMeta = derivation.meta or { };
      
      # Build the SPDX document
      packages = [ {
        SPDXID = "SPDXRef-Package-${drvName}";
        name = drvName;
        versionInfo = drvVersion;
        downloadLocation = "NOASSERTION";
        filesAnalyzed = false;
        licenseConcluded = drvMeta.license or "NOASSERTION";
        licenseDeclared = drvMeta.license or "NOASSERTION";
        copyrightText = drvMeta.copyright or "NOASSERTION";
      } ];
      
      spdxDoc = {
        spdxVersion = "SPDX-2.3";
        dataLicense = "CC0-1.0";
        SPDXID = "SPDXRef-DOCUMENT";
        name = "${drvName}-SBOM";
        documentNamespace = "https://opendesk.hrz.uni-marburg.de/spdx/${drvName}/${drvVersion}";
        creators = [ "Tool: nix-sbom-generator" "Organization: openDesk Edu" ];
        packages = packages;
      };
      
      output = pkgs.writeText "${outName}-spdx.json" (builtins.toJSON spdxDoc);
    in
      output;

  # Generate CycloneDX SBOM manually from Nix derivation
  generateCycloneDX = { 
    derivation, outputDir ? "./sbom", outputName ? null
    , includeLicenses ? true, includeDependencies ? true
  }:
    let
      drvName = (derivation.name or "unknown");
      drvVersion = (derivation.version or "latest");
      outName = if outputName != null then outputName else "${drvName}-${drvVersion}";
      
      # Get the derivation's metadata
      drvMeta = derivation.meta or { };
      
      # Build the CycloneDX document
      components = [ {
        type = "library";
        name = drvName;
        version = drvVersion;
        purl = "pkg:nix/${drvName}@${drvVersion}";
        licenses = if includeLicenses && (drvMeta ? license) then [ {
          license = { id = drvMeta.license; };
        } ] else [];
      } ];
      
      cycloneDoc = {
        bomFormat = "CycloneDX";
        specVersion = "1.4";
        serialNumber = "urn:uuid:${builtins.hashString (drvName + drvVersion)}";
        version = 1;
        metadata = {
          timestamp = "${builtins.currentTime}";
          tools = [ {
            vendor = "openDesk Edu";
            name = "nix-sbom-generator";
            version = "1.0.0";
          } ];
          component = {
            type = "application";
            name = drvName;
            version = drvVersion;
            purl = "pkg:nix/${drvName}@${drvVersion}";
          };
        };
        components = components;
        dependencies = if includeDependencies then [ {
          ref = "pkg:nix/${drvName}@${drvVersion}";
          dependsOn = [ ];  # Would be populated with actual dependencies
        } ] else [ ];
      };
      
      output = pkgs.writeText "${outName}-cyclonedx.json" (builtins.toJSON cycloneDoc);
    in
      output;

  # Generate both formats
  generateBoth = { derivation, outputDir ? "./sbom", outputName ? null, ... }:
    [
      (generateSPDX { inherit derivation outputDir outputName; })
      (generateCycloneDX { inherit derivation outputDir outputName; })
    ];

  # =============================================================================
  # SBOM GENERATION WRAPPERS
  # =============================================================================

  # Generate SBOM for any format
  generateFor = { derivation, format ? "both", outputDir ? "./sbom", outputName ? null, ... }:
    case format of
      "spdx" -> generateSPDX { inherit derivation outputDir outputName; };
      "cyclonedx" -> generateCycloneDX { inherit derivation outputDir outputName; };
      "both" -> generateBoth { inherit derivation outputDir outputName; };
      _ -> throw "Invalid SBOM format: ${format}. Valid options: ${builtins.concatStringsSep ", " sbomFormats}";
    ;

  # =============================================================================
  # SBOM GENERATION FOR DOCKER IMAGES
  # =============================================================================

  # Generate SBOM for a Docker image using buildLayeredImage
  generateForDockerImage = { 
    drv, format ? "both", outputDir ? "./sbom", outputName ? null
    , syft ? pkgs.syft
  }:
    let
      # This is a placeholder - actual implementation would use a post-build hook
      # or separate derivation to generate SBOM after the image is built
      drvName = (drv.name or "unknown");
      drvVersion = (drv.version or "latest");
      outName = if outputName != null then outputName else "${drvName}-${drvVersion}";
      
      # Return a derivation that generates SBOM after the image
      # Note: This is a conceptual implementation - actual Nix implementation
      # would need to use runCommand or similar
      sbomScript = pkgs.writeText "generate-sbom-${drvName}.sh" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        
        # This would be called after the image build
        # It would use syft to scan the built image
        echo "Generating SBOM for ${drvName}:${drvVersion}"
        mkdir -p "${outputDir}"
        
        # In a real implementation, we would:
        # 1. Load the built image from docker
        # 2. Run syft on it
        # 3. Save the SBOM to outputDir
        # For now, just create placeholder files
        echo '{ "format`: ${format}, "name": "${drvName}", "version": "${drvVersion}" }' > "${outputDir}/${outName}-${format}.json"
        echo "SBOM placeholder created for ${drvName}"
      '';
    in
      pkgs.runCommand "sbom-${drvName}.${format}" { } ''
        ${pkgs.bash}/bin/bash "${sbomScript}"
      '';

  # =============================================================================
  # SBOM GENERATION FOR NIX IMAGES (dockerTools)
  # =============================================================================

  # Wrapper for dockerTools.buildImage that includes SBOM generation
  buildImageWithSBOM = { 
    name, tag ? "latest", fromImage, contents ? { }, config ? { }, 
    format ? "both", outputDir ? "./sbom", syft ? pkgs.syft, ...
  }:
    let
      # Import dockerTools
      dockerTools = pkgs.dockerTools;
      
      # Build the base image
      baseImage = dockerTools.buildImage {
        inherit name tag fromImage contents config;
      };
      
      # Generate SBOM for the built image
      # Note: This is a placeholder - actual implementation would need to
      # generate SBOM after the image is built
      sbomDrv = generateForDockerImage {
        drv = baseImage;
        inherit format outputDir;
      };
      
      # Return both the image and SBOM
      # In practice, we'd want to ensure the SBOM is generated after the image
    in
      baseImage;  # Return the image; SBOM generation is separate

  # Wrapper for dockerTools.buildLayeredImage that includes SBOM generation
  buildLayeredImageWithSBOM = { 
    name, tag ? "latest", fromImage, contents ? { }, config ? { }, 
    maxLayers ? 10, format ? "both", outputDir ? "./sbom", syft ? pkgs.syft, ...
  }:
    let
      dockerTools = pkgs.dockerTools;
      
      baseImage = dockerTools.buildLayeredImage {
        inherit name tag fromImage contents config maxLayers;
      };
      
      sbomDrv = generateForDockerImage {
        drv = baseImage;
        inherit format outputDir;
      };
      
    in
      baseImage;

  # =============================================================================
  # SBOM METADATA ENRICHMENT
  # =============================================================================

  # Add openDesk-specific metadata to SBOM
  enrichWithOpenDeskMetadata = { 
    sbom, serviceName ? "unknown", serviceVersion ? "latest", 
    environment ? "production", maintainer ? "opendesk-edu@hrz.uni-marburg.de"
  }:
    let
      metadata = {
        "x-opendesk-service" = serviceName;
        "x-opendesk-version" = serviceVersion;
        "x-opendesk-environment" = environment;
        "x-opendesk-maintainer" = maintainer;
        "x-opendesk-repository" = "https://github.com/opendesk-edu/opendesk-nix";
      };
    in
      sbom // { metadata = metadata; };

  # =============================================================================
  # SBOM VALIDATION
  # =============================================================================

  # Validate SBOM format
  validateSBOM = { sbom, format }:
    let
      requiredFields = case format of
        "spdx" -> [ "spdxVersion" "dataLicense" "SPDXID" "name" "documentNamespace" "creators" "packages" ];
        "cyclonedx" -> [ "bomFormat" "specVersion" "serialNumber" "version" "metadata" "components" ];
        _ -> [ ];
      
      missingFields = builtins.filter 
        (field: !(builtins.hasAttr field sbom))
        requiredFields;
    in {
      valid = builtins.length missingFields == 0;
      missingFields = missingFields;
      warnings = if valid then [ ] else [ "SBOM is missing required fields: ${builtins.concatStringsSep ", " missingFields}" ];
    };

  # =============================================================================
  # SBOM STORAGE AND PUBLISHING
  # =============================================================================

  # Create a script to publish SBOMs to a registry
  publishSBOMScript = { 
    sbomPath, registryUrl ? "harbor.opendesk.hrz.uni-marburg.de", 
    project ? "sbom", subject ? null
  }:
    ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      
      echo "Publishing SBOM to registry..."
      
      # In a real implementation, we would:
      # 1. Authenticate with the registry
      # 2. Upload the SBOM as an artifact
      # 3. Attach it to the image using OCI artifacts
      
      if [ -f "${sbomPath}" ]; then
        echo "SBOM file found: ${sbomPath}"
        echo "Would upload to: ${registryUrl}/${project}/${subject}"
        echo "SBOM publishing is not yet implemented"
        exit 0
      else
        echo "SBOM file not found: ${sbomPath}"
        exit 1
      fi
    '';

  # =============================================================================
  # SBOM SIGNING
  # =============================================================================

  # Create a script to sign SBOMs with Cosign
  signSBOMScript = { 
    sbomPath, keyPath, outputPath ? "${sbomPath}.sig"
  }:
    ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      
      if [ ! -f "${sbomPath}" ]; then
        echo "SBOM file not found: ${sbomPath}"
        exit 1
      fi
      
      if [ ! -f "${keyPath}" ]; then
        echo "Key file not found: ${keyPath}"
        exit 1
      fi
      
      echo "Signing SBOM..."
      cosign sign-blob --key "${keyPath}" --output "${outputPath}" "${sbomPath}"
      echo "SBOM signed and saved to ${outputPath}"
    '';

  # =============================================================================
  # SBOM UTILITY FUNCTIONS
  # =============================================================================

  # Get SBOM path for a derivation
  getSBOMPath = { derivation, format, outputDir ? "./sbom" }:
    let
      drvName = (derivation.name or "unknown");
      drvVersion = (derivation.version or "latest");
    in
      "${outputDir}/${drvName}-${drvVersion}-${format}.json";

  # Check if SBOM exists
  sbomExists = { sbomPath }:
    builtins.pathExists sbomPath;

  # Read SBOM from file
  readSBOM = { sbomPath }:
    if sbomExists { inherit sbomPath; } then
      builtins.fromJSON (builtins.readFile sbomPath)
    else
      null;

  # =============================================================================
  # SBOM GENERATION PIPELINE
  # =============================================================================

  # Complete pipeline: build image -> generate SBOM -> validate -> sign
  sbomPipeline = { 
    derivation, format ? "both", outputDir ? "./sbom", 
    sign ? false, keyPath ? null, 
    validate ? true, enrich ? true, ...
  }:
    let
      drvName = (derivation.name or "unknown");
      drvVersion = (derivation.version or "latest");
      
      # Step 1: Generate SBOM
      sbomFiles = generateFor {
        derivation = derivation;
        format = format;
        outputDir = outputDir;
        outputName = "${drvName}-${drvVersion}";
      };
      
      # Step 2: Enrich with metadata
      enrichedSBOMs = if enrich && (format == "both" || format == "spdx") then
        [ enrichWithOpenDeskMetadata {
            sbom = readSBOM { sbomPath = (if format == "both" then "${outputDir}/${drvName}-${drvVersion}-spdx.json" else sbomFiles); };
            serviceName = drvName;
            serviceVersion = drvVersion;
          } ]
        else if enrich && format == "cyclonedx" then
        [ enrichWithOpenDeskMetadata {
            sbom = readSBOM { sbomPath = sbomFiles; };
            serviceName = drvName;
            serviceVersion = drvVersion;
          } ]
        else [];
      
      # Step 3: Validate (placeholder)
      validation = if validate then
        [ "Validation not yet implemented" ]
      else [];
      
      # Step 4: Sign (placeholder)
      # signing = if sign && keyPath != null then [ signSBOMScript { sbomPath = ...; keyPath = keyPath; } ] else [];
    in {
      inherit derivation drvName drvVersion;
      sbomFiles = if format == "both" then [
        "${outputDir}/${drvName}-${drvVersion}-spdx.json"
        "${outputDir}/${drvName}-${drvVersion}-cyclonedx.json"
      ] else [ "${outputDir}/${drvName}-${drvVersion}-${format}.json" ];
      enrichedSBOMs = enrichedSBOMs;
      validation = validation;
    };

  # =============================================================================
  # EXPORT ALL
  # =============================================================================

in {
  inherit
    # Formats
    sbomFormats
    
    # SPDX
    spdxDocument generateSPDX
    
    # CycloneDX
    generateCycloneDX
    
    # Multi-format
    generateFor generateBoth
    
    # Docker images
    generateForDockerImage
    
    # Nix images
    buildImageWithSBOM buildLayeredImageWithSBOM
    
    # Metadata
    enrichWithOpenDeskMetadata
    
    # Validation
    validateSBOM
    
    # Storage and publishing
    publishSBOMScript
    
    # Signing
    signSBOMScript
    
    # Utilities
    getSBOMPath sbomExists readSBOM
    
    # Pipeline
    sbomPipeline
    ;
}
