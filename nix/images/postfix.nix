# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
#
# Postfix — Mail Transfer Agent (MTA)
# Image: postfix:3.8.4
#
# Replaces: docker.io/instrumentisto/postfix:latest
# Built with: Nix dockerTools.buildLayeredImage
# Registry: 172.17.0.6:5001/postfix:3.8.4

{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; } }:

pkgs.dockerTools.buildLayeredImage {
  name = "postfix";
  tag = "3.8.4";

  contents = with pkgs; [
    postfix
    bash
    coreutils
    openssl
    cacert
  ];

  config = {
    Cmd = [
      "${pkgs.postfix}/sbin/postfix"
      "start-fg"
    ];

    Env = [
      "PATH=${pkgs.postfix}/sbin:${pkgs.postfix}/libexec:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.openssl}/bin"
    ];

    ExposedPorts = {
      "25/tcp" = { };
      "587/tcp" = { };
      "465/tcp" = { };
    };

    Volumes = {
      "/etc/postfix" = { };
      "/var/spool/postfix" = { };
      "/var/lib/postfix" = { };
    };

    Labels = {
      "org.opencontainers.image.title" = "Postfix";
      "org.opencontainers.image.description" = "Mail Transfer Agent (MTA)";
      "org.opencontainers.image.version" = "3.8.4";
      "org.opencontainers.image.source" = "http://www.postfix.org/";
      "org.opencontainers.image.licenses" = "IPL-1.0";
      "maintainer" = "SCS Cluster <tobias.weiss@uni-marburg.de>";
    };
  };

  maxLayers = 50;
}
