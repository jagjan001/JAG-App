data "google_compute_image" "consul_image" {
  name    = var.consul_compute_image
  project = var.image_project_id == "" ? var.project_id : var.image_project_id
}

module "consul_instance_template" {
  source                 = "./modules/tf-gcp-instance-template-mod"
  project                = var.project_id
  region                 = var.region
  name_prefix            = "consul-"
  machine_type           = var.consul_machine_type
  compute_image          = data.google_compute_image.consul_image.self_link
  disk_size_gb           = var.consul_disk_size_gb
  network                = "projects/${var.project_id}/global/networks/${var.env}-${var.network_name}-vpc"
  subnetwork             = "projects/${var.project_id}/regions/${var.region}/subnetworks/${var.env}-${var.network_name}-subnet"
  target_tags            = ["${var.consul_cluster_name}-${var.env}-${var.project_id}", "allow-ssh"]
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  startup_script         = "${data.template_file.consul_server_userdata.rendered} ${data.template_file.consul_backup_agent.rendered}"
  service_account_email  = data.google_service_account.svc_account.email

  metadata = {
    "shutdown-script" = data.template_file.consul_shutdown.rendered
  }
}

module "consul_manage_instance_group" {
  source                      = "./modules/tf-gcp-instance-group-mod"
  project                     = var.project_id
  region                      = var.region
  network                     = "projects/${var.project_id}/global/networks/${var.env}-${var.network_name}-vpc"
  name                        = "consul-mig"
  service_port                = 8501
  service_port_name           = "consul-backend"
  target_tags                 = ["${var.consul_cluster_name}-${var.env}-${var.project_id}"]
  instance_template_self_link = module.consul_instance_template.default_no_external_ip_self_link
  distribution_policy_zones   = data.google_compute_zones.available.names
  autoscaling                 = false
  size                        = var.consul_vm_count
}

module "gcs_consul_backup_bucket" {
  source          = "./modules/tf-gcp-gcs-mod"
  project_id      = var.project_id
  names           = ["backup-${var.env}-${var.project_id}"]
  prefix          = "consul"
  set_admin_roles = false

  versioning = {
    first = true
  }
}

