---
id: keycloak-setup
title: Keycloak Setup
sidebar_label: Keycloak Setup
---

# Keycloak Setup and Configuration

This guide covers the Keycloak deployment using Crossplane and the Bitnami Helm chart.

## 📦 Deployment Components

### Keycloak Chart
- **Repository**: https://charts.bitnami.com/bitnami
- **Chart**: keycloak
- **Version**: 24.2.0
- **Provider**: Crossplane Helm Provider v2.0.0

### Configuration

The Keycloak deployment is configured via Crossplane Release in `.kubernetes/base/keycloak/crossplane-release.yaml`:

```yaml
apiVersion: helm.crossplane.io/v1beta1
kind: Release
metadata:
  name: keycloak-release
  namespace: keycloak
spec:
  forProvider:
    chart:
      name: keycloak
      repository: https://charts.bitnami.com/bitnami
      version: "24.2.0"
    namespace: keycloak
    values:
      auth:
        adminUser: admin
        adminPassword: admin
      postgresql:
        enabled: false
      externalDatabase:
        host: postgres
        port: 5432
        user: keycloak
        password: password
        database: keycloak
      service:
        type: ClusterIP
        ports:
          http: 8080
      resources:
        requests:
          memory: "512Mi"
          cpu: "500m"
        limits:
          memory: "1Gi"
          cpu: "1000m"
```

## 🗄️ Database Configuration

Keycloak uses an external PostgreSQL database:

- **Host**: postgres (Kubernetes service)
- **Port**: 5432
- **Database**: keycloak
- **User**: keycloak
- **Password**: password

The PostgreSQL deployment is in `.kubernetes/base/postgres/`.

## 🌐 Ingress Configuration

Keycloak is exposed via NGINX Ingress Controller:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: keycloak-ingress
  namespace: keycloak
spec:
  ingressClassName: nginx
  rules:
  - host: keycloak.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: keycloak-release
            port:
              number: 8080
```

## 🔧 Deployment Commands

### Manual Deployment
```bash
# Create namespace
make create-namespace

# Deploy PostgreSQL
make deploy-postgres

# Deploy Keycloak
make deploy-keycloak

# Setup local access
make setup-hosts
```

### Automated Deployment
```bash
# Complete deployment
make full-demo
```

## 🔍 Verification

### Check Deployment Status
```bash
# Show all resources
make status

# Check Keycloak pods
kubectl get pods -n keycloak

# View logs
make logs
```

### Test Accessibility
```bash
# Test Keycloak accessibility
make test-keycloak

# Port forward (alternative to ingress)
make port-forward
```

## 🔐 Security Considerations

### Development Environment
- Default admin credentials (admin/admin)
- No TLS encryption
- Local cluster only

### Production Recommendations
- Use strong, unique passwords
- Enable TLS with proper certificates
- Implement network policies
- Regular security updates
- Backup and disaster recovery procedures

## 🛠️ Troubleshooting

### Common Issues

#### Keycloak Not Starting
```bash
# Check pod status
kubectl get pods -n keycloak

# View logs
make logs

# Check database connection
kubectl exec -it -n keycloak deployment/postgres -- psql -U keycloak -d keycloak -c '\l'
```

#### Ingress Not Working
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress resources
kubectl get ingress -n keycloak

# Use port-forward as alternative
make port-forward
```

### Reset Deployment
```bash
# Reset Keycloak deployment
make reset-keycloak
```

## 📚 Resources

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Bitnami Keycloak Chart](https://github.com/bitnami/charts/tree/main/bitnami/keycloak)
- [Crossplane Helm Provider](https://github.com/crossplane-contrib/provider-helm) 