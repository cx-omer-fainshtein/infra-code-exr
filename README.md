# DevOps Exercise: Kubernetes Setup with Jenkins, PostgreSQL, and Grafana Exposed via Traefik

## Overview
This repository contains a DevOps exercise that automates the deployment of a Kubernetes environment using Helm and k3d. The provided deployment script simplifies the setup process on macOS, while Windows users must ensure required tools are installed manually.

## Prerequisites
### macOS

The deployment script automatically verifies and installs required dependencies.

### Windows
Ensure the following tools are installed and available in your system's PATH:
- `kubectl`
- `docker`
- `k3d`
- `helm`

## Deployment Steps
1. **Clone the repository:**
   ```sh
   git clone https://github.com/cx-omer-fainshtein/infra-code-exr.git
   cd infra-code-exr
   ```

2. **Run the deployment script:**
   - **macOS:** The script will verify dependencies and proceed with the installation.
   - **Windows:** Ensure all prerequisites are installed before proceeding.

   ```sh
   ./abracadabra.sh install
   ```

## Uninstallation
To remove the deployment and delete the k3d cluster, run:
```sh
./abracadabra.sh uninstall
```

## Known Issues
- jenkins DSL job finish as aborted but execute the task
- jenkins DSL job login to postgres db hard coded 
- jenkins ovveride grfana and vice versa - only one service can be expose at the time
- terraform setup isn't completed
- 
