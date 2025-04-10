resource "google_compute_network" "k8s-default" {
  name                     = "${var.project_name}-network"
  auto_create_subnetworks  = false
  enable_ula_internal_ipv6 = true
}

resource "google_compute_subnetwork" "subnetwork" {
  name = "${var.project_name}-subnetwork"

  ip_cidr_range = "10.0.0.0/16"
  region        = var.region


  network = google_compute_network.k8s-default.id
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.0.0/22"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.4.0/22"
  }
}
