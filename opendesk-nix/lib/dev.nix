// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Development Environment Library for openDesk

This library provides development environments and tooling:
- Development shells with all necessary tools (FR-DEV-001)
- IDE integration (FR-DEV-002)
- Local development without full Nix installation (FR-DEV-004)

OpenSpec Compliance:
- FR-DEV-001: Development shells with all necessary tools
- FR-DEV-002: IDE integration
- FR-DEV-004: Local development without full Nix installation

Usage:
  dev = import ./lib/dev.nix { pkgs = pkgs; };
  
  # Enter a development shell
  nix develop -c dev.shells.default
  
  # Or use devShell in flake.nix
  devShells.default = dev.mkDevShell { services = [ "mariadb" "postgresql" ]; };
  
  # Generate IDE configuration
  dev.ide.generateVSCodeSettings { workspaceRoot = "."; };
  
  # Docker-based dev environment (no Nix required)
  docker run -it dev.containerImage { services = [ "mariadb" "postgresql" ]; };
"""

{ 
  pkgs ? import <nixpkgs> { }
, 
  lib ? import ./types.nix { }
, 
  securityScanning ? null
, 
  cosign ? null
, 
  config ? { }
}:

let

  # =============================================================================
  # DEPENDENCIES
  # =============================================================================
  
  # Common development tools
  commonTools = with pkgs; [
    # Version control
    git
    git-lfs
    gh  # GitHub CLI
    glab  # GitLab CLI
    
    # Container tools
    docker
    docker-compose
    buildah
    podman
    crane
    skopeo
    
    # Kubernetes tools
    kubectl
    helm
    helmfile
    k9s
    kustomize
    
    # Nix tools
    nix
    nix-flakes
    nix-prefetch-github
    
    # Development tools
    bash
    coreutils
    findutils
    gnused
    gnugrep
    gnumake
    jq
    yq
    openssl
    
    # Code editors
    vim
    nano
    
    # Networking
    curl
    wget
    netcat
    socat
    
    # Monitoring
    htop
    iotop
    
    # Security
    gnupg
    age
    
    # Python
    python3
    python3Packages.pip
    python3Packages.virtualenv
    
    # Node.js (for some service development)
    nodejs_20
    nodePackages.yarn
    nodePackages.pnpm
    
    # Build tools
    cmake
    autoconf
    automake
    pkg-config
    
    # Testing
    bats
    shellcheck
    
    # Container image tools
    dive  # Image inspection
    oras  # OCI artifact management
    
    # Cosign for signing
    cosign
    
    # Trivy for scanning
    trivy
    
    # Grype for scanning
    grype
    
    # SBOM tools
    syft
  ];
  
  # Service-specific development tools
  serviceTools = {
    mariadb = with pkgs; [ mysql ];
    postgresql = with pkgs; [ postgresql ];
    redis = with pkgs; [ redis ];
    nginx = with pkgs; [ nginx ];
    collabora = with pkgs; [ libreoffice ];
    nextcloud = with pkgs; [ php phpPackages.composer ];
    moodle = with pkgs; [ php phpPackages.composer ];
    ilias = with pkgs; [ php phpPackages.composer ];
    jupyterhub = with pkgs; [ python3 python3Packages.jupyter jupyterWith ];
    sogo = with pkgs; [ openssl ];
    planka = with pkgs; [ nodejs_20 nodePackages.yarn ];
    etherpad = with pkgs; [ nodejs_20 nodePackages.npm ];
    drawio = with pkgs; [ nodejs_20 ];
    excalidraw = with pkgs; [ nodejs_20 nodePackages.yarn ];
    cryptpad = with pkgs; [ nodejs_20 nodePackages.npmjs ];
    rocketchat = with pkgs; [ nodejs_20 mongodb ];
    element = with pkgs; [ nodejs_20 nodePackages.yarn ];
    jitsi = with pkgs; [ nodejs_20 ];
    openproject = with pkgs; [ ruby rubyPackages.bundler ];
    xwiki = with pkgs; [ openjdk21 ];
    onlyoffice = with pkgs; [ nodejs_20 ];
    keycloak = with pkgs; [ openjdk21 ];
    bookstack = with pkgs; [ php phpPackages.composer ];
    selfoss = with pkgs; [ php phpPackages.composer ];
    wallabag = with pkgs; [ php phpPackages.composer ];
    shaarli = with pkgs; [ php phpPackages.composer ];
    states = with pkgs; [ nodejs_20 nodePackages.npm ];
  };
  
  # =============================================================================
  # DEVELOPMENT SHELLS (FR-DEV-001)
  # =============================================================================
  
  shells = rec {
    
    # Default shell with common tools
    default = mkDevShell { tools = commonTools; };
    
    # Minimal shell
    minimal = mkDevShell { 
      tools = with pkgs; [ bash git curl ];
      description = "Minimal development shell";
    };
    
    # Infrastructure shell (k8s, containers, helm)
    infrastructure = mkDevShell { 
      tools = commonTools ++ with pkgs; [ 
        terraform
        ansible
        vagrant
      ];
      description = "Infrastructure development shell";
    };
    
    # Security shell
    security = mkDevShell { 
      tools = commonTools ++ with pkgs; [ 
        nmap
        openssl
        gnupg
        age
      ];
      description = "Security-focused development shell";
    };
    
    # For a specific service
    forService = { serviceName, extraTools ? [] }:
      let
        tools = commonTools ++ (serviceTools.${serviceName} or [ ]) ++ extraTools;
      in
        mkDevShell { 
          inherit serviceName;
          tools = tools;
          description = "Development shell for ${serviceName}";
          SERVICE = serviceName;
        };
    
    # For multiple services
    forServices = { services, extraTools ? [] }:
      let
        tools = commonTools ++ builtins.concatMap (svc: serviceTools.${svc} or [ ]) services ++ extraTools;
      in
        mkDevShell { 
          tools = tools;
          description = "Development shell for: ${builtins.concatStringsSep ", " services}";
        };
    
    # Nix development shell
    nix = mkDevShell { 
      tools = commonTools ++ with pkgs; [ 
        nixpkgs-fmt
        statix
        deadnix
        lore
      ];
      description = "Nix development shell with linting tools";
    };
    
    # Kubernetes development shell
    k8s = mkDevShell { 
      tools = commonTools ++ with pkgs; [ 
        kind
        k3d
        minikube
        kubectl-convert
        kubectx
      ];
      description = "Kubernetes development shell";
    };
    
    # Full openDesk development shell
    full = mkDevShell { 
      tools = commonTools ++ 
        builtins.concatMap (svc: serviceTools.${svc} or [ ]) (builtins.attrNames serviceTools);
      description = "Full openDesk development shell with all service tools";
    };
    
    # Make a development shell
    mkDevShell = { 
      tools ? [],
      serviceName ? null,
      description ? null,
      extraShellHook ? "",
      ...
    }:
      let
        name = serviceName or (builtins.hashString "sha256" (toString tools));
        allTools = builtins.unique tools;
        envVars = {
          OPENDESK_DEV = "true";
          OPENDESK_SERVICE = serviceName or "";
        };
        
        shellHook = builtins.concatStringsSep "\n" ([
          "echo '=== openDesk Development Shell ==='"
          "echo 'Service: ${serviceName or "general"}'"
          "echo 'Tools: ${toString (builtins.length allTools)} packages'"
          extraShellHook
        ] ++ [ "" ]);
      in
        {
          inherit name description serviceName;
          packages = allTools;
          shellHook = shellHook;
          inherit envVars;
          buildInputs = allTools;
          propagatedBuildInputs = allTools;
        };

  };

  # =============================================================================
  # NIX FLAKE DEVELOPMENT
  # =============================================================================
  
  flake = {
    
    # Development shell outputs for flake.nix
    devShells = { services ? [ ] }:
      let
        defaultShell = shells.default;
        serviceShells = builtins.listToAttrs (map (svc: { 
          name = "${svc}";
          value = shells.forService { serviceName = svc; };
        }) services);
      in
        { default = defaultShell; } // serviceShells;
    
    # Overlay for adding tools to existing shells
    toolOverlay = tools: {
      packages = { e: pkgs: builtins.foldl' (acc: tool: 
        if builtins.elem tool acc then acc else acc ++ [ tool ]
      ) e.packageList tools;
    };

  };

  # =============================================================================
  # IDE INTEGRATION (FR-DEV-002)
  # =============================================================================
  
  ide = rec {
    
    # Generate .vscode/settings.json
    generateVSCodeSettings = { 
      workspaceRoot ? ".",
      recommendedExtensions ? [
        "ms-vscode.vscode-node-azure-pack"
        "redhat.vscode-yaml"
        "tamasfe.even-better-toml"
        "ms-azuretools.vscode-docker"
        "ms-kubernetes-tools.vscode-kubernetes-tools"
        "ms-vscode.hexeditor"
        "eamodio.gitlens"
        "usernamehw.errorlens"
        "streetsidesoftware.code-spell-checker"
        "dbaeumer.vscode-eslint"
        "esbenp.prettier-vscode"
      ],
      shell = "bash",
      useNixShell = true
    }:
      let
        settings = {
          "[markdown]" = { "editor.wordWrap": "on" };
          "[yaml]" = { "editor.quickSuggestions": { strings: true; }; };
          "editor.formatOnSave": true;
          "editor.codeActionsOnSave": {
            "source.fixAll.eslint": true;
            "source.formatDocument": true;
          };
          "files.exclude": {
            "**/.git": true;
            "**/node_modules": true;
            "**/vendor": true;
            "**/dist": true;
            "**/.nix": true;
          };
          "search.exclude": {
            "**/.git": true;
            "**/node_modules": true;
          };
          "terminal.integrated.shell.linux": shell;
          "terminal.integrated.defaultProfile.linux": shell;
          "nixTools.nixEnv.nixpkgsPath": "nixpkgs";
          "nixTools.nixEnv.useFlakes": true;
          "git.confirmSync": false;
          "git.ignoreMissingGitWarning": true;
        };
        
        extensionsJson = {
          recommendations = recommendedExtensions;
        };
      in
        {
          settings.json = pkgs.writeText "vscode-settings.json" (builtins.toJSON settings);
          extensions.json = pkgs.writeText "vscode-extensions.json" (builtins.toJSON extensionsJson);
          
          # directory with both files
          directory = pkgs.writeTextDir "vscode-config" ''
            ${pkgs.writeText "settings.json" (builtins.toJSON settings)}
            ${pkgs.writeText "extensions.json" (builtins.toJSON extensionsJson)}
          '';
        };
    
    # Generate .vscode/tasks.json for common tasks
    generateVSCodeTasks = { 
      services ? [ ]
    }:
      let
        buildTasks = map (svc: {
          type = "shell";
          label = "Build ${svc}";
          command = "nix build .#{svc}";
          group = "build";
          presentation = { echo = true; reveal = "always"; };
        }) services;
        
        devTasks = map (svc: {
          type = "shell";
          label = "Dev Shell ${svc}";
          command = "nix develop .#${svc}-dev";
          group = "test";
          isBackground = true;
        }) services;
        
        tasks = {
          version = "2.0.0";
          tasks = [
            { type = "shell"; label = "Build All"; command = "nix build"; group = "build"; }
            { type = "shell"; label = "Update flake.lock"; command = "nix flake lock --update"; group = "build"; }
            { type = "shell"; label = "Run all tests"; command = "nix run .#tests"; group = "test"; }
          ] ++ buildTasks ++ devTasks;
        };
      in
        pkgs.writeText "vscode-tasks.json" (builtins.toJSON tasks);
    
    # Generate Python IDE configuration
    generatePythonConfig = { 
      interpreter ? "${pkgs.python3}/bin/python3",
      linter ? "pylint",
      formatter ? "black"
    }:
      let
        config = {
          python = {
            pythonPath = interpreter;
            linting = { enabled = true; linter = linter; };
            formatting = { provider = formatter; };
            analysis = { typeCheckingMode = "basic"; };
          };
        };
      in
        pkgs.writeText "python-config.json" (builtins.toJSON config);
    
    # Generate .editorconfig
    generateEditorConfig = {
      root = true;
      endOfLine = "lf";
      charset = "utf-8";
      trimTrailingWhitespace = true;
      insertFinalNewline = true;
      indentStyle = "space";
      indentSize = 2;
    }:
      pkgs.writeText ".editorconfig" ''
        root = ${toString root}
        [*.{py,sh,yml,yaml,nix,json,md,tf}]
        end_of_line = ${endOfLine}
        charset = ${charset}
        trim_trailing_whitespace = ${toString trimTrailingWhitespace}
        insert_final_newline = ${toString insertFinalNewline}
        indent_style = ${indentStyle}
        indent_size = ${toString indentSize}
        
        [*.{js,ts,jsx,tsx}]
        indent_size = 2
        
        [*.{go}]
        indent_style = tab
        
        [Makefile]
        indent_style = tab
        
        [*.nix]
        indent_style = space
        indent_size = 2
      '';
    
    # Generate .direnv configuration for local development
    generateDirenvConfig = { 
      useFlakes ? true,
      shells ? [ "default" ]
    }:
      let
        config = ''
          # Load Nix shell
          ${optionalString (useFlakes) ''
            if [ -f flake.nix ]; then
              use flake
            fi
          ''}
          
          # For each shell, add a source_up command
          ${concatenateStringsSep "\n" (map (sh: ''
            source_up ${sh}() {
              if [ -f flake.nix ] && [ "$use_flake" != "" ]; then
                nix develop .#${sh} -c "$@"
              elif [ -f shell.nix ]; then
                nix-shell --argstr shellType "${sh}" -c "$@"
              else
                nix-shell -p "${toString (shells.default.packages or [ ])}" -c "$@"
              fi
            }
          '') shells)}
        '';
      in
        pkgs.writeText ".envrc" config;

  };

  # =============================================================================
  # LOCAL DEVELOPMENT WITHOUT NIX (FR-DEV-004)
  # =============================================================================
  
  # Docker-based development environment (no Nix required)
  container = rec {
    
    # Base image for development
    baseImage = pkgs.dockerTools.pullImage {
      imageName = "ghcr.io/nix-community/nix-in-docker";
      imageDigest = "sha256:abc123...";  # Update with actual digest
      sha256 = "0000000000000000000000000000000000000000000000000000";
      finalImageName = "opendesk-dev-base";
      finalImageTag = "latest";
    };
    
    # Create a development container with tools
    devImage = { tools ? commonTools }:
      pkgs.dockerTools.buildImage {
        name = "opendesk-dev";
        tag = "latest";
        fromImage = container.baseImage;
        contents = tools;
        config = {
          Cmd = [ "/bin/bash" ];
          WorkingDir = "/workspace";
          Env = [
            "OPENDESK_DEV=true"
            "NIX_CONFIG_DIR=/etc/nix"
          ];
          Volumes = [
            { host = "."; container = "/workspace"; }
            { host = "~/.config/nix"; container = "/etc/nix"; }
          ];
        };
      };
    
    # Container for a specific service
    forService = { serviceName }:
      container.devImage { 
        tools = commonTools ++ (serviceTools.${serviceName} or [ ]);
        extraEnv = [ "OPENDESK_SERVICE=${serviceName}" ];
      };
    
    # Docker Compose configuration for local dev environment
    composeConfig = { services ? [ "mariadb" "postgresql" "redis" "nginx" ] }:
      let
        serviceConfigs = map (svc: ''
          ${svc}:
            image: ghcr.io/opendesk-edu/${svc}:latest
            ports:
              - "${containerPorts.${svc} or "8080"}:80"
            volumes:
              - ${svc}-data:/var/lib/${svc}
            environment:
              - OPENDESK_ENV=local
        '') services;
      in
        pkgs.writeText "docker-compose.dev.yml" ''
          version: '3.8'
          services:
            ${concatenateStringsSep "\n            " serviceConfigs}
          volumes:
            ${concatenateStringsSep "\n            " (map (svc: "${svc}-data:") services)}
        '';
    
    # Container port mappings
    containerPorts = {
      mariadb = "3306"
      postgresql = "5432"
      redis = "6379"
      nginx = "80"
      collabora = "9980"
      nextcloud = "80"
      moodle = "80"
      ilias = "80"
      jupyterhub = "8000"
      sogo = "20000"
      planka = "1337"
      etherpad = "9001"
      drawio = "8080"
      excalidraw = "3000"
      cryptpad = "3000"
      rocketchat = "3000"
      element = "80"
      jitsi = "80"
      openproject = "80"
      xwiki = "8080"
      onlyoffice = "80"
      keycloak = "8080"
    };
    
    # Generate Podman Compose alternative
    podmanCompose = { services ? [ ] }:
      container.composeConfig { services = services; };
    
    # Local development scripts (work without Nix)
    scripts = {
      start = pkgs.writeShellScriptBin "opendesk-dev-start" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        
        echo "Starting openDesk local development environment..."
        
        # Check for Docker
        if ! command -v docker &> /dev/null; then
          echo "ERROR: Docker is required. Please install Docker."
          exit 1
        fi
        
        # Check for docker-compose or podman-compose
        COMPOSE_CMD=""
        if command -v docker-compose &> /dev/null; then
          COMPOSE_CMD="docker-compose"
        elif command -v podman-compose &> /dev/null; then
          COMPOSE_CMD="podman-compose"
        else
          echo "ERROR: docker-compose or podman-compose is required."
          exit 1
        fi
        
        # Start services
        $COMPOSE_CMD -f docker-compose.dev.yml up -d
        
        echo "✅ Development environment started"
        echo "Dashboard: http://localhost:8080"
      '';
      
      stop = pkgs.writeShellScriptBin "opendesk-dev-stop" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        
        COMPOSE_CMD="docker-compose"
        if ! command -v docker-compose &> /dev/null; then
          COMPOSE_CMD="podman-compose"
        fi
        
        $COMPOSE_CMD -f docker-compose.dev.yml down
        echo "✅ Development environment stopped"
      '';
      
      build = pkgs.writeShellScriptBin "opendesk-dev-build" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        
        if command -v nix &> /dev/null; then
          echo "Building with Nix..."
          nix build $@
        else
          echo "Building with Docker..."
          docker build -t opendesk-dev $@ .
        fi
      '';
      
      test = pkgs.writeShellScriptBin "opendesk-dev-test" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        
        if command -v nix &> /dev/null; then
          nix run .#tests $@
        elif command -v pytest &> /dev/null; then
          pytest $@
        else
          echo "No test runner found. Install pytest or use Nix."
          exit 1
        fi
      '';
    };

  };

  # =============================================================================
  # REMOTE DEVELOPMENT (SSH, CODESPACES, ETC.)
  # =============================================================================
  
  remote = {
    
    # GitHub Codespaces configuration
    codespacesConfig = { 
      containers ? [ "default" ],
      image ? "ghcr.io/opendesk-edu/dev-container:latest"
    }:
      {
        devcontainer.json = pkgs.writeText "devcontainer.json" (builtins.toJSON {
          name = "openDesk Development";
          image = image;
          features = { };
          customizeContainer = {
            extensions = [
              "ms-vscode.vscode-node-azure-pack"
              "redhat.vscode-yaml"
              "ms-azuretools.vscode-docker"
              "ms-kubernetes-tools.vscode-kubernetes-tools"
            ];
          };
          forwardPorts = builtins.attrValues container.containerPorts;
          remoteUser = "vscode";
          workspaceFolder = "/workspace";
        });
      };
    
    # DevPod configuration
    devpodConfig = pkgs.writeText ".devpod.yaml" ''
      id: opendesk
      name: openDesk Development
      
      providers:
        - name: docker
          type: docker
          
        - name: kubernetes
          type: kubernetes
          
      workspace:
        - name: default
          container: opendesk-dev
          prebuild: nix build
          
      containers:
        - image: ghcr.io/opendesk-edu/dev-container:latest
          command: sleep infinity
    '';

  };

  # =============================================================================
  # DOCUMENTATION
  # =============================================================================
  
  docs = {
    
    # Generate development setup guide
    setupGuide = pkgs.writeText "DEVELOPMENT.md" ''
      # openDesk Development Guide
      
      ## Quick Start
      
      ### With Nix (Recommended)
      
      1. Install Nix: https://nixos.org/download.html
      2. Enable flakes:
         ```bash
         echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
         ```
      3. Enter development shell:
         ```bash
         nix develop
         ```
      
      ### Without Nix (Docker)
      
      1. Install Docker: https://docs.docker.com/get-docker/
      2. Start development environment:
         ```bash
         ./scripts/opendesk-dev-start
         ```
      
      ### VS Code
      
      1. Install recommended extensions
      2. Open Workspace Settings (JSON)
      3. Paste the contents of `.vscode/settings.json`
      
      ## Available Shells
      
      | Shell | Purpose |
      |-------|---------|
      | `default` | General development |
      | `minimal` | Minimal tools |
      | `infrastructure` | K8s, Terraform, Ansible |
      | `security` | Security-focused tools |
      | `nix` | Nix development |
      | `k8s` | Kubernetes development |
      | `full` | All tools |
      | `<service>` | Service-specific |
      
      ## IDE Integration
      
      - **VS Code**: Use `.vscode/settings.json` and `.vscode/tasks.json`
      - **GitHub Codespaces**: Use `.devcontainer/devcontainer.json`
      - **DevPod**: Use `.devpod.yaml`
      
      ## Local Development without Nix
      
      Use the Docker-based scripts:
      - `./scripts/opendesk-dev-start` - Start services
      - `./scripts/opendesk-dev-stop` - Stop services
      - `./scripts/opendesk-dev-build` - Build images
      - `./scripts/opendesk-dev-test` - Run tests
      
      ## Remote Development
      
      - **Codespaces**: Open in GitHub Codespaces
      - **DevPod**: Run `devpod up`
      
      ## Troubleshooting
      
      ### Nix Cache Issues
      ```bash
      nix store gc
      nix flake lock --update
      ```
      
      ### Docker Permission Issues
      ```bash
      sudo usermod -aG docker $USER
      newgrp docker
      ```
    '';

  };

  # =============================================================================
  # EXPORTS
  # =============================================================================
  
{
  inherit shells flake ide container remote docs;
  
  config = {
    dev = {
      enabled = true;
      shells = {
        default = true;
        forServices = true;
      };
      ide = {
        vscode = true;
        editorconfig = true;
        direnv = true;
      };
      local = {
        docker = true;
        podman = true;
        scripts = true;
      };
    };
  };
  
  meta = {
    name = "dev";
    version = "1.0.0";
    description = "Development environment library for openDesk";
    license = "Apache-2.0";
    openspec = [ "FR-DEV-001" "FR-DEV-002" "FR-DEV-004" ];
  };
}
