# Harbor Deployment Guide for Kubernetes using Helm

## 1. Introduction

This document provides instructions for deploying Harbor, an open source container registry, on a Kubernetes cluster using Helm. Harbor is a CNCF project that provides a secure registry that can be deployed in your private environment.

## 2. Prerequisites

- Kubernetes cluster (v1.29.2+rke2r1 or compatible version)
- Helm installed on your workstation
- Storage Provisioner configured in your cluster
- Ingress Controller configured in your cluster
- Network access to the Kubernetes cluster

## 3. Deployment Process

### 3.1 Add Harbor Helm Repository

```bash
helm repo add harbor https://helm.goharbor.io
helm repo update
```

### 3.2 Fetch Harbor Helm Chart

```bash
helm fetch harbor/harbor --untar
```

### 3.3 Configure Chart Values

Modify the `values.yaml` file to set the following parameters:

| Parameter                                                     | Value                          | Description                                 |
| ------------------------------------------------------------- | ------------------------------ | ------------------------------------------- |
| `expose.ingress.hosts.core`                                   | `harbor.cluster.local`         | Harbor ingress hostname                     |
| `expose.ingress.className`                                    | `nginx`                        | Ingress controller class                    |
| `expose.ingress.annotations."nginx.org/client-max-body-size"` | `"0"`                          | Required for large image uploads with Nginx |
| `externalURL`                                                 | `https://harbor.cluster.local` | External URL for Harbor access              |
| `persistence.persistentVolumeClaim.registry.storageClass`     | `nfs-client`                   | Storage class for persistent volumes        |
| `harborAdminPassword`                                         | `<your_password>`              | Password for Harbor admin user              |

### 3.4 Deploy Harbor

Execute the following command to deploy Harbor in a dedicated namespace:

```bash
helm install harbor harbor/ --namespace harbor --create-namespace
```

### 3.5 Verify Deployment

Check that all Harbor pods are running:

```bash
kubectl get pods -n harbor
```

## 4. Post-Deployment Configuration

### 4.1 Access Harbor UI

Once deployed, you can access the Harbor dashboard at:

- URL: https://harbor.cluster.local
- Username: admin
- Password: `<your_password>` (as configured in values.yaml)

### 4.2 Configure DNS

Ensure that the hostname `harbor.cluster.local` is resolvable in your environment. This may require updating your DNS server or `/etc/hosts` file.

## 5. Advanced Configuration

### 5.1 External Database Configuration

By default, Harbor deploys its own PostgreSQL and Redis databases. To use external database services:

1. Set the database type to external in the values.yaml file
2. Configure the external database connection parameters

Example configuration for external PostgreSQL:

```yaml
database:
  type: external
  external:
    host: "external-postgresql.example.com"
    port: "5432"
    username: "harbor"
    password: "harbor_password"
    coreDatabase: "harbor_core"
    notaryServerDatabase: "harbor_notary_server"
    notarySignerDatabase: "harbor_notary_signer"
    sslmode: "require"
```

## 6. Troubleshooting

### 6.1 Common Issues

- **Pod Startup Failures**: Check pod logs using `kubectl logs -n harbor <pod-name>`
- **Storage Issues**: Verify that the storage class exists and is functioning correctly
- **Ingress Issues**: Ensure the ingress controller is properly configured

### 6.2 Log Collection

To collect logs from all Harbor components:

```bash
kubectl logs -n harbor -l app=harbor -c core --tail=200
```

## 7. References

- [Harbor Official Documentation](https://goharbor.io/docs/)
- [Harbor Helm Chart Repository](https://github.com/goharbor/harbor-helm)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

