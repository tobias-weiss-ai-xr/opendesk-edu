<!--
SPDX-FileCopyrightText: 2025 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<h1>Scaling</h1>

This document covers the possibilities to scale the applications in openDesk.

It provides rough benchmarks for configuring your own environment across various scale levels.
In production, resource demands are primarily driven by actual usage patterns and system load, especially the number of concurrently active users.
Consequently, we strongly recommend implementing monitoring and logging solutions to detect usage trends and enable timely intervention when needed.

| Application  | Recommendation | Note(s) |
| ------------ | -------------- | ------- |
| Collabora    | * 15 active users / CPU thread <br/> * 10 active users / Mbit/s <br/> * 50 MB RAM / active user | - |
| Element      | Per 10k users (no federation / open federation): <br/><br/> Homeserver: <br/> * 10 vCPU / 15 vCPU <br/> * 8150 MiB RAM / 11650  MiB RAM <br/><br/>Postgres: <br/> * 4 vCPU / 10 vCPU <br/> * 16 GiB RAM  / 32 GiB RAM | Required hardware resources really depend on federation vs. no federation |
| Cryptpad     | No large-scale deployments seen, minimum requirements: <br/> * 2 vCPU <br/> * 2 GB RAM <br/> * 20 GB storage (depending on planned usage) | Most of the computation is done client-side |
| Jitsi        | Jitsi-Meet server: <br/> * 4 vCPU <br/> 8 GB RAM <br/> <br/> For every 200 concurrent users one JVB with: <br/> * 8 vCPU <br/> * 8 GB RAM <br/><br/> Network link: <br/> * 10 Gbit/s per bridge <br/> * Should allow for 1000 4k streams, or 4000 720p streams | - |
| OpenProject  | * 4-6 vCPU per ~500 users <br/> * 6-8 GB per ~500 users <br/> * +20-50 GB storage per ~500 users, depending on workload and attachment storage <br/><br/> * Web Workers: +4 per ~500 users <br/> * Background Workers: +1-2 multithreaded workers per ~500 users, depending on workload | These values are guidelines and should be adjusted based on actual monitoring of resource usage. Scaling should prioritize CPU and RAM, prioritize scaling Web Workers first, followed by Background Workers and Disk Space as needed. |
| Open-Xchange | For ~200 users (64 concurrent users to App Suite & 128 users to Dovecot): <br/> * 10 vCPU <br/> * 58 GB RAM <br/> * 660 GB storage | - |
| XWiki        | Advise for small instances: <br> * 4 vCPU <br/> * 6GB RAM | - |
| Nextcloud    | Up to 5,000 / more than 5,000 users: <br/> * 4 to 20 application servers with 8 cores and 32GB / 64GB RAM each <br/> * 2/4 DB servers with 8 / 16 cores and 64GB / 128GB RAM each (/ plus DB load balancer) <br/> * 1 / 2 HAproxy load balancer with 2 cores and 16GB RAM | - |

# Upstream information

While scaling services horizontally is the ideal solution, information about vertical scaling is helpful
when defining the application's resources, see [`resources.yaml.gotmpl`](../helmfile/environments/default/resources.yaml.gotmpl) for references.

Linked below is documentation related to scaling for upstream applications, where publically available:

- [Collabora Online Technical Documentation](https://mautic.collaboraoffice.com/asset/60:collabora-online-technical-information-pdf)
- [OpenProject System Requirements](https://www.openproject.org/docs/installation-and-operations/system-requirements/)
- [XWiki Performance](https://www.xwiki.org/xwiki/bin/view/Documentation/AdminGuide/Performances/)
- [Element Requirements and Recommendations](https://ems-docs.element.io/books/element-server-suite-documentation-lts-2404/page/requirements-and-recommendations)
- [Jitsi DevOps Guide (scalable setup)](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-scalable/), [Jitsi Meet Needs](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-requirements/)