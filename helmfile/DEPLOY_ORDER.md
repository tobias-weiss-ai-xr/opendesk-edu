# Deploy Stage Ordering

Apps are deployed in stages via helmfile level labels:

| Stage | Component | Description |
|-------|-----------|-------------|
| 010-infra | cert-manager, ingress-controller | Cluster infrastructure |
| 020-storage | rook-ceph, ceph-csi | Storage provisioners |
| 030-monitoring | kube-prometheus-stack, loki | Observability |
| 040-database | postgresql, mariadb | Database services |
| 050-components | All edu apps | Application layer |

Within each stage, apps are deployed in parallel.
Dependencies are resolved by stage ordering, not within-stage ordering.

## Adding a new app

Set the deployStage label to match the earliest stage your app depends on.
