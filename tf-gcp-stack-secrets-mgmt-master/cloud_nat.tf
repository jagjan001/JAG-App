module "cloud_nat" {
  source            = "./modules/tf-gcp-cloud-nat-mod"
  region            = var.region
  network_self_link = module.vpc.self_link
}

