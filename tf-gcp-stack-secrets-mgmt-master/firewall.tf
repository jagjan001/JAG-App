module "lb_https_port_allow" {
  source    = "./modules/tf-gcp-network-firewall"
  name      = "i-allow-lb"
  network   = module.vpc.name
  priority  = "1001"
  direction = "INGRESS"
  protocol  = "tcp"
  ports     = ["443"]

  # target_tags   = "${var.vault_cluster_name}-${var.env}-${var.project_id}"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "209.85.152.0/22", "209.85.204.0/22"]
}

module "internal_firewall_allow_ssh" {
  source    = "./modules/tf-gcp-network-firewall"
  name      = "i-allow-ssh"
  network   = module.vpc.name
  priority  = "1000"
  direction = "INGRESS"
  protocol  = "tcp"
  ports     = ["22"]

  # target_tags   = "allow-ssh"
  source_ranges = [var.subnet_ip_cidr_range]
}

module "internal_firewall_allow_all_tcp" {
  source        = "./modules/tf-gcp-network-firewall"
  name          = "i-allow-tcp"
  network       = module.vpc.name
  priority      = "65534"
  direction     = "INGRESS"
  protocol      = "tcp"
  ports         = ["0-65535"]
  source_ranges = [var.subnet_ip_cidr_range]
}

module "internal_firewall_allow_all_udp" {
  source        = "./modules/tf-gcp-network-firewall"
  name          = "i-allow-udp"
  network       = module.vpc.name
  priority      = "65534"
  direction     = "INGRESS"
  protocol      = "udp"
  ports         = ["0-65535"]
  source_ranges = [var.subnet_ip_cidr_range]
}

module "internal_firewall_allow_all_icmp" {
  source        = "./modules/tf-gcp-network-firewall"
  name          = "i-allow-icmp"
  network       = module.vpc.name
  priority      = "65534"
  direction     = "INGRESS"
  protocol      = "icmp"
  source_ranges = [var.subnet_ip_cidr_range]
}

