# kasmvnc Chart

This is an OCI-based chart that needs to be downloaded manually.

To vendor this chart:
```bash
helm pull oci://<registry>/kasmvnc --version <version> --untar --untardir=vendor/charts/kasmvnc
```
