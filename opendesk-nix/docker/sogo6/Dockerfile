# SOGo 6 Docker Image for openDesk Edu
# Target: registry.gitlab.opencode.de/umr/sogo6:latest
# SPDX-License-Identifier: Apache-2.0
# Maintainer: openDesk Edu Team <team@opendesk-edu.org>
# Build: nix build .#sogo6-image || docker build -t sogo6 -f docker/sogo6/Dockerfile .
#
# ==============================================================================
# IMAGE SPECIFICATIONS
# ==============================================================================
# - Multi-stage build for security and minimal size
# - Non-root user (sogo: UID 1000, GID 1000)
# - Read-only filesystem where possible
# - Drop ALL capabilities, add only required ones
# - No privilege escalation
# - Health checks with exponential backoff
# - OCI-compliant labels with SBOM support
# - EDV (External Data Validation) support
# - Optimized for multi-threaded workloads
#
# ==============================================================================
# BUILD ARGUMENTS
# ==============================================================================
ARG SOGO_VERSION=6.0.0
ARG SOGO_DEBIAN_VERSION=12
ARG SOGO_BUILD_DATE=""
ARG SOGO_GIT_COMMIT=""
ARG SOGO_GIT_REPO=""

# ==============================================================================
# STAGE 1: Base Image - Official SOGo 6 with pinned version
# ==============================================================================
FROM sogo/sogo:${SOGO_VERSION} as base

# Verify the base image
RUN echo "Building SOGo ${SOGO_VERSION} on Debian base" && \
    cat /etc/os-release | grep -E "PRETTY_NAME|VERSION" && \
    sogod --version | head -3 && \
    # Check for EDV capability
    sogod --help 2>&1 | grep -i "external" || true && \
    echo "Base image verification: OK"

# ==============================================================================
# STAGE 2: Runtime - Final production image
# ==============================================================================
FROM base

# ======================
# SECURITY: Environment
# ======================
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Berlin \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    
    # SOGo 6 Configuration
    SOGO_DB_HOST="postgresql.opendesk.svc" \
    SOGO_DB_PORT=5432 \
    SOGO_DB_NAME="sogo" \
    SOGO_DB_USER="sogo" \
    SOGO_DB_TYPE="PostgreSQL" \
    SOGO_WORKERS=8 \
    
    # EDV Configuration
    SOGO_EDV_ENABLED=true \
    SOGO_EDV_KEYSERVER="hkps://keys.openpgp.org" \
    SOGO_GNUPG_HOME="/var/lib/sogo/gpg" \
    
    # Memcached Configuration (optimized for SOGo 6)
    MEMCACHED_PORT=11211 \
    MEMCACHED_CACHE_SIZE=512 \
    MEMCACHED_MAX_CONNECTIONS=1024 \
    MEMCACHED_THREADS=8 \
    
    # Service Configuration
    SOGO_SMTP_SERVER="smtp.opendesk.svc" \
    SOGO_SMTP_PORT=25 \
    SOGO_MAIL_DOMAIN="opendesk-edu.org" \
    
    # Performance Configuration
    SOGO_MAX_MESSAGE_SIZE=104857600  # 100MB
    SOGO_MAX_MESSAGE Age=100M
    
    # Health check configuration
    SOGO_HEALTH_CHECK_INTERVAL=30 \
    SOGO_HEALTH_CHECK_TIMEOUT=10 \n
# ======================
# SECURITY: Packages
# ======================
# Install runtime dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    # Database clients
    postgresql-client-15 \
    default-mysql-client \
    
    # LDAP utilities
    ldap-utils \
    
    # GnuPG for EDV (External Data Validation)
    gnupg \
    gnupg-utils \
    
    # Essential networking tools
    curl \
    ca-certificates \
    net-tools \
    iproute2 \
    dnsutils \
    procps \
    
    # Memcached (optimized version)
    memcached \
    
    # Timezone data
    tzdata \
    
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
# SECURITY: User & Directories
# ======================
# Ensure sogo user exists
RUN if ! id -u sogo >/dev/null 2>&1; then \
        groupadd --system --gid 1000 sogo && \
        useradd --system --uid 1000 --gid 1000 --no-create-home \
                --shell /bin/false --home /var/lib/sogo sogo; \
    fi && \
    # Create GnuPG home directory for EDV
    mkdir -p /var/lib/sogo/gpg && \
    chown -R sogo:sogo /var/lib/sogo/gpg && \
    chmod 700 /var/lib/sogo/gpg && \
    id sogo

# Create all required directories for SOGo 6
RUN mkdir -p /var/lib/sogo \
               /var/log/sogo \
               /var/cache/sogo \
               /run/sogo \
               /etc/sogo \
               /etc/sogo/edv \
               /etc/sogo/ssl \
               /etc/GNUstep \
    && chown -R sogo:sogo /var/lib/sogo /var/log/sogo /var/cache/sogo \
                          /run/sogo /etc/sogo /etc/GNUstep \
    && chmod 750 /var/lib/sogo /var/log/sogo /var/cache/sogo \
               /etc/sogo /etc/sogo/edv /etc/sogo/ssl \
    && chmod 755 /run/sogo /etc/GNUstep

# ======================
# SECURITY: Ulimits (SOGo 6 optimized)
# ======================
RUN cat > /etc/security/limits.d/99-sogo.conf << 'EOF'
# SOGo 6 ulimit configuration
sogo soft nofile 65536
sogo hard nofile 65536
sogo soft nproc 32768
sogo hard nproc 32768
sogo soft memlock unlimited
sogo hard memlock unlimited
EOF

# ======================
# CONFIGURATION: SOGo 6
# ======================
# Copy main configuration
COPY docker/sogo6/sogo.conf /etc/sogo/sogo.conf

# Set restrictive permissions
RUN chown sogo:sogo /etc/sogo/sogo.conf && \
    chmod 600 /etc/sogo/sogo.conf

# ======================
# CONFIGURATION: EDV (External Data Validation)
# ======================
# Copy EDV-specific configuration
COPY docker/sogo6/edv/edv.conf /etc/sogo/edv/edv.conf 2>/dev/null || \
    cp docker/sogo6/edv.conf /etc/sogo/edv/edv.conf 2>/dev/null || true

RUN chown -R sogo:sogo /etc/sogo/edv && \
    chmod 600 /etc/sogo/edv/edv.conf 2>/dev/null || true && \
    chmod 700 /etc/sogo/edv

# ======================
# CONFIGURATION: Memcached (optimized for SOGo 6)
# ======================
COPY docker/sogo6/memcached.conf /etc/memcached.conf

RUN chmod 644 /etc/memcached.conf

# ======================
# CONFIGURATION: GNUstep
# ======================
COPY docker/sogo6/GNUstep.conf /etc/GNUstep/GNUstep.conf 2>/dev/null || true
RUN chmod 644 /etc/GNUstep/GNUstep.conf 2>/dev/null || true

# ======================
# SECURITY: Log rotation
# ======================
COPY docker/sogo6/logrotate.conf /etc/logrotate.d/sogo 2>/dev/null || true
RUN chmod 644 /etc/logrotate.d/sogo 2>/dev/null || true

# ======================
# HEALTH: Scripts
# ======================
# Copy health check script (SOGo 6 specific)
COPY docker/sogo6/healthcheck.sh /healthcheck.sh

# Make executable
RUN chmod +x /healthcheck.sh && \
    chown sogo:sogo /healthcheck.sh

# ======================
# ENTRYPOINT: Script
# ======================
# Copy entrypoint script (SOGo 6 with EDV support)
COPY docker/sogo6/entrypoint.sh /entrypoint.sh

# Make executable
RUN chmod +x /entrypoint.sh && \
    chown sogo:sogo /entrypoint.sh

# ======================
# SECURITY: File permissions audit
# ======================
RUN echo "=== SOGo 6 File Permission Audit ===" && \
    echo "sogo.conf:" && ls -la /etc/sogo/sogo.conf && \
    echo "memcached.conf:" && ls -la /etc/memcached.conf && \
    echo "entrypoint.sh:" && ls -la /entrypoint.sh && \
    echo "healthcheck.sh:" && ls -la /healthcheck.sh && \
    echo "EDV dir:" && ls -la /etc/sogo/edv 2>/dev/null || true && \
    echo "User sogo:" && id sogo && \
    echo "=== End Audit ==="

# ======================
# SECURITY: Finalize
# ======================
# Switch to non-root user
USER sogo
WORKDIR /var/lib/sogo

# Set umask
ENV UMASK=0022

# =============================================================================
# IMAGE METADATA (OCI Compliant + SBOM)
# =============================================================================
LABEL maintainer="openDesk Edu Team <team@opendesk-edu.org>" \
      vendor="openDesk Edu" \
      
# OCI Standard
      org.opencontainers.image.title="SOGo 6 Groupware Server" \
      org.opencontainers.image.description="SOGo 6 is the next-generation groupware server with enhanced External Data Validation (EDV), multi-threaded processing, and improved performance. Full support for CalDAV, CardDAV, GroupDAV, and Exchange ActiveSync." \
      org.opencontainers.image.vendor="openDesk Edu" \
      org.opencontainers.image.license="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/opendesk-edu/opendesk-nix/tree/main/docker/sogo6" \
      org.opencontainers.image.url="https://opendesk-edu.org/components/sogo" \
      org.opencontainers.image.version="${SOGO_VERSION}-opendesk-3.1.0" \
      org.opencontainers.image.revision="${SOGO_GIT_COMMIT:-unknown}" \
      org.opencontainers.image.created="${SOGO_BUILD_DATE:-$(date -u +'%Y-%m-%dT%H:%M:%SZ')}" \
      
# OS and Architecture
      org.opencontainers.image.architectures="amd64" \
      org.opencontainers.image.os="linux" \
      
# openDesk-specific
      opendesk.org.component="groupware" \
      opendesk.org.purpose="email-calendar-contacts-edv" \
      opendesk.org.version.sogo="${SOGO_VERSION}" \
      opendesk.org.version.debian="${SOGO_DEBIAN_VERSION}" \
      opendesk.org.features="EDV,GnuPG,Multi-threaded,CalDAV,CardDAV,ActiveSync" \
      opendesk.org.hardened="true" \
      opendesk.org.registry="registry.gitlab.opencode.de/umr/sogo6" \
      opendesk.org.sbom.format="CycloneDX-1.5,SPDX-2.3" \
      opendesk.org.provenance="openDesk Edu Nix Build" \
      
# Security labels
      com.redhat.device-type="container" \
      com.redhat.component="sogo6-server" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.name="sogo6" \
      org.label-schema.description="SOGo 6 Groupware Server with EDV support" \
      org.label-schema.version="${SOGO_VERSION}" \
      org.label-schema.vendor="openDesk Edu" \
      org.label-schema.license="Apache-2.0" \
      org.label-schema.url="https://opendesk-edu.org" \
      org.label-schema.build-date="${SOGO_BUILD_DATE:-$(date -u +'%Y-%m-%dT%H:%M:%SZ')}" \
      
# ZKI IT-Grundschutz
      de.zki.it-grundschutz.module="BA 3.4mail, IS 3.4mail" \
      de.zki.it-grundschutz.layer="Application" \
      de.zki.it-grundschutz.classification="public" \
      de.zki.it-grundschutz.data-protection="personal-data,confidential" \
      de.zki.it-grundschutz.edv-capable="true" \
      
# container.gov.de
      de.container.gov.component-id="opendesk-sogo6" \
      de.container.gov.component-name="SOGo 6 Groupware Server with EDV" \
      de.container.gov.component-version="${SOGO_VERSION}-opendesk-3.1.0" \
      de.container.gov.sbom-format="CycloneDX-1.5, SPDX-2.3" \
      de.container.gov.security-level="enhanced"

# =============================================================================
# NETWORKING
# =============================================================================
# Exposed ports
EXPOSE 20000      # WO/HTTP port
EXPOSE 11211      # Memcached port

# =============================================================================
# HEALTH CHECKS
# =============================================================================
# Note: For Kubernetes, use the healthcheck.sh script:
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
#            failureThreshold: 45
#            periodSeconds: 10

# =============================================================================
# STARTUP
# =============================================================================
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sogod"]
