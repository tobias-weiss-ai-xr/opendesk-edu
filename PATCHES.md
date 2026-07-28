# Upstream Patch Tracking

Charts and images that were forked or patched from upstream sources.

## Charts

| Chart | Upstream | Our Changes | Status |
|-------|----------|-------------|--------|
| mariadb | Bitnami mariadb 20.2.2 | Replaced with direct StatefulSet + official `mariadb:11.4` image. Supports ILIAS-optimized config. | Replaced |
| bookstack | Bitnami mariadb (subchart) | Replaced with direct StatefulSet. APP_KEY via secret. DAC_OVERRIDE fix. | Replaced |
| ilias | Bitnami mariadb + mariadb-galera | Both replaced with direct StatefulSet. nubus-common inlined. | Replaced |
| planka | Bitnami postgresql | Disabled. Uses shared postgresql via ExternalName service. | Replaced |
| intercom-service | nubus-common → bitnami/common | Both inlined into `_helpers.tpl` (14 functions). | Inlined |
| limesurvey | Bitnami mariadb | Replaced with direct StatefulSet. | Replaced |
| typo3 | Bitnami mariadb | Replaced with direct StatefulSet. | Replaced |
| zammad | Bitnami postgresql + elasticsearch | Disabled. External DB config. | Replaced |
| grommunio | Bitnami mariadb + redis | Disabled. External cache/DB config. | Replaced |

## Images

| Image | Upstream | Our Changes | Dockerfile |
|-------|----------|-------------|------------|
| mariadb | `docker.io/library/mariadb:11.4.4` | ILIAS-optimized my.cnf. `mysqladmin` symlinks. | `images/mariadb/Dockerfile` |
| ilias-shibboleth | `srsolutions/ilias:9-php8.2-apache` | Added `libapache2-mod-shib` + `mod_ssl` + self-signed certs. | `images/ilias-shibboleth/Dockerfile` |
| moodle-shib | Ubuntu 22.04 base | Full Moodle 4.4 + Apache + PHP 8.1 + Shibboleth SP. | `images/moodle-shib/Dockerfile` |
| bookstack | `linuxserver/bookstack` | Pinned by digest. No code changes. | Mirror only |
| drawio | `jgraph/drawio` | Pinned by digest. | Mirror only |
| excalidraw | `excalidraw/excalidraw` | Pinned by digest. | Mirror only |
| self-service-password | `ltbproject/self-service-password` | Pinned by digest. | Mirror only |
| planka | `ghcr.io/plankanban/planka` | Pinned by digest. | Mirror only |

## Tracking upstream

- Charts are versioned in `helmfile/charts/<name>/Chart.yaml`
- When upstream releases a new version, check our diff against theirs
- Run: `git diff --stat upstream/main -- helmfile/charts/<name>/`
