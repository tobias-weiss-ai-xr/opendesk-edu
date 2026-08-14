# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
#
# OpenLDAP — LDAP directory server
# Image: openldap:2.6.7
#
# Replaces: docker.io/osixia/openldap:1.5.0
# Built with: Nix dockerTools.buildLayeredImage
# Registry: 172.17.0.6:5001/openldap:2.6.7

{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; } }:

pkgs.dockerTools.buildLayeredImage {
  name = "openldap";
  tag = "2.6.7";

  contents = with pkgs; [
    openldap
    bash
    coreutils
    openssl
    cacert
  ];

  config = {
    Cmd = [
      "${pkgs.openldap}/sbin/slapd"
      "-h"
      "ldap:/// ldapi:///"
      "-g"
      "openldap"
      "-u"
      "openldap"
    ];

    Env = [
      "PATH=${pkgs.openldap}/sbin:${pkgs.openldap}/libexec:${pkgs.bash}/bin:${pkgs.coreutils}/bin"
    ];

    ExposedPorts = {
      "389/tcp" = { };
      "636/tcp" = { };
    };

    Volumes = {
      "/var/lib/openldap" = { };
      "/etc/openldap/slapd.d" = { };
      "/etc/openldap/certs" = { };
    };

    Labels = {
      "org.opencontainers.image.title" = "OpenLDAP";
      "org.opencontainers.image.description" = "LDAP directory server";
      "org.opencontainers.image.version" = "2.6.7";
      "org.opencontainers.image.source" = "https://www.openldap.org/";
      "org.opencontainers.image.licenses" = "OLDAP-2.8";
      "maintainer" = "SCS Cluster <tobias.weiss@uni-marburg.de>";
    };
  };

  maxLayers = 50;
}
