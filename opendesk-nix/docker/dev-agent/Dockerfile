# openDesk Dev Agent Kubernetes Operator
# Target: registry.gitlab.opencode.de/umr/dev-agent:latest
# Base: Built from opendesk-dev-agent-operator with hardening
# SPDX-License-Identifier: Apache-2.0
# Maintainer: openDesk Edu Team
# Version: 1.2.0
# Build: nix build .#dev-agent-image || docker build -t registry.gitlab.opencode.de/umr/dev-agent:latest -f docker/dev-agent/Dockerfile .

# ============================================
# ARGUMENTS - Configurable build parameters
# ============================================
ARG OPERATOR_VERSION=1.2.0
ARG BUILD_DATE
ARG GIT_COMMIT
ARG GIT_BRANCH

# ============================================
# STAGE 1: Build Go binary from source
# ============================================
FROM golang:1.19-alpine3.18 AS builder

# Install required build dependencies
RUN apk add --no-cache \
    ca-certificates \
    git \
    make \
    gcc \
    musl-dev \
    linux-headers

# Set working directory
WORKDIR /workspace

# Clone the operator repository
RUN git clone https://github.com/opendesk-edu/opendesk-dev-agent-operator.git . && \
    git checkout v${OPERATOR_VERSION}

# Build the operator binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -a \
    -installsuffix cgo \
    -ldflags "-w -s -X 'github.com/opendesk-edu/opendesk-dev-agent-operator/cmd.Version=${OPERATOR_VERSION}' \
             -X 'github.com/opendesk-edu/opendesk-dev-agent-operator/cmd.BuildDate=${BUILD_DATE:-unknown}' \
             -X 'github.com/opendesk-edu/opendesk-dev-agent-operator/cmd.GitCommit=${GIT_COMMIT:-unknown}' \
             -X 'github.com/opendesk-edu/opendesk-dev-agent-operator/cmd.GitBranch=${GIT_BRANCH:-unknown}'" \
    -o /usr/local/bin/manager \
    ./cmd/main.go

# ============================================
# STAGE 2: Final Production Image
# ============================================
FROM alpine:3.18

# ============================================
# SECURITY: Create non-root user
# ============================================
RUN addgroup --system opendesk && \
    adduser --system --ingroup opendesk --no-create-home --shell /bin/false opendesk

# ============================================
# SYSTEMS: Install minimal runtime dependencies
# ============================================
RUN apk add --no-cache \
    ca-certificates \
    curl \
    bash \
    tzdata \
    && rm -rf /var/cache/apk/*

# Configure timezone
RUN apk add --no-cache --virtual .timezone && \
    cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    echo "Europe/Berlin" > /etc/timezone && \
    apk del .timezone

# ============================================
# FILESYSTEM: Create directories
# ============================================
RUN mkdir -p /home/opendesk/.kube /var/log/opendesk /tmp && \
    chown opendesk:opendesk /home/opendesk/.kube /var/log/opendesk && \
    chmod 755 /var/log/opendesk && \
    chmod 700 /home/opendesk/.kube

# ============================================
# BINARY: Copy operator binary from builder
# ============================================
COPY --from=builder --chown=opendesk:opendesk /usr/local/bin/manager /usr/local/bin/manager

# ============================================
# CONFIGS: default configurations
# ============================================
COPY docker/dev-agent/config.yaml /etc/opendesk-dev-agent/config.yaml
COPY docker/dev-agent/entrypoint.sh /entrypoint.sh
COPY docker/dev-agent/healthcheck.sh /healthcheck.sh

RUN chmod +x /entrypoint.sh /healthcheck.sh && \
    chown opendesk:opendesk /entrypoint.sh /healthcheck.sh && \
    chown opendesk:opendesk /etc/opendesk-dev-agent/config.yaml && \
    chmod 644 /etc/opendesk-dev-agent/config.yaml && \
    chmod 755 /entrypoint.sh /healthcheck.sh

# ============================================
# SECURITY: permissions
# ============================================
RUN chmod 500 /usr/local/bin/manager && \
    chown opendesk:opendesk /usr/local/bin/manager

# ============================================
# SWITCH: non-root user
# ============================================
USER opendesk
WORKDIR /home/opendesk

# ============================================
# ENVIRONMENT: defaults
# ============================================
ENV OPERATOR_NAME=opendesk-dev-agent \
    OPERATOR_NAMESPACE=opendesk \
    OPERATOR_LOG_LEVEL=info \
    OPERATOR_WATCH_NAMESPACES=opendesk,opendesk-edu,default \
    OPERATOR_DISABLE_PI_MEMORY=true \
    OPERATOR_ENABLE_LEADER_ELECTION=false \
    OPERATOR_METRICS.Bind_ADDRESS=:8080 \
    OPERATOR_HEALTH_PROBE.Bind_ADDRESS=:8081 \
    K8S_CLUSTER_TYPE=k3s

# ============================================
# IMAGE METADATA
# ============================================
LABEL maintainer="tobias.weiss@opendesk-edu.org"
LABEL org.opencontainers.image.title="openDesk Dev Agent Operator"
LABEL org.opencontainers.image.description="Kubernetes Operator for self-healing openDesk deployment with automatic monitoring and repair capabilities"
LABEL org.opencontainers.image.vendor="openDesk Edu"
LABEL org.opencontainers.image.license="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/opendesk-edu/opendesk-dev-agent-operator"
LABEL org.opencontainers.image.url="https://opendesk-edu.org"
LABEL org.opencontainers.image.documentation="https://github.com/opendesk-edu/opendesk-dev-agent-operator/README.md"
LABEL org.opencontainers.image.version="${OPERATOR_VERSION}"
LABEL org.opencontainers.image.revision="${GIT_COMMIT:-unknown}"
LABEL org.opencontainers.image.created="${BUILD_DATE:-unknown}"
LABEL org.opencontainers.image.architectures="amd64"
LABEL org.opencontainers.image.os="linux"
LABEL opendesk.org.component="operator"
LABEL opendesk.org.purpose="self-healing"
LABEL opendesk.org.hardened="true"
LABEL opendesk.org.k8s.version="1.25+"

# ============================================
# NETWORKING
# ============================================
EXPOSE 8080 8081 9443

# ============================================
# VOLUMES
# ============================================
VOLUME /tmp /var/log/opendesk /home/opendesk/.kube

# ============================================
# HEALTH CHECKS
# ============================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
    CMD /healthcheck.sh || exit 1

# ============================================
# STARTUP: Entrypoint
# ============================================
ENTRYPOINT ["/entrypoint.sh"]
CMD ["--debug", "--disable-pi-memory", "--watch-namespace=$(OPERATOR_WATCH_NAMESPACES)", 
     "--zap-log-level=$(OPERATOR_LOG_LEVEL)", "--zap-encoder=json", 
     "--leader-elect=$(OPERATOR_ENABLE_LEADER_ELECTION)", "--metrics-addr=$(OPERATOR_METRICS.Bind_ADDRESS)"]
