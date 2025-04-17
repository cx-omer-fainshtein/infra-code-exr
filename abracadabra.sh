#!/bin/bash

set -e  # Exit on any error

# Ensure we have the right number of arguments
if [ $# -lt 1 ]; then
  echo "Usage: $0 {install|uninstall}"
  exit 1
fi

case "$1" in
  install)
    # Create k3d cluster
    echo "Creating k3d cluster..."
    k3d cluster create omer-solution -p "8080:80@loadbalancer" -p "8443:443@loadbalancer" -p "9000:9000@loadbalancer" --agents 3 --servers 1

    echo "Exposing Traefik dashboard via Ingress..."
    kubectl apply -f ./helm/traefik/traefik-dashboard-ingress.yaml

    # Create Kubernetes secret for PostgreSQL credentials
    echo "Please enter PostgreSQL params for your DB:"

    read -p "Enter PostgreSQL username: " postgres_username
    read -sp "Enter PostgreSQL password: " postgres_password
    echo
    read -p "Enter PostgreSQL database name: " postgres_db

    kubectl create namespace postgresql || true  # Ignore if already exists
    kubectl create secret generic postgres-secret \
      --from-literal=postgres-username="$postgres_username" \
      --from-literal=postgres-password="$postgres_password" \
      --from-literal=postgres-db="$postgres_db" \
      --namespace=postgresql

    echo "Kubernetes secret for PostgreSQL created successfully."

    # Step 4: Deploy PostgreSQL with Helm
    echo "Deploying PostgreSQL..."
    helm repo add bitnami https://charts.bitnami.com/bitnami || true
    helm repo update
    helm install postgresql bitnami/postgresql --namespace postgresql --values ./helm/postgres/postgres-values.yaml

    kubectl create namespace jenkins || true # ignore if already exist

    # Step 5: Deploy Jenkins with Helm
    echo "Creating Jenkins admin secret..."
    kubectl create secret generic jenkins-admin-secret \
      --from-literal=jenkins-admin-user=admin \
      --from-literal=jenkins-admin-password=goodPassword \
      --namespace=jenkins

    # Step 6: Deploy Jenkins with Helm
    echo "Deploying Jenkins..."
    helm install jenkins jenkinsci/jenkins --namespace jenkins --values ./helm/jenkins/jenkins-values.yaml
    kubectl apply -f ./helm/jenkins/jenkins-ingress.yaml

    # Step 7: Deploy Grafana with Helm
    kubectl create namespace grafana || true
    echo "Deploying Grafana..."
    helm install grafana bitnami/grafana --namespace grafana --values ./helm/grafana/values.yaml
    kubectl apply -f ./helm/grafana/ingress-values.yaml

    echo "🔄 Waiting for all pods to be Ready and Running..."

    MAX_WAIT=40  # seconds
    SLEEP_INTERVAL=10
    ELAPSED=0

    while [ $ELAPSED -lt $MAX_WAIT ]; do
      # Get pods not in 'Running' or 'Completed' state
      NOT_READY_PODS=$(kubectl get pods --all-namespaces --no-headers | grep -Ev 'Running|Completed')

      if [ -n "$NOT_READY_PODS" ]; then
        echo "⏳ Still waiting... ($ELAPSED seconds elapsed)"
        echo "🔍 Pods not ready:"
        echo "$NOT_READY_PODS"
        echo "----------------------------------------------------"

        sleep $SLEEP_INTERVAL
        ELAPSED=$((ELAPSED + SLEEP_INTERVAL))
      else
        echo "✅ All pods are Ready and Running!"
        # Let it naturally exit loop
      fi
    done
    echo "sleeping for 30 seconds just in case..."
    sleep 30

    # Extract auto-generated Grafana admin password
    grafana_password=$(kubectl get secret grafana-admin \
      --namespace grafana \
      -o jsonpath="{.data.GF_SECURITY_ADMIN_PASSWORD}" | base64 --decode)

    echo "📥 Extracted Grafana password: $grafana_password"

    grafana_password=$(kubectl get secret grafana-admin --namespace grafana -o jsonpath="{.data.GF_SECURITY_ADMIN_PASSWORD}" | base64 -d)
    sed -i '' "/variable \"grafana_password\" {/,/^}/s/default = \".*\"/  default = \"${grafana_password//\//\\/}\"/" ./terraform/variables.tf

    cd terraform
    terraform init
    terraform apply -auto-approve
    cd ..

    echo "Deployment complete!"

    echo "Please launch grafana and jenkins: \n
          grafana: http://grafana.localhost:8080/ \n
          user: admin \n
          password: ${grafana_password} \n
          jenkins: http://jenkins.localhost:8080/ \n
          user: admin \n
          password: goodPassword
        "
    ;;

  uninstall)
    echo "Deleting k3d cluster..."
    k3d cluster delete omer-solution
    ;;

  *)
    echo "Invalid argument. Use 'install' or 'uninstall'."
    exit 1
    ;;
esac
