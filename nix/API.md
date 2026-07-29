# lib/k8s.nix API Reference

## Core Resources

### `deployment { args }`
Creates a Deployment manifest.
Args: name, image, tag, port, replicas, env, envFrom, resources, probes,
      volumes, extraContainers, initContainers, nodeSelector, affinity,
      tolerations, priorityClassName, dnsConfig, hostAliases,
      imagePullSecrets, serviceAccountName, podAnnotations, podLabels

### `statefulset { args }`
Same as deployment but creates a StatefulSet with serviceName.

### `daemonSet { args }`
Same as deployment but creates a DaemonSet.

### `service { args }`
Creates a Service (ClusterIP, NodePort, LoadBalancer).
Args: name, port, targetPort, type, clusterIP, ports (extra), annotations

### `headlessService { name, port }`
Creates a headless Service (clusterIP: None) for StatefulSets.

### `ingress { args }`
Creates an Ingress with TLS support.
Args: name, host, port, className, tls, tlsSecret, annotations, paths

### `configMap { name, data }`
Creates a ConfigMap from an attribute set.

### `namespace { name }`
Creates a Namespace.

## Batch Resources

### `job { name, image, tag, command, env, backoffLimit }`
Creates a one-time Job.

### `cronJob { name, image, tag, schedule, command, env, backoffLimit }`
Creates a scheduled CronJob.

## Autoscaling & Availability

### `hpa { name, minReplicas, maxReplicas, targetCPU }`
Creates a HorizontalPodAutoscaler.

### `pdb { name, minAvailable }`
Creates a PodDisruptionBudget.

### `networkPolicy { name, namespace, ports }`
Creates a NetworkPolicy allowing ingress from namespace.

## Security

### `serviceAccount { name, annotations }`
Creates a ServiceAccount.

### `securityContext`
Standard non-root security context (runAsUser: 1000, capabilities drop ALL).

## Probes

### `tcpProbe port`
TCP socket probe with defaults (30s initial, 10s period).

### `httpProbe { path, port, initialDelaySeconds, periodSeconds }`
HTTP GET probe.

### `commandProbe { command, initialDelaySeconds, periodSeconds }`
Exec command probe.

## Volumes

### `mkVolume { name, mountPath, secret?, configMap?, hostPath?, subPath? }`
Creates a volume + mount pair. Exactly one of secret/configMap/hostPath.

### `emptyDir { name, mountPath, medium? }`
Creates an emptyDir volume + mount.

### `hostPath { name, mountPath, hostPath, type }`
Creates a hostPath volume + mount.

## Container

### `mkContainer { args }`
Low-level container builder. Used by all resource generators.
Args: name, image, tag, port, ports, env, envFrom, resources,
      probes, probeType, probePath, volumes, command, args, lifecycle
