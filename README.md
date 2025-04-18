# DevOps Exercise: Kubernetes Setup with Jenkins, PostgreSQL, and Grafana Exposed via Traefik

## Overview
This repository contains a DevOps exercise that automates the deployment of a Kubernetes environment using Helm and k3d. The provided deployment script simplifies the setup process on macOS, while Windows users must ensure required tools are installed manually.

## Known Issues
- jenkins job DSL need to be manually configure and manually update password as for now
  * how to solve it? create automation job that will excute within the jenkins deployment + make sure the execute pod have kubectl on him to get the password you set on the deployment

- Traefik dashboard isn't expose
  * i check in the service - and the dashboard is enable by deafult on port 9000 - i stil can't access him and get 404

## Prerequisites
- `kubectl`
- `docker`
- `k3d`
- `helm`
- `terraform`

## Deployment Steps
1. **Clone the repository:**
   ```sh
   git clone https://github.com/cx-omer-fainshtein/infra-code-exr.git
   cd infra-code-exr
   ```

2. **Edit /etc/hosts file:**
   add this lines into your /etc/hosts file:
   ```sh
   127.0.0.1 grafana.localhost jenkins.localhost traefik.localhost
   ```
  
3. **Run the deployment script:**

   ```sh
   ./abracadabra.sh install
   ```

## Uninstallation
To remove the deployment and delete the k3d cluster, run:
```sh
./abracadabra.sh uninstall
```
