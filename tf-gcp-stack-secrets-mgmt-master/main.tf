##########
## IAM
##########
data "google_service_account" "svc_account" {
  account_id = var.sa_account
}

##########
## GCE
##########
data "google_compute_subnetwork" "subnetwork" {
  self_link = module.subnet.self_link
}

data "google_compute_network" "network" {
  name = "${var.env}-vault-service-vpc"
}

data "google_compute_zones" "available" {
}

##########################
### Vault / Consul Config
##########################
resource "random_id" "consul_gossip_encryption" {
  byte_length = 16
}

resource "random_id" "vault_hostname_prefix" {
  byte_length = 4
}

resource "random_id" "consul_hostname_prefix" {
  byte_length = 4
}

data "template_file" "public_ca" {
  template = file("${path.module}/templates/ca.crt")
}

data "template_file" "puppet_install" {
  template = file("${path.module}/templates/puppet_install.sh.tpl")
  vars = {
    puppet_bucket = var.puppet_bucket
    puppet_branch = var.puppet_branch
  }
}


data "template_file" "consul_server_userdata" {
  template = file("${path.module}/templates/consul-user-data.tpl")

  vars = {
    datacenter             = var.consul_datacenter
    encrypt                = var.consul_gossip_encryption_string != "" ? var.consul_gossip_encryption_string : random_id.consul_gossip_encryption.b64_std
    gcp_cluster_name       = "${var.consul_cluster_name}-${var.env}-${var.project_id}"
    is_server              = "true"
    enable_ui              = "true"
    bootstrap_expect       = var.consul_vm_count
    service_name           = "consul"
    get_certificate_script = data.template_file.get_certificate_script.rendered
    internal_domain        = var.internal_domain
    environment            = var.env
    project                = var.project_id
    # puppet_master          = var.puppet_master
    # puppet_branch          = var.puppet_branch
    puppet_install         = data.template_file.puppet_install.rendered
  }
}

data "template_file" "consul_backup_agent" {
  template = file("${path.module}/templates/consul-backup-agent.tpl")

  vars = {
    datacenter           = var.consul_datacenter
    cloud_storage_bucket = "consul-backup-${var.env}-${var.project_id}"
    project              = var.project_id
    service_account      = data.google_service_account.svc_account.email
  }
}

data "template_file" "consul_agent_userdata" {
  template = file("${path.module}/templates/consul-user-data.tpl")

  vars = {
    datacenter             = var.consul_datacenter
    encrypt                = var.consul_gossip_encryption_string != "" ? var.consul_gossip_encryption_string : random_id.consul_gossip_encryption.b64_std
    gcp_cluster_name       = "${var.consul_cluster_name}-${var.env}-${var.project_id}"
    is_server              = "false"
    enable_ui              = "false"
    bootstrap_expect       = 0
    service_name           = "vault"
    get_certificate_script = data.template_file.get_certificate_script.rendered
    internal_domain        = var.internal_domain
    environment            = var.env
    project                = var.project_id
    # puppet_master          = var.puppet_master
    # puppet_branch          = var.puppet_branch
    puppet_install         = data.template_file.puppet_install.rendered
  }
}

data "template_file" "vault_server_user_data" {
  template = file("${path.module}/templates/vault-user-data.tpl")

  vars = {
    project                  = var.project_id
    service_account          = data.google_service_account.svc_account.email
    header                   = data.template_file.consul_agent_userdata.rendered
    keyvault_name            = var.keyring_name
    vault_unseal_secret_name = var.vault_unseal_secret_name
    internal_domain          = var.internal_domain
  }
}

data "template_file" "get_certificate_script" {
  template = file("${path.module}/templates/get_cert.sh.tpl")

  vars = {
    snow_auth            = var.snow_auth
    api_key              = var.api_key
    api_secret           = var.api_secret
    idam_auth            = var.idam_auth
    snow_email_primary   = var.snow_email_primary
    snow_email_secondary = var.snow_email_secondary
    deptlos              = var.deptlos
    territory            = var.territory
    appteam              = var.appteam
    public_ca            = data.template_file.public_ca.rendered
    conf_country         = var.conf_country
    conf_state           = var.conf_state
    conf_locality        = var.conf_locality
    conf_org             = var.conf_org
    conf_orgunit         = var.conf_orgunit
    internal_domain      = var.internal_domain
    san_name             = var.san_name
    snow_url             = var.snow_url
  }
}


######
# Shutdown Scripts
######
data "template_file" "vault_shutdown" {
  template = file("${path.module}/templates/vault_shutdown.sh.tpl")

  vars = {
    project         = var.project_id
    service_account = data.google_service_account.svc_account.email
  }
}

data "template_file" "consul_shutdown" {
  template = file("${path.module}/templates/consul_shutdown.sh.tpl")

  vars = {
    project         = var.project_id
    service_account = data.google_service_account.svc_account.email
  }
}

