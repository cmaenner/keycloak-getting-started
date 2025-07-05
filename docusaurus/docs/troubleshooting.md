---
id: troubleshooting
title: Troubleshooting
sidebar_label: Troubleshooting
---

# Troubleshooting Guide

This guide covers common issues and their solutions when working with the Keycloak development environment.

## 🔍 Quick Diagnostics

Run comprehensive troubleshooting:
```bash
make troubleshoot
```

This will check:
1. Cluster status
2. Crossplane health
3. Keycloak deployment
4. Ingress configuration
5. Network connectivity

## 🚨 Common Issues

### Cluster Not Accessible

#### Symptoms
- `kubectl` commands fail
- Cluster context not found
- Kind cluster not running

#### Solutions
```bash
# Check cluster status
make cluster-info

# Verify context
kubectl config current-context

# Should be: kind-keycloak-demo
kubectl config use-context kind-keycloak-demo

# Recreate cluster if needed
make delete-cluster
make create-cluster
```

### Ingress Not Working

#### Symptoms
- Can't access Keycloak via keycloak.local
- Ingress controller not responding
- 404 or connection refused errors

#### Solutions
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress resources
kubectl get ingress -n keycloak

# Use port-forward as alternative
make port-forward

# Reinstall ingress if needed
kubectl delete -f .kubernetes/cluster-setup/ingress-nginx.yaml
make install-ingress
```

### Crossplane Issues

#### Symptoms
- Providers not healthy
- Release not ready
- Crossplane pods not running

#### Solutions
```bash
# Check Crossplane status
make test-crossplane

# Check provider health
kubectl get providers

# View provider details
kubectl describe provider provider-helm

# Reinstall Crossplane if needed
make uninstall-crossplane
make install-crossplane
make configure-crossplane
```

### Keycloak Not Starting

#### Symptoms
- Keycloak pods not ready
- Database connection errors
- Resource constraints

#### Solutions
```bash
# Check pod status
kubectl get pods -n keycloak

# View logs
make logs

# Check database connection
kubectl exec -it -n keycloak deployment/postgres -- psql -U keycloak -d keycloak -c '\l'

# Reset deployment
make reset-keycloak
```

## 🔧 Debug Commands

### Cluster Information
```bash
# Show cluster info
make cluster-info

# Check nodes
kubectl get nodes

# Check namespaces
kubectl get namespaces
```

### Component Status
```bash
# Show all component status
make status

# Check specific components
kubectl get pods -n crossplane-system
kubectl get pods -n ingress-nginx
kubectl get pods -n keycloak
```

### Network Connectivity
```bash
# Test Keycloak accessibility
make test-keycloak

# Check services
kubectl get services -n keycloak

# Check endpoints
kubectl get endpoints -n keycloak
```

### Logs and Events
```bash
# Keycloak logs
make logs

# Crossplane logs
kubectl logs -n crossplane-system -l app.kubernetes.io/name=crossplane

# Ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Recent events
kubectl get events -n keycloak --sort-by=.metadata.creationTimestamp
```

## 🛠️ Advanced Troubleshooting

### Resource Constraints

#### Symptoms
- Pods in Pending state
- Insufficient memory/CPU errors

#### Solutions
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n keycloak

# Adjust resource limits in crossplane-release.yaml
# Increase memory/CPU limits if needed
```

### Database Issues

#### Symptoms
- Keycloak can't connect to PostgreSQL
- Database initialization errors

#### Solutions
```bash
# Check PostgreSQL status
kubectl get pods -n keycloak -l app=postgres

# Check PostgreSQL logs
kubectl logs -n keycloak deployment/postgres

# Test database connection
kubectl exec -it -n keycloak deployment/postgres -- psql -U keycloak -d keycloak -c '\l'

# Recreate database if needed
kubectl delete -k .kubernetes/base/postgres/
kubectl apply -k .kubernetes/base/postgres/
```

### Version Compatibility

#### Symptoms
- Chart version conflicts
- Provider version mismatches

#### Solutions
```bash
# Check current versions
kubectl get releases -n keycloak -o yaml | grep version
kubectl get providers -o yaml | grep package

# Update versions if needed
# Edit .kubernetes/base/keycloak/crossplane-release.yaml
# Edit .kubernetes/cluster-setup/crossplane-config.yaml
```

## 🔄 Reset and Recovery

### Complete Reset
```bash
# Clean everything
make cleanup-all

# Start fresh
make presentation-ready
```

### Partial Reset
```bash
# Reset Keycloak only
make cleanup-keycloak
make deploy-postgres
make deploy-keycloak

# Reset Crossplane only
make uninstall-crossplane
make install-crossplane
make configure-crossplane
```

### Configuration Reset
```bash
# Reset to base configuration
kubectl delete -k .kubernetes/overlays/development/
kubectl apply -k .kubernetes/base/
```

## 📊 Monitoring

### Health Checks
```bash
# Monitor all resources
watch kubectl get all -n keycloak

# Monitor Crossplane
watch kubectl get providers

# Monitor ingress
watch kubectl get ingress -n keycloak
```

### Performance Monitoring
```bash
# Check resource usage
kubectl top pods -n keycloak

# Check node resources
kubectl top nodes

# Check persistent volumes
kubectl get pv,pvc -n keycloak
```

## 🆘 Getting Help

### Information to Collect
When seeking help, collect:

1. **Environment Information**
   ```bash
   make versions
   kubectl version
   docker version
   ```

2. **Current Status**
   ```bash
   make status
   make troubleshoot
   ```

3. **Relevant Logs**
   ```bash
   make logs
   kubectl describe pod <pod-name> -n keycloak
   ```

### Useful Commands
```bash
# Show tool versions
make versions

# Comprehensive troubleshooting
make troubleshoot

# Test connectivity
make test-keycloak
```

## 📚 Additional Resources

- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
- [Crossplane Troubleshooting](https://docs.crossplane.io/getting-started/troubleshooting/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [NGINX Ingress Troubleshooting](https://kubernetes.github.io/ingress-nginx/troubleshooting/) 