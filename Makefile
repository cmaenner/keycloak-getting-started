# Keycloak Development with Kind, Crossplane
# Makefile for automation and deployment

.PHONY: help install-tools create-cluster delete-cluster cluster-info install-ingress install-crossplane configure-crossplane uninstall-crossplane test-crossplane create-namespace deploy-postgres deploy-keycloak setup-hosts port-forward reset-keycloak status logs describe-keycloak troubleshoot versions cleanup-keycloak cleanup-all quick-setup full-demo presentation-ready test-keycloak check-runtime setup-helm-rbac update-helm-rbac deploy-crossplane-manifests kind-delete kind-create kind-recreate kind-delete-simple kind-create-simple kind-recreate-simple install-cert-manager

# Default target
help:
	@echo "Keycloak Development with Kind, Crossplane"
	@echo "=========================================="
	@echo ""
	@echo "Available commands:"
	@echo "  install-tools          - Install required tools (Docker, Kind, kubectl, Helm, Node.js)"
	@echo "  create-cluster         - Create Kind cluster"
	@echo "  delete-cluster         - Delete Kind cluster"
	@echo "  cluster-info           - Show cluster information"
	@echo "  install-ingress        - Install NGINX Ingress Controller"
	@echo "  install-crossplane     - Install Crossplane"
	@echo "  configure-crossplane   - Configure Crossplane providers"
	@echo "  uninstall-crossplane   - Remove Crossplane"
	@echo "  test-crossplane        - Test Crossplane resources"
	@echo "  create-namespace       - Create keycloak namespace"
	@echo "  deploy-postgres        - Deploy PostgreSQL database"
	@echo "  deploy-keycloak        - Deploy Keycloak via Crossplane"
	@echo "  setup-hosts            - Add keycloak.local to /etc/hosts"
	@echo "  port-forward           - Port forward Keycloak service"
	@echo "  reset-keycloak         - Reset Keycloak deployment"
	@echo "  status                 - Show status of all components"
	@echo "  logs                   - Show Keycloak logs"
	@echo "  describe-keycloak      - Describe Keycloak release"
	@echo "  troubleshoot           - Run troubleshooting checks"
	@echo "  versions               - Show tool versions"

	@echo "  cleanup-keycloak       - Remove Keycloak resources"
	@echo "  cleanup-configs        - Remove generated config files"
	@echo "  cleanup-all            - Complete cleanup"
	@echo "  quick-setup            - Setup cluster, ingress, Crossplane"
	@echo "  full-demo              - Complete demo environment"
	@echo "  presentation-ready     - Everything ready for presentation"
	@echo "  test-keycloak          - Test Keycloak accessibility"
	@echo "  check-runtime          - Check Docker or Rancher Desktop status"
	@echo "  setup-helm-rbac        - Setup comprehensive RBAC for Helm provider"
	@echo "  update-helm-rbac       - Update RBAC for new Helm provider service accounts"
	@echo "  deploy-crossplane-manifests - Deploy Crossplane infrastructure manifests"
	@echo "  kind-delete            - Delete Kind cluster"
	@echo "  kind-create            - Create Kind cluster with 4 CPUs and 8GB RAM"
	@echo "  kind-recreate          - Recreate Kind cluster with 4 CPUs and 8GB RAM"
	@echo "  kind-delete-simple     - Delete simple Kind cluster"
	@echo "  kind-create-simple     - Create simple Kind cluster with 4 CPUs and 8GB RAM"
	@echo "  kind-recreate-simple    - Recreate simple Kind cluster with 4 CPUs and 8GB RAM"
	@echo "  install-cert-manager   - Install cert-manager via Helm and wait for pods to be ready"

# Variables
CLUSTER_NAME := keycloak-demo
NAMESPACE := keycloak
KEYCLOAK_URL := keycloak.local:8443

# Install required tools
install-tools:
	@echo "Installing required tools..."
	@echo "Checking Docker Desktop..."
	@if which docker > /dev/null; then \
		echo "Docker found: $(shell docker --version)"; \
	else \
		echo "Neither Docker nor Rancher Desktop found. Please install Docker Desktop or Rancher Desktop first."; \
		echo "Docker Desktop: https://www.docker.com/products/docker-desktop/"; \
		exit 1; \
	fi
	@echo "Checking Kind..."
	@which kind > /dev/null || (echo "Installing Kind..." && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-$(uname)-amd64 && chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind)
	@echo "Checking kubectl..."
	@which kubectl > /dev/null || (echo "Installing kubectl..." && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/$(uname)/amd64/kubectl" && chmod +x kubectl && sudo mv kubectl /usr/local/bin/)
	@echo "Checking Helm..."
	@which helm > /dev/null || (echo "Installing Helm..." && curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash)
	@echo "Checking Node.js..."
	@which node > /dev/null || (echo "Node.js not found. Please install Node.js 18+ first." && exit 1)
	@echo "Checking npm..."
	@which npm > /dev/null || (echo "npm not found. Please install npm first." && exit 1)
	@echo "All tools are ready!"

# Create Kind cluster
create-cluster:
	@echo "Creating Kind cluster: $(CLUSTER_NAME)"
	@kind create cluster --name $(CLUSTER_NAME) --config .kubernetes/cluster-setup/kind-config.yaml
	@echo "Cluster created successfully!"

# Delete Kind cluster
delete-cluster:
	@echo "Deleting Kind cluster: $(CLUSTER_NAME)"
	@kind delete cluster --name $(CLUSTER_NAME)
	@echo "Cluster deleted successfully!"

# Show cluster information
cluster-info:
	@echo "Cluster Information:"
	@kubectl cluster-info
	@echo ""
	@echo "Nodes:"
	@kubectl get nodes
	@echo ""
	@echo "Context:"
	@kubectl config current-context

# Install NGINX Ingress Controller
install-ingress:
	@echo "Installing NGINX Ingress Controller..."
	@kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
	@echo "Waiting for ingress controller to be ready..."
	@kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s || (echo "Waiting for pod to be created..." && sleep 10 && kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s)
	@echo "Ingress controller installed successfully!"

# Install Crossplane
install-crossplane:
	@echo "Installing Crossplane..."
	@helm repo add crossplane-stable https://charts.crossplane.io/stable
	@helm repo update
	@helm install crossplane --namespace crossplane-system --create-namespace crossplane-stable/crossplane
	@echo "Waiting for Crossplane to be ready..."
	@kubectl wait --for=condition=ready pod --selector=app.kubernetes.io/name=crossplane --namespace crossplane-system --timeout=300s
	@echo "Crossplane installed successfully!"

# Configure Crossplane providers
configure-crossplane:
	@echo "Configuring Crossplane providers..."
	@echo "Installing providers..."
	@kubectl apply -f .kubernetes/cluster-setup/crossplane-providers.yaml
	@echo "Waiting for Helm ProviderConfig CRD..."
	@timeout 120 bash -c 'until kubectl get crd providerconfigs.helm.crossplane.io 2>/dev/null; do sleep 2; done'
	@echo "Waiting for Kubernetes ProviderConfig CRD..."
	@timeout 120 bash -c 'until kubectl get crd providerconfigs.kubernetes.crossplane.io 2>/dev/null; do sleep 2; done'
	@echo "Waiting for Keycloak ProviderConfig CRD..."
	@timeout 120 bash -c 'until kubectl get crd providerconfigs.keycloak.crossplane.io 2>/dev/null; do sleep 2; done'
	@echo "Waiting for providers to be healthy..."
	@kubectl wait --for=condition=healthy provider.pkg.crossplane.io/provider-helm --timeout=300s
	@kubectl wait --for=condition=healthy provider.pkg.crossplane.io/provider-kubernetes --timeout=300s
	@kubectl wait --for=condition=healthy provider.pkg.crossplane.io/provider-keycloak --timeout=300s
	@echo "Applying ProviderConfig..."
	@kubectl apply -f .kubernetes/cluster-setup/crossplane-providerconfigs.yaml
	@echo "Setting up comprehensive RBAC for Helm provider..."
	@kubectl apply -f .kubernetes/cluster-setup/helm-provider-static-rbac.yaml
	@echo "Updating RBAC for current Helm provider service accounts..."
	@./scripts/update-helm-rbac.sh
	@echo "Crossplane providers configured successfully!"

# Uninstall Crossplane
uninstall-crossplane:
	@echo "Uninstalling Crossplane..."
	@helm uninstall crossplane -n crossplane-system
	@kubectl delete namespace crossplane-system
	@echo "Crossplane uninstalled successfully!"

# Test Crossplane resources
test-crossplane:
	@echo "Testing Crossplane resources..."
	@kubectl get providers
	@kubectl get providerconfigs
	@echo "Crossplane test completed!"

# Create namespace
create-namespace:
	@echo "Creating namespace: $(NAMESPACE)"
	@kubectl apply -f .kubernetes/base/namespace.yaml
	@echo "Namespace created successfully!"

# Install certificates
install-certificates:
	@echo "Installing certificates..."
	@kubectl apply -f .kubernetes/base/cert-manager/certificate.yaml
	@echo "Certificates installed successfully!"

# Deploy PostgreSQL
deploy-postgres:
	@echo "Deploying PostgreSQL..."
	@kubectl apply -k .kubernetes/base/postgres/
	@echo "Waiting for PostgreSQL to be ready..."
	@kubectl wait --for=condition=ready pod --selector=app=postgres --namespace $(NAMESPACE) --timeout=300s
	@echo "PostgreSQL deployed successfully!"

# Deploy Keycloak
deploy-keycloak:
	@echo "Deploying Keycloak..."
	kubectl apply -k .kubernetes/base/keycloak/
	@echo "Waiting for Keycloak Helm release to be READY..."
	kubectl wait --for=condition=Ready --timeout=300s release.helm.crossplane.io/keycloak-release -n keycloak
	@echo "Waiting for Keycloak pod to be created..."
	until kubectl get pod -n keycloak -l app.kubernetes.io/name=keycloak | grep -v NAME | grep -q keycloak-release; do \
		echo "Keycloak pod not found yet. Waiting..."; \
		sleep 5; \
	done
	@echo "Waiting for Keycloak pod to be ready..."
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=keycloak -n keycloak --timeout=300s
	@echo "Keycloak deployed successfully!"

# Setup hosts file
setup-hosts:
	@echo "Adding keycloak.local to /etc/hosts..."
	@if ! grep -q "keycloak.local" /etc/hosts; then \
		echo "127.0.0.1 keycloak.local" | sudo tee -a /etc/hosts; \
	else \
		echo "keycloak.local already in /etc/hosts"; \
	fi

# Port forward Keycloak service
port-forward:
	@echo "Starting port forward for Keycloak..."
	@kubectl port-forward -n $(NAMESPACE) svc/keycloak-release 8080:8080

# Reset Keycloak deployment
reset-keycloak:
	@echo "Resetting Keycloak deployment..."
	@kubectl delete -k .kubernetes/base/keycloak/
	@kubectl apply -k .kubernetes/base/keycloak/
	@echo "Keycloak reset successfully!"

# Show status of all components
status:
	@echo "=== Cluster Status ==="
	@kubectl get nodes
	@echo ""
	@echo "=== Namespaces ==="
	@kubectl get namespaces
	@echo ""
	@echo "=== Crossplane Status ==="
	@kubectl get pods -n crossplane-system 2>/dev/null || echo "Crossplane not installed"
	@echo ""
	@echo "=== Ingress Controller ==="
	@kubectl get pods -n ingress-nginx 2>/dev/null || echo "Ingress controller not installed"
	@echo ""
	@echo "=== Keycloak Status ==="
	@kubectl get pods -n $(NAMESPACE) 2>/dev/null || echo "Keycloak namespace not found"
	@echo ""
	@echo "=== Services ==="
	@kubectl get services -n $(NAMESPACE) 2>/dev/null || echo "No services found"

# Show Keycloak logs
logs:
	@echo "Keycloak logs:"
	@kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/name=keycloak --tail=50

# Describe Keycloak release
describe-keycloak:
	@echo "Keycloak release details:"
	@kubectl describe release keycloak-release -n $(NAMESPACE)

# Run troubleshooting checks
troubleshoot:
	@echo "=== Troubleshooting ==="
	@echo "1. Checking cluster status..."
	@kubectl cluster-info
	@echo ""
	@echo "2. Checking Crossplane..."
	@kubectl get providers 2>/dev/null || echo "Crossplane not installed"
	@echo ""
	@echo "3. Checking Keycloak..."
	@kubectl get pods -n $(NAMESPACE) 2>/dev/null || echo "Keycloak not deployed"
	@echo ""
	@echo "4. Checking ingress..."
	@kubectl get ingress -n $(NAMESPACE) 2>/dev/null || echo "No ingress found"
	@echo ""
	@echo "5. Testing connectivity..."
	@curl -s -o /dev/null -w "%{http_code}" http://$(KEYCLOAK_URL) 2>/dev/null || echo "Connection failed"

# Show tool versions
versions:
	@echo "=== Tool Versions ==="
	@printf "Docker: "
	@if which docker > /dev/null; then \
		docker --version 2>/dev/null || echo "installed but not responding"; \
	else \
		echo "Not installed"; \
	fi
	@printf "Kind: "
	@if which kind > /dev/null; then \
		kind --version 2>/dev/null || echo "installed but not responding"; \
	else \
		echo "Not installed"; \
	fi
	@printf "kubectl: "
	@if which kubectl > /dev/null; then \
		kubectl version --client 2>/dev/null || echo "installed but not responding"; \
	else \
		echo "Not installed"; \
	fi
	@printf "Helm: "
	@if which helm > /dev/null; then \
		helm version 2>/dev/null || echo "installed but not responding"; \
	else \
		echo "Not installed"; \
	fi
	@printf "Node.js: "
	@if which node > /dev/null; then \
		node --version 2>/dev/null || echo "installed but not responding"; \
	else \
		echo "Not installed"; \
	fi
	@printf "npm: "
	@if which npm > /dev/null; then \
		npm --version 2>/dev/null || echo "installed but not responding"; \
	else \
		echo "Not installed"; \
	fi



# Cleanup Keycloak resources
cleanup-keycloak:
	@echo "Cleaning up Keycloak resources..."
	@kubectl delete -k .kubernetes/base/keycloak/ 2>/dev/null || echo "Keycloak resources not found"
	@kubectl delete -k .kubernetes/base/postgres/ 2>/dev/null || echo "PostgreSQL resources not found"
	@kubectl delete namespace $(NAMESPACE) 2>/dev/null || echo "Namespace not found"
	@echo "Keycloak cleanup completed!"

# Complete cleanup
cleanup-all: cleanup-keycloak delete-cluster
	@echo "Complete cleanup finished!"

.PHONY: create-cluster-issuer
create-cluster-issuer:
	@kubectl apply -f .kubernetes/base/cert-manager/cluster-issuer.yaml

# Quick setup
quick-setup: create-cluster install-ingress install-cert-manager install-crossplane configure-crossplane
	@echo "Quick setup completed!"

# Full demo
full-demo: quick-setup create-namespace install-certificates deploy-postgres deploy-crossplane-manifests deploy-keycloak setup-hosts
	@echo "Full demo environment ready!"

# Presentation ready
presentation-ready: full-demo
	@echo "Everything is ready for presentation!"
	@echo "Keycloak: http://$(KEYCLOAK_URL)"

# Test Keycloak accessibility
test-keycloak:
	@echo "Testing Keycloak accessibility..."
	@curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://$(KEYCLOAK_URL) || echo "Connection failed"

# Check container runtime
check-runtime:
	@echo "=== Container Runtime Check ==="
	@if which docker > /dev/null; then \
		echo "✅ Docker found: $(shell docker --version)"; \
		echo "Docker info:"; \
		docker info --format 'table {{.Name}}\t{{.ServerVersion}}\t{{.OperatingSystem}}' 2>/dev/null || echo "Docker not running"; \
	elif which rancher-desktop > /dev/null; then \
		echo "✅ Rancher Desktop found"; \
		echo "Rancher Desktop status:"; \
		rancher-desktop --version 2>/dev/null || echo "Rancher Desktop not running"; \
	else \
		echo "❌ Neither Docker nor Rancher Desktop found"; \
		echo "Please install Docker Desktop or Rancher Desktop:"; \
		echo "  - Docker Desktop: https://www.docker.com/products/docker-desktop/"; \
		echo "  - Rancher Desktop: https://rancherdesktop.io/"; \
	fi

# Setup comprehensive RBAC for Helm provider
setup-helm-rbac:
	@echo "Setting up comprehensive RBAC for Helm provider..."
	@kubectl apply -f .kubernetes/cluster-setup/helm-provider-static-rbac.yaml
	@echo "RBAC setup completed!"

# Update RBAC for new Helm provider service accounts
update-helm-rbac:
	@echo "Updating RBAC for Helm provider service accounts..."
	@./scripts/update-helm-rbac.sh

# Deploy Crossplane infrastructure manifests
deploy-crossplane-manifests:
	@echo "Deploying Crossplane infrastructure manifests..."
	@if [ -d ".kubernetes/code" ]; then \
		echo "Found Crossplane manifests in .kubernetes/code/"; \
		kubectl apply -f .kubernetes/code/; \
		echo "Crossplane manifests deployed successfully!"; \
	else \
		echo "No .kubernetes/code/ directory found. Creating it..."; \
		mkdir -p .kubernetes/code; \
		echo "Created .kubernetes/code/ directory. Add your Crossplane manifests here."; \
	fi

.PHONY: kind-delete
kind-delete:
	kind delete cluster --name keycloak-demo

.PHONY: kind-create
kind-create: kind-delete
	kind create cluster --name keycloak-demo --config .kubernetes/cluster-setup/kind-config.yaml
	@echo "Waiting for Kind node container to be ready..."
	sleep 5
	docker update --cpus=4 --memory=8g keycloak-demo-control-plane
	@echo "Kind cluster created with 4 CPUs and 8GB RAM."

.PHONY: kind-recreate
kind-recreate: kind-delete kind-create
	@echo "Kind cluster recreated with 4 CPUs and 8GB RAM."

.PHONY: kind-delete-simple
kind-delete-simple:
	kind delete cluster --name keycloak-demo

.PHONY: kind-create-simple
kind-create-simple: kind-delete-simple
	kind create cluster --name keycloak-demo --config .kubernetes/cluster-setup/kind-config-simple.yaml
	@echo "Waiting for Kind node container to be ready..."
	sleep 5
	docker update --cpus=4 --memory=8g keycloak-demo-control-plane
	@echo "Kind cluster (simple config) created with 4 CPUs and 8GB RAM."

.PHONY: kind-recreate-simple
kind-recreate-simple: kind-delete-simple kind-create-simple
	@echo "Kind cluster (simple config) recreated with 4 CPUs and 8GB RAM."

.PHONY: install-cert-manager
install-cert-manager:
	@echo "Installing cert-manager via Helm..."
	@echo "Step 1: Installing cert-manager core components..."
	kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
	helm repo add jetstack https://charts.jetstack.io || true
	helm repo update
	helm upgrade --install cert-manager jetstack/cert-manager \
		--namespace cert-manager \
		--version v1.18.2 \
		--set installCRDs=true
	@echo "Waiting for cert-manager pods to be ready..."
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=300s
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager-webhook -n cert-manager --timeout=300s || true
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager-cainjector -n cert-manager --timeout=300s || true
	@echo "Step 2: Installing cert-manager cluster issuers..."
	kubectl apply -f .kubernetes/base/cert-manager/cluster-issuer.yaml
	@echo "cert-manager installed successfully!" 