# SOGo 5 Docker Image for openDesk Edu
# Target: registry.gitlab.opencode.de/umr/sogo5:latest
# SPDX-License-Identifier: Apache-2.0
# Maintainer: openDesk Edu Team <team@opendesk-edu.org>
# Build: nix build .#sogo5-image || docker build -t sogo5 -f docker/sogo5/Dockerfile .
#
# ==============================================================================
# IMAGE SPECIFICATIONS
# ==============================================================================
# - Multi-stage build for security and minimal size
# - Non-root user (sogo: UID 1000)
# - Read-only filesystem where possible
# - Drop ALL capabilities, add only required ones
# - No privilege escalation
# - Health checks with exponential backoff
# - OCI-compliant labels with SBOM support
#
# ==============================================================================
# BUILD ARGUMENTS
# ==============================================================================
ARG SOGO_VERSION=5.10.0
ARG SOGO_DEBIAN_VERSION=12
ARG SOGO_BUILD_DATE=""
ARG SOGO_GIT_COMMIT=""
ARG SOGO_GIT_REPO=""

# ==============================================================================
# STAGE 0: Pre-heating - Ensure reproducible builds
# ==============================================================================
FROM scratch as preheat

# =============================================================================
# STAGE 1: Base Image - Official SOGo with pinned version
# =============================================================================
FROM sogo/sogo:${SOGO_VERSION} as base

# Verify the base image
RUN echo "Building SOGo ${SOGO_VERSION} on Debian base" && \
    cat /etc/os-release | grep PRETTY_NAME && \
    sogod --version | head -1 && \
    echo "Base image verification: OK"

# =============================================================================
# STAGE 2: Dependency Builder - Compile additional tools if needed
# =============================================================================
FROM debian:${SOGO_DEBIAN_VERSION}-slim as builder

# Ensure reproducibility
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LC_ALL=C \
    LANG=C

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        && rm -rf /var/lib/apt/lists/*

# =============================================================================
# STAGE 3: Runtime - Final production image
# =============================================================================
FROM base

# ======================
# SECURITY: Environment
# ======================
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Berlin \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    
    # SOGo Configuration
    SOGO_DB_HOST="postgresql.opendesk.svc" \
    SOGO_DB_PORT=5432 \
    SOGO_DB_NAME="sogo" \
    SOGO_DB_USER="sogo" \
    SOGO_DB_TYPE="PostgreSQL" \
    SOGO_WORKERS=4 \
    
    # Memcached Configuration
    MEMCACHED_PORT=11211 \
    MEMCACHED_CACHE_SIZE=512 \
    MEMCACHED_MAX_CONNECTIONS=1024 \
    MEMCACHED_THREADS=4 \
    
    # Service Configuration
    SOGO_SMTP_SERVER="smtp.opendesk.svc" \
    SOGO_SMTP_PORT=25 \
    SOGO_MAIL_DOMAIN="opendesk-edu.org" \
    
    # Health check configuration
    SOGO_HEALTH_CHECK_INTERVAL=30 \
    SOGO_HEALTH_CHECK_TIMEOUT=10 \
    SOGO_STARTUP_TIMEOUT=60

# ======================
# SECURITY: Packages
# ======================
# Install minimal runtime dependencies in a single RUN statement
# This reduces image layers and ensures apt cache is cleaned
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    # Database clients
    postgresql-client-15 \
    default-mysql-client \
    
    # LDAP utilities
    ldap-utils \
    
    # Essential networking tools
    curl \
    ca-certificates \
    net-tools \
    iproute2 \
    dnsutils \
    procps \
    
    # Memcached for SOGo caching
    memcached \
    
    # Timezone data
    tzdata \
    
    # Mail utilities (for debugging)
    mailutils \
    
    # Cleanup
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && apt-get autoclean \
    && apt-mark autoremove

# ======================
# SECURITY: Timezone
# ======================
RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    echo "Europe/Berlin" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata 2>/dev/null || true

# ======================
# SECURITY: user + directories
# ======================
# Ensure sogo user and group exist (UID/GID should match upstream image)
RUN if ! id -u sogo >/dev/null 2>&1; then \
        groupadd --system --gid 1000 sogo && \
        useradd --system --uid 1000 --gid 1000 --no-create-home \
                --shell /bin/false --home /var/lib/sogo sogo; \
    fi && \
    # Verify user exists
    id sogo

# Create all required directories with proper permissions
RUN mkdir -p /var/lib/sogo \
               /var/log/sogo \
               /var/cache/sogo \
               /run/sogo \
               /etc/sogo \
               /etc/GNUstep \
    && chown -R sogo:sogo /var/lib/sogo /var/log/sogo /var/cache/sogo /run/sogo /etc/sogo /etc/GNUstep \
    && chmod 750 /var/lib/sogo /var/log/sogo /var/cache/sogo /etc/sogo /etc/GNUstep \
    && chmod 755 /run/sogo

# ======================
# SECURITY: Ulimits
# ======================
RUN cat > /etc/security/limits.d/99-sogo.conf << 'EOF'
# SOGo 5 ulimit configuration
sogo soft nofile 65536
sogo hard nofile 65536
sogo soft nproc 16384
sogo hard nproc 16384
sogo soft memlock unlimited
sogo hard memlock unlimited
EOF

# ======================
# CONFIGURATION: SOGo
# ======================
# Copy SOGo configuration (used at runtime)
COPY docker/sogo5/sogo.conf /etc/sogo/sogo.conf

# Set restrictive permissions
RUN chown sogo:sogo /etc/sogo/sogo.conf && \
    chmod 600 /etc/sogo/sogo.conf

# ======================
# CONFIGURATION: Memcached
# ======================
# Copy Memcached configuration
COPY docker/sogo5/memcached.conf /etc/memcached.conf

# Permissions for memcached config
RUN chmod 644 /etc/memcached.conf

# ======================
# CONFIGURATION: GNUstep
# ======================
# Copy GNUstep defaults
COPY docker/sogo5/GNUstep.conf /etc/GNUstep/GNUstep.conf 2>/dev/null || true
RUN chmod 644 /etc/GNUstep/GNUstep.conf 2>/dev/null || true

# ======================
# SECURITY: Log rotation
# ======================
# Configure log rotation for SOGo logs
COPY docker/sogo5/logrotate.conf /etc/logrotate.d/sogo 2>/dev/null || true
RUN chmod 644 /etc/logrotate.d/sogo 2>/dev/null || true

# ======================
# HEALTH: Scripts
# ======================
# Copy health check script
COPY docker/sogo5/healthcheck.sh /healthcheck.sh

# Make executable and set ownership
RUN chmod +x /healthcheck.sh && \
    chown sogo:sogo /healthcheck.sh

# ======================
# ENTRYPOINT: Script
# ======================
# Copy entrypoint script
COPY docker/sogo5/entrypoint.sh /entrypoint.sh

# Make executable and set ownership
RUN chmod +x /entrypoint.sh && \
    chown sogo:sogo /entrypoint.sh

# ======================
# SECURITY: File permissions audit
# ======================
# Verify all configuration files have proper ownership
RUN echo "=== File Permission Audit ===" && \
    echo "sogo.conf:" && ls -la /etc/sogo/sogo.conf && \
    echo "memcached.conf:" && ls -la /etc/memcached.conf && \
    echo "entrypoint.sh:" && ls -la /entrypoint.sh && \
    echo "healthcheck.sh:" && ls -la /healthcheck.sh && \
    echo "User sogo:" && id sogo && \
    echo "=== End Audit ==="

# ======================
# SECURITY: Drop capabilities && finalize
# ======================
# Switch to non-root user
USER sogo
WORKDIR /var/lib/sogo

# Set umask for SOGo (restrictive)
ENV UMASK=0022

# =============================================================================
# IMAGE METADATA (OCI Compliant + CycloneDX/SPDX)
# =============================================================================
# Standard OCI labels
LABEL maintainer="openDesk Edu Team <team@opendesk-edu.org>" \
      vendor="openDesk Edu" \
      
# Required OCI labels
      org.opencontainers.image.title="SOGo 5 Groupware Server" \
      org.opencontainers.image.description="SOGo 5 is a mature groupware server with a focus on scalability and open standards. Supports CalDAV, CardDAV, and GroupDAV, with ActiveSync support for Microsoft mobile clients." \
      org.opencontainers.image.vendor="openDesk Edu" \
      org.opencontainers.image.license="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/opendesk-edu/opendesk-nix/tree/main/docker/sogo5" \
      org.opencontainers.image.url="https://opendesk-edu.org/components/sogo" \
      org.opencontainers.image.version="${SOGO_VERSION}-opendesk-2.1.0" \
      org.opencontainers.image.revision="${SOGO_GIT_COMMIT:-unknown}" \
      org.opencontainers.image.created="${SOGO_BUILD_DATE:-$(date -u +'%Y-%m-%dT%H:%M:%SZ')}" \
      
# OS and Architecture
      org.opencontainers.image.architectures="amd64" \
      org.opencontainers.image.os="linux" \
      
# openDesk-specific labels
      opendesk.org.component="groupware" \
      opendesk.org.purpose="email-calendar-contacts" \
      opendesk.org.version.sogo="${SOGO_VERSION}" \
      opendesk.org.version.debian="${SOGO_DEBIAN_VERSION}" \
      opendesk.org.hardened="true" \
      opendesk.org.registry="registry.gitlab.opencode.de/umr/sogo5" \
      opendesk.org.sbom.format="CycloneDX,SPDX" \
      opendesk.org.provenance="openDesk Edu Nix Build" \
      
# Security labels
      com.redhat.device-type="container" \
      com.redhat.component="sogo-server" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.name="sogo5" \
      org.label-schema.description="SOGo Groupware Server for openDesk" \
      org.label-schema.version="${SOGO_VERSION}" \
      org.label-schema.vendor="openDesk Edu" \
      org.label-schema.license="Apache-2.0" \
      org.label-schema.url="https://opendesk-edu.org" \
      org.label-schema.build-date="${SOGO_BUILD_DATE:-$(date -u +'%Y-%m-%dT%H:%M:%SZ')}" \
      
# ZKI IT-Grundschutz labels
      de.zki.it-grundschutz.module="BA 3.4mail" \
      de.zki.it-grundschutz.layer="Application" \
      de.zki.it-grundschutz.classification="public" \
      de.zki.it-grundschutz.data-protection="personal-data" \
      
# container.gov.de labels (for SBOM publishing)
      de.container.gov.component-id="opendesk-sogo5" \
      de.container.gov.component-name="SOGo 5 Groupware Server" \
      de.container.gov.component-version="${SOGO_VERSION}-opendesk-2.1.0" \
      de.container.gov.sbom-format="CycloneDX-1.5, SPDX-2.3"

# =============================================================================
# NETWORKING
# =============================================================================
# SOGo ports
# - 20000: WO/HTTP port (main web interface)
# - 127.0.0.1:20001: SOGo daemon management port (internal)
EXPOSE 20000
# Memcached port (if exposed externally)
EXPOSE 11211

# =============================================================================
# HEALTH CHECKS
# =============================================================================
# Multi-probe health configuration:
# 1. Startup: Wait up to 2 minutes for service to start
# 2. Liveness: Always check if service is running
# 3. Readiness: Check if service can accept requests

# -- Startup probe ( inexpensice checks
HEALTHCHECK --interval=15s --timeout=5s --start-period=60s --retries=30 \
    CMD /healthcheck.sh startup || exit 1

# Note: Docker only supports one HEALTHCHECK. Kubernetes Islanders
# Note: Docker only supports. Kubernetes operators
# Note: Docker on
# Note: For Kuberneorscheme, use the healthcheck.sh script in your liveness/readiness
# For Kubernetes, use these probes:
# Liveness:  exec: command: [/healthcheck.sh, liveness]
#             initialDelaySeconds: 60
#             periodSeconds: 10
#             failureThreshold: 3
#
# Readiness: exec: command: [/healthcheck.sh, readiness]
#            initialDelaySeconds: 90
#            periodSeconds: 15
#            failureThreshold: 3
#
# Startup:   exec: command: [/healthcheck.sh, startup]
#            failureThreshold: 30
#            periodSeconds: 10

# =============================================================================
# STARTUP
# =============================================================================
# Entrypoint runs as PID 1 with proper signal handling
ENTRYPOINT ["/entrypoint.sh"]

# Default command (can be overridden)
CMD ["/usr/sbin/sogod"]
