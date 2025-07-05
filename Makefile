# Keycloak Development with Kind, Crossplane & Docusaurus
# Makefile for automation and deployment

.PHONY: help install-tools create-configs create-cluster create-cluster-simple delete-cluster cluster-info install-ingress install-crossplane configure-crossplane uninstall-crossplane test-crossplane create-namespace deploy-postgres deploy-keycloak setup-hosts port-forward reset-keycloak status logs describe-keycloak troubleshoot versions init-docusaurus docusaurus-dev docusaurus-build docusaurus-serve setup-github-pages cleanup-keycloak cleanup-configs cleanup-all quick-setup full-demo presentation-ready test-keycloak check-runtime setup-helm-rbac update-helm-rbac

# Default target
help:
	@echo "Keycloak Development with Kind, Crossplane & Docusaurus"
	@echo "=================================================="
	@echo ""
	@echo "Available commands:"
	@echo "  install-tools          - Install required tools (Docker, Kind, kubectl, Helm, Node.js)"
	@echo "  create-configs         - Create configuration files"
	@echo "  create-cluster         - Create Kind cluster"
	@echo "  create-cluster-simple  - Create simple Kind cluster (single node)"
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
	@echo "  init-docusaurus        - Initialize Docusaurus project"
	@echo "  docusaurus-dev         - Start development server"
	@echo "  docusaurus-build       - Build for production"
	@echo "  docusaurus-serve       - Serve production build"
	@echo "  setup-github-pages     - Setup GitHub Pages workflow"
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

# Variables
CLUSTER_NAME := keycloak-demo
NAMESPACE := keycloak
KEYCLOAK_URL := keycloak.local:8080

# Install required tools
install-tools:
	@echo "Installing required tools..."
	@echo "Checking Docker or Rancher Desktop..."
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

# Create configuration files
create-configs:
	@echo "Configuration files are already in .kubernetes/ directory"

# Create Kind cluster
create-cluster:
	@echo "Creating Kind cluster: $(CLUSTER_NAME)"
	@kind create cluster --name $(CLUSTER_NAME) --config .kubernetes/cluster-setup/kind-config.yaml
	@echo "Cluster created successfully!"

# Create simple Kind cluster (single node)
create-cluster-simple:
	@echo "Creating simple Kind cluster: $(CLUSTER_NAME)"
	@kind create cluster --name $(CLUSTER_NAME) --config .kubernetes/cluster-setup/kind-config-simple.yaml
	@echo "Simple cluster created successfully!"

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
	@kubectl apply -k .kubernetes/cluster-setup/ingress-nginx/
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
	@echo "Waiting for providers to be healthy..."
	@kubectl wait --for=condition=healthy provider.pkg.crossplane.io/provider-helm --timeout=300s
	@kubectl wait --for=condition=healthy provider.pkg.crossplane.io/provider-kubernetes --timeout=300s
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
	@kubectl apply -k .kubernetes/base/keycloak/
	@echo "Waiting for Keycloak to be ready..."
	@kubectl wait --for=condition=ready pod --selector=app.kubernetes.io/name=keycloak --namespace $(NAMESPACE) --timeout=600s
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

# Initialize Docusaurus
init-docusaurus:
	@echo "Initializing Docusaurus project..."
	@npx create-docusaurus@latest docusaurus classic --yes
	@echo "Docusaurus initialized successfully!"

# Start Docusaurus development server
docusaurus-dev:
	@echo "Starting Docusaurus development server..."
	@cd docusaurus && npm start

# Build Docusaurus for production
docusaurus-build:
	@echo "Building Docusaurus for production..."
	@cd docusaurus && npm run build

# Serve Docusaurus production build
docusaurus-serve:
	@echo "Serving Docusaurus production build..."
	@cd docusaurus && npm run serve

# Setup GitHub Pages workflow
setup-github-pages:
	@echo "Setting up GitHub Pages workflow..."
	@mkdir -p .github/workflows
	@echo "name: Deploy to GitHub Pages" > .github/workflows/deploy.yml
	@echo "on:" >> .github/workflows/deploy.yml
	@echo "  push:" >> .github/workflows/deploy.yml
	@echo "    branches: [ main ]" >> .github/workflows/deploy.yml
	@echo "jobs:" >> .github/workflows/deploy.yml
	@echo "  build-and-deploy:" >> .github/workflows/deploy.yml
	@echo "    runs-on: ubuntu-latest" >> .github/workflows/deploy.yml
	@echo "    steps:" >> .github/workflows/deploy.yml
	@echo "    - uses: actions/checkout@v3" >> .github/workflows/deploy.yml
	@echo "    - name: Setup Node.js" >> .github/workflows/deploy.yml
	@echo "      uses: actions/setup-node@v3" >> .github/workflows/deploy.yml
	@echo "      with:" >> .github/workflows/deploy.yml
	@echo "        node-version: '18'" >> .github/workflows/deploy.yml
	@echo "    - name: Install dependencies" >> .github/workflows/deploy.yml
	@echo "      run: cd docusaurus && npm install" >> .github/workflows/deploy.yml
	@echo "    - name: Build" >> .github/workflows/deploy.yml
	@echo "      run: cd docusaurus && npm run build" >> .github/workflows/deploy.yml
	@echo "    - name: Deploy to GitHub Pages" >> .github/workflows/deploy.yml
	@echo "      uses: peaceiris/actions-gh-pages@v3" >> .github/workflows/deploy.yml
	@echo "      with:" >> .github/workflows/deploy.yml
	@echo "        github_token: $${{ secrets.GITHUB_TOKEN }}" >> .github/workflows/deploy.yml
	@echo "        publish_dir: ./docusaurus/build" >> .github/workflows/deploy.yml
	@echo "GitHub Pages workflow created successfully!"

# Cleanup Keycloak resources
cleanup-keycloak:
	@echo "Cleaning up Keycloak resources..."
	@kubectl delete -k .kubernetes/base/keycloak/ 2>/dev/null || echo "Keycloak resources not found"
	@kubectl delete -k .kubernetes/base/postgres/ 2>/dev/null || echo "PostgreSQL resources not found"
	@kubectl delete namespace $(NAMESPACE) 2>/dev/null || echo "Namespace not found"
	@echo "Keycloak cleanup completed!"

# Cleanup configs
cleanup-configs:
	@echo "Cleaning up configuration files..."
	@echo "Configuration files in .kubernetes/ are preserved"

# Complete cleanup
cleanup-all: cleanup-keycloak delete-cluster cleanup-configs
	@echo "Complete cleanup finished!"

# Quick setup
quick-setup: create-cluster-simple install-ingress install-crossplane configure-crossplane
	@echo "Quick setup completed!"

# Full demo
full-demo: quick-setup create-namespace deploy-postgres deploy-keycloak setup-hosts
	@echo "Full demo environment ready!"

# Presentation ready
presentation-ready: full-demo init-docusaurus
	@echo "Everything is ready for presentation!"
	@echo "Keycloak: http://$(KEYCLOAK_URL)"
	@echo "Docusaurus: http://localhost:3000"

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