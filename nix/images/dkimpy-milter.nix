# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
#
# DKIMpy Milter — DKIM signing milter for Postfix
# Image: dkimpy-milter:1.1.8
#
# Replaces: docker.io/dkimpy-milter:v3
# Built with: Nix dockerTools.buildLayeredImage
# Registry: 172.17.0.6:5001/dkimpy-milter:1.1.8

{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; } }:

pkgs.dockerTools.buildLayeredImage {
  name = "dkimpy-milter";
  tag = "1.1.8";
  created = "2026-08-13T00:00:00Z";

  contents = with pkgs; [
    bash
    coreutils
    python3
    python3Packages.dkimpy
    python3Packages.pymilter
    openssl
    cacert
    dockerTools.fakeNss
  ];

  config = {
    User = "dkim";

    Cmd = [
      "${pkgs.python3}/bin/python3"
      "-m"
      "dkimpy.milter"
      "/etc/dkimpy/dkimpy-milter.conf"
    ];

    Env = [
      "PATH=${pkgs.coreutils}/bin:${pkgs.bash}/bin:${pkgs.python3}/bin:${pkgs.openssl}/bin"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "PYTHONPATH=${pkgs.python3Packages.dkimpy}/${pkgs.python3.sitePackages}"
    ];

    ExposedPorts = {
      "8892/tcp" = { };
    };

    Volumes = {
      "/etc/dkimpy/keys" = { };
      "/etc/dkimpy" = { };
    };

    WorkingDir = "/";

    Labels = {
      "org.opencontainers.image.title" = "DKIMpy Milter";
      "org.opencontainers.image.description" = "DKIM signing milter for Postfix";
      "org.opencontainers.image.version" = "1.1.8";
      "org.opencontainers.image.source" = "https://github.com/bysquare/dkimpy";
      "org.opencontainers.image.licenses" = "BSD-3-Clause";
      "maintainer" = "SCS Cluster <tobias.weiss@uni-marburg.de>";
    };

    StopSignal = "SIGTERM";
    StopTimeout = 10;
  };

  maxLayers = 100;
}
