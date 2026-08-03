// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ 
  lib,
  security ? import ../../lib/security.nix { },
  registry ? import ../../lib/registry.nix { },
  types ? import ../../lib/types.nix { },
  sbom ? import ../../lib/sbom.nix { },
  pkgs ? import <nixpkgs> { }
}:

let
 name = "limesurvey"; image = "ghcr.io/opendesk-edu/limesurvey"; tag = "latest";
  port = 8080;

  # Security configuration
  containerSecurity = security.mkContainerSecurityContext { profile = "web"; };
  podSecurity = security.mkPodSecurityContext { user = 1000; group = 1000; fsGroup = 1000; };

  # Probe configuration
  livenessProbe = lib.mkProbe {
    type = "tcp";
    port = 8080;
    initialDelaySeconds = 30;
    periodSeconds = 10;
    timeoutSeconds = 5;
  };
  readinessProbe = lib.mkProbe {
    type = "tcp";
    port = 8080;
    initialDelaySeconds = 5;
    periodSeconds = 5;
    timeoutSeconds = 3;
  };

  # Resource configuration
  resources = {
    requests = { cpu = "100m"; memory = "256Mi"; };
    limits = { cpu = "500m"; memory = "512Mi"; };
  };


in

[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
  (lib.ingressWithCert { inherit name; host = "limesurvey.opendesk.hrz.uni-marburg.de"; inherit port; })
]