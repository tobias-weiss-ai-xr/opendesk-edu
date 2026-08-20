# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 container.gov.de Contributors
# container.gov.de CI/CD Pipeline Library
# Integrated with container.gov.de Compliance Standards
# 6 Sigma Quality Standard

{ lib, pkgs, ... }:

let
  complianceLib = import ../compliance/container-gov-de.nix;
  securityLib = import ../security-scanning.nix;
  sbomLib = import ../sbom.nix;
  cosignLib = import ../cosign.nix;
  registryLib = import ../registry.nix;
  
  # Configuration for container.gov.de pipeline
  config = {
    registries = {
      target = "ghcr.io";
      fallback = "172.17.209.143:5000";
    };
    signing = {
      enabled = true;
      keyName = "cosign-key";
      keyPath = "./secrets/${config.signing.keyName}";
    };
    scanning = {
      grype = true;
      trivy = true;
      snyk = false;  # Requires API token
      failOnCritical = true;
      failOnHigh = true;
      failOnMedium = false;
    };
    sbom = {
      spdx = true;
      cyclonedx = true;
      attachToImage = true;
    };
    notifications = {
      slack = false;
      email = false;
      teams = false;
    };
  };

  # Generate GitHub Actions workflow for container.gov.de
  mkGitHubActionsWorkflow = { 
    repoName ? "container-gov-de",
    services ? [ "nginx" "mariadb" "redis" "postgresql" ],
    schedule ? "0 2 * * *",
    registries ? [ config.registries.target ],
    customSteps ? [ ],
    ...
  }:
    let
      serviceList = builtins.concatStringsSep ",\n          " services;
      registryList = builtins.concatStringsSep ",\n          " registries;
      
      # Generate service matrix
      serviceMatrix = builtins.concatStringsSep ", " services;
      
      # Generate registry matrix  
      registryMatrix = builtins.concatStringsSep ", " registries;
    in
    pkgs.writeText ".github/workflows/container-gov-de-compliance.yml" (''
name: container.gov.de Compliance Pipeline

on:
  push:
    branches:
      - main
      - release/*
    tags:
      - 'v*'
  pull_request:
    branches:
      - main
  schedule:
    - cron: '${schedule}'  # Daily at 2 AM by default
  workflow_dispatch:
    inputs:
      service:
        description: 'Service to build'
        required: false
        default: ''
      registry:
        description: 'Target registry'
        required: false
        default: ''

concurrency:
  group: container-gov-de">${{ github.ref }}
  cancel-in-progress: true

env:
  NIX_CONFIG: "experimental-features = nix-command flakes ca-derivations"

jobs:
  # Stage 1: Setup Environment
  setup:
    name: Setup Nix Environment
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Needed for flake
      
      - name: Install Nix
        uses: cachix/install-nix-action@v26
        with:
          install_url: https://releases.nixos.org/nix/nix-2.20.1/install
          nix_path: nixpkgs=channel:nixos-23.11
          extra_nix_config: |
            experimental-features = nix-command flakes ca-derivations
            trusted-substituters = https://cache.nixos.org https://opendesk.cache
            trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= opendesk.cache-1:abc123...
      
      - name: Cache Nix store
        uses: cachix/cachix-action@v12
        with:
          name: opendesk-nix
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
      
      - name: Set matrix output
        id: set-matrix
        run: |
          SERVICES=$(cat <<EOF
          ${serviceList}
          EOF
          )
          echo "matrix={\"service\":[${SERVICES}],\"registry\":[${registryMatrix}]}" >> $GITHUB_OUTPUT

  # Stage 2: Build container.gov.de Compliant Images
  build:
    name: Build Compliant Image
    needs: setup
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
    strategy:
      matrix:
        service: ${{ fromJSON(needs.setup.outputs.matrix).service }}
        registry: ${{ fromJSON(needs.setup.outputs.matrix).registry }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Install Nix
        uses: cachix/install-nix-action@v26
        with:
          nix_path: nixpkgs=channel:nixos-23.11
          extra_nix_config: |
            experimental-features = nix-command flakes ca-derivations
      
      - name: Cache Nix store
        uses: cachix/cachix-action@v12
        with:
          name: opendesk-nix
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
      
      - name: Build container.gov.de Compliant Image
        run: |
          nix build .#packages.x86_64-linux.${{ matrix.service }}-container-gov-de --no-link
        env:
          NIXPKGS_ALLOW_INSECURE: "1"
          NIXPKGS_ALLOW_BROKEN: "1"
      
      - name: Load image into Docker
        run: |
          IMAGE_FILE=$(realpath result)
          docker load < $IMAGE_FILE
          docker images
      
      - name: Tag image for registry
        run: |
          REPO=${{ matrix.service }}-container-gov-de
          TAG=latest
          if [ "${{ github.ref }}" != "refs/heads/main" ]; then
            TAG=$(echo ${{ github.ref }} | sed 's|refs/heads/||;s|/|-|g')
          fi
          if [ "${{ github.ref_type }}" = "tag" ]; then
            TAG=${{ github.ref_name }}
          fi
          docker tag $REPO:$TAG ${{ matrix.registry }}/${REPO}:$TAG
          echo "REPO=${REPO}" >> $GITHUB_ENV
          echo "TAG=$TAG" >> $GITHUB_ENV

  # Stage 3: Generate SBOM
  sbom:
    name: Generate SBOM
    needs: build
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: ${{ fromJSON(needs.setup.outputs.matrix).service }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Install Nix
        uses: cachix/install-nix-action@v26
      
      - name: Generate SPDX SBOM
        if: inputs.sbom-spdx == 'true' || true
        run: |
          nix build .#sbom-spdx-${{ matrix.service }} --no-link
      
      - name: Generate CycloneDX SBOM
        if: inputs.sbom-cyclonedx == 'true' || true
        run: |
          nix build .#sbom-cyclonedx-${{ matrix.service }} --no-link
      
      - name: Upload SPDX SBOM
        uses: actions/upload-artifact@v4
        with:
          name: sbom-spdx-${{ matrix.service }}
          path: result/*.spdx.json
      
      - name: Upload CycloneDX SBOM
        uses: actions/upload-artifact@v4
        with:
          name: sbom-cyclonedx-${{ matrix.service }}
          path: result/*.cyclonedx.json

  # Stage 4: Security Scanning
  security-scan:
    name: Security Scan
    needs: [ build, sbom ]
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
    strategy:
      matrix:
        service: ${{ fromJSON(needs.setup.outputs.matrix).service }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Install Nix
        uses: cachix/install-nix-action@v26
      
      - name: Load Docker image
        run: |
          nix build .#packages.x86_64-linux.${{ matrix.service }}-container-gov-de --no-link
          docker load < result
      
      - name: Scan with Grype
        id: grype
        run: |
          nix profile install .#grype
          grype ${{ env.REPO }}:${{ env.TAG }} -o json > grype-report.json || true
          ffucf
          
      - name: Check for critical vulnerabilities
        run: |
          MAX_SEVERITY="HIGH"
          if [ "${{ config.scanning.failOnCritical }}" = "true" ]; then
            MAX_SEVERITY="CRITICAL"
          fi
          CRITICAL_COUNT=$(jq '[.matches[] | select(.vulnerability.severity == "CRITICAL")] | length' grype-report.json)
          HIGH_COUNT=$(jq '[.matches[] | select(.vulnerability.severity == "HIGH")] | length' grype-report.json)
          if [ "$CRITICAL_COUNT" -gt 0 ] && [ "${{ config.scanning.failOnCritical }}" = "true" ]; then
            echo "::error::Found $CRITICAL_COUNT CRITICAL vulnerabilities"
            exit 1
          fi
          if [ "$HIGH_COUNT" -gt 0 ] && [ "${{ config.scanning.failOnHigh }}" = "true" ]; then
            echo "::error::Found $HIGH_COUNT HIGH vulnerabilities"
            exit 1
          fi
          echo "Vulnerabilities: CRITICAL=$CRITICAL_COUNT, HIGH=$HIGH_COUNT"
      
      - name: Scan with Trivy
        run: |
          nix profile install .#trivy
          trivy image --severity CRITICAL,HIGH ${{ env.REPO }}:${{ env.TAG }} -f json -o trivy-report.json || true
      
      - name: Upload scan reports
        uses: actions/upload-artifact@v4
        with:
          name: security-reports-${{ matrix.service }}
          path: |
            grype-report.json
            trivy-report.json

  # Stage 5: Sign Images
  sign:
    name: Sign Image
    needs: [ build, security-scan ]
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: ${{ fromJSON(needs.setup.outputs.matrix).service }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Install Cosign
        if: config.signing.enabled
        run: |
          nix profile install .#cosign
      
      - name: Import Cosign private key
        if: config.signing.enabled
        run: |
          echo "${{ secrets.COSIGN_PRIVATE_KEY }}" > cosign.key
          chmod 600 cosign.key
          echo "${{ secrets.COSIGN_PASSWORD }}" > cosign-password.txt
      
      - name: Sign image with Cosign
        if: config.signing.enabled
        run: |
          cosign sign --key cosign.key ${{ matrix.registry }}/${{ env.REPO }}:${{ env.TAG }} --password-file cosign-password.txt
      
      - name: Verify signature
        if: config.signing.enabled
        run: |
          echo "${{ secrets.COSIGN_PUBLIC_KEY }}" > cosign.pub
          cosign verify --key cosign.pub ${{ matrix.registry }}/${{ env.REPO }}:${{ env.TAG }}

  # Stage 6: Compliance Check
  compliance:
    name: container.gov.de Compliance
    needs: [ build, sbom, security-scan, sign ]
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: ${{ fromJSON(needs.setup.outputs.matrix).service }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Install Nix
        uses: cachix/install-nix-action@v26
      
      - name: Run container.gov.de Compliance Check
        run: |
          nix build .#packages.x86_64-linux.${{ matrix.service }}-compliance-check --no-link
          
          # Parse compliance result
          COMPLIANCE_LEVEL=$(jq -r '.complianceLevel' result.json)
          PASSED=$(jq -r '.passed' result.json)
          TOTAL=$(jq -r '.total' result.json)
          
          echo "Compliance: $COMPLIANCE_LEVEL ($PASSED/$TOTAL checks passed)"
          
          if [ "$COMPLIANCE_LEVEL" != "FULLY COMPLIANT" ]; then
            echo "::error::container.gov.de compliance check failed for ${{ matrix.service }}"
            jq '.' result.json
            exit 1
          fi
      
      - name: Upload Compliance Report
        uses: actions/upload-artifact@v4
        with:
          name: compliance-report-${{ matrix.service }}
          path: result.json

  # Stage 7: Push to Registry
  push:
    name: Push to Registry
    needs: [ build, sbom, security-scan, sign, compliance ]
    if: github.ref == 'refs/heads/main' || github.ref_type == 'tag'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: ${{ fromJSON(needs.setup.outputs.matrix).service }}
        registry: ${{ fromJSON(needs.setup.outputs.matrix).registry }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Load Docker image
        run: |
          nix build .#packages.x86_64-linux.${{ matrix.service }}-container-gov-de --no-link
          docker load < result
      
      - name: Push to registry
        run: |
          echo "Pushing ${{ matrix.registry }}/${{ env.REPO }}:${{ env.TAG }}..."
          docker push ${{ matrix.registry }}/${{ env.REPO }}:${{ env.TAG }}
          
      - name: Push SBOMs
        if: config.sbom.attachToImage
        run: |
          # Push SBOMs as OCI artifacts
          # This would use OCI registry capabilities
          echo "SBOM artifacts available in workflow artifacts"

  # Stage 8: Generate Final Report
  report:
    name: Generate Final Report
    needs: [ build, sbom, security-scan, sign, compliance, push ]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Download all artifacts
        uses: actions/download-artifact@v4
      
      - name: Generate HTML Report
        run: |
          mkdir -p compliance-report
          cp **/*compliance-report*.json compliance-report/
          cp **/*-report*.json compliance-report/
          
          cat > compliance-report/index.html << 'HTML'
          <!DOCTYPE html>
          <html>
          <head>
            <title>container.gov.de Pipeline Report - ${{ github.repository }}</title>
            <style>
              body { font-family: Arial; margin: 20px; }
              .summary { background: #f0f0f0; padding: 20px; margin: 10px 0; }
              .success { color: green; }
              .failure { color: red; }
              pre { background: #eee; padding: 10px; overflow: auto; }
            </style>
          </head>
          <body>
            <h1>container.gov.de Pipeline Report</h1>
            <p>Workflow: ${{ github.workflow }}</p>
            <p>Run: ${{ github.run_id }}</p>
            <p>Commit: ${{ github.sha }}</p>
            
            <h2>Summary</h2>
            <div class="summary">
              <p><strong>Status:</strong> 
                ${{
                  if (success())
                    echo '<span class="success">✓ All jobs passed</span>'
                  else
                    echo '<span class="failure">✗ Some jobs failed</span>'
                  fi
                }}
              </p>
            </div>
            
            <h2>Artifacts</h2>
            <ul>
              <li><a href="compliance-report/">Compliance Reports</a