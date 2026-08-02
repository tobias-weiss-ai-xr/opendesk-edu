# SOGo 5 Docker Image for openDesk
# Target: registry.gitlab.opencode.de/umr/sogo5:latest
# Base: Official SOGo 5 image with openDesk hardening
# SPDX-License-Identifier: Apache-2.0
# Maintainer: openDesk Edu Team
# Build: nix build .#sogo5-image || docker build -t registry.gitlab.opencode.de/umr/sogo5:latest -f docker/sogo5/Dockerfile .

# ============================================
# STAGE 1: Base Image with pinned version
# ============================================
ARG SOGO_VERSION=5.10.0
FROM sogo/sogo:${SOGO_VERSION} as base

# ============================================
# STAGE 2: Builder for additional components
# ============================================
FROM debian:12-slim as builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# STAGE 3: Final Production Image
# ============================================
FROM base

# --- SECURITY: Install minimal required packages ---
# Use single RUN to reduce layers and ensure cleanup
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Database clients (for health checks and connections)
    postgresql-client-15 \
    default-mysql-client \
    
    # LDAP tools
    ldap-utils \
    
    # Essential utilities
    curl \
    ca-certificates \
    tzdata \
    net-tools \
    iproute2 \
    procps \
    
    # For SOGo LDAP cache
    memcached \
    
    # Timezone configuration
    && ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime \
    && echo "Europe/Berlin" > /etc/timezone \
    
    # Cleanup apt cache
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && apt-get autoclean

# --- SECURITY: Create and configure sogo user ---
# Verify sogo user exists, if not create it
RUN if ! id -u sogo >/dev/null 2>&1; then \
    groupadd --system sogo && \
    useradd --system --no-create-home --shell /bin/false --ingroup sogo sogo; \
    fi

# --- FILESYSTEM: Create data directories with proper permissions ---
RUN mkdir -p /var/lib/sogo /var/log/sogo /etc/sogo /run/sogo && \
    chown -R sogo:sogo /var/lib/sogo /var/log/sogo /etc/sogo /run/sogo && \
    chmod -R 750 /var/lib/sogo /var/log/sogo /etc/sogo && \
    # Ensure proper permissions for runtime directory
    chmod 755 /run/sogo

# --- CONFIGURATION: SOGo configuration for openDesk ---
# Use environment variables for sensitive data and service discovery
COPY docker/sogo5/sogo.conf /etc/sogo/sogo.conf

# Set permissions for configuration
RUN chown sogo:sogo /etc/sogo/sogo.conf && \
    chmod 640 /etc/sogo/sogo.conf

# --- CONFIGURATION: Memcached for SOGo ---
COPY docker/sogo5/memcached.conf /etc/memcached.conf
RUN chmod 644 /etc/memcached.conf

# --- SECURITY: Set proper ownership for all SOGo directories ---
RUN chown -R sogo:sogo /usr/lib/SOGo /usr/lib-GNUstep /etc/sogo && \
    chmod -R 750 /usr/lib/SOGo /usr/lib-GNUstep

# --- SYSTEM: Configure ulimits for SOGo ---
RUN cat > /etc/security/limits.d/99-sogo.conf << 'EOF'
sogo soft nofile 65536
sogo hard nofile 65536
sogo soft nproc 16384
sogo hard nproc 16384
EOF

# --- SWITCH: To sogo user for security ---
USER sogo
WORKDIR /var/lib/sogo

# ============================================
# IMAGE METADATA (OCI Compliant)
# ============================================

LABEL maintainer="tobias.weiss@hrz.uni-marburg.de"
LABEL org.opencontainers.image.title="SOGo 5 Groupware Server"
LABEL org.opencontainers.image.description="SOGo 5 Groupware Server for openDesk with LDAP and MySQL/PostgreSQL support"
LABEL org.opencontainers.image.vendor="openDesk Edu"
LABEL org.opencontainers.image.license="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/opendesk-edu/opendesk-nix"
LABEL org.opencontainers.image.url="https://opendesk-edu.org"
LABEL org.opencontainers.image.version="${SOGO_VERSION}-opendesk-1"
LABEL org.opencontainers.image.revision="${GIT_COMMIT:-unknown}"
LABEL org.opencontainers.image.created="${BUILD_DATE:-unknown}"
LABEL org.opencontainers.image.architectures="amd64"
LABEL org.opencontainers.image.os="linux"
LABEL opendesk.org.component="groupware"
LABEL opendesk.org.purpose="email-calendar-contacts"
LABEL opendesk.org.hardened="true"

# ============================================
# NETWORKING
# ============================================

EXPOSE 20000 127.0.0.1:20001

# ============================================
# HEALTH CHECKS
# ============================================

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -sSf http://localhost:20000/SOGo || \
         pg_isready -h postgresql.opendesk.svc -p 5432 -U sogo 2>/dev/null || \
         exit 1

# ============================================
# STARTUP: Init script for multi-process setup
# ============================================

COPY docker/sogo5/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && chown sogo:sogo /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sogod"]
