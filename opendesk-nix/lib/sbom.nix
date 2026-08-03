# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ lib, pkgs, ... }:

let
  # SPDX License identifiers
  spdxLicenses = [
    "Apache-2.0" "GPL-2.0-only" "GPL-2.0-or-later" "GPL-3.0-only" "GPL-3.0-or-later"
    "MIT" "BSD-2-Clause" "BSD-3-Clause" "AGPL-3.0-only" "AGPL-3.0-or-later"
    "LGPL-2.1-only" "LGPL-2.1-or-later" "LGPL-3.0-only" "LGPL-3.0-or-later"
  ];

  # Generate SPDX 2.3 document
  mkSPDX = { name, version, downloadLocation, licenseID, copyrightText ? "NOASSERTION" }:
    pkgs.writeText "${name}-spdx.json" (builtins.toJSON {
      spdxVersion = "SPDX-2.3";
      dataLicense = "CC0-1.0";
      SPDXID = "SPDXRef-DOCUMENT";
      name = name;
      documentNamespace = "https://opendesk.hrz.uni-marburg.de/spdx/${name}/${version}";
      creationInfo = {
        created = "2026-01-01T00:00:00Z";
        creators = [ "Tool: opendesk-nix" "Organization: openDesk Edu" ];
        licenseListVersion = "3.22";
      };
      documentDescribes = [ "SPDXRef-Package" ];
      packages = [ {
        SPDXID = "SPDXRef-Package";
        name = name;
        versionInfo = version;
        downloadLocation = downloadLocation;
        filesAnalyzed = false;
        licenseConcluded = licenseID;
        licenseDeclared = licenseID;
        copyrightText = copyrightText;
      } ];
    });

  # Generate CycloneDX 1.4 document
  mkCycloneDX = { name, version, description ? "", purl ? null, licenseID }:
    pkgs.writeText "${name}-cyclonedx.json" (builtins.toJSON {
      bomFormat = "CycloneDX";
      specVersion = "1.4";
      version = 1;
      metadata = {
        timestamp = "2026-01-01T00:00:00Z";
        tools = [ { vendor = "openDesk Edu"; name = "opendesk-nix"; version = "1.0"; } ];
      };
      components = [ {
        type = "library";
        name = name;
        version = version;
        description = description;
        purl = purl;
        licenses = [ { license = { id = licenseID; }; } ];
      } ];
    });

  # SBOM format types
  sbomFormats = [ "spdx" "cyclonedx" "both" ];

  # Scan a Nix package
  scanNixPackage = { pkg, licenseID ? "NOASSERTION" }:
    let
      name = pkg.pname or "unknown";
      version = pkg.version or "latest";
      downloadLocation = pkg.meta.homepage or "NOASSERTION";
    in {
      spdx = mkSPDX { inherit name version downloadLocation licenseID; };
      cyclonedx = mkCycloneDX { 
        inherit name version;
        description = pkg.meta.description or "";
        purl = "pkg:nixpkgs/${name}@${version}";
        inherit licenseID;
      };
    };

  # Generate SBOM for all packages
  scanAllPackages = { pkgsToScan, licenseMap ? { } }:
    map (pkg:
      let licenseID = licenseMap.${pkg.pname} or "NOASSERTION";
      in scanNixPackage { pkg = pkg; licenseID = licenseID; }
    ) pkgsToScan;

in {
  inherit spdxLicenses mkSPDX mkCycloneDX sbomFormats scanNixPackage scanAllPackages;
}
