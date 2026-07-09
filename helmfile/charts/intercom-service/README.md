# intercom-service

![Version: 2.1.0](https://img.shields.io/badge/Version-2.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.4](https://img.shields.io/badge/AppVersion-1.4-informational?style=flat-square)

intercom service, short ICS, is used to allow inter component API usage from the user's webbrowser

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Univention |  | <https://www.univention.de/> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://artifacts.software-univention.de/nubus/charts | nubus-common | ^0.11.x |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| additionalAnnotations | object | `{}` | Additional custom annotations to add to all deployed objects. |
| additionalLabels | object | `{}` | Additional custom labels to add to all deployed objects. |
| affinity | object | `{}` | Affinity for pod assignment. Ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity Note: podAffinityPreset, podAntiAffinityPreset, and nodeAffinityPreset will be ignored when it's set. |
| containerSecurityContext.allowPrivilegeEscalation | bool | `false` | Enable container privileged escalation. |
| containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Security capabilities for container. |
| containerSecurityContext.enabled | bool | `true` | Enable security context. |
| containerSecurityContext.privileged | bool | `false` |  |
| containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mounts the container's root filesystem as read-only. |
| containerSecurityContext.runAsGroup | int | `1000` | Process group id. |
| containerSecurityContext.runAsNonRoot | bool | `true` | Run container as a user. |
| containerSecurityContext.runAsUser | int | `1000` | Process user id. |
| containerSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` | Disallow custom Seccomp profile by setting it to RuntimeDefault. |
| extraVolumeMounts | list | `[]` | Optionally specify an extra list of additional volumeMounts. |
| extraVolumes | list | `[]` | Optionally specify an extra list of additional volumes. |
| fullnameOverride | string | `""` | Provide a name to substitute for the full names of resources. |
| global.domain | string | `""` |  |
| global.imagePullPolicy | string | `nil` | Define an ImagePullPolicy.  Ref.: https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy  "IfNotPresent" => The image is pulled only if it is not already present locally.udm-rest-api.secretRef "Always" => Every time the kubelet launches a container, the kubelet queries the container image registry to             resolve the name to an image digest. If the kubelet has a container image with that exact digest cached             locally, the kubelet uses its cached image; otherwise, the kubelet pulls the image with the resolved             digest, and uses that image to launch the container. "Never" => The kubelet does not try fetching the image. If the image is somehow already present locally, the            kubelet attempts to start the container; otherwise, startup fails. |
| global.imagePullSecrets | list | `[]` | Credentials to fetch images from private registry. Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  imagePullSecrets:   - "docker-registry"  |
| global.imageRegistry | string | `"artifacts.software-univention.de"` | Container registry address. |
| global.subDomains.keycloak | string | `""` |  |
| global.subDomains.portal | string | `"portal"` |  |
| ics.default | object | `{"domain":"example.com","protocol":"https"}` | Default settings which are used for all services if they are not overriden for a specific service. |
| ics.default.domain | string | `"example.com"` | Domain which will be added for all subdomains for apps. It will be overriden by the specific service settings if set. |
| ics.default.protocol | string | `"https"` | Protocol which will be used to connect to apps. It will be overriden by the specific service settings if set. |
| ics.enableSessionCookie | bool | `false` | Enable session cookie (transient cookie). If enabled, the session cookie will be deleted at the end of the browser session. Otherwise, the session will be a rolling session (reset every time the user is active). |
| ics.issuerBaseUrl | string | `""` | Base URL of issuer. |
| ics.keycloak.enabled | bool | `true` |  |
| ics.keycloak.realm | string | `"souvap"` | Configured Realm for authentication. |
| ics.keycloak.subdomain | string | `"id"` | Subdomain with "ics.default.protocol" and "ics.default.domain". Mutual exclusive with "url". |
| ics.keycloak.url | string | `""` | URL as FQDN. Mutual exclusive with "subdomain". |
| ics.logLevel | string | `"INFO"` | Log level. |
| ics.matrix.auth.applicationServiceSecret | string | `nil` | Application Service secret. Either this value or an existing Secret has to be specified. |
| ics.matrix.auth.existingSecret.keyMapping.password | string | `nil` | The key to retrieve the application service secret from the secret. Setting this value allows to use a key with a different name. |
| ics.matrix.auth.existingSecret.name | string | `nil` | The name of an existing Secret to use for retrieving the Matrix application service secret. |
| ics.matrix.enabled | bool | `true` | Enable Matrix. |
| ics.matrix.serverName | string | `"matrix"` | Name of matrix server. |
| ics.matrix.subdomain | string | `"matrix"` | Subdomain with "ics.default.protocol" and "ics.default.domain". Mutual exclusive with "url". |
| ics.matrix.url | string | `""` | URL as FQDN. Mutual exclusive with "subdomain". |
| ics.nextcloud | object | `{"audience":"ncoidc","enabled":true,"origin":"fs","originUrl":"","subdomain":"fs","url":""}` | Nextcloud file service connection settings. |
| ics.nextcloud.audience | string | `"ncoidc"` | Audience. |
| ics.nextcloud.enabled | bool | `true` | Enable Nextcloud integration. |
| ics.nextcloud.origin | string | `"fs"` | Origin of nextcloud with "ics.default.protocol" and "ics.default.domain". Mutual exclusive with "originUrl". |
| ics.nextcloud.originUrl | string | `""` | Origin of Nextcloud as FQDN. Mutual exclusive with "origin". |
| ics.nextcloud.subdomain | string | `"fs"` | Subdomain of Nextcloud with "ics.default.protocol" and "ics.default.domain". Mutual exclusive with "url". |
| ics.nextcloud.url | string | `""` | URL of Nextcloud as FQDN. Mutual exclusive with "subdomain". |
| ics.nordeck.enabled | bool | `true` | Enable Nordeck's meeting widget bot. |
| ics.nordeck.mode | string | `"test"` | Widget mode. |
| ics.nordeck.subdomain | string | `"meetings-widget-bot"` | Subdomain with "ics.default.protocol" and "ics.default.domain". Mutual exclusive with "url". |
| ics.nordeck.url | string | `""` | URL as FQDN. Mutual exclusive with "subdomain". |
| ics.oidc.clientSecret | string | `nil` | OIDC Client Secret Either this value or an existing Secret has to be specified. |
| ics.oidc.existingSecret.keyMapping.clientSecret | string | `nil` | The key to retrieve the application service secret from the secret. Setting this value allows to use a key with a different name. |
| ics.oidc.existingSecret.name | string | `nil` | The name of an existing Secret to use for retrieving the OIDC client secret. |
| ics.oidc.id | string | `"intercom"` | OIDC ClientID. |
| ics.originRegex | string | `""` | Origin Regex settings. The originRegex is used to validate the origin of the incoming requests. If the origin does not match the regex, ICS will not handle CORS correctly and will not set Access-Control-Allow-Origin header in the proxied request. |
| ics.portal.auth.existingSecret.keyMapping.sharedSecret | string | `nil` | The key to retrieve the shared secret from the secret. Setting this value allows to use a key with a different name. |
| ics.portal.auth.existingSecret.name | string | `nil` | The name of an existing Secret to use for retrieving the shared secret to use with the Portal Server. |
| ics.portal.auth.sharedSecret | string | `nil` | Portal Server shared secret used to retrieve the `navigation.json` for a given user. This requires the portal server central navigation to be enabled. Either this value or an existing Secret has to be specified. |
| ics.portal.enabled | bool | `true` | Enable Univention Portal integration. |
| ics.portal.subdomain | string | `"portal"` | Subdomain with "ics.default.protocol" and "ics.default.domain". Mutual exclusive with "url". |
| ics.portal.url | string | `""` | Origin of Univention Portal as FQDN. Mutual exclusive with "subdomain". |
| ics.proxy | bool | `false` | Proxy settings. |
| ics.redis.auth.existingSecret.keyMapping.password | string | `nil` | The key to retrieve the password from the secret. Setting this value allows to use a key with a different name. |
| ics.redis.auth.existingSecret.name | string | `nil` | The name of an existing Secret to use for retrieving the password to use with the Redis cache service. |
| ics.redis.auth.password | string | `nil` | Redis cache service password. Either this value or an existing Secret has to be specified. |
| ics.redis.auth.username | string | `""` | Redis cache service username. |
| ics.redis.host | string | `"redis-headless"` | Redis cache service host. |
| ics.redis.port | string | `"6379"` | Redis cache service port. |
| ics.redis.ssl.customca | string | `""` | CustomCA certificate for Redis connection |
| ics.redis.ssl.enabled | bool | `false` | Enable Redis SSL connection |
| ics.redis.ssl.mTLS | object | `{"clientCert":"","clientKey":"","enabled":false,"existingSecret":{"name":"intercom-service-redis-client-credentials"}}` | Optional configuration of mutual TLS. The following values are required in that case, clientCert and clientKey or a tls secret containing both. |
| ics.redis.ssl.mTLS.clientCert | string | `""` | Client certificate for the Redis connection |
| ics.redis.ssl.mTLS.clientKey | string | `""` | Client key for the Redis connection |
| ics.redis.ssl.mTLS.enabled | bool | `false` | Enable Redis SSL connection using mTLS |
| ics.redis.ssl.mTLS.existingSecret.name | string | `"intercom-service-redis-client-credentials"` | Name of the secret that contains the client tls.crt and tls.key |
| ics.redis.ssl.pathCA | string | `"/etc/ssl/certs/redis-custom-CA.pem"` | Optional. Path to the Redis custom CA |
| ics.session.existingSecret.keyMapping.secret | string | `nil` | The key to retrieve the Intercom Service secret from the secret. Setting this value allows to use a key with a different name. |
| ics.session.existingSecret.name | string | `nil` | The name of an existing Secret to use for retrieving the Intercom Service secret. |
| ics.session.secret | string | `nil` | The secret used to derive an encryption key for the user identity in a stateless session cookie, to sign the transient cookies used by the login callback and to sign the custom session store cookies |
| ics.sessionRollingDuration | int | `86400` | Rolling session duration in seconds. The session will be reset if the user is active within the duration. Otherwise, the user will be logged out, requiring a silent login. If `enableSessionCookie` is set to true, this setting will be ignored. |
| ics.userUniqueMapper | string | `"entryuuid"` | Mapper claim name for the Intercom Service client. The field must be unique along users. If not set, the default value is "entryuuid", which is provisioned by the Intercom Service initContainer. Any other value that "entryuuid" is not guaranteed to be unique on Nubus. |
| ics.usernameClaim | string | `"phoenixusername"` | ID Token claim that contains the username for a user. Needs to be configured in Keycloak. |
| ics.xwiki | object | `{"audience":"xwikioidc","enabled":true,"subdomain":"wiki","url":""}` | XWiki connection settings. |
| ics.xwiki.audience | string | `"xwikioidc"` | Audience. The audience is the target client ICS will request tokens for when using Token Exchange. More information at https://www.keycloak.org/securing-apps/token-exchange |
| ics.xwiki.enabled | bool | `true` | Enable XWiki integration. |
| ics.xwiki.subdomain | string | `"wiki"` | Subdomain of XWiki with "ics.default.protocol" and "ics.default.domain". Mutual exclusive with "url". |
| ics.xwiki.url | string | `""` | URL of XWiki as FQDN. Mutual exclusive with "subdomain". |
| image.pullPolicy | string | `nil` |  |
| image.registry | string | `""` | Container registry address. This setting has higher precedence than global.registry. |
| image.repository | string | `"nubus-dev/images/intercom-service"` | Container repository string. |
| image.tag | string | `"latest"` | Define image tag. |
| imagePullSecrets | list | `[]` | Credentials to fetch images from private registry. Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  imagePullSecrets:   - "docker-registry"  |
| ingress.annotations | object | `{}` | Define custom ingress annotations. annotations:   nginx.ingress.kubernetes.io/rewrite-target: / |
| ingress.enabled | bool | `true` | Enable creation of Ingress. |
| ingress.host | string | `"ics.example.com"` | Define the Fully Qualified Domain Name (FQDN) where application should be reachable. |
| ingress.ingressClassName | string | `"nginx"` | The Ingress controller class name. |
| ingress.path | string | `"/"` | Define the Ingress path. |
| ingress.pathType | string | `"Prefix"` | Each path in an Ingress is required to have a corresponding path type. Paths that do not include an explicit pathType will fail validation. There are three supported path types:  "ImplementationSpecific" => With this path type, matching is up to the IngressClass. Implementations can treat this                             as a separate pathType or treat it identically to Prefix or Exact path types. "Exact" => Matches the URL path exactly and with case sensitivity. "Prefix" => Matches based on a URL path prefix split by /.  Ref.: https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types |
| ingress.tls | object | `{"enabled":true,"secretName":""}` | Secure an Ingress by specifying a Secret that contains a TLS private key and certificate.  Ref.: https://kubernetes.io/docs/concepts/services-networking/ingress/#tls |
| ingress.tls.enabled | bool | `true` | Enable TLS/SSL/HTTPS for Ingress. |
| ingress.tls.secretName | string | `""` | The name of the kubernetes secret which contains a TLS private key and certificate. Hint: This secret is not created by this chart and must be provided. |
| lifecycleHooks | object | `{}` | Lifecycle to automate configuration before or after startup. |
| livenessProbe.enabled | bool | `true` | Enables kubernetes LivenessProbe. |
| livenessProbe.failureThreshold | int | `3` | Number of failed executions until container is terminated. |
| livenessProbe.initialDelaySeconds | int | `15` | Delay after container start until LivenessProbe is executed. |
| livenessProbe.periodSeconds | int | `5` | Time between probe executions. |
| livenessProbe.successThreshold | int | `1` | Number of successful executions after failed ones until container is marked healthy. |
| livenessProbe.timeoutSeconds | int | `2` | Timeout for command return. |
| nameOverride | string | `""` | String to partially override release name. |
| nodeSelector | object | `{}` | Node labels for pod assignment. Ref: https://kubernetes.io/docs/user-guide/node-selection/ |
| podAnnotations | object | `{}` | Pod Annotations. Ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| podLabels | object | `{}` | Pod Labels. Ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/ |
| podSecurityContext.enabled | bool | `true` | Enable security context. |
| podSecurityContext.fsGroup | int | `1000` | If specified, all processes of the container are also part of the supplementary group. |
| podSecurityContext.fsGroupChangePolicy | string | `"Always"` | Change ownership and permission of the volume before being exposed inside a Pod. |
| provisioning | object | `{"config":{"clientBaseUrl":"","debug":{"enabled":false,"pauseBeforeScriptStart":0},"keycloak":{"auth":{"existingSecret":{"keyMapping":{"password":""},"name":""},"password":"","username":"kcadmin"},"connection":{"host":"","port":"","protocol":"http"},"realm":"nubus"}},"enabled":true,"extraEnvVars":[],"extraVolumeMounts":[],"image":{"imagePullSecrets":[],"pullPolicy":null,"registry":null,"repository":"nubus/images/wait-for-dependency","tag":"0.36.10@sha256:d0f02b847daad4cae834bcd29266ba30bfc806034a9aac2811e3f66bfd6ecec8"},"provisioningImage":{"imagePullSecrets":[],"pullPolicy":null,"registry":null,"repository":"nubus/images/keycloak-bootstrap","tag":"0.25.1@sha256:c2a4fd2d4de55a78195fdddd9087a6a390520a3be6141b10c777c971019d772e"},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"enabled":true,"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}}` | The Intercom Service Keycloak provisioning job |
| provisioning.config.clientBaseUrl | string | `""` | Base URL for setting in Keycloak client URL without backslash. Example: "https://ics.uv-jtorres-dev.gaia.open-desk.cloud" |
| provisioning.config.debug.enabled | bool | `false` | Enable debug output of included Ansible scripts |
| provisioning.config.debug.pauseBeforeScriptStart | int | `0` | Seconds for the job to pause before starting the actual bootstrapping. |
| provisioning.config.keycloak | object | `{"auth":{"existingSecret":{"keyMapping":{"password":""},"name":""},"password":"","username":"kcadmin"},"connection":{"host":"","port":"","protocol":"http"},"realm":"nubus"}` | Keycloak specific settings. |
| provisioning.config.keycloak.auth.existingSecret.keyMapping.password | string | `""` | The key to retrieve the Keycloak admin password from the secret. Setting this value allows to use a key with a different name. |
| provisioning.config.keycloak.auth.existingSecret.name | string | `""` | The name of an existing Secret to use for retrieving the Keycloak admin password. |
| provisioning.config.keycloak.auth.password | string | `""` | Keycloak admin password. |
| provisioning.config.keycloak.auth.username | string | `"kcadmin"` | Keycloak admin user. |
| provisioning.config.keycloak.connection | object | `{"host":"","port":"","protocol":"http"}` | Connection parameters. |
| provisioning.config.keycloak.connection.host | string | `""` | Keycloak host. |
| provisioning.config.keycloak.connection.port | string | `""` | Keycloak port. |
| provisioning.config.keycloak.connection.protocol | string | `"http"` | Keycloak protocol. |
| provisioning.config.keycloak.realm | string | `"nubus"` | Keycloak realm. |
| provisioning.enabled | bool | `true` | Enable keycloak provisioning by default. |
| provisioning.extraEnvVars | list | `[]` | Array with extra environment variables to add to containers.  extraEnvVars:   - name: FOO     value: "bar" |
| provisioning.extraVolumeMounts | list | `[]` | Optionally specify an extra list of additional volumeMounts. |
| provisioning.image.pullPolicy | string | `nil` | Define image sha256 as an alternative to `tag` sha256: null |
| provisioning.securityContext.allowPrivilegeEscalation | bool | `false` | Enable container privileged escalation. |
| provisioning.securityContext.capabilities | object | `{"drop":["ALL"]}` | Security capabilities for container. |
| provisioning.securityContext.enabled | bool | `true` | Enable security context. |
| provisioning.securityContext.readOnlyRootFilesystem | bool | `true` | Mounts the container's root filesystem as read-only. |
| provisioning.securityContext.runAsGroup | int | `1000` | Process group id. |
| provisioning.securityContext.runAsNonRoot | bool | `true` | Run container as a user. |
| provisioning.securityContext.runAsUser | int | `1000` | Process user id. |
| provisioning.securityContext.seccompProfile.type | string | `"RuntimeDefault"` | Disallow custom Seccomp profile by setting it to RuntimeDefault. |
| readinessProbe.enabled | bool | `true` | Enables kubernetes ReadinessProbe. |
| readinessProbe.failureThreshold | int | `15` | Number of failed executions until container is terminated. |
| readinessProbe.initialDelaySeconds | int | `5` | Delay after container start until ReadinessProbe is executed. |
| readinessProbe.periodSeconds | int | `2` | Time between probe executions. |
| readinessProbe.successThreshold | int | `1` | Number of successful executions after failed ones until container is marked healthy. |
| readinessProbe.timeoutSeconds | int | `1` | Timeout for command return. |
| replicaCount | int | `1` | Set the amount of replicas of deployment. |
| resources.limits.cpu | string | `"500m"` | The max number of CPUs to consume. |
| resources.limits.memory | string | `"128Mi"` | The max number of RAM to consume. |
| resources.requests.cpu | string | `"10m"` | The number of CPUs which has to be available on the scheduled node. |
| resources.requests.memory | string | `"32Mi"` | The number of RAM which has to be available on the scheduled node. |
| service.annotations | object | `{}` | Additional custom annotations. |
| service.enabled | bool | `true` | Enable kubernetes service creation. |
| service.ports.http.containerPort | int | `8008` | Internal port. |
| service.ports.http.port | int | `8008` | Accessible port. |
| service.ports.http.protocol | string | `"TCP"` | service protocol. |
| service.sessionAffinity | object | `{"enabled":false,"timeoutSeconds":10800}` | Configure session affinity for to hit the same backend for the period specified in `timeoutSeconds`.  Ref.: https://kubernetes.io/docs/reference/networking/virtual-ips/#session-affinity |
| service.sessionAffinity.enabled | bool | `false` | Whether to enable session affinity or not. |
| service.sessionAffinity.timeoutSeconds | int | `10800` | The session duration in seconds. |
| service.type | string | `"ClusterIP"` | Choose the kind of Service, one of "ClusterIP", "NodePort" or "LoadBalancer". |
| serviceAccount.annotations | object | `{}` | Additional custom annotations for the ServiceAccount. |
| serviceAccount.automountServiceAccountToken | bool | `false` | Allows auto mount of ServiceAccountToken on the serviceAccount created. Can be set to false if pods using this serviceAccount do not need to use K8s API. |
| serviceAccount.create | bool | `true` | Enable creation of ServiceAccount for pod. |
| serviceAccount.labels | object | `{}` | Additional custom labels for the ServiceAccount. |
| terminationGracePeriodSeconds | string | `""` | In seconds, time the given to the pod needs to terminate gracefully. Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod/#termination-of-pods |
| tolerations | list | `[]` | Tolerations for pod assignment. Ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/ |
| topologySpreadConstraints | list | `[]` | Topology spread constraints rely on node labels to identify the topology domain(s) that each Node is in. Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/  topologySpreadConstraints:   - maxSkew: 1     topologyKey: failure-domain.beta.kubernetes.io/zone     whenUnsatisfiable: DoNotSchedule |
| updateStrategy.type | string | `"RollingUpdate"` | Set to Recreate if you use persistent volume that cannot be mounted by more than one pods to make sure the pods are destroyed first. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
