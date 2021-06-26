module "bastion_vm_peering" {
  source                         = "./modules/tf-gcp-bastion-mod"
  bastion_enable                 = var.bastion
  bastion_env                    = var.env
  bastion_project_id             = var.project_id
  bastion_network_name           = "bastion"
  bastion_region                 = var.region
  bastion_ip_cidr_range          = var.bastion_ip_cidr_range
  firewall_public_ssh_source_ips = var.firewall_ssh_source_ips
  vault_vpc_name                 = "${var.env}-${var.network_name}-vpc"
}

module "peer_allowed_ssh" {
  source        = "./modules/tf-gcp-network-firewall"
  name          = "peer-allow-ssh"
  network       = module.vpc.name
  priority      = "1001"
  direction     = "INGRESS"
  protocol      = "tcp"
  ports         = ["22", "443"]
  source_ranges = [var.bastion_ip_cidr_range]
}

