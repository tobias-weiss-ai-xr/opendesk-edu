# Migrating from Helmfile to Nix

## Why Migrate?

- Pure evaluation → no "failed to render values file" errors
- Caching → instant rebuild for unchanged services
- Composable → services are pure Nix functions
- flake.lock → all dependencies pinned by hash

## Migration Steps

### 1. Generate Nix module (automatic)
```bash
python3 scripts/helmfile2nix.py helmfile/charts/mariadb/values.yaml > nix/k8s/mariadb.nix
```

### 2. Build and compare
```bash
# Build with Nix
cd nix && nix build .#mariadb
cat result | yq -P > /tmp/nix-mariadb.yaml

# Build with Helmfile
helmfile -f helmfile.yaml.gotmpl -e edu template --skip-deps | yq > /tmp/helmfile-mariadb.yaml

# Compare
diff /tmp/nix-mariadb.yaml /tmp/helmfile-mariadb.yaml
```

### 3. Add missing features
If the Nix output differs, add missing features to the lib/k8s.nix helpers
or customize the service module.

### 4. Switch
```bash
nix build .#mariadb
cat result | kubectl apply -f -
```

## Running Nix alongside Helmfile
Both can coexist. Nix-managed services use `app.kubernetes.io/managed-by: nix`
while Helmfile services use `Helm`. No conflicts.
