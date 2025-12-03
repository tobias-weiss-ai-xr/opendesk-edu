<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<h1>Monitoring</h1>

This document will cover how you can enable observability with Prometheus-based monitoring and Grafana dashboards as
well as the overall status of the monitoring integration.

<!-- TOC -->
* [Technology](#technology)
* [Defaults](#defaults)
* [Metrics](#metrics)
* [Alerts](#alerts)
* [Dashboards for Grafana](#dashboards-for-grafana)
* [Component overview](#component-overview)
<!-- TOC -->

# Technology

openDesk includes integration with Prometheus-based monitoring.

Together with [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack), you can easily leverage the full potential of the open-source cloud-native observability stack.

Before enabling the following options, you need to install the respective custom resource definitions (CRDs) from the kube-prometheus-stack repository which should at least include the Prometheus Operator.

# Defaults

All configurable options and their defaults can be found in
[`monitoring.yaml.gotmpl`](../helmfile/environments/default/monitoring.yaml.gotmpl).

# Metrics

To deploy `podMonitor` and `serviceMonitor` custom resources, enable them by:

```yaml
monitoring:
  prometheus:
    serviceMonitors:
      enabled: true
    podMonitors:
      enabled: true
```
```

# Alerts

openDesk ships with a set of Prometheus alerting rules that are specific to the operation of openDesk.
Some of these are created by our partners while others are defined in [opendesk-alerts](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-alerts).

All alert rules are deployed as [PrometheusRule](https://prometheus-operator.dev/docs/api-reference/api/#monitoring.coreos.com/v1.PrometheusRule) and can be enabled like this:

```yaml
monitoring:
  prometheus:
    prometheusRules:
      enabled: true
```

# Dashboards for Grafana

If your Grafana instance is deployed via kube-prometheus-stack, or you have deployed the [Sidecar for datasources](https://github.com/grafana/helm-charts/blob/main/charts/grafana/README.md#sidecar-for-datasources), openDesk can make dashboards available via ConfigMap resources. 

Enable the functionality with the following snippet:

```yaml
monitoring:
  grafana:
    dashboards:
      enabled: true
```

Please find further details in the [related Helm chart](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-dashboards).

# Component overview

| Component | Metrics (pod- or serviceMonitor) | Alerts (prometheusRule) | Dashboard (Grafana) |
|:----------|----------------------------------|-------------------------|---------------------|
| Collabora | :white_check_mark:               | :white_check_mark:      | :white_check_mark:  |
| Nextcloud | :white_check_mark:               | :x:                     | :x:                 |
