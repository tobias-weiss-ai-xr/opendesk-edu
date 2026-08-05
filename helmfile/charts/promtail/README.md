<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Promtail - Log Agent for Loki
**SPDX-License-Identifier: AGPL-3.0-or-later**

## Overview
This chart deploys Promtail as a log collection agent that ships logs from Kubernetes pods to Loki for centralized logging.

## Description
Promtail is an agent which ships the contents of local logs to a central location. It is typically deployed as a DaemonSet to collect logs from all nodes in the cluster.

## Features
- **File-based log collection**: Direct access to pod log files
- **Kubernetes integration**: Automatic service discovery and metadata labeling
- **Efficient shipping**: Batching and compression for optimal performance
- **Multi-tenant support**: Can ship to multiple Loki tenants

## Configuration

### Log Collection
- **Source**: `/var/log/pods/<namespace>*/*/*.log`
- **Target**: `http://loki:3100/loki/api/v1/push`
- **Format**: Structured JSON with Kubernetes metadata

### Resource Limits  
- **CPU**: 50m request, 500m limit per node
- **Memory**: 64Mi request, 512Mi limit per node

## Deployment
The chart deploys Promtail as a DaemonSet, ensuring one instance per node for complete log coverage.

```bash
helm install promtail ./chart -n opendesk --values values.yaml
```

## Dependencies
- Requires Loki service (typically in same namespace)
- Needs host filesystem access for log files
- RBAC configured for pod log discovery

## Namespace Support
Currently configured for opendesk namespace logs but can be expanded with label selectors for multi-namespace deployment.

## Resource Requirements
For optimal performance on large clusters, consider:
- Configuring node filters for targeted log collection
- Implementing log sampling to reduce volume
- Tuning scrape intervals and batch sizes