# Project / Enviorment
variable "project_id" {
}

variable "region" {
}

variable "env" {
}

variable "image_project_id" {
  description = "Project name where images are being hosted"
}

variable "firewall_ssh_source_ips" {
  default = [
    "144.228.220.178",
    "160.81.147.138",
    "167.14.241.80",
    "207.41.38.218",
    "204.214.59.26",
    "34.194.79.78",
    "35.171.59.97",
    "63.162.225.42",
    "155.201.0.0/16",
    "155.201.150.20",
    "205.246.19.18",
    "205.246.19.42",
    "205.246.19.234",
    "205.246.19.66",
    "205.246.19.90",
    "205.246.19.122",
    "205.246.19.130",
    "205.246.19.138",
    "205.246.19.170",
    "205.246.19.2",
  ]
}

variable "bastion_ip_cidr_range" {
}

variable "bastion" {
  default = true
}

# IAM
variable "custom_role_name" {
}

variable "sa_account" {
}

# Networking
variable "network_name" {
  default = "vault-service"
}

variable "subnet_ip_cidr_range" {
}

# Vault
variable "vault_compute_image" {
}

variable "vault_machine_type" {
}

variable "vault_disk_size_gb" {
}

variable "vault_cluster_name" {
  default = "vault-cluster"
}

variable "vault_unseal_secret_name" {
  default     = "vault-unseal"
  description = "This sets the name of the GCP key used to store Hashicorp Vault's unseal keys"
}

variable "keyring_name" {
  description = "The name of the GCP key ring."
  default     = ""
}

variable "vault_public_lb_subdomain" {
  description = "The DNS subdomain for the Vault public LB. Should be in the form of `*.REGION.cloudapp.azure.com`. Leave default value empty to use var.internal_domain"
  default     = ""
}

variable "vault_vm_count" {
  description = "Number of Vault instances"
  default     = 1
}

# Consul
variable "consul_compute_image" {
}

variable "consul_machine_type" {
}

variable "consul_disk_size_gb" {
}

variable "consul_cluster_name" {
  default = "consul-cluster"
}

variable "consul_datacenter" {
  description = "Consul datacenter name"
}

variable "internal_domain" {
  default     = "vault.internal"
  description = "This sets the internal domain used for local name resolution"
}

variable "consul_gossip_encryption_string" {
  description = "The key must be 16-bytes, Base64 encoded. If empty, Terraform will generate one automatically"
  default     = ""
}

variable "consul_vm_count" {
  description = "Number of Consul instances"
  default     = 3
}

#### Puppet Arguments
variable "puppet_branch" {
  description = "The Puppet environment branch. Must be one of the following: dev_test, dev, stage, prod"
  default     = "prod"
}

variable "puppet_bucket" {
  description = "The bucket where puppet scripts are located"
}


# variable "puppet_master" {
#   description = "The FQDN of the compile master dns_alt_name: Use ghs.puppet-cm.pwc.com for long-lived Vault environments and ghs-puppet-cm-dev.pwc.com for short-lived development environments"
#   default     = "ghs-puppet-cm.pwc.com"
# }

# variable "puppet_domain" {
#   description = "The domain must be one of the following: devcloudnp.ad.pwcinternal.com, devcloud.ad.pwcinternal.com, glblclouddev.ad.pwcinternal.com, glblcloud.ad.pwcinternal.com, stagecloudnp.ad.pwcinternal.com, stagecloud.ad.pwcinternal.com, or pwcglb.com"
#   default     = "pwcglb.com"
# }

### Certificate automation variables
#### API Headers
variable "snow_auth" {
  description = "The base64 encoded Service Now service account used to authenticate to the SNOW backend. You can generate this variable by running $(echo 'insert_snow_username:password' | base64)"
}

variable "api_key" {
  description = "The API key used to access the API via the NIF"
}

variable "api_secret" {
  description = "The API secret used to access the API via the NIF"
}

variable "idam_auth" {
  description = "The base64 encoded IDAM service account used for Proxy authorization. You can generate this variable by running $(echo 'insert_idam_username:password' | base64)"
}

#### CSR Metadata
variable "conf_country" {
  description = "The two-letter ISO code for the country where your organization is located"
  default     = "US"
}

variable "conf_state" {
  description = "The state where your organization is located. This should not be abbreviated e.g. Sussex, Normandy, New Jersey"
  default     = "Florida"
}

variable "conf_locality" {
  description = "The town/city where your organization is located"
  default     = "Tampa"
}

variable "conf_org" {
  description = "Usually the legal incorporated name of a company and should include any suffixes such as Ltd., Inc., or Corp."
  default     = "PwC"
}

variable "conf_orgunit" {
  description = "The department name / organizational unit"
  default     = "PwCLabs"
}

#### ServiceNow Metadata
variable "snow_email_primary" {
  description = "The primary email to receive ServiceNow ticket updates. This must be a valid PwC email"
}

variable "snow_email_secondary" {
  description = "The secondary email to receive ServiceNow ticket updates. This must be a PwC email"
}

variable "deptlos" {
  description = "PwC line of service"
  default     = "IFS"
}

variable "territory" {
  description = "PwC territory site"
  default     = "PwC United States of America"
}

variable "appteam" {
  description = "Please provide the SNOW assignment group for your team. If you do not have a group please select 'GLOBAL - NIS - IDENTITY AND ACCESS MANAGEMENT - CERTIFICATE MANAGEMENT)'"
  default     = "GLOBAL - NIS - IDENTITY AND ACCESS MANAGEMENT - CERTIFICATE MANAGEMENT"
}

variable "san_name" {
  description = "SAN name for PWC cert requests. Must be formatted as `DNS:altname1.domain,DNS:altname2.domain`"
}

variable "snow_url" {
  description = "The SNoW API URL to make API call for the cert automation"
  default     = "https://api.pwc.com"
}