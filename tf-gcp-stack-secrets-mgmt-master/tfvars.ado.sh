#!/bin/sh

cat <<EOF > terraform.auto.tfvars
env = "$ENVIORMENT"
project_id = "$PROJECT_ID"
region = "$REGION"
image_project_id = "$IMAGE_PROJECT_ID"

keyring_name="$KEY_RING_NAME"
vault_unseal_secret_name="$KMS_KEY_NAME"
sa_account="$SA_ACCOUNT_NAME"
custom_role_name="$SA_CUSTOM_ROLE_NAME"

bastion=$BASTION_ENABLE
bastion_ip_cidr_range="$BASTION_CIDR"
subnet_ip_cidr_range="$SUBNET_CIDR"
vault_compute_image="$VAULT_COMPUTE_IMAGE"
vault_machine_type="$VAULT_MACHINE_TYPE"
vault_disk_size_gb=$VAULT_DISK_SIZE
vault_vm_count="$VAULT_VM_COUNT"

consul_compute_image="$CONSUL_COMPUTE_IMAGE"
consul_machine_type="$CONSUL_MACHINE_TYPE"
consul_disk_size_gb=$CONSUL_DISK_SIZE
consul_datacenter="$CONSUL_DATACENTER_NAME"
consul_vm_count="$CONSUL_VM_COUNT"

puppet_branch="$PUPPET_BRANCH"
puppet_bucket="$PUPPET_BUCKET"

snow_auth = "$SNOW_AUTH_TOKEN"
api_key = "$SNOW_API_KEY"
api_secret = "$SNOW_API_SECRET"
idam_auth = "$SNOW_IDAM_AUTH"
snow_email_primary = "$SNOW_PRIMARY_EMAIL"
snow_email_secondary = "$SNOW_SECONDARY_EMAIL"
san_name = "$SAN_NAME"
EOF