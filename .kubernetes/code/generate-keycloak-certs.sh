#!/bin/bash

# Generate self-signed certificates for Keycloak
set -e

CERT_DIR=.kubernetes/code/certs
SECRET_FILE=.kubernetes/code/keycloak-tls-secret.yaml
SECRET_NAME=keycloak-tls-secret
NAMESPACE=keycloak

echo "Generating self-signed certificates for Keycloak..."

mkdir -p $CERT_DIR
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout $CERT_DIR/tls.key \
  -out $CERT_DIR/tls.crt \
  -subj "/CN=keycloak-release.keycloak.svc.cluster.local"

kubectl create secret tls $SECRET_NAME \
  --cert=$CERT_DIR/tls.crt \
  --key=$CERT_DIR/tls.key \
  -n $NAMESPACE \
  --dry-run=client -o yaml >$SECRET_FILE

echo "Certificates generated successfully!"
echo "Files created:"
echo "  - .kubernetes/code/certs/tls.key"
echo "  - .kubernetes/code/certs/tls.crt"
echo "  - .kubernetes/code/keycloak-tls-secret.yaml"
