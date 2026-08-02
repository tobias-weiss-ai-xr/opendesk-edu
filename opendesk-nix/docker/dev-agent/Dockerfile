# openDesk Dev Agent Kubernetes Operator
# Target: registry.gitlab.opencode.de/umr/dev-agent:latest
# Maintained by: openDesk Edu Team
# SPDX-License-Identifier: Apache-2.0

# Use the operator image we already built
FROM ghcr.io/tobias-weiss-ai-xr/opendesk-dev-agent-operator:latest

# Set maintainer
LABEL maintainer="tobias.weiss@hrz.uni-marburg.de"
LABEL org.opencontainers.image.title="Dev Agent"
LABEL org.opencontainers.image.description="Kubernetes Operator for self-healing openDesk deployment"
LABEL org.opencontainers.image.vendor="openDesk Edu"
LABEL org.opencontainers.image.license="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/opendesk-edu/opendesk-dev-agent-operator"
LABEL org.opencontainers.image.url="https://opendesk-edu.org"

# Switch to root
USER root

# Add openDesk-specific configuration
RUN mkdir -p /etc/opendesk-dev-agent && \
    cat > /etc/opendesk-dev-agent/config.yaml << 'EOF'
# openDesk Dev Agent Configuration
apiVersion: opendesk-dev-agent.tobias-weiss-ai-xr.github.com/v1
kind: HealthPolicy
metadata:
  name: opendesk-health-monitor
  namespace: opendesk
spec:
  checkInterval: 5m
  namespaces:
    - opendesk
    - opendesk-edu
    - default
  componentHealth:
    - name: keycloak
      type: StatefulSet
      minReadyReplicas: 1
    - name: nextcloud
      type: Deployment
      minReadyReplicas: 1
    - name: mariadb
      type: StatefulSet
      minReadyReplicas: 1
    - name: postgres
      type: StatefulSet
      minReadyReplicas: 1
  podHealth:
    crashLoopThreshold: 5
    errorThreshold: 3
    warningThreshold: 2
---
apiVersion: opendesk-dev-agent.tobias-weiss-ai-xr.github.com/v1
kind: RepairStrategy
metadata:
  name: opendesk-repair-strategy
  namespace: opendesk
spec:
  enabled: true
  repairActions:
    - type: restart
      conditions:
        - crashLoopBackOff
        - error
        - waiting
    - type: recreate
      conditions:
        - imagePullBackOff
        - errImagePull
    - type: scale
      targetReplicas: 2
      conditions:
        - highLoad
  maxRepairsPerHour: 12
  cooldownPeriod: 30m
  targets:
    - "keycloak*"
    - "nextcloud*"
    - "mariadb*"
    - "postgres*"
    - "*sogo*"
EOF

# Add optimization for openDesk cluster
RUN cat > /etc/opendesk-dev-agent/k8s-optimizations.sh << 'SCRIPT'
#!/bin/bash
# K3s-specific optimizations for the devi agent

# Set resource limits for the operator itself
cat > /tmp/operator-resources.yaml << 'YAML'
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
YAML

# Enable K3s-specific features
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
    echo "K3s detected - applying optimizations"
    # Add node affinity for control plane
    cat > /tmp/node-affinity.yaml << 'YAML'
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node-role.kubernetes.io/control-plane
                operator: In
                values:
                - "true"
            - matchExpressions:
              - key: node-role.kubernetes.io/master
                operator: In
                values:
                - "true"
YAML
fi
SCRIPT

chmod +x /etc/opendesk-dev-agent/k8s-optimizations.sh

# Set permissions
RUN chmod 644 /etc/opendesk-dev-agent/config.yaml && \
    chown -R root:root /etc/opendesk-dev-agent

# Switch to non-root user (operator default is 65532)
USER 65532

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -sSf http://localhost:8080/healthz || exit 1

# Readiness check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -sSf http://localhost:8080/readyz || exit 1

# Default command - override with openDesk-specific args
CMD ["/usr/local/bin/manager"]
ENTRYPOINT ["/usr/local/bin/manager"]
