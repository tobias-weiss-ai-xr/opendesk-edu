<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Loki - Log Aggregation and Visualization
**SPDX-License-Identifier: AGPL-3.0-or-later**

## Overview
This chart deploys Loki for centralized log aggregation and visualization as part of the openDesk Edu platform logging infrastructure.

## Description
Loki is a horizontally-scalable, highly-available, multi-tenant log aggregation system inspired by Prometheus. It provides full logging capabilities, including:

- Log aggregation from multiple sources
- Timeline-based log exploration with powerful query language (LogQL)
- Metrics and alerting integration
- High availability and scalability

## Components
The chart deploys:
- **Loki server**: Core log aggregation service with persistence
- **Storage**: Ceph RBD storage for log persistence (50Gi by default)
- **ServiceMonitor**: Prometheus integration for component monitoring

## Configuration

### Storage
- **Storage Class**: `ceph-rbd-ssd` (fast SSD storage for databases)
- **Size**: 50Gi (configurable)
- **Retention**: 31 days (configurable)

### Resource Limits
- **CPU**: 100m request, 1 CPU limit
- **Memory**: 256Mi request, 2Gi limit

### Ingestion Limits
- **Rate**: 50MB/sec
- **Burst**: 100MB

## Usage
This chart is part of the openDesk Edu logging infrastructure and is typically used with:
- **Promtail**: Log collection agent
- **Grafana**: Visualization and dashboard integration
- **Prometheus**: Metrics collection and alerting

## Deployment
```bash
helm install loki ./chart -n opendesk --values values.yaml
```

## Dependencies
- Requires Ceph RBD storage class
- Optionally integrates with existing Prometheus setup
- Designed to work within opendesk namespace

## Security
- Uses standard Kubernetes RBAC
- Integrates with existing TLS certificate infrastructure
- Follows openDesk security best practices