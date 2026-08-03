{ pkgs, lib, ... }:

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Multi-registry support for openDesk container images.

This library provides:
- Push to multiple container registries
- Image naming conventions
- Authentication management
- Registry configuration

Usage:
  registry = import ./lib/registry.nix { inherit pkgs lib; };
  
  # Define registries
  registries = [
    (registry.ghcr { name = "ghcr.io"; })
    (registry.gitlab { name = "gitlab.com"; })
    (registry.zot { name = "zot.hrz.uni-marburg.de"; url = "https://zot.hrz.uni-marburg.de"; })
  ];
  
  # Push image to all registries
  registry.pushAll { image = myImage; tag = "latest"; registries = registries; }
"""

let
  # =============================================================================
  # REGISTRY DEFINITIONS
  # =============================================================================

  # Base registry type
  baseRegistry = { name, type, url, namespace ? null, username ? null, password ? null, 
    insecure ? false, enabled ? true, default ? false }:
    {
      inherit name type url namespace username password insecure enabled default;
      fullName = if namespace != null then "${url}/${namespace}" else url;
    };

  # GitHub Container Registry (GHCR)
  ghcr = { name ? "ghcr.io", namespace ? "opendesk-edu", username ? null, password ? null, 
    insecure ? false, enabled ? true, default ? false }:
    baseRegistry {
      inherit name namespace username password insecure enabled default;
      type = "ghcr";
      url = "ghcr.io";
    };

  # GitLab Container Registry
  gitlab = { name ? "gitlab.opencode.de", namespace ? "umr/opendesk-edu", 
    username ? null, password ? null, insecure ? false, enabled ? true, default ? false }:
    baseRegistry {
      inherit name namespace username password insecure enabled default;
      type = "gitlab";
      url = name;
    };

  # Zot Registry
  zot = { name ? "zot.hrz.uni-marburg.de", url ? "https://zot.hrz.uni-marburg.de", 
    namespace ? null, username ? null, password ? null, 
    insecure ? true, enabled ? true, default ? true }:
    baseRegistry {
      inherit name url namespace username password insecure enabled default;
      type = "zot";
    };

  # Docker Hub
  dockerHub = { name ? "docker.io", namespace ? null, username ? null, password ? null, 
    insecure ? false, enabled ? true, default ? false }:
    baseRegistry {
      inherit name namespace username password insecure enabled default;
      type = "docker-hub";
      url = "docker.io";
    };

  # Quay.io
  quay = { name ? "quay.io", namespace ? null, username ? null, password ? null, 
    insecure ? false, enabled ? true, default ? false }:
    baseRegistry {
      inherit name namespace username password insecure enabled default;
      type = "quay";
      url = "quay.io";
    };

  # Local registry (for development)
  local = { name ? "localhost:5000", url ? "localhost:5000", 
    namespace ? null, insecure ? true, enabled ? true, default ? false }:
    baseRegistry {
      inherit name url namespace insecure enabled default;
      type = "local";
      username = null;
      password = null;
    };

  # =============================================================================
  # REGISTRY CONFIGURATION
  # =============================================================================

  # Default openDesk registries
  defaultRegistries = [
    (ghcr { namespace = "opendesk-edu"; default = true; })
    (gitlab { namespace = "umr/opendesk-edu"; })
    (zot { url = "https://zot.hrz.uni-marburg.de"; namespace = "opendesk-edu"; })
  ];

  # Production registries (HRZ)
  hrzRegistries = [
    (zot { url = "https://zot.hrz.uni-marburg.de"; namespace = "opendesk-edu"; default = true; })
    (ghcr { namespace = "opendesk-edu"; })
  ];

  # Development registries
  devRegistries = [
    (local { name = "localhost:5000"; default = true; })
    (ghcr { namespace = "opendesk-edu"; })
  ];

  # CI/CD registries
  ciRegistries = [
    (ghcr { namespace = "opendesk-edu"; default = true; })
    (gitlab { namespace = "umr/opendesk-edu"; })
    (zot { url = "https://zot.hrz.uni-marburg.de"; namespace = "opendesk-edu"; })
  ];

  # =============================================================================
  # IMAGE NAMING CONVENTIONS
  # =============================================================================

  # Format image name according to registry conventions
  formatImageName = { registry, repo, tag ? "latest", digest ? null }:
    let
      base = if registry.namespace != null then "${registry.fullName}/${repo}" else "${registry.url}/${repo}";
    in
      if digest != null then "${base}@${digest}"
      else "${base}:${tag}";

  # Format image name for a service
  formatServiceImageName = { serviceName, serviceVersion ? "latest", registry, 
    prefix ? "opendesk-edu", includeVersion ? true, tag ? null }:
    let
      repo = if prefix != null then "${prefix}/${serviceName}" else serviceName;
      finalTag = if tag != null then tag else if includeVersion then serviceVersion else "latest";
    in
      formatImageName { inherit registry repo; tag = finalTag; };

  # Parse image name into components
  parseImageName = imageName:
    let
      parts = builtins.split "/" imageName;
      repoParts = if builtins.length parts > 1 then builtins.tail parts else parts;
      nameParts = builtins.split ":" (builtins.head repoParts);
      tagParts = if builtins.length nameParts > 1 then [ builtins.tail nameParts ] else [ [ ] ];
      digestParts = builtins.match "@.*" (builtins.head nameParts);
      
      name = if digestParts == null then builtins.head nameParts else builtins.substring 0 (builtins.stringLength (builtins.head nameParts) - (builtins.stringLength digestParts)) (builtins.head nameParts);
      tag = if builtins.length (builtins.head tagParts) > 0 then builtins.head (builtins.head tagParts) else null;
      digest = if digestParts != null then builtins.substring 1 (builtins.stringLength digestParts) digestParts else null;
      registry = if builtins.length parts > 1 then builtins.head parts else "docker.io";
      namespace = if builtins.length parts > 2 then builtins.elemAt parts 1 else null;
    in {
      inherit registry namespace name tag digest;
      repo = if namespace != null then "${namespace}/${name}" else name;
    };

  # =============================================================================
  # IMAGE PUSHING
  # =============================================================================

  # Generate Docker push command for a single registry
  generatePushCommand = { image, tag, registry, auth ? true }:
    let
      imageName = formatImageName { inherit registry repo = image.name; tag = tag; };
      authCmd = if auth && registry.username != null && registry.password != null then
        "${pkgs.docker}/bin/docker login ${registry.url} -u ${registry.username} -p ${registry.password} && "
      else if auth && registry.name == "ghcr.io" then
        "echo 'GHCR credentials should be in ~/.docker/config.json' && "
      else if auth then
        "echo 'No credentials configured for ${registry.name}' && "
      else
        "";
    in
      "${authCmd}${pkgs.docker}/bin/docker push ${imageName}";

  # Generate Skopeo copy command (for local Zot registry without Docker)
  generateSkopeoCopyCommand = { sourceImage, sourceTag, targetRegistry, targetRepo, 
    targetTag ? sourceTag, auth ? true }:
    let
      source = "docker://${sourceImage}:${sourceTag}";
      target = "docker://${formatImageName { registry = targetRegistry; repo = targetRepo; tag = targetTag; }}";
      authArgs = if auth then "--dest-creds=${targetRegistry.username}:${targetRegistry.password}" else "";
      insecureArgs = if targetRegistry.insecure then "--dest-tls-verify=false" else "";
    in
      "${pkgs.skopeo}/bin/skopeo copy ${source} ${target} --all ${authArgs} ${insecureArgs}";

  # Push image to a single registry
  pushToRegistry = { image, tag, registry, method ? "docker", auth ? true }:
    let
      cmd = if method == "docker" then
        generatePushCommand { inherit image tag registry auth; }
      else if method == "skopeo" then
        generateSkopeoCopyCommand {
          sourceImage = image.name;
          sourceTag = image.version or tag;
          targetRegistry = registry;
          targetRepo = image.name;
          targetTag = tag;
          auth = auth;
        }
      else
        throw "Invalid push method: ${method}. Valid options: docker, skopeo";
    in
      pkgs.writeShellScriptBin "push-to-${registry.name}" cmd;

  # Push image to multiple registries
  pushAll = { image, tag, registries, method ? "docker", auth ? true }:
    let
      filteredRegistries = builtins.filter (r: r.enabled) registries;
      pushCommands = map (registry: pushToRegistry { inherit image tag registry method auth; }) filteredRegistries;
    in
      pkgs.writeShellScriptBin "push-all" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        echo "Pushing ${image.name}:${tag} to ${toString (builtins.length filteredRegistries)} registries..."
        ${builtins.concatStringsSep "\n" pushCommands}
        echo "Push complete!"
      '';

  # =============================================================================
  # IMAGE TAGGING
  # =============================================================================

  # Generate tag from Git information
  generateGitTag = { short ? true, prefix ? "", suffix ? "" }:
    let
      # In a real implementation, this would be called with git info
      # For now, return a placeholder
      gitInfo = { 
        commit = "abc123";
        shortCommit = "abc123";
        branch = "main";
        tag = null;
        dirty = false;
      };
      
      tag = if gitInfo.tag != null then gitInfo.tag
        else if short then gitInfo.shortCommit
        else gitInfo.commit;
    in
      "${prefix}${tag}${suffix}";

  # Generate semantic version tag
  generateSemverTag = { version, prefix ? "v" }:
    "${prefix}${version}";

  # Generate timestamp tag
  generateTimestampTag = { timestamp ? builtins.currentTime, format ? "%Y%m%d-%H%M%S" }:
    # In a real implementation, we'd use strftime
    # For now, just return a simplified version
    "${builtins.substring 0 8 timestamp}-${builtins.substring 8 6 timestamp}";

  # Tagging strategies
  tagStrategies = {
    git = generateGitTag;
    semver = generateSemverTag;
    timestamp = generateTimestampTag;
    latest = _: "latest";
    commit = { }@args: generateGitTag (args // { short = true; });
    shortCommit = { }@args: generateGitTag (args // { short = true; prefix = "git-"; });
  };

  # Apply multiple tags to an image
  applyTags = { image, tags, registry, method ? "docker" }:
    let
      tagCommands = map (tag: generatePushCommand { inherit image registry; tag = tag; method = method; }) tags;
    in
      pkgs.writeShellScriptBin "tag-and-push" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        echo "Tagging and pushing ${image.name} with tags: ${builtins.concatStringsSep ", " tags}"
        # Tag the image
        ${pkgs.docker}/bin/docker tag ${image.name}:latest ${formatImageName { registry = registry; repo = image.name; tag = builtins.head tags; }}
        ${builtins.concatStringsSep "\n" tagCommands}
        echo "Done!"
      '';

  # =============================================================================
  # REGISTRY AUTHENTICATION
  # =============================================================================

  # Create Docker config file for registry authentication
  createDockerConfig = { registries, outputPath ? "./config.json" }:
    let
      filteredRegistries = builtins.filter (r: r.enabled && r.username != null && r.password != null) registries;
      auths = map (registry: {
        name = registry.fullName;
        auth = builtins.base64Encode "${registry.username}:${registry.password}";
      }) filteredRegistries;
      config = {
        auths = builtins.listToAttrs auths;
        # Add experimental features for local registry
        "experimental" = "enabled";
      };
    in
      pkgs.writeText outputPath (builtins.toJSON config);

  # Create registry authentication script
  createAuthScript = { registries, outputPath ? "./auth.sh" }:
    let
      loginCommands = map (registry: 
        if registry.username != null && registry.password != null then
          "${pkgs.docker}/bin/docker login ${registry.fullName} -u ${registry.username} -p ${registry.password}"
        else if registry.name == "ghcr.io" then
          "echo 'Using GITHUB_TOKEN from environment for ${registry.name}' && echo ${registry.password} | ${pkgs.docker}/bin/docker login ${registry.fullName} -u USERNAME --password-stdin"
        else
          "echo 'Skipping ${registry.name} - no credentials configured'"
      ) registries;
    in
      pkgs.writeText outputPath (''#${'!'}${pkgs.bash}/bin/bash
        set -euo pipefail
        echo "Authenticating with registries..."
        ${builtins.concatStringsSep "\n" loginCommands}
        echo "Authentication complete!"
      '');

  # =============================================================================
  # REGISTRY HEALTH CHECKS
  # =============================================================================

  # Check registry health
  checkRegistryHealth = { registry, timeout ? 10 }:
    let
      url = if registry.insecure then "http://${registry.url}/v2/" else "https://${registry.url}/v2/";
      cmd = "${pkgs.curl}/bin/curl --fail --silent --show-error --max-time ${toString timeout} --output /dev/null ${url}";
      
      # Add insecure flag for local registries
      insecureFlag = if registry.insecure then "--insecure" else "";
      fullCmd = "${cmd} ${insecureFlag}";
    in
      fullCmd;

  # Check all registries
  checkAllRegistries = { registries, timeout ? 10 }:
    let
      checkCommands = map (registry: 
        "echo -n '\nChecking ${registry.name}... ' && ${checkRegistryHealth { registry = registry; timeout = timeout; }} && echo 'OK' || echo 'FAILED'"
      ) registries;
    in
      pkgs.writeShellScriptBin "check-registries" (''
        #${'!'}${pkgs.bash}/bin/bash
        set -euo pipefail
        echo "Checking registry health..."
        ${builtins.concatStringsSep "\n" checkCommands}
        echo "\nRegistry check complete!"
      '');

  # =============================================================================
  # IMAGE INDEXING AND SEARCHING
  # =============================================================================

  # List all images in a registry (requires appropriate permissions)
  listImages = { registry, namespace ? null, limit ? 100 }:
    let
      url = if registry.insecure then "http://${registry.url}/v2/" else "https://${registry.url}/v2/";
      baseUrl = if namespace != null then "${url}${namespace}/" else url;
      cmd = "${pkgs.curl}/bin/curl --silent --show-error ${url}_catalog?n=${toString limit}";
      insecureFlag = if registry.insecure then "--insecure" else "";
    in
      "${cmd} ${insecureFlag}";

  # Get image tags from a registry
  getImageTags = { registry, imageName, limit ? 100 }:
    let
      url = if registry.insecure then "http://" else "https://";
      baseUrl = "${url}${registry.url}/v2/${imageName}/tags/list?n=${toString limit}";
      cmd = "${pkgs.curl}/bin/curl --silent --show-error ${baseUrl}";
      insecureFlag = if registry.insecure then "--insecure" else "";
    in
      "${cmd} ${insecureFlag}";

  # =============================================================================
  # IMAGE SYNCING
  # =============================================================================

  # Sync image between registries
  syncImage = { sourceRegistry, targetRegistry, imageName, sourceTag ? "latest", 
    targetTag ? sourceTag, auth ? true }:
    let
      cmd = generateSkopeoCopyCommand {
        sourceImage = formatImageName { registry = sourceRegistry; repo = imageName; tag = sourceTag; };
        sourceTag = null;  # Already in sourceImage
        targetRegistry = targetRegistry;
        targetRepo = imageName;
        targetTag = targetTag;
        auth = auth;
      };
    in
      pkgs.writeShellScriptBin "sync-${sourceRegistry.name}-to-${targetRegistry.name}" cmd;

  # Sync all images from one registry to another
  syncAllImages = { sourceRegistry, targetRegistry, namespaces ? [ ], auth ? true }:
    let
      # This would list all images and sync them
      # For now, just return a placeholder
      cmd = "echo 'Image syncing not yet implemented' && echo 'This would sync all images from ${sourceRegistry.name} to ${targetRegistry.name}'";
    in
      pkgs.writeShellScriptBin "sync-all" cmd;

  # =============================================================================
  # IMAGE CLEANUP
  # =============================================================================

  # Clean up untagged images from a registry
  cleanupUntaggedImages = { registry, namespace ? null, dryRun ? true, keepDays ? 30 }:
    let
      url = if registry.insecure then "http://" else "https://";
      baseUrl = "${url}${registry.url}/v2/${namespace or ""}";
      cmd = "echo 'Untagged image cleanup not yet implemented' && echo 'Would cleanup images older than ${toString keepDays} days from ${registry.name}'";
      dryRunFlag = if dryRun then "--dry-run" else "";
    in
      pkgs.writeShellScriptBin "cleanup-untagged" cmd;

  # =============================================================================
  # REGISTRY STATISTICS
  # =============================================================================

  # Get registry statistics
  getRegistryStats = { registry }:
    let
      cmd = if registry.type == "zot" then
        # Zot has a specific API for stats
        "${pkgs.curl}/bin/curl --silent --show-error ${if registry.insecure then "--insecure" else ""} ${if registry.insecure then "http://" else "https://"}${registry.url}/v2/_zot/stats"
      else
        # Generic registry stats
        "echo 'Registry stats not available for ${registry.type}'"
      ;
    in
      cmd;

  # =============================================================================
  # UTILITY FUNCTIONS
  # =============================================================================

  # Get the default registry from a list
  getDefaultRegistry = registries:
    let
      default Registries = builtins.filter (r: r.default) registries;
    in
      if builtins.length defaultRegistries > 0 then
        builtins.head defaultRegistries
      else if builtins.length registries > 0 then
        builtins.head registries
      else
        null;

  # Get registry by name
  getRegistryByName = { name, registries }:
    let
      matching = builtins.filter (r: r.name == name) registries;
    in
      if builtins.length matching > 0 then
        builtins.head matching
      else
        null;

  # Get registry by type
  getRegistryByType = { type, registries }:
    let
      matching = builtins.filter (r: r.type == type) registries;
    in
      if builtins.length matching > 0 then
        builtins.head matching
      else
        null;

  # Enable/disable a registry
  toggleRegistry = { name, enabled, registries }:
    map (r: if r.name == name then r // { enabled = enabled; } else r) registries;

  # Set default registry
  setDefaultRegistry = { name, registries }:
    map (r: r // { default = (r.name == name); }) registries;

  # =============================================================================
  # EXPORT ALL
  # =============================================================================

in {
  inherit
    # Registry factories
    baseRegistry ghcr gitlab zot dockerHub quay local
    
    # Registry configurations
    defaultRegistries hrzRegistries devRegistries ciRegistries
    
    # Image naming
    formatImageName formatServiceImageName parseImageName
    
    # Image pushing
    generatePushCommand generateSkopeoCopyCommand
    pushToRegistry pushAll
    
    # Tagging
    generateGitTag generateSemverTag generateTimestampTag
    tagStrategies applyTags
    
    # Authentication
    createDockerConfig createAuthScript
    
    # Health checks
    checkRegistryHealth checkAllRegistries
    
    # Image operations
    listImages getImageTags
    
    # Syncing
    syncImage syncAllImages
    
    # Cleanup
    cleanupUntaggedImages
    
    # Statistics
    getRegistryStats
    
    # Utilities
    getDefaultRegistry getRegistryByName getRegistryByType
    toggleRegistry setDefaultRegistry
    ;
}
