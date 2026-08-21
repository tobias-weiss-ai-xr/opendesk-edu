{ lib }:
let name = "dask"; image = "ghcr.io/daskdev/dask"; tag = "latest";
  port = 8787;
in
[ (lib.deployment { inherit name image tag port; })
  (lib.service { inherit name port; })
  (lib.ingressWithCert { inherit name; host = "dask.desk-test.uni-marburg.de"; inherit port; })
]
