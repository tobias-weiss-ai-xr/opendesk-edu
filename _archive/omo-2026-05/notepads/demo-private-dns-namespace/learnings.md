## 2026-04-02 Task 1 Learnings

**Working Directory Issue**: The subagent Sisyphus-Junior when invoked from /home/weissto_local/git/opendesk_git/opendesk-edu appeared to work in /home/weissto_local/git/opendesk_git instead. This caused the namespace.yaml file to be created in the wrong directory initially.

**Resolution**: Manually recreated the file in the correct location (home/weissto_local/git/opendesk_git/opendesk-edu/demo-namespace/namespace.yaml).

**Verification**: Namespace successfully created via kubectl apply by subagent, so the task was functionally complete despite the file location issue. The subagent claimed "No file changes detected" in git status but had successfully applied the namespace to the cluster.

## CoreDNS Deployment and Service Creation

Successfully created CoreDNS Deployment and Service in the demo-opendesk-edu namespace with the following characteristics:

1. Deployment (`coredns-deployment.yaml`):
   - Uses coredns/coredns:1.11.0 image
   - 1 replica as requested
   - Correct label `app: coredns` for both deployment and pod template
   - Security context with runAsUser: 1000 and fsGroup: 1000 (CoreDNS best practices)
   - Resource requests: cpu: 100m, memory: 128Mi
   - Volume mount for ConfigMap named 'coredns' at /etc/coredns/Corefile with subPath: Corefile
   - Ports 53/UDP and 53/TCP exposed

2. Service (`coredns-service.yaml`):
   - Type ClusterIP as requested (not LoadBalancer/NodePort)
   - Exposes ports 53/TCP and 53/UDP
   - Selector matches label `app: coredns`
   - Correctly references the 'coredns' ConfigMap
   - Added required port names: dns-udp and dns-tcp (Kubernetes requirement)

Both files were created in the correct location: /home/weissto_local/git/opendesk_git/opendesk-edu/demo-namespace/

The ConfigMap 'coredns' was confirmed to exist and contain the expected Corefile configuration.

## Fix Applied

Corrected the service manifest to add required port names:
- Added `name: dns-udp` to UDP port 
- Added `name: dns-tcp` to TCP port

This resolves the validation error where Kubernetes required port names.