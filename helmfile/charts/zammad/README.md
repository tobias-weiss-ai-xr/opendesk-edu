# Zammad

A Helm chart for deploying [Zammad](https://zammad.com/) (v7.0) service desk / ticketing system with PostgreSQL and Elasticsearch.

## Prerequisites

- Kubernetes 1.29+
- Helm 3
- PV provisioner supporting ReadWriteMany access mode
- Sufficient cluster resources for Elasticsearch

## Installing the Chart

```bash
helm repo add opendesk-edu https://codeberg.org/opendesk-edu/opendesk-edu
helm install my-release opendesk-edu/zammad
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `zammad.image` | Zammad container image | `ghcr.io/zammad/zammad` |
| `zammad.tag` | Image tag | `latest` |
| `zammad.port` | Container port | `3000` |
| `zammad.replicas` | Number of replicas | `1` |
| `zammad.db.host` | PostgreSQL host | `""` (auto-set by subchart) |
| `zammad.db.user` | Database username | `zammad` |
| `zammad.elasticsearch.host` | Elasticsearch host | `""` (auto-set by subchart) |
| `zammad.volumes.data.size` | Data volume size | `1Gi` |
| `zammad.resources.requests.cpu/memory` | Pod resource requests | `200m / 512Mi` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.hosts[0].host` | Ingress hostname | `helpdesk.opendesk.example.com` |
| `postgresql.enabled` | Deploy bundled PostgreSQL | `true` |
| `elasticsearch.enabled` | Deploy bundled Elasticsearch | `true` |
