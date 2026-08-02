# SOGo 6 Docker Image for openDesk
# Target: registry.gitlab.opencode.de/umr/sogo6:latest
# Base: Official SOGo 6 image with openDesk hardening
# SPDX-License-Identifier: Apache-2.0
# Maintainer: openDesk Edu Team
# Version: 6.0.0
# Build: nix build .#sogo6-image || docker build -t registry.gitlab.opencode.de/umr/sogo6:latest -f docker/sogo6/Dockerfile .

# ============================================
# ARGUMENTS - Configurable build parameters
# ============================================
ARG SOGO_VERSION=6.0.0
ARG BUILD_DATE
ARG GIT_COMMIT
ARG GIT_BRANCH

# ============================================
# STAGE 1: Base Image
# ============================================
FROM sogo/sogo:${SOGO_VERSION} as base

# ============================================
# STAGE 2: Final Production Image
# ============================================
FROM base

# --- SECURITY: Switch to root for package installation ---
USER root

# --- SECURITY: Install minimal required packages in single layer ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Database clients (PostgreSQL)
    postgresql-client-15 \
    
    # Database clients (MariaDB/MySQL)
    default-mysql-client \
    
    # LDAP tools for user authentication
    ldap-utils \
    
    # Essential utilities
    curl \
    ca-certificates \
    tzdata \
    net-tools \
    iproute2 \
    procps \
    
    # Memcached for caching (required for SOGo 6)
    memcached \
    
    # Timezone configuration
    && ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime \
    && echo "Europe/Berlin" > /etc/timezone \
    
    # Cleanup: Remove apt cache in same layer to reduce image size
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && apt-get autoclean

# --- SECURITY: Ensure sogo user exists ---
RUN if ! id -u sogo >/dev/null 2>&1; then \
    groupadd --system sogo && \
    useradd --system --no-create-home --shell /bin/false --ingroup sogo sogo; \
    fi

# --- FILESYSTEM: Create directories with proper permissions ---
RUN mkdir -p /var/lib/sogo /var/log/sogo /etc/sogo /run/sogo && \
    chown -R sogo:sogo /var/lib/sogo /var/log/sogo /etc/sogo /run/sogo && \
    chmod -R 750 /var/lib/sogo /var/log/sogo /etc/sogo && \
    chmod 755 /run/sogo

# --- FILESYSTEM: Ensure SOGo directories have correct permissions ---
RUN chown -R sogo:sogo /usr/lib/SOGo /usr/lib-GNUstep /etc/sogo

# --- CONFIGURATION: Copy openDesk-specific configuration ---
COPY docker/sogo6/sogo.conf /etc/sogo/sogo.conf
COPY docker/sogo6/memcached.conf /etc/memcached.conf

# --- SECURITY: Set proper permissions for configuration files ---
RUN chown sogo:sogo /etc/sogo/sogo.conf && \
    chmod 640 /etc/sogo/sogo.conf && \
    chmod 644 /etc/memcached.conf

# --- SYSTEM: Configure ulimits for SOGo 6 ---
RUN cat > /etc/security/limits.d/99-sogo.conf << 'EOF'
sogo soft nofile 65536
sogo hard nofile 65536
sogo soft nproc 16384
sogo hard nproc 16384
EOF

# --- SYSTEM: Configure sysctl for better performance ---
RUN cat > /etc/sysctl.d/99-sogo.conf << 'EOF'
# Increase file descriptor limits
fs.file-max = 100000

# Network performance
net.core.somaxconn = 4096
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 5
EOF

# --- SWITCH: To non-root user for security ---
USER sogo
WORKDIR /var/lib/sogo

# ============================================
# IMAGE METADATA (OCI Compliant)
# ============================================

LABEL maintainer="tobias.weiss@hrz.uni-marburg.de"
LABEL org.opencontainers.image.title="SOGo 6 Groupware Server"
LABEL org.opencontainers.image.description="SOGo 6 Groupware Server for openDesk with LDAP, MySQL/PostgreSQL, and Memcached support"
LABEL org.opencontainers.image.vendor="openDesk Edu"
LABEL org.opencontainers.image.license="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/opendesk-edu/opendesk-nix"
LABEL org.opencontainers.image.url="https://opendesk-edu.org"
LABEL org.opencontainers.image.documentation="https://github.com/opendesk-edu/opendesk-nix/docs/BEST_PRACTICES.md"
LABEL org.opencontainers.image.version="${SOGO_VERSION}-opendesk-1"
LABEL org.opencontainers.image.revision="${GIT_COMMIT:-unknown}"
LABEL org.opencontainers.image.created="${BUILD_DATE:-unknown}"
LABEL org.opencontainers.image.architectures="amd64"
LABEL org.opencontainers.image.os="linux"
LABEL opendesk.org.component="groupware"
LABEL opendesk.org.purpose="email-calendar-contacts"
LABEL opendesk.org.hardened="true"
LABEL opendesk.org.sogo.version="6.x"

# ============================================
# NETWORKING
# ============================================

EXPOSE 20000 127.0.0.1:11211

# ============================================
# HEALTH CHECKS
# ============================================

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -sSf http://localhost:20000/SOGo || \
         pg_isready -h postgresql.opendesk.svc -p 5432 -U sogo 2>/dev/null || \
         exit 1

# ============================================
# STARTUP: Entrypoint for multi-process setup
# ============================================

COPY docker/sogo6/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && chown sogo:sogo /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sogod"]
