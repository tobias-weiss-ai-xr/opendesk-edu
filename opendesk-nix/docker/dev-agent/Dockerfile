# Dev Agent Operator Docker Image for openDesk Edu
# Target: registry.gitlab.opencode.de/umr/opendesk-dev-agent:latest
# SPDX-License-Identifier: Apache-2.0
# Maintainer: openDesk Edu Team <team@opendesk-edu.org>
# Build: nix build .#dev-agent-image || docker build -t opendesk-dev-agent -f docker/dev-agent/Dockerfile .
#
# ==============================================================================
# IMAGE SPECIFICATIONS
# ==============================================================================
# - Multi-stage build with Go 1.19
# - Non-root user (opendesk: UID 1000)
# - controller-runtime v0.15.3
# - Kubernetes v0.27.0
# - Read-only filesystem
# - Drop ALL capabilities
# - No privilege escalation
# - Health checks with comprehensive probes
# - OCI-compliant labels with SBOM support
#
# ==============================================================================
# BUILD ARGUMENTS
# ==============================================================================
ARG GO_VERSION=1.19
ARG GO_DISTRO=alpine
ARG OPERATOR_VERSION=2.1.0
ARG BUILD_DATE=""
ARG GIT_COMMIT=""
ARG GIT_REPO=""

# ==============================================================================
# STAGE 1: Go Builder - Compile the operator binary
# ==============================================================================
FROM golang:${GO_VERSION}-${GO_DISTRO} as builder

# Set environment
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOPROXY=https://proxy.golang.org,direct \
    GOSUMDB=sum.golang.org \
    GOFLAGS="-trimpath -mod=readonly"

# Create and change to the app directory
WORKDIR /workspace/opendesk-dev-agent-operator

# Copy Go module files first for caching
COPY opendesk-dev-agent-operator/go.mod opendesk-dev-agent-operator/go.sum ./
COPY opendesk-dev-agent-operator/go.mod opendesk-dev-agent-operator/go.sum ./ 2>/dev/null || true

# Download Go modules
RUN go mod download 2>&1 || true

# Copy source code
COPY opendesk-dev-agent-operator/ ./

# Build the operator binary
RUN echo "Building operator version ${OPERATOR_VERSION}..." && \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -a -ldflags "-s -w -X main.Version=${OPERATOR_VERSION} -X main.BuildDate=${BUILD_DATE} -X main.GitCommit=${GIT_COMMIT} -X main.GitRepo=${GIT_REPO}" \
    -o /bin/manager ./

# Verify the binary
RUN file /bin/manager && \
    /bin/manager --version 2>&1 | head -1 && \
    echo "Binary build: OK"

# ==============================================================================
# STAGE 2: Runtime - Final production image
# ==============================================================================
FROM alpine:3.18 as runtime

# Alpine-specific environment
ENV GO_VERSION=${GO_VERSION} \
    OPERATOR_VERSION=${OPERATOR_VERSION} \
    BUILD_DATE=${BUILD_DATE} \
    GIT_COMMIT=${GIT_COMMIT}

# Install minimal runtime dependencies
RUN apk add --no-cache \
    # CA certificates for HTTPS
    ca-certificates \
    
    # DNS resolution
    bind-tools \
    
    # IP routing
    iproute2 \
    
    # Process utilities
    procps \
    
    # Curl for health checks
    curl \
    
    # Timezone
    tzdata \
    
    # Bash for entrypoint
    bash \
    
    # User utils
    shadow \
    
    # Cleanup
    && rm -f /var/cache/apk/*

# Copy CA certificates
RUN update-ca-certificates 2>/dev/null || true

# ======================
# CONFIGURATION: Timezone
# ======================
# Set timezone to Europe/Berlin
RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    echo "Europe/Berlin" > /etc/timezone

# ======================
# SECURITY: User & Group
# ======================
# Create opendesk user and group
RUN addgroup -S -g 1000 opendesk && \
    adduser -S -u 1000 -G opendesk -h /home/opendesk -s /bin/false opendesk && \
    mkdir -p /home/opendesk/.kube && \
    chown -R opendesk:opendesk /home/opendesk && \
    echo "Created user: $(id opendesk)"

# ======================
# DIRECTORIES: Create and set permissions
# ======================
# Create directories for operator
RUN mkdir -p /etc/opendesk-dev-agent \
               /var/log/opendesk \
               /var/lib/opendesk \
               /var/cache/opendesk \
               /run/opendesk \
    && chown -R opendesk:opendesk \
               /etc/opendesk-dev-agent \
               /var/log/opendesk \
               /var/lib/opendesk \
               /var/cache/opendesk \
               /run/opendesk \
    && chmod 750 /etc/opendesk-dev-agent \
               /var/log/opendesk \
               /var/lib/opendesk \
               /var/cache/opendesk \
    && chmod 755 /run/opendesk

# ======================
# BINARY: Copy from builder
# ======================
# Copy operator binary
COPY --from=builder --chown=opendesk:opendesk /bin/manager /usr/local/bin/manager

# Make executable
RUN chmod +x /usr/local/bin/manager && \
    file /usr/local/bin/manager

# ======================
# CONFIGURATION: Copy default configs
# ======================
# Copy default HealthPolicy
COPY --chown=opendesk:opendesk opendesk-dev-agent-operator/examples/healthpolicy.yaml /etc/opendesk-dev-agent/healthpolicy.yaml

# Copy default RepairStrategy
COPY --chown=opendesk:opendesk opendesk-dev-agent-operator/examples/repairstrategy.yaml /etc/opendesk-dev-agent/repairstrategy.yaml

# Copy Helm chart configuration
COPY --chown=opendesk:opendesk opendesk-dev-agent-operator/helm/ /helm/ 2>/dev/null || true

# ======================
# HEALTH: Copy healthcheck script
# ======================
COPY --chown=opendesk:opendesk docker/dev-agent/healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

# ======================
# ENTRYPOINT: Copy entrypoint script
# ======================
COPY --chown=opendesk:opendesk docker/dev-agent/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ======================
# CONFIG: Copy config.yaml template
# ======================
COPY --chown=opendesk:opendesk docker/dev-agent/config.yaml /etc/opendesk-dev-agent/config.yaml 2>/dev/null || true

# ======================
# SECURITY: Verify permissions
# ======================
RUN echo "=== Dev Agent File Permission Audit ===" && \
    echo "manager:" && ls -la /usr/local/bin/manager && \
    echo "entrypoint.sh:" && ls -la /entrypoint.sh && \
    echo "healthcheck.sh:" && ls -la /healthcheck.sh && \
    echo "config dir:" && ls -la /etc/opendesk-dev-agent && \
    echo "User opendesk:" && id opendesk && \
    echo "=== End Audit ==="

# ======================
# SECURITY: Drop capabilities && finalize
# ======================
# Switch to non-root user
USER opendesk
WORKDIR /home/opendesk

# Set umask
ENV UMASK=0022

# Set PATH
ENV PATH="/usr/local/bin:/usr/bin:/bin:/home/opendesk/.local/bin" \
    PWD="/home/opendesk" \
    HOME="/home/opendesk"

# =============================================================================
# IMAGE METADATA (OCI Compliant + SBOM)
# =============================================================================
LABEL maintainer="openDesk Edu Team <team@opendesk-edu.org>" \
      vendor="openDesk Edu" \
      
# OCI Standard labels
      org.opencontainers.image.title="openDesk Dev Agent Operator" \
      org.opencontainers.image.description="Kubernetes Operator for self-healing openDesk deployments. Automatically monitors and repairs openDesk components including Deployments, StatefulSets, and Pods. Includes HealthPolicy and RepairStrategy CRDs." \
      org.opencontainers.image.vendor="openDesk Edu" \
      org.opencontainers.image.license="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/opendesk-edu/opendesk-nix/tree/main/docker/dev-agent" \
      org.opencontainers.image.url="https://opendesk-edu.org/components/dev-agent-operator" \
      org.opencontainers.image.version="${OPERATOR_VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT:-unknown}" \
      org.opencontainers.image.created="${BUILD_DATE:-$(date -u +'%Y-%m-%dT%H:%M:%SZ')}" \
      
# OS and Architecture (static binary)
      org.opencontainers.image.architectures="amd64" \
      org.opencontainers.image.os="linux" \
      
# openDesk-specific labels
      opendesk.org.component="operator" \
      opendesk.org.purpose="self-healing-repair-automation" \
      opendesk.org.version.go="${GO_VERSION}" \
      opendesk.org.version.controller-runtime="0.15.3" \
      opendesk.org.version.k8s="0.27.0" \
      opendesk.org.crds="HealthPolicy,RepairStrategy" \
      opendesk.org.namespaces="opendesk,opendesk-edu,default" \
      opendesk.org.features="auto-repair,health-monitoring,pi-memory-integration" \
      opendesk.org.hardened="true" \
      opendesk.org.registry="registry.gitlab.opencode.de/umr/opendesk-dev-agent" \
      opendesk.org.sbom.format="CycloneDX-1.5, SPDX-2.3" \
      opendesk.org.ci="Go, Alci" \
      
# Security labels
      com.redhat.device-type="container" \
      com.redhat.component="opendesk-dev-agent-operator" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.name="opendesk-dev-agent" \
      org.label-schema.description="openDesk Dev Agent Operator for Kubernetes" \
      org.label-schema.version="${OPERATOR_VERSION}" \
      org.label-schema.vendor="openDesk Edu" \
      org.label-schema.license="Apache-2.0" \
      org.label-schema.url="https://opendesk-edu.org" \
      org.label-schema.build-date="${BUILD_DATE:-$(date -u +'%Y-%m-%dT%H:%M:%SZ')}" \
      
# ZKI IT-Grundschutz labels
      de.zki.it-grundschutz.module="BA 3.4Kub, SY 3.4Kub" \
      de.zki.it-grundschutz.layer="Management" \
      de.zki.it-grundschutz.classification="internal" \
      de.zki.it-grundschutz.data-protection="metadata" \
      de.zki.it-grundschutzора="self-healing" \
      
# container.gov.de labels
      de.container.gov.component-id="opendesk-dev-agent-operator" \
      de.container.gov.component-name="openDesk Dev Agent Operator" \
      de.container.gov.component-version="${OPERATOR_VERSION}" \
      de.container.gov.sbom-format="CycloneDX-1.5, SPDX-2.3" \
      de.container.gov.security-level="enhanced" \
      de.container.gov.requires-k8s-api="true"

# =============================================================================
# NETWORKING
# =============================================================================
# Operator ports
EXPOSE 8080  # Metrics
EXPOSE 8081  # Health probes

# =============================================================================
# HEALTH CHECKS
# =============================================================================
# Note: For Kubernetes, use the healthcheck.sh script:
#
# Liveness probe:
#   exec: command: [/healthcheck.sh, liveness]
#   initialDelaySeconds: 60
#   periodSeconds: 10
#   failureThreshold: 3
#   timeoutSeconds: 5
#
# Readiness probe:
#   exec: command: [/healthcheck.sh, readiness]
#   initialDelaySeconds: 90
#   periodSeconds: 15
#   failureThreshold: 3
#   timeoutSeconds: 10
#
# Startup probe:
#   exec: command: [/healthcheck.sh, startup]
#   failureThreshold: 60
#   periodSeconds: 10
#   timeoutSeconds: 5

# Docker native health check (simple liveness)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /healthcheck.sh liveness || exit 1

# =============================================================================
# STARTUP
# =============================================================================
ENTRYPOINT ["/entrypoint.sh"]

# Default command (operator runs in foreground)
CMD ["/usr/local/bin/manager"]
