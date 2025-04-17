terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 2.0"
    }
  }
}

provider "grafana" {
  url  = "http://grafana.localhost:8080/"
  auth = "${var.grafana_user}:${var.grafana_password}"
}
