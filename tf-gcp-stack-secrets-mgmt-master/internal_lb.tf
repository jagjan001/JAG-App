# ------------------------------------------------------------------------------
# CREATE BACKEND SERVICE
# ------------------------------------------------------------------------------

resource "google_compute_region_backend_service" "default" {
  project          = var.project_id
  name             = "${var.env}-tf-${var.project_id}-lb"
  region           = var.region
  protocol         = "TCP"
  timeout_sec      = 10
  session_affinity = "NONE"

  # load_balancing_scheme = "INTERNAL_MANAGED"
  backend {
    group = module.vault_manage_instance_group.regional_instance_group_url
    # balancing_mode = "UTILIZATION"
  }

  # backend          = ["${module.vault_manage_instance_group.regional_instance_group_url}"]
  health_checks = [google_compute_health_check.tcp.self_link]
}

# ------------------------------------------------------------------------------
# CREATE FORWARDING RULE
# ------------------------------------------------------------------------------
resource "google_compute_forwarding_rule" "default" {
  provider              = google-beta
  project               = var.project_id
  name                  = "${var.env}-tf-${var.project_id}-fr"
  region                = var.region
  network               = "${var.env}-${var.network_name}-vpc"
  subnetwork            = "${var.env}-${var.network_name}-subnet"
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.default.self_link
  ip_address            = google_compute_address.internal_with_gce_endpoint.address
  ip_protocol           = "TCP"
  ports                 = ["443"]
  allow_global_access   = true

  # If service label is specified, it will be the first label of the fully qualified service name.
  # Due to the provider failing with an empty string, we're setting the name as service label default
  service_label = "${var.env}-vault"
  #   # This is a beta feature
  #   labels = "${var.custom_labels}"
}

# ------------------------------------------------------------------------------
# CREATE HEALTH CHECK - ONE OF ´http´ OR ´tcp´
# ------------------------------------------------------------------------------

resource "google_compute_health_check" "tcp" {
  project = var.project_id
  name    = "${var.env}-tf-${var.project_id}-hc"

  tcp_health_check {
    port = 8200
  }
}

# ------------------------------------------------------------------------------
# CREATE FIREWALLS FOR THE LOAD BALANCER AND HEALTH CHECKS
# ------------------------------------------------------------------------------

# Load balancer firewall allows ingress traffic from instances tagged with any of the ´var.source_tags´
resource "google_compute_firewall" "load_balancer" {
  project = var.project_id
  name    = "${var.env}-tf-${var.project_id}-ilb-fw"
  network = "${var.env}-${var.network_name}-vpc"

  allow {
    protocol = "tcp"
    ports    = ["443", "8200"]
  }

  # Source tags defines a source of traffic as coming from the primary internal IP address
  # of any instance having a matching network tag.
  source_tags = ["local-host"]

  # Target tags define the instances to which the rule applies
  target_tags = ["${var.vault_cluster_name}-${var.env}-${var.project_id}", "${var.consul_cluster_name}-${var.env}-${var.project_id}"]
}

# Health check firewall allows ingress tcp traffic from the health check IP addresses
resource "google_compute_firewall" "health_check" {
  project = var.project_id
  name    = "${var.env}-tf-${var.project_id}-hc"
  network = "${var.env}-${var.network_name}-vpc"

  allow {
    protocol = "tcp"
    ports    = ["8200"]
  }

  # These IP ranges are required for health checks
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

  # Target tags define the instances to which the rule applies
  target_tags = ["${var.vault_cluster_name}-${var.env}-${var.project_id}", "${var.consul_cluster_name}-${var.env}-${var.project_id}"]
}

