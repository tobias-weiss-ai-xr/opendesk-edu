#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Dockerfile to NixOS Configuration Converter
Converts Dockerfile instructions to NixOS configuration.nix

Usage:
    python3 migrate-service.py <dockerfile-path> [service-name] [version]
"""

import re
import sys
import os
import subprocess
from typing import Dict, List, Optional, Tuple


class DockerfileParser:
    """Parses Dockerfile and extracts relevant information."""
    
    def __init__(self, dockerfile_path: str):
        self.dockerfile_path = dockerfile_path
        self.dockerfile = self._read_dockerfile()
        
    def _read_dockerfile(self) -> str:
        """Read and return the Dockerfile content."""
        with open(self.dockerfile_path, 'r') as f:
            return f.read()
    
    def parse(self) -> Dict:
        """Parse the Dockerfile and return structured data."""
        return {
            'base_image': self._parse_base_image(),
            'maintainer': self._parse_maintainer(),
            'labels': self._parse_labels(),
            'env': self._parse_env(),
            'run': self._parse_run(),
            'copy': self._parse_copy(),
            'add': self._parse_add(),
            'expose': self._parse_expose(),
            'volume': self._parse_volume(),
            'workdir': self._parse_workdir(),
            'user': self._parse_user(),
            'cmd': self._parse_cmd(),
            'entrypoint': self._parse_entrypoint(),
            'healthcheck': self._parse_healthcheck(),
            'arg': self._parse_arg(),
            'stopsignal': self._parse_stopsignal(),
        }
    
    def _parse_base_image(self) -> str:
        """Extract the base image from FROM instruction."""
        match = re.search(r'^FROM\s+([^\s]+)', self.dockerfile, re.MULTILINE)
        return match.group(1) if match else 'scratch'
    
    def _parse_maintainer(self) -> Optional[str]:
        """Extract MAINTAINER instruction (deprecated but still used)."""
        match = re.search(r'^MAINTAINER\s+(.+)$', self.dockerfile, re.MULTILINE)
        return match.group(1).strip() if match else None
    
    def _parse_labels(self) -> Dict[str, str]:
        """Extract LABEL instructions."""
        labels = {}
        for match in re.finditer(r'^LABEL\s+([^=]+)=([^\n]+)', self.dockerfile, re.MULTILINE):
            key = match.group(1).strip()
            value = match.group(2).strip().strip('"\'')
            labels[key] = value
        return labels
    
    def _parse_env(self) -> List[Dict[str, str]]:
        """Extract ENV instructions."""
        envs = []
        for match in re.finditer(r'^ENV\s+([^\n]+)', self.dockerfile, re.MULTILINE):
            parts = match.group(1).strip().split()
            for part in parts:
                if '=' in part:
                    key, value = part.split('=', 1)
                    envs.append({'key': key.strip(), 'value': value.strip().strip('"\'')})
        return envs
    
    def _parse_run(self) -> List[str]:
        """Extract RUN instructions."""
        runs = []
        for match in re.finditer(r'^RUN\s+(.+)$', self.dockerfile, re.MULTILINE):
            # Remove line continuation characters and join lines
            run_cmd = match.group(1).replace('\\\n', ' ').strip()
            runs.append(run_cmd)
        return runs
    
    def _parse_copy(self) -> List[Dict[str, str]]:
        """Extract COPY instructions."""
        copies = []
        for match in re.finditer(r'^COPY\s+([^\s]+)\s+([^\n]+)', self.dockerfile, re.MULTILINE):
            copies.append({
                'src': match.group(1).strip(),
                'dest': match.group(2).strip()
            })
        return copies
    
    def _parse_add(self) -> List[Dict[str, str]]:
        """Extract ADD instructions."""
        adds = []
        for match in re.finditer(r'^ADD\s+([^\s]+)\s+([^\n]+)', self.dockerfile, re.MULTILINE):
            adds.append({
                'src': match.group(1).strip(),
                'dest': match.group(2).strip()
            })
        return adds
    
    def _parse_expose(self) -> List[str]:
        """Extract EXPOSE instructions."""
        exposes = []
        for match in re.finditer(r'^EXPOSE\s+([^\n]+)', self.dockerfile, re.MULTILINE):
            ports = match.group(1).strip().split()
            exposes.extend(ports)
        return exposes
    
    def _parse_volume(self) -> List[str]:
        """Extract VOLUME instructions."""
        volumes = []
        for match in re.finditer(r'^VOLUME\s+([^\n]+)', self.dockerfile, re.MULTILINE):
            vol_paths = match.group(1).strip().strip('[]').split(',')
            volumes.extend([v.strip().strip('"\'') for v in vol_paths])
        return volumes
    
    def _parse_workdir(self) -> Optional[str]:
        """Extract WORKDIR instruction."""
        match = re.search(r'^WORKDIR\s+([^\n]+)', self.dockerfile, re.MULTILINE)
        return match.group(1).strip() if match else None
    
    def _parse_user(self) -> Optional[str]:
        """Extract USER instruction."""
        match = re.search(r'^USER\s+([^\n]+)', self.dockerfile, re.MULTILINE)
        return match.group(1).strip() if match else None
    
    def _parse_cmd(self) -> List[str]:
        """Extract CMD instruction."""
        match = re.search(r'^CMD\s+(\[.+\]|\S+)', self.dockerfile, re.MULTILINE)
        if match:
            cmd = match.group(1).strip()
            # Handle both exec form and shell form
            if cmd.startswith('['):
                # Exec form: ["executable", "param1", "param2"]
                parts = cmd.strip('[]').split(',')
                return [p.strip().strip('"\'') for p in parts]
            else:
                # Shell form: command param1 param2
                return [cmd]
        return []
    
    def _parse_entrypoint(self) -> List[str]:
        """Extract ENTRYPOINT instruction."""
        match = re.search(r'^ENTRYPOINT\s+(\[.+\]|\S+)', self.dockerfile, re.MULTILINE)
        if match:
            entrypoint = match.group(1).strip()
            if entrypoint.startswith('['):
                parts = entrypoint.strip('[]').split(',')
                return [p.strip().strip('"\'') for p in parts]
            else:
                return [entrypoint]
        return []
    
    def _parse_healthcheck(self) -> Optional[Dict]:
        """Extract HEALTHCHECK instruction."""
        pattern = r'HEALTHCHECK\s+--interval=([\dms]+)\s+--timeout=([\dms]+)\s+--retries=(\d+)\s+--start-period=([\dms]+)\s+CMD\s+([^\n]+)'
        match = re.search(pattern, self.dockerfile)
        if match:
            return {
                'interval': self._parse_duration(match.group(1)),
                'timeout': self._parse_duration(match.group(2)),
                'retries': int(match.group(3)),
                'start_period': self._parse_duration(match.group(4)),
                'test': match.group(5).strip()
            }
        return None
    
    def _parse_arg(self) -> Dict[str, str]:
        """Extract ARG instructions."""
        args = {}
        for match in re.finditer(r'^ARG\s+([^=]+)=?([^\n]*)', self.dockerfile, re.MULTILINE):
            key = match.group(1).strip()
            value = match.group(2).strip().strip('"\'') if match.group(2) else ''
            args[key] = value
        return args
    
    def _parse_stopsignal(self) -> Optional[str]:
        """Extract STOPSIGNAL instruction."""
        match = re.search(r'^STOPSIGNAL\s+([^\n]+)', self.dockerfile, re.MULTILINE)
        return match.group(1).strip() if match else None
    
    def _parse_duration(self, duration: str) -> int:
        """Parse duration string to nanoseconds."""
        if 'ms' in duration:
            num = int(duration.replace('ms', ''))
            return num * 1000000  # Convert ms to ns
        elif 's' in duration:
            num = int(duration.replace('s', ''))
            return num * 1000000000  # Convert s to ns
        elif 'm' in duration:
            num = int(duration.replace('m', ''))
            return num * 60 * 1000000000  # Convert m to ns
        return int(duration) * 1000000000  # Assume seconds


class NixOSGenerator:
    """Generates NixOS configuration from Dockerfile data."""
    
    def __init__(self, dockerfile_data: Dict, service_name: str = None, version: str = None):
        self.data = dockerfile_data
        self.service_name = service_name or self._infer_service_name()
        self.version = version or self._infer_version()
        self.packages = self._extract_packages()
        self.user = dockerfile_data.get('user', self.service_name)
        self.workdir = dockerfile_data.get('workdir', f'/var/lib/{self.service_name}')
        
    def _infer_service_name(self) -> str:
        """Infer service name from base image or labels."""
        base = self.data.get('base_image', '')
        if ':' in base:
            return base.split(':')[0].replace('/', '-').replace('.', '-')
        return 'service'
    
    def _infer_version(self) -> str:
        """Infer version from base image."""
        base = self.data.get('base_image', '')
        if ':' in base:
            tag = base.split(':')[1]
            if tag != 'latest' and tag.isalnum():
                return tag
        return 'latest'
    
    def _extract_packages(self) -> List[str]:
        """Extract package names from RUN apt-get/yum/apk install commands."""
        packages = []
        for run_cmd in self.data.get('run', []):
            # Match apt-get install
            apt_match = re.search(r'apt-get\s+install\s+([^\\&]+)', run_cmd)
            if apt_match:
                parts = apt_match.group(1).split()
                packages.extend([p for p in parts if p and not p.startswith('-') and not p.startswith('\\')])
            
            # Match apk add
            apk_match = re.search(r'apk\s+add\s+([^\\&]+)', run_cmd)
            if apk_match:
                parts = apk_match.group(1).split()
                packages.extend([p for p in parts if p and not p.startswith('-') and not p.startswith('\\')])
            
            # Match yum install
            yum_match = re.search(r'yum\s+install\s+([^\\&]+)', run_cmd)
            if yum_match:
                parts = yum_match.group(1).split()
                packages.extend([p for p in parts if p and not p.startswith('-') and not p.startswith('\\')])
        
        return sorted(set(packages))
    
    def generate_configuration_nix(self) -> str:
        """Generate NixOS configuration.nix file."""
        service_upper = self.service_name.upper()
        
        config = f'''# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
{self.service_name.capitalize()} NixOS Configuration for openDesk
Version: {self.version}
Generated from Dockerfile
OpenSpec: Full compliance (FR-IMAGE-001 through FR-IMAGE-009)
"""

{{ config, pkgs, lib, ... }}:

{{
  # Import openDesk overlays
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];

'''
        
        # Add service configuration
        config += f'''  # {self.service_name.capitalize()} service
  services.{self.service_name} = {{
    enable = true;'''
        
        # Check if it's a known service
        if self.service_name in ['mariadb', 'mysql', 'postgresql', 'redis', 'nginx', 'keycloak']:
            config += f'''
    package = pkgs.opendeskPackages.{self.service_name};'''
        else:
            # Try to find in nixpkgs
            config += f'''
    # Package not found in opendeskPackages, using default
    # package = pkgs.{self.service_name};'''
        
        # Add port if exposed
        if self.data.get('expose'):
            port = self.data['expose'][0]
            config += f'''
    port = {port};'''
        
        config += '''\n  };

'''
        
        # Add user configuration
        config += f'''  # System user for {self.service_name}
  users.users.{self.user} = {{
    isSystemUser = true;
    uid = 1000;'''
        
        # Add group if user is specified
        if self.user != 'root':
            config += f'''
    group = "{self.user}"'''
        
        config += f''';
    home = "{self.workdir}";
    shell = pkgs.bash;
    description = "{self.service_name.capitalize()} Service User";
  }};

  users.groups.{self.user} = {{
    gid = 1000;
  }};

'''
        
        # Add setup script for directories
        config += f'''  # Setup directories
  system.activationScripts.setup{self.service_name.capitalize()} = lib.mkAfter ''
    mkdir -p {self.workdir} /var/log/{self.service_name} /etc/{self.service_name}
    chown -R {self.user}:{self.user} {self.workdir} /var/log/{self.service_name} /etc/{self.service_name}
    chmod -R 750 {self.workdir}
    chmod -R 755 /var/log/{self.service_name}
    chmod -R 755 /etc/{self.service_name}
  '';

'''
        
        # Add environment variables as NixOS settings
        if self.data.get('env'):
            config += '  # Environment variables
'
            for env in self.data['env']:
                config += f'  # {env["key"]} = {env["value"]}
'
        
        # Add security hardening
        config += '''  # Security hardening
  security.polkit.enable = false;
  services.openssh.enable = false;

  # System state version for reproducibility
  system.stateVersion = "23.11";
}
'''
        
        return config
    
    def generate_default_nix(self) -> str:
        """Generate NixOS default.nix file."""
        ports = self.data.get('expose', ['8080'])
        volumes = self.data.get('volume', [f'/var/lib/{self.service_name}'])
        
        # Parse health check
        health_interval = 30000000000  # 30s default
        health_timeout = 10000000000   # 10s default
        health_retries = 3
        health_start = 10000000000    # 10s default
        health_test = "exit 0"
        
        if self.data.get('healthcheck'):
            hc = self.data['healthcheck']
            health_interval = hc.get('interval', health_interval)
            health_timeout = hc.get('timeout', health_timeout)
            health_retries = hc.get('retries', health_retries)
            health_start = hc.get('start_period', health_start)
            health_test = hc.get('test', health_test)
        
        # Parse CMD
        cmd = self.data.get('cmd', [f'{self.service_name}'])
        if not cmd:
            cmd = [f'{self.service_name}']
        
        # Parse ENTRYPOINT
        entrypoint = self.data.get('entrypoint', [])
        
        # Parse STOPSIGNAL
        stop_signal = self.data.get('stopsignal', 'SIGTERM')
        stop_timeout = 30
        
        config = f'''# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
{self.service_name.capitalize()} NixOS Container Image
Version: {self.version}
Generated from Dockerfile
OpenSpec: FR-BUILD-001 through FR-BUILD-007
"""

{{ 
  pkgs ? import <nixpkgs> {{ system = "x86_64-linux"; }},
  docks ? import (builtins.fetchGit {{
    url = "https://github.com/dockernix/docks.nix";
    ref = "refs/tags/0.5.0";
  }}) {{ inherit pkgs; }},
  ...
}}:

let
  lib = pkgs.lib;
  opendeskOverlays = import ../../../../../overlays/opendesk.nix;
  nixpkgsWithOverlays = pkgs // {{
    overlays = [ opendeskOverlays ];
  }};
'''
        
        # Try to get the package
        if self.service_name in ['mariadb', 'mysql', 'postgresql', 'redis', 'nginx', 'keycloak']:
            config += f'  servicePkg = nixpkgsWithOverlays.opendeskPackages.{self.service_name};\n'
        else:
            config += f'  servicePkg = pkgs.{self.service_name} or pkgs.unknownService;\n'
        
        config += '''in

docks.mkImage {
  name = "''' + f'{self.service_name}-opendesk' + ''' ";
  tag = "''' + f'{self.version}-nixos' + ''' ";

  # NixOS configuration
  config = import ./configuration.nix {{ inherit pkgs lib; }};

  # Container configuration
  containerConfig = {
'''
        
        # Add exposed ports
        config += '    ExposedPorts = {\n'
        for port in ports:
            config += f'      "{port}/tcp" = {{}};\n'
        config += '    };\n\n'
        
        # Add volumes
        config += '    Volumes = {\n'
        for vol in volumes:
            config += f'      "{vol}" = {{}};\n'
        config += '    };\n\n'
        
        # Add environment variables
        config += '    Env = [\n'
        config += '      "OPENDESK_ENV=production"\n'
        config += '      "TZ=Europe/Berlin"\n'
        config += '      "LC_ALL=C.UTF-8"\n'
        config += '      "LANG=C.UTF-8"\n'
        
        # Add Dockerfile ENV variables
        for env in self.data.get('env', []):
            config += f'      "{env["key"]}={env["value"]}"\n'
        
        config += '    ];\n\n'
        
        # Add health check
        config += f'    HealthCheck = {{\n'
        config += f'      Test = [ "CMD-SHELL" "{health_test}" ];\n'
        config += f'      Interval = {health_interval};  # {health_interval/1000000000}s\n'
        config += f'      Timeout = {health_timeout};   # {health_timeout/1000000000}s\n'
        config += f'      Retries = {health_retries};\n'
        config += f'      StartPeriod = {health_start}; # {health_start/1000000000}s\n'
        config += '    };\n\n'
        
        # Add user and working directory
        config += f'    User = "{self.user}";\n'
        config += f'    WorkingDir = "{self.workdir}";\n\n'
        
        # Add CMD
        if entrypoint:
            config += f'    Entrypoint = [ {" ".join(f""{e}"" for e in entrypoint)} ];\n'
            if cmd and cmd != entrypoint:
                config += f'    Cmd = [ {" ".join(f""{c}"" for c in cmd)} ];\n'
        else:
            config += f'    Cmd = [ {" ".join(f""{c}"" for c in cmd)} ];\n'
        
        # Add stop signal
        config += f'    StopSignal = "{stop_signal}";\n'
        config += f'    StopTimeout = {stop_timeout};\n'
        
        config += '  };\n\n'
        
        # Add extra packages
        config += '  extraPackages = p: with p; [\n'
        config += '    openssl\n'
        config += '    curl\n'
        config += '    procps\n'
        config += '    coreutils\n'
        config += '  ];\n\n'
        
        # Add OCI labels
        config += '  ociLabels = {\n'
        config += f'    "org.opencontainers.image.title" = "{self.service_name}-opendesk";\n'
        config += f'    "org.opencontainers.image.version" = "{self.version}-nixos";\n'
        config += '    "org.opencontainers.image.authors" = "openDesk Edu Team";\n'
        config += '    "org.opencontainers.image.url" = "https://opendesk.hrz.uni-marburg.de";\n'
        config += '    "org.opencontainers.image.licenses" = "Apache-2.0";\n'
        config += '    "com.opendesk.service" = "' + f'{self.service_name}' + '";\n'
        config += '    "com.opendesk.nixos" = "true";\n'
        config += '  };\n'
        
        config += '}\n'
        
        return config
    
    def generate_overlay_entry(self) -> str:
        """Generate entry for overlays/opendesk.nix."""
        return f'''    {self.service_name} = super.{self.service_name}.overrideAttrs (old: rec {{
      version = "{self.version}";
      pname = "{self.service_name}-opendesk";
      # TODO: Add custom source/overrides
      # src = super.fetchurl {{
      #   url = "https://.../{{name}}-{{version}}.tar.gz";
      #   sha256 = "...";
      # }};
    }});'''
    
    def generate_service_catalog_entry(self) -> str:
        """Generate entry for lib/nixos/services.nix."""
        ports = self.data.get('expose', ['8080'])
        return f'''    {self.service_name} = mkService {{
      name = "{self.service_name}";
      version = "{self.version}";
      description = "{self.service_name.capitalize()} service for openDesk";
      category = "other";
      tier = "backend";
      ports = [ {