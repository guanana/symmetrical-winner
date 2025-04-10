resource "google_service_account" "k8s_svc" {
  account_id   = "k8s-${var.project_name}-svc"
  display_name = "${title(var.project_name)} Service Account"
}