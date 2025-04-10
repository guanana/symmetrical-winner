terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
  }
  backend "local" {}
}

provider "google" {
  project = var.gcp_project_name
  region  = var.region
}

# terraform {
#   backend "gcs" {
#     bucket  = "tf-state-prod"
#     prefix  = "terraform/state"
#   }
# }

# provider "kubernetes" {
#   host                   = "https://${google_container_cluster.project_gke.endpoint}"
#   token                  = data.google_client_config.default.access_token
#   cluster_ca_certificate = base64decode(google_container_cluster.project_gke.master_auth[0].cluster_ca_certificate)
#   ignore_annotations = [
#     "^autopilot\\.gke\\.io\\/.*",
#     "^cloud\\.google\\.com\\/.*"
#   ]
# }