# Keycloak Environment with Kind & Crossplane

This project demonstrates modern identity management deployment using Kubernetes, showcasing Keycloak deployment with Crossplane for infrastructure as code.

## 🏗️ Project Structure

```
keycloak-presentation/
├── .kubernetes/              # Kubernetes manifests with Kustomize
│   ├── base/
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── postgres/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   └── kustomization.yaml
│   │   └── keycloak/
│   │       ├── crossplane-release.yaml
│   │       ├── ingress.yaml
│   │       └── kustomization.yaml
│   ├── overlays/
│   │   ├── development/
│   │   │   ├── kustomization.yaml
│   │   │   └── keycloak-dev-config.yaml
│   │   └── production/
│   │       ├── kustomization.yaml
│   │       └── keycloak-prod-config.yaml
│   └── cluster-setup/
│       ├── kind-config.yaml
│       ├── crossplane-config.yaml
│       └── ingress-nginx.yaml
├── Makefile                  # Automation commands
└── README.md                 # This file
```

## 🚀 Technologies Used

### Core Infrastructure

- **[Kind](https://kind.sigs.k8s.io/)** - Kubernetes in Docker for local development
- **[Kubernetes](https://kubernetes.io/)** - Container orchestration platform
- **[Kustomize](https://kustomize.io/)** - Kubernetes configuration management
- **[Helm](https://helm.sh/)** - Kubernetes package manager

### Identity Management

- **[Keycloak](https://www.keycloak.org/)** - Open-source identity and access management
- **[PostgreSQL](https://www.postgresql.org/)** - Database for Keycloak

### Infrastructure as Code

- **[Crossplane](https://crossplane.io/)** - Kubernetes-native infrastructure management
- **[Crossplane Provider Helm](https://github.com/crossplane-contrib/provider-helm)** - Helm chart deployment via Crossplane

### Networking

- **[NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)** - Ingress controller for Kind

## 📋 Prerequisites

### System Requirements

- Docker 20.10+
- 8GB+ RAM
- 20GB+ free disk space
- Linux, macOS, or Windows with WSL2

### Required Tools

Install all tools automatically:

```bash
make install-tools
```

Or install manually:

- Docker
- Kind
- kubectl
- Helm
- Node.js 18+
- npm

## 🎯 Quick Start

### 1. Complete Setup (Recommended)

```bash
# Setup everything for presentation
make presentation-ready
```

### 2. Verification

```bash
# Check all components
make status

# Test Keycloak accessibility
make test-keycloak

# View logs if needed
make logs
```

## 🔧 Available Commands

### Cluster Management

```bash
make create-cluster          # Create Kind cluster
make delete-cluster          # Delete Kind cluster
make cluster-info           # Show cluster information
make install-ingress        # Install NGINX Ingress Controller
```

### Crossplane Operations

```bash
make install-crossplane      # Install Crossplane
make configure-crossplane    # Configure Crossplane providers
make uninstall-crossplane    # Remove Crossplane
make test-crossplane        # Test Crossplane resources
```

### Keycloak Deployment

```bash
make create-namespace       # Create keycloak namespace
make deploy-postgres        # Deploy PostgreSQL database
make deploy-keycloak        # Deploy Keycloak via Crossplane
make setup-hosts           # Add keycloak.local to /etc/hosts
make port-forward          # Port forward Keycloak service
make reset-keycloak        # Reset Keycloak deployment
```

### Monitoring & Debugging

```bash
make status                # Show status of all components
make logs                  # Show Keycloak logs
make describe-keycloak     # Describe Keycloak release
make troubleshoot          # Run troubleshooting checks
make versions              # Show tool versions
```

### Cleanup

```bash
make cleanup-keycloak      # Remove Keycloak resources
make cleanup-configs       # Remove generated config files
make cleanup-all           # Complete cleanup
```

### Quick Commands

```bash
make quick-setup           # Setup cluster, ingress, Crossplane
make full-demo            # Complete demo environment
make presentation-ready    # Everything ready for presentation
```

## 🎨 Kustomize Structure

### Base Configuration

Located in `.kubernetes/base/`, contains:

- **namespace.yaml** - Keycloak namespace definition
- **postgres/** - PostgreSQL deployment and service
- **keycloak/** - Keycloak Crossplane release and ingress

### Overlays

- **development/** - Development-specific configurations
- **production/** - Production-ready configurations

### Usage

```bash
# Apply development configuration
kubectl apply -k .kubernetes/overlays/development

# Apply production configuration
kubectl apply -k .kubernetes/overlays/production

# Apply base configuration
kubectl apply -k .kubernetes/base
```

## 🌐 Access Points

### Keycloak

- **URL**: [https://keycloak.local:8443](https://keycloak.local:8443/)
- **Admin Console**: [https://keycloak.local:8443/admin/master/console](https://keycloak.local:8443/admin/master/console)
- **Username**: admin
- **Password**: admin

## 📊 Presentation Structure (30 minutes)

[https://gamma.app/docs/Bring-Your-Own-Identity-System-Boardwalk-Bytes-2025-fh76lhzu0gnqj8p](https://gamma.app/docs/Bring-Your-Own-Identity-System-Boardwalk-Bytes-2025-fh76lhzu0gnqj8p)

## 🔍 Troubleshooting

### Common Issues

#### Cluster Not Accessible

```bash
# Check cluster status
make cluster-info

# Verify context
kubectl config current-context

# Should be: kind-keycloak-demo
kubectl config use-context kind-keycloak-demo
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

#### Crossplane Issues

```bash
# Check Crossplane status
make test-crossplane

# Check provider health
kubectl get providers

# View provider details
kubectl describe provider provider-helm
```

#### Keycloak Not Starting

```bash
# Check pod status
kubectl get pods -n keycloak

# View logs
make logs

# Check database connection
kubectl exec -it -n keycloak deployment/postgres -- psql -U keycloak -d keycloak -c '\l'
```

### Debug Commands

```bash
# Comprehensive troubleshooting
make troubleshoot

# Monitor all resources
watch kubectl get all -n keycloak

# Check events
kubectl get events -n keycloak --sort-by=.metadata.creationTimestamp
```

## 🔐 Security Considerations

### Development Environment

- Default passwords for demo purposes
- No TLS encryption
- Local cluster only

### Production Recommendations

- Use strong, unique passwords
- Enable TLS with proper certificates
- Implement network policies
- Regular security updates
- Backup and disaster recovery procedures

## 📚 Learning Resources

### Official Documentation

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Crossplane Documentation](https://docs.crossplane.io/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Kustomize Documentation](https://kustomize.io/)

### Tutorials & Guides

- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/)
- [Crossplane Getting Started](https://docs.crossplane.io/getting-started/)
- [Keycloak Admin Guide](https://www.keycloak.org/docs/latest/server_admin/)

## 🤝 Contributing

### Development Workflow

1. Fork the repository
2. Create feature branch
3. Make changes
4. Test with `make presentation-ready`
5. Submit pull request

### Testing Changes

```bash
# Clean environment
make cleanup-all

# Test full setup
make presentation-ready

# Verify all components
make status
make test-keycloak
```

## 📄 License

This project is for educational and demonstration purposes. Individual components are licensed under their respective licenses:

- Keycloak: Apache License 2.0
- Crossplane: Apache License 2.0
- Kubernetes: Apache License 2.0

---

**Ready to get started?** Run `make presentation-ready` to set up everything for your presentation!

For questions or issues, please check the troubleshooting section or open an issue in the repository. 