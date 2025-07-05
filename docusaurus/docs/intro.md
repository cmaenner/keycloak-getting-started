---
id: intro
title: Introduction
sidebar_label: Introduction
---

# Welcome to Keycloak Development

This project demonstrates modern identity management deployment using Kubernetes, showcasing Keycloak deployment with Crossplane for infrastructure as code and Docusaurus for documentation.

## 🚀 Quick Start

Get everything running with a single command:

```bash
make presentation-ready
```

This will:
1. Create a Kind Kubernetes cluster
2. Install NGINX Ingress Controller
3. Install and configure Crossplane
4. Deploy PostgreSQL database
5. Deploy Keycloak via Crossplane
6. Initialize Docusaurus documentation site

## 🏗️ Architecture

Our setup uses:

- **Kind** - Kubernetes in Docker for local development
- **Crossplane** - Infrastructure as code for Kubernetes
- **Keycloak** - Open-source identity and access management
- **PostgreSQL** - Database for Keycloak
- **NGINX Ingress Controller** - Ingress controller for Kind
- **Docusaurus** - Documentation website generator

## 🌐 Access Points

Once deployed, you can access:

- **Keycloak**: http://keycloak.local:8080
  - Admin Console: http://keycloak.local:8080/admin
  - Username: `admin`
  - Password: `admin`

- **Documentation**: http://localhost:3000

## 📋 Prerequisites

- Docker 20.10+
- 8GB+ RAM
- 20GB+ free disk space
- Linux, macOS, or Windows with WSL2

The setup will automatically install required tools like Kind, kubectl, Helm, and Node.js.

## 🔧 Available Commands

See the [README.md](../README.md) for a complete list of available `make` commands.

## 🎯 Next Steps

1. [Keycloak Setup](./keycloak-setup.md) - Learn about Keycloak configuration
2. [Crossplane Configuration](./crossplane-config.md) - Understand infrastructure as code
3. [Troubleshooting](./troubleshooting.md) - Common issues and solutions 