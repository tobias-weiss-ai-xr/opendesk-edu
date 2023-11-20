<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<h1>Monitoring</h1>

This document will cover how you can enable observability with Prometheus based monitoring and Grafana dashboards, as
well as the overall status of monitoring integration.

<!-- TOC -->
  * [Technology](#technology)
  * [Defaults](#defaults)
  * [Metrics](#metrics)
  * [Alerts](#alerts)
  * [Dashboards for Grafana](#dashboards-for-grafana)
  * [Components](#components)
<!-- TOC -->

## Technology

We provide integration into the Prometheus based monitoring.
Together with
[kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) you
easily leverage the full potential of open-source cloud-native observability stack.

Before enabling the following options, you need to install the respective CRDs from the kube-prometheus-stack
repository or prometheus operator.

## Defaults

All configurable options and their defaults can be found in
[`monitoring.yaml`](../helmfile/environments/default/monitoring.yaml).

## Metrics

To deploy podMonitor and serviceMonitor custom resources, enable it by:

```yaml
prometheus:
  serviceMonitors:
    enabled: true
  podMonitors:
    enabled: true
```

## Alerts

Some helm-charts provide a default set of prometheusRules for alerting, enable it by:

```yaml
prometheus:
  prometheusRules:
    enabled: true
```

## Dashboards for Grafana

To deploy optional ConfigMaps with Grafana dashboards, enable it by:

```yaml
grafana:
  dashboards:
    enabled: true
```

## Components
| Component | Metrics (pod- or serviceMonitor)  | Alerts (prometheusRule) | Dashboard (Grafana) |
|:----------|-----------------------------------|-------------------------|---------------------|
| Collabora | :white_check_mark:                | :white_check_mark:      | :white_check_mark:  |
| Nextcloud | :white_check_mark:                | :x:                     | :x:                 |
