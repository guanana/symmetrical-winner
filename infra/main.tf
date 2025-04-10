resource "google_container_cluster" "project_gke" {
  name                     = "${var.project_name}-${var.cluster_name}"
  location                 = var.zone
  initial_node_count       = 1
  remove_default_node_pool = true
  deletion_protection      = false
  network                  = google_compute_network.k8s-default.id
  subnetwork               = google_compute_subnetwork.subnetwork.id
  ip_allocation_policy {
    services_secondary_range_name = google_compute_subnetwork.subnetwork.secondary_ip_range[0].range_name
    cluster_secondary_range_name  = google_compute_subnetwork.subnetwork.secondary_ip_range[1].range_name
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "k8s-${var.project_name}-node-pool"
  cluster    = google_container_cluster.project_gke.id
  node_count = var.gke_node_count
  node_config {
    preemptible  = true
    machine_type = "e2-medium"

    service_account = google_service_account.k8s_svc.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_compute_disk" "provisioned_disks" {
  count = 3
  name  = "${var.app}-disk-${count.index}"
  size  = 5
  type  = "pd-standard"
  zone  = var.zone
}

