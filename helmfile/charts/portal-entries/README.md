# Portal Entries

Provisions portal tile entries in LDAP for collab-services. Each entry creates a tile in the openDesk portal navigation.

## How it Works

1. Each entry is defined in `values.yaml` with `id`, `displayName`, `description`, `url`
2. The chart generates LDIF files as a ConfigMap
3. The LDIF is applied via `ldapadd` (manual) or the `apply.sh` script

## Adding a New Portal Tile

Add an entry to `values.yaml`:

```yaml
entries:
  - id: my-service
    displayName:
      en: My Service
      de: Mein Dienst
    description:
      en: Service description
      de: Dienstbeschreibung
    url: https://my-service.example.com
```

## Applying to LDAP

```bash
# From a pod with ldapadd access:
kubectl exec -it ums-ldap-server-primary-0 -- bash
ldapadd -x -H ldap://localhost \
  -D "cn=admin,dc=swp-ldap,dc=internal" -W \
  -f /path/to/entry.ldif
```

## Linking to Portal Navigation

Entries must be added to the portal's central navigation. See `entries/portal-central-navigation.ldif` for the required LDAP modify operation.