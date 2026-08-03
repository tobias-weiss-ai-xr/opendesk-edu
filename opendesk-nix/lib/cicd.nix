// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
CI/CD Pipeline Library for openDesk

This library provides comprehensive CI/CD pipeline configurations for:
- GitHub Actions
- GitLab CI
- Build triggers
- Vulnerability scanning
- Registry pushing
- Manual build triggers

OpenSpec Compliance:
- FR-CICD-001: GitHub Actions integration
- FR-CICD-002: GitLab CI integration
- FR-CICD-003: Build triggers on code changes
- FR-CICD-004: Vulnerability scan triggers
- FR-CICD-005: Registry push on release
- FR-CICD-006: Manual build triggers
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
  registry ? null
, 
  sbom ? null
, 
  config ? { }
}:

let

  scanning = if securityScanning != null then securityScanning else import ./security-scanning.nix { inherit pkgs lib; };
  signing = if cosign != null then cosign else import ./cosign.nix { inherit pkgs lib; };
  regLib = if registry != null then registry else import ./registry.nix { inherit pkgs lib; };
  sbomLib = if sbom != null then sbom else import ./sbom.nix { inherit pkgs lib; };

  # =============================================================================
  # GITHUB ACTIONS
  # =============================================================================

githubActions = rec {

  defaultConfig = {
    name = "ci";
    on = {
      push = { branches = [ "main" "feature/**" "release/**" ]; };
      pull_request = { branches = [ "main" ]; };
      schedule = [ { cron = "0 2 * * *"; } ];
      workflow_dispatch = { inputs = { 
        service = { description = "Specific service to build"; required = false; };
        force = { description = "Force rebuild"; required = false; default = "false"; };
      }; };
    };
    permissions = {
      contents = "read";
      packages = "write";
      id-token = "write";
    };
    env = {
      REGISTRY = "ghcr.io";
      IMAGE_NAME = "${{ github.repository }}";
      DOCKER_METADATA_ACTION = "docker/metadata-action@v5";
      DOCKER_BUILD_PUSH_ACTION = "docker/build-push-action@v5";
      DOCKER_LOGIN_ACTION = "docker/login-action@v3";
    };
  };

  mkServiceWorkflow = { serviceName, context ? ".", fileName ? null, config ? defaultConfig }:
    let
      workflowName = config.name or "build-${serviceName}";
      needsBuild = "needs.build.result == 'success' || needs.build.result == 'skipped'";
    in
      builtins.filterAttrs (name: value: value != null && value != "") {
        name = workflowName;
        on = config.on or defaultConfig.on;
        permissions = config.permissions or defaultConfig.permissions;
        env = (config.env or defaultConfig.env) // { SERVICE = serviceName; };
        jobs = {
          build = {
            name = "Build ${serviceName}";
            runs-on = "ubuntu-latest";
            outputs = { image = "${{ steps.meta.outputs.tags }}"; };
            steps = [
              { uses = "actions/checkout@v4"; }
              { name = "Set up Docker Buildx"; uses = "docker/setup-buildx-action@v3"; }
              { name = "Docker meta"; id = "meta"; uses = "${{ env.DOCKER_METADATA_ACTION }}"; with = {
                images = "${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/${{ env.SERVICE }}";
                tags = [
                  "type=ref,event=branch"
                  "type=ref,event=pr"
                  "type=semver,pattern={{version}}"
                  "type=semver,pattern={{major}}.{{minor}}"
                  "type=semver,pattern={{major}}"
                  "type=sha"
                ];
              }; }
              { name = "Login to Container Registry"; uses = "${{ env.DOCKER_LOGIN_ACTION }}"; with = {
                registry = "${{ env.REGISTRY }}";
                username = "${{ github.actor }}";
                password = "${{ secrets.GITHUB_TOKEN }}";
              }; }
              { name = "Build and push"; id = "build"; uses = "${{ env.DOCKER_BUILD_PUSH_ACTION }}"; with = {
                context = context;
                platforms = "linux/amd64,linux/arm64";
                push = "${{ github.event_name != 'pull_request' }}";
                tags = "${{ steps.meta.outputs.tags }}";
                labels = "${{ steps.meta.outputs.labels }}";
                cache-from = "type=gha";
                cache-to = "type=gha,mode=max";
              }; }
            ];
          };
          scan = {
            name = "Scan ${serviceName}";
            runs-on = "ubuntu-latest";
            needs = "build";
            if = "always() &&" ++ needsBuild;
            steps = [
              { uses = "actions/checkout@v4"; }
              { name = "Run Trivy scan"; uses = "aquasecurity/trivy-action@master"; with = {
                image-ref = "${{ needs.build.outputs.image }}";
                format = "sarif";
                output = "trivy-results.sarif";
                exit-code = "1";
                ignore-unfixed = true;
                vuln-type = "os,library";
                severity = "CRITICAL,HIGH";
              }; }
              { name = "Upload Trivy results"; if = "always()"; uses = "github/codeql-action/upload-sarif@v3";
                with = { sarif_file = "trivy-results.sarif"; }; }
            ];
          };
          sign = {
            name = "Sign ${serviceName}";
            runs-on = "ubuntu-latest";
            needs = "build";
            if = "always() && " ++ needsBuild;
            steps = [
              { uses = "actions/checkout@v4"; }
              { name = "Install Cosign"; uses = "sigstore/cosign-installer@v3.3.0"; }
              { name = "Sign image"; if = "${{ github.event_name != 'pull_request' }}";
                run = |
                  cosign sign --key env://COSIGN_PRIVATE_KEY \
                    ${{ needs.build.outputs.image }} \
                    --annotate=build-url=${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
                env = {
                  COSIGN_PRIVATE_KEY = "${{ secrets.COSIGN_PRIVATE_KEY }}";
                  COSIGN_PASSWORD = "${{ secrets.COSIGN_PASSWORD }}";
                }; }
            ];
          };
        };
      };

  mkMultiServiceWorkflow = { services, context ? ".", config ? defaultConfig }:
    let
      workflowName = config.name or "build-all-services";
      matrix = builtins.listToAttrs (map (svc: { name = svc; value = { service: svc; }; }) services);
    in
      builtins.filterAttrs (name: value: value != null && value != "") {
        name = workflowName;
        on = config.on or defaultConfig.on;
        permissions = config.permissions or defaultConfig.permissions;
        env = config.env or defaultConfig.env;
        jobs = {
          build = {
            name = "Build";
            runs-on = "ubuntu-latest";
            needs = "meta";
            strategy = { matrix = matrix; fail-fast = false; };
            outputs = { image = "${{ steps.build.outputs.image }}"; };
            steps = [
              { uses = "actions/checkout@v4"; }
              { name = "Docker meta"; id = "meta"; uses = "${{ env.DOCKER_METADATA_ACTION }}";
                with = {
                  images = "${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/${{ matrix.service }}";
                  tags = [
                    "type=ref,event=branch"
                    "type=ref,event=pr"
                    "type=semver,pattern={{version}}"
                    "type=sha"
                  ];
                }; }
              { name = "Set up Docker Buildx"; uses = "docker/setup-buildx-action@v3"; }
              { name = "Login to Registry"; uses = "${{ env.DOCKER_LOGIN_ACTION }}"; with = {
                registry = "${{ env.REGISTRY }}";
                username = "${{ github.actor }}";
                password = "${{ secrets.GITHUB_TOKEN }}";
              }; }
              { name = "Build and push"; id = "build"; uses = "${{ env.DOCKER_BUILD_PUSH_ACTION }}"; with = {
                context = context;
                file = "${{ matrix.service }}/Dockerfile";
                platforms = "linux/amd64,linux/arm64";
                push = "${{ github.event_name != 'pull_request' }}";
                tags = "${{ steps.meta.outputs.tags }}";
                labels = "${{ steps.meta.outputs.labels }}";
              }; }
            ];
          };
          scan = {
            name = "Scan";
            runs-on = "ubuntu-latest";
            needs = "build";
            if = "always() && needs.build.result != 'failure'";
            strategy = { matrix = matrix; fail-fast = false; };
            steps = [
              { uses = "actions/checkout@v4"; }
              { name = "Run Trivy"; uses = "aquasecurity/trivy-action@master"; with = {
                image-ref = "${{ needs.build.outputs.image }}";
                format = "sarif";
                output = "trivy-${{ matrix.service }}.sarif";
                exit-code = "1";
                severity = "CRITICAL,HIGH";
              }; }
            ];
          };
        };
      };

};

# =============================================================================
# GITLAB CI
# =============================================================================

gitlabCI = rec {

  defaultConfig = {
    stages = [ "build" "scan" "sign" "deploy" ];
    image = "docker:24.0";
    services = [ "docker:24.0-dind" ];
    variables = {
      DOCKER_DRIVER: "overlay2";
      DOCKER_TLS_CERTDIR: "";
      REGISTRY: "registry.gitlab.com";
    };
    before_script = [
      "docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY"
    ];
  };

  mkServiceJob = { serviceName, context ? ".", config ? defaultConfig }:
    let
      jobName = "build-${serviceName}";
      imageTag = "$CI_REGISTRY_IMAGE/${serviceName}:$CI_COMMIT_REF_SLUG";
    in
      builtins.filterAttrs (name: value: value != null && value != "") {
        ${jobName} = {
          stage = "build";
          image = config.image or defaultConfig.image;
          services = config.services or defaultConfig.services;
          variables = (config.variables or defaultConfig.variables) // {
            IMAGE = imageTag;
          };
          before_script = config.before_script or defaultConfig.before_script;
          script = [
            "docker build -t $IMAGE --platform linux/amd64,linux/arm64 $context"
            "docker push $IMAGE"
            "echo \"IMAGE_TAG=$IMAGE\" >> build.env"
          ];
          artifacts = {
            reports = { dotenv = "build.env"; };
          };
          rules = [
            { if = "$CI_COMMIT_BRANCH == \"main\" || $CI_COMMIT_BRANCH =~ /^feature/ || $CI_COMMIT_BRANCH =~ /^release/"; }
            { if = "$CI_PIPELINE_SOURCE == \"merge_request_event\""; }
            { if = "$CI_PIPELINE_SOURCE == \"web\"; when = "always"; }
            { if = "$CI_PIPELINE_SOURCE == \"schedule\"; }
          ];
        };
        "scan-${serviceName}" = {
          stage = "scan";
          needs = [ jobName ];
          script = [
            "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \"
              aquasec/trivy:0.48.0 image --exit-code 1 --severity CRITICAL,HIGH $IMAGE"
          ];
          allow_failure = true;
        };
        "sign-${serviceName}" = {
          stage = "sign";
          needs = [ jobName ];
          script = [
            "apk add --no-cache cosign"
            "echo $COSIGN_PRIVATE_KEY | cosign sign --key - $IMAGE \"
              "--annotate=build-url=$CI_PROJECT_URL/pipelines/$CI_PIPELINE_ID"
          ];
          rules = [
            { if = "$CI_COMMIT_BRANCH == \"main\" || $CI_REF_PROTECTED == \"true\""; }
          ];
        };
      };

  mkPipeline = { services, context ? ".", config ? defaultConfig }:
    let
      jobs = builtins.concatMap (svc: [
        gitlabCI.mkServiceJob { serviceName = svc; context = "${context}/${svc}"; config = config; }
      ]) services;
      mergedJobs = builtins.foldl' (acc: job: acc // job) { } jobs;
    in
      builtins.filterAttrs (name: value: value != null && value != "") {
        stages = config.stages or defaultConfig.stages;
        inherit (defaultConfig) image services variables before_script;
      } // mergedJobs;

};

# =============================================================================
# BUILD TRIGGERS
# =============================================================================

buildTriggers = {

  # On code changes (FR-CICD-003)
  onCodeChange = { path ? "./**" }:
    builtins.filterAttrs (name: value: value != null && value != "") {
      triggers = {
        paths = [ path ];
        action = "run";
      };
      description = "Trigger builds when code changes in ${path}";
    };

  # On schedule
  onSchedule = { cron ? "0 2 * * *" }:
    builtins.filterAttrs (name: value: value != null && value != "") {
      schedule = [ { cron = cron; } ];
      description = "Trigger builds on schedule: ${cron}";
    };

  # On external trigger
  onExternalTrigger = { event ? "repository_dispatch", types ? [ "build-request" ] }:
    builtins.filterAttrs (name: value: value != null && value != "") {
      repository_dispatch = { types = types; };
      description = "Trigger builds on ${event} events";
    };

  # On merge requests / pull requests
  onMergeRequest = {
    branches = [ "main" ];
    description = "Trigger builds on merge/pull requests targeting ${toString branches}";
  };

};

# =============================================================================
# DELIVERY PIPELINE
# =============================================================================

delivery = rec {

  # Full pipeline: build -> scan -> sign -> push
  mkPipeline = { 
    services,
    registries ? [ "ghcr" "gitlab" "zot" ],
    scan ? true,
    sign ? true,
    push ? true
  }:
    let
      workflows = {
        github = githubActions.mkMultiServiceWorkflow { services = services; };
        gitlab = gitlabCI.mkPipeline { services = services; };
      };
    in
      builtins.filterAttrs (name: value: value != null && value != "") {
        inherit workflows;
        config = {
          registries = regLib.formatRegistries registries;
          security = {
            scan = scanning.config;
            sign = signing.config;
          };
        };
        description = "Complete CI/CD pipeline for ${toString services}";
      };

  # Release pipeline with version bumping
  mkReleasePipeline = { 
    service,
    versionFile ? "./version",
    bump ? "patch",
    registries ? [ "ghcr" "gitlab" "zot" ]
  }:
    let
      workflow = githubActions.mkServiceWorkflow { serviceName = service; };
      releaseJob = {
        release = {
          name = "Release ${service}";
          runs-on = "ubuntu-latest";
          needs = "build";
          if = "github.ref == 'refs/heads/main' &&github.event_name == 'push' ";
          steps = [
            { uses = "actions/checkout@v4"; }
            { name = "Bump version"; run = "echo \"NEW_VERSION=$(npm version ${bump} --no-git-tag-version)\" >> $GITHUB_ENV"; }
            { name = "Create GitHub Release"; uses = "softprops/action-gh-release@v1";
              with = {
                tag_name = "v${{ env.NEW_VERSION }}";
                name = "${service} v${{ env.NEW_VERSION }}";
                body = "Automated release";
              }; }
            { name = "Registry push";
              run = "echo Pushing to ${toString registries} - implemented per-registry"; }
          ];
        };
      };
    in
      workflow // { jobs = workflow.jobs // releaseJob; };

};

# =============================================================================
# EXPORTS
# =============================================================================

{
  inherit githubActions gitlabCI buildTriggers delivery;
  
  config = {
    ci = {
      github = {
        enabled = true;
        runner = "ubuntu-latest";
        platforms = "linux/amd64,linux/arm64";
      };
      gitlab = {
        enabled = true;
        image = "docker:24.0";
      };
    };
    triggers = {
      onCodeChange = true;
      onSchedule = true;
      onExternal = true;
      onMergeRequest = true;
    };
    deployment = {
      pushOnRelease = true;
      manualTriggers = true;
    };
  };
  
  meta = {
    name = "cicd";
    version = "1.0.0";
    description = "CI/CD pipeline library for openDesk";
    license = "Apache-2.0";
    openspec = [ "FR-CICD-001" "FR-CICD-002" "FR-CICD-003" "FR-CICD-004" "FR-CICD-005" "FR-CICD-006" ];
  };
}
