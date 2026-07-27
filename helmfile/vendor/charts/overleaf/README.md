# overleaf Chart

This is an OCI-based chart that needs to be downloaded manually.

To vendor this chart:
```bash
helm pull oci://<registry>/overleaf --version <version> --untar --untardir=vendor/charts/overleaf
```
