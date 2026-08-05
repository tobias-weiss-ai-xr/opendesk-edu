# File Storage Migration Guide: Switching Between Nextcloud and OpenCloud

## Overview

OpenDesk supports two file storage solutions: **Nextcloud** (mature, legacy) and **OpenCloud** (modern, CS3-native). This guide helps system administrators and decision-makers understand, configure, and migrate between these solutions effectively.

Whether you're adopting OpenCloud for its modern architecture or maintaining Nextcloud for its stability, this guide covers coexistence, switching strategies, and best practices.

## Architecture

Nextcloud and OpenCloud run in parallel within the same `opendesk` Kubernetes namespace. Both use Keycloak OIDC for authentication but operate independently. Access is controlled via Keycloak group memberships, allowing users to be assigned to one or both solutions.

```ascii
+-------------------+       +-------------------+
|                   |       |                   |
|    Nextcloud      |       |    OpenCloud      |
|                   |       |                   |
+--------+----------+       +--------+----------+
         |                             |
         | (SAML)                   | (OIDC)
         v                             v
+-------------------------------------------+
|                                           |
|                Keycloak                  |
|                                           |
+--------+-----------------------------------+
         |
         | (User Groups: Fileshare / FileshareCloud)
         v
+-------------------------------------------+
|                                           |
|                Nubus Portal               |
| (Tiles: Nextcloud / OpenCloud)            |
|                                           |
+--------+-----------------------------------+
         |
         | (OX Capability: filestorage_owncloud_oauth)
         v
+-------------------------------------------+
|                                           |
|              Open-Xchange                 |
|                                           |
+-------------------------------------------+
```

### Key Components

- **Namespace**: `opendesk` (shared by both solutions)
- **Authentication**: Keycloak OIDC (both solutions)
- **Portal Access**: Nubus portal tiles controlled by Keycloak group memberships
- **OX Integration**: Optional integration with either or both solutions via `filestorage_owncloud_oauth` capability

## Key Differences Between Nextcloud and OpenCloud

| Feature                | Nextcloud                          | OpenCloud                              |
|------------------------|------------------------------------|----------------------------------------|
| **Technology**         | PHP-based                          | Go-based (CS3/OCM)                     |
| **Authentication**     | SAML (via Keycloak)                | OIDC (via Keycloak)                    |
| **Architecture**       | Monolithic                         | Microservice (CS3-native)              |
| **Ecosystem**          | Mature, extensive app ecosystem    | Modern, ScienceMesh/OCM support        |
| **User Access Group**  | `managed-by-attribute-Fileshare`   | `managed-by-attribute-FileshareCloud`  |
| **OX Integration**     | Yes (via `filestorage_owncloud`)   | Yes (via `filestorage_owncloud_oauth`)

## User Access Control

Access to Nextcloud or OpenCloud is controlled via **Keycloak group memberships**. Users can be assigned to one or both solutions, allowing for gradual migration.

### Keycloak Groups

| Solution   | Group Name                          |
|------------|-------------------------------------|
| Nextcloud  | `managed-by-attribute-Fileshare`    |
| OpenCloud  | `managed-by-attribute-FileshareCloud` |

### Assigning Users

1. Access the **Keycloak Admin Console**
   - URL: `https://keycloak.opendesk.example.com/auth/admin`
   - Select the `opendesk` realm

2. Navigate to **Groups**
   - Choose the group (`managed-by-attribute-Fileshare` or `managed-by-attribute-FileshareCloud`)
   - Select **Members** > **Add member** > Choose users

3. Verify access in the **Nubus portal**
   - Users in `managed-by-attribute-Fileshare` see the Nextcloud tile
   - Users in `managed-by-attribute-FileshareCloud` see the OpenCloud tile
   - Users in both groups see both tiles

### Common Scenarios

| Scenario               | Group Assignment Strategy                          |
|------------------------|----------------------------------------------------|
| Full Nextcloud access  | Only `managed-by-attribute-Fileshare`              |
| Full OpenCloud access  | Only `managed-by-attribute-FileshareCloud`         |
| Phased migration       | Both groups (then remove Nextcloud group later)    |

## OX Integration with OpenCloud

Open-Xchange integrates with OpenCloud using OAuth2 authentication via Keycloak. This enables users to access OpenCloud storage directly from the OX App Suite interface.

### Key Integration Points

1. **OAuth2 Flow**: Open-Xchange uses Keycloak for authentication and token management
2. **Capability**: The `filestorage_owncloud_oauth` capability enables OpenCloud integration
3. **Server URL**: OpenCloud is accessed via `https://opencloud.opendesk.example.com`

### Configuration

The integration is configured in `values-openxchange.yaml.gotmpl`:

```yaml
# Enable OpenCloud integration capability
com.openexchange.capability.filestorage_owncloud_oauth: "true"

# OpenCloud server URL for OX
io.ox.owncloud//server: "https://{{ .Values.global.hosts.opencloud }}.{{ .Values.global.domain }}/"

# OIDC/OAuth2 configuration
com.openexchange.oidc.clientId: "opendesk-oxappsuite"
com.openexchange.oidc.clientSecret: {{ .Values.secrets.keycloak.clientSecret.as8oidc | quote }}
com.openexchange.oidc.opIssuer: "https://{{ .Values.global.hosts.keycloak }}.{{ .Values.global.domain }}/realms/{{ .Values.platform.realm }}"
```

### Integration Workflow

1. **Authentication**: Keycloak issues OAuth2 tokens during OX login
2. **Token Exchange**: OX uses tokens to authenticate with OpenCloud
3. **File Access**: Users manage OpenCloud files directly from OX
4. **Context Mapping**: User context (`oxContextIDNum`) is passed via token claims

### Conditional Integration

The integration is enabled only when OpenCloud is active:

```yaml
# helmfile/apps/open-xchange/values-openxchange.yaml.gotmpl
{{- if .Values.apps.opencloud.enabled }}
com.openexchange.capability.filestorage_owncloud_oauth: "true"
{{- end }}
```

## Admin Configuration

Administrators control which file storage solution is enabled via Helm values and Keycloak configuration. OpenCloud can be enabled or disabled independently of Nextcloud, allowing for phased migration.

### Enabling/Disabling OpenCloud

OpenCloud is controlled via the `opendesk_main.yaml.gotmpl` file:

```yaml
# helmfile/environments/default/opendesk_main.yaml.gotmpl
apps:
  opencloud:
    enabled: true  # Set to false to disable OpenCloud
    namespace: ~
```

After changing this value, apply the configuration:

```bash
helmfile sync
```

### Keycloak Client Configuration

The OpenCloud Keycloak client is defined in `values-opendesk-keycloak-bootstrap.yaml.gotmpl`:

```yaml
# helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl
config:
  clientAccessRestrictions:
    opencloud:
      client: "opendesk-opencloud"
      scope: "opendesk-opencloud-scope"
      role: "opendesk-opencloud-access-control"
      group: "managed-by-attribute-FileshareCloud"
```

The client secret is managed via secrets:

```yaml
secrets:
  keycloak:
    clientSecret:
      opencloud: "{{ .Values.secrets.keycloak.clientSecret.opencloud }}"
```

### Portal Tile Configuration

The OpenCloud portal tile is configured in `theme.yaml.gotmpl`:

```yaml
# helmfile/environments/default/theme.yaml.gotmpl
portalTiles:
  fileshareOpencloud: {{ readFile "./../../files/theme/opencloud/favicon.svg" | b64enc | quote }}
```

### Open-Xchange Integration

Open-Xchange integrates with OpenCloud via OAuth2 and the `filestorage_owncloud_oauth` capability. This is configured in `values-openxchange.yaml.gotmpl`:

```yaml
# helmfile/apps/open-xchange/values-openxchange.yaml.gotmpl
com.openexchange.capability.filestorage_owncloud_oauth: "true"

# OpenCloud server URL
io.ox.owncloud//server: "https://{{ .Values.global.hosts.opencloud }}.{{ .Values.global.domain }}/"
```

### OX Capability Configuration

The Open-Xchange capability for OpenCloud is enabled conditionally:

```yaml
# helmfile/apps/open-xchange/values-openxchange.yaml.gotmpl
{{- if .Values.apps.opencloud.enabled }}
com.openexchange.capability.filestorage_owncloud_oauth: "true"
{{- end }}
```

This ensures OX only attempts to integrate with OpenCloud when it is enabled.

## Migration Strategies

Migrating between Nextcloud and OpenCloud requires careful planning to avoid disruption. Since there is no automated tool, files must be transferred manually.

### Recommended Migration Workflow

1. **Prepare the transition**
   - Communicate timelines, expectations, and training opportunities
   - Familiarize users with OpenCloud's interface and features

2. **Enable dual access**
   - Assign users to both `managed-by-attribute-Fileshare` and `managed-by-attribute-FileshareCloud` groups
   - This allows access to both platforms during the transition

3. **Transfer files**
   - Download from Nextcloud: `https://files.opendesk.example.com`
   - Upload to OpenCloud: `https://opencloud.opendesk.example.com`
   - For large files (>500MB), use split archives or WebDAV

4. **Validate data**
   - Confirm all critical files are present in OpenCloud
   - Verify file permissions and sharing settings

5. **Complete cutover**
   - Remove users from the `managed-by-attribute-Fileshare` group
   - Optionally disable Nextcloud

### WebDAV Access

Both solutions support WebDAV for programmatic file access:

| Solution   | WebDAV URL                                      | Notes                                  |
|------------|-------------------------------------------------|----------------------------------------|
| Nextcloud  | `https://files.opendesk.example.com/remote.php/dav/files/` | Requires SAML authentication via Keycloak |
| OpenCloud  | `https://opencloud.opendesk.example.com/dav/`               | Requires OIDC authentication via Keycloak |

### Open Cloud Mesh (OCM)

For future cross-instance sharing, consider Open Cloud Mesh (OCM):

- Enables sharing between OpenCloud instances across organizations
- Supports ScienceMesh federation for research collaboration
- Requires additional configuration of CS3 APIs

### Common Migration Issues

| Issue                          | Cause                                      | Solution                                  |
|--------------------------------|--------------------------------------------|--------------------------------------------|
| Missing files post-migration   | Incomplete transfer                        | Verify transfer completeness               |
| Broken sharing links           | Permissions not preserved                  | Reconfigure shares in OpenCloud            |
| Slow performance               | Large files or high load                   | Schedule off-peak transfers                |
| Authentication failures        | Incorrect group assignments                | Verify Keycloak group memberships          |
| OX integration errors          | Capability not enabled                     | Check `filestorage_owncloud_oauth` setting |

## Troubleshooting

### Pod Status and Logs

Check OpenCloud pod status:

```bash
kubectl -n opendesk get pods -l app.kubernetes.io/name=opencloud
```

View OpenCloud logs:

```bash
kubectl -n opendesk logs -l app.kubernetes.io/name=opencloud --tail=50
```

### PVC Binding Issues

Verify PVC binding:

```bash
kubectl -n opendesk get pvc -l app.kubernetes.io/name=opencloud
```

### Keycloak Authentication Issues

1. Verify Keycloak client exists:

   ```bash
   kubectl -n opendesk exec -it ums-keycloak-0 -- /opt/keycloak/bin/kcadm.sh get clients -r opendesk | grep opendesk-opencloud
   ```

2. Check client secret matches:

   ```bash
   kubectl -n opendesk get secret opendesk-keycloak -o jsonpath='{.data.opencloud-client-secret}' | base64 -d
   ```

3. Verify user group membership:

   ```bash
   kubectl -n opendesk exec -it ums-keycloak-0 -- /opt/keycloak/bin/kcadm.sh get users -r opendesk -q username=<USERNAME> --fields groups
   ```

### OX Integration Failures

1. Verify capability is enabled:

   ```bash
   kubectl -n opendesk exec -it ox-core-mw-0 -- grep filestorage_owncloud_oauth /opt/open-xchange/etc/Capabilities.properties
   ```

2. Check OX server URL:

   ```bash
   kubectl -n opendesk exec -it ox-core-mw-0 -- grep owncloud.server /opt/open-xchange/etc/UiSettings.properties
   ```

3. Test OAuth2 flow:

   ```bash
   curl -v "https://opencloud.opendesk.example.com/.well-known/openid-configuration"
   ```

## References
