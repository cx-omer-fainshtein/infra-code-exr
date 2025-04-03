#!/bin/bash

# Ensure we have the right number of arguments
if [ $# -lt 1 ]; then
  echo "Usage: $0 {install|uninstall}"
  exit 1
fi

# Define directories for files
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_URL="https://github.com/cx-omer-fainshtein/infra-code-exr.git"

# Check for the command argument
case "$1" in
  install)
    # Step 1: Install prerequisites

    # Install kubectl if not installed
    if ! command -v kubectl &> /dev/null
    then
      echo "kubectl not found, installing..."
      brew install kubectl
    else
      echo "kubectl is already installed"
    fi

    # Check if Docker Desktop / Podman is running
    if ! pgrep -x "Docker" > /dev/null && ! pgrep -x "podman" > /dev/null
    then
      echo "Docker Desktop or Podman is not running. Please start it first."
      exit 1
    else
      echo "Docker Desktop / Podman is running"
    fi

    # Install k3d if not installed
    if ! command -v k3d &> /dev/null
    then
      echo "k3d not found, installing..."
      brew install k3d
    else
      echo "k3d is already installed"
    fi

    # Install Helm if not installed
    if ! command -v helm &> /dev/null
    then
      echo "Helm not found, installing..."
      brew install helm
    else
      echo "Helm is already installed"
    fi

    # Step 2: Create k3d cluster
    echo "Creating k3d cluster..."
    k3d cluster create --api-port 6550 -p "8081:80@loadbalancer" --agents 2

    # Step 3: Create Kubernetes secret for PostgreSQL credentials
    echo "Please enter PostgreSQL credentials"

    # Prompt for username, password, and database name
    read -p "Enter PostgreSQL username: " postgres_username
    read -sp "Enter PostgreSQL password: " postgres_password
    echo
    read -p "Enter PostgreSQL database name: " postgres_db

    # Create the secret with the entered credentials
    kubectl create secret generic postgres-secret \
      --from-literal=postgres-username=$postgres_username \
      --from-literal=postgres-password=$postgres_password \
      --from-literal=postgres-db=$postgres_db \
      --namespace=postgresql

    echo "Kubernetes secret for PostgreSQL created successfully."

    # Step 4: Deploy PostgreSQL with Helm (Bitnami chart)
    echo "Deploying PostgreSQL..."
    kubectl create namespace postgresql
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    helm install postgresql bitnami/postgresql --namespace postgresql --values "$SCRIPT_DIR/postgresql-values.yaml"

    # Step 5: Deploy Jenkins with Helm (Bitnami chart)
    echo "Deploying Jenkins..."
    kubectl create namespace jenkins
    helm install jenkins bitnami/jenkins --namespace jenkins --values "$SCRIPT_DIR/jenkins-values.yaml"
    kubectl apply -f "$SCRIPT_DIR/jenkins-ingress.yaml"

    # Step 6: Deploy Grafana with Helm (Bitnami chart)
    echo "Deploying Grafana..."
    kubectl create namespace grafana
    helm install grafana bitnami/grafana --namespace grafana --values "$SCRIPT_DIR/grafana-values.yaml"
    kubectl apply -f "$SCRIPT_DIR/grafana-ingress.yaml"

    echo "Deployment complete!"
    ;;
  
  uninstall)
    # Step 1: Delete k3d cluster
    echo "Deleting k3d cluster..."
    k3d cluster delete
    ;;
  
  *)
    echo "Invalid argument. Use 'install' or 'uninstall'."
    exit 1
    ;;
esac

