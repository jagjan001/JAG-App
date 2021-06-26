module "vpc" {
  source = "./modules/tf-gcp-gcn-mod"
  name   = "${var.env}-${var.network_name}-vpc"
}

module "subnet" {
  source                   = "./modules/tf-gcp-network-subnet"
  name                     = "${var.env}-${var.network_name}-subnet"
  vpc                      = module.vpc.self_link
  subnetwork-region        = var.region
  private_ip_google_access = true
  ip_cidr_range            = var.subnet_ip_cidr_range
}

resource "google_compute_address" "internal_with_gce_endpoint" {
  project      = var.project_id
  name         = "lb-internal-ip"
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"
  subnetwork   = "projects/${var.project_id}/regions/${var.region}/subnetworks/${var.env}-${var.network_name}-subnet"
}

