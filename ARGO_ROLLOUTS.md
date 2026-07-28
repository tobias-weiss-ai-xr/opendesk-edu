# ArgoCD Rollouts — Canary Deployments

## Setup

```bash
# Install ArgoCD Rollouts controller
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Install kubectl plugin
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
```

## Convert a Deployment to Rollout

Replace `kind: Deployment` with `kind: Rollout` and add a strategy:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: bookstack
spec:
  replicas: 2
  strategy:
    canary:
      steps:
        - setWeight: 25
        - pause: {duration: 5m}
        - setWeight: 50
        - pause: {duration: 5m}
        - setWeight: 75
        - pause: {duration: 5m}
  selector:
    matchLabels:
      app: bookstack
  template:
    # same as deployment template
```

## Verify

```bash
kubectl argo rollouts list rollouts
kubectl argo rollouts get rollout bookstack
kubectl argo rollouts promote bookstack
```
