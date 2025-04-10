output "gke_name" {
  value = google_container_cluster.project_gke.name
}
output "gcp_project_name" {
  value = data.google_client_config.default.project
}