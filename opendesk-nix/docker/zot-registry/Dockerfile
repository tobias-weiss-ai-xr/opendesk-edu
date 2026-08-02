# Hardened Zot Registry for openDesk Kubernetes Caching
# Target: registry.gitlab.opencode.de/umr/zot-registry:latest
# Purpose: Local sidecar registry for caching images on K3s cluster
# SPDX-License-Identifier: Apache-2.0
# Security: Hardened configuration for production use
# Maintainer: openDesk Edu Team

# ============================================
# STAGE 1: Builder
# ============================================
FROM alpine:3.20 as builder

# Install build dependencies
RUN apk add --no-cache --virtual .build-deps \
    go=1.21.0 \
    git \
    make \
    gcc \
    musl-dev

# Clone and build Zot with security flags
WORKDIR /build
RUN git clone https://github.com/zotregistry/zot.git . && \
    git checkout v2.0.0-rc4 && \
    cd cmd/zot && \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
      -ldflags="-w -s -extldflags '-static'" \
      -a \
      -installsuffix cgo \
      -o /zot .

# ============================================
# STAGE 2: Final Hardened Image
# ============================================
FROM alpine:3.20

# --- SECURITY: Install minimal required packages ---
RUN apk add --no-cache \
    # Runtime dependencies
    ca-certificates \
    tzdata \
    # Health check tools
    wget \
    # Signal handling for Zot
    tini \
    # DNS resolution
    bind-tools

# --- SECURITY: Update certificates ---
RUN update-ca-certificates 2>/dev/null || true

# --- SYSTEM: Configure timezone ---
RUN apk add --no-cache tzdata && \
    ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    echo "Europe/Berlin" > /etc/timezone && \
    apk del tzdata 2>/dev/null || true

# --- SECURITY: Create non-root user and group ---
RUN addgroup -S zot && \
    adduser -S zot -u 1000 -G zot -h /var/lib/zot -s /bin/false

# --- FILESYSTEM: Create required directories with proper permissions ---
RUN mkdir -p /etc/zot /var/lib/zot/storage /var/lib/zot/cache /var/log/zot /tmp && \
    chmod 700 /var/lib/zot/storage /var/lib/zot/cache /var/log/zot && \
    chown zot:zot /etc/zot /var/lib/zot/storage /var/lib/zot/cache /var/log/zot /tmp

# --- COPY: Binary from builder ---
COPY --from=builder /zot /usr/local/bin/zot
COPY --chown=zot:zot config.yml /etc/zot/config.yml
COPY --chown=zot:zot passwd /etc/zot/passwd

# --- SECURITY: Set proper permissions ---
RUN chmod 600 /etc/zot/config.yml /etc/zot/passwd && \
    chown zot:zot /usr/local/bin/zot && \
    touch /var/log/zot/zot.log && \
    chown zot:zot /var/log/zot/zot.log

# --- SECURITY: Cleanup ---
RUN rm -rf /var/cache/apk/* /tmp/* 2>/dev/null || true

# --- SWITCH: To non-root user ---
USER zot
WORKDIR /var/lib/zot

# ============================================
# IMAGE METADATA
# ============================================

# Expose registry ports
EXPOSE 8080 8443

# Health check - verify registry is responding
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q --spider --no-check-certificate http://localhost:8080/v2/ || exit 1

# Security labels (OCI compliant)
LABEL maintainer="tobias.weiss@hrz.uni-marburg.de"
LABEL org.opencontainers.image.title="Zot Registry (Hardened)"
LABEL org.opencontainers.image.description="Hardened Zot OCI Registry for openDesk Kubernetes caching with pull-through support"
LABEL org.opencontainers.image.vendor="openDesk Edu"
LABEL org.opencontainers.image.license="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/opendesk-edu/opendesk-nix"
LABEL org.opencontainers.image.url="https://opendesk-edu.org"
LABEL org.opencontainers.image.documentation="https://github.com/opendesk-edu/opendesk-nix/docs/BEST_PRACTICES.md"
LABEL org.opencontainers.image.version="2.0.0"
LABEL org.opencontainers.image.created=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
LABEL org.opencontainers.image.architectures="amd64"
LABEL org.opencontainers.image.os="linux"
LABEL opendesk.org.component="registry"
LABEL opendesk.org.purpose="caching"
LABEL opendesk.org.hardened="true"

# ============================================
# ENTRYPOINT: Use tini for proper signal handling
# ============================================
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/zot", "serve", "/etc/zot/config.yml"]
