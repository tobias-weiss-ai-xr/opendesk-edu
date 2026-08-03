# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ lib, pkgs, docking ? null, ... }:

let
  # Security scanning tools
  scanners = {
    grype = {
      enable = true;
      severity = [ "critical" "high" "medium" "low" "negligible" ];
      ignore = [ ]; 
    };
    trivy = {
      enable = true;
      exitCode = 1;
      ignoreUnfixed = true;
      vulnType = [ "os" "library" ];
      severity = [ "CRITICAL" "HIGH" "MEDIUM" "LOW" "UNKNOWN" ];
    };
    snyk = {
      enable = false;  # Requires API token
      severityThreshold = "high";
    };
  };

  # Run Grype scan on a Docker image or directory
  scanWithGrype = { target, output ? "grype-report.json", format ? "json" }:
    pkgs.runCommand "grype-${builtins.hashString "sha256" target}" {
      inherit (pkgs) grype jq;
    } ''
      mkdir -p $(dirname ${output})
      grype ${target} -o ${format} > ${output}
    '';

  # Run Trivy scan on a Docker image or filesystem
  scanWithTrivy = { target, output ? "trivy-report.json", format ? "json", severity ? "HIGH" }:
    pkgs.runCommand "trivy-${builtins.hashString "sha256" target}" {
      inherit (pkgs) trivy;
    } ''
      mkdir -p $(dirname ${output})
      trivy fs --security-checks vuln,config ${target} -f ${format} -o ${output}
      trivy image --severity ${severity} ${target} -f ${format} >> ${output} 2>/dev/null || true
    '';

  # Run Snyk scan (requires SNYK_TOKEN)
  scanWithSnyk = { target }:
    pkgs.runCommand "snyk-${builtins.hashString "sha256" target}" {
      inherit (pkgs) snyk;
    } ''
      snyk test --severity-threshold=high ${target} || true
    '';

  # Scan a container image
  scanImage = { image, scanners ? [ "grype" "trivy" ], outputDir ? "./scans" }:
    let
      results = map (scanner: 
        if scanner == "grype" then scanWithGrype { target = image; output = "${outputDir}/${builtins.baseNameOf image}-grype.json"; }
        else if scanner == "trivy" then scanWithTrivy { target = image; output = "${outputDir}/${builtins.baseNameOf image}-trivy.json"; }
        else if scanner == "snyk" then scanWithSnyk { target = image; }
        else null
      ) scanners;
    in results;

  # Scan a filesystem directory
  scanDirectory = { path, scanners ? [ "grype" "trivy" ], outputDir ? "./scans" }:
    let
      results = map (scanner: 
        if scanner == "grype" then scanWithGrype { target = path; output = "${outputDir}/grype-report.json"; }
        else if scanner == "trivy" then scanWithTrivy { target = path; output = "${outputDir}/trivy-report.json"; }
        else null
      ) scanners;
    in results;

  # Scan all images
  scanAllImages = { images, config ? scanners }:
    map (image: scanImage { image = image; scanners = config; }) images;

  # Generate Sarah report (aggregate scan results)
  mkSarahReport = { scanResults, output ? "sarah-report.json" }:
    pkgs.runCommand "sarah-${builtins.hashString "sha256" (builtins.toJSON scanResults)}" {
      inherit (pkgs) jq;
    } ''
      echo '${builtins.toJSON scanResults}' | jq '.' > ${output}
    '';

  # CIS Kubernetes Benchmark scanning
  scanCISKubernetes = { config ? null }:
    pkgs.runCommand "cis-k8s-scan" {
      inherit (pkgs) kube-bench;
    } ''
      mkdir -p ./cis-reports
      kube-bench --targets node,master --json --outputfile ./cis-reports/results.json run
    '';

  # Run multiple scanners on a target
  scanWithAll = { target, image ? true, directory ? false, outputDir ? "./security-scans" }:
    let
      scanResults = [
        (scanWithGrype { target = target; output = "${outputDir}/grype-results.json"; })
        (scanWithTrivy { target = target; output = "${outputDir}/trivy-results.json"; })
      ] ++ lib.optional (image) (
        (scanWithSnyk { target = target; })
      );
      report = mkSarahReport { scanResults = scanResults; output = "${outputDir}/aggregate-report.json"; };
    in scanResults ++ [ report ];

in {
  inherit scanners scanWithGrype scanWithTrivy scanWithSnyk scanImage 
    scanDirectory scanAllImages mkSarahReport scanCISKubernetes scanWithAll;
  
  # Configuration options
  config = {
    grype = scanners.grype;
    trivy = scanners.trivy;
    snyk = scanners.snyk;
    minSeverity = "HIGH";
    ignoreCves = [ ];
    reportFormats = [ "json" "table" "sarif" ];
  };
}
