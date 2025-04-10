variable "gcp_project_name" {
  description = "GCP Project Name"
  type = string
}

variable "project_name" {
  description = "Base project name"
  type        = string
  default     = "cbrio"
}

variable "region" {
  description = "Regions to deploy GCP resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zone to deploy GCP resources"
  type        = string
  default     = "us-central1-c"
}

variable "cluster_name" {
  description = "Cluster Name for GKE"
  type        = string
  default     = "k8s"
}

variable "gke_node_count" {
  description = "Number of nodes to add to the GKE cluster"
  type        = number
  default     = 3
}

variable "app" {
  description = "App name"
  type        = string
}
