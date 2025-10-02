For Direct Deployment, using the gitlab values
## Deployment Steps

### 1. Add the Prometheus Community Helm Repository

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### 2. Examine and Customize Values

```bash
# Download values file from the gitlab, telemtry/kube-prometheus-stack.values.yaml

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --create-namespace \
  --namespace prometheus \
  --values kube-prometheus-stack.values.yaml

```

Expose the services accordingly to requirement.

If using ingress visit documentation Prometheus Stack Ingress Deployment