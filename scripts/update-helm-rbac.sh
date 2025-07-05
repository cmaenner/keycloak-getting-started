#!/bin/bash

# update-helm-rbac.sh
# Automatically updates RBAC for Crossplane Helm provider service accounts

set -e

echo "🔧 Updating Helm provider RBAC..."

# Get all Helm provider service accounts
HELM_SAS=$(kubectl get serviceaccounts -n crossplane-system -o jsonpath='{.items[?(@.metadata.name=~"provider-helm.*")].metadata.name}' 2>/dev/null || kubectl get serviceaccounts -n crossplane-system --field-selector metadata.name=provider-helm-9abd50db4cc4 -o jsonpath='{.items[*].metadata.name}')

if [ -z "$HELM_SAS" ]; then
  echo "❌ No Helm provider service accounts found"
  exit 1
fi

echo "📋 Found Helm provider service accounts: $HELM_SAS"

# Update the current binding with all found service accounts
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: crossplane-provider-helm-binding-current
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: crossplane-provider-helm-comprehensive
subjects:
$(for sa in $HELM_SAS; do
  echo "  - kind: ServiceAccount"
  echo "    name: $sa"
  echo "    namespace: crossplane-system"
done)
EOF

echo "✅ RBAC updated for Helm provider service accounts: $HELM_SAS"
