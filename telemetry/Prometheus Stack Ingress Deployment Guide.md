# Prometheus Stack Ingress Deployment Guide

## Overview

This document provides detailed instructions for exposing Prometheus Stack components through Kubernetes Ingress. The Prometheus Stack typically includes Prometheus, Alertmanager, Grafana, and supporting components like Node Exporter and Kube State Metrics.

## Prerequisites

- Kubernetes cluster (v1.19+)
- NGINX Ingress Controller deployed and operational
- Prometheus Stack deployed via Prometheus Operator or kube-prometheus-stack Helm chart
- kubectl command-line tool configured to communicate with your cluster
- Administrative access to the cluster

## Architecture

The architecture follows a standard Kubernetes Ingress pattern:

```
                         ┌───────────────────────┐
                         │    External Traffic   │
                         │      (HTTP/HTTPS)     │
                         └──────────┬────────────┘
                                    │
                                    ▼
                         ┌───────────────────────┐
                         │   Ingress Controller  │
                         └──────────┬────────────┘
                                    │
                                    ▼
     ┌───────────────────────────────────────────────────────────────┐
     │                                                               │
┌────┴───────┐   ┌───────────────┐   ┌────────────┐   ┌─────────────┐
│  Grafana   │   │  Prometheus   │   │Alertmanager│   │Other Services│
└────────────┘   └───────────────┘   └────────────┘   └─────────────┘
```

## Component Overview

The Prometheus Stack typically includes:

1. **Prometheus**: Time-series database for metrics collection
   
   - Default port: 9090
   - Typical service name: `prometheus-operated` or `kube-prometheus-stack-prometheus`

2. **Alertmanager**: Handles alerts from Prometheus
   
   - Default port: 9093
   - Typical service name: `alertmanager-operated` or `kube-prometheus-stack-alertmanager`

3. **Grafana**: Visualization and dashboarding
   
   - Default port: 80 or 3000
   - Typical service name: `kube-prometheus-stack-grafana`

4. **Prometheus Node Exporter**: Collects hardware and OS metrics
   
   - Default port: 9100
   - Typical service name: `kube-prometheus-stack-prometheus-node-exporter`

5. **Kube State Metrics**: Generates metrics about Kubernetes objects
   
   - Default port: 8080
   - Typical service name: `kube-prometheus-stack-kube-state-metrics`

## Configuring Ingress Resources

### 1. Grafana Ingress

Create an Ingress resource for Grafana:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: prometheus  # Adjust to your namespace
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    # Add additional annotations as needed
spec:
  ingressClassName: nginx
  rules:
  - host: grafana.example.com  # Replace with your domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kube-prometheus-stack-grafana
            port:
              number: 80
  # Optional TLS configuration
  # tls:
  # - hosts:
  #   - grafana.example.com
  #   secretName: grafana-tls-secret
```

### 2. Prometheus Ingress

Create an Ingress resource for Prometheus:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  namespace: prometheus  # Adjust to your namespace
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    # Optional: Add auth for security
    # nginx.ingress.kubernetes.io/auth-type: basic
    # nginx.ingress.kubernetes.io/auth-secret: basic-auth
    # nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
spec:
  ingressClassName: nginx
  rules:
  - host: prometheus.example.com  # Replace with your domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kube-prometheus-stack-prometheus
            port:
              number: 9090
```

### 3. Alertmanager Ingress

Create an Ingress resource for Alertmanager:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: alertmanager-ingress
  namespace: prometheus  # Adjust to your namespace
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: alertmanager.example.com  # Replace with your domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kube-prometheus-stack-alertmanager
            port:
              number: 9093
```

### 4. Node Exporter Ingress (Optional)

Create an Ingress resource for Node Exporter metrics:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: node-exporter-ingress
  namespace: prometheus  # Adjust to your namespace
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: node-exporter.example.com  # Replace with your domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kube-prometheus-stack-prometheus-node-exporter
            port:
              number: 9100
```

### 5. Kube State Metrics Ingress (Optional)

Create an Ingress resource for Kube State Metrics:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kube-state-metrics-ingress
  namespace: prometheus  # Adjust to your namespace
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: kube-state-metrics.example.com  # Replace with your domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kube-prometheus-stack-kube-state-metrics
            port:
              number: 8080
```

## Deployment Steps

1. **Identify Service Names and Ports**
   
   Before applying any Ingress resources, verify the exact service names and ports:
   
   ```bash
   # List all services in the Prometheus namespace
   kubectl get svc -n prometheus
   
   # Get specific details about a service
   kubectl describe svc kube-prometheus-stack-grafana -n prometheus
   ```

2. **Applying Ingress Resources**
   
   Apply the Ingress resources:
   
   ```bash
   # Apply the Ingress resources
   kubectl apply -f grafana-ingress.yaml
   kubectl apply -f prometheus-ingress.yaml
   kubectl apply -f alertmanager-ingress.yaml
   # Optional
   kubectl apply -f node-exporter-ingress.yaml
   kubectl apply -f kube-state-metrics-ingress.yaml
   ```

3. **Verify Ingress Resources**
   
   Check that the Ingress resources were created successfully:
   
   ```bash
   kubectl get ingress -n prometheus
   kubectl describe ingress -n prometheus
   ```

## Security Considerations

### 1. Enable TLS for All Services

For production environments, enable TLS for all Ingress resources:

1. Create TLS certificates for each domain:
   
   ```bash
   # Using cert-manager or manually
   kubectl create secret tls prometheus-tls-secret --key tls.key --cert tls.crt -n prometheus
   ```

2. Configure TLS in the Ingress resources:
   
   ```yaml
   spec:
    tls:
    - hosts:
      - prometheus.example.com
      secretName: prometheus-tls-secret
   ```

### 2. Add Authentication

Add basic authentication to protect sensitive metrics:

1. Create an auth file:
   
   ```bash
   htpasswd -c auth admin  # You'll be prompted for a password
   ```

2. Create a Kubernetes secret:
   
   ```bash
   kubectl create secret generic basic-auth --from-file=auth -n prometheus
   ```

3. Add authentication annotations to Ingress resources:
   
   ```yaml
   metadata:
    annotations:
      nginx.ingress.kubernetes.io/auth-type: basic
      nginx.ingress.kubernetes.io/auth-secret: basic-auth
      nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
   ```

### 3. IP Whitelisting

Restrict access to specific IP ranges:

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/whitelist-source-range: "10.0.0.0/24,192.168.0.0/24"
```

## Advanced Configurations

### 1. Sub-path Routing

Deploy services under sub-paths to use a single domain:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: monitoring-ingress
  namespace: prometheus
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - host: monitoring.example.com
    http:
      paths:
      - path: /grafana(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: kube-prometheus-stack-grafana
            port:
              number: 80
      - path: /prometheus(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: kube-prometheus-stack-prometheus
            port:
              number: 9090
      - path: /alertmanager(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: kube-prometheus-stack-alertmanager
            port:
              number: 9093
```

### 2. Custom Headers for Security

Add security headers to all responses:

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "X-XSS-Protection: 1; mode=block";
```

### 3. Grafana Configuration

If you're using subpaths for Grafana, update Grafana's configuration:

```yaml
grafana:
  grafana.ini:
    server:
      root_url: "%(protocol)s://%(domain)s/grafana"
      serve_from_sub_path: true
```

## Troubleshooting

### Common Issues

1. **Service Not Found**
   
   - Verify service existence: `kubectl get svc -n prometheus`
   - Check service name spelling in Ingress resource

2. **Incorrect Port**
   
   - Verify service ports: `kubectl describe svc <service-name> -n prometheus`

3. **TLS Certificate Issues**
   
   - Check certificate validity
   - Verify secret exists in correct namespace

4. **Authentication Problems**
   
   - Verify auth secret exists: `kubectl get secrets -n prometheus`
   - Check auth file format is correct

5. **Path Routing Issues**
   
   - Check path format in Ingress resource
   - Verify `rewrite-target` annotation if using subpaths

### Debugging Steps

1. Check Ingress Controller logs:
   
   ```bash
   kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
   ```

2. Verify Ingress configuration:
   
   ```bash
   kubectl describe ingress -n prometheus
   ```

3. Test service directly:
   
   ```bash
   kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n prometheus
   ```

## Integration with External Systems

### 1. DNS Configuration

Configure DNS records to point to your Kubernetes cluster nodes or load balancer:

```
grafana.example.com     IN A <Node-IP-or-LoadBalancer-IP>
prometheus.example.com  IN A <Node-IP-or-LoadBalancer-IP>
alertmanager.example.com IN A <Node-IP-or-LoadBalancer-IP>
```

### 2. External Load Balancer (Optional)

For production environments, consider using an external load balancer:

```yaml
controller:
  service:
    type: LoadBalancer
    externalTrafficPolicy: Local
```

## References

- [Prometheus Operator Documentation](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/getting-started.md)
- [kube-prometheus-stack Helm Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [NGINX Ingress Controller Documentation](https://kubernetes.github.io/ingress-nginx/)
- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Grafana Documentation](https://grafana.com/docs/)
