---
id: crossplane-config
title: Crossplane Configuration
sidebar_label: Crossplane Configuration
---

# Crossplane Configuration

This guide covers the Crossplane setup and configuration for infrastructure as code.

## 🏗️ Architecture Overview

Crossplane is a Kubernetes-native control plane that enables you to manage infrastructure using the Kubernetes API. In this project, we use Crossplane to deploy Keycloak using the Helm provider.

## 📦 Components

### Crossplane Core
- **Version**: Latest stable
- **Installation**: Via Helm
- **Namespace**: crossplane-system

### Providers
- **Helm Provider**: v2.0.0
- **Kubernetes Provider**: v0.11.0

## 🔧 Installation

### Install Crossplane
```bash
# Install Crossplane via Helm
make install-crossplane
```

This command:
1. Adds the Crossplane Helm repository
2. Installs Crossplane in the `crossplane-system` namespace
3. Waits for Crossplane to be ready

### Configure Providers
```bash
# Configure Crossplane providers
make configure-crossplane
```

This applies the configuration from `.kubernetes/cluster-setup/crossplane-config.yaml`:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-helm
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-helm:v2.0.0
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-kubernetes:v0.11.0
---
apiVersion: pkg.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: InjectedIdentity
```

## 🔍 Verification

### Check Crossplane Status
```bash
# Test Crossplane resources
make test-crossplane
```

This will show:
- Provider status
- ProviderConfig status

### Manual Verification
```bash
# Check Crossplane pods
kubectl get pods -n crossplane-system

# Check providers
kubectl get providers

# Check provider configs
kubectl get providerconfigs
```

## 🚀 Keycloak Deployment

### Crossplane Release

Keycloak is deployed using a Crossplane Release resource:

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
      # ... configuration values
  providerConfigRef:
    name: default
```

### Deployment Commands
```bash
# Deploy Keycloak via Crossplane
make deploy-keycloak

# Check release status
kubectl get releases -n keycloak

# Describe release
kubectl describe release keycloak-release -n keycloak
```

## 🔄 Resource Management

### Create Resources
```bash
# Apply base configuration
kubectl apply -k .kubernetes/base/

# Apply development overlay
kubectl apply -k .kubernetes/overlays/development/

# Apply production overlay
kubectl apply -k .kubernetes/overlays/production/
```

### Delete Resources
```bash
# Delete Keycloak resources
make cleanup-keycloak

# Delete all Crossplane resources
kubectl delete -k .kubernetes/base/
```

## 🛠️ Troubleshooting

### Common Issues

#### Provider Not Healthy
```bash
# Check provider status
kubectl get providers

# Describe provider
kubectl describe provider provider-helm

# Check provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-helm
```

#### Release Not Ready
```bash
# Check release status
kubectl get releases -n keycloak

# Describe release
kubectl describe release keycloak-release -n keycloak

# Check events
kubectl get events -n keycloak --sort-by=.metadata.creationTimestamp
```

### Debug Commands
```bash
# Comprehensive troubleshooting
make troubleshoot

# Check Crossplane logs
kubectl logs -n crossplane-system -l app.kubernetes.io/name=crossplane
```

## 🔐 Security

### Provider Configuration
- Uses InjectedIdentity for authentication
- No external credentials required
- Runs with cluster permissions

### Best Practices
- Use specific namespaces for resources
- Implement RBAC for production
- Regular security updates
- Monitor resource usage

## 📚 Resources

- [Crossplane Documentation](https://docs.crossplane.io/)
- [Crossplane Helm Provider](https://github.com/crossplane-contrib/provider-helm)
- [Crossplane Kubernetes Provider](https://github.com/crossplane-contrib/provider-kubernetes)
- [Crossplane Getting Started](https://docs.crossplane.io/getting-started/) 