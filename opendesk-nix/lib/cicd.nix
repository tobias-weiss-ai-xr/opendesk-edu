# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ lib, pkgs, ... }:

let
  mkWorkflow = { serviceName, scriptBody }:
    pkgs.writeText "${serviceName}.yml" scriptBody;

  buildWorkflow = { serviceName, serviceVersion ? "latest" }:
    mkWorkflow {
      inherit serviceName;
      scriptBody = ''
name: Build-${serviceName}

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Build with Nix
        uses: cachix/install-nix-action@v26
        with:
          nix_path: nixpkgs=channel:nixos-unstable
      - name: Build image
        run: nix build .#packages.${serviceName}-image
      - name: Test
        run: nix flake check
'';
    };

  deployWorkflow = { serviceName, environment ? "production" }:
    mkWorkflow {
      inherit serviceName;
      scriptBody = ''
name: Deploy-${serviceName}

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Deploy
        run: echo "Deploying ${serviceName} to ${environment}"
'';
    };

  # GitLab CI configuration
  gitlabBuild = { serviceName }:
    pkgs.writeText ".gitlab-ci-${serviceName}.yml" ''
      image: nixos/nix:latest
      stages:
        - build
        - test
      build:
        stage: build
        script:
          - nix build .#packages.${serviceName}-image
      test:
        stage: test
        script:
          - nix flake check
    '';

in {
  inherit buildWorkflow deployWorkflow mkWorkflow gitlabBuild;
}
