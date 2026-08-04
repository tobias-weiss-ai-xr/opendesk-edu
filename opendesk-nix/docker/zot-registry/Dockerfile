# Hardened Zot Registry for openDesk Kubernetes Caching
# Target: registry.gitlab.opencode.de/umr/zot-registry:latest
# Purpose: Local pull-through cache registry for K3s cluster
# Base: Static Go binary with Alpine runtime
# SPDX-License-Identifier: Apache-2.0
# Security: Production-hardened, non-root, minimal attack surface
# Maintainer: openDesk Edu Team
# Version: 2.0.0-rc4
# Build: nix build .#zot-registry-image || docker build -t registry.gitlab.opencode.de/umr/zot-registry:latest -f docker/zot-registry/Dockerfile .

# ============================================
# ARGUMENTS - Configurable build parameters
# ============================================
ARG ZOT_VERSION=v2.0.0-rc4
ARG GO_VERSION=1.21.0
ARG ALPINE_VERSION=3.20
ARG BUILD_DATE
ARG GIT_COMMIT
ARG GIT_BRANCH

# ============================================
# IMAGE METADATA (Built during build)
# ============================================
ARG IMAGE_VERSION=2.0.0
ARG IMAGE_TITLE="Zot Registry (Hardened)"
ARG IMAGE_DESCRIPTION="Hardened Zot OCI Registry for openDesk Kubernetes caching with pull-through support, rate limiting, and security features"

# ============================================
# STAGE 1: Builder - Compile Zot from source
# ============================================
FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS builder

# Install build dependencies
RUN apk add --no-cache --virtual .build-deps \
    git \
    make \
    gcc \
    musl-dev \
    ca-certificates

# Clone Zot repository
WORKDIR /build
RUN git clone --depth 1 --branch ${ZOT_VERSION} https://github.com/zotregistry/zot.git . && \
    git submodule update --init --recursive

# Build Zot binary with security flags
RUN cd /build/cmd/zot && \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64 \
    go build \
      -ldflags="-w -s -extldflags '-static' \
                -X 'github.com/zotregistry/zot/pkg/api.Version=${ZOT_VERSION}' \
                -X 'github.com/zotregistry/zot/pkg/api.BuildTime=$(date -u +'%Y-%m-%dT%H:%M:%SZ')' \
                -X 'github.com/zotregistry/zot/pkg/api.GitCommit=${GIT_COMMIT:-unknown}' \
                -X 'github.com/zotregistry/zot/pkg/api.GitBranch=${GIT_BRANCH:-unknown}'" \
      -a \
      -installsuffix cgo \
      -o /zot .

# Verify binary
RUN file /zot && \
    /zot --version && \
    strip /zot

# ============================================
# STAGE 2: Final Production Image - Hardened Runtime
# ============================================
FROM alpine:${ALPINE_VERSION}

# ============================================
# SECURITY: Install minimal required packages in SINGLE LAYER
# ============================================
RUN apk add --no-cache \
    # SSL/TLS certificates (mandatory for HTTPS)
    ca-certificates \
    
    # Timezone support
    tzdata \
    
    # Health check tool (wget for HTTP checks)
    wget \
    
    # DNS resolution tools
    bind-tools \
    
    # Signal handling wrapper (tini)
    tini \
    
    # Remove apk cache after install
    && rm -rf /var/cache/apk/*

# ============================================
# SECURITY: Configure timezone (Europe/Berlin)
# DO NOT install tzdata again - it's already installed above
# ============================================
RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    echo "Europe/Berlin" > /etc/timezone

# ============================================
# SECURITY: Update CA certificates (critical for HTTPS)
# ============================================
RUN update-ca-certificates 2>/dev/null || true

# ============================================
# SECURITY: Create non-root user and group
# Zot does NOT need root privileges
# ============================================
RUN addgroup -S zot && \
    adduser -S zot -u 1000 -G zot -h /var/lib/zot -s /bin/false

# ============================================
# FILESYSTEM: Create required directories
# ============================================
RUN mkdir -p /etc/zot \
    /var/lib/zot/storage \
    /var/lib/zot/cache \
    /var/lib/zot/backups \
    /var/log/zot \
    /tmp \
    && chmod 700 /var/lib/zot/storage /var/lib/zot/cache /var/lib/zot/backups /var/log/zot \
    && chown zot:zot /etc/zot /var/lib/zot/storage /var/lib/zot/cache /var/lib/zot/backups /var/log/zot /tmp

# ============================================
# BINARY: Copy Zot binary from builder
# ============================================
COPY --from=builder --chown=zot:zot /zot /usr/local/bin/zot

# ============================================
# CONFIGS: Copy configuration files
# ============================================
COPY --chown=zot:zot docker/zot-registry/config.yml /etc/zot/config.yml
COPY --chown=zot:zot docker/zot-registry/passwd /etc/zot/passwd

# ============================================
# SECURITY: Set proper permissions
# ============================================
RUN chmod 600 /etc/zot/config.yml /etc/zot/passwd && \
    chmod 500 /usr/local/bin/zot && \
    chown zot:zot /usr/local/bin/zot && \
    touch /var/log/zot/zot.log && \
    chown zot:zot /var/log/zot/zot.log

# ============================================
# SECURITY: Cleanup temporary files
# ============================================
RUN rm -rf /tmp/* 2>/dev/null || true

# ============================================
# SWITCH: To non-root user
# ============================================
USER zot
WORKDIR /var/lib/zot

# ============================================
# ENVIRONMENT: Default configuration
# ============================================
ENV ZOT_CUSTOM_CERT_DIR=/etc/zot/certs \
    ZOT_REGISTRY_HTTP_PORT=8080 \
    ZOT_REGISTRY_HTTPS_PORT=8443 \
    ZOT_LOG_LEVEL=info \
    ZOT_LOG_OUTPUT=/var/log/zot/zot.log \
    ZOT_STORAGE_ROOT=/var/lib/zot/storage \
    ZOT_CACHE_ROOT=/var/lib/zot/cache \
    ZOT_ENABLE_ANALYTICS=false \
    ZOT_ENABLE_METRICS=true \
    ZOT_ENABLE_VULNERABILITY_SCANNING=false

# ============================================
# IMAGE METADATA (OCI Compliant)
# ============================================
LABEL maintainer="tobias.weiss@opendesk-edu.org"
LABEL org.opencontainers.image.title="${IMAGE_TITLE}"
LABEL org.opencontainers.image.description="${IMAGE_DESCRIPTION}"
LABEL org.opencontainers.image.vendor="openDesk Edu"
LABEL org.opencontainers.image.license="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/opendesk-edu/opendesk-nix"
LABEL org.opencontainers.image.url="https://opendesk-edu.org"
LABEL org.opencontainers.image.documentation="https://github.com/opendesk-edu/opendesk-nix/docs/BEST_PRACTICES.md"
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL org.opencontainers.image.revision="${GIT_COMMIT:-unknown}"
LABEL org.opencontainers.image.created="${BUILD_DATE:-$(date -u +'%Y-%m-%dT%H:%M:%SZ')}"
LABEL org.opencontainers.image.architectures="amd64"
LABEL org.opencontainers.image.os="linux"
LABEL opendesk.org.component="registry"
LABEL opendesk.org.purpose="caching"
LABEL opendesk.org.hardened="true"
LABEL opendesk.org.zot.version="${ZOT_VERSION}"
LABEL opendesk.org.oci.compliant="true"
LABEL opendesk.org.pull_through.enabled="true"
LABEL opendesk.org.pull_through.registries="ghcr.io,registry.gitlab.opencode.de"

# ============================================
# NETWORKING: Exposed ports
# ============================================
EXPOSE 8080 8443

# ============================================
# VOLUMES: Persistent storage
# ============================================
VOLUME /var/lib/zot/storage /var/lib/zot/cache /var/lib/zot/backups /var/log/zot

# ============================================
# HEALTH CHECKS
# ============================================
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wget -q --spider --no-check-certificate http://localhost:8080/v2/ || \
         test -f /var/lib/zot/storage/.initialized || \
         exit 1

# ============================================
# STARTUP: Entrypoint with tini for signal handling
# ============================================
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/zot", "serve", "/etc/zot/config.yml"]
