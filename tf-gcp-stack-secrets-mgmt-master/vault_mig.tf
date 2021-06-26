data "google_compute_image" "vault_image" {
  name    = var.vault_compute_image
  project = var.image_project_id == "" ? var.project_id : var.image_project_id
}

module "vault_instance_template" {
  source                 = "./modules/tf-gcp-instance-template-mod"
  project                = var.project_id
  region                 = var.region
  name_prefix            = "vault-"
  machine_type           = var.vault_machine_type
  compute_image          = data.google_compute_image.vault_image.self_link
  disk_size_gb           = var.vault_disk_size_gb
  network                = "projects/${var.project_id}/global/networks/${var.env}-${var.network_name}-vpc"
  subnetwork             = "projects/${var.project_id}/regions/${var.region}/subnetworks/${var.env}-${var.network_name}-subnet"
  target_tags            = ["${var.vault_cluster_name}-${var.env}-${var.project_id}", "allow-ssh"]
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  startup_script         = data.template_file.vault_server_user_data.rendered
  service_account_email  = data.google_service_account.svc_account.email

  metadata = {
    "shutdown-script" = data.template_file.vault_shutdown.rendered
  }
}

module "vault_manage_instance_group" {
  source                      = "./modules/tf-gcp-instance-group-mod"
  project                     = var.project_id
  region                      = var.region
  network                     = "projects/${var.project_id}/global/networks/${var.env}-${var.network_name}-vpc"
  name                        = "vault-mig"
  service_port                = 8200
  service_port_name           = "vault-ui"
  target_tags                 = ["${var.vault_cluster_name}-${var.env}-${var.project_id}"]
  instance_template_self_link = module.vault_instance_template.default_no_external_ip_self_link
  distribution_policy_zones   = data.google_compute_zones.available.names
  autoscaling                 = false
  size                        = var.vault_vm_count
  # update_strategy = "ROLLING_UPDATE"
  # min_replicas = 2
  # max_replicas = 2
  # cooldown_period = 60
  # autoscaling_cpu = [{
  #   target = 0.8
  # }]
}

